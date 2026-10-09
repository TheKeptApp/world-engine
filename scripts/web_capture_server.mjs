// A capture owns its loopback server and an OS-assigned port; no shared port/process.
import {createServer} from 'node:http';
import {readFile,realpath} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
export async function startCaptureServer(root, overrides={}) {
 root=await realpath(root);
 const here=resolve(root,'web/bakeoff');
 const mounts=[['/world/capture/',resolve(root,'Generated/web-capture')],['/world/lakeview/',resolve(here,'generated/lakeview-sheil-park')],['/world/sloans/',resolve(root,'Generated/package/sloans-lake')],['/src/',resolve(root,'web/src')],['/vendor/',resolve(root,'web/node_modules/three')],['/packs/',resolve(root,'docs/proposals')],['/',here]];
 const types={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.json':'application/json','.png':'image/png','.bin':'application/octet-stream','.glb':'model/gltf-binary','.css':'text/css'};
 const failures=[];
 const server=createServer(async(req,res)=>{try{
  const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  if(Object.hasOwn(overrides,path)){res.writeHead(200,{'Content-Type':typeof overrides[path]==='string'?'text/html':'application/json','Cache-Control':'no-store'});res.end(typeof overrides[path]==='string'?overrides[path]:JSON.stringify(overrides[path]));return;}
  if(path==='/favicon.ico'){res.writeHead(204);res.end();return;}
  for(const [prefix,base] of mounts){if(!path.startsWith(prefix))continue;
   const file=await realpath(resolve(base,path.slice(prefix.length)||'index.html'));
   if(file!==base&&!file.startsWith(base+sep))break;
   const bytes=await readFile(file);res.writeHead(200,{'Content-Type':types[extname(file)]||'application/octet-stream','Cache-Control':'no-store','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'});res.end(bytes);return;
  }
 }catch{}failures.push(req.url);res.writeHead(404);res.end('Not found');});
 await new Promise((ok,no)=>{server.once('error',no);server.listen(0,'127.0.0.1',ok);});
 return {origin:`http://127.0.0.1:${server.address().port}`,failures,close:()=>new Promise((ok,no)=>{server.close(error=>error?no(error):ok());server.closeAllConnections();})};
}
