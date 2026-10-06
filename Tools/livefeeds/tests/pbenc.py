"""A tiny protobuf encoder for building SYNTHETIC GTFS-Realtime test feeds.

Written independently of livefeeds.gtfsrt (the decoder under test) from the protobuf wire format and
the field numbers in the GTFS-Realtime reference (https://gtfs.org/realtime/reference/). No real
feed data is committed anywhere in this repository; every fixture is built by this module.
"""

import struct
from typing import List, Optional


def varint(n: int) -> bytes:
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def tag(field: int, wire: int) -> bytes:
    return varint((field << 3) | wire)


def f_varint(field: int, n: int) -> bytes:
    return tag(field, 0) + varint(n)


def f_len(field: int, payload: bytes) -> bytes:
    return tag(field, 2) + varint(len(payload)) + payload


def f_str(field: int, s: str) -> bytes:
    return f_len(field, s.encode("utf-8"))


def f_float(field: int, x: float) -> bytes:
    return tag(field, 5) + struct.pack("<f", x)


def f_double(field: int, x: float) -> bytes:
    return tag(field, 1) + struct.pack("<d", x)


def vehicle_position(*, trip_id: Optional[str] = None, route_id: Optional[str] = None,
                     direction: Optional[int] = None, vehicle_id: Optional[str] = None,
                     label: Optional[str] = None, lat: Optional[float] = None, lon: Optional[float] = None,
                     bearing: Optional[float] = None, speed: Optional[float] = None,
                     timestamp: Optional[int] = None, status: Optional[int] = None,
                     extras: bytes = b"") -> bytes:
    """VehiclePosition message. Unknown extra fields (occupancy, odometer, ...) go in `extras`."""
    trip = b""
    if trip_id is not None:
        trip += f_str(1, trip_id)
    if route_id is not None:
        trip += f_str(5, route_id)
    if direction is not None:
        trip += f_varint(6, direction)
    pos = b""
    if lat is not None:
        pos += f_float(1, lat)
    if lon is not None:
        pos += f_float(2, lon)
    if bearing is not None:
        pos += f_float(3, bearing)
    if speed is not None:
        pos += f_float(5, speed)
    desc = b""
    if vehicle_id is not None:
        desc += f_str(1, vehicle_id)
    if label is not None:
        desc += f_str(2, label)
    out = b""
    if trip:
        out += f_len(1, trip)
    if pos:
        out += f_len(2, pos)
    if status is not None:
        out += f_varint(4, status)
    if timestamp is not None:
        out += f_varint(5, timestamp)
    if desc:
        out += f_len(8, desc)
    return out + extras


def entity(entity_id: str, vehicle: Optional[bytes] = None, deleted: bool = False,
           trip_update: Optional[bytes] = None) -> bytes:
    out = f_str(1, entity_id)
    if deleted:
        out += f_varint(2, 1)
    if trip_update is not None:
        out += f_len(3, trip_update)
    if vehicle is not None:
        out += f_len(4, vehicle)
    return out


def encode_feed(timestamp: Optional[int], entities: List[bytes], version: str = "2.0") -> bytes:
    header = f_str(1, version) + f_varint(2, 0)
    if timestamp is not None:
        header += f_varint(3, timestamp)
    return f_len(1, header) + b"".join(f_len(2, e) for e in entities)
