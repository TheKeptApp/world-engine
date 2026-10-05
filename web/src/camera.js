// Camera rig, ported from Sources/WorldEngine/WorldCamera.swift: street follow (projected-bounds
// framing at 22% of the view height, occlusion pull-in, recenter), overview orbit and fixed.
import * as THREE from 'three/webgpu';

export const streetSettings = {
  screenFraction: 0.22, fieldOfViewDegrees: 50, pitchDegrees: 14, minPitchDegrees: 4, maxPitchDegrees: 60,
  targetHeightFactor: 0.8, minZoom: 0.5, maxZoom: 2.5, recenterDelay: 5, minDistance: 0.8,
};

/** Distance at which a local bounding box (rotated by `quaternion`) spans `fraction` of the view height. */
export function fittedDistance(box, quaternion, viewDirection, fovDegrees, fraction) {
  const f = viewDirection.clone().normalize();
  const right = new THREE.Vector3().crossVectors(f, new THREE.Vector3(0, 1, 0)).normalize();
  const up = new THREE.Vector3().crossVectors(right, f);
  let lo = Infinity, hi = -Infinity;
  const c = new THREE.Vector3();
  for (let i = 0; i < 8; i++) {
    c.set(i & 1 ? box.max.x : box.min.x, i & 2 ? box.max.y : box.min.y, i & 4 ? box.max.z : box.min.z).applyQuaternion(quaternion);
    const v = c.dot(up);
    lo = Math.min(lo, v); hi = Math.max(hi, v);
  }
  return Math.max(0.1, hi - lo) / (2 * Math.tan((fovDegrees * Math.PI) / 360) * fraction);
}

export class CameraRig {
  constructor(camera, world) {
    this.camera = camera;
    this.world = world;
    this.mode = null;
    this.street = { ...streetSettings };
    this.yawOffset = 0;
    this.pitchOffset = 0;
    this.zoom = 1;
    this.autoRecenter = true;
    this.absoluteYaw = null;
    this.lastInteraction = -Infinity;
    this.smoothedYaw = null;
    this.smoothedDistance = null;
    this.characterBounds = null;
    this.lookTarget = new THREE.Vector3();
  }

  followStreet(object, localBounds) { this.mode = { type: 'street', object }; this.characterBounds = localBounds; }
  overview(center, distance, pitchDegrees, yawDegrees, fov) { this.mode = { type: 'overview', center, distance, pitchDegrees, yawDegrees, fov }; }
  fixed(position, target, fov) { this.mode = { type: 'fixed', position, target, fov }; }
  userDidInteract(now) { this.lastInteraction = now; }

  setFOV(fov) {
    if (this.camera.fov !== fov) { this.camera.fov = fov; this.camera.updateProjectionMatrix(); }
  }

  /**
   * Near plane from camera height. three.js r180 has no reversed depth buffer, so with a fixed
   * 0.1 m near plane a 24-bit depth buffer resolves only ~2 m at the 1.8 km aerial distance and
   * the centimeter-spaced ground layers fight. RealityKit keeps 0.1 m (its depth is precise).
   */
  updateNear() {
    const near = Math.min(500, Math.max(0.1, 0.25 * this.camera.position.y));
    if (Math.abs(near - this.camera.near) > 0.05 * this.camera.near) {
      this.camera.near = near;
      this.camera.updateProjectionMatrix();
    }
  }

  /** Places the camera; returns the cut-away target (character center) in street mode, else null. */
  update(dt, now) {
    const result = this.place(dt, now);
    this.updateNear();
    return result;
  }

  place(dt, now) {
    const m = this.mode;
    if (!m) return null;
    if (m.type === 'fixed') {
      this.setFOV(m.fov);
      this.camera.position.copy(m.position);
      this.camera.lookAt(m.target);
      this.lookTarget.copy(m.target);
      return null;
    }
    if (m.type === 'overview') {
      this.setFOV(m.fov);
      const p = (m.pitchDegrees * Math.PI) / 180, y = (m.yawDegrees * Math.PI) / 180;
      const offset = new THREE.Vector3(Math.sin(y) * Math.cos(p), Math.sin(p), Math.cos(y) * Math.cos(p)).multiplyScalar(m.distance);
      this.camera.position.copy(m.center).add(offset);
      this.camera.lookAt(m.center);
      this.lookTarget.copy(m.center);
      return null;
    }
    const s = this.street, entity = m.object;
    this.setFOV(s.fieldOfViewDegrees);
    const bounds = this.characterBounds;
    const h = Math.max(0.2, bounds.max.y - bounds.min.y);
    const target = entity.position.clone().add(new THREE.Vector3(0, h * s.targetHeightFactor, 0));
    this.lookTarget.copy(target);

    if (this.autoRecenter && now - this.lastInteraction > s.recenterDelay) {
      this.yawOffset *= Math.max(0, 1 - dt * 1.5);
      this.pitchOffset *= Math.max(0, 1 - dt * 1.5);
    }
    const fwd = new THREE.Vector3(0, 0, 1).applyQuaternion(entity.quaternion);
    const behindYaw = Math.atan2(-fwd.x, -fwd.z);
    const targetYaw = (this.absoluteYaw ?? behindYaw) + this.yawOffset;
    if (this.smoothedYaw !== null) {
      let d = targetYaw - this.smoothedYaw;
      while (d > Math.PI) d -= 2 * Math.PI;
      while (d < -Math.PI) d += 2 * Math.PI;
      this.smoothedYaw += d * Math.min(1, dt * 4);
    } else {
      this.smoothedYaw = targetYaw;
    }
    const pitch = (Math.max(s.minPitchDegrees, Math.min(s.maxPitchDegrees, s.pitchDegrees + this.pitchOffset)) * Math.PI) / 180;
    const yaw = this.smoothedYaw;
    const dir = new THREE.Vector3(Math.sin(yaw) * Math.cos(pitch), Math.sin(pitch), Math.cos(yaw) * Math.cos(pitch));
    const base = fittedDistance(bounds, entity.quaternion, dir.clone().negate(), s.fieldOfViewDegrees, s.screenFraction);
    const wanted = base * Math.max(s.minZoom, Math.min(s.maxZoom, this.zoom));

    let allowed = wanted;
    const hit = this.world.castCamera(target, dir, wanted);
    if (hit !== null) allowed = Math.max(s.minDistance, hit - 0.15);
    const current = this.smoothedDistance ?? allowed;
    this.smoothedDistance = allowed < current ? allowed : current + (allowed - current) * Math.min(1, dt * 1.2);
    this.camera.position.copy(target).addScaledVector(dir, this.smoothedDistance);
    this.camera.lookAt(target);
    return entity.position.clone().add(new THREE.Vector3(0, h * 0.5, 0));
  }
}
