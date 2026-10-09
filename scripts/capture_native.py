#!/usr/bin/env python3
"""Worker for capture-native.sh; the shell entry point acquires the heavy lock."""
import argparse
import hashlib
import json
import math
import os
import re
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]


def frozen_view(root, view_id):
    contract = json.loads((root / 'docs/lookloop/a3-capture-contract.json').read_text())
    current = json.loads((root / 'Tools/lookloop/views.json').read_text())
    if contract['commonArgs'] != current['commonArgs']:
        raise ValueError('capture common arguments differ from the frozen A3 contract')
    return next(v for v in contract['views'] if v['id'] == view_id)


def inspection_view(view, pose, mode):
    """R's 8 Oct A10 capture override; frozen hero defaults remain unchanged when absent."""
    result = dict(view)
    args = list(view['args'])
    if pose is not None:
        values = [float(v) for v in pose.split(',')]
        if len(values) != 5 or not all(math.isfinite(v) for v in values):
            raise ValueError('inspection pose requires five finite values')
        lat, lon, alt, heading, pitch = values
        if not (-90 <= lat <= 90 and -180 <= lon <= 180 and 8 <= alt <= 1500 and 5 <= pitch <= 85):
            raise ValueError('inspection pose outside capture limits')
        # Capture only: same fixed weather/clock as the requested A10 inspection controls.
        remove = {'-preset', '-showcase', '-camera', '-mode', '-character', '-weatherspec', '-inspectionpose'}
        filtered = []
        i = 0
        while i < len(args):
            if args[i] in remove: i += 2
            else: filtered.append(args[i]); i += 1
        args = filtered + ['-character', 'none', '-weatherspec', 'label=clear,cloud=0,wind=0', '-inspectionpose', pose]
    if mode is not None:
        if mode not in ('off', 'remove', 'layered'): raise ValueError('invalid foliage experiment mode')
        args += ['-foliageexp1', mode]
    result['args'] = args
    return result


def verify_frame(run, view_id):
    rows = (run / 'capture.tsv').read_text().splitlines()
    if len(rows) != 1 or rows[0].split('\t')[:2] != [view_id, 'ok']:
        raise ValueError('capture did not record exactly one successful requested view')
    frame = run / 'raw' / f'{view_id}.png'
    data = frame.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n' or len(data) < 24:
        raise ValueError('capture frame is not a PNG')
    size = struct.unpack('>II', data[16:24])
    if not all(size):
        raise ValueError('capture frame has empty dimensions')
    return frame, size, hashlib.sha256(data).hexdigest()


def context_expected(root, view):
    args = view['args']
    common = json.loads((root / 'docs/lookloop/a3-capture-contract.json').read_text())['commonArgs']
    if any('noContext' in arg.split(',') for arg in args + common):
        return False
    area = args[args.index('-area') + 1] if '-area' in args else 'sloans-lake'
    if '/' in area or area in ('.', '..'):
        raise ValueError('invalid capture area id')
    manifest = json.loads((root / 'Data/areas' / area / 'manifest.json').read_text())
    return any(source.get('format') == 'osm-overpass-json' and 'context' in source.get('layers', [])
               and 'all' not in source.get('layers', []) for source in manifest['sources'])


