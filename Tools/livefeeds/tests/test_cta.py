"""CTA Train Tracker adapter: normalisation, key handling, relay and server integration (synthetic data, offline)."""

import datetime
import json
import tempfile
import threading
import unittest
import urllib.request

from livefeeds import cta
from livefeeds.fetch import FetchError, FetchResult
from livefeeds.relay import Area, Config, CtaSource, Relay
from livefeeds.salt import DailySalt
from livefeeds.server import make_server
from tests.common import Clock, FakeUpstream

KEY = "not-a-real-key-0123456789"


def tt_body(trains_by_route, tmst="2026-10-06T18:57:08", err="0"):
    """A synthetic Train Tracker answer in the shape the live API returns (strings everywhere, lower-case routes,
    one train as an object rather than a list, a route without trains as null)."""
    routes = []
    for name, trains in trains_by_route.items():
        routes.append({"@name": name, "train": trains})
    return json.dumps({"ctatt": {"tmst": tmst, "errCd": err, "errNm": None if err == "0" else "err",
                                 "route": routes}}).encode()


def train(rn, lat="41.77498", lon="-87.6271", heading="321", prdt="2026-10-06T18:57:00", is_app="0"):
    return {"rn": rn, "destSt": "30173", "destNm": "Howard", "trDr": "1", "nextStaId": "40910",
            "nextStpId": "30177", "nextStaNm": "63rd", "prdt": prdt, "arrT": "2026-10-06T18:58:00",
            "isApp": is_app, "isDly": "0", "flags": None, "lat": lat, "lon": lon, "heading": heading}


# 2026-10-06 18:57:08 in Chicago is CDT (UTC-5): 23:57:08Z.
TMST = int(datetime.datetime(2026, 10, 6, 23, 57, 8, tzinfo=datetime.timezone.utc).timestamp())
CHICAGO = Area("chicago", "Chicago", (41.64, -87.95, 42.08, -87.52), "America/Chicago", 3, ("cta",))


class NormaliseTest(unittest.TestCase):
    def setUp(self):
        self.salt = DailySalt(None, "America/Chicago")

    def test_records_follow_the_relay_contract(self):
        body = tt_body({"red": [train("827", is_app="1"), train("828", heading="0")],
                        "brn": train("401"), "y": None})
        n = cta.normalise(body, self.salt, TMST)
        self.assertEqual(n.feed_timestamp, TMST)
        self.assertEqual(len(n.vehicles), 3)
        by_route = {v["route"]: v for v in n.vehicles if v["route"] != "Red"}
        brown = by_route["Brn"]
        self.assertEqual(brown["routeName"], "Brown")
        self.assertEqual(brown["kind"], "rail")
        self.assertEqual(brown["source"], "cta")
        self.assertIsNone(brown["speedMps"])
        self.assertEqual(brown["timestamp"], TMST - 8)
        red = sorted((v for v in n.vehicles if v["route"] == "Red"), key=lambda v: v["heading"])
        self.assertEqual(red[0]["heading"], 0.0)       # CTA's 0 is a real bearing (no placeholder seen); kept
        self.assertEqual(red[1]["stopStatus"], "incoming")
        self.assertIsNone(red[0]["stopStatus"])
        for v in n.vehicles:
            self.assertTrue(v["id"].startswith("cta:"))
            self.assertNotIn("827", v["id"])           # run numbers are salted, never served
        self.assertEqual([v["id"] for v in n.vehicles], sorted(v["id"] for v in n.vehicles))

    def test_drops_are_counted(self):
        body = tt_body({"red": [train("1", lat=""), train("2", lat="0", lon="0"), train("", lat="41.9"),
                                train("3", prdt="2026-10-06T18:40:00")],
                        "xyz": [train("9")]})
        n = cta.normalise(body, self.salt, TMST)
        self.assertEqual(n.vehicles, [])
        self.assertEqual(n.dropped, {"noPosition": 1, "badPosition": 1, "noId": 1, "tooOld": 1, "unknownRoute": 1})

    def test_api_errors(self):
        with self.assertRaises(FetchError) as cm:
            cta.normalise(tt_body({}, err="101"), self.salt, TMST)
        self.assertEqual(cm.exception.status, 403)        # invalid key: hard error, 15-minute backoff
        with self.assertRaises(FetchError) as cm:
            cta.normalise(tt_body({}, err="500"), self.salt, TMST)
        self.assertIsNone(cm.exception.status)
        with self.assertRaises(ValueError):
            cta.normalise(b'{"other": 1}', self.salt, TMST)

    def test_local_time_handles_standard_time(self):
        # January: CST (UTC-6).
        self.assertEqual(cta.local_time("2026-01-15T12:00:00"),
                         int(datetime.datetime(2026, 1, 15, 18, 0, tzinfo=datetime.timezone.utc).timestamp()))
        self.assertIsNone(cta.local_time("garbage"))


