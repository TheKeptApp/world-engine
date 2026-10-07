"""Sky layer: Meeus worked examples, contract shape, skyglow and stale handling (offline)."""

import calendar
import json
import math
import os
import tempfile
import unittest

from livefeeds.sky import astro, bodies, contract, skyglow, stars


def utc(y, mo, d, h=0, mi=0, s=0.0):
    return calendar.timegm((y, mo, d, h, mi, 0)) + s


def td(y, mo, d):
    """POSIX instant of 0h TD (TT) on a date."""
    p = utc(y, mo, d)
    return p - astro.delta_t(p)


def geocentric_frame(posix):
    fr = bodies.Frame.make(posix, bodies.Observer(0.0, 0.0))
    fr.observer_km = (0.0, 0.0, 0.0)
    return fr


class TimeTests(unittest.TestCase):
    def test_gmst_meeus_12a_12b(self):
        self.assertAlmostEqual(astro.gmst_deg(utc(1987, 4, 10)) / 15, 13 + 10 / 60 + 46.3668 / 3600, places=7)
        self.assertAlmostEqual(astro.gmst_deg(utc(1987, 4, 10, 19, 21)) / 15, 8 + 34 / 60 + 57.0896 / 3600, places=7)

    def test_leap_seconds(self):
        self.assertEqual(astro.delta_t(utc(2026, 10, 6)), 69.184)
        self.assertEqual(astro.delta_t(utc(2016, 12, 31, 23, 59)), 68.184)

    def test_nutation_meeus_22a(self):
        # 1987 April 10, 0h TD: delta psi = -3.788", delta eps = +9.443".
        dpsi, deps = astro.nutation(astro.centuries_tt(td(1987, 4, 10)))
        self.assertAlmostEqual(dpsi, -3.788, delta=0.05)
        self.assertAlmostEqual(deps, 9.443, delta=0.05)


class BodyTests(unittest.TestCase):
    def test_moon_meeus_47a(self):
        lon, lat, dist = bodies.moon_ecliptic_of_date(astro.centuries_tt(td(1992, 4, 12)))
        self.assertAlmostEqual(lon, 133.162655, delta=1e-5)
        self.assertAlmostEqual(lat, -3.229126, delta=3e-4)  # ~1 arcsec
        self.assertAlmostEqual(dist, 368409.7, delta=0.1)

    def test_sun_meeus_25b(self):
        v, _ = bodies.apparent_topocentric_km("sun", geocentric_frame(td(1992, 10, 13)))
        ra, dec = astro.ra_dec(v)
        self.assertLess(abs(ra - 198.378178) * 3600, 2)
        self.assertLess(abs(dec - -7.783871) * 3600, 2)

    def test_venus_meeus_33a(self):
        v, _ = bodies.apparent_topocentric_km("venus", geocentric_frame(td(1992, 12, 20)))
        ra, dec = astro.ra_dec(v)
        self.assertLess(abs(ra - (21 + 4 / 60 + 41.454 / 3600) * 15) * 3600, 15)
        self.assertLess(abs(dec - -(18 + 53 / 60 + 16.84 / 3600)) * 3600, 15)

    def test_precession_meeus_21b(self):
        # theta Persei, J2000 2h44m11.977s +49d13'42.48", proper motion applied, to 2028 Nov 13.19 TD.
        years = (2462088.69 - astro.J2000) / 365.25
        ra0 = (2 + 44 / 60 + 11.977 / 3600) * 15 + 0.03425 * 15 / 3600 * years
        dec0 = 49 + 13 / 60 + 42.48 / 3600 - 0.0895 / 3600 * years
        t = (2462088.69 - astro.J2000) / 36525
        ra, dec = astro.ra_dec(astro.matvec(astro.precession_matrix(t), astro.from_ra_dec(ra0, dec0)))
        self.assertAlmostEqual(ra, 41.547214, delta=1e-4)  # 0.36 arcsec
        self.assertAlmostEqual(dec, 49.348483, delta=1e-4)

    def test_range_guard(self):
        with self.assertRaises(bodies.OutOfRange):
            bodies.solar_system(utc(2051, 1, 1), bodies.Observer(41.9, -87.6))

    def test_moon_phase_names(self):
        self.assertEqual(bodies.moon_phase_name(0.01, 3), "new")
        self.assertEqual(bodies.moon_phase_name(0.5, 90), "firstQuarter")
        self.assertEqual(bodies.moon_phase_name(0.8, 200), "waningGibbous")
        self.assertEqual(bodies.moon_phase_name(0.99, 180), "full")

    def test_full_moon_bright_new_moon_dark(self):
        full = bodies.moon_magnitude(0, 384400)
        quarter = bodies.moon_magnitude(90, 384400)
        self.assertAlmostEqual(full, -12.73, places=2)
        self.assertGreater(quarter, full + 2)

    def test_saturn_magnitude_reasonable(self):
        ss = bodies.solar_system(utc(2026, 10, 6, 2), bodies.Observer(41.88, -87.63))
        self.assertTrue(-1.0 < ss["saturn"]["magnitude"] < 1.5)
        self.assertTrue(-3.0 < ss["jupiter"]["magnitude"] < -1.5)


