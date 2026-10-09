import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

path = Path(__file__).resolve().parents[1] / 'world_scoreboard.py'
spec = importlib.util.spec_from_file_location('scoreboard', path)
scoreboard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scoreboard)


class InventoryTests(unittest.TestCase):
    def test_selection_sorted_and_missing_held_inputs_never_fetched(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ['z', 'a', 'missing']:
                p = root / 'Data/areas' / name; p.mkdir(parents=True)
                m = dict(id=name, center=dict(latitude=40, longitude=-105), widthMeters=1000, heightMeters=1000,
                         sources=[dict(path='osm.json', format='osm-overpass-json', layers=['all'])])
                (p / 'manifest.json').write_text(json.dumps(m))
                if name != 'missing':
                    (p / 'osm.json').write_text('{"elements":[]}')
            blocks, missing = scoreboard.inventory(root)
            self.assertEqual([b['area'] for b in blocks], ['a', 'z'])
            self.assertEqual(missing[0]['area'], 'missing')

    def test_stale_source_hash_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); p = root / 'Data/areas/a'; p.mkdir(parents=True)
            (p / 'osm.json').write_text('{}')
            (p / 'manifest.json').write_text(json.dumps(dict(id='a', sources=[dict(path='osm.json', sha256='stale')])) )
            with self.assertRaisesRegex(ValueError, 'hash disagrees'):
                scoreboard.inventory(root)

    def test_two_failed_attempts_stop(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(scoreboard.subprocess, 'Popen') as popen:
            popen.return_value.wait.return_value = 1
            with self.assertRaisesRegex(RuntimeError, 'failed twice'):
                scoreboard.run_bounded_step(['false', 'unit failure'], Path(tmp) / 'log')
            self.assertEqual(popen.call_count, 2)


if __name__ == '__main__':
    unittest.main()
