"""Per-cell extraction of buildings, streets, barriers, trees and land cover, and the aggregate
measures written to measurements.json. Only aggregates leave this module (no per-feature output).

Conventions
- Frame: local east/north metres around the cell centre (WGS84 ENU, as LocalFrame.swift).
- A building belongs to a cell if its (uncleaned) outer-ring centroid is inside the cell rectangle,
  then its footprint is cleaned with Polygon2D.cleaned(minArea: 1) - the engine's own rule.
- "Buildings" = outlines (`building=*` != no). `building:part`-only features are counted separately
  and excluded from every building/house statistic (they would double count the outline).
- Lengths (streets, alleys, barriers, tree rows) are clipped to the cell rectangle.
- Streets are fetched in a box 100 m larger than the cell so houses near the edge find their street.
"""
import math
from collections import Counter, defaultdict

from . import colours, geo, osm, paths, rules, stats

SETBACK_CLASSES = {"residential", "living_street", "unclassified", "tertiary", "secondary", "primary"}
SETBACK_RADIUS = 60.0      # same radius as StreetContext.frontEdge
ALLEY_NEAR_M = 30.0        # "house within ~30 m of an alley"
GARAGE_ALLEY_ADJ_M = 8.0   # garage footprint within 8 m of an alley centreline = adjacent
BARRIER_KINDS = ("fence", "wall", "hedge", "retaining_wall")
TAGS_TRACKED = ["building:levels", "height", "roof:shape", "roof:levels", "roof:height", "roof:angle", "roof:material",
                "roof:colour", "building:material", "building:colour", "start_date"]

_USE = None
_GENUS = None
_MATERIALS = None


def use_table():
    global _USE
    if _USE is None:
        t = paths.data_table("use_classes.json")
        _USE = {k: set(v) for k, v in t.items() if isinstance(v, list)}
    return _USE


def genus_table():
    global _GENUS
    if _GENUS is None:
        t = paths.data_table("genus_leaf.json")
        common = {k: v for k, v in t["commonNames"].items() if k != "comment"}
        _GENUS = (t["genus"], t["species"], sorted(common.items(), key=lambda kv: (-len(kv[0]), kv[0])))
    return _GENUS


_PALMS = None


def palm_genera():
    global _PALMS
    if _PALMS is None:
        _PALMS = set(paths.data_table("genus_leaf.json").get("palmGenera", []))
    return _PALMS


def material_table():
    global _MATERIALS
    if _MATERIALS is None:
        _MATERIALS = paths.data_table("materials.json")
    return _MATERIALS


def year_of(v):
    if not v:
        return None
    digits = ""
    for ch in v:
        if ch.isdigit():
            digits += ch
            if len(digits) == 4:
                y = int(digits)
                return y if 1700 <= y <= 2100 else None
        else:
            digits = ""
    return None


def tree_habit(tags):
    """(leaf_type, leaf_cycle, source) from tags, else from genus/species/taxon via data/genus_leaf.json."""
    lt, lc = tags.get("leaf_type"), tags.get("leaf_cycle")
    src = "tag" if (lt or lc) else None
    if lt and lc:
        return lt, lc, "tag"
    genus, species, common = genus_table()
    name = None
    for k in ("species", "taxon", "genus"):
        if tags.get(k):
            name = tags[k].split(";")[0].strip()
            break
    derived = None
    how = None
    if name:
        parts = name.replace("×", "× ").split()
        sp = " ".join(name.split()[:2]) if len(name.split()) >= 2 else None
        if sp and sp in species:
            derived, how = species[sp], "species"
        else:
            g = parts[0].capitalize() if parts else None
            if g in genus:
                derived, how = genus[g], "genus"
    if derived is None:
        for k in ("species:en", "taxon:en", "genus:en", "name"):
            v = (tags.get(k) or "").lower()
            if not v:
                continue
            for cname, hab in common:
                if cname in v:
                    derived, how = hab, "commonName"
                    break
            if derived:
                break
    if derived:
        lt = lt or derived[0]
        lc = lc or (derived[1] if derived[1] != "mixed" else None)
        src = src + "+" + how if src else how
    return lt, lc, src


def tree_genus(tags):
    if tags.get("genus"):
        return tags["genus"].split(";")[0].strip().capitalize()
    for k in ("species", "taxon"):
        if tags.get(k):
            return tags[k].split()[0].strip().capitalize()
    return None


PROBABLE_GARAGE_MAX_M2 = 60.0


