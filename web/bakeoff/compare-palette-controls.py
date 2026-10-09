"""Read-only control-noise measurement; preserve full image and world-crop results."""
from pathlib import Path
import json, hashlib
from PIL import Image
import numpy as np
base=Path('web/bakeoff/evidence/palette-b')
controls=[]
for name in ['sloans-absent','sloans-off','lakeview-absent','lakeview-off']:
    run=base/'rebase-controls'/name
    report=json.loads((run/'web-capture.json').read_text()); assert report['status']=='passed'
    row=report['frames'][0]; frame=run/row['frame']
    control=Path('docs/lookloop/captures/a7-web-crown-all-near-fix')/('sloans-150-foliage-off-crown-off-fresh.png' if name.startswith('sloans') else 'lakeview-foliage-off-crown-off.png')
    a=np.asarray(Image.open(frame).convert('RGB')).astype(np.int16); b=np.asarray(Image.open(control).convert('RGB')).astype(np.int16)
    assert a.shape==b.shape
    diff=np.abs(a-b); ys,xs=np.where(diff.max(axis=2)>0)
    def metrics(d):
        maximum=float(d.max())/255;mean=float(d.mean())/255
        return {'maxByte':int(d.max()),'maxNormalized':maximum,'meanNormalized':mean,'differingChannels':int(np.count_nonzero(d)),'gatePass':maximum<=2/255 and mean<=1e-3}
    controls.append({'name':name,'frame':str(frame),'control':str(control),'sha256':hashlib.sha256(frame.read_bytes()).hexdigest(),'pngByteIdentical':frame.read_bytes()==control.read_bytes(),'wholeImage':metrics(diff),'worldBelow32':metrics(diff[32:]),'differenceBounds':[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())] if len(xs) else None})
(base/'rebase-controls/comparison.json').write_text(json.dumps({'units':'RGB channels normalized 0..1; maximum <=2/255, mean <=1e-3','worldCrop':'Top 32 rows excluded, same boundary as diagnosis §3; requires R approval for control gate','controls':controls},indent=2)+'\n')
for r in controls:print(r['name'],r['wholeImage'],r['worldBelow32'])
