import datetime
import os
import re
import tempfile
import unittest

from livefeeds.salt import DailySalt


def ts(year, month, day, hour, minute=0, tz="America/Denver"):
    from zoneinfo import ZoneInfo
    return datetime.datetime(year, month, day, hour, minute, tzinfo=ZoneInfo(tz)).timestamp()


class SaltTests(unittest.TestCase):
    def test_id_shape_and_no_raw_id(self):
        s = DailySalt(None, "America/Denver", 3)
        vid = s.vehicle_id("rtd", "BUS-1501", ts(2026, 10, 6, 12))
        self.assertRegex(vid, r"^rtd:[0-9a-f]{12}$")
        self.assertNotIn("1501", vid)

    def test_stable_within_a_service_day_distinct_across_vehicles(self):
        s = DailySalt(None, "America/Denver", 3)
        morning, evening = ts(2026, 10, 6, 5), ts(2026, 10, 6, 23, 30)
        self.assertEqual(s.vehicle_id("rtd", "A", morning), s.vehicle_id("rtd", "A", evening))
        # after midnight but before 03:00 local, it is still the same service day
        self.assertEqual(s.vehicle_id("rtd", "A", morning), s.vehicle_id("rtd", "A", ts(2026, 10, 7, 2, 59)))
        self.assertNotEqual(s.vehicle_id("rtd", "A", morning), s.vehicle_id("rtd", "B", morning))
        self.assertNotEqual(s.vehicle_id("rtd", "A", morning), s.vehicle_id("other", "A", morning))

    def test_rotates_at_the_next_service_day(self):
        s = DailySalt(None, "America/Denver", 3)
        before = s.vehicle_id("rtd", "A", ts(2026, 10, 7, 2, 59))
        after = s.vehicle_id("rtd", "A", ts(2026, 10, 7, 3, 1))
        self.assertNotEqual(before, after)
        self.assertEqual(s.service_day(ts(2026, 10, 7, 3, 1)), "2026-10-07")
        self.assertEqual(s.service_day(ts(2026, 10, 7, 2, 59)), "2026-10-06")

    def test_old_salt_is_discarded_so_yesterday_cannot_be_recomputed(self):
        s = DailySalt(None, "America/Denver", 3)
        day1 = s.vehicle_id("rtd", "A", ts(2026, 10, 6, 12))
        s.vehicle_id("rtd", "A", ts(2026, 10, 7, 12))          # rotates
        # asking for the old day again does not bring the old salt back
        self.assertNotEqual(s.vehicle_id("rtd", "A", ts(2026, 10, 6, 12)), day1)

    def test_separate_instances_do_not_share_a_salt(self):
        t = ts(2026, 10, 6, 12)
        self.assertNotEqual(DailySalt(None).vehicle_id("rtd", "A", t), DailySalt(None).vehicle_id("rtd", "A", t))

    def test_persisted_salt_survives_restart_within_the_day_only(self):
        with tempfile.TemporaryDirectory() as d:
            t = ts(2026, 10, 6, 12)
            first = DailySalt(d, "America/Denver", 3).vehicle_id("rtd", "A", t)
            again = DailySalt(d, "America/Denver", 3).vehicle_id("rtd", "A", t + 3600)
            self.assertEqual(first, again)
            next_day = DailySalt(d, "America/Denver", 3).vehicle_id("rtd", "A", ts(2026, 10, 7, 12))
            self.assertNotEqual(first, next_day)
            mode = os.stat(os.path.join(d, "salt.json")).st_mode & 0o777
            self.assertEqual(mode, 0o600)

    def test_corrupt_salt_file_is_replaced(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "salt.json"), "w") as f:
                f.write("{not json")
            s = DailySalt(d, "America/Denver", 3)
            self.assertRegex(s.vehicle_id("rtd", "A", ts(2026, 10, 6, 12)), r"^rtd:[0-9a-f]{12}$")

    def test_unknown_timezone_falls_back_to_utc(self):
        s = DailySalt(None, "Not/AZone", 3)
        self.assertEqual(s.service_day(datetime.datetime(2026, 10, 6, 4, tzinfo=datetime.timezone.utc).timestamp()),
                         "2026-10-06")


if __name__ == "__main__":
    unittest.main()
