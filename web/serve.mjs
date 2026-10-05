// Local server for Safari on the Mac: http://127.0.0.1:8765/?backend=webgpu
//   /            web/dist
//   /world/      Generated/package/<area>   (scripts/export-package.sh)
//   /dog/        Generated/dog              (scripts/convert-dog.sh)
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { dirname, extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const area = JSON.parse(await readFile(resolve(root, '../Apps/WorldLab/Resources/demo.json'), 'utf8')).area;
const mounts = [
  ['/world/', resolve(root, '../Generated/package', area)],
  ['/dog/', resolve(root, '../Generated/dog')],
  ['/', resolve(root, 'dist')],
];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.glb': 'model/gltf-binary',
  '.png': 'image/png', '.bin': 'application/octet-stream' };
const port = Number(process.env.PORT || 8765);

createServer(async (req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  for (const [prefix, dir] of mounts) {
    if (!path.startsWith(prefix)) continue;
    const file = normalize(join(dir, path.slice(prefix.length) || 'index.html'));
    if (!file.startsWith(dir)) break;
    try {
      const s = await stat(file);
      if (!s.isFile()) break;
      res.writeHead(200, { 'Content-Type': types[extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-cache',
        'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp' });
      res.end(await readFile(file));
      return;
    } catch { break; }
  }
  res.writeHead(404); res.end('not found');
}).listen(port, '127.0.0.1', () => console.log(`http://127.0.0.1:${port}/`));
