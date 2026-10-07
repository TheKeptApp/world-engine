"""CTA static GTFS: shape selection by pattern and route, stops, snapping of live CTA records (synthetic, offline)."""

import io
import json
import threading
import unittest
import urllib.request
import zipfile

from livefeeds import cta, ctabus, ctagtfs
from livefeeds.relay import Area, Config, CtaBusSource, Relay
from livefeeds.salt import DailySalt
from livefeeds.server import make_server
from livefeeds.transit.smoothing import Smoother
from tests.common import Clock, FakeUpstream
from tests.test_ctabus import TS, bus, combined
from tests.test_cta import TMST, train, tt_body

LON0 = -87.6300


def gtfs_zip() -> zipfile.ZipFile:
    """Two Red line shapes (north- and southbound, a few metres apart), bus route 1 with pattern 6351 under two
    service prefixes (68106351 used more) and pattern 8085, stops of each kind."""
    def line(sid, lat0, lat1, lon, n=11):
        return ["%s,%.6f,%.6f,%d" % (sid, lat0 + (lat1 - lat0) * i / (n - 1), lon, i + 1) for i in range(n)]
    shapes = ["shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence"]
    shapes += line("309200007", 41.90, 41.80, LON0)               # Red south
    shapes += line("309200008", 41.80, 41.90, LON0 + 0.0002)      # Red north
    shapes += line("68106351", 41.85, 41.88, -87.6240)
    shapes += line("68206351", 41.85, 41.88, -87.6240)
    shapes += line("68108085", 41.88, 41.85, -87.6250)
    shapes += line("68110811", 41.88, 41.85, -87.6260)                # 5-digit pattern 10811
    trips = ["route_id,service_id,trip_id,direction_id,block_id,shape_id,direction,wheelchair_accessible,schd_trip_id",
             "Red,1,R1,0,b,309200007,South,1,1", "Red,1,R2,1,b,309200008,North,1,2",
             "1,1,B1,0,b,68106351,South,1,3", "1,1,B2,0,b,68106351,South,1,4", "1,1,B3,0,b,68206351,South,1,5",
             "1,1,B4,1,b,68108085,North,1,6", "1,1,B5,1,b,68110811,North,1,7"]
    routes = ["agency_id,route_id,route_short_name,route_long_name,route_type",
              "1,Red,,Red Line,1", "1,1,1,Bronzeville/Union Station,3"]
    stops = ["stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,location_type,parent_station,wheelchair_boarding",
             '1,1,"Jackson & Austin",,41.876,-87.774,0,,1', "30001,,Platform,,41.85,-87.63,0,40001,1",
             "40001,,Garfield,,41.85,-87.63,1,,1"]
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        for name, rows in (("shapes.txt", shapes), ("trips.txt", trips), ("routes.txt", routes), ("stops.txt", stops)):
            z.writestr(name, "﻿" + "\n".join(rows) + "\n")
    buf.seek(0)
    return zipfile.ZipFile(buf)


class BuildTest(unittest.TestCase):
    def setUp(self):
        self.shapes, self.stops = ctagtfs.build(gtfs_zip(), 0.0)

    def test_one_shape_per_pattern_and_route_candidates(self):
        self.assertEqual(sorted(self.shapes.shapes), ["309200007", "309200008", "68106351", "68108085", "68110811"])
        self.assertEqual(self.shapes.candidates["pid:10811"], ["68110811"])
        self.assertEqual(self.shapes.candidates["pid:6351"], ["68106351"])     # the more used prefix
        self.assertEqual(self.shapes.candidates["route:Red"], ["309200007", "309200008"])
        self.assertEqual(self.shapes.candidates["route:1"], ["68106351", "68108085", "68110811"])
        self.assertEqual(self.shapes.trips, {})

    def test_stops(self):
        self.assertEqual([(s["id"], s["kind"]) for s in self.stops.stops], [("1", "bus"), ("40001", "rail")])
        hit, more = self.stops.within(41.84, -87.64, 41.86, -87.62)
        self.assertEqual([s["name"] for s in hit], ["Garfield"])
        self.assertFalse(more)

    def test_resolve_prefers_the_current_shape(self):
        sh = self.shapes
        self.assertEqual(sh.resolve("pid:6351", 41.86, -87.6240).id, "68106351")
        on_north = 41.85, LON0 + 0.0002
        self.assertEqual(sh.resolve("route:Red", *on_north).id, "309200008")
        # Shared corridor: a train already on the southbound shape stays on it while within the offset limit.
        self.assertEqual(sh.resolve("route:Red", *on_north, prefer="309200007").id, "309200007")
        self.assertIsNone(sh.resolve("route:Pink", 41.85, LON0))
        self.assertIsNone(sh.resolve(None, 41.85, LON0))
        self.assertEqual(sh.resolve("pid:99999|route:1", 41.86, -87.6250).id, "68108085")   # unknown pattern

    def test_round_trip_keeps_candidates(self):
        import os, tempfile
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "s.json")
            self.shapes.save(p)
            back = type(self.shapes).load(p)
            self.assertEqual(back.candidates, self.shapes.candidates)
            q = os.path.join(d, "t.json")
            self.stops.save(q)
            self.assertEqual(ctagtfs.StopTable.load(q).stops, self.stops.stops)


