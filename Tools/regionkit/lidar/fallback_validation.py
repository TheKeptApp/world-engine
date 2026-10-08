#!/usr/bin/env python3
"""Compare unselected inferred candidates with observed heights; never edits observations/exports."""
import argparse
import hashlib
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


def thinning_mask(node, count, fraction):
    """Stable point identity: fixed namespace + EPT node key + zero-based record index.

    SplitMix64 uses unsigned wraparound; selection ignores class, geometry, height,
    area and processing order. The same fraction thins ground and surface alike.
    """
    if not math.isfinite(fraction) or not 0 < fraction <= 1:
        raise ValueError('Retention fraction must be in (0,1]')
    if fraction == 1:return np.ones(count,dtype=bool)
    seed=int.from_bytes(hashlib.sha256(('worldengine-density-thinning-v1:'+node).encode()).digest()[:8],'little')
    with np.errstate(over='ignore'):
        z=np.arange(count,dtype=np.uint64)+np.uint64(seed)+np.uint64(0x9e3779b97f4a7c15)
        z=(z^(z>>30))*np.uint64(0xbf58476d1ce4e5b9)
        z=(z^(z>>27))*np.uint64(0x94d049bb133111eb)
        z=z^(z>>31)
    return (z>>11).astype(np.float64)*(1./9007199254740992.) < fraction


def read_survey(work,area,man,fraction=1.):
    surface=[];ground=[];vegetation=[];nonnoise=[];before=Counter();after=Counter();files=[]
    for path in sorted(Path(work.p('laz',area)).glob('*.laz')):
        O.disk_guard(O.REPO);las=laspy.read(path);lon,lat=O.RP.merc_to_lonlat(np.asarray(las.x),np.asarray(las.y));x,y=O.RP.local_en(man['center']['latitude'],man['center']['longitude'],lat,lon);cls=np.asarray(las.classification)
        take=(abs(x)<=man['widthMeters']/2+25)&(abs(y)<=man['heightMeters']/2+25)
        keep=thinning_mask(path.stem,len(las.points),fraction)
        for counts,mask in [(before,take),(after,take&keep)]:
            for c,n in zip(*np.unique(cls[mask],return_counts=True)):counts[int(c)]+=int(n)
        take &= keep
        for dest,classes in [(surface,[1,3,4,5,6]),(ground,[2]),(vegetation,[3,4,5])]:
            mask=take&np.isin(cls,classes);dest.append(np.column_stack((x[mask],y[mask],np.asarray(las.z)[mask])))
        mask=take&~np.isin(cls,[7,18]);nonnoise.append(np.column_stack((x[mask],y[mask])))
        files.append({'node':path.stem,'sha256':O.sha(path),'records':len(las.points)})
    arrays=tuple(np.concatenate(p) if p else np.empty((0,3)) for p in [surface,ground,vegetation])
    return (*arrays,np.concatenate(nonnoise),{'beforeClassCounts':dict(before),'afterClassCounts':dict(after),'sourceNodes':files})


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


