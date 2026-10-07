# Terrain + Slope v1

Open [the gallery](index.html). Seven PNG sheets each show street, 45° aerial and far views; seven HTML sheets stack enlarged panels for phones and include exact slope-section diagrams.

## Contents
- images/: gentle 3%, moderate 10%, steep 22%, corner lot, Pittsburgh stair street, Kansas City retaining-wall street, San Diego canyon edge.
- values.json: grade bands, metre dimensions, foundations, stairs, roads, LOD and budget targets; inherited sharedLook from style-b-calibration-v2.
- research.md: data, construction/generation logic, city standards, mobile rendering and unresolved gates.
- sources.md: 20 primary sources, status and check date.
- prompts.json and image-manifest.json: generation/edit history, image dimensions and checksums.
- phone-check/: browser screenshots and verification results.

## Recommendations
1. Keep floor slabs level and anchor buildings using the full footprint, entrance and garage levels.
2. Verify exact AOI DEM footprints, datum and acquisition date; never promise complete metro 1 m coverage without that check.
3. Preserve road, retaining and canyon breaklines; never drape bridges onto bare earth.
4. Bake geometry and stable anchors once, and simplify by projected size without changing contact heights.
5. Share calibration v2 lighting/materials and existing v2 GPU buckets; benchmark sustained phone use before accepting subcaps.

Verified claims cite dated primary sources. All authored dimensions, grade examples, camera targets and performance subcaps are assumptions. Generated images are qualitative concepts, not surveyed geography or literal construction geometry; foliage/roof detail is illustrative and must be simplified to the JSON tiers in-engine. The generated three viewpoints are visually coherent concepts, not projections of one validated mesh. Six-city complete 1 m coverage and current existing maximum street records remain unverified. ADA stair criteria have limited applicability and do not make a stair-only route accessible.

No project files were changed; no git used. All authored deliverables are in this folder.

## Verification and file inventory

32 deliverable files saved (Finder .DS_Store metadata excluded). All 8 HTML pages passed at 390×844 and 430×844 CSS pixels: 16 checks, all images loaded, no horizontal overflow. Nine screenshots saved; steep-sheet phone layout visually inspected. This is desktop Chrome viewport simulation, not physical-device Safari or a GPU benchmark. All JSON parsed and all referenced scene files exist.

- [01-gentle.html](01-gentle.html)
- [02-moderate.html](02-moderate.html)
- [03-steep.html](03-steep.html)
- [04-corner.html](04-corner.html)
- [05-stair-street.html](05-stair-street.html)
- [06-retaining.html](06-retaining.html)
- [07-canyon.html](07-canyon.html)
- [README.md](README.md)
- [image-manifest.json](image-manifest.json)
- [images/01-gentle.png](images/01-gentle.png)
- [images/02-moderate.png](images/02-moderate.png)
- [images/03-steep.png](images/03-steep.png)
- [images/04-corner.png](images/04-corner.png)
- [images/05-stair-street.png](images/05-stair-street.png)
- [images/06-retaining.png](images/06-retaining.png)
- [images/07-canyon.png](images/07-canyon.png)
- [index.html](index.html)
- [phone-check.cjs](phone-check.cjs)
- [phone-check/390-01-gentle.png](phone-check/390-01-gentle.png)
- [phone-check/390-02-moderate.png](phone-check/390-02-moderate.png)
- [phone-check/390-03-steep.png](phone-check/390-03-steep.png)
- [phone-check/390-04-corner.png](phone-check/390-04-corner.png)
- [phone-check/390-05-stair-street.png](phone-check/390-05-stair-street.png)
- [phone-check/390-06-retaining.png](phone-check/390-06-retaining.png)
- [phone-check/390-07-canyon.png](phone-check/390-07-canyon.png)
- [phone-check/390-index.png](phone-check/390-index.png)
- [phone-check/430-index.png](phone-check/430-index.png)
- [phone-check/report.json](phone-check/report.json)
- [prompts.json](prompts.json)
- [research.md](research.md)
- [sources.md](sources.md)
- [values.json](values.json)
