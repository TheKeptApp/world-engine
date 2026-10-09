# Metro reference images

**R-supplied reference images — private, not for publication.** This collection supports matched-view skyline checks, not redistribution or engine assets. Keep originals, per-metro metadata, EXIF, matched renders and blind-label keys local; the folder’s `.gitignore` excludes all metro contents. Only this guide and ignore policy are tracked. Do not force-add private inputs, embed them in tracked reports, publish them, or infer publication rights from ownership. A clone contains the instructions, not the photographs; missing private inputs stay pending.

## Folder and filename convention

Create one subfolder per supplied metro: `city-state`, lowercase and hyphenated, using the full state name (for example `denver-colorado`, `chicago-illinois`, `greenville-south-carolina`). Create that metro’s `metadata.md` on first delivery and add one row for every photo. No images or metro-specific facts were supplied with this setup request, so no populated metro inventory is claimed.

When known, use `view-name_lat_lon_heading.jpg`: lowercase hyphenated view name, signed decimal WGS84 latitude/longitude for the **camera location**, and heading in degrees clockwise from true north (0 inclusive to 360 exclusive). Preserve supplied precision; never guess coordinates or heading. Use `unknown` in an unknown field, for example `skyline_unknown_unknown_unknown.jpg`, and explain it in metadata. Do not merely rename a different file format to `.jpg`; keep the supplied original and record any derived JPEG separately. If two files would collide, make the view-name unique (for example add capture date/time); do not overwrite originals.

Local layout:

```text
metro-reference/
  README.md
  denver-colorado/
    metadata.md
    view-name_lat_lon_heading.jpg
```

## Per-metro metadata.md template

Keep the populated file **private/local**. Record information R supplies or explicitly confirms; use `unknown` where absent. Ownership is `yes / no / unknown`, never assumed from upload. Date/time must include UTC offset or timezone; keep uncertain/EXIF-only values labelled, and never invent a capture time. Do not put residence associations or private location details in tracked reports.

```markdown
# <city-state> — private metro reference metadata
Private, not for publication. Maintained by A3 from R-supplied information.

| Local reference ID | Image filename | Where taken (camera location, lat/lon if known) | Capture date | Local time + timezone / UTC | R owns photo? (yes/no/unknown) | Ownership/date/location evidence or uncertainty |
|---|---|---|---|---|---|---|
| <opaque ID> | <filename> | unknown | unknown | unknown | unknown | awaiting R |

## View matching — one entry per reference ID
- Original SHA-256 / original filename: unknown
- Heading (true north), pitch/roll, camera height and vertical FOV: unknown
- Image dimensions, crop and lens information: unknown
- Weather/visibility and season: unknown
- Matched renderer, data/build commit, camera contract and render hash: pending
- Blind review label/key and local evidence paths: pending
- Skyline result and tallest-ten table: pending
```

## Metro skyline check

This is an additional hold-out check for **each reference image**, requested by R; it does not replace the existing four-hero look gate or the failure-only smoke protocol.

1. Establish and freeze the photo’s viewpoint **before grading**: camera coordinates/height, heading, pitch/roll, FOV, crop/aspect ratio, date/time and relevant visibility. Record what is measured versus estimated; resolve a material camera ambiguity before judging building geometry. Match the render to that viewpoint with the unchanged pipeline and record renderer/data/build hashes. Do not move buildings or tune heights to fit the photo. Capture work follows the existing heavy-lock/load protocol.
2. A3 blind-grades the matched render next to the reference: hide build/variant labels and randomize candidate order, keeping a sealed key until the verdict/reasons are recorded. For a single render hide its build identity; do not claim a multi-candidate blind test. Viewpoint familiarity is disclosed. Judge relative skyline height order, dominant masses, width/spacing, roofline silhouette and occlusion, accounting for perspective and terrain. Do not treat photographs as exact height measurements, and do not penalize missing photographic texture under the rich-stylized rubric.
3. Report **PASS / FAIL** for “skyline height/massing reads correctly”, with concise evidence and the largest discrepancies. PASS means identifiable skyline peaks, relative heights and massing read consistently at the matched viewpoint; FAIL means a visible mismatch with a sufficiently matched camera. Missing photos, unmatchable cameras, unidentifiable buildings or inadequate height evidence are **PENDING**, not an invented binary verdict. This is an additional structural assessment, separate from §M’s six visual aspects; no new numeric tolerance or gate threshold is introduced.
4. Alongside every verdict list the **tallest 10 buildings visible in the reference viewpoint**, ranked by supported physical above-ground height, not apparent pixel height. Match each to a stable public building/data ID (public building name optional), mark its position in the local comparison, and report reference height/source/uncertainty, rendered height, height delta when valid, plus massing/occlusion notes. State roof versus spire/antenna convention and datum consistently. Include missing rendered buildings; do not silently drop them. If fewer than ten are visible list all; if rank/heights cannot be established, mark unknown/unranked and explain incomplete coverage instead of fabricating a top ten. No new data download or licence approval is implied.
5. Store detailed comparisons and viewpoint metadata locally with that metro. File only a privacy-safe summary keyed by an opaque reference ID: build, renderer, PASS/FAIL/PENDING, tallest-ten public IDs/heights with sources (only if safe to share), gaps and owning lane. Never include the private filename/coordinates/date trail or photo in a tracked/public report. Preserve prior results, report regressions without averaging them away, and route data to A1, generators to P2, native rendering to 5A and web look to A2. A Sloan’s gain paired with a hold-out loss remains reject-flagged; a new skyline PASS→FAIL is explicitly flagged as a structural hold-out regression, not converted to a numeric §M score. No per-block fixes or tuning on hold-outs.

Tallest-ten table for the private per-reference report:

| Height rank | Public building/data ID | Position in view | Reference height (m), source, uncertainty | Rendered height (m) | Delta (m) | Massing/occlusion / missing evidence |
|---|---|---|---|---|---|---|
| pending | unknown | unknown | unknown | unknown | unknown | no reference supplied |

No skyline checks, captures, scores or ownership verification are claimed by this folder setup.
