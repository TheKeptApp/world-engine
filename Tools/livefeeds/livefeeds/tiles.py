"""Area model: zoom-14 Web-Mercator (slippy map) tiles, as recommended in docs/research/live-feeds.md 4.3.

A request names a rectangle of tiles (or a WGS84 bbox that is snapped outward to one). The
rectangle is canonical, so identical views share one cache key. The relay caps it at 4 x 4 tiles.
"""

import math
from dataclasses import dataclass
from typing import Iterator, List, Tuple

ZOOM = 14
MAX_SIDE = 4            # tiles per side (live-feeds.md 4.12)
MAX_LAT = 85.0511287798066


class AreaError(ValueError):
    """A bbox or tile rectangle that the relay refuses."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def _fx(lon: float, z: int) -> float:
    return (lon + 180.0) / 360.0 * (1 << z)


def _fy(lat: float, z: int) -> float:
    lat = max(-MAX_LAT, min(MAX_LAT, lat))
    return (1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0 * (1 << z)


def tile_xy(lat: float, lon: float, z: int = ZOOM) -> Tuple[int, int]:
    n = 1 << z
    x = min(n - 1, max(0, int(math.floor(_fx(lon, z)))))
    y = min(n - 1, max(0, int(math.floor(_fy(lat, z)))))
    return x, y


def tile_bounds(x: int, y: int, z: int = ZOOM) -> Tuple[float, float, float, float]:
    """(south, west, north, east) of a tile, WGS84 degrees."""
    n = float(1 << z)

    def lat(ty: float) -> float:
        return math.degrees(math.atan(math.sinh(math.pi * (1.0 - 2.0 * ty / n))))

    return lat(y + 1), x / n * 360.0 - 180.0, lat(y), (x + 1) / n * 360.0 - 180.0


@dataclass(frozen=True)
class Rect:
    """Inclusive rectangle of tiles at one zoom. y grows southward (slippy-map convention)."""
    z: int
    x0: int
    y0: int
    x1: int
    y1: int

    @property
    def columns(self) -> int:
        return self.x1 - self.x0 + 1

    @property
    def rows(self) -> int:
        return self.y1 - self.y0 + 1

    def tiles(self) -> Iterator[Tuple[int, int]]:
        for x in range(self.x0, self.x1 + 1):
            for y in range(self.y0, self.y1 + 1):
                yield x, y

    def bbox(self) -> Tuple[float, float, float, float]:
        """(south, west, north, east) covering the whole rectangle."""
        s, _, _, _ = tile_bounds(self.x0, self.y1, self.z)
        _, w, n, _ = tile_bounds(self.x0, self.y0, self.z)
        _, _, _, e = tile_bounds(self.x1, self.y0, self.z)
        return s, w, n, e

    def key(self) -> str:
        return "%d/%d/%d/%d/%d" % (self.z, self.x0, self.y0, self.x1, self.y1)


def _check_size(r: Rect) -> Rect:
    if r.columns > MAX_SIDE or r.rows > MAX_SIDE:
        raise AreaError("area-too-large", "at most %d x %d tiles at zoom %d (got %d x %d)"
                        % (MAX_SIDE, MAX_SIDE, ZOOM, r.columns, r.rows))
    return r


def rect_from_bbox(south: float, west: float, north: float, east: float) -> Rect:
    """Snap a WGS84 bbox outward to the zoom-14 tile grid."""
    for v in (south, west, north, east):
        if not math.isfinite(v):
            raise AreaError("bad-bbox", "bbox values must be finite numbers")
    if not (-90.0 <= south < north <= 90.0):
        raise AreaError("bad-bbox", "need -90 <= south < north <= 90")
    if not (-180.0 <= west <= 180.0 and -180.0 <= east <= 180.0):
        raise AreaError("bad-bbox", "longitudes must be within -180..180")
    if west >= east:
        raise AreaError("bad-bbox", "need west < east (boxes across the antimeridian are not supported)")
    z = ZOOM
    n = 1 << z
    eps = 1e-9
    x0 = min(n - 1, max(0, int(math.floor(_fx(west, z)))))
    x1 = min(n - 1, max(x0, int(math.floor(_fx(east, z) - eps))))
    y0 = min(n - 1, max(0, int(math.floor(_fy(north, z)))))
    y1 = min(n - 1, max(y0, int(math.floor(_fy(south, z) - eps))))
    return _check_size(Rect(z, x0, y0, x1, y1))


def parse_bbox(text: str) -> Rect:
    parts = text.split(",")
    if len(parts) != 4:
        raise AreaError("bad-bbox", "bbox must be S,W,N,E")
    try:
        s, w, n, e = (float(p) for p in parts)
    except ValueError:
        raise AreaError("bad-bbox", "bbox values must be numbers")
    return rect_from_bbox(s, w, n, e)


def parse_tiles(text: str) -> Rect:
    """Canonical form: z/x0/y0/x1/y1 (zoom must be 14)."""
    parts = text.split("/")
    if len(parts) != 5:
        raise AreaError("bad-tiles", "tiles must be z/x0/y0/x1/y1")
    try:
        z, x0, y0, x1, y1 = (int(p) for p in parts)
    except ValueError:
        raise AreaError("bad-tiles", "tile numbers must be integers")
    if z != ZOOM:
        raise AreaError("bad-tiles", "only zoom %d is supported" % ZOOM)
    n = 1 << z
    if not (0 <= x0 <= x1 < n and 0 <= y0 <= y1 < n):
        raise AreaError("bad-tiles", "need 0 <= x0 <= x1 < %d and 0 <= y0 <= y1 < %d" % (n, n))
    return _check_size(Rect(z, x0, y0, x1, y1))


def bbox_intersects(a: List[float], b: Tuple[float, float, float, float]) -> bool:
    """Both are (south, west, north, east)."""
    return not (a[2] < b[0] or a[0] > b[2] or a[3] < b[1] or a[1] > b[3])
