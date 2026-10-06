"""Profile validator mirroring StyleProfile.swift decoding plus semantic checks.

Decoding rules mirrored from Sources/WorldGen/StyleProfile.swift (Codable, version 2):
- required keys and JSON types (Double accepts any JSON number; Int/[Int] must be integral;
  Bool must be true/false; optional keys may be absent or null);
- `typeRules` values that are not objects (e.g. a "comment" string) are dropped by the decoder;
  an object value with a non-number weight would ALSO be silently dropped -> reported as an error;
- unknown keys are ignored by the decoder -> reported as info; the documentation keys `comment` and
  `provenance` (top level) are known and also ignored by the decoder.
- optional fields (absent or null decode as nil): `trees.canopyShare` and
  `typeThresholds.smallAreaPercentile` / `largeAreaPercentile` / `hugeAreaPercentile`.
Semantic checks (errors): typeRules type ids exist in houseTypes; colour tuples are 4 x #RRGGBB;
weights >= 0 with a positive sum per roof mix; [lo, hi] ranges have 2 numbers with lo <= hi;
floors are integers >= 1; shares in [0, 1]; months 1-12; unique house type ids; canopyShare and
area percentiles in [0, 1]; present area percentiles strictly ordered small < large < huge.
Warnings: only some of the three area percentiles present; `provenance` not an object of per-field
objects (a `comment` string inside it is fine).
"""
import re

HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")
SITUATION_KEYS = {"oneFloorBroad", "oneFloor", "twoFloorSquare", "twoFloorNarrow", "twoFloor", "threeFloor",
                  "unknown", "small", "large", "semidetached"}

TOP = {"id", "version", "name", "seasons", "trees", "houseTypes", "typeRules", "typeThresholds", "garage", "shed",
       "chimneyLikelihood", "foundationMeters"}
SEASONS = {"hemisphere", "spring", "summer", "autumn", "winter"}
TREES = {"deciduousShare", "crownWeights", "heightMeters", "youngShare", "youngHeightMeters"}
TREES_OPT = {"canopyShare"}
HOUSE_REQ = {"id", "floors", "perFloor", "roof", "pitch", "overhang", "porch", "windows", "door", "colors"}
HOUSE_OPT = {"minAspect", "maxAspect", "minRectangularity", "broadFrontage", "parapet"}
PORCH = {"likelihood", "depth", "frontage", "style"}
WINDOWS_REQ = {"bay", "width", "height"}
WINDOWS_OPT = {"broad"}
THRESH = {"smallArea", "largeArea", "hugeArea", "broadAspect", "squareAspect", "squareRectangularity", "narrowAspect"}
# Optional percentile thresholds, in this order (each must be < the next when present).
THRESH_PCT = ("smallAreaPercentile", "largeAreaPercentile", "hugeAreaPercentile")
TOP_DOC = {"comment", "provenance"}   # documentation keys the decoder ignores
OUT_REQ = {"wallHeight", "pitch", "overhang", "colors"}
OUT_OPT = {"roof", "doubleDoorMinWidthMeters"}
ROOF = {"gabled", "hipped", "flat"}


def _num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def _int(v):
    """Int fields must be integral JSON literals (conservative: `2.0` is rejected)."""
    return isinstance(v, int) and not isinstance(v, bool)


class Report:
    def __init__(self, name):
        self.name, self.errors, self.warnings, self.info = name, [], [], []

    def err(self, path, msg):
        self.errors.append("%s: %s" % (path, msg))

    def warn(self, path, msg):
        self.warnings.append("%s: %s" % (path, msg))

    def note(self, path, msg):
        self.info.append("%s: %s" % (path, msg))

    @property
    def ok(self):
        return not self.errors

    def summary(self):
        return "%s: %s (%d errors, %d warnings)" % (self.name, "OK" if self.ok else "FAIL", len(self.errors), len(self.warnings))


