#!/usr/bin/env python3
"""Packs a worldengine.stars/1 JSON catalogue into the compact sky-only binary `worldengine.stars.bin/1`.

    python3 scripts/data/pack_star_catalog.py IN.json OUT.bin

The JSON (from build_star_catalog.py --count all --missing-bv null) stays the build source; the binary is what
ships once with the app (owner decision 2026-10-07: sky-only, under 1 MB). Read by LiveSky
`StarCatalog.load(binary:)`. Deterministic: the same JSON gives the same bytes.

Layout, all little-endian:
  header  : 8-byte magic "WESTAR01", UInt32 star count, UInt32 name-table byte length
  star    : 34 bytes each, in the JSON's order (magnitude, then id)
            UInt16 id (HR number) | Int16 mag x 1000 | Int16 B-V x 1000 (-32768 = null)
            Float32 u.x u.y u.z (J2000 unit vector) | Float32 distPc (NaN = null)
            Float32 velPcPerYear x y z (NaN = null)
  names   : repeated UInt16 id, UInt8 byte length, UTF-8 bytes (proper names only)
Float32 keeps directions to about 0.01 arcsec; magnitudes and colours keep the JSON's three decimals.
"""
import json
import math
import struct
import sys

MAGIC = b"WESTAR01"
NULL_CI = -32768


def pack(cat: dict) -> bytes:
    if cat.get("schema") != "worldengine.stars/1":
        raise SystemExit("unsupported schema %r" % cat.get("schema"))
    stars = cat["stars"]
    body = bytearray()
    names = bytearray()
    nan = float("nan")
    for s in stars:
        sid = int(s["id"])
        if not 0 < sid < 65536:
            raise SystemExit("id out of range: %d" % sid)
        ci = NULL_CI if s.get("ci") is None else int(round(s["ci"] * 1000))
        vel = s.get("velPcPerYear") or [nan, nan, nan]
        dist = s.get("distPc")
        body += struct.pack("<Hhhfffffff", sid, int(round(s["mag"] * 1000)), ci,
                            *s["u"], nan if dist is None else dist, *vel)
        if s.get("name"):
            b = s["name"].encode("utf-8")
            names += struct.pack("<HB", sid, len(b)) + b
    return MAGIC + struct.pack("<II", len(stars), len(names)) + bytes(body) + bytes(names)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    with open(sys.argv[1], encoding="utf-8") as f:
        data = pack(json.load(f))
    with open(sys.argv[2], "wb") as f:
        f.write(data)
    print("%d stars, %d bytes" % (struct.unpack_from("<I", data, 8)[0], len(data)))


if __name__ == "__main__":
    main()
