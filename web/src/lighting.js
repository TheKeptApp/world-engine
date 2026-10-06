// Applies a package light state (environment.json) to the three.js scene: sun, shadows, sky,
// image-based specular light and the shared fill/fog values. Light *meaning* comes from the
// package; the calibration constants below map it to three.js units so captures match RealityKit.
import * as THREE from 'three/webgpu';
import { equirectUV, positionWorldDirection, texture, uniform, vec4 } from 'three/tsl';
import { srgbToLinear } from './materials.js';

export const calibration = {
  // Fitted to RealityKit captures of the v2-01 (golden) and v2-04 (noon) fixtures: lawn, paving,
  // road, shaded walls and crowns within about ±20% luminance after both tone curves.
  // Direct sun: illuminance per normalized sun intensity (RealityKit uses 14000 lux with its own exposure).
  sunScale: 10,
  // Sky light (diffuse spherical harmonics of the sky image) and the visible sky.
  environmentIntensity: 0.08,
  backgroundIntensity: 0.8,
  // R8 fill scale (materials.json lighting.fillScale).
  fillScale: 2.4,
  shadowMapSize: 2048,
  shadowExtent: 40,   // ±40 m around the camera target (RealityKit: 80 m shadow distance)
};

/** Projects an equirectangular sRGB sky image onto 9 SH coefficients (radiance, linear light). */
function skyHarmonics(image) {
  const w = 128, h = 64;
  const canvas = document.createElement('canvas');
  canvas.width = w; canvas.height = h;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(image, 0, 0, w, h);
  const px = ctx.getImageData(0, 0, w, h).data;
  const sh = new THREE.SphericalHarmonics3();
  const basis = new Array(9).fill(0);
  const dir = new THREE.Vector3(), color = new THREE.Color();
  let total = 0;
  for (let y = 0; y < h; y++) {
    const lat = (0.5 - (y + 0.5) / h) * Math.PI;        // row 0 = zenith
    const weight = Math.cos(lat);                         // solid angle ∝ cos(lat)
    for (let x = 0; x < w; x++) {
      const lon = ((x + 0.5) / w) * 2 * Math.PI - Math.PI;
      dir.set(Math.cos(lat) * Math.cos(lon), Math.sin(lat), Math.cos(lat) * Math.sin(lon));
      const i = (y * w + x) * 4;
      color.setRGB(srgbToLinear(px[i] / 255), srgbToLinear(px[i + 1] / 255), srgbToLinear(px[i + 2] / 255));
      THREE.SphericalHarmonics3.getBasisAt(dir, basis);
      for (let k = 0; k < 9; k++) {
        sh.coefficients[k].x += basis[k] * color.r * weight;
        sh.coefficients[k].y += basis[k] * color.g * weight;
        sh.coefficients[k].z += basis[k] * color.b * weight;
      }
      total += weight;
    }
  }
  return sh.scale((4 * Math.PI) / total);
}

const linear = (srgb) => new THREE.Color(srgbToLinear(srgb[0]), srgbToLinear(srgb[1]), srgbToLinear(srgb[2]));

export class Lighting {
  constructor(scene) {
    this.scene = scene;
    this.sun = new THREE.DirectionalLight(0xffffff, 1);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(calibration.shadowMapSize, calibration.shadowMapSize);
    const e = calibration.shadowExtent;
    Object.assign(this.sun.shadow.camera, { left: -e, right: e, top: e, bottom: -e, near: 1, far: 400 });
    this.sun.shadow.camera.updateProjectionMatrix();
    this.sun.shadow.bias = -0.0004;
    this.sun.shadow.normalBias = 0.03;
    scene.add(this.sun);
    scene.add(this.sun.target);
  }

  async apply(state, globals, skyURL) {
    // Calibration overrides for tuning against RealityKit captures (?sun=…&env=…&bg=…).
    const q = new URLSearchParams(location.search);
    for (const [key, name] of [['sun', 'sunScale'], ['env', 'environmentIntensity'], ['bg', 'backgroundIntensity']]) {
      if (q.has(key)) calibration[name] = Number(q.get(key));
    }
    const L = state.light;
    this.state = L;
    const exposure = L.exposure;
    // Sun: color = normalized sun color (sRGB, as RealityKit receives it), strength = intensity × exposure.
    const c = L.sunColor, len = Math.hypot(c[0], c[1], c[2]) || 1;
    const srgb = [c[0] / len, c[1] / len, c[2] / len].map((v) => (v <= 0.0031308 ? v * 12.92 : 1.055 * Math.pow(v, 1 / 2.4) - 0.055));
    this.sun.color.setRGB(srgb[0], srgb[1], srgb[2], THREE.SRGBColorSpace);
    this.sun.intensity = L.sunIntensity * exposure * calibration.sunScale;
    this.sun.castShadow = L.sunIntensity > 0.01 && new URLSearchParams(location.search).get('shadows') !== '0';
    const d = L.sunDirection;
    this.sunDirection = new THREE.Vector3(d[0], d[1] > 0.02 ? d[1] : 0.02, d[2]).normalize();

    // Sky: equirectangular image (three.js convention) as background and environment.
    const tex = await new THREE.TextureLoader().loadAsync(skyURL);
    tex.mapping = THREE.EquirectangularReflectionMapping;
    tex.colorSpace = THREE.SRGBColorSpace;
    // Sky light: diffuse irradiance of the same image as 9 spherical-harmonic coefficients (a
    // LightProbe). Works the same on WebGPU and WebGL2 (three's equirect PMREM path does not
    // run on WebGL2 here). RealityKit's IBL also adds faint speculars; this does not.
    if (this.probe) this.scene.remove(this.probe);
    this.probe = new THREE.LightProbe(skyHarmonics(tex.image), calibration.environmentIntensity * exposure);
    this.scene.add(this.probe);
    // Background: sample the sky image by view direction (equirectangular, three.js convention).
    this.backgroundIntensity = uniform(calibration.backgroundIntensity);
    this.scene.backgroundNode = vec4(texture(tex, equirectUV(positionWorldDirection)).rgb.mul(this.backgroundIntensity), 1);
    this.scene.environment = null;

    // Shared material values (the Metal globals row).
    globals.fogColor.value.copy(linear(L.fog));
    globals.fogStart.value = L.fogStart;
    globals.fogEnd.value = L.fogEnd;
    globals.fillSky.value.copy(linear(L.ambientSky).multiplyScalar(L.fillSky * calibration.fillScale * exposure));
    globals.fillGround.value.copy(linear(L.ambientGround).multiplyScalar(L.fillGround * calibration.fillScale * exposure));
    globals.litFraction.value = L.litWindows;
    const lit = L.sunElevation < -6 ? [0xdc, 0xa9, 0x67] : [0xe9, 0xbe, 0x7c];
    globals.litWindow.value.setRGB(...lit.map((v) => srgbToLinear(v / 255)));
    this.baseFog = [L.fogStart, L.fogEnd];
  }

  /** Per frame: shadow camera follows the view target; aerial fog policy by camera height. */
  update(target, cameraPosition, globals) {
    const p = this.sunDirection.clone().multiplyScalar(150).add(target);
    this.sun.position.copy(p);
    this.sun.target.position.copy(target);
    const h = Math.max(0, cameraPosition.y);
    globals.fogStart.value = Math.max(this.baseFog[0], h * 0.92);
    globals.fogEnd.value = Math.max(this.baseFog[1], h * 2.4);
  }
}
