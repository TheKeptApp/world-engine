"""Planar geometry in local metres, ported from the engine's WorldGeo / WorldGen code.

Ports (same constants and branch order as the Swift source):
- LocalFrame (WGS84 ECEF -> ENU)                      Sources/WorldGeo/LocalFrame.swift
- RingMath.signedArea / centroid / contains / clean    Sources/WorldGeo/Polygon2D.swift
- Polygon2D.cleaned                                    Sources/WorldGeo/Polygon2D.swift
- FootprintAnalysis (convex hull, minimum-area rect,   Sources/WorldGen/FootprintAnalysis.swift
  orthogonality, orthogonal decomposition, class)
- SegmentIndex.nearest                                 Sources/WorldGen/StreetContext.swift
- Clipping of polylines to a rectangle                 (Liang-Barsky, like Sources/WorldGeo/Clipping.swift)
"""
import math

# --- WGS84 local frame -----------------------------------------------------------------------
A = 6378137.0
F = 1.0 / 298.257223563
E2 = F * (2 - F)


def ecef(lat, lon, h=0.0):
    la, lo = math.radians(lat), math.radians(lon)
    n = A / math.sqrt(1 - E2 * math.sin(la) ** 2)
    return ((n + h) * math.cos(la) * math.cos(lo),
            (n + h) * math.cos(la) * math.sin(lo),
            (n * (1 - E2) + h) * math.sin(la))


class LocalFrame:
    """East/north metres around an origin (flat-world projection, exact WGS84 math)."""

    def __init__(self, lat, lon):
        self.lat, self.lon = lat, lon
        self.p0 = ecef(lat, lon)
        la, lo = math.radians(lat), math.radians(lon)
        self.sl, self.cl, self.so, self.co = math.sin(la), math.cos(la), math.sin(lo), math.cos(lo)

    def xy(self, lat, lon):
        p = ecef(lat, lon)
        dx, dy, dz = p[0] - self.p0[0], p[1] - self.p0[1], p[2] - self.p0[2]
        e = -self.so * dx + self.co * dy
        n = -self.sl * self.co * dx - self.sl * self.so * dy + self.cl * dz
        return (e, n)


def box_around(lat, lon, half_m):
    """(S, W, N, E) of a box +-half_m metres around a centre, using the ellipsoid's meridional (M)
    and prime-vertical (N) radii of curvature at the centre latitude."""
    la = math.radians(lat)
    w = math.sqrt(1 - E2 * math.sin(la) ** 2)
    m_rad = A * (1 - E2) / w ** 3
    n_rad = A / w
    dlat = math.degrees(half_m / m_rad)
    dlon = math.degrees(half_m / (n_rad * math.cos(la)))
    return (round(lat - dlat, 6), round(lon - dlon, 6), round(lat + dlat, 6), round(lon + dlon, 6))


def haversine_km(lat1, lon1, lat2, lon2):
    r = 6371.0088
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


# --- vectors ---------------------------------------------------------------------------------
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def mul(a, s):
    return (a[0] * s, a[1] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def length(a):
    return math.hypot(a[0], a[1])


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


# --- RingMath --------------------------------------------------------------------------------
def signed_area(r):
    """Shoelace signed area, positive for counter-clockwise rings (closing point not repeated)."""
    n = len(r)
    if n < 3:
        return 0.0
    s = 0.0
    j = n - 1
    for i in range(n):
        s += (r[j][0] - r[i][0]) * (r[j][1] + r[i][1])
        j = i
    return s / 2


def centroid(r):
    a = signed_area(r)
    if abs(a) <= 1e-9:
        if not r:
            return (0.0, 0.0)
        return (sum(p[0] for p in r) / len(r), sum(p[1] for p in r) / len(r))
    cx = cy = 0.0
    j = len(r) - 1
    for i in range(len(r)):
        c = r[j][0] * r[i][1] - r[i][0] * r[j][1]
        cx += (r[j][0] + r[i][0]) * c
        cy += (r[j][1] + r[i][1]) * c
        j = i
    return (cx / (6 * a), cy / (6 * a))


def ring_contains(r, p):
    """Even-odd point-in-ring test (same edge rule as RingMath.contains)."""
    inside = False
    j = len(r) - 1
    for i in range(len(r)):
        a, b = r[i], r[j]
        if (a[1] > p[1]) != (b[1] > p[1]):
            if p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]:
                inside = not inside
        j = i
    return inside


