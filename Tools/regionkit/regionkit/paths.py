"""Repository paths and JSON helpers."""
import json
import os

KIT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))          # Tools/regionkit
REPO = os.path.dirname(os.path.dirname(KIT))                               # repository root
PROFILES = os.path.join(REPO, "Sources", "WorldGen", "Profiles")
REGIONS_DRAFT = os.path.join(REPO, "docs", "proposals", "regions-v1", "regions-draft.json")
DATA = os.path.join(KIT, "data")
DRAFTS = os.path.join(KIT, "drafts")
REGIONS = os.path.join(KIT, "regions")


def repo_file(rel):
    """A repository-relative path, else the same path under $REGIONKIT_PROPOSALS_ROOT (another checkout
    of this repository, used when proposal folders are not committed here yet). Read-only use."""
    cand = os.path.join(REPO, rel)
    if os.path.exists(cand):
        return cand
    alt = os.environ.get("REGIONKIT_PROPOSALS_ROOT")
    if alt and os.path.exists(os.path.join(alt, rel)):
        return os.path.join(alt, rel)
    return None


def config_path(p):
    for cand in (p, os.path.join(KIT, p), os.path.join(REGIONS, p), os.path.join(REGIONS, p + ".json")):
        if os.path.isfile(cand):
            return os.path.abspath(cand)
    raise FileNotFoundError(p)


def repo_rel(p):
    return os.path.relpath(os.path.abspath(p), REPO)


def load_json(p):
    with open(p) as f:
        return json.load(f)


def write_json(p, obj, compact_lists=True):
    """Deterministic JSON: 2-space indent, short numeric/string lists kept on one line."""
    text = json.dumps(obj, indent=2, ensure_ascii=False)
    if compact_lists:
        import re
        def squash(m):
            inner = m.group(0)
            flat = " ".join(inner.split())
            flat = flat.replace("[ ", "[").replace(" ]", "]")
            return flat if len(flat) <= 100 else inner
        text = re.sub(r"\[[^\[\]{}]*\]", squash, text)
    os.makedirs(os.path.dirname(os.path.abspath(p)), exist_ok=True)
    with open(p, "w") as f:
        f.write(text + "\n")


def data_table(name):
    return load_json(os.path.join(DATA, name))
