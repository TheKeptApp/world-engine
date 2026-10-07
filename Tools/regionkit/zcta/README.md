# zcta

Offline tool that writes `Data/areas/<id>/zcta.json`: ZIP Code Tabulation Area (ZCTA5, 2020) boundaries clipped to each area's context box (the manifest source with layers `["context"]`).

Source: U.S. Census Bureau TIGERweb, layer 7 ("2020 Census ZIP Code Tabulation Areas") of `TIGERweb/PUMA_TAD_TAZ_UGA_ZCTA/MapServer`. Queried by envelope, only the `ZCTA5` field, full resolution, WGS84. Licence: U.S. Government work, treated as public domain (not stated explicitly on the Census pages checked; see `docs/research/licensing.md` Z1).

## Run

    UV_CACHE_DIR=/tmp/claude-zcta-uv uv run --no-project --with shapely --with numpy --with certifi \
        python Tools/regionkit/zcta/zcta.py Data/areas/sloans-lake Data/areas/evanston-south

`certifi` is only needed when Python has no system CA bundle. Requests are sequential with a 1 s pause and the User-Agent `WorldEngine regionkit (research)`. Files over 300 KB are simplified (0.5 m, then 1 m) and record `simplifiedToleranceM`.

## Output (`census-zcta-v1`)

Pretty JSON, sorted keys. `zctas` is sorted by id; each has `polygons`, each polygon `[outerRing, hole, ...]`, rings `[lon, lat]`, closed, 7 decimals, outer rings counter-clockwise, holes clockwise. ZCTAs do not cover water, so Lake Michigan is empty.

## Tests

    python3 -m unittest discover -s Tools/regionkit/zcta/tests

Clipping tests need shapely and are skipped without it.