def verify_scene_readiness(run, view_id, require_context, require_scene_ready=False):
    """Require the opt-in Metal-completion handshake; CPU-only mode audits old artifacts."""
    matched = []
    for path in sorted((run / 'logs').glob('_launch-*.log')):
        lines = path.read_text(errors='replace').splitlines()
        if any(line.startswith('CROWN_ADAPTER_FAILED') for line in lines):
            raise ValueError('crown adapter accounting failed; candidate capture rejected')
        shots = [i for i, line in enumerate(lines)
                 if line.startswith(f'VIEWSHOT id={view_id} ') and 'file=' in line]
        for shot in shots:
            before = lines[:shot]
            completions = [i for i, line in enumerate(before) if re.match(r'CONTEXT cells=\d+ ', line)]
            if require_context and not completions:
                raise ValueError('scene not ready: context attachment did not complete before VIEWSHOT; no automatic recapture')
            ready = [i for i, line in enumerate(before) if line == f'VIEWREADY id={view_id}']
            if require_context and (not ready or completions[-1] >= ready[-1]):
                raise ValueError('scene not ready: context attachment must precede VIEWREADY, not just the saved-image log')
            if any(line.startswith('CONTEXT failed:') for line in before) and require_context:
                raise ValueError('scene not ready: context loading failed')
            signals = [line for line in before if line.startswith(f'SCENEREADY id={view_id} ')]
            proof = None
            output_proof = None
            if require_scene_ready:
                if len(signals) != 1:
                    raise ValueError('scene not ready: missing or ambiguous SCENEREADY')
                proof = dict(field.split('=', 1) for field in signals[0].split()[1:])
                if proof.get('context') != ('ready' if require_context else 'not-required'):
                    raise ValueError('scene not ready: unexpected context state')
                if proof.get('exposure') != 'pinned-1':
                    raise ValueError('scene not ready: deterministic capture exposure was not confirmed')
                if int(proof.get('gpuCompleted', '0')) < 3 or int(proof.get('stableFrames', '0')) < 3:
                    raise ValueError('scene not ready: insufficient completed stable frames')
                if not re.fullmatch(r'[1-9]\d*x[1-9]\d*', proof.get('size', '')) or not proof.get('signature'):
                    raise ValueError('scene not ready: missing drawable or scene signature')
                signal_index = before.index(signals[0])
                if not ready or signal_index >= ready[-1] or (require_context and signal_index <= completions[-1]):
                    raise ValueError('scene not ready: SCENEREADY ordering is invalid')

            if require_context and not require_scene_ready and not any(line.startswith('VIEW t=') for line in before[completions[-1] + 1:]):
                raise ValueError('scene not ready: no post-attachment view update before VIEWSHOT')
            drawsplit = re.search(r'drawsplit\[([^]]+)\]', lines[shot])
            cost = re.search(r' triangles=(\d+) draws=(\d+) ', lines[shot])
            if not drawsplit or not cost:
                raise ValueError('capture lacks scene coverage counters')
            matched.append(dict(contextRequired=require_context, contextAttachedBeforeCapture=bool(completions),
                                gpuCompletionProved=proof is not None, captureExposure=({'mode': 'pinned', 'gain': 1.0} if proof else None), sceneReady=proof, outputStability=output_proof, triangles=int(cost[1]), draws=int(cost[2]),
                                drawsplit=drawsplit[1], launchLog=str(path), shotLine=shot + 1))
    if len(matched) != 1:
        raise ValueError('capture lacks one unambiguous launch-log VIEWSHOT')
    return matched[0]


def simulator_env(devices):
    booted = [d for group in devices['devices'].values() for d in group if d['state'] == 'Booted']
    if len(booted) > 1:
        raise ValueError('more than one Simulator is booted; finish the other lane before capture')
    return {'LOOKLOOP_UDID': booted[0]['udid']} if booted else {'LOOKLOOP_SIM': 'LookLoop iPhone 17 Pro'}


def crash_evidence(since):
    reports = []
    folder = Path.home() / 'Library/Logs/DiagnosticReports'
    for pattern in ('WorldLab-*.ips', 'SimMetalHost-*.ips'):
        for path in folder.glob(pattern):
            if path.stat().st_mtime >= since:
                try:
                    data = json.loads(path.read_text().split('\n', 1)[1])
                    reports.append({'file': path.name, 'time': data.get('captureTime'),
                                    'exception': data.get('exception'), 'termination': data.get('termination')})
                except (OSError, ValueError, IndexError):
                    reports.append({'file': path.name, 'detail': 'crash report could not be parsed'})
    return reports


