#!/usr/bin/env python3
"""Bound a capture process group so heavy.sh always regains control and releases its lock."""
import argparse
import math
import os
import signal
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--seconds', type=float, default=900)
    parser.add_argument('--grace', type=float, default=10)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if not math.isfinite(args.seconds) or not math.isfinite(args.grace) or args.seconds <= 0 or args.grace < 0 or not args.command:
        parser.error('positive timeout, nonnegative grace and command required')
    child = subprocess.Popen(args.command, start_new_session=True)
    interrupted = []

    def stop(signum, _frame):
        interrupted.append(signum)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    deadline = time.monotonic() + args.seconds
    status = None
    try:
        while child.poll() is None:
            if interrupted or time.monotonic() >= deadline:
                status = 128 + interrupted[0] if interrupted else 124
                print('web capture refused to continue: interrupted' if interrupted else
                      f'web capture timeout: {args.seconds:g}s; terminating owned capture group', file=sys.stderr)
                break
            time.sleep(0.05)
        if status is None:
            code = child.wait()
            return code if code >= 0 else 128 - code
    finally:
        # TERM gives the worker's trap time to close its browser/server. KILL is bounded.
        try:
            os.killpg(child.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        if child.poll() is None:
            try:
                child.wait(timeout=args.grace)
            except subprocess.TimeoutExpired:
                pass
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        child.wait()
    return status


if __name__ == '__main__':
    sys.exit(main())
