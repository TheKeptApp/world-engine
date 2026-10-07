import contextlib
import gzip
import http.client
import io
import json
import threading
import unittest

from livefeeds import rtd, tiles
from livefeeds.relay import SCHEMA
from livefeeds.server import make_server
from tests.common import (LAT_A, LAT_FAR, LAT_R, LON_A, LON_FAR, LON_R, T0, Clock, make_relay, sample_feed)


def bbox_around(lat, lon, pad=0.0002):
    return "%f,%f,%f,%f" % (lat - pad, lon - pad, lat + pad, lon + pad)


class ServerCase(unittest.TestCase):
    """A real server on an ephemeral port in front of a relay with a fake upstream and clock."""

    def setUp(self):
        self.clock = Clock()
        self.relay = make_relay(clock=self.clock)
        self.relay.poll_once()
        self.server = make_server(self.relay, "127.0.0.1", 0)
        self.thread = threading.Thread(target=self.server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True)
        self.thread.start()
        self.port = self.server.server_address[1]

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)

    def request(self, path, method="GET", headers=None, body=None):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        try:
            conn.request(method, path, body=body, headers=headers or {})
            resp = conn.getresponse()
            data = resp.read()
            hdrs = {k.lower(): v for k, v in resp.getheaders()}
            return resp.status, hdrs, data
        finally:
            conn.close()

    def get_json(self, path, headers=None):
        status, hdrs, data = self.request(path, headers=headers)
        if hdrs.get("content-encoding") == "gzip":
            data = gzip.decompress(data)
        return status, hdrs, json.loads(data) if data else None


