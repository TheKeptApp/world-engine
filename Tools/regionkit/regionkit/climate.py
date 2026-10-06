"""NOAA NCEI U.S. Climate Normals 1991-2020 (monthly) and a Koppen-Geiger class computed from them.

Access (verified 2026-10-06):
- station inventory: https://www.ncei.noaa.gov/data/normals-monthly/1991-2020/doc/inventory_30yr.txt
- per-station CSV:   https://www.ncei.noaa.gov/data/normals-monthly/1991-2020/access/<STATION>.csv
  columns MLY-TAVG-NORMAL (deg F, tenths), MLY-PRCP-NORMAL (inches), MLY-SNOW-NORMAL (inches),
  with meas_flag_* / comp_flag_* (Readme_By-Variable_By-Station_Normals_Files.txt;
  units: Normals_MLY_Documentation_1991-2020.pdf section III.C).
- dataset citation (NCEI metadata gov.noaa.ncdc:C01620): Palecki et al. (2021), U.S. Climate Normals
  2020: U.S. Monthly Climate Normals (1991-2020), NOAA NCEI, doi:10.25921/wck8-er13.
Only derived values (12 monthly means in deg C / mm) are stored, never the raw files.

Koppen-Geiger (Peel, Finlayson & McMahon 2007; same criteria as Beck et al. 2018):
  MAT, MAP; Thot/Tcold = warmest/coldest month; summer = the warmer 6-month half (AMJJAS or ONDJFM).
  Pthreshold = 2*MAT (>= 70 % of MAP in winter), 2*MAT + 28 (>= 70 % in summer), else 2*MAT + 14.
  E: Thot < 10 (ET if Thot > 0, else EF).  B: MAP < 10*Pthreshold (BW if MAP < 5*Pthreshold, else BS;
  h if MAT >= 18, else k).  A: Tcold >= 18 (Af Pdry >= 60; Am Pdry >= 100 - MAP/25; else Aw).
  C: Tcold > 0 (C/D threshold 0 deg C; the original Koppen -3 deg C variant is reported too).  D: else.
  2nd letter for C/D: s if Psdry < 40 and Psdry < Pwwet/3; w if Pwdry < Pswet/10; else f (s tested first).
  3rd letter: a Thot >= 22; b >= 4 months >= 10; c 1-3 months >= 10 (D: d if Tcold < -38).
"""
import csv
import io

from . import geo, net

BASE = "https://www.ncei.noaa.gov/data/normals-monthly/1991-2020/"
INVENTORY = BASE + "doc/inventory_30yr.txt"
MAX_CANDIDATES = 12
# Snowfall normals are rarer (many nearby precipitation-only stations), so the snow search goes further.
SNOW_MAX_CANDIDATES = 40
SNOW_MAX_KM = 50.0
BAD_FLAGS = {"M", "V", "Y", "Z"}


def inventory():
    txt = net.get(INVENTORY, note="NCEI inventory").decode("latin-1")
    out = []
    for line in txt.splitlines():
        if len(line) < 40:
            continue
        parts = line.split()
        try:
            sid, lat, lon = parts[0], float(parts[1]), float(parts[2])
        except (ValueError, IndexError):
            continue
        name = line[41:71].strip() if len(line) > 41 else ""
        state = line[38:40].strip()
        out.append({"id": sid, "lat": lat, "lon": lon, "state": state, "name": name})
    return out


def station_csv(sid):
    return net.get(BASE + "access/%s.csv" % sid, note="NCEI normals " + sid).decode("latin-1")


def parse_station(text):
    rows = list(csv.DictReader(io.StringIO(text)))
    if not rows:
        return None
    meta = {"name": rows[0].get("NAME", "").strip(), "lat": float(rows[0]["LATITUDE"]), "lon": float(rows[0]["LONGITUDE"]),
            "elevationM": float(rows[0]["ELEVATION"])}

    def series(var):
        vals, flags = [], []
        by_month = {}
        for r in rows:
            m = r.get("month") or (r.get("DATE") or "")[:2]
            try:
                mi = int(m)
            except ValueError:
                continue
            by_month[mi] = r
        for mi in range(1, 13):
            r = by_month.get(mi)
            if r is None:
                return None, None
            v = (r.get(var) or "").strip()
            mf = (r.get("meas_flag_" + var) or "").strip()
            cf = (r.get("comp_flag_" + var) or "").strip()
            if v == "" or mf in BAD_FLAGS:
                return None, None
            try:
                x = float(v)
            except ValueError:
                return None, None
            if x <= -7777:  # NCEI special values
                return None, None
            vals.append(x)
            flags.append(cf)
        return vals, flags

    tavg, tf = series("MLY-TAVG-NORMAL")
    prcp, pf = series("MLY-PRCP-NORMAL")
    snow, sf = series("MLY-SNOW-NORMAL")
    return meta, {"tavgF": tavg, "prcpIn": prcp, "snowIn": snow, "flags": {"tavg": tf, "prcp": pf, "snow": sf}}


