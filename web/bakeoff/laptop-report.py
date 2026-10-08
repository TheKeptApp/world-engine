import json,pathlib
P=pathlib.Path(__file__).resolve().parent
rows=['# Laptop budget — overnight A2','', 'Measured in headed Chrome on the GPU named below, at the unchanged calibration portrait viewport. Warmed 2.5 s then sampled 10 s per capture (capture-once.mjs); frame intervals include scheduling/display pacing. GPU timer values are reported only when the browser exposes the extension. These are not phone timings or a thermal qualification.','', 'No separate laptop, hero or standard numeric allocations are filed. Reference floor limits are 400,000 main triangles, 150,000 shadow triangles, 100 main draws (R device-tier clarification; visual-v2 §8.1). Count every pass; texture allocation limit is unfiled.','', '| View | Frame mean / p95 ms | GPU mean / p95 ms | Main tri / draws | Shadow tri / draws | Post tri / draws | All tri / draws | Content / targets / MSAA MiB | Floor |','|---|---|---|---|---|---|---|---|---|']
all_data={}
for scene in ['sloans','lakeview']:
 m=json.load(open(P/'evidence/candidate'/f'{scene}.json'));c=m['cost'];passes=c['passes'];totals={phase:{k:sum(v[k] for name,v in passes.items() if name.startswith(phase+'/')) for k in ['triangles','draws']} for phase in ['main','shadow','post']}
 assert sum(v['triangles'] for v in totals.values())==m['triangles'];assert sum(v['draws'] for v in totals.values())==m['drawCalls'];assert c['unknownAllocations']==0
 ok=totals['main']['triangles']<=400000 and totals['main']['draws']<=100 and totals['shadow']['triangles']<=150000
 gpu=m.get('gpuTimer',{});gputime=f"{gpu['meanMs']:.2f} / {gpu['p95Ms']:.2f}" if gpu.get('meanMs') is not None else 'unavailable'
 pair=lambda p:f"{totals[p]['triangles']:,} / {totals[p]['draws']}"
 rows.append(f"| {scene} | {1000/m['fps']:.2f} / {m['p95FrameMs']:.2f} | {gputime} | {pair('main')} | {pair('shadow')} | {pair('post')} | {m['triangles']:,} / {m['drawCalls']} | {c['contentTextureMiB']:.2f} / {c['targetTextureMiB']:.2f} / {c['renderbufferMiB']:.2f} | {'PASS' if ok else 'FAIL'} |")
 all_data[scene]={**m,'totals':totals,'floorPass':ok}
rows+=['','GPU: '+all_data['sloans']['gpu']+'. Texture totals exclude the default framebuffer, driver padding and CPU copies (budget.js allocation ledger).','', '## Every active effect and measured pass cost','', '| Effect | Sloan main tri/draw; shadow tri/draw | Lakeview main tri/draw; shadow tri/draw | Resource / rule |','|---|---|---|---|']
for category,description in [('opaque world','Exported buildings, lawns, roads, walks, existing details, shrubs and props; shared matte key/fill + existing AO in these draws; palette 0.0039 MiB.'),('foliage','P2 species layouts + date-derived colours; shared instancing, no leaf textures.'),('tufts','Existing export grass accents; no shadow pass.'),('water','Lake gradient, normal ripples, Fresnel sky reflection and physical sun response in the same water draws; 2 MiB R16F shore field; shares sky texture.'),('facade details','Pack bays, stoops, cornices and eligible fences; courses/tones in opaque-world shader, no additional texture.'),('DEM','Real 3DEP mountain grid; contrast/size extinction gate in the same pass, no shadow draw.'),('sky/composite','32 MiB float procedural sky gradient/cumulus; shared single exposure/saturation/luminance curve in post (1 triangle/1 draw).')]:
 vals=[]
 for scene in all_data:
  passes=all_data[scene]['cost']['passes'];parts=[]
  for phase in ['main','shadow']:
   p=passes.get(phase+'/'+category,{'triangles':0,'draws':0});parts.append(f"{p['triangles']:,}/{p['draws']}")
  vals.append('; '.join(parts))
 rows.append(f'| {category} | {vals[0]} | {vals[1]} | {description} |')
rows+=['','Homogeneous airlight is a single material fog mix; DEM uses its one explicit gated mix and reflected sky bypasses re-fog. No extra haze pass. Soft shadow-map work is included above, with its allocation in the target texture ledger; MSAA is included separately. Per-effect GPU milliseconds are not measured.','', 'Laptop-only effects: none are selected by a laptop flag. All effects currently run on every named tier; portability is not phone qualification. Both floor views must satisfy all three geometry caps; failing shadows cannot be hidden by main-view headroom.','', 'Hero = iPhone 15 Pro+, standard = 14–15, floor = 12–13. Phone-budget JSON lists actual counts for all three, without invented hero/standard or texture ceilings.','', 'Sources: evidence/candidate/*.json, evidence/phone-budget.json, main.js, budget.js, data/p2-crowns.json, data/facade-values.json, data/facade-mechanics.json, and the pack-key table in OVERNIGHT-SOURCES.md.']
(P/'LAPTOP-BUDGET.md').write_text('\n'.join(rows)+'\n')
(P/'evidence/laptop-budget.json').write_text(json.dumps({s:{k:v for k,v in m.items() if k in ['fps','p95FrameMs','gpu','gpuTimer','viewport','totals','floorPass','triangles','drawCalls','inputSha256']} for s,m in all_data.items()},indent=2)+'\n')
print('\n'.join(rows[:11]))
