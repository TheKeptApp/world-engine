"""Minimal GTFS-Realtime decoder: protobuf wire format, only the fields the relay needs.

Field numbers follow the official GTFS-Realtime reference and gtfs-realtime.proto:
https://gtfs.org/realtime/reference/

    FeedMessage       header = 1, entity = 2 (repeated)
    FeedHeader        gtfs_realtime_version = 1, incrementality = 2, timestamp = 3
    FeedEntity        id = 1, is_deleted = 2, vehicle = 4
    VehiclePosition   trip = 1, position = 2, current_status = 4, timestamp = 5, vehicle = 8
    TripDescriptor    trip_id = 1, route_id = 5, direction_id = 6
    VehicleDescriptor id = 1, label = 2
    Position          latitude = 1, longitude = 2, bearing = 3 (all float), speed = 5 (float, m/s)

Every other field (trip_update, alert, shape, stop, occupancy, ...) is skipped by wire type.
Standard library only.
"""

import math
import struct
from dataclasses import dataclass
from typing import Iterator, List, Optional, Tuple

# Wire types (https://protobuf.dev/programming-guides/encoding/)
VARINT, FIXED64, LEN, FIXED32 = 0, 1, 2, 5

# VehiclePosition.VehicleStopStatus
INCOMING_AT, STOPPED_AT, IN_TRANSIT_TO = 0, 1, 2


class DecodeError(ValueError):
    """The bytes are not a well-formed protobuf message."""


def read_varint(buf, pos: int, end: int) -> Tuple[int, int]:
    result = 0
    shift = 0
    while True:
        if pos >= end:
            raise DecodeError("truncated varint")
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not b & 0x80:
            return result, pos
        shift += 7
        if shift > 70:
            raise DecodeError("varint too long")


def iter_fields(buf, start: int = 0, end: Optional[int] = None) -> Iterator[Tuple[int, int, object]]:
    """Yield (field_number, wire_type, value) for one message in buf[start:end].

    value is an int for VARINT, FIXED32 and FIXED64 (raw bits), and a (start, end) offset
    pair for LEN, so nested messages are parsed in place without copying.
    """
    if end is None:
        end = len(buf)
    pos = start
    while pos < end:
        tag, pos = read_varint(buf, pos, end)
        field, wtype = tag >> 3, tag & 7
        if field == 0:
            raise DecodeError("field number 0")
        if wtype == VARINT:
            value, pos = read_varint(buf, pos, end)
        elif wtype == FIXED64:
            if pos + 8 > end:
                raise DecodeError("truncated fixed64")
            value = int.from_bytes(buf[pos:pos + 8], "little")
            pos += 8
        elif wtype == LEN:
            n, pos = read_varint(buf, pos, end)
            if pos + n > end:
                raise DecodeError("truncated length-delimited field")
            value = (pos, pos + n)
            pos += n
        elif wtype == FIXED32:
            if pos + 4 > end:
                raise DecodeError("truncated fixed32")
            value = int.from_bytes(buf[pos:pos + 4], "little")
            pos += 4
        else:
            raise DecodeError("unsupported wire type %d" % wtype)
        yield field, wtype, value


def _float32(bits: int) -> Optional[float]:
    f = struct.unpack("<f", bits.to_bytes(4, "little"))[0]
    return f if math.isfinite(f) else None


def _text(buf, span) -> str:
    return bytes(buf[span[0]:span[1]]).decode("utf-8", "replace")


@dataclass
class RawVehicle:
    """One vehicle entity as it appears in the feed. Absent optional fields are None."""
    entity_id: str = ""
    trip_id: Optional[str] = None
    route_id: Optional[str] = None
    direction_id: Optional[int] = None
    vehicle_id: Optional[str] = None
    label: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    bearing: Optional[float] = None
    speed: Optional[float] = None          # metres per second
    timestamp: Optional[int] = None        # POSIX seconds
    current_status: Optional[int] = None   # INCOMING_AT / STOPPED_AT / IN_TRANSIT_TO


@dataclass
class Feed:
    version: str
    timestamp: Optional[int]               # FeedHeader.timestamp, POSIX seconds
    vehicles: List[RawVehicle]
    entity_count: int                      # all entities, including ones that are not vehicles


def _decode_trip(buf, span, v: RawVehicle) -> None:
    for f, w, val in iter_fields(buf, *span):
        if f == 1 and w == LEN:
            v.trip_id = _text(buf, val)
        elif f == 5 and w == LEN:
            v.route_id = _text(buf, val)
        elif f == 6 and w == VARINT:
            v.direction_id = val


def _decode_descriptor(buf, span, v: RawVehicle) -> None:
    for f, w, val in iter_fields(buf, *span):
        if f == 1 and w == LEN:
            v.vehicle_id = _text(buf, val)
        elif f == 2 and w == LEN:
            v.label = _text(buf, val)


def _decode_position(buf, span, v: RawVehicle) -> None:
    for f, w, val in iter_fields(buf, *span):
        if w != FIXED32:
            continue
        if f == 1:
            v.lat = _float32(val)
        elif f == 2:
            v.lon = _float32(val)
        elif f == 3:
            v.bearing = _float32(val)
        elif f == 5:
            v.speed = _float32(val)


def _decode_vehicle_position(buf, span, v: RawVehicle) -> None:
    for f, w, val in iter_fields(buf, *span):
        if f == 1 and w == LEN:
            _decode_trip(buf, val, v)
        elif f == 2 and w == LEN:
            _decode_position(buf, val, v)
        elif f == 4 and w == VARINT:
            v.current_status = val
        elif f == 5 and w == VARINT:
            v.timestamp = val
        elif f == 8 and w == LEN:
            _decode_descriptor(buf, val, v)


def decode_feed(data: bytes) -> Feed:
    """Decode a GTFS-Realtime FeedMessage. Raises DecodeError on malformed input."""
    buf = memoryview(data)
    version = ""
    timestamp: Optional[int] = None
    vehicles: List[RawVehicle] = []
    entities = 0
    for f, w, val in iter_fields(buf):
        if f == 1 and w == LEN:
            for hf, hw, hval in iter_fields(buf, *val):
                if hf == 1 and hw == LEN:
                    version = _text(buf, hval)
                elif hf == 3 and hw == VARINT:
                    timestamp = hval
        elif f == 2 and w == LEN:
            entities += 1
            v = RawVehicle()
            has_vehicle = False
            deleted = False
            for ef, ew, ev in iter_fields(buf, *val):
                if ef == 1 and ew == LEN:
                    v.entity_id = _text(buf, ev)
                elif ef == 2 and ew == VARINT:
                    deleted = bool(ev)
                elif ef == 4 and ew == LEN:
                    has_vehicle = True
                    _decode_vehicle_position(buf, ev, v)
            if has_vehicle and not deleted:
                vehicles.append(v)
    if not version and timestamp is None and not entities:
        raise DecodeError("no FeedMessage content")
    return Feed(version=version, timestamp=timestamp, vehicles=vehicles, entity_count=entities)
