#!/usr/bin/env python3
"""Plain-python tests for wall_variants.py and calibration_colours.py. Run: python3 Tools/lookloop/tests/test_wall_variants.py"""
import datetime
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import calibration_colours as cc  # noqa: E402
import wall_variants as wv  # noqa: E402
from PIL import Image  # noqa: E402


def test_sun_position():
    # June solstice, local noon at lon 0, lat 40: due south, elevation 90 - 40 + 23.44
    az, el = wv.sun_position(40.0, 0.0, datetime.datetime(2026, 6, 21, 12, 2))
    assert abs(az - 180) < 3 and abs(el - 73.4) < 1.0, (az, el)
    # the Lakeview afternoon fixture (15 Sep 2026 19:55 UTC at Chicago): south-west, about 42 degrees up
    az, el = wv.sun_position(41.943402, -87.66075, datetime.datetime(2026, 9, 15, 19, 55))
    assert 220 < az < 232 and 40 < el < 44, (az, el)


def test_ray_hit_and_facing():
    # a 10 m square building 20 m east of the camera, 8 m tall; the camera looks east (heading 90) level
    sq = [(20, -5), (30, -5), (30, 5), (20, 5), (20, -5)]
    polys = [("way/1", sq, 8.0)]
    sun_from_west = (-1.0, 0.0)  # the sun lies to the west: the west face (toward the camera) is lit
    hit = wv.ray_hit(polys, 1.65, 90, 0, 0.5, 0.5, sun_from_west)
    assert hit and hit[1] == "way/1" and abs(hit[0] - 20) < 0.1 and hit[2] > 0.99, hit
    hit = wv.ray_hit(polys, 1.65, 90, 0, 0.5, 0.5, (1.0, 0.0))  # sun in the east: that face is in shade
    assert hit and hit[2] < -0.99, hit
    assert wv.ray_hit(polys, 1.65, 90, 0, 0.5, 0.02, sun_from_west) is None  # a ray far above the roof misses
    assert wv.ray_hit(polys, 1.65, 270, 0, 0.5, 0.5, sun_from_west) is None  # looking the other way


def test_lin_and_hex():
    assert wv.hexrgb("#FFE8C6") == (255, 232, 198)
    assert abs(wv.lin(255) - 1) < 1e-6 and wv.lin(0) == 0


def test_region_colour_masks():
    im = Image.new("RGB", (100, 100), (30, 90, 200))  # blue
    for x in range(40):
        for y in range(100):
            im.putpixel((x, y), (192, 137, 100))  # brick on the left 40 %
    assert cc.region_colour(im, {"box": [0, 0, 1, 1], "mask": "brick"}, "wall") == "#C08964"
    assert cc.region_colour(im, [0.5, 0, 1, 1], "sky") == "#1E5AC8"
    assert cc.region_colour(im, [0, 0, 0.3, 0.3], "crowns") is None  # no green pixels: too few to measure


if __name__ == "__main__":
    for name, fn in sorted(globals().items()):
        if name.startswith("test_"):
            fn()
            print("ok", name)
    print("all tests passed")
