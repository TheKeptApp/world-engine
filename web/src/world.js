// Loads the shared world package (Sources/WorldPackage) and builds the three.js scene graph:
// chunk meshes, prototype instancing per kind/variant/400 m cell with near/mid/far detail,
// edge tufts near the camera, and camera collision hulls. Nothing here decides what the world
// looks like; every choice comes from the package.
import * as THREE from 'three/webgpu';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { createGlobals, createPaletteTexture, createWorldMaterial, setPalette } from './materials.js';

async function json(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return r.json();
}

/** Runs `fn` over `items` with at most `limit` in flight. */
async function pool(items, limit, fn) {
  const out = new Array(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) { const i = next++; out[i] = await fn(items[i], i); }
  }));
  return out;
}

const tmpMatrix = new THREE.Matrix4();
const tmpQuat = new THREE.Quaternion();
const tmpScale = new THREE.Vector3();
const tmpPos = new THREE.Vector3();
const yAxis = new THREE.Vector3(0, 1, 0);

/**
 * three.js keeps instance matrices of meshes with ≤ 1000 slots in a uniform block, but Apple's
 * WebGL2 allows only 16 KB (256 matrices) per block. Capacities between 257 and 1000 are raised
 * to 1001 so those meshes use per-instance attributes (same rule for both backends).
 */
const instanceCapacity = (n) => (n <= 256 ? Math.max(1, n) : Math.max(n, 1001));

/** An instanced mesh with its own per-instance origin attribute (shared vertex buffers). */
function instancedMesh(geometry, material, wanted) {
  const capacity = instanceCapacity(wanted);
  const g = new THREE.BufferGeometry();
  for (const [name, attr] of Object.entries(geometry.attributes)) {
    if (name === '_feature') continue;
    g.setAttribute(name, attr);
  }
  g.setIndex(geometry.index);
  g.boundingBox = geometry.boundingBox;
  g.boundingSphere = geometry.boundingSphere;
  const origins = new THREE.InstancedBufferAttribute(new Float32Array(capacity * 3), 3);
  origins.setUsage(THREE.DynamicDrawUsage);
  g.setAttribute('instOrigin', origins);
  const mesh = new THREE.InstancedMesh(g, material, capacity);
  mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  mesh.count = 0;
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return mesh;
}

/** Writes instances (each {position:[x,y,z], yaw, scale, stretch?:[x,z]}) into a mesh. */
function fill(mesh, list) {
  const origins = mesh.geometry.attributes.instOrigin;
  list.forEach((inst, i) => {
    tmpPos.fromArray(inst.position);
    tmpQuat.setFromAxisAngle(yAxis, inst.yaw);
    const stretch = inst.stretch || [1, 1];
    tmpScale.set(inst.scale * stretch[0], inst.scale, inst.scale * stretch[1]);
    tmpMatrix.compose(tmpPos, tmpQuat, tmpScale);
    mesh.setMatrixAt(i, tmpMatrix);
    origins.setXYZ(i, inst.position[0], inst.position[1], inst.position[2]);
  });
  mesh.count = list.length;
  mesh.instanceMatrix.needsUpdate = true;
  origins.needsUpdate = true;
  if (list.length > 0) mesh.computeBoundingSphere();
  mesh.visible = list.length > 0;
}

export class WorldScene {
  constructor(base) {
    this.base = base; // URL prefix of the package, e.g. "world/"
    this.root = new THREE.Group();
    this.root.name = 'World';
    this.globals = createGlobals();
    this.paletteTexture = createPaletteTexture();
    this.stats = { chunkTriangles: 0, instances: 0, tuftCandidates: 0 };
  }

