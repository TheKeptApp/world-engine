// The witness is an unoccluded horizontal neutral Lambert patch at the pack sun
// elevation. Three's hemispheric irradiance is linear RGB, not a neutral scalar.
// No camera inputs. Sources: calibration-v2 sharedLook.lighting; installed
// three/src/nodes/lighting/HemisphereLightNode.js; 5A docs/look-spec-changes.md.
const linear=x=>x<=.04045?x/12.92:((x+.055)/1.055)**2;
const Y=hex=>hex.slice(1).match(/../g).map(h=>linear(parseInt(h,16)/255)).reduce((s,x,i)=>s+x*[.2126,.7152,.0722][i],0);
export function witnessLight(L){
 const ratio=L.shadow.neutralWitnessShadowToLitLinearY,directIntensity=Math.PI*L.sun.directRelative;
 const directY=directIntensity*Y(L.sun.hex)*Math.sin(L.sun.elevationDeg*Math.PI/180);
 const ambientIntensity=directY*ratio/(1-ratio)/Y(L.sky.fillHex);
 const fillY=ambientIntensity*Y(L.sky.fillHex);
 return {directIntensity,ambientIntensity,witness:{normal:[0,1,0],directY,fillY,ratio:fillY/(directY+fillY),source:'style-b-calibration-v2/sharedLook.lighting.shadow.neutralWitnessShadowToLitLinearY'}};
}
