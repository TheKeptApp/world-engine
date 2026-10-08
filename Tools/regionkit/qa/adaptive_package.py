#!/usr/bin/env python3
"""Independently audit adaptive exports: all triangles/channels, scene joins and byte budgets."""
import argparse
from collections import Counter,defaultdict
import hashlib
import json
from pathlib import Path
import struct
import sys
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'lidar'))
import observed_heights as O


def glb(path):
    data=path.read_bytes();magic,version,size=struct.unpack_from('<III',data)
    assert (magic,version,size)==(0x46546c67,2,len(data))
    n,kind=struct.unpack_from('<II',data,12);assert kind==0x4e4f534a
    j=json.loads(data[20:20+n]);bn,bk=struct.unpack_from('<II',data,20+n);assert bk==0x004e4942 and 28+n+bn==len(data)
    binary=data[28+n:];sizes={'SCALAR':1,'VEC3':3,'VEC4':4};types={5123:('H',2),5125:('I',4),5126:('f',4)}
    def accessor(i):
        a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];fmt,scalar=types[a['componentType']];width=scalar*sizes[a['type']]
        assert not v.get('byteStride') and not a.get('sparse')
        start=v.get('byteOffset',0)+a.get('byteOffset',0);b=binary[start:start+a['count']*width];assert len(b)==a['count']*width
        return b,width,fmt
    signatures=Counter();decoded=0;maxpart=0;triangles=0;feature_values={};allbounds=[]
    for node in j['nodes']:
        origin=node.get('translation',[0,0,0])
        for p in j['meshes'][node['mesh']]['primitives']:
            attrs={k:accessor(v) for k,v in p['attributes'].items()};ib,_,iformat=accessor(p['indices']);indices=[v[0] for v in struct.iter_unpack('<'+iformat,ib)]
            material=j['materials'][p['material']];name=material['name'];partbytes=len(ib)+sum(len(v[0]) for v in attrs.values());decoded+=partbytes;maxpart=max(maxpart,partbytes)
            prefix=json.dumps([origin,material,[(k,attrs[k][1:]) for k in sorted(attrs)]],sort_keys=True).encode()
            vertices={i:b''.join(attrs[k][0][i*attrs[k][1]:(i+1)*attrs[k][1]] for k in sorted(attrs)) for i in set(indices)}
            for t in range(0,len(indices),3):signatures[hashlib.sha256(prefix+b''.join(vertices[i] for i in indices[t:t+3])).digest()]+=1
            triangles+=len(indices)//3
            fb,_,fmt=attrs['_FEATURE'];feature_values[name]=[v[0] for v in struct.iter_unpack('<'+fmt,fb)]
            pb,_,_=attrs['POSITION']
            allbounds.extend(tuple(pv[a]+origin[a] for a in range(3)) for pv in struct.iter_unpack('<fff',pb))
    return {'signatures':signatures,'decoded':decoded,'maxPart':maxpart,'triangles':triangles,'features':feature_values,'bytes':len(data),'points':allbounds}


def audit(source,packed):
    O.require_heavy_lock();O.disk_guard(packed)
    manifests=[json.loads((p/'world.json').read_text()) for p in [source,packed]]
    old,new=manifests;assert new['tilePacking']['sourceWorldSHA256']==O.sha(source/'world.json')
    budget=new['tilePacking'];before=defaultdict(Counter);after=defaultdict(Counter);summaries=[];parents={c['id']:c for c in old['chunks']}
    for root,man,dest in [(source,old,before),(packed,new,after)]:
        rows=[]
        for path,meta in man['files'].items():
            p=root/path;assert p.stat().st_size==meta['bytes'] and O.sha(p)==meta['sha256'],path
        for c in man['chunks']:
            parent=c.get('parentID',c['id']);scene=json.loads((root/c['scene']).read_text())
            if root==packed:
                orig_scene=json.loads((source/parents[parent]['scene']).read_text())
                strip=lambda f:{k:v for k,v in f.items() if not k.startswith('lod')}
                assert [strip(f) for f in scene['features']]==[strip(f) for f in orig_scene['features']]
            for lod,path in enumerate(c['lods']):
                m=glb(root/path);assert m['triangles']==c['triangles'][lod]
                dest[(parent,lod)].update(m['signatures'])
                for f in scene['features']:
                    for material,key in [('worldStatic','static'),('worldWater','water')]:
                        values=m['features'].get(material,[])
                        for start,count in f['lod'+str(lod)][key]:
                            assert len(values[start:start+count])==count and all(v==f['index'] for v in values[start:start+count])
                if root==packed:
                    assert (lod in c['emptyLODs'])==(m['triangles']==0)
                    assert m['decoded']==c['decodedBytes'][lod] and m['decoded']<=budget['twoTileDecodedQueueBytes']//2
                    assert m['bytes']<=budget['uploadBytes'] and m['maxPart']<=budget['uploadBytes']
                    for p in m['points']:assert all(c['bounds'][0][a]-1e-7<=p[a]<=c['bounds'][1][a]+1e-7 for a in range(3))
                rows.append({'id':c['id'],'lod':lod,'bytes':m['bytes'],'decoded':m['decoded'],'part':m['maxPart'],'triangles':m['triangles']})
        for lod in range(2):
            r=[v for v in rows if v['lod']==lod];decoded=sorted((v['decoded'] for v in r),reverse=True)
            summaries.append({'stage':'before' if root==source else 'after','lod':lod,'tiles':len(r),'triangles':sum(v['triangles'] for v in r),'maxGLBBytes':max(v['bytes'] for v in r),'maxDecodedPartBytes':max(v['part'] for v in r),'tilesOver2MiB':sum(v['part']>budget['uploadBytes'] for v in r),'worstTwoTileDecodedBytes':sum(decoded[:2]),'emptyTiles':sum(v['triangles']==0 for v in r)})
    assert before==after,'Triangle/material/channel/feature multiset changed'
    for path,meta in old['files'].items():
        if not path.startswith('chunks/'):assert new['files'][path]==meta,'Non-geometry file changed: '+path
    return {'area':old['area']['id'],'sourceWorldSHA256':O.sha(source/'world.json'),'packedWorldSHA256':O.sha(packed/'world.json'),'status':'PASS','triangleAttributeMultisetsIdentical':True,'sceneFeatureJoinsVerified':True,'appearanceFilesUnchanged':True,'metrics':summaries,'memoryScope':'Decoded attribute/index arrays only, not total CPU/GPU residency or frame time'}


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--packed',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    result=audit(a.source,a.packed);a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
