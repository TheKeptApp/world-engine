"""Evidence only: exact-world controls, all-pass deltas and blind-ready copies; no scoring."""
from pathlib import Path
import json,hashlib,shutil
import numpy as np
from PIL import Image
b=Path('web/bakeoff/evidence/light-trial')
def compare(a,b):
    a=np.asarray(Image.open(a).convert('RGB'),dtype=np.int16)[32:];b=np.asarray(Image.open(b).convert('RGB'),dtype=np.int16)[32:]
    assert a.shape==b.shape
    d=np.abs(a-b)
    return dict(maxByte=int(d.max()),meanByte=float(d.mean()),differingChannels=int(np.count_nonzero(d)))
def load(run):
    r=json.loads((b/run/'web-capture.json').read_text());assert r['status']=='passed';return r
rows=[]
for area in ['sloans','lakeview']:
    off,on=load(area+'-off'),load(area+'-on')
    for a,z in zip(off['frames'],on['frames']):
        assert a['scene']==z['scene'] and a['repeat']==z['repeat']
        for k in ['camera','date','fixture','exposure','projection']:assert a[k]==z[k],k
        assert a['metrics']['cost']['passes']==z['metrics']['cost']['passes'],'pass budget changed'
        ap=b/(area+'-off')/a['frame'];zp=b/(area+'-on')/z['frame']
        if area=='sloans':control=Path('docs/lookloop/captures/a7-web-crown-all-near-fix')/(a['scene']+'-foliage-off-crown-off-fresh.png')
        else:control=Path('web/bakeoff/evidence/palette-b/lakeview-default/lakeview-foliage-off-crown-off-fresh.png')
        gate=compare(ap,control);assert gate['maxByte']==gate['meanByte']==0,gate
        delta=compare(ap,zp);assert delta['differingChannels']>0
        row=dict(scene=a['scene'],repeat=a['repeat'],off=str(ap),on=str(zp),control=str(control),worldGate=gate,onDifference=delta,passes=a['metrics']['cost']['passes'],offMetrics=a['metrics'],onMetrics=z['metrics'],trial=z['lightTrialReport'])
        rows.append(row)
blind=b/'blind';blind.mkdir(exist_ok=True);key=[]
# Stable opaque labels; pairing key stays in evidence, A3 receives blind folder.
for r in rows:
    if r['repeat']:continue
    for mode in ['off','on']:
        src=Path(r[mode]);label=hashlib.sha256((r['scene']+mode+'R-light-trial').encode()).hexdigest()[:12]+'.png';shutil.copyfile(src,blind/label)
        key.append(dict(frame=label,scene=r['scene'],mode=mode,sha256=hashlib.sha256(src.read_bytes()).hexdigest()))
(b/'blind-key.json').write_text(json.dumps(key,indent=2)+'\n')
(b/'manifest.json').write_text(json.dumps(dict(status='passed',gate='R exact-world max/mean 0/0, rows y>=32; credits excluded',rows=rows,scores=None),indent=2)+'\n')
print('PASS exact-world controls; OFF/ON all-pass geometry/draw equality; nonzero trial pixel change; blind copies prepared.')
