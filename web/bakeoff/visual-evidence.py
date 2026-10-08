"""A3 grades these captures; do not substitute a colour-distance score."""
import json, pathlib, os
from PIL import Image,ImageDraw
here=pathlib.Path(__file__).parent; root=here.parent.parent
assets=pathlib.Path(os.environ['WORLDENGINE_ASSETS'])
frames=json.load(open(root/'Tools/lookloop/calibration-regions.json'))['frames']
for scene,frame in [('sloans','06-sloans'),('lakeview','01-lakeview')]:
 after=Image.open(here/'evidence/candidate'/f'{scene}.png').convert('RGB')
 for other,label,suffix in [(Image.open(assets/frames[frame]['path']),'Calibration v2','side-by-side'),(Image.open(here/'evidence/shadow-colour/before'/f'{scene}.png'),'Before this round','before-after')]:
  w,h=after.size;sheet=Image.new('RGB',(2*w,h+32),'#19232a');sheet.paste(after,(0,32));sheet.paste(other.convert('RGB').resize(after.size),(w,32));d=ImageDraw.Draw(sheet);d.text((8,8),'A2 current - '+scene,fill='white');d.text((w+8,8),label,fill='white');sheet.save(here/'evidence/shadow-colour'/f'{scene}-{suffix}.png')
(here/'evidence/shadow-colour/grade.json').write_text(json.dumps({'grader':'A3','status':'pending visual review; no self-assigned grade','order':['sloans','lakeview'],'deltaE':'not used per R'},indent=2)+'\n')