def is_probable_garage(b):
    """A generator `house` that is probably a detached garage: building=yes, under 60 m2, and within 8 m
    of a service/unnamed road (the engine's alley set). Diagnostic only; the generator still treats it
    as a house."""
    return b["type"] == "yes" and b["area"] < PROBABLE_GARAGE_MAX_M2 and bool(b.get("service_adjacent"))


def principal_houses(bs):
    return [b for b in bs if b["role"] == "house" and not b.get("probable_garage")]


class Cell:
    """Everything measured in one sample cell (in memory only)."""

    def __init__(self, spec, doc, template, fetch_record):
        self.spec = spec
        self.fetch = fetch_record
        self.template = template
        lat, lon = spec["center"]
        self.frame = geo.LocalFrame(lat, lon)
        if spec.get("manifestSize") and spec["manifestSize"][0]:
            w, h = spec["manifestSize"]
            self.rect = (-w / 2, -h / 2, w / 2, h / 2)  # AreaManifest: Rect2D(centerWidth:height:)
        elif spec.get("radiusMeters"):
            r = spec["radiusMeters"]
            self.rect = (-r, -r, r, r)
        else:
            s, w_, n, e = spec["bbox"]
            sw, ne = self.frame.xy(s, w_), self.frame.xy(n, e)
            nw, se = self.frame.xy(n, w_), self.frame.xy(s, e)
            self.rect = ((sw[0] + nw[0]) / 2, (sw[1] + se[1]) / 2, (ne[0] + se[0]) / 2, (ne[1] + nw[1]) / 2)
        self.area_m2 = (self.rect[2] - self.rect[0]) * (self.rect[3] - self.rect[1])
        self.buildings, self.parts, self.skipped = [], [], []
        self.roads, self.trees, self.pois = [], [], []
        self.lengths = Counter()
        self.flags = []
        self.landcover = {}
        self._extract(doc)

    def inside(self, p):
        x0, y0, x1, y1 = self.rect
        return x0 <= p[0] <= x1 and y0 <= p[1] <= y1

    # --- extraction ----------------------------------------------------------------------
    def _extract(self, doc):
        fr = self.frame
        area_polys = defaultdict(list)

        def node_xy(nid):
            n = doc.nodes.get(nid)
            return None if n is None else fr.xy(n[0], n[1])

        for wid in sorted(doc.ways):
            nids, tags = doc.ways[wid]
            if not tags:
                continue
            pts = [node_xy(n) for n in nids]
            if any(p is None for p in pts):
                self.skipped.append(("way", wid, "missing nodes"))
                continue
            btype = osm.building_type(tags)
            if btype is not None and osm.is_area_way(nids, tags):
                self._add_building(("way", wid), tags, btype, geo.Polygon(pts[:-1]))
                continue
            if osm.is_area_way(nids, tags):
                for cat in self._area_categories(tags):
                    area_polys[cat].append(geo.Polygon(pts[:-1]))
            hw = tags.get("highway")
            if hw is not None and tags.get("area") != "yes":
                self._add_road(wid, hw, tags, pts)
                continue
            bar = tags.get("barrier")
            if bar in BARRIER_KINDS or tags.get("natural") == "tree_row":
                key = "tree_row" if tags.get("natural") == "tree_row" else bar
                for piece in geo.clip_polyline(pts, self.rect):
                    self.lengths["barrier:" + key] += geo.polyline_length(piece)
                if key == "hedge" and tags.get("area") == "yes":
                    self.lengths["hedge_area_count"] += 1
            if tags.get("natural") == "coastline":
                if any(geo.clip_polyline(pts, self.rect)):
                    self.flags.append("cell touches a natural=coastline way (shoreline)")

        for rid in sorted(doc.relations):
            members, tags = doc.relations[rid]
            if tags.get("type") not in ("multipolygon",):
                continue
            btype = osm.building_type(tags)
            cats = self._area_categories(tags)
            if btype is None and not cats:
                continue
            polys, err = osm.assemble(doc, rid, fr)
            if err:
                self.skipped.append(("relation", rid, err))
                continue
            for poly in polys:
                if btype is not None:
                    self._add_building(("relation", rid), tags, btype, poly)
                else:
                    for cat in cats:
                        area_polys[cat].append(poly)

        for rid, tags in sorted(doc.excluded_relations.items()):
            self.flags.append("large area relation not fetched (>= %d members): %s" % (
                osm.MAX_RELATION_MEMBERS, ", ".join("%s=%s" % (k, tags[k]) for k in ("natural", "water", "landuse", "leisure", "name") if k in tags)))

        use = use_table()
        for nid in sorted(doc.nodes):
            lat, lon, tags = doc.nodes[nid]
            if not tags:
                continue
            p = fr.xy(lat, lon)
            if not self.inside(p):
                continue
            if tags.get("natural") == "tree":
                lt, lc, src = tree_habit(tags)
                self.trees.append({"leaf_type_tag": tags.get("leaf_type"), "leaf_cycle_tag": tags.get("leaf_cycle"),
                                   "leaf_type": lt, "leaf_cycle": lc, "habit_source": src,
                                   "genus": tree_genus(tags), "species": tags.get("species"), "taxon": tags.get("taxon"),
                                   "height": rules.parse_length(tags.get("height")) if tags.get("height") else None,
                                   "has_height": "height" in tags, "has_crown": "diameter_crown" in tags,
                                   "has_circumference": "circumference" in tags})
                continue
            if any(k in tags for k in use["commercialKeys"]) or tags.get("amenity") in use["commercialAmenities"]:
                self.pois.append(p)

        # land cover unions (1 m raster over the cell)
        for cat, polys in area_polys.items():
            r = geo.Raster(self.rect, 1.0)
            for poly in polys:
                r.fill_polygon(poly)
            self.landcover[cat] = r
        self._post()

    @staticmethod
    def _area_categories(t):
        cats = []
        if (t.get("natural") == "water" or t.get("waterway") == "riverbank" or t.get("water") is not None
                or t.get("landuse") in ("reservoir", "basin")):
            cats.append("water")
        if t.get("natural") == "wood" or t.get("landuse") == "forest":
            cats.append("wood")
        if t.get("landuse") == "residential":
            cats.append("residential")
        if t.get("landuse") in ("commercial", "retail"):
            cats.append("commercial")
        if t.get("leisure") == "park":
            cats.append("park")
        return cats

    def _add_building(self, ref, tags, btype, poly):
        if not self.inside(poly.centroid):
            return
        clean = poly.cleaned(min_area=1.0)
        if clean is None:
            self.skipped.append((ref[0], ref[1], "degenerate footprint"))
            return
        area = clean.area
        fp = geo.Footprint(clean)
        lv = rules.parse_number(tags.get("building:levels")) if tags.get("building:levels") else None
        b = {
            "ref": ref, "type": btype, "is_part": tags.get("building") is None, "poly": clean, "area": area, "fp": fp,
            "aspect": fp.aspect, "rect": fp.rectangularity, "kind": fp.kind,
            "role": rules.role(btype, area),
            "levels_raw": lv,
            "levels_int": int(rules.swift_round(lv)) if lv is not None else None,
            "roof_levels": rules.parse_number(tags.get("roof:levels")) if tags.get("roof:levels") else None,
            "height": rules.parse_length(tags.get("height")) if tags.get("height") else None,
            "roof_height": rules.parse_length(tags.get("roof:height")) if tags.get("roof:height") else None,
            "roof_angle": rules.parse_number(tags.get("roof:angle")) if tags.get("roof:angle") else None,
            "roof_shape": tags.get("roof:shape"),
            "roof_material": tags.get("roof:material"), "roof_colour": tags.get("roof:colour"),
            "building_material": tags.get("building:material"), "building_colour": tags.get("building:colour"),
            "year": year_of(tags.get("start_date")),
            "present": {k: (k in tags) for k in TAGS_TRACKED},
            "tags_use": {k: tags[k] for k in ("shop", "office", "craft", "amenity", "building:use", "tourism") if k in tags},
        }
        (self.parts if b["is_part"] else self.buildings).append(b)

    def _add_road(self, wid, hw, tags, pts):
        kind = rules.highway_kind(hw)
        width, wsrc = rules.road_width(kind, tags)
        rd = {"id": wid, "tag": hw, "kind": kind, "tags": {k: tags[k] for k in ("name", "service", "width", "lanes") if k in tags},
              "line": pts, "width": width, "width_source": wsrc}
        self.roads.append(rd)
        clipped = sum(geo.polyline_length(pc) for pc in geo.clip_polyline(pts, self.rect))
        if clipped <= 0:
            return
        self.lengths["highway:" + hw] += clipped
        if hw == "service":
            self.lengths["service:" + tags.get("service", "(none)")] += clipped
        if tags.get("footway") == "sidewalk" or tags.get("path") == "sidewalk":
            self.lengths["sidewalk"] += clipped

    # --- per-feature derived values --------------------------------------------------------
    def _post(self):
        streets = [r for r in self.roads if rules.is_street(r["kind"], r["tags"])]
        alley_like = [r for r in self.roads if rules.is_alley_like(r["kind"], r["tags"])]
        setback_roads = [r for r in self.roads if r["tag"] in SETBACK_CLASSES]
        alleys = [r for r in self.roads if r["tag"] == "service" and r["tags"].get("service") == "alley"]
        street_idx = geo.SegmentIndex([r["line"] for r in streets])
        alley_like_idx = geo.SegmentIndex([r["line"] for r in alley_like])
        setback_idx = geo.SegmentIndex([r["line"] for r in setback_roads])
        alley_idx = geo.SegmentIndex([r["line"] for r in alleys])

        # POIs -> buildings (bbox grid)
        grid = defaultdict(list)
        for i, b in enumerate(self.buildings):
            x0, y0, x1, y1 = b["poly"].bounds()
            for gx in range(int(math.floor(x0 / 50)), int(math.floor(x1 / 50)) + 1):
                for gy in range(int(math.floor(y0 / 50)), int(math.floor(y1 / 50)) + 1):
                    grid[(gx, gy)].append(i)
        for b in self.buildings:
            b["poi"] = 0
        for p in self.pois:
            for i in grid.get((int(math.floor(p[0] / 50)), int(math.floor(p[1] / 50))), ()):
                if self.buildings[i]["poly"].contains(p):
                    self.buildings[i]["poi"] += 1
                    break

        res = self.landcover.get("residential")
        com = self.landcover.get("commercial")
        for b in self.buildings:
            ring = b["poly"].outer
            c = geo.centroid(ring)
            b["in_res_landuse"] = bool(res and res.contains_point(c))
            b["in_com_landuse"] = bool(com and com.contains_point(c))
            b["use"] = self._use_class(b)
            if b["role"] == "house":
                fe = rules.best_edge(ring, street_idx, 60.0)
                b["front_edge"] = fe
                b["broad_front"] = rules.broad_front(ring, fe, b["fp"].obb)
                b["setback"] = self._setback(ring, c, setback_idx, setback_roads)
                b["alley_near"] = self._near(ring, c, alley_idx, ALLEY_NEAR_M) is not None
                b["service_adjacent"] = self._near(ring, c, alley_like_idx, GARAGE_ALLEY_ADJ_M) is not None
                b["probable_garage"] = is_probable_garage(b)
            elif b["role"] == "garage":
                b["alley_adjacent"] = self._near(ring, c, alley_idx, GARAGE_ALLEY_ADJ_M) is not None
                b["engine_alley_edge"] = rules.best_edge(ring, alley_like_idx, 30.0) is not None

    def _use_class(self, b):
        use = use_table()
        t = b["type"]
        commercial_sig = b["poi"] > 0 or any(k in b["tags_use"] for k in use["commercialKeys"]) or \
            b["tags_use"].get("amenity") in use["commercialAmenities"]
        if b["role"] in ("garage", "shed") or t in use["outbuilding"]:
            return "outbuilding"
        if t in use["mixed"] or "mixed" in (b["tags_use"].get("building:use") or ""):
            return "mixed"
        if t in use["residential"]:
            return "mixed" if commercial_sig else "residential"
        if t in use["commercial"]:
            return "commercial"
        if t in use["other"]:
            return "other"
        if commercial_sig:
            return "commercial (tags/POI)"
        if b["in_res_landuse"]:
            return "residential (landuse)"
        if b["in_com_landuse"]:
            return "commercial (landuse)"
        return "unknown"

    def _segments_near(self, idx, p, radius):
        r = int(math.ceil(radius / idx.cell))
        kx, ky = idx.key(p[0]), idx.key(p[1])
        seen = set()
        out = []
        for x in range(kx - r, kx + r + 1):
            for y in range(ky - r, ky + r + 1):
                for s in idx.buckets.get((x, y), ()):
                    key = (s[0], s[1], s[2])
                    if key in seen:
                        continue
                    seen.add(key)
                    out.append(s)
        return out

    def _near(self, ring, c, idx, radius):
        """(distance, line index) from the footprint boundary to the nearest line within radius."""
        reach = radius + max(geo.dist(c, q) for q in ring)
        best = None
        n = len(ring)
        for li, a, b in self._segments_near(idx, c, reach):
            if geo.ring_contains(ring, a):
                return (0.0, li)
            for i in range(n):
                d = geo.segment_segment_distance(ring[i], ring[(i + 1) % n], a, b)
                if d <= radius and (best is None or d < best[0]):
                    best = (d, li)
        return best

    def _setback(self, ring, c, idx, roads):
        hit = self._near(ring, c, idx, SETBACK_RADIUS)
        if hit is None:
            return None
        d, li = hit
        rd = roads[li]
        return {"centerline_m": d, "half_width_m": rd["width"] / 2, "facade_to_curb_m": d - rd["width"] / 2,
                "class": rd["tag"], "width_source": rd["width_source"]}


