"""Hung/interrupting captures must return to the real heavy wrapper's own-lock trap."""
from pathlib import Path
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
WATCH = ROOT / 'scripts/capture_timeout.py'


class CaptureTimeoutTests(unittest.TestCase):
    def test_hang_returns_124_and_real_heavy_trap_releases_fixture_lock(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            lock = root / 'only-this-test-lock'
            script = root / 'heavy.sh'
            script.write_text((ROOT / 'scripts/heavy.sh').read_text().replace(
                'LOCK="$HOME/.agent-heavy-lock"', 'LOCK="$A7_TIMEOUT_TEST_LOCK"'))
            bins = root / 'bin'
            bins.mkdir()
            load = bins / 'sysctl'
            load.write_text('#!/bin/sh\nprintf "{ 1 1 1 }\\n"\n')
            load.chmod(0o755)
            marker = root / 'child-pid'
            child = ('import os,signal,time,pathlib; '
                     'signal.signal(signal.SIGTERM,signal.SIG_IGN); '
                     f'pathlib.Path({str(marker)!r}).write_text(str(os.getpid())); time.sleep(60)')
            env = dict(os.environ, PATH=str(bins)+os.pathsep+os.environ['PATH'],
                       A7_TIMEOUT_TEST_LOCK=str(lock), HEAVY_LOAD_WAIT='0')
            result = subprocess.run(['bash', str(script), 'timeout fixture', sys.executable,
                                     str(WATCH), '--seconds', '.3', '--grace', '.1',
                                     sys.executable, '-c', child], env=env,
                                    capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 124, result.stderr)
            self.assertIn('HEAVY done:', result.stderr)
            self.assertFalse(lock.exists())
            self.assertTrue(marker.exists())
            with self.assertRaises(ProcessLookupError):
                os.kill(int(marker.read_text()), 0)

    def test_signal_trap_terminates_owned_child(self):
        with tempfile.TemporaryDirectory() as td:
            marker = Path(td) / 'pid'
            child = ('import os,signal,time,pathlib; '
                     'signal.signal(signal.SIGTERM,signal.SIG_IGN); '
                     f'pathlib.Path({str(marker)!r}).write_text(str(os.getpid())); time.sleep(60)')
            process = subprocess.Popen([sys.executable, str(WATCH), '--seconds', '60',
                                        '--grace', '.1', sys.executable, '-c', child],
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try:
                deadline = time.monotonic()+3
                while not marker.exists() and time.monotonic() < deadline:
                    time.sleep(.01)
                self.assertTrue(marker.exists())
                process.send_signal(signal.SIGTERM)
                _, error = process.communicate(timeout=5)
                self.assertEqual(process.returncode, 143, error)
                with self.assertRaises(ProcessLookupError):
                    os.kill(int(marker.read_text()), 0)
            finally:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)

    def test_exit_status_preserved(self):
        result = subprocess.run([sys.executable, str(WATCH), '--seconds', '5',
                                 sys.executable, '-c', 'raise SystemExit(7)'])
        self.assertEqual(result.returncode, 7)

    def test_invalid_timeout_cannot_disable_watchdog(self):
        for setting in ['nan', 'inf', '0', '-1']:
            result = subprocess.run([sys.executable, str(WATCH), '--seconds', setting,
                                     sys.executable, '-c', 'raise SystemExit(0)'],
                                    capture_output=True)
            self.assertEqual(result.returncode, 2)


if __name__ == '__main__':
    unittest.main()
