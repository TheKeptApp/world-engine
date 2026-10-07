# Japan showcase: primary sources and coverage snapshot

Checked2026-10-07. VERIFIED denotes a supported source fact; decisions and product interpretations are judgments. UNVERIFIED issues remain open. The country-shortlist-v1 informed scope, but current primary sources govern. No supplier agreements accepted or datasets converted.

## Dataset and licence evidence

Exact licence quotations appear once in datasets.csv; not repeated here. Japanese excerpts are original text. English translations in README are editorial unless sourced from official English guidance. Blank quotes mean no separate excerpt was verified, not permission. Each row retains the exact quoted page URL. Read full terms, exclusions and resource metadata.

### jma_obs — JMA observations/history

GO product-specific. Endpoint cadence/quota not tested; third-party content excluded; source and editing credit.

- [Primary source 1](https://www.jma.go.jp/jma/en/copyright.html)
- [Primary source 2](https://www.data.jma.go.jp/developer/)

### jma_forecast — Official JMA forecasts

GO faithful official relay. Minute feed refresh is not forecast issuance rate or delivery SLA. Do not change values/regions into own repeated forecasts.

- [Primary source 1](https://www.jma.go.jp/jma/kishou/minkan/q_a_m.html)
- [Primary source 2](https://www.data.jma.go.jp/developer/ryuui.pdf)
- [Primary source 3](https://www.jma.go.jp/jma/kishou/minkan/kyoka_en.html)

### jma_alert — JMA weather/tsunami warnings and earthquake information

GO contextual relay; HOLD emergency push/EEW. Selected public feed EEW inclusion and emergency-grade delivery not verified; no custom tsunami prediction without applicable permission.

- [Primary source 1](https://www.jma.go.jp/jma/kishou/minkan/q_a_m.html)
- [Primary source 2](https://www.jma.go.jp/jma/kishou/info/ml-23.html)
- [Primary source 3](https://www.data.jma.go.jp/developer/ryuui.pdf)

### jma_gpv — JMA GPV / high-resolution precipitation nowcast

HOLD future immersive forecast interpretation. Nowcast 250m to30min, 1km35–60min, five-minute updates; production fees/delivery unresolved.

- [Primary source 1](https://www.jma.go.jp/jma/kishou/minkan/q_a_m.html)
- [Primary source 2](https://www.data.jma.go.jp/developer/weatherdataguide/appendix/2-1-b.html)

### ecmwf — ECMWF IFS/AIFS open subset

GO model fallback; HOLD independent Japan forecast. Four runs/day00/06/12/18UTC; recent12runs about2–3days; 9km subset upgrade forthcoming not assumed active. Open catalog does not mean every delivery service free.

- [Primary source 1](https://www.ecmwf.int/en/forecasts/datasets/open-data)
- [Primary source 2](https://apps.ecmwf.int/datasets/licences/general/)
- [Primary source 3](https://forum.ecmwf.int/t/ecmwf-free-and-open-data-at-9-km-soon-to-come/15366)

### odpt_basic — ODPT Basic participating rail/bus data

CONDITIONAL app; NO-GO raw API. Article8(4); frontend coordinates may reconstruct data. API key/review required; numeric cadence per odpt:frequency, validity dct:valid; none registered.

- [Primary source 1](https://developer.odpt.org/terms/data_basic_license.html)
- [Primary source 2](https://developer.odpt.org/terms/data_basic_use_guideline.html)
- [Primary source 3](https://ckan.odpt.org/)

### toei_static — Toei bus GTFS-JP

GO preferred transit foundation. Chosen route coverage/freshness and endpoint limits unverified; credit Bureau of Transportation Tokyo Metropolitan Government / ODPT association.

- [Primary source 1](https://ckan.odpt.org/dataset/b_bus_gtfs_jp-toei)
- [Primary source 2](https://developer.odpt.org/en/faq-info)

### toei_rt — Toei bus VehiclePosition

GO preferred first live transit. Numeric cadence/SLA and Yanaka route matching unverified. Expose message timestamps; avoid private/passenger linkage.

- [Primary source 1](https://ckan.odpt.org/dataset/b_bus_gtfs_rt-toei)

### kyoto_bus — Kyoto City Bus

CONDITIONAL static app; NO-GO raw API. Provider specifics not fully verified; realtime Kyoto bus GPS not established.

- [Primary source 1](https://ckan.odpt.org/dataset/kyoto_municipal_transportation_kyoto_city_bus_gtfs)
- [Primary source 2](https://data.city.kyoto.lg.jp/dataset/00656/)

### odpt_challenge — ODPT Challenge2026 limited operators

NO-GO durable launch foundation. Authorization expires2027-03-12; provider invention/competition clauses need review; not permanent JR East rail rights.

- [Primary source 1](https://developer.odpt.org/challenge_license)
- [Primary source 2](https://challenge2026.odpt.org/)

### gsi — GSI terrain/maps

HOLD self-hosted derivative until approval status pinned. Articles29/30 basic-survey and43/44 public-survey; server tile display exemption not blanket mesh exemption; no general foreign map export ban established.

- [Primary source 1](https://web2.gsi.go.jp/ENGLISH/page_e30286.html)
- [Primary source 2](https://www.gsi.go.jp/LAW/2930-qa.html)
- [Primary source 3](https://service.gsi.go.jp/onestop/navi/nav6-1/)

### jma_phenology — JMA phenological station observations

GO observed season baseline. Reference tree milestones are not every tree or scenic peak; missing local species/location data remains inference.

- [Primary source 1](https://www.jma.go.jp/jma/en/copyright.html)
- [Primary source 2](https://www.data.jma.go.jp/sakura/data/download_ruinenchi.html)

### plateau — PLATEAU municipal 3D open models

CONDITIONAL GO geometry. Municipal copyright; commercial storage/redistribution/transformation allowed by selected open grant; third-party notices and public-survey rules remain. General updates1–5years.

- [Primary source 1](https://www.mlit.go.jp/plateau/site-policy/)
- [Primary source 2](https://www.mlit.go.jp/plateau/faq/)
- [Primary source 3](https://www.mlit.go.jp/plateau/open-data/)

### plateau_tiles — PLATEAU delivery catalog / tiles

GO discovery. Public quota/SLA/bulk terms unverified; choose exact year/LOD/texture; spec5.0 does not mean CityGML encoding5.

- [Primary source 1](https://api.plateauview.mlit.go.jp/datacatalog/plateau-datasets)
- [Primary source 2](https://docs.plateauview.mlit.go.jp/datasets/3d-tiles/)
- [Primary source 3](https://docs.plateauview.mlit.go.jp/datasets/citygml/)

### plateau_tokyo — Tokyo Taito/Bunkyo FY2025

CONDITIONAL GO bounded extract. FY is package label not survey date. Directory/API verified; CKAN item pages403; exact exceptions and pilot high-LOD intersection UNVERIFIED.

- [Primary source 1](https://www.geospatial.jp/ckan/dataset/plateau-13106-taito-ku-2025)
- [Primary source 2](https://api.plateauview.mlit.go.jp/datacatalog/plateau-datasets)
- [Primary source 3](https://www.mlit.go.jp/plateau/site-policy/)

### plateau_kyoto — Kyoto FY2025

CONDITIONAL GO bounded extract. FY is package label not survey date. Directory/API verified; CKAN item pages403; exact exceptions and pilot high-LOD intersection UNVERIFIED.

- [Primary source 1](https://www.geospatial.jp/ckan/dataset/plateau-26100-kyoto-shi-2025)
- [Primary source 2](https://api.plateauview.mlit.go.jp/datacatalog/plateau-datasets)
- [Primary source 3](https://www.mlit.go.jp/plateau/site-policy/)

### plateau_osaka — Osaka FY2025

CONDITIONAL GO bounded extract. FY is package label not survey date. Directory/API verified; CKAN item pages403; exact exceptions and pilot high-LOD intersection UNVERIFIED.

- [Primary source 1](https://www.geospatial.jp/ckan/dataset/plateau-27100-osaka-shi-2025)
- [Primary source 2](https://api.plateauview.mlit.go.jp/datacatalog/plateau-datasets)
- [Primary source 3](https://www.mlit.go.jp/plateau/site-policy/)

### kyoto_exports — Kyoto municipal supplementary FY2025 exports

GO attributed exports. FY2025 resources updated2026-08-31; source copyright Kyoto City; no pipeline conversion tested.

- [Primary source 1](https://data.city.kyoto.lg.jp/dataset/00661/?page=1)

### osm — OpenStreetMap

GO with architecture audit. Visible © OpenStreetMap contributors; combined database duties fact-specific. PLATEAU imports do not establish complete/current coverage.

- [Primary source 1](https://www.openstreetmap.org/copyright)
- [Primary source 2](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)
- [Primary source 3](https://wiki.openstreetmap.org/wiki/JA:MLIT_PLATEAU/imports_outline)

### ccby — CC BY4.0 legal framework

GO copyright scope. Does not waive privacy/trademark/moral rights/Survey Act; no automatic whole-app share-alike; cannot promise exclusive source ownership.

- [Primary source 1](https://creativecommons.org/licenses/by/4.0/deed.en)
- [Primary source 2](https://creativecommons.org/licenses/by/4.0/legalcode.en)

## Additional legal, visual and season evidence

### legal_appi

[legal_appi](https://www.ppc.go.jp/all_faq_index/faq1-q11-4/)

VERIFIED Article171 foreign-app applicability; editorial English translation in README. Checked2026-10-07.

> 個人情報保護法の域外適用の対象となります（法第171条）。

### legal_guidelines

[legal_guidelines](https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/)

VERIFIED current general guidelines revisedJune2026. Purpose, safeguards, transfers and retained-data duties; location classification is product-specific INFERENCE. Checked2026-10-07.

### legal_amendment

[legal_amendment](https://www.ppc.go.jp/news/press/2026/260717/)

VERIFIED July17,2026 promulgation; most provisions within2years by Cabinet Order. Exact effective provision review UNVERIFIED. Checked2026-10-07.

> 改正法は、一部を除き、公布日から起算して２年以内で政令で定める日から施行されます。

### legal_english

[legal_english](https://www.ppc.go.jp/en/legal/)

VERIFIED English index labels April2023 consolidated translation; Japanese law controls. Checked2026-10-07.

### legal_architecture

[legal_architecture](https://www.cric.or.jp/english/doc/LawOfJapan_202603.pdf)

VERIFIED translation Articles46/48/50. Architectural construction exception, outdoor artwork exceptions and moral rights; independent sculpture asset treatment UNVERIFIED. Checked2026-10-07.

> Reproducing an architectural work by means of construction

### legal_temple

[legal_temple](https://www.kiyomizudera.or.jp/en/news/2023/notice-to-visitors.php)

VERIFIED site commercial-recording policy; not a nationwide ban or ruling on licensed exterior meshes. Checked2026-10-07.

> Please refrain from recording for commercial purposes in the temple grounds.

### legal_marks

[legal_marks](https://www.japaneselawtranslation.go.jp/ja/laws/download/4032/09/s34Aa001270305en14.0_r1A3.pdf)

VERIFIED Article26(1)(vi) reference; exact game branding use unresolved. Checked2026-10-07.

### legal_confusion

[legal_confusion](https://www.meti.go.jp/policy/economy/chizai/chiteki/pdf/unfaircompetition_textbook_english.pdf)

VERIFIED well-known/famous business indication rules; generic props recommendation is JUDGMENT. Checked2026-10-07.

> Acts of creating confusion with well-known indications of goods or business

### weather_foreign

[weather_foreign](https://www.jma.go.jp/jma/kishou/minkan/kyoka_en.html)

VERIFIED current foreign-operator forecasting guidance. Exact forecast quote appears only in README to avoid duplicate quotation. Checked2026-10-07.

### weather_foreign_detail

[weather_foreign_detail](https://www.jma.go.jp/jma/kishou/minkan/tekiyou.pdf)

VERIFIED March31,2026 Japan-user applicability guidance. Checked2026-10-07.

### weather_reform

[weather_reform](https://www.jma.go.jp/jma/press/2604/14a/20240414_seirei.html)

VERIFIED reform effectiveMay29,2026; do not rely only on old XML summaries. Checked2026-10-07.

### kyoto_index

[kyoto_index](https://assets.cms.plateau.reearth.io/assets/0f/4b712b-5ca1-476d-a5be-df67c70d8a88/26100_indexmap_op.pdf)

VERIFIED delivered extent: LOD1urbanized185km2, LOD2building21.89km2, LOD3combined0.022km2; underlying survey vintage not inferred fromFY2025. Checked2026-10-07.

### lod_tutorial

[lod_tutorial](https://www.mlit.go.jp/plateau/learning/tpc03-3/)

VERIFIED semantic LOD/surfaces/appearance relationships; nominal accuracy criteria not dataset guarantees. Checked2026-10-07.

### crs_tutorial

[crs_tutorial](https://www.mlit.go.jp/plateau/learning/tpc03-4/)

VERIFIED older coordinate guidance; newer exact CRS must be read from resource. Checked2026-10-07.

### look_tokyo

[Primary source](https://www.gotokyo.org/en/spot/170/index.html)

VERIFIED: Yanaka Ginza is a functioning traditional shotengai of independent everyday shops, not Ginza luxury district. Test-area selection is JUDGMENT. Checked2026-10-07.

### look_tokyo_lanes

[Primary source](https://www.gotokyo.org/en/story/walks-and-tours/yanaka-and-nezu/)

VERIFIED: narrow backstreets, temple district, spring cherry blossoms and late-spring azaleas. Does not measure building-family proportions. Checked2026-10-07.

### look_yanaka

[Primary source](https://www.city.taito.lg.jp/kenchiku/toshikeikaku/keikaku/chikukeikaku/yanakatikukeikaku.files/yanakatikukeikankeiseiGL.pdf)

VERIFIED: local guidance describes many 2–3-storey buildings, varied architecture and low-rise pitched-roof character. Planning guidance is reference evidence, not digital-depiction law. Checked2026-10-07.

### look_kyoto

[Primary source](https://global.kyoto.travel/en/faq/detail.php?faq_id=1015)

VERIFIED: official visitor information identifies Itsutsuji-dori in Nishijin among streets where machiya exteriors can be seen. Checked2026-10-07.

### look_nishijin

[Primary source](https://www.city.kyoto.lg.jp/tokei/page/0000281270.html)

VERIFIED: Senryogatsuji landscape plan describes mixed residential/commercial textile-industry streets, traditional houses and modernized buildings. Checked2026-10-07.

### look_machiya

[Primary source](https://kyoto-bunkaisan.city.kyoto.lg.jp/kyotoisan/nintei-theme/kyoumachiya.html)

VERIFIED: Kyoto city heritage explanation supports lattice fronts, aligned tile eaves and mushiko windows. Different periods/businesses vary; exact pilot mix UNVERIFIED. Checked2026-10-07.

### look_trees

[Primary source](https://www.kensetsu.metro.tokyo.lg.jp/park/ryokuka/hyoushi/hyoushi1)

VERIFIED: Tokyo official street-tree guide includes cherry cultivars, ginkgo, zelkova, tulip tree and dogwood; not a Yanaka species inventory. Checked2026-10-07.

### phenology_bloom

[Primary source](https://www.data.jma.go.jp/sakura/data/sakura_kaika.html)

VERIFIED: normal cherry opening Tokyo March24, Kyoto March26, Osaka March27; 2026 observations March19/March23/March26. Station reference trees, not every neighborhood/cultivar. Checked2026-10-07.

### phenology_full

[Primary source](https://www.data.jma.go.jp/sakura/data/sakura004_07.html)

VERIFIED: 1991–2020 normal full bloom Tokyo March31, Kyoto April4, Osaka April4; 2026 March28/March30/April3. Not future forecasts. Checked2026-10-07.

### phenology_maple

[Primary source](https://www.data.jma.go.jp/sakura/data/phn_014.html)

VERIFIED: 2025 station maple coloration Tokyo Nov23 (5 days early), Kyoto Dec10 (5 days late), Osaka Dec4 (3 days late). Derived normals Nov28/Dec5/Dec1. 2026 coloration not observed yet on research date; station criterion differs from tourist scenic peak. Checked2026-10-07.

### phenology_csv

[Primary source](https://www.data.jma.go.jp/sakura/data/download_ruinenchi.html)

VERIFIED: JMA offers accumulated phenology CSV including cherry opening/full bloom, ginkgo yellow/drop, maple color/drop. Terms follow JMA content policy; verify record metadata. Checked2026-10-07.

## Complete PLATEAU directory snapshot

Publisher: [PLATEAU official open-data directory](https://www.mlit.go.jp/plateau/open-data/). Live HTML extracted2026-10-07; page update label2026-05-11. Exactly306linked dataset entries,306unique URLs and306unique prefecture/name pairs across45listed prefectures. This is a directory coverage list, not306distinct municipalities, all-building coverage or a surveyed uniformLOD list. FY suffix is package fiscal year, not guaranteed survey date. Wards, aggregates, samples and special sites remain separate entries. All linked items were extracted; individual CKAN pages were not all fetched and some returned403 during research. Exact item licenses/extent must be pinned before production.

| Prefecture | Directory entry | Dataset link / FY |
|---|---|---|
| 北海道 | 更別村 | [plateau-01639-sarabetsu-mura-2023](https://www.geospatial.jp/ckan/dataset/plateau-01639-sarabetsu-mura-2023) |
| 北海道 | 室蘭市 | [plateau-01205-muroran-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-01205-muroran-shi-2022) |
| 北海道 | 札幌市 | [plateau-01100-sapporo-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-01100-sapporo-shi-2020) |
| 青森県 | 鰺ヶ沢町 | [plateau-02321-ajigasawa-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-02321-ajigasawa-machi-2025) |
| 青森県 | むつ市 | [plateau-02208-mutsu-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-02208-mutsu-shi-2022) |
| 岩手県 | 宮古市 | [plateau-03202-miyako-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-03202-miyako-shi-2025) |
| 岩手県 | 盛岡市 | [plateau-03201-morioka-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-03201-morioka-shi-2024) |
| 宮城県 | 仙台市 | [plateau-04100-sendai-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-04100-sendai-shi-2024) |
| 秋田県 | 大館市 | [plateau-05204-odate-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-05204-odate-shi-2024) |
| 福島県 | 相馬市 | [plateau-07209-soma-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-07209-soma-shi-2023) |
| 福島県 | 福島市 | [plateau-07201-fukushima-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-07201-fukushima-shi-2025) |
| 福島県 | 南相馬市 | [plateau-07212-minamisouma-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-07212-minamisouma-shi-2022) |
| 福島県 | 郡山市 | [plateau-07203-koriyama-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-07203-koriyama-shi-2020) |
| 福島県 | いわき市 | [plateau-07204-iwaki-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-07204-iwaki-shi-2020) |
| 福島県 | 白河市 | [plateau-07205-shirakawa-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-07205-shirakawa-shi-2020) |
| 茨城県 | 境町 | [plateau-08546-sakai-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-08546-sakai-machi-2023) |
| 茨城県 | つくば市 | [plateau-08220-tsukuba-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-08220-tsukuba-shi-2023) |
| 茨城県 | 鉾田市 | [plateau-08234-hokota-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-08234-hokota-shi-2022) |
| 栃木県 | 宇都宮市 | [plateau-09201-utsunomiya-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-09201-utsunomiya-shi-2023) |
| 群馬県 | 前橋市 | [plateau-10201-maebashi-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-10201-maebashi-shi-2023) |
| 群馬県 | 桐生市 | [plateau-10203-kiryu-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-10203-kiryu-shi-2020) |
| 群馬県 | 館林市 | [plateau-10207-tatebayashi-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-10207-tatebayashi-shi-2020) |
| 埼玉県 | 秩父市 | [plateau-11207-chichibu-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11207-chichibu-shi-2025) |
| 埼玉県 | 寄居町 | [plateau-11408-yorii-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11408-yorii-machi-2025) |
| 埼玉県 | 鳩山町 | [plateau-11348-hatoyama-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11348-hatoyama-machi-2025) |
| 埼玉県 | 吉見町 | [plateau-11347-yoshimi-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11347-yoshimi-machi-2025) |
| 埼玉県 | 川島町 | [plateau-11346-kawajima-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11346-kawajima-machi-2025) |
| 埼玉県 | 小川町 | [plateau-11343-ogawa-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11343-ogawa-machi-2025) |
| 埼玉県 | 嵐山町 | [plateau-11342-ranzan-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11342-ranzan-machi-2025) |
| 埼玉県 | 滑川町 | [plateau-11341-namegawa-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11341-namegawa-machi-2025) |
| 埼玉県 | 坂戸市 | [plateau-11239-sakado-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11239-sakado-shi-2025) |
| 埼玉県 | 北本市 | [plateau-11233-kitamoto-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11233-kitamoto-shi-2025) |
| 埼玉県 | 桶川市 | [plateau-11231-okegawa-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11231-okegawa-shi-2025) |
| 埼玉県 | 和光市 | [plateau-11229-wako-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11229-wako-shi-2025) |
| 埼玉県 | 朝霞市 | [plateau-11227-asaka-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11227-asaka-shi-2025) |
| 埼玉県 | 草加市 | [plateau-11221-soka-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11221-soka-shi-2025) |
| 埼玉県 | 深谷市 | [plateau-11218-fukaya-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11218-fukaya-shi-2025) |
| 埼玉県 | 羽生市 | [plateau-11216-hanyu-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11216-hanyu-shi-2025) |
| 埼玉県 | 狭山市 | [plateau-11215-sayama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11215-sayama-shi-2025) |
| 埼玉県 | 本庄市 | [plateau-11211-honjo-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11211-honjo-shi-2025) |
| 埼玉県 | 上里町 | [plateau-11385-kamisato-machi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11385-kamisato-machi-2024) |
| 埼玉県 | 三芳町 | [plateau-11324-miyoshi-machi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11324-miyoshi-machi-2024) |
| 埼玉県 | 伊奈町 | [plateau-11301-ina-machi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11301-ina-machi-2024) |
| 埼玉県 | 鶴ヶ島市 | [plateau-11241-tsurugashima-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11241-tsurugashima-shi-2024) |
| 埼玉県 | 幸手市 | [plateau-11240-satte-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11240-satte-shi-2024) |
| 埼玉県 | 三郷市 | [plateau-11237-misato-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11237-misato-shi-2024) |
| 埼玉県 | 富士見市 | [plateau-11235-fujimi-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11235-fujimi-shi-2024) |
| 埼玉県 | 志木市 | [plateau-11228-shiki-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11228-shiki-shi-2024) |
| 埼玉県 | 蕨市 | [plateau-11223-warabi-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11223-warabi-shi-2024) |
| 埼玉県 | 鴻巣市 | [plateau-11217-konosu-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11217-konosu-shi-2024) |
| 埼玉県 | 所沢市 | [plateau-11208-tokorozawa-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11208-tokorozawa-shi-2024) |
| 埼玉県 | 川口市 | [plateau-11203-kawaguchi-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11203-kawaguchi-shi-2024) |
| 埼玉県 | 八潮市 | [plateau-11234-yashio-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11234-yashio-shi-2023) |
| 埼玉県 | 吉川市 | [plateau-11243-yoshikawa-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11243-yoshikawa-shi-2023) |
| 埼玉県 | 白岡市 | [plateau-11246-shiraoka-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11246-shiraoka-shi-2023) |
| 埼玉県 | 加須市 | [plateau-11210-kazo-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11210-kazo-shi-2023) |
| 埼玉県 | 久喜市 | [plateau-11232-kuki-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11232-kuki-shi-2023) |
| 埼玉県 | 宮代町 | [plateau-11442-miyashiro-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11442-miyashiro-machi-2023) |
| 埼玉県 | 杉戸町 | [plateau-11464-sugito-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11464-sugito-machi-2023) |
| 埼玉県 | 松伏町 | [plateau-11465-matsubushi-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11465-matsubushi-machi-2023) |
| 埼玉県 | 越谷市 | [plateau-11222-koshigaya-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11222-koshigaya-shi-2023) |
| 埼玉県 | 春日部市 | [plateau-11214-kasukabe-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-11214-kasukabe-shi-2023) |
| 埼玉県 | 戸田市 | [plateau-11224-toda-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-11224-toda-shi-2022) |
| 埼玉県 | 蓮田市 | [plateau-11238-hasuda-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-11238-hasuda-shi-2022) |
| 埼玉県 | 上尾市 | [plateau-11219-ageo-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11219-ageo-shi-2025) |
| 埼玉県 | 入間市 | [plateau-11225-iruma-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11225-iruma-shi-2025) |
| 埼玉県 | ふじみ野市 | [plateau-11245-fujimino-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11245-fujimino-shi-2025) |
| 埼玉県 | さいたま市 | [plateau-11100-saitama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11100-saitama-shi-2025) |
| 埼玉県 | 熊谷市 | [plateau-11202-kumagaya-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-11202-kumagaya-shi-2025) |
| 埼玉県 | 新座市 | [plateau-11230-niiza-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-11230-niiza-shi-2024) |
| 埼玉県 | 毛呂山町 | [plateau-11326-moroyama-machi-2020](https://www.geospatial.jp/ckan/dataset/plateau-11326-moroyama-machi-2020) |
| 千葉県 | 多古町 | [plateau-12347-tako-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-12347-tako-machi-2025) |
| 千葉県 | 千葉市 | [plateau-12100-chiba-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-12100-chiba-shi-2024) |
| 千葉県 | 木更津市 | [plateau-12206-kisarazu-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-12206-kisarazu-shi-2024) |
| 千葉県 | 八千代市 | [plateau-12221-yachiyo-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-12221-yachiyo-shi-2022) |
| 千葉県 | 茂原市 | [plateau-12210-mobara-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-12210-mobara-shi-2022) |
| 千葉県 | 柏市 | [plateau-12217-kashiwa-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-12217-kashiwa-shi-2020) |
| 東京都 | 小笠原村 | [plateau-13421-ogasawara-mura-2025](https://www.geospatial.jp/ckan/dataset/plateau-13421-ogasawara-mura-2025) |
| 東京都 | 御蔵島村 | [plateau-13382-mikurajima-mura-2024](https://www.geospatial.jp/ckan/dataset/plateau-13382-mikurajima-mura-2024) |
| 東京都 | 青ケ島村 | [plateau-13402-aogashima-mura-2024](https://www.geospatial.jp/ckan/dataset/plateau-13402-aogashima-mura-2024) |
| 東京都 | 神津島村 | [plateau-13364-kozushima-mura-2024](https://www.geospatial.jp/ckan/dataset/plateau-13364-kozushima-mura-2024) |
| 東京都 | 新島村 | [plateau-13363-niijima-mura-2024](https://www.geospatial.jp/ckan/dataset/plateau-13363-niijima-mura-2024) |
| 東京都 | 大島町 | [plateau-13361-oshima-machi-2024](https://www.geospatial.jp/ckan/dataset/plateau-13361-oshima-machi-2024) |
| 東京都 | 利島村 | [plateau-13362-toshima-mura-2024](https://www.geospatial.jp/ckan/dataset/plateau-13362-toshima-mura-2024) |
| 東京都 | 八丈町 | [plateau-13401-hachijo-machi-2024](https://www.geospatial.jp/ckan/dataset/plateau-13401-hachijo-machi-2024) |
| 東京都 | 三宅村 | [plateau-13381-miyake-mura-2024](https://www.geospatial.jp/ckan/dataset/plateau-13381-miyake-mura-2024) |
| 東京都 | 東京都サンプルデータ（竹芝モデル） | [plateau-tokyo-takeshiba-2023](https://www.geospatial.jp/ckan/dataset/plateau-tokyo-takeshiba-2023) |
| 東京都 | 豊島区 | [plateau-13116-toshima-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13116-toshima-ku-2025) |
| 東京都 | 港区 | [plateau-13103-minato-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13103-minato-ku-2025) |
| 東京都 | 東京都23区 | [plateau-tokyo23ku-2022](https://www.geospatial.jp/ckan/dataset/plateau-tokyo23ku-2022) |
| 東京都 | 千代田区 | [plateau-13101-chiyoda-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13101-chiyoda-ku-2025) |
| 東京都 | 中央区 | [plateau-13102-chuo-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13102-chuo-ku-2025) |
| 東京都 | 文京区 | [plateau-13105-bunkyo-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13105-bunkyo-ku-2025) |
| 東京都 | 台東区 | [plateau-13106-taito-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13106-taito-ku-2025) |
| 東京都 | 墨田区 | [plateau-13107-sumida-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13107-sumida-ku-2025) |
| 東京都 | 江東区 | [plateau-13108-koto-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13108-koto-ku-2025) |
| 東京都 | 品川区 | [plateau-13109-shinagawa-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13109-shinagawa-ku-2025) |
| 東京都 | 目黒区 | [plateau-13110-meguro-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13110-meguro-ku-2025) |
| 東京都 | 大田区 | [plateau-13111-ota-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13111-ota-ku-2025) |
| 東京都 | 世田谷区 | [plateau-13112-setagaya-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13112-setagaya-ku-2025) |
| 東京都 | 渋谷区 | [plateau-13113-shibuya-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13113-shibuya-ku-2025) |
| 東京都 | 奥多摩町 | [plateau-13308-okutama-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13308-okutama-machi-2025) |
| 東京都 | 檜原村 | [plateau-13307-hinohara-mura-2025](https://www.geospatial.jp/ckan/dataset/plateau-13307-hinohara-mura-2025) |
| 東京都 | 日の出町 | [plateau-13305-hinode-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13305-hinode-machi-2025) |
| 東京都 | 瑞穂町 | [plateau-13303-mizuho-machi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13303-mizuho-machi-2025) |
| 東京都 | あきる野市 | [plateau-13228-akiruno-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13228-akiruno-shi-2025) |
| 東京都 | 羽村市 | [plateau-13227-hamura-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13227-hamura-shi-2025) |
| 東京都 | 稲城市 | [plateau-13225-inagi-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13225-inagi-shi-2025) |
| 東京都 | 多摩市 | [plateau-13224-tama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13224-tama-shi-2025) |
| 東京都 | 武蔵村山市 | [plateau-13223-musashimurayama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13223-musashimurayama-shi-2025) |
| 東京都 | 東久留米市 | [plateau-13222-higashikurume-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13222-higashikurume-shi-2025) |
| 東京都 | 清瀬市 | [plateau-13221-kiyose-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13221-kiyose-shi-2025) |
| 東京都 | 東大和市 | [plateau-13220-higashiyamato-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13220-higashiyamato-shi-2025) |
| 東京都 | 狛江市 | [plateau-13219-komae-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13219-komae-shi-2025) |
| 東京都 | 福生市 | [plateau-13218-fussa-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13218-fussa-shi-2025) |
| 東京都 | 国立市 | [plateau-13215-kunitachi-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13215-kunitachi-shi-2025) |
| 東京都 | 国分寺市 | [plateau-13214-kokubunji-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13214-kokubunji-shi-2025) |
| 東京都 | 日野市 | [plateau-13212-hino-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13212-hino-shi-2025) |
| 東京都 | 小平市 | [plateau-13211-kodaira-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13211-kodaira-shi-2025) |
| 東京都 | 小金井市 | [plateau-13210-koganei-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13210-koganei-shi-2025) |
| 東京都 | 町田市 | [plateau-13209-machida-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13209-machida-shi-2025) |
| 東京都 | 調布市 | [plateau-13208-chofu-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13208-chofu-shi-2025) |
| 東京都 | 昭島市 | [plateau-13207-akishima-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13207-akishima-shi-2025) |
| 東京都 | 府中市 | [plateau-13206-fuchu-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13206-fuchu-shi-2025) |
| 東京都 | 青梅市 | [plateau-13205-ome-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13205-ome-shi-2025) |
| 東京都 | 三鷹市 | [plateau-13204-mitaka-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13204-mitaka-shi-2025) |
| 東京都 | 武蔵野市 | [plateau-13203-musashino-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13203-musashino-shi-2025) |
| 東京都 | 立川市 | [plateau-13202-tachikawa-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13202-tachikawa-shi-2025) |
| 東京都 | 江戸川区 | [plateau-13123-edogawa-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13123-edogawa-ku-2025) |
| 東京都 | 葛飾区 | [plateau-13122-katsushika-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13122-katsushika-ku-2025) |
| 東京都 | 足立区 | [plateau-13121-adachi-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13121-adachi-ku-2025) |
| 東京都 | 練馬区 | [plateau-13120-nerima-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13120-nerima-ku-2025) |
| 東京都 | 板橋区 | [plateau-13119-itabashi-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13119-itabashi-ku-2025) |
| 東京都 | 荒川区 | [plateau-13118-arakawa-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13118-arakawa-ku-2025) |
| 東京都 | 北区 | [plateau-13117-kita-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13117-kita-ku-2025) |
| 東京都 | 杉並区 | [plateau-13115-suginami-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13115-suginami-ku-2025) |
| 東京都 | 中野区 | [plateau-13114-nakano-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13114-nakano-ku-2025) |
| 東京都 | 新宿区 | [plateau-13104-shinjuku-ku-2025](https://www.geospatial.jp/ckan/dataset/plateau-13104-shinjuku-ku-2025) |
| 東京都 | 西東京市 | [plateau-13229-nishitokyo-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13229-nishitokyo-shi-2025) |
| 東京都 | 八王子市 | [plateau-13201-hachioji-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13201-hachioji-shi-2025) |
| 東京都 | 東村山市 | [plateau-13213-higashimurayama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-13213-higashimurayama-shi-2025) |
| 神奈川県 | 藤沢市 | [plateau-14205-fujisawa-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-14205-fujisawa-shi-2025) |
| 神奈川県 | 厚木市 | [plateau-14212-atsugi-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-14212-atsugi-shi-2023) |
| 神奈川県 | 横浜市 | [plateau-14100-yokohama-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-14100-yokohama-shi-2024) |
| 神奈川県 | 川崎市 | [plateau-14130-kawasaki-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-14130-kawasaki-shi-2022) |
| 神奈川県 | 鎌倉市 | [plateau-14204-kamakura-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-14204-kamakura-shi-2024) |
| 神奈川県 | 相模原市 | [plateau-14150-sagamihara-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-14150-sagamihara-shi-2024) |
| 神奈川県 | 横須賀市 | [plateau-14201-yokosuka-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-14201-yokosuka-shi-2020) |
| 神奈川県 | 箱根町 | [plateau-14382-hakone-machi-2020](https://www.geospatial.jp/ckan/dataset/plateau-14382-hakone-machi-2020) |
| 新潟県 | 加茂市 | [plateau-15209-kamo-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-15209-kamo-shi-2023) |
| 新潟県 | 新発田市 | [plateau-15206-shibata-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-15206-shibata-shi-2025) |
| 新潟県 | 三条市 | [plateau-15204-sanjo-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-15204-sanjo-shi-2025) |
| 新潟県 | 長岡市 | [plateau-15202-nagaoka-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-15202-nagaoka-shi-2024) |
| 新潟県 | 上越市 | [plateau-15222-joetsu-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-15222-joetsu-shi-2023) |
| 新潟県 | 新潟市 | [plateau-15100-niigata-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-15100-niigata-shi-2023) |
| 富山県 | 舟橋村 | [plateau-16321-funahashi-mura-2025](https://www.geospatial.jp/ckan/dataset/plateau-16321-funahashi-mura-2025) |
| 富山県 | 高岡市 | [plateau-16202-takaoka-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-16202-takaoka-shi-2024) |
| 富山県 | 射水市 | [plateau-16211-imizu-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-16211-imizu-shi-2024) |
| 石川県 | 金沢市 | [plateau-17201-kanazawa-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-17201-kanazawa-shi-2024) |
| 石川県 | 加賀市 | [plateau-17206-kaga-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-17206-kaga-shi-2024) |
| 山梨県 | 甲府市 | [plateau-19201-kofu-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-19201-kofu-shi-2023) |
| 長野県 | 飯山市 | [plateau-20213-iiyama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-20213-iiyama-shi-2025) |
| 長野県 | 長野市 | [plateau-20201-nagano-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-20201-nagano-shi-2024) |
| 長野県 | 安曇野市 | [plateau-20220-azumino-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-20220-azumino-shi-2025) |
| 長野県 | 諏訪市 | [plateau-20206-suwa-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-20206-suwa-shi-2023) |
| 長野県 | 佐久市 | [plateau-20217-saku-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-20217-saku-shi-2025) |
| 長野県 | 松本市 | [plateau-20202-matsumoto-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-20202-matsumoto-shi-2020) |
| 長野県 | 岡谷市 | [plateau-20204-okaya-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-20204-okaya-shi-2022) |
| 長野県 | 伊那市 | [plateau-20209-ina-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-20209-ina-shi-2020) |
| 長野県 | 茅野市 | [plateau-20214-chino-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-20214-chino-shi-2023) |
| 岐阜県 | 大垣市 | [plateau-21202-ogaki-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-21202-ogaki-shi-2025) |
| 岐阜県 | 美濃加茂市 | [plateau-21211-minokamo-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-21211-minokamo-shi-2024) |
| 岐阜県 | 岐阜市 | [plateau-21201-gifu-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-21201-gifu-shi-2025) |
| 静岡県 | 浜松市 | [plateau-22130-hamamatsu-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22130-hamamatsu-shi-2023) |
| 静岡県 | 川根本町 | [plateau-22429-kawanehon-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22429-kawanehon-cho-2023) |
| 静岡県 | 西伊豆町 | [plateau-22306-nishiizu-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22306-nishiizu-cho-2023) |
| 静岡県 | 松崎町 | [plateau-22305-matsuzaki-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22305-matsuzaki-cho-2023) |
| 静岡県 | 島田市 | [plateau-22209-shimada-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22209-shimada-shi-2023) |
| 静岡県 | 南伊豆町 | [plateau-22304-minamiizu-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22304-minamiizu-cho-2023) |
| 静岡県 | 伊豆の国市 | [plateau-22225-izunokuni-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22225-izunokuni-shi-2023) |
| 静岡県 | 熱海市 | [plateau-22205-atami-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22205-atami-shi-2023) |
| 静岡県 | 三島市 | [plateau-22206-mishima-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22206-mishima-shi-2023) |
| 静岡県 | 藤枝市 | [plateau-22214-fujieda-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22214-fujieda-shi-2023) |
| 静岡県 | 伊豆市 | [plateau-22222-izu-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22222-izu-shi-2023) |
| 静岡県 | 富士市 | [plateau-22210-fuji-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22210-fuji-shi-2023) |
| 静岡県 | 御前崎市 | [plateau-22223-omaezaki-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22223-omaezaki-shi-2023) |
| 静岡県 | 焼津市 | [plateau-22212-yaizu-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22212-yaizu-shi-2023) |
| 静岡県 | 吉田町 | [plateau-22424-yoshida-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22424-yoshida-cho-2023) |
| 静岡県 | 湖西市 | [plateau-22221-kosai-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22221-kosai-shi-2023) |
| 静岡県 | 富士宮市 | [plateau-22207-fujinomiya-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22207-fujinomiya-shi-2023) |
| 静岡県 | 伊東市 | [plateau-22208-ito-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22208-ito-shi-2023) |
| 静岡県 | 袋井市 | [plateau-22216-fukuroi-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22216-fukuroi-shi-2023) |
| 静岡県 | 東伊豆町 | [plateau-22301-higashiizu-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22301-higashiizu-cho-2023) |
| 静岡県 | 磐田市 | [plateau-22211-iwata-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22211-iwata-shi-2023) |
| 静岡県 | 森町 | [plateau-22461-mori-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22461-mori-machi-2023) |
| 静岡県 | 小山町 | [plateau-22344-oyama-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22344-oyama-cho-2023) |
| 静岡県 | 御殿場市 | [plateau-22215-gotenba-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22215-gotenba-shi-2023) |
| 静岡県 | 牧之原市 | [plateau-22226-makinohara-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22226-makinohara-shi-2023) |
| 静岡県 | 下田市 | [plateau-22219-shimoda-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22219-shimoda-shi-2023) |
| 静岡県 | 静岡市 | [plateau-22100-shizuoka-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22100-shizuoka-shi-2023) |
| 静岡県 | 裾野市 | [plateau-22220-susono-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22220-susono-shi-2023) |
| 静岡県 | 長泉町 | [plateau-22342-nagaizumi-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22342-nagaizumi-cho-2023) |
| 静岡県 | 函南町 | [plateau-22325-kannami-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22325-kannami-cho-2023) |
| 静岡県 | 清水町 | [plateau-22341-shimizu-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22341-shimizu-cho-2023) |
| 静岡県 | 河津町 | [plateau-22302-kawazu-cho-2023](https://www.geospatial.jp/ckan/dataset/plateau-22302-kawazu-cho-2023) |
| 静岡県 | 沼津市 | [plateau-22203-numazu-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22203-numazu-shi-2023) |
| 静岡県 | 掛川市 | [plateau-22213-kakegawa-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22213-kakegawa-shi-2023) |
| 静岡県 | 菊川市 | [plateau-22224-kikugawa-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-22224-kikugawa-shi-2023) |
| 愛知県 | 豊田市 | [plateau-23211-toyota-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-23211-toyota-shi-2023) |
| 愛知県 | 豊橋市 | [plateau-23201-toyohashi-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-23201-toyohashi-shi-2024) |
| 愛知県 | 春日井市 | [plateau-23206-kasugai-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-23206-kasugai-shi-2023) |
| 愛知県 | 日進市 | [plateau-23230-nisshin-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-23230-nisshin-shi-2023) |
| 愛知県 | 豊川市 | [plateau-23207-toyokawa-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-23207-toyokawa-shi-2022) |
| 愛知県 | 名古屋市 | [plateau-23100-nagoya-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-23100-nagoya-shi-2022) |
| 愛知県 | 岡崎市 | [plateau-23202-okazaki-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-23202-okazaki-shi-2020) |
| 愛知県 | 津島市 | [plateau-23208-tsushima-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-23208-tsushima-shi-2020) |
| 愛知県 | 安城市 | [plateau-23212-anjo-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-23212-anjo-shi-2020) |
| 三重県 | 伊勢市 | [plateau-24203-ise-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-24203-ise-shi-2024) |
| 三重県 | 熊野市 | [plateau-24212-kumano-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-24212-kumano-shi-2022) |
| 三重県 | 四日市市 | [plateau-24202-yokkaichi-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-24202-yokkaichi-shi-2022) |
| 滋賀県 | 近江八幡市 | [plateau-25204-omihachiman-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-25204-omihachiman-shi-2025) |
| 滋賀県 | 長浜市 | [plateau-25203-nagahama-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-25203-nagahama-shi-2024) |
| 京都府 | 与謝野町 | [plateau-26465-yosano-cho-2025](https://www.geospatial.jp/ckan/dataset/plateau-26465-yosano-cho-2025) |
| 京都府 | 舞鶴市 | [plateau-26202-maizuru-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-26202-maizuru-shi-2025) |
| 京都府 | 京都市 | [plateau-26100-kyoto-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-26100-kyoto-shi-2025) |
| 大阪府 | 2025大阪・関西万博会場 | [plateau-27999-osaka-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-27999-osaka-shi-2025) |
| 大阪府 | 東大阪市 | [plateau-27227-higashiosaka-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-27227-higashiosaka-shi-2024) |
| 大阪府 | 岸和田市 | [plateau-27202-kishiwadashi-2024](https://www.geospatial.jp/ckan/dataset/plateau-27202-kishiwadashi-2024) |
| 大阪府 | 和泉市 | [plateau-27219-izumi-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-27219-izumi-shi-2023) |
| 大阪府 | 柏原市 | [plateau-27221-kashiwara-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-27221-kashiwara-shi-2022) |
| 大阪府 | 河内長野市 | [plateau-27216-kawachinagano-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-27216-kawachinagano-shi-2025) |
| 大阪府 | 堺市 | [plateau-27140-sakai-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-27140-sakai-shi-2024) |
| 大阪府 | 大阪市 | [plateau-27100-osaka-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-27100-osaka-shi-2025) |
| 大阪府 | 豊中市 | [plateau-27203-toyonaka-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-27203-toyonaka-shi-2020) |
| 大阪府 | 池田市 | [plateau-27204-ikeda-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-27204-ikeda-shi-2025) |
| 大阪府 | 高槻市 | [plateau-27207-takatsuki-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-27207-takatsuki-shi-2020) |
| 大阪府 | 摂津市 | [plateau-27224-settsu-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-27224-settsu-shi-2020) |
| 大阪府 | 忠岡町 | [plateau-27341-tadaoka-cho-2020](https://www.geospatial.jp/ckan/dataset/plateau-27341-tadaoka-cho-2020) |
| 兵庫県 | たつの市 | [plateau-28229-tatsuno-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-28229-tatsuno-shi-2023) |
| 兵庫県 | 三木市 | [plateau-28215-miki-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-28215-miki-shi-2023) |
| 兵庫県 | 姫路市 | [plateau-28201-himeji-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-28201-himeji-shi-2023) |
| 兵庫県 | 朝来市 | [plateau-28225-asago-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-28225-asago-shi-2022) |
| 兵庫県 | 加古川市 | [plateau-28210-kakogawa-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-28210-kakogawa-shi-2020) |
| 奈良県 | 三郷町 | [plateau-29343-sango-cho-2025](https://www.geospatial.jp/ckan/dataset/plateau-29343-sango-cho-2025) |
| 奈良県 | 香芝市 | [plateau-29210-kashiba-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-29210-kashiba-shi-2025) |
| 和歌山県 | すさみ町 | [plateau-30406-susami-cho-2025](https://www.geospatial.jp/ckan/dataset/plateau-30406-susami-cho-2025) |
| 和歌山県 | 太地町 | [plateau-30422-taiji-cho-2021](https://www.geospatial.jp/ckan/dataset/plateau-30422-taiji-cho-2021) |
| 和歌山県 | 和歌山市 | [plateau-30201-wakayama-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-30201-wakayama-shi-2023) |
| 鳥取県 | 日吉津村 | [plateau-31384-hiezu-son-2023](https://www.geospatial.jp/ckan/dataset/plateau-31384-hiezu-son-2023) |
| 鳥取県 | 境港市 | [plateau-31204-sakaiminato-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-31204-sakaiminato-shi-2022) |
| 鳥取県 | 米子市 | [plateau-31202-yonago-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-31202-yonago-shi-2024) |
| 鳥取県 | 鳥取市 | [plateau-31201-tottori-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-31201-tottori-shi-2020) |
| 島根県 | 隠岐の島町 | [plateau-32528-okinoshima-cho-2024](https://www.geospatial.jp/ckan/dataset/plateau-32528-okinoshima-cho-2024) |
| 島根県 | 松江市 | [plateau-32201-matsue-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-32201-matsue-shi-2024) |
| 島根県 | 益田市 | [plateau-32204-masuda-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-32204-masuda-shi-2024) |
| 岡山県 | 津山市 | [plateau-33203-tsuyama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-33203-tsuyama-shi-2025) |
| 岡山県 | 早島町 | [plateau-33423-hayashima-cho-2024](https://www.geospatial.jp/ckan/dataset/plateau-33423-hayashima-cho-2024) |
| 岡山県 | 岡山市 | [plateau-33100-okayama-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-33100-okayama-shi-2025) |
| 岡山県 | 倉敷市 | [plateau-33202-kurashiki-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-33202-kurashiki-shi-2024) |
| 岡山県 | 備前市 | [plateau-33211-bizen-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-33211-bizen-shi-2023) |
| 広島県 | 三次市 | [plateau-34209-miyoshi-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-34209-miyoshi-shi-2022) |
| 広島県 | 海田町 | [plateau-34304-kaita-cho-2025](https://www.geospatial.jp/ckan/dataset/plateau-34304-kaita-cho-2025) |
| 広島県 | 竹原市 | [plateau-34203-takehara-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-34203-takehara-shi-2023) |
| 広島県 | 府中市 | [plateau-34208-fuchu-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-34208-fuchu-shi-2022) |
| 広島県 | 広島市 | [plateau-34100-hiroshima-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-34100-hiroshima-shi-2024) |
| 広島県 | 呉市 | [plateau-34202-kure-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-34202-kure-shi-2020) |
| 広島県 | 福山市 | [plateau-34207-fukuyama-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-34207-fukuyama-shi-2020) |
| 山口県 | 周南市 | [plateau-35215-shunan-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-35215-shunan-shi-2024) |
| 徳島県 | 美波町 | [plateau-36387-minami-cho-2025](https://www.geospatial.jp/ckan/dataset/plateau-36387-minami-cho-2025) |
| 徳島県 | 徳島市 | [plateau-36201-tokushima-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-36201-tokushima-shi-2023) |
| 香川県 | さぬき市 | [plateau-37206-sanuki-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-37206-sanuki-shi-2024) |
| 香川県 | 高松市 | [plateau-37201-takamatsu-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-37201-takamatsu-shi-2022) |
| 愛媛県 | 東温市 | [plateau-38215-toon-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-38215-toon-shi-2023) |
| 愛媛県 | 松山市 | [plateau-38201-matsuyama-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-38201-matsuyama-shi-2020) |
| 高知県 | 香南市 | [plateau-39211-konan-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-39211-konan-shi-2025) |
| 高知県 | 安芸市 | [plateau-39203-aki-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-39203-aki-shi-2025) |
| 高知県 | 高知市 | [plateau-39201-kouchi-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-39201-kouchi-shi-2023) |
| 高知県 | いの町 | [plateau-39386-ino-cho-2024](https://www.geospatial.jp/ckan/dataset/plateau-39386-ino-cho-2024) |
| 福岡県 | 古賀市 | [plateau-40223-koga-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-40223-koga-shi-2024) |
| 福岡県 | 大牟田市 | [plateau-40202-omuta-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-40202-omuta-shi-2023) |
| 福岡県 | 筑前町 | [plateau-40447-chikuzen-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-40447-chikuzen-machi-2023) |
| 福岡県 | うきは市 | [plateau-40225-ukiha-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-40225-ukiha-shi-2025) |
| 福岡県 | 福岡市 | [plateau-40130-fukuoka-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-40130-fukuoka-shi-2024) |
| 福岡県 | 北九州市 | [plateau-40100-kitakyushu-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-40100-kitakyushu-shi-2020) |
| 福岡県 | 久留米市 | [plateau-40203-kurume-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-40203-kurume-shi-2020) |
| 福岡県 | 飯塚市 | [plateau-40205-iizuka-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-40205-iizuka-shi-2020) |
| 福岡県 | 宗像市 | [plateau-40220-munakata-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-40220-munakata-shi-2020) |
| 佐賀県 | 鳥栖市 | [plateau-41203-tosu-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-41203-tosu-shi-2025) |
| 佐賀県 | 武雄市 | [plateau-41206-takeo-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-41206-takeo-shi-2022) |
| 佐賀県 | 小城市 | [plateau-41208-ogi-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-41208-ogi-shi-2022) |
| 佐賀県 | 大町町 | [plateau-41423-omachi-cho-2022](https://www.geospatial.jp/ckan/dataset/plateau-41423-omachi-cho-2022) |
| 佐賀県 | 江北町 | [plateau-41424-kouhoku-machi-2022](https://www.geospatial.jp/ckan/dataset/plateau-41424-kouhoku-machi-2022) |
| 佐賀県 | 白石町 | [plateau-41425-shiroisi-chou-2022](https://www.geospatial.jp/ckan/dataset/plateau-41425-shiroisi-chou-2022) |
| 長崎県 | 波佐見町 | [plateau-42323-hasami-cho-2024](https://www.geospatial.jp/ckan/dataset/plateau-42323-hasami-cho-2024) |
| 長崎県 | 松浦市 | [plateau-42208-matsuura-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-42208-matsuura-shi-2024) |
| 長崎県 | 佐世保市 | [plateau-42202-sasebo-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-42202-sasebo-shi-2022) |
| 熊本県 | 宇城市 | [plateau-43213-uki-shi-2025](https://www.geospatial.jp/ckan/dataset/plateau-43213-uki-shi-2025) |
| 熊本県 | 熊本市 | [plateau-43100-kumamoto-shi-2022](https://www.geospatial.jp/ckan/dataset/plateau-43100-kumamoto-shi-2022) |
| 熊本県 | 荒尾市 | [plateau-43204-arao-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-43204-arao-shi-2020) |
| 熊本県 | 玉名市 | [plateau-43206-tamana-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-43206-tamana-shi-2024) |
| 熊本県 | 益城町 | [plateau-43443-mashiki-machi-2023](https://www.geospatial.jp/ckan/dataset/plateau-43443-mashiki-machi-2023) |
| 大分県 | 臼杵市 | [plateau-44206-usuki-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-44206-usuki-shi-2023) |
| 大分県 | 日田市 | [plateau-44204-hita-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-44204-hita-shi-2020) |
| 宮崎県 | 延岡市 | [plateau-45203-nobeoka-shi-2023](https://www.geospatial.jp/ckan/dataset/plateau-45203-nobeoka-shi-2023) |
| 鹿児島県 | 南さつま市 | [plateau-46220-minamisatsuma-shi-2024](https://www.geospatial.jp/ckan/dataset/plateau-46220-minamisatsuma-shi-2024) |
| 沖縄県 | 那覇市 | [plateau-47201-naha-shi-2020](https://www.geospatial.jp/ckan/dataset/plateau-47201-naha-shi-2020) |