def normals_near(lat, lon, log=print):
    """Nearest station with complete monthly TAVG + PRCP normals, and nearest with SNOW normals."""
    inv = sorted(inventory(), key=lambda s: (geo.haversine_km(lat, lon, s["lat"], s["lon"]), s["id"]))
    temp_station = snow_station = None
    tried = []
    for i, s in enumerate(inv[:SNOW_MAX_CANDIDATES]):
        d = geo.haversine_km(lat, lon, s["lat"], s["lon"])
        # Past the temperature candidates, keep looking only while a snow station is still missing and near.
        if i >= MAX_CANDIDATES and (temp_station is None or snow_station is not None or d > SNOW_MAX_KM):
            break
        try:
            parsed = parse_station(station_csv(s["id"]))
        except RuntimeError as e:  # station listed without an access file
            tried.append({"id": s["id"], "distanceKm": round(d, 1), "result": str(e)[:60]})
            continue
        if parsed is None:
            continue
        meta, ser = parsed
        ok_t = ser["tavgF"] is not None and ser["prcpIn"] is not None
        ok_s = ser["snowIn"] is not None
        tried.append({"id": s["id"], "distanceKm": round(d, 1), "tempPrcp": ok_t, "snow": ok_s})
        rec = {"id": s["id"], "name": meta["name"], "lat": meta["lat"], "lon": meta["lon"], "elevationM": meta["elevationM"],
               "distanceKm": round(d, 1)}
        if ok_t and temp_station is None:
            temp_station = (rec, ser)
        if ok_s and snow_station is None:
            snow_station = (rec, ser)
        if temp_station and snow_station:
            break
    if temp_station is None:
        return {"available": False, "tried": tried}
    rec, ser = temp_station
    t_c = [round((f - 32) * 5 / 9, 2) for f in ser["tavgF"]]
    p_mm = [round(i * 25.4, 1) for i in ser["prcpIn"]]
    out = {"available": True, "source": "NOAA NCEI U.S. Climate Normals 1991-2020, monthly (doi:10.25921/wck8-er13)",
           "stationTempPrecip": rec, "tempC": t_c, "precipMm": p_mm,
           "completeness": {"tavg": "".join(ser["flags"]["tavg"]), "prcp": "".join(ser["flags"]["prcp"])},
           "candidatesTried": tried}
    if snow_station:
        srec, sser = snow_station
        out["stationSnow"] = srec
        out["snowMm"] = [round(i * 25.4, 0) for i in sser["snowIn"]]
        out["completeness"]["snow"] = "".join(sser["flags"]["snow"])
    else:
        out["stationSnow"] = None
        out["snowMm"] = None
    out["koppen"] = koppen(t_c, p_mm, lat)
    out["koppenMinus3"] = koppen(t_c, p_mm, lat, cd_threshold=-3.0)
    return out


def koppen(t, p, lat, cd_threshold=0.0):
    """Koppen-Geiger class from 12 monthly mean temperatures (deg C) and precipitation (mm)."""
    mat = sum(t) / 12
    map_ = sum(p)
    thot, tcold = max(t), min(t)
    amjjas = [3, 4, 5, 6, 7, 8]
    ondjfm = [9, 10, 11, 0, 1, 2]
    warm_first = sum(t[i] for i in amjjas) >= sum(t[i] for i in ondjfm)
    summer, winter = (amjjas, ondjfm) if warm_first else (ondjfm, amjjas)
    ps = sum(p[i] for i in summer)
    pw = sum(p[i] for i in winter)
    if pw >= 0.7 * map_:
        pth = 2 * mat
    elif ps >= 0.7 * map_:
        pth = 2 * mat + 28
    else:
        pth = 2 * mat + 14
    pdry = min(p)
    psdry, pswet = min(p[i] for i in summer), max(p[i] for i in summer)
    pwdry, pwwet = min(p[i] for i in winter), max(p[i] for i in winter)
    tmon10 = sum(1 for x in t if x >= 10)
    detail = {"MAT": round(mat, 2), "MAP": round(map_, 1), "Thot": thot, "Tcold": tcold, "Pthreshold": round(pth, 1),
              "summerHalf": "AMJJAS" if warm_first else "ONDJFM", "Pdry": pdry, "Psdry": psdry, "Pswet": pswet,
              "Pwdry": pwdry, "Pwwet": pwwet, "monthsAtLeast10C": tmon10, "cdThresholdC": cd_threshold}
    if thot < 10:
        return {"class": "ET" if thot > 0 else "EF", "detail": detail}
    if map_ < 10 * pth:
        cls = ("BW" if map_ < 5 * pth else "BS") + ("h" if mat >= 18 else "k")
        return {"class": cls, "detail": detail}
    if tcold >= 18:
        if pdry >= 60:
            cls = "Af"
        elif pdry >= 100 - map_ / 25:
            cls = "Am"
        else:
            cls = "Aw"
        return {"class": cls, "detail": detail}
    first = "C" if tcold > cd_threshold else "D"
    s_cond = psdry < 40 and psdry < pwwet / 3
    w_cond = pwdry < pswet / 10
    second = "s" if s_cond else ("w" if w_cond else "f")
    detail["sCondition"], detail["wCondition"] = s_cond, w_cond
    if thot >= 22:
        third = "a"
    elif tmon10 >= 4:
        third = "b"
    elif first == "D" and tcold < -38:
        third = "d"
    else:
        third = "c"
    return {"class": first + second + third, "detail": detail}
