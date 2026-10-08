# Cross-lane handoffs — A3

A3 is the only filing lane; Claude P3 is paused (R, 8 Oct 2026). Main's existing filing from P3 (`f3fb595` and subsequent updates) is authoritative. This log adds missing coordination records; it does not change pack approvals, STATUS files or compiled values. Dates below are the owner decision/report dates.

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-07 | P2 → 5A / A3 | Species crowns and city fallback mixes | Merged `fcda086` / `262dd22`; inferred fallback remains labelled. No new scoring claim here. |
| 2026-10-07 | 5A → P2 / A3 | Wet-ground sheen and rain darkening exception | Merged `7fcb580`; main's closed exception retained. |
| 2026-10-07 | 5A → P2 / A3 | Lake colour and water mechanics | Merged `22a1dee`; lake-winter-v1 owns colour, water-surfaces-v1 mechanics. |
| 2026-10-08 | P3 → A3 | Sole ownership of filing, trackers, roadmap, owner log and handoff log | Accepted on R's instruction. P3's main filing wins; duplicate A3 filing/STATUS/index/value edits discarded from the replacement change. |
| 2026-10-08 | R → A1 (Astra) | Data lane | OSM/Overture, heights/roofs, assessor, terrain/DEM, licences and QA in the existing data area. |
| 2026-10-08 | R → A2 (Astra) | Web bake-off lane | Confined to web/bakeoff/; water permitted only there. iOS water/shader/compiled water wiring remain with 5A. |
| 2026-10-08 | R → A3 (Astra) | Filing + trackers lane | Docs only, no code. A3 is the only filing lane; P3 paused. Mirrored lane map in AGENTS.md and CLAUDE.md; every other main rule retained. |
| 2026-10-08 | A3 → A1 | metro-data-coverage-v1 | A1 owns coverage/source/licence QA; canonical research already filed on main. No duplicate proposal copy needed. |
| 2026-10-08 | A3 → A1 (live-world later) | live-flights-v1 and real-flights-path-v1 | A1 owns source/privacy/freshness verification now; live-world later. Hosted adsb.lol launch decision and lawyer gate remain as main records them. |
| 2026-10-08 | A3 → A2 web/W1 | licensing-demo-v1 | Web licensing-demo owner, after the look gate. Main's filed design remains authoritative. |
| 2026-10-08 | 5A → A3 | Calibration v2 colour tune | Main `9884994`; no new look-loop scoring in this docs-only task. |
| 2026-10-08 | P3 → A3 | Slim runtime mock bundle | Main `cb7ac4a`; main's full reference/slim runtime split retained unchanged. A3's duplicate aggregate is not included in this change. |
| 2026-10-08 | A3 → R | ZIP relocation | 12 source ZIPs listed in zips-for-r.md; awaiting R's external-drive move. None copied, committed, moved or deleted. |
| 2026-10-08 | R → A3 | Upkeep mode | No recurring automation or auto-merges. Update trackers when R asks or after lane reports; no schedule created. |
| 2026-10-08 | R → A3 | Holds | Somewhere remains unfiled; Southern awaits R. |
| 2026-10-08 | A3 → R | Missing-pack audit | All 28 earlier requested/earlier-research packs already exist on main, including research-gpt locations and the transit CSV. No new pack filing required. |

P3's remaining handoff items (Friday cleanup plan, source sweeps, open lawyer questions) remain in docs/decisions/owner-log.md, 2026-10-08; this task does not execute them. Add future handoffs with date, from → to, item and status, grounded in lane reports or R's request.

Verification for this narrowed change: only these two tracking files and the mirrored instruction files differ from main; no proposal, STATUS, source, compiler, test or mock-value changes. No new visual-closeness claim applies to this documentation-only change.

## No block-specific fixes — R, 8 Oct 2026

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-08 | R → all look/data/generator lanes | General data/region-driven rules only; no place/building/camera tuning | Binding rule added verbatim to AGENTS.md and CLAUDE.md. Every new mock exception requires R's written approval. |
| 2026-10-08 | A3 → capture/scoring lane (P3 paused) | Untuned hold-out protocol | Required after every look merge: Lakeview, a fixed other Denver neighbourhood (not Sloan's Lake), Greenville Downtown; name/freeze the second Denver block and capture IDs before comparison. No new captures claimed by this docs task. |
| 2026-10-08 | A3 → A1 | Unchanged pipeline hold-out coverage/quality | Required alongside Sloan's for data reports; include area/source/configuration evidence. |
| 2026-10-08 | A3 → look-loop code owner (P3 paused) | finish.py legacy scoreboard row | Code update queued, not performed by A3. Until then A3 fills the two new columns manually from lane evidence after each look merge; missing results stay pending. |
| 2026-10-08 | look lanes → A3 | Sloan's score and hold-out score | Report both with merge/run evidence after every look merge. A3 records individual hold-out scores and rejects Sloan's gains accompanied by hold-out losses. |

## A1 → P2 — Sloan's Lake survey roofs, 8 October 2026

Prepared data: `Data/areas/sloans-lake/building-heights.json` and `building-roofs.json`; contract: `docs/data/building-roofs.md`. 407/1,399 buildings have accepted candidate roof heights; types: 77 gable, 66 hip, 113 flat, 151 other; 992 missing. All D and uncalibrated. Source is the 2020 USGS survey; ground and roof share that survey, NAVD88 metres. No class-6 points exist locally, so explicitly labelled planar class-1 candidates are used. Treat confidence as support, not probability; retain nulls and keep estimates separate. P2 owns consumer wiring and visual validation. Tests/merge pending; no live engine change claimed. R deferred Lakeview and Greenville; approved Greenville bounds remain HOLD.
