// Run after A7's command has produced the three immutable capture directories.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const [before,off,candidate]=process.argv.slice(2);
assert(before&&off&&candidate,'Pass unmodified, default-off and candidate capture directories');
const load=async dir=>JSON.parse(await readFile(resolve(dir,'web-capture.json')));
const [b,o,c]=await Promise.all([before,off,candidate].map(load));
for(const r of [b,o,c])assert.equal(r.status,'passed');
assert.equal(b.frames.length,3);assert.equal(o.frames.length,3);assert.equal(c.frames.length,3);
for(let i=0;i<3;i++){
 const a=b.frames[i],x=o.frames[i],y=c.frames[i];assert.equal(a.scene,x.scene);assert.equal(a.scene,y.scene);assert.equal(a.sha256,x.sha256);
 assert.deepEqual(await readFile(resolve(before,a.frame)),await readFile(resolve(off,x.frame)),'default-off PNG changed');
 assert.deepEqual(a.metrics.cost.passes,x.metrics.cost.passes);assert.deepEqual(a.metrics.camera,y.metrics.camera);assert.deepEqual(a.fixture,y.fixture);assert.equal(y.crownV3,'standard');
 for(const [key,p]of Object.entries(x.metrics.cost.passes))if(!key.endsWith('/foliage'))assert.deepEqual(y.metrics.cost.passes[key],p,'non-foliage changed: '+key);
 assert(y.crownV3Report.fragments.averageCardLayers>0);assert.equal(y.crownV3Report.fragments.nearClippedTrianglesOmitted,0);
 assert.equal(y.crownV3Report.lodCounts.reduce((a,b)=>a+b,0)+y.crownV3Report.frustumCulled,y.crownV3Report.trees);
}
console.log('PASS: all three default-off PNGs byte-identical, same cameras/exposure/coverage, only foliage pass deltas, fragment and tree-conservation evidence present');
