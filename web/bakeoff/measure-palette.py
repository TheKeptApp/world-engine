"""Read captured PNGs only; no rendering/scoring. Diagnosis §3 eligible pixels, CIELAB D65."""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
from PIL import Image

def measure(path):
    rgb8 = np.asarray(Image.open(path).convert('RGB'))[32:, :, :]
    srgb = rgb8.astype(np.float64) / 255
    rgb = np.where(srgb <= .04045, srgb / 12.92, ((srgb + .055) / 1.055)**2.4)
    # Undo the fixed contrast/saturation and invert the unchanged luminance curve,
    # solely to reject samples outside the diagnosis's reversible domain.
    u = (rgb - .5) / 1.06 + .5
    y = u @ np.array([.2126, .7152, .0722])
    m = y[..., None] + (u - y[..., None]) / 1.08
    a, b, c = 1 - .983729*y, .0245786 - .432951*y, -.000090537 - .238081*y
    x = (-b + np.sqrt(np.maximum(0, b*b-4*a*c))) / (2*a)
    with np.errstate(divide='ignore', invalid='ignore'):
        source = m * (.6*x/1.2745606273192622/ y)[..., None]
    eligible = ((rgb8 > 1) & (rgb8 < 254)).all(axis=2) & (source >= 0).all(axis=2) & np.isfinite(source).all(axis=2)
    xyz = rgb @ np.array([[.4124564,.3575761,.1804375],[.2126729,.7151522,.0721750],[.0193339,.1191920,.9503041]]).T / np.array([.95047,1,1.08883])
    delta = 6/29
    f = np.where(xyz > delta**3, np.cbrt(xyz), xyz/(3*delta**2)+4/29)
    light = 116*f[...,1]-16
    chroma = np.hypot(500*(f[...,0]-f[...,1]),200*(f[...,1]-f[...,2]))
    return {'meanL':float(light[eligible].mean()), 'meanC':float(chroma[eligible].mean()), 'eligiblePixels':int(eligible.sum()), 'worldPixels':int(eligible.size), 'eligibleShare':float(eligible.mean())}

if __name__ == '__main__':
    ap=argparse.ArgumentParser();ap.add_argument('runs',nargs='+');ap.add_argument('--output',required=True);args=ap.parse_args()
    root=Path(__file__).resolve().parents[2]
    result={'method':'docs/execution/palette-diagnosis.md §3; exclude top 32 rows; every RGB8 channel >1 and <254; reconstructed source nonnegative; mean per-pixel Lab D65 L*/C*. Eligibility recomputed per frame; no score.', 'frames':[]}
    for run in (Path(p).resolve() for p in args.runs):
        report=json.loads((run/'web-capture.json').read_text())
        assert report['status']=='passed',run
        for row in report['frames']:
            frame=run/row['frame']; digest=hashlib.sha256(frame.read_bytes()).hexdigest(); assert digest==row['sha256']
            result['frames'].append({'frame':str(frame.relative_to(root)), 'sha256':digest,'scene':row['scene'],'paletteB':row.get('paletteB','absent'),'crownV3':row.get('crownV3',False),'repeat':row['repeat'],'metrics':measure(frame),'cost':row['metrics']['cost']['passes'],'camera':row['metrics']['camera'],'exposure':row['exposure'],'paletteBReport':row.get('paletteBReport'), 'captureReport':str((run/'web-capture.json').relative_to(root))})
    Path(args.output).write_text(json.dumps(result,indent=2)+'\n')