def clean_ring(ring, merge=0.01, collinear=0.001):
    """RingMath.clean: drop a repeated closing point, merge near-duplicates, remove collinear points."""
    pts = []
    for p in ring:
        if pts and dist(pts[-1], p) < merge:
            continue
        pts.append(p)
    while len(pts) > 1 and dist(pts[0], pts[-1]) < merge:
        pts.pop()
    changed = True
    while changed and len(pts) >= 3:
        changed = False
        i = 0
        while i < len(pts) and len(pts) >= 3:
            a = pts[(i + len(pts) - 1) % len(pts)]
            b = pts[i]
            c = pts[(i + 1) % len(pts)]
            ac = sub(c, a)
            ln = length(ac)
            d = abs(cross(ac, sub(b, a))) / ln if ln > 1e-12 else dist(a, b)
            if d < collinear:
                pts.pop(i)
                changed = True
            else:
                i += 1
    return pts if len(pts) >= 3 else None


class Polygon:
    __slots__ = ("outer", "holes")

    def __init__(self, outer, holes=None):
        self.outer = outer
        self.holes = holes or []

    @property
    def area(self):
        return abs(signed_area(self.outer)) - sum(abs(signed_area(h)) for h in self.holes)

    @property
    def centroid(self):
        return centroid(self.outer)

    def contains(self, p):
        return ring_contains(self.outer, p) and not any(ring_contains(h, p) for h in self.holes)

    def cleaned(self, merge=0.01, min_area=0.5):
        """Polygon2D.cleaned: outer CCW, holes CW, rings under min_area dropped; None if the outer dies."""
        o = clean_ring(self.outer, merge)
        if o is None or abs(signed_area(o)) < min_area:
            return None
        o = o if signed_area(o) > 0 else o[::-1]
        hs = []
        for h in self.holes:
            c = clean_ring(h, merge)
            if c is None or abs(signed_area(c)) < min_area:
                continue
            hs.append(c if signed_area(c) < 0 else c[::-1])
        return Polygon(o, hs)

    def bounds(self):
        xs = [p[0] for p in self.outer]
        ys = [p[1] for p in self.outer]
        return (min(xs), min(ys), max(xs), max(ys))


# --- FootprintAnalysis -----------------------------------------------------------------------
TINY_AREA = 12.0
LARGE_AREA = 400.0


class OrientedRect:
    __slots__ = ("center", "u", "half_length", "half_width")

    def __init__(self, center, u, half_length, half_width):
        if half_width > half_length:
            self.center, self.u = center, (-u[1], u[0])
            self.half_length, self.half_width = half_width, half_length
        else:
            self.center, self.u = center, u
            self.half_length, self.half_width = half_length, half_width

    @property
    def v(self):
        return (-self.u[1], self.u[0])

    @property
    def area(self):
        return 4 * self.half_length * self.half_width

    @property
    def aspect(self):
        """long / short, 1 when degenerate (BuildingGenerator: halfWidth > 0 ? hl / hw : 1)."""
        return self.half_length / self.half_width if self.half_width > 0 else 1.0

    def point(self, s, t):
        return (self.center[0] + self.u[0] * s + self.v[0] * t, self.center[1] + self.u[1] * s + self.v[1] * t)


def convex_hull(pts):
    p = sorted(pts, key=lambda q: (q[0], q[1]))
    if len(p) < 3:
        return p
    lower, upper = [], []
    for q in p:
        while len(lower) >= 2 and cross(sub(lower[-1], lower[-2]), sub(q, lower[-2])) <= 0:
            lower.pop()
        lower.append(q)
    for q in reversed(p):
        while len(upper) >= 2 and cross(sub(upper[-1], upper[-2]), sub(q, upper[-2])) <= 0:
            upper.pop()
        upper.append(q)
    return lower[:-1] + upper[:-1]


