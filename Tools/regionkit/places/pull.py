#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["duckdb==1.5.6"]
# ///
"""Report-only bounded Places intake; never registers an engine/package source.

Run with uv run --script. Sources/licences are checked before writing raw rows;
unknown providers fail closed. No latest-release substitution or network retries.
"""
import argparse, datetime, hashlib, json, math, os, shutil, ssl, time
import urllib.request
from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parents[3]
UA = 'WorldEngine-A1-Places-research/1.0'
PROVIDERS = {'meta': 'CDLA-Permissive-2.0', 'Microsoft': 'CDLA-Permissive-2.0',
             'PinMeTo': 'CDLA-Permissive-2.0', 'Krick': 'CDLA-Permissive-2.0',
             'RenderSEO': 'CDLA-Permissive-2.0', 'DAC': 'CDLA-Permissive-2.0',
             'BrightQuery': 'CDLA-Permissive-2.0', 'Foursquare': 'Apache-2.0',
             'AllThePlaces': 'CC0-1.0', 'Overture': 'CDLA-Permissive-2.0',
             'Overture-signals': 'CDLA-Permissive-2.0'}
DOCUMENTS = {
 'attribution.html': 'https://docs.overturemaps.org/attribution/',
 'CDLA-Permissive-2.0.txt': 'https://raw.githubusercontent.com/Community-Data-License-Agreements/Releases/main/CDLA-Permissive-2.0.txt',
 'Apache-2.0.txt': 'https://www.apache.org/licenses/LICENSE-2.0.txt',
 'Foursquare-NOTICE.html': 'https://opensource.foursquare.com/places-notice-txt/',
 'CC0-1.0.html': 'https://creativecommons.org/publicdomain/zero/1.0/legalcode.en',
 'taxonomy.csv': 'https://docs.overturemaps.org/taxonomy/2026-09-23.0/taxonomy.csv',
}

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p, j): p.write_text(json.dumps(j, indent=2, sort_keys=True)+'\n')
def disk_guard():
 if shutil.disk_usage(ROOT).free < 8 * 10**9: raise RuntimeError('Disk guard: fewer than 8 GB free')
