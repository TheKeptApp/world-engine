#!/usr/bin/env python3
"""Internal geometry-only comparison. Never writes area data, packages or ladder config.

Run with an existing numpy/shapely environment. Raw tiles, joins and agreement
stay in ignored Generated/ms-height-experiment; only aggregate evidence is filed.
Rules: height-sources-us.md Join contract; no geometry shifts or height fitting.
"""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys

import numpy as np
import shapely
from shapely.geometry import shape
from shapely.ops import transform

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT/'Tools/regionkit/lidar'))
import lidar as L
import roofplanes as RP


def sha(p):
    h=hashlib.sha256()
    with Path(p).open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()


def usable(value):
    return isinstance(value,(float,int)) and not isinstance(value,bool) and math.isfinite(value) and value>0


def match(polys, sources, minimum=.70):
    """Reject multiple eligible candidates on either side; no height-aware selection."""
    tree=shapely.STRtree(sources)
    candidates={}; reverse=defaultdict(list)
    for ref,p in polys.items():
        found=[]
        for i in tree.query(p):
            i=int(i); q=sources[i]; intersection=p.intersection(q).area
            iou=intersection/(p.area+q.area-intersection) if intersection else 0
            if iou>=minimum: found.append((i,iou)); reverse[i].append(ref)
        candidates[ref]=found
    accepted={ref:rows[0] for ref,rows in candidates.items() if len(rows)==1 and len(reverse[rows[0][0]])==1}
    return accepted,{'noEligibleOverlap':sum(not c for c in candidates.values()),
        'multipleEligibleSources':sum(len(c)>1 for c in candidates.values()),
        'sharedEligibleSourceRecords':sum(len(v)>1 for v in reverse.values()),
        'ambiguousTargetCount':sum(bool(c) and ref not in accepted for ref,c in candidates.items()),
        'duplicateSourceReuseAccepted':0}


def metrics(errors):
    a=np.asarray(errors,float)
    if not len(a): return {'n':0,'medianAbsoluteM':None,'p90AbsoluteM':None,'signedMeanBiasM':None,'meetsProposedThresholds':False}
    median=float(np.median(abs(a))); p90=float(np.percentile(abs(a),90)); bias=float(np.mean(a))
    return {'n':len(a),'medianAbsoluteM':median,'p90AbsoluteM':p90,'signedMeanBiasM':bias,
            'meetsProposedThresholds':median<=1 and p90<=3 and abs(bias)<=.5}


def tile_bounds(key):
    x=y=0
    for d in key: x=x*2+(int(d)&1); y=y*2+(int(d)>>1)
    n=2**len(key)
    lat=lambda v:math.degrees(math.atan(math.sinh(math.pi*(1-2*v/n))))
    return (x/n*360-180,lat(y+1),(x+1)/n*360-180,lat(y))


def selected_rows(catalogue,b):
    out=[]
    for row in csv.DictReader(catalogue.open()):
        if row['Location']!='UnitedStates':continue
        w,s,e,n=tile_bounds(row['QuadKey'])
        if w<=b['east'] and e>=b['west'] and s<=b['north'] and n>=b['south']:out.append(row)
    return out


