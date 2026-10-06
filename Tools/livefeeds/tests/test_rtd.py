import gzip
import hashlib
import io
import os
import ssl
import tempfile
import threading
import unittest
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from livefeeds import fetch, rtd
from livefeeds.fetch import FetchError
from livefeeds.gtfsrt import decode_feed
from livefeeds.salt import DailySalt
from livefeeds.zipstream import StreamUnsupported, extract_member
from tests import pbenc
from tests.common import T0, sample_feed, sample_routes

ROUTES_TXT = ("﻿route_id,agency_id,route_short_name,route_long_name,route_type\n"
              "15,X,15,Synthetic Street,3\n"
              "A,X,A,Synthetic Rail,2\n"
              "L1,X,L,Synthetic Light Rail,0\n"
              "BOAT,X,B,Synthetic Boat,4\n"
              "EXT,X,E,Extended bus type,714\n"
              "BAD,X,B,Not a number,zz\n"
              ",X,N,No id,3\n")


def pseudo_random_bytes(n: int) -> bytes:
    """Deterministic, incompressible filler."""
    out = bytearray()
    block = b"seed"
    while len(out) < n:
        block = hashlib.sha256(block).digest()
        out += block
    return bytes(out[:n])


class Unseekable(io.RawIOBase):
    """Forces zipfile to write data descriptors (flag bit 3), like a streamed zip."""

    def __init__(self):
        self.buf = bytearray()

    def writable(self):
        return True

    def seekable(self):
        return False

    def write(self, b):
        self.buf += b
        return len(b)


def build_zip(members, streamed: bool, compression=zipfile.ZIP_DEFLATED) -> bytes:
    sink = Unseekable() if streamed else io.BytesIO()
    with zipfile.ZipFile(sink, "w", compression) as z:
        for name, data in members:
            z.writestr(name, data)
    return bytes(sink.buf) if streamed else sink.getvalue()


