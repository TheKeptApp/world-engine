# Overture Places — five held areas, 10 October 2026

**Done: release `2026-09-23.1` pulled and analysed locally. No engine, area manifest, package, ladder or renderer changes.** Raw files are gitignored; only aggregate results, report tooling, category rules and rights/provenance receipts are tracked. No business name, brand, phone, website, email, street address or provider record-ID value is copied into this report or its aggregate JSON.

## Per-area result

Counts are released records, not verified businesses. There is no confidence/operating-status filter. “Additional category” is a conservative spatial evidence candidate in the stated crosswalk; it is not verified entity novelty, exclusive building use or a quality grade. The untested-category column prevents extrapolating that result to the whole Places taxonomy.

| Area | Places | Inside held footprint | Unique / ambiguous hosts | Additional category candidates | Of those, unique footprint | Categories not crosswalked | OSM-absent-family places |
|---|---:|---:|---:|---:|---:|---:|---:|
| Sloan’s Lake extended | 567 | 345 (60.8%) | 345 / 0 | 109 | 44 | 403 | 4 |
| Lakeview | 444 | 292 (65.8%) | 292 / 0 | 101 | 57 | 309 | 4 |
| Wilmette | 98 | 44 (44.9%) | 44 / 0 | 13 | 4 | 78 | 11 |
| West Highland | 207 | 140 (67.6%) | 140 / 0 | 25 | 11 | 151 | 4 |
| Greenville Downtown | 2,367 | 1,814 (76.6%) | 1,804 / 10 | 192 | 117 | 1,988 | 16 |

Wilmette’s 44 contained records comprise 32 in OSM footprints and 12 in held non-OSM Overture footprints; every other area’s containment is in OSM footprints. Greenville has ten ambiguous overlapping-footprint hits; no host is chosen for them. A8’s outline-selection/merge convention is reused, so containment is against its held-core footprint set, not new Overture Buildings downloads.

## Top 15 primary taxonomy categories

Primary categories only, ordered by count descending then category ID ascending; descendants are not rolled up in this table. Missing primary labels are reported separately, not counted as a category.

| Area | Top 15: category (records) | Missing primary |
|---|---|---:|
| Sloan’s Lake extended | `beauty_salon` (17); `hair_salon` (16); `historic_site` (14); `real_estate_service` (10); `barber` (9); `park` (9); `auto_dealer` (8); `restaurant` (8); `health_care` (7); `medical_spa` (7); `atm` (6); `coffee_shop` (6); `fast_food_restaurant` (6); `financial_service` (6); `gym` (6) | 12 |
| Lakeview | `bar` (10); `restaurant` (10); `womens_clothing_store` (10); `atm` (9); `health_care` (9); `bank_or_credit_union` (6); `coffee_shop` (6); `flowers_and_gifts_store` (6); `gym` (6); `pizza_restaurant` (6); `sports_bar` (6); `beauty_salon` (5); `clothing_store` (5); `contractor` (5); `dental_clinic` (5) | 8 |
| Wilmette | `automotive_repair` (3); `chiropractic` (3); `gas_station` (3); `park` (3); `youth_organization` (3); `art_gallery` (2); `atm` (2); `contractor` (2); `elementary_school` (2); `gym` (2); `historic_site` (2); `money_transfer_service` (2); `psychology` (2); `real_estate_agent` (2); `acupuncture` (1) | 5 |
| West Highland | `real_estate_agent` (32); `american_restaurant` (7); `clothing_store` (4); `flowers_and_gifts_store` (4); `acupuncture` (3); `cafe` (3); `elementary_school` (3); `fashion_boutique` (3); `historic_site` (3); `legal_service` (3); `marketing_agency` (3); `mexican_restaurant` (3); `obstetrics_and_gynecology` (3); `pizza_restaurant` (3); `post_office` (3) | 5 |
| Greenville Downtown | `real_estate_agent` (112); `real_estate_service` (78); `attorney_or_law_firm` (66); `legal_service` (58); `financial_service` (51); `historic_site` (40); `restaurant` (40); `insurance_agency` (35); `corporate_or_business_office` (32); `software_development` (31); `bank_or_credit_union` (30); `mortgage_lender` (30); `business_consulting` (29); `information_technology_company` (28); `professional_service` (27) | 102 |

## A8 baseline and new category evidence

