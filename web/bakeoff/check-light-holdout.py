from pathlib import Path
import json,hashlib
from PIL import Image
import numpy as np
b=Path('web/bakeoff/evidence/light-trial');rows=[]
for mode in ['off','on']:
    post=json.loads((b/('post-merge-'+mode)/'web-capture.json').read_text());before=json.loads((b/('lakeview-'+mode)/'web-capture.json').read_text());assert post['status']=='passed'
    for a,z in zip(post['frames'],before['frames']):
        p=b/('post-merge-'+mode)/a['frame'];q=b/('lakeview-'+mode)/z['frame']
        d=np.abs(np.asarray(Image.open(p).convert('RGB'),dtype=np.int16)[32:]-np.asarray(Image.open(q).convert('RGB'),dtype=np.int16)[32:]);assert d.max()==0
        assert a['metrics']['cost']['passes']==z['metrics']['cost']['passes']
        rows.append(dict(mode=mode,repeat=a['repeat'],frame=str(p),control=str(q),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),worldMax=int(d.max()),worldMean=float(d.mean()),passesUnchanged=True))
p=b/'manifest.json';m=json.loads(p.read_text());m['postMergeHoldout']={'revision':'9a6eb0e','rows':rows,'status':'passed exact world 0/0 and unchanged passes; no score'};p.write_text(json.dumps(m,indent=2)+'\n')
print('PASS post-merge Lakeview OFF/ON fresh/repeat: world max/mean 0/0 against the pre-merge pairs; every pass unchanged.')