class VehiclesEndpointTests(ServerCase):
    def test_bbox_returns_the_documented_envelope_and_vehicles(self):
        status, hdrs, doc = self.get_json("/v1/vehicles?bbox=" + bbox_around(LAT_A, LON_A))
        self.assertEqual(status, 200)
        self.assertEqual(hdrs["content-type"], "application/json; charset=utf-8")
        self.assertEqual(list(doc), ["schema", "live", "generatedAt", "feedTimestamp", "state", "stale",
                                     "pollIntervalSeconds", "area", "vehicles", "attribution"])
        self.assertEqual(doc["schema"], SCHEMA)
        self.assertIs(doc["live"], True)
        self.assertEqual((doc["generatedAt"], doc["feedTimestamp"]), (T0, T0))
        self.assertEqual((doc["state"], doc["stale"]), ("fresh", False))
        self.assertEqual(doc["pollIntervalSeconds"], 15)
        self.assertEqual(doc["area"]["z"], 14)
        self.assertTrue(doc["area"]["covered"])
        self.assertEqual(len(doc["vehicles"]), 2)                   # the two buses; rail and far bus are other tiles
        for v in doc["vehicles"]:
            self.assertEqual(list(v), ["id", "kind", "route", "routeName", "lat", "lon", "heading", "speedMps",
                                       "stopStatus", "timestamp", "ageSeconds", "source", "positionState", "basis", "motion"])
            self.assertEqual((v["kind"], v["route"], v["source"]), ("bus", "15", "rtd"))
        self.assertEqual([v["id"] for v in doc["vehicles"]], sorted(v["id"] for v in doc["vehicles"]))

    def test_tile_filtering_by_rectangle(self):
        _, _, one = self.get_json("/v1/vehicles?bbox=" + bbox_around(LAT_R, LON_R))
        self.assertEqual([(v["kind"], v["route"]) for v in one["vehicles"]], [("rail", "A")])
        _, _, two = self.get_json("/v1/vehicles?bbox=" + bbox_around(LAT_FAR, LON_FAR))
        self.assertEqual([v["route"] for v in two["vehicles"]], ["BOLT"])
        # a 2 x 1 rectangle spanning the rail tile and the bus tile returns all three
        _, _, both = self.get_json("/v1/vehicles?tiles=14/3412/6217/3413/6217")
        self.assertEqual(sorted(v["route"] for v in both["vehicles"]), ["15", "15", "A"])
        # an empty tile in the covered area
        _, _, empty = self.get_json("/v1/vehicles?tiles=14/3420/6217/3420/6217")
        self.assertEqual(empty["vehicles"], [])
        self.assertTrue(empty["area"]["covered"])

    def test_bbox_and_tiles_forms_agree_and_content_location_is_canonical(self):
        _, hdrs, by_bbox = self.get_json("/v1/vehicles?bbox=" + bbox_around(LAT_A, LON_A))
        canon = hdrs["content-location"]
        self.assertEqual(canon, "/v1/vehicles?tiles=14/3413/6217/3413/6217")
        _, hdrs2, by_tiles = self.get_json(canon)
        self.assertEqual(by_bbox, by_tiles)
        self.assertEqual(hdrs["etag"], hdrs2["etag"])               # identical views share a cache key

    def test_age_is_computed_at_serve_time(self):
        _, _, a = self.get_json("/v1/vehicles?tiles=14/3413/6217/3413/6217")
        self.clock.advance(20)
        _, _, b = self.get_json("/v1/vehicles?tiles=14/3413/6217/3413/6217")
        by_id = {v["id"]: v for v in a["vehicles"]}
        for v in b["vehicles"]:
            self.assertEqual(v["ageSeconds"], by_id[v["id"]]["ageSeconds"] + 20)
            self.assertEqual(v["timestamp"], by_id[v["id"]]["timestamp"])
        self.assertEqual(b["generatedAt"], a["generatedAt"] + 20)
        self.assertEqual(sorted(v["ageSeconds"] for v in a["vehicles"]), [5, 10])

    def test_caching_headers_etag_and_304(self):
        path = "/v1/vehicles?tiles=14/3413/6217/3413/6217"
        status, hdrs, _ = self.request(path)
        self.assertEqual(status, 200)
        self.assertEqual(hdrs["cache-control"], "public, max-age=10")
        self.assertTrue(hdrs["etag"].startswith('W/"'))
        self.assertIn("accept-encoding", hdrs["vary"].lower())
        status, hdrs304, body = self.request(path, headers={"If-None-Match": hdrs["etag"]})
        self.assertEqual((status, body), (304, b""))
        self.assertEqual(hdrs304["etag"], hdrs["etag"])
        self.assertEqual(hdrs304["cache-control"], "public, max-age=10")
        # the validator ignores the passage of seconds but not a new snapshot
        self.clock.advance(5)
        self.assertEqual(self.request(path, headers={"If-None-Match": hdrs["etag"]})[0], 304)
        self.clock.advance(25)
        self.relay.upstream.publish(sample_feed(int(self.clock())))
        self.relay.poll_once()
        status, new_hdrs, _ = self.request(path, headers={"If-None-Match": hdrs["etag"]})
        self.assertEqual(status, 200)
        self.assertNotEqual(new_hdrs["etag"], hdrs["etag"])
        # list form and "*" also match
        self.assertEqual(self.request(path, headers={"If-None-Match": '"x", ' + new_hdrs["etag"]})[0], 304)
        self.assertEqual(self.request(path, headers={"If-None-Match": "*"})[0], 304)

    def test_etag_changes_with_state_and_area(self):
        path = "/v1/vehicles?tiles=14/3413/6217/3413/6217"
        etag_fresh = self.request(path)[1]["etag"]
        self.clock.advance(100)                                      # pull is late: stale
        etag_stale = self.request(path)[1]["etag"]
        self.assertNotEqual(etag_fresh, etag_stale)
        self.assertNotEqual(etag_fresh, self.request("/v1/vehicles?tiles=14/3412/6217/3412/6217")[1]["etag"])

    def test_gzip_negotiation(self):
        path = "/v1/vehicles?tiles=14/3412/6217/3413/6217"
        _, plain_hdrs, plain = self.request(path)
        self.assertNotIn("content-encoding", plain_hdrs)
        status, hdrs, packed = self.request(path, headers={"Accept-Encoding": "gzip"})
        self.assertEqual(hdrs["content-encoding"], "gzip")
        self.assertEqual(gzip.decompress(packed), plain)
        self.assertLess(len(packed), len(plain))
        self.assertEqual(int(hdrs["content-length"]), len(packed))
        _, refused, _ = self.request(path, headers={"Accept-Encoding": "gzip;q=0"})
        self.assertNotIn("content-encoding", refused)

    def test_head_has_headers_and_no_body(self):
        path = "/v1/vehicles?tiles=14/3413/6217/3413/6217"
        status, hdrs, body = self.request(path, method="HEAD")
        self.assertEqual((status, body), (200, b""))
        _, _, full = self.request(path)
        self.assertEqual(int(hdrs["content-length"]), len(full))
        self.assertIn("etag", hdrs)

    def test_cors_and_options(self):
        _, hdrs, _ = self.request("/v1/vehicles?tiles=14/3413/6217/3413/6217")
        self.assertEqual(hdrs["access-control-allow-origin"], "*")
        status, hdrs, body = self.request("/v1/vehicles", method="OPTIONS")
        self.assertEqual((status, body), (204, b""))
        self.assertIn("GET", hdrs["access-control-allow-methods"])

    def test_outside_every_configured_area_is_empty_and_never_wakes_the_poller(self):
        calls = []
        orig = self.relay.touch
        self.relay.touch = lambda: calls.append(1) or orig()      # type: ignore[assignment]
        _, _, doc = self.get_json("/v1/vehicles?bbox=51.500,-0.130,51.505,-0.125")        # another country
        self.assertEqual(doc["vehicles"], [])
        self.assertFalse(doc["area"]["covered"])
        self.assertEqual(calls, [])
        self.get_json("/v1/vehicles?tiles=14/3413/6217/3413/6217")
        self.assertEqual(calls, [1])

    def test_bad_requests_are_400_json_with_codes(self):
        cases = {
            "/v1/vehicles": "bad-request",
            "/v1/vehicles?bbox=1,2,3,4&tiles=14/1/1/1/1": "bad-request",
            "/v1/vehicles?bbox=a,b,c,d": "bad-bbox",
            "/v1/vehicles?bbox=40,-105,39,-104": "bad-bbox",
            "/v1/vehicles?bbox=39,-106,40,-104": "area-too-large",
            "/v1/vehicles?tiles=14/0/0/10/10": "area-too-large",
            "/v1/vehicles?tiles=9/1/1/1/1": "bad-tiles",
            "/v1/vehicles?bbox=1,2,3,4&bbox=5,6,7,8": "bad-request",
        }
        for path, code in cases.items():
            status, hdrs, doc = self.get_json(path)
            self.assertEqual(status, 400, path)
            self.assertEqual(doc["error"]["code"], code, path)
            self.assertEqual(hdrs["cache-control"], "no-store")

    def test_unknown_path_405_and_414(self):
        status, _, doc = self.get_json("/nope")
        self.assertEqual((status, doc["error"]["code"]), (404, "not-found"))
        status, _, body = self.request("/v1/vehicles", method="POST", body=b"x")
        self.assertEqual(status, 405)
        self.assertEqual(json.loads(body)["error"]["code"], "method-not-allowed")
        self.assertEqual(self.request("/v1/vehicles?bbox=" + "1" * 600)[0], 414)


