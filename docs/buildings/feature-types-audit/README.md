# Extended feature types: P2 audit 2 (9 Oct 2026)

Report only: no code, defaults, shaders or palette changed. Read against main `9137307`. Follows the [classification audit](../classification-audit/README.md). Map data © OpenStreetMap contributors.

**Sources.** Three OSM extracts, with element counts per type:

| Area | Source | Extent | Building cover |
|---|---|---|---|
| Sloan's extended (108-cell package) | `Data/areas/sloans-lake-extended` osm.json, sha256 `74f96f75…`, matches its manifest | 3.85 km² | 15.7% |
| Lakeview | `lakeview-sheil-park` | 1.0 km² | 76.5% (inflated, see method) |
| Wilmette | `wilmette-vattmann-park` | 1.0 km² | 20.1% |

**Method for (e), "share of ground".** The closed-way area of the type, divided by the area extent. Building types count their footprints. This stands in for what is visible at 150 m: a top-down share, not a rendered-pixel measurement.

Gaps in the method:
- Relation multipolygons are counted but have no area.
- Lakeview's building cover double-counts where OSM and Overture overlap, so its building shares are about 2× too low as a share of buildings. Ground shares are unaffected.

**Ranking** = mean ground share across the three areas × total feature count.

| # | Type | (a) OSM tags | (b) Sloan's ext / Lakeview / Wilmette | (c) Engine reads | (d) Drawn as | (e) share of ground, S / L / W |
|---|---|---|---|---|---|---|
| 1 | shopping centres & strip malls | shop=mall, landuse=retail, building=retail | 53 / 24 / 6 | landuse=retail → .commercial (not drawn in core); building=retail → blockEvidence commercial | plain block (Sloan) / cornerMixedUse (Chicago) | 9.07% / 6.34% / 4.53% |
| 2 | parking lots & garages | amenity=parking, parking=*, building=garage(s)/parking | 86 / 20 / 5 | MapFeatureBuilder.areaKind .parking → SceneGenerator area ("parking" paving); building=garage(s) → BuildingGenerator.role .garage | flat paving / garage box | 3.65% / 1.98% / 0.72% |
| 3 | apartments & townhomes | building=apartments|terrace|semidetached_house|residential, landuse=residential | 82 / 32 / 4 | BuildingGenerator.role / blockEvidence apartments; terrace/semidetached → house | house or apartment block (Chicago families); Denver: no apartment family | 1.82% / 1.39% / 0.3% |
| 4 | sports fields & courts | leisure=pitch|track|sports_centre|stadium, sport=* | 34 / 6 / 8 | areaKind .pitch (pitch), .recreation (sports_centre); track not read | flat green "pitch" (no lines, no court colour); track: nothing | 0.95% / 0.36% / 1.7% |
| 5 | bridges & overpasses | bridge=yes on highway/railway, man_made=bridge | 3 / 23 / 0 | MapFeatureBuilder isBridge; drawn flat (UnsupportedFeatures flatRoadFallback) | flat road on ground | 0.0% / 1.03% / 0.0% |
| 6 | salons & small service shops | shop=hairdresser|beauty|laundry|dry_cleaning|… (small retail/service) | 51 / 18 / 0 | shop on outline → commercial evidence; points ignored (Batch 2 commercialpoints reads them ≥250 m²) | house or plain block | 0.16% / 0.15% / 0.0% |
| 7 | playgrounds | leisure=playground, playground=* | 15 / 8 / 4 | areaKind .playground, pointKind .playgroundEquipment | flat "playground" surface + equipment props | 0.23% / 0.12% / 0.33% |
| 8 | bus stops & shelters | highway=bus_stop, public_transport=platform, shelter=yes | 17 / 28 / 21 | not read | nothing | 0.0% / 0.08% / 0.09% |
| 9 | office buildings | building=office, office=* | 12 / 3 / 1 | Rules default height 10 m only | plain block | 0.06% / 0.3% / 0.08% |
| 10 | grocery & big-box | shop=supermarket|department_store|hardware|doityourself|wholesale|general | 3 / 2 / 0 | shop on outline → commercial evidence; building=supermarket height rule only | plain block | 0.53% / 0.69% / 0.0% |
| 11 | gas stations & convenience | amenity=fuel, shop=convenience | 3 / 2 / 3 | not read (fuel); shop on outline → commercial evidence | plain block or house; no canopy/pumps | 0.0% / 0.16% / 0.04% |
| 12 | hotels/motels | tourism=hotel|motel|guest_house, building=hotel | 2 / 1 / 0 | not read | plain block | 0.04% / 0.36% / 0.0% |
| 13 | post office & community centre | amenity=post_office|community_centre|library|townhall | 3 / 1 / 2 | not read (map labels only) | plain block | 0.05% / 0.0% / 0.14% |
| 14 | car dealers & repair | shop=car|car_repair|tyres|car_parts, amenity=car_wash | 13 / 2 / 1 | shop → commercial evidence on outline | plain block | 0.06% / 0.0% / 0.0% |
| 15 | fast food drive-thru | amenity=fast_food + drive_through=yes | 4 / 0 / 0 | amenity on outline → commercial evidence; drive_through not read | plain block / mixed-use | 0.03% / 0.0% / 0.0% |
| 16 | swimming pools | leisure=swimming_pool, leisure=water_park | 4 / 1 / 0 | areaKind .pool | flat water | 0.01% / 0.01% / 0.0% |
| 17 | waterfront | building=boathouse, man_made=pier|jetty, leisure=slipway|marina, natural=beach, amenity=shelter, building=pavilion | 15 / 0 / 0 | areaKind .pier/.sand; boathouse/pavilion → generic building; shelter not read | pier deck / sand / plain block | 0.01% / 0.0% / 0.0% |
| 18 | warehouses & light industrial | building=warehouse|industrial, landuse=industrial | 0 / 1 / 0 | height rule only; landuse=industrial context ring only | plain block / base lawn | 0.0% / 0.06% / 0.0% |
| 19 | towers & substations | man_made=water_tower|mast|tower|communications_tower, power=substation|tower | 1 / 0 / 1 | not read (UnsupportedFeatures logs power/man_made) | nothing | 0.0% / 0.0% / 0.0% |
| 20 | self-storage | shop=storage_rental, building=storage | 1 / 0 / 0 | shop → commercial evidence | plain block | 0.0% / 0.0% / 0.0% |
| 21 | mobile home parks | residential=trailer_park, building=static_caravan | 0 / 0 / 0 | not read | house | 0.0% / 0.0% / 0.0% |
| 22 | barns, silos, farmland | building=barn|silo|farm_auxiliary, landuse=farmland|farmyard | 0 / 0 / 0 | context ring only | plain block / base lawn | 0.0% / 0.0% / 0.0% |

