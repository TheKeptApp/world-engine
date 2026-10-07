# Japan showcase v1

Research date: **2026-10-07**. **CONDITIONAL GO for two bounded, exterior, public-street showcases; not a nationwide launch clearance.** Use PLATEAU roof-aware geometry where present, OSM streets/POIs, current observations and faithful official weather relay. Start Tokyo first, Kyoto second. This follows the country shortlist's Japan “later/showcase” rationale, updated for the requested **web-first licensing plus iPhone** scope rather than carrying over its iOS-first launch ranking.

Inputs read: country-shortlist-v1 README/sources and WorldEngine visual direction. Research used lead plus data, weather/live-feed and legal sub-agents; lead covered look/culture. No signups, supplier contact, accepted agreements, git operations or renderer changes. No extract completeness audit, mesh conversion, forecast-service ruling or device benchmark was performed.

**Evidence convention:** VERIFIED means the linked primary source supports the stated page/dataset/law fact on this date; not complete product legal clearance. INFERENCE/JUDGMENT/ASSUMPTION identify recommendations and interpretations. UNVERIFIED identifies missing evidence. GO is scoped permission/readiness; CONDITIONAL/HOLD needs the named gate; NO-GO means the proposed use conflicts with reviewed standard rules, not that a negotiated route is impossible. Japanese originals and actual selected resource notices control; English translations and short quotes are navigation aids.

## Go/no-go by item

| Item | Own showcase/app | World State / client asset API | Gate |
|---|---|---|---|
| PLATEAU exterior geometry | CONDITIONAL GO | CONDITIONAL GO derived meshes/tiles | Item license, attribution and Survey Act applicability; confirm pilot LOD |
| OSM roads/POIs/buildings | GO under ODbL | GO with applicable database/Produced Work duties | Audit combination architecture; retain visible credit |
| GSI terrain/maps | CONDITIONAL GO | HOLD self-hosted derivatives | Selected basic/public-survey approval/exemption route |
| JMA observations | GO audited product | GO copyright-wise | Pin endpoint/product provenance and age |
| Faithful official JMA forecast relay | GO | CONDITIONAL GO faithful relay | Preserve official area, values, issue/valid time; do not generate own prediction |
| Own Japan point/time forecast from JMA/ECMWF | NO-GO without required authorization | NO-GO without authorization | JMA licence or licensed-provider arrangement; foreign hosting is no exemption |
| Official warnings/quake/tsunami contextual relay | GO with provenance | CONDITIONAL GO | Corrections/cancellations/regions; HOLD promised emergency/EEW delivery |
| ECMWF model fields | GO copyright-wise | GO copyright-wise | Japanese forecast-service presentation still needs separate review |
| Toei bus static + realtime CC BY | GO | GO with attribution | Route coverage, timestamps, access/quota checks |
| ODPT Basic rail/bus | CONDITIONAL app GO | NO-GO reusable raw/reconstructable feed absent written permission | Provider-specific terms and frontend coordinate distribution |
| Kyoto City Bus static | CONDITIONAL app GO | NO-GO reusable raw feed absent permission | Basic/provider terms; no realtime GPS claim verified |
| ODPT Challenge2026 | Contest prototype only | NO-GO durable raw API foundation | Entry/free functionality; expires March12,2027 |
| Manual public-area browsing | GO low-data design | GO public nonpersonal inputs | No resident/route identity assumptions |
| Account-linked precise routes/location | HOLD product privacy review | HOLD sharing/reidentification review | APPI and cross-border design |
| Landmark exteriors | CONDITIONAL GO | CONDITIONAL GO | Dataset license, art/branding and source access conditions |
| Temple interiors / copied art / logos | HOLD clearance | HOLD clearance | Not needed for pilot |

The matrix is a lead judgment supported by [datasets.csv](datasets.csv) and [sources.md](sources.md), which retain exact resource-level rights, quotations and limitations.

## PLATEAU: what actually exists