# --- aggregation ------------------------------------------------------------------------------
def _ratio_km2(metres, area_m2, digits=3):
    return round(metres / 1000 / (area_m2 / 1e6), digits) if area_m2 else None


def summarize(cells, template):
    """Aggregate measures for one or more cells (pooled)."""
    t = template["typeThresholds"]
    area = sum(c.area_m2 for c in cells)
    km2 = area / 1e6
    B = [b for c in cells for b in c.buildings]
    P = [b for c in cells for b in c.parts]
    H = [b for b in B if b["role"] == "house"]
    G = [b for b in B if b["role"] == "garage"]
    roles = Counter(b["role"] for b in B)
    out = {"cellCount": len(cells), "areaKm2": round(km2, 4)}

    # counts and densities
    out["buildings"] = {
        "outlines": len(B), "buildingParts": len(P),
        "perKm2": round(len(B) / km2, 1) if km2 else None,
        "housesPerKm2": round(len(H) / km2, 1) if km2 else None,
        "byRole": stats.shares(roles),
        "byBuildingValue": stats.shares(Counter(b["type"] for b in B), top=25),
        "partsByRole": stats.shares(Counter(b["role"] for b in P)) if P else {},
        "footprintClassByRole": {r: stats.shares(Counter(b["kind"] for b in B if b["role"] == r)) for r in sorted(roles)},
        "skippedFeatures": sum(len(c.skipped) for c in cells),
    }

    # levels / heights
    def levels_hist(bs):
        cnt = Counter()
        for b in bs:
            li = b["levels_int"]
            if b["levels_raw"] is None or li is None or li <= 0:
                continue
            cnt[str(li) if li < 5 else "5+"] += 1
        return cnt

    lv = {}
    for r in sorted(roles):
        bs = [b for b in B if b["role"] == r]
        h = levels_hist(bs)
        lv[r] = {"n": len(bs), "withLevels": sum(h.values()), "share": stats.share(sum(h.values()), len(bs)),
                 "levels": stats.shares(h), "fractionalLevels": sum(1 for b in bs if b["levels_raw"] is not None and b["levels_raw"] != int(b["levels_raw"])),
                 "heightM": stats.dist([b["height"] for b in bs if b["height"] is not None]),
                 "roofLevels": stats.shares(Counter(str(b["roof_levels"]) for b in bs if b["roof_levels"] is not None))}
    alllv = levels_hist(B)
    out["levels"] = {"all": {"n": len(B), "withLevels": sum(alllv.values()), "share": stats.share(sum(alllv.values()), len(B)),
                             "levels": stats.shares(alllv),
                             "median": stats.percentile([b["levels_raw"] for b in B if b["levels_raw"] is not None and b["levels_raw"] > 0], 0.5)},
                     "byRole": lv}

    def mpl(bs):
        tot, wall = [], []
        for b in bs:
            if b["height"] is None or not b["levels_raw"]:
                continue
            tot.append(b["height"] / (b["levels_raw"] + (b["roof_levels"] or 0)))
            if b["roof_height"] is not None:
                wall.append((b["height"] - b["roof_height"]) / b["levels_raw"])
            elif b["roof_shape"] == "flat":
                wall.append(b["height"] / b["levels_raw"])
        return {"total": stats.dist(tot), "wall": stats.dist(wall)}

    out["metresPerLevel"] = {"houses": mpl(H), "allBuildings": mpl(B),
                             "definition": "total = height / (building:levels + roof:levels); wall = (height - roof:height) / building:levels, or height / building:levels when roof:shape=flat. Only buildings with both height and levels."}

    # roofs and materials
    def roofs(bs):
        raw = Counter(b["roof_shape"] for b in bs if b["roof_shape"])
        mapped = Counter(rules.map_roof(b["roof_shape"]) or "ignored(%s)" % b["roof_shape"] for b in bs if b["roof_shape"])
        return {"n": sum(raw.values()), "share": stats.share(sum(raw.values()), len(bs)), "raw": stats.shares(raw),
                "mapped": stats.shares(mapped)}

    out["roofShape"] = {"houses": roofs(H), "garages": roofs(G), "all": roofs(B)}
    out["roofAngleDeg"] = {"houses": stats.dist([b["roof_angle"] for b in H if b["roof_angle"] is not None]),
                           "all": stats.dist([b["roof_angle"] for b in B if b["roof_angle"] is not None])}

    def colour_freq(bs, key):
        raw = Counter()
        fam = Counter()
        unparsed = 0
        for b in bs:
            v = b[key]
            if not v:
                continue
            raw[v.strip().lower()] += 1
            hx, how = colours.normalize(v)
            if hx is None:
                unparsed += 1
            else:
                fam[colours.family(hx)] += 1
        return {"n": sum(raw.values()), "raw": stats.shares(raw, top=15), "families": stats.shares(fam), "unparsed": unparsed}

    out["materialsAndColours"] = {
        "roofMaterial": {"houses": stats.shares(Counter(b["roof_material"] for b in H if b["roof_material"]), top=15),
                         "all": stats.shares(Counter(b["roof_material"] for b in B if b["roof_material"]), top=15)},
        "buildingMaterial": {"houses": stats.shares(Counter(b["building_material"] for b in H if b["building_material"]), top=15),
                             "all": stats.shares(Counter(b["building_material"] for b in B if b["building_material"]), top=15)},
        "roofColour": {"houses": colour_freq(H, "roof_colour"), "all": colour_freq(B, "roof_colour")},
        "buildingColour": {"houses": colour_freq(H, "building_colour"), "all": colour_freq(B, "building_colour")},
    }

    # footprints
    fpr = {}
    for r in sorted(roles):
        bs = [b for b in B if b["role"] == r]
        fpr[r] = {"areaM2": stats.dist([b["area"] for b in bs], 1), "aspect": stats.dist([b["aspect"] for b in bs]),
                  "rectangularity": stats.dist([b["rect"] for b in bs], 3),
                  "obbShortSideM": stats.dist([2 * b["fp"].obb.half_width for b in bs], 1),
                  "obbLongSideM": stats.dist([2 * b["fp"].obb.half_length for b in bs], 1)}
    out["footprints"] = fpr

    sit = Counter()
    for b in H:
        sit[rules.situation(b["type"], b["levels_raw"], b["area"], b["aspect"], b["rect"], b["broad_front"], t)] += 1
    out["situationsTemplateThresholds"] = {"thresholds": t, "counts": stats.shares(sit)}

    PH = principal_houses(B)
    pg = [b for b in H if b.get("probable_garage")]
    small_yes = [b for b in H if b["type"] == "yes" and b["area"] < PROBABLE_GARAGE_MAX_M2]
    phl = Counter()
    for b in PH:
        if b["levels_raw"] is not None and b["levels_int"] and b["levels_int"] > 0:
            phl[str(b["levels_int"]) if b["levels_int"] < 5 else "5+"] += 1
    psb = [b["setback"]["facade_to_curb_m"] for b in PH if b.get("setback")]
    pfe = [b for b in PH if b.get("front_edge") is not None]
    out["probableGarages"] = {
        "definition": "generator houses with building=yes, footprint < 60 m2 and within 8 m of a service/unnamed road (the engine renders them as houses)",
        "n": len(pg), "shareOfHouses": stats.share(len(pg), len(H)),
        "smallBuildingYesHouses": len(small_yes), "shareOfSmallYesNearService": stats.share(len(pg), len(small_yes)),
        "withLevels": sum(1 for b in pg if b["levels_raw"] is not None)}
    out["principalHouses"] = {
        "definition": "generator houses minus probable garages",
        "n": len(PH), "levels": stats.shares(phl), "withLevels": sum(phl.values()),
        "footprintM2": stats.dist([b["area"] for b in PH], 1), "aspect": stats.dist([b["aspect"] for b in PH]),
        "obbShortSideM": stats.dist([2 * b["fp"].obb.half_width for b in PH], 1),
        "obbLongSideM": stats.dist([2 * b["fp"].obb.half_length for b in PH], 1),
        "facadeToCurbM": stats.dist(psb), "longSideFacesStreetShare": stats.share(sum(1 for b in pfe if b["broad_front"]), len(pfe)),
        "within30mOfAlleyShare": stats.share(sum(1 for b in PH if b.get("alley_near")), len(PH))}

    # use mix
    uses = Counter(b["use"] for b in B)
    nonout = {k: v for k, v in uses.items() if k != "outbuilding"}
    tot = sum(nonout.values())
    area_by = Counter()
    for b in B:
        if b["use"] != "outbuilding":
            area_by[b["use"]] += b["area"]
    grouped = Counter()
    for k, v in nonout.items():
        grouped[k.split(" ")[0]] += v
    out["useMix"] = {"definition": "Share of non-outbuilding outlines. residential/commercial/mixed from building=* (data/use_classes.json); a residential-type building with shop/office/craft/commercial-amenity tags or a commercial POI node inside it counts as mixed; building=yes etc. falls back to tags/POIs, then landuse=residential / commercial|retail at its centroid.",
                     "byCount": stats.shares(Counter(nonout)), "grouped": stats.shares(grouped),
                     "byFootprintArea": {k: round(v / sum(area_by.values()), 3) for k, v in sorted(area_by.items(), key=lambda kv: -kv[1])} if area_by else {},
                     "outbuildings": uses.get("outbuilding", 0), "n": tot}

    # setbacks and frontage
    sb = [b["setback"] for b in H if b.get("setback")]
    fe = [b for b in H if b.get("front_edge") is not None]
    broad = [b for b in fe if b["broad_front"]]
    out["setback"] = {
        "definition": "Footprint boundary to the nearest street centreline (residential, living_street, unclassified, tertiary, secondary, primary; within 60 m) minus half the carriageway (width tag, else lanes x 3.3 m, else the engine's RoadRules default per class: residential/unclassified 6 m, living_street 5, tertiary 8, secondary 10, primary 12). Negative = footprint overlaps the assumed carriageway (mapping/width error).",
        "housesMeasured": len(sb), "housesTotal": len(H), "coverage": stats.share(len(sb), len(H)),
        "facadeToCurbM": stats.dist([s["facade_to_curb_m"] for s in sb]),
        "centrelineM": stats.dist([s["centerline_m"] for s in sb]),
        "negative": sum(1 for s in sb if s["facade_to_curb_m"] < 0),
        "widthSource": stats.shares(Counter(s["width_source"] for s in sb)),
        "nearestClass": stats.shares(Counter(s["class"] for s in sb)),
    }
    out["frontage"] = {
        "definition": "Front edge = StreetContext.frontEdge (nearest NAMED vehicle street within 60 m, edges >= 2.5 m); long side faces street = BuildingGenerator broadFront (|dot(front edge, long axis)| > 0.85).",
        "housesWithFrontEdge": len(fe), "longSideFacesStreet": len(broad), "share": stats.share(len(broad), len(fe)),
        "shareAmongAspectAtLeastBroadAspect": stats.share(sum(1 for b in broad if b["aspect"] >= t["broadAspect"]),
                                                          sum(1 for b in fe if b["aspect"] >= t["broadAspect"])),
    }

    # coverage proxies
    res_area = sum(c.landcover["residential"].area() for c in cells if "residential" in c.landcover)
    water_area = sum(c.landcover["water"].area() for c in cells if "water" in c.landcover)
    houses_in_res = sum(b["area"] for b in H if b["in_res_landuse"])
    all_area = sum(b["area"] for b in B)
    out["coverage"] = {
        "definition": "OSM has no parcels. net = house footprint area (centroid inside landuse=residential) / landuse=residential area in the cell; gross = all outline footprint area / (cell area - water area).",
        "residentialLanduseKm2": round(res_area / 1e6, 4), "residentialLanduseShare": stats.share(res_area, area),
        "net": round(houses_in_res / res_area, 3) if res_area > 0.01 * area else None,
        "gross": round(all_area / (area - water_area), 3) if area - water_area > 0 else None,
        "waterShare": stats.share(water_area, area),
    }

    # alleys
    L = Counter()
    for c in cells:
        L.update(c.lengths)
    alley_m = L.get("service:alley", 0)
    out["alleys"] = {
        "alleyKmPerKm2": _ratio_km2(alley_m, area), "alleyKm": round(alley_m / 1000, 3),
        "driveways": {"kmPerKm2": _ratio_km2(L.get("service:driveway", 0), area)},
        "housesWithin30mOfAlley": {"n": sum(1 for b in H if b.get("alley_near")), "share": stats.share(sum(1 for b in H if b.get("alley_near")), len(H))},
        "garagesAdjacentToAlley": {"definition": "garage footprint within 8 m of a service=alley centreline",
                                   "n": sum(1 for b in G if b.get("alley_adjacent")), "share": stats.share(sum(1 for b in G if b.get("alley_adjacent")), len(G))},
        "garagesEngineAlleyEdge": {"definition": "StreetContext.alleyEdge finds an edge facing a service/unnamed road within 30 m (what the generator uses for the garage door)",
                                   "n": sum(1 for b in G if b.get("engine_alley_edge")), "share": stats.share(sum(1 for b in G if b.get("engine_alley_edge")), len(G))},
    }
    out["streets"] = {"kmPerKm2ByHighway": {k.split(":", 1)[1]: _ratio_km2(v, area) for k, v in sorted(L.items()) if k.startswith("highway:")},
                      "serviceKmPerKm2": {k.split(":", 1)[1]: _ratio_km2(v, area) for k, v in sorted(L.items()) if k.startswith("service:")},
                      "sidewalkKmPerKm2": _ratio_km2(L.get("sidewalk", 0), area)}

    # barriers
    bar = {}
    for k in BARRIER_KINDS + ("tree_row",):
        m = L.get("barrier:" + k, 0)
        bar[k] = {"km": round(m / 1000, 3), "kmPerKm2": _ratio_km2(m, area),
                  "mPer100Houses": round(m / len(H) * 100, 1) if H else None}
    bar["hedgeAreas"] = L.get("hedge_area_count", 0)
    out["barriers"] = bar

    # trees
    T = [x for c in cells for x in c.trees]
    lt_tag = Counter(x["leaf_type_tag"] for x in T if x["leaf_type_tag"])
    lc_tag = Counter(x["leaf_cycle_tag"] for x in T if x["leaf_cycle_tag"])
    lt_all = Counter(x["leaf_type"] for x in T if x["leaf_type"])
    lc_all = Counter(x["leaf_cycle"] for x in T if x["leaf_cycle"])
    heights = [x["height"] for x in T if x["height"] is not None]
    wood = sum(c.landcover["wood"].area() for c in cells if "wood" in c.landcover)
    park = sum(c.landcover["park"].area() for c in cells if "park" in c.landcover)
    out["trees"] = {
        "count": len(T), "perKm2": round(len(T) / km2, 1) if km2 else None,
        "leafTypeTagged": stats.shares(lt_tag), "leafCycleTagged": stats.shares(lc_tag),
        "leafTypeTagOrGenus": stats.shares(lt_all), "leafCycleTagOrGenus": stats.shares(lc_all),
        "habitSource": stats.shares(Counter(x["habit_source"] or "none" for x in T)),
        "palmShareOfTreesWithGenus": stats.share(sum(1 for x in T if x["genus"] in palm_genera()), sum(1 for x in T if x["genus"])),
        "topGenus": stats.shares(Counter(x["genus"] for x in T if x["genus"]), top=10),
        "topSpecies": stats.shares(Counter(x["species"] for x in T if x["species"]), top=10),
        "topTaxon": stats.shares(Counter(x["taxon"] for x in T if x["taxon"]), top=10),
        "heightM": stats.dist(heights),
        "tagCoverage": {"height": stats.share(sum(1 for x in T if x["has_height"]), len(T)),
                        "genus/species/taxon": stats.share(sum(1 for x in T if x["genus"] or x["species"] or x["taxon"]), len(T)),
                        "leaf_type": stats.share(len([x for x in T if x["leaf_type_tag"]]), len(T)),
                        "leaf_cycle": stats.share(len([x for x in T if x["leaf_cycle_tag"]]), len(T)),
                        "diameter_crown": stats.share(sum(1 for x in T if x["has_crown"]), len(T)),
                        "circumference": stats.share(sum(1 for x in T if x["has_circumference"]), len(T))},
        "treeRowKmPerKm2": _ratio_km2(L.get("barrier:tree_row", 0), area),
        "woodShare": stats.share(wood, area), "parkShare": stats.share(park, area),
    }

    # tag coverage
    def missing(bs):
        return {k: stats.share(sum(1 for b in bs if not b["present"][k]), len(bs)) for k in TAGS_TRACKED}

    out["tagMissing"] = {"buildings": missing(B), "houses": missing(H), "nBuildings": len(B), "nHouses": len(H)}
    years = [b["year"] for b in B if b["year"]]
    out["startDate"] = {"n": len(years), "decades": stats.shares(Counter("%ds" % (y // 10 * 10) for y in years))}
    out["flags"] = sorted(set(f for c in cells for f in c.flags))
    return out


def signature(cell_summary):
    """Zone signature for the classifier test (per cell)."""
    s = cell_summary
    hf = s["footprints"].get("house", {}).get("areaM2", {})
    lv = s["levels"]["all"]
    tall = 0
    n = 0
    for k, v in lv["levels"].items():
        n += v["n"]
        if k in ("3", "4", "5+"):
            tall += v["n"]
    return {
        "buildingsPerKm2": s["buildings"]["perKm2"],
        "housesPerKm2": s["buildings"]["housesPerKm2"],
        "houseShare": s["buildings"]["byRole"].get("house", {}).get("share", 0),
        "blockShare": s["buildings"]["byRole"].get("block", {}).get("share", 0),
        "medianLevels": lv["median"],
        "share3PlusLevels": round(tall / n, 3) if n else None,
        "levelsTagged": lv["share"],
        "houseFootprintP50": s.get("principalHouses", {}).get("footprintM2", {}).get("p50", hf.get("p50")),
        "probableGarageShare": s.get("probableGarages", {}).get("shareOfHouses"),
        "grossCoverage": s["coverage"]["gross"],
        "alleyKmPerKm2": s["alleys"]["alleyKmPerKm2"],
    }