A8’s [summary](landmark-classification-summary.md) and [reproduction code §§8–9](landmark-classification.md#8-reproducible-source-census) are the baseline. The exact fenced-code hashes are pinned in the tool and receipt. Restaurant, bar, cafe, clinic, school, hardware and gas vectors reproduce A8 exactly in the original five-core order; the four unchanged hold-outs keep their original extent. Sloan’s baseline was the **1,600 × 1,200 m original core**, not the requested enlarged box. The same predicates are rerun on the new source and extended extent before Places comparison. Do not claim the increase caused by new Places if it comes from the larger source area.

| Family | A8 original Sloan’s OSM | Extended Sloan’s OSM |
|---|---:|---:|
| restaurant | 8 | 33 |
| bar | 2 | 9 |
| cafe | 1 | 2 |
| clinic | 3 | 5 |
| school | 0 | 13 |
| hardware | 0 | 1 |
| gas | 0 | 1 |

Each cell below is **A8 OSM tagged records in the same extent / Places family records / additional-category candidates**. This is not raw subtraction: one entity can have multiple OSM records; one OSM building can host several Places; some Places are co-located, closed, wrong or duplicated.

| Family | Sloan’s extended | Lakeview | Wilmette | West Highland | Greenville Downtown |
|---|---:|---:|---:|---:|---:|
| restaurant | 33 / 38 / 24 | 17 / 44 / 27 | 0 / 1 / 1 | 10 / 22 / 9 | 89 / 143 / 42 |
| cafe | 2 / 6 / 5 | 5 / 10 / 6 | 0 / 0 / 0 | 4 / 4 / 1 | 22 / 24 / 11 |
| clinic | 5 / 27 / 11 | 2 / 33 / 32 | 0 / 8 / 8 | 4 / 12 / 1 | 7 / 49 / 42 |
| church | 0 / 2 / 2 | 4 / 3 / 2 | 3 / 1 / 0 | 1 / 2 / 1 | 13 / 19 / 12 |
| school | 13 / 9 / 3 | 0 / 1 / 1 | 4 / 3 / 1 | 2 / 5 / 4 | 6 / 10 / 6 |
| gas | 1 / 1 / 1 | 1 / 1 / 0 | 2 / 3 / 1 | 0 / 0 / 0 | 1 / 2 / 2 |
| hardware | 1 / 3 / 3 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 1 / 1 |
| bar | 9 / 9 / 3 | 7 / 19 / 13 | 0 / 1 / 1 | 0 / 4 / 4 | 28 / 41 / 20 |
| salon | 6 / 43 / 36 | 1 / 12 / 12 | 0 / 1 / 1 | 4 / 3 / 1 | 20 / 36 / 13 |
| grocery | 3 / 6 / 3 | 2 / 2 / 1 | 1 / 0 / 0 | 0 / 0 / 0 | 3 / 6 / 5 |
| hotel | 2 / 3 / 3 | 0 / 2 / 2 | 0 / 0 / 0 | 0 / 0 / 0 | 12 / 14 / 8 |
| hospital | 2 / 4 / 1 | 0 / 0 / 0 | 0 / 0 / 0 | 1 / 1 / 1 | 0 / 6 / 6 |
| university | 0 / 1 / 1 | 0 / 1 / 1 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 6 / 6 |
| library | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 1 / 1 |

**Fixed association rule:** decode the point’s unrounded WKB coordinate; select the requested Sloan rectangle or the manifest’s exact local ENU core; assemble OSM multipolygons with holes and retain A8’s richer non-conflicting duplicate view; use held non-OSM Overture footprints only under A8’s existing merge convention. No nearest-building snapping, buffering, manual moves or name/brand guessing. Count all footprint hits; unique-hit enrichment is reported separately from ambiguous/outside hits.

For an explicitly crosswalked family, OSM corroboration is a matching explicit tag on a containing host outline, a matching OSM point in that same host, a matching tagged polygon containing the Places point, or a same-family OSM point within **15 m**. The 15 m threshold is a documented research heuristic, fixed across all areas; it is not calibrated and can over-corroborate adjacent tenants. Records lacking this evidence are additional-category **candidates**. “OSM-absent-family places” is the union of records whose mapped family had zero A8 tags anywhere in that core; it can overlap several families, so no summed-family double count. Those records can still be inaccurate.

Crosswalk uses `taxonomy.primary` plus its ancestor hierarchy; unrelated alternates do not change the family count. Restaurant excludes the separate fast-food branch, cafe includes `cafe` and `coffee_shop`, clinic/practice rolls up `outpatient_care_facility`, and hardware uses exact hardware/home-improvement descendants rather than every home/garden store. Broad categories such as `health_care`, real-estate services and generic businesses remain unmeasured for enrichment; no class is invented from a footprint or name. Full family counts and all primary frequencies are in [aggregate JSON](overture-places-five-areas.json).

## Actual record fields and completeness

All five raw files have the same 18 columns. Values below count records with at least one non-null/non-empty leaf; optional structs with only null leaves do not count as populated. A column’s presence in Parquet is not a guarantee its value exists. Nested Parquet types are retained in the aggregate JSON.

| Column | Meaning | Sloan’s / Lakeview / Wilmette / West Highland / Greenville |
|---|---|---|
| `addresses` | Freeform/locality/postcode/region/country | 567 / 444 / 98 / 207 / 2367 |
| `basic_category` | Coarser category | 555 / 436 / 93 / 202 / 2268 |
| `bbox` | Point bounds (float precision differs from WKB) | 567 / 444 / 98 / 207 / 2367 |
| `brand` | Brand names/Wikidata | 68 / 75 / 9 / 11 / 166 |
| `confidence` | Existence confidence, not category or location accuracy | 567 / 444 / 98 / 207 / 2367 |
| `emails` | Contact emails | 180 / 166 / 41 / 91 / 751 |
| `geometry` | WKB point, longitude/latitude | 567 / 444 / 98 / 207 / 2367 |
| `id` | Full GERS UUID | 567 / 444 / 98 / 207 / 2367 |
| `names` | Primary/common/rule names | 567 / 444 / 98 / 207 / 2367 |
| `operating_status` | Open/closed/unknown | 454 / 361 / 79 / 154 / 1814 |
| `phones` | Contact numbers | 485 / 394 / 81 / 186 / 1977 |
| `socials` | Social URLs | 292 / 245 / 52 / 109 / 1050 |
| `sources` | Dataset, property, licence, update time, confidence and source record/provenance fields | 567 / 444 / 98 / 207 / 2367 |
| `taxonomy` | Primary, hierarchy and alternates | 555 / 436 / 93 / 202 / 2265 |
| `theme` | places | 567 / 444 / 98 / 207 / 2367 |
| `type` | place | 567 / 444 / 98 / 207 / 2367 |
| `version` | Feature revision | 567 / 444 / 98 / 207 / 2367 |
| `websites` | Website URLs | 462 / 395 / 84 / 184 / 1960 |

## What stays out of shipped classification packages

**Omit all four requested fields (`names`, `brand`, `phones`, `websites`) from a shipped classification payload under current policy.** Names/brands are barred by the repository’s no-business-name/no-brand/readable-sign rules and [A11 inventory Places row](../legal/data-licence-inventory-v1.md). Phone/website fields are unnecessary for classification and can expose sole-trader/personal contacts or account links; keep them out of the proposed payload, alongside emails/social links/freeform addresses/provider record IDs. This is a data-minimisation recommendation; the repository does not already impose a specific blanket statutory phone/website prohibition. Required plain-text **source attribution/NOTICE** identifiers remain separate and must not be stripped.

**ODbL is not a ban on names or contacts, and CDLA/Apache/CC0 do not make those four columns inherently unshippable forever.** The current Places guide states the theme has no OSM input. Provider-specific grants permit scoped internal analysis here. CDLA requires agreement text with shared Data; Apache requires its licence, applicable notices and change notices; CC0 is a waiver. Apache does not grant trademark rights. Source permission does not settle privacy, trademark depiction, a category’s truth or a future external product’s scope. [Official Places source/licence guide](https://docs.overturemaps.org/guides/places/#sources-and-licensing), [attribution register](https://docs.overturemaps.org/attribution/#places), [CDLA §§2–3](https://cdla.dev/permissive-2-0/), [Apache §§4,6](https://www.apache.org/licenses/LICENSE-2.0.txt).

Containment/corroboration against OSM is dependent analysis; separate tables or IDs do not establish proprietary independence. A shipped OSM-derived joined class/building database still needs the repository’s ODbL treatment and counsel review under [A11 brief A1/A3/A7/A8](../legal/lawyer-brief-v1.md) and [A8 §6](landmark-classification.md#61-9-october-addendum--separable-assertions-not-a-promise-of-proprietary-rights). The existing free database offer remains pending. **GREEN applies only to these verified source grants and internal intake; external release remains RED.** No raw record, join or category enters a shipped package in this task.

## Source provenance, quality and limitations

Release-specific STAC collection licence is `other`, not blanket ODbL/CDLA. Per-provider/property declarations and the retained register agree: Meta/Microsoft/PinMeTo/BrightQuery/DAC and Overture’s confidence/status properties declare CDLA 2.0; Foursquare declares Apache 2.0; AllThePlaces declares CC0. The complete observed provider set/counts for each area is in the aggregate receipt, and the exact register/STAC/licence/NOTICE snapshot hashes are in [intake provenance](../data-sources/overture-places-2026-09-23.1/intake.json). Full CDLA and Apache texts plus current Foursquare NOTICE accompany the local data/provenance. No licence is borrowed from the Buildings theme.

Live rights pages were retrieved on 10 October 2026, and are not a September release archive. The current Foursquare NOTICE says copyright 2026 while Overture’s register quotes 2024; both are retained and the release-specific notice reconciliation remains for A11 before external redistribution. The first metadata-only attempt stopped on Overture’s internal labels; their explicit CDLA property grants were then checked and retained before any raw row was written. No grant was guessed or weakened.

| Area | Closed / unknown status | Confidence <0.5 | Exact co-located groups / records | Query rows excluded by exact extent | Raw bytes | Pull seconds |
|---|---:|---:|---:|---:|---:|---:|
| Sloan’s Lake extended | 16 / 113 | 55 | 30 / 149 | 2 | 100,924 | 3.696 |
| Lakeview | 14 / 83 | 22 | 22 / 52 | 2 | 85,620 | 5.508 |
| Wilmette | 9 / 19 | 4 | 3 / 22 | 2 | 30,128 | 3.229 |
| West Highland | 10 / 53 | 26 | 15 / 49 | 3 | 46,270 | 1.901 |
| Greenville Downtown | 106 / 553 | 254 | 187 / 963 | 4 | 330,099 | 2.179 |

Zero duplicate GERS IDs in each selected area; co-located records are **not** proven duplicate businesses and were not deduplicated. Operating-status null means unknown, not open. Closed and low-confidence records stay in the requested source census; do not treat these counts as live/open businesses. No independent truth/position/tenant validation was performed. Footprint association is weaker where OSM or held Overture footprints are absent; extra point categories cannot supply architecture or an exclusive whole-building role.

Pull seconds are measured per-area bounded query/rights check/local Parquet write, not total wall time or transferred network bytes; metadata retrieval and the stopped probe are excluded. Raw subsets total 593041 bytes; full regional Parquet shards were not downloaded. Raw SHA-256/query bounds/input hashes are retained for reproducibility. Exact requested Sloan rectangle is used; other areas query a 2 m padded geographic envelope then select the unchanged local core, excluding source fetch buffers.

## Reproduction and checks

```sh
# General report tools only; no worldbake fetch/source registration.
uv run --script Tools/regionkit/places/pull.py --release 2026-09-23.1 --areas sloans-lake-extended lakeview-sheil-park wilmette-vattmann-park west-highland greenville-downtown --extent-config Tools/regionkit/data/package-extents.json --output Data/research/overture-places/2026-09-23.1
# Refuses an existing output unless resuming a stopped metadata pass; never overwrites raw subsets.
uv run --script Tools/regionkit/places/analyze.py --intake Data/research/overture-places/2026-09-23.1/intake.json --output docs/data/overture-places-five-areas.json
HEAVY_AGENT=A1 PYTHONDONTWRITEBYTECODE=1 scripts/heavy.sh "Places offline controls" uv run --with duckdb==1.5.6 python -m unittest discover -s Tools/regionkit/places -p "test_*.py" -v
```

Focused controls cover holes, overlapping hosts, nearby different-category points, the fixed proximity boundary, taxonomy ancestors/alternates, byte-order WKB, nested null fields and unknown/conflicting/missing source grants. All nine focused controls pass under the heavy wrapper (0.007 s test execution; admitted at load 4.49 after the P2 job released its lock); owned lock released. No subagents. The redundant post-rebase test was cancelled while queued: only tracking text changed; all analysis/control code and aggregate output are byte-identical to the nine-test passing revision. Post-rebase raw/source hashes, grants and aggregates were independently rechecked. No captures/scoreboard are applicable to a report-only intake that changes no loaded data or render path.

Used: handoffs latest A1/A8/A11 entries; landmark-classification-summary table; landmark-classification §§1,6,8,9; sloans-lake-extended contract/source coverage; data-licensing §§1–3; legal data-licence-inventory Places row; lawyer-brief A1/A3/A7/A8; web-credits-answers §2; current DECISIONS and source/routing/MOCKS registry text; official Places schema/guide/taxonomy, STAC 2026-09-23.1 and licence/NOTICE URLs in intake. Mock: none; data research only, registry text read and no image claimed. Deviation: uncalibrated 15 m corroboration heuristic, limited crosswalk, no independent truth or external clearance.

## Files touched and handover

`.gitignore`; `Tools/regionkit/places/{pull.py,analyze.py,crosswalk.json,test_analysis.py}`; this report and aggregate JSON; `docs/data-sources/overture-places-2026-09-23.1/{README.md,intake.json,CDLA-Permissive-2.0.txt,Apache-2.0.txt,Foursquare-NOTICE.txt}`; additive A1 tracking/handoff entries and only the A1 STATE row. No source registration or renderer-consumption entry: Places remains report-only/not loaded. Existing Sloan’s extended delivery and all other lane rows remain authoritative. Future consumer work requires separate authorization, a reviewed field allowlist/association contract and A11’s external-release checks.
