"""Compare captured controls and pass ledgers; no visual scoring."""
import json, hashlib, shutil
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent

def difference(a,b):
    x=np.array(Image.open(a).convert('RGB'))[32:].astype(np.int16)
    y=np.array(Image.open(b).convert('RGB'))[32:].astype(np.int16)
    assert x.shape==y.shape,(a,b)
    d=np.abs(x-y)
    return dict(max=int(d.max()),mean=float(d.mean()),changedComponents=int(np.count_nonzero(d)),excludedCreditRows=32)

results=[]
blind=HERE/'blind';blind.mkdir(exist_ok=True)
key=[]
for name in ['sloans','lakeview','wilmette','west-highland']:
    before=HERE/(name+'-off')/'web-capture.json';after=HERE/(name+'-on')/'web-capture.json'
    if not before.exists() or not after.exists(): continue
    off=json.loads(before.read_text());on=json.loads(after.read_text())
    assert off['status']==on['status']=='passed',(name,off['status'],on['status'])
    for a in [f for f in off['frames'] if not f['repeat']]:
        b=next(f for f in on['frames'] if f['scene']==a['scene'] and not f['repeat'])
        passesA=a['metrics']['cost']['passes'];passesB=b['metrics']['cost']['passes']
        row=dict(view=a['scene'],off=a['frame'],on=b['frame'],passesOff=passesA,passesOn=passesB,passLedgerIdentical=passesA==passesB,appearanceDifference=difference(before.parent/a['frame'],after.parent/b['frame']))
        if name=='sloans':
            control=ROOT/'docs/lookloop/captures/a7-web-crown-all-near-fix'/(a['scene']+'-foliage-off-crown-off-fresh.png')
        elif name=='lakeview':
            control=ROOT/'web/bakeoff/evidence/palette-b/lakeview-default/lakeview-foliage-off-crown-off-fresh.png'
        else: control=None
        if control: row['control']=str(control.relative_to(ROOT));row['controlDifference']=difference(control,before.parent/a['frame'])
        for label,src in zip(['A','B'],[before.parent/a['frame'],after.parent/b['frame']] if int(hashlib.sha256(a['scene'].encode()).hexdigest()[:8],16)%2 else [after.parent/b['frame'],before.parent/a['frame']]):
            dest=blind/(a['scene']+'-'+label+'.png');shutil.copyfile(src,dest);key.append(dict(view=a['scene'],label=label,source=str(src.relative_to(HERE))))
        def totals(passes,prefix):
            rows=[v for k,v in passes.items() if k.startswith(prefix+'/')]
            return {k:sum(r[k] for r in rows) for k in ['triangles','draws']}
        row['offTotals']={p:totals(passesA,p) for p in ['main','shadow','post']}
        row['onTotals']={p:totals(passesB,p) for p in ['main','shadow','post']}
        row['delta']={p:{k:row['onTotals'][p][k]-row['offTotals'][p][k] for k in ['triangles','draws']} for p in ['main','shadow','post']}
        assert row['passLedgerIdentical'],row['view']+' changed rendering pass costs'
        assert row['appearanceDifference']['changedComponents']>0,row['view']+' trial is a no-op'
        if control: assert row['controlDifference']['max']==0,row['view']+' failed control gate'
        results.append(row)
(HERE/'comparisons.json').write_text(json.dumps(results,indent=2)+'\n')
for r in results:
    print(r['view'],'same pass ledger',r['passLedgerIdentical'],'control',r.get('controlDifference'))

(HERE/'blind-key.json').write_text(json.dumps(key,indent=2)+'\n')
