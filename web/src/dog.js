// DogWell's Luna (glTF from the handoff export): walk clip, coat material matching the
// RealityKit one in Apps/WorldLab/Sources/DogCoat.metal (vertex color + world fill + rim).
import * as THREE from 'three/webgpu';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { abs, dot, float, mix, normalView, normalWorld, positionViewDirection, pow, vec3, vertexColor } from 'three/tsl';

export const rimStrength = 0.35;

export async function loadDog(url, globals) {
  const gltf = await new GLTFLoader().loadAsync(url);
  const dog = gltf.scene;
  dog.name = 'Luna';
  const coat = new THREE.MeshStandardNodeMaterial();
  coat.name = 'coat';
  const color = vertexColor().rgb;
  const hemi = normalWorld.y.mul(0.5).add(0.5);
  const sky = vec3(globals.fillSky);
  const rim = pow(float(1).sub(abs(dot(normalView, positionViewDirection))), 3).mul(rimStrength);
  coat.colorNode = color;
  coat.roughnessNode = float(0.7);
  coat.metalnessNode = float(0);
  coat.emissiveNode = color.mul(mix(sky.mul(0.35), sky, hemi)).add(vec3(0.6, 0.56, 0.5).mul(rim));
  dog.traverse((o) => {
    if (!o.isMesh) return;
    o.castShadow = true;
    o.receiveShadow = true;
    o.frustumCulled = false;
    if (o.material?.name === 'coat') o.material = coat;
  });
  const root = new THREE.Group();
  root.name = 'Character';
  root.add(dog);
  const mixer = new THREE.AnimationMixer(dog);
  const walk = gltf.animations.find((a) => a.name === 'walk') || gltf.animations[0];
  if (walk) mixer.clipAction(walk).play();
  mixer.update(0);
  // Local bounds in the first pose (RealityKit: visualBounds relative to the entity).
  root.updateMatrixWorld(true);
  const bounds = new THREE.Box3().setFromObject(dog, true);
  return { root, mixer, bounds };
}

/** Stand-in when the dog export is missing: the WorldLab capsule (0.65 m). */
export function standIn() {
  const root = new THREE.Group();
  root.name = 'Stand-in';
  const paint = new THREE.MeshStandardNodeMaterial({ color: new THREE.Color(0.95, 0.55, 0.25), roughness: 0.6 });
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.12, 0.41, 8, 16), paint);
  body.position.y = 0.325;
  body.castShadow = true;
  root.add(body);
  return { root, mixer: null, bounds: new THREE.Box3(new THREE.Vector3(-0.12, 0, -0.12), new THREE.Vector3(0.12, 0.65, 0.12)) };
}