class SkyglowTests(unittest.TestCase):
    def test_limiting_magnitude_conversion(self):
        self.assertAlmostEqual(skyglow.limiting_magnitude(22.0), 6.62, places=2)
        self.assertLess(skyglow.limiting_magnitude(18.0), 4.1)

    def test_twilight_and_moon_brighten_the_sky(self):
        dark = skyglow.sky_brightness(0.0, -30, -10, 0)
        dusk = skyglow.sky_brightness(0.0, -9, -10, 0)
        moon = skyglow.sky_brightness(0.0, -30, 60, 0)
        self.assertAlmostEqual(dark["zenithSkyMagNow"], 22.0, places=6)
        self.assertLess(dusk["zenithSkyMagNow"], 20)
        self.assertLess(moon["zenithSkyMagNow"], 19.5)  # full Moon high up: about 18 mag/arcsec^2
        self.assertGreater(moon["zenithSkyMagNow"], 17.0)

    def _grid(self, value, year=2025):
        return skyglow.RadianceGrid(north=42.5, west=-88.5, dlat=0.05, dlon=0.05, rows=30, cols=30,
                                    values=[value] * 900, product="synthetic", year=year, source={})

    def test_uniform_grid_returns_its_value(self):
        self.assertAlmostEqual(skyglow.weighted_radiance(self._grid(7.0), 41.75, -87.75), 7.0, places=6)

    def test_outside_or_edge_is_unknown(self):
        g = self._grid(7.0)
        self.assertIsNone(skyglow.weighted_radiance(g, 10.0, 10.0))
        self.assertIsNone(skyglow.weighted_radiance(g, 42.49, -88.49))  # corner: most of the kernel is off-grid

    def test_brighter_city_lower_limiting_magnitude(self):
        a = skyglow.sky_brightness(skyglow.artificial_ratio(0.3), -30, -10, 0)["limitingMagnitudeDark"]
        b = skyglow.sky_brightness(skyglow.artificial_ratio(60), -30, -10, 0)["limitingMagnitudeDark"]
        self.assertGreater(a, b + 1.5)

    def test_load_round_trip(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "g.json")
            with open(p, "w") as fh:
                json.dump({"schema": "worldengine.radiance/1", "product": "x", "year": 2024,
                           "grid": {"north": 1, "west": 0, "dlat": 0.5, "dlon": 0.5, "rows": 2, "cols": 2},
                           "values": [1, 2, 3, None]}, fh)
            g = skyglow.RadianceGrid.load(p)
            self.assertEqual(len(list(g.cells())), 3)