  async load(onProgress = () => {}) {
    const b = this.base;
    this.manifest = await json(`${b}world.json`);
    const [palettes, environment, instances, collision, tuftBuffer] = await Promise.all([
      json(`${b}${this.manifest.palettes}`), json(`${b}${this.manifest.environment}`), json(`${b}${this.manifest.instances}`),
      json(`${b}${this.manifest.collision}`), fetch(`${b}${this.manifest.clutter.tufts.file}`).then((r) => r.arrayBuffer()),
    ]);
    this.palettes = palettes;
    this.environment = environment;
    this.runtime = this.manifest.runtime;
    this.hulls = collision.hulls;
    this.tufts = new Float32Array(tuftBuffer);
    this.stats.tuftCandidates = this.tufts.length / 4;
    this.indexTufts();

    const g = this.globals, pal = this.paletteTexture;
    this.materials = {
      static: createWorldMaterial('static', g, pal), water: createWorldMaterial('water', g, pal),
      prop: createWorldMaterial('prop', g, pal), foliage: createWorldMaterial('foliage', g, pal),
    };
    const byName = { worldStatic: this.materials.static, worldWater: this.materials.water };
    // Shadows come from back faces: closed shapes (houses, crowns, the dog) still cast, flat ground
    // layers never shadow themselves (front-face casting self-shadowed the ground at any bias).
    for (const m of Object.values(this.materials)) m.shadowSide = THREE.BackSide;

    const loader = new GLTFLoader();
    const loadGLB = (path) => loader.loadAsync(`${b}${path}`);
    let done = 0;
    const total = this.manifest.chunks.length + this.manifest.prototypes.reduce((n, p) => n + p.lods.length, 0) + 1;
    const tick = () => onProgress(++done / total);

    // Chunks (LOD0 everywhere, as the RealityKit renderer does).
    const chunks = await pool(this.manifest.chunks, 6, async (c) => {
      const gltf = await loadGLB(c.lods[0]);
      tick();
      return gltf.scene;
    });
    for (const scene of chunks) {
      scene.traverse((o) => {
        if (!o.isMesh) return;
        o.geometry.deleteAttribute('_feature');
        o.material = byName[o.material.name] || this.materials.static;
        o.castShadow = o.material === this.materials.static;
        o.receiveShadow = true;
        this.stats.chunkTriangles += o.geometry.index.count / 3;
      });
      this.root.add(scene);
    }
    const boundary = await loadGLB(this.manifest.boundary);
    tick();
    boundary.scene.traverse((o) => { if (o.isMesh) { o.material = this.materials.static; o.receiveShadow = true; } });
    this.root.add(boundary.scene);

    // Prototypes: kind/variant → [geometry per LOD].
    this.prototypes = new Map();
    for (const p of this.manifest.prototypes) {
      const geos = [];
      for (const path of p.lods) {
        const gltf = await loadGLB(path);
        tick();
        let geo = null;
        gltf.scene.traverse((o) => { if (o.isMesh) geo = o.geometry; });
        geo.computeBoundingBox();
        geo.computeBoundingSphere();
        geos.push(geo);
      }
      this.prototypes.set(`${p.kind}/${p.variant}`, { ...p, geometries: geos });
    }

    // Instances grouped per kind/variant/cell.
    const groups = new Map();
    for (const inst of instances.instances) {
      const key = `${inst.kind}/${inst.variant}/${inst.cell[0]},${inst.cell[1]}`;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(inst);
    }
    this.lodGroups = [];
    this.staticPropTriangles = 0;
    for (const key of [...groups.keys()].sort()) {
      const list = groups.get(key);
      const proto = this.prototypes.get(`${list[0].kind}/${list[0].variant}`);
      const material = proto.material === 'worldFoliage' ? this.materials.foliage : this.materials.prop;
      this.stats.instances += list.length;
      if (proto.geometries.length === 1) {
        const mesh = instancedMesh(proto.geometries[0], material, list.length);
        fill(mesh, list);
        mesh.name = `Props ${key}`;
        this.root.add(mesh);
        this.staticPropTriangles += proto.triangles[0] * list.length;
      } else {
        const levels = proto.geometries.map((geo, lod) => {
          const mesh = instancedMesh(geo, material, list.length);
          mesh.name = `LOD ${key} ${lod}`;
          this.root.add(mesh);
          return mesh;
        });
        this.lodGroups.push({ key, kind: list[0].kind, isTree: proto.isTree, instances: list, levels, triangles: proto.triangles, counts: levels.map(() => 0) });
      }
    }

    // Tufts near the camera.
    const tuft = this.prototypes.get('tuft/0');
    this.tuftMesh = instancedMesh(tuft.geometries[0], this.materials.foliage, 200);
    this.tuftMesh.name = 'Clutter tufts';
    this.tuftMesh.castShadow = false;
    this.root.add(this.tuftMesh);
    this.tuftCenter = null;
    this.lodCenter = null;
    this.treeTriangles = 0;
  }

  /** Applies a light state's season to the palette. */
  setSeason(season) { setPalette(this.paletteTexture, this.palettes, season); }

  /** Re-buckets trees and bushes into their detail levels (near, mid, far, skyline) when the camera moved > 8 m. */
  updateLODs(cameraPosition) {
    const c = [cameraPosition.x, cameraPosition.z];
    if (this.lodCenter && Math.hypot(c[0] - this.lodCenter[0], c[1] - this.lodCenter[1]) < this.runtime.lodRebucketMeters) return;
    this.lodCenter = c;
    const distances = this.runtime.lodDistances;
    let trees = 0, others = 0;
    for (const grp of this.lodGroups) {
      const buckets = grp.levels.map(() => []);
      for (const inst of grp.instances) {
        // Same as RealityKit: horizontal distance between camera and instance, in float; level k from distances[k - 1].
        const d = Math.hypot(Math.fround(inst.position[0]) - c[0], Math.fround(inst.position[2]) - c[1]);
        let lod = 0;
        while (lod < buckets.length - 1 && lod < distances.length && d >= distances[lod]) lod++;
        buckets[lod].push(inst);
      }
      buckets.forEach((list, lod) => {
        fill(grp.levels[lod], list);
        grp.counts[lod] = list.length;
        if (grp.isTree) trees += list.length * grp.triangles[lod]; else others += list.length * grp.triangles[lod];
      });
    }
    this.treeTriangles = trees;
    this.lodPropTriangles = others;
  }

