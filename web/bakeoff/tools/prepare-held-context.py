"""Stage existing GREEN OSM context sources; no fetches or shipping manifest edits.
Rights: docs/data/context-coverage-check.md §4 and A11 inventory OSM core row.
General selection: existing context source whose declared box contains the target
core plus 500 m, smallest box then path. Preserve actual bounds, not a new 3 km claim.
"""
import hashlib,json,math,os,sys
from pathlib import Path
root=Path(__file__).resolve().parents[3]
report=[]
for area in sys.argv[1:]:
    target=root/'Data/areas'/area
    m=json.loads((target/'manifest.json').read_text());b=m['approvedBounds']
    dy=500/111320;dx=dy/math.cos(math.radians(m['center']['latitude']))
    needed=dict(south=b['south']-dy,north=b['north']+dy,west=b['west']-dx,east=b['east']+dx)
    choices=[]
    for f in sorted((root/'Data/areas').glob('*/manifest.json')):
        for s in json.loads(f.read_text())['sources']:
            if s['format']!='osm-overpass-json' or s['layers']!=['context'] or s['license']!='ODbL-1.0':continue
            c=s['bounds'];p=(f.parent/s['path']).resolve()
            if not all(c[k]<=needed[k] for k in ['south','west']) or not all(c[k]>=needed[k] for k in ['north','east']):continue
            data=p.read_bytes()
            if hashlib.sha256(data).hexdigest()!=s['sha256'] or len(data)!=s['bytes']:raise ValueError('Source hash mismatch: '+str(p))
            choices.append(((c['north']-c['south'])*(c['east']-c['west']),str(p),s))
    row=dict(area=area,requiredBounds=needed)
    stage_file=root/'Generated/context-held'/area/'manifest.json'
    if stage_file.exists():stage_file.unlink() # this helper's generated staging manifest only
    if not choices:
        row.update(status='blocked-missing-held-context',reason='No held context extract contains core plus 500 m; core OSM and DEM do not establish wider map coverage.')
    else:
        _,path,s=sorted(choices,key=lambda c:c[:2])[0]
        dest=root/'Generated/context-held'/area;dest.mkdir(parents=True,exist_ok=True)
        staged=json.loads(json.dumps(m));staged['sources']=[dict(s,path=os.path.relpath(path,dest))]
        (dest/'manifest.json').write_text(json.dumps(staged,indent=2)+'\n')
        row.update(status='staged',source=str(Path(path).relative_to(root)),sha256=s['sha256'],bytes=s['bytes'],bounds=s['bounds'],license=s['license'],attribution=s['attribution'],stage=str(dest.relative_to(root)),limitation='Original category-specific selection envelopes remain; no complete building band or full 3 km ring around target claimed.')
    report.append(row)
out=root/'web/bakeoff/evidence/context-holdouts/source-audit.json';out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
