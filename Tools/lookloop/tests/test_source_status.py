"""Source-driven report precedence; never changes compiled values or look policy."""
import io
import json
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'Tools/lookloop'))
sys.path.insert(0,str(ROOT/'scripts'))
import compile_mocks as cm
import push_guard as guard


class SourceStatusTests(unittest.TestCase):
    def fixture(self, root, status='**APPROVED by R — test decision.**'):
        pack=root/'docs/proposals/general-policy-v2'
        pack.mkdir(parents=True)
        (pack/'STATUS.md').write_text('# Status\n\n'+status+'\n')
        (pack/'values.json').write_text(json.dumps({
            'status':'historical pending', 'definition':{'convention':'source-defined'},
            'overrides':[{'pack':'old-pack','paths':['/surface/roughness','/states/*/background'],
                          'scope':'Replace background only; preserve local layers.'}]}))
        return pack

    def doc(self, key='old-pack/surface.roughness'):
        return {'conflicts':[{'parameter':'example','definitions':[
            {'pack':'old-pack','key':key,'value':0.8,'state':'day','source':'old.json'}]}]}

    def test_status_change_changes_output_without_changing_values(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); pack=self.fixture(root); doc=self.doc()
            original=json.dumps(doc,sort_keys=True)
            approved=cm.render_conflicts_md(doc,root)
            self.assertIn('Superseded field by approved general-policy-v2',approved)
            self.assertIn('preserve local layers',approved)
            (pack/'STATUS.md').write_text('# Status\n\n**Pending R approval.**\n')
            pending=cm.render_conflicts_md(doc,root)
            self.assertNotEqual(approved,pending)
            self.assertIn('pending (R decides)',pending)
            self.assertNotIn('Superseded field',pending)
            self.assertEqual(json.dumps(doc,sort_keys=True),original)

    def test_unapproved_and_body_mentions_do_not_approve(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td)
            pack=self.fixture(root,'**Rejected by R.**\n\nEarlier: R approved another version.')
            self.assertEqual(cm.approved_status_overrides(root),[])
            (pack/'STATUS.md').unlink()
            self.assertEqual(cm.approved_status_overrides(root),[])

    def test_pointer_scope_preserves_unrelated_fields(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); self.fixture(root)
            records=cm.approved_status_overrides(root)
            for key in ['old-pack/surface.roughness','old-pack/states[2].background.sigma']:
                self.assertIn('Superseded field',cm.source_resolution(self.doc(key)['conflicts'][0]['definitions'][0],records))
            for key in ['old-pack/surface.colour','old-pack/states[2].localLayer.sigma','old-pack/states[2].nested.background.sigma']:
                self.assertEqual(cm.source_resolution(self.doc(key)['conflicts'][0]['definitions'][0],records),'pending (R decides)')

    def test_prose_selectors_are_scoped_not_whole_pack_replacements(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); pack=self.fixture(root)
            path=pack/'values.json'; data=json.loads(path.read_text())
            data['overrides'][0]['paths']=['background coefficients in fixtures']
            path.write_text(json.dumps(data))
            output=cm.render_conflicts_md(self.doc(),root)
            self.assertIn('Approved scoped rule',output)
            self.assertIn('other fields remain unresolved',output)
            self.assertNotIn('Superseded field',output)
            doc=self.doc();doc['conflicts'][0]['definitions'][0]['resolved']='different state'
            self.assertIn('| different state |',cm.render_conflicts_md(doc,root))

    def test_real_haze_status_and_preserved_scope(self):
        report=cm.render_conflicts_md(cm.build())
        self.assertIn('Superseded field by approved haze-visibility-v1',report)
        self.assertIn('"contrastThreshold": 0.05',report)
        self.assertIn('meteorological_optical_range_5_percent',report)
        self.assertIn('preserving ground fog .035/m',report)
        self.assertIn('preserve localLayerExtinctionPerM',report)
        haze_rows=[line for line in report.splitlines() if line.startswith('| haze extinction')]
        self.assertEqual(len(haze_rows),4)
        self.assertTrue(all('pending (R decides)' not in line for line in haze_rows))

    def test_guard_reads_archived_status_not_working_copy(self):
        original_git=guard.git
        def changed_status(*args,**kwargs):
            data=original_git(*args,**kwargs)
            if args[0]!='archive': return data
            output=io.BytesIO()
            with tarfile.open(fileobj=io.BytesIO(data)) as source, tarfile.open(fileobj=output,mode='w') as dest:
                for member in source:
                    stream=source.extractfile(member) if member.isfile() else None
                    if member.name=='docs/proposals/haze-visibility-v1/STATUS.md':
                        payload=b'# Status\n\n**Pending R approval.**\n'
                        member.size=len(payload);stream=io.BytesIO(payload)
                    dest.addfile(member,stream)
            return output.getvalue()
        with patch.object(guard,'git',side_effect=changed_status):
            self.assertEqual(guard.mock_check('HEAD',ROOT),['stale generated file: docs/lookloop/mock-conflicts.md'])


if __name__=='__main__':
    unittest.main()
