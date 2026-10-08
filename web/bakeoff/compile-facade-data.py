"""Compile export feature semantics and OSM rings; no scene/camera art decisions."""
import json,pathlib,math
root=pathlib.Path.cwd();out=root/'web/bakeoff/data';assets=pathlib.Path('/Users/robwoodbury/Desktop/world-engine')
for scene,area,export in [('sloans','sloans-lake',assets/'Generated/package/sloans-lake'),('lakeview','lakeview-sheil-park',root/'web/bakeoff/generated/lakeview-sheil-park')]:
 osm=json.load(open(root/'Data/areas'/area/'osm.json'))['elements'];nodes={e['id']:e for e in osm if e['type']=='node'};ways={str(e['id']):e for e in osm if e['type']=='way'}
 manifest=json.load(open(export/'world.json'));features=[];seen=set();fences=set()
 for chunk in manifest['chunks']:
  for f in json.load(open(export/chunk['scene']))['features']:
   if f['kind']=='generated-fence':fences.add(f['id'].removeprefix('gen:fence:'))
 for chunk in manifest['chunks']:
  for f in json.load(open(export/chunk['scene']))['features']:
   if f['kind']!='building' or f['id'] in seen or not f.get('generated',{}).get('family'):continue
   seen.add(f['id']);way=ways.get(f['id'].split('/')[-1]);
   if not way:continue
   ring=[[nodes[n]['lat'],nodes[n]['lon']] for n in way['nodes'][:-1] if n in nodes]
   if len(ring)<3:continue
   features.append({'id':f['id'],'ring':ring,'generated':f['generated'],'source':f.get('source',{}),'hasFence':f['id'] in fences})
 roads=[]
 for way in ways.values():
  if way.get('tags',{}).get('highway') not in ['residential','tertiary','secondary','primary','unclassified','living_street']:continue
  line=[[nodes[n]['lat'],nodes[n]['lon']] for n in way.get('nodes',[]) if n in nodes]
  if len(line)>1:roads.append(line)
 (out/f'{scene}-facades.json').write_text(json.dumps({'source':f'Data/areas/{area}/osm.json + export chunks/*/scene.json; OSM attribution retained.','features':features,'roads':roads},separators=(',',':'))+'\n')
 print(scene,len(features),'real footprints')
