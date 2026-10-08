import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import io
import tarfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'Tools/lookloop'))
import holdouts
import colour_prescreen as colour
import finish
spec = importlib.util.spec_from_file_location('push_guard', ROOT / 'scripts/push_guard.py')
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class ScoringTests(unittest.TestCase):
    def test_holdouts_missing_and_invalid(self):
        contract = {'views':[{'id':'focus','area':'sloans-lake'}, {'id':'held','area':'elsewhere'}],
                    'pendingHoldouts':[{'area':'Denver','status':'missing data'}]}
        report = holdouts.report([('focus', {'calGap':{'closeness':4}})], contract)
        self.assertEqual(report['sloansScores'], {'focus':4})
        self.assertEqual(report['holdoutScores'], {'held':None})
        self.assertEqual(report['coverage'], 'PENDING')
        self.assertIn('Denver: PENDING', holdouts.cells(report)[1])
        for bad in [True, float('nan'), 6, '3']:
            self.assertIsNone(holdouts.score({'calGap': {'closeness':bad}}))

    def test_fit_error_and_grader_separation(self):
        rows = [dict(x=x,y=y,view=str(x),grader='one') for x,y in [(1,1),(2,3),(3,3)]]
        rows += [dict(x=x,y=3,view=str(x),grader='two') for x in [1,2,3]]
        model = colour.fit(rows)
        self.assertGreater(model['models']['one']['trainingMAE'], 0)
        self.assertGreater(model['models']['one']['leaveViewOutMAE'], 0)
        self.assertFalse(model['models']['two']['informative'])
        self.assertFalse(colour.screen(model, {}, 'two')['isGrade'])
        self.assertEqual(colour.screen(model, {}, 'two')['status'], 'UNAVAILABLE')

    def test_real_evidence_no_fake_discrimination(self):
        model = colour.fit(colour.observations(ROOT / 'docs/lookloop'))
        self.assertEqual(sum(m['n'] for m in model['models'].values()), 8)
        self.assertTrue(all(not m['informative'] for m in model['models'].values()))

    def test_finish_calibration_only_and_scoreboard(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td); run = base/'run'; run.mkdir()
            (run/'grades').mkdir(); (run/'frames').mkdir(); (run/'sheets').mkdir()
            docs = base/'docs'; docs.mkdir()
            for name in ['a3-capture-contract.json','calibration-scores.json']:
                (docs/name).write_bytes((ROOT/'docs/lookloop'/name).read_bytes())
            (run/'signals.json').write_bytes((ROOT/'docs/lookloop/a3-baseline/signals.json').read_bytes())
            for p in (ROOT/'docs/lookloop/a3-baseline').glob('*afternoon.json'):
                (run/'grades'/p.name).write_bytes(p.read_bytes())
            saved = finish.DOCS, finish.LATEST, sys.argv
            try:
                finish.DOCS, finish.LATEST = str(docs), str(docs/'latest')
                sys.argv = ['finish.py', str(run)]
                import contextlib, io
                with contextlib.redirect_stdout(io.StringIO()):
                    finish.main()
                output = json.loads((run/'grades.json').read_text())
                self.assertEqual(output['holdouts']['sloansScores']['ordinary-street-afternoon'],3)
                self.assertEqual(output['holdouts']['coverage'],'PENDING')
                self.assertEqual(output['aggregate']['graded'],4)
                with contextlib.redirect_stdout(io.StringIO()):
                    finish.main()
                again=json.loads((run/'grades.json').read_text())
                self.assertIsNone(again['aggregate']['meanV2Score50'])
                self.assertEqual(output['aggregate']['lookGate']['status'],'FAIL')
                table = [r for r in (docs/'scoreboard.md').read_text().splitlines() if r.startswith('|')]
                self.assertEqual([r.count('|') for r in table], [18,18,18,18])
                self.assertIn('lakeview-street-afternoon: 3/5',table[-1])
                historical=json.loads((ROOT/'docs/lookloop/latest/grades.json').read_text())
                (run/'signals.json').write_text(json.dumps({v:e['signals'] for v,e in historical['views'].items()}))
                for v,e in historical['views'].items():
                    if e.get('grade'):
                        (run/'grades'/f'{v}.json').write_text(json.dumps(e['grade']))
                with contextlib.redirect_stdout(io.StringIO()):
                    finish.main()
                legacy=json.loads((run/'grades.json').read_text())
                self.assertIsNotNone(legacy['aggregate']['meanV2Score50'])
                self.assertEqual(legacy['holdouts']['sloansScores']['ordinary-street-afternoon'],3)
            finally:
                finish.DOCS, finish.LATEST, sys.argv = saved


