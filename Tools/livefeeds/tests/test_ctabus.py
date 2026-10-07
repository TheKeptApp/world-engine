"""CTA Bus Tracker adapter: batching, normalisation, key handling, relay integration (synthetic data, offline)."""

import datetime
import json
import unittest
from urllib.parse import parse_qs, urlparse

from livefeeds import ctabus
from livefeeds.fetch import FetchError, FetchResult
from livefeeds.relay import Area, Config, CtaBusSource, Relay
from livefeeds.salt import DailySalt
from tests.common import Clock, FakeUpstream

KEY = "not-a-real-key-0123456789"
# 2026-10-06 19:18:46 in Chicago is CDT (UTC-5).
TS = int(datetime.datetime(2026, 10, 7, 0, 18, 46, tzinfo=datetime.timezone.utc).timestamp())
CHICAGO = Area("chicago", "Chicago", (41.64, -87.95, 42.08, -87.52), "America/Chicago", 3, ("ctabus",))


def bus(vid, rt="1", lat="41.86793772379557", lon="-87.62419764200847", hdg="181", tmstmp="20261006 19:18:46"):
    """Shaped like a live getvehicles record (strings for coordinates, ints for pattern ids)."""
    return {"vid": vid, "tmstmp": tmstmp, "lat": lat, "lon": lon, "hdg": hdg, "pid": 6351, "rt": rt,
            "des": "34th/Michigan", "pdist": 10647, "dly": False, "tatripid": "348", "origtatripno": "280468930",
            "tablockid": "1 -755", "zone": "", "mode": 1, "psgld": "N/A", "stst": 68190, "stsd": "2026-10-06"}


def combined(vehicles, routes=({"rt": "1", "rtnm": "Bronzeville/Union Station"},), errors=None):
    r = {"vehicle": list(vehicles), "routes": list(routes)}
    if errors:
        r["error"] = errors
    return json.dumps({"bustime-response": r}).encode()


def answer(doc):
    body = json.dumps({"bustime-response": doc}).encode()
    return FetchResult(200, body, None, None, len(body))


class NormaliseTest(unittest.TestCase):
    def setUp(self):
        self.salt = DailySalt(None, "America/Chicago")

    def test_records_follow_the_relay_contract(self):
        n = ctabus.normalise(combined([bus("7971"), bus("8000", rt="X9", hdg="0", tmstmp="20261006 19:18:40")]),
                             self.salt, TS + 3)
        self.assertEqual(n.feed_timestamp, TS)
        self.assertEqual(len(n.vehicles), 2)
        by = {v["route"]: v for v in n.vehicles}
        one = by["1"]
        self.assertEqual(one["routeName"], "Bronzeville/Union Station")
        self.assertEqual((one["kind"], one["source"], one["heading"]), ("bus", "ctabus", 181.0))
        self.assertEqual((one["lat"], one["lon"]), (41.86794, -87.62420))
        self.assertIsNone(one["speedMps"])
        self.assertIsNone(one["stopStatus"])
        self.assertEqual(by["X9"]["routeName"], "X9")               # no name in the table: the code
        self.assertEqual(by["X9"]["timestamp"], TS - 6)
        for v in n.vehicles:
            self.assertTrue(v["id"].startswith("ctabus:"))
            self.assertNotIn("7971", v["id"])
            self.assertEqual(set(v), {"id", "kind", "route", "routeName", "lat", "lon", "heading", "speedMps",
                                      "stopStatus", "timestamp", "source"})   # no trip, block or pattern ids

    def test_drops_are_counted(self):
        body = combined([bus("1", lat=""), bus("2", lat="0", lon="0"), bus(""), bus("3", tmstmp="20261006 19:00:00"),
                         bus("4"), bus("4")])
        n = ctabus.normalise(body, self.salt, TS)
        self.assertEqual(len(n.vehicles), 1)
        self.assertEqual(n.dropped, {"noPosition": 1, "badPosition": 1, "noId": 1, "tooOld": 1, "duplicate": 1})

    def test_errors(self):
        no_bus = [{"rt": "zzz", "msg": "No data found for parameter"}]
        self.assertEqual(ctabus.normalise(combined([], errors=no_bus), self.salt, TS).vehicles, [])
        with self.assertRaises(FetchError) as cm:
            ctabus.normalise(combined([], errors=[{"msg": "Invalid API access key supplied"}]), self.salt, TS)
        self.assertEqual(cm.exception.status, 403)
        with self.assertRaises(ValueError):
            ctabus.normalise(b'{"other": 1}', self.salt, TS)

    def test_local_time(self):
        self.assertEqual(ctabus.local_time("20260115 12:00"),
                         int(datetime.datetime(2026, 1, 15, 18, 0, tzinfo=datetime.timezone.utc).timestamp()))
        self.assertIsNone(ctabus.local_time("garbage"))