def run(area,work):
    directory=ROOT/'Data/areas'/area
    man=json.loads((directory/'manifest.json').read_text()); obs=json.loads((directory/'building-heights.json').read_text())
    assert obs['footprints']['sha256']==sha(directory/'osm.json')
    fps,_=L.footprints({'area':'Data/areas/'+area},man)
    polys={ref:fps[ref]['poly'] for ref in obs['records']}
    assert all(p.is_valid and not p.is_empty for p in polys.values())
    b=next(s['bounds'] for s in man['sources'] if s['path']=='osm.json')
    selected=selected_rows(work/'dataset-links.csv',b)
    if not selected:raise ValueError('No catalogue coverage')
    lat=man['center']['latitude'];lon=man['center']['longitude']
    def project(x,y,z=None): return RP.local_en(lat,lon,y,x)
    extent=shapely.union_all(list(polys.values())).envelope
    rows=[]; source_polys=[]; counts=Counter(); tiles=[]; geometry_counts=Counter()
    for item in selected:
        path=work/(item['QuadKey']+'.gz')
        if shutil.disk_usage(work).free<8*1024**3:raise RuntimeError('Disk guard below 8 GiB')
        tiles.append({**item,'sha256':sha(path),'bytes':path.stat().st_size})
        with gzip.open(path,'rt') as f:
            for line_no,line in enumerate(f,1):
                feature=json.loads(line);counts['tileRecordsScanned']+=1
                g=feature['geometry']; coordinates=g['coordinates']
                # GeoJSON Polygon/MultiPolygon only; fast geographic envelope rejection.
                rings=coordinates if g['type']=='Polygon' else [r for p in coordinates for r in p] if g['type']=='MultiPolygon' else []
                if not rings:counts['unsupportedGeometry']+=1;continue
                points=[p for r in rings for p in r]
                if max(p[0] for p in points)<b['west'] or min(p[0] for p in points)>b['east'] or max(p[1] for p in points)<b['south'] or min(p[1] for p in points)>b['north']:continue
                p=transform(project,shape(g))
                if not p.is_valid or p.is_empty:counts['invalidLocalGeometry']+=1;continue
                if not p.intersects(extent):continue
                height=feature.get('properties',{}).get('height')
                source_polys.append(p);rows.append({'sourceRecord':f"{item['QuadKey']}:{line_no}",'height':height})
                geometry_counts[shapely.normalize(p).wkb]+=1
    matches,diagnostics=match(polys,source_polys)
    records={};errors=[];null_filled=0; usable_count=0
    for ref,observed in obs['records'].items():
        record={'observedAGLM':observed['roof_top_agl_m'],'matched':ref in matches,'inferredMicrosoftHeightM':None}
        if ref in matches:
            i,iou=matches[ref];record.update(rows[i]);record['iou']=iou
            if usable(rows[i]['height']):
                h=rows[i]['height'];record['inferredMicrosoftHeightM']=h;usable_count+=1
                if record['observedAGLM'] is None:null_filled+=1
                else:errors.append(h-record['observedAGLM'])
        records[ref]=record
    observed_n=sum(r['roof_top_agl_m'] is not None for r in obs['records'].values())
    result={'area':area,'footprints':len(polys),'acceptedLidar':observed_n,'lidarNull':len(polys)-observed_n,
            'matchedFootprints':len(matches),'matchPercent':100*len(matches)/len(polys),
            'usableMicrosoftHeights':usable_count,'usablePercent':100*usable_count/len(polys),
            'lidarNullWithMicrosoftHeight':null_filled,'matchedButMissingHeight':len(matches)-usable_count,
            'localSourceRecords':len(rows),'sourceMissingHeight':sum(not usable(r['height']) for r in rows),
            'exactDuplicateGeometryExtraRecords':sum(n-1 for n in geometry_counts.values()),
            'joinDiagnostics':diagnostics,'scan':dict(counts),'comparison':metrics(errors),'tiles':tiles,
            'inputs':{str(p.relative_to(ROOT)):sha(p) for p in [directory/'osm.json',directory/'building-heights.json',directory/'manifest.json']}}
    (work/(area+'-joins.json')).write_text(json.dumps({'internalOnly':True,'approvedRungs':[],'exportEnabled':False,'records':records},indent=2)+'\n')
    result['localJoinSHA256']=sha(work/(area+'-joins.json'))
    return result


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--areas',nargs='+',required=True);args=parser.parse_args()
    work=ROOT/'Generated/ms-height-experiment'
    for name in ['CDLA-Permissive-2.0.txt','provider-LICENSE','provider-README.md']:assert (work/name).is_file()
    report={'internalOnly':True,'approvedRungs':[],'exportEnabled':False,'release':'2026-08-13',
       'providerCommit':json.loads((work/'provider-commit.json').read_text())['sha'],
       'catalogueURL':'https://bfppub.blob.core.windows.net/%24web/2026-08-13/dataset-links.csv',
       'evidenceHashes':{p.name:sha(p) for p in [work/'dataset-links.csv',work/'provider-README.md',work/'provider-LICENSE',work/'CDLA-Permissive-2.0.txt']},
       'scriptSHA256':sha(__file__),'joinRule':'Local WGS84 tangent-plane metres; IoU >=0.70; exactly one eligible candidate on both sides; no geometry adjustments or height-based choices.',
       'heightRule':'Finite numeric height >0 metres; -1 and all other invalid/nonpositive values missing.',
       'reference':'Existing accepted grade-D USGS roof_top_agl_m (p95 roof minus same-survey ground); not independent ground truth. Microsoft modelled average AGL has a different statistic and epoch.',
       'thresholdsUnapproved':{'medianAbsoluteM':1,'p90AbsoluteM':3,'absoluteMeanBiasM':.5},'areas':[]}
    for area in args.areas:
        result=run(area,work);report['areas'].append(result);print(json.dumps(result),flush=True)
    (work/'report.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')

if __name__=='__main__':main()
