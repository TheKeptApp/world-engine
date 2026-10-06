import math
import struct
import unittest

from livefeeds import gtfsrt
from livefeeds.gtfsrt import DecodeError, decode_feed
from tests import pbenc
from tests.common import T0, sample_feed


class VarintTests(unittest.TestCase):
    def test_roundtrip(self):
        for n in (0, 1, 127, 128, 300, 16383, 16384, 2 ** 32 - 1, 2 ** 40 + 5):
            data = pbenc.varint(n)
            value, pos = gtfsrt.read_varint(data, 0, len(data))
            self.assertEqual((value, pos), (n, len(data)))

    def test_truncated(self):
        with self.assertRaises(DecodeError):
            gtfsrt.read_varint(b"\x80", 0, 1)


class DecodeFeedTests(unittest.TestCase):
    def test_header_and_vehicle_fields(self):
        feed = decode_feed(sample_feed(T0))
        self.assertEqual(feed.version, "2.0")
        self.assertEqual(feed.timestamp, T0)
        self.assertEqual(feed.entity_count, 12)
        by_id = {v.entity_id: v for v in feed.vehicles}
        v = by_id["BUS-1501"]
        self.assertEqual((v.trip_id, v.route_id, v.direction_id), ("T-1", "15", 0))
        self.assertEqual((v.vehicle_id, v.label), ("BUS-1501", "1501"))
        self.assertAlmostEqual(v.lat, 39.75, places=4)       # float32 precision
        self.assertAlmostEqual(v.lon, -104.99, places=4)
        self.assertAlmostEqual(v.bearing, 90.0, places=3)
        self.assertAlmostEqual(v.speed, 5.5, places=3)
        self.assertEqual(v.timestamp, T0 - 10)
        self.assertEqual(v.current_status, gtfsrt.IN_TRANSIT_TO)

    def test_optional_fields_absent_are_none(self):
        feed = decode_feed(sample_feed(T0))
        nr = {v.entity_id: v for v in feed.vehicles}["NR-1"]
        self.assertIsNone(nr.route_id)
        self.assertIsNone(nr.trip_id)
        self.assertIsNone(nr.speed)
        self.assertIsNone(nr.current_status)
        self.assertEqual(nr.bearing, 0.0)       # present and zero is not the same as absent

    def test_non_vehicle_and_deleted_entities_are_skipped(self):
        feed = decode_feed(sample_feed(T0))
        ids = {v.entity_id for v in feed.vehicles}
        self.assertNotIn("TU-1", ids)
        self.assertNotIn("DEL-1", ids)
        self.assertEqual(len(feed.vehicles), 10)

    def test_unknown_fields_are_skipped_every_wire_type(self):
        extras = (pbenc.f_varint(30, 7) + pbenc.f_double(31, 2.5) + pbenc.f_float(32, 1.5)
                  + pbenc.f_str(33, "x"))
        vp = pbenc.vehicle_position(route_id="15", vehicle_id="V", lat=1.0, lon=2.0, timestamp=5, extras=extras)
        data = pbenc.encode_feed(100, [pbenc.entity("e", vp)]) + pbenc.f_str(15, "future field")
        feed = decode_feed(data)
        self.assertEqual(len(feed.vehicles), 1)
        self.assertEqual(feed.vehicles[0].route_id, "15")

    def test_missing_header_timestamp(self):
        feed = decode_feed(pbenc.encode_feed(None, [pbenc.entity("e", pbenc.vehicle_position(lat=1.0, lon=2.0))]))
        self.assertIsNone(feed.timestamp)
        self.assertEqual(len(feed.vehicles), 1)

    def test_non_finite_floats_become_none(self):
        data = pbenc.encode_feed(1, [pbenc.entity("e", pbenc.vehicle_position(
            route_id="15", lat=float("nan"), lon=float("inf"), bearing=1.0))])
        v = decode_feed(data).vehicles[0]
        self.assertIsNone(v.lat)
        self.assertIsNone(v.lon)
        self.assertEqual(v.bearing, 1.0)

    def test_empty_feed_with_header_is_valid(self):
        feed = decode_feed(pbenc.encode_feed(T0, []))
        self.assertEqual(feed.vehicles, [])
        self.assertEqual(feed.timestamp, T0)

    def test_malformed_input_raises(self):
        good = sample_feed(T0)
        for bad in (good[:-3], good[:10], b"\xff\xff\xff", b"<html>not protobuf</html>", b""):
            with self.assertRaises(DecodeError, msg=repr(bad[:12])):
                decode_feed(bad)

    def test_group_wire_types_rejected(self):
        with self.assertRaises(DecodeError):
            decode_feed(pbenc.tag(1, 3) + b"\x00")

    def test_utf8_text_and_float_bits(self):
        vp = pbenc.vehicle_position(route_id="é", vehicle_id="V", lat=-33.5, lon=151.25)
        v = decode_feed(pbenc.encode_feed(1, [pbenc.entity("e", vp)])).vehicles[0]
        self.assertEqual(v.route_id, "é")
        self.assertEqual((v.lat, v.lon), (-33.5, 151.25))     # exactly representable in float32
        self.assertTrue(math.isclose(struct.unpack("<f", struct.pack("<f", 39.75))[0], 39.75, abs_tol=1e-6))


if __name__ == "__main__":
    unittest.main()
