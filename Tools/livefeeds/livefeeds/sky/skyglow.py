"""Night-sky brightness and naked-eye limiting magnitude.

Three sources of zenith sky light are added as linear flux:
  1. artificial skyglow inferred from NASA Black Marble (VIIRS DNB) upward radiance around the observer;
  2. twilight, from the Sun's altitude (a coarse table, assumption);
  3. moonlight, Krisciunas & Schaefer (1991, PASP 103, 1033) at the zenith.
The natural moonless dark-site zenith brightness is taken as 22.0 V mag/arcsec^2.

The radiance-to-skyglow step is the weakest link: it is a distance-weighted average of radiance
(Walker's-law-like (d + 1 km)^-2.5 kernel out to 50 km) times one calibration constant, with no
atmosphere or terrain model. Every number it produces is labelled "inferred" and carries
`confidence: "low"` until it is calibrated against sky-quality-meter readings (docs/live-world/sky.md).
"""

import json
import math
from dataclasses import dataclass
from typing import Iterable, List, Optional, Tuple

NATURAL_SKY_MAG = 22.0
KERNEL_RADIUS_KM = 50.0
KERNEL_CORE_KM = 1.0
# Ratio of artificial to natural zenith brightness per nW/cm^2/sr of kernel-weighted radiance (assumption).
CALIBRATION = 1.0
# Zenith sky brightness against solar altitude (deg, V mag/arcsec^2), coarse literature-level shape (assumption).
TWILIGHT_TABLE = ((5.0, 3.5), (0.0, 5.5), (-6.0, 12.5), (-12.0, 18.0), (-18.0, NATURAL_SKY_MAG))
EXTINCTION_K = 0.172  # V-band extinction coefficient used by Krisciunas & Schaefer


def mag_to_flux(m: float) -> float:
    return 10 ** (-0.4 * m)


def flux_to_mag(f: float) -> float:
    return -2.5 * math.log10(f)


def limiting_magnitude(sky_mag: float) -> float:
    """Naked-eye limiting magnitude at the zenith from sky brightness (V mag/arcsec^2). Conversion used by
    the Unihedron SQM documentation and Clear Sky Chart: NELM = 7.93 - 5 log10(10^(4.316 - B/5) + 1)."""
    return 7.93 - 5 * math.log10(10 ** (4.316 - sky_mag / 5) + 1)


# -- artificial skyglow -------------------------------------------------------------------------

@dataclass
class RadianceGrid:
    """Regular lat/lon grid of upward radiance, nW/cm^2/sr (row 0 is the northernmost row)."""
    north: float
    west: float
    dlat: float
    dlon: float
    rows: int
    cols: int
    values: List[float]
    product: str
    year: int
    source: dict

    @classmethod
    def load(cls, path: str) -> "RadianceGrid":
        with open(path, "r", encoding="utf-8") as fh:
            d = json.load(fh)
        if d.get("schema") != "worldengine.radiance/1":
            raise ValueError("unsupported radiance schema")
        g = d["grid"]
        vals = d["values"]
        if len(vals) != g["rows"] * g["cols"]:
            raise ValueError("radiance grid size mismatch")
        return cls(g["north"], g["west"], g["dlat"], g["dlon"], g["rows"], g["cols"], vals,
                   d["product"], int(d["year"]), d.get("source", {}))

    def contains(self, lat: float, lon: float) -> bool:
        return (self.north - self.rows * self.dlat <= lat <= self.north
                and self.west <= lon <= self.west + self.cols * self.dlon)

    def cells(self) -> Iterable[Tuple[float, float, float]]:
        for r in range(self.rows):
            lat = self.north - (r + 0.5) * self.dlat
            for c in range(self.cols):
                v = self.values[r * self.cols + c]
                if v is not None and v > 0:
                    yield lat, self.west + (c + 0.5) * self.dlon, v


def _kernel(d_km: float) -> float:
    return (d_km + KERNEL_CORE_KM) ** -2.5


def _uniform_kernel_integral() -> float:
    # Integral of 2 pi r (r + core)^-2.5 dr from 0 to R, closed form.
    c, r = KERNEL_CORE_KM, KERNEL_RADIUS_KM

    def prim(x):  # antiderivative of x (x + c)^-2.5
        return -2 * (x + c) ** -0.5 + (2.0 / 3.0) * c * (x + c) ** -1.5
    return 2 * math.pi * (prim(r) - prim(0))


def weighted_radiance(grid: RadianceGrid, lat: float, lon: float) -> Optional[float]:
    """Kernel-weighted mean radiance around the point; None when the point or most of the kernel is
    outside the grid (fewer than 70 percent of the kernel weight covered)."""
    if not grid.contains(lat, lon):
        return None
    kx = 111.32 * math.cos(math.radians(lat))
    ky = 110.57
    cell_area = (grid.dlat * ky) * (grid.dlon * kx)
    total = covered = 0.0
    r0 = int(max(0, math.floor((grid.north - lat - KERNEL_RADIUS_KM / ky) / grid.dlat)))
    r1 = int(min(grid.rows, math.ceil((grid.north - lat + KERNEL_RADIUS_KM / ky) / grid.dlat)))
    c0 = int(max(0, math.floor((lon - grid.west - KERNEL_RADIUS_KM / kx) / grid.dlon)))
    c1 = int(min(grid.cols, math.ceil((lon - grid.west + KERNEL_RADIUS_KM / kx) / grid.dlon)))
    for r in range(r0, r1):
        clat = grid.north - (r + 0.5) * grid.dlat
        for c in range(c0, c1):
            clon = grid.west + (c + 0.5) * grid.dlon
            d = math.hypot((clat - lat) * ky, (clon - lon) * kx)
            if d > KERNEL_RADIUS_KM:
                continue
            w = _kernel(d) * cell_area
            covered += w
            v = grid.values[r * grid.cols + c]
            total += w * (v if v is not None and v > 0 else 0.0)
    full = _uniform_kernel_integral()
    if covered < 0.7 * full:
        return None
    return total / covered


