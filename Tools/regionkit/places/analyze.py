#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["duckdb==1.5.6"]
# ///
"""Offline aggregate Places report, reusing the exact reviewed A8 census.

No engine, manifest, estimator or package mutation. No names/contact values in
output. Containment means source geometry, not verified tenancy or identity.
"""
import argparse, ast, collections, hashlib, json, math, re, struct, sys
from pathlib import Path
import duckdb

ROOT=Path(__file__).resolve().parents[3]
CENSUS_SHA='af6e859f99ebf6303d1f7eea773b0f54a05fb9aab1a2c9799bc33c447ff9615a'
EXTENSION_SHA='2080693dbe61e0fdc2f38f82794855694adb6c2b1ffdb14c602fc36a92a36057'
BASELINE_AREAS=['sloans-lake','lakeview-sheil-park','wilmette-vattmann-park','west-highland','greenville-downtown']
BASELINE_EXPECTED={'restaurant':[8,17,0,10,89],'bar':[2,7,0,0,28],'cafe':[1,5,0,4,22],
 'clinic':[3,2,0,4,7],'school':[0,0,4,2,6],'hardware':[0,0,0,0,0],'gas':[0,1,2,0,1]}

def sha_bytes(x):return hashlib.sha256(x).hexdigest()
def sha(p):return sha_bytes(p.read_bytes())
def a8_library():
 doc=ROOT/'docs/data/landmark-classification.md';blocks=re.findall(r'```python\n(.*?)\n```',doc.read_text(),re.S)
 if [sha_bytes(c.encode()) for c in blocks] != [CENSUS_SHA,EXTENSION_SHA]:raise RuntimeError('Reviewed A8 census changed; review before running')
 ns={'__name__':'places_a8_library'};saved=sys.argv;sys.argv=['a8',str(ROOT/'Data/areas'),'source']
 captured={}
 try:
  code=blocks[0].replace(" return {'area':name,", " capture(name, locals())\n return {'area':name,")
  ns['capture']=lambda name,values:captured.__setitem__(name,values)
  exec(compile(code,str(doc)+'#section8','exec'),ns)
 finally:sys.argv=saved
 ns['original']=ns['classes']
 # Only the reviewed extension's predicate definition; none of its scratch I/O.
 tree=ast.parse(blocks[1]);func=next(x for x in tree.body if isinstance(x,ast.FunctionDef) and x.name=='classes')
 exec(compile(ast.Module(body=[func],type_ignores=[]),str(doc)+'#section9','exec'),ns)
 ns['TYPES']+=['restaurant','bar','cafe','ice-cream','pizza','salon','hardware','grocery','gas','big-box','hotel','office','apartment','parking-lot','sports-field','playground','bridge','water-tower','cell-tower','substation','clubhouse','communication-mast']
 return ns,captured

def point_wkb(blob):
 bo='<' if blob[0]==1 else '>';kind=struct.unpack_from(bo+'I',blob,1)[0];offset=5
 if kind&0x20000000:offset+=4
 if (kind&0xffff)%1000!=1:raise ValueError('Places geometry is not Point')
 return struct.unpack_from(bo+'dd',blob,offset)
def totals(r):return {c:sum(v.get(k,0) for k in ('B','P','S','L')) for c,v in r['counts'].items()}
def osm_families(tags,classes):
 out=classes(tags)-{'worship'}
 if 'worship' in classes(tags):
  b=tags.get('building');relig=tags.get('religion')
  if b in {'church','chapel','cathedral'} or relig=='christian':out.add('church')
  elif b=='synagogue' or relig=='jewish':out.add('synagogue')
  elif b=='mosque' or relig=='muslim':out.add('mosque')
 return out

def places_families(taxonomy,crosswalk):
 tokens=set((taxonomy or {}).get('hierarchy') or [])
 if (taxonomy or {}).get('primary'):tokens.add(taxonomy['primary'])
 return {f for f,vs in crosswalk.items() if tokens & set(vs)}
def corroboration(point,family,hosts,building_classes,features,contains,radius):
 if any(family in building_classes[k] for k in hosts):return True
 # Any explicitly tagged OSM point in the same host supplies coarse use evidence.
 for f in features:
  if family not in f['families']:continue
  if f['g'] and contains(point,f['g']):return True
  if f['bucket']=='P' and f['p']:
   if math.dist(point,f['p'])<=radius:return True
   if any(contains(f['p'],g) for _,g in hosts.items()):return True
 return False

