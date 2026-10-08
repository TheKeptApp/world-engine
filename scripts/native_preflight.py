#!/usr/bin/env python3
"""Check native prerequisites without producing assets or borrowing another checkout.
See docs/tracking/weekend-brief.md section 0; run producers under scripts/heavy.sh.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
PREPARE='scripts/heavy.sh "prepare native assets" scripts/generate.sh'
EXPORT='scripts/heavy.sh "export native package" scripts/export-package.sh'
WEB='scripts/heavy.sh "build web assets" scripts/build-web.sh'
BUILD='scripts/heavy.sh "build native simulator" scripts/build-native.sh'


def check(root, stage='build', app=None):
    failures=[]
    def need(path, step, digest=None):
        path=Path(path)
        valid=path.is_file() and path.stat().st_size>0
        if valid and digest:
            valid=hashlib.sha256(path.read_bytes()).hexdigest()==digest
        if not valid:
            failures.append((str(path.relative_to(root)) if path.is_relative_to(root) else str(path),step))
        return valid
    spec=root/'Apps/WorldLab/project.yml'
    if not need(spec,'git restore --source=HEAD -- Apps/WorldLab/project.yml'):
        return failures
    # Every area actually bundled by the unchanged project specification.
    areas=re.findall(r'path:\s*\.\./\.\./Data/areas/([^\s]+)',spec.read_text())
    for area in areas:
        folder=root/'Data/areas'/area
        need(folder/'manifest.json',f'git restore --source=HEAD -- Data/areas/{area}')
        for header in folder.glob('*.json'):
            data=json.loads(header.read_text())
            if isinstance(data,dict) and data.get('binFile'):
                binary=folder/data['binFile']
                step=(f'uv run --no-project --python python3 --with certifi --with numpy --with scipy --with rasterio '
                      f'--with "laspy[lazrs]" python Tools/regionkit/terrain/slope.py all --work /tmp/worldengine-terrain --areas {area}')
                need(binary,step,data.get('binSha256'))
    # SwiftPM resource sources are tracked; the Simulator metallib is an Xcode output.
    package=root/'Package.swift'
    if need(package,'git restore --source=HEAD -- Package.swift'):
        for line in package.read_text().splitlines():
            target=re.search(r'\.target\(name: "([^"]+)"',line)
            if target:
                for resource in re.findall(r'\.(?:copy|process)\("([^"]+)"\)',line):
                    rel=f'Sources/{target[1]}/{resource}'
                    files=subprocess.run(['git','ls-files','-z','--',rel],cwd=root,capture_output=True,check=True).stdout
                    for name in files.decode().split('\0'):
                        if name: need(root/name,f'git restore --source=HEAD -- {rel}')
    if stage=='inputs': return failures
    need(root/'Apps/WorldLab/WorldLab.xcodeproj/project.pbxproj',PREPARE)
    for name in ['Info.plist','WorldLab.entitlements']:
        need(root/'Apps/WorldLab/Generated'/name,PREPARE)
    demo=root/'Apps/WorldLab/Resources/demo.json'
    if need(demo,'git restore --source=HEAD -- Apps/WorldLab/Resources/demo.json'):
        area=json.loads(demo.read_text())['area']
        folder=root/'Generated/package'/area
        manifest=folder/'world.json'
        if need(manifest,EXPORT):
            doc=json.loads(manifest.read_text())
            # Exporter records hashes for all emitted payloads, not just world.json.
            for name, metadata in doc.get('files',{}).items():
                digest=metadata.get('sha256') if isinstance(metadata,dict) else metadata
                need(folder/name,EXPORT,digest if isinstance(digest,str) else None)
    for name in ['app.js','index.html','demo.json']:
        need(root/'web/dist'/name,WEB)
    pbx=root/'Apps/WorldLab/WorldLab.xcodeproj/project.pbxproj'
    if pbx.exists() and 'Generated/dog' in pbx.read_text() and not (root/'Generated/dog').is_dir():
        failures.append(('Generated/dog',PREPARE))
    if stage=='capture':
        app=app or root/'.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app'
        need(app/'WorldLab',BUILD)
        need(app/'WorldEngine_WorldEngine.bundle/default.metallib',BUILD)
    return failures


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage',choices=['inputs','build','capture'],default='build')
    parser.add_argument('--app',type=Path)
    args=parser.parse_args()
    try:
        failures=check(ROOT,args.stage,args.app)
    except (ValueError,OSError,subprocess.CalledProcessError) as e:
        print(f'native preflight: invalid prerequisite: {str(e).replace(str(Path.home()), "~")}',file=sys.stderr)
        return 1
    for path,step in failures:
        print(f'native preflight: missing or invalid {path.replace(str(Path.home()), "~")}; run: {step}',file=sys.stderr)
    if failures: return 1
    print(f'native preflight: {args.stage} prerequisites verified')
    return 0


if __name__=='__main__':
    sys.exit(main())