def _keys(r, path, obj, required, optional=()):
    if not isinstance(obj, dict):
        r.err(path, "expected object")
        return False
    for k in sorted(required):
        if k not in obj or obj[k] is None:
            r.err(path, "missing required key %r" % k)
    for k in sorted(set(obj) - set(required) - set(optional)):
        r.note(path, "unknown key %r (ignored by the decoder)" % k)
    return True


def _numlist(r, path, v, rng=False, nonneg=False, allow_empty=False):
    if not isinstance(v, list) or not all(_num(x) for x in v):
        r.err(path, "expected [Double]")
        return
    if not v and not allow_empty:
        r.err(path, "empty list")
    if rng:
        if len(v) != 2:
            r.err(path, "expected a [lo, hi] range of 2 numbers, got %d" % len(v))
        elif v[0] > v[1]:
            r.err(path, "range lo > hi (%s)" % v)
    if nonneg and any(x < 0 for x in v):
        r.err(path, "negative value")


def _share(r, path, v):
    if not _num(v):
        r.err(path, "expected Double")
    elif not 0 <= v <= 1:
        r.err(path, "share outside [0, 1]: %s" % v)


def _roof(r, path, v):
    if not _keys(r, path, v, ROOF):
        return
    vals = []
    for k in ROOF:
        x = v.get(k)
        if x is None:
            continue
        if not _num(x):
            r.err(path + "." + k, "expected Double")
        elif x < 0:
            r.err(path + "." + k, "negative weight")
        else:
            vals.append(x)
    if vals and sum(vals) <= 0:
        r.err(path, "roof weights sum to 0")


def _colors(r, path, v):
    if not isinstance(v, list) or not v:
        r.err(path, "expected non-empty [[String]]")
        return
    for i, t in enumerate(v):
        if not isinstance(t, list) or len(t) != 4:
            r.err("%s[%d]" % (path, i), "colour tuple must have 4 entries [wall, trim, door, roof]")
            continue
        for j, c in enumerate(t):
            if not isinstance(c, str) or not HEX.match(c):
                r.err("%s[%d][%d]" % (path, i, j), "not #RRGGBB: %r" % (c,))


def _outbuilding(r, path, v):
    if not _keys(r, path, v, OUT_REQ, OUT_OPT):
        return
    _numlist(r, path + ".wallHeight", v.get("wallHeight"), rng=True, nonneg=True)
    if v.get("roof") is not None:
        _roof(r, path + ".roof", v["roof"])
    _numlist(r, path + ".pitch", v.get("pitch"), rng=True, nonneg=True)
    _numlist(r, path + ".overhang", v.get("overhang"), rng=True, nonneg=True)
    if v.get("doubleDoorMinWidthMeters") is not None and not _num(v["doubleDoorMinWidthMeters"]):
        r.err(path + ".doubleDoorMinWidthMeters", "expected Double")
    _colors(r, path + ".colors", v.get("colors"))


def _percentiles(r, th):
    """Optional relative thresholds: quantiles (0-1) of the area's house footprints; when present they
    replace the absolute m2 values in areas with >= 30 house candidates (generator rule, StyleProfile.swift)."""
    present = []
    for k in THRESH_PCT:
        v = th.get(k)
        if v is None:
            continue
        if not _num(v):
            r.err("$.typeThresholds." + k, "expected Double")
        elif not 0 <= v <= 1:
            r.err("$.typeThresholds." + k, "percentile outside [0, 1]: %s" % v)
        else:
            present.append((k, v))
    for (k1, v1), (k2, v2) in zip(present, present[1:]):
        if not v1 < v2:
            r.err("$.typeThresholds", "expected %s < %s (%s, %s)" % (k1, k2, v1, v2))
    if present and len(present) < len(THRESH_PCT):
        r.warn("$.typeThresholds", "only %s of the area percentiles present (the others use absolute m2)" %
               ", ".join(k for k, _ in present))


