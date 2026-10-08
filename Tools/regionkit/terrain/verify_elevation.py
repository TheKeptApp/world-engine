#!/usr/bin/env python3
"""One locked terrain suite and unchanged read-back audit for an arbitrary area list."""
import argparse
import json
from pathlib import Path
import unittest
import audit_elevation as A

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--areas',nargs='+',required=True);p.add_argument('--output',required=True);args=p.parse_args()
    A.require_lock();A.E.guard()
    suite=unittest.TestLoader().discover(str(Path(__file__).resolve().parent/'tests'))
    if not unittest.TextTestRunner(verbosity=1).run(suite).wasSuccessful():raise SystemExit(1)
    rows=[];policies=[]
    allowed=json.loads((A.E.HERE/'data/elevation.json').read_text())['authorizedAreas']
    for area in args.areas:
        if area not in allowed:raise ValueError('Unauthorized area')
        result=A.audit(area);meta=json.loads((A.E.REPO/'Data/areas'/area/'elevation/metadata.json').read_text())
        policies.append({'policy':meta['policy'],'nativeBufferMeters':meta['nativeBufferMeters'],'maximumDistanceM':meta['maximumDistanceM'],'bands':[(b['rangeM'],b['sampleSpacingM']) for b in meta['bands']]})
        rows.append({'area':area,'nativeCoverage':result['nativeCoverage'],'bandCoverage':[{'rangeM':b['rangeM'],'sampleSpacingM':b['sampleSpacingM'],'validFraction':b['validFraction']} for b in meta['bands']],'status':result['status'],'errors':result['errors'],'flags':result['flags']})
    identical=all(p==policies[0] for p in policies[1:]);failed=not identical or any(r['errors'] for r in rows)
    result={'format':'worldengine-elevation-comparison/1','identicalPolicy':identical,'areas':rows,'status':'FAIL' if failed else 'PASS_WITH_GAPS' if any(r['flags'] for r in rows) else 'PASS','qualityNote':'Native 1 m local clips; identical coarser source/output resolution by distance. Coverage and internal consistency are verified, not independent elevation accuracy.'}
    Path(args.output).parent.mkdir(parents=True,exist_ok=True);Path(args.output).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));raise SystemExit(failed)
