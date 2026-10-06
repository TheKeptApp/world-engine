"""Clip very large multipolygon relations in a detailed Overpass JSON file (`osm.json`).

Why: the "all" query recurses into every multipolygon that touches the area box, so a relation such as
Lake Michigan (relation 1205149, 1,251 members) drags in all of its member ways and their nodes (82,000
nodes, 8 MB for a 1 km box). The relation is kept as is (tags and full member list, the same shape the
context layer uses for big water); only its member ways that do not intersect the clip box, and the nodes
only those ways used, are removed.

Rules (never drop what other kept elements reference):
  * a way is dropped only if it is a member of a relation with >= min_members members, its node bounding
    box does not intersect the clip box, and no relation with fewer members lists it;
  * a node is dropped only if a dropped way used it and no kept way or kept relation uses it;
  * every kept element is copied byte for byte (the file is not re-serialised).

Python 3 standard library only.
"""
import hashlib
import json
import os
import re

MIN_MEMBERS = 300


def _split(text):
    """-> (prefix, [(obj, raw_text)], suffix). Elements are parsed with raw_decode so their text is kept."""
    m = re.search(r'"elements"\s*:\s*\[', text)
    if not m:
        raise ValueError("no elements array")
    dec = json.JSONDecoder()
    i = m.end()
    out = []
    n = len(text)
    while True:
        while i < n and text[i] in " \t\r\n,":
            i += 1
        if text[i] == "]":
            break
        obj, j = dec.raw_decode(text, i)
        out.append((obj, text[i:j]))
        i = j
    return text[:m.end()], out, text[i:]


def _bbox_hits(pts, box):
    if not pts:
        return False
    s, w, n, e = box
    lats = [p[0] for p in pts]
    lons = [p[1] for p in pts]
    return not (max(lats) < s or min(lats) > n or max(lons) < w or min(lons) > e)


def clip_text(text, box, min_members=MIN_MEMBERS):
    """box = (south, west, north, east). Returns (new_text, report dict)."""
    prefix, items, suffix = _split(text)
    coords = {}
    ways = {}
    big = []
    small_way_refs = set()
    for obj, _ in items:
        t = obj.get("type")
        if t == "node":
            coords[obj["id"]] = (obj["lat"], obj["lon"])
        elif t == "way":
            ways[obj["id"]] = obj
        elif t == "relation":
            if len(obj.get("members", [])) >= min_members:
                big.append(obj)
            else:
                for m in obj.get("members", []):
                    if m["type"] == "way":
                        small_way_refs.add(m["ref"])
    big_refs = {m["ref"] for r in big for m in r["members"] if m["type"] == "way"}
    dropped = set()
    for wid in big_refs:
        w = ways.get(wid)
        if w is None or wid in small_way_refs:
            continue
        pts = [coords[n] for n in w.get("nodes", []) if n in coords]
        if not _bbox_hits(pts, box):
            dropped.add(wid)
    # Nodes: used by dropped ways, and not by anything kept.
    used_by_dropped = set()
    used_by_kept = set()
    for wid, w in ways.items():
        (used_by_dropped if wid in dropped else used_by_kept).update(w.get("nodes", []))
    for obj, _ in items:
        if obj.get("type") == "relation":
            for m in obj.get("members", []):
                if m["type"] == "node":
                    used_by_kept.add(m["ref"])
    dropped_nodes = used_by_dropped - used_by_kept
    kept = []
    for obj, raw in items:
        t = obj.get("type")
        if t == "way" and obj["id"] in dropped:
            continue
        if t == "node" and obj["id"] in dropped_nodes:
            continue
        kept.append(raw)
    report = {
        "relations": [{"id": r["id"], "name": r.get("tags", {}).get("name"), "members": len(r["members"]),
                       "kept_member_ways": sum(1 for m in r["members"] if m["type"] == "way"
                                               and m["ref"] in ways and m["ref"] not in dropped)}
                      for r in big],
        "ways_before": len(ways), "ways_dropped": len(dropped),
        "nodes_before": len(coords), "nodes_dropped": len(dropped_nodes),
        "elements_before": len(items), "elements_after": len(kept),
    }
    new_text = prefix + "\n" + ",\n".join(kept) + "\n" + suffix if kept else prefix + suffix
    return new_text, report


def context_box(manifest):
    for s in manifest["sources"]:
        if "context" in s.get("layers", []):
            b = s["bounds"]
            return (b["south"], b["west"], b["north"], b["east"])
    return None


def update_manifest_text(text, path, nbytes, sha):
    """Replace bytes and sha256 of the source with the given path, keeping the file's formatting.
    Keys are sorted in manifest.json, so `bytes` precedes `path` and `sha256` follows it in a source."""
    hits = [m for m in re.finditer(r'"path"\s*:\s*"%s"' % re.escape(path), text)]
    if len(hits) != 1:
        raise ValueError("source %s not found uniquely in manifest" % path)
    pos = hits[0].start()
    before = list(re.finditer(r'("bytes"\s*:\s*)\d+', text[:pos]))[-1]
    text = text[:before.start()] + before.group(1) + str(nbytes) + text[before.end():]
    pos = text.index(hits[0].group(0))
    after = re.compile(r'("sha256"\s*:\s*")[0-9a-f]+').search(text, pos)
    return text[:after.start()] + after.group(1) + sha + text[after.end():]


def clip_area(area_dir, filename="osm.json", min_members=MIN_MEMBERS, write=True, log=print):
    with open(os.path.join(area_dir, "manifest.json"), encoding="utf-8") as f:
        mtext = f.read()
    box = context_box(json.loads(mtext))
    if box is None:
        raise ValueError("%s has no context source; nothing to clip against" % area_dir)
    p = os.path.join(area_dir, filename)
    with open(p, "rb") as f:
        raw = f.read()
    new_text, rep = clip_text(raw.decode("utf-8"), box, min_members)
    new = new_text.encode("utf-8")
    rep.update(bytes_before=len(raw), bytes_after=len(new), box=box)
    if rep["ways_dropped"] == 0:
        log("%s: nothing to clip" % area_dir)
        return rep
    sha = hashlib.sha256(new).hexdigest()
    rep["sha256"] = sha
    if write:
        with open(p, "wb") as f:
            f.write(new)
        with open(os.path.join(area_dir, "manifest.json"), "w", encoding="utf-8") as f:
            f.write(update_manifest_text(mtext, filename, len(new), sha))
    log("%s: %d -> %d bytes; ways %d -> %d; nodes %d -> %d; sha256 %s" % (
        area_dir, rep["bytes_before"], rep["bytes_after"], rep["ways_before"],
        rep["ways_before"] - rep["ways_dropped"], rep["nodes_before"],
        rep["nodes_before"] - rep["nodes_dropped"], sha))
    return rep
