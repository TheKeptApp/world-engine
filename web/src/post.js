// R9 grade and emissive bloom, matching Sources/WorldEngine/PostProcess.swift: bloom of the
// display-referred image above 0.9 at 4%, then saturation 0.99 and contrast 1.03.
import * as THREE from 'three/webgpu';
import { acesFilmicToneMapping, agxToneMapping, convertColorSpace, dot, float, mix, neutralToneMapping, pass, vec3, vec4 } from 'three/tsl';
import { bloom } from 'three/addons/tsl/display/BloomNode.js';

/** Tone curve (matched to RealityKit captures). */
export const toneMapping = 'aces';

export const grade = { saturation: 0.99, contrast: 1.03, bloomThreshold: 0.9, bloomStrength: 0.04 };

export function createPost(renderer, scene, camera) {
  const post = new THREE.PostProcessing(renderer);
  post.outputColorTransform = false;
  const scenePass = pass(scene, camera);
  const tm = { aces: acesFilmicToneMapping, neutral: neutralToneMapping, agx: agxToneMapping }[new URLSearchParams(location.search).get('tm') || toneMapping];
  const mapped = tm(scenePass.getTextureNode('output').rgb, float(1));
  const glow = bloom(vec4(mapped, 1), grade.bloomStrength, 0.2, grade.bloomThreshold);
  const withBloom = mapped.add(glow.rgb);
  const luma = dot(withBloom, vec3(0.2126, 0.7152, 0.0722));
  const graded = mix(vec3(luma), withBloom, grade.saturation).sub(0.5).mul(grade.contrast).add(0.5).clamp(0, 1);
  post.outputNode = convertColorSpace(vec4(graded, 1), THREE.LinearSRGBColorSpace, THREE.SRGBColorSpace);
  return post;
}
