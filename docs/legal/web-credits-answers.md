# Answers to A10's five web credits questions

Checked **10 October 2026** against repository baseline `cdcf70a`. **Facts and questions only; not legal advice or release approval.** A10 `fa4c15f` wired the web data-credit overlay; that is implementation evidence, not a completed source inventory or a working ODbL offer. No notice wording, legal terms, provider mark or runtime code is drafted/wired here.

## R's missing-items list

1. **A real data-download address and the matching archives:** no working offer URL was identified. A download page is an engineering task; the lawyer decides the offer's legal scope and sufficiency.
2. **A notice list tied to each actual package:** retained Overture inputs identify release `2026-09-23.1` and three upstream datasets, but a complete release-pinned, export-specific notice reconciliation is missing. Source collection is engineering; licence/notice interpretation is counsel's question.
3. **Dates and provenance carried into final credits:** USGS and NAIP facts exist below. Their binding to each final archive is missing. The Census product is identified, but its exact product/service grant and applicable notice remain a counsel question.
4. **Credits for inputs outside the map-source list:** NAIP is a demonstrated selection gap. Catalogue/night-light/live-feed applicability is surface-dependent; the main package viewer, bakeoff and separate live-sky demo must not be treated as one runtime. The final host needs an input/notice record.
5. **A complete software/provider notice payload:** three.js text exists, but no approved complete web payload was identified. Engineering must collect and ship the actual dependency texts; counsel settles uncertain NOTICE requirements, source grants and any provider-mark conflict with the unbranded-content policy.

## 1. Free version-matched ODbL offer

**Known:** `Sources/WorldGen/Profiles/credits.json` retains `ODBL_OFFER_URL_PENDING` / `placeholder: true`. `WorldPackage.swift` writes `dataLicense.offer.status = pending` when no URL exists. The retained local Sloan sample described below also says pending. A10's overlay states that the draft does not claim a download exists. No placeholder becomes an operational URL through this audit.

**Minimum proposed page/content checklist for review, not legal terms:** one stable public address linked from the viewer and package notice; a list of every externally delivered package version with area ID, generator/version identifier, archive hash and direct free download; an explicit file index identifying which files comprise the offered database; the ODbL text/link and preserved source/credit/change notices; version-pinned provenance sufficient to connect an archive to the displayed package; usable download instructions and any alteration-file reconstruction inputs. Keep old delivered versions accessible under a documented retention plan. Test an unauthenticated download of the exact version and verify its hashes. A hash index, stable address and retention plan are proposed engineering evidence, not asserted verbatim licence requirements.

The repository's current route is a data-only ZIP, excluding separately licensed software/assets, in [data-licensing §§1–3](../data-licensing.md). Its listed data scope and the generated sample include world/chunk scene data, meshes, instances, collisions, environment and map data; the exact shipped `dataLicense.derivativeDatabase` list is the candidate archive index. Do not substitute an OSM extract or a source-file link for that candidate without counsel's answer. A signed app/archive was not supplied.

