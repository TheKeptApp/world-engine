#!/usr/bin/env python3
"""Check the engine's data values against the R-approved mock values.

Loads Resources/look/mock-values.json, Tools/lookloop/mock-mapping.json, the engine profile JSON and
docs/lookloop/mock-exceptions.md. Tolerances: colours CIE76 dE <= 5 (Lab from sRGB, D65);
scalars within +-5 % relative, or +-0.02 absolute when |mock| < 0.4.
Exit 1 if any non-excepted mapped row fails. Mappings of house-contrast-v1 sharedLighting (the daytime
master, R 2026-10-07) compare against this checkout's engine files (main); an optional "phase5b" field
in the mapping (e.g. phase5b paintover-grade.json values) is printed in the note column, never scored.

Usage: python3 Tools/lookloop/conformance.py
"""
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VALUES = ROOT / "Resources/look/mock-values.json"
MAPPING = ROOT / "Tools/lookloop/mock-mapping.json"
EXCEPTIONS = ROOT / "docs/lookloop/mock-exceptions.md"
DE_MAX, REL_MAX, ABS_MAX, ABS_BELOW = 5.0, 0.05, 0.02, 0.4


def srgb_to_lab(hexstr):
    h = hexstr.lstrip("#")
    rgb = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    r, g, b = lin
    x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
    y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * b)
    z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    fx, fy, fz = f(x), f(y), f(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def delta_e76(a, b):
    return math.dist(srgb_to_lab(a), srgb_to_lab(b))


def scalar_ok(mock, engine):
    if abs(mock) < ABS_BELOW:
        return abs(engine - mock) <= ABS_MAX
    return abs(engine - mock) <= REL_MAX * abs(mock)


def resolve(data, path):
    """Dots, [i] list indices and [id=X] list selectors."""
    for tok in re.findall(r"[^.\[\]]+|\[[^\]]+\]", path):
        if tok.startswith("["):
            inner = tok[1:-1]
            if "=" in inner:
                k, v = inner.split("=", 1)
                data = next(x for x in data if str(x.get(k)) == v)
            else:
                data = data[int(inner)]
        else:
            data = data[tok]
    return data


def parse_exceptions(text):
    """{mock key: status} for table rows whose status column says 'R approved'."""
    out = {}
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5 or set(cells[0]) <= set("-: ") or cells[0] == "Mock key":
            continue
        if "R approved" in cells[-1]:
            out[cells[0].strip("`")] = cells[-1]
    return out


def engine_final(m, cache):
    def load(f):
        if f not in cache:
            cache[f] = json.loads((ROOT / f).read_text())
        return cache[f]
    raw = resolve(load(m["engine"]["file"]), m["engine"]["path"])
    factors = [resolve(load(f["file"]), f["path"]) for f in m.get("factors", [])]
    t = m["transform"]
    if t == "multiply":
        for f in factors:
            raw *= f
        return raw, False
    if t == "log2_ratio":
        return math.log2(raw / factors[0]), False
    return raw, t != "none"


def run(values=None, mapping=None, exceptions=None):
    values = values or json.loads(VALUES.read_text())["entries"]
    mapping = mapping or json.loads(MAPPING.read_text())
    exceptions = exceptions if exceptions is not None else parse_exceptions(EXCEPTIONS.read_text())
    rows, cache = [], {}
    for m in mapping["mappings"]:
        mock = values[m["mock"]]["value"]
        eng, raw = engine_final(m, cache)
        if m["kind"] == "colour":
            d = delta_e76(mock, eng)
            ok, delta, size = d <= DE_MAX, f"dE {d:.1f}", d / DE_MAX
        else:
            ok = scalar_ok(mock, eng)
            tol = ABS_MAX if abs(mock) < ABS_BELOW else REL_MAX * abs(mock)
            delta, size = f"{eng - mock:+.4g}", abs(eng - mock) / tol
        status = "pass" if ok else ("excepted" if m["mock"] in exceptions else "FAIL")
        if raw:
            status += " (raw, transform not modelled)"
        engs = eng if isinstance(eng, str) else f"{eng:.4g}"
        rows.append({"key": m["mock"], "mock": mock, "engine": engs, "delta": delta, "status": status, "size": size,
                     "note": ("phase5b: " + m["phase5b"]) if m.get("phase5b") else ""})
    return rows


def main():
    rows = run()
    w = max(len(r["key"]) for r in rows)
    print(f"{'key':<{w}}  {'mock':>9}  {'engine final':>12}  {'delta':>9}  status  [note]")
    for r in rows:
        note = f"  [{r['note']}]" if r["note"] else ""
        print(f"{r['key']:<{w}}  {str(r['mock']):>9}  {r['engine']:>12}  {r['delta']:>9}  {r['status']}{note}")
    fails = [r for r in rows if r["status"].startswith("FAIL")]
    passes = [r for r in rows if r["status"].startswith("pass")]
    unmapped = len(json.loads(MAPPING.read_text())["unmapped"])
    print(f"\n{len(rows)} mapped: {len(passes)} pass, {len(fails)} fail, "
          f"{len(rows) - len(passes) - len(fails)} excepted; {unmapped} unmapped keys")
    master = [r for r in rows if "/sharedLighting." in r["key"]]
    print(f"daytime master (house-contrast-v1 sharedLighting): {len(master)} mapped, "
          f"{sum(r['status'].startswith('pass') for r in master)} pass, {sum(r['status'].startswith('FAIL') for r in master)} fail")
    print("biggest deltas (in tolerance units):")
    for r in sorted(rows, key=lambda r: -r["size"])[:5]:
        print(f"  {r['key']}: mock {r['mock']} engine {r['engine']} ({r['delta']}, {r['size']:.1f}x tol)")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
