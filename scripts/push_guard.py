#!/usr/bin/env python3
"""Local pre-push guard. Reads Git's ref-update stdin; never prints matching values.

Checks every newly outgoing blob, including intermediate commits, and validates
mock freshness and the reviewed instruction pair at each outgoing commit.
"""
import hashlib
import importlib.util
import io
import json
import re
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

LIMIT = 50 * 1024 * 1024
ZERO = '0' * 40
EMAIL = re.compile(r'\b([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})\b')
ROLES = {'info', 'support', 'contact', 'privacy', 'licensing', 'legal', 'help', 'sales', 'press', 'admin', 'data', 'webmaster', 'noreply', 'no-reply'}
EXAMPLE_DOMAINS = {'example.com', 'example.org', 'example.net', 'test.invalid'}
PERSONAL_PATH = re.compile(r'(?:/Us' r'ers/|/ho' r'me/|[A-Za-z]:[\\/]Users[\\/])[^\s/\\<>$"\']+')
SECRETS = [
    re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    re.compile(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    re.compile(r'\bgh[pousr]_[A-Za-z0-9]{30,}\b'),
    re.compile(r'\bgithub_pat_[A-Za-z0-9_]{30,}\b'),
    re.compile(r'\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b'),
    re.compile(r'\bxox[baprs]-[A-Za-z0-9-]{15,}\b'),
    re.compile(r'''(?i)(?:api[_-]?key|access[_-]?token|secret|password)\s*["']?\s*[:=]\s*["']([^"'\n]{12,})["']'''),
]


def git(*args, cwd=None):
    return subprocess.run(['git', *args], cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout


def findings(data):
    # Byte scan even for binary blobs: printable embedded credentials still count.
    text = data.decode('utf-8', errors='replace')
    result = []
    if any(p.search(text) for p in SECRETS):
        result.append('possible secret/key')
    if PERSONAL_PATH.search(text):
        result.append('personal absolute path')
    if any(local.lower() not in ROLES and domain.lower() not in EXAMPLE_DOMAINS
           and not domain.lower().endswith('.example') for local, domain in EMAIL.findall(text)):
        result.append('possible personal email')
    return result


def instruction_check(read, changed):
    try:
        manifest = json.loads(read('scripts/instruction-pair.json'))
        if any(hashlib.sha256(read(p)).hexdigest() != manifest['sha256'][p] for p in ('AGENTS.md', 'CLAUDE.md')):
            return ['instruction drift: reviewed pair fingerprint differs']
        touched = set(changed) & {'AGENTS.md', 'CLAUDE.md'}
        if touched and touched != {'AGENTS.md', 'CLAUDE.md'}:
            return ['instruction drift: both instruction files must change in the same commit']
        return []
    except (KeyError, ValueError, subprocess.CalledProcessError):
        return ['instruction drift: missing/invalid reviewed pair']


def mock_check(commit, cwd=None):
    # Export only compiler inputs/outputs; check committed snapshots, never dirty files.
    paths = ['Tools/lookloop', 'docs/proposals', 'docs/lookloop/mock-conflicts.md',
             'Resources/look/mock-values.json', 'Sources/WorldGen/Profiles/mock-values.json',
             'docs/research-gpt/street-geometry-rules-v1/rules.csv']
    try:
        archive = git('archive', commit, '--', *paths, cwd=cwd)
        with tempfile.TemporaryDirectory(prefix='a7-push-') as tmp:
            root = Path(tmp)
            with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
                tar.extractall(root, filter='data')
            # Use this guard's compiler implementation, against the pushed input tree.
            compiler = Path(__file__).resolve().parents[1] / 'Tools/lookloop/compile_mocks.py'
            spec = importlib.util.spec_from_file_location('guard_mock_compiler', compiler)
            cm = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(cm)
            doc = cm.build(root)
            expected = {'Resources/look/mock-values.json': cm.render(doc),
                        'Sources/WorldGen/Profiles/mock-values.json': cm.render(cm.bundle_doc(doc, root)),
                        'docs/lookloop/mock-conflicts.md': cm.render_conflicts_md(doc)}
            return [] if all((root / p).read_text() == value for p, value in expected.items()) else ['stale mock-values']
    except Exception:
        return ['mock-values freshness check failed (missing or invalid committed inputs)']


def outgoing(local, remote, remote_name, cwd=None):
    args = ['rev-list', local]
    if remote != ZERO:
        args += ['^' + remote]
    else:
        # A new branch/tag needs only objects absent from known refs of this remote.
        refs = git('for-each-ref', '--format=%(objectname)', f'refs/remotes/{remote_name}/', cwd=cwd).decode().split()
        args += ['^' + ref for ref in refs]
    return git(*args, cwd=cwd).decode().split()


def check(commits, cwd=None, check_mocks=True):
    errors, seen = [], set()
    for commit in commits:
        changed = git('diff-tree', '--root', '-m', '--no-commit-id', '--name-only', '-r', '-z', commit, cwd=cwd).decode().split('\0')
        read = lambda p: git('show', f'{commit}:{p}', cwd=cwd)
        errors.extend(f'{commit[:10]}: {reason}' for reason in instruction_check(read, changed))
        if check_mocks:
            errors.extend(f'{commit[:10]}: {reason}' for reason in mock_check(commit, cwd))
        # Raw diff includes each parent of a merge, catching merge resolutions as well.
        raw = git('diff-tree', '--root', '-m', '--no-commit-id', '-r', '--raw', '-z', commit, cwd=cwd).split(b'\0')
        for i in range(0, len(raw)-1, 2):
            fields = raw[i].split()
            if len(fields) != 5:
                continue
            oid, status = fields[3].decode(), fields[4].decode()
            if status == 'D' or oid in seen:
                continue
            seen.add(oid)
            # Do not echo paths: a filename can itself contain private information.
            size = int(git('cat-file', '-s', oid, cwd=cwd))
            reasons = ['file over 50 MB'] if size > LIMIT else findings(git('cat-file', 'blob', oid, cwd=cwd))
            reasons += findings(raw[i+1])
            errors.extend(f'{commit[:10]} blob {oid[:10]}: {r}' for r in reasons)
    return sorted(set(errors))


def main():
    try:
        commits = set()
        remote_name = sys.argv[1] if len(sys.argv) > 1 else 'origin'
        for line in sys.stdin:
            _, local, _, remote = line.split()
            if local != ZERO:  # deletion sends no new objects
                commits.update(outgoing(local, remote, remote_name))
        errors = check(sorted(commits))
    except Exception:
        print('Push blocked: guard could not verify the outgoing commits.', file=sys.stderr)
        return 1
    if errors:
        print('Push blocked:\n' + '\n'.join(errors), file=sys.stderr)
        return 1
    print(f'Push guard: {len(commits)} outgoing commit(s) checked.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
