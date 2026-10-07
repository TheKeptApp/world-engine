"""Transit smoothing: shapes, projection, speed estimation, the reference client model, relay wiring."""

import json
import os
import tempfile
import unittest

from livefeeds.relay import Area, Config, Relay
from livefeeds.server import render_vehicle
from livefeeds.transit import shapes as S
from livefeeds.transit import smoothing as M
from tests import pbenc
from tests.common import LAT_A, LON_A, Clock, FakeUpstream, T0, sample_routes

# A synthetic east-west street through the test area (about 1.7 km), with a redundant midpoint.
LAT = LAT_A
LON0, LON1 = LON_A - 0.01, LON_A + 0.01
TRIPS_TXT = "﻿route_id,service_id,trip_id,shape_id\n15,WK,T-1,SH-15E\n15,WK,T-2,SH-15E\nA,WK,T-3,SH-NONE\n"
SHAPES_TXT = ("shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence\n"
              "SH-15E,%f,%f,1\nSH-15E,%f,%f,2\nSH-15E,%f,%f,3\nSH-UNUSED,1,1,1\nSH-UNUSED,1,2,2\n"
              % (LAT, LON0, LAT, (LON0 + LON1) / 2, LAT, LON1))


def table():
    return S.ShapeTable.from_gtfs(TRIPS_TXT, SHAPES_TXT, T0, "synthetic")


def lon_at(m):
    """Longitude m metres east of LON0 along the street."""
    return LON0 + (LON1 - LON0) * m / table().shapes["SH-15E"].length


class ShapeTests(unittest.TestCase):
    def test_parse_simplify_and_filter(self):
        t = table()
        self.assertEqual(set(t.shapes), {"SH-15E"})        # unused shapes are not kept
        self.assertEqual(len(t.shapes["SH-15E"].points), 2)  # collinear midpoint simplified away
        self.assertEqual(t.trips, {"T-1": "SH-15E", "T-2": "SH-15E"})
        self.assertAlmostEqual(t.shapes["SH-15E"].length, 1711, delta=5)

    def test_project_and_point_at(self):
        sh = table().shapes["SH-15E"]
        d, off = sh.project(LAT + 0.0002, lon_at(500))
        self.assertAlmostEqual(d, 500, delta=0.5)
        self.assertAlmostEqual(off, 22.2, delta=0.5)
        lat, lon, hdg = sh.point_at(500)
        self.assertAlmostEqual(lon, lon_at(500), places=7)
        self.assertAlmostEqual(hdg, 90.0, places=3)
        self.assertEqual(sh.point_at(-5)[:2], sh.points[0])
        self.assertEqual(sh.point_at(1e9)[:2], sh.points[-1])

    def test_loop_prefers_continuity(self):
        # Out and back on the same street: two candidates per position.
        out = S.Shape("L", [(LAT, LON0), (LAT, LON1), (LAT, LON0)])
        half = out.length / 2
        d_near_end, _ = out.project(LAT, lon_at(300), near=out.length - 400)
        d_near_start, _ = out.project(LAT, lon_at(300), near=200)
        self.assertGreater(d_near_end, half)
        self.assertLess(d_near_start, half)

    def test_save_load(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "shapes.json")
            table().save(p)
            t2 = S.ShapeTable.load(p)
            self.assertEqual(t2.trips, table().trips)
            self.assertAlmostEqual(t2.shapes["SH-15E"].length, table().shapes["SH-15E"].length)

    def test_shape_json(self):
        j = table().shapes["SH-15E"].to_json()
        self.assertEqual(len(j["points"]), len(j["distM"]))
        self.assertEqual(j["distM"][0], 0.0)


def veh(vid, m, t, speed=None, lat=LAT, kind="bus"):
    return {"id": vid, "kind": kind, "lat": lat, "lon": lon_at(m), "timestamp": t, "speedMps": speed}


class TrackerTests(unittest.TestCase):
    def test_speed_inferred_from_successive_positions(self):
        tr, t = M.Tracker(), table()
        a = [veh("v1", 100, T0)]
        tr.annotate(a, {"v1": "T-1"}, t, T0)
        self.assertIsNone(a[0]["motion"]["speedMps"])
        b = [veh("v1", 400, T0 + 30)]
        tr.annotate(b, {"v1": "T-1"}, t, T0 + 30)
        m = b[0]["motion"]
        self.assertEqual(m["speedBasis"], "inferred")
        self.assertAlmostEqual(m["speedMps"], 10.0, delta=0.1)
        self.assertEqual(m["shapeId"], "SH-15E")
        self.assertAlmostEqual(m["distM"], 400, delta=1)
        # The same report again keeps the estimate instead of dropping it.
        c = [veh("v1", 400, T0 + 30)]
        tr.annotate(c, {"v1": "T-1"}, t, T0 + 60)
        self.assertAlmostEqual(c[0]["motion"]["speedMps"], 10.0, delta=0.1)

    def test_observed_speed_wins_and_is_capped(self):
        tr = M.Tracker()
        v = [veh("v1", 100, T0, speed=99.0)]
        tr.annotate(v, {"v1": "T-1"}, table(), T0)
        self.assertEqual(v[0]["motion"]["speedBasis"], "observed")
        self.assertEqual(v[0]["motion"]["speedMps"], M.SPEED_CAP_MPS["bus"])

    def test_off_shape_unknown_trip_and_jumps(self):
        tr, t = M.Tracker(), table()
        v = [veh("off", 100, T0, lat=LAT + 0.01), veh("x", 100, T0), veh("j", 100, T0)]
        tr.annotate(v, {"off": "T-1", "x": "T-404", "j": "T-1"}, t, T0)
        self.assertIsNone(v[0]["motion"])   # 1.1 km off its shape
        self.assertIsNone(v[1]["motion"])   # trip not in the static data
        w = [veh("j", 1600, T0 + 10)]       # 150 m/s: impossible, no speed
        tr.annotate(w, {"j": "T-1"}, t, T0 + 10)
        self.assertIsNone(w[0]["motion"]["speedMps"])

    def test_no_shapes_means_no_motion(self):
        v = [veh("v1", 100, T0)]
        M.Tracker().annotate(v, {"v1": "T-1"}, None, T0)
        self.assertIsNone(v[0]["motion"])


