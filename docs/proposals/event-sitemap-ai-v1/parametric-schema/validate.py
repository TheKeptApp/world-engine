"""Validate the 1.0.0 example contracts; jsonschema>=4.18 is required."""
import copy, hashlib, json, pathlib, sys
from jsonschema import Draft202012Validator, FormatChecker
ROOT=pathlib.Path(__file__).parent
SCHEMA=json.loads((ROOT/'kit.schema.json').read_text())
Draft202012Validator.check_schema(SCHEMA)
VALIDATOR=Draft202012Validator(SCHEMA,format_checker=FormatChecker())
def digest(instance):
 payload={k:instance[k] for k in ('instanceId','partId','partVersion','parameterValues','resolvedTransform')}
 return hashlib.sha256(json.dumps(payload,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def expr(e,values):
 if e['op']=='constant':return e['value']
 if e['op']=='parameter':return values[e['name']]
 xs=[expr(x,values) for x in e['args']]
 if e['op']=='add':return sum(xs)
 n=1
 for x in xs:n*=x
 return n
def require(ok,message):
 if not ok:raise ValueError(message)
def provenance(p,values=None,instance=None):
 ids=[s['id'] for s in p['sources']];require(len(ids)==len(set(ids)),'Duplicate source IDs')
 require(set(p['sourceIds'])<=set(ids),'Unknown source reference')
 for k,v in p['parameterOrigins'].items():require(v['sourceId'] in ids,'Unknown parameter source '+k)
 if values is not None:require(set(p['parameterOrigins'])==set(values),'Every parameter needs an origin')
 require(not p['aiMade'] or p['model'] is not None,'AI-made object needs model/licence provenance')
 if p['confidence']['basis']=='not_scored':require(p['confidence']['score'] is None,'Unscored confidence cannot contain a score')
 if p['confidence']['calibration']=='calibrated_on_named_dataset':require(p['confidence']['calibrationDataset'],'Calibrated confidence needs a named dataset')
 if p['method']=='ai_generated':require(p['aiMade'],'Generated object needs AI-made flag')
 events=p['approvalHistory'];prev=None;rev=0
 for e in events:
  require(e['previousEventId']==prev,'Broken approval chain')
  require(e['revision']>rev,'Approval revisions must increase')
  require(e['action'] in ['propose','reopen'] or e['actorRole']!='system','System cannot approve organizer changes')
  prev=e['id'];rev=e['revision']
 if p['approvalState']=='accepted':
  if p['aiMade']:require(p['model']['licenceReview']=='approved_for_scope','AI-made output licence remains unreviewed')
  require(events and events[-1]['action'] in ['accept','bulk_accept'],'Accepted state requires last human approval')
  if instance:require(events[-1]['subjectDigest']==digest(instance),'Approval stale after parameter/transform edit')
def part(p):
 fid=p['partId']; value_schema=SCHEMA['$defs']['values-'+fid]
 require(set(p['parameters'])==set(value_schema['properties']),'Part parameters must match family contract')
 defaults={k:v['default'] for k,v in p['parameters'].items()}
 Draft202012Validator(value_schema).validate(defaults)
 for k,definition in p['parameters'].items():
  contract=value_schema['properties'][k]
  if definition['type'] in ['number','integer']:
   require(definition['minimum']<=definition['default']<=definition['maximum'],'Default outside declared bounds')
   require(definition['minimum']>=contract['minimum'] and definition['maximum']<=contract['maximum'],'Metadata expands family bounds')
   require(definition['unit']==('count' if definition['type']=='integer' else 'kVA' if k=='ratedPower' else 'deg' if k=='swingDegrees' else 'm'),'Unexpected canonical unit')
  elif definition['type']=='enum':require(set(definition['choices'])<=set(contract['enum']) and definition['default'] in definition['choices'],'Enum metadata differs from contract')
 require({x['tier'] for x in p['detailTiers']}=={'footprint','balanced','close'} and len(p['detailTiers'])==3,'Unique three detail tiers required')
 require({x['kind'] for x in p['envelopes']}>={'footprint','clearance','queue','utility'},'Missing envelope kind')
 ids={s['id'] for s in p['provenance']['sources']}
 for x in p['presets']+p['supplierSizePresets']:
  Draft202012Validator(value_schema).validate(x['values']);require(x['sourceId'] in ids,'Unknown preset source')
  if x['verification']=='supplier_verified':require(x['supplierId'] and x['supplierSku'] and x['checkedAt'],'Verified supplier preset needs supplier, SKU, checked time')
  dimensions(p,x['values'])
 for m in p['materialSlots']:require(m['defaultColour'] in m['palette'],'Default outside approved palette')
 provenance(p['provenance'],defaults)
def dimensions(p,values):
 for e in p['envelopes']:
  for key in ['width','depth','height']:require(expr(e[key],values)>0,'Nonpositive envelope '+e['id'])
  for v in e['offset'].values():expr(v,values)
 for c in p['constraints']:
  if c['rule']=='manual_supplier_check':continue
  a=values[c['left']];b=values[c['right']] if isinstance(c['right'],str) else c['right']
  if c['rule'] in ['lte','parameter_count_lte']:require(a<=b,c['message'])
  elif c['rule']=='lt':require(a<b,c['message'])
  elif c['rule']=='gte':require(a>=b,c['message'])
def intent(i):
 require(i['resolution']!='resolved' or not i['ambiguities'],'Resolved intent has ambiguities')
 placement=i['normalizedPlacement'];orientation=placement['orientation']
 require(orientation['mode']!='bearing' or orientation['bearingDeg'] is not None,'Bearing missing')
 require(orientation['mode']!='face_anchor' or orientation['anchorId'] is not None,'Facing anchor missing')
 if placement['type']=='route_chainage':
  q=placement['originalQuantity'];factor={'m':1,'ft':.3048,'in':.0254,'km':1000,'mi':1609.344}
  require(q['unit'] in factor and abs(placement['chainageM']-q['value']*factor[q['unit']])<1e-6,'Chainage conversion mismatch')
 a=i['array']
 if a:
  require(a['endChainageM']>=a['startChainageM'],'Array end before start')
  if a['basis']=='route':require(a['routeId'] is not None,'Route array without route')
  length=a['endChainageM']-a['startChainageM'] if a['basis']=='route' else sum((a['end'][k]-a['start'][k])**2 for k in ['east','north','up'])**.5
  import math
  count=math.ceil(length/a['spacingM'])
  if a['endpointPolicy']=='exclude_both':count=max(0,count-1)
  if a['endpointPolicy']=='include_both_if_exact' and abs(length/a['spacingM']-round(length/a['spacingM']))<1e-9:count+=1
  require(count<=a['maxCount'],'Array exceeds maxCount')
def validate_document(doc,catalog):
 VALIDATOR.validate(doc)
 if doc['documentType']=='catalog':
  ids=[p['partId'] for p in doc['parts']];require(len(ids)==len(set(ids)),'Duplicate part family')
  for p in doc['parts']:part(p)
 elif doc['documentType']=='instanceSet':
  ids=[p['instanceId'] for p in doc['instances']];require(len(ids)==len(set(ids)),'Duplicate instances')
  for i in doc['instances']:
   p=catalog[i['partId']];dimensions(p,i['parameterValues']);intent(i['placementIntent']);provenance(i['provenance'],i['parameterValues'],i)
   require(set(i['materialOverrides'])<={m['slotId'] for m in p['materialSlots']},'Unknown material slot')
   for k,v in i['materialOverrides'].items():require(v in next(m['palette'] for m in p['materialSlots'] if m['slotId']==k),'Material outside palette')
   require(i['resolvedTransform']['sceneRevision']==doc['sceneRevision'],'Stale scene transform')
   if i['provenance']['approvalState']=='accepted':require(i['placementIntent']['resolution']=='resolved','Unresolved accepted object')
 else:
  for c in doc['commands']:dimensions(catalog[c['partId']],c['parameterValues']);intent(c['intent']);provenance(c['provenance'],c['parameterValues'])
def main():
 cat=json.loads((ROOT/'examples/catalog.json').read_text());catalog={p['partId']:p for p in cat['parts']}
 reports=[]
 for file in sorted((ROOT/'examples').glob('*.json')):
  validate_document(json.loads(file.read_text()),catalog);reports.append({'file':str(file.relative_to(ROOT)),'status':'passed'})
 original=json.loads((ROOT/'examples/instances.json').read_text());negative=[]
 def rejection(name,edit):
  bad=copy.deepcopy(original);edit(bad)
  try:validate_document(bad,catalog)
  except Exception:negative.append({'case':name,'status':'correctly_rejected'});return
  raise ValueError('Invalid case accepted: '+name)
 rejection('negative width',lambda d:d['instances'][0]['parameterValues'].update(width=-1))
 rejection('unknown parameter',lambda d:d['instances'][0]['parameterValues'].update(unrecognized=True))
 rejection('wrong count type',lambda d:d['instances'][2]['parameterValues'].update(cupCount=1.5))
 rejection('dependent clear width exceeds arch',lambda d:d['instances'][4]['parameterValues'].update(clearWidth=12,width=8.8))
 rejection('unapproved accepted state',lambda d:d['instances'][1]['provenance'].update(approvalState='accepted'))
 rejection('wrong mile conversion',lambda d:d['instances'][2]['placementIntent']['normalizedPlacement'].update(chainageM=2000))
 rejection('wrong schema version',lambda d:d.update(schemaVersion='2.0.0'))
 rejection('stale accepted transform',lambda d:d['instances'][0]['resolvedTransform']['position'].update(east=99))
 out={'schema':'Draft 2020-12','schemaVersion':'1.0.0','schemaMetaValidation':'passed','examples':reports,'negativeCases':negative,'limits':'Does not resolve actual map geometry, supplier certification, operational safety or measured accuracy.'}
 (ROOT/'validation-report.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
if __name__=='__main__':main()
