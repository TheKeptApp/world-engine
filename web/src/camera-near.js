// Shared existing CameraRig height policy; preserve its arithmetic and 5% hysteresis.
// See docs/review/lake-banding-diagnosis.md. Flat export ground is y=0.
export function updateCameraNear(camera) {
  const near = Math.min(500, Math.max(0.1, 0.25 * camera.position.y));
  if (Math.abs(near - camera.near) > 0.05 * camera.near) {
    camera.near = near;
    camera.updateProjectionMatrix();
  }
}
