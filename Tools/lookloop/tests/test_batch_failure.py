import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'batch.py'


class BatchFailureTests(unittest.TestCase):
    def exercise(self, launch_code, frame=False, missing_log=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'views.tsv').write_text('fixture\t-preset fixture\n')
            (root / 'Documents').mkdir()
            (root / 'Documents/frame.png').write_bytes(b'fixture-image')
            def command(args, **kwargs):
                if 'launch' in args:
                    device_log = next(a.split('=', 1)[1] for a in args if a.startswith('--stdout='))
                    log = root / device_log.lstrip('/')
                    log.parent.mkdir(parents=True, exist_ok=True)
                    if launch_code == 0 and not missing_log:
                        log.write_text('VIEWSHOT id=fixture file=frame.png\nVIEWS done\n' if frame else 'VIEWS failed\n')
                    return subprocess.CompletedProcess(args, launch_code, 'launch output', 'launch detail')
                return subprocess.CompletedProcess(args, 0, tmp, '')
            with patch.dict('os.environ', {'LOAD_TIMEOUT': '-1'}), patch.object(sys, 'argv', [str(SCRIPT), tmp, 'sim', 'bundle', json.dumps([])]), patch('subprocess.run', side_effect=command), patch('time.sleep'):
                with self.assertRaises(SystemExit) as result:
                    runpy.run_path(str(SCRIPT), run_name='__main__')
            if launch_code == 0 and not missing_log:
                self.assertTrue(list((root / 'logs').glob('_launch-*.log')))
            records = (root / 'capture.tsv').read_text()
            evidence = next((root / 'logs').glob('*.launch-result')).read_text()
            return result.exception.code, records, evidence

    def test_missing_first_frame_records_failure_without_traceback(self):
        code, records, evidence = self.exercise(0)
        self.assertEqual(code, 1)
        self.assertEqual(records, 'fixture\tfailed\t-\n')
        self.assertIn('exit=0', evidence)
        self.assertIn('launch output', evidence)

    def test_timeout_without_app_log_records_failure(self):
        code, records, _ = self.exercise(0, missing_log=True)
        self.assertEqual(code, 1)
        self.assertEqual(records, "fixture\tfailed\t-\n")

    def test_launch_refusal_preserves_error_and_fails(self):
        code, records, evidence = self.exercise(3)
        self.assertEqual(code, 1)
        self.assertIn('failed', records)
        self.assertIn('exit=3', evidence)
        self.assertIn('launch detail', evidence)

    def test_completed_frame_succeeds(self):
        code, records, _ = self.exercise(0, frame=True)
        self.assertEqual(code, 0)
        self.assertIn('fixture\tok\t', records)


if __name__ == '__main__':
    unittest.main()
