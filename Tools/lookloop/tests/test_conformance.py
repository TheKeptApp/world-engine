#!/usr/bin/env python3
"""Plain-python tests for compile_mocks.py and conformance.py. Run: python3 Tools/lookloop/tests/test_conformance.py"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import compile_mocks as cm  # noqa: E402
import conformance as cf  # noqa: E402


def test_delta_e():
    assert cf.delta_e76("#808080", "#808080") == 0
    assert abs(cf.delta_e76("#000000", "#FFFFFF") - 100) < 0.01
    assert abs(cf.srgb_to_lab("#FF0000")[0] - 53.24) < 0.05  # reference CIE L* of sRGB red
    assert cf.delta_e76("#E4E9EB", "#E8EDF0") < 5 < cf.delta_e76("#314D79", "#4A66B8")


def test_scalar_tolerance():
    assert cf.scalar_ok(0.3, 0.31) and not cf.scalar_ok(0.3, 0.33)
    assert cf.scalar_ok(1.0, 1.04) and not cf.scalar_ok(1.0, 1.06)


def test_flatten():
    data = {"date": "x", "note": "long text", "a": {"hex": "#AABBCC", "n": 1.5, "b": True,
            "s": "led-warm", "long": "a sentence with spaces"}, "l": [{"v": 2}, 3], "sources": [1]}
    got = dict(cm.flatten(data))
    assert got == {"a.b": True, "a.hex": "#AABBCC", "a.n": 1.5, "a.s": "led-warm", "l[0].v": 2, "l[1]": 3}, got


def test_approved_packs():
    text = ("| F | Pack | I | Values | Status |\n|---|---|---|---|---|\n"
            "| a | p1 | x | `docs/proposals/p1/v.json` | **R approved – binding target** |\n"
            "| b | p2 | x | `docs/proposals/p2/v.json` | pending R approval |\n")
    assert cm.approved_packs(text) == [("p1", "docs/proposals/p1/v.json")]


def test_exception_parsing():
    md = ("| Mock key | Engine value | Reason | R approval date | Status |\n|---|---|---|---|---|\n"
          "| `p/a.b` | 1 | r | 2026-10-07 | TEMPORARY, R approved 2026-10-07 |\n"
          "| p/c | 1 | r | | proposed |\n")
    assert cf.parse_exceptions(md) == {"p/a.b": "TEMPORARY, R approved 2026-10-07"}
    real = cf.parse_exceptions(cf.EXCEPTIONS.read_text())
    assert "rain-v1/wetPathDarkening" in real


def test_daytime_master_precedence():
    doc = cm.build()
    assert doc["entries"]["house-contrast-v1/sharedLighting.sky.gradient[0].hex"]["role"] == "daytime-master"
    assert "role" not in doc["entries"]["house-contrast-v1/houseTypes.chicago_bungalow.surfaces.wall.hex"]
    by = {c["parameter"]: c for c in doc["conflicts"]}
    assert by["sun elevation fixture (deg)"]["resolved"] == cm.MASTER_RESOLUTION
    assert by["sky zenith colour (90 deg stop)"]["resolved"] == "different state"
    assert "resolved" not in by["haze extinction per metre (clear/haze fixture)"]
    m = {"state": "daytime-master", "value": 1}
    assert cm.resolution([m, {"state": "other state", "value": 2}]) == "different state"
    assert cm.resolution([m, {"state": "day", "value": 2}]) == cm.MASTER_RESOLUTION
    assert cm.resolution([{"state": "day", "value": 1}, {"state": "day", "value": 2}]) is None


def test_resolve():
    d = {"h": [{"id": "x", "c": [["#1", "#2"]]}]}
    assert cf.resolve(d, "h[id=x].c[0][1]") == "#2"


def test_check_deterministic():
    a, b = cm.render(cm.build()), cm.render(cm.build())
    assert a == b
    r = subprocess.run([sys.executable, str(HERE.parent / "compile_mocks.py"), "--check"], capture_output=True)
    assert r.returncode == 0, r.stdout


def test_archetype_rows():
    values = {
        "house-archetypes-v1/archetypes.a.colourVariations[0].wallHex": {"value": "#A57450"},
        "house-archetypes-v1/archetypes.a.colourVariations[0].trimHex": {"value": "#DECBAB"},
        "house-archetypes-v1/archetypes.a.colourVariations[0].roofHex": {"value": "#5B5A52"},
        "house-archetypes-v1/archetypes.a.roof.allowedPitchDegreeRangesProposal[0][0]": {"value": 0},
        "house-archetypes-v1/archetypes.a.roof.allowedPitchDegreeRangesProposal[0][1]": {"value": 90},
    }
    rows = cf.archetype_rows(values, {"archetypes": {"map": {"a": ["front-range/modern"]}}})
    assert any(r["key"].endswith("pitch") and r["status"] == "pass" for r in rows)
    assert all(r["status"] in ("pass", "FAIL") for r in rows)


def test_daytime_overrides():
    import tempfile
    src = r'''static let prefix = "p/s."
        set("road", seasons: [0, 1, 2], m.string(prefix + "ground.asphalt.hex"))
        for key in ["lawn", "lawnA"] { set(key, seasons: [1], m.string(prefix + "ground.lawn.hex")) }
        let greens = (0..<3).compactMap { m.string(prefix + "postcard.trees.crownGreensHex[\($0)]") }
        set(key, seasons: [0, 1], green)'''
    with tempfile.TemporaryDirectory() as d:
        f = Path(d) / "M.swift"
        f.write_text(src)
        old, cf.DAYTIME_SRC = cf.DAYTIME_SRC, f
        try:
            ov, crown = cf.daytime_overrides()
        finally:
            cf.DAYTIME_SRC = old
    assert ov[("road", 2)] == "p/s.ground.asphalt.hex" and ov[("lawnA", 1)] == "p/s.ground.lawn.hex"
    assert ("lawn", 0) not in ov and crown == [0, 1]


if __name__ == "__main__":
    for name, fn in sorted(globals().items()):
        if name.startswith("test_"):
            fn()
            print("ok", name)
    print("all tests passed")
