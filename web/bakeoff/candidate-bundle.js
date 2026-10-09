// Context stays outside detailed geometry pools and retains its original draw ordering.
export function updateDetailedOnly(selector,contextMeshes){
 const masks=contextMeshes.map(o=>o.layers.mask);
 try{for(const o of contextMeshes)o.layers.set(2);selector.update();}
 finally{contextMeshes.forEach((o,i)=>o.layers.mask=masks[i]);}
}