def present(v):
 if isinstance(v,dict):return any(present(x) for x in v.values())
 if isinstance(v,(list,tuple)):return any(present(x) for x in v)
 return v is not None and v != ''
def analyze(area,intake,ns,captured,config):
 a8=ns['run'](area['area']);v=captured[area['area']];m=v['m'];xy=v['xy'];contains=ns['contains']
 raw=ROOT/area['rawPath']
 if sha(raw)!=area['rawSHA256']:raise RuntimeError('Raw hash mismatch')
 if sha(ROOT/'Data/areas'/area['area']/'manifest.json')!=area['manifestSHA256']:raise RuntimeError('Manifest changed since intake')
 con=duckdb.connect(config={'threads':2,'memory_limit':'1GB'});cur=con.execute('SELECT * FROM read_parquet(?) ORDER BY id',[str(raw)])
 schema=[{'name':d[0],'type':str(d[1])} for d in cur.description];columns=[x['name'] for x in schema]
 rows=[dict(zip(columns,row)) for row in cur.fetchall()]
 features=[]
 for f in v['features']:
  families=osm_families(f['t'],ns['classes'])
  if families:features.append(dict(f,families=families))
 buildings=v['buildings'];bg={k:b['g'] for k,b in buildings.items()}
 bounds={k:ns['bounds'](g) for k,g in bg.items()}
 bc={k:osm_families(b['t'],ns['classes']) if b['source']=='OSM' else set() for k,b in buildings.items()}
 counts=collections.Counter();presence=collections.Counter();sources=collections.Counter();licenses=collections.Counter();source_properties=collections.Counter();status=collections.Counter();enrich=collections.Counter();hits_count=collections.Counter();hosts_used=set();point_positions=collections.Counter();catfamilies=collections.defaultdict(collections.Counter);accepted=[];low=0
 configured_bounds=area['queryBounds'] if area['selection']=='requested geographic rectangle' else None
 for r in rows:
  lon,lat=point_wkb(bytes(r['geometry']));p=xy((lon,lat))
  keep=(configured_bounds['west']<=lon<=configured_bounds['east'] and configured_bounds['south']<=lat<=configured_bounds['north']) if configured_bounds else v['core'](p)
  if not keep:continue
  accepted.append(r['id']);point_positions[(lon,lat)]+=1
  tax=r.get('taxonomy') or {};category=tax.get('primary') or '(missing)';counts[category]+=1
  for field in columns:presence[field]+=present(r[field])
  status[r.get('operating_status') or '(null)']+=1
  if r.get('confidence') is not None and r['confidence']<.5:low+=1
  for src in r.get('sources') or []:
   sources[src.get('dataset')]+=1;licenses[src.get('license') or '(null)']+=1
   source_properties[(src.get('dataset'),src.get('license'),src.get('property'))]+=1
  hs={k:bg[k] for k,b in bounds.items() if b[0]<=p[0]<=b[2] and b[1]<=p[1]<=b[3] and contains(p,bg[k])}
  hits_count['insideAnyFootprint' if hs else 'outsideFootprints']+=1
  if len(hs)==1:hits_count['uniqueFootprint']+=1
  elif hs:hits_count['multipleFootprints']+=1
  if any(buildings[k]['source']=='OSM' for k in hs):hits_count['insideOSMFootprint']+=1
  if any(buildings[k]['source']=='Overture' for k in hs):hits_count['insideHeldOvertureFootprint']+=1
  hosts_used.update(hs)
  families=places_families(tax,config['families'])
  if not families:enrich['unmappedCategoryPlaces']+=1;continue
  enrich['mappedCategoryPlaces']+=1;novel=set()
  for family in families:
   catfamilies[family]['places']+=1
   found=corroboration(p,family,hs,bc,features,contains,config['pointCorroborationMetres'])
   if found:catfamilies[family]['OSMCorroborated']+=1
   else:
    novel.add(family);catfamilies[family]['additionalCategoryCandidates']+=1
    if len(hs)==1:catfamilies[family]['additionalInUniqueFootprint']+=1
   if hs:catfamilies[family]['insideAnyFootprint']+=1
  if novel:
   enrich['additionalCategoryCandidates']+=1
   if len(hs)==1:enrich['additionalInUniqueFootprint']+=1
   elif hs:enrich['additionalInAmbiguousFootprint']+=1
   else:enrich['additionalOutsideFootprints']+=1
  else:enrich['allMappedFamiliesOSMCorroborated']+=1
 duplicate_ids=len(accepted)-len(set(accepted))
 if duplicate_ids:raise RuntimeError('Duplicate GERS IDs in bounded release extract')
 a8counts=totals(a8);a8counts.update(a8['worship_subtypes'])
 for family,co in catfamilies.items():
  co['A8OSMTaggedRecordsSameExtent']=a8counts.get(family,0)
  if a8counts.get(family,0)==0:enrich['placesInOSMAbsentFamilies']+=co['places']
 # Above family sum may overlap; retain union as separate metric.
 absent={f for f in config['families'] if a8counts.get(f,0)==0}
 union_absent=sum(bool(places_families(r.get('taxonomy'),config['families'])&absent) for r in rows if r['id'] in set(accepted))
 result={'area':area['area'],'places':len(accepted),'rawQueryRows':len(rows),'outsideCoreExcluded':len(rows)-len(accepted),
  'sourceHashes':a8['hashes'],'coreFootprints':len(buildings),'osmFootprints':a8['osm_buildings'],'heldOvertureFootprints':a8['overture_buildings'],
  'footprintAssociation':dict(hits_count),'uniqueHostFootprints':len(hosts_used),'duplicateGERSIDs':duplicate_ids,
  'coincidentPointGroups':sum(n>1 for n in point_positions.values()),'placesAtCoincidentPoints':sum(n for n in point_positions.values() if n>1),
  'top15PrimaryCategories':[{'category':k,'places':n} for k,n in sorted(((k,n) for k,n in counts.items() if k!='(missing)'),key=lambda t:(-t[1],t[0]))[:15]],
  'allPrimaryCategories':dict(sorted(counts.items())),'enrichment':dict(enrich),'placesInOSMAbsentFamiliesUnion':union_absent,
  'crosswalk':{f:dict(c) for f,c in sorted(catfamilies.items())},'A8TaggedRecordCountsSameExtent':a8counts,
  'fieldSchema':schema,'fieldNonEmptyCounts':dict(presence),'providerOccurrences':dict(sources),'declaredLicenseOccurrences':dict(licenses),
  'sourcePropertyOccurrences':[{'dataset':d,'license':l,'property':p,'occurrences':n} for (d,l,p),n in sorted(source_properties.items(),key=lambda t:str(t[0]))],
  'operatingStatus':dict(status),'confidenceBelow0_5':low,'rawPath':area['rawPath'],'rawBytes':area['rawBytes'],'rawSHA256':area['rawSHA256'],
  'fetchSeconds':area['seconds'],'queryBounds':area['queryBounds'],'geometryMissing':a8['geometry_missing'],'conflictingOSMDuplicates':a8['tag_conflicts']}
 return result

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--intake',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
 j=json.loads(args.intake.read_text());config=json.loads((Path(__file__).with_name('crosswalk.json')).read_text());ns,captured=a8_library()
 baseline=[ns['run'](a) for a in BASELINE_AREAS]
 vectors={c:[totals(r)[c] for r in baseline] for c in BASELINE_EXPECTED}
 if vectors!=BASELINE_EXPECTED:raise RuntimeError('A8 baseline counts changed: '+str(vectors))
 output={'format':'worldengine-places-coverage/1','release':j['release'],'fetchedUTC':j['fetchedUTC'],'internalOnly':True,'exportEnabled':False,
  'intakeSHA256':sha(args.intake),'censusSHA256':CENSUS_SHA,'censusExtensionSHA256':EXTENSION_SHA,
  'crosswalkSHA256':sha(Path(__file__).with_name('crosswalk.json')),'baselineVectorsVerified':vectors,
  'baseline':[{'area':r['area'],'sourceHashes':r['hashes'],'counts':totals(r),'worshipSubtypes':r['worship_subtypes']} for r in baseline],
  'method':'A8 source census; primary+hierarchy whitelist; unsnapped point-in-footprint; OSM corroboration from host outline, same-host point, containing tagged polygon, or same-family point <=15m. Tenant identity/true novelty unverified.',
  'areas':[analyze(a,j,ns,captured,config) for a in j['areas']]}
 args.output.write_text(json.dumps(output,sort_keys=True,indent=2)+'\n')
 for a in output['areas']:print(a['area'],a['places'],a['footprintAssociation'],a['enrichment'])
if __name__=='__main__':main()
