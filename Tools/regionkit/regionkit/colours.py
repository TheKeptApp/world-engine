"""Colour maths (sRGB D65 <-> CIELAB), CIEDE2000, and OSM colour-value normalisation."""
import math

from . import paths, rules

_NAMES = None
_FAMILIES = None


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#%02X%02X%02X" % tuple(max(0, min(255, int(round(c * 255)))) for c in rgb)


def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _gam(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


XN, YN, ZN = 0.95047, 1.0, 1.08883


def hex_to_lab(h):
    r, g, b = (_lin(c) for c in hex_to_rgb(h))
    x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b

    def f(t):
        return t ** (1 / 3) if t > (6 / 29) ** 3 else t / (3 * (6 / 29) ** 2) + 4 / 29

    fx, fy, fz = f(x / XN), f(y / YN), f(z / ZN)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def lab_to_hex(lab):
    L, a, b = lab
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200

    def finv(t):
        return t ** 3 if t > 6 / 29 else 3 * (6 / 29) ** 2 * (t - 4 / 29)

    x, y, z = XN * finv(fx), YN * finv(fy), ZN * finv(fz)
    r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
    bb = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    return rgb_to_hex(tuple(_gam(max(0.0, min(1.0, c))) for c in (r, g, bb)))


def lab_to_lch(lab):
    L, a, b = lab
    return (L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360)


def lch_to_lab(lch):
    L, C, h = lch
    return (L, C * math.cos(math.radians(h)), C * math.sin(math.radians(h)))


def delta_e76(h1, h2):
    a, b = hex_to_lab(h1), hex_to_lab(h2)
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def delta_e2000(h1, h2):
    """CIEDE2000 (Sharma, Wu & Dalal 2005 formulation), kL = kC = kH = 1."""
    L1, a1, b1 = hex_to_lab(h1)
    L2, a2, b2 = hex_to_lab(h2)
    C1, C2 = math.hypot(a1, b1), math.hypot(a2, b2)
    Cb = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(Cb ** 7 / (Cb ** 7 + 25 ** 7)))
    a1p, a2p = (1 + G) * a1, (1 + G) * a2
    C1p, C2p = math.hypot(a1p, b1), math.hypot(a2p, b2)
    h1p = math.degrees(math.atan2(b1, a1p)) % 360 if C1p else 0.0
    h2p = math.degrees(math.atan2(b2, a2p)) % 360 if C2p else 0.0
    dLp, dCp = L2 - L1, C2p - C1p
    if C1p * C2p == 0:
        dhp = 0.0
    else:
        dhp = h2p - h1p
        if dhp > 180:
            dhp -= 360
        elif dhp < -180:
            dhp += 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp / 2))
    Lbp, Cbp = (L1 + L2) / 2, (C1p + C2p) / 2
    if C1p * C2p == 0:
        hbp = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hbp = (h1p + h2p) / 2
    elif h1p + h2p < 360:
        hbp = (h1p + h2p + 360) / 2
    else:
        hbp = (h1p + h2p - 360) / 2
    T = (1 - 0.17 * math.cos(math.radians(hbp - 30)) + 0.24 * math.cos(math.radians(2 * hbp))
         + 0.32 * math.cos(math.radians(3 * hbp + 6)) - 0.20 * math.cos(math.radians(4 * hbp - 63)))
    dtheta = 30 * math.exp(-(((hbp - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cbp ** 7 / (Cbp ** 7 + 25 ** 7))
    Sl = 1 + 0.015 * (Lbp - 50) ** 2 / math.sqrt(20 + (Lbp - 50) ** 2)
    Sc = 1 + 0.045 * Cbp
    Sh = 1 + 0.015 * Cbp * T
    Rt = -math.sin(math.radians(2 * dtheta)) * Rc
    return math.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))


# --- OSM colour values -----------------------------------------------------------------------
def _tables():
    global _NAMES, _FAMILIES
    if _NAMES is None:
        t = paths.data_table("colours.json")
        _NAMES = {k.lower(): v for k, v in t["names"].items()}
        _FAMILIES = t["families"]
    return _NAMES, _FAMILIES


def normalize(value):
    """OSM colour value -> (#RRGGBB, how) or (None, reason). The engine's own mapping
    (BuildingGenerator.hexColor) is tried first; then the kit's extended name table; then #RGB."""
    if value is None:
        return None, "missing"
    v = value.strip()
    e = rules.engine_hex(v)
    if e is not None:
        return e.upper(), "engine"
    names, _ = _tables()
    s = v.lower().replace("_", " ").replace("-", " ").strip()
    s2 = s.replace(" ", "")
    if s in names:
        return names[s], "name"
    if s2 in names:
        return names[s2], "name"
    if s.startswith("#") and len(s) == 4:
        try:
            int(s[1:], 16)
            return ("#" + "".join(c * 2 for c in s[1:])).upper(), "short-hex"
        except ValueError:
            pass
    if len(s) == 6:
        try:
            int(s, 16)
            return ("#" + s).upper(), "hex-no-hash"
        except ValueError:
            pass
    return None, "unparsed"


def family(hexv):
    """Nearest colour family anchor by CIEDE2000."""
    _, fams = _tables()
    best = min(fams.items(), key=lambda kv: (delta_e2000(hexv, kv[1]), kv[0]))
    return best[0]


def family_anchor(name):
    _, fams = _tables()
    return fams.get(name)
