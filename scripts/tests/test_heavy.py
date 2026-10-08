"""Exercise the real wrapper with fake load readings and an isolated fixture lock."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class HeavyTests(unittest.TestCase):
    def run_wrapper(self, loads, wait='0', foreign=False, command_status=0, limit='25', live=False):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); lock=root/'fixture-lock'; marker=root/'started'
            # Redirect only the fixture's lock; HOME and the real shared lock are untouched.
            source=(ROOT/'scripts/heavy.sh').read_text()
            original='LOCK="$HOME/.agent-heavy-lock"'
            self.assertEqual(source.count(original),1)
            script=root/'heavy.sh'
            script.write_text(source.replace(original, 'LOCK="$A7_TEST_LOCK"'))
            bins=root/'bin'; bins.mkdir()
            loadfile=root/'loads'; loadfile.write_text('\n'.join(loads)+'\n')
            for name, body in {
                'sysctl': 'value=$(head -1 "$A7_TEST_LOADS"); count=$(wc -l < "$A7_TEST_LOADS"); if [ "$count" -gt 1 ]; then tail -n +2 "$A7_TEST_LOADS" > "$A7_TEST_LOADS.next"; mv "$A7_TEST_LOADS.next" "$A7_TEST_LOADS"; fi; printf "%s\\n" "$value"',
                'sleep': 'kill -TERM "$PPID"' if live else 'exit 0',
                'pgrep': 'exit 1',
            }.items():
                p=bins/name; p.write_text('#!/bin/sh\n'+body+'\n'); p.chmod(0o755)
            if foreign:
                lock.mkdir(); (lock/'owner').write_text(f'pid={os.getpid() if live else 99999999}\nagent=fixture-other\n')
            env=dict(os.environ, PATH=str(bins)+os.pathsep+os.environ['PATH'],
                     A7_TEST_LOCK=str(lock), A7_TEST_LOADS=str(loadfile),
                     HEAVY_LOAD_WAIT=wait, HEAVY_LOAD=limit)
            result=subprocess.run(['bash',str(script),'fixture job','sh','-c',
                                   'touch "$1"; exit "$2"','sh',str(marker),str(command_status)],
                                  env=env,text=True,capture_output=True,timeout=5)
            return result, marker.exists(), lock.exists(), (lock/'owner').read_text() if (lock/'owner').exists() else None

    def test_timeout_above_or_at_limit_never_starts(self):
        for load in ['25.00','25.01','40.5']:
            with self.subTest(load=load):
                result, started, lock, _=self.run_wrapper(['{ '+load+' 1 1 }'],wait='60')
                self.assertNotEqual(result.returncode,0)
                self.assertIn('HEAVY refused:',result.stderr)
                self.assertIn('waited 60s',result.stderr)
                self.assertFalse(started); self.assertFalse(lock)

    def test_under_limit_starts_and_releases_own_lock(self):
        result, started, lock, _=self.run_wrapper(['{ 24.99 1 1 }'])
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertTrue(started); self.assertFalse(lock)

    def test_load_falls_during_wait(self):
        result, started, lock, _=self.run_wrapper(['{ 26 1 1 }','{ 24 1 1 }'],wait='60')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertTrue(started); self.assertFalse(lock)

    def test_rise_after_lock_acquired_refuses_and_releases_own_lock(self):
        result, started, lock, _=self.run_wrapper(['{ 24 1 1 }','{ 26 1 1 }'])
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(started); self.assertFalse(lock)

    def test_unreadable_load_fails_closed(self):
        for load in ['','unavailable','{ NaN 1 1 }']:
            result, started, lock, _=self.run_wrapper([load])
            self.assertNotEqual(result.returncode,0)
            self.assertIn('unavailable',result.stderr)
            self.assertFalse(started); self.assertFalse(lock)

    def test_foreign_abandoned_lock_never_changed(self):
        for loads in [['{ 24 1 1 }'],['{ 26 1 1 }'],['{ 24 1 1 }','{ 26 1 1 }']]:
            result, started, lock, owner=self.run_wrapper(loads,foreign=True)
            self.assertTrue(lock)
            self.assertEqual(owner,'pid=99999999\nagent=fixture-other\n')
            self.assertEqual(started,len(loads)==1 and '24' in loads[0])

    def test_live_foreign_lock_preserved_on_interrupt(self):
        result, started, lock, owner=self.run_wrapper(['{ 24 1 1 }'],foreign=True,live=True)
        self.assertEqual(result.returncode,130,result.stderr)
        self.assertFalse(started); self.assertTrue(lock)
        self.assertEqual(owner,f'pid={os.getpid()}\nagent=fixture-other\n')

    def test_invalid_settings_refuse_before_lock(self):
        for wait, limit in [('invalid','25'),('0','invalid')]:
            result, started, lock, _=self.run_wrapper(['{ 1 1 1 }'],wait=wait,limit=limit)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('invalid load gate settings',result.stderr)
            self.assertFalse(started); self.assertFalse(lock)

    def test_command_exit_status_preserved(self):
        result, started, lock, _=self.run_wrapper(['{ 1 1 1 }'],command_status=7)
        self.assertEqual(result.returncode,7)
        self.assertTrue(started); self.assertFalse(lock)

    def test_override_cannot_raise_ceiling(self):
        result, started, _, _=self.run_wrapper(['{ 26 1 1 }'],limit='30')
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(started)
        result, started, _, _=self.run_wrapper(['{ 24 1 1 }'],limit='20')
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(started)


if __name__=='__main__':
    unittest.main()
