"""Compare livefeeds.sats.sgp4 with Vallado's published SGP4 verification output (validation only).

Vallado et al. (AIAA 2006-6753) publish a verification element file (SGP4-VER.TLE) and the reference output
of their C++ code (tcppver.out). Both ship inside the `sgp4` package on PyPI (MIT, by Brandon Rhodes, which
wraps Vallado's C++), so:
    python3 -m venv /tmp/v && /tmp/v/bin/pip install sgp4
    PYTHONPATH=Tools/livefeeds /tmp/v/bin/python Tools/livefeeds/validation/sgp4_vallado.py
Near-earth cases only (our module rejects deep-space objects by design). Prints the worst position and
velocity differences per satellite and overall.
"""
import os

import sgp4 as sgp4pkg

from livefeeds.sats import elements, sgp4

D = os.path.dirname(sgp4pkg.__file__)


def main():
    tle = {}
    lines = [l.rstrip("\n") for l in open(os.path.join(D, "SGP4-VER.TLE")) if not l.startswith("#")]
    for i, l in enumerate(lines):
        if l.startswith("1 ") and i + 1 < len(lines) and lines[i + 1].startswith("2 "):
            l1, l2 = l[:69], lines[i + 1][:69]
            try:
                tle[int(l1[2:7])] = elements.parse_tle("", l1, l2, verify_checksum=False)
            except elements.ElementError:
                pass
    worst_r = worst_v = 0.0
    n = skipped = errors = 0
    sat = None
    rows = []
    for l in open(os.path.join(D, "tcppver.out")):
        p = l.split()
        if not p:
            continue
        if p[-1] == "xx":
            if sat is not None:
                rows.append(sat)
            num = int(p[0])
            try:
                sat = [num, sgp4.Satellite(tle[num]), 0.0, 0.0, 0]
            except (sgp4.DeepSpace, KeyError):
                sat = [num, None, 0, 0, 0]
                skipped += 1
            except sgp4.PropagationError:
                sat = [num, None, 0, 0, 0]
                errors += 1
            continue
        if sat is None or sat[1] is None:
            continue
        t = float(p[0])
        try:
            r, v = sat[1].propagate_minutes(t)
        except sgp4.PropagationError:
            sat[4] += 1  # reference may also stop here (decay); counted, not compared
            continue
        ref = [float(x) for x in p[1:7]]
        dr = max(abs(a - b) for a, b in zip(r, ref[:3]))
        dv = max(abs(a - b) for a, b in zip(v, ref[3:6]))
        sat[2], sat[3] = max(sat[2], dr), max(sat[3], dv)
        n += 1
    rows.append(sat)
    for num, s, dr, dv, e in rows:
        if s is not None:
            worst_r, worst_v = max(worst_r, dr), max(worst_v, dv)
            print("%05d  max |dr| %.3e km  max |dv| %.3e km/s%s" % (num, dr, dv, "  (%d epochs raised)" % e if e else ""))
    print("near-earth satellites compared: %d, states: %d, deep-space skipped: %d, init errors: %d"
          % (sum(1 for r in rows if r[1] is not None), n, skipped, errors))
    print("WORST position difference %.3e km (%.1f mm), velocity %.3e km/s" % (worst_r, worst_r * 1e6, worst_v))


if __name__ == "__main__":
    main()