## Top 10 to improve the 150 m and 600 m views (region-independent; the unknown fallback stays)

1. **Retail / strip-mall land and buildings** (83 features, 6.6% of ground). `landuse=retail` is not drawn in the core today: it shows as base lawn. Draw it as a paved forecourt, and use commercialpoints / mixed-use strip massing.
2. **Parking lots** (111 features, 2.1%). They are already flat paving. Add stall striping and kerb islands, using the infrastructure-kit marking values.
3. **Apartments and townhomes** (118 features, 1.2%; Sloan's 11.6% of building footprint). Denver has no apartment family. facade-detail-v2 `denver-apartment`-style families are approved; terrace rows need a row-house mapping.
4. **Sports fields and courts** (48 features, 1.0%). Today they are a flat green "pitch". Add sport-specific surface and line keys (baseball diamond, court colours) and a running track. `leisure=track` is not read today.
5. **Bridges and overpasses** (26 features; Lakeview 23, rail). Today they are a flat road on the ground. Add a deck and piers. Readable at 600 m.
6. **Salons and small service shops** (69 features). Point evidence, plus the one-bay storefront ruling from Batch 2.
7. **Playgrounds** (27 features, 0.23%). Already a surface plus equipment props; check surface colour against ground-v1.
8. **Bus stops and shelters** (66 features). Not read; add a small shelter prop near the curb (point kind).
9. **Office buildings** (16 features). A height rule only; add a glazed office family.
10. **Grocery and big-box** (5 features, 0.41%; large footprints at Sloan's). A plain block; add a big-box family (flat roof, loading side, glazed entry).

Zero or near-zero in these three areas, so not ranked:
- None in these areas: mobile home parks, barns/silos/farmland, self-storage (1).
- Towers and substations (2).
- Warehouses (1).
- Waterfront: 15 features at Sloan's, all small (boathouse, pier, shelters).
- Drive-thru (4).

**Recommendation:** build #1–#4 first, as data-driven area kinds and families. Together they cover about 11% of ground and 360 features across the three areas.

Used: classification-audit README; MapFeatureBuilder.areaKind/pointKind; SceneGenerator area styles; Rules default heights; BuildingGenerator.role/blockEvidence. Mock: none (audit). Deviation: (e) is a top-down area share, not rendered pixels; relations have no area; Lakeview building cover inflated by OSM/Overture overlap.
