# WorldEngine — OSM / ODbL research v1

**7 October 2026 · Research only, not legal advice. R and qualified counsel decide.** Sources were checked on this date; their publication/status dates are recorded in [sources.md](sources.md). **Verified** means a primary source states the fact, not that a court has approved WorldEngine. **Interpretation** means an application to this design. **Proposal** means a suggested compliance practice. **Unverified** identifies an unresolved fact or classification. No messages were sent to providers or OSMF. No git commands, builds or repo edits.

## Plain-English summary

**Verified:** WorldEngine can use OSM commercially, including paid apps and paid services. Selling access does not give customers exclusive rights to the underlying open data. OSMF also permits proprietary terms for a finished visual work, subject to its data obligations. [OSMF legal FAQ §§1.2–1.3, 1.7–1.9](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ).

**Interpretation / recommended default:** keep the engine, tools, shaders, generic art and customer experience proprietary; publish the OSM-derived spatial data that the products use. Treat WorldEngine's semantic GLB tiles and companion feature tables as an ODbL data product unless counsel approves a narrower classification. Rendered frames are a different output from the data behind them. A closed image or video does not eliminate obligations on an underlying derivative database. [Produced Work guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline).

**Verified repo policy, not a new legal ruling:** [docs/data-licensing.md](~/Desktop/world-engine/docs/data-licensing.md) already records R's 6 October decision to treat the package's data as a derivative database, provide exact data archives, keep code/art separate, retain visible OSM credit and burn credit into exports. The public offer is still pending in [credits.json](~/Desktop/world-engine/Sources/WorldGen/Profiles/credits.json:30). This report supports reviewing that conservative approach; it does not silently reverse it.

**Interpretation:** independently acquired weather and lidar can coexist with OSM. Drawing them together does not automatically open them. Conversely, moving a derived driveway or corrected building into another file does not make it independent. The dependency and feature/property mix matter. [Horizontal Layers](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Horizontal_Map_Layers_-_Guideline), [Collective Database](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline).

**Verified / caveat:** Overture is not an ODbL-free replacement as a whole. Its themes and source licences differ; §7 records the current theme results and a Microsoft upstream discrepancy. Selecting only records not labelled OSM is not a verified escape from a published theme's licence.

The practical business boundary is between **software/services/art sold under WorldEngine terms** and **map data recipients may reuse under its open licence**. The major unresolved issue is the exact scope of procedural, map-dependent inference and customer modifications—not whether paid products are allowed.

## Product → risk → compliance proposal

Risk ratings are **interpretations of exposure**, not likelihood-of-litigation scores. This table applies the existing repo policy; exceptions require counsel's classification. Source foundations are in §§1–7 and sources.md.

| WorldEngine product | Principal risk | Proposed compliance route |
|---|---|---|
| Paid iPhone apps, including DogWell / Neighboor experiences | **Medium:** public rendering from a modified map; cached/package data also reaches devices | Visible OSM credit and source credits; reachable version-specific free data offer; app EULA expressly carves out ODbL data. Proprietary app code and unrelated personal data stay outside the offer. |
| Downloadable / streamed GLB world packages | **High:** recoverable geometry, feature IDs/tags and semantic companion tables | ODbL data manifest/notice; exact machine-readable data archive; separate prototype/art licences; no blanket no-copy/no-extraction clause over open data. Account for all published LODs and inferred placements. |
| Shareable creator-kit live views / web embeds | **Medium–high:** a public scene is made from a derivative database; users may edit the map | Retain credit on every embed; link the exact base-data version/offer; classify customer edits separately. Offer additional public derivative data when edits alter the open map layer. |
| Creator-kit postcards / videos | **Medium:** attribution gets cropped or omitted; underlying data offer overlooked | Credit baked into exports under current policy; share page links to the offer; distinguish artwork/media licence from map-data licence. |
| Engine SDK licences / white-label deliveries | **High:** licensee EULAs conflict with open data; downstream credits lost | Sell proprietary SDK/art/support independently. Deliver an ODbL data schedule, notices and offer information; make attribution/offer integration part of the delivery requirements. Each licensee handles its own changes and public use. |
| World State API: geometry, tags, inferred doors/yards | **High:** systematic spatial database delivery and map-dependent enrichment | Separate ODbL endpoints/fields from independent live layers; preserve provenance/licences; publish a reproducible versioned data snapshot or counsel-approved complete change set. Charge for API service/latency, without stripping recipients' data rights. |
| World State API: NOAA values, solar math or lidar grid, independently obtained | **Lower ODbL exposure, separate source risks:** accidental merge with map-derived records | Keep independently sourced canonical fields, acquisition paths and licensing; compose at query/render time. A house-specific shadow/lot-slope answer still needs dependency analysis (§4). |
| Private internal prototyping | **Lower:** the public-use boundary changes when external recipients are involved | Keep a release register. Do not equate an NDA or invite-only delivery with internal use; counsel applies control/public-use definitions. |

