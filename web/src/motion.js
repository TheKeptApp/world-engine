// Walks an object along a route at a fixed speed, facing the direction of travel.
// Port of WorldMotion (Sources/WorldEngine/World.swift); heading smoothing is per frame there too.
import { GroundLayer } from './geo.js';

export class Motion {
  /** route: [[east, north], ...] local meters. */
  constructor(object, route, speed, loop = true) {
    this.object = object;
    const r = route.slice();
    if (loop && r.length > 1) {
      const f = r[0], l = r[r.length - 1];
      if (Math.hypot(f[0] - l[0], f[1] - l[1]) > 0.01) r.push(f);
    }
    this.route = r;
    this.cumulative = [0];
    for (let i = 1; i < r.length; i++) this.cumulative.push(this.cumulative[i - 1] + Math.hypot(r[i][0] - r[i - 1][0], r[i][1] - r[i - 1][1]));
    this.speed = speed;
    this.loop = loop;
    this.paused = false;
    this.distance = 0;
    this.heading = null;
    this.apply();
  }

  get length() { return this.cumulative[this.cumulative.length - 1] || 0; }

  seek(meters) { this.distance = meters; this.heading = null; this.apply(); }

  advance(dt) {
    if (this.paused || this.length <= 0) return;
    this.distance += this.speed * dt;
    this.distance = this.loop ? this.distance % this.length : Math.min(this.distance, this.length);
    this.apply();
  }

  state() {
    const r = this.route, c = this.cumulative;
    if (r.length < 2) return { position: r[0] || [0, 0], direction: [0, 1] };
    const d = Math.max(0, Math.min(this.distance, this.length));
    let i = 0;
    while (i < c.length - 2 && c[i + 1] < d) i++;
    const a = r[i], b = r[i + 1], seg = c[i + 1] - c[i];
    const t = seg > 0 ? (d - c[i]) / seg : 0;
    const dir = seg > 0 ? [(b[0] - a[0]) / seg, (b[1] - a[1]) / seg] : [0, 1];
    return { position: [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t], direction: dir };
  }

  apply() {
    const { position: p, direction: dir } = this.state();
    this.object.position.set(p[0], GroundLayer.sidewalk, -p[1]);
    // Float32 math in Swift; double here (differences far below a millimeter).
    const target = Math.atan2(dir[0], -dir[1]);
    if (this.heading !== null) {
      let delta = target - this.heading;
      while (delta > Math.PI) delta -= 2 * Math.PI;
      while (delta < -Math.PI) delta += 2 * Math.PI;
      this.heading += delta * 0.15;
    } else {
      this.heading = target;
    }
    this.object.rotation.set(0, this.heading, 0);
  }
}
