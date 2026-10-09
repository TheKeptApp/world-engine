# Palette B: lot and tableA trial

R authorized this reduced-scope trial after the surface-role admission stop. Roofs, walls, plaster and the mapped-colour guard remain deferred. No feature IDs, colour-equality selectors, camera/block look rules, global desaturation or native changes. This trial does not promote the diagnosis hypotheses into approved pack values.

## Consumers and selectors

- `web/bakeoff/main.js` lazily loads `palette-b.js` only for `paletteB=lot|tableA`. Absent/off takes the original node-construction path. Other values error.
- `lot`: `Paint.Flags.lawn` (4) selects the existing native rule: mix exported seasonal `lawnA/lawnB` texture samples with clamped `_extra.y`, multiply by `_paint.y`. The export's season selection is unchanged; no new colours.
- `tableA`: cumulative lot rule plus diagnosis §4 hypotheses. `TABLE.slots` addresses validated named assignments: lawnA/B, tufts, road, sidewalk, curb, bark. Equal-colour slots elsewhere stay untouched. Existing sidewalk flag (8) also consumes the concrete endpoint. No constant seasonal lawn-base replacement is introduced: the two endpoints own lawn colour in both trial modes.
- Species keys address summer/peak endpoints for maple, linden, elm, aspen and cottonwood, and summer for blue spruce. P2 vegetation peak precedence is preserved using those same species keys. General bark uses its named assignment and species/family branch input, preserving aspen's light bark. Other species leaf endpoints, date weights, regional retained-green fractions, species selection and geometry are unchanged.
- Water targets apply to the selected lake profile/state only, upstream of the existing inverse-grade/irradiance compensation. Grade, sun/fill, haze, wave/reflection/shore mechanics and shadows are unchanged.
- `TABLE` is serialized deterministically and SHA-256 hashed. Each frame's `paletteBReport` contains the hash, source, resolved selectors/values, value semantics, lawn endpoint linear RGB and deferred roles. Authored hex values decode once; palette textures are linear/NoColorSpace; main retains its single explicit output encode.

## Validation commands

Set `WORLDENGINE_ASSETS` to this checkout for the existing arithmetic suites. Run the palette, policy, atmosphere, sky-colour, overnight, foliage-exp1, crown-v2, crown-v3 and capture-tooling tests under `scripts/heavy.sh`. The first attempted batch lacked that environment variable and stopped at the legacy overnight fixture read; rerun with it set. No renderer defect was inferred from that setup failure.

## Capture recipe

Only `scripts/capture-web.sh` performs renders, under its existing heavy admission, watchdog and cleanup. Each invocation releases its own lock. The only capture-tool additions are palette query/metadata routing and the requested Lakeview 150 m inspection height using the saved Lakeview eye and existing 270°/45°/50° inspection recipe. The saved street contract and Sloan ladder are unchanged.

All trial captures use crown OFF, foliage exp1 OFF, no sceneBudget, fixed grade/date/pose. Sloan 40/150/600 m: lot and tableA, plus additional absent/off controls for c8c361d identity; Sloan 150 m v3+tableA; Lakeview 150 m absent vs tableA. Each condition has a fresh/repeat pair. This is 30 trial/ladder frames including 12 additional Sloan default-identity controls, plus 4 Lakeview 600 m absent/off fresh/repeat controls: 34 frames total.

`measure-palette.py` implements diagnosis §3's eligible-pixel method, excluding top 32 rows, clipped channels and negative reconstructed source radiance. Mean L*/C* is the mean of eligible per-pixel Lab D65 values. Eligibility is recomputed for each frame: report its share, since different eligible populations are not a strict matched-pixel causal estimate. No score or ΔE is computed. PNGs remain local/ignored; manifest and compact evidence are committed.

## Sloan measurements (crown OFF)

| Height | Default L*/C* | lot L*/C* | tableA L*/C* | tableA eligible share |
|---|---:|---:|---:|---:|
| 40 m | 66.02 / 27.65 | 67.71 / 29.62 | 61.38 / 21.20 | 95.81% |
| 150 m | 68.35 / 26.65 | 69.71 / 29.04 | 64.33 / 21.28 | 95.31% |
| 600 m | 70.11 / 24.90 | 71.19 / 30.81 | 64.02 / 17.07 | 99.29% |

The lot-only rule increases lightness/chroma because the exported autumn endpoints are lighter/warmer than bakeoff's former constant. tableA reduces the eligible means; this is not a closeness score or approval to ship. Orange mapped roofs remain unchanged/deferred. All three modes retain the pre-existing crown-OFF main costs: 729,101 triangles / 182 draws; 791,795 / 251; 624,433 / 292. This trial does not resolve the existing scene-budget overage.


| Additional condition | Mean L* | Mean C* | Eligible share |
|---|---:|---:|---:|
| sloans-150 v3 tableA | 63.62 | 18.16 | 95.30% |
| lakeview absent | 66.10 | 17.45 | 98.47% |
| lakeview tableA | 64.00 | 14.85 | 99.80% |

All 34 frames (17 fresh/repeat pairs) are validated. Absent/off Sloan 40/150/600 and Lakeview 600 PNG bytes equal c8c361d controls exactly. Every lot/tableA pass count equals its default; v3+tableA equals the existing v3 pass counts. Lakeview 150 m is newly captured at the unchanged inspection recipe; no prior c8c361d frame exists at that height. Its repeat and paired coverage checks pass. Mean changes are ungraded.

## Ledger text for A3

Integrated behind default OFF, capture/identity validation passed; visual acceptance pending A3. Implementation 7f16c53 plus this evidence commit; exact captured source hashes, table hash, selectors and values are in manifest.json and each batch web-capture.json. Arithmetic suites pass (1,056 identity cases; 228 v3 cases; 14 capture-tooling tests). No visual score claimed. Used: `docs/execution/palette-diagnosis.md` §§3–4 and R's reduced-scope authorization. Mock: calibration-v2 frames 06-sloans and 01-lakeview; identity controls c8c361d/A7 post-near-plane ladder. Deviation: surface-role-dependent rows deferred by R; Lakeview 150 m is a new inspection pair, not a historical street-frame comparison.

Touched: web/bakeoff palette adapter, bounded main hooks, identity/arithmetic/capture-evidence tests, measurement script and evidence; minimal scripts capture query/metadata and Lakeview-150 routing plus its test. No pack, native, tracking, grade, light, geometry or shadow changes. Named seasonal slots are independently allocated before hex-deduplicated building tuples (`Sources/WorldGen/Palette.swift::init(seasonal:)`); this is why equal-hex building slots are not recoloured.