## 1. GLB meshes: Produced Work or Derivative Database?

**Verified guidance:** OSMF's endorsed 2014 Produced Work guideline uses the intended extraction of original data as the dividing test. Its examples classify conventional images as usual visual works and database dumps as usual databases. It supplies no GLB-specific safe harbour. [Guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline).

**Interpretation:** distinguish three things:

1. A displayed frame/video: a finished visual output, ordinarily a Produced Work.
2. A geometry-only artistic mesh: classification is fact-specific. Recovering a rough silhouette from any image is not the same as delivering a feature database; neither file extension nor theoretical recoverability alone settles it.
3. WorldEngine's package: georeferenced tiles plus individually identifiable feature records, OSM tags, collision hulls and placements. This is much closer to an operational spatial database than an unstructured illustration.

**Inferred from inspected code:** [WorldPackage.swift](~/Desktop/world-engine/Sources/WorldPackage/WorldPackage.swift:399) lists `world.json`, `chunks/*/scene.json`, two GLB LODs, `instances.json`, `clutter-tufts.bin`, `collision.json` and map-derived environment defaults as data. `_FEATURE` links geometry to feature tables; frame coordinates support geolocation. Its classification is an explicit owner policy implemented by the exporter, not an OSMF decision about this exact pipeline.

**Interpretation of “extractable”:** facts a recipient can retrieve as records—footprints, boundaries, source IDs, heights/tags, building hulls, per-feature choices or positioned inferred objects—are the concern. Stable IDs, lookup APIs and georeferencing strengthen the database case. Removing `_FEATURE`, compressing vertices, encrypting assets or deleting tags does not establish that a substantially derived collection has stopped being a database. Do not use obfuscation as the licensing architecture.

**Proposal:** show counsel an actual tile, feature table, exporter dependency graph and intended customer uses. Until reviewed, keep the current conservative classification. Independently authored prototype meshes can remain separately licensed, while their map-derived instance positions and selected per-building values are offered as data. Some rights over individual creative contents may remain separate from database rights; counsel must resolve any combined mesh/art dependency.

## 2. API share-alike and an inexpensive data offer

