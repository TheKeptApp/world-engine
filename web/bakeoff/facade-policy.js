// Pack family selection uses explicit export grammar and mapped era; never camera.
export function facadeFamily(region,generated,pack){
 const f=generated.family;
 const id=region==='chicago'?({greystoneFacade:'chicago-greystone-two-flat',brickStackedFacade:'chicago-brick-two-flat',sixFlat:'chicago-brick-two-flat'}[f]):region==='denver'?({bungalow:'denver-bungalow',foursquare:'denver-foursquare'}[f]):null;
 return pack.content.families.find(f=>f.id===id)||null;
}
export function wallColour(family,source,pack,random){
 if(source['building:colour'])return source['building:colour'];
 const year=parseInt(source.start_date,10);let era=null;
 if(Number.isFinite(year))era=year<1910?pack.content.eraPalettes[0]:year<=1930?pack.content.eraPalettes[1]:pack.content.eraPalettes[2];
 return era?era.colours[Math.floor(random()*era.colours.length)]:family.wall;
}
export function detailTier(height,distance,viewport,fov,lod){const px=height*viewport/(2*Math.tan(fov*Math.PI/360)*Math.max(distance,Number.EPSILON));return px>=lod.nearMinPx?'near':px>=lod.middleMinPx?'middle':'far';}
