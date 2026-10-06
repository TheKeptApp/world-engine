import json
import os
import tempfile
import unittest

from livefeeds import rtd
from livefeeds.fetch import FetchError
from livefeeds.relay import Config, MIN_POLL_INTERVAL, load_areas
from tests.common import AREAS_JSON, T0, Clock, FakeUpstream, make_relay, sample_feed


class PollTests(unittest.TestCase):
    def test_first_poll_publishes_a_snapshot(self):
        r = make_relay()
        self.assertEqual(r.view(T0)[1:], ("unavailable", "no-data"))
        self.assertEqual(r.poll_once(), "updated")
        snap, state, reason = r.view(T0)
        self.assertEqual((state, reason), ("fresh", "ok"))
        self.assertEqual(snap.feed_timestamp, T0)
        self.assertEqual(snap.counts, {"bus": 3, "rail": 1})
        self.assertEqual(r.upstream.calls[0], (None, None))
        self.assertEqual(r.stats["bytes"], len(r.upstream.body))

    def test_conditional_request_and_304(self):
        r = make_relay()
        r.poll_once()
        r.clock.advance(31)
        self.assertEqual(r.poll_once(), "unchanged")
        self.assertEqual(r.upstream.calls[1][0], r.upstream.etag)       # sent If-None-Match
        self.assertEqual(r.stats["http304"], 1)
        snap, state, _ = r.view(r.clock())
        self.assertEqual(state, "fresh")                                # a 304 is a good pull
        self.assertEqual(snap.seq, 1)

    def test_new_data_replaces_snapshot_and_old_or_equal_timestamps_do_not(self):
        r = make_relay()
        r.poll_once()
        r.clock.advance(30)
        r.upstream.publish(sample_feed(T0 + 30))
        self.assertEqual(r.poll_once(), "updated")
        self.assertEqual(r.view(r.clock())[0].seq, 2)
        r.clock.advance(30)
        r.upstream.publish(sample_feed(T0 + 30))        # same header timestamp, new validator
        self.assertEqual(r.poll_once(), "unchanged")
        r.clock.advance(30)
        r.upstream.publish(sample_feed(T0 - 100))       # an older file (CDN lag)
        self.assertEqual(r.poll_once(), "unchanged")
        snap = r.view(r.clock())[0]
        self.assertEqual((snap.seq, snap.feed_timestamp), (2, T0 + 30))

    def test_poll_interval_has_a_floor(self):
        with self.assertRaises(ValueError):
            Config(poll_interval=MIN_POLL_INTERVAL - 1)
        Config(poll_interval=MIN_POLL_INTERVAL)
        Config(poll_interval=120)

    def test_never_more_than_one_upstream_request_per_30_seconds(self):
        clock = Clock()
        up = FakeUpstream(sample_feed(T0))
        times = []

        def recording(etag, lm):
            times.append(clock())
            return up(etag, lm)

        r = make_relay(upstream=up, clock=clock)
        r._fetch = recording
        for i in range(60):
            clock.t = max(clock.t, r._next_poll_at)      # the loop wakes exactly when the poll is due
            if i % 3 == 0:
                up.publish(sample_feed(int(clock())))
            if i == 20:
                up.error = FetchError("HTTP 503", 503)   # errors only ever stretch the gap
            if i == 24:
                up.error = None
            r.poll_once()
        gaps = [b - a for a, b in zip(times, times[1:])]
        self.assertEqual(len(times), 60)
        self.assertGreaterEqual(min(gaps), 30.0)


class StaleStateTests(unittest.TestCase):
    def test_fresh_stale_unavailable_by_pull_age(self):
        r = make_relay()
        r.poll_once()
        for dt, expect in ((0, ("fresh", "ok")), (59, ("fresh", "ok")), (61, ("stale", "relay-pull-late")),
                           (300, ("stale", "relay-pull-late")), (301, ("unavailable", "relay-pull-too-old"))):
            snap, state, reason = r.view(T0 + dt)
            self.assertEqual((state, reason), expect, dt)
            self.assertIsNotNone(snap)         # the last snapshot is kept for stale and unavailable alike

    def test_feed_timestamp_age_also_counts(self):
        # The HTTP pull is fine but RTD's own timestamp is old: delayed, then unavailable.
        for feed_age, expect in ((100, "fresh"), (121, "stale"), (299, "stale"), (301, "unavailable")):
            r = make_relay()
            r.upstream.body = sample_feed(T0 - feed_age)
            r.poll_once()
            self.assertEqual(r.view(T0)[1], expect, feed_age)

    def test_recovers_after_a_good_pull(self):
        r = make_relay()
        r.poll_once()
        r.clock.advance(400)
        self.assertEqual(r.view(r.clock())[1], "unavailable")
        r.upstream.publish(sample_feed(int(r.clock())))
        r._next_poll_at = 0
        r.poll_once()
        self.assertEqual(r.view(r.clock())[1], "fresh")

    def test_thresholds_are_configurable(self):
        r = make_relay(fresh_pulls=1, unavailable_after=100)
        r.poll_once()
        self.assertEqual(r.view(T0 + 31)[1], "stale")
        self.assertEqual(r.view(T0 + 101)[1], "unavailable")


