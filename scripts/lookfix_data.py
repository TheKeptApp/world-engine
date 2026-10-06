#!/usr/bin/env python3
"""The lighting bible as engine data, generated from ChatGPT's look-fix pack (read-only input).

  scripts/lookfix_data.py          regenerate Sources/WorldGen/Profiles/lighting-bible.json and the
                                   bible-owned fields of Profiles/time-of-day.json
  scripts/lookfix_data.py --check  exit 1 if either is out of date with the proposal

Reads docs/proposals/look-fix-v1/lighting-fixtures.json (the twelve states: time, weather inputs,
sun and Moon) and LOOK-FIX-SPEC.md's tables (§2.2 state targets, §2.3 lift, shade tint and
clear-air fade, §2.4 night, §3.1 wet ground, §3.2 extinction presets). Nothing is copied by hand:
change the proposal, rerun this. Hand-tuned renderer values (saturation, fill and direct
multipliers) live in Profiles/grade.json, keyed by the same state names.
"""
import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK = "docs/proposals/look-fix-v1"
SPEC = f"{PACK}/LOOK-FIX-SPEC.md"
FIXTURES = f"{PACK}/lighting-fixtures.json"
OUT = "Sources/WorldGen/Profiles/lighting-bible.json"
TIME_OF_DAY = "Sources/WorldGen/Profiles/time-of-day.json"

# Spec row labels -> fixture state names (the ids without "lighting-NN-").
ROWS = {
    "morning": "morning", "midday": "midday", "ordinary 15:30": "ordinary-1530", "15:30": "ordinary-1530",
    "golden hour": "golden-hour", "golden": "golden-hour", "blue hour": "blue-hour", "overcast": "overcast",
    "light rain": "light-rain", "rain": "light-rain", "storm": "storm", "fog": "fog", "snow, overcast": "snow",
    "snow": "snow", "moon night": "moon-night", "moonless night": "moonless-night", "moonless": "moonless-night",
}
AIR_COLOR_KEYS = {"morning": "morning", "noon": "midday", "15:30": "ordinary-1530", "golden": "golden-hour",
                  "blue": "blue-hour", "overcast": "overcast", "snow": "snow", "moon": "moon-night", "moonless": "moonless-night"}
# Time-of-day keys the bible states drive (sun tint, sky-fill tint, shade tint).
TIME_KEYS = {"morning": "morning", "noon": "midday", "golden": "golden-hour", "dawn": "blue-hour", "dusk": "blue-hour",
             "night": "moon-night"}
HEX = r"#[0-9A-Fa-f]{6}"


def sha(path):
    return hashlib.sha256(open(os.path.join(ROOT, path), "rb").read()).hexdigest()


def table(text, header_start):
    """Rows (lists of cell strings) of the markdown table whose header begins with header_start."""
    lines = text.splitlines()
    i = next(k for k, l in enumerate(lines) if l.startswith("| " + header_start))
    rows = []
    for l in lines[i + 2:]:
        if not l.startswith("|"):
            break
        rows.append([c.strip() for c in l.strip().strip("|").split("|")])
    return rows


def number(s):
    return float(s.replace("−", "-").replace("+", ""))


