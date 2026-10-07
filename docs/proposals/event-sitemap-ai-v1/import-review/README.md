# Import review · interactive concept

Open [index.html](index.html) directly in a desktop browser. The prototype is local and uses the same colour, type, spacing, radius and elevation tokens as Creator Kit UX v2. It reuses v2's procedural Style B scene and bundled Three.js. No brands, characters or remote services are required.

Start with **Explore with a sample race plan**. Follow the eight steps. Direct links such as [item review](index.html#review), [alignment](index.html#anchors) and [summary](index.html#summary) load complete synthetic states for visual inspection. The normal flow gates progress; direct links intentionally prepare demo data and are not production authorization routes.

## Flow and screen inventory

| Screen | Main task | Continue gate | Failure / recovery |
|---|---|---|---|
| Upload | Choose/drop PDF, PNG, JPG or DXF; sample entry secondary | File selected | Unsupported type and >50 MB demo size show feedback; choose again |
| Page & crop | Page thumbnails, original source, drag crop, retained dimensions/north | Explicit crop confirmation | Too-small crop rejected; choose page/reset crop |
| Scale & north | Document units, known line length, north bearing, measured-dimension acknowledgement | Positive measurement and valid bearing, confirmed by user | Missing/invalid scale blocks continuation; unscaled sketch remains a reference |
| Align & check | Two source/place anchor pairs plus a separate check point; overlay opacity | Independent check ≤proposed 2 m threshold plus explicit alignment approval | Failed check disables approval; re-pick or restore suggestions |
| Detection draft | Source scan/progress, highlighted 3D proposals, unresolved counts | Detection finished | Unknown symbols preserved; rerunning after approval asks before resetting draft |
| Item review | Source crop beside 3D object; dimensions/origin; accept, replace, resize, dismiss; undo | All non-group proposals and unresolved symbols have decisions | Invalid dimensions rejected; replacement/resize reopens approval; dismiss requires a reason |
| Group review | Six source-labelled barriers; shared dimensions and per-item footprint overview | All items match + inspection acknowledgement + deliberate group accept | Mixed family/size blocks bulk approval; review individually or restore preset |
| Summary | Counts, source/crop, alignment/check error, original retention and decision record | No pending proposals/unresolved symbols, alignment confirmed | Return to remaining decisions; nothing automatically published |

The source and world stay together throughout preparation/review. The right inspector carries the next decision. The left progress rail communicates completion without separate modes. Draft items use a light highlight around actual meshes; the protected place remains visible. Amber communicates uncertain/unresolved inputs; green is reserved for ready or approved outcomes.

## States designed beyond the happy path

- Empty upload; file selected; unsupported file; oversized file; photo correction required.
- Page changed/crop changed: confirmation resets; original retained.
- Unknown DXF units, unscaled sketch or absent north: production flow requests evidence rather than guessing.
- Two-point fit pending; source selected awaiting map counterpart; paired controls; independent check passed/failed; alignment reopened.
- Parsing/detection progress; proposals ready; uncertain labels; unsupported symbols in unresolved tray.
- Individual pending, accepted, resized/replaced and awaiting fresh approval, dismissed with reason, reopened by undo.
- Homogeneous group ready, not inspected, approved; mixed group blocked and routed to individual review.
- Summary complete/incomplete, decision-record download, approved scene export and private-workspace return.

Phone photographs need a separate four-corner perspective correction state before alignment. This concept explains it but does not implement perspective rectification. A folded sheet or unscaled sketch may never support trusted metric placement. Two anchors determine a clean-plan similarity fit; the third point is independent evidence rather than another fitting point. The proposed threshold is a product assumption, not a measured GIS accuracy claim.

Changing page/crop/scale/anchors reopens alignment and accepted item review. Production must also invalidate the detection transform and reproject every proposal; this prototype keeps its synthetic object positions. See the limitations below before interpreting it as a working importer.

## Interaction details

Use suggested anchors to explore the correct fit, then **Show a failed check** to inspect the blocked state. You can also click a source point and then its map counterpart for all three pairs. Check markers are visually distinct. The plan overlay slider and Plan/Walk it controls work in the 3D scene.

Review the ten individual parts. Editing values alone does not silently approve them; Apply resize updates the mesh preview, and Accept records the decision. Replace opens the ten-family selector and retains the original label. The unresolved tray offers assignment to a kit family for a fresh individual review, or dismissal with a recorded reason. Six barriers remain for the group step; Show a mixed group changes one width and blocks shared approval.

**Download review record** exports source metadata, crop, units/north, anchors/check point, decisions, unresolved items and journal. It does not embed original file bytes. **Download approved scene JSON** exports accepted parts under the 1.0.0 kit instance contract in `../parametric-schema/`. Confidence, actors, source and map are explicitly demonstration data. Production needs authenticated approval identities, immutable event storage and original-source retention.

## Responsive treatment

- Desktop: 1440×900, progress rail, source/world comparison and persistent inspector.
- Tablet: 1024×768, compact rail/inspector, same full planning flow.
- Phone: 390×844, horizontal progress, compact source/world comparison, inspector below and fixed action footer. Focused review is supported; full alignment/layout remains more comfortable on desktop/tablet. The inspector scrolls to expose full details.

[Screen boards](screen-boards.html) include all eight desktop screens, alignment-error and mixed-group states, three tablet screens and four phone screens. PNG captures are saved in `screens/` at their labelled viewport sizes. Screens are actual rendered prototype captures, not image mockups.

## Boundaries of this deliverable

This is an interaction prototype. The supplied plan, park geometry, detections, scores and lighting are synthetic. It does not perform real PDF/DXF parsing, OCR, uploads to a server, geospatial base-map acquisition, true GIS alignment, photo rectification, calibrated recognition, supplier verification, permit approval or publishing. Arbitrary uploaded images can be previewed locally, but only the sample has a synthetic detection draft; unsupported processing is stated in the UI.

The 3D preview uses approximate procedural geometry and does not consume all schema options. Stage dimensions and riser height are editable; the schema package describes the complete parameter vocabulary and versioned generators for production implementation. The overlay is illustrative; production must render the accepted transform and crop, validate the independent check and preserve the original units. Geometry here should not be used as operational or engineering evidence.

The completed browser checks are recorded in [verification.json](verification.json). Schema checks and example/negative-case results live in the schema folder. The validation pilot plan was intentionally skipped as requested.

A checked synthetic export is included as [example-approved-scene.json](example-approved-scene.json). It is demonstration data, not an event plan for operational use.