class StaleBehaviourTests(ServerCase):
    PATH = "/v1/vehicles?tiles=14/3413/6217/3413/6217"

    def test_stale_keeps_vehicles_and_flags_them(self):
        self.clock.advance(120)
        _, _, doc = self.get_json(self.PATH)
        self.assertEqual((doc["state"], doc["stale"]), ("stale", True))
        self.assertEqual(len(doc["vehicles"]), 2)
        self.assertEqual(doc["feedTimestamp"], T0)
        self.assertEqual(sorted(v["ageSeconds"] for v in doc["vehicles"]), [125, 130])

    def test_unavailable_drops_vehicles_but_still_answers(self):
        self.clock.advance(301)
        status, _, doc = self.get_json(self.PATH)
        self.assertEqual(status, 200)
        self.assertEqual((doc["state"], doc["stale"]), ("unavailable", True))
        self.assertEqual(doc["vehicles"], [])
        self.assertEqual(doc["feedTimestamp"], T0)
        self.assertTrue(doc["attribution"])

    def test_never_polled_is_unavailable_with_null_feed_timestamp(self):
        relay = make_relay(clock=self.clock)                          # no poll_once
        server = make_server(relay, "127.0.0.1", 0)
        t = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True)
        t.start()
        try:
            conn = http.client.HTTPConnection("127.0.0.1", server.server_address[1], timeout=10)
            conn.request("GET", self.PATH)
            doc = json.loads(conn.getresponse().read())
            conn.close()
        finally:
            server.shutdown()
            server.server_close()
        self.assertEqual((doc["state"], doc["feedTimestamp"], doc["vehicles"]), ("unavailable", None, []))

    def test_recovery(self):
        self.clock.advance(400)
        self.assertEqual(self.get_json(self.PATH)[2]["state"], "unavailable")
        self.relay.upstream.publish(sample_feed(int(self.clock())))
        self.relay._next_poll_at = 0
        self.relay.poll_once()
        _, _, doc = self.get_json(self.PATH)
        self.assertEqual(doc["state"], "fresh")
        self.assertEqual(len(doc["vehicles"]), 2)