def download(url, path):
 if path.exists():
  data=path.read_bytes()
  return {'url':url,'path':str(path.relative_to(ROOT)),'bytes':len(data),'sha256':sha(path)}
 req=urllib.request.Request(url,headers={'User-Agent':UA})
 with urllib.request.urlopen(req,timeout=120,context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')) as r:
  data=r.read()
 path.write_bytes(data)
 return {'url':url, 'path':str(path.relative_to(ROOT)), 'bytes':len(data),'sha256':sha(path)}
def box_for(m):
 lat=m['center']['latitude'];lon=m['center']['longitude'];f=1/298.257223563;e2=f*(2-f)
 q=1-e2*math.sin(math.radians(lat))**2
 mer=6378137*(1-e2)/q**1.5;prime=6378137/q**.5
 dy=math.degrees((m['heightMeters']/2+2)/mer)
 dx=math.degrees((m['widthMeters']/2+2)/(prime*math.cos(math.radians(lat))))
 return dict(south=lat-dy,north=lat+dy,west=lon-dx,east=lon+dx)
def meets(x,b): return x[0]<=b['east'] and x[2]>=b['west'] and x[1]<=b['north'] and x[3]>=b['south']
def sql_quote(s): return "'"+str(s).replace("'","''")+"'"

def validate_sources(rows):
 unknown=sorted({s.get('dataset','') for row in rows for s in row[0] or [] if s.get('dataset') not in PROVIDERS})
 if unknown:raise RuntimeError('Unverified providers; no raw rows saved: '+str(unknown))
 for row in rows:
  if not row[0]:raise RuntimeError('No source declaration; no raw rows saved')
  for s in row[0]:
   grant=s.get('license');dataset=s['dataset']
   if (dataset in {'Overture','Overture-signals'} and not grant) or (grant and grant != PROVIDERS[dataset]):
    raise RuntimeError('Missing internal or conflicting per-record grant; no raw rows saved')

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--release',required=True);ap.add_argument('--areas',nargs='+',required=True)
 ap.add_argument('--resume',action='store_true',help='Reuse retained metadata after a stopped intake; never overwrite raw files')
 ap.add_argument('--extent-config',type=Path);ap.add_argument('--output',type=Path,required=True)
 args=ap.parse_args();disk_guard()
 out=args.output.resolve();out.mkdir(parents=True,exist_ok=args.resume)
 metadata=out/'metadata';metadata.mkdir(exist_ok=args.resume)
 docs={k:download(u,metadata/k) for k,u in DOCUMENTS.items()}
 attr=(metadata/'attribution.html').read_text()
 for provider in PROVIDERS:
  if provider not in {'Overture','Overture-signals'} and provider.lower() not in attr.lower():raise RuntimeError('Provider absent from retained register: '+provider)
 url=f'https://stac.overturemaps.org/{args.release}/places/place/collection.json'
 docs['collection.json']=download(url,metadata/'collection.json');coll=json.loads((metadata/'collection.json').read_text())
 if coll['id']!='place' or coll['license']!='other':raise RuntimeError('Unexpected collection/licence: review before intake')
 boxes=coll['extent']['spatial']['bbox'][1:];items=[x['href'] for x in coll['links'] if x['rel']=='item']
 if len(items)!=len(boxes):raise RuntimeError('Unaligned STAC item boxes')
 configured={x['id']:x['bounds'] for x in json.loads(args.extent_config.read_text())['areas']} if args.extent_config else {}
 con=duckdb.connect(config={'custom_user_agent':UA,'threads':2,'memory_limit':'1GB'})
 cache=ROOT/'.local/overture-places-duckdb';cache.mkdir(parents=True,exist_ok=True)
 con.execute('SET extension_directory = ?',[str(cache)])
 con.execute('INSTALL httpfs');con.execute('LOAD httpfs');con.execute("CALL enable_logging('HTTP')")
 result={'format':'worldengine-places-intake/1','release':args.release,'fetchedUTC':datetime.datetime.now(datetime.timezone.utc).isoformat(),
         'sourceLicenceColour':'GREEN for scoped internal intake only','exportEnabled':False,'registeredInAreaManifest':False,
         'duckdbVersion':duckdb.__version__,'providerLicences':PROVIDERS,'documents':docs,'areas':[]}
 for area in args.areas:
  disk_guard();start=time.monotonic();path=ROOT/'Data/areas'/area;m=json.loads((path/'manifest.json').read_text());b=configured.get(area,box_for(m))
  files=[];selected=[]
  for i,(box,href) in enumerate(zip(boxes,items)):
   if not meets(box,b):continue
   ip=metadata/f'item-{i}.json'
   docs[ip.name]=download(href,ip)
   item=json.loads(ip.read_text())
   if meets(item['bbox'],b):files.append(item['assets']['aws']['href']);selected.append(ip.name)
  if not files:raise RuntimeError('No STAC files for '+area)
  fs='['+','.join(sql_quote(u) for u in sorted(files))+']'
  where=f"bbox.xmin <= {b['east']!r} AND bbox.xmax >= {b['west']!r} AND bbox.ymin <= {b['north']!r} AND bbox.ymax >= {b['south']!r}"
  select=f'SELECT * FROM read_parquet({fs}) WHERE {where}'
  sources=con.execute(f'SELECT sources FROM ({select})').fetchall()
  validate_sources(sources)
  dest=out/area;dest.mkdir()
  sql=select+' ORDER BY id';(dest/'query.sql').write_text(sql+';\n')
  raw=dest/'places.parquet'
  con.execute(f'COPY ({sql}) TO {sql_quote(raw)} (FORMAT PARQUET, COMPRESSION ZSTD)')
  n=con.execute('SELECT count(*) FROM read_parquet(?)',[str(raw)]).fetchone()[0]
  result['areas'].append({'area':area,'queryBounds':b,'selection':'requested geographic rectangle' if area in configured else '2 m padded geographic query, exact manifest local rectangle in analysis',
   'manifestSHA256':sha(path/'manifest.json'),'files':sorted(files),'STACItems':selected,'rows':n,'rawPath':str(raw.relative_to(ROOT)),
   'rawBytes':raw.stat().st_size,'rawSHA256':sha(raw),'querySHA256':sha(dest/'query.sql'),'seconds':round(time.monotonic()-start,3)})
  write(out/'intake.json',result)
  print(area+': '+str(n)+' bounded raw rows; provider rights checked',flush=True)
 write(out/'intake.json',result)
if __name__=='__main__':main()