def run(area, work_dir, output, target_density=None, source_density=None, baseline=None):
    O.require_heavy_lock();O.disk_guard(O.REPO)
    cfg=json.loads((O.HERE/'data/fallback-validation.json').read_text());root=O.REPO/'Data/areas'/area
    obs=json.loads((root/'building-heights.json').read_text());man=json.loads((root/'manifest.json').read_text())
    if obs['source']['licenseStatus']!='GREEN' or not obs['source']['groundAndRoofSameSurvey']:raise ValueError('GREEN same-survey reference required')
    if obs['footprints']['sha256']!=O.sha(root/'osm.json'):raise ValueError('Stale reference footprints')
    work=O.S.Work(work_dir);plan=json.loads(Path(work.p('plan',area+'.json')).read_text())
    if not plan.get('fullDensity') or plan['ept']!=obs['source']['eptRoot']:raise ValueError('Wrong or partial survey cache')
    fraction=1.;base=None
    if target_density is not None:
        if number(source_density) is None or number(target_density) is None or target_density>source_density or not baseline:
            raise ValueError('Thinning needs positive target <= source density and a frozen full-density baseline')
        fraction=target_density/source_density;base=json.loads(Path(baseline).read_text())
        if base.get('sampling',{}).get('retentionFraction',1.) != 1.:raise ValueError('Baseline must be full density')
        if base['referenceSHA256']!=O.sha(root/'building-heights.json') or base['osmSHA256']!=O.sha(root/'osm.json') or base['configuration']!=cfg:
            raise ValueError('Reference, footprints and rung settings must match full-density baseline')
        expected={ref for ref,h in obs['records'].items() if h['roof_top_agl_m'] is not None}
        if set(base['records'])!=expected:raise ValueError('Baseline population mismatch')
        if any(base['records'][ref]['referenceObservedM']!=obs['records'][ref]['roof_top_agl_m'] for ref in expected):raise ValueError('Baseline reference values differ')
    elif source_density is not None or baseline is not None:raise ValueError('Partial thinning arguments')
    fps,_=O.L.footprints({'area':'Data/areas/'+area},man);surface,ground,veg,raw,sampling=read_survey(work,area,man,fraction)
    ri=O.L.PointIndex(raw);densities=[];observed_densities=[]
    for ref in obs['records']:
        poly=fps[ref]['poly'];points=raw[ri.query(poly.bounds)]
        density=float(shapely.contains_xy(poly,points[:,0],points[:,1]).sum()/poly.area);densities.append(density)
        if obs['records'][ref]['roof_top_agl_m'] is not None:observed_densities.append(density)
    sampling.update({'retentionFraction':fraction,'targetFootprintMedianReturnsM2':target_density,'sourceFootprintMedianReturnsM2':source_density,'achievedFootprintMedianReturnsM2':float(np.median(densities)),'achievedObservedFootprintMedianReturnsM2':float(np.median(observed_densities)),
                     'baselineSHA256':O.sha(baseline) if baseline else None,'rule':'SHA256 namespace worldengine-density-thinning-v1 + EPT node key seeds SplitMix64 on zero-based LAZ record index; retain high-53-bit uniform < fraction; identical thinning for all classes',
                     'strata':'Frozen full-density vegetation-overlap labels' if base else 'Full-density vegetation-overlap labels'})
    if not len(ground):raise ValueError('No ground returns')
    si=O.L.PointIndex(surface);vi=O.L.PointIndex(veg) if len(veg) else None;gt=cKDTree(ground[:,:2]);matches,provenance=overture_matches(root,man,fps,cfg)
    records={};rungs=['dsm_dtm','overture','osm_levels_roof'];errors={r:{'all':[],'overhang':[],'noOverhang':[]} for r in rungs};wall=[]
    for ref,h in obs['records'].items():
        reference=h['roof_top_agl_m']
        if reference is None:continue
        poly=fps[ref]['poly'];sp=surface[si.query(poly.bounds)];vp=veg[vi.query(poly.bounds)] if vi else veg
        vp=vp[shapely.contains_xy(poly,vp[:,0],vp[:,1])] if len(vp) else vp
        total=int(shapely.contains_xy(poly,sp[:,0],sp[:,1]).sum());overhang=len(vp)>=cfg['overhangMinimumVegetationPoints'] and len(vp)/max(total,1)>=cfg['overhangMinimumShare']
        if base:overhang=base['records'][ref]['treeOverhangProxy']
        dh,reason=dsm_candidate(poly,sp,gt,ground,cfg['dsm']);lh,wh,lr=levels_candidate(fps[ref]['tags'],cfg['floorHeightM'])
        values={'dsm_dtm':dh,'overture':matches.get(ref,{}).get('height'),'osm_levels_roof':lh}
        records[ref]={'referenceObservedM':reference,'treeOverhangProxy':overhang,'vegetationPoints':len(vp),'inferredCandidatesM':values,'reasons':{'dsm_dtm':reason,'osm_levels_roof':lr},'overtureMatch':matches.get(ref),'evidenceCode':'inferred','qualityGrade':'D','selectedRung':None,'exportEligible':False}
        if wh is not None:wall.append(wh-reference)
        for rung,v in values.items():
            if v is not None:
                err=v-reference;errors[rung]['all'].append(err);errors[rung]['overhang' if overhang else 'noOverhang'].append(err)
    report={'format':'worldengine-fallback-validation/1','area':area,'configuration':cfg,'referenceSHA256':O.sha(root/'building-heights.json'),'osmSHA256':O.sha(root/'osm.json'),'referenceCount':len(records),'treeOverhangProxyCount':sum(r['treeOverhangProxy'] for r in records.values()),'sampling':sampling,'overtureProvenance':provenance,'metrics':{r:{g:metrics(e) for g,e in groups.items()} for r,groups in errors.items()},'wallOnlyDiagnosticNotRoofHeight':metrics(wall),'limitations':['Reference heights are uncalibrated grade D, not ground truth.','DSM and reference share lidar acquisition; USGS Overture may also share it.','Tree-overhang stratum is classified vegetation overlapping footprint, not manual confirmation.','Each rung is evaluated independently on observed buildings; selection bias versus observed-null buildings remains.','No candidate selected or exported; canopy contamination must pass the acceptance gate before use.'],'approvedRungs':[],'records':records}
    populations={'all':len(records),'overhang':report['treeOverhangProxyCount'],'noOverhang':len(records)-report['treeOverhangProxyCount']}
    for groups in report['metrics'].values():
        for group,m in groups.items():
            m['eligiblePopulation']=populations[group];m['nullCount']=populations[group]-m['n'];m['nullRate']=m['nullCount']/populations[group] if populations[group] else None
    if base:
        report['limitations']+=['Random thinning does not recreate Denver scan geometry, occlusion, leaf state or class-1 classification.','Overture and OSM are unchanged external inputs: their sparse-run metrics are controls, not evidence of sparse-lidar robustness.','No rung averaging or bias correction; full-density reference heights and overlap labels frozen.']
    Path(output).parent.mkdir(parents=True,exist_ok=True);Path(output).write_text(json.dumps(report,indent=2,allow_nan=False)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='records'}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--area',required=True);p.add_argument('--work',required=True);p.add_argument('--output',required=True);p.add_argument('--target-density',type=float);p.add_argument('--source-density',type=float);p.add_argument('--baseline');a=p.parse_args();run(a.area,a.work,a.output,a.target_density,a.source_density,a.baseline)
