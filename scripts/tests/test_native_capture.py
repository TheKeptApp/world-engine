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
