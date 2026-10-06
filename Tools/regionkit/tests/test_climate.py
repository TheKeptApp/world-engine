"""Koppen-Geiger on known normals.

Chicago O'Hare (USW00094846) monthly TAVG/PRCP normals 1991-2020 as published by NOAA NCEI (deg F / inches,
converted here); the other cases are synthetic normals constructed to sit inside one class each."""
import unittest

from regionkit import climate

OHARE_F = [25.2, 28.8, 39.0, 49.7, 60.6, 70.6, 75.4, 73.8, 66.3, 54.0, 41.3, 30.5]
OHARE_IN = [1.99, 1.97, 2.45, 3.75, 4.49, 4.10, 3.71, 4.25, 3.19, 3.43, 2.42, 2.11]


def c(f):
    return [(x - 32) * 5 / 9 for x in f]


def mm(i):
    return [x * 25.4 for x in i]


class Koppen(unittest.TestCase):
    def test_ohare_is_dfa(self):
        k = climate.koppen(c(OHARE_F), mm(OHARE_IN), 41.995)
        self.assertEqual(k["class"], "Dfa")
        self.assertEqual(climate.koppen(c(OHARE_F), mm(OHARE_IN), 41.995, cd_threshold=-3)["class"], "Dfa")  # Tcold -3.8 C

    def test_c_d_threshold_variant(self):
        t = [-1.5, 0, 5, 10, 15, 20, 23, 22, 18, 12, 6, 1]   # coldest -1.5 C
        p = [60] * 12
        self.assertEqual(climate.koppen(t, p, 40)["class"], "Dfa")
        self.assertEqual(climate.koppen(t, p, 40, cd_threshold=-3)["class"], "Cfa")

    def test_tropical(self):
        self.assertEqual(climate.koppen([25] * 12, [100] * 12, 5)["class"], "Af")
        # dry month 40 mm, MAP 2000 -> 100 - 2000/25 = 20 <= 40 -> Am
        self.assertEqual(climate.koppen([25] * 12, [40] + [178.2] * 11, 5)["class"], "Am")
        self.assertEqual(climate.koppen([25] * 12, [5, 5, 5, 50, 150, 200, 250, 250, 200, 150, 50, 5], 15)["class"], "Aw")

    def test_arid(self):
        hot = [15, 17, 20, 24, 29, 34, 36, 35, 32, 26, 19, 15]
        self.assertEqual(climate.koppen(hot, [20, 20, 20, 8, 3, 2, 25, 25, 15, 15, 15, 20], 33)["class"], "BWh")
        cool = [0, 2, 6, 10, 15, 21, 24, 23, 18, 11, 5, 0]
        self.assertEqual(climate.koppen(cool, [12, 15, 30, 45, 60, 45, 45, 40, 30, 25, 15, 12], 40)["class"], "BSk")

    def test_mediterranean_and_polar(self):
        t = [10, 11, 13, 15, 18, 21, 24, 24, 22, 18, 14, 11]
        p = [100, 90, 70, 40, 20, 5, 1, 2, 15, 60, 90, 110]
        self.assertEqual(climate.koppen(t, p, 38)["class"], "Csa")
        self.assertEqual(climate.koppen([-20, -18, -15, -10, -2, 4, 8, 6, 1, -6, -14, -18], [20] * 12, 70)["class"], "ET")

    def test_southern_hemisphere_halves(self):
        t = [24, 24, 22, 19, 16, 13, 12, 13, 15, 18, 21, 23]
        k = climate.koppen(t, [100] * 12, -33)
        self.assertEqual(k["detail"]["summerHalf"], "ONDJFM")
        self.assertEqual(k["class"], "Cfa")


class StationSearch(unittest.TestCase):
    """Snowfall normals may sit beyond the temperature candidates (no network: inventory and CSVs stubbed)."""

    @staticmethod
    def _csv(sid, snow):
        head = "STATION,NAME,LATITUDE,LONGITUDE,ELEVATION,month,MLY-TAVG-NORMAL,MLY-PRCP-NORMAL,MLY-SNOW-NORMAL\n"
        rows = ["%s,%s,41.0,-87.0,180,%02d,%s,%s,%s" % (sid, sid, m, OHARE_F[m - 1], OHARE_IN[m - 1], "2.0" if snow else "")
                for m in range(1, 13)]
        return head + "\n".join(rows) + "\n"

    def test_snow_found_past_temperature_candidates(self):
        # Station k sits k km north; only the first has temperature, only number 20 has snowfall.
        inv = [{"id": "S%02d" % k, "lat": 41.0 + k / 111.0, "lon": -87.0, "state": "IL", "name": ""} for k in range(1, 31)]
        orig = climate.inventory, climate.station_csv
        climate.inventory = lambda: inv
        climate.station_csv = lambda sid: self._csv(sid, snow=(sid == "S20")) if sid in ("S01", "S20") else \
            self._csv(sid, snow=False).replace(",%s," % OHARE_F[0], ",,")
        try:
            out = climate.normals_near(41.0, -87.0, log=lambda *a: None)
        finally:
            climate.inventory, climate.station_csv = orig
        self.assertEqual(out["stationTempPrecip"]["id"], "S01")
        self.assertEqual(out["stationSnow"]["id"], "S20")
        self.assertEqual(len(out["snowMm"]), 12)


if __name__ == "__main__":
    unittest.main()