class AttributionAndPrivacyTests(ServerCase):
    def all_paths(self):
        return [
            "/v1/vehicles?tiles=14/3413/6217/3413/6217",
            "/v1/vehicles?bbox=" + bbox_around(LAT_A, LON_A),
            "/v1/vehicles?bbox=51.500,-0.130,51.505,-0.125",            # outside coverage
            "/v1/vehicles?tiles=14/3420/6217/3420/6217",       # empty tile
            "/v1/vehicles",                                    # 400
            "/v1/vehicles?bbox=zzz",                           # 400
            "/v1/vehicles?tiles=14/0/0/10/10",                 # 400
            "/v1/status",
            "/missing",                                        # 404
        ]

    def test_attribution_is_in_every_json_response_exactly(self):
        expected = {"source": "rtd", "text": rtd.ATTRIBUTION["text"], "url": rtd.FEEDS_PAGE_URL,
                    "licenseUrl": rtd.LICENSE_URL}
        for path in self.all_paths():
            for headers in ({}, {"Accept-Encoding": "gzip"}):
                _, _, doc = self.get_json(path, headers)
                self.assertEqual(doc["attribution"], [expected], path)
                self.assertEqual(doc["schema"], SCHEMA, path)
        status, _, body = self.request("/v1/vehicles", method="POST", body=b"")
        self.assertEqual(json.loads(body)["attribution"], [expected])
        # also after the data has gone stale and unavailable
        for dt in (120, 400):
            self.clock.advance(dt)
            _, _, doc = self.get_json(self.all_paths()[0])
            self.assertEqual(doc["attribution"], [expected])

    def test_the_credit_names_rtd_without_marks_and_carries_the_non_endorsement_statement(self):
        text = rtd.ATTRIBUTION["text"]
        self.assertIn("not endorsed by, sponsored by or affiliated with RTD", text)
        self.assertIn("Unofficial", text)

    def test_raw_vehicle_ids_labels_and_trips_never_appear_in_any_response(self):
        blob = b""
        for path in self.all_paths():
            blob += self.request(path)[2]
        text = blob.decode("utf-8")
        for raw in ("BUS-1501", "BUS-1502", "RAIL-9", "BUS-FAR", "NR-1", "UNK-1", "T-1", "T-2", "T-3", "1501"):
            self.assertNotIn(raw, text)
        _, _, doc = self.get_json(self.all_paths()[0])
        for v in doc["vehicles"]:
            self.assertRegex(v["id"], r"^rtd:[0-9a-f]{12}$")

    def test_ids_are_stable_between_polls_within_the_service_day(self):
        path = "/v1/vehicles?tiles=14/3412/6217/3413/6217"
        ids1 = [v["id"] for v in self.get_json(path)[2]["vehicles"]]
        self.clock.advance(30)
        self.relay.upstream.publish(sample_feed(int(self.clock())))
        self.relay.poll_once()
        ids2 = [v["id"] for v in self.get_json(path)[2]["vehicles"]]
        self.assertEqual(ids1, ids2)
        self.assertEqual(len(ids1), 3)

    def test_no_client_information_is_logged_or_kept(self):
        err = io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()) as out:
            for path in self.all_paths():
                self.request(path)
        self.assertEqual(err.getvalue(), "")
        self.assertEqual(out.getvalue(), "")
        status = self.get_json("/v1/status")[2]["status"]
        text = json.dumps(status)
        self.assertNotIn("127.0.0.1", text)
        self.assertNotIn("3413", text)                                   # no request tiles are kept
        self.assertGreater(status["httpResponses"]["200"], 0)           # aggregate counts only
        self.assertGreater(status["httpResponses"]["400"], 0)

    def test_status_endpoint(self):
        status, hdrs, doc = self.get_json("/v1/status")
        self.assertEqual(status, 200)
        st = doc["status"]
        self.assertEqual(st["state"], "fresh")
        self.assertEqual(st["vehicleCounts"], {"bus": 3, "rail": 1})
        self.assertIn("droppedByReason", st)
        self.assertEqual(hdrs["cache-control"], "no-store")


