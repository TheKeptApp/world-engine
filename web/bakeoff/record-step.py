#!/usr/bin/env python3
"""Archive ordered capture evidence, compare the previous accepted step, append log.
Does not revert code: caller must restore their own step and recapture when rejected.
"""
import json,pathlib,shutil,sys
from PIL import Image,ImageDraw
root=pathlib.Path(__file__).resolve().parent
if root.name=='drafts':root=root.parents[2]
e=root/'evidence';stage,previous,note=sys.argv[1:4];dest=e/'overnight'/stage;dest.mkdir(parents=True,exist_ok=True)
summary=json.load(open(e/'summary.json'));prior=json.load(open(e/'overnight'/previous/'summary.json'))
scores={s:summary[s]['meanFixedBoxDeltaE76'] for s in ['sloans','lakeview']};delta={s:scores[s]-prior[s]['meanFixedBoxDeltaE76'] for s in scores};reject=delta['sloans']<0 and delta['lakeview']>0
for f in ['summary.json','scores.json','holdout-proof.json','region-colours.txt']:
 shutil.copyfile(e/f,dest/f)
for scene in scores:
 for ext in ['png','json']:shutil.copyfile(e/'candidate'/f'{scene}.{ext}',dest/f'{scene}.{ext}')
 shutil.copyfile(e/f'{scene}-side-by-side.png',dest/f'{scene}-mock.png')
 a=Image.open(e/'overnight'/previous/f'{scene}.png').convert('RGB');b=Image.open(dest/f'{scene}.png').convert('RGB');w,h=b.size;out=Image.new('RGB',(w*2,h+32),'#19232a');out.paste(a,(0,32));out.paste(b,(w,32));d=ImageDraw.Draw(out);d.text((8,8),f'{scene} | before {previous}',fill='white');d.text((w+8,8),f'after {stage}',fill='white');out.save(dest/f'{scene}-before-after.png')
with open(e/'overnight-log.md','a') as f:
 f.write(f'\n## {stage} — '+('REJECT; restore this step' if reject else 'ACCEPT')+'\n')
 f.write('Ordered capture: Sloan then Lakeview, frozen inputs. '+', '.join(f'{s} ΔE76 {scores[s]:.6f} ({delta[s]:+.6f})' for s in scores)+'.\n')
 f.write('Visual: '+note+'\n')
 f.write(f'Evidence: `overnight/{stage}/`; '+('Sloan improved while Lakeview worsened; user hold-out rollback rule triggered.' if reject else 'Hold-out rollback condition did not trigger.')+'\n')
print(json.dumps({'scores':scores,'delta':delta,'reject':reject}))
