#!/usr/bin/env python3
"""Run the unmodified region_colours implementation on calibration-v2 boxes.
The upstream tool hard-codes old hero mocks. Redirect only its config read here;
never write Tools/lookloop, proposals or the established baseline.
"""
import contextlib, importlib.util, io, json, os, pathlib, statistics, sys
sys.dont_write_bytecode = True
from PIL import Image, ImageDraw
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parent.parent
ASSETS=pathlib.Path(os.environ.get('WORLDENGINE_ASSETS',ROOT))
sys.path.insert(0,str(ROOT/'Tools/lookloop'))
import region_colours as rc
import conformance as cf
frames={'sloans':'06-sloans','lakeview':'01-lakeview'}
config=json.load(open(ROOT/'Tools/lookloop/calibration-regions.json'))['frames']
views={}
for scene,frame in frames.items():
 regions={k:(v['box'] if isinstance(v,dict) else v) for k,v in config[frame]['regions'].items()}
 views[scene]={'mock':str(ASSETS/config[frame]['path']),'regions':regions}
# Inject the config read only; the original pixel extraction and dE implementation run unchanged.
original_open=open
def adapted_open(path,*args,**kwargs):
 if str(path)==str(ROOT/'Tools/lookloop/regions.json'):return io.StringIO(json.dumps({'views':views}))
 return original_open(path,*args,**kwargs)
rc.open=adapted_open
rc.RUNS=str(HERE/'evidence/runs')
for mode in ['baseline','candidate']:
 raw=HERE/'evidence/runs'/mode/'raw';raw.mkdir(parents=True,exist_ok=True)
 for scene in frames:
  source=HERE/'evidence'/mode/f'{scene}.png'
  Image.open(source).save(raw/f'{scene}.png')
sys.argv=['region_colours.py','candidate','baseline']
output=io.StringIO()
with contextlib.redirect_stdout(output):rc.main()
(HERE/'evidence/region-colours.txt').write_text(output.getvalue().rstrip()+'\n')
print(output.getvalue())
summary={}
means={}
for scene,view in views.items():
 candidate=Image.open(HERE/'evidence/candidate'/f'{scene}.png').convert('RGB')
 mock=Image.open(view['mock']).convert('RGB').resize(candidate.size)
 rows=[]
 for surface,box in view['regions'].items():
  a,b=rc.colour(candidate,box,surface),rc.colour(mock,box,surface)
  rows.append({'surface':surface,'box':box,'render':a,'mock':b,'deltaE76':cf.delta_e76(a,b) if a and b else None})
 summary[scene]=rows
 base=Image.open(HERE/'evidence/baseline'/f'{scene}.png').convert('RGB')
 baseline=[]
 for surface,box in view['regions'].items():
  a,b=rc.colour(base,box,surface),rc.colour(mock,box,surface)
  if a and b:baseline.append(cf.delta_e76(a,b))
 measured=[r['deltaE76'] for r in rows if r['deltaE76'] is not None]
 means[scene]={'meanFixedBoxDeltaE76':statistics.mean(measured),'existingViewerMeanDeltaE76':statistics.mean(baseline),'sampledRegions':len(measured),'totalRegions':len(rows)}
 prior_path=HERE/'evidence/previous-a2'/f'{scene}.png'
 if prior_path.exists():
  prior=Image.open(prior_path).convert('RGB'); prior_values=[]
  for surface,box in view['regions'].items():
   a,b=rc.colour(prior,box,surface),rc.colour(mock,box,surface)
   if a and b:prior_values.append(cf.delta_e76(a,b))
  means[scene]['previousA2MeanDeltaE76']=statistics.mean(prior_values)
  means[scene]['changeFromPreviousA2']=means[scene]['meanFixedBoxDeltaE76']-statistics.mean(prior_values)
 width,height=candidate.size
 sheet=Image.new('RGB',(width*2,height+35),'#19232a');sheet.paste(candidate,(0,35));sheet.paste(mock,(width,35));draw=ImageDraw.Draw(sheet);draw.text((10,10),scene+' · three.js',fill='white');draw.text((width+10,10),'Calibration v2 · mock',fill='white');sheet.save(HERE/'evidence'/f'{scene}-side-by-side.png')
(HERE/'evidence/scores.json').write_text(json.dumps(summary,indent=2)+'\n')
(HERE/'evidence/summary.json').write_text(json.dumps(means,indent=2)+'\n')
# compare_runs retains its frame-change control. No fabricated reviewer scores:
# null/ungraded fields deliberately leave art grades and parity unavailable.
for mode in ['baseline','candidate']:
 grades=HERE/'evidence/runs'/mode/'grades';grades.mkdir(parents=True,exist_ok=True)
 for scene in frames:
  (grades/f'{scene}.json').write_text(json.dumps({'status':'ungraded; numerical colour test only'}))
import compare_runs as cr
cr.RUNS=rc.RUNS
sys.argv=['compare_runs.py','baseline','candidate']
output=io.StringIO()
with contextlib.redirect_stdout(output):cr.main()
(HERE/'evidence/compare-runs.txt').write_text(output.getvalue().rstrip()+'\n')
print(output.getvalue())
