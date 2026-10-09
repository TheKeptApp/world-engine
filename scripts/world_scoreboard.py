#!/usr/bin/env python3
"""One finite, manual scoreboard run; per-block heavy admission, no data fetching."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / 'docs/scoreboard/world-scoreboard-v0.json'
LADDER = ROOT / 'scripts/web_sloans_ladder.json'
RENDERER = 'shipping-web-modules/WebGL2/package-light-state/crown-off/no-host-character'
THRESHOLDS = dict(blankGroundFraction=.35, buildingRelativeError=.02, tunnelSurfaceY=-.1,
                  clippingSegmentPixels=2, clippedStaticFraction=.01, pixelVariance=4, pixelRange=10,
                  probeColumns=81, probeRows=45)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inventory(root):
    """All held manifests in stable ID order, never duplicate places to reach twelve."""
    blocks, missing, seen = [], [], set()
    for path in sorted((root / 'Data/areas').glob('*/manifest.json')):
        manifest = json.loads(path.read_text())
        area = manifest['id']
        if area != path.parent.name or area in seen:
            raise ValueError('Area IDs must be unique and match directory names: ' + area)
        seen.add(area)
        required = []
        for source in manifest['sources']:
            file = path.parent / source['path']
            if not file.is_file():
                required.append(source['path'])
            elif source.get('sha256') and digest(file.read_bytes()) != source['sha256']:
                raise ValueError('Held source hash disagrees with manifest: ' + area + '/' + source['path'])
        if required:
            missing.append(dict(area=area, reason='Missing held source files', files=required))
            continue
        if not any(s['format'] == 'osm-overpass-json' and 'all' in s['layers'] for s in manifest['sources']):
            missing.append(dict(area=area, reason='No held core OSM all layer'))
            continue
        files = {str(p.relative_to(root)): digest(p.read_bytes()) for p in sorted(path.parent.rglob('*')) if p.is_file()}
        blocks.append(dict(area=area, center=manifest['center'], width=manifest['widthMeters'],
                           height=manifest['heightMeters'], sources=manifest['sources'],
                           sourceFiles=files, sourceHash=digest(json.dumps(files, sort_keys=True).encode())))
    return sorted(blocks, key=lambda b: b['area']), missing


def code_hashes(root):
    paths = []
    for folder in ('Sources/WorldGen', 'Sources/WorldMap', 'Sources/WorldPackage', 'Sources/WorldGeo',
                   'Sources/WorldMesh', 'Sources/WorldEnvironment', 'web/src'):
        paths.extend(p for p in (root / folder).rglob('*') if p.is_file())
    paths.extend(root / p for p in ('Package.swift', 'Package.resolved', 'web/package-lock.json',
                                   'web/bakeoff/budget.js', 'scripts/web_sloans_ladder.json',
                                   'scripts/web_capture_blocks.mjs', 'scripts/web_capture_server.mjs',
                                   'scripts/world_scoreboard_checks.mjs', 'scripts/world_scoreboard_page.mjs',
                                   'scripts/world_scoreboard_probes.mjs', 'scripts/world_scoreboard_block.mjs',
                                   'scripts/world_scoreboard.py', 'scripts/world-scoreboard.sh'))
    return {str(p.relative_to(root)): digest(p.read_bytes()) for p in sorted(set(paths)) if p.is_file()}


def run_bounded_step(command, log):
    """Only two tries. heavy.sh releases between attempts and blocks."""
    env = dict(os.environ, HEAVY_AGENT='A7 world scoreboard')
    attempts = []
    for attempt in (1, 2):
        started = time.monotonic()
        with log.open('a') as stream:
            stream.write(f'Attempt {attempt}: {command[1]}\n'); stream.flush()
            child = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT)
            def stop(signum, _frame):
                child.send_signal(signal.SIGTERM)
                try:
                    child.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    child.kill(); child.wait()
                raise KeyboardInterrupt
            prior = {s: signal.signal(s, stop) for s in (signal.SIGINT, signal.SIGTERM)}
            try:
                code = child.wait()
            finally:
                for s, handler in prior.items():
                    signal.signal(s, handler)
        attempts.append(dict(attempt=attempt, exitCode=code, seconds=round(time.monotonic() - started, 3)))
        if code == 0:
            return attempts
        print(f'Scoreboard step failed ({attempt}/2), exit {code}; owned lock released. Log: {log}', flush=True)
    raise RuntimeError('Step failed twice; stopped. ' + log.read_text()[-2500:])


def render_report(report):
    lines = ['# World scoreboard v0 — automatic technical screen', '',
             f"Status: **{report['status']}**. Commit `{report['commit']}`; {report['seconds']:.1f} s wall time, including admission waits.",
             f"Selection: all {len(report['selection']['areas'])} held areas, sorted by ID; shortfall to 12: {report['selection']['shortfallTo12']}. No data fetched.",
             f"Renderer: `{RENDERER}`. Counts are submissions, not package totals; standard limits are provisional. No human grades.", '',
             '| Block | Type | m | Main tris/draws | Shadow tris/draws | Floor | Standard | Blank ground | Buildings source/export | Water source/export | Parks source/export | Tunnel strips | Near clip triangles |',
             '|---|---|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|']
    for row in report['rows']:
        m = row['metrics']; tiers = row['tiers']
        lines.append(f"| {row['area']} | {row['type']} | {row['altitude']} | {m['mainTriangles']}/{m['mainDraws']} | {m['shadowTriangles']}/{m['shadowDraws']} | {'PASS' if tiers['floor']['pass'] else 'FAIL'} | {'PASS' if tiers['standard']['pass'] else 'FAIL'} | {m['blankGroundFraction']:.1%} | {m['sourceBuildings']}/{m['exportedBuildings']} | {m['sourceWater']}/{m['exportedWater']} | {m['sourceParks']}/{m['exportedParks']} | {m['tunnelSurfaceRanges']} | {m['nearClipTriangles']} |")
    lines.extend(['', '## Failures and warnings', ''])
    failures = [f"- {r['key']}: {', '.join(r['failures'])}" for r in report['rows'] if r['failures']]
    lines.extend(failures or ['- None.'])
    lines.extend(f"- {r['key']}: WARNING {', '.join(r['warnings'])}; occlusion not resolved." for r in report['rows'] if r['warnings'])
    lines.extend('- Unavailable: ' + json.dumps(m, sort_keys=True) for m in report['selection']['missing'])
    if report.get('error'):
        lines.extend(['', '## Operational stop', '', report['error']])
    lines.extend(['', '## Diff against previous JSON', '', '```json', json.dumps(report.get('diff'), indent=2), '```', ''])
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--previous', type=Path, help='Default: existing --output JSON before this run')
    args = parser.parse_args()
    output = args.output.resolve(); previous_path = (args.previous or output).resolve()
    previous = json.loads(previous_path.read_text()) if previous_path.exists() else None
    started = time.monotonic()
    blocks, missing = inventory(ROOT)
    if not blocks:
        parser.error('No eligible held areas; no data fetched')
    frozen = code_hashes(ROOT)
    ladder = json.loads(LADDER.read_text())
    harness = {k: v for k, v in frozen.items() if k.startswith('scripts/world_scoreboard') or k.endswith('scripts/world-scoreboard.sh')}
    # Renderer/exporter changes are the subject of a diff, not a reason to suppress it.
    harness_hash = digest(json.dumps(harness, sort_keys=True).encode())
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    run = ROOT / '.build/world-scoreboard' / str(uuid.uuid4()); run.mkdir(parents=True)
    report = dict(schema='world-scoreboard/0', status='running', commit=commit,
                  startedUTC=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  renderer=RENDERER, thresholds=THRESHOLDS, sourceCodeHashes=frozen,
                  selection=dict(rule='Every Data/areas/*/manifest.json with held, hash-valid core sources; ID ascending; no duplicates or fetches',
                                 areas=[b['area'] for b in blocks], shortfallTo12=max(0, 12 - len(blocks)), missing=missing),
                  blocks=[], rows=[], steps=[], seconds=0,
                  previousJSONSha256=digest(previous_path.read_bytes()) if previous_path.exists() else None)
    try:
        prepare = ['bash', str(ROOT / 'scripts/heavy.sh'), 'scoreboard: build existing exporter and web dependencies',
                   'python3', str(ROOT / 'scripts/capture_timeout.py'), '--seconds', '1800', 'bash', '-c',
                   'swift build -c release --product worldbake && npm ci --prefix web --no-audit --no-fund']
        report['steps'].append(dict(step='prepare', attempts=run_bounded_step(prepare, run / 'prepare.log')))
        for block in blocks:
            if code_hashes(ROOT) != frozen or inventory(ROOT)[0] != blocks:
                raise RuntimeError('Inputs changed during run; stopped without mixing revisions')
            pose = ladder['pose'] if block['area'] == ladder['area'] else dict(lat=block['center']['latitude'], lon=block['center']['longitude'], heading=270, pitchDown=45, fov=50)
            dest = run / block['area']
            spec = dict(block, pose=pose, utc=ladder['utc'], altitudes=ladder['altitudesAGLMetres'],
                        viewport=ladder['viewport'], commit=commit, output=str(dest), renderer=RENDERER,
                        detectorContract=THRESHOLDS, harnessHash=harness_hash)
            spec_path = run / (block['area'] + '.json'); spec_path.write_text(json.dumps(spec))
            print('Scoreboard block: ' + block['area'], flush=True)
            command = ['bash', str(ROOT / 'scripts/heavy.sh'), 'scoreboard: ' + block['area'] + ' export and 40/150/600 m',
                       'python3', str(ROOT / 'scripts/capture_timeout.py'), '--seconds', '1200',
                       'node', str(ROOT / 'scripts/world_scoreboard_block.mjs'), str(spec_path)]
            attempts = run_bounded_step(command, run / (block['area'] + '.log'))
            result = json.loads((dest / 'block.json').read_text())
            result['sourceHash'] = block['sourceHash']; result['sourceFiles'] = block['sourceFiles']
            report['blocks'].append(result); report['rows'].extend(result['rows']); report['steps'].append(dict(step=block['area'], attempts=attempts))
            print(block['area'] + ': 3 frames complete; lock released', flush=True)
        if code_hashes(ROOT) != frozen or inventory(ROOT)[0] != blocks:
            raise RuntimeError('Inputs changed during run; final evidence invalid')
        report['status'] = 'completed-with-failures' if any(r['failures'] for r in report['rows']) else 'completed'
    except (Exception, KeyboardInterrupt) as error:
        report['status'] = 'stopped'; report['error'] = str(error) or 'Interrupted'
    report['seconds'] = round(time.monotonic() - started, 3)
    # Pure diff utility runs without acquiring a heavy lock.
    temp = run / 'report.json'; temp.write_text(json.dumps(report))
    prev = run / 'previous.json'; prev.write_text(json.dumps(previous))
    diff = subprocess.check_output(['node', '--input-type=module', '-e',
        "import {readFile} from 'node:fs/promises'; import {compareRuns} from './scripts/world_scoreboard_checks.mjs'; console.log(JSON.stringify(compareRuns(JSON.parse(await readFile(process.argv[1])),JSON.parse(await readFile(process.argv[2])))));", str(temp), str(prev)], cwd=ROOT, text=True)
    report['diff'] = json.loads(diff)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + '\n')
    report_path = output.with_suffix('.md'); report_path.write_text(render_report(report))
    print(f"{report['status']}: {len(report['rows'])} frames, {report['seconds']:.1f} s. JSON: {output}. Report: {report_path}", flush=True)
    return 1 if report['status'] == 'stopped' else 0


if __name__ == '__main__':
    sys.exit(main())
