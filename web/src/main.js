// WorldEngine three.js renderer. Loads the shared world package, walks the character along the
// WorldLab demo loop with the same camera rig and presets, and reports frame timing to WorldLab
// (WKWebView message handler "worldlab") or shows it in the page (Safari).
//
// URL parameters: backend=webgpu|webgl2, preset=NAME, state=golden|noon, test=1, hud=0|1,
// frame16x9=1, post=0, world=URL prefix of the package, dog=URL of the dog .glb.
import * as THREE from 'three/webgpu';
import { WorldScene } from './world.js';
import { Lighting } from './lighting.js';
import { CameraRig, fittedDistance } from './camera.js';
import { Motion } from './motion.js';
import { GroundLayer, LocalFrame } from './geo.js';
import { loadDog, standIn } from './dog.js';
import { createPost } from './post.js';
import { FrameReporter } from './metrics.js';

// Inside WorldLab, page warnings and errors also go to the app's log.
for (const level of ['warn', 'error']) {
  const original = console[level].bind(console);
  console[level] = (...args) => {
    original(...args);
    window.webkit?.messageHandlers?.worldlab?.postMessage({ type: 'log', level, message: args.map(String).join(' ').slice(0, 2000) });
  };
}
window.addEventListener('error', (e) => console.error('uncaught', e.message, e.filename, e.lineno));
window.addEventListener('unhandledrejection', (e) => console.error('unhandled rejection', e.reason?.stack || e.reason));

const params = new URLSearchParams(location.search);
const requested = params.get('backend') || 'webgpu';
const presetName = params.get('preset');
const showHUD = params.get('hud') !== '0';
const worldBase = params.get('world') || 'world/';
const dogURL = params.get('dog') || 'dog/luna_light.glb';
const status = (text) => { const el = document.getElementById('status'); el.textContent = text; el.hidden = !text; };

async function main() {
  const demo = await (await fetch('demo.json')).json();
  if (params.get('frame16x9') === '1') document.getElementById('view').classList.add('frame16x9');
  const canvas = document.getElementById('c');

  const renderer = new THREE.WebGPURenderer({ canvas, antialias: true, forceWebGL: requested === 'webgl2', powerPreference: 'high-performance' });
  status('Starting renderer…');
  await renderer.init();
  const backend = renderer.backend.isWebGPUBackend ? 'webgpu' : 'webgl2';
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.info.autoReset = false;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, 1, 0.1, 5000);
  const world = new WorldScene(worldBase);
  await world.load((p) => status(`Loading world… ${Math.round(p * 100)}%`));
  scene.add(world.root);

  // Light state: noon for the v2-04 preset, else the package default (golden hour), as WorldLab does.
  const stateName = params.get('state') || (presetName === 'v2-04' ? 'noon' : world.environment.defaultState);
  const state = world.environment.states[stateName];
  world.setSeason(state.season);
  const lighting = new Lighting(scene);
  await lighting.apply(state, world.globals, `${worldBase}${state.sky}`);

  let character;
  try { character = await loadDog(dogURL, world.globals); } catch (e) { console.warn('dog', e); character = standIn(); }
  scene.add(character.root);

  const origin = world.manifest.frame.origin;
  const frame = new LocalFrame(origin.latitude, origin.longitude);
  const motion = new Motion(character.root, demo.route.map((p) => frame.local(p.lat, p.lon)), demo.walkSpeed, true);
  const rig = new CameraRig(camera, world);
  rig.followStreet(character.root, character.bounds);
  applyPreset(presetName, { demo, frame, world, rig, motion, character });

  const post = params.get('post') === '0' ? null : createPost(renderer, scene, camera);
  const reporter = new FrameReporter(backend, requested);
  setupGestures(canvas, rig, !presetName);
  status('Compiling shaders…');
  const resize = () => {
    const w = canvas.clientWidth, h = canvas.clientHeight;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  };
  new ResizeObserver(resize).observe(canvas);
  resize();

  const hud = document.getElementById('hud');
  hud.hidden = !showHUD;
  const clock = new THREE.Clock();
  const g = world.globals;
  const fwd = new THREE.Vector3();
  let hudTimer = 0;

  if (renderer.compileAsync) await renderer.compileAsync(scene, camera);
  // Debug hook: render one frame offscreen and return mean colors of screen regions.
  window.__worldDebug = async (regions) => {
    rig.update(0, performance.now() / 1000);
    world.updateLODs(camera.position);
    lighting.update(rig.lookTarget, camera.position, world.globals);
    const w = 400, h = 225;
    camera.aspect = w / h; camera.updateProjectionMatrix();
    const rt = new THREE.RenderTarget(w, h);
    renderer.setRenderTarget(rt);
    renderer.render(scene, camera);
    renderer.setRenderTarget(null);
    const px = await renderer.readRenderTargetPixelsAsync(rt, 0, 0, w, h);
    const out = {};
    for (const [name, [x0, y0, x1, y1]] of Object.entries(regions)) {
      let r = 0, g = 0, b = 0, n = 0;
      for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
        const row = renderer.backend.isWebGPUBackend ? y : h - 1 - y;
        const i = (row * w + x) * 4; r += px[i]; g += px[i + 1]; b += px[i + 2]; n++;
      }
      out[name] = [r / n, g / n, b / n].map((v) => Math.round(v));
    }
    return { backend, out };
  };
  status('');
  renderer.setAnimationLoop(async (time) => {
    const dt = Math.min(clock.getDelta(), 0.1);
    const now = performance.now() / 1000;
    // Same order as RealityKit's update: camera, then motion and world.
    const cut = rig.update(dt, now);
    motion.advance(dt);
    character.mixer?.update(dt);
    world.updateLODs(camera.position);
    world.updateTufts(rig.lookTarget, camera.position);
    lighting.update(rig.lookTarget, camera.position, g);
    g.cutEnabled.value = cut ? 1 : 0;
    if (cut) g.character.value.copy(cut);
    // R8 contact under the character (bounds × 0.575, heading from its facing).
    const b = character.bounds;
    g.contactPos.value.copy(character.root.position);
    g.contactHalf.value.set(Math.max(b.max.x - b.min.x, 0.2) * 0.575, Math.max(b.max.z - b.min.z, 0.2) * 0.575);
    fwd.set(0, 0, 1).applyQuaternion(character.root.quaternion);
    g.contactHeading.value = Math.atan2(fwd.x, fwd.z);
    g.contactOpacity.value = 0.18;

    renderer.info.reset();
    if (post) post.render(); else renderer.render(scene, camera);
    reporter.frame(time, renderer.info.render);

    hudTimer += dt;
    if (showHUD && hudTimer > 0.5) {
      hudTimer = 0;
      const r = reporter.recent();
      hud.textContent = `${backend}${backend !== requested ? ` (asked ${requested})` : ''}  ${r.fps.toFixed(0)} fps  frame ${r.ms.toFixed(1)} ms\n`
        + `tris ${(renderer.info.render.triangles / 1000).toFixed(0)}k  draws ${renderer.info.render.drawCalls}  trees ${(world.treeTriangles / 1000).toFixed(0)}k\n`
        + `${window.worldlabStatus || ''}`;
    }
  });
}

