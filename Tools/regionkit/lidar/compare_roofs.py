#!/usr/bin/env python3
"""Compare roof evidence for any configured areas, with identical classifier settings."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path
import observed_heights as O


def compare(areas):
    O.require_heavy_lock()
    rows=[];methods=[];errors=[]
    for area in areas:
        if area not in O.L.load('observed-heights.json')['authorizedAreas']: raise ValueError('Unauthorized area')
        root=O.REPO/'Data/areas'/area
        d=json.loads((root/'building-roofs.json').read_text());h=json.loads((root/'building-heights.json').read_text())
        methods.append({k:v for k,v in d['method'].items() if k!='surveyCollected'})
        if d['heightSidecarSHA256']!=O.sha(root/'building-heights.json'): errors.append(area+': stale heights')
        if set(d['records'])!=set(h['records']): errors.append(area+': building refs differ')
        forms=Counter();grades=Counter();support=[]
        for ref,r in d['records'].items():
            form=r['type'];pitch=r['pitch_deg'];ridge=r['ridge_bearing_deg']
            forms[form or 'missing']+=1;grades[r['quality_grade']]+=1
            if form is None:
                if pitch is not None or ridge is not None or r['evidence_code']!='missing':errors.append(area+': '+ref+': populated unknown roof')
            else:
                if form not in ('flat','gable','hip','other') or h['records'].get(ref,{}).get('roof_top_agl_m') is None:errors.append(area+': '+ref+': roof without valid height/type')
                if not isinstance(pitch,(int,float)) or not math.isfinite(pitch) or not 0<=pitch<=90:errors.append(area+': '+ref+': invalid pitch')
                if form in ('gable','hip'):
                    if not isinstance(ridge,(int,float)) or not math.isfinite(ridge) or not 0<=ridge<180:errors.append(area+': '+ref+': invalid ridge')
                elif ridge is not None:errors.append(area+': '+ref+': unexpected ridge')
                score=r['confidence']['support_score']
                if not isinstance(score,(int,float)) or not math.isfinite(score) or not 0<=score<=1:errors.append(area+': '+ref+': invalid support')
                else:support.append(score)
            if r['quality_grade']!='D' or r['confidence']['calibrated_probability'] is not None:errors.append(area+': '+ref+': unsupported calibrated quality')
        n=len(d['records']);known=n-forms['missing']
        rows.append({'area':area,'footprints':n,'accepted':known,'null':forms['missing'],'coverageFraction':known/n if n else None,
                     'forms':dict(forms),'grades':dict(grades),'meanUncalibratedSupport':sum(support)/len(support) if support else None,
                     'surveyCollected':d['source']['collected'],'roofSHA256':O.sha(root/'building-roofs.json')})
    identical=all(m==methods[0] for m in methods[1:])
    if not identical:errors.append('Roof methods differ between areas')
    return {'format':'worldengine-roof-comparison/1','identicalMethods':identical,'areas':rows,'errors':errors,
            'status':'FAIL' if errors else 'PASS_WITH_GAPS' if any(r['null'] for r in rows) else 'PASS',
            'qualityNote':'All forms uncalibrated grade D. Support is not probability or real-world accuracy; ridge is an approximate axis, not a traced segment.'}


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--areas',nargs='+',required=True);ap.add_argument('--output',required=True)
    a=ap.parse_args();d=compare(a.areas);Path(a.output).parent.mkdir(parents=True,exist_ok=True);Path(a.output).write_text(json.dumps(d,indent=2,sort_keys=True)+'\n');print(json.dumps(d));raise SystemExit(bool(d['errors']))