def main():
    parser = argparse.ArgumentParser(description='Fresh-worktree native capture; call scripts/capture-native.sh.')
    parser.add_argument('--view', default='ordinary-street-afternoon')
    parser.add_argument('--inspectionpose', help='R A10: lat,lon,AGL metres,heading,pitch down; replaces hero framing only')
    parser.add_argument('--foliageexp1', choices=('off', 'remove', 'layered'), help='R A10 build variant, absent defaults off')
    parser.add_argument('--output', type=Path, help='new run directory; defaults to .build/lookloop/native-<unique ID>')
    args = parser.parse_args()
    run = (args.output or ROOT / '.build/lookloop' / f'native-{uuid.uuid4().hex[:12]}').resolve()
    started = time.monotonic()
    started_wall = time.time()
    created_run = False
    try:
        view = inspection_view(frozen_view(ROOT, args.view), args.inspectionpose, args.foliageexp1)
        view["args"] = view["args"] + ["-sceneready"]
        if shutil.disk_usage(ROOT).free < 8 * 1024**3:
            raise ValueError('less than 8 GB free; native capture not started')
        run.mkdir(parents=True, exist_ok=False)  # never accept frames from an earlier run
        created_run = True
        (run / 'views.tsv').write_text(view['id'] + '\t' + ' '.join(view['args']) + '\n')
        timings = {}
        env = dict(os.environ)
        env["FOLIAGE_EXP1_BUILD"] = args.foliageexp1 or "off"
        for key in ('LOOKLOOP_SIM', 'LOOKLOOP_UDID', 'SKIP_BUILD', 'LOOKLOOP_BATCH'):
            env.pop(key, None)
        with (run / 'pipeline.log').open('w') as log:
            for label, command in [('build', [str(ROOT / 'scripts/build-native.sh')]),
                                   ('capture', [str(ROOT / 'Tools/lookloop/capture.sh'), str(run), args.view])]:
                if label == 'capture':
                    devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '-j']))
                    env.update(simulator_env(devices))
                    env.update(SKIP_BUILD='1', LOOKLOOP_BATCH='1')
                print(f'native capture: {label}; log: {run / "pipeline.log"}', file=sys.stderr, flush=True)
                t = time.monotonic()
                subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
                timings[label + 'Seconds'] = round(time.monotonic() - t, 2)
        frame, size, digest = verify_frame(run, args.view)
        timings['totalSeconds'] = round(time.monotonic() - started, 2)
        readiness = verify_scene_readiness(run, args.view, context_expected(ROOT, view), require_scene_ready=True)
        report = dict(timings, sceneReadiness=readiness, crashes=crash_evidence(started_wall), view=args.view, args=view['args'], frame=str(frame), size=size, sha256=digest,
                      commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip())
        if args.foliageexp1 is not None:
            logs = '\n'.join(p.read_text(errors='replace') for p in sorted((run / 'logs').glob('_launch-*.log')))
            expected = f'FOLIAGE_EXP1 mode={args.foliageexp1} value={("off", "remove", "layered").index(args.foliageexp1)} defaultConstant=0'
            if expected not in logs: raise ValueError('captured launch did not confirm foliage mode')
        report['observedCameraLines'] = [line for p in sorted((run / 'logs').glob('_launch-*.log')) for line in p.read_text(errors='replace').splitlines() if line.startswith('CAMERA -inspectionpose ')]
        if args.inspectionpose and not report['observedCameraLines']: raise ValueError('capture did not report the inspection pose')
        report.update(inspectionPose=args.inspectionpose, foliageExp1=args.foliageexp1 or 'off', defaultConstant=0,
                      shaderSourceSHA256=hashlib.sha256((ROOT / 'Sources/WorldEngine/Shaders/WorldShaders.metal').read_bytes()).hexdigest())
        report['compiledConstant'] = ('off', 'remove', 'layered').index(args.foliageexp1 or 'off')
        source = ROOT / ('.build/foliage-exp1/current.metal' if report['compiledConstant'] else 'Sources/WorldEngine/Shaders/WorldShaders.metal')
        report['compiledShaderSourceSHA256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        app = ROOT / '.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app'
        report['metallibSHA256'] = {str(p.relative_to(app)): hashlib.sha256(p.read_bytes()).hexdigest() for p in app.rglob('default.metallib')}
        (run / 'native-capture.json').write_text(json.dumps(report, indent=2) + '\n')
        print(frame)  # stable stdout contract: the collected frame's absolute path
        return 0
    except (ValueError, StopIteration, OSError, subprocess.SubprocessError) as error:
        if created_run:
            (run / 'failure.json').write_text(json.dumps({'error': str(error), 'crashes': crash_evidence(started_wall)}, indent=2) + '\n')
        print(f'native capture failed: {error}; evidence: {run}'.replace(str(Path.home()), '~'), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
