"""Collect frozen captures, counters and per-frame tier checks; never assign scores."""
import json,hashlib,shutil,html
from pathlib import Path
root=Path(__file__).resolve().parents[3];dest=root/'web/bakeoff/evidence/context-holdouts'
runs=['/private/tmp/a5-context-holdouts-west-v1']+['/private/tmp/a5-context-holdouts-'+a+'-v1' for a in ['greenville-downtown','lakeview-sheil-park','wilmette-vattmann-park']]
shutil.copy2(Path.home()/'Desktop/world-engine/docs/proposals/look-fix-v1/images/aerial-01-continuation-clear.png',dest/'reference.png')
rows=[];panels=[];run_status=[]
for run in runs:
    run=Path(run);r=json.loads((run/'qualification.json').read_text());area=r['area'];out=dest/area;out.mkdir(exist_ok=True)
    shutil.copy2(run/'qualification.json',out/'qualification.json');run_status.append(dict(area=area,status=r['status'],error=r.get('error')))
    for f in r['frames']:
        p=Path(f['path']);assert hashlib.sha256(p.read_bytes()).hexdigest()==f['pngSha256'];shutil.copy2(p,out/p.name)
        m,s=f['main'],f['shadow'];row=dict(area=area,altitude=f['altitude'],mode=f['mode'],main=m,shadow=s,blankPercent=f['blank']['fraction']*100,diff=f.get('diff'),floor=m['triangles']<400000 and m['draws']<=100 and s['triangles']<=150000,standard=m['triangles']<=500000 and m['draws']<=120 and s['triangles']<=180000,png=str((out/p.name).relative_to(dest)),sha256=f['pngSha256'],context=f['metrics']['contextRing'])
        rows.append(row)
    for height in [40,150,600]:
        pair=[f for f in rows if f['area']==area and f['altitude']==height and f['mode'] in ['before','after']]
        panels.append('<section><h2>'+html.escape(area)+' · '+str(height)+' m</h2><div class="pair">'+''.join('<figure><figcaption>'+f['mode'].upper()+'</figcaption><img src="'+f['png']+'"></figure>' for f in pair)+'</div></section>')
(dest/'summary.json').write_text(json.dumps(dict(runs=run_status,rows=rows),indent=2)+'\n')
lines=['| Area | m | Mode | Blank % | Main tris / draws | Shadow tris / draws | Floor | Standard | Differing bytes / max |','|---|---:|---|---:|---:|---:|---|---|---:|']
for r in rows:
    if r['mode']=='repeat':continue
    d=r['diff'];lines.append(f"| {r['area']} | {r['altitude']} | {r['mode']} | {r['blankPercent']:.2f} | {r['main']['triangles']:,} / {r['main']['draws']} | {r['shadow']['triangles']:,} / {r['shadow']['draws']} | {'PASS' if r['floor'] else 'FAIL'} | {'PASS' if r['standard'] else 'FAIL'} | {str(d['differingBytes'])+' / '+str(d['max']) if d else '—'} |")
(dest/'results.md').write_text('# Matched hold-out results\n\n'+ '\n'.join(lines)+'\n\nRepeat controls and source hashes are in each qualification.json. Pass/fail here is counters only; not a minimum-device performance or visual pass.\n')
(dest/'review.html').write_text('<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><title>Context hold-outs paired frames</title><style>body{font:16px system-ui;margin:20px;background:#eee;color:#17382d}.pair{display:flex;flex-wrap:wrap;gap:16px}figure{margin:0;width:390px;max-width:100%}img{width:100%}section{margin:32px 0}</style><h1>Context hold-outs · paired review</h1><p>Fixed shader clock. OFF includes A10 stack; ON adds ring + water merge. No scores. Greenville source missing. Counter results are in results.md.</p>'+''.join(panels)+'<h2>Continuation reference · not matched composition</h2><figure><img src="reference.png"></figure>')
print('\n'.join(lines));print(run_status)