class KeyHandlingTest(unittest.TestCase):
    def test_key_is_read_from_the_environment_and_never_in_errors(self):
        seen = []

        def get(url, ua, etag, lm, timeout):
            seen.append(url)
            raise FetchError("HTTP 500 for %s" % url, 500)

        fetch = cta.fetcher(environ={cta.KEY_ENV: KEY}, get=get)
        with self.assertRaises(FetchError) as cm:
            fetch(None, None)
        self.assertIn(KEY, seen[0])
        self.assertIn("rt=Red%2CBlue%2CBrn%2CG%2COrg%2CP%2CPink%2CY", seen[0])
        self.assertNotIn(KEY, str(cm.exception))
        self.assertEqual(cm.exception.status, 500)

        def boom(url, *a):
            raise RuntimeError(url)

        with self.assertRaises(FetchError) as cm:
            cta.fetcher(environ={cta.KEY_ENV: KEY}, get=boom)(None, None)
        self.assertNotIn(KEY, str(cm.exception))

    def test_missing_key_is_a_hard_error(self):
        with self.assertRaises(FetchError) as cm:
            cta.fetcher(environ={})(None, None)
        self.assertEqual(cm.exception.status, 401)


class RelayAndServerTest(unittest.TestCase):
    def test_relay_serves_cta_with_cta_credit_only(self):
        clock = Clock(TMST + 5)
        up = FakeUpstream(tt_body({"red": [train("827", lat="41.8781", lon="-87.6298")]}))
        with tempfile.TemporaryDirectory() as d:
            relay = Relay(Config(cache_dir=d), [CHICAGO], fetch=up, clock=clock, source=CtaSource)
            self.assertEqual(relay.poll_once(), "updated")
            snap, state, _ = relay.view(clock())
            self.assertEqual(state, "fresh")
            server = make_server(relay, "127.0.0.1", 0)
            t = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True)
            t.start()
            try:
                url = "http://127.0.0.1:%d/v1/vehicles?bbox=41.87,-87.64,41.88,-87.62" % server.server_address[1]
                doc = json.loads(urllib.request.urlopen(url, timeout=5).read())
            finally:
                server.shutdown()
                server.server_close()
            self.assertEqual(len(doc["vehicles"]), 1)
            self.assertEqual(doc["vehicles"][0]["routeName"], "Red")
            self.assertTrue(doc["live"])
            self.assertEqual(doc["attribution"], [cta.ATTRIBUTION])
            self.assertEqual(doc["attribution"][0]["text"], "Data provided by Chicago Transit Authority")

    def test_error_in_a_200_body_keeps_the_last_snapshot(self):
        clock = Clock(TMST + 5)
        up = FakeUpstream(tt_body({"red": [train("827")]}))
        relay = Relay(Config(), [CHICAGO], fetch=up, clock=clock, source=CtaSource)
        relay.poll_once()
        up.publish(tt_body({}, err="102"))
        clock.advance(40)
        self.assertEqual(relay.poll_once(), "error")
        self.assertIn("CTA error 102", relay.last_error)
        self.assertEqual(len(relay.view(clock())[0].vehicles), 1)
        self.assertGreaterEqual(relay._next_poll_at - clock(), 900)     # quota: hard backoff


if __name__ == "__main__":
    unittest.main()