def artificial_ratio(weighted_radiance_nw: float) -> float:
    return CALIBRATION * max(0.0, weighted_radiance_nw)


# -- twilight and moonlight -----------------------------------------------------------------------

def twilight_flux(sun_alt_deg: float) -> float:
    """Extra zenith flux above the natural dark sky, in mag_to_flux units."""
    t = TWILIGHT_TABLE
    if sun_alt_deg >= t[0][0]:
        m = t[0][1]
    elif sun_alt_deg <= t[-1][0]:
        return 0.0
    else:
        for (a0, m0), (a1, m1) in zip(t, t[1:]):
            if a1 <= sun_alt_deg <= a0:
                m = m1 + (m0 - m1) * (sun_alt_deg - a1) / (a0 - a1)
                break
    return max(0.0, mag_to_flux(m) - mag_to_flux(NATURAL_SKY_MAG))


def moonlight_flux(moon_alt_deg: float, moon_phase_angle_deg: float) -> float:
    """Zenith moonlight (Krisciunas & Schaefer 1991, eq. 15-21) in mag_to_flux units; 0 when the Moon is down."""
    if moon_alt_deg <= 0:
        return 0.0
    alpha = abs(moon_phase_angle_deg)
    i_star = 10 ** (-0.4 * (3.84 + 0.026 * alpha + 4e-9 * alpha ** 4))
    rho = 90.0 - moon_alt_deg  # separation between the zenith and the Moon
    f_rho = 10 ** 5.36 * (1.06 + math.cos(math.radians(rho)) ** 2) + 10 ** (6.15 - rho / 40.0)
    x_moon = (1 - 0.96 * math.sin(math.radians(rho)) ** 2) ** -0.5
    x_zen = 1.0
    b_nl = f_rho * i_star * 10 ** (-0.4 * EXTINCTION_K * x_moon) * (1 - 10 ** (-0.4 * EXTINCTION_K * x_zen))
    if b_nl <= 0:
        return 0.0
    mag = (20.7233 - math.log(b_nl / 34.08)) / 0.92104
    return mag_to_flux(mag)


def sky_brightness(artificial: Optional[float], sun_alt: float, moon_alt: float, moon_phase: float) -> dict:
    """Zenith sky brightness (V mag/arcsec^2) and limiting magnitudes. `artificial` is the
    artificial-to-natural ratio, or None when unknown (then the dark-site value is used and flagged)."""
    nat = mag_to_flux(NATURAL_SKY_MAG)
    art = (artificial or 0.0) * nat
    dark = flux_to_mag(nat + art)
    now = flux_to_mag(nat + art + twilight_flux(sun_alt) + moonlight_flux(moon_alt, moon_phase))
    return {
        "zenithSkyMagDark": dark,
        "zenithSkyMagNow": now,
        "limitingMagnitudeDark": limiting_magnitude(dark),
        "limitingMagnitudeNow": limiting_magnitude(now),
    }


# -- baking a grid from a Black Marble export ---------------------------------------------------

def grid_from_xyz(lines: Iterable[str], product: str, year: int, source: dict, fill_above: float = 6e4) -> dict:
    """Builds a `worldengine.radiance/1` document from GDAL XYZ text ("lon lat value" per cell centre,
    as written by `gdal_translate -of XYZ` from a Black Marble VNP46A4 annual radiance layer).
    Values at or above `fill_above` (the product's fill value 65535 after scaling) become null."""
    pts = {}
    for line in lines:
        parts = line.split()
        if len(parts) < 3:
            continue
        lon, lat, v = float(parts[0]), float(parts[1]), float(parts[2])
        pts[(round(lat, 9), round(lon, 9))] = None if (v != v or v >= fill_above or v < 0) else round(v, 2)
    lats = sorted({k[0] for k in pts}, reverse=True)
    lons = sorted({k[1] for k in pts})
    if len(lats) < 2 or len(lons) < 2:
        raise ValueError("need at least a 2 x 2 grid")
    dlat, dlon = lats[0] - lats[1], lons[1] - lons[0]
    for seq, step in ((lats, -dlat), (lons, dlon)):
        if any(abs((b - a) - step) > 1e-6 for a, b in zip(seq, seq[1:])):
            raise ValueError("XYZ input is not a regular grid")
    values = [pts.get((la, lo)) for la in lats for lo in lons]
    return {"schema": "worldengine.radiance/1", "product": product, "year": year, "source": source,
            "unit": "nW/cm^2/sr",
            "grid": {"north": round(lats[0] + dlat / 2, 9), "west": round(lons[0] - dlon / 2, 9),
                     "dlat": round(dlat, 9), "dlon": round(dlon, 9), "rows": len(lats), "cols": len(lons)},
            "values": values}
