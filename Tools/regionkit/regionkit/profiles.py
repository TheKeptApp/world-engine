"""Template/reference profiles, read in place (never copied or modified):
Sources/WorldGen/Profiles/<id>.json, else the `profiles` array of
docs/proposals/regions-v1/regions-draft.json (read-only input)."""
import copy
import json
import os

from . import paths

# Other data tables in the profiles folder (palettes, light, weather, display policy...) are not
# StyleProfiles. They are recognised by shape (no `houseTypes`), so new tables need no list update.
NON_PROFILE_FILES = {"regions", "base-palette", "seasonal-palette", "time-of-day", "weather"}


def _is_style_profile(path):
    try:
        with open(path) as f:
            d = json.load(f)
    except (OSError, ValueError):
        return False
    return isinstance(d, dict) and "houseTypes" in d
# Proposal folders whose profiles/<id>.json files are standalone StyleProfile objects (read-only input).
PROPOSAL_PROFILE_DIRS = ["docs/proposals/regions-chicagoland-miami/profiles"]


def engine_profile_ids():
    out = []
    for f in sorted(os.listdir(paths.PROFILES)):
        if f.endswith(".json") and f[:-5] not in NON_PROFILE_FILES and _is_style_profile(os.path.join(paths.PROFILES, f)):
            out.append(f[:-5])
    return out


def proposal_profiles():
    if not os.path.exists(paths.REGIONS_DRAFT):
        return {}
    with open(paths.REGIONS_DRAFT) as f:
        d = json.load(f)
    return {p["id"]: p for p in d.get("profiles", [])}


def proposal_additions():
    if not os.path.exists(paths.REGIONS_DRAFT):
        return {}
    with open(paths.REGIONS_DRAFT) as f:
        d = json.load(f)
    return (d.get("proposedAdditions") or {}).get("profiles", {})


def load(pid):
    """(profile dict deep copy, source path relative to the repo)."""
    p = os.path.join(paths.PROFILES, pid + ".json")
    if pid not in NON_PROFILE_FILES and os.path.exists(p) and _is_style_profile(p):
        with open(p) as f:
            return json.load(f), paths.repo_rel(p)
    props = proposal_profiles()
    if pid in props:
        return copy.deepcopy(props[pid]), paths.repo_rel(paths.REGIONS_DRAFT) + "#profiles/" + pid
    for d in PROPOSAL_PROFILE_DIRS:
        rel = "%s/%s.json" % (d, pid)
        f = paths.repo_file(rel)
        if f:
            with open(f) as fh:
                return json.load(fh), rel
    raise KeyError("unknown template profile %r (looked in %s and %s)" % (
        pid, paths.repo_rel(paths.PROFILES), paths.repo_rel(paths.REGIONS_DRAFT)))


def all_known():
    """Every profile the validator must accept: engine profiles + regions-v1 profiles."""
    out = []
    for pid in engine_profile_ids():
        prof, src = load(pid)
        out.append((pid, prof, src))
    for pid, prof in proposal_profiles().items():
        out.append((pid, copy.deepcopy(prof), paths.repo_rel(paths.REGIONS_DRAFT) + "#profiles/" + pid))
    for d in PROPOSAL_PROFILE_DIRS:
        base = paths.repo_file(d)
        if not base:
            continue
        for f in sorted(os.listdir(base)):
            if f.endswith(".json"):
                with open(os.path.join(base, f)) as fh:
                    out.append((f[:-5], json.load(fh), "%s/%s" % (d, f)))
    return out
