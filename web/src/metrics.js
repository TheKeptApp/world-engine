// Frame timing. Inside WorldLab (WKWebView) the frame intervals go to the native TestRun via the
// "worldlab" message handler in small batches, so heat, battery and the 10-minute schedule are
// measured the same way for every renderer. In Safari the page keeps its own rolling numbers.
export class FrameReporter {
  constructor(backend, requested) {
    this.backend = backend;
    this.native = window.webkit?.messageHandlers?.worldlab ?? null;
    this.batch = [];
    this.window = [];
    this.lastPost = performance.now();
    this.last = null;
    this.native?.postMessage({ type: 'ready', backend, requested, pixelRatio: window.devicePixelRatio,
      drawable: [Math.round(innerWidth * devicePixelRatio), Math.round(innerHeight * devicePixelRatio)] });
  }

  /** Call once per frame after rendering. Uses the rAF-to-rAF interval (presentation pacing). */
  frame(_dt, info) {
    const t = performance.now();
    if (this.last !== null) {
      const ms = t - this.last;
      this.batch.push(Math.round(ms * 1000) / 1000);
      this.window.push(ms);
      if (this.window.length > 120) this.window.shift();
    }
    this.last = t;
    if (t - this.lastPost > 250 && this.batch.length) {
      this.native?.postMessage({ type: 'frames', intervals: this.batch, triangles: info.triangles, drawCalls: info.drawCalls });
      this.batch = [];
      this.lastPost = t;
    }
  }

  recent() {
    const n = this.window.length || 1;
    const ms = this.window.reduce((a, b) => a + b, 0) / n;
    return { ms, fps: ms > 0 ? 1000 / ms : 0 };
  }
}
