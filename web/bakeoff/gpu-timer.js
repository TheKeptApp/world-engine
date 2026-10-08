// WebGL EXT_disjoint_timer_query_webgl2: GPU elapsed time for the complete frame,
// including shadows and the post pass. Never wait synchronously for a query.
export function frameTimer(gl){
 const ext=gl.getExtension('EXT_disjoint_timer_query_webgl2'),pending=[],samples=[];let active=null,disjoint=0;
 const clear=()=>{for(const q of pending)gl.deleteQuery(q);pending.length=0;samples.length=0;};
 return {reset:clear,begin(){if(!ext)return;if(gl.getParameter(ext.GPU_DISJOINT_EXT)){disjoint++;clear();return;}
  while(pending.length&&gl.getQueryParameter(pending[0],gl.QUERY_RESULT_AVAILABLE)){const q=pending.shift();samples.push(gl.getQueryParameter(q,gl.QUERY_RESULT)/1e6);gl.deleteQuery(q);}
  if(pending.length<4){active=gl.createQuery();gl.beginQuery(ext.TIME_ELAPSED_EXT,active);}
 },end(){if(active){gl.endQuery(ext.TIME_ELAPSED_EXT);pending.push(active);active=null;}},snapshot(){const sorted=[...samples].sort((a,b)=>a-b);return {available:!!ext,samples:samples.length,meanMs:samples.length?samples.reduce((a,b)=>a+b,0)/samples.length:null,p95Ms:sorted[Math.floor(sorted.length*.95)]??null,maxMs:sorted.at(-1)??null,disjointEvents:disjoint,scope:'all passes in post.render; hardware GPU timer when available; no per-effect timing'};}};
}