def validate(p, name="profile"):
    r = Report(name)
    if not _keys(r, "$", p, TOP, TOP_DOC):
        return r
    pv = p.get("provenance")
    if pv is not None and (not isinstance(pv, dict) or
                           not all(isinstance(x, dict) or (k == "comment" and isinstance(x, str)) for k, x in pv.items())):
        r.warn("$.provenance", "expected an object of per-field objects, plus an optional comment (ignored by the decoder)")
    if not isinstance(p.get("id"), str):
        r.err("$.id", "expected String")
    if not _int(p.get("version")):
        r.err("$.version", "expected Int")
    elif p["version"] != 2:
        r.warn("$.version", "schema version %s (expected 2)" % p["version"])
    if not isinstance(p.get("name"), str):
        r.err("$.name", "expected String")

    s = p.get("seasons")
    if _keys(r, "$.seasons", s, SEASONS):
        if s.get("hemisphere") not in ("north", "south"):
            r.err("$.seasons.hemisphere", "expected 'north' or 'south'")
        months = []
        for k in ("spring", "summer", "autumn", "winter"):
            v = s.get(k)
            if not isinstance(v, list) or not all(_int(m) for m in v):
                r.err("$.seasons." + k, "expected [Int]")
                continue
            for m in v:
                if not 1 <= m <= 12:
                    r.err("$.seasons." + k, "month outside 1-12: %s" % m)
            months += v
        if sorted(months) != list(range(1, 13)):
            r.warn("$.seasons", "months do not cover 1-12 exactly once (season(month:) falls back to summer)")

    t = p.get("trees")
    if _keys(r, "$.trees", t, TREES, TREES_OPT):
        _share(r, "$.trees.deciduousShare", t.get("deciduousShare"))
        if t.get("canopyShare") is not None:
            _share(r, "$.trees.canopyShare", t["canopyShare"])
        cw = t.get("crownWeights")
        if not isinstance(cw, dict) or not all(_num(x) for x in cw.values()):
            r.err("$.trees.crownWeights", "expected [String: Double]")
        else:
            if any(x < 0 for x in cw.values()):
                r.err("$.trees.crownWeights", "negative weight")
            if sum(cw.values()) <= 0:
                r.err("$.trees.crownWeights", "weights sum to 0")
            for k in cw:
                if k not in ("broad", "oval", "spreading"):
                    r.warn("$.trees.crownWeights", "key %r is not a crown archetype (rendered as broad)" % k)
        _numlist(r, "$.trees.heightMeters", t.get("heightMeters"), rng=True, nonneg=True)
        _share(r, "$.trees.youngShare", t.get("youngShare"))
        _numlist(r, "$.trees.youngHeightMeters", t.get("youngHeightMeters"), rng=True, nonneg=True)

    ids = []
    hts = p.get("houseTypes")
    if not isinstance(hts, list) or not hts:
        r.err("$.houseTypes", "expected non-empty [HouseType]")
        hts = []
    for i, h in enumerate(hts):
        path = "$.houseTypes[%d]" % i
        if not _keys(r, path, h, HOUSE_REQ, HOUSE_OPT):
            continue
        if not isinstance(h.get("id"), str):
            r.err(path + ".id", "expected String")
        else:
            ids.append(h["id"])
            path = "$.houseTypes[%s]" % h["id"]
        fl = h.get("floors")
        if not isinstance(fl, list) or not fl or not all(_int(x) for x in fl):
            r.err(path + ".floors", "expected non-empty [Int]")
        elif any(x < 1 for x in fl):
            r.err(path + ".floors", "floors must be >= 1")
        _numlist(r, path + ".perFloor", h.get("perFloor"), rng=True, nonneg=True)
        for k in ("minAspect", "maxAspect", "minRectangularity"):
            if h.get(k) is not None and not _num(h[k]):
                r.err(path + "." + k, "expected Double")
        if h.get("broadFrontage") is not None and not isinstance(h["broadFrontage"], bool):
            r.err(path + ".broadFrontage", "expected Bool")
        _roof(r, path + ".roof", h.get("roof"))
        _numlist(r, path + ".pitch", h.get("pitch"), rng=True, nonneg=True)
        _numlist(r, path + ".overhang", h.get("overhang"), rng=True, nonneg=True)
        if h.get("parapet") is not None:
            _numlist(r, path + ".parapet", h["parapet"], rng=True, nonneg=True)
        po = h.get("porch")
        if _keys(r, path + ".porch", po, PORCH):
            _share(r, path + ".porch.likelihood", po.get("likelihood"))
            _numlist(r, path + ".porch.depth", po.get("depth"), rng=True, nonneg=True)
            _numlist(r, path + ".porch.frontage", po.get("frontage"), rng=True, nonneg=True)
            if po.get("style") not in ("covered", "stoop", "entry", "canopy"):
                r.warn(path + ".porch.style", "unknown style %r (treated as a non-covered entry)" % po.get("style"))
        w = h.get("windows")
        if _keys(r, path + ".windows", w, WINDOWS_REQ, WINDOWS_OPT):
            for k in ("bay", "width", "height"):
                _numlist(r, path + ".windows." + k, w.get(k), rng=True, nonneg=True)
            if w.get("broad") is not None:
                _numlist(r, path + ".windows.broad", w["broad"], rng=True, nonneg=True)
        _numlist(r, path + ".door", h.get("door"))
        if isinstance(h.get("door"), list) and any(_num(x) and not 0 <= x <= 1 for x in h["door"]):
            r.err(path + ".door", "door positions are shares of the facade (0-1)")
        _colors(r, path + ".colors", h.get("colors"))
    if len(ids) != len(set(ids)):
        r.err("$.houseTypes", "duplicate house type ids")

    tr = p.get("typeRules")
    if not isinstance(tr, dict):
        r.err("$.typeRules", "expected object")
    else:
        for k, v in tr.items():
            if not isinstance(v, dict):
                if k != "comment":
                    r.note("$.typeRules." + k, "non-object value dropped by the decoder")
                continue
            if not all(_num(x) for x in v.values()):
                r.err("$.typeRules." + k, "non-number weight: the decoder would silently drop this rule")
                continue
            if k not in SITUATION_KEYS:
                r.warn("$.typeRules." + k, "not a situation key the generator uses")
            for tid, wv in v.items():
                if tid not in ids:
                    r.err("$.typeRules.%s.%s" % (k, tid), "house type id not in houseTypes")
                if wv < 0:
                    r.err("$.typeRules.%s.%s" % (k, tid), "negative weight")
            if v and sum(v.values()) <= 0:
                r.err("$.typeRules." + k, "weights sum to 0")
        if not isinstance(tr.get("unknown"), dict):
            r.warn("$.typeRules", "no `unknown` rule (fallback for missing situation keys)")

    th = p.get("typeThresholds")
    if _keys(r, "$.typeThresholds", th, THRESH, THRESH_PCT):
        for k in THRESH:
            if th.get(k) is not None and not _num(th[k]):
                r.err("$.typeThresholds." + k, "expected Double")
        if all(_num(th.get(k)) for k in ("smallArea", "largeArea", "hugeArea")):
            if not th["smallArea"] <= th["largeArea"] <= th["hugeArea"]:
                r.err("$.typeThresholds", "expected smallArea <= largeArea <= hugeArea")
        _percentiles(r, th)

    for k in ("garage", "shed"):
        _outbuilding(r, "$." + k, p.get(k))
    _share(r, "$.chimneyLikelihood", p.get("chimneyLikelihood"))
    _numlist(r, "$.foundationMeters", p.get("foundationMeters"), rng=True, nonneg=True)
    return r
