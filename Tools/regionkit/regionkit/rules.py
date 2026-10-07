"""Exact ports of the generator rules the drafts are calibrated against.

- TagParsing.length / number / integer        Sources/WorldMap/TagParsing.swift
- BuildingGenerator.role(of:)                  Sources/WorldGen/BuildingGenerator.swift (lines 56-66)
- BuildingGenerator.situation(...)             (lines 70-88)
- house type eligibility (houseType(for:))     (lines 101-109)
- OSM roof:shape -> generator roof             (lines 171-176)
- BuildingGenerator.hexColor named colours     (lines 493-503)
- RoadRules.width                              Sources/WorldMap/Rules.swift
- StreetContext streets/alleys + bestEdge      Sources/WorldGen/StreetContext.swift
"""
import math

from . import geo

# --- TagParsing ------------------------------------------------------------------------------


def first_value(raw):
    parts = raw.split(";")
    return (parts[0] if parts else raw).strip()


def parse_length(raw):
    """TagParsing.length: metres from `12`, `12.5`, `12 m`, `12 ft`, `40'`, `40'6\"`, `12,5`."""
    if raw is None:
        return None
    s = first_value(raw).lower()
    if "." not in s and s.count(",") == 1:
        s = s.replace(",", ".")
    meters = None
    if "'" in s:
        q = s.index("'")
        try:
            feet = float(s[:q].strip())
        except ValueError:
            feet = None
        rest = s[q + 1:].strip()
        if rest.endswith('"'):
            rest = rest[:-1]
        rest = rest.strip()
        try:
            inches = 0.0 if rest == "" else float(rest)
        except ValueError:
            inches = None
        if feet is not None and inches is not None:
            meters = feet * 0.3048 + inches * 0.0254
    else:
        end = 0
        while end < len(s) and (s[end].isdigit() and s[end] in "0123456789" or s[end] == "."):
            end += 1
        try:
            number = float(s[:end]) if end > 0 else None
        except ValueError:
            number = None
        unit = s[end:].strip()
        if number is not None:
            if unit in ("", "m", "meter", "meters", "metre", "metres"):
                meters = number
            elif unit in ("ft", "feet", "foot"):
                meters = number * 0.3048
    if meters is None or not (meters > 0 and meters <= 1000):
        return None
    return meters


def parse_number(raw):
    """TagParsing.number: plain non-negative number <= 500, first `;` value, `,` -> `.`."""
    if raw is None:
        return None
    s = first_value(raw).replace(",", ".")
    if "_" in s:  # Python accepts digit separators, Swift's Double(String) does not
        return None
    try:
        n = float(s)
    except ValueError:
        return None
    if math.isnan(n) or n < 0 or n > 500:
        return None
    # Swift Double("1e2") parses too; Python float accepts "inf"/"nan" strings, excluded above.
    return n


def parse_int(raw):
    if raw is None:
        return None
    try:
        return int(first_value(raw))
    except ValueError:
        return None


def swift_round(x):
    """Swift `Double.rounded()` (schoolbook: half away from zero)."""
    return math.floor(x + 0.5) if x >= 0 else -math.floor(-x + 0.5)


# --- roles and situations --------------------------------------------------------------------
HOUSE_TYPES = {"house", "detached", "semidetached_house", "bungalow", "residential", "terrace", "cabin"}
GARAGE_TYPES = {"garage", "garages", "carport"}
SHED_TYPES = {"shed", "hut", "kiosk", "toilets"}
TINY_AREA = geo.TINY_AREA  # 12 m2


def role(btype, area):
    """BuildingGenerator.role(of:) - order matters: garage, shed/tiny, house, block."""
    if btype in GARAGE_TYPES:
        return "garage"
    if btype in SHED_TYPES or area < TINY_AREA:
        return "shed"
    if btype in HOUSE_TYPES or (btype == "yes" and area < 250):
        return "house"
    return "block"


SITUATIONS = ["oneFloorBroad", "oneFloor", "twoFloorSquare", "twoFloorNarrow", "twoFloor", "threeFloor",
              "unknown", "small", "large", "semidetached"]