class NormaliseTests(unittest.TestCase):
    def setUp(self):
        self.salt = DailySalt(None, "America/Denver", 3)
        self.feed = decode_feed(sample_feed(T0))
        self.result = rtd.normalise(self.feed, sample_routes(), self.salt, T0)

    def test_kept_and_dropped(self):
        self.assertEqual(len(self.result.vehicles), 4)
        self.assertEqual(sorted((v["kind"], v["route"]) for v in self.result.vehicles),
                         [("bus", "15"), ("bus", "15"), ("bus", "BOLT"), ("rail", "A")])
        self.assertEqual(self.result.dropped, {"noRoute": 1, "unknownRoute": 1, "otherMode": 1, "tooOld": 1,
                                               "badPosition": 1, "noPosition": 1})
        self.assertEqual(self.result.unknown_routes, {"ZZZ"})
        self.assertEqual(self.result.feed_timestamp, T0)

    def test_record_fields_and_order(self):
        by_route = {(v["route"], v["stopStatus"]): v for v in self.result.vehicles}
        bus = by_route[("15", "inTransit")]
        self.assertEqual(list(bus), ["id", "kind", "route", "routeName", "lat", "lon", "heading", "speedMps",
                                     "stopStatus", "timestamp", "source"])
        self.assertEqual((bus["kind"], bus["route"], bus["routeName"]), ("bus", "15", "15"))
        self.assertEqual((bus["lat"], bus["lon"]), (39.75, -104.99))
        self.assertEqual((bus["heading"], bus["speedMps"]), (90.0, 5.5))
        self.assertEqual((bus["timestamp"], bus["source"]), (T0 - 10, "rtd"))
        self.assertEqual(by_route[("15", "stopped")]["stopStatus"], "stopped")
        self.assertIsNone(by_route[("15", "stopped")]["speedMps"])
        rail = by_route[("A", "incoming")]
        self.assertEqual((rail["kind"], rail["heading"]), ("rail", 45.0))

    def test_heading_stays_below_360(self):
        far = [v for v in self.result.vehicles if v["route"] == "BOLT"][0]
        self.assertEqual(far["heading"], 0.0)       # 359.97 rounds to 360.0, wrapped to 0.0

    def test_no_raw_identifiers_leak(self):
        text = repr(self.result.vehicles)
        for raw in ("BUS-1501", "BUS-1502", "RAIL-9", "BUS-FAR", "1501", "T-1", "T-3"):
            self.assertNotIn(raw, text)
        self.assertEqual(len({v["id"] for v in self.result.vehicles}), 4)

    def test_sorted_by_id_and_stable_across_runs(self):
        ids = [v["id"] for v in self.result.vehicles]
        self.assertEqual(ids, sorted(ids))
        again = rtd.normalise(self.feed, sample_routes(), self.salt, T0 + 30)
        self.assertEqual(ids, [v["id"] for v in again.vehicles])

    def test_missing_vehicle_timestamp_falls_back_to_feed_time(self):
        vp = pbenc.vehicle_position(trip_id="t", route_id="15", vehicle_id="V1", lat=39.75, lon=-104.99)
        feed = decode_feed(pbenc.encode_feed(T0, [pbenc.entity("e", vp)]))
        out = rtd.normalise(feed, sample_routes(), self.salt, T0 + 5)
        self.assertEqual(out.vehicles[0]["timestamp"], T0)

    def test_missing_feed_timestamp_falls_back_to_now(self):
        vp = pbenc.vehicle_position(trip_id="t", route_id="15", vehicle_id="V1", lat=39.75, lon=-104.99,
                                    timestamp=T0 - 5)
        feed = decode_feed(pbenc.encode_feed(None, [pbenc.entity("e", vp)]))
        out = rtd.normalise(feed, sample_routes(), self.salt, T0)
        self.assertEqual(out.feed_timestamp, T0)
        self.assertEqual(len(out.vehicles), 1)

    def test_entity_id_used_when_vehicle_id_absent_and_nothing_when_both_absent(self):
        vp = pbenc.vehicle_position(trip_id="t", route_id="15", lat=39.75, lon=-104.99, timestamp=T0)
        out = rtd.normalise(decode_feed(pbenc.encode_feed(T0, [pbenc.entity("ent-1", vp)])),
                            sample_routes(), self.salt, T0)
        self.assertEqual(len(out.vehicles), 1)
        out = rtd.normalise(decode_feed(pbenc.encode_feed(T0, [pbenc.entity("", vp)])),
                            sample_routes(), self.salt, T0)
        self.assertEqual(out.dropped, {"noId": 1})

    def test_bearing_zero_is_a_placeholder_and_becomes_null(self):
        def heading(bearing):
            vp = pbenc.vehicle_position(trip_id="t", route_id="15", vehicle_id="V1", lat=39.75, lon=-104.99,
                                        bearing=bearing, timestamp=T0)
            return rtd.normalise(decode_feed(pbenc.encode_feed(T0, [pbenc.entity("e", vp)])),
                                 sample_routes(), self.salt, T0).vehicles[0]["heading"]
        self.assertIsNone(heading(0.0))
        self.assertIsNone(heading(None))
        self.assertEqual(heading(0.5), 0.5)
        self.assertEqual(heading(180.0), 180.0)
        self.assertEqual(heading(360.0), 0.0)        # a genuine report that wraps to north stays a number

    def test_invalid_speed_and_bearing_become_null(self):
        vp = pbenc.vehicle_position(trip_id="t", route_id="15", vehicle_id="V1", lat=39.75, lon=-104.99,
                                    bearing=720.0, speed=-3.0, timestamp=T0)
        v = rtd.normalise(decode_feed(pbenc.encode_feed(T0, [pbenc.entity("e", vp)])),
                          sample_routes(), self.salt, T0).vehicles[0]
        self.assertIsNone(v["heading"])
        self.assertIsNone(v["speedMps"])

    def test_max_vehicle_age_is_configurable(self):
        out = rtd.normalise(self.feed, sample_routes(), self.salt, T0, max_vehicle_age=2000)
        self.assertNotIn("tooOld", out.dropped)
        self.assertEqual(len(out.vehicles), 5)


class RouteTableTests(unittest.TestCase):
    def test_route_kind(self):
        for t in (0, 1, 2, 5, 7, 12, 100, 109, 402, 900, 1):
            self.assertEqual(rtd.route_kind(t), "rail", t)
        for t in (3, 11, 200, 714, 800):
            self.assertEqual(rtd.route_kind(t), "bus", t)
        for t in (4, 6, 1000, 1100, -1):
            self.assertIsNone(rtd.route_kind(t), t)

    def test_parse_routes_txt(self):
        r = rtd.Routes.from_routes_txt(ROUTES_TXT, T0)
        self.assertEqual(len(r), 5)
        self.assertEqual(r.get("15"), ("15", "bus"))
        self.assertEqual(r.get("A"), ("A", "rail"))
        self.assertEqual(r.get("L1"), ("L", "rail"))
        self.assertEqual(r.get("BOAT"), ("B", None))
        self.assertEqual(r.get("EXT"), ("E", "bus"))
        self.assertIsNone(r.get("BAD"))

    def test_save_and_load(self):
        r = rtd.Routes.from_routes_txt(ROUTES_TXT, T0)
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "sub", "routes.json")
            r.save(p)
            back = rtd.Routes.load(p)
            self.assertEqual(back.table, r.table)
            self.assertEqual(back.fetched_at, T0)
            with open(p, "w") as f:
                f.write("{broken")
            self.assertIsNone(rtd.Routes.load(p))
            self.assertIsNone(rtd.Routes.load(os.path.join(d, "missing.json")))


