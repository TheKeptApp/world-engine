"""Offline controls for rights boundaries and spatial evidence ambiguity."""
import importlib.util
import struct
import unittest
from pathlib import Path

def module(name):
 p=Path(__file__).with_name(name+'.py');s=importlib.util.spec_from_file_location(name,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
analysis=module('analyze');pull=module('pull')

class Controls(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.ns,_=analysis.a8_library();cls.contains=staticmethod(cls.ns['contains'])
  cls.outer=[(0,0),(10,0),(10,10),(0,10)]
  cls.host={'b':[(cls.outer,[])]}
 def test_hole_does_not_host_place(self):
  hole=[(3,3),(7,3),(7,7),(3,7)]
  self.assertFalse(self.contains((5,5),[(self.outer,[hole])]))
  self.assertTrue(self.contains((1,1),[(self.outer,[hole])]))
 def test_two_overlapping_hosts_remain_two(self):
  hosts=[g for g in [self.host['b'],self.host['b']] if self.contains((1,1),g)]
  self.assertEqual(len(hosts),2)
 def test_same_host_point_is_use_evidence_not_identity(self):
  f={'families':{'restaurant'},'bucket':'P','p':(9,9),'g':None}
  self.assertTrue(analysis.corroboration((1,1),'restaurant',self.host,{'b':set()},[f],self.contains,1))
 def test_neighbour_point_threshold_and_different_category(self):
  f={'families':{'cafe'},'bucket':'P','p':(15,0),'g':None}
  self.assertTrue(analysis.corroboration((0,0),'cafe',{}, {},[f],self.contains,15))
  self.assertFalse(analysis.corroboration((-.01,0),'cafe',{}, {},[f],self.contains,15))
  self.assertFalse(analysis.corroboration((0,0),'clinic',{}, {},[f],self.contains,15))
 def test_taxonomy_ancestors_not_unrelated_alternates(self):
  t={'primary':'pizza_restaurant','hierarchy':['restaurant','pizza_restaurant'],'alternates':['school']}
  self.assertEqual(analysis.places_families(t,{'restaurant':['restaurant'],'school':['school']}),{'restaurant'})
 def test_nested_null_contact_fields_not_counted_present(self):
  self.assertFalse(analysis.present({'names':{'primary':None},'wikidata':None}))
  self.assertFalse(analysis.present([{'freeform':None}]))
  self.assertTrue(analysis.present({'confidence':0}))
 def test_wkb_byte_orders_and_reject_polygon(self):
  for bo,prefix in [(1,'<'),(0,'>')]:
   self.assertEqual(analysis.point_wkb(bytes([bo])+struct.pack(prefix+'Idd',1,-105,39)),(-105,39))
  with self.assertRaises(ValueError):analysis.point_wkb(b'\x01'+struct.pack('<I',3))
 def test_unknown_and_conflicting_grants_stop(self):
  for src in [{'dataset':'unknown','license':'CDLA-Permissive-2.0'}, {'dataset':'meta','license':'proprietary'}, {'dataset':'Overture-signals'}]:
   with self.assertRaises(RuntimeError):pull.validate_sources([([src],)])
 def test_internal_property_grants_explicit(self):
  pull.validate_sources([([{'dataset':'Overture','license':'CDLA-Permissive-2.0','property':'/properties/confidence'}, {'dataset':'Foursquare','license':'Apache-2.0'}],)])
  with self.assertRaises(RuntimeError):pull.validate_sources([(None,)])

if __name__=='__main__':unittest.main()
