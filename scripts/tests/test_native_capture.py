import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import capture_native as capture


class NativeCaptureTests(unittest.TestCase):
    def test_frozen_view_and_common_args(self):
        view = capture.frozen_view(ROOT, 'ordinary-street-afternoon')
        self.assertEqual(view['id'], 'ordinary-street-afternoon')
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name, doc in [('docs/lookloop/a3-capture-contract.json', {'views': [view], 'commonArgs': ['frozen']}),
                              ('Tools/lookloop/views.json', {'commonArgs': ['changed']})]:
                p = root / name; p.parent.mkdir(parents=True); p.write_text(json.dumps(doc))
            with self.assertRaisesRegex(ValueError, 'frozen'):
                capture.frozen_view(root, view['id'])

    def test_authorized_inspection_override_keeps_clock_and_mode(self):
        view = capture.frozen_view(ROOT, 'ordinary-street-afternoon')
        self.assertEqual(capture.inspection_view(view, None, None), view)
        pose = '39.7511195,-105.0389,40,270,45'
        changed = capture.inspection_view(view, pose, 'layered')
        self.assertNotIn('-preset', changed['args'])
        self.assertIn('2026-10-15T20:30:00Z', changed['args'])
        self.assertEqual(changed['args'][-4:], ['-inspectionpose', pose, '-foliageexp1', 'layered'])
        for bad in ['nan,2,40,0,45', '1,2,7,0,45', '1,2,40,0,90', '1,2,3']:
            with self.assertRaises(ValueError): capture.inspection_view(view, bad, 'off')
        with self.assertRaises(ValueError): capture.inspection_view(view, pose, 'invalid')

    def test_failed_or_stale_frame_cannot_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); (root / 'raw').mkdir()
            frame = root / 'raw/view.png'
            frame.write_bytes(b'\x89PNG\r\n\x1a\n' + b'\0' * 8 + struct.pack('>II', 10, 20))
            (root / 'capture.tsv').write_text('view\tfailed\t-\n')
            with self.assertRaises(ValueError): capture.verify_frame(root, 'view')
            (root / 'capture.tsv').write_text('view\tok\t1\n')
            self.assertEqual(capture.verify_frame(root, 'view')[1], (10, 20))
            frame.write_bytes(b'not a PNG')
            with self.assertRaises(ValueError): capture.verify_frame(root, 'view')

    def test_existing_output_directory_is_untouched(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'failure.json'; p.write_text('existing evidence')
            with patch.object(sys, 'argv', ['capture-native', '--output', tmp]):
                self.assertEqual(capture.main(), 1)
            self.assertEqual(p.read_text(), 'existing evidence')
            self.assertEqual(list(Path(tmp).iterdir()), [p])

    def test_context_completion_must_precede_capture_and_view_update(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp); (run / 'logs').mkdir()
            log = run / 'logs/_launch-fixture.log'
            shot = 'VIEWSHOT id=view file=views/view.png triangles=228159 draws=43 drawsplit[context=6]'
            log.write_text('VIEWREADY id=view\n' + shot + '\nCONTEXT cells=18 parse=0.5s\n')
            with self.assertRaisesRegex(ValueError, 'before VIEWSHOT'):
                capture.verify_scene_readiness(run, 'view', True)
            log.write_text('VIEWREADY id=view\nCONTEXT cells=18 parse=0.5s\nVIEW t=34 triangles=228159\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'precede VIEWREADY'):
                capture.verify_scene_readiness(run, 'view', True)
            log.write_text('CONTEXT cells=18 parse=0.5s\nVIEWREADY id=view\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'post-attachment'):
                capture.verify_scene_readiness(run, 'view', True)
            log.write_text('CONTEXT cells=18 parse=0.5s\nVIEW t=34 triangles=228159\nVIEWREADY id=view\n' + shot + '\n')
            proof = capture.verify_scene_readiness(run, 'view', True)
            self.assertEqual(proof['draws'], 43)
            self.assertFalse(proof['gpuCompletionProved'])
            log.write_text(shot + '\n')
            self.assertFalse(capture.verify_scene_readiness(run, 'view', False)['contextRequired'])

    def test_missing_or_duplicate_capture_logs_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp); (run / 'logs').mkdir()
            with self.assertRaisesRegex(ValueError, 'unambiguous'):
                capture.verify_scene_readiness(run, 'view', False)
            shot = 'VIEWSHOT id=view file=views/view.png triangles=5 draws=1 drawsplit[context=0]'
            (run / 'logs/_launch-fixture.log').write_text(shot + '\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'unambiguous'):
                capture.verify_scene_readiness(run, 'view', False)

    def test_manifest_drives_context_requirement(self):
        self.assertTrue(capture.context_expected(ROOT, {'args': []}))
        self.assertFalse(capture.context_expected(ROOT, {'args': ['-diagnostics', 'noContext,noPost']}))

    def test_reuses_only_booted_simulator_and_rejects_multiple(self):
        self.assertIn('LOOKLOOP_SIM', capture.simulator_env({'devices': {}}))
        one = {'udid': 'fixture', 'state': 'Booted'}
        self.assertEqual(capture.simulator_env({'devices': {'runtime': [one]}}), {'LOOKLOOP_UDID': 'fixture'})
        with self.assertRaises(ValueError): capture.simulator_env({'devices': {'runtime': [one, one]}})


if __name__ == '__main__': unittest.main()
