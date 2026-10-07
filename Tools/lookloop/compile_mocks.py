#!/usr/bin/env python3
"""Compile the values JSON of every R-approved design pack into Resources/look/mock-values.json.

Approved packs are the rows of docs/proposals/INDEX.md whose Status contains "R approved".
Every kept leaf becomes an entry keyed "<pack>/<json.path>" (dots, [i] for list items).
Descriptive/meta fields are skipped; colours, numbers, booleans and short enum strings are kept.
Cross-pack definitions of the same parameter are listed under "conflicts" and mirrored to
docs/lookloop/mock-conflicts.md. Precedence (owner decision, R 2026-10-07): house-contrast-v1
`sharedLighting.*` is the daytime lighting master (entries carry "role": "daytime-master"). A conflict
where an approved pack's clear-daytime value differs from the master is kept but marked resolved for
the master; pairs where the other values belong to night / blue-hour / fog / golden / overcast states
are marked "different state". Conflicts without the master stay pending (R decides).

house-archetypes-v1 (R approved 2026-10-07) is compiled per type: archetypes keyed "archetypes.<id>.…", street
contexts and scenes keyed by metro, plus approvedHouseValues; its copied sharedLighting and meta blocks are not
compiled (house-contrast-v1 stays the daytime master). Each archetype entry carries "label": the pack's nearest
"status" text (its "proposal" labels). Differences between the archetypes' inherited house values and
house-contrast-v1 houseTypes are listed as conflicts for R.
R-approved corrections in Tools/lookloop/mock-corrections.json are applied last (owner rule, R 2026-10-07:
images beat JSON when an approved pack disagrees with itself). Corrected entries carry "correction" (the id) and
"original" (the pack's value, null if the pack had no such key); the full records are copied under "corrections".

Usage: python3 Tools/lookloop/compile_mocks.py [--check]
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "docs/proposals/INDEX.md"
OUT = ROOT / "Resources/look/mock-values.json"
# Byte-identical bundled copy so the WorldGen target can load it (P2, 7 Oct 2026); generated, never hand-edited.
BUNDLE = ROOT / "Sources/WorldGen/Profiles/mock-values.json"
CORRECTIONS = "Tools/lookloop/mock-corrections.json"
CONFLICTS_MD = ROOT / "docs/lookloop/mock-conflicts.md"

# Keys (at any depth) whose whole subtree is descriptive/meta, not a look value.
SKIP_KEYS = {
    "claimPolicy", "notes", "note", "sources", "prompts", "schemaVersion", "schema", "date",
    "status", "units", "definitions", "paintoverValidation", "frames", "priorities", "boards",
    "review", "poster", "weatherHistory", "representation", "materialFormula", "compatibility",
    "comment", "policy", "rule", "liftRule", "selectionStatus", "bearingStatus", "sourceStatus",
    "geometryStatus", "inventory", "cctNote",
}
HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")
ENUM = re.compile(r"^[A-Za-z0-9_\-.]{1,48}$")
# Leaf names too generic to identify a parameter across packs.
# elevationDeg/maxElevationDeg: gradient-stop and time-gate positions, not one parameter (the sun and
# sky meanings are covered by SEMANTIC below).
GENERIC = {"hex", "colourHex", "id", "roughness", "sheenStrength", "surface", "elevationDeg", "maxElevationDeg"}
MASTER_PACK, MASTER_PREFIX = "house-contrast-v1", "sharedLighting."
MASTER_RESOLUTION = "house-contrast-v1 sharedLighting (daytime master, R 2026-10-07)"
# Definitions that belong to a non-clear-day state (not in conflict with the clear daytime master).
OTHER_STATE = re.compile(r"^night-fog-v1/|golden_hour|\.night\.|overcast|blue-hour|fog")
# Parameters with the same meaning under different names (regex on "<pack>/<path>"); a group is a
# conflict when it spans two packs with differing values.
SEMANTIC = {
    "haze extinction per metre (clear/haze fixture)": r"^(night-fog-v1/states\[\d+\]\.haze\.sigmaPerM|lake-winter-v1/water\.haze\.fixtureExtinctionPerM)$",
    "sky zenith colour (90 deg stop)": r"^(house-contrast-v1/sharedLighting\.sky\.gradient\[0\]\.hex|night-fog-v1/states\[\d+\]\.skyGradient\[0\]\.hex)$",
    "sky mid colour (30 deg stop)": r"^(house-contrast-v1/sharedLighting\.sky\.gradient\[1\]\.hex|night-fog-v1/states\[\d+\]\.skyGradient\[1\]\.hex)$",
    "sky horizon colour (0 deg stop)": r"^(house-contrast-v1/sharedLighting\.sky\.gradient\[2\]\.hex|night-fog-v1/states\[\d+\]\.skyGradient\[2\]\.hex)$",
    "exposure relative EV": r"^(house-contrast-v1/sharedLighting\.exposure\.relativeEV|night-fog-v1/states\[\d+\]\.exposureRelativeEV)$",
    "direct sun relative to clear": r"^(house-contrast-v1/sharedLighting\.sun\.directIntensityRelativeClearE0|night-fog-v1/states\[\d+\]\.directSunRelativeClear)$",
    "sun elevation fixture (deg)": r"^(house-contrast-v1/sharedLighting\.sun\.elevationDeg|night-fog-v1/states\[\d+\]\.time\.elevationExampleDeg|lake-winter-v1/water\.skyStates\.\w+\.sunElevationDegrees)$",
    "sun azimuth fixture (deg)": r"^(house-contrast-v1/sharedLighting\.sun\.azimuthDegTrueNorthClockwise|lake-winter-v1/water\.skyStates\.\w+\.sunAzimuthDegrees)$",
}


def approved_packs(index_text):
    """[(pack, values_json_path)] for INDEX rows whose Status contains 'R approved'."""
    out = []
    for line in index_text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5 or "R approved" not in cells[-1]:
            continue
        pack = cells[1].strip("`* ")
        m = re.search(r"`(docs/proposals/[^`]+\.json)`", cells[3])
        if m:
            out.append((pack, m.group(1)))
    return sorted(set(out))


def keep_leaf(v):
    if isinstance(v, bool) or isinstance(v, (int, float)) or v is None:
        return v is not None
    if isinstance(v, str):
        return bool(HEX.match(v)) or bool(ENUM.match(v))
    return False


def flatten(obj, path=""):
    """Yield (path, value) for every kept leaf."""
    if isinstance(obj, dict):
        for k in sorted(obj):
            if k in SKIP_KEYS:
                continue
            yield from flatten(obj[k], f"{path}.{k}" if path else k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from flatten(v, f"{path}[{i}]")
    elif keep_leaf(obj):
        yield path, obj


ARCH_PACK = "house-archetypes-v1"
ARCH_KEEP = ("archetypes", "streetContexts", "streetScenes", "approvedHouseValues")


def arch_view(data):
    """The archetypes pack with lists keyed by id / metro and lighting and meta blocks dropped."""
    return {"archetypes": {a["id"]: a for a in data.get("archetypes", [])},
            "streetContexts": data.get("streetContexts", {}),
            "streetScenes": {s["metro"]: s for s in data.get("streetScenes", [])},
            "approvedHouseValues": data.get("approvedHouseValues", {})}


def flatten_labelled(obj, path="", label=None):
    """flatten() that also yields the nearest enclosing "status" text (the pack's proposal label)."""
    if isinstance(obj, dict):
        label = obj["status"] if isinstance(obj.get("status"), str) else label
        for k in sorted(obj):
            if k in SKIP_KEYS:
                continue
            yield from flatten_labelled(obj[k], f"{path}.{k}" if path else k, label)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from flatten_labelled(v, f"{path}[{i}]", label)
    elif keep_leaf(obj):
        yield path, obj, label


def archetype_conflicts(entries):
    """Archetype inherited / approved house values that differ from house-contrast-v1 houseTypes (R decides)."""
    out = []
    for k, e in sorted(entries.items()):
        m = re.match(rf"^{ARCH_PACK}/(?:archetypes\.[^.]+\.inheritedHouseValues|approvedHouseValues\.([^.]+))\.(.+)$", k)
        if not m:
            continue
        if m.group(1):
            typ, rest = m.group(1), m.group(2)
        else:
            aid = k.split(".")[1]
            typ = entries.get(f"{ARCH_PACK}/archetypes.{aid}.inheritedHouseValuesKey", {}).get("value")
            rest = k.split(".inheritedHouseValues.", 1)[1]
        other = entries.get(f"{MASTER_PACK}/houseTypes.{typ}.{rest}")
        if other and other["value"] != e["value"]:
            out.append({"parameter": f"house type {typ}: {rest}", "definitions": [
                {"key": f'{other["pack"]}/{other["key"]}', "pack": other["pack"], "value": other["value"], "source": other["source"], "state": "day"},
                {"key": k, "pack": ARCH_PACK, "value": e["value"], "source": e["source"], "state": "day"}]})
    return out


def leaf_name(path):
    parts = [p for p in re.split(r"[.\[\]]", path) if p and not p.isdigit()]
    return parts[-1] if parts else path


def find_conflicts(entries):
    """Same (non-generic) leaf name and same value type in two different packs with different values."""
    by_name = {}
    for key, e in entries.items():
        name = leaf_name(e["key"])
        if name in GENERIC:
            continue
        kind = "colour" if isinstance(e["value"], str) and HEX.match(e["value"]) else type(e["value"]).__name__
        by_name.setdefault((name, kind), []).append(e)
    for label, rx in SEMANTIC.items():
        es = [e for k, e in entries.items() if re.match(rx, k)]
        if es:
            by_name[(label, "semantic")] = es
    conflicts = []
    for (name, kind), es in sorted(by_name.items()):
        packs = sorted({e["pack"] for e in es})
        if len(packs) < 2:
            continue
        values = {json.dumps(e["value"]) for e in es}
        if len(values) < 2:
            continue
        defs = [{"key": f'{e["pack"]}/{e["key"]}', "pack": e["pack"], "value": e["value"], "source": e["source"],
                 "state": state_of(f'{e["pack"]}/{e["key"]}', e)} for e in sorted(es, key=lambda e: (e["pack"], e["key"]))]
        conflict = {"parameter": name, "definitions": defs}
        resolved = resolution(defs)
        if resolved:
            conflict["resolved"] = resolved
            for d in defs:
                d["resolved"] = {"daytime-master": "master value (wins in clear daytime)",
                                 "other state": "different state", "day": MASTER_RESOLUTION}[d["state"]]
        conflicts.append(conflict)
    return conflicts


def state_of(key, e):
    if e.get("role") == "daytime-master":
        return "daytime-master"
    return "other state" if OTHER_STATE.search(key) else "day"


def resolution(defs):
    """Master wins over differing clear-day values; non-day states are not conflicts with it."""
    masters = [d for d in defs if d["state"] == "daytime-master"]
    if not masters:
        return None
    master_values = {json.dumps(d["value"]) for d in masters}
    if any(d["state"] == "day" and json.dumps(d["value"]) not in master_values for d in defs):
        return MASTER_RESOLUTION
    return "different state"


def build(root=ROOT):
    packs = approved_packs((root / "docs/proposals/INDEX.md").read_text())
    entries, dates = {}, []
    for pack, rel in packs:
        data = json.loads((root / rel).read_text())
        if isinstance(data.get("date"), str):
            dates.append(data["date"])
        rows = (flatten_labelled(arch_view(data)) if pack == ARCH_PACK else ((p, v, None) for p, v in flatten(data)))
        for path, value, label in rows:
            entry = {"value": value, "pack": pack, "key": path, "source": rel}
            if label:
                entry["label"] = label
            if pack == MASTER_PACK and path.startswith(MASTER_PREFIX):
                entry["role"] = "daytime-master"
            entries[f"{pack}/{path}"] = entry
    cpath = root / CORRECTIONS
    corrections = json.loads(cpath.read_text())["corrections"] if cpath.exists() else []
    for c in corrections:
        pack, pre = c["pack"], c.get("replacePrefix")
        if pack not in [p for p, _ in packs]:
            continue
        src = next(rel for p, rel in packs if p == pack)
        old = {k: e for k, e in entries.items() if k.startswith(f"{pack}/") and (
            (pre and e["key"].startswith(pre)) or e["key"] in c["set"])}
        for k in old:
            del entries[k]
        for path, value in c["set"].items():
            entry = {"value": value, "pack": pack, "key": path, "source": src, "correction": c["id"],
                     "original": old[f"{pack}/{path}"]["value"] if f"{pack}/{path}" in old else None}
            if pack == MASTER_PACK and path.startswith(MASTER_PREFIX):
                entry["role"] = "daytime-master"
            entries[f"{pack}/{path}"] = entry
        c["originalValues"] = {e["key"]: e["value"] for e in old.values()}
    return {
        "corrections": corrections,
        # Deterministic: newest approved pack date, not wall-clock time.
        "generated": max(dates) if dates else "unknown",
        "generator": "Tools/lookloop/compile_mocks.py",
        "approvedPacks": [p for p, _ in packs],
        "conflicts": find_conflicts({k: e for k, e in entries.items() if e["pack"] != ARCH_PACK}) + archetype_conflicts(entries),
        "entries": entries,
    }


def render(doc):
    return json.dumps(doc, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def render_conflicts_md(doc):
    lines = [
        "# Mock value conflicts between approved packs",
        "",
        "Generated by `Tools/lookloop/compile_mocks.py` (do not hand-edit). When two R-approved packs define the same",
        "parameter differently, both are kept. Matching is by leaf parameter name across packs plus the named",
        "same-meaning groups in `SEMANTIC`. Precedence (R, 2026-10-07): house-contrast-v1 `sharedLighting` is the",
        "daytime lighting master; it wins over other packs' clear-daytime values. Night / blue-hour / fog / golden /",
        "overcast values are different states, not conflicts. Conflicts without the master stay pending for R.",
        "",
        "| Parameter | Mock key | Value | State | Source | Resolution |",
        "|---|---|---|---|---|---|",
    ]
    for c in doc["conflicts"]:
        for d in c["definitions"]:
            lines.append(f'| {c["parameter"]} | `{d["key"]}` | `{json.dumps(d["value"])}` | {d["state"]} | '
                         f'`{d["source"]}` | {d.get("resolved", "pending (R decides)")} |')
    if not doc["conflicts"]:
        lines.append("| (none found) | | | | | |")
    return "\n".join(lines) + "\n"


def main(argv):
    doc = build()
    text, md = render(doc), render_conflicts_md(doc)
    if "--check" in argv:
        ok = OUT.exists() and OUT.read_text() == text and BUNDLE.exists() and BUNDLE.read_text() == text and CONFLICTS_MD.exists() and CONFLICTS_MD.read_text() == md
        print("mock-values.json up to date" if ok else "mock-values.json is STALE: run Tools/lookloop/compile_mocks.py")
        return 0 if ok else 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text)
    BUNDLE.write_text(text)
    CONFLICTS_MD.write_text(md)
    print(f"wrote {OUT.relative_to(ROOT)}: {len(doc['entries'])} entries from {', '.join(doc['approvedPacks'])}; "
          f"{len(doc['conflicts'])} conflicts")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