class SnappingTest(unittest.TestCase):
    def test_trains_and_buses_get_motion_with_inferred_speed(self):
        table, stops = ctagtfs.build(gtfs_zip(), 0.0)
        salt = DailySalt(None, "America/Chicago")
        from livefeeds.transit.smoothing import Tracker
        tr = Tracker()
        b1 = ctabus.normalise(combined([bus("7971", lat="41.8600", lon="-87.6240", tmstmp="20261006 19:18:00")]),
                              salt, TS)
        tr.annotate(b1.vehicles, b1.trips, table, TS)
        self.assertEqual(b1.vehicles[0]["motion"]["shapeId"], "68106351")
        self.assertIsNone(b1.vehicles[0]["motion"]["speedMps"])
        b2 = ctabus.normalise(combined([bus("7971", lat="41.8610", lon="-87.6240", tmstmp="20261006 19:18:20")]),
                              salt, TS + 20)
        tr.annotate(b2.vehicles, b2.trips, table, TS + 20)
        m = b2.vehicles[0]["motion"]
        self.assertEqual(m["speedBasis"], "inferred")
        self.assertAlmostEqual(m["speedMps"], 111.2 / 20, delta=0.3)     # 0.001 deg of latitude in 20 s
        t1 = cta.normalise(tt_body({"red": [train("827", lat="41.8500", lon="-87.6300")]}), salt, TMST)
        tr.annotate(t1.vehicles, t1.trips, table, TMST)
        self.assertEqual(t1.vehicles[0]["motion"]["shapeId"], "309200007")
        for v in t1.vehicles + b2.vehicles:
            self.assertNotIn("pid", json.dumps(v))                       # lookup keys never reach records

    def test_stale_layer_freezes(self):
        sm = Smoother(1000.0)
        rec = {"id": "x", "timestamp": 100, "motion": {"shapeId": "s", "distM": 100.0, "t": 100, "speedMps": 10.0,
                                                       "speedBasis": "inferred"}}
        sm.observe(rec, 101.0, "fresh")
        sm.observe(rec, 130.0, "stale")
        self.assertTrue(sm.frozen)
        self.assertEqual(sm.distance(140.0), sm.distance(200.0))           # never animates while stale


class StopsEndpointTest(unittest.TestCase):
    def test_stops_served_with_cta_credit(self):
        table, stops = ctagtfs.build(gtfs_zip(), 0.0)
        table.stops = stops
        clock = Clock(TS + 5)
        area = Area("chicago", "Chicago", (41.64, -87.95, 42.08, -87.52), "America/Chicago", 3, ("ctabus",))
        relay = Relay(Config(), [area], fetch=FakeUpstream(combined([bus("7971")])), clock=clock,
                      shapes_fetch=lambda: (table, 0), source=CtaBusSource)
        relay.poll_once()
        server = make_server(relay, "127.0.0.1", 0)
        t = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True)
        t.start()
        try:
            base = "http://127.0.0.1:%d" % server.server_address[1]
            doc = json.loads(urllib.request.urlopen(base + "/v1/stops?bbox=41.84,-87.64,41.86,-87.62", timeout=5).read())
        finally:
            server.shutdown()
            server.server_close()
        self.assertEqual([s["name"] for s in doc["stops"]], ["Garfield"])
        self.assertEqual(doc["attribution"][0]["text"], "Data provided by Chicago Transit Authority")


if __name__ == "__main__":
    unittest.main()
