#!/usr/bin/env python3
"""One nine-frame batch; invoke via capture-foliage-exp1.sh, never nest heavy locks."""
import argparse,base64,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def coverage_fingerprint(readiness):
 """Match category triangles and draws, including context; totals alone can hide swaps."""
 proof=readiness.get('sceneReady')
 if not readiness.get('gpuCompletionProved') or not proof:
  raise ValueError('Matched batch requires completed-frame SCENEREADY evidence')
 signature=base64.b64decode(proof['signature'],validate=True).decode('utf-8')
 def counts(text):
  fields=dict(re.findall(r'(chunks|buildings|foliage|props|context|other)=(\d+)',text))
  if len(fields)!=6: raise ValueError('Incomplete category coverage signature')
  return tuple(int(fields[key]) for key in ('chunks','buildings','foliage','props','context','other'))
 triangles=counts(signature.split('|tri=',1)[1].split('|draw=',1)[0])
 draws=counts(signature.split('|draw=',1)[1])
 if sum(triangles)!=readiness['triangles'] or sum(draws)!=readiness['draws'] or draws!=counts(readiness['drawsplit']):
  raise ValueError('Snapshot counters disagree with SCENEREADY; batch stopped')
 return triangles,draws

def main():
 p=argparse.ArgumentParser();p.add_argument('--output',required=True,type=Path);a=p.parse_args()
 a.output=a.output.resolve();a.output.mkdir(parents=True,exist_ok=False)
 frames=[]
 coverage={}
 for mode in ('off','remove','layered'):
  for altitude in (40,150,600):
   run=a.output/('baseline' if mode=='off' else mode)/str(altitude)
   command=[sys.executable,str(ROOT/'scripts/capture_native.py'),'--view','ordinary-street-afternoon','--inspectionpose',f'39.7511195,-105.0389,{altitude},270,45','--foliageexp1',mode,'--output',str(run)]
   subprocess.run(command,cwd=ROOT,check=True)
   evidence=json.loads((run/'native-capture.json').read_text())
   readiness=evidence['sceneReadiness']
   fingerprint=coverage_fingerprint(readiness)
   if coverage.setdefault(altitude,fingerprint)!=fingerprint:
    raise ValueError(f'Unmatched scene coverage at {altitude} m: {mode}; batch stopped, no automatic recapture')
   frames.append(evidence)
   (a.output/'batch.json').write_text(json.dumps(frames,indent=2)+'\n')
 print('FOLIAGE_BATCH '+str(a.output),flush=True)

if __name__=='__main__': main()
