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
infrastructure-kit-v1 (R approved 2026-10-07, all 48 sheets) is compiled under the key prefix "style-b/infrastructure"
(assets by id, palettes by name; its copied sharedLighting is not compiled). Precedence (R, 7 Oct 2026):
street-geometry-rules-v1 owns street geometry (carriageway, lane and sidewalk widths by country and class); the kit
owns look (markings, materials, colours, bridge, rail and airport styling). The kit's street cross-section keys carry
"supersededFor": "geometry" and are listed as a resolved conflict (US residential carriageway: kit 10.2 m, rules 10.6 m).
foliage-seasons-v1 (R approved 2026-10-07) compiles under "style-b/foliage" (species and cities by id, regional plantings by key) and
style-b-calibration-v2 (R approved 2026-10-07: packs own content, calibration v2 owns look and replaces the old Lakeview street as the
look-gate target) under "style-b/look" (its sharedLook block only). Neither compiles its copied sharedLighting.
water-surfaces-v1 (R approved 2026-10-07, MECHANICS only) compiles under "style-b/water": profiles (without their colour blocks), shore types, the
wave model (four terms), foam, ice gating (without ice colours and roughness), live inputs, performance budget and detail tiers. Water COLOUR stays
with lake-winter-v1 and style-b-calibration-v2 (Lake Michigan stays the #315F7F family), so the pack's colours, reflection/roughness limits,
atmosphere/exposure and copied lighting are not compiled. lake-winter-v1's wave tables carry "supersededFor": "wave-mechanics".
road-signs-signals-v1 (R approved 2026-10-07) compiles under "style-b/road-signs" (countries by id): it governs signs and signals everywhere and all
road markings outside the US; infrastructure-kit-v1 governs US lane markings and crosswalks, so the pack's US marking keys carry
"supersededFor": "us-markings" and the kit's marking and crosswalk keys carry "governs": "us-markings". Differing US marking values are listed as
resolved conflicts. terrain-slope-v1 ("style-b/terrain") and greenville-sc-v1 ("style-b/greenville", R's test location 3) compile their own content;
the sharedLook they copy from the calibration is not compiled.
R's 8 Oct 2026 approvals compile under their own prefixes by the generic pack view (lists keyed by id; the copied look blocks, image and file
names, sources and review blocks dropped): life packs "style-b/life-chicago-denver", "style-b/life-nyc", "style-b/life-sf" (one actor pool, events
off unless verified: the game-day block carries "gatedBy": "events-off-unless-verified"), "style-b/nyc-hero", "style-b/metros-wave2" (with SF r2),
"style-b/metros-wave3", "style-b/weather-moments", "style-b/car-mix", "style-b/mexico-australia", "style-b/mountain-terrain". venues-campuses-v1
(Builder phase) and creator-kit-ux-v3 (app design) are not compiled: the engine stays generic.
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
    "geometryStatus", "inventory", "cctNote", "valuesStatus",
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


INFRA_PACK, INFRA_PREFIX = "infrastructure-kit-v1", "style-b/infrastructure"
FOLIAGE_PACK, LOOK_PACK = "foliage-seasons-v1", "style-b-calibration-v2"
WATER_PACK, SIGNS_PACK, TERRAIN_PACK, GREENVILLE_PACK = "water-surfaces-v1", "road-signs-signals-v1", "terrain-slope-v1", "greenville-sc-v1"
KEY_PREFIX = {INFRA_PACK: INFRA_PREFIX, FOLIAGE_PACK: "style-b/foliage", LOOK_PACK: "style-b/look", WATER_PACK: "style-b/water",
              SIGNS_PACK: "style-b/road-signs", TERRAIN_PACK: "style-b/terrain", GREENVILLE_PACK: "style-b/greenville"}  # compiled key prefix per pack (default: the pack name)
LAKE_PACK = "lake-winter-v1"
LAKE_WAVE_KEYS = re.compile(r"^water\.profiles\.[^.]+\.waveByWindKmh\.")
US_MARKING_KEYS = re.compile(r"^profiles\.us\.markings\.")
KIT_MARKING_KEYS = re.compile(r"^assets\.roads-0[89]-(markings|crosswalks)\.")
GEOMETRY_OWNER = "street-geometry-rules-v1"
GEOMETRY_RULES = "docs/research-gpt/street-geometry-rules-v1/rules.csv"
# The kit's street cross-section keys (Roads sheets 01, 02, 05, 06, 07, 08); markings, crosswalk, bridge and soundwall keys stay the kit's.
GEOMETRY_KEYS = re.compile(r"^assets\.roads-0[125678]-[^.]+\.dimensionsM\.(laneWidth|lanesEachDirection|shoulderWidth|medianWidth|"
                           r"rampPavementWidth|pavementWidth|throughLanesTotal|centerTurnLaneWidth|sidewalkWidth|parkwayWidth|curbHeight|"
                           r"carriagewayWidth|travelLaneWidth|parkingLaneWidth|pavedWidth|drainStripWidth|edgeSetback)$")
ARCH_PACK = "house-archetypes-v1"
ARCH_KEEP = ("archetypes", "streetContexts", "streetScenes", "approvedHouseValues")


def arch_view(data):
    """The archetypes pack with lists keyed by id / metro and lighting and meta blocks dropped."""
    return {"archetypes": {a["id"]: a for a in data.get("archetypes", [])},
            "streetContexts": data.get("streetContexts", {}),
            "streetScenes": {s["metro"]: s for s in data.get("streetScenes", [])},
            "approvedHouseValues": data.get("approvedHouseValues", {})}


def infra_view(data):
    """The infrastructure kit by asset id, palettes by name; sharedLighting, generation and verification are not compiled."""
    assets = {}
    for a in data.get("assets", []):
        a = dict(a)
        a["palette"] = {p["name"]: {k: v for k, v in p.items() if k != "name"} for p in a.get("palette", [])}
        assets[a["id"]] = a
    return {"assets": assets, "lodPolicy": data.get("lodPolicy", {})}


def foliage_view(data):
    """Foliage by species id and city id; the copied sharedLighting and the illustration notes are not compiled."""
    out = {k: v for k, v in data.items() if k not in ("sharedLighting", "illustrationLimits", "species", "cities")}
    out["species"] = {x["id"]: x for x in data.get("species", [])}
    out["cities"] = {x["id"]: x for x in data.get("cities", [])}
    return out


# Generic view for the packs R approved on 2026-10-08: pack -> (key prefix, extra top-level keys to drop).
GENERIC_PACKS = {
    "chicago-denver-life-v1": ("style-b/life-chicago-denver", ()),
    "nyc-life-v1": ("style-b/life-nyc", ()),
    "sf-life-v1": ("style-b/life-sf", ()),
    "nyc-hero-v1": ("style-b/nyc-hero", ("materials",)),
    "us-metros-wave2-v1": ("style-b/metros-wave2", ()),
    "us-metros-wave3-v1": ("style-b/metros-wave3", ()),
    "weather-moments-v1": ("style-b/weather-moments", ()),
    "regional-car-mix-v1": ("style-b/car-mix", ()),
    "mexico-australia-v1": ("style-b/mexico-australia", ()),
    "mountain-terrain-v1": ("style-b/mountain-terrain", ("slopeRules",)),
    # R approved 8 Oct 2026 (second batch): country style packs and the seasonal life pack.
    "uk-style-b-v1": ("style-b/uk", ()),
    "netherlands-style-b-v1": ("style-b/netherlands", ("dataPlan", "inherits", "dimensionStatus", "weather")),  # weather presets are 5A's / weather-moments-v1's
    "canada-style-b-v2": ("style-b/canada", ("reference", "signals_reference", "supersedes", "snowbank_rules")),  # fixed snowbank heights; the approved weather rules are history-driven
    "seasonal-holiday-life-v1": ("style-b/life-seasonal", ("nightLighting", "detailTiers", "lookInheritanceRule", "provenanceCalibrationStatus",
                                                         "validation", "continuity", "jobs")),
}
# Packs compiled by a view of their own; kept out of the generic leaf-name conflict search.
OWN_PACKS = (ARCH_PACK, INFRA_PACK, FOLIAGE_PACK, LOOK_PACK, WATER_PACK, SIGNS_PACK, TERRAIN_PACK, GREENVILLE_PACK, *GENERIC_PACKS)
# Top-level blocks that copy another pack's look or are descriptive, and leaf names that only point at files.
GENERIC_DROP = {"sharedLighting", "sharedLook", "bibleSharedLightingSnapshot", "approvedReferenceSharedLighting", "inherited", "precedence",
                "lookSource", "lookSourceSha256", "lookSourceStatus", "lookOwnership", "look", "referenceManifest", "sources", "sheets",
                "boards", "review", "forbidden", "exclusions", "provenance", "supersededFiles", "lightingSource", "lightingReference",
                "referencePaths", "revision", "sfValuesFile", "sfTerrainReference", "artworkCalibration", "surfacePolicy", "views", "mapPolicy",
                "sizeStatus", "colourScope", "densityStatus", "densityFormula", "localTimeBands", "treeMixMeaning"}
GENERIC_LEAF_DROP = {"image", "imageFile", "sheet", "sheetFile", "sheetPngFile", "page", "path", "file", "asset", "url", "sha256",
                     "panelIndex", "board", "boardRow", "boardRows", "description", "name", "title"}
GENERIC_GATES = {"chicago-denver-life-v1": [("gameDay", "events-off-unless-verified")], "nyc-life-v1": [("gameDay", "events-off-unless-verified")],
                 "sf-life-v1": [("gameDay", "events-off-unless-verified")],
                 "netherlands-style-b-v1": [("kingsDay", "events-off-unless-verified")],
                 "seasonal-holiday-life-v1": [("scenes", "events-off-unless-verified")]}


# Derived or plot data, dropped whatever its type (hex colours stay; the linear-RGB copies and profile coordinate arrays only bloat the bundle).
GENERIC_DROP_ANY = {"linearRGB", "linearRgb", "linearLuminance", "profileLocalM", "sourceUrls"}
# Look values and prose inside a pack's own records, dropped at any depth for that pack only: style-b-calibration-v2 owns roughness, detail tiers and faces;
# the lake pack owns water roughness (R, 2026-10-08). sf-life-v1 scenes keep their dimensions, speeds, grades, activity envelopes and counts.
# Country style packs: street geometry belongs to street-geometry-rules-v1 and signs, signals and markings to road-signs-signals-v1 (R, 7 Oct 2026).
COUNTRY_GEOMETRY = {"uk-style-b-v1": r"^streets\[\d+\]\.", "netherlands-style-b-v1": r"^(streetWidths_m\.|canals\.width_m|bridges[.\[][^.]*\.?deckWidth_m)", "canada-style-b-v2": r"^street_profiles_m\."}
COUNTRY_SIGNALS = {"netherlands-style-b-v1": r"^signals\.", "canada-style-b-v2": r"^signals_rules"}
GENERIC_NESTED_DROP = {"sf-life-v1": {"surfaceValues", "detailTiers", "mustBeExact", "canSimplify", "signatureElements", "evidenceStatus", "views", "facePolicy"},
                       "us-metros-wave2-v1": {"surfaceValues"},  # per-house roughness (wall 0.86, glass 0.5) against calibration v2's 0.82 and 0.28
                       "weather-moments-v1": {"exposureRelativeEV", "contrastSlope", "saturationFactor"},  # copies of the daytime master's exposure on every endpoint
                       "mountain-terrain-v1": {"scatterHex"},
                       "netherlands-style-b-v1": {"water"},  # canals.water #617E86 clashes with water-surfaces-v1's canal colour; the lake pack and calibration v2 own water colour
                       # `share` disagrees with percentResidentialBuildings in 18 of 50 US scenes (the README table matches the latter); sampleState is an authored scenario, not a rule
                       "seasonal-holiday-life-v1": {"share", "sampleState"}}  # the pale JSON horizon stop; haze takes the corrected sky horizon colour


def drop_named(obj, names):
    if isinstance(obj, dict):
        return {k: drop_named(v, names) for k, v in obj.items() if k not in names}
    if isinstance(obj, list):
        return [drop_named(v, names) for v in obj]
    return obj


def strip_leaf_names(obj, names):
    if isinstance(obj, dict):
        return {k: strip_leaf_names(v, names) for k, v in obj.items()
                if k not in GENERIC_DROP_ANY and not (k in names and not isinstance(v, (dict, list)))}
    if isinstance(obj, list):
        return [strip_leaf_names(v, names) for v in obj]
    return obj


def key_lists(obj):
    """Lists of dicts that all carry a unique id become dicts keyed by id, recursively; other lists keep their indices."""
    if isinstance(obj, dict):
        return {k: key_lists(v) for k, v in obj.items()}
    if isinstance(obj, list):
        if obj and all(isinstance(x, dict) and isinstance(x.get("id"), str) for x in obj) and len({x["id"] for x in obj}) == len(obj):
            return {x["id"]: key_lists({k: v for k, v in x.items() if k != "id"}) for x in obj}
        return [key_lists(v) for v in obj]
    return obj


def generic_view(pack, data):
    drop = GENERIC_DROP | set(GENERIC_PACKS[pack][1])
    out = drop_named({k: v for k, v in data.items() if k not in drop}, GENERIC_NESTED_DROP.get(pack, ()))
    return key_lists(strip_leaf_names(out, GENERIC_LEAF_DROP))


def by_id(items, key="id"):
    return {x[key]: x for x in items}


WATER_KEEP = ("shorelines", "waveModelProposal", "foamRulesProposal", "livePolicy", "performanceProposal", "screenDetailTiersProposal")


def water_view(data):
    """Water MECHANICS only (R, 2026-10-07): profiles without colour blocks, shore types, waves, foam, ice gating without ice colours and roughness, live inputs, budget."""
    out = {k: data[k] for k in WATER_KEEP if k in data}
    out["profiles"] = {p["id"]: {k: v for k, v in p.items() if k not in ("id", "colourConditions", "colourEvidence")} for p in data.get("profiles", [])}
    ice = dict(data.get("iceRules", {}))
    ice.pop("colours", None)
    ice.pop("roughnessProposal", None)
    out["iceRules"] = ice
    return out


def signs_view(data):
    """Signs, signals, markings, mounting and rail by country id; the copied sharedLook, sources and descriptions are not compiled."""
    out = {k: data[k] for k in ("colours", "verifiedAnchors", "renderPolicy") if k in data}
    out["profiles"] = {p["id"]: {k: v for k, v in p.items() if k not in ("id", "sources", "description", "lookRef")} for p in data.get("profiles", [])}
    return out


def terrain_view(data):
    """Terrain and slope rules; grade bands, scenes and coverage by id; the inherited look and the source list are not compiled."""
    out = {k: v for k, v in data.items() if k not in ("look", "sharedLook", "gradeBands", "scenes", "coverage", "sources", "evidenceRule")}
    out["gradeBands"] = by_id(data.get("gradeBands", []))
    out["scenes"] = {s["id"]: {k: v for k, v in s.items() if k not in ("description", "image", "sheet")} for s in data.get("scenes", [])}
    out["coverage"] = {c["city"].lower().replace(" ", "-"): c for c in data.get("coverage", [])}
    return out


def greenville_view(data):
    """Greenville's regional content by id (archetypes, districts, streets, trees, terrain, lawns, weather); the copied sharedLook and the sheet list are not compiled."""
    drop = ("sharedLook", "lookSource", "lookSourceSha256", "lookSourceStatus", "lookOwnership", "sheets", "blockPaintover",
            "archetypes", "districts", "streets", "trees")
    out = {k: v for k, v in data.items() if k not in drop}
    out["archetypes"] = by_id(data.get("archetypes", []))
    out["districts"] = by_id(data.get("districts", []))
    out["streets"] = by_id(data.get("streets", []), "type")
    out["trees"] = by_id(data.get("trees", []))
    return out


def look_view(data):
    """The calibration pack's shared look (lighting, materials, people and vehicles); scenes and notes are not compiled."""
    return data.get("sharedLook", {})


def look_conflicts(entries):
    """Differences between the calibration look and the daytime master (house-contrast-v1 sharedLighting): listed for R, the master stays the numeric baseline."""
    pairs = [("lighting.sky.zenithHex", "sharedLighting.sky.gradient[0].hex"), ("lighting.sky.midHex", "sharedLighting.sky.gradient[2].hex"),
             ("lighting.sky.horizonHex", "sharedLighting.sky.gradient[3].hex"), ("lighting.sun.hex", "sharedLighting.sun.colorHex"),
             ("lighting.exposure.relativeEV", "sharedLighting.exposure.relativeEV"), ("lighting.exposure.saturation", "sharedLighting.exposure.saturationFactor"),
             ("lighting.shadow.appearanceHex", "sharedLighting.shadows.appearanceTintHex")]
    out = []
    for a, b in pairs:
        ka, kb = f"style-b/look/{a}", f"{MASTER_PACK}/{b}"
        if ka in entries and kb in entries and entries[ka]["value"] != entries[kb]["value"]:
            out.append({"parameter": f"look {a.split('.', 1)[1]}", "resolved": "daytime master (house-contrast-v1) is the numeric baseline; calibration v2 owns look (R, 2026-10-07)",
                        "definitions": [{"key": kb, "pack": MASTER_PACK, "value": entries[kb]["value"], "source": entries[kb]["source"], "state": "daytime-master",
                                        "resolved": "master value (numeric baseline)"},
                                       {"key": ka, "pack": LOOK_PACK, "value": entries[ka]["value"], "source": entries[ka]["source"], "state": "day",
                                        "resolved": "calibration look value, from its own frames (R: images beat JSON)"}]})
    return out


def signs_conflicts(entries):
    """US marking values where road-signs-signals-v1 and infrastructure-kit-v1 differ: the kit governs US lane markings and crosswalks (R, 2026-10-07)."""
    sp, ip = f"{KEY_PREFIX[SIGNS_PACK]}/profiles.us.markings.", f"{INFRA_PREFIX}/assets."
    pairs = [("US crosswalk stripe width (m)", "stripeWidthM", "roads-09-crosswalks.dimensionsM.stripeWidth"),
             ("US crosswalk stripe gap (m)", "stripeGapM", "roads-09-crosswalks.dimensionsM.stripeGap"),
             ("US crosswalk depth along the road (m)", "crosswalkTravelDepthM", "roads-09-crosswalks.dimensionsM.crossingWidthAlongRoad"),
             ("US stop line width (m)", "stopLineWidthM", "roads-08-markings.dimensionsM.stopBarWidth"),
             ("US yellow marking colour", "centreLineHex", "roads-08-markings.palette.Base.accentHex"),
             ("US white marking colour", "stopLineColourHex", "roads-08-markings.palette.Base.secondaryHex")]
    out = []
    for name, a, b in pairs:
        ka, kb = sp + a, ip + b
        if ka in entries and kb in entries and entries[ka]["value"] != entries[kb]["value"]:
            out.append({"parameter": name, "resolved": "infrastructure-kit-v1 governs US lane markings and crosswalks (R, 2026-10-07)",
                        "definitions": [{"key": kb, "pack": INFRA_PACK, "value": entries[kb]["value"], "source": entries[kb]["source"], "state": "day",
                                         "resolved": "governs US lane markings and crosswalks"},
                                        {"key": ka, "pack": SIGNS_PACK, "value": entries[ka]["value"], "source": entries[ka]["source"], "state": "day",
                                         "resolved": "superseded for US markings; the pack keeps signs, signals and non-US markings"}]})
    return out


def geometry_conflict(entries, root):
    """The documented US residential carriageway conflict (R, 2026-10-07): street-geometry-rules-v1 owns geometry."""
    key = f"{INFRA_PREFIX}/assets.roads-06-residential.dimensionsM.carriagewayWidth"
    rules = root / GEOMETRY_RULES
    if key not in entries or not rules.exists():
        return []
    import csv
    row = next((r for r in csv.DictReader(rules.open()) if r.get("rule_id") == "us_residential_v1"), None)
    if not row:
        return []
    return [{"parameter": "US residential carriageway width (m)", "resolved": f"{GEOMETRY_OWNER} owns street geometry (R, 2026-10-07)",
             "definitions": [
                 {"key": key, "pack": INFRA_PACK, "value": entries[key]["value"], "source": entries[key]["source"], "state": "day",
                  "resolved": "superseded for geometry; the kit keeps look"},
                 {"key": f"{GEOMETRY_OWNER}/us_residential_v1.carriageway_default_m", "pack": GEOMETRY_OWNER,
                  "value": float(row["carriageway_default_m"]), "source": GEOMETRY_RULES, "state": "day",
                  "resolved": "owns street geometry (research CSV, not compiled)"}]}]


def flatten_labelled(obj, path="", label=None):
    """flatten() that also yields the nearest enclosing "status" text (the pack's proposal label)."""
    if isinstance(obj, dict):
        label = obj["status"] if isinstance(obj.get("status"), str) else obj["valuesStatus"] if isinstance(obj.get("valuesStatus"), str) else label
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


def precedence(packs, root):
    """Standing ownership rules between approved packs (R decisions); each is listed only when its packs are approved."""
    names = {p for p, _ in packs}
    out = [{"id": "street-geometry-owner", "decided": "R, 2026-10-07",
            "statement": f"{GEOMETRY_OWNER} owns street geometry (carriageway, lane, sidewalk widths by country and class); the infrastructure kit owns look (markings, materials, colours, bridge, rail and airport styling). Keys marked supersededFor=geometry are not geometry sources. Images beat JSON applies to look, not measurements."}]
    if SIGNS_PACK in names:
        out.append({"id": "signs-signals-markings-owner", "decided": "R, 2026-10-07",
                    "statement": f"{SIGNS_PACK} governs signs and signals everywhere and all road markings outside the US; {INFRA_PACK} governs US lane markings and crosswalks. "
                                 "Keys marked supersededFor=us-markings are not sources for US markings; keys marked governs=us-markings are. "
                                 "Keys marked supersededFor=signs-signals (country style packs' own signal rules) are not sources either."})
    if WATER_PACK in names:
        out.append({"id": "water-colour-and-mechanics-owner", "decided": "R, 2026-10-07",
                    "statement": f"{LAKE_PACK} and style-b-calibration-v2 own water colour (Lake Michigan stays the #315F7F family); {WATER_PACK} is approved for mechanics only: "
                                 "wave terms, foam, shore types, ice gating, live inputs and budget. Its colour, reflection/roughness, exposure and ice colour keys are not compiled; "
                                 "lake-winter-v1 wave tables carry supersededFor=wave-mechanics."})
    if any(p in names for p in ("chicago-denver-life-v1", "nyc-life-v1", "sf-life-v1", "seasonal-holiday-life-v1")):
        out.append({"id": "life-rules", "decided": "R, 2026-10-08",
                    "statement": "chicago-denver-life-v1, nyc-life-v1, sf-life-v1 and seasonal-holiday-life-v1: content approved, look owned by style-b-calibration-v2. Life rules are binding: one actor pool, "
                                 "and events (game-day crowds, festival tents, opened hydrants, markets, plows, seasonal sellers and the like) stay OFF unless a verified schedule, event or history, "
                                 "or a labelled demo, enables them (every seasonal-holiday-life-v1 scene is gated this way). Counts are per 100 m of one side (Chicago-Denver, SF), per 150 m (NYC) and a percent of residential building frontages (seasonal-holiday-life-v1): one unit is needed before the pools merge. "
                                 "Their copied lighting blocks, material roughness, water roughness, detail tiers and face policies are not compiled (calibration v2 and the lake pack own them)."})
    if "nyc-hero-v1" in names and "weather-moments-v1" in names:
        out.append({"id": "nyc-light-states", "decided": "pending R",
                    "statement": "nyc-hero-v1 light states and the weather-moments-v1 New York pairs were approved together and disagree: winter low sun 15 deg / 155 deg against 8 deg / 225 deg, "
                                 "snow-day direct light 0 against 0.08, rainy-night wet-road roughness 0.2-0.35 against asphalt 0.52 with patch-only reflections. No precedence is set; both are compiled under their own prefixes."})
    if "weather-moments-v1" in names:
        out.append({"id": "weather-exposure", "decided": "pending R",
                    "statement": "weather-moments-v1 repeats the daytime master's exposure on every endpoint (relativeEV +0.35, fog and golden hour included) where night-fog-v1's morning fog is +0.10. "
                                 "Those exposure keys are not compiled (the daytime master and night-fog-v1 own exposure); which value wins for fog and overcast is unclear and goes to R."})
    if "mountain-terrain-v1" in names:
        out.append({"id": "mountain-palettes", "decided": "pending R",
                    "statement": "mountain-terrain-v1 aspen and conifer colours differ from foliage-seasons-v1, its snow differs from lake-winter-v1, and its palettes are keyed by calendar season where "
                                 "foliage-seasons-v1 turns the calendar switch off. No precedence is set; all are compiled under their own prefixes. Its slope rules are a copy of terrain-slope-v1 and are not compiled. "
                                 "R's 8 Oct approvals list names mountains, so the r2 fixes and the hiking trails are treated as approved."})
    return out


def build(root=ROOT):
    packs = approved_packs((root / "docs/proposals/INDEX.md").read_text())
    entries, dates = {}, []
    for pack, rel in packs:
        data = json.loads((root / rel).read_text())
        if isinstance(data.get("date"), str):
            dates.append(data["date"])
        rows = (flatten_labelled(arch_view(data)) if pack == ARCH_PACK else flatten_labelled(infra_view(data)) if pack == INFRA_PACK
                else flatten_labelled(foliage_view(data)) if pack == FOLIAGE_PACK else flatten_labelled(look_view(data)) if pack == LOOK_PACK
                else flatten_labelled(water_view(data)) if pack == WATER_PACK else flatten_labelled(signs_view(data)) if pack == SIGNS_PACK
                else flatten_labelled(terrain_view(data)) if pack == TERRAIN_PACK else flatten_labelled(greenville_view(data)) if pack == GREENVILLE_PACK
                else flatten_labelled(generic_view(pack, data)) if pack in GENERIC_PACKS
                else ((p, v, None) for p, v in flatten(data)))
        prefix = KEY_PREFIX.get(pack) or (GENERIC_PACKS[pack][0] if pack in GENERIC_PACKS else pack)
        for path, value, label in rows:
            entry = {"value": value, "pack": pack, "key": path, "source": rel}
            if label:
                entry["label"] = label
            if pack == MASTER_PACK and path.startswith(MASTER_PREFIX):
                entry["role"] = "daytime-master"
            if pack == INFRA_PACK and GEOMETRY_KEYS.match(path):
                entry["supersededFor"] = "geometry"
                entry["geometryOwner"] = GEOMETRY_OWNER
            if pack in COUNTRY_GEOMETRY and re.match(COUNTRY_GEOMETRY[pack], path):
                entry["supersededFor"] = "geometry"
                entry["geometryOwner"] = GEOMETRY_OWNER
            if pack in COUNTRY_SIGNALS and re.match(COUNTRY_SIGNALS[pack], path):
                entry["supersededFor"] = "signs-signals"
                entry["signsOwner"] = SIGNS_PACK
            for gate_prefix, gate in GENERIC_GATES.get(pack, ()):
                if path.startswith(gate_prefix + "."):
                    entry["gatedBy"] = gate
            if pack == SIGNS_PACK and US_MARKING_KEYS.match(path):
                entry["supersededFor"] = "us-markings"
                entry["markingsOwner"] = INFRA_PACK
            if pack == INFRA_PACK and KIT_MARKING_KEYS.match(path):
                entry["governs"] = "us-markings"
            if pack == LAKE_PACK and LAKE_WAVE_KEYS.match(path) and any(p == WATER_PACK for p, _ in packs):
                entry["supersededFor"] = "wave-mechanics"
                entry["supersededBy"] = WATER_PACK
            entries[f"{prefix}/{path}"] = entry
    cpath = root / CORRECTIONS
    corrections = json.loads(cpath.read_text())["corrections"] if cpath.exists() else []
    for c in corrections:
        pack, pre = c["pack"], c.get("replacePrefix")
        if pack not in [p for p, _ in packs]:
            continue
        src = next(rel for p, rel in packs if p == pack)
        old = {k: e for k, e in entries.items() if k.startswith(f"{KEY_PREFIX.get(pack, pack)}/") and (
            (pre and e["key"].startswith(pre)) or e["key"] in c["set"])}
        for k in old:
            del entries[k]
        kp = KEY_PREFIX.get(pack, pack)
        for path, value in c["set"].items():
            entry = {"value": value, "pack": pack, "key": path, "source": src, "correction": c["id"],
                     "original": old[f"{kp}/{path}"]["value"] if f"{kp}/{path}" in old else None}
            if pack == MASTER_PACK and path.startswith(MASTER_PREFIX):
                entry["role"] = "daytime-master"
            entries[f"{kp}/{path}"] = entry
        c["originalValues"] = {e["key"]: e["value"] for e in old.values()}
    return {
        "corrections": corrections,
        # Deterministic: newest approved pack date, not wall-clock time.
        "generated": max(dates) if dates else "unknown",
        "generator": "Tools/lookloop/compile_mocks.py",
        "approvedPacks": [p for p, _ in packs],
        "precedence": precedence(packs, root),
        "conflicts": (find_conflicts({k: e for k, e in entries.items() if e["pack"] not in OWN_PACKS})
                      + archetype_conflicts(entries) + geometry_conflict(entries, root) + look_conflicts(entries) + signs_conflicts(entries)),
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
