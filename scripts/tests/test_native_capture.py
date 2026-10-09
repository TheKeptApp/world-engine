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
import capture_foliage_exp1 as batch
import base64


class NativeCaptureTests(unittest.TestCase):
    def test_batch_matches_each_category_including_context(self):
        tri='chunks=2 buildings=0 foliage=0 props=0 context=3 other=0'
        draw='chunks=1 buildings=0 foliage=0 props=0 context=1 other=0'
        def readiness(triangles):
            signature=base64.b64encode(f'pose|tri={triangles}|draw={draw}'.encode()).decode()
            return dict(gpuCompletionProved=True,sceneReady=dict(signature=signature),triangles=5,draws=2,drawsplit=draw)
        original=batch.coverage_fingerprint(readiness(tri))
        swapped=batch.coverage_fingerprint(readiness(tri.replace('chunks=2','chunks=3').replace('context=3','context=2')))
        self.assertNotEqual(original,swapped)
        bad=readiness(tri);bad['triangles']=6
        with self.assertRaisesRegex(ValueError,'disagree'): batch.coverage_fingerprint(bad)
        bad=readiness(tri);bad['gpuCompletionProved']=False
        with self.assertRaisesRegex(ValueError,'SCENEREADY'): batch.coverage_fingerprint(bad)

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

    def test_capture_date_override_is_explicit_validated_and_preserves_default(self):
        view = capture.frozen_view(ROOT, 'ordinary-street-afternoon')
        before = list(view['args'])
        changed = capture.inspection_view(view, '39.7511195,-105.0389,150,270,45', 'off', '2026-07-15T20:30:00Z')
        self.assertEqual(changed['args'][changed['args'].index('-date')+1], '2026-07-15T20:30:00Z')
        self.assertEqual(view['args'], before)
        self.assertEqual(changed['utc'], '2026-07-15T20:30:00Z')
        for date in ('2026-02-30T20:30:00Z', '2026-07-15', '2026-07-15T20:30:00-06:00'):
            with self.assertRaises(ValueError): capture.inspection_view(view, None, None, date)

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

    def test_scene_ready_requires_completed_frames_and_correct_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp); (run / 'logs').mkdir(); log = run / 'logs/_launch-fixture.log'
            signal = 'SCENEREADY id=view context=ready exposure=pinned-1 gpuCompleted=3 stableFrames=3 size=1005x565 signature=cG9zZQ=='
            output = 'OUTPUTSTABLE id=view samples=3 observations=3 completed=5 exposure=pinned-1'
            shot = 'VIEWSHOT id=view file=views/view.png triangles=5 draws=1 drawsplit[context=1]'
            log.write_text('CONTEXT cells=18 parse=1s\n' + signal + '\nVIEWREADY id=view\n' + output + '\n' + shot + '\n')
            self.assertTrue(capture.verify_scene_readiness(run, 'view', True, True)['gpuCompletionProved'])
            log.write_text('CONTEXT cells=18 parse=1s\n' + signal + '\nVIEWREADY id=view\n' + shot + '\n')
            self.assertTrue(capture.verify_scene_readiness(run, 'view', True, True)['gpuCompletionProved'])

            log.write_text('CONTEXT cells=18 parse=1s\n' + signal.replace(' exposure=pinned-1', '') + '\nVIEWREADY id=view\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'exposure'):
                capture.verify_scene_readiness(run, 'view', True, True)
            log.write_text('CONTEXT cells=18 parse=1s\nVIEWREADY id=view\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'SCENEREADY'):
                capture.verify_scene_readiness(run, 'view', True, True)
            log.write_text('CONTEXT cells=18 parse=1s\n' + signal.replace('stableFrames=3', 'stableFrames=2') + '\nVIEWREADY id=view\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'insufficient'):
                capture.verify_scene_readiness(run, 'view', True, True)
            log.write_text('CONTEXT cells=18 parse=1s\nVIEWREADY id=view\n' + signal + '\n' + shot + '\n')
            with self.assertRaisesRegex(ValueError, 'ordering'):
                capture.verify_scene_readiness(run, 'view', True, True)

    def test_failed_runtime_adapter_rejects_candidate(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp); (run / 'logs').mkdir()
            (run / 'logs/_launch-fixture.log').write_text('CROWN_ADAPTER_FAILED error=unknownShadowCost\nVIEWSHOT id=view triangles=5 draws=1 drawsplit[context=0]\n')
            with self.assertRaisesRegex(ValueError, 'adapter accounting'):
                capture.verify_scene_readiness(run, 'view', False)

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
