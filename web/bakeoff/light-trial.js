import * as T from 'three/webgpu';
import {Fn,texture,dFdx,dFdy,float} from 'three/tsl';
export function lightTrialMode(value){const mode=value??'off';if(!['off','on'].includes(mode))throw Error('Invalid lightTrial: '+mode);return mode;}
// R light trial, 9 Oct: existing calibration-v2 lighting inputs only.
// Trial interpretation: lower-hemisphere bounce uses the existing ambient floor;
// upper irradiance and the horizontal 0.62 witness are unchanged, AO is not edited.
export function lightTrialValues(L){return {filterWidthPx:L.shadow.filterDrawablePx[1],groundScale:L.shadow.ambientVisibilityFloor,fillHex:L.sky.fillHex,source:'style-b-calibration-v2/sharedLook.lighting.shadow.{filterDrawablePx,ambientVisibilityFloor}; sky.fillHex'};}
export function installLightTrial(scene,sun,policy){
 const values=lightTrialValues(policy.look.lighting);
 const hemispheres=scene.children.filter(o=>o.isHemisphereLight);
 if(hemispheres.length!==1)throw Error('Light trial requires one existing hemisphere');
 hemispheres[0].groundColor.copy(hemispheres[0].color).multiplyScalar(values.groundScale);
 // 4x4 equal-area quadrature: sixteen depth comparisons, same as installed
 // PCFSoftShadowFilter. Derivatives convert drawable pixels to shadow UVs;
 // neither world reach nor shadow map size/casters change. No extra render pass.
 sun.shadow.filterNode=Fn(({depthTexture,shadowCoord,depthLayer})=>{
  const dx=dFdx(shadowCoord.xy),dy=dFdy(shadowCoord.xy);let total=float(0);
  for(let y=0;y<4;y++)for(let x=0;x<4;x++){
   const uv=shadowCoord.xy.add(dx.mul(((x+.5)/4-.5)*values.filterWidthPx)).add(dy.mul(((y+.5)/4-.5)*values.filterWidthPx));
   let sample=texture(depthTexture,uv);if(depthTexture.isArrayTexture)sample=sample.depth(depthLayer);
   total=total.add(sample.compare(shadowCoord.z));
  }
  return total.div(16);
 });
 return {...values,mode:'on',depthComparisons:16,additionalPasses:0,witness:policy.witness,interpretation:'experimental lower hemisphere = sky fill × ambient floor; horizontal witness preserved'};
}
