"""Parsing orbital element sets: two-line elements (TLE) and CelesTrak OMM JSON (FORMAT=json).

Only the fields SGP4 needs are read. Raw element lines never leave the relay (docs/live-world/satellites.md).
"""

import calendar
import datetime
from typing import Iterable, List

from .sgp4 import Elements


class ElementError(ValueError):
    pass


def _checksum_ok(line: str) -> bool:
    s = 0
    for ch in line[:68]:
        if ch.isdigit():
            s += int(ch)
        elif ch == "-":
            s += 1
    return line[68].isdigit() and s % 10 == int(line[68])


def _implied_decimal(field: str) -> float:
    """TLE "assumed decimal point" exponent field, e.g. '-11606-4' -> -0.11606e-4."""
    f = field.strip()
    if not f or f.replace("0", "").replace("+", "").replace("-", "") == "":
        return 0.0
    sign = -1.0 if f[0] == "-" else 1.0
    f = f.lstrip("+-")
    mant, exp = f[:-2], f[-2:]
    return sign * float("0." + mant) * 10 ** int(exp)


def tle_epoch_posix(year2: int, day: float) -> float:
    year = 1900 + year2 if year2 >= 57 else 2000 + year2
    return calendar.timegm((year, 1, 1, 0, 0, 0)) + (day - 1.0) * 86400.0


def parse_tle(name: str, line1: str, line2: str, verify_checksum: bool = True) -> Elements:
    line1, line2 = line1.rstrip(), line2.rstrip()
    if len(line1) < 69 or len(line2) < 69 or line1[0] != "1" or line2[0] != "2":
        raise ElementError("not a two-line element set")
    if verify_checksum and not (_checksum_ok(line1) and _checksum_ok(line2)):
        raise ElementError("TLE checksum mismatch")
    try:
        norad = int(line1[2:7])
        if int(line2[2:7]) != norad:
            raise ElementError("line numbers disagree")
        return Elements(
            norad_id=norad, name=name.strip() or str(norad),
            epoch=tle_epoch_posix(int(line1[18:20]), float(line1[20:32])),
            inclination=float(line2[8:16]), raan=float(line2[17:25]),
            eccentricity=float("0." + line2[26:33].strip()), arg_perigee=float(line2[34:42]),
            mean_anomaly=float(line2[43:51]), mean_motion=float(line2[52:63]),
            bstar=_implied_decimal(line1[53:61]))
    except ValueError as exc:
        if isinstance(exc, ElementError):
            raise
        raise ElementError("malformed TLE field: %s" % exc)


def parse_tle_text(text: str) -> List[Elements]:
    """Three-line (name + two lines) or bare two-line sets, as CelesTrak FORMAT=tle returns them."""
    lines = [l.rstrip() for l in text.splitlines() if l.strip()]
    out, i = [], 0
    while i < len(lines):
        if lines[i].startswith("1 ") and i + 1 < len(lines) and lines[i + 1].startswith("2 "):
            out.append(parse_tle("", lines[i], lines[i + 1]))
            i += 2
        elif i + 2 < len(lines) and lines[i + 1].startswith("1 ") and lines[i + 2].startswith("2 "):
            out.append(parse_tle(lines[i], lines[i + 1], lines[i + 2]))
            i += 3
        else:
            raise ElementError("unparseable TLE text near line %d" % (i + 1))
    return out


def _iso_to_posix(s: str) -> float:
    s = s.strip().replace("Z", "")
    dt = datetime.datetime.fromisoformat(s).replace(tzinfo=datetime.timezone.utc)
    return dt.timestamp()


def parse_omm_json(records: Iterable[dict]) -> List[Elements]:
    """CCSDS OMM keys as CelesTrak's GP API returns them with FORMAT=json."""
    out = []
    for r in records:
        try:
            out.append(Elements(
                norad_id=int(r["NORAD_CAT_ID"]), name=str(r.get("OBJECT_NAME", r["NORAD_CAT_ID"])).strip(),
                epoch=_iso_to_posix(r["EPOCH"]), inclination=float(r["INCLINATION"]), raan=float(r["RA_OF_ASC_NODE"]),
                eccentricity=float(r["ECCENTRICITY"]), arg_perigee=float(r["ARG_OF_PERICENTER"]),
                mean_anomaly=float(r["MEAN_ANOMALY"]), mean_motion=float(r["MEAN_MOTION"]),
                bstar=float(r.get("BSTAR", 0.0))))
        except (KeyError, ValueError) as exc:
            raise ElementError("malformed OMM record: %s" % exc)
    return out
