// R-approved far view class; current packages use a flat local ground datum.
// The caller can supply terrain groundY when a terrain-aware package is supported.
export function farViewAllowed(camera,groundY=0){
 const altitude=camera.position.y-groundY;
 return Number.isFinite(altitude)&&Number.isFinite(groundY)&&altitude>=400;
}
export function casterVisible(object){
 for(let p=object;p;p=p.parent)if(!(p.userData.farShadowVisible??p.visible))return false;
 return true;
}
