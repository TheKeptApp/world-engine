// Isolated local preview. No changes to the production viewer or its server.
import {createServer} from 'node:http';
import {readFile, stat} from 'node:fs/promises';
import {resolve, extname, dirname, sep} from 'node:path';
import {fileURLToPath} from 'node:url';
const here=dirname(fileURLToPath(import.meta.url));
const repo=resolve(here,'../..');
const assets=resolve(process.env.WORLDENGINE_ASSETS || repo);
const mounts=[['/world/lakeview/',resolve(here,'generated/lakeview-sheil-park')],['/world/sloans/',resolve(assets,'Generated/package/sloans-lake')],['/src/',resolve(repo,'web/src')],['/vendor/',resolve(assets,'web/node_modules/three')],['/packs/',resolve(assets,'docs/proposals')],['/',here]];
const types={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.json':'application/json','.png':'image/png','.bin':'application/octet-stream','.glb':'model/gltf-binary','.css':'text/css'};
createServer(async(req,res)=>{try{const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);for(const [prefix,root] of mounts){if(!path.startsWith(prefix))continue;const f=resolve(root,path.slice(prefix.length)||'index.html');if(f!==root&&!f.startsWith(root+sep))break;if(!(await stat(f)).isFile())break;res.writeHead(200,{'Content-Type':types[extname(f)]||'application/octet-stream','Cache-Control':'no-cache','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'});res.end(await readFile(f));return;}}catch{}res.writeHead(404);res.end('Not found');}).listen(Number(process.env.PORT||8782),'127.0.0.1',()=>console.log('Bake-off: http://127.0.0.1:8782/'));