class FetcherTest(unittest.TestCase):
    def routes(self, n):
        return [{"rt": str(i), "rtnm": "Route %d" % i, "rtclr": "#000", "rtdd": str(i)} for i in range(n)]

    def test_batches_of_ten_and_daily_routes(self):
        calls = []

        def get(url, ua, etag, lm, timeout):
            q = parse_qs(urlparse(url).query)
            calls.append((urlparse(url).path.rsplit("/", 1)[1], q))
            if url.split("?")[0].endswith("getroutes"):
                return answer({"routes": self.routes(23)})
            rts = q["rt"][0].split(",")
            return answer({"vehicle": [bus("v" + rts[0], rt=rts[0])],
                           "error": [{"rt": rts[-1], "msg": "No data found for parameter"}]})

        clock = Clock(TS)
        fetch = ctabus.fetcher(environ={ctabus.KEY_ENV: KEY}, get=get, clock=clock)
        res = fetch(None, None)
        self.assertEqual([c[0] for c in calls], ["getroutes", "getvehicles", "getvehicles", "getvehicles"])
        self.assertEqual([len(c[1]["rt"][0].split(",")) for c in calls[1:]], [10, 10, 3])
        self.assertEqual(calls[1][1]["tmres"], ["s"])
        doc = json.loads(res.body)["bustime-response"]
        self.assertEqual(len(doc["vehicle"]), 3)
        self.assertEqual(doc["routes"][0], {"rt": "0", "rtnm": "Route 0"})
        calls.clear()
        clock.advance(60)
        fetch(None, None)
        self.assertNotIn("getroutes", [c[0] for c in calls])         # routes cached for a day
        calls.clear()
        clock.advance(86400)
        fetch(None, None)
        self.assertEqual(calls[0][0], "getroutes")

    def test_key_never_in_errors(self):
        seen = []

        def get(url, *a):
            seen.append(url)
            raise FetchError("HTTP 500 for %s" % url, 500)

        with self.assertRaises(FetchError) as cm:
            ctabus.fetcher(environ={ctabus.KEY_ENV: KEY}, get=get)(None, None)
        self.assertIn(KEY, seen[0])
        self.assertNotIn(KEY, str(cm.exception))
        self.assertEqual(cm.exception.status, 500)

        def bad_key(url, *a):
            return answer({"error": [{"msg": "Invalid API access key supplied"}]})

        with self.assertRaises(FetchError) as cm:
            ctabus.fetcher(environ={ctabus.KEY_ENV: KEY}, get=bad_key)(None, None)
        self.assertEqual(cm.exception.status, 403)
        self.assertNotIn(KEY, str(cm.exception))
        with self.assertRaises(FetchError) as cm:
            ctabus.fetcher(environ={})(None, None)
        self.assertEqual(cm.exception.status, 401)


class RelayTest(unittest.TestCase):
    def test_relay_serves_buses_with_cta_credit(self):
        clock = Clock(TS + 5)
        up = FakeUpstream(combined([bus("7971")]))
        relay = Relay(Config(), [CHICAGO], fetch=up, clock=clock, source=CtaBusSource)
        self.assertEqual(relay.poll_once(), "updated")
        snap, state, _ = relay.view(clock())
        self.assertEqual(state, "fresh")
        self.assertEqual(len(snap.vehicles), 1)
        self.assertEqual(CtaBusSource.attribution["text"], "Data provided by Chicago Transit Authority")


if __name__ == "__main__":
    unittest.main()
