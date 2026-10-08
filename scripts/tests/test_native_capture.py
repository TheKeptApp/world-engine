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

    def test_reuses_only_booted_simulator_and_rejects_multiple(self):
        self.assertIn('LOOKLOOP_SIM', capture.simulator_env({'devices': {}}))
        one = {'udid': 'fixture', 'state': 'Booted'}
        self.assertEqual(capture.simulator_env({'devices': {'runtime': [one]}}), {'LOOKLOOP_UDID': 'fixture'})
        with self.assertRaises(ValueError): capture.simulator_env({'devices': {'runtime': [one, one]}})


if __name__ == '__main__': unittest.main()