class ErrorHandlingTests(unittest.TestCase):
    def test_backoff_doubles_to_a_cap_and_snapshot_is_kept(self):
        r = make_relay()
        r.poll_once()
        r.upstream.error = FetchError("HTTP 503", 503)
        delays = []
        for _ in range(5):
            r.clock.advance(r._next_poll_at - r.clock() + 0.001)
            before = r.clock()
            self.assertEqual(r.poll_once(), "error")
            delays.append(r._next_poll_at - before)
        for delay, base in zip(delays, (60, 120, 240, 300, 300)):
            self.assertGreaterEqual(delay, base)
            self.assertLessEqual(delay, base * 1.1 + 0.01)
        self.assertEqual(r.view(T0)[1], "fresh")
        self.assertEqual(r.last_outcome, "error")
        self.assertIn("503", r.last_error)
        # a good pull resets the backoff
        r.upstream.error = None
        r.clock.advance(r._next_poll_at - r.clock() + 0.001)
        r.upstream.publish(sample_feed(int(r.clock())))
        self.assertEqual(r.poll_once(), "updated")
        self.assertLessEqual(r._next_poll_at - r.clock(), 33.01)

    def test_retry_after_is_honoured_and_capped(self):
        r = make_relay()
        r.poll_once()
        r.upstream.error = FetchError("HTTP 429", 429, retry_after=200)
        r.poll_once()
        self.assertGreaterEqual(r._next_poll_at - r.clock(), 200)
        r.upstream.error = FetchError("HTTP 429", 429, retry_after=99999)
        r.poll_once()
        self.assertLessEqual(r._next_poll_at - r.clock(), 900 * 1.1 + 0.01)

    def test_revocation_style_errors_do_not_retry_hot(self):
        for status in (401, 403, 404, 410):
            r = make_relay()
            r.upstream.error = FetchError("HTTP %d" % status, status)
            r.poll_once()
            self.assertGreaterEqual(r._next_poll_at - r.clock(), 900, status)

    def test_network_error_and_decode_error(self):
        r = make_relay()
        r.poll_once()
        r.upstream.error = FetchError("network error: timed out")
        self.assertEqual(r.poll_once(), "error")
        r.upstream.error = None
        r.clock.advance(200)
        r.upstream.publish(b"<html>maintenance</html>")
        self.assertEqual(r.poll_once(), "error")
        self.assertIn("decode", r.last_error)
        self.assertEqual(r.view(r.clock())[0].seq, 1)                  # previous snapshot kept

    def test_internal_state_never_raises_out_of_poll_once(self):
        r = make_relay()
        r._fetch = lambda etag, lm: (_ for _ in ()).throw(FetchError("boom"))
        self.assertEqual(r.poll_once(), "error")


class RoutesTests(unittest.TestCase):
    def test_routes_failure_means_no_snapshot_and_no_hammering(self):
        r = make_relay(routes_fail=True)
        self.assertEqual(r.poll_once(), "error")
        self.assertEqual(r.view(T0)[1:], ("unavailable", "no-data"))
        self.assertEqual(r.upstream.calls, [])                          # the feed was not parsed without routes
        r.clock.advance(100)
        r.poll_once()
        self.assertEqual(r.routes_calls["calls"], 1)                    # within routes_retry: not retried
        r.clock.advance(600)
        r.poll_once()
        self.assertEqual(r.routes_calls["calls"], 2)

    def test_routes_cached_on_disk_and_reused_after_restart(self):
        with tempfile.TemporaryDirectory() as d:
            r1 = make_relay(cache_dir=d)
            r1.poll_once()
            self.assertEqual(r1.routes_calls["calls"], 1)
            self.assertEqual(r1.stats["routesBytes"], 1234)
            self.assertTrue(os.path.exists(os.path.join(d, "routes.json")))
            r2 = make_relay(cache_dir=d)
            r2.poll_once()
            self.assertEqual(r2.routes_calls["calls"], 0)

    def test_unknown_route_triggers_a_refresh_only_after_the_minimum_interval(self):
        r = make_relay()
        r.poll_once()                                   # the sample feed contains an unknown route id
        self.assertTrue(r._unknown_routes_seen)
        r.clock.advance(3600)
        r.poll_once()
        self.assertEqual(r.routes_calls["calls"], 1)
        r.clock.advance(6 * 3600)
        r.poll_once()
        self.assertEqual(r.routes_calls["calls"], 2)

    def test_routes_older_than_a_week_are_refetched(self):
        r = make_relay()
        r.poll_once()
        r.clock.advance(8 * 86400)
        r.poll_once()
        self.assertEqual(r.routes_calls["calls"], 2)

    def test_failed_refresh_keeps_using_the_old_table(self):
        r = make_relay()
        r.poll_once()
        r.clock.advance(8 * 86400)
        r._routes_fetch = lambda: (_ for _ in ()).throw(FetchError("down", 503))
        self.assertEqual(r.poll_once(), "unchanged")          # still polls; the old table is used
        self.assertEqual(len(r._routes), 4)
        self.assertEqual(r.stats["routesErrors"], 1)


