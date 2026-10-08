# Sources and evidence

Checked 2026-10-07. Verified means supported by the cited primary source, not locally measured. Numeric engine guides are assumptions.

## USGS-1M

**Verified** — 2015 specification: bare-earth hydroflattened 1 m cells; 10 km square blocks with 6 m overlap. Resolution is not accuracy.

[USGS-1M](https://www.usgs.gov/publications/1-meter-digital-elevation-model-specification)

## USGS-LICENSE

**Verified** — All 3DEP products are public domain. A separate third-party ancillary dataset needs its own license review.

[USGS-LICENSE](https://pubs.usgs.gov/tm/11b9/tm11B9.pdf)

## USGS-QUALITY

**Verified** — QL2 target: 10 cm RMSEz, 1 m DEM, nominal pulse spacing <=0.71 m. Check each project's quality metadata.

[USGS-QUALITY](https://www.usgs.gov/3d-elevation-program/topographic-data-quality-levels-qls)

## USGS-DATUM

**Verified** — 1 m DEM uses UTM; preserve actual horizontal and vertical datum from tile metadata.

[USGS-DATUM](https://www.usgs.gov/faqs/what-projection-horizontal-datum-vertical-datum-and-resolution-a-usgs-digital-elevation-model)

## USGS-ACCESS

**Verified** — Official catalog API for product metadata and footprint queries; six-city complete 1 m coverage not verified in this pack.

[USGS-ACCESS](https://tnmaccess.nationalmap.gov/api/v1/docs)

## OSM-INCLINE

**Verified** — Incline may be percentage, explicit degrees or qualitative up/down; sign follows way direction. Qualitative tags do not provide a numeric grade.

[OSM-INCLINE](https://wiki.openstreetmap.org/wiki/Key:incline)

## OSM-LICENSE

**Verified** — OSM is ODbL, with attribution and applicable database share-alike requirements; public-domain DEM does not erase OSM obligations.

[OSM-LICENSE](https://www.openstreetmap.org/copyright)

## SEATTLE-GRADE

**Verified** — Design maxima: principal/commercial 9%, collector/minor 10%, residential access/alleys 17%; usual crown and sidewalk cross slope 2%, curb 6 inches. These are design criteria, not observed city maxima.

[SEATTLE-GRADE](https://streetsillustrated.seattle.gov/design-standards/roadway-construction/grading/)

## SEATTLE-WALL

**Verified** — Retaining structures support grade differences where allowable ground slopes are exceeded. Project approval and design remain necessary.

[SEATTLE-WALL](https://streetsillustrated.seattle.gov/design-standards/structures/)

## LA-GRADE

**Verified** — LA manual preferred street grade <=6%; major highway desirable 6%, absolute 7%; other streets normally 15%. Applicability and exceptions require project review.

[LA-GRADE](https://completestreetdesignmanual.engineering.lacity.gov/e-300-roadway-design-controls-and-criteria/e-390-grade-design-policy/e-391-design-details)

## SD-STREET

**Verified (indexed official text)** — 2024 Street Design Manual: typical crowned streets use 2% cross slope. Full current maximum grade table not verified.

[SD-STREET](https://www.sandiego.gov/sites/default/files/2024-12/sdmu-full-print.pdf)

## KC-STREET

**Verified** — City identifies adopted public works/design standards. No existing maximum street-grade record verified here.

[KC-STREET](https://www.kcmo.gov/city-hall/departments/public-works/public-works-design-construction-standards)

## SF-PARK

**Verified** — Curb wheels on perceptible grades; uphill with curb turn away, downhill toward curb. This is wheel orientation, not permission to rotate parking bays to arbitrary angles.

[SF-PARK](https://www.sfmta.com/getting-around/drive-park/how-avoid-parking-tickets)

## PITTSBURGH-STEPS

**Verified** — Public stair streets are a real part of Pittsburgh's mobility network. Individual dimensions and condition need mapping/survey.

[PITTSBURGH-STEPS](https://www.pittsburghpa.gov/Business-Development/Mobility-and-Infrastructure/Plans/City-Steps)

## ADA-STAIRS

**Verified** — Covered stair flights: uniform risers 4–7 inches, uniform treads at least 11 inches. Scope matters; this is not a universal survey of residential stairs.

[ADA-STAIRS](https://www.access-board.gov/ada/guides/chapter-5-stairways/)

## ADA-ROUTE

**Verified** — Stairs alone are not an accessible route. Generated scenes must not label a stair-only route accessible.

[ADA-ROUTE](https://www.access-board.gov/ada/guides/chapter-4-accessible-routes/)

## CESIUM-LOD

**Verified** — Screen-space error governs terrain refinement (default 2); terrain depth tests/LOD can affect surface objects, shadows add cost. A map-engine reference, not a measured WorldEngine budget.

[CESIUM-LOD](https://cesium.com/learn/cesiumjs/ref-doc/Globe.html)

## THREE-LOD

**Verified** — three.js supplies distance-based LOD; screen-error selection and stable anchoring proposed here need application logic.

[THREE-LOD](https://threejs.org/docs/pages/LOD.html)

## THREE-MESH

**Verified** — Indexed vertex geometry is supported by BufferGeometry.

[THREE-MESH](https://threejs.org/docs/pages/BufferGeometry.html)

## REALITY-MESH

**Verified** — RealityKit LowLevelMesh supports custom vertex formats and CPU/compute updates; MeshDescriptor is a simpler alternative. Prefer baked static meshes here.

[REALITY-MESH](https://developer.apple.com/documentation/realitykit/lowlevelmesh)