def minimum_area_rect(ring):
    """Rotating edges of the convex hull; first strictly smaller area wins (1e-9 tolerance)."""
    hull = convex_hull(ring)
    best, best_area = None, float("inf")
    for i in range(len(hull)):
        d = sub(hull[(i + 1) % len(hull)], hull[i])
        ln = length(d)
        if ln <= 1e-9:
            continue
        u = (d[0] / ln, d[1] / ln)
        v = (-u[1], u[0])
        smin = tmin = float("inf")
        smax = tmax = -float("inf")
        for p in hull:
            s, t = dot(p, u), dot(p, v)
            smin, smax, tmin, tmax = min(smin, s), max(smax, s), min(tmin, t), max(tmax, t)
        a = (smax - smin) * (tmax - tmin)
        if a < best_area - 1e-9:
            best_area = a
            c = add(mul(u, (smin + smax) / 2), mul(v, (tmin + tmax) / 2))
            best = OrientedRect(c, u, (smax - smin) / 2, (tmax - tmin) / 2)
    return best or OrientedRect(ring[0] if ring else (0.0, 0.0), (1.0, 0.0), 0.0, 0.0)


def orthogonality(ring, u):
    tol = math.sin(math.radians(10))
    total = aligned = 0.0
    for i in range(len(ring)):
        d = sub(ring[(i + 1) % len(ring)], ring[i])
        ln = length(d)
        if ln <= 1e-9:
            continue
        dn = (d[0] / ln, d[1] / ln)
        c = abs(cross(u, dn))
        s = abs(dot(u, dn))
        if c < tol or s < tol:
            aligned += ln
        total += ln
    return aligned / total if total > 0 else 0.0