class ContractTests(unittest.TestCase):
    NOW = utc(2026, 10, 6, 4)

    def test_shape_and_labels(self):
        doc = contract.build(self.NOW, bodies.Observer(41.8781, -87.6298, 181), now=self.NOW)
        self.assertEqual(doc["schema"], "worldengine.live.sky/1")
        self.assertEqual(doc["state"], "fresh")
        self.assertFalse(doc["live"])
        for k in ("sun", "moon"):
            self.assertEqual(doc[k]["basis"], "inferred")
        self.assertEqual([p["id"] for p in doc["planets"]], list(bodies.PLANETS))
        self.assertTrue(all(p["basis"] == "inferred" for p in doc["planets"]))
        self.assertEqual(doc["lightPollution"]["state"], "unavailable")
        self.assertEqual(doc["skyBrightness"]["confidence"], "assumesDarkSite")
        self.assertTrue(doc["attribution"][0]["required"])
        self.assertGreater(doc["stars"]["count"], 50)
        self.assertTrue(all(s["apparentAltDeg"] >= -1 for s in doc["stars"]["items"]))
        json.dumps(doc)  # serialisable

    def test_polaris_altitude_equals_latitude(self):
        doc = contract.build(self.NOW, bodies.Observer(39.7392, -104.9903, 1609), now=self.NOW)
        pol = [s for s in doc["stars"]["items"] if s["id"] == "hr424"][0]
        self.assertAlmostEqual(pol["altDeg"], 39.74, delta=0.8)

    def test_radiance_states(self):
        g = skyglow.RadianceGrid(42.5, -88.5, 0.05, 0.05, 30, 30, [20.0] * 900, "synthetic", 2025, {})
        obs = bodies.Observer(41.75, -87.75)
        fresh = contract.build(self.NOW, obs, radiance=g, now=self.NOW)
        self.assertEqual(fresh["lightPollution"]["state"], "fresh")
        self.assertEqual(fresh["lightPollution"]["weightedRadiance"]["basis"], "observed")
        self.assertEqual(fresh["attribution"][-1]["source"], "nasa-black-marble")
        g.year = 2021
        self.assertEqual(contract.build(self.NOW, obs, radiance=g, now=self.NOW)["lightPollution"]["state"], "stale")
        g.year = 2015
        old = contract.build(self.NOW, obs, radiance=g, now=self.NOW)
        self.assertEqual(old["lightPollution"]["state"], "unavailable")
        self.assertIsNone(old["lightPollution"]["artificialToNaturalRatio"])

    def test_out_of_range_is_unavailable(self):
        doc = contract.build(utc(2060, 1, 1), bodies.Observer(25.76, -80.19), now=self.NOW)
        self.assertEqual(doc["state"], "unavailable")
        self.assertNotIn("planets", doc)


class StarTests(unittest.TestCase):
    def test_catalog_loads(self):
        cat = stars.load_catalog()
        self.assertEqual(cat["count"], len(cat["stars"]))

    def test_extinction_grows_to_horizon(self):
        self.assertLess(stars.extinction_mag(90), stars.extinction_mag(10))
        self.assertAlmostEqual(stars.extinction_mag(90), 0.25, places=2)


if __name__ == "__main__":
    unittest.main()


class BakeTests(unittest.TestCase):
    def test_xyz_round_trip(self):
        lines = ["%f %f %f" % (-88 + c * 0.5, 42 - r * 0.5, (65535 if (r, c) == (1, 1) else r * 10 + c))
                 for r in range(3) for c in range(4)]
        doc = skyglow.grid_from_xyz(lines, "VNP46A4", 2025, {"name": "synthetic"})
        self.assertEqual((doc["grid"]["rows"], doc["grid"]["cols"]), (3, 4))
        self.assertAlmostEqual(doc["grid"]["north"], 42.25)
        self.assertAlmostEqual(doc["grid"]["west"], -88.25)
        self.assertEqual(doc["values"][:4], [0, 1, 2, 3])
        self.assertIsNone(doc["values"][5])

    def test_irregular_rejected(self):
        with self.assertRaises(ValueError):
            skyglow.grid_from_xyz(["0 0 1", "1 0 1", "3 0 1", "0 1 1", "1 1 1", "3 1 1"], "x", 2025, {})
