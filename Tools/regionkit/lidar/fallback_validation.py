#!/usr/bin/env python3
"""Compare unselected inferred candidates with observed heights; never edits observations/exports."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path
import numpy as np
import shapely
import laspy
from scipy.spatial import cKDTree
import observed_heights as O


def number(v):
    if isinstance(v,bool): return None
    try: v=float(v)
    except (ValueError,TypeError): return None
    return v if math.isfinite(v) and v>0 else None


def metrics(errors, minimum=5):
    a=np.asarray(errors,dtype=float)
    if len(a)<minimum:return {'n':len(a),'medianAbsoluteM':None,'p90AbsoluteM':None,'meanBiasM':None,'medianBiasM':None,'status':'INSUFFICIENT_SAMPLE'}
    return {'n':len(a),'medianAbsoluteM':float(np.median(abs(a))),'p90AbsoluteM':float(np.percentile(abs(a),90)),'meanBiasM':float(np.mean(a)),'medianBiasM':float(np.median(a)),'status':'REVIEW_REQUIRED'}


def levels_candidate(tags, floor_m):
    levels=number(tags.get('building:levels'))
    if levels is None:return None,None,'missing_levels'
    wall=levels*floor_m
    roof=number(tags.get('roof:height'))
    if tags.get('roof:height') in ('0','0.0'):roof=0.
    if roof is None and 'roof:height' not in tags and tags.get('roof:shape')=='flat':roof=0.
    return (wall+roof if roof is not None else None),wall,('explicit_roof_height_or_flat' if roof is not None else 'missing_roof_height')


def dsm_candidate(poly, points, ground_tree, ground, cfg):
    er=poly.buffer(-cfg['erosionM'])
    if er.is_empty:return None,'empty_erosion'
    p=points[shapely.contains_xy(er,points[:,0],points[:,1])]
    if len(p)<cfg['minimumSurfacePoints']:return None,'few_surface_points'
    keys=np.floor(p[:,:2]/cfg['cellM']).astype(int)
    uniq,inv=np.unique(keys,axis=0,return_inverse=True)
    z=np.array([np.percentile(p[inv==i,2],95) for i in range(len(uniq))])
    xy=(uniq+.5)*cfg['cellM'];dist,idx=ground_tree.query(xy,k=cfg['groundNeighbours'],distance_upper_bound=cfg['groundRadiusM'])
    valid=np.isfinite(dist);weights=np.where(valid,1/np.maximum(dist,.05)**2,0);safe=np.minimum(idx,len(ground)-1);den=weights.sum(axis=1)
    dtm=np.divide((ground[safe,2]*weights).sum(axis=1),den,out=np.full(len(z),np.nan),where=den>0)
    support=(valid.sum(axis=1)>=cfg['minimumGroundNeighbours'])&np.isfinite(dtm)
    if support.sum()*cfg['cellM']**2/er.area<cfg['minimumCoverage']:return None,'insufficient_surface_or_ground_coverage'
    h=float(np.percentile(z[support]-dtm[support],95))
    return (h,'candidate_unvalidated_canopy') if h>0 else (None,'nonpositive')


def read_survey(work,area,man):
    surface=[];ground=[];vegetation=[]
    for path in sorted(Path(work.p('laz',area)).glob('*.laz')):
        O.disk_guard(O.REPO);las=laspy.read(path);lon,lat=O.RP.merc_to_lonlat(np.asarray(las.x),np.asarray(las.y));x,y=O.RP.local_en(man['center']['latitude'],man['center']['longitude'],lat,lon);cls=np.asarray(las.classification)
        take=(abs(x)<=man['widthMeters']/2+25)&(abs(y)<=man['heightMeters']/2+25)
        for dest,classes in [(surface,[1,3,4,5,6]),(ground,[2]),(vegetation,[3,4,5])]:
            mask=take&np.isin(cls,classes);dest.append(np.column_stack((x[mask],y[mask],np.asarray(las.z)[mask])))
    return tuple(np.concatenate(p) if p else np.empty((0,3)) for p in [surface,ground,vegetation])


def overture_matches(root,man,fps,cfg):
    path=root/'overture-buildings.json'
    if not path.exists():return {},{'status':'MISSING_SOURCE'}
    d=json.loads(path.read_text())
    if d.get('license')!='ODbL-1.0':raise ValueError('Overture licence not allowlisted')
    # Only explicit height-property lineage; do not infer height provenance from geometry.
    allowed=set(cfg['greenHeightDatasets']);rows=[];polys=[]
    for r in d['buildings']:
        src=[s.get('dataset') for s in r.get('sources',[]) if s.get('property')=='/properties/height']
        if number(r.get('height')) is None or len(set(src))!=1 or src[0] not in allowed:continue
        p=O.H.record_polygon(r,man['center']['latitude'],man['center']['longitude'])
        if p is None or p.is_empty or not p.is_valid:continue
        rows.append({**r,'heightDataset':src[0]});polys.append(p)
    if not rows:return {},{'status':'NO_VERIFIED_HEIGHT_LINEAGE','release':d['release']}
    tree=shapely.STRtree(polys);matched={};used=Counter()
    for ref,fp in fps.items():
        p=fp['poly'];candidates=[]
        for i in tree.query(p):
            q=polys[i];iou=p.intersection(q).area/p.union(q).area
            if iou>=cfg['matchMinimumIoU']:candidates.append((int(i),iou))
        if len(candidates)==1:matched[ref]=candidates[0];used[candidates[0][0]]+=1
    out={ref:{'height':rows[i]['height'],'id':rows[i]['id'],'heightDataset':rows[i]['heightDataset'],'iou':iou} for ref,(i,iou) in matched.items() if used[i]==1}
    return out,{'status':'EXPLICIT_PROPERTY_PROVENANCE_ONLY','release':d['release'],'eligibleRecords':len(rows),'sourceSHA256':O.sha(path),'sameSurveyIndependence':'USGS Lidar lineage may reuse reference survey; acquisition identity unavailable; not independent validation'}


def run(area, work_dir, output):
    O.require_heavy_lock();O.disk_guard(O.REPO)
    cfg=json.loads((O.HERE/'data/fallback-validation.json').read_text());root=O.REPO/'Data/areas'/area
    obs=json.loads((root/'building-heights.json').read_text());man=json.loads((root/'manifest.json').read_text())
    if obs['source']['licenseStatus']!='GREEN' or not obs['source']['groundAndRoofSameSurvey']:raise ValueError('GREEN same-survey reference required')
    if obs['footprints']['sha256']!=O.sha(root/'osm.json'):raise ValueError('Stale reference footprints')
    work=O.S.Work(work_dir);plan=json.loads(Path(work.p('plan',area+'.json')).read_text())
    if not plan.get('fullDensity') or plan['ept']!=obs['source']['eptRoot']:raise ValueError('Wrong or partial survey cache')
    fps,_=O.L.footprints({'area':'Data/areas/'+area},man);surface,ground,veg=read_survey(work,area,man)
    if not len(ground):raise ValueError('No ground returns')
    si=O.L.PointIndex(surface);vi=O.L.PointIndex(veg) if len(veg) else None;gt=cKDTree(ground[:,:2]);matches,provenance=overture_matches(root,man,fps,cfg)
    records={};rungs=['dsm_dtm','overture','osm_levels_roof'];errors={r:{'all':[],'overhang':[],'noOverhang':[]} for r in rungs};wall=[]
    for ref,h in obs['records'].items():
        reference=h['roof_top_agl_m']
        if reference is None:continue
        poly=fps[ref]['poly'];sp=surface[si.query(poly.bounds)];vp=veg[vi.query(poly.bounds)] if vi else veg
        vp=vp[shapely.contains_xy(poly,vp[:,0],vp[:,1])] if len(vp) else vp
        total=int(shapely.contains_xy(poly,sp[:,0],sp[:,1]).sum());overhang=len(vp)>=cfg['overhangMinimumVegetationPoints'] and len(vp)/max(total,1)>=cfg['overhangMinimumShare']
        dh,reason=dsm_candidate(poly,sp,gt,ground,cfg['dsm']);lh,wh,lr=levels_candidate(fps[ref]['tags'],cfg['floorHeightM'])
        values={'dsm_dtm':dh,'overture':matches.get(ref,{}).get('height'),'osm_levels_roof':lh}
        records[ref]={'referenceObservedM':reference,'treeOverhangProxy':overhang,'vegetationPoints':len(vp),'inferredCandidatesM':values,'reasons':{'dsm_dtm':reason,'osm_levels_roof':lr},'overtureMatch':matches.get(ref),'evidenceCode':'inferred','qualityGrade':'D','selectedRung':None,'exportEligible':False}
        if wh is not None:wall.append(wh-reference)
        for rung,v in values.items():
            if v is not None:
                err=v-reference;errors[rung]['all'].append(err);errors[rung]['overhang' if overhang else 'noOverhang'].append(err)
    report={'format':'worldengine-fallback-validation/1','area':area,'configuration':cfg,'referenceSHA256':O.sha(root/'building-heights.json'),'osmSHA256':O.sha(root/'osm.json'),'referenceCount':len(records),'treeOverhangProxyCount':sum(r['treeOverhangProxy'] for r in records.values()),'overtureProvenance':provenance,'metrics':{r:{g:metrics(e) for g,e in groups.items()} for r,groups in errors.items()},'wallOnlyDiagnosticNotRoofHeight':metrics(wall),'limitations':['Reference heights are uncalibrated grade D, not ground truth.','DSM and reference share lidar acquisition; USGS Overture may also share it.','Tree-overhang stratum is classified vegetation overlapping footprint, not manual confirmation.','Each rung is evaluated independently on observed buildings; selection bias versus observed-null buildings remains.','No candidate selected or exported; canopy contamination must pass the acceptance gate before use.'],'approvedRungs':[],'records':records}
    Path(output).parent.mkdir(parents=True,exist_ok=True);Path(output).write_text(json.dumps(report,indent=2,allow_nan=False)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='records'}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--area',required=True);p.add_argument('--work',required=True);p.add_argument('--output',required=True);a=p.parse_args();run(a.area,a.work,a.output)