  // Tufts: candidates bucketed in 6 m cells (the generator's cell size) for nearest-200 queries.
  indexTufts() {
    this.tuftCells = new Map();
    const t = this.tufts;
    for (let i = 0; i < t.length; i += 4) {
      const key = `${Math.floor(t[i] / 6)},${Math.floor(-t[i + 1] / 6)}`;
      if (!this.tuftCells.has(key)) this.tuftCells.set(key, []);
      this.tuftCells.get(key).push(i);
    }
  }

  /** R3 edge tufts: nearest 200 within 25 m of the look target, shrinking 20–30 m from the camera. */
  updateTufts(target, cameraPosition) {
    if (this.tuftCenter && Math.hypot(target.x - this.tuftCenter.x, target.z - this.tuftCenter.z) < 3) return;
    this.tuftCenter = target.clone();
    const radius = 25, t = this.tufts;
    const east = target.x, north = -target.z;
    const found = [];
    const c0 = Math.floor((east - radius) / 6), c1 = Math.ceil((east + radius) / 6);
    const r0 = Math.floor((north - radius) / 6), r1 = Math.ceil((north + radius) / 6);
    for (let cx = c0; cx <= c1; cx++) {
      for (let cy = r0; cy <= r1; cy++) {
        const cell = this.tuftCells.get(`${cx},${cy}`);
        if (!cell) continue;
        for (const i of cell) {
          const d = Math.hypot(t[i] - east, -t[i + 1] - north);
          if (d <= radius) found.push([d, i]);
        }
      }
    }
    found.sort((a, b) => a[0] - b[0]);
    const list = [];
    for (const [, i] of found.slice(0, 200)) {
      const d = Math.hypot(t[i] - cameraPosition.x, t[i + 1] - cameraPosition.z);
      const fade = 1 - THREE.MathUtils.smoothstep(d, 20, 30);
      if (fade <= 0.02) continue;
      list.push({ position: [t[i], 0, t[i + 1]], yaw: t[i + 2], scale: t[i + 3] * fade });
    }
    fill(this.tuftMesh, list);
  }

  /** Distance from `target` along `dir` to the first building hull (sphere radius 0.3), or null. */
  castCamera(target, dir, maxDistance) {
    let best = null;
    const step = 0.2, margin = 0.3;
    for (let s = step; s <= maxDistance; s += step) {
      const x = target.x + dir.x * s, y = target.y + dir.y * s, z = target.z + dir.z * s;
      if (this.hitsHull(x, y, z, margin)) { best = s; break; }
    }
    return best;
  }

  hitsHull(x, y, z, margin) {
    if (!this.hullGrid) {
      this.hullGrid = new Map();
      this.hulls.forEach((h, i) => {
        let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
        for (const [px, pz] of h.points) { x0 = Math.min(x0, px); x1 = Math.max(x1, px); z0 = Math.min(z0, pz); z1 = Math.max(z1, pz); }
        h.box = [x0, z0, x1, z1];
        for (let gx = Math.floor((x0 - 1) / 20); gx <= Math.floor((x1 + 1) / 20); gx++) {
          for (let gz = Math.floor((z0 - 1) / 20); gz <= Math.floor((z1 + 1) / 20); gz++) {
            const k = `${gx},${gz}`;
            if (!this.hullGrid.has(k)) this.hullGrid.set(k, []);
            this.hullGrid.get(k).push(i);
          }
        }
      });
    }
    const list = this.hullGrid.get(`${Math.floor(x / 20)},${Math.floor(z / 20)}`);
    if (!list) return false;
    for (const i of list) {
      const h = this.hulls[i];
      if (y > h.height + margin || y < -margin) continue;
      const [x0, z0, x1, z1] = h.box;
      if (x < x0 - margin || x > x1 + margin || z < z0 - margin || z > z1 + margin) continue;
      if (distanceToPolygon(h.points, x, z) <= margin) return true;
    }
    return false;
  }
}

/** Signed-free distance from (x, z) to a polygon: 0 inside, else distance to the nearest edge. */
function distanceToPolygon(points, x, z) {
  let inside = false, best = Infinity;
  for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
    const [xi, zi] = points[i], [xj, zj] = points[j];
    if ((zi > z) !== (zj > z) && x < ((xj - xi) * (z - zi)) / (zj - zi) + xi) inside = !inside;
    const dx = xj - xi, dz = zj - zi, len2 = dx * dx + dz * dz;
    const t = len2 > 0 ? Math.max(0, Math.min(1, ((x - xi) * dx + (z - zi) * dz) / len2)) : 0;
    best = Math.min(best, Math.hypot(x - (xi + dx * t), z - (zi + dz * t)));
  }
  return inside ? 0 : best;
}
