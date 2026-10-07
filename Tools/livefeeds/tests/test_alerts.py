"""NWS alerts layer (docs/live-world/alerts.md): offline tests with synthetic features (no network)."""

import json
import os
import tempfile
import unittest

from livefeeds import fetch
from livefeeds.alerts import nws

T = 1791380000  # 2026-10-07T13:33:20Z
CHI = {"id": "chicago", "states": ["IL", "IN"], "bbox": [41.1875, -88.5542, 42.5292, -86.9208]}
MIA = {"id": "miami", "states": ["FL"], "bbox": [25.1, -80.95, 26.45, -79.6]}


def iso(t):
    import datetime
    return datetime.datetime.fromtimestamp(t, datetime.timezone.utc).isoformat()


def feature(i, **kw):
    props = {"@id": "https://api.weather.gov/alerts/urn:test:%d" % i, "status": "Actual", "messageType": "Alert",
             "event": "Flood Warning", "severity": "Severe", "certainty": "Likely", "urgency": "Immediate",
             "headline": "Flood Warning issued by NWS Chicago IL", "description": "* WHAT...Flooding.\n\n* WHERE...Cook County.",
             "instruction": "Turn around, don't drown.", "sent": iso(T - 3600), "effective": iso(T - 3600),
             "expires": iso(T + 3600), "ends": None, "affectedZones": []}
    props.update(kw.pop("props", {}))
    geom = kw.pop("geometry", {"type": "Polygon", "coordinates": [[[-87.8, 41.8], [-87.6, 41.8], [-87.6, 42.0], [-87.8, 42.0], [-87.8, 41.8]]]})
    return {"type": "Feature", "id": props["@id"], "geometry": geom, "properties": props}


class InForceTests(unittest.TestCase):
    def snap(self, features, fetched=T - 60, zones=None):
        return nws.snapshot([CHI, MIA], features, T, fetched, None, (zones or {}).get)

    def test_an_alert_in_force_is_passed_through_verbatim(self):
        f = feature(1)
        doc = self.snap([f])
        self.assertEqual(doc["state"], "fresh")
        self.assertTrue(doc["live"] and doc["official"] and doc["basis"] == "observed")
        a = doc["alerts"][0]
        for k in ("event", "severity", "certainty", "urgency", "headline", "description", "instruction"):
            self.assertEqual(a[k], f["properties"][k], k)
        self.assertEqual(a["areas"], ["chicago"])
        self.assertEqual(a["link"], f["properties"]["@id"])
        self.assertEqual((a["source"], a["basis"], a["official"]), ("nws", "observed", True))
        self.assertEqual(a["label"], nws.LABEL)
        self.assertEqual(doc["attribution"][0]["source"], "nws")

    def test_expired_ended_cancelled_test_and_future_alerts_are_never_active(self):
        cases = [
            feature(2, props={"expires": iso(T - 1)}),
            feature(3, props={"expires": iso(T + 9999), "ends": iso(T - 10)}),
            feature(4, props={"messageType": "Cancel"}),
            feature(5, props={"status": "Test"}),
            feature(6, props={"status": "Exercise"}),
            feature(7, props={"effective": iso(T + 600), "sent": iso(T - 60)}),
        ]
        self.assertEqual(self.snap(cases)["alerts"], [])
        # An expired alert stays hidden even when the cache is stale and nothing newer arrived.
        self.assertEqual(nws.snapshot([CHI], [feature(8, props={"expires": iso(T - 1)})], T, T - 7200, None)["alerts"], [])

    def test_area_filter_and_zone_placement(self):
        far = feature(9, geometry={"type": "Polygon", "coordinates": [[[-105, 39.5], [-104.9, 39.5], [-104.9, 39.6], [-105, 39.5]]]})
        zoned = feature(10, geometry=None, props={"affectedZones": ["https://api.weather.gov/zones/forecast/FLZ173"]})
        zones = {"https://api.weather.gov/zones/forecast/FLZ173":
                 {"type": "Polygon", "coordinates": [[[-80.3, 25.7], [-80.1, 25.7], [-80.1, 25.9], [-80.3, 25.9], [-80.3, 25.7]]]}}
        # A polygon around the whole Chicago box still touches it (no vertex inside the box).
        around = feature(11, geometry={"type": "Polygon", "coordinates": [[[-90, 40], [-85, 40], [-85, 44], [-90, 44], [-90, 40]]]})
        doc = self.snap([far, zoned, around], zones=zones)
        got = {a["id"].rsplit(":", 1)[1]: (a["areas"], a["placedBy"]) for a in doc["alerts"]}
        self.assertEqual(got, {"10": (["miami"], "zones"), "11": (["chicago"], "polygon")})

    def test_state_follows_the_fetch_age(self):
        self.assertEqual(nws.snapshot([CHI], [], T, None, "x")["state"], "unavailable")
        self.assertEqual(nws.snapshot([CHI], [], T, T - nws.FRESH_SECONDS - 1, None)["state"], "stale")


class ClientTests(unittest.TestCase):
    def test_contact_comes_only_from_configuration(self):
        with tempfile.TemporaryDirectory() as d:
            missing = os.path.join(d, "none.json")
            with self.assertRaises(nws.ConfigError):
                nws.contact({}, missing)
            self.assertEqual(nws.contact({"NWS_CONTACT": "a@example.org"}, missing), "a@example.org")
            cfg = os.path.join(d, "livefeeds.json")
            with open(cfg, "w") as fh:
                json.dump({"nwsContact": "b@example.org"}, fh)
            self.assertEqual(nws.contact({}, cfg), "b@example.org")
        self.assertIn("contact: a@example.org", nws.user_agent("a@example.org"))
        self.assertNotIn("@", nws.USER_AGENT_BASE)

    def test_cache_headers_set_the_next_request(self):
        self.assertEqual(nws.max_age({"Cache-Control": "public, max-age=30, s-maxage=30"}, T), 30)
        self.assertIsNone(nws.max_age({}, T))

    def test_polls_no_faster_than_allowed_and_backs_off_when_refused(self):
        calls = []
        now = [T]

        def ok(url, lm=None):
            calls.append(url)
            body = json.dumps({"type": "FeatureCollection", "features": [feature(1)]}).encode()
            return fetch.FetchResult(200, body, None, "Wed, 07 Oct 2026 13:00:00 GMT", len(body)), {"Cache-Control": "max-age=30"}

        with tempfile.TemporaryDirectory() as d:
            s = nws.AlertStore(d, ["IL"], getter=ok, clock=lambda: now[0])
            feats, fetched, err = s.active()
            self.assertEqual((len(feats), fetched, err), (1, T, None))
            now[0] = T + 30
            s.active()                       # max-age 30 is under the 60 s floor: no second request yet
            now[0] = T + 61
            s.active()
            self.assertEqual(len(calls), 2)

            def refused(url, lm=None):
                raise fetch.FetchError("HTTP 403", 403)
            s2 = nws.AlertStore(d, ["IL"], getter=refused, clock=lambda: now[0])
            now[0] = T + 200
            feats, _, err = s2.active()
            self.assertIn("needsHuman", err)
            self.assertEqual(len(feats), 1)  # the last good response is kept (and still filtered by time)


if __name__ == "__main__":
    unittest.main()
