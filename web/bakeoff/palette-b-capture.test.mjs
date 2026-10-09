// Run after the requested captures and the additional absent/off control ladder.
import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const dir=resolve(process.argv[2]||'web/bakeoff/evidence/palette-b');
const manifest=JSON.parse(await readFile(resolve(dir,'manifest.json'))),rows=manifest.frames;
const png=async r=>readFile(resolve(r.frame));
for(const mode of ['absent','off','lot','tableA'])for(const height of [40,150,600]){
 const scene='sloans-'+height,a=rows.find(r=>r.scene===scene&&r.paletteB===mode&&!r.crownV3&&!r.repeat),b=rows.find(r=>r.scene===scene&&r.paletteB===mode&&!r.crownV3&&r.repeat);
 assert(a&&b,scene+'/'+mode);assert.deepEqual(await png(a),await png(b),'repeat PNG noise');
 const control=rows.find(r=>r.scene===scene&&r.paletteB==='absent'&&!r.repeat);
 assert.deepEqual(a.cost,control.cost,'palette changed geometry/draw coverage');assert.deepEqual(a.camera,control.camera);assert.deepEqual(a.exposure,control.exposure);
 if(['absent','off'].includes(mode))assert.deepEqual(await png(a),await readFile(resolve('docs/lookloop/captures/a7-web-crown-all-near-fix',scene+'-foliage-off-crown-off-fresh.png')),'c8c361d control PNG drift');
 else {assert.equal(a.paletteBReport.mode,mode);assert.match(a.paletteBReport.tableHash,/^[a-f0-9]{64}$/);assert(a.paletteBReport.lawnEndpoints.lawnA);}
}
for(const [scene,mode,v3]of [['lakeview','absent',false],['lakeview','tableA',false],['sloans-150','tableA','standard']]){
 const pair=rows.filter(r=>r.scene===scene&&r.paletteB===mode&&r.crownV3===v3);assert.equal(pair.length,2);assert.deepEqual(await png(pair[0]),await png(pair[1]));
}
const lake=rows.filter(r=>r.scene==='lakeview'&&!r.repeat);assert.deepEqual(lake[0].cost,lake[1].cost);assert.deepEqual(lake[0].camera,lake[1].camera);assert.deepEqual(lake[0].exposure,lake[1].exposure);
manifest.validation={status:'passed',defaultIdentity:'Sloan 40/150/600: absent and off PNG-byte-identical to c8c361d controls; fresh/repeat identical',coverage:'lot/tableA retain every pass triangle/draw count, frozen camera and exposure',repeats:'All 15 conditions have PNG-identical fresh/repeat pairs',scores:'not run'};
await writeFile(resolve(dir,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('PASS 30 frames: c8c361d PNG default identity; repeats; unchanged geometry/camera/grade; mode/hash/resolved endpoints present.');