def situation(btype, levels_raw, area, aspect, rectangularity, broad_front, t):
    """BuildingGenerator.situation. `levels_raw` is the parsed building:levels (float) or None;
    `t` is the profile's typeThresholds dict."""
    if btype == "semidetached_house":
        return "semidetached"
    if levels_raw is not None:
        levels = int(swift_round(levels_raw))
        if levels > 0:
            if levels == 1:
                return "oneFloorBroad" if (aspect >= t["broadAspect"] and broad_front) else "oneFloor"
            if levels == 2:
                if aspect <= t["squareAspect"] and rectangularity >= t["squareRectangularity"]:
                    return "twoFloorSquare"
                return "twoFloorNarrow" if aspect >= t["narrowAspect"] else "twoFloor"
            return "threeFloor"
    if area < t["smallArea"]:
        return "small"
    if area > t["largeArea"]:
        return "large"
    return "unknown"


def eligible(ht, levels_int, aspect, rectangularity, broad_front):
    """houseType(for:) eligibility filter for one house type dict."""
    if levels_int is not None and levels_int > 0 and levels_int not in ht["floors"]:
        return False
    if ht.get("minAspect") is not None and aspect < ht["minAspect"]:
        return False
    if ht.get("maxAspect") is not None and aspect > ht["maxAspect"]:
        return False
    if ht.get("minRectangularity") is not None and rectangularity < ht["minRectangularity"]:
        return False
    if ht.get("broadFrontage") is True and not broad_front:
        return False
    return True


def type_probabilities(profile, key, levels_int, aspect, rectangularity, broad_front):
    """Probability of each house type for one house: the situation's weights (or `unknown`'s),
    filtered by eligibility, falling back to the unfiltered list when nothing is eligible
    (BuildingGenerator.houseType). Weights are clamped at 0 as in StableRandom.pick."""
    rules = profile["typeRules"]
    weights = rules.get(key) if isinstance(rules.get(key), dict) else None
    if weights is None:
        weights = rules.get("unknown") if isinstance(rules.get("unknown"), dict) else {}
    types = {ht["id"]: ht for ht in profile["houseTypes"]}
    allc = [(i, max(0.0, float(weights[i]))) for i in sorted(weights) if i in types]
    cands = [(i, w) for i, w in allc if eligible(types[i], levels_int, aspect, rectangularity, broad_front)]
    use = cands if cands else allc
    total = sum(w for _, w in use)
    if total <= 0:
        # StableRandom.pick with all-zero weights returns the last item.
        return {use[-1][0]: 1.0} if use else {}
    return {i: w / total for i, w in use}


# --- roofs -----------------------------------------------------------------------------------
ROOF_MAP = {"gabled": "gabled", "saltbox": "gabled", "gambrel": "gabled", "mansard": "gabled",
            "hipped": "hipped", "pyramidal": "hipped", "half-hipped": "hipped", "side_hipped": "hipped",
            "flat": "flat", "skillion": "slab"}


def map_roof(shape):
    """Generator roof for an OSM roof:shape; None for shapes the generator ignores (then the profile mix decides)."""
    if shape is None:
        return None
    return ROOF_MAP.get(shape)


# --- colours ---------------------------------------------------------------------------------
ENGINE_NAMED = {
    "white": "#E8E3D8", "black": "#3A3D42", "grey": "#9A9A97", "gray": "#9A9A97", "red": "#A4564A",
    "brown": "#7A5E4A", "beige": "#D2C3A6", "yellow": "#DCC87E", "green": "#728F66", "blue": "#7088A3",
    "tan": "#C4A886", "darkgrey": "#5E6064", "darkgray": "#5E6064", "lightgrey": "#C6C5C0", "lightgray": "#C6C5C0",
}


def engine_hex(v):
    """BuildingGenerator.hexColor: the engine's own colour mapping (None = the engine ignores the tag)."""
    s = v.strip().lower()
    if s in ENGINE_NAMED:
        return ENGINE_NAMED[s]
    if s.startswith("#") and len(s) == 7:
        try:
            int(s[1:], 16)
            return s
        except ValueError:
            return None
    return None


# --- roads -----------------------------------------------------------------------------------
LANE_WIDTH = 3.3
DEFAULT_WIDTHS = {"motorway": 14, "trunk": 13, "primary": 12, "secondary": 10, "tertiary": 8, "residential": 8,
                  "unclassified": 6, "living_street": 5, "road": 6, "busway": 6, "service": 4, "track": 3,
                  "pedestrian": 4, "cycleway": 2.5, "footway": 2, "path": 2, "bridleway": 2.5, "steps": 2,
                  "corridor": 2, "other": 3}
VEHICULAR = {"motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential",
             "living_street", "service", "road", "busway", "track"}