class ZipStreamTests(unittest.TestCase):
    MEMBERS = [("trips.txt", b"t" * 5000), ("agency.txt", b"agency\n"), ("routes.txt", ROUTES_TXT.encode("utf-8")),
               ("stop_times.txt", pseudo_random_bytes(300_000))]

    def reader(self, data):
        bio = io.BytesIO(data)
        return bio, bio.read

    def test_streamed_zip_with_data_descriptors(self):
        data = build_zip(self.MEMBERS, streamed=True)
        self.assertEqual(data[6] & 0x08, 0x08)       # flag bit 3 set on the first entry
        bio, read = self.reader(data)
        self.assertEqual(extract_member(read, "routes.txt"), ROUTES_TXT.encode("utf-8"))
        self.assertLess(bio.tell(), 100_000)         # stopped well before the big member

    def test_seekable_zip_and_stored_members(self):
        for comp in (zipfile.ZIP_DEFLATED, zipfile.ZIP_STORED):
            data = build_zip(self.MEMBERS, streamed=False, compression=comp)
            _, read = self.reader(data)
            self.assertEqual(extract_member(read, "routes.txt", max_stream_bytes=1_000_000),
                             ROUTES_TXT.encode("utf-8"))

    def test_member_not_present_returns_none(self):
        data = build_zip(self.MEMBERS[:2], streamed=True)
        _, read = self.reader(data)
        self.assertIsNone(extract_member(read, "routes.txt"))

    def test_budget_exceeded_is_unsupported(self):
        data = build_zip([("big.bin", pseudo_random_bytes(400_000)), ("routes.txt", b"x")], streamed=False,
                         compression=zipfile.ZIP_STORED)
        _, read = self.reader(data)
        with self.assertRaises(StreamUnsupported):
            extract_member(read, "routes.txt", max_stream_bytes=100_000)

    def test_garbage_and_truncation_are_unsupported(self):
        for data in (b"not a zip at all", build_zip(self.MEMBERS, streamed=True)[:300]):
            _, read = self.reader(data)
            with self.assertRaises(StreamUnsupported):
                extract_member(read, "routes.txt")


class UpstreamHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def do_GET(self):  # noqa: N802
        srv = self.server
        srv.seen.append({"path": self.path, "ua": self.headers.get("User-Agent"),
                         "inm": self.headers.get("If-None-Match"), "ae": self.headers.get("Accept-Encoding")})
        if self.path == "/feed.pb":
            if self.headers.get("If-None-Match") == '"e1"':
                self.send_response(304)
                self.send_header("ETag", '"e1"')
                self.end_headers()
                return
            body = srv.feed_body
            if srv.gzip:
                body = gzip.compress(body)
            self.send_response(200)
            self.send_header("ETag", '"e1"')
            self.send_header("Last-Modified", "Mon, 01 Jan 2026 00:00:00 GMT")
            if srv.gzip:
                self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/busy":
            self.send_response(503)
            self.send_header("Retry-After", "120")
            self.send_header("Content-Length", "0")
            self.end_headers()
        elif self.path == "/denied":
            self.send_response(403)
            self.send_header("Content-Length", "0")
            self.end_headers()
        elif self.path == "/huge":
            self.send_response(200)
            self.send_header("Content-Length", str(10_000))
            self.end_headers()
            self.wfile.write(b"x" * 10_000)
        elif self.path == "/moved.zip":
            self.send_response(308)
            self.send_header("Location", "/static.zip")
            self.send_header("Content-Length", "0")
            self.end_headers()
        elif self.path == "/static.zip":
            data = srv.zip_bytes
            self.send_response(200)
            self.send_header("Content-Type", "application/zip")          # no Content-Length, ignores Range
            self.send_header("Connection", "close")
            self.end_headers()
            self.close_connection = True
            try:
                for i in range(0, len(data), 16384):
                    self.wfile.write(data[i:i + 16384])
            except (BrokenPipeError, ConnectionResetError):
                pass
        else:
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()


class HttpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv = ThreadingHTTPServer(("127.0.0.1", 0), UpstreamHandler)
        cls.srv.daemon_threads = True
        cls.srv.seen = []
        cls.srv.gzip = False
        cls.srv.feed_body = sample_feed(T0)
        cls.srv.zip_bytes = build_zip(ZipStreamTests.MEMBERS + [("shapes.txt", pseudo_random_bytes(3_000_000))],
                                      streamed=True)
        cls.thread = threading.Thread(target=cls.srv.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = "http://127.0.0.1:%d" % cls.srv.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()
        cls.srv.server_close()

    def setUp(self):
        self.srv.seen.clear()
        self.srv.gzip = False

    def test_honest_user_agent_and_conditional_get(self):
        r = fetch.http_get(self.base + "/feed.pb")
        self.assertEqual(r.status, 200)
        self.assertEqual(r.etag, '"e1"')
        self.assertEqual(r.wire_bytes, len(self.srv.feed_body))
        self.assertEqual(len(decode_feed(r.body).vehicles), 10)
        self.assertEqual(self.srv.seen[0]["ua"], "WorldEngine-livefeeds-prototype/0.1")
        self.assertNotIn("Mozilla", self.srv.seen[0]["ua"])
        self.assertEqual(self.srv.seen[0]["ae"], "gzip")
        again = fetch.http_get(self.base + "/feed.pb", etag=r.etag, last_modified=r.last_modified)
        self.assertEqual((again.status, again.body), (304, None))
        self.assertEqual(self.srv.seen[1]["inm"], '"e1"')

    def test_gzip_body_is_decoded_and_wire_size_is_compressed_size(self):
        self.srv.gzip = True
        r = fetch.http_get(self.base + "/feed.pb")
        self.assertEqual(r.body, self.srv.feed_body)
        self.assertLess(r.wire_bytes, len(self.srv.feed_body))

    def test_errors(self):
        with self.assertRaises(FetchError) as cm:
            fetch.http_get(self.base + "/busy")
        self.assertEqual((cm.exception.status, cm.exception.retry_after), (503, 120.0))
        with self.assertRaises(FetchError) as cm:
            fetch.http_get(self.base + "/denied")
        self.assertEqual(cm.exception.status, 403)
        with self.assertRaises(FetchError) as cm:
            fetch.http_get(self.base + "/huge", max_bytes=100)
        self.assertIn("larger", str(cm.exception))
        with self.assertRaises(FetchError) as cm:
            fetch.http_get("http://127.0.0.1:1/unreachable", timeout=2)
        self.assertIsNone(cm.exception.status)

    def test_fetch_routes_reads_only_the_start_of_a_big_zip_through_a_redirect(self):
        routes, downloaded = rtd.fetch_routes(self.base + "/moved.zip", clock=lambda: T0)
        self.assertEqual(routes.get("A"), ("A", "rail"))
        self.assertEqual(routes.fetched_at, T0)
        self.assertLess(downloaded, 200_000)
        self.assertLess(downloaded, len(self.srv.zip_bytes) / 10)
        self.assertEqual({s["ua"] for s in self.srv.seen}, {"WorldEngine-livefeeds-prototype/0.1"})

    def test_fetch_routes_falls_back_to_full_download_when_stream_is_unsupported(self):
        zbytes = build_zip([("shapes.txt", pseudo_random_bytes(2_500_000)), ("routes.txt", ROUTES_TXT.encode())],
                           streamed=False, compression=zipfile.ZIP_STORED)
        old = self.srv.zip_bytes
        self.srv.zip_bytes = zbytes
        try:
            routes, downloaded = rtd.fetch_routes(self.base + "/static.zip")
        finally:
            self.srv.zip_bytes = old
        self.assertEqual(routes.get("15"), ("15", "bus"))
        self.assertGreater(downloaded, 2_500_000)

    def test_fetch_routes_without_routes_txt_fails_cleanly(self):
        old = self.srv.zip_bytes
        self.srv.zip_bytes = build_zip([("agency.txt", b"a")], streamed=True)
        try:
            with self.assertRaises(FetchError):
                rtd.fetch_routes(self.base + "/static.zip")
        finally:
            self.srv.zip_bytes = old


class TlsTests(unittest.TestCase):
    def test_context_always_verifies(self):
        ctx = fetch.ssl_context()
        self.assertEqual(ctx.verify_mode, ssl.CERT_REQUIRED)
        self.assertTrue(ctx.check_hostname)

    def test_certificate_failure_message_has_a_hint(self):
        err = fetch._network_error(ssl.SSLCertVerificationError("unable to get local issuer certificate"))
        self.assertIn("SSL_CERT_FILE", str(err))
        self.assertIsNone(err.status)


class AttributionTests(unittest.TestCase):
    def test_text_and_links(self):
        a = rtd.ATTRIBUTION
        self.assertEqual(a["source"], "rtd")
        self.assertIn("Regional Transportation District (RTD)", a["text"])
        self.assertIn("not endorsed by, sponsored by or affiliated with RTD", a["text"])
        self.assertIn("not those of RTD", a["text"])
        self.assertTrue(a["licenseUrl"].endswith("/gtfs-realtime-license-agreement"))
        self.assertTrue(a["url"].startswith("https://www.rtd-denver.com/"))
        self.assertNotIn("logo", a["text"].lower())


if __name__ == "__main__":
    unittest.main()