**[W1] Lawyer:** Does that exact archive satisfy [ODbL §§4.6–4.7](https://opendatacommons.org/licenses/odbl/1-0/), or should it use the qualifying alterations/method route; which reconstruction inputs, upstream contents and unrestricted parallel access must accompany it, including invite-only and store delivery? Which files may remain separately licensed? **Engineering:** choose host/address, assemble versioned data archives and prove download/version matching. No hosting/publishing is authorized by this docs task.

## 2. Overture release and upstream notices per package

**Known input facts:** `Data/areas/{lakeview-sheil-park,wilmette-vattmann-park,kenilworth-station,winnetka-village-green}/manifest.json` record Buildings release **2026-09-23.1**. Existing local `overture-buildings.json` files confirm that release and retain these dataset summaries; only metadata was inspected, no new source fetched:

| Area input | Building records | Microsoft ML Buildings source occurrences | OpenStreetMap occurrences | USGS Lidar occurrences |
|---|---:|---:|---:|---:|
| Lakeview | 2,895 | 357 | 2,871 | 2,188 |
| Wilmette | 1,279 | 1,249 | 49 | 27 |
| Kenilworth | 841 | 826 | 16 | 14 |
| Winnetka | 607 | 569 | 53 | 28 |

These source counts overlap within records; they are not additive, and are **input-level**, not counts of records surviving export. The input summaries label Microsoft/OSM ODbL and omit a separate licence field on USGS occurrences. Absence of a field is not a grant. Other retained area manifests do not list Overture; this does not prove every later generated/context artifact excludes it.

Existing manifest/overlay wording is: “© OpenStreetMap contributors, Overture Maps Foundation; Microsoft Global ML Building Footprints (ODbL); USGS 3D Elevation Program”. This is a recorded string, **not a completeness approval**. Keep the theme grant separate from the current direct Global ML release's grant.

The readable [Overture attribution register](https://docs.overturemaps.org/attribution/) lists Buildings as ODbL and includes OSM, Microsoft and USGS alongside other potential contributors. Its current page is not an archived notice snapshot for every 2026-09-23.1 record. No inference is made that other contributors appear in these four inputs or that the short combined string fulfills every applicable notice.

**Missing engineering evidence:** export hash/version → actual retained record/property source set → release-specific notice/register snapshot → exact notice texts/licence links. `world.json.sources` carries release via `dataTimestamp`, but its umbrella attribution does not encode per-property notice selection. A10 capture evidence names two manifests; their exact full-scoreboard `world.json` artifacts were not found at the capture tool's expected paths in the primary checkout, so their notices cannot be certified from a different local package.

**[W2] Lawyer:** For those retained/exported Overture records, which exact upstream notices and grants survive transformation, and is the proposed combined attribution sufficient once reconciled against a release-pinned register? **Engineering:** pin that register and export-specific source set; supply missing artifact hashes. Do not label unverified wording “approved”.

## 3. USGS, NAIP and Census

### USGS facts available now

[Building-height documentation](../data/building-heights.md) and `Tools/regionkit/lidar/data/observed-heights.json` retain the following point-cloud identities/dates and delivered vertical units. Survey dates come from previously checked source tile metadata, not a new survey or per-point timestamps.

| Used/reviewed area | Point-cloud project / delivery | Recorded acquisition | Terrain metadata separately retained |
|---|---|---|---|
| Sloan; same Denver source family for West Highland | CO_DRCOG_2020_B20 / CO_DRCOG_2_2020 | 26 May–12 June 2020 | `Data/areas/<area>/elevation/metadata.json`: CO_DRCOG_2020_B20; 1m DEM clips published 10 February 2022 |
| Lakeview | IL_4_County_QL1_LiDAR_2016_B16 / USGS_LPC_IL_4County_Cook_2017_LAS_2019 | 16 April–7 May 2017 | IL_4_County_QL1_LiDAR_2016_B16; native DEM clip publication 18 November 2024 |
| Greenville | SC_SavannahPeeDee_2019_B19 / SC_SavannahPeeDee_2_2019 | 5–22 January 2020 | SC_SavannahPeeDee_2019_B19; native DEM clip publication 6 May 2022 |

Metadata retains NAVD88 / EPSG:5703 and metre-valued outputs; Cook/Greenville source LAS units were survey feet but delivered EPT is already metres. Terrain metadata also lists the actual multiresolution bands and source URLs: use the full file for the archive, not only this native-clip summary. Do not interchange publication and acquisition dates or assume a point-cloud date covers every DEM band.

The available acknowledgement is “Data available from U.S. Geological Survey, National Geospatial Program.” Prior inventory records it as requested acknowledgement, not an invented licence condition. Describe roof p95/p50/eave-minus-ground measurements separately from terrain clipping/resampling/slope processing. Missing: the final export's complete contributing tile/band/height-source list, retained metadata hashes and attachment to credits. General USGS policy was unreadable in this check; prior [height-source check](height-sources-check.md) remains the policy evidence, with its limits.

### NAIP facts available now

`Tools/regionkit/aerial/results/canopy_areas.json`, its data configuration, [aerial research §§12–13](../research/aerial.md), and `Data/areas/<area>/canopy-blocks.json` provide:

| Area | Recorded acquisition / resolution | Recorded item ID(s) |
|---|---|---|
| Sloan | 25 September 2023 / 0.3m RGBN | `co_m_3910524_ne_13_030_20230925_20240104`; `co_m_3910516_se_13_030_20230925_20240104` |
| Lakeview | 10 July 2023 / 0.3m RGBN | `il_m_4108703_ne_16_030_20230710_20240209` |
| Evanston | 10 July 2023 / 0.3m RGBN | `il_m_4208759_sw_16_030_20230710_20240209` |
| Wilmette, Kenilworth, Winnetka | 10 July 2023 / 0.3m RGBN | `il_m_4208759_nw_16_030_20230710_20240209` |

These are committed study provenance, not a claim of new imagery or complete coverage for West Highland, Greenville or Sloan extended. Acquisition dates differ from item delivery-date suffixes. Provider access: Planetary Computer STAC `naip`, windowed imagery reads; Sloan mosaics two quarter-quads. Processing: canopy masks, OSM-derived exclusions/block geometry, aggregate/block shares and profile tree-density inputs; method/version and calibration limits remain in the referenced files. Existing credit: “NAIP imagery provided by USDA Farm Service Agency”. Missing: export-specific proof of which area/profile/borrowed measurements actually contribute, retained processing/metadata hashes and credit selection independent of source-string matching.

### Census facts and unresolved grant

The actual retained subset is **TIGERweb layer 7, 2020 Census ZIP Code Tabulation Areas**, not a demonstrated downloaded TIGER/Line shapefile. `zcta.json.source` records retrieved **2026-10-06**, vintage 2020 and that service's query URL; [zcta README](../../Tools/regionkit/zcta/README.md) specifies context-box clipping, boundary geometry and only the ZCTA5 attribute, with recorded simplification where applicable. The readable [service metadata](https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/PUMA_TAD_TAZ_UGA_ZCTA/MapServer/7?f=pjson) identifies January 1, 2020 vintage and “Source: U.S. Census Bureau”. This is geographic classification data, not population estimates or individual respondent data.

The repository calls it public domain but explicitly records that exact product permission was not stated on pages checked. Its `licenseURL` points to [Census Data API terms](https://www.census.gov/data/developers/about/terms-of-service.html). That page has its own attribution and modification provisions; applicability to this TIGERweb service was not established. Generic [citation guidance](https://www.census.gov/about/policies/citation.html) does not answer that scope question. The existing “TIGER/Line ... (2020)” credit is therefore not promoted to an exact approved service notice.

**[W3] Lawyer:** Which product/service grant and notice govern this clipped TIGERweb subset, including the API terms' scope and modification language, and which USGS/NAIP item conditions and changes must accompany the actual shipped derived data? **Engineering:** provide the final tile/profile/subset and artifact evidence above; counsel cannot supply missing capture artifacts or measurement provenance.

## 4. Sources outside world.json.sources

**Demonstrated local sample:** `Generated/package/sloans-lake/world.json` in the primary checkout, SHA-256 `2bf693eaaa26cc943f5301c6b20ff17bd078c4a5d8266bdbd5ebece9ccc651e6`, lists OSM, Census and terrain-slope sources; `credits` separately includes `naip`. Its offer is pending. This is a retained local sample, **not** A10's missing full-scoreboard artifact or a public shipped release.

`web/credits.js` selects notices by searching **only** `manifest.sources`, with OSM always present; it does not read `manifest.credits` or host feed attribution. Thus the retained sample's NAIP entry would not be selected. The exporter merges static/profile credits separately from extra Census/terrain sources. A complete notice selection contract must cover both channels and actual host inputs.

| Surface / input | Facts established | What is missing |
|---|---|---|
| Main `web/index.html` / `web/src` package sky | `WorldPackage.swift` generates sky PNGs via `WorldGen/SkyImage.swift`; `web/src/lighting.js` loads those images. Reviewed generator uses authored gradient/cloud/sun inputs; no catalogue, Black Marble or relay ingestion is traced on this path | Final loaded environment/sky/version evidence, and profile-derived credits. Do not claim every possible external host has no extra source |
| Bakeoff sky | `web/bakeoff/main.js` and `sky.js` read calibration/weather pack gradients; A10's ladder capture uses this separate renderer path | Host/sidecar/context/profile input manifest beyond the package sources; pack “weather” names are not proof of a live provider |
| Catalogue stars | Native/environment catalogue and `STARS-NOTICE.md` exist; not traced into reviewed main web sky rendering | If enabled in web, pin actual catalogue, provenance, required/courtesy notice scope and any displayed star-name notice; catalogue's origin-licence caveat/CDS block remains unresolved. No individual names reproduced here |
| Black Marble | Livefeed grid files/docs identify VNP46A4.002, 2025 annual snow-free near-nadir composite, baked 7 October 2026; Denver tiles h07v05/h07v04, derived 30-arcsecond means from 15-arcsecond data | No traced use in reviewed main web world; if enabled, exact product citation/access record, policy and subset notice. NASA policy unreadable in this check |
| Live feeds / weather | `Tools/livefeeds` contains source-specific relay attribution; `web/live/README.md` is a separate fixture-only sky module/demo with no runtime provider fetch | No cleared provider/live payload established for main web. Enabled host feeds need source, age, terms and attribution/mark payload; presence of relay code alone does not prove display |

**[W4] Lawyer:** If catalogue stars, Black Marble, weather or relay feeds are enabled, which exact grants/notices apply to the pin/version/output, including the catalogue caveat and required provider marks? **Engineering:** identify actual active runtime inputs, pass host attribution to credits and distinguish demo/stale/live. Do not wire candidate notices just because sources appear in research.

## 5. Software NOTICE texts and provider marks

**Known:** `web/package.json` and lock pin **three.js 0.180.0** and build-only **esbuild 0.25.10**. The reviewed r180 [three.js LICENSE](https://github.com/mrdoob/three.js/blob/r180/LICENSE) is MIT; the installed primary-checkout version matches and its LICENSE text matches the retained `threejs.licenseText` entry in `Sources/WorldGen/Profiles/credits.json`. The static entry is a text source, not proof it is shipped. The current overlay has only data-source entries. `web/build.mjs` uses `legalComments: 'none'` and copies index/demo/credits files; it does not explicitly copy a software notice payload. No approved complete **web** software/NOTICE bundle or provider-mark payload was identified.

**Payload evidence engineering must supply for review:** the exact release dependency/import inventory; unchanged full licence/copyright texts for shipped code; required supplied NOTICE text, where applicable; component versions and text hashes; a named distributed notice file and a viewer route to it; matching artifact/file-list evidence. Distinguish build tools from runtime code and optional font/loader/decoder assets: package installation does not prove every installed asset is shipped. Conversely an import/asset outside package dependencies must not disappear from this list. Do not substitute a credits label/link for a text payload where the component's grant calls for text. Earcut's Swift entry is app-only in the static catalogue; web's three.js-contained components need the actual runtime review, not automatic copying of an unrelated native notice.

**Provider marks:** the existing catalogue records weather attribution/mark as host-supplied. No active provider requiring a mark was established in the main web path. If one is enabled, obtain the actual prescribed asset/text/link and applicable placement from the host/provider terms; do not fabricate a logo or silently replace a prescribed mark with text. Engine unbranded content and legal attribution are a counsel/owner policy question, not waived by this audit.

**[W5] Lawyer:** For the actual shipped web dependency/asset and provider list, which full licence/NOTICE texts and mandatory marks/placements are required, and what lawful option resolves any conflict with the no-brand/no-personal-data output policy? **Engineering:** submit exact payload and artifact evidence. This document supplies neither legal terms nor payload approval.

## Evidence, checks and limits

Read A10 [integration/questions](web-credits-integration.md) at `fa4c15f`, [machine evidence](web-credits-evidence.json), [brief](lawyer-brief-v1.md), [draft](credits-draft.md), [inventory](data-licence-inventory-v1.md), [height check](height-sources-check.md), data policy, building-height/aerial/zcta/live-sky documentation; area manifests, canopy/elevation/height metadata, catalogue notice, web credit/build/runtime files and exporter source paths named above. Retained local Overture summaries and one local package were read as metadata only; no new data fetched or source records reproduced. Routing: DECISIONS, STATE, INDEX, INTEGRATION, REFERENCE-MAP and MOCKS registry; no visual mock/image used or score claimed. A10's overlay results remain its evidence, not rerun here.

USGS National Map policy, Census copyright page and NASA Earthdata policy requests returned tool errors; no blocked route bypassed. Readable primary texts are linked above. A current source register is not proof of a historic release register. No app/store archive, live provider payload, complete generated release or offer endpoint was certified. Questions W1–W5 are carried into the lawyer brief. Only this answer document, the brief and the handoff entry change; no terms, source acquisition, code, hosting or release approval.
