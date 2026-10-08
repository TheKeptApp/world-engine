"""Real Git commits exercise evidence requirements and automatic activation."""
import contextlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
import push_guard as guard


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.git('init','-b','main')
        self.git('config','user.name','Tooling Test')
        self.git('config','user.email','test@example.org')
        self.commit({'README.md':'baseline'},'baseline')

    def git(self,*args):
        return guard.git(*args,cwd=self.root).decode().strip()

    def commit(self,files,message='change'):
        for name,value in files.items():
            path=self.root/name
            if value is None: path.unlink()
            else:
                path.parent.mkdir(parents=True,exist_ok=True)
                path.write_text(value)
        self.git('add','.')
        self.git('commit','-qm',message)
        return self.git('rev-parse','HEAD')

    def check(self,commit,active=True):
        changed=self.git('diff-tree','--root','-m','--no-commit-id','--name-only','-r',commit).splitlines()
        return guard.evidence_check(commit,changed,active,self.root)

    def test_evidence_line_passes(self):
        for i,path in enumerate(guard.RENDER_ROOTS):
            c=self.commit({path+'render.js':str(i)},'render\n\nUsed: research section. Mock: frame.png. Deviation: none.')
            self.assertEqual(self.check(c),([],[]))

    def test_same_commit_ledger_update_passes(self):
        c=self.commit({'Sources/WorldGen/Tree.swift':'code',guard.INTEGRATION:'integration evidence'})
        self.assertEqual(self.check(c),([],[]))

    def test_missing_or_incomplete_evidence_blocks(self):
        for i,msg in enumerate(['change','Used: x Mock: y','Used: Mock: y Deviation: none',
                                'Used: x\nMock: y\nDeviation: none','Used: x Mock: y Deviation: ']):
            c=self.commit({'web/src/main.js':str(i)},msg)
            errors,warnings=self.check(c)
            self.assertEqual(errors,[guard.EVIDENCE_ERROR]);self.assertEqual(warnings,[])

    def test_docs_tests_and_tooling_only_pass(self):
        c=self.commit({'web/bakeoff/README.md':'docs','docs/tracking/test.md':'docs',
                       'web/bakeoff/policy.test.mjs':'test','Sources/WorldGen/Tests/Foo.swift':'test',
                       'web/src/main.spec.js':'test','scripts/tool.py':'tool',
                       'web/bakeoff/score.py':'tool','web/bakeoff/capture.mjs':'tool'})
        self.assertEqual(self.check(c),([],[]))

    def test_mixed_test_and_render_commit_blocks(self):
        c=self.commit({'web/bakeoff/policy.test.mjs':'test','web/bakeoff/data/scenes.json':'data'})
        self.assertEqual(self.check(c)[0],[guard.EVIDENCE_ERROR])

    def test_warning_before_ledger_then_block_after_main_lands(self):
        c=self.commit({'web/src/main.js':'first'})
        self.assertFalse(guard.integration_seen('refs/heads/main',self.root))
        errors,warnings=self.check(c,active=False)
        self.assertEqual(errors,[]);self.assertEqual(len(warnings),1)
        self.commit({guard.INTEGRATION:'A3 ledger'},'docs')
        self.assertTrue(guard.integration_seen('refs/heads/main',self.root))
        c=self.commit({'web/src/main.js':'second'})
        self.assertEqual(self.check(c,active=guard.integration_seen('main',self.root))[0],[guard.EVIDENCE_ERROR])

    def test_deletion_cannot_disable_or_supply_evidence(self):
        self.commit({guard.INTEGRATION:'ledger'})
        c=self.commit({guard.INTEGRATION:None,'Sources/WorldEngine/File.swift':'render'})
        self.assertTrue(guard.integration_seen('main',self.root))
        self.assertEqual(self.check(c,active=False)[0],[guard.EVIDENCE_ERROR])

    def test_render_deletion_requires_evidence(self):
        self.commit({'web/src/main.js':'render'})
        c=self.commit({'web/src/main.js':None})
        self.assertEqual(self.check(c)[0],[guard.EVIDENCE_ERROR])

    def test_main_activation_applies_to_branch_without_ledger(self):
        base=self.git('rev-parse','HEAD')
        self.commit({guard.INTEGRATION:'ledger'})
        self.git('checkout','-b','old-branch',base)
        c=self.commit({'web/src/main.js':'render'})
        self.assertEqual(self.check(c,guard.integration_seen('main',self.root))[0],[guard.EVIDENCE_ERROR])

    def test_guard_entry_point_keeps_other_checks_and_checks_each_commit(self):
        self.commit({guard.INTEGRATION:'ledger'})
        bad=self.commit({'web/src/main.js':'render'})
        good=self.commit({guard.INTEGRATION:'later evidence'})
        with patch.object(guard,'instruction_check',return_value=[]), patch.object(guard,'mock_check',return_value=[]) as freshness:
            errors=guard.check([bad,good],self.root)
        self.assertEqual(errors,[f'{bad[:10]}: {guard.EVIDENCE_ERROR}'])
        self.assertEqual(freshness.call_count,2)

    def test_advertised_main_ref_activates_without_tracking_ref(self):
        base=self.git('rev-parse','HEAD')
        main=self.commit({guard.INTEGRATION:'ledger'})
        self.git('checkout','--detach',base)
        self.git('branch','-D','main')
        c=self.commit({'web/src/main.js':'render'})
        with patch.object(guard,'instruction_check',return_value=[]):
            errors=guard.check([c],self.root,False,evidence_refs=[main])
        self.assertEqual(errors,[f'{c[:10]}: {guard.EVIDENCE_ERROR}'])

    def test_installed_hook_delegates_to_guard(self):
        self.assertIn('scripts/push_guard.py',(ROOT/'.githooks/pre-push').read_text())
        self.assertIn('core.hooksPath .githooks',(ROOT/'scripts/install_push_guard.sh').read_text())


if __name__=='__main__':
    unittest.main()