def decompose(ring, frame):
    """FootprintAnalysis.decompose: (roof rect count, flat rect count) or None."""
    local = []
    for p in ring:
        d = sub(p, frame.center)
        local.append((dot(d, frame.u), dot(d, frame.v)))

    def clusters(vals):
        out = []
        for v in sorted(vals):
            if out and v - out[-1] < 0.35:
                continue
            out.append(v)
        return out

    xs, ys = clusters([q[0] for q in local]), clusters([q[1] for q in local])
    if not (len(xs) >= 2 and len(ys) >= 2 and len(xs) <= 24 and len(ys) <= 24):
        return None
    nx, ny = len(xs) - 1, len(ys) - 1
    inside = [[ring_contains(local, ((xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2)) for j in range(ny)] for i in range(nx)]
    roofs = flats = 0
    while True:
        best = None
        for i0 in range(nx):
            for j0 in range(ny):
                if not inside[i0][j0]:
                    continue
                max_j = ny - 1
                for i1 in range(i0, nx):
                    if not inside[i1][j0]:
                        break
                    j1 = j0
                    while j1 + 1 <= max_j and inside[i1][j1 + 1]:
                        j1 += 1
                    max_j = j1
                    a = (xs[i1 + 1] - xs[i0]) * (ys[j1 + 1] - ys[j0])
                    if a > (best[4] if best else 0):
                        best = (i0, i1, j0, j1, a)
        if best is None:
            break
        i0, i1, j0, j1, a = best
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                inside[i][j] = False
        if a >= 6 and roofs < 6:
            roofs += 1
        elif a >= 0.5:
            flats += 1
    return roofs, flats


class Footprint:
    """FootprintAnalysis: obb, rectangularity, orthogonality, kind, roof rect count."""

    __slots__ = ("obb", "rectangularity", "orthogonality", "kind", "roof_rects")

    def __init__(self, poly):
        area = poly.area
        self.obb = minimum_area_rect(poly.outer)
        self.rectangularity = area / self.obb.area if self.obb.area > 0 else 0.0
        self.orthogonality = orthogonality(poly.outer, self.obb.u)
        self.roof_rects = 0
        if area < TINY_AREA:
            self.kind = "tiny"
        elif poly.holes:
            self.kind = "irregular"
        elif self.rectangularity >= 0.9:
            self.kind = "rectangle"
            self.roof_rects = 1
        else:
            dec = decompose(poly.outer, self.obb) if self.orthogonality >= 0.85 else None
            if dec is not None and dec[0] > 0:
                self.kind = "orthogonal"
                self.roof_rects = dec[0]
            elif self.rectangularity >= 0.75 and area <= LARGE_AREA:
                self.kind = "nearRectangle"
                self.roof_rects = 1
            else:
                self.kind = "irregular"

    @property
    def aspect(self):
        return self.obb.aspect


# --- segment search (SegmentIndex) ------------------------------------------------------------
class SegmentIndex:
    """Grid-bucketed segments; `nearest` has the same semantics as the Swift SegmentIndex."""

    def __init__(self, lines, cell=40.0):
        self.cell = cell
        self.buckets = {}
        for li, line in enumerate(lines):
            for a, b in zip(line, line[1:]):
                if a == b:
                    continue
                lo = (min(a[0], b[0]), min(a[1], b[1]))
                hi = (max(a[0], b[0]), max(a[1], b[1]))
                for x in range(self.key(lo[0]), self.key(hi[0]) + 1):
                    for y in range(self.key(lo[1]), self.key(hi[1]) + 1):
                        self.buckets.setdefault((x, y), []).append((li, a, b))

    def key(self, v):
        return int(math.floor(v / self.cell))

    def nearest(self, p, radius, include=None):
        """(point, distance, line, direction) of the nearest segment point within radius, else None."""
        best = None
        r = int(math.ceil(radius / self.cell))
        kx, ky = self.key(p[0]), self.key(p[1])
        for x in range(kx - r, kx + r + 1):
            for y in range(ky - r, ky + r + 1):
                for li, a, b in self.buckets.get((x, y), ()):
                    if include is not None and not include(li):
                        continue
                    d = sub(b, a)
                    l2 = d[0] * d[0] + d[1] * d[1]
                    t = min(1.0, max(0.0, dot(sub(p, a), d) / l2)) if l2 > 0 else 0.0
                    q = (a[0] + d[0] * t, a[1] + d[1] * t)
                    dd = dist(p, q)
                    if dd <= radius and dd < (best[1] if best else float("inf")):
                        ln = math.sqrt(l2)
                        best = (q, dd, li, (d[0] / ln, d[1] / ln))
        return best


# --- distances -------------------------------------------------------------------------------
def point_segment_distance(p, a, b):
    d = sub(b, a)
    l2 = dot(d, d)
    t = min(1.0, max(0.0, dot(sub(p, a), d) / l2)) if l2 > 0 else 0.0
    return dist(p, (a[0] + d[0] * t, a[1] + d[1] * t))


def _segments_intersect(p1, p2, q1, q2):
    d1 = cross(sub(q2, q1), sub(p1, q1))
    d2 = cross(sub(q2, q1), sub(p2, q1))
    d3 = cross(sub(p2, p1), sub(q1, p1))
    d4 = cross(sub(p2, p1), sub(q2, p1))
    return ((d1 > 0) != (d2 > 0)) and ((d3 > 0) != (d4 > 0))


def segment_segment_distance(p1, p2, q1, q2):
    if _segments_intersect(p1, p2, q1, q2):
        return 0.0
    return min(point_segment_distance(p1, q1, q2), point_segment_distance(p2, q1, q2),
               point_segment_distance(q1, p1, p2), point_segment_distance(q2, p1, p2))


def ring_line_distance(ring, line):
    """Minimum distance between a closed ring's boundary and a polyline (0 if they cross or the
    line starts inside the ring)."""
    if line and ring_contains(ring, line[0]):
        return 0.0
    best = float("inf")
    n = len(ring)
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        for q1, q2 in zip(line, line[1:]):
            d = segment_segment_distance(a, b, q1, q2)
            if d < best:
                best = d
                if best == 0.0:
                    return 0.0
    return best


# --- clipping --------------------------------------------------------------------------------
def clip_segment(a, b, rect):
    """Liang-Barsky. rect = (xmin, ymin, xmax, ymax). Returns (a', b') or None."""
    x0, y0, x1, y1 = rect
    dx, dy = b[0] - a[0], b[1] - a[1]
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, a[0] - x0), (dx, x1 - a[0]), (-dy, a[1] - y0), (dy, y1 - a[1])):
        if p == 0:
            if q < 0:
                return None
        else:
            t = q / p
            if p < 0:
                if t > t1:
                    return None
                t0 = max(t0, t)
            else:
                if t < t0:
                    return None
                t1 = min(t1, t)
    return ((a[0] + t0 * dx, a[1] + t0 * dy), (a[0] + t1 * dx, a[1] + t1 * dy))