def build():
    spec = open(os.path.join(ROOT, SPEC), encoding="utf-8").read()
    fixtures = json.load(open(os.path.join(ROOT, FIXTURES)))
    states = {}
    for f in fixtures["fixtures"]:
        name = f["id"].split("-", 2)[2]
        states[name] = {
            "fixture": f["id"], "utc": f["utc"], "elevation": round(f["sun"]["elevationDeg"], 4),
            "azimuth": round(f["sun"]["azimuthDeg"], 4),
            "weather": {k: f[k] for k in ("cloudCover", "rainMmPerHour", "wetness", "snowCover")},
            "moon": {"altitude": round(f["moon"]["altitudeDeg"], 4), "illuminatedFraction": round(f["moon"]["illuminatedFraction"], 5)},
        }
    # §2.2
    for cells in table(spec, "State | Direct / sky-fill tint"):
        s = states[ROWS[cells[0].lower()]]
        hexes = re.findall(HEX, cells[1])
        s["directTint"] = hexes[0] if len(hexes) == 2 else None
        s["skyFillTint"] = hexes[-1]
        s["keyFill"] = number(cells[2])
        s["ev"] = number(cells[3])
        m = re.match(r"(\d+);\s*(\d+)/(\d+)/(\d+)", cells[4])
        s["luma"], s["p5"], s["p50"], s["p95"] = (int(x) for x in m.groups())
        s["saturationS"] = int(cells[5])
    # §2.3
    for cells in table(spec, "State | Solar height multiplier"):
        s = states[ROWS[cells[0].lower()]]
        lift = re.findall(r"\d\.\d+", cells[2])
        s["lift"] = [float(lift[0]), float(lift[1])] if len(lift) == 2 else None
        s["shadeTint"] = re.findall(HEX, cells[3])[0]
        m = re.match(r"(\d+)→(\d+)(?: m)? / (\d+)%", cells[5])
        s["air"] = {"start": int(m.group(1)), "d50": int(m.group(2)), "cap": int(m.group(3)) / 100} if m else None
    colors = re.search(r"Clear-air fade color: (.*)", spec).group(1)
    for key, hexv in re.findall(r"(15:30|[a-z]+) (" + HEX + ")", colors):
        state = states[AIR_COLOR_KEYS[key]]
        if state.get("air"):
            state["air"]["color"] = hexv
    for s in states.values():  # "weather override": the weather's extinction takes the distance
        if s.get("air") is None:
            s["air"] = {"start": 180, "d50": 1200, "cap": 0.0, "color": "#AAB8C8"}
    # §2.4
    night = {}
    m = re.search(r"horizon (" + HEX + r") to upper (" + HEX + r")", spec)
    night["ambientHorizon"], night["ambientUpper"] = m.groups()
    m = re.search(r"\((" + HEX + r") core, (" + HEX + r") surround\)", spec)
    night["windowCore"], night["windowSurround"] = m.groups()
    m = re.search(r"(\d+)–(\d+)% of eligible windows lit", spec)
    night["litWindows"] = [int(m.group(1)) / 100, int(m.group(2)) / 100]
    bands = {}
    for light, part in re.findall(r"(moonlit|moonless) (trunk [^;.]+)", spec):
        for what, lo, hi in re.findall(r"(trunk|roof|wall) (?:Y )?(\d+)–(\d+)", part):
            bands.setdefault(light, {})[what] = [int(lo), int(hi)]
    night["patchBands"] = bands
    # §3.1
    wet = {}
    for cells in table(spec, "Surface | Full-W diffuse reduction"):
        red = re.findall(r"\d+", cells[1])
        rough = re.findall(r"\.\d+", cells[2])
        wet[cells[0]] = {"darkening": [int(red[0]) / 100, int(red[1]) / 100], "roughness": [float(rough[0]), float(rough[1])],
                         "puddles": cells[3]}
    # §3.2
    extinction = {}
    for cells in table(spec, "State / density | Color"):
        start, end = (int(x) for x in re.findall(r"\d+", cells[2]))
        extinction[cells[0].lower().replace(" ", "-")] = {"color": cells[1], "start": start, "end": end}
    return {
        "comment": f"GENERATED by scripts/lookfix_data.py from {PACK} (read-only). Do not edit: change the proposal "
                   "and rerun. States: §2.2 targets (whole-frame encoded-sRGB Y and HSV S), §2.3 lift, shade tint and "
                   "clear-air fade (cap 0 = weather override), lighting-fixtures.json time, weather inputs, sun and Moon.",
        "sources": {"spec": {"path": SPEC, "sha256": sha(SPEC)}, "fixtures": {"path": FIXTURES, "sha256": sha(FIXTURES)}},
        "observer": fixtures["observer"], "camera": fixtures["camera"],
        "states": states, "night": night, "wet": wet, "extinction": extinction,
    }


def time_of_day(bible):
    """time-of-day.json with the bible-owned fields set (sun, ambientSky, shadowTint; night sky)."""
    path = os.path.join(ROOT, TIME_OF_DAY)
    lines = open(path, encoding="utf-8").read().split("\n")
    out = []
    for line in lines:
        m = re.match(r'\s*"(dawn|morning|noon|golden|dusk|night)":\s*\{', line)
        if m:
            st = bible["states"][TIME_KEYS[m.group(1)]]
            fields = {"ambientSky": st["skyFillTint"], "shadowTint": st["shadeTint"]}
            if st["directTint"]:
                fields["sun"] = st["directTint"]
            if m.group(1) == "night":
                fields["skyTop"], fields["skyHorizon"] = bible["night"]["ambientUpper"], bible["night"]["ambientHorizon"]
            for k, v in fields.items():
                line, n = re.subn(r'("%s":\s*)"#[0-9A-Fa-f]{6}"' % k, r'\1"%s"' % v, line)
                assert n == 1, (m.group(1), k)
        out.append(line)
    return "\n".join(out)


def main():
    bible = build()
    text = json.dumps(bible, indent=1, ensure_ascii=False) + "\n"
    tod = time_of_day(bible)
    if "--check" in sys.argv:
        stale = [p for p, t in ((OUT, text), (TIME_OF_DAY, tod))
                 if not os.path.exists(os.path.join(ROOT, p)) or open(os.path.join(ROOT, p), encoding="utf-8").read() != t]
        print("lighting bible data up to date" if not stale else "out of date: " + ", ".join(stale))
        sys.exit(1 if stale else 0)
    open(os.path.join(ROOT, OUT), "w", encoding="utf-8").write(text)
    open(os.path.join(ROOT, TIME_OF_DAY), "w", encoding="utf-8").write(tod)
    print(f"wrote {OUT} ({len(bible['states'])} states) and {TIME_OF_DAY}")


if __name__ == "__main__":
    main()
