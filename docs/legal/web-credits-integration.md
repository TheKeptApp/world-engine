# Web credits integration — A10, 2026-10-09

## Sources and scope

Used: A11 lawyer-brief-v1.md §A (A1/A3), credits-draft.md Core map / Building data / Elevation and imagery / Stars, night lights and boundaries / Before publishing, data-licence-inventory-v1.md Current implementation evidence; docs/tracking/INDEX.md legal entries; DECISIONS.md Legal scope; REFERENCE-MAP.md and MOCKS.md (no approved credits UI mock). Operational CLAUDE/AGENTS, roadmap, owner-log, proposal index and pack-usage were read. Mock: matched frozen Sloan/Lakeview ladder controls and a 390px real UI screenshot; no look mock or new look score applies to this UI-only task.

`web/index.html` mounts an independent `web/credits.js` module and `web/build.mjs` copies it and its exact-wording `web/credits.json` catalogue. No renderer module, shader, light, budget, camera or default flag is edited. Existing visible OSM link remains; a fixed About / credits button and linked OSM credit are always reachable. The native app is untouched. Native credits remain a separate task.

The dialog uses actual displayed world.json sources to select notices. OSM is always present; Overture, USGS, NAIP and Census wording appears only on matching package records. Legal text fragments/URLs are copied verbatim from A11, tested against the draft. No release-placeholder URL or invented legal statement is supplied. Keyboard Escape/Close restores button focus; modal content scrolls at phone width without resizing the canvas. A failed package lookup explicitly marks credits incomplete instead of claiming all sources were credited.

## Questions for A11 — unresolved, not silently wired

1. What is the working free version-matched ODbL derivative-database offer URL? The UI retains the draft's exact sentence “This draft does not claim that the download already exists.” It cannot wire a missing offer.
2. For Overture-bearing packages, what exact release and reconciled upstream notice/register replace EXACT RELEASE and its RELEASE BLOCKER? The existing manifest source-combination notice is wired verbatim; it is not a completeness claim.
3. Which shipped USGS project metadata and NAIP dates/processing provenance should appear, and is the Census product grant/subset verified? Those bracketed fields remain unresolved; complete acknowledgement/citation fragments are wired.
4. Are any sources contributing to the actual web world absent from world.json.sources (e.g. sky/catalogue, night lights or live feeds)? Supply exact runtime applicability and cleared notices before those conditional draft sections can be wired. Country/live HOLD sections are not shown simply because they appear in research.
5. Separate software licence/NOTICE texts and any mandatory visual provider marks are outside this data-credit draft; where is the approved web notice payload? This UI integration supplies no legal clearance and no external publication.

## Verification contract

Two focused tests verify exact A11 text/URLs and source-conditioned selection. Build produces the renderer app bundle plus standalone overlay files. Six frozen ladder views use the existing capture-only fixed clock and full scoreboard packages: Sloan and Lakeview at 40/150/600 m. Each page completes stable submission frames, freezes its renderer, saves BEFORE, mounts the same shipped credits module, saves AFTER, and checks backend pass counters unchanged. Compare every byte outside the explicitly reported overlay bounding rectangle, maximum <=1 byte (1/255). This paired test isolates UI compositing without fresh-process timing noise; it does not claim native validation or a new renderer score. Phone control verification uses the actual production index.html with app.js suppressed only for the UI fixture, at 390×844, plus each actual loaded-world ladder overlay. Full raw frames stay outside Git.

## Results

Build and two focused tests pass. Heavy admission load14.82 (<25), lock released normally. All six overlay-excluded comparisons max0/mean0/differing bytes0; pass counts identical before/after. Machine evidence: [web-credits-evidence.json](web-credits-evidence.json).

| View | Main triangles / draws unchanged | Shadow triangles / draws unchanged | Pixel max / mean |
|---|---:|---:|---:|
| sloans-lake/40 | 791,213 / 184 | 69,697 / 62 | 0 / 0 |
| sloans-lake/150 | 935,422 / 257 | 68,019 / 42 | 0 / 0 |
| sloans-lake/600 | 698,361 / 305 | 0 / 0 | 0 / 0 |
| lakeview-sheil-park/40 | 1,084,028 / 219 | 87,604 / 92 | 0 / 0 |
| lakeview-sheil-park/150 | 1,209,778 / 238 | 81,537 / 47 | 0 / 0 |
| lakeview-sheil-park/600 | 960,351 / 219 | 0 / 0 | 0 / 0 |

Phone390×844 checks pass for both actual production-index UI fixtures: dialog stays inside viewport, opens/closes and linked OSM is reachable. Sloan phone screenshot opened and inspected at `/private/tmp/a10-credits-sloans-v1/phone-credits.png`; Lakeview screenshot `/private/tmp/a10-credits-lakeview-v1/phone-credits.png`. No phone install. Render source SHA values match the pre-overlay commit, and the renderer bundle entry remains unchanged. Raw ladder paths and precise excluded rectangles are in the machine evidence. These are frozen same-page comparisons; no fresh-process/native/performance or legal-release acceptance is inferred.

## 2026-10-10 — credit-only source selection fix

Read current handoffs.md and A11 web-credits-answers.md §§3–4 first after fetching the newly landed answer. Conditional notice selection now searches the union of world.json.sources and world.json.credits; catalogue filtering still emits each notice once. No catalogue wording, placeholders, CSS, DOM construction or renderer source changed. A11's answers supply facts/questions, explicitly no new notice wording; existing draft placeholders and unresolved offer/provenance questions are retained rather than filled or invented.

A regression fixture has credits:[{id:naip,text:NAIP imagery provided by USDA Farm Service Agency}] and sources:[]; it must select and visibly render the existing exact NAIP notice. A duplicate source+credit emits only one notice. Three unit tests pass. The browser test compares the prior/current real module at390×844 with a source-only manifest, dialog closed and open, plus the credit-only NAIP dialog. Raw screenshots/evidence: /private/tmp/a10-credit-only-ui-20261010/. No renderer or native capture is required for this selector-only fix.

Result: three unit tests and actual browser regression pass. NAIP acknowledgement is visibly rendered with sources:[]; the390×844 screenshot was opened and inspected. Existing source-only open and closed overlay screenshots each have max0/differing bytes0 versus the pre-fix module, without exclusions. CSS/catalogue/renderer bytes are untouched. Raw evidence.json is retained with the screenshot directory. The initially queued heavy wrapper was stopped before admission because this static DOM-only test suppresses app.js and does no world rendering; P2's process/lock was untouched.