class DiskSnapshotTests(unittest.TestCase):
    def test_restart_restores_a_recent_snapshot_without_raw_ids(self):
        with tempfile.TemporaryDirectory() as d:
            clock = Clock()
            r1 = make_relay(cache_dir=d, clock=clock)
            r1.poll_once()
            with open(os.path.join(d, "snapshot.json"), encoding="utf-8") as f:
                text = f.read()
            for raw in ("BUS-1501", "RAIL-9", "T-1", "1501"):
                self.assertNotIn(raw, text)
            clock.advance(100)
            r2 = make_relay(cache_dir=d, clock=clock)
            snap, state, _ = r2.view(clock())
            self.assertEqual(len(snap.vehicles), 4)
            self.assertEqual([v["id"] for v in snap.vehicles], [v["id"] for v in r1.view(clock())[0].vehicles])
            self.assertEqual(state, "stale")                    # 100 s since the last good pull

    def test_old_snapshot_is_not_restored(self):
        with tempfile.TemporaryDirectory() as d:
            clock = Clock()
            make_relay(cache_dir=d, clock=clock).poll_once()
            clock.advance(301)
            r2 = make_relay(cache_dir=d, clock=clock)
            self.assertEqual(r2.view(clock())[1:], ("unavailable", "no-data"))

    def test_corrupt_snapshot_is_ignored(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "snapshot.json"), "w") as f:
                json.dump({"schema": 1, "pulledAt": T0, "feedTimestamp": T0, "vehicles": [{"id": "x"}]}, f)
            r = make_relay(cache_dir=d)
            self.assertEqual(r.view(T0)[1:], ("unavailable", "no-data"))

    def test_no_cache_dir_means_nothing_is_written(self):
        r = make_relay(cache_dir=None)
        r.poll_once()
        self.assertEqual(r.view(T0)[1], "fresh")


class ActivityAndStatusTests(unittest.TestCase):
    def test_idle_gating(self):
        r = make_relay(idle_seconds=120)
        self.assertFalse(r._idle(T0))                        # no snapshot yet: never idle
        r.poll_once()
        self.assertTrue(r._idle(T0))                         # nobody asked yet
        self.assertFalse(r.touch())                          # no thread: nothing to resume
        self.assertFalse(r._idle(T0 + 100))
        self.assertTrue(r._idle(T0 + 121))
        self.assertFalse(make_relay(idle_seconds=0)._idle(T0 + 10 ** 6))

    def test_background_poller_starts_polls_once_and_stops(self):
        import time as real_time
        r = make_relay(clock=real_time.time)
        r.upstream.body = sample_feed(int(real_time.time()))
        r.start()
        try:
            r.wait_for_poll(0, 3)
            self.assertGreaterEqual(r.poll_count(), 1)
            self.assertEqual(r.view(real_time.time())[1], "fresh")
            real_time.sleep(0.3)
            self.assertEqual(len(r.upstream.calls), 1)       # not again until the interval is up
        finally:
            r.stop()

    def test_wait_for_poll_times_out_quickly(self):
        r = make_relay()
        r.wait_for_poll(r.poll_count(), 0.05)                # no poll happens: returns after the timeout
        r.poll_once()
        r.wait_for_poll(0, 5)                                # already satisfied: returns at once

    def test_status_has_aggregates_only(self):
        r = make_relay()
        r.poll_once()
        st = r.status(T0 + 5)
        self.assertEqual(st["state"], "fresh")
        self.assertEqual(st["vehicleCounts"], {"bus": 3, "rail": 1})
        self.assertEqual(st["feedAgeSeconds"], 5.0)
        self.assertEqual(st["routes"]["count"], 4)
        text = json.dumps(st)
        for forbidden in ("127.0.0.1", "BUS-1501", "address", "client"):
            self.assertNotIn(forbidden, text)


class AreasTests(unittest.TestCase):
    def test_areas_json_is_valid_data(self):
        areas = load_areas(AREAS_JSON)
        self.assertEqual([a.id for a in areas], ["denver"])
        s, w, n, e = areas[0].bbox
        self.assertTrue(s < n and w < e)
        self.assertEqual(areas[0].timezone, "America/Denver")


if __name__ == "__main__":
    unittest.main()