VERIFIED: the official directory lists **306 entries across45prefectures**, with page update label **2026-05-11**. The live HTML yielded306unique URLs and306unique prefecture/name pairs. Entries include wards, a Tokyo23-ward aggregate, Takeshiba sample and Osaka Expo: **306 is not a distinct-municipality count** or uniform coverage guarantee. The complete prefecture/name/link list is in the [sources appendix](sources.md#complete-plateau-directory-snapshot). [Official directory](https://www.mlit.go.jp/plateau/open-data/).

VERIFIED: live directory links now point to individual Tokyo wards FY2025, Kyoto FY2025 and Osaka FY2025; the older Tokyo23-ward aggregate is FY2022. Cached search/page representations showed some older city links, so the directory appendix was extracted from live publisher HTML. Fiscal year, release timestamp, survey date and later edits are different dates. General update intervals are roughly1–5years; varies locally. [FAQ](https://www.mlit.go.jp/plateau/faq/).

| Area | Verified catalog evidence | What this does not prove |
|---|---|---|
| Tokyo pilot | TaitoFY2025 LOD1/2/3/4,7building tile records; BunkyoFY2025 LOD1/2,3records | Every Yanaka/Sendagi building has roof/detail/interior data |
| Kyoto | FY2025 LOD1/2/3,35building tile records; official index LOD1urbanized185.00km², LOD2building21.89km², LOD3combined feature0.022km² | Whole city is detailed machiya; LOD3 area is not solely buildings |
| Osaka | FY2025 LOD1/2/3,47building tile records | Full high-LOD coverage; exact FY2025 high-LOD extent not verified |

Record counts are tile asset layers, not building counts. The catalog has7,776records overall in the inspected snapshot. Kyoto's supplemental municipal LOD1 FBX/FGDB resources were updated August31,2026 and expressly CC BY4.0. [Live catalog](https://api.plateauview.mlit.go.jp/datacatalog/plateau-datasets), [Kyoto delivered index](https://assets.cms.plateau.reearth.io/assets/0f/4b712b-5ca1-476d-a5be-df67c70d8a88/26100_indexmap_op.pdf), [Kyoto exports](https://data.city.kyoto.lg.jp/dataset/00661/?page=1).

### LOD, roofs, textures and formats

VERIFIED: CityGML is standard; selected areas also offer experimental FBX, OBJ or FGDB. Delivery offers3D Tiles/MVT and CityGMLZIP. Most tiles1.0, someFY2025+1.1. Product `spec:5.0` is not automatically CityGML encoding5. [Delivery docs](https://docs.plateauview.mlit.go.jp/datasets/3d-tiles/), [CityGML delivery](https://docs.plateauview.mlit.go.jp/datasets/citygml/).

| LOD | Practical geometry interpretation |
|---|---|
| 0 | Footprint / projected roof-edge representation |
| 1 | Extruded box-like solids; abstracted height; roof shape not guaranteed |
| 2 | Roof/wall/ground surfaces and roof geometry; preferred Style B baseline |
| 3 | More detailed exterior elements/openings, usually localized |
| 4 | Older convention includes interiors; newer CityGML3.0 interior layers require separate metadata interpretation |

Textures are independent of LOD; textured LOD1 and untextured LOD2/3 variants can coexist. Do not infer detailed facades or full photographic third-party clearance from a high LOD. [PLATEAU tutorial](https://www.mlit.go.jp/plateau/learning/tpc03-3/), [specification portal](https://www.mlit.go.jp/plateaudocument/).

VERIFIED copyright route: PLATEAU's current site policy defaults to PDL1.0 unless another notice applies, expressly allows CC BY4.0-compatible use, and identifies municipal copyright. CC BY permits commercial copying/redistribution/adaptation with source, license and change notices; not exclusive ownership or additional restrictions on licensed material. This supports simplified derived meshes/tiles **copyright-wise**, while the policy separately retains public-survey restrictions. See exact quotes in datasets.csv. [Site policy](https://www.mlit.go.jp/plateau/site-policy/), [CC BY legal code](https://creativecommons.org/licenses/by/4.0/legalcode.en).

**JUDGMENT pipeline:** use semantic CityGML/no-texture LOD2 first; preserve roof planes and metric footprint positions, remove photo appearance, interiors and excessive triangulation. Verify horizontal/vertical datum per package, rather than hardcoding a tutorial CRS. Pin source URL, release, actual survey vintage when known, checksum, license, approval status and transformations. One chosen building geometry per matched building; avoid duplicate OSM+PLATEAU extrusion. Keep municipal geometry and OSM network provenance distinct; mere file separation does not settle ODbL combination duties. [Coordinate tutorial](https://www.mlit.go.jp/plateau/learning/tpc03-4/).

### OSM comparison: Tokyo, Kyoto, Osaka

VERIFIED: OSM's PLATEAU import workflow exists; Osaka has a historical completion record from2024. **UNVERIFIED:** current footprint completeness, height-tag rate, roof-tag rate, road width/access coverage and import overlap in all three cities. No numeric completeness claim is made. PLATEAU supplies verified roof-aware layers; an OSM footprint-only fallback cannot be assumed equivalent. OSM is the practical connected street/path/POI layer, but current topology/business names still need extract checks. [OSM import documentation](https://wiki.openstreetmap.org/wiki/JA:MLIT_PLATEAU/imports_outline), [ODbL](https://www.openstreetmap.org/copyright).

**JUDGMENT gate:** for each600m pilot and an Osaka comparison window, pin same-date OSM extract and PLATEAU release; compare matched/unmatched footprint area/count, valid heights, LOD2 intersection and street connectivity. Report findings separately, not citywide percentages inferred from one block. Measure stale/demolished buildings, alignment and narrow-lane elevation/steps. No raw dataset downloads were tested here.

## Weather and live-feed boundaries

VERIFIED: JMA's current English guidance states:
> a license is required regardless of whether the business operator is located inside or outside Japan.

That applies to performing Japan forecasts for Japanese users; faithful official relay is distinct. The foreign-operator guidance dates March31,2026 and relevant reform took effect May29,2026. Foreign applicants require domestic representation. Copyright openness does not remove this rule. [Current English guidance](https://www.jma.go.jp/jma/kishou/minkan/kyoka_en.html), [foreign guidance](https://www.jma.go.jp/jma/kishou/minkan/tekiyou.pdf), [reform](https://www.jma.go.jp/jma/press/2604/14a/20240414_seirei.html).

VERIFIED: JMA's FAQ distinguishes faithful official/licensed-provider relay, model-output display and independently generated forecasts. Road-surface/ground-temperature and snow-depth predictions can be regulated; pollen/bloom/lifestyle categories are not automatically treated the same. **INFERENCE:** a future scrubber depicting actual predicted local rain, wetness or snow can communicate a forecast visually. Style B graphics are no automatic exemption. **HOLD** exact future-rendering design pending JMA clarification or licensed-provider arrangement. [FAQ](https://www.jma.go.jp/jma/kishou/minkan/q_a_m.html).

VERIFIED: JMA XML public PULL can delay/stop; a minute refresh describes feed packaging, not emergency SLA. Faithfully relay official weather/tsunami warnings and earthquake information, preserving issue/update/cancel state and affected regions. Selected EEW message inclusion and entitled rapid delivery remain UNVERIFIED. JUDGMENT: contextual layer first, no safety-critical push promise. [XML precautions](https://www.data.jma.go.jp/developer/ryuui.pdf), [warning law](https://www.jma.go.jp/jma/kishou/info/ml-23.html).

VERIFIED: ECMWF's open subset is CC BY4.0, global, documented0.25°, four daily runs and approximately12recent runs. The announced9km subset upgrade must not be assumed deployed. Open licensing permits redistribution/derivation but does not replace Japan forecasting permission or JMA warnings. Full-catalog openness and free delivery are different. [Open data](https://www.ecmwf.int/en/forecasts/datasets/open-data), [terms](https://apps.ecmwf.int/datasets/licences/general/).

VERIFIED: ODPT Basic permits commercial apps but restricts reusable raw/copied/reconstructable redistribution under Article8(4) absent permission. Client-facing live coordinates deserve review too. Respect `odpt:frequency`, `dct:valid`, source/generated times, expiration, provider credit and translation notices. **GO** Toei static/realtime catalogs expressly CC BY4.0; **CONDITIONAL** Kyoto City Bus static Basic/provider terms; **NO-GO permanent reliance** on Challenge2026 expiring March12,2027. No nationwide live rail guarantee, permanent JR East rights or Kyoto bus GPS feed was established. [Basic terms](https://developer.odpt.org/terms/data_basic_license.html), [guidelines](https://developer.odpt.org/terms/data_basic_use_guideline.html), [Toei RT](https://ckan.odpt.org/dataset/b_bus_gtfs_rt-toei), [Kyoto static](https://ckan.odpt.org/dataset/kyoto_municipal_transportation_kyoto_city_bus_gtfs), [challenge](https://developer.odpt.org/challenge_license).

**JUDGMENT metadata:** sourceIssuedAt/observedAt, validAt/validUntil, receivedAt, original region/route IDs, observation/forecast/model/schedule category, corrections/cancellations and rights profile. Timetable animation is simulated, not observed live location. Section-level rail positions are not necessarily GPS. Degrade explicitly to stale/unavailable rather than inventing current conditions.

## Two recommended test areas and Style B treatment

**JUDGMENT — Tokyo: Yanaka Ginza plus adjoining Yanaka/Sendagi public lanes.** Start with approximately a 600 × 600 m data window centered on the shopping-street approach, expanding only after footprint and grade checks. The exact boundary and camera coordinates remain UNVERIFIED, not a committed survey. Official tourism sources establish a working independent-shop shotengai and narrow backstreets; Taito's guideline describes many 2–3-storey buildings and varied low-rise pitched-roof character. [Tokyo shops](https://www.gotokyo.org/en/spot/170/index.html), [backstreets](https://www.gotokyo.org/en/story/walks-and-tours/yanaka-and-nezu/), [Taito guidance](https://www.city.taito.lg.jp/kenchiku/toshikeikaku/keikaku/chikukeikaku/yanakatikukeikankeiseiGL.pdf).

**JUDGMENT — Kyoto: Nishijin, Itsutsuji-dori / Omiya-dori public streets and the Senryogatsuji vicinity.** Approximately a 600 × 600 m window, subject to the same validation. Official visitor guidance identifies Itsutsuji-dori for machiya exteriors; the municipal landscape plan documents textile-related mixed residential/commercial streets and a mixture of traditional and modern buildings. It is a living neighborhood, not an all-historic museum set. [Official exterior-view guidance](https://global.kyoto.travel/en/faq/detail.php?faq_id=1015), [municipal plan](https://www.city.kyoto.lg.jp/tokei/page/0000281270.html).

| Element | Tokyo pilot | Kyoto pilot | Evidence status / renderer rule |
|---|---|---|---|
| Building families | Low-rise detached/attached houses, shop-houses, small apartments and modern infill | Machiya with low upper storey or full two-storey form, workshops/shop-houses, modern infill | JUDGMENT family selection; no measured percentages. Preserve authoritative footprint/height and real tags |
| Roofs | Simple pitched and hipped volumes alongside flat roofs; compact eaves | Aligned tile eaves, main pitched roofs, street canopy; restrained ridge shape | Kyoto city verifies tile/eave/lattice/mushiko motifs. Tile color/ridge silhouettes use geometry and flat materials, no photo textures |
| Facades | Cream/plaster, muted siding, timber accents, modest shopfront glass | Timber lattice, cream earthen/plaster walls, gray tiles, deep eave shade | Palette is JUDGMENT; avoid applying machiya to all buildings |
| Street space | Narrow lanes, minimal setbacks; preserve steps/slope and mapped access | Tight frontage, deep lots, irregular surviving fabric within larger street network | Exact widths/setbacks UNVERIFIED until extract; do not add Denver sidewalks/lawns by default |
| Utilities | Poles, overhead-wire bundles, exterior AC boxes where supported | Selective poles/wires and compact exterior services | JUDGMENT procedural additions, not measured utility infrastructure; do not claim electrical clearance |
| Everyday props | Generic vending machine, bicycle stand, awning and delivery box | Restrained generic shop canopy, small planters, lattice details | JUDGMENT optional props; no real brand/logo, product packaging or resident nameplates |
| Greenery | Sparse street plants and localized larger green spaces, not a continuous boulevard canopy | Small planters/courtyard hints; larger trees in mapped green areas | JUDGMENT distribution; interiors/courtyards not exposed through private walls |

Kyoto city's heritage explanation documents lattice fronts, aligned tile edges and mushiko windows, while emphasizing variations by era and trade. Use those as silhouette cues rather than a detailed reconstruction of one private home. [Machiya motifs](https://kyoto-bunkaisan.city.kyoto.lg.jp/kyotoisan/nintei-theme/kyoumachiya.html).

**JUDGMENT — phone readability:** keep real road widths, footprint positions and roof profiles; simplify near-camera ornaments into a few reusable meshes. Prioritize roof/eave silhouette, facade shadow, compact frontage and utility rhythm. Only show major wire bundles near the camera; fade small wires before shimmer dominates. Use smooth rounded crown clusters with interior darkening and thick branching trunks. Place fictional, Japanese-reviewed category signs on selected shopfronts rather than illegible text noise or invented pseudo-kanji. At 5–40 m, one focal sign per facade plus one subordinate sign is a proposed cap, not a local rule. Signs/props must not conceal required attribution. Keep background silhouettes simple, street light pools readable, rain bright with sky reflection and foliage palettes blended continuously.

**JUDGMENT — assets first:** machiya lattice/eave/mushiko kit; narrow modern house/shop-house kit; poles/wires; unbranded vending machine/AC/planter set; sakura, ginkgo, zelkova and maple variants. No interiors or landmark hand-modeling are needed for the first pilot. Start with the existing v2 draw/triangle/GPU buckets; no benchmark or Japan tile conversion was performed in this research. Dense imported geometry and original photo textures are not automatically acceptable on an iPhone.

### Trees and seasons

VERIFIED: Tokyo's official street-tree guide lists cherry cultivars, ginkgo, zelkova, tulip tree and dogwood. This does not establish the species proportions on either pilot street. Add evergreen broadleaf/pine only from mapped species or a clearly labeled regional assumption; reserve maple-rich scenes for supported gardens/green spaces. Do not turn every street pink in spring or red in autumn. [Tokyo guide](https://www.kensetsu.metro.tokyo.lg.jp/park/ryokuka/hyoushi/hyoushi1).

| Station reference | Normal cherry opening | Normal full bloom | Actual 2026 opening / full bloom |
|---|---|---|---|
| Tokyo | March 24 | March 31 | March 19 / March 28 |
| Kyoto | March 26 | April 4 | March 23 / March 30 |
| Osaka | March 27 | April 4 | March 26 / April 3 |

VERIFIED: these JMA reference-tree dates are station observations/normals, not all-tree scenic peaks or forecasts. [Opening](https://www.data.jma.go.jp/sakura/data/sakura_kaika.html), [full bloom, 1991–2020 normals](https://www.data.jma.go.jp/sakura/data/sakura004_07.html). Use cultivar/location variation, current observed phenology and a multi-day bloom envelope; any future prediction service needs the separate weather-law review.

VERIFIED / DERIVED ARITHMETIC: JMA's 2025 maple coloration table and normal deviations imply station normal dates Tokyo November 28, Kyoto December 5, Osaka December 1. These are **not tourist peak dates**; a reference-tree observation criterion can be later than a photogenic garden's peak. 2026 observations are not yet populated at the research date. JUDGMENT: allow late-November/early-December red/gold envelopes, per-tree variation and gradual leaf drop; avoid a fixed national November switch. [Maple observations](https://www.data.jma.go.jp/sakura/data/phn_014.html). [JMA phenology CSV archive](https://www.data.jma.go.jp/sakura/data/download_ruinenchi.html) supplies observed cherry, ginkgo and maple milestones for a data-driven season baseline.

## Legal decisions for the actual product

**VERIFIED — APPI:** PPC's current FAQ confirms Article171 applies to foreign businesses handling personal information abroad in connection with services to individuals in Japan, including app operation. Account-linked routes, precise location and inferred homes can identify living people (application INFERENCE); a public footprint alone is not automatically personal information. Purpose specification/disclosure, safeguards, contractor oversight, applicable third-party/cross-border arrangements, breach duties and retained-data rights require a product-specific design. An iPhone location prompt does not complete that design. [PPC foreign-app FAQ](https://www.ppc.go.jp/all_faq_index/faq1-q11-4/), [June2026 general guidelines](https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/).

**JUDGMENT:** launch with manually selected public areas, no login and no uploaded route history. Keep resident names, doorbell text, faces, plates and private occupancy out of assets/API. If location is used, prefer on-device selection and document transfers. Do not describe all coordinates as requiring consent or all location as special-care information; that was not established.

**VERIFIED current-law caution:** APPI amendments were promulgated July17,2026; most commence on a Cabinet Order date within two years, with exceptions. The April2023 English consolidated translation is not proof of every current provision. Exact amendment commencement/effect on WorldEngine remains UNVERIFIED. [PPC amendment notice](https://www.ppc.go.jp/news/press/2026/260717/), [English legal index](https://www.ppc.go.jp/en/legal/).

**VERIFIED — survey law separate from copyright:** GSI uses PDL1.0 and retains statutory restrictions. Its approval FAQ distinguishes Articles29/30 basic-survey and43/44 public-survey reproduction/use. Live GSI-server tile display has a defined exemption; self-hosted transformed terrain/meshes cannot borrow it automatically. The public-survey decision guide includes elevation-based3D uses. PLATEAU flags the same separate public-survey issue. No Japan-wide foreign map export prohibition was established. [GSI terms](https://web2.gsi.go.jp/ENGLISH/page_e30286.html), [approval FAQ](https://www.gsi.go.jp/LAW/2930-qa.html), [3D use guide](https://service.gsi.go.jp/onestop/navi/nav6-1/), [PLATEAU policy](https://www.mlit.go.jp/plateau/site-policy/). **HOLD** exact mesh/terrain production distribution until source/procedure applicability is recorded.

**VERIFIED — architecture differs from art:** Copyright Law Article46 has an architectural exception for reproduction by construction, and additional exceptions for outdoor artworks/sculptures; Articles48/50 address credit and moral rights. **INFERENCE:** digital exterior architecture has a stronger basis than selling a faithful sculpture asset. This does not clear murals, posters, statues or artwork in photographic textures. Downloadable sculpture-copy and stylization/moral-rights questions remain UNVERIFIED. [CRIC March2026 translation, Japanese original controls](https://www.cric.or.jp/english/doc/LawOfJapan_202603.pdf). **JUDGMENT:** omit independent art replicas; preserve architectural massing and avoid deliberate damage representations.

**VERIFIED — site conditions:** Kiyomizu-dera restricts commercial recording on its grounds without permission. That is an access/recording rule, not proof a licensed exterior mesh is forbidden. No general temple/shrine depiction ban was verified. **JUDGMENT:** public streets first; avoid worshippers, ritual interiors/private gardens and desecration gameplay; get a local review of names and religious details. [Temple notice](https://www.kiyomizudera.or.jp/en/news/2023/notice-to-visitors.php).

**VERIFIED — marks:** Trademark Act Article26(1)(vi) addresses use that is not a source identifier; METI explains confusing well-known indications and famous indications. Exact game application is fact-specific. **JUDGMENT:** use unbranded vending machines, invented Japanese-reviewed shop labels and generic packaging. Factual POI names can be a separate label layer, without suggesting sponsorship; this is not blanket clearance of logos. Audit PLATEAU photo textures for signs/art before any retained appearance. [Trademark Act translation](https://www.japaneselawtranslation.go.jp/ja/laws/download/4032/09/s34Aa001270305en14.0_r1A3.pdf), [METI explanation](https://www.meti.go.jp/policy/economy/chizai/chiteki/pdf/unfaircompetition_textbook_english.pdf).

## Recommended sequence and open gates

1. **Tokyo exterior geometry first:** select Taito/BunkyoFY2025 window, confirm local LOD2/roof availability and survey procedure; generate no-texture Style B geometry with OSM visible credit.
2. **Observed/official weather next:** public observations and faithful official relay with source/age labels; clarify future-weather rendering before building that product feature.
3. **One truly live transit layer:** Toei bus CC BY positions with explicit freshness, after route matching. Obtain written permission for other reusable rail/bus output rather than hiding it behind a renderer.
4. **Kyoto contrast pilot:** Nishijin public exteriors with measured surviving roof/height data and machiya kit; static bus information may remain separate until rights are resolved.
5. **Privacy and local review:** manually selected areas, generic signage, no resident identity; Japanese reviewer checks labels, scene authenticity and cultural choices.

UNVERIFIED before production: pilot-level high-LOD intersections and survey dates; exact per-item exclusions/approval status; current OSM completeness; 3D conversion/device performance; JMA ruling on real future visual rendering; production message limits/costs/reliability and EEW entitlement; permanent rail redistribution; Kyoto realtime bus availability; local species/prop positions; effects and commencement of each2026APPI amendment. These are explicit gates, not silently granted permissions.

## Files

- [README.md](README.md): scoped decisions, PLATEAU/OSM comparison, two pilot recommendations, weather/transit/legal conclusions.
- [datasets.csv](datasets.csv):20resource/framework rows, separate use rights, exact short licence quotes and source URLs.
- [sources.md](sources.md): primary evidence register, limitations and complete306-entry PLATEAU directory snapshot.

No concept images were requested or generated. No source meshes or app code were changed.
