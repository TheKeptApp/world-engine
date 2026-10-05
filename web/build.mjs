// Bundles the renderer into dist/ (git-ignored). `three` resolves to the WebGPU build so the
// loaders, TSL and the renderer share one copy of the library.
import * as esbuild from 'esbuild';
import { copyFileSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const dist = resolve(root, 'dist');
rmSync(dist, { recursive: true, force: true });
mkdirSync(dist, { recursive: true });

const threeWebGPU = {
  name: 'three-webgpu',
  setup(build) {
    build.onResolve({ filter: /^three$/ }, () => ({ path: resolve(root, 'node_modules/three/build/three.webgpu.js') }));
  },
};

await esbuild.build({
  entryPoints: [resolve(root, 'src/main.js')],
  bundle: true,
  format: 'esm',
  target: 'es2022',
  outfile: resolve(dist, 'app.js'),
  minify: !process.env.DEV,
  sourcemap: process.env.DEV ? 'inline' : false,
  legalComments: 'none',
  plugins: [threeWebGPU],
  logLevel: 'warning',
});
copyFileSync(resolve(root, 'index.html'), resolve(dist, 'index.html'));
// Host data (route, fixtures): the same file WorldLab uses.
copyFileSync(resolve(root, '../Apps/WorldLab/Resources/demo.json'), resolve(dist, 'demo.json'));
console.log('Built web/dist');