class IdleWakeTests(ServerCase):
    def test_a_request_wakes_an_idle_poller_and_gets_fresh_data(self):
        self.relay.start()                                  # polls once at start (activity), then idles
        try:
            self.relay.wait_for_poll(self.relay.poll_count() - 1, 3)
            self.clock.advance(1000)                         # nobody asked for a long time: idle, data is old
            self.assertTrue(self.relay._idle(self.clock()))
            self.relay.upstream.publish(sample_feed(int(self.clock())))
            _, _, doc = self.get_json("/v1/vehicles?tiles=14/3413/6217/3413/6217")
            self.assertEqual(doc["state"], "fresh")          # the request waited for the wake-up poll
            self.assertEqual(doc["feedTimestamp"], T0 + 1000)
            self.assertEqual(len(doc["vehicles"]), 2)
        finally:
            self.relay.stop()


class KeepAliveTests(ServerCase):
    def test_two_requests_on_one_connection(self):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        try:
            for _ in range(2):
                conn.request("GET", "/v1/vehicles?tiles=14/3413/6217/3413/6217")
                resp = conn.getresponse()
                self.assertEqual(resp.status, 200)
                json.loads(resp.read())
            conn.request("GET", "/v1/vehicles?tiles=14/3413/6217/3413/6217",
                         headers={"If-None-Match": resp.getheader("ETag")})
            r3 = conn.getresponse()
            self.assertEqual((r3.status, r3.read()), (304, b""))
            conn.request("GET", "/v1/status")                            # connection still usable after a 304
            self.assertEqual(conn.getresponse().status, 200)
        finally:
            conn.close()


if __name__ == "__main__":
    unittest.main()


class ShapesEndpointTests(ServerCase):
    def setUp(self):
        super().setUp()
        from tests.test_transit import table
        self.relay._shapes = table()

    def test_shapes_by_id(self):
        status, hdrs, doc = self.get_json("/v1/shapes?ids=SH-15E,NOPE")
        self.assertEqual(status, 200)
        self.assertEqual([s["id"] for s in doc["shapes"]], ["SH-15E"])
        self.assertEqual(doc["missing"], ["NOPE"])
        self.assertIn("max-age=86400", hdrs["cache-control"])
        self.assertTrue(doc["attribution"])

    def test_shapes_needs_ids(self):
        self.assertEqual(self.get_json("/v1/shapes")[0], 400)
        many = ",".join("s%d" % i for i in range(51))
        self.assertEqual(self.get_json("/v1/shapes?ids=" + many)[0], 400)
