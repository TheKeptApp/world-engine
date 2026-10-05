// Exact WGS84 local tangent plane, ported from Sources/WorldGeo/LocalFrame.swift.
// Scene axes: east = +X, up = +Y, north = −Z (meters).
const A = 6378137.0;
const F = 1 / 298.257223563;
const E2 = F * (2 - F);

function ecef(latDeg, lonDeg, h = 0) {
  const lat = (latDeg * Math.PI) / 180, lon = (lonDeg * Math.PI) / 180;
  const n = A / Math.sqrt(1 - E2 * Math.sin(lat) * Math.sin(lat));
  return [(n + h) * Math.cos(lat) * Math.cos(lon), (n + h) * Math.cos(lat) * Math.sin(lon), (n * (1 - E2) + h) * Math.sin(lat)];
}

export class LocalFrame {
  constructor(latitude, longitude) {
    this.origin = ecef(latitude, longitude, 0);
    const lat = (latitude * Math.PI) / 180, lon = (longitude * Math.PI) / 180;
    this.trig = [Math.sin(lat), Math.cos(lat), Math.sin(lon), Math.cos(lon)];
  }

  /** East/north meters (flat-world projection). */
  local(latitude, longitude) {
    const p = ecef(latitude, longitude, 0);
    const d = [p[0] - this.origin[0], p[1] - this.origin[1], p[2] - this.origin[2]];
    const [sinLat, cosLat, sinLon, cosLon] = this.trig;
    const e = -sinLon * d[0] + cosLon * d[1];
    const n = -sinLat * cosLon * d[0] - sinLat * sinLon * d[1] + cosLat * d[2];
    return [e, n];
  }

  /** Scene position [x, y, z] at height y. */
  scene(latitude, longitude, y = 0) {
    const [e, n] = this.local(latitude, longitude);
    return [e, y, -n];
  }
}

/** Ground layer heights, from Sources/WorldGen/SceneGenerator.swift (GroundLayer). */
export const GroundLayer = { sidewalk: 0.06 };