/** Screenshot presets, ported from WorldLab's Presets (ContentView.swift). */
function applyPreset(name, { demo, frame, world, rig, motion, character }) {
  if (!name) return;
  rig.autoRecenter = false;
  const stop = (m) => { motion.seek(m); motion.paused = true; };
  const f = demo.fixtures;
  const at = (p, y = GroundLayer.sidewalk) => new THREE.Vector3(...frame.scene(p.lat, p.lon, y));
  switch (name) {
    case 'v2-01':
    case 'v2-04': {
      motion.paused = true;
      const anchor = at(f.streetAnchor);
      character.root.position.copy(anchor);
      character.root.rotation.set(0, -Math.PI / 2, 0); // face west (−X)
      const o = new THREE.Vector3(...f.streetCameraOffset), t = new THREE.Vector3(...f.streetTargetOffset);
      const dir = o.clone().sub(t).normalize();
      const d = fittedDistance(character.bounds, character.root.quaternion, dir.clone().negate(), f.fovDegrees, 0.22);
      rig.fixed(anchor.clone().add(t).addScaledVector(dir, d), anchor.clone().add(t), f.fovDegrees);
      break;
    }
    case 'v2-06': {
      stop(150);
      const c = at(f.aerialCenter);
      const ground = new THREE.Vector3(c.x, 0, c.z);
      rig.fixed(ground.clone().add(new THREE.Vector3(...f.aerialCameraOffset)), ground, f.fovDegrees);
      break;
    }
    case 'street-mid': stop(150); rig.absoluteYaw = Math.PI / 2 + 0.35; rig.pitchOffset = -6; rig.zoom = 2.5; break;
    case 'corner': stop(255); rig.absoluteYaw = Math.PI / 4; rig.zoom = 2.4; rig.pitchOffset = -4; break;
    case 'lake-path': stop(705); rig.absoluteYaw = -Math.PI / 4 - 0.25; rig.zoom = 2.5; rig.pitchOffset = -6; break;
    case 'aerial-low':
      stop(150);
      rig.overview(new THREE.Vector3(242, GroundLayer.sidewalk, -40), 170, 36, -50, 40);
      break;
    default: break;
  }
}

/** Drag to orbit, pinch to zoom (free walk only), like WorldView's gestures. */
function setupGestures(canvas, rig, enabled) {
  if (!enabled) return;
  const pointers = new Map();
  let start = null, pinch = null;
  canvas.addEventListener('pointerdown', (e) => {
    canvas.setPointerCapture(e.pointerId);
    pointers.set(e.pointerId, [e.clientX, e.clientY]);
    start = { x: e.clientX, y: e.clientY, yaw: rig.yawOffset, pitch: rig.pitchOffset };
    if (pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      pinch = { d: Math.hypot(a[0] - b[0], a[1] - b[1]), zoom: rig.zoom };
    }
  });
  canvas.addEventListener('pointermove', (e) => {
    if (!pointers.has(e.pointerId)) return;
    pointers.set(e.pointerId, [e.clientX, e.clientY]);
    const now = performance.now() / 1000;
    if (pointers.size === 2 && pinch) {
      const [a, b] = [...pointers.values()];
      const d = Math.hypot(a[0] - b[0], a[1] - b[1]);
      rig.zoom = Math.max(rig.street.minZoom, Math.min(rig.street.maxZoom, pinch.zoom * (pinch.d / Math.max(d, 1))));
    } else if (start) {
      rig.yawOffset = start.yaw - (e.clientX - start.x) * 0.008;
      rig.pitchOffset = start.pitch + (e.clientY - start.y) * 0.12;
    }
    rig.userDidInteract(now);
  });
  const end = (e) => { pointers.delete(e.pointerId); if (pointers.size < 2) pinch = null; if (pointers.size === 0) start = null; };
  canvas.addEventListener('pointerup', end);
  canvas.addEventListener('pointercancel', end);
}

main().catch((e) => {
  console.error(e);
  status(`Failed: ${e.message}`);
  window.webkit?.messageHandlers?.worldlab?.postMessage({ type: 'error', message: String(e.message || e) });
});
