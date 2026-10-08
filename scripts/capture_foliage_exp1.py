#!/usr/bin/env python3
"""One nine-frame batch; invoke via capture-foliage-exp1.sh, never nest heavy locks."""
import argparse,json,os,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--output',required=True,type=Path);a=p.parse_args()
a.output=a.output.resolve();a.output.mkdir(parents=True,exist_ok=False)
frames=[]
for mode in ('off','remove','layered'):
 for altitude in (40,150,600):
  run=a.output/('baseline' if mode=='off' else mode)/str(altitude)
  command=[sys.executable,str(ROOT/'scripts/capture_native.py'),'--view','ordinary-street-afternoon','--inspectionpose',f'39.7511195,-105.0389,{altitude},270,45','--foliageexp1',mode,'--output',str(run)]
  subprocess.run(command,cwd=ROOT,check=True)
  evidence=json.loads((run/'native-capture.json').read_text())
  frames.append(evidence)
  (a.output/'batch.json').write_text(json.dumps(frames,indent=2)+'\n')
print('FOLIAGE_BATCH '+str(a.output),flush=True)
