"""Overpass JSON parsing, multipolygon assembly and the per-cell fetch query.

Parsing and assembly follow Sources/WorldMap/OSMDocument.swift and MultipolygonAssembler.swift
(member ways with role != "inner" are outers; each inner goes to the smallest containing outer).
"""
import json

from . import geo


class Doc:
    def __init__(self):
        self.nodes = {}       # id -> (lat, lon, tags)
        self.ways = {}        # id -> (node ids, tags)
        self.relations = {}   # id -> (members [(type, ref, role)], tags)
        self.excluded_relations = {}  # id -> tags (printed without members: too large to fetch)
        self.timestamp = None

    @classmethod
    def from_overpass(cls, data):
        j = json.loads(data) if isinstance(data, (bytes, str)) else data
        d = cls()
        d.timestamp = (j.get("osm3s") or {}).get("timestamp_osm_base")
        for e in j.get("elements", []):
            t = e.get("type")
            tags = e.get("tags") or {}
            if t == "node":
                if "lat" in e and "lon" in e:
                    d.nodes[e["id"]] = (e["lat"], e["lon"], tags)
            elif t == "way":
                d.ways[e["id"]] = (e.get("nodes") or [], tags)
            elif t == "relation":
                if "members" not in e:
                    d.excluded_relations[e["id"]] = tags
                    continue
                d.relations[e["id"]] = ([(m["type"], m["ref"], m.get("role", "")) for m in e["members"]], tags)
        return d

    def way_latlons(self, wid):
        nids, _ = self.ways[wid]
        out = []
        for n in nids:
            nd = self.nodes.get(n)
            if nd is None:
                return None
            out.append((nd[0], nd[1]))
        return out


def is_closed(nids):
    return len(nids) >= 4 and nids[0] == nids[-1]


def join_rings(chains):
    """MultipolygonAssembler.joinRings: join open node-ID chains into closed rings, None if any
    chain cannot be closed."""
    remaining = [c for c in chains if len(c) >= 2]
    rings = []
    while remaining:
        current = list(remaining.pop())
        while current[0] != current[-1]:
            tail = current[-1]
            idx = None
            for i, c in enumerate(remaining):
                if c[0] == tail or c[-1] == tail:
                    idx = i
                    break
            if idx is None:
                return None
            nxt = remaining.pop(idx)
            current += (nxt if nxt[0] == tail else nxt[::-1])[1:]
        if len(current) >= 4:
            rings.append(current)
    return rings


def assemble(doc, rid, frame):
    """Returns (list of geo.Polygon, error string or None)."""
    members, _ = doc.relations[rid]
    outer_chains, inner_chains = [], []
    for typ, ref, role in members:
        if typ != "way":
            continue
        w = doc.ways.get(ref)
        if w is None:
            return [], "multipolygon member way/%d missing" % ref
        (inner_chains if role == "inner" else outer_chains).append(w[0])
    outer_ids, inner_ids = join_rings(outer_chains), join_rings(inner_chains)
    if outer_ids is None or inner_ids is None:
        return [], "multipolygon ring does not close"

    def ring(ids):
        r = []
        for n in ids[:-1]:
            nd = doc.nodes.get(n)
            if nd is None:
                return None
            r.append(frame.xy(nd[0], nd[1]))
        return r

    outers = [r for r in (ring(i) for i in outer_ids) if r]
    inners = [r for r in (ring(i) for i in inner_ids) if r]
    if not outers:
        return [], "multipolygon has no outer ring"
    polys = [geo.Polygon(o) for o in outers]
    for inner in inners:
        probe = inner[0]
        containing = [i for i, p in enumerate(polys) if geo.ring_contains(p.outer, probe)]
        if containing:
            i = min(containing, key=lambda k: abs(geo.signed_area(polys[k].outer)))
            polys[i].holes.append(inner)
    return polys, None


# --- tag rules (Sources/WorldMap/MapFeatureBuilder.swift) ----------------------------------------
def building_type(t):
    """`building=*` value (not "no"), else `building:part` value; None if not a building."""
    b = t.get("building")
    if b is not None and b != "no":
        return b
    p = t.get("building:part")
    if p is not None and p != "no":
        return "yes" if p == "yes" else p
    return None


def is_area_way(nids, tags):
    """MapFeatureBuilder.classifyWay: closed ways describe areas unless they are highways (without
    area=yes) or area=no."""
    is_area = tags.get("area") == "yes"
    return is_closed(nids) and not (tags.get("highway") is not None and not is_area) and tags.get("area") != "no"


# --- the per-cell query -----------------------------------------------------------------------
MAX_RELATION_MEMBERS = 300


def cell_query(bbox, highway_bbox):
    """One Overpass query per sample cell (Fetcher.swift style: explicit per-statement boxes and
    `(._;>;); out body qt;` so ways crossing the edge come back complete).

    Area multipolygons with >= MAX_RELATION_MEMBERS members (e.g. a Great Lake) are not recursed;
    they are listed with `out tags` so the report can flag them."""
    b = "(%.6f,%.6f,%.6f,%.6f)" % tuple(bbox)
    hb = "(%.6f,%.6f,%.6f,%.6f)" % tuple(highway_bbox)
    big = "(if:count_members()<%d)" % MAX_RELATION_MEMBERS
    huge = "(if:count_members()>=%d)" % MAX_RELATION_MEMBERS
    mp = '["type"="multipolygon"]'
    return ("[out:json][timeout:180];\n"
            "(\n"
            '  way["building"]%(b)s;\n'
            '  relation["building"]%(mp)s%(b)s;\n'
            '  way["building:part"]%(b)s;\n'
            '  relation["building:part"]%(mp)s%(b)s;\n'
            '  way["highway"]%(hb)s;\n'
            '  way["barrier"~"^(fence|wall|hedge|retaining_wall)$"]%(b)s;\n'
            '  relation["barrier"="hedge"]%(mp)s%(b)s;\n'
            '  node["natural"="tree"]%(b)s;\n'
            '  way["natural"]%(b)s;\n'
            '  relation["natural"]%(mp)s%(b)s%(big)s;\n'
            '  way["landuse"]%(b)s;\n'
            '  relation["landuse"]%(mp)s%(b)s%(big)s;\n'
            '  way["leisure"]%(b)s;\n'
            '  relation["leisure"]%(mp)s%(b)s%(big)s;\n'
            '  way["amenity"]%(b)s;\n'
            '  relation["amenity"]%(mp)s%(b)s%(big)s;\n'
            '  way["water"]%(b)s;\n'
            '  relation["water"]%(mp)s%(b)s%(big)s;\n'
            '  node["shop"]%(b)s;\n'
            '  node["office"]%(b)s;\n'
            '  node["amenity"]%(b)s;\n'
            '  node["craft"]%(b)s;\n'
            ");\n"
            "(._;>;);\n"
            "out body qt;\n"
            "(\n"
            '  relation["natural"]%(mp)s%(b)s%(huge)s;\n'
            '  relation["landuse"]%(mp)s%(b)s%(huge)s;\n'
            '  relation["leisure"]%(mp)s%(b)s%(huge)s;\n'
            '  relation["water"]%(mp)s%(b)s%(huge)s;\n'
            ");\n"
            "out tags;") % {"b": b, "hb": hb, "mp": mp, "big": big, "huge": huge}
