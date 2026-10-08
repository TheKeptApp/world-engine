#!/usr/bin/env python3
"""Worker for capture-native.sh; the shell entry point acquires the heavy lock."""
import argparse
import hashlib
import json
import os
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
    parser.add_argument('--output', type=Path, help='new run directory; defaults to .build/lookloop/native-<unique ID>')
    args = parser.parse_args()
    run = (args.output or ROOT / '.build/lookloop' / f'native-{uuid.uuid4().hex[:12]}').resolve()
    started = time.monotonic()
    started_wall = time.time()
    created_run = False
    try:
        view = frozen_view(ROOT, args.view)
        if shutil.disk_usage(ROOT).free < 8 * 1024**3:
            raise ValueError('less than 8 GB free; native capture not started')
        run.mkdir(parents=True, exist_ok=False)  # never accept frames from an earlier run
        created_run = True
        (run / 'views.tsv').write_text(view['id'] + '\t' + ' '.join(view['args']) + '\n')
        timings = {}
        env = dict(os.environ)
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
        report = dict(timings, crashes=crash_evidence(started_wall), view=args.view, args=view['args'], frame=str(frame), size=size, sha256=digest,
                      commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip())
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