def rec(dist, t, speed, status=None):
    return {"timestamp": t, "stopStatus": status,
            "motion": {"shapeId": "SH", "distM": dist, "t": t, "speedMps": speed, "speedBasis": "inferred", "offsetM": 0}}


D = M.RENDER_DELAY_SECONDS


class SmootherTests(unittest.TestCase):
    def test_interpolates_between_reports_in_the_past(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10), T0)
        s.observe(rec(400, T0 + 30, 10), T0 + 30)
        # Drawn 45 s in the past: at T0 + 60 the render time is T0 + 15, halfway between the reports.
        self.assertAlmostEqual(s.distance(T0 + 60), 250)
        self.assertAlmostEqual(s.distance(T0 + 75), 400)

    def test_extrapolates_at_most_30_s_then_holds(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10), T0)
        self.assertAlmostEqual(s.distance(T0 + D + 10), 200)
        self.assertAlmostEqual(s.distance(T0 + D + 30), 400)
        self.assertAlmostEqual(s.distance(T0 + D + 300), 400)

    def test_stopped_vehicle_is_held(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10, status="stopped"), T0)
        self.assertAlmostEqual(s.distance(T0 + D + 20), 100)

    def test_new_data_is_blended_not_jumped(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10), T0)
        before = s.distance(T0 + D + 20)              # 300 m, extrapolated
        s.observe(rec(340, T0 + 20, 12), T0 + D + 20)  # the new fix says 340 m at that render time
        self.assertAlmostEqual(s.distance(T0 + D + 20), before)
        mid = s.distance(T0 + D + 21.5)
        self.assertTrue(before < mid < 360)
        self.assertAlmostEqual(s.distance(T0 + D + 23), 376)
        self.assertFalse(s.snapped)

    def test_far_jump_snaps(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10), T0)
        s.distance(T0 + D + 30)
        s.observe(rec(2000, T0 + 30, 10), T0 + D + 30)
        self.assertTrue(s.snapped)

    def test_never_runs_backwards_visibly(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10), T0)
        shown = s.distance(T0 + D + 30)                 # 400 m
        s.observe(rec(300, T0 + 30, 0), T0 + D + 30)    # actually only reached 300 m and stopped
        for k in range(1, 9):
            self.assertGreaterEqual(s.distance(T0 + D + 30 + k), shown - M.BACKTRACK_TOLERANCE_M)
        self.assertAlmostEqual(s.distance(T0 + D + 30 + 12), 300)  # hold gave way after 10 s

    def test_stale_is_frozen_where_it_ended_up(self):
        s = M.Smoother(10_000)
        s.observe(rec(100, T0, 10), T0)
        d = s.distance(T0 + D + 10)
        s.observe(rec(100, T0, 10), T0 + D + 10, layer_state="stale")
        self.assertTrue(s.frozen)
        self.assertEqual(s.distance(T0 + D + 100), d)
        s.observe(rec(500, T0 + 120, 10), T0 + 125)      # fresh again
        self.assertFalse(s.frozen)
        old = M.Smoother(10_000)
        old.observe(rec(100, T0, 10), T0 + 500)          # first sight is already too old: never animated
        self.assertTrue(old.frozen)
        self.assertIsNone(old.distance(T0 + 600))


class RelayWiringTests(unittest.TestCase):
    def feed(self, ts, m):
        vp = pbenc.vehicle_position
        return pbenc.encode_feed(ts, [pbenc.entity("B", vp(trip_id="T-1", route_id="15", vehicle_id="B",
                                                           lat=LAT, lon=lon_at(m), timestamp=ts, status=2))])

    def test_motion_served_and_trip_ids_never_leave(self):
        clock = Clock()
        up = FakeUpstream(self.feed(T0, 100))
        area = Area("test", "Test box", (39.40, -105.60, 40.30, -104.55), "America/Denver", 3)
        with tempfile.TemporaryDirectory() as d:
            relay = Relay(Config(cache_dir=d), [area], fetch=up, routes_fetch=lambda: (sample_routes(clock()), 1),
                          shapes_fetch=lambda: (table(), 10), clock=clock)
            relay.poll_once()
            clock.advance(30)
            up.publish(self.feed(T0 + 30, 400))
            relay.poll_once()
            snap, state, _ = relay.view(clock())
            out = render_vehicle(snap.vehicles[0], clock())
            self.assertEqual(out["positionState"], "fresh")
            self.assertEqual(out["basis"], "observed")
            self.assertAlmostEqual(out["motion"]["speedMps"], 10.0, delta=0.1)
            self.assertIsNotNone(relay.shape("SH-15E"))
            on_disk = "".join(open(os.path.join(d, f)).read() for f in os.listdir(d) if f.startswith("snapshot"))
            self.assertNotIn("T-1", on_disk)
            self.assertNotIn("T-1", json.dumps(out))
            clock.advance(200)
            old = render_vehicle(snap.vehicles[0], clock())
            self.assertEqual(old["positionState"], "stale")
            self.assertIsNone(old["motion"])


if __name__ == "__main__":
    unittest.main()