# RoadRules (Sources/WorldMap/Rules.swift, P2 main 4b979d4): carriageways include parked cars.
PARKING_KINDS = {"residential", "tertiary", "unclassified", "secondary"}
PARKING_LANE_WIDTH = 2.3
MIN_TRAVEL_WIDTH = 4.5
NO_CARRIAGEWAY_PARKING = {"no", "none", "no_parking", "no_stopping", "no_standing", "fire_lane",
                          "separate", "street_side", "on_kerb", "shoulder"}


def parking_sides(tags):
    """RoadRules.parkingSides: sides (0-2) with parked cars in the carriageway; untagged sides count as parked."""
    def side(s):
        v = (tags.get("parking:%s" % s) or tags.get("parking:both") or tags.get("parking:lane:%s" % s)
             or tags.get("parking:lane:both") or tags.get("parking:lane"))
        return v is None or v not in NO_CARRIAGEWAY_PARKING
    return int(side("left")) + int(side("right"))


def highway_kind(tag):
    base = tag[:-5] if tag.endswith("_link") else tag
    return base if base in DEFAULT_WIDTHS else "other"


def road_width(kind, tags):
    """RoadRules.width: `width` tag (<= 60 m); else lanes x 3.3 m (at least 4.5 m travel width on parking streets)
    plus 2.3 m per parked side; else the class default, narrowed by 2.3 m per side tagged without parking (never
    below 4.5 m). Not ported: RoadRules.clampedToSidewalks (it needs the sidewalk geometry pass), so on streets with
    mapped sidewalks closer than this width the engine draws them narrower than this value."""
    w = parse_length(tags.get("width")) if tags.get("width") else None
    if w is not None and 0 < w <= 60:
        return w, "width"
    sides = parking_sides(tags) if kind in PARKING_KINDS else 0
    if kind in VEHICULAR:
        lanes = parse_int(tags.get("lanes"))
        if lanes is not None and 0 < lanes < 12:
            travel = lanes * LANE_WIDTH
            if kind in PARKING_KINDS:
                travel = max(travel, MIN_TRAVEL_WIDTH)
            return travel + sides * PARKING_LANE_WIDTH, "lanes"
    base = float(DEFAULT_WIDTHS.get(kind, 3))
    if kind not in PARKING_KINDS or sides == 2:
        return base, "default"
    return max(min(base, MIN_TRAVEL_WIDTH), base - (2 - sides) * PARKING_LANE_WIDTH), "default"


def is_street(kind, tags):
    """StreetContext.streets: named vehicle roads except service/track."""
    return kind in VEHICULAR and kind not in ("service", "track") and tags.get("name") is not None


def is_alley_like(kind, tags):
    """StreetContext.alleys: service roads, or unnamed vehicle roads except tracks."""
    return kind in VEHICULAR and (kind == "service" or (tags.get("name") is None and kind != "track"))


def best_edge(ring, index, radius):
    """StreetContext.bestEdge: the footprint edge facing the nearest line of `index`."""
    c = geo.centroid(ring)
    target = index.nearest(c, radius)
    if target is None:
        return None
    tline = target[2]
    best_i, best_score = None, 0.05
    n = len(ring)
    for i in range(n):
        p, q = ring[i], ring[(i + 1) % n]
        d = geo.sub(q, p)
        ln = geo.length(d)
        if ln < 2.5:
            continue
        normal = (d[1] / ln, -d[0] / ln)
        mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
        hit = index.nearest(mid, radius + 20, include=lambda li: li == tline)
        if hit is None:
            continue
        to_road = geo.sub(hit[0], mid)
        dd = geo.length(to_road)
        facing = geo.dot(normal, (to_road[0] / dd, to_road[1] / dd)) if dd > 1e-6 else 0.0
        score = facing * min(ln, 8) / 8 / (1 + dd / 30)
        if score > best_score:
            best_i, best_score = i, score
    return best_i


def broad_front(ring, front_edge, obb):
    """houseType(for:): the front edge runs along the footprint's long axis (|dot| > 0.85)."""
    if front_edge is None:
        return False
    p, q = ring[front_edge], ring[(front_edge + 1) % len(ring)]
    d = geo.sub(q, p)
    ln = geo.length(d)
    dirv = (d[0] / ln, d[1] / ln) if ln > 0 else (1.0, 0.0)
    return abs(geo.dot(dirv, obb.u)) > 0.85