class GuardTests(unittest.TestCase):
    def test_secrets_privacy_and_safe_roles(self):
        self.assertIn('possible secret/key',guard.findings(('gh'+'p_'+'a'*36).encode()))
        self.assertIn('personal absolute path',guard.findings(('/Us'+'ers/person/file').encode()))
        self.assertIn('possible personal email',guard.findings(('person'+'@mail.invalid').encode()))
        self.assertEqual(guard.findings(b'contact@example.org'),[])
        self.assertEqual(guard.findings(b'licensing@agency.gov'),[])

    def test_instruction_pair(self):
        read=lambda p:(ROOT/p).read_bytes()
        self.assertEqual(guard.instruction_check(read, []),[])
        self.assertTrue(guard.instruction_check(read, ['CLAUDE.md']))
        def changed(p):
            return read(p)+b'changed' if p=='AGENTS.md' else read(p)
        self.assertTrue(guard.instruction_check(changed, ['CLAUDE.md','AGENTS.md']))

    def test_committed_mock_freshness_and_stale_output(self):
        self.assertEqual(guard.mock_check('HEAD', ROOT), [])
        original_git = guard.git
        stale_path = 'Resources/look/mock-values.json'
        def stale(*args, **kwargs):
            data = original_git(*args, **kwargs)
            if args[0] != 'archive':
                return data
            output = io.BytesIO()
            with tarfile.open(fileobj=io.BytesIO(data)) as source, tarfile.open(fileobj=output, mode='w') as dest:
                for member in source:
                    stream = source.extractfile(member) if member.isfile() else None
                    if member.name == stale_path:
                        stream = io.BytesIO(b'{}'); member.size = 2
                    dest.addfile(member, stream)
            return output.getvalue()
        for stale_path in ['Resources/look/mock-values.json',
                           'Sources/WorldGen/Profiles/mock-values.json',
                           'docs/lookloop/mock-conflicts.md']:
            with self.subTest(path=stale_path), patch.object(guard, 'git', side_effect=stale):
                self.assertEqual(guard.mock_check('HEAD', ROOT), [f'stale generated file: {stale_path}'])

    def test_intermediate_blob_and_deletion(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td)
            def git(*args): return guard.git(*args,cwd=td).decode().strip()
            git('init'); git('config','user.name','Tooling Test'); git('config','user.email','test@example.org')
            (root/'scripts').mkdir()
            for p in ['AGENTS.md','CLAUDE.md','scripts/instruction-pair.json']:
                (root/p).write_bytes((ROOT/p).read_bytes())
            git('add','.'); git('commit','-qm','baseline'); base=git('rev-parse','HEAD')
            (root/'fixture').write_text('gh'+'p_'+'a'*36)
            git('add','.'); git('commit','-qm','bad'); bad=git('rev-parse','HEAD')
            (root/'fixture').unlink(); git('add','.'); git('commit','-qm','remove')
            commits=guard.outgoing(git('rev-parse','HEAD'),base,'origin',td)
            self.assertIn(bad,commits)
            self.assertTrue(any('secret' in s for s in guard.check(commits,td,check_mocks=False)))
            self.assertEqual(guard.check([commits[0]],td,check_mocks=False),[])
            # Large files are measured before reading their contents.
            with (root/'large').open('wb') as stream: stream.truncate(guard.LIMIT+1)
            git('add','.'); git('commit','-qm','large')
            self.assertTrue(any('50 MB' in s for s in guard.check([git('rev-parse','HEAD')],td,False)))


if __name__ == '__main__':
    unittest.main()
