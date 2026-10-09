"""Exercise the complete push guard against a synthetic child of actual main.
Only a temporary repository receives the deliberately invalid fixture commit.
"""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import push_guard as guard


class MainEvidenceProof(unittest.TestCase):
    def test_actual_main_blocks_missing_evidence_commit(self):
        self.assertTrue(guard.integration_seen('origin/main', ROOT))
        subprocess.run(['git', 'cat-file', '-e', 'fc439aa:docs/tracking/INTEGRATION.md'], cwd=ROOT, check=True)
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run(['git', 'clone', '--shared', '--no-checkout', '--quiet', str(ROOT), tmp], check=True)
            def git(*args, data=None):
                return subprocess.run(['git', *args], cwd=tmp, input=data, text=True, capture_output=True, check=True).stdout.strip()
            git('config', 'user.name', 'Tooling Test'); git('config', 'user.email', 'test@example.org')
            base = guard.git('rev-parse', 'origin/main', cwd=ROOT).decode().strip()
            git('read-tree', base)
            blob = git('hash-object', '-w', '--stdin', data='// deliberately invalid evidence fixture\n')
            git('update-index', '--add', '--cacheinfo', f'100644,{blob},Sources/WorldEngine/EvidenceFixture.swift')
            bad = git('commit-tree', git('write-tree'), '-p', base, data='Deliberate missing-evidence fixture\n')
            result = subprocess.run([sys.executable, str(ROOT / 'scripts/push_guard.py'), 'origin'], cwd=tmp,
                                    input=f'refs/heads/proof {bad} refs/heads/main {base}\n', text=True, capture_output=True)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertEqual(result.stderr.strip(), f'Push blocked:\n{bad[:10]}: {guard.EVIDENCE_ERROR}')
            self.assertNotIn('warning', result.stderr.lower())
            print(f'Blocking proof: commit {bad[:10]}, exit={result.returncode}; {result.stderr.strip()}', flush=True)


if __name__ == '__main__': unittest.main()