def clip_polyline(pts, rect):
    """Pieces of a polyline inside rect (consecutive inside segments are joined)."""
    pieces, cur = [], []
    for a, b in zip(pts, pts[1:]):
        c = clip_segment(a, b, rect)
        if c is None:
            if len(cur) >= 2:
                pieces.append(cur)
            cur = []
            continue
        ca, cb = c
        if cur and dist(cur[-1], ca) < 1e-9:
            cur.append(cb)
        else:
            if len(cur) >= 2:
                pieces.append(cur)
            cur = [ca, cb]
        if dist(cb, b) > 1e-9:  # left the rectangle
            pieces.append(cur)
            cur = []
    if len(cur) >= 2:
        pieces.append(cur)
    return pieces


def polyline_length(pts):
    return sum(dist(a, b) for a, b in zip(pts, pts[1:]))


def clip_ring(ring, rect):
    """Sutherland-Hodgman clip of a ring to a rectangle (area-correct for any simple ring)."""
    x0, y0, x1, y1 = rect
    out = list(ring)
    for edge in range(4):
        if not out:
            break
        inp, out = out, []

        def inside(p):
            return (p[0] >= x0, p[0] <= x1, p[1] >= y0, p[1] <= y1)[edge]

        def inter(p, q):
            if edge in (0, 1):
                x = x0 if edge == 0 else x1
                t = (x - p[0]) / (q[0] - p[0])
                return (x, p[1] + t * (q[1] - p[1]))
            y = y0 if edge == 2 else y1
            t = (y - p[1]) / (q[1] - p[1])
            return (p[0] + t * (q[0] - p[0]), y)

        for i in range(len(inp)):
            cur, prev = inp[i], inp[i - 1]
            if inside(cur):
                if not inside(prev):
                    out.append(inter(prev, cur))
                out.append(cur)
            elif inside(prev):
                out.append(inter(prev, cur))
    return out if len(out) >= 3 else []


# --- union area by scanline rasterisation -----------------------------------------------------
class Raster:
    """Binary mask over rect at `res` metres per pixel; polygons are filled with the even-odd rule
    sampled at pixel centres. Used for union areas (overlapping landuse etc.)."""

    def __init__(self, rect, res=1.0):
        self.rect, self.res = rect, res
        self.w = max(1, int(math.ceil((rect[2] - rect[0]) / res)))
        self.h = max(1, int(math.ceil((rect[3] - rect[1]) / res)))
        self.bits = bytearray(self.w * self.h)

    def fill_polygon(self, poly, value=1):
        rings = [poly.outer] + list(poly.holes)
        x0, y0 = self.rect[0], self.rect[1]
        edges = []
        for r in rings:
            n = len(r)
            for i in range(n):
                a, b = r[i], r[(i + 1) % n]
                if a[1] != b[1]:
                    edges.append((a, b))
        if not edges:
            return
        ymin = min(min(a[1], b[1]) for a, b in edges)
        ymax = max(max(a[1], b[1]) for a, b in edges)
        r0 = max(0, int(math.floor((ymin - y0) / self.res)))
        r1 = min(self.h - 1, int(math.ceil((ymax - y0) / self.res)))
        for row in range(r0, r1 + 1):
            y = y0 + (row + 0.5) * self.res
            xs = []
            for a, b in edges:
                if (a[1] > y) != (b[1] > y):
                    xs.append(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            xs.sort()
            base = row * self.w
            for k in range(0, len(xs) - 1, 2):
                c0 = int(math.ceil((xs[k] - x0) / self.res - 0.5))
                c1 = int(math.floor((xs[k + 1] - x0) / self.res - 0.5))
                c0, c1 = max(0, c0), min(self.w - 1, c1)
                if c1 >= c0:
                    self.bits[base + c0: base + c1 + 1] = bytes([value]) * (c1 - c0 + 1)

    def area(self):
        return self.bits.count(1) * self.res * self.res

    def area_and(self, other):
        """Area where both masks are set (same grid required)."""
        n = 0
        for a, b in zip(self.bits, other.bits):
            if a and b:
                n += 1
        return n * self.res * self.res

    def contains_point(self, p):
        c = int((p[0] - self.rect[0]) / self.res)
        r = int((p[1] - self.rect[1]) / self.res)
        if 0 <= c < self.w and 0 <= r < self.h:
            return self.bits[r * self.w + c] == 1
        return False
