"""Report actual all-pass counts; never infer phone FPS from desktop timings."""
import json, pathlib, hashlib
P=pathlib.Path(__file__).resolve().parent
result={}
for scene in ['sloans','lakeview']:
 result[scene]={}
 for tier in ['hero','standard','floor']:
  directory=P/'evidence'/('candidate' if tier=='standard' else 'candidate-'+tier)
  m=json.loads((directory/(scene+'.json')).read_text()); c=m['cost']; passes=c['passes']
  totals={phase:{k:sum(v[k] for name,v in passes.items() if name.startswith(phase+'/')) for k in ['triangles','draws']} for phase in ['main','shadow','post']}
  assert sum(v['triangles'] for v in totals.values())==m['triangles'], 'unaccounted triangles'
  assert sum(v['draws'] for v in totals.values())==m['drawCalls'], 'unaccounted draws'
  assert c['unknownAllocations']==0, 'unknown texture allocation formats'
  floor=totals['main']['triangles']<=400000 and totals['main']['draws']<=100 and totals['shadow']['triangles']<=150000
  result[scene][tier]={'passes':totals,'allPassTriangles':m['triangles'],'allPassDraws':m['drawCalls'],'contentTextureMiB':c['contentTextureMiB'],'targetTextureMiB':c['targetTextureMiB'],'renderbufferMiB':c['renderbufferMiB'],'floorGeometryGate':'PASS' if floor else 'FAIL','tierBudget':'floor contract' if tier=='floor' else 'not filed','textureBudget':'not filed','gpuTiming':'not measured on phone','laptopFPS':m['fps'],'inputSha256':m['inputSha256'],'pngSha256':hashlib.sha256((directory/(scene+'.png')).read_bytes()).hexdigest()}
 assert len({r['inputSha256'] for r in result[scene].values()})==1
 assert len({r['pngSha256'] for r in result[scene].values()})==1, 'tiers unexpectedly change appearance'
(P/'evidence/phone-budget.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