**Verified licence anchor:** publicly using a Produced Work made from a derivative triggers obligations on that underlying derivative (§§4.4(c), 4.6), without requiring the visual output itself to be ODbL. §4.6 permits the full derivative database or a complete alterations/method file including added contents; internet delivery is free. §§4.7–4.8 address restrictions and parallel unrestricted access. Programs are excluded by §2.3(a). [ODbL legal text](https://opendatacommons.org/licenses/odbl/1-0/).

**Interpretation:** geometry/attribute APIs are not exempt just because queries are small or users cannot download one giant file. WorldEngine's systematic collection and repeated extraction matter. A rendering-only API has a different output classification, but still needs an underlying-data review. Only isolated geocoding has specific endorsed guidance (§3); do not extend that exception to streamed building/yard collections.

**Verified:** OSMF's FAQ allows fulfilling recipient requests and says unmodified OSM can be referred back to OSM. It does not require submitting improvements into the main OSM database. That does not justify pointing users to today's planet dump when WorldEngine has published additional inferred data. [FAQ §1.7.1](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ).

**Proposal for lowest operational complexity:** retain the repo's full-data option rather than disclose the generator through the method option. At each public data release, store an immutable compressed archive, hash, licence/notice, provenance and version index. Reference it from app credits, package notices, API documentation/response metadata and share pages. Automate archive creation from the data-only file manifest. Shared source extracts can be deduplicated by hash; do not charge recipients an internet download fee. A simple static host avoids rebuilding data on each legal request. No numerical hosting-cost claim is verified here.

**Alternative proposal, counsel-gated:** a clearly advertised on-request offer with a working contact and prompt free machine-readable fulfilment can reduce routine transfer. Validate response time, retention, exact scope and practicality—particularly for App Store/DRM parallel distribution—before relying on it. No reviewed primary evidence establishes that Mapbox, Apple or Niantic use this exact arrangement privately. Do not present it as their proven method.

**Interpretation:** subscription/API authentication is not automatically forbidden; restrictions on subsequent rights in the ODbL data are the issue. Keep service rate limits and credentials separate from the unrestricted data-copy route. Avoid EULA clauses claiming all API output is confidential, prohibiting every extraction or forbidding data redistribution without a source-specific carve-out.

**Unverified:** whether one city-wide archive, regional shards plus deltas, or a broader internal database is the correct complete offer for the future API. Do not assume a 200 m transport tile defines the legal database boundary. Counsel should map the publicly used derivation, release versions and parent/detail representations, including aggregate proxies.

## 3. Rule-inferred doors, yards and driveways

**Interpretation:** inferred does not mean independent. A persisted driveway derived from OSM road orientation and building position, a yard partition made from OSM footprints, or a door position attached to an OSM facade has a direct derivation path. Factual corrections made by comparing other sources to OSM also need review. Treat these spatial outputs as part of the offered data by default; mark them inferred so they are not mistaken for observed entrances or legal parcels.

**Verified qualification:** the Trivial Transformations page includes purely algorithmic manipulation examples, but explicitly remains at **proposal stage**. It is not an endorsed blanket exception for procedural enrichment. [Draft guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline). Generic colour palettes, house-type rules and prototype assets are different from a published per-building placement table. Their independent authorship does not automatically decide the status of the table generated with OSM inputs.

**Verified narrow geocoding guidance:** individual direct/indirect geocoding results can be retained with proprietary data when the endorsed conditions hold; systematically reconstructing a substantial database is excluded, and public use of a modified geocoder's underlying database still matters. [Geocoding guideline, endorsed 2017-08-24](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Geocoding_-_Guideline). A user's occasional address lookup is not the same workload as generating every front door in a city.

**Verified substantial guidance:** the endorsed guideline concerns one-off, non-repeated extraction; it lists fewer than 100 features and small settlements, and treats repeated small extractions together. [Substantial guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Substantial_-_Guideline). Neither the app's single-block viewport nor a one-feature API response establishes a city-scale service is insubstantial. Do not design compliance around counting fewer than 100 features per request.

## 4. Independent layers and what mixing breaks

**Verified guidance:** a separately sourced feature type can remain independent; mixed/complementary collections of the same type can attract share-alike. The 2016 Collective Database guideline additionally permits entirely non-OSM properties within a regional cut, even when referenced to OSM IDs. Files need not be physically separate. [Horizontal Layers](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Horizontal_Map_Layers_-_Guideline), [Collective Database](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline).

The following are **WorldEngine interpretations/proposals**, not individual OSMF approvals:

| Layer | Independence-preserving design | Derived/mixed output requiring review |
|---|---|---|
| NOAA weather | Native grid/time values from NOAA, own IDs/coordinates/licence; OSM used only as visual base | Weather values retain their source; a map-dependent collection of house-specific effects must be analysed separately. NOAA's federal status is not assumed for third-party feed content. |
| Sun/moon / shadow | Independently calculated ephemeris and lighting parameters | Per-building shadow polygons, visibility/occlusion or shade scores calculated using OSM walls are dependent outputs, even though the solar algorithm is independent. |
| Lidar slope / terrain | Original independently licensed terrain/slope grid, CRS/datum, quality and source timestamps; no OSM corrections baked back into it | Lot-average slope, terrain snapped/corrected using OSM or a driveway graded from both sources. The source grid and resulting map-dependent records have different dependency paths. |
| City data | Entire independently sourced property/feature type for a defined region, with permission for that product; retain complete provenance | Filling missing OSM buildings, deduplicating against OSM, moving outlines to match OSM or mixing heights opportunistically. Public access to city data alone is not a licence. |
| Overture | Retain actual theme/source/release terms and provenance | Conflated ODbL buildings/roads; non-OSM provenance labels do not undo the published theme licence. |
| Customer photos, text, artwork | Unrelated independently created content linked for display; customer rights and publication permission recorded | Customer-corrected OSM footprint, entrance, road or a persistent spatial field generated using map geometry. |

**Proposal:** maintain three explicit products: OSM-derived map records; independently sourced layer records; render-only composition. Record dependency links and licences **per output**, not just per imported file. Keep original independent data available without OSM augmentation. JSON can contain references to separate layers, but a blanket ODbL label on an inseparable merged record is not proof that a restricted third-party source permits redistribution.

The current `environment.json` policy already distinguishes map-derived defaults from independently authored lighting tables. The future API should expose similarly precise field/layer terms. If a provider's conditions are incompatible with required sharing, solve that boundary or choose a different source before publishing that mixed dataset; attribution alone does not cure it.

## 5. Creator-kit overlays, ownership and paid sharing

**Interpretation:** creator artwork/text/photos are governed by the creator's rights and contract with WorldEngine. Displaying them over an OSM base ordinarily need not assign ownership to OSMF. A property field wholly supplied independently can fit the Collective Database guidance; an arbitrary ID reference is not automatically disqualifying. A paid share changes neither the source of the rights nor the distinction between an overlay and a map correction.

**Proposal:** offer distinct editing categories: visual decoration; independent sourced observations; and edits to the map-derived spatial layer. A customer's facade colour selection may be art/decorative content, while a changed entrance location, building outline or inferred driveway can modify the data product. Classification of per-building style overrides is **unverified**; the repo's decision to keep host overrides separate is an architectural intention, not a legal answer for every public creator workflow.

**Proposal:** customer terms retain customer ownership where applicable, grant publication rights needed for shared views, explain source-specific open data rights and identify when map edits will be released as ODbL data. Never promise all map-dependent exports are exclusive. A live embed should carry base-version and edit-version offer links. Mere viewing/customizing does not make all customers responsible for building a data-hosting service; allocate fulfilment operationally, without claiming contracts remove statutory/licence obligations.

**Unverified / counsel:** who is the public user/publisher when WorldEngine hosts a customer's live scene, exports a customer's data package, or supplies a white-label SDK? Determine each party's role, licence notices and obligations. Consent/privacy cannot be solved by an open licence; avoid including personal locations, private annotations or routes in an offer intended for public map data.

## 6. Attribution in apps, 3D, AR, exports and embeds

**Verified:** credit OSM and identify ODbL. The official copyright page accepts linking to its copyright URL for visual works; data distribution should name/link the licence directly, and nonlinked media use the printed URL. [OSM copyright page](https://www.openstreetmap.org/copyright).

**Verified OSMF safe-harbour guidance, checked 2026-10-07; page edited 2026-09-10:**

| Surface | Relevant guidance |
|---|---|
| Interactive map/app/embed | Legible corner credit or startup credit; licence information accessible. Initial credit must not require interaction. Automatic collapse only after five seconds, except dismissal/map interaction. |
| Static image | Credit on the image; small-image and same-document exceptions exist. |
| Map-focused video | Typically corner credit plus end credits/description; readable duration, with panning/zoom exceptions. |
| Incidental/fictional video | End credits or digital description may suffice; preserve existing incidental-map credits. |
| Game/simulation | Startup, view, gameplay, credits/menu or another suitable location, with detailed information accessible. |
| Database/API data | Notice in data/metadata/documentation; preserve and communicate licence information. |

These are source summaries, not a universal “always visible in every game” rule. [Attribution Guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines). No dedicated AR/headset/3D exception was verified.

**Proposal / existing stricter policy:** display `© OpenStreetMap contributors`, linked to [OSM copyright](https://www.openstreetmap.org/copyright), whenever the WorldEngine world is visible—including AR and embedded scenes. A credits/info control shows ODbL, other providers and “World data download.” Burn `© OpenStreetMap contributors · openstreetmap.org/copyright` into images and map-focused videos; share pages/descriptions carry hyperlinks and the exact data offer. Keep credit readable at phone size, uncropped and unobscured by controls. In AR, use an anchored UI label rather than tiny text on a 3D surface; this is a proposed placement, not an endorsed AR layout.

Data packages additionally include `LICENSE-DATA.md`, ODbL URI, original notices, source versions and the offer. API documentation alone is not a reason to omit metadata accompanying downloadable data. Other providers' notices are cumulative. Neither “Powered by WorldEngine” nor crediting only Overture/Mapbox replaces required OSM attribution. Match attribution to actual OSM-derived layers as locations/zoom change without hiding it accidentally.

## 7. Overture as an alternative — theme-specific results

See the verified theme/licence table below and detailed links in sources.md. Preserve release-specific rights records; do not assume an aggregate schema or GERS ID conveys a permissive licence.

**Verified, 2026-10-07:** current guides reference release **2026-09-23.1**, schema v2.0.0. [Release notes](https://docs.overturemaps.org/blog/2026/09/23/release-notes/).

| Theme | Published terms / ODbL-free? | Conditions and limits |
|---|---|---|
| Places | **Yes, source-specific permissive data:** CDLA Permissive 2.0, Apache 2.0, CC0 | Guide says no OSM. Meta/Microsoft and several partners contribute CDLA data; Foursquare is Apache; AllThePlaces is CC0. Preserve source terms/notices. [Guide](https://docs.overturemaps.org/guides/places/) |
| Addresses | **Generally permissive, source-specific; no single overall licence** | More than 175 sources; some government/custom terms. Review every selected source, including G-NAF/local agreements. Do not replace this inventory with “all CDLA.” [Guide](https://docs.overturemaps.org/guides/addresses/), [attribution register](https://docs.overturemaps.org/attribution/) |
| Transportation | **No: ODbL** | OSM primary, enriched with TomTom/authoritative data. No verified blanket permissive exit by source filtering. [Guide](https://docs.overturemaps.org/guides/transportation/) |
| Buildings | **No: ODbL** | OSM-priority conflation with other footprints; building parts OSM-only; matching records may contribute heights. Non-OSM footprint origin does not prove independent attributes. [Guide](https://docs.overturemaps.org/guides/buildings/) |
| Divisions | **No: ODbL** | Mixed OSM/geoBoundaries and other listed sources. [Guide](https://docs.overturemaps.org/guides/divisions/) |
| Base | **No: published theme ODbL** | Includes OSM plus independently sourced land cover/bathymetry. Separately acquiring an upstream dataset is different from re-licensing the theme. [Guide](https://docs.overturemaps.org/guides/base/) |

**Verified discrepancy, unresolved release lineage:** Overture's attribution register labels Microsoft Global ML Building Footprints ODbL, whereas Microsoft's current direct [README](https://github.com/microsoft/GlobalMLBuildingFootprints) and [LICENSE](https://github.com/microsoft/GlobalMLBuildingFootprints/blob/main/LICENSE) grant CDLA Permissive 2.0; the listed refresh is 2026-08-13. The change date and exact snapshot ingested by Overture are **unverified**. This does not relicense Overture's conflated buildings. Google's direct [Open Buildings](https://sites.research.google/gr/open-buildings/) offers CC BY 4.0 or ODbL; a directly acquired CC BY release is another potential input, subject to its terms and geographic coverage.

**Verified narrow filter precedent:** [2025-09-24 Places release notes](https://docs.overturemaps.org/blog/2025/09/24/release-notes/) document filtering Foursquare for that release's CDLA-only dataset. Today's source inventory has changed; use actual current licences. This is not a blanket permission for filtering ODbL themes. [SourceItem](https://docs.overturemaps.org/schema/reference/common/source_item/) supports property-level provenance and an optional licence; absent licence information requires provider inquiry, not an assumption of permission.

**Verified licence distinction:** CDLA §2.1 requires licence text with shared Data and §3.1 excludes obligations on Results. [CDLA Permissive 2.0](https://cdla.dev/permissive-2-0/). Preserve Apache/CC/source obligations separately; a “Results” rule for CDLA does not apply to ODbL data.

**Interpretation:** the permissive path is an independently built map layer from appropriately licensed inputs, not an OSM-derived map with its IDs removed. Prefer direct-source acquisition if the desired upstream licence differs from Overture's conflated distribution. Independent replacement may retain OSM for other feature types under the guidelines; city/region boundaries and property replacement must be specified. Neither CDLA nor Apache provides an automatic guarantee about trademarks, privacy, architecture or every source's additional terms.

## 8. Commercial precedents and enforcement

**Verified public evidence, not comprehensive compliance audits:**

| Company | Publicly demonstrated practice | What is not established |
|---|---|---|
| Mapbox | Published OSM attribution requirement for Streets; mixed-source maps. [Attribution docs](https://docs.mapbox.com/help/glossary/attribution/), [data licences](https://www.mapbox.com/about/maps) | Full internal derivative scope, data-offer procedure and every customer's compliance. |
| Strava | Official map-source / ODbL acknowledgment. [About Strava Maps](https://support.strava.com/en-us/articles/15402176-about-strava-maps) | All backend datasets or a public offer for every derivative. |
| Apple | Public OSM acknowledgement in Maps legal materials. [Legal page](https://www.apple.com/legal/internet-services/maps/legal-en.html), [acknowledgements](https://gspe21-ssl.ls.apple.com/html/attribution-295.html) | Any special exemption, complete legal audit or every surface's placement. |
| Meta | Historical Daylight ODbL distribution/downloads; 2023 basemap use documented. [Engineering](https://engineering.fb.com/2023/02/07/web/basemap-facebook-instagram-whatsapp-improvements/), [Daylight attribution](https://daylightmap.org/attribution.html) | Daylight as a current 2026 feed: [2024 sunset announcement](https://daylightmap.org/2024/05/03/sunsetting-daylight.html) planned its end and migration to Overture. |
| Esri | ODbL-labelled OSM feature-layer distribution and compatible contributor datasets. [2020 OSM layer](https://www.esri.com/arcgis-blog/products/arcgis-living-atlas/mapping/live-openstreetmap-data-in-arcgis), [Esri/Facebook release](https://www.esri.com/about/newsroom/announcements/esri-and-facebook-collaborate-to-release-new-openstreetmap-ready-datasets) | Legal classification of all proprietary ArcGIS datasets. |
| Niantic / Pokémon GO | OSM use documented by OSMF and a team-attributed community page. [OSMF 2025 announcement](https://blog.openstreetmap.org/2025/02/07/eight-new-corporate-members/), [NianticLabs declaration](https://wiki.openstreetmap.org/wiki/NianticLabs) | Company-hosted derivative offer and complete game attribution audit **unverified**. Wayspots are not synonymous with OSM basemap data. |

**Interpretation:** Daylight and Esri demonstrate open-data distribution alongside proprietary services; visible legal notices demonstrate attribution practices. None proves that membership, donations or returning some edits buys an exemption. Do not copy a competitor's layout or absence of a public download as legal clearance.

**Verified enforcement record:**

- **2012 Apple iPhoto:** OSM's official blog reported missing credit and later its addition in iPhoto 1.0.1. This predates the September 2012 ODbL transition; it is a correction/outreach example, not an ODbL court judgment. [Welcome, Apple!, including May 3 update](https://blog.openstreetmap.org/2012/03/08/welcome-apple/comment-page-1/).
- **2022 board strategy:** OSMF discussed large consumers' attribution deficiencies and possible responses. Discussion of letters/legal action is not proof of a completed lawsuit. [Board notes](https://osmfoundation.org/wiki/Board/Minutes/2022-02-S2S/Attribution_-_Agree_on_an_attribution_enforcement_strategy).
- **Operational tile blocking:** the official report process describes blocking accepted continued non-attribution cases from OSMF's standard tile server after attempted contact. It cannot shut down an independently hosted OSM-derived service. [tile-attribution repository](https://github.com/openstreetmap/tile-attribution).
- **2026 actual case handling:** March LWG minutes record Hotelmap/EVRI/LinkMyRide outreach or escalation discussions and Dopper concerns. Completed takedowns or judgments are not established by these minutes. [2026-03-09 minutes](https://osmfoundation.org/wiki/Licensing_Working_Group/Minutes/2026-03-09).

**Unverified:** no reported ODbL judgment against the named companies was verified in the searched primary sources. That is not proof none exists or that the licence is unenforceable. **Verified licence risk:** breach terminates rights automatically; §9.4 provides specified reinstatement routes. [ODbL §9](https://opendatacommons.org/licenses/odbl/1-0/). **Interpretation:** remediation, injunction/damages exposure, provider/app-store escalation, incompatible asset contracts, customer promises and reputational damage merit counsel's jurisdiction-specific assessment. Do not assume US operation removes contract or overseas database-right exposure.

## 9. Precise questions for counsel and OSMF LWG

These are **proposed questions**, not messages already sent. Attach a small public-data-only package, licence manifest and dependency diagram; avoid personal/customer data.

### Counsel

1. For the supplied GLB + `_FEATURE` + georeferenced scene tables, is each output a derivative database, Produced Work, or separately licensed content? What intent/accessibility facts decide it?
2. Does our exact inferred door/yard/driveway and per-building style pipeline add database contents requiring sharing? Can any operation rely on trivial transformation despite that guideline's draft status?
3. What is the complete derivative scope for a city-wide internal database feeding 200 m tiles, multiple LODs and a feature API? Is a set of versioned shards/deltas sufficient, and which contents must be included?
4. Does delivering exact data archives satisfy §4.6 without generator/rules/shader disclosure, including dependencies on separately licensed prototypes? Is the method alternative safe or unnecessary here?
5. What response time, version retention and recipient access satisfy an on-request offer? How does App Store DRM or enterprise authentication interact with §4.7's practical accessibility requirement?
6. Which app/API/SDK EULA carve-outs preserve ODbL rights while protecting code, credentials, independent assets and personal data? Which anti-extraction clauses conflict?
7. Do per-building shade/slope scores derived jointly from OSM and independent grids constitute derivative contents? Can source grids remain independent while those results are shared?
8. For creator colour overrides, new door coordinates, corrected footprints and customer-provided building assets, which are art, independent property layers or database modifications? Who has the public-use obligations in each hosted/exported workflow?
9. Can each intended city/Overture/source licence lawfully coexist in the proposed collective product? Which complete feature/property substitutions qualify, and what regional-cut boundaries are defensible?
10. May we acquire Microsoft's current direct CDLA building release independently while avoiding Overture's ODbL building distribution? What evidence proves no OSM lineage or mixed licensed fields remains?
11. Are visible credit, burn-in, data notices and offer links sufficient on phone, AR, embeds, widgets and map-focused video? Which surfaces need a different layout?
12. How do applicable US/EU/UK contract/database laws affect this company and global recipients? What incident response, cure, preservation and insurance provisions should we use?
13. Which provider, privacy and individual-content rights cannot be satisfied by a data licence? How do we keep private walk/home annotations out of derivative offers?

### OSMF Licensing Working Group

1. Does the endorsed Produced Work extraction test classify the attached feature-addressable, georeferenced GLB package as data? Does a geometry-only representation differ?
2. Would wholly procedural spatial augmentation from footprints/roads fit your draft trivial-transformation position, and is there newer endorsed guidance? Please distinguish added observations from generated placements.
3. Do you agree that the original independent weather/terrain layers can remain separate while map-dependent shade/lot results are offered? What feature/property boundaries should our manifest show?
4. Is the proposed immutable versioned data archive and linked offer an appropriate §4.6 route for live views, recaps and an API? What should we publish for archived publicly shared scenes?
5. Which attribution category best fits a navigable 3D world and AR overlay? Can you review the proposed visible phone credit and export burn-in layouts?
6. Does whole-property replacement within a named regional cut apply to independently observed customer attributes linked to OSM IDs? Which of our overlay examples fails independence?
7. Is it correct that ordinary isolated geocoding guidance should not be extended to bulk inferred door/yard endpoints or systematically streamed geometry?

Contact through the official [LWG page](https://osmfoundation.org/wiki/Licensing_Working_Group); its guidance informs OSMF's position but does not substitute for counsel or waive contributors' rights.

## 10. Recommended next decisions and unresolved items

**Proposals for R:**

1. Retain the data-open / engine-proprietary package policy; have counsel review concrete samples rather than only abstract file formats.
2. Make the existing pending data offer concrete before public launch. Review exact data scope, recipient rights and version retention.
3. Treat inferred spatial placements as offered data by default; keep independent source grids and generic art separately attributable/licensed.
4. Define creator editing categories and API per-layer terms now so a single commercial EULA cannot accidentally contradict open data rights.
5. Evaluate Overture places/addresses and direct permissive building inputs separately; do not count Overture transportation/buildings as a blanket ODbL exit.

**Unverified register:** legal classification of artistic geometry-only GLBs; complete inference/offer scope; customer style overrides; party responsibilities; method-vs-archive sufficiency; exact on-request fulfilment/retention; current commercial firms' nonpublic arrangements; reported litigation completeness; Overture upstream licence discrepancy; source-specific city rights. This report proposes no licence changes to the repo.
