# Blender (background) script: import a glTF dog, keep one clip, export USDZ for RealityKit.
#   Blender -b --factory-startup -P glb_to_usdz.py -- <in.glb> <out.usdz> <clip>
import sys, bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst, clip = argv[0], argv[1], argv[2]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
# The importer converts clip times with the scene frame rate: set the clips' 30 fps first.
scene.render.fps = 30
bpy.ops.import_scene.gltf(filepath=src)
# The importer adds a display-only icosphere for bone shapes; it is not part of the dog.
# glTF node names that became empties push same-named meshes to ".001": keep the mesh name.
for o in list(scene.objects):
    if o.type == "MESH" and o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o, do_unlink=True)
for o in list(scene.objects):
    if o.type == "EMPTY":
        mesh = scene.objects.get(o.name + ".001")
        if mesh is not None and mesh.type == "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
            mesh.name = mesh.name[:-4]
arm = next(o for o in scene.objects if o.type == "ARMATURE")
action = bpy.data.actions.get(clip) or next(a for a in bpy.data.actions if a.name.startswith(clip))
arm.animation_data_create()
arm.animation_data.action = action
# Blender 4.4+ slotted actions: bind the action's first slot to the armature.
if hasattr(arm.animation_data, "action_slot") and len(action.slots) > 0:
    arm.animation_data.action_slot = action.slots[0]
# Drop NLA tracks the importer made for the other clips.
for t in list(arm.animation_data.nla_tracks):
    arm.animation_data.nla_tracks.remove(t)
start, end = action.frame_range
scene.frame_start, scene.frame_end = int(start), int(end)
print("CLIP", action.name, "frames", start, end)
for o in scene.objects:
    if o.type == "MESH":
        print("MESH", o.name, "verts", len(o.data.vertices), "colors", [a.name for a in o.data.color_attributes],
              "uvs", [u.name for u in o.data.uv_layers])

import os, tempfile
work = tempfile.mkdtemp()
usdc = os.path.join(work, "dog.usdc")
bpy.ops.wm.usd_export(filepath=usdc, export_animation=True, export_armatures=True, only_deform_bones=False,
                      export_shapekeys=True, export_materials=True, export_uvmaps=True, export_normals=True,
                      generate_preview_surface=True, root_prim_path="/Luna",
                      convert_orientation=True, export_global_forward_selection="NEGATIVE_Z", export_global_up_selection="Y")

# RealityKit reads vertex colors only from displayColor: copy the glTF COLOR_0 ("Color") there,
# and also into texture coordinates (st = RG, st1 = B + AO) for custom materials.
from pxr import Usd, UsdGeom, Sdf, Gf, UsdUtils
stage = Usd.Stage.Open(usdc)
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
for prim in stage.Traverse():
    if not prim.IsA(UsdGeom.Mesh):
        continue
    api = UsdGeom.PrimvarsAPI(prim)
    color = api.GetPrimvar("Color")
    if not color or not color.HasValue():
        continue
    values = color.Get()
    interp = color.GetInterpolation()
    dc = api.CreatePrimvar("displayColor", Sdf.ValueTypeNames.Color3fArray, interp)
    dc.Set([Gf.Vec3f(c[0], c[1], c[2]) for c in values])
    ao = api.GetPrimvar("_AO")
    aov = ao.Get() if ao and ao.HasValue() else [1.0] * len(values)
    st = api.CreatePrimvar("st", Sdf.ValueTypeNames.TexCoord2fArray, interp)
    st.Set([Gf.Vec2f(c[0], c[1]) for c in values])
    st1 = api.CreatePrimvar("st1", Sdf.ValueTypeNames.TexCoord2fArray, interp)
    st1.Set([Gf.Vec2f(c[2], a) for c, a in zip(values, aov)])
    print("COLORS", prim.GetPath(), len(values), interp)
stage.GetRootLayer().Save()
if os.path.exists(dst):
    os.remove(dst)
ok = UsdUtils.CreateNewARKitUsdzPackage(Sdf.AssetPath(usdc), dst)
print("WROTE", dst, ok)
