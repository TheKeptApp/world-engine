import pathlib,json,hashlib,re,itertools,xml.etree.ElementTree as ET
p=pathlib.Path(__file__).resolve().parent;r=json.loads((p/'specs.json').read_text())['variants'];m=json.loads((p/'image-manifest.json').read_text())['variants'];assert len(r)==len(m)==23
assert len({x['id'] for x in r})==23;assert sum(len(x['views']) for x in r)==62
assert {f:sum(x['family']==f for x in r) for f in {x['family'] for x in r}}==dict(parking=4,soccer=2,baseball=2,court=2,track=2,playground=4,bridge=4,station=3)
assert {x['region'] for x in r}=={'Colorado Front Range','Chicago north shore','Southeast'}
for x in r:
 assert 1<=x['commonness_heuristic']<=10 and x['pick_rule'] and x['archetype']
 assert all(re.fullmatch('#[0-9A-F]{6}',c) for c in x['colours'].values())
 assert (p/'prompts'/f"{x['id']}.txt").read_text().strip()==x['prompt']
 if 'top' in x['views']:ET.parse(p/'plans'/f"{x['id']}.svg")
for x in m:
 b=(p/x['file']).read_bytes();assert b[:8]==b'\x89PNG\r\n\x1a\n';assert len(b)==x['bytes'];assert hashlib.sha256(b).hexdigest()==x['sha256']
assert len(list((p/'plans').glob('*.svg')))==16
for a,b in itertools.combinations(r,2):assert a['layout']!=b['layout'] or a['colours']!=b['colours']
assert sum(s.startswith('| ') and ' / ' in s for s in (p/'sameness.md').read_text().splitlines())==253
print('PASS:23 variants;62 image panels declared;23 matching PNG hashes;16 valid SVG plans;253 pair checks;all required specs/prompts/regions present')
