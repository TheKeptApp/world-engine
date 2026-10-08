#!/usr/bin/env python3
"""One small public-domain USGS 3DEP DEM window; output only in this lane.
Licence gate: USGS National Map terms verified 2026-10-07 (America/Denver).
No aerial image, personal data, credentials, or new package dependency.
"""
import datetime, hashlib, io, json, pathlib, urllib.parse, subprocess
from PIL import Image
HERE=pathlib.Path(__file__).resolve().parent
SERVICE='https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer'
TERMS='https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map'
BBOX=[-105.95,39.30,-105.02,40.20]
params={'bbox':','.join(map(str,BBOX)),'bboxSR':'4326','imageSR':'4326','size':'256,256','format':'tiff','pixelType':'F32','interpolation':'RSP_BilinearInterpolation','renderingRule':json.dumps({'rasterFunction':'None'}),'f':'image'}
url=SERVICE+'/exportImage?'+urllib.parse.urlencode(params)
notice={'licenceGate':'GREEN','licence':'US Government Public Domain','terms':TERMS,'credit':'Map services and data available from U.S. Geological Survey, National Geospatial Program.','service':SERVICE,'requestedBBoxWGS84':BBOX,'request':url,'modifications':'Resampled by USGS to a 256 x 256 height grid; rounded to 0.1 m for JSON. Far-view geometry only; not surveying precision.','snow':'No snow observation supplied; no invented snow mask.'}
(HERE/'data').mkdir(exist_ok=True)
(HERE/'data/terrain-source.json').write_text(json.dumps(notice,indent=2)+'\n')
raw=subprocess.run(['/usr/bin/curl','--fail','--silent','--show-error','--location','--max-time','90',url],check=True,capture_output=True).stdout
im=Image.open(io.BytesIO(raw))
if im.mode!='F':raise RuntimeError(f'Expected elevation F32, got {im.mode}; refusing a hillshade image')
scale=im.tag_v2[33550]; tie=im.tag_v2[33922]
actual_bbox=[tie[3],tie[4]-im.height*scale[1],tie[3]+im.width*scale[0],tie[4]]
values=[float(v) for v in im.getdata()]
if not all(0<v<5000 for v in values):raise RuntimeError('DEM has nodata or implausible heights')
notice.update({'actualBBoxWGS84':actual_bbox,'retrievedUTC':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sha256':hashlib.sha256(raw).hexdigest(),'width':im.width,'height':im.height,'elevationRangeM':[min(values),max(values)],'serviceVintage':'Service reports DEM data published through 2026-09-28; individual acquisition dates vary.'})
(HERE/'generated').mkdir(exist_ok=True);(HERE/'generated/front-range.tif').write_bytes(raw)
(HERE/'data/front-range.json').write_text(json.dumps({'bbox':actual_bbox,'width':im.width,'height':im.height,'heightsM':[round(v,1) for v in values],'rowOrder':'north to south','verticalDatum':'Service orthometric heights; no geoid-to-ellipsoid conversion. Relative height error remains unquantified.'},separators=(',',':'))+'\n')
(HERE/'data/terrain-source.json').write_text(json.dumps(notice,indent=2)+'\n')
print(json.dumps({'size':im.size,'mode':im.mode,'rangeM':notice['elevationRangeM'],'bytes':len(raw)}))
