import {frameTimer} from './gpu-timer.js';
import {installCostLedger,phoneBudget} from './budget.js';
import * as T from 'three/webgpu';
import {fract,mx_noise_float,reflect,fog,exp,equirectUV,min,fwidth,length,transformNormalToView,attribute,texture,vec2,vec3,vec4,float,int,floor,select,max,mix,dot,clamp,smoothstep,sin,cos,abs,normalize,positionWorld,positionWorldDirection,normalWorld,cameraPosition,uniform,pass,output,convertColorSpace,acesFilmicToneMapping} from 'three/tsl';
import {WorldScene} from '/src/world.js';
import {shorelineField} from './water.js';
import {Lighting} from '/src/lighting.js';
import {createPost} from '/src/post.js';
import {facadeColours,facadeDetails} from './facades.js';
import {phenology} from './phenology.js';
import {applySpecies} from './foliage.js';
import {addFrontRange} from './backdrop.js';
import {createSkyTexture} from './sky.js';
import {appearanceToRadiance} from './sky-colour.js';
import {resolvePolicy} from './policy.js';
import {LocalFrame} from '/src/geo.js';
const q=new URLSearchParams(location.search), id=document.body.dataset.scene;
const tier=q.get('tier')||'standard';if(!phoneBudget.tiers[tier])throw Error('Unknown phone tier');
if(q.has('capture'))document.body.classList.add('capture');
const get=async p=>{const r=await fetch(p);if(!r.ok)throw Error(`${p}: ${r.status}`);return r.json();};
const status=document.querySelector('#status');
window.addEventListener('error',e=>{document.body.dataset.error=e.error?.stack||e.message;});
window.addEventListener('unhandledrejection',e=>{document.body.dataset.error=e.reason?.stack||String(e.reason);});
const now=uniform(0);
const rgb=c=>vec3(c.r,c.g,c.b);
async function main(){
 const [cal,lake,water,foliage,scenes,fixture,weather,skyCorrection,haze,p2,facadePack,facadeMechanics,facadeData]=await Promise.all([get('/packs/style-b-calibration-v2/values.json'),get('/packs/lake-winter-v1/lake-winter-values.json'),get('/packs/water-surfaces-v1/water-values.json'),get('/packs/foliage-seasons-v1/foliage-values.json'),get('scenes.json'),get('fixture.json'),get('/packs/weather-moments-v1/values.json'),get('data/sky-correction.json'),get('data/haze-values.json'),get('data/p2-crowns.json'),get('data/facade-values.json'),get('data/facade-mechanics.json'),get(`data/${id}-facades.json`)]);
 const config=scenes[id],policy=resolvePolicy(cal,lake,fixture,skyCorrection,haze,config.climateRegion),look=policy.look,L=look.lighting;
 const world=new WorldScene(config.world);await world.load(p=>status.textContent=`Loading export… ${Math.round(p*100)}%`);const seasonal=phenology(fixture.date,config.region,p2);world.setSeason(seasonal.exportSeasonIndex);
 const scene=new T.Scene();scene.add(world.root);
 const renderer=new T.WebGPURenderer({canvas:document.querySelector('#c'),antialias:true,forceWebGL:true});await renderer.init();renderer.setPixelRatio(1);renderer.shadowMap.enabled=true;renderer.shadowMap.type=T.PCFSoftShadowMap;renderer.info.autoReset=false;
 const camera=new T.PerspectiveCamera(config.camera.fov,1,.2,150000);
 const ledger=installCostLedger(renderer,camera),gpuTimer=frameTimer(renderer.backend.gl);
 world.root.traverse(o=>{if(o.isMesh)o.userData.costCategory=o.material===world.materials.water?'water':'opaque world';});
 world.tuftMesh.userData.costCategory='tufts';
 const origin=world.manifest.frame.origin, frame=new LocalFrame(origin.latitude,origin.longitude);
 const at=(lat,lon,y)=>new T.Vector3(...frame.scene(lat,lon,y));
 // These are composition fits, not recovered photographic camera matrices.
 const fit=config.camera;
 camera.position.copy(at(...fit.eye));camera.lookAt(at(...fit.target));
 const baseline=q.has('baseline');
 const facadeCount=baseline?0:await facadeColours(world,facadePack,config.region);
 const facades=baseline?null:facadeDetails(scene,facadeData,frame,facadePack,config.region,look,facadeMechanics);
 const sky=policy.sky;
 const upper=new T.Color(sky.zenithHex),mid=new T.Color(sky.midHex),horizon=new T.Color(sky.horizonHex);
 const skyTexture=createSkyTexture(sky,L.exposure,weather.inherited.sharedLighting.sky);
 scene.backgroundNode=vec4(texture(skyTexture,equirectUV(positionWorldDirection)).rgb,1);
 const scatter=new T.Color().fromArray(policy.atmosphere.airlightLinear);
 // haze-visibility-v1/integration.applyOnce: one linear airlight mix; no sky re-fog.
 scene.fogNode=fog(rgb(scatter),float(1).sub(exp(length(cameraPosition.sub(positionWorld)).mul(-policy.hazeExtinctionPerM))));
 const sun=new T.DirectionalLight(L.sun.hex,policy.directIntensity);
 const az=T.MathUtils.degToRad(L.sun.azimuthDeg),el=T.MathUtils.degToRad(L.sun.elevationDeg);
 const sunDirection=new T.Vector3(Math.sin(az)*Math.cos(el),Math.sin(el),-Math.cos(az)*Math.cos(el));
 sun.position.copy(camera.position).addScaledVector(sunDirection,180);sun.target.position.copy(camera.position);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);Object.assign(sun.shadow.camera,{left:-90,right:90,top:90,bottom:-90,near:1,far:450});sun.shadow.camera.updateProjectionMatrix();sun.shadow.bias=-.00015;sun.shadow.normalBias=.05;scene.add(sun,sun.target);
 scene.add(new T.HemisphereLight(sky.fillHex,sky.fillHex,policy.ambientIntensity));
 if(!baseline){for(const slot of world.palettes.slots){const name=slot.names?.[0],key={road:'asphalt',sidewalk:'concrete',curb:'curb',lawn:'lawn'}[name];if(key){const c=new T.Color(look.materials.groundBaseHex[key]),a=world.paletteTexture.image.data;a.set([c.r,c.g,c.b,1],slot.slot*4);}}world.paletteTexture.needsUpdate=true;}
 const palette=world.paletteTexture;palette.name='palette';skyTexture.name='sky gradient + cumulus';
 // Preserve exported geometry, palette slots and stable per-building variation.
 function matte(kind){const m=new T.MeshStandardNodeMaterial();const p=attribute('_paint','vec4'),e=attribute('_extra','vec4'),flags=int(p.z.add(.5));const flag=b=>flags.bitAnd(int(b)).notEqual(0);const slot=floor(p.x.add(.5));let colour=texture(palette,vec2(slot.add(.5).div(256),.5)).rgb.mul(p.y);const ground=look.materials.groundBaseHex;
 colour=select(flag(4),rgb(new T.Color(ground.lawn)).mul(p.y),colour);colour=select(flag(8),rgb(new T.Color(ground.concrete)).mul(p.y),colour);
 if(kind==='static'){
 const face=attribute('_facade','vec4');colour=select(face.w.greaterThan(0),face.rgb.mul(p.y),colour);
 // Near-only shallow masonry cue: no per-brick geometry, physical scale never enlarged.
 const phase=positionWorld.y.div(facadeMechanics.coursePitchM),footprint=fwidth(phase),line=float(1).sub(smoothstep(facadeMechanics.jointHeightM/facadeMechanics.coursePitchM,float(facadeMechanics.jointHeightM/facadeMechanics.coursePitchM).add(footprint),abs(fract(phase).sub(.5))));
 const visible=float(1).sub(smoothstep(.5,1,footprint.mul(facadePack.lod.featureCullBelowPx)));
 colour=colour.mul(float(1).sub(select(face.w.equal(1),line.mul(visible).mul(facadeMechanics.jointContrast),0)));
 }
 m.colorNode=colour;m.roughnessNode=select(flag(1),float(look.materials.roughness.glass),float(kind==='foliage'?look.materials.roughness.foliage:look.materials.roughness.masonry));m.aoNode=max(e.x,look.lighting.shadow.ambientVisibilityFloor);m.metalness=0;m.shadowSide=T.BackSide;return m;}
 const replacements=new Map(Object.entries(world.materials).filter(([k])=>k!=='water').map(([k,v])=>[v,matte(k)]));
 if(!baseline)world.root.traverse(o=>{if(o.isMesh&&replacements.has(o.material))o.material=replacements.get(o.material);});
 const species=baseline?{}:applySpecies(world,foliage,look.materials.roughness.foliage,config.region,seasonal,p2);
 let mountains=null;
 if(config.waterProfile&&!baseline){
  const mountain=await get('/packs/mountain-terrain-v1/values.json');
  mountains=await addFrontRange(scene,config.backdrop,frame,origin,mountain,policy,camera);
  const profile=lake.water.profiles[config.waterProfile], wave=profile.waveByWindKmh[String(fixture.windKmh)];
  const state=lake.states.find(s=>s.id===config.waterState);
  const waterMaterial=new T.MeshPhysicalNodeMaterial({ior:water.reflectionLimits.waterIORReference});const wp=positionWorld;
  const profileMechanics=water.profiles.find(p=>p.id===config.waterMechanicsProfile);
  // Sources/WorldEngine/Shaders/WorldShaders.metal lake four-wave spectrum.
  // Pack normalAmplitude controls normal-only sub-mesh ripples; no invented swell.
  const weights=water.waveModelProposal.fourWaveWeights,energy=weights.reduce((a,b)=>a+b,0),scales=[1,.71,.53,.37],turns=[0,.45,-.38,.9];
  let gx=float(0),gz=float(0);
  weights.forEach((weight,i)=>{const wavelength=Math.max(.05,wave.wavelengthM*scales[i]),k=2*Math.PI/wavelength,angle=(fixture.windFromDegrees+180)*Math.PI/180+turns[i],dx=Math.sin(angle),dz=-Math.cos(angle);
   const phase=wp.x.mul(dx*k).add(wp.z.mul(dz*k)).sub(now.mul(wave.phaseSpeedMps*k)).add(i*1.7);
   const footprint=fwidth(phase).div(2*Math.PI),fade=float(1).sub(smoothstep(1/lake.water.lod.minimumProjectedWaveWidthCssPx,1,footprint)).mul(float(1).sub(smoothstep(lake.water.lod.normalDetailFadeStartM,lake.water.lod.normalDetailFadeEndM,length(cameraPosition.sub(wp)))));
   const slope=cos(phase).mul(weight/energy*policy.wind.normalAmplitude).mul(fade);gx=gx.add(slope.mul(dx));gz=gz.add(slope.mul(dz));});
  // P2 water noise coordinates/strength; stable world field breaks coherent bands.
  gx=gx.add(mx_noise_float(wp.xz.mul(.9).add(now.mul(.05))).mul(.03));
  gz=gz.add(mx_noise_float(wp.xz.mul(.9).add(7).sub(now.mul(.04))).mul(.03));
  const ripple=gx,waterNormal=normalize(vec3(gx.negate(),1,gz.negate()));
  waterMaterial.normalNode=transformNormalToView(waterNormal);
  // _extra.z is not shore distance. The attached attribute is computed from exported water boundary edges.
  const meshes=[];world.root.traverse(o=>{if(o.isMesh&&o.material===world.materials.water)meshes.push(o);});
  world.root.updateMatrixWorld(true);const field=shorelineField(meshes);field.texture.name='water shore distance';
  const shore=texture(field.texture,wp.xz.sub(vec2(...field.min)).div(vec2(...field.span))).r;
  const body=mix(rgb(new T.Color(profile.shallowColourHex)),rgb(new T.Color(state.surfaceValues[0].baseColourHex)),smoothstep(0,profile.shallowBlendWidthM,shore));
  const view=normalize(cameraPosition.sub(wp));const grazing=float(1).sub(abs(dot(view,waterNormal))).pow(lake.water.reflection.grazingExponent);
  const reflection=mix(float(lake.water.reflection.normalStrength),float(lake.water.reflection.grazingStrength),grazing).min(mix(water.reflectionLimits.nearBlendCap,water.reflectionLimits.farBlendCap,smoothstep(50,180,length(cameraPosition.sub(wp)))));
  waterMaterial.colorNode=body.mul(mix(lake.water.shoreline.linearBaseMultiplier,1,smoothstep(0,lake.water.shoreline.darkeningWidthM,shore)));
  // Already-atmospheric sky reflection bypasses the world fog mix. output.rgb
  // is the once-fogged lit water from NodeMaterial.setupOutput, before the one grade.
  const reflectedRadiance=mix(texture(skyTexture,equirectUV(reflect(view.negate(),waterNormal))).rgb,rgb(new T.Color().fromArray(appearanceToRadiance(new T.Color(policy.reflectedSky.reflectionColourHex).toArray(),L.exposure))),policy.wind.roughness);
  waterMaterial.outputNode=vec4(mix(output.rgb,reflectedRadiance,reflection),1);
  waterMaterial.roughness=policy.wind.roughness;waterMaterial.metalness=0;
  world.root.traverse(o=>{if(o.isMesh&&o.material===world.materials.water){o.material=waterMaterial;}});
 }
 let baselineLighting;
 if(baseline){scene.fogNode=null;scene.remove(sun,sun.target);for(const child of [...scene.children])if(child.isHemisphereLight)scene.remove(child);const state=world.environment.states.noon||world.environment.states[world.environment.defaultState];baselineLighting=new Lighting(scene);await baselineLighting.apply(state,world.globals,`/world/${id}/${state.sky}`);}
 let post=new T.PostProcessing(renderer);post.outputColorTransform=false;
 const source=pass(scene,camera).getTextureNode('output').rgb;
 // Exposure and saturation occur exactly once here, shared by both cities.
 // 5A hue-preserving luminance curve; same ACES fit, one exposure + grade.
 const sourceY=dot(source,vec3(.2126,.7152,.0722)),x=sourceY.mul(L.exposure.linearGain/.6);
 const mappedY=x.mul(x.add(.0245786)).sub(.000090537).div(x.mul(x.mul(.983729).add(.432951)).add(.238081)).max(0);
 const mapped=source.mul(mappedY.div(sourceY.max(.000001)));const y=dot(mapped,vec3(.2126,.7152,.0722));
 const graded=mix(vec3(y),mapped,L.exposure.saturation).sub(.5).mul(L.exposure.contrast).add(.5).clamp(0,1);
 post.outputNode=convertColorSpace(vec4(graded,1),T.LinearSRGBColorSpace,T.SRGBColorSpace);
 if(baseline)post=createPost(renderer,scene,camera);
 const resize=()=>{const c=renderer.domElement;renderer.setSize(c.clientWidth,c.clientHeight,false);camera.aspect=c.clientWidth/c.clientHeight;camera.updateProjectionMatrix();mountains?.updateProjection(c.clientHeight);facades?.update(camera,c.clientHeight);};new ResizeObserver(resize).observe(renderer.domElement);resize();
 document.querySelector('#mock').href=`/packs/style-b-calibration-v2/frames/${config.mock}.png`;
 world.updateLODs(camera.position);world.updateTufts(camera.position,camera.position);
 const times=[];let last=0,frameCount=0;status.textContent=`Calibration v2 · ${fixture.date} inferred foliage · clear atmosphere`;
 window.bakeoff={world,scene,camera,renderer,fit,species,policy,fixture,seasonal,facades:{count:facadeCount,report:facades?.report},mountains:mountains?.diagnostics,resetMetrics:()=>{times.length=0;last=0;gpuTimer.reset();},metrics:null};
 renderer.setAnimationLoop(t=>{now.value=(q.has('still')||window.bakeoff.freeze)?0:t/1000;baselineLighting?.update(camera.position,camera.position,world.globals);renderer.info.reset();ledger.reset();gpuTimer.begin();post.render();gpuTimer.end();if(last)times.push(t-last);last=t;if(times.length>2400)times.shift();const r=renderer.info.render;if(++frameCount%30!==0&&window.bakeoff.metrics){document.body.dataset.ready="1";return;}const avg=times.reduce((a,b)=>a+b,0)/Math.max(1,times.length);window.bakeoff.metrics={scene:id,tier,deviceClass:phoneBudget.tiers[tier],cost:ledger.snapshot(),backend:'WebGL2',gpuTimer:gpuTimer.snapshot(),drawCalls:r.drawCalls,triangles:r.triangles,fps:1000/avg,sampleDurationMs:avg*times.length,p95FrameMs:[...times].sort((a,b)=>a-b)[Math.floor(times.length*.95)]??0,samples:times.length,viewport:[camera.aspect,renderer.domElement.width,renderer.domElement.height],camera:{position:camera.position.toArray(),direction:camera.getWorldDirection(new T.Vector3()).toArray(),fov:camera.fov},visibility:document.visibilityState,userAgent:navigator.userAgent};document.querySelector('#metrics').textContent=`${r.drawCalls} draw calls · ${r.triangles.toLocaleString()} triangles\n${(1000/avg).toFixed(1)} fps · ${times.length} samples`;document.body.dataset.ready='1';});
}
main().catch(e=>{status.textContent=`Unable to load: ${e.message}`;document.body.dataset.error=e.stack||e.message;console.error(e);});
