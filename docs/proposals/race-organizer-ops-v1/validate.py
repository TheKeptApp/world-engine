import json,math,pathlib
p=pathlib.Path(__file__).parent
def check(v,s,path="$"):
    t=s.get("type")
    ok={"object":lambda:isinstance(v,dict),"array":lambda:isinstance(v,list),"string":lambda:isinstance(v,str),"integer":lambda:isinstance(v,int) and not isinstance(v,bool),"null":lambda:v is None}
    if t: assert ok[t](),(path,t)
    if "const" in s: assert v==s["const"],path
    if "enum" in s: assert v in s["enum"],path
    if isinstance(v,dict):
        assert all(k in v for k in s.get("required",[])),path
        for k,z in s.get("properties",{}).items():
            if k in v: check(v[k],z,path+"."+k)
    if isinstance(v,list):
        assert len(v)>=s.get("minItems",0) and len(v)<=s.get("maxItems",float("inf")),path
        for i,z in enumerate(v): check(z,s.get("items",{}),path+"["+str(i)+"]")
    if isinstance(v,int) and "minimum" in s: assert v>=s["minimum"],path
for f in p.rglob("*.json"): json.loads(f.read_text())
r=json.loads((p/"rules.json").read_text())
schema=json.loads((p/"rules.schema.json").read_text())
check(r,schema)
ids=[x["id"] for x in r["rules"]]; assert len(ids)==len(set(ids))
known={x["id"] for x in json.loads((p/"sources.json").read_text())}
assert all(set(x["sourceIds"])<=known for x in r["rules"])
for x in r["sizeProfiles"]:
    assert sum(x["toiletClusters"])==x["toilets"]
    assert sum(max(1,math.ceil(z*.05)) for z in x["toiletClusters"])==x["accessibleToilets"]
    assert x["toilets"]==math.ceil(x["runners"]/50)
    assert x["waveCount"]==math.ceil(x["runners"]/x["waveRunners"])
    assert x["waveIntervalSeconds"]>=x["waveTimingCheckSeconds"]
assert r["heat"]["approvedThresholdsC"] is None
assert r["heat"]["autonomousGoNoGo"] is False
manifest=json.loads((p/"image-manifest.json").read_text())
assert len(manifest["images"])==6
for x in manifest["images"]:
    assert (p/x["file"]).is_file() and (p/x["file"]).stat().st_size>10000
for x in json.loads((p/"layouts.json").read_text())["layouts"]:
    assert x["routeGeometry"] is None
    assert set(x["sources"])<=known
    assert all((p/z).is_file() for z in x["images"])
print("PASS: all JSON parsed; schema keyword checks; source references, toilet cluster rounding, wave timing, six assets, and pending heat/route gates.")
