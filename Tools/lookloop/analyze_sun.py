"""Sun elevation/azimuth from the NOAA equations (as Sources/WorldGeo/SolarPosition.swift), for view metadata."""
import datetime, math


def sun(utc, lat, lon):
    t = datetime.datetime.fromisoformat(utc.replace("Z", "+00:00")).astimezone(datetime.timezone.utc)
    jd = t.timestamp() / 86400 + 2440587.5
    T = (jd - 2451545) / 36525
    L0 = (280.46646 + T * (36000.76983 + T * 0.0003032)) % 360
    M = 357.52911 + T * (35999.05029 - 0.0001537 * T)
    e = 0.016708634 - T * (0.000042037 + 0.0000001267 * T)
    C = (math.sin(math.radians(M)) * (1.914602 - T * (0.004817 + 0.000014 * T)) + math.sin(math.radians(2 * M)) * (0.019993 - 0.000101 * T)
         + math.sin(math.radians(3 * M)) * 0.000289)
    lam = L0 + C - 0.00569 - 0.00478 * math.sin(math.radians(125.04 - 1934.136 * T))
    eps = 23 + (26 + (21.448 - T * (46.815 + T * (0.00059 - T * 0.001813))) / 60) / 60 + 0.00256 * math.cos(math.radians(125.04 - 1934.136 * T))
    dec = math.degrees(math.asin(math.sin(math.radians(eps)) * math.sin(math.radians(lam))))
    y = math.tan(math.radians(eps / 2)) ** 2
    eq = 4 * math.degrees(y * math.sin(2 * math.radians(L0)) - 2 * e * math.sin(math.radians(M))
                          + 4 * e * y * math.sin(math.radians(M)) * math.cos(2 * math.radians(L0))
                          - 0.5 * y * y * math.sin(4 * math.radians(L0)) - 1.25 * e * e * math.sin(2 * math.radians(M)))
    tst = (t.hour * 60 + t.minute + t.second / 60 + eq + 4 * lon) % 1440
    ha, la, d = math.radians(tst / 4 - 180), math.radians(lat), math.radians(dec)
    z = math.acos(math.sin(la) * math.sin(d) + math.cos(la) * math.cos(d) * math.cos(ha))
    az = (math.degrees(math.atan2(math.sin(ha), math.cos(ha) * math.sin(la) - math.tan(d) * math.cos(la))) + 180) % 360
    return {"elevationDeg": round(90 - math.degrees(z), 1), "azimuthDeg": round(az, 1), "shadowBearingDeg": round((az + 180) % 360, 1),
            "source": "NOAA equations (as Sources/WorldGeo/SolarPosition.swift)"}
