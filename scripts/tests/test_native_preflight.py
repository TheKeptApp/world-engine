import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
import native_preflight as preflight


class NativePreflightTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.put('Apps/WorldLab/project.yml','path: ../../Data/areas/demo\n')
        self.put('Package.swift','// no resource targets in this fixture')
        self.put('Data/areas/demo/manifest.json','{}')
        self.put('Apps/WorldLab/Resources/demo.json','{"area":"demo"}')

    def put(self,name,value):
        p=self.root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(value)

    def prepared(self):
        for p in ['Apps/WorldLab/WorldLab.xcodeproj/project.pbxproj','Apps/WorldLab/Generated/Info.plist',
                  'Apps/WorldLab/Generated/WorldLab.entitlements','web/dist/app.js','web/dist/index.html','web/dist/demo.json']:
            self.put(p,'fixture')
        self.put('Generated/package/demo/world.json',json.dumps({'files':{'mesh.bin':{'sha256':hashlib.sha256(b'mesh').hexdigest()}}}))
        self.put('Generated/package/demo/mesh.bin','mesh')

    def test_missing_outputs_name_producers(self):
        self.assertEqual(preflight.check(self.root,'inputs'),[])
        failures=dict(preflight.check(self.root))
        self.assertEqual(failures['Generated/package/demo/world.json'],preflight.EXPORT)
        self.assertEqual(failures['web/dist/app.js'],preflight.WEB)
        self.assertEqual(failures['Apps/WorldLab/WorldLab.xcodeproj/project.pbxproj'],preflight.PREPARE)

    def test_valid_outputs_and_tampered_package(self):
        self.prepared();self.assertEqual(preflight.check(self.root),[])
        self.put('Generated/package/demo/mesh.bin','tampered')
        self.assertIn(('Generated/package/demo/mesh.bin',preflight.EXPORT),preflight.check(self.root))

    def test_terrain_hash_and_missing_binary(self):
        self.put('Data/areas/demo/terrain-slope.json',json.dumps({'binFile':'terrain-slope.bin','binSha256':hashlib.sha256(b'grid').hexdigest()}))
        self.assertIn('--areas demo',preflight.check(self.root,'inputs')[0][1])
        self.put('Data/areas/demo/terrain-slope.bin','grid');self.assertEqual(preflight.check(self.root,'inputs'),[])
        self.put('Data/areas/demo/terrain-slope.bin','wrong');self.assertTrue(preflight.check(self.root,'inputs'))

    def test_capture_requires_shader_and_executable_even_when_build_skipped(self):
        self.prepared()
        self.assertEqual(len(preflight.check(self.root,'capture')),2)
        app='.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app/'
        self.put(app+'WorldLab','binary');self.put(app+'WorldEngine_WorldEngine.bundle/default.metallib','metal')
        self.assertEqual(preflight.check(self.root,'capture'),[])

    def test_capture_scripts_do_not_ignore_build_errors(self):
        for name in ['Tools/lookloop/capture.sh','scripts/snapshots.sh','scripts/gate_shots.sh','scripts/lookloop_viewlist.sh']:
            text=(ROOT/name).read_text()
            self.assertIn('build-native.sh" || exit $?',text)
            self.assertIn('native_preflight.py" --stage capture || exit $?',text)
            self.assertNotIn('build 2>&1',text)


if __name__=='__main__': unittest.main()
