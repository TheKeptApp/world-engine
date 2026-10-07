# Licensing and attribution checklist

> **Not legal advice.** This is an engineering checklist plus the questions to take to a lawyer. All sources were checked on **2026-10-05**, except the rows and sections updated on **2026-10-06**: H1–H3 (star catalogue), N1 and N2 (aerial and lidar), V1 and O12 (Overture), the live transit and aircraft feed block (checklist rows LT, LA and LR, §12, Q21–Q31 and the live-feed sources in §11), the national transit-feed questions Q33–Q38, the live-aircraft questions Q39–Q43, the aerial and lidar source groups in §11 and §13, and the live-world lane sources in §14 (rows LW). Licence texts and guidelines change, so re-check them before any release. Where a source was ambiguous or could not be found, this document says so and turns it into a lawyer question instead of guessing.
>
> **How quotes are used:** short verbatim quotes (under 15 words, in quotation marks) come only from openly licensed or public licence texts: ODbL, openstreetmap.org/copyright, OSMF wiki pages, Creative Commons, CDLA-Permissive-2.0, Overture docs and the HYG README. Apple's and Epic's agreements are **paraphrased**, with exact section numbers, so a checker can compare each claim against the clause. The only quoted words from them are defined terms and phrases of a few words. Other quoted strings are repo text (file paths given) or attribution text we display. In the live-feed block (rows LT, LA and LR, §12 and Q21–Q31) short quotes under 15 words also come from the agency and provider terms (CTA, Pace, RTD, Metra, FlightAware, JETNET, adsb.lol and others), kept to key phrases; everything else there is paraphrased.

**Summary of blockers.** Nothing blocks internal development today. The repo already shows OSM credit on screen, ships an ODbL notice next to the raw extract, and licenses the derived star file correctly. Live transit and aircraft feeds are not used yet, but before they are, several would block a commercial launch (Pace's static data for "non commercial use" and its undocumented live URLs, CTA's rider-assistance purpose clause, Metra's relay and no-modification wording (unverified), the non-commercial community aircraft feeds, and the cost of commercial aircraft feeds): see §12 and `docs/research/live-feeds.md`. Before any **public release of our own apps**, three things are mandatory and missing:
1. A credits/licences screen that includes the ODbL "offer" of the data behind the world (ODbL §4.6). *2026-10-06: the engine component exists (`WorldCreditsView`, `WorldCreditsButton`, `credits.json`); hosts must show it, and the offer's download URL is not hosted yet (`docs/data-licensing.md`).*
2. Attribution burned into every exported image, video and widget. The on-screen overlay does not appear in offscreen renders. *2026-10-06: the burn-in helper exists (`CreditBurnIn`, `WorldCredits.burnIn`); export code must call it.*
3. Apple Weather attribution UI as soon as any WeatherKit data is shown.

Owner decisions of 2026-10-06 are in §13.

There are two **conditional blockers**:
- **White-label or licensing to third parties.** The world package's data part must be treated as ODbL. That means share-alike, no extra restrictions, and recipients may redistribute it for free. We can sell the engine, the assets we own and services, but not exclusive rights to the world data. WeatherKit access also cannot be shared: each licensee needs its own Apple Developer Program membership and WeatherKit access, or another weather provider.
- **Fab assets.** The Standard License forbids standalone redistribution and forbids letting third parties build the assets into their own products. So Fab assets can never go into a world package, the public ODbL data download, or a white-label deliverable. Fab EULA §6(a) also says we may not "combine, Distribute, or otherwise use" Fab content with code or content under a licence that would directly or indirectly require all or part of the Fab content to be "governed under any terms other than those of this Agreement". It names CC BY-SA as an example. Under that test, CC BY-SA data merely sitting next to Fab assets in one app would not obviously pull the Fab assets under CC BY-SA, but the named example makes this an open question. A lawyer should read the clause against the CC BY-SA star file we bundle **before any Fab purchase**.

---

## 1. Checklist

Status values: **Done** (in repo), **Partly**, **To do**, **Needs lawyer**, **N/A yet** (the source isn't used yet), **Needs provider confirmation** (only the data provider can answer, in writing; used in the LT, LA and LR rows), **Decided** (an owner decision of 2026-10-06 settles the policy, §13; any remaining work is named in the cell).

| # | Obligation | Applies to | How we comply | Status | Source |
|---|---|---|---|---|---|
| **O1** | Credit "OpenStreetMap" visibly whenever the world is on screen, linked to openstreetmap.org/copyright. The historical form "© OpenStreetMap contributors" is accepted. | App screen | `WorldView` overlays `WorldAttributionView` (`Sources/WorldEngine/WorldAttributionView.swift`): fixed-contrast plate, `Link` to /copyright. Apps that draw the world in their own view must add it (doc comment; README "Data attribution"; CLAUDE.md rule). | Done (engine); each host must keep it | [ODbL §4.3](https://opendatacommons.org/licenses/odbl/1-0/); [OSMF Attribution Guideline: Attribution text, Interactive maps](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Attribution_text) |
| **O2** | Same credit in the web renderer, as a link to /copyright | Web | `web/index.html` `#attr` "© OpenStreetMap contributors" is a link to https://www.openstreetmap.org/copyright (quick fix 1, 2026-10-06); styling and position unchanged | Done | [Attribution Guideline: Attribution text](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Attribution_text) |
| **O3** | Collapsing is allowed only by dismissal, on map interaction or after 5 s, and licence info must stay findable. Attribution should not require interaction to see. | App screen, web | Decision 6c: the credit is always visible (never collapsed, stricter than OSMF), plus a small (i) `WorldCreditsButton` (`Sources/WorldEngine/WorldCreditsView.swift`) that opens the credits sheet, as the guideline describes. Adding the button to `WorldView` is proposed to the renderer owner. | Done (policy and component); button placement in `WorldView` / hosts to do | [Attribution Guideline: Interactive maps](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Interactive_maps); [safe-harbour requirements](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Requirements_to_fit_within_OSMF.E2.80.99s_safe_harbour) |
| **O4** | Static images: credit on the image. Where it can't be a hyperlink, print the URL openstreetmap.org/copyright. | Shared image / postcard | Offscreen renders don't include the SwiftUI overlay, so burn "© OpenStreetMap contributors · openstreetmap.org/copyright" into every exported image. Phase 5A's `PostcardComposer` only chooses poses; no image export exists yet, so this applies when export is built. Also put the link in the share text or share page. Burn-in helper now exists: `CreditBurnIn` (`Sources/WorldGen/CreditBurnIn.swift`, tested) and `WorldCredits.burnIn(...)` (`Sources/WorldEngine/WorldCredits.swift`): OSM line plus every other required source credit, fixed-contrast plate, size relative to the image, a corner (decision 6c: no credit-free exports). | Partly (helper done; export callers to do) | [Attribution Guideline: Static images](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Static_images), [Books…](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Books,_magazines,_and_printed_maps); [Legal FAQ §1.8.1–1.8.2](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ). The printed-URL rule is in §1.8.2, and FAQ §1.8 assumes the OSM data is unmodified. |
| **O5** | Video: credit in a corner while the world is shown, plus credit and URL in the end credits or description | Shared video | Burn in a corner credit (run each frame through the O4 burn-in helper); add the URL to the share description | Partly (helper done; video export and description to do) | [Attribution Guideline: TV, film, or video productions](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#TV,_film,_or_video_productions) |
| **O6** | Widgets: legible credit. A thumbnail/icon exemption exists, but whether it covers home-screen widgets is unclear. | Widget | Proposed: show "© OpenStreetMap" in the widget; tapping opens the app, where the licence info is. Widget images can use the O4 burn-in helper (it shrinks to fit but never drops the credit). | Partly (helper done; widget design to do); smallest sizes need a lawyer | [Attribution Guideline: Static images](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Static_images) |
| **O7** | When the raw extract is conveyed (repo, app bundle): licence URI in or next to the data and in its docs; keep the existing notices intact | Raw-data distribution, repo | `Data/areas/<area>/NOTICE.md` (credit, ODbL URI, `out body`); `manifest.json` (`license`, `attribution`); `osm.json` is unmodified, so the Overpass `osm3s.copyright` header stays | Done | [ODbL §4.2(b)–(d)](https://opendatacommons.org/licenses/odbl/1-0/); [Attribution Guideline: Databases](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Databases) |
| **O8** | World package: ODbL notice and licence URI inside the package and in its docs | Package distribution, web, white-label | Decision 6a, quick fix 2: the exporter writes `LICENSE-DATA.md` into every package (ODbL data files, licence URL, every manifest source with licence and attribution, how to obtain the data, separately licensed files, credits); `world.json` adds `licenseURL` per source, a `dataLicense` block and a `credits` array (`docs/package-format.md`, Licensing). Tested. | Done | [ODbL §4.2(b), (d)](https://opendatacommons.org/licenses/odbl/1-0/) |
| **O9** | Offer recipients of the Produced Work (app screen, postcards, web) a machine-readable copy of the Derivative Database, or of the alterations / method, free over the internet | App screen, shared images, web | Link from the credits screen and share page to a free public download of the package's data part. If our transformations count as trivial, a pointer to the unmodified extract / openstreetmap.org is enough (§2.4 below). Plan documented in `docs/data-licensing.md` §2: publish the package's data part plus the source extracts; one URL in `credits.json` (`odbl-offer`, placeholder) feeds the credits view and the package notice. | Partly (plan documented; hosting to do; which case applies needs a lawyer) | [ODbL §4.4(c), §4.6](https://opendatacommons.org/licenses/odbl/1-0/); [Legal FAQ §1.7.1](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ); [Trivial Transformations](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline) |
| **O10** | Conveyed derivative data goes out only under ODbL, with no extra terms or technical measures that restrict it (unless a parallel unrestricted copy is offered) | App bundle, web, package distribution, white-label | The public download from O9 doubles as the parallel unrestricted copy (planned in `docs/data-licensing.md` §2: free, no account, no terms beyond the ODbL). Licence and contract templates must not restrict the package data. | Partly (plan documented; hosting and contract templates to do); needs lawyer | [ODbL §4.4(a), §4.7, §4.8](https://opendatacommons.org/licenses/odbl/1-0/) |
| **O11** | Keep non-OSM user or app data (building overrides) separate; never publish it merged with OSM data | App, shared images, package | Policy in `docs/plan-m1.md` §3.2 / §6: overrides are stored by the host, separately | Done (policy; feature not built). Sharing renders that include overrides needs a lawyer. | [Collective Database guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline); [Horizontal Layers](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Horizontal_Map_Layers_-_Guideline) |
| **O12** | Adding external observation data to OSM features (e.g. Overture heights) is not a trivial transformation, so share-alike covers the additions | Package, all public surfaces | Decide before merging any non-OSM source by OSM ID. Keep per-feature provenance (`scene.json` `roofShapeFrom`/`floorsFrom` already does). **2026-10-06 (decision 1):** Overture fills only footprints OSM lacks, as separate `overture/<id>` features; no Overture value is written onto an OSM feature (Overture records with an OSM source are dropped). The merged area data is ODbL either way (the Overture buildings theme is ODbL). | Done for gap-filling; any later use of Overture heights on OSM buildings needs this gate again | [Trivial Transformations](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline); [ODbL §4.4](https://opendatacommons.org/licenses/odbl/1-0/) |
| **O13** | One findable place listing every source and licence (OSM/ODbL + the O9 offer, stars, weather provider, live feeds, code notices) | App, web | Decision 6b: the engine provides it. `Sources/WorldGen/Profiles/credits.json` (static credits) merged with every manifest source, the host's weather attribution and, since 2026-10-06, the host-supplied live-feed credits (`CreditsCatalog.merged`), shown by `WorldCreditsView` / `WorldCreditsButton`. The live-feed slot is `WorldLiveFeedCredit` (`WorldGen.LiveFeedCredit`), passed as `liveFeeds:` to `WorldCredits.list` / `burnIn` and to the credits view and button: each live feed becomes a "Live data" credit, and entries with `live: false` (e.g. the ambient-planes snapshot) become a separate "Illustrative (not live)" credit (live-feeds §8.8). No screen in `Apps/WorldLab` yet. | Done (engine); each host must show it | [Attribution Guideline: Interactive maps](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Interactive_maps), [Computer games and simulations](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Computer_games_and_simulations) |
| **V1** | Overture buildings, base, divisions and transportation themes are ODbL. Buildings also include CC BY 4.0 and other ODbL sources. | All surfaces, package | If adopted: same handling as O7–O12. Credit "© OpenStreetMap contributors, Overture Maps Foundation" plus per-source credits (e.g. Esri Community Maps contributors, Google Open Buildings) in the credits screen and package notice. `docs/research/data-coverage.md` recommends Overture buildings as a second footprint source for the North Shore (Microsoft ML footprints, ODbL). Esri Community Maps extras (CC BY 4.0) appear in 7 of its audit cells, so per-source credit would apply wherever those are used. **Adopted 2026-10-06 (decision 1):** `worldbake fetch --layers overture` writes the area's manifest source with an attribution built from the datasets present (e.g. Microsoft Global ML Building Footprints (ODbL); Esri Community Maps contributors (CC BY 4.0)) and an `## Overture buildings` section in the area's NOTICE.md; the package notice and `credits.json` merge list every manifest source (`docs/research/overture-source.md`). | Done in code (per area once fetched); credit wording for a few rare datasets unverified | [Overture Attribution and Licensing #buildings](https://docs.overturemaps.org/attribution/#buildings); [Buildings guide](https://docs.overturemaps.org/guides/buildings/#sources-and-licensing) |
| **V2** | Overture places: CDLA Permissive 2.0, Apache 2.0 (Foursquare) and CC0 (AllThePlaces). Contains no OSM data, but joining it to OSM may form an ODbL derivative database. | Package, all surfaces | If adopted: ship the CDLA text with shared data and keep the Apache NOTICE for Foursquare rows | N/A yet | [Overture #places](https://docs.overturemaps.org/attribution/#places); [Places guide](https://docs.overturemaps.org/guides/places/#sources-and-licensing); [CDLA-Permissive-2.0 §2.1](https://cdla.dev/permissive-2-0/) |
| **W1** | When showing Apple weather data (e.g. condition text, temperature): clearly show the Apple Weather mark and the legal link to the other data sources | App screen, web, widget | Host shows the mark (`WeatherAttribution.combinedMarkLightURL`/`DarkURL`, or REST `/attribution/{language}`) and links `legalPageURL` (`legalAttributionText` for apps that can't show the legal page in a Safari view). The engine carries `WeatherAttributionInfo` (`Sources/WorldEnvironment/WeatherProvider.swift`). | To do (struct exists; WorldLab's `ExperienceOverlay` reserves the attribution slot for live data in 5B, no mark or link yet) | [WeatherKit: Attribution requirements](https://developer.apple.com/weatherkit/#attribution-requirements); [WeatherAttribution](https://developer.apple.com/documentation/weatherkit/weatherattribution); [App Review 5.2.5 ("Apple Products"; last sentence)](https://developer.apple.com/app-store/review/guidelines/#5.2.5); [DPLA Att. 8 §1.4](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) |
| **W2** | Value-added output (our rain, snow and fog states derived from the data): credit the source to Apple Weather, with a notice that Apple's data was modified | App, shared images, widget, web | `WeatherAttributionInfo.modifiedNotice` ("Weather visualization modified from … data.") must be displayed beside the world | Partly | [WeatherKit: Value-added services or products](https://developer.apple.com/weatherkit/#attribution-requirements); [DPLA Att. 8 §1.2](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) |
| **W3** | Non-interactive outputs (postcards, video, widgets): Apple publishes no specific rule | Shared image, video, widget | Proposed: burn in the mark and modified notice; legal link on the share page and in the app | Needs lawyer / Apple confirmation | No Apple source found |
| **W4** | Weather alerts: embed a link to Apple's alert page, name the issuing agency in full, never modify the text | App, web | The engine shows no alerts. Keep it that way, or implement all three. | Done (not shown) | [WeatherKit: Weather alerts](https://developer.apple.com/weatherkit/#attribution-requirements) (all three rules); [DPLA Att. 8 §1.4](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) (no modification only) |
| **W5** | No bulk downloads, no secondary or derived weather database; cache or store only temporarily and on a limited basis, for performance | App, package, shared images, white-label | `TemporaryWeatherCache`: memory only, fresh 30 min (15 while changing), stale ≤ 2 h, `purge`. Still to do: never write Apple data into exported packages' `environment.json`, saved recaps or postcard metadata; honour `expirationDate` / `expireTime`. | Partly | [DPLA Att. 8 §1.5, §1.6](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/); [WeatherMetadata](https://developer.apple.com/documentation/weatherkit/weathermetadata); [REST Metadata](https://developer.apple.com/documentation/weatherkitrestapi/metadata) |
| **W6** | No fees for weather data in its original form, and no fees solely for access to Apple Services; our end-user terms must not permit reverse engineering of the WeatherKit APIs or data; not for emergency or life-saving use; an EULA notice if the app gives real-time weather guidance | App, web | Keep weather a value-added visualization; add an anti-reverse-engineering clause covering WeatherKit data to the app EULA; add the §2.2 notice if counsel says it applies | To do; needs lawyer | [DPLA §2.8, Att. 8 §1.2, §1.3, §2.2](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) |
| **W7** | Use the service only for our own apps and websites; don't share keys or sublicense the API or data; third parties need their own access | White-label | The engine never calls WeatherKit and holds no keys (the WorldLab demo app has a one-shot `WeatherKitProbe` on its own explicit App ID since the phase 5A merge) (provider-neutral `WeatherProvider`; `docs/plan-m1.md`: "The engine doesn't call WeatherKit"). Each licensee brings its own membership and WeatherKit access, or another provider. | Done in engine design; contracts to do | [DPLA §1.2 "Application", §2.6, §2.8, §2.9, Att. 8 §1.2](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) |
| **W8** | Web version through the REST API: same attribution rules. REST supplies logos (`/attribution/{language}`) and `Metadata.attributionURL`. | Web | Signing key server-side; show logos (partial URLs, appended to https://weatherkit.apple.com) and the legal link. The §2.8 wording ("Apple-branded products") needs clearing; see §4.5 for both sides. | Needs lawyer | [WeatherKit REST API](https://developer.apple.com/documentation/weatherkitrestapi/); [REST Attribution](https://developer.apple.com/documentation/weatherkitrestapi/attribution); [DPLA §2.8](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) |
| **H1** | **HYG is replaced.** The star file is now derived from the Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren 1991), distributed by NASA HEASARC. Its licence checks (HEASARC says its materials are freely available; the data.gov record lists U.S. Government Works) found no copyright or usage condition, so it is treated as public domain. CC BY-SA no longer applies to the star file, so the share-alike, notice and change-note duties of CC BY-SA 4.0 are gone. | App bundle, package, web | `Sources/WorldEnvironment/Catalog/STARS-NOTICE.md` records the checks, hashes and caveat; the JSON header (`source`, `license`, `licenseURL`, `changes`); one-command rebuild with `scripts/data/build_star_catalog.py`. Unverified: the catalogue's own CDS ReadMe (bot check blocked it). Proper names come from the IAU Catalog of Star Names (CC BY, attribution only, credited in the notice). | Done (replaced; CDS ReadMe unverified) | [HEASARC data policy](https://heasarc.gsfc.nasa.gov/docs/heasarc/data_policy.html); [data.gov record](https://catalog.data.gov/dataset/bright-star-catalog); [HEASARC BSC5P](https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html); [IAU star names](https://www.iau.org/public/themes/naming_stars/) |
| **H2** | Credit is a courtesy now, not a licence duty (the old HYG CC BY-SA 4.0 §3(a) credit no longer applies) | App screen, web, shared images showing stars | `StarCatalog.attribution` is now "Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren 1991), public domain." and travels as `sky.starAttribution` in the environment document; `credits.json` (`star-catalog`) carries the same courtesy credit, shown by `WorldCreditsView`. The IAU star names are labels only and never drawn; if an app ever shows them, add "Star names: IAU Catalog of Star Names, IAU Working Group on Star Names" (CC BY). | Courtesy only (in the credits file) | [HEASARC data policy](https://heasarc.gsfc.nasa.gov/docs/heasarc/data_policy.html); [IAU-CSN header](https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt) |
| **H3** | Not applicable any more: the CC BY-SA 4.0 §3(b)(3) bar on additional terms or technical measures applied only to the HYG file, which is replaced | App bundle (App Store), white-label | Nothing to carve out. The star file carries no share-alike or non-restriction condition, so the star file no longer enters the lawyer questions on App Store terms (Q12). | N/A (resolved by replacing HYG) | [STARS-NOTICE.md](../../Sources/WorldEnvironment/Catalog/STARS-NOTICE.md) |
| **F1** | Fab Standard License: any engine or tool is allowed; available file formats depend on the listing | App | Buy only listings that offer non-Unreal formats (FBX / glTF / USD) | Decided (6e): Personal tier; Fab assets only inside app bundles | [Fab EULA (summary; §2(d), §3(a))](https://www.fab.com/eula) |
| **F2** | Distribute assets only inside a Project as an included dependency, in object code, and restrict end users from extracting them | App, web | Add an anti-extraction clause to the app EULA and compile assets into the app. On the web, don't serve loose files without counsel's view. Decision 6e: Fab assets only inside app bundles. | Decided (6e); EULA clause to do on purchase; web needs lawyer | [Fab EULA §4(a), §4(c)](https://www.fab.com/eula) |
| **F3** | Rendered images and videos made with assets may be distributed freely | Shared image, video | Nothing extra needed | OK (decided 6e) | [Fab EULA §4 "Distributing Linear Media Projects" (4(b))](https://www.fab.com/eula) |
| **F4** | No standalone distribution; no letting third parties build the assets into their products; no editing tools or templates that export them | Package distribution, white-label | The exporter must never put Fab assets into a world package or the ODbL download. White-label licensees buy their own licences. Policy recorded in `docs/package-format.md` (Licensing) and `docs/data-licensing.md`. | Decided (6e): never in packages, the download or white-label deliverables | [Fab EULA §5(a), §6 "General Restrictions" (ii)–(iii)](https://www.fab.com/eula) |
| **F5** | Don't combine assets with GPL, LGPL or CC BY-SA content | App, package (ODbL) | The CC BY-SA part is resolved: HYG is replaced by the public-domain Yale Bright Star Catalogue (the IAU names are CC BY, attribution only). Still open: counsel's reading of §6(a) against the ODbL package data (Q13), and a check for GPL/LGPL code. Decision 6e: Fab assets only inside app bundles. | Star-file part resolved; ODbL-package part needs lawyer (kept, 6e) | [Fab EULA §6(a)](https://www.fab.com/eula) |
| **F6** | Personal tier only if we plus affiliates made ≤ US$100,000 gross revenue in the digital content industry in the last 12 months, counting advances and funds raised | Purchase | Decide the tier at purchase; record the EULA version (Oct 1, 2024) with each purchase | Decided (6e): Personal tier for now; re-check eligibility at each purchase | [Fab EULA §2(a), §7(a)](https://www.fab.com/eula); [Epic: Licenses and Pricing in Fab](https://dev.epicgames.com/documentation/en-us/fab/licenses-and-pricing-in-fab) |
| **X1** | Keep licence notices for bundled code: the Earcut port (ISC) and three.js 0.180.0 (MIT, per `web/package-lock.json`) | App, web | The ISC notice is in the header of `Sources/WorldMesh/Earcut.swift`. `credits.json` now carries both notices with full licence text (Earcut: app surface; three.js: web surface), shown by `WorldCreditsView`. Still needed: the three.js notice inside `web/dist` (`web/build.mjs` uses `legalComments: 'none'`, which strips it from the bundle). | Partly (app done; web dist notice to do) | Licence text in the source file / package metadata |
| **LT1** | Metra: redistribute the data through our own host and never direct users to Metra's servers, so a relay is mandatory | Relay, phones | Phones call only our relay; Metra URLs and the key exist only server-side (live-feeds §4) | N/A yet; To do (before using the feed) | [Metra GTFS API page](https://metra.com/metra-gtfs-api) and [licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement): **unverified (site blocks automated access; confirm in a normal browser)** |
| **LT2** | Metra: wherever its data is shown, state "not sponsored, affiliated, or operated by Metra" and the date and time of the last update; never say the data is accurate, complete or timely | App screen, exports, widgets | Relay response carries per-feed `attribution` and `updated`; host shows both; burn into exports together with O4–O6 | To do (before using the feed) | [Metra licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement): **unverified (site blocks automated access; confirm in a normal browser)** |
| **LT3** | Metra: licensee "must not modify or delete Data"; our area filtering, compact re-encoding and snapshot purging may conflict | Relay | Keep each Metra response unaltered and derive tile views from it; ask Metra in writing | Needs provider confirmation / lawyer | [Metra licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement): **unverified (site blocks automated access; confirm in a normal browser)** |
| **LT4** | Metra: key by web form with licence acceptance; paid or ad-supported use not addressed; revocable, "AS IS", changeable and terminable without notice; Metra marks not used with the Data; its website terms bar robots and commercial use of the website | Business, relay, tooling | An authorised person accepts the licence for the company; key kept server-side; ask about paid use; no Metra logos; never scrape metra.com | Needs provider confirmation / lawyer | [Metra licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement), [website terms](https://metra.com/terms-and-conditions): **unverified (site blocks automated access; confirm in a normal browser)** |
| **LT5** | CTA: use only to assist riders or promote public transportation; other uses need CTA's express permission | Business, app | Ask CTA whether an ambient live-vehicle layer, and shared images of it, qualify before shipping | Needs provider confirmation / lawyer | [CTA Developer License Agreement](https://www.transitchicago.com/developers/terms/) |
| **LT6** | CTA: no selling CTA Data separate from the app; caching allowed with reasonable efforts to keep it current; delete all CTA Data on termination and certify in writing if asked | Relay, packages, white-label | Latest snapshot only, expiring in minutes; a purge procedure; no CTA data in packages, fixtures or exports | To do (before using the feed) | [CTA DLA](https://www.transitchicago.com/developers/terms/) |
| **LT7** | CTA: no implied affiliation; credit optional; only the Bus Tracker and Train Tracker logos, 'L' route colours and standard icons; no official CTA maps; no CTA mark as the most prominent feature; no project named "Bus Tracker" or "Train Tracker" | App, exports | No CTA logos by default; the optional credit line travels through the relay | To do (before using the feed) | [CTA branding guidelines](https://www.transitchicago.com/developers/branding/); [CTA DLA](https://www.transitchicago.com/developers/terms/) |
| **LT8** | CTA: daily caps per key shared by the whole relay (Train Tracker 50,000 or 100,000, Bus Tracker 100,000) and an IP-based DoS time-out; the Bus Tracker key needs a person's Bus Tracker account, one key per account | Relay | Server-side keys; one egress IP; 30 s polls; only routes in active tiles; company-owned account; ask for higher caps before launch | To do (before using the feed) | [Train Tracker overview](https://www.transitchicago.com/developers/traintracker/), [docs](https://www.transitchicago.com/developers/ttdocs/), [Bus Tracker overview](https://www.transitchicago.com/developers/bustracker/) |
| **LT9** | CTA: the agreement copy on the key-application page differs from the current terms page and is probably older (neither is dated): it has an unfilled "[Insert Link]" placeholder, a narrower grant (use, reproduce, distribute) and says CTA owns "any changes that you make"; which text binds is unclear; whether a relay is "your application" is not stated | Business, relay | Keep a dated copy of the text accepted when the key is issued; ask CTA | Needs provider confirmation / lawyer | [Key-application page](https://www.transitchicago.com/developers/traintrackerapply/); [CTA DLA](https://www.transitchicago.com/developers/terms/) |
| **LT10** | CTA GTFS-RT beta: key route, rate limits and terms are not published | Relay | Do not use until CTA confirms | N/A yet | [CTA GTFS-RT beta page](https://transitdata.transitchicago.com/) |
| **LT11** | Pace: static data shared "for non commercial use"; the Pace name and logo need prior written consent | Business, app | Do not ship Pace data in a paid or ad-supported app without Pace's written permission | Needs provider confirmation / lawyer (do not use meanwhile) | [Pace data page](https://pacebus.com/route-timetable-data-services) |
| **LT12** | Pace: live GTFS-RT URLs are undocumented (found in a third-party catalogue, on the same host as Pace's own Bus Tracker); Pace says its Bus Tracker predictions are not available for download | Relay | Do not use | N/A yet; Needs provider confirmation | [Pace data page](https://pacebus.com/route-timetable-data-services); [Pace Bus Tracker tools page](https://pacebus.com/bus-tracker-tools) (host); third party: [Transitland Atlas record](https://raw.githubusercontent.com/transitland/transitland-atlas/main/feeds/pacebus.com.dmfr.json) |
| **LT13** | RTD: use, reproduce and redistribute allowed; RTD marks not used with the Data; an "unofficial web site" notice may be required; no availability promise; paid use not addressed | Relay, app | Non-endorsement line in the credits; no RTD marks, maps or logo; ask RTD about paid use | To do (before using the feed); Needs provider confirmation | [RTD licence](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement); [RTD static GTFS page](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs) |
| **LT14** | All transit feeds: revocable, "as is", terms change without notice; indemnities and forums (CTA: Illinois law, Cook County courts, you indemnify CTA; RTD: Colorado law, Denver courts, indemnity to the extent permitted by law) | Business | Per-feed kill switch and a "live data unavailable" state (live-feeds §4.7); a lawyer reviews indemnity and forum before anyone accepts | Needs lawyer | [CTA DLA](https://www.transitchicago.com/developers/terms/); [RTD licence](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement); Metra licence: **unverified (site blocks automated access; confirm in a normal browser)** |
| **LA1** | OpenSky: public API is for research and non-commercial use; commercial use needs a licence; cloud hosts may be blocked | Relay | Not used | N/A yet | [OpenSky API docs](https://openskynetwork.github.io/opensky-api/index.html); its terms page and `/data/api` page: **unverified (site blocks automated access; confirm in a normal browser)** |
| **LA2** | ADS-B Exchange Community API: non-commercial | Relay | Not used | N/A yet | [ADS-B Exchange Developer Hub](https://www.adsbexchange.com/community/developer-hub/) |
| **LA3** | ADS-B Exchange Enterprise (JETNET terms for order forms executed on or after 2025-01-14): section 2.d allows data to be retrieved or presented for a third-party end user only if that end user is a direct JETNET subscriber under a separate active Order Form using their own credentials, with permitted workflows defined in the Order Form, and any reseller, referral or pass-through arrangement needs a separate signed agreement; section 2.b(xi) bars publishing or distributing the data unless JETNET authorises it in writing or the Order Form says so, and requires the attribution "JETNET, LLC" where authorised; cached or stored data must be removed within 30 days after expiry (2.d) | Relay | A fan-out relay is not covered by the standard terms; it needs a special agreement, or every app user would have to be a JETNET subscriber | N/A yet; Needs provider confirmation | [JETNET terms of use](https://www.jetnet.com/legal/terms-of-use/) (the ADS-B Exchange terms address redirects there) |
| **LA4** | adsb.lol (ODbL): attribute; share-alike on a publicly used adapted database; keep open if redistributed; the operator asks production users to get in touch; no SLA; an API key is planned | Relay, shared images | Ask the operator; attribution string in the relay response; decide the ODbL status of the relay snapshot (Q25); poll slowly | To do (before using the feed); Needs provider confirmation / lawyer | [adsb.lol API spec](https://api.adsb.lol/api/openapi.json); [ODbL summary](https://opendatacommons.org/licenses/odbl/summary/); [adsb.lol privacy and licence page](https://www.adsb.lol/privacy-license/) |
| **LA5** | adsb.fi: personal, non-commercial use only; no licensing, selling or leasing; cite adsb.fi and link its home page | Relay | Not used | N/A yet | [adsb.fi README](https://raw.githubusercontent.com/adsbfi/opendata/main/README.md) |
| **LA6** | airplanes.live: non-commercial use; feeder-only | Relay | Not used | N/A yet | **Unverified (site blocks automated access; confirm in a normal browser)**: earlier terms read from Internet Archive copies after the site returned 403; feeder-only per a third-party GitHub issue (repository `skylight`, issue 66; owner name omitted, so no link) |
| **LA7** | FlightAware AeroAPI Standard: the licence lists B2C embedding and internal use (the pricing page marks B2B as Premium only); data to third parties without additional fee, only non-raw, embedded and never through the AeroAPI API; raw data kept at most 30 days; no "commercial aircraft situational displays"; no backfill from another real-time provider without FlightAware's prior written permission; no modifying AeroAPI Data without permission, while Derivative Works are allowed | Relay, white-label | Written confirmation of the relay model and of whether normalising counts as a Derivative Work; serve only derived normalised fields; no community fallback unless FlightAware agrees in writing; the relay is not offered to third parties | Needs provider confirmation / lawyer | [AeroAPI Standard licence](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License.pdf); [AeroAPI pricing page](https://www.flightaware.com/commercial/aeroapi/) |
| **LA8** | FlightAware terms: no resale or redistribution of Data Services unless the Order allows it; not for safety-of-life, navigation, collision avoidance or air traffic control | App | "Not for navigation" notice in the app; keep within the Order | To do (before using the feed) | [FlightAware Terms and Conditions (Sep 2026)](https://www.flightaware.com/commercial/flightaware-terms-conditions-Sep2026.pdf) |
| **LA9** | Flightradar24: API data stored at most 30 days; raw data not to be resold or redistributed; commercial products credit Flightradar24; no backfill from another provider | Relay | Written confirmation of the relay model; credit string in the relay response | Needs provider confirmation | [Storage rules](https://fr24api.flightradar24.com/docs/storage-rules); ToS clauses: **unverified (site blocks automated access; confirm in a normal browser)** |
| **LA10** | LADD owners can have data filtered from public display, but only by participating sites; PIA gives an aircraft an alternate ICAO address (it does not hide the aircraft, it breaks the link to the registered owner); the FAA binds SWIM-feed vendors to filter LADD participants; community feeds describe themselves as unfiltered and flag such aircraft rather than hide them | Relay | Drop LADD and PIA aircraft before caching or logging; send no ICAO address, registration or owner data to phones; keep a deny list for removal requests | To do (before using any aircraft feed); lawyer on whether a legal duty applies to us (Q28) | [FAA LADD page](https://www.faa.gov/pilots/ladd); [NBAA PIA page](https://nbaa.org/aircraft-operations/security/privacy/privacy-icao-address-pia/) |
| **LA11** | FAA SWIM, Wingbits, Spire (not used): SWIM needs a request to the FAA for some services and its vendors are bound to filter LADD aircraft; Wingbits B2B terms bar giving direct access to the data feed or APIs; Spire's price and licence are by sales (unconfirmed). Aireon: sold through FlightAware Premium on request; its own terms were not researched (unconfirmed) | n/a | Not used | N/A yet | [FAA SWIM get-connected page](https://www.faa.gov/air_traffic/technology/swim/products/get_connected); [FAA LADD page](https://www.faa.gov/pilots/ladd); [Wingbits B2B terms](https://wingbits.com/terms-and-conditions/b2b); [Spire Aviation docs](https://aviation-docs.spire.com/api/flights-live/introduction); [FlightAware AeroAPI pricing page](https://www.flightaware.com/commercial/aeroapi/) |
| **LR1** | Show the attribution of every live feed that has vehicles on screen, alongside the OpenStreetMap credit | App screen, exports | Registry strings pass through the relay response; the host displays them; burn into exports with O4–O6. Since 2026-10-06 the engine has a host-supplied live-feed credit slot for this: `WorldLiveFeedCredit` passed as `liveFeeds:` to `WorldCredits.list` / `burnIn` and to `WorldCreditsView` / `WorldCreditsButton` (live-feeds §8.8). Each live feed becomes a "Live data" credit; non-live entries (`live: false`, e.g. ambient planes) become a separate "Illustrative (not live)" credit. | To do (before using any feed): the engine slot exists, hosts must pass the feeds on screen | Per-feed sources in LT1–LT14 and LA1–LA11 |
| **LR2** | Keep no more live data than each provider allows: latest snapshot only; no live data in the repo, packages, fixtures or export metadata | Relay, repo | Snapshot expires in minutes; synthetic fixtures only | To do (before using any feed) | LT6, LA3, LA7, LA9 |
| **LR3** | Keys stay server-side: Metra requires redistribution through our own host, CTA caps keys per account | Relay | Secret store; one key per feed and environment | To do (before using any feed) | LT1, LT8 |
| **N1** | USDA NAIP aerial imagery (NAIP-derived statistics are used: measured `trees.canopyShare` ships in four profiles, evanston, chicago-dense-north, front-range and wilmette; research tooling in `Tools/regionkit/aerial/`): public domain; USDA requests the credit "NAIP imagery provided by USDA Farm Service Agency". Per-block canopy shares and tree-spacing estimates (`Data/areas/<id>/canopy-blocks.json` in six test areas: evanston-south, lakeview-sheil-park, sloans-lake, wilmette-vattmann-park, winnetka-village-green and kenilworth-station; aggregates over street-bounded blocks, added 2026-10-06, the last two and the Wilmette tree-count calibration added the same day; `docs/research/aerial.md` 13.9 and 13.10) are NAIP-derived data, public domain, covered by the same always-shown credit; they carry no per-building values. Per-building hints keyed by OSM ID would fall under O12 | Credits screen, package notice, research docs | Credit line in the credits list and in any data notice that carries NAIP-derived values (`credits.json` `naip`, condition `always` since 2026-10-06, because the shipped profiles carry NAIP-measured canopy shares); no per-building NAIP values in packages until O12 is decided (`docs/research/aerial.md` §8) | Done (credit always shown); per-building hints stay gated by O12 | NAIP tile metadata (TIFF ImageDescription) and USDA FSA FGDC metadata ("Use_Constraints: None"), quoted in `docs/research/aerial.md` §1; [USDA FSA policies](https://www.fsa.usda.gov/help/policies-and-links) (not re-checked: the page timed out for the checker) |
| **N2** | USGS 3DEP lidar (wherever lidar-derived values are used: tree heights today, and possibly zone roof-form mixes, complex shares or pitches from `Tools/regionkit/lidar/`): "US Government Public Domain" per the AWS Open Data registry; the delivery's FGDC metadata asks that "Acknowledgement of the originating agencies would be appreciated in products derived from these data" and obliges anyone who modifies the data to describe the modifications. Per-building hints keyed by OSM ID would fall under O12 (external observation data on OSM features) | Credits screen, package notice, research docs | Credit "USGS 3D Elevation Program" wherever lidar-derived values are used. Lidar values used so far: `trees.heightMeters` and `youngShare` in three profiles (evanston, wilmette, chicago-dense-north, since 2026-10-06), whose provenance credits "U.S. Geological Survey, 3D Elevation Program". **Lidar data now ships in five areas (2026-10-06):** `Data/areas/{evanston-south, lakeview-sheil-park, wilmette-vattmann-park, winnetka-village-green, kenilworth-station}/lidar-roofs.json` (per-footprint top and eave height, pitch, roof form; keyed by the engine ref `way/…`, `relation/…` or `overture/…`) and `roof-mix-blocks.json` (roof-form shares per street block, hidden when a block has fewer than 5 classified roofs). Each file header carries `licence` "US Government Public Domain" and `credit` "USGS 3D Elevation Program" (courtesy credit; Cook County lidar dataset `USGS_LPC_IL_4County_Cook_2017_LAS_2019`), each area `NOTICE.md` has a "Lidar roof hints" section, and the area manifests' Overture attribution already names "USGS 3D Elevation Program" for the three Overture-footprint areas. Nothing from the point cloud is committed. The Wilmette area's manifest attribution already names "USGS 3D Elevation Program" (via Overture's sources), but `credits.json` has no separate 3DEP entry yet; describe the derivation (plane segmentation, aggregates) in the notice; no per-building lidar values in packages until O12 is decided for them (`docs/research/lidar-roofs.md` §8). **Terrain slope grids (2026-10-06):** `Data/areas/{evanston-south, lakeview-sheil-park}/terrain-slope.bin` + `.json` from the Cook dataset above (`USGS_LPC_IL_4County_Cook_2017_LAS_2019`, project IL_4_County_QL1_LiDAR_2016_B16, QL1, flown 2017-04-16 to 2017-05-07) and `Data/areas/sloans-lake/terrain-slope.bin` + `.json` from a second 3DEP project, Denver: EPT `CO_DRCOG_2_2020` (project CO_DRCOG_2020_B20, delivery CO_DRCOG_2_2020, QL2, flown 2020-05-26 to 2020-06-12; FGDC tile metadata with the same `useconst` as Cook). 1 m slope rasters from vendor ground points only (no OSM keys, no buildings, no point cloud committed); the 1 m DEM of each project (prd-tnm, public domain) was read in windows for validation only. Each header names the source and carries `attribution` "USGS 3D Elevation Program", `license` public-domain and the method (the FGDC "describe the modifications" request); tool: `Tools/regionkit/terrain/`. The National Map FAQ also requests "Data available from U.S. Geological Survey, National Geospatial Program." when citing or reprinting | Partly (tree-height aggregates ship in three profiles; per-footprint roof hints and block roof mixes are committed data in five areas with the credit in file headers and NOTICE.md; no `credits.json` 3DEP entry yet; O12 is still undecided for the per-building values, which sit on OSM and Overture footprints, so a package that bundles `lidar-roofs.json` stays gated by it; the terrain slope grids are not keyed to OSM or Overture, so O12 does not apply to them; their credit is in the file headers only, not yet in NOTICE.md or `credits.json`) | AWS Open Data registry entry `usgs-lidar` ("License: US Government Public Domain"); FGDC metadata of tile `USGS_LPC_IL_4_County_QL1_LiDAR_2016_B16_LAS_15759550` (`useconst`), quoted in `docs/research/lidar-roofs.md` §1. USGS copyright page (www.usgs.gov/information-policies-and-instructions/copyrights-and-credits; earlier 403, **read 2026-10-06**: "USGS-authored or produced data and information are considered to be in the U.S. Public Domain") and The National Map terms FAQ (https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map, read 2026-10-06: "free and in the public domain", no restrictions, acknowledgement requested); Denver: FGDC metadata of tile `USGS_LPC_CO_DRCOG_2020_B20_w0495n4399` (`useconst`) |
| **Z1** | U.S. Census Bureau ZIP Code Tabulation Areas 2020 (TIGER/Line ZCTA5, via TIGERweb): public domain as a U.S. Government work (the Census terms pages checked say nothing explicit either way, so this is unverified). Used for ZCTA tagging in the map data layer; extracts in `Data/areas/<id>/zcta.json` (format `census-zcta-v1`, clipped to each area's context box; tooling in `Tools/regionkit/zcta/`). Suggested credit: "U.S. Census Bureau, TIGER/Line ZIP Code Tabulation Areas (2020)". | Credits screen, package notice, research docs | Credit line wherever ZCTA-tagged data ships; the extracts hold boundaries only, no OSM IDs or personal data. TIGERweb was queried sequentially with the User-Agent "WorldEngine regionkit (research)" | To do (credit line to add) | Unverified: no Census page read states the licence. Read 2026-10-06: [Census API terms of service](https://www.census.gov/data/developers/about/terms-of-service.html) (attribution wording only), [Open data policy](https://www.census.gov/about/policies/open-gov/open-data.html), [Citation guidance](https://www.census.gov/about/policies/citation.html); service: [TIGERweb ZCTA layer](https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/PUMA_TAD_TAZ_UGA_ZCTA/MapServer/7) |

---

## 2. OpenStreetMap (ODbL 1.0)

### 2.1 Key clauses

- **Definitions** ([ODbL §1](https://opendatacommons.org/licenses/odbl/1-0/)):
  - A *Produced Work* is a work such as an image, audiovisual material, text or sounds that results from using the whole or a Substantial part of the Contents.
  - A *Derivative Database* is any adaptation or modification of the database, including extracting or re-utilising a Substantial part in a new database.
  - *Convey* means enabling someone to make or receive copies. The text adds: "Conveying does not include interaction with a user through a computer network", where no copy is transferred.
  - *Publicly* means to anyone outside your control.
- **Code is out of scope:** the licence does not apply to "computer programs used in the making or operation of the Database" ([§2.3(a)](https://opendatacommons.org/licenses/odbl/1-0/)). Rights in individual Contents are not covered either, other than Database Rights or in contract ([§2.4](https://opendatacommons.org/licenses/odbl/1-0/)). So WorldGen, the renderers and our own art stay ours.
- **Notices:**
  - To Publicly Convey the database, or a derivative of it, you need ODbL terms, the licence text or URI in the data and its docs, intact notices, and a directory-level notice where a file can't hold one ([§4.2](https://opendatacommons.org/licenses/odbl/1-0/)).
  - Public use of a Produced Work needs a notice that the content came from the database and is under ODbL ([§4.3](https://opendatacommons.org/licenses/odbl/1-0/)).
- **Share-alike:**
  - A publicly used derivative database must be licensed under ODbL, a later similar version of it, or a compatible licence ([§4.4(a)](https://opendatacommons.org/licenses/odbl/1-0/)).
  - Publicly using a Produced Work makes its derivative database publicly used ([§4.4(c)](https://opendatacommons.org/licenses/odbl/1-0/)).
  - Making a Produced Work "does not create a Derivative Database for purposes of Section 4.4" ([§4.5(b)](https://opendatacommons.org/licenses/odbl/1-0/)).
  - Internal use is not public ([§4.5(c)](https://opendatacommons.org/licenses/odbl/1-0/)).
- **Offer:** whoever publicly uses a derivative database, or a Produced Work from one, must "offer to recipients of the Derivative Database or Produced Work a copy", in machine-readable form, of either (a) the entire derivative database or (b) the alterations or the method, free of charge over the internet ([§4.6](https://opendatacommons.org/licenses/odbl/1-0/)).
- **No restrictions:** no added terms or technical measures restricting ODbL rights, unless an unrestricted copy is also made available ([§4.7](https://opendatacommons.org/licenses/odbl/1-0/)). "You may not impose any further restrictions" ([§4.8](https://opendatacommons.org/licenses/odbl/1-0/)).
- **Charging** is allowed, but because the result stays ODbL, "other people may then redistribute this without payment" ([Legal FAQ §1.9](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)). OSMF cannot grant an alternative licence ([FAQ §1.11](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)).
- **Two duties on [openstreetmap.org/copyright](https://www.openstreetmap.org/copyright)** ("How to credit OpenStreetMap"): credit OpenStreetMap, and "Make clear that the data is available under the Open Database License." When distributing in data form, "please name and link directly to the license(s)".

### 2.2 What the repo does today

- Raw OSM is fetched with `out body`, with no usernames or IDs (`Data/areas/sloans-lake/osm.overpassql`).
- It is committed unmodified with `NOTICE.md` and `manifest.json`.
- The extract is clearly **Substantial**: 3,706 ways (1,427 of them buildings) plus 6,230 tagged nodes. Some of those nodes sit within ways, so the conclusion rests on the ways alone. The [Substantial guideline](https://osmfoundation.org/wiki/License/Community_Guidelines/Substantial_-_Guideline) treats an extraction as insubstantial, provided it is one-off and not repeated, in three cases:
  - fewer than 100 features;
  - more than 100 features if the extraction is non-systematic and based on your own qualitative criteria;
  - the features of an area of up to 1,000 inhabitants.

  A full extract of a city neighbourhood fits none of them.
- The demo app `WorldLab` bundles that folder and the generated package (`Apps/WorldLab/project.yml`). It is a development app, not a public release.
- `WorldView` always overlays the credit. The web renderer's credit is a link to openstreetmap.org/copyright since 2026-10-06 (O2); it was unlinked text before.
- `docs/plan-m1.md` §6 currently says "generated detail is a Produced Work, so attribution only". This document recommends revisiting that for the **package** (§2.3).

### 2.3 Is the world package a Produced Work or a Derivative Database?

The package (`docs/package-format.md`) contains:
- GLB chunk meshes, with a per-vertex `_FEATURE` index into `scene.json`
- `scene.json` feature tables: OSM identities (`way/123`), 16 kept OSM source tags, kinds, and generated choices with their provenance (`osm` vs `profile`)
- `instances.json`, `collision.json` and prototypes
- `world.json`, with an exact WGS84 ENU frame (vertices within 1 cm), source licence and hashes
- palettes, materials, environment and the source profiles

**Arguments that it is a Produced Work:**
- The meshes are a rendering-ready 3D visual work. The definition is open-ended ("such as an image…"), and OSMF says vector images such as SVG are usually Produced Works ([Produced Work guideline](https://osmfoundation.org/wiki/License/Community_Guidelines/Produced_Work_-_Guideline), board-endorsed 2014-06-06).
- The package exists to be drawn, not to supply map data. The guideline's test is intent: is the result "intended for the extraction of the original data, then it is a database"?
- Baking geometry is algorithmic. Trivial Transformations lists reformatting for "Faster access for a game." and algorithmic generalisation as trivial ([guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline)).

**Arguments that it is (or contains) a Derivative Database:**
- `scene.json`, `instances.json` and `collision.json` are literally systematic, individually accessible tables keyed by OSM ID and carrying OSM tags. That is the ODbL definition of a database, and it re-utilises a Substantial part of the Contents in a new database ([§4.4(b)](https://opendatacommons.org/licenses/odbl/1-0/)).
- With the exact frame in `world.json`, footprints, paths and positions convert back to latitude/longitude. In its machine-learning section, OSMF says a Produced Work that is "used to extract, copy, or recreate substantial parts of the OpenStreetMap data" is considered a Derivative Database ([Attribution Guideline: Machine learning models](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Machine_learning_models)). Applying that to a package that merely *could* be used this way is our extrapolation, not OSMF's statement.
- The package is a machine interface that other programs (the three.js renderer, future renderers) read data out of.

**Working conclusion (conservative):**
- Treat the package as a **Derivative Database**: at least `scene.json`, `instances.json`, `collision.json` and `world.json`, and the GLBs while they are paired with them.
- Treat everything **rendered** from it (frames on screen, postcards, video, widgets) as **Produced Works from a Derivative Database**.
- Treat the bundled `osm.json` as the Database itself (an unmodified Substantial extract).
- Stripping IDs and tags would not clearly change the answer, because the geometry stays exact. So don't rely on stripping. Confirm with counsel (Q1).

**Ambiguity to flag:** the Community Guidelines index, a page introduced as listing guidelines endorsed by the OSMF board, lists Trivial Transformations under its "Other guidelines:" subheading ([index](https://osmfoundation.org/wiki/Licence/Community_Guidelines)). But the guideline page itself says "This is at the proposal stage in our process" and shows no endorsement date. Don't build a compliance position on it alone (Q2).

### 2.4 Share-alike obligations: our own apps

1. **On-screen world (Produced Work).** Attribution (O1) plus the §4.6 offer (O9). Two ways to satisfy the offer:
   - (a) If counsel agrees our pipeline is a trivial transformation, point users to the unmodified data.
     - The FAQ says "you can simply refer users back to openstreetmap.org as the data source", but only on the condition "If you haven't made changes to the OSM data" ([§1.7.1](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ)).
     - The Trivial Transformations guideline's examples cover the same case: users must be told clearly where to get the equivalent OSM data, either from you or from OSM or a mirror ([guideline, Examples](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Trivial_Transformations_-_Guideline)).
     - Better still, link a copy of the exact extract we used, since its timestamp and hash are already recorded in `manifest.json`.
   - (b) Otherwise, offer the derivative database itself: the package's data files, under ODbL, as a free download. Offering the database (§4.6(a)) rather than the method (§4.6(b)) means the generator code never has to be published.
2. **Package or extract inside the app bundle.** Users receive a copy, so this is "Convey" and §4.2 / §4.4 apply to the data files. Those files must be ODbL-licensed and carry the notice (O7, O8).
   - Whether App Store packaging or the sandbox counts as a §4.7 "technological measure" is unclear (Q1). A free public download of the same data would probably satisfy §4.7(b) parallel distribution, provided it is at least as accessible to recipients, in practice, as the copy in the app (§4.7(b)(iii)).
3. **Web version.** The browser downloads package files, so a copy is transferred. That is Conveying, not mere "interaction … through a computer network". Same duties as item 2, plus the linked credit (O2).
4. **Shared postcards and video.** Produced Works in other people's hands. Burned-in credit (O4, O5) and the same offer link on the share page.
5. **What becomes ODbL.** If item 1(b) applies, the generated per-building choices in `scene.json` (house type, colours and so on) become ODbL data that anyone may reuse. Code (§2.3(a)) and independent Contents such as our prototype meshes, palettes and shaders (§2.4) are not covered. Splitting the package into an ODbL **data** part and a separately licensed **presentation** part would make this explicit (owner decision D1).

### 2.5 Share-alike obligations: white-label or licensing

- Giving packages to third parties is Publicly Conveying a Derivative Database. The data parts must be under ODbL; we may charge, but we may not add restrictions (§4.4, §4.7, §4.8). Recipients may redistribute them freely (FAQ §1.9).
- What we can sell under our own terms:
  - the engine and generator code (§2.3(a))
  - our own art and presentation files as independent Contents (§2.4). They must stay compatible: §4.4(d) forbids adding Contents incompatible with ODbL to the derivative database. Hence F4/F5.
  - hosting, updates, support and custom work
- Each licensee becomes a publisher of Produced Works. Contracts should flow down attribution (O1, O4–O6) and the §4.6 offer. Under §4.8 we are not responsible for enforcing third parties' compliance, but we must not grant terms that conflict with ODbL.
- Exclusive rights to a city's world data cannot be granted. A lawyer must draft this (Q15).

### 2.6 Attribution by surface

All from the [OSMF Attribution Guideline](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines), adopted 2021-06-25:

- **Text.** "Attribution must be to “OpenStreetMap”." It must also make clear that the data is under ODbL (mandatory). Linking the text "OpenStreetMap" to /copyright is one accepted way to do that. "“© OpenStreetMap contributors” or “© OpenStreetMap” are acceptable". It must be legible, considering font, size, colour, contrast, positioning and how long it is shown; WCAG is recommended.
- **Interactive map / app screen.** A corner, adjacent to the map, or a start-up splash or pop-up.
  - Collapsing is allowed on dismissal, on interaction, or "automatically after five seconds".
  - After collapsing, the user "must still be able to find the licence information", e.g. via an (i) button or About.
  - The safe harbour also says attribution "should not require individuals to interact with the map".
  - Our "always visible" rule exceeds this.
- **3D world as a game or simulation.** The guideline's games section says "attribution can be provided either by a splash screen on application startup", in-view, in credits or in menus, with details somewhere suitable. This could justify a "clean view" without the overlay, but CLAUDE.md requires it to stay visible. Owner decision D2.
- **Shared images and postcards.** Same as interactive maps; one credit per document. Where a hyperlink isn't possible, the print rule applies: "The URL to openstreetmap.org/copyright must be printed out." Exemptions exist for images under 100 features or 10,000 m², and "Small thumbnails/icons do not require attribution." Don't rely on the area exemption for postcards.
- **Widgets.** No explicit rule. The thumbnail exemption may or may not cover them (Q4). Proposed safe default (our idea, not from OSMF): "© OpenStreetMap" visible in the widget, with tap-through to the licence info.
- **Video.** Corner credit while the world is the main content, plus end credits or description with the URL.
- **Web.** Same as interactive maps; the credit must be a link (O2).
- **Data (packages, extracts).** Attribution and the ODbL text or link inside the data, or in a README / notice file.

### 2.7 Data we add

- **Regional profiles and seeds.** Style tables that don't reference OSM features are plausibly an independent database in a Collective Database. One of the Collective guideline's alternative conditions is that the OSM and non-OSM datasets do "not reference each other" ([guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline), endorsed 2016-06-17). The others cover replacing or adding a geometry, data type or property under all-OSM or no-OSM rules. The per-building **choices** in `scene.json` reference OSM IDs, and for roof shape and floors they mix OSM and profile values. The guideline's safe harbour requires a property to use "either all OSM data or no OSM data for that property", so those choices fall outside it. They are part of the derivative database, which is acceptable if we offer them (§2.4 item 5).
- **Measured profile values (2026-10-06).** Profiles now carry aggregate statistics measured from OSM (the chicago-dense-north `typeRules` come from OSM `building:levels`) and from public-domain imagery and lidar (`trees.canopyShare` from NAIP; tree heights from USGS 3DEP). We classify them as aggregate statistics, not extracts of individual OSM records. OSM is credited in the `provenance` of the profile concerned (chicago-dense-north), and the profiles stay separately licensed WorldEngine content. Whether that classification holds is Q32.
- **Building overrides (planned).** Host or user data keyed by OSM ID that replaces a property for some buildings only. Same mixing problem. Horizontal Layers says that if OSM and non-OSM data are used together "for a given Feature Type", then "the share-alike condition would apply regardless" of layering ([Horizontal Layers](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Horizontal_Map_Layers_-_Guideline)).
  - Private on-device use is not public use.
  - **Publicly shared** renders that include overrides could oblige us to offer the override data to recipients, which is a privacy concern (Q6).
- **Overture or other sources merged by OSM ID.** External observation data, so not trivial ("Without reading any other observation data (important!)"). The combined database must be offered under ODbL (O12). `docs/research/data-coverage.md` recommends exactly this kind of merge (Overture buildings as a second footprint source for the North Shore); see V1.

---

## 3. Overture Maps

Source: [Attribution and Licensing](https://docs.overturemaps.org/attribution/) (docs v2.0.0). The page footer says "Last updated on May 15, 2026", but many per-source entries carry later "Accessed: 2026-09-…" dates, so the source list is newer than the footer suggests.

Cross-reference: `docs/research/data-coverage.md` recommends Overture buildings as a second footprint source for the North Shore. Its audit finds Esri Community Maps extras (CC BY 4.0) in 7 cells, so per-source CC BY credit applies wherever those are used (V1).

| Theme | Licence (as stated by Overture) | Attribution listed |
|---|---|---|
| Addresses | Varies by source; all permissive, some with special terms | Per-country/source list on the page |
| Base | ODbL | © OpenStreetMap contributors; Daylight; ESA WorldCover (CC BY 4.0); ETOPO1 (PDDL); GLOBathy (CC0, "assumed") |
| **Buildings** | **ODbL** | © OpenStreetMap contributors; Esri Community Maps contributors (CC BY 4.0); Microsoft Global ML Building Footprints (ODbL); Google Open Buildings (CC BY 4.0); USGS 3DEP; Shi et al. East Asia buildings (CC BY 4.0); IGN Spain BTN 2024 (CC BY 4.0) |
| Divisions | ODbL | © OpenStreetMap contributors; geoBoundaries, Esri, LINZ (CC BY 4.0) |
| **Places** | No single "License for theme" line on the attribution page. The guide says CDLA Permissive 2.0 and Apache 2.0. | Meta, Microsoft, PinMeTo, Krick, RenderSEO, DAC, BrightQuery (CDLA-Permissive-2.0); Foursquare (Apache 2.0, NOTICE.txt); AllThePlaces (CC0) |
| Transportation | ODbL | © OpenStreetMap contributors; TomTom |

- **Buildings inherit ODbL share-alike.** The buildings guide says "the buildings theme is published under the ODbL license" because it includes OpenStreetMap ([guide](https://docs.overturemaps.org/guides/buildings/#sources-and-licensing)). Using it brings the full §2 duties, plus the CC BY 4.0 source credits.
- **Places carry no share-alike.** The guide says "It contains no OpenStreetMap data" ([guide](https://docs.overturemaps.org/guides/places/)). Its source table lists CDLA-Permissive-2.0, Apache-2.0 (Foursquare) and CC0-1.0 (AllThePlaces). It warns that joining places to OSM "may need to carry the Open Database License (ODbL)" ([Sources and licensing](https://docs.overturemaps.org/guides/places/#sources-and-licensing)).
  - CDLA-Permissive-2.0 requires that a recipient sharing the data "makes available the text of this agreement with the shared Data" (§2.1).
  - It puts no restrictions on *Results* (§3.1) ([cdla.dev](https://cdla.dev/permissive-2-0/)).
- **Attribution text.**
  - For its OSM-based Explore tool, Overture uses "© OpenStreetMap contributors, Overture Maps Foundation."
  - A citation "Overture Maps Foundation, overturemaps.org" is described as optional for publications.
  - Overture publishes no single mandatory string for apps. Suggested: that Explore line, plus the per-source credits in the credits screen and package notice (Q20).

---

## 4. Apple WeatherKit

Sources:
- [WeatherKit page: Attribution requirements](https://developer.apple.com/weatherkit/#attribution-requirements)
- [Apple Developer Program License Agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) (DPLA; agreement and Schedule 1 last updated **2026-08-18**). WeatherKit sits in **§3.3.8(B)** and **Attachment 8**; call quotas are in **Attachment 9**.
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (last updated 2026-06-08)

Apple's documentation pages are JavaScript-rendered. They were read through Apple's documentation JSON, which carries the same text. Everything below is paraphrased.

### 4.1 Attribution

- **Original data shown.** Any app, web app or website that displays Apple weather data (other than alerts or value-added products) must clearly display the Apple Weather trademark (Apple logo + "Weather") and the legal link to other data sources (WeatherKit page).
  - App Review 5.2.5 is titled "Apple Products". Only its last sentence concerns weather: apps that display Apple Weather data should follow the attribution requirements in the WeatherKit documentation.
  - DPLA Att. 8 §1.4 requires display to comply with all attribution requirements.
- **Value-added services or products.** Data derived from Apple weather data and transformed so that nobody can recover the original data. Credit the source to Apple Weather, with a notice that Apple's data was modified (WeatherKit page; the same concept is a defined term in DPLA Att. 8 §1.2, "Value-Added Services or Products").
  - Our nine-label weather states rendered as rain, snow or fog are plausibly value-added.
  - A weather strip showing temperature or condition text is original data and needs the full mark plus legal link.
- **Assets.**
  - `WeatherAttribution` provides `combinedMarkLightURL` and `combinedMarkDarkURL` (combined Apple Weather mark), `squareMarkURL`, `legalPageURL` (legal attribution page) and `serviceName`.
  - `legalAttributionText` is for apps that cannot show the legal page in a Safari view ([doc](https://developer.apple.com/documentation/weatherkit/weatherattribution)).
  - REST: `GET /attribution/{language}` returns logo URLs at @1x–@3x (light, dark and square) plus `serviceName`. The URLs are partial: append each to https://weatherkit.apple.com to get the image ([doc](https://developer.apple.com/documentation/weatherkitrestapi/attribution)). `Metadata.attributionURL` is the legal attribution URL ([doc](https://developer.apple.com/documentation/weatherkitrestapi/metadata)).
  - The data-source page lists the agencies behind the data ([data sources](https://developer.apple.com/weatherkit/data-source-attribution/)).
- **Alerts.** The WeatherKit page requires all three: an embedded link to Apple's alert details page, the full name of the issuing agency, and no modification. DPLA Att. 8 §1.4 covers only the no-modification rule.
- **By surface:**
  - App screen: mark + legal link next to weather info. The proposal placement is in `docs/proposals/weather-v1` §10 and `experience-v1` §5.
  - Shared images and video: Apple says nothing specific. Proposed: burned-in mark + modified notice, with the legal link on the share page (W3, Q8).
  - Widgets: same gap. Proposed (unsourced): the legal link lives behind the widget's tap target.
  - Web: same rules. The WeatherKit page names apps, web apps and websites.

### 4.2 Storage and caching

- **DPLA Att. 8 §1.5:** no use that enables bulk downloads or feeds, or that extracts or scrapes the data. Apple weather data may not be used or offered as part of any secondary or derived database.
- **DPLA Att. 8 §1.6:** unless the Documentation expressly permits otherwise, no caching, pre-fetching or storing except temporarily and on a limited basis, solely to improve WeatherKit performance in the app.
  - No document was found that permits more.
  - The data carries an expiry (`WeatherMetadata.expirationDate`; REST `Metadata.expireTime`, "no longer valid"). That is a ceiling to respect, not a permission.
- **Repo:**
  - `TemporaryWeatherCache` is memory only: 30 min fresh (15 while changing), up to 2 h stale only on fetch failure, then discarded.
  - Exported packages currently carry synthetic "clear" weather, not Apple data.
  - Keep it that way: don't persist Apple-derived states in `environment.json`, recaps or postcard metadata without counsel (Q9). `docs/proposals/weather-v1` §9 already reached the same reading.

### 4.3 Fees, purpose, EULA

- **Att. 8 §1.2:**
  - No charging end users for Apple weather data in its original form; charging for value-added products, including apps, is allowed.
  - No sublicensing of the API or the original data.
  - Our end-user licence terms must not permit end users or other third parties to reverse engineer the WeatherKit APIs or the weather data, for any purpose.
- **DPLA §2.8:** no fees to end users solely for access to or use of Apple Services through our apps or Corresponding Products.
- **Att. 8 §1.3:** apps using WeatherKit may not be designed or marketed for emergency or life-saving purposes.
- **Att. 8 §2.2:** apps that use WeatherKit for real-time weather guidance must include a set risk notice in their EULA. Whether a live weather visualization counts as guidance is unclear (Q10).
- **Att. 8 §3.2:** Apple may limit, suspend or revoke access for violations.

### 4.4 Third parties and white-label

- **DPLA §2.8 (use of Apple Services):**
  - Access only through Apple's mechanisms.
  - No sharing of access mechanisms (keys) with third parties, except Service Providers under §2.9.
  - Use only as needed for *your* Covered Products (your Applications etc.) or Corresponding Products (your website, web application, or other version of your software application; §1.2 definitions).
  - No building a substitute service from the Apple Services.
- **DPLA §2.6:** no selling, redistributing or sublicensing any Services, or enabling others to.
- **"Application"** (§1.2) means software distributed under *your own* trademark or brand.
- **Conclusion.** A licensee's branded app is not our Application. It needs **its own** Apple Developer Program membership and WeatherKit access.
  - We may not proxy our quota or keys to licensees.
  - Feeding licensees an Apple-derived environment feed is at least doubtful, given §1.2 (value-added products are for "Your end users"), §1.5 (no secondary/derived database) and §2.8. See Q16.
  - Acting as a licensee's **Service Provider** using *their* keys may be possible under §2.9 with a written agreement.
- **Engine design already fits.** The engine never calls WeatherKit and takes a host `WeatherProvider`.
- **App Review 4.2.6:** apps built from a commercialised template must be submitted by the content provider itself, or delivered as one aggregated "picker" app. **App Review 5.2.1** adds that apps should be submitted by the person or entity that owns or has licensed the relevant IP. Both matter for any white-label app programme (Q17).
- **Call quotas** (WeatherKit page; DPLA Att. 9): 500,000 calls/month included per membership; paid tiers start at 1 million calls for US$49.99/month.

### 4.5 Web version (REST)

- The REST API is Apple's route for web apps and other platforms such as Android ([REST API overview](https://developer.apple.com/documentation/weatherkitrestapi/)). Attribution rules are the same.
- **Ambiguity (Q11):** DPLA §2.8 says Apple Services are to be accessed only for use on Apple-branded products. That seems to conflict with Apple's own statement that REST serves other platforms. Points on the other side:
  - A Corresponding Product includes "other version[s]" of our software application, not only websites (§1.2).
  - §2.8 allows use "as permitted by Apple in writing, including in the Documentation", and the WeatherKit REST documentation explicitly targets web apps and Android.
  - Attachment 8 expressly applies to WeatherKit use in "Your Application or Corresponding Product".

  On balance, web use looks intended, but the literal wording should be cleared.

---

## 5. Star catalog: HYG (CC BY-SA 4.0), replaced by the Yale Bright Star Catalogue

**Update 2026-10-06 (owner decision 6d):** the star file is now derived from the Yale Bright Star Catalogue, 5th rev. ed., as distributed by NASA HEASARC (public domain in practice; see rows H1-H3 and `Sources/WorldEnvironment/Catalog/STARS-NOTICE.md`). The HYG analysis below is kept for the record; its CC BY-SA obligations no longer apply.

- **Licence verified.** The live repository is now [codeberg.org/astronexus/hyg](https://codeberg.org/astronexus/hyg). The GitHub repo's README now points there and holds the archive our notice cites ([GitHub](https://github.com/astronexus/HYG-Database)).
  - Codeberg README: "Versions since v4.0 are licensed as above (CC-BY-SA 4.0)." Earlier versions used CC BY-SA 2.5.
  - The `LICENSE` file is CC BY-SA 4.0 in both repositories.
  - Current version is v4.4; we use v4.1, which is covered.
  - Optional: also cite the Codeberg URL in `STARS-NOTICE.md`.
- **Does share-alike cover the derived JSON?** Likely yes.
  - We selected, merged and transformed the data. Under CC BY-SA 4.0 §4(b), putting a substantial portion of a database's contents into a database in which *we* hold sui generis database rights makes that database *Adapted Material* for share-alike purposes. It bites only if HYG's licensed rights include sui generis rights and we hold such rights in our file.
  - Copyright in factual star positions is thin, and whether any right applies to a 256-star subset is a jurisdiction question (Q12).
  - We already license the file CC BY-SA 4.0, which is the safe answer either way.
- **Rendered sky images.** A rendering of positions isn't a database, and isn't obviously an adaptation under copyright law. CC's FAQ ties "adaptation" to applicable copyright law ([FAQ](https://creativecommons.org/faq/#when-is-my-use-considered-an-adaptation)). Likely not Adapted Material. Credit is cheap, so credit anyway.
- **The app itself.** A collection. Including CC material in a collection "does not change the license applicable to the original material" ([FAQ](https://creativecommons.org/faq/#if-i-create-a-collection-that-includes-a-work-offered-under-a-cc-license-which-licenses-may-i-choose-for-the-collection)), so share-alike does not extend to our code or assets.
- **Attribution required** (CC BY-SA 4.0 §3(a)(1)): creator, any copyright notice, a licence notice and URI, a link to the source, and a note of our modifications. Also, if supplied with the material: a notice referring to the warranty disclaimer, and any indication of previous modifications, which must be retained.
  - Done in `STARS-NOTICE.md` and the JSON header. The repo's credit string is "Stars: HYG Database v4.1, David Nash / Astronomy Nexus, CC BY-SA 4.0 (modified)."
  - §3(a)(2) allows any reasonable manner for the medium. A credits screen is reasonable for the app. Not shown anywhere yet (H2).
- **Restriction rule.** §3(b)(3): "You may not offer or impose any additional or different terms" or technical measures on Adapted Material. Keep the star file outside restrictive app or white-label terms (H3, Q12).
- **Conflict with Fab.** Fab EULA §6(a) names CC BY-SA as a licence that Fab content may not be combined with (§6, F5, Q13).

---

## 6. Fab Standard License

Source: [Fab EULA](https://www.fab.com/eula), last updated **2024-10-01**.
- Scripted fetches get a bot check (HTTP 403). The page was read in a normal browser session; no challenge was completed.
- The paragraph labels "4(b)" and "6(b)" are inferred from position; the page renders those two paragraphs without letters.
- Supporting page: [Epic: Licenses and Pricing in Fab](https://dev.epicgames.com/documentation/en-us/fab/licenses-and-pricing-in-fab).

Everything below is paraphrased.

- **Any engine.** The page's (non-binding) summary says the assets may be used with any compatible tool, not only Unreal Engine.
  - The binding grant (§3(a)) is a non-exclusive, non-transferable licence to *privately* use, reproduce, display, perform and modify the content, with no engine limit. Sharing the content, or Projects made with it, is governed separately by §4 and §5.
  - Source assets come in Unreal format and possibly others listed per product (§2(d)). Check each listing for FBX / glTF / USD.
- **Embedded in apps.** A Project that includes the content as a dependency may be distributed to end users (§4(c)), but:
  - only in object code;
  - end users may use the content only as part of the Project;
  - we must restrict them from extracting it.
  - Distributors and publishers may be used. "Distribute" includes making a Project's functionality available on a network (§4(a)).
  - Implications: an anti-extraction clause in our EULA. For the **web**, plain GLB downloads make extraction trivial, so counsel's view is needed (Q14).
- **Rendered output.** Rendered video and images made with the content may be distributed freely (§4(b), "Distributing Linear Media Projects"). Postcards and video are fine.
- **Standalone.** No distributing the content on a standalone basis, except to collaborators building the Project with us, who must delete it afterwards (§5(a)). No selling, renting or transferring it standalone; a Project must add value beyond the content (§6(b)(ii)).
- **Third parties.** No allowing any third party to incorporate the content into their own products, and no world/level-editing tools or templates that let works be exported (§6(b)(iii)). So:
  - no Fab content in world packages, the ODbL data download or white-label deliverables;
  - each licensee buys its own licence. We could integrate assets the licensee itself bought, as their contractor (§5(a)); confirm with counsel (Q18).
- **Incompatible licences.** We may not "combine, Distribute, or otherwise use" the content with code or content under a licence that would directly or indirectly require any of the content to be governed by other terms. Named examples: GPL, LGPL (except dynamic linking) and **CC BY-SA** (§6(a)). Under that test the open question is mere aggregation: a CC BY-SA file in the same app does not obviously place the Fab assets under CC BY-SA, but the named example makes the reading uncertain.
  - The ODbL is not named. However, ODbL §4.4(d) forbids adding incompatible Contents to an ODbL derivative database, which is another reason to keep Fab content out of packages.
  - Whether shipping Fab meshes in the **same app** as the CC BY-SA star file counts as an act to "combine" them needs counsel (Q13). If counsel is unsure, replace HYG with a public-domain catalog (owner decision D4). (Moot for the stars since 2026-10-06: the star file is now public domain.)
- **Other restrictions:** no reverse engineering or deriving data from the content (§6(b)(i)); keep its proprietary notices (§6(b)(vi)); don't use "NoAI" content for generative AI (§6(b)(vii), §16(l)). Code plugins are licensed per seat (§2(e)).
- **Tiers** (§2(a)):
  - The Personal tier (and Personal – Reference Only) applies only if, at purchase, you **together with any controlling entity and entities under common control** made **no more than US$100,000 gross revenue** from commercial activity **in the digital content industry** over the **last 12 months**.
  - Revenue **includes advances received and other funds raised**.
  - Otherwise, Professional.
  - Buying an ineligible tier means paying Epic the difference on request.
  - The summary says both tiers grant the same rights, and no upgrade is needed if the threshold is crossed after purchase.
  - Epic's doc phrases the threshold more loosely ("gross revenue from commercial activity"); the EULA wording above is the binding one.
- **Version lock.** Content stays under the terms in force when it was acquired (§7(a)). Keep a record of the EULA date with each purchase.
- **Credit.** Not required by the Standard License (summary). Fab assets offered under CC BY instead follow that licence's attribution rule.

---

## 7. Other notices found in passing

- **Earcut port:** ISC licence text kept in `Sources/WorldMesh/Earcut.swift`. The licence requires the notice in all copies. *2026-10-06: the notice is now in the in-app acknowledgements (`credits.json` `earcut`, shown by `WorldCreditsView`).*
- **three.js 0.180.0:** MIT per `web/package-lock.json`. Ship its licence notice with `web/dist` and the app acknowledgements. *2026-10-06: the acknowledgements part is done (`credits.json` `threejs`); the notice inside `web/dist` is still to do (X1).*
- **esbuild:** dev-only, not distributed.
- **Public Overpass servers** remain a developer tool only (`docs/plan-m1.md`). This is a usage-policy matter, not licensing.
- **Copernicus DEM and other plan sources** (`docs/plan-m1.md` §6, §10) were not researched here.

---

## 8. Blockers and risks, ranked

1. **Package characterization drives everything (High; both scenarios).** If the package is a Derivative Database (likely), every channel that hands it over must ship it under ODbL with no extra restrictions: app bundle, web, white-label. Every product showing it needs the §4.6 offer. Not a launch blocker for our own apps once O8–O10 and O13 are done. It **is** a business-model constraint for white-label: no exclusive or proprietary data licences. (§2.3–2.5; Q1, Q2, Q3, Q15)
2. **Fab assets cannot travel (High; white-label and web).** Standalone and third-party-incorporation bans (§5(a), §6(b)(iii)), anti-extraction duty (§4(c)), and possible conflicts with CC BY-SA and ODbL content (§6(a)). Resolve before buying. (F2, F4, F5; Q13, Q14, Q18)
3. **WeatherKit is per-developer and non-archivable (High for white-label, Medium for own apps).** No key sharing or sublicensing (§2.6, §2.8, Att. 8 §1.2). Temporary caching only (Att. 8 §1.6). No derived databases (§1.5). Licensees need their own access. Saved recaps, postcards and packages must not become a weather archive. (W5, W7; Q9, Q16)
4. **Attribution on exported surfaces is missing (Medium; own apps).** OSM and Apple Weather credits (and the star courtesy credit) are not burned into images, video or widgets. Apple publishes no rule for non-interactive outputs. (O4–O6, W3, H2; Q4, Q8)
5. **Web specifics (Medium).** Unlinked OSM credit (O2; 2026-10-06: resolved, the web credit is now a link); package download is Conveying; Fab extraction; the DPLA §2.8 "Apple-branded products" wording against REST on other platforms. (Q11, Q14)
6. **User overrides in shared renders (Medium, when built).** May trigger a §4.6 offer of user data. Keep overrides out of public outputs until counsel answers. (O11; Q6)
7. **CC BY-SA in App Store and white-label terms (Low).** §3(b)(3); credit UI missing. (H2, H3; Q12) *(2026-10-06: resolved. HYG was replaced by the public-domain Yale Bright Star Catalogue, so no CC BY-SA material is bundled; the credit is a courtesy shown in `WorldCreditsView`.)*
8. **Overture adoption (Low, future).** Buildings bring ODbL plus CC BY 4.0 credits; merging heights makes the combination a derivative database. (V1, O12; Q20) *(2026-10-06: resolved for gap-filling. V1 and O12 are done: Overture fills only missing footprints as separate features, the manifest and notice carry the credits. Merging Overture heights onto OSM features would need the O12 gate again; Q20 stands.)*
9. **Code notices (Low).** Acknowledgements list missing. (X1) *(2026-10-06: partly resolved. `credits.json` and `WorldCreditsView` now carry the Earcut and three.js notices; the three.js notice inside `web/dist` is still to do.)*

---

## 9. Questions for a lawyer

**Own apps**

1. Is the world package (GLB meshes with a per-vertex feature index, plus `scene.json`, `instances.json` and `collision.json` keyed by OSM IDs and tags, plus an exact WGS84 frame) a Derivative Database or a Produced Work under ODbL? If a Derivative Database, does shipping it inside an iOS app bundle "Publicly Convey" it? Is App Store packaging or the sandbox a §4.7 technological measure that requires a parallel unrestricted copy?
2. Our generator adds regional style profiles and seeded choices, which are not observation data. Is that a "trivial transformation", given the OSMF page is marked "proposal stage" while the index lists it as endorsed? If so, can the §4.6 offer be satisfied by pointing to the unmodified extract?
3. Can the §4.6 offer be a link in an About/credits screen to a free download of only the package's data files, excluding meshes, materials and assets? Must every shared postcard or video carry the offer, or is a share page enough?
4. Does the OSMF thumbnail exemption cover home-screen widgets? If not, what is the minimum legible credit for the smallest widget size?
5. For an always-visible overlay in a 3D world that behaves like a game or simulation, may a clean view hide the credit under the games/simulations safe harbour (splash or credits), despite our stricter internal rule?
6. If users' per-building overrides (colours, roof shapes) appear in postcards they share publicly, is the result a Produced Work from a Derivative Database that obliges us to offer the override data to recipients? How should this be designed so private user data is never subject to an offer?
7. WeatherKit: are rendered weather states (nine labels plus intensity driving rain, snow and fog visuals) "Value-Added Services or Products" (DPLA Att. 8 §1.2)? If the same screen also shows temperature or condition text, does the full mark plus legal link apply to that screen only?
8. WeatherKit attribution on non-interactive outputs (shared images, video, widgets): is a burned-in Apple Weather mark plus modified-data notice, with the legal link on the share page or in the app, sufficient? Should we ask Apple Developer Support in writing?
9. Att. 8 §1.6: does keeping a rendered postcard (pixels that reflect weather), or a resolved weather label in a saved recap, count as caching or storing Apple Weather Data? What retention, if any, is permitted for derived labels used to replay a past moment?
10. Att. 8 §2.2: does a live weather visualization or strip count as "real-time weather guidance" requiring the EULA notice? Att. 8 §1.2: in a paid or subscription app, does showing live temperature count as charging for data "in its original form"?
11. DPLA §2.8 says Apple Services are for use on Apple-branded products, but Apple documents the WeatherKit REST API for websites and Android. May our web version show WeatherKit data to visitors on non-Apple devices?
12. HYG: does distributing the CC BY-SA derived star file inside an App Store app (Apple's standard EULA, FairPlay) conflict with CC BY-SA §3(b)(3)? Is a 256-star factual subset protected at all (US copyright; EU sui generis rights for a non-EU maker)? **Resolved 2026-10-06:** HYG was replaced by a public-domain catalogue; this no longer applies.
13. Fab §6(a): does shipping Fab meshes in the same app as the CC BY-SA star file, or rendering Fab props from an ODbL-licensed package, fall within the bar on attempts to "combine" Fab content with such licences? Should we replace HYG with a public-domain catalog before buying? (The CC BY-SA part is resolved: the star file is now public domain. The ODbL-package part stands.)
14. Fab §4(c) on the web: if Fab-derived meshes are delivered to browsers, what satisfies the duty to "restrict end users from extracting" the content (terms, packing, encryption)? Is web use advisable at all?

**White-label / licensing**

15. Given ODbL §4.4, §4.7 and §4.8, what may a licence to third parties restrict? Which parts can stay proprietary: code (§2.3(a)), our prototype meshes, palettes and shaders as independent Contents (§2.4), regional profiles as a Collective Database? Please draft flow-down clauses for attribution and the §4.6 offer.
16. WeatherKit: confirm each licensee needs its own Apple Developer Program membership and WeatherKit access. Can we operate a weather proxy as the licensee's §2.9 Service Provider using *their* keys? Can we sell licensees a hosted, Apple-derived environment feed, or is that a "secondary or derived database" (Att. 8 §1.5) or a sublicence (§1.2, §2.6)?
17. App Review 4.2.6: if licensees ship branded apps on our engine, must each be submitted from the licensee's own developer account? Does an SDK licence count as a "template or app generation service"?
18. Fab: confirm white-label deliverables must exclude Fab content (§6(b)(iii)). Can we integrate assets a licensee bought under *their* licence, as their contractor or collaborator (§5(a))?
19. Fab tier: does our entity (with any controlling or affiliated entities, counting funds raised) qualify for Personal under §2(a)? This may be an accountant's question.
20. Overture: if we merge Overture building heights into OSM features by ID, is the combination ODbL (yes, per Overture)? Exactly which attribution strings and placements satisfy the CC BY 4.0 sources (Esri, Google Open Buildings and others) on screen, in exports and in packages?

**Live transit and aircraft feeds** (details in `docs/research/live-feeds.md`)

21. CTA's agreement allows use for the sole purpose of assisting riders or promoting public transportation. Does an ambient live-vehicle layer in a 3D world, including postcards and video that show it, fall within that, or do we need CTA's express permission? Which agreement text binds, the current terms page or the different, probably older (both undated) copy on the key-application page, and is our relay "your application"?
22. Metra's licence (unverified (site blocks automated access; confirm in a normal browser)) says the licensee must not modify or delete Data and must redistribute through its own host. Does filtering a feed by area, re-encoding it compactly, or discarding snapshots after minutes breach that? Does the same licence let one relay serve many users?
23. Pace's data page says the data is shared for non commercial use, but the licence text itself does not say so. Is the intro binding on a paid or ad-supported app? Does public availability of Pace's undocumented GTFS-RT URLs, which sit on the same host as Pace's own Bus Tracker, imply any permission? (Our working answer is no and not to use them.)
24. Where a licence is silent on commercial use (CTA's agreement, RTD, Metra), is silence permission, or do we need written confirmation? Are the indemnities, liability caps and forums acceptable (CTA: indemnify and hold harmless, ten-dollar cap, Cook County courts; RTD: indemnity to the extent permitted by law, Denver courts), and who may accept an online licence for the company?
25. adsb.lol data is ODbL. Is our relay's normalised snapshot a Derivative Database, and do phones that receive transient copies of positions count as "Convey"? Does showing aircraft in the same scene as OpenStreetMap-derived data create any combined-database duty beyond the existing ODbL handling? Is the operator's "contact me for production" request a condition or only a courtesy?
26. FlightAware Standard: is a 3D scene of overhead aircraft a "commercial aircraft situational display"? Does serving derived, non-raw positions from our relay to many users of our app meet the "embedded, not via the AeroAPI API" wording? Does normalising count as a Derivative Work (allowed) or as modifying AeroAPI Data (barred without written permission)? Does B2C cover a free or ad-supported app, and does licensing the engine to other app makers make us a B2B (Premium) user? May FlightAware give written permission for a community-feed fallback?
    - Related, ADS-B Exchange Enterprise: JETNET's section 2.d lets data be presented for third-party end users only if each is a direct JETNET subscriber, and any reseller or pass-through needs a separate signed agreement. Is a relay serving our app users possible under such an agreement at all?
27. Flightradar24's terms (unverified (site blocks automated access; confirm in a normal browser)) bar redistributing raw data and require credit. May our relay serve normalised positions to app users? Does the 30-day storage limit apply to an in-memory snapshot?
28. LADD and PIA: the FAA binds SWIM-feed vendors to filter LADD aircraft. Does any legal duty to filter, or any privacy law (including for EU users), apply to us when we take community or commercial feeds? Is dropping flagged aircraft and never sending registration or ICAO address enough, and may we show a callsign at all?
29. Attribution, non-affiliation statements and last-updated times (Metra) on non-interactive outputs (postcards, video, widgets): is a burned-in credit enough, and does sharing an image of live vehicles count as redistributing the data beyond the licence?
30. Retention and privacy: does a latest-snapshot-only relay satisfy CTA's delete-on-termination and the 30-day limits, given Metra's "must not delete" wording? Is a tile request, which reveals location to about 1.8 km, personal data, and what logging is acceptable?
31. Transit licences are non-assignable and non-transferable (CTA). May we bake agency static data (GTFS shapes) into distributed world packages, and may one relay serve several white-label apps under one key, or must each licensee hold its own key and accept each agreement?

**National transit feeds** (added 2026-10-06; from `docs/research-gpt/transit-feeds-top20.csv`, eight rows spot-checked in `docs/data-sources/metro-transit.csv`; questions only, nothing decided)

33. "No modification" and "no augmenting" (MTA; LA Metro, which also bars redistributing without authorization): is drawing vehicles from a feed inside a 3D world, simplified or snapped to our geometry, a modification or augmentation of the data, and does a filtered subset count (MTA allows subsets)?
34. Indemnities (LA Metro, WMATA, King County Metro) and "as is" terms: what exposure do we take on for showing live positions in a consumer app, and does it change for white-label licensees?
35. Relays and APIs: MTA requires serving from our own server; WMATA needs prior approval to build any API that exposes its data and written approval for third-party sharing. Is our relay, serving our own apps (and later licensees), an "API" or "third-party sharing" under those terms?
36. Ambiguous commercial terms: SEPTA bars commercial use of its trademarks and copyrighted materials but is silent on data; BART is silent on commercial use and revocable without notice; SEPTA and WMATA reserve future fees. Is commercial use of the data permitted, and how should we plan for revocation or fees?
37. Swiftly-hosted feeds (LA Metro, Miami-Dade, MTA Maryland): Swiftly's agreement restricts content transfer and resale and incremental charges. Do its terms or the agency's terms govern, and may a paid app or paid tier show them?
38. Unread terms: Metra's developer pages returned 403 and MBTA's MassDOT licence PDF was not reviewed. Both must be obtained and read before use.

**Live aircraft sources** (added 2026-10-06; `docs/research-gpt/live-aircraft-research/`, spot-check in `docs/data-sources/live-aircraft-checks.md`; questions only, nothing decided)

39. adsb.lol (ODbL, free): is a live 3D scene built from its positions a Produced Work, and are our relay's cached tracks a Derivative Database that must be offered under ODbL? What attribution satisfies it on screen and in exported images, and what does its indemnity clause expose us to? (See also Q25.)
40. ADS-B Exchange: its acceptable-use policy bans software-as-a-service use and unauthorized distribution. Would an Enterprise agreement expressly permit showing positions to all users of our consumer apps, and is the $10 Community API (labelled non-commercial) usable at all, even in development builds we distribute?
41. FAA SWIM: what do the per-service data agreement and the LADD/PIA filtering duties require of a consumer app (including any history we keep), and is redistribution to app users allowed? The agreement could not be read during the check.
42. OpenSky: the research row says for-profit use, including testing, needs a written licence; the terms page was blocked during the check. Confirm before any use, including prototypes.
43. FlightAware AeroAPI Standard ($100/month minimum, "Business and B2C"): does it allow a live map-style display of overhead aircraft to app users, and may our relay fan one feed out to many users? (See also Q26.)

**Measured profile values** (added 2026-10-06)

32. Our regional profiles carry aggregate weights measured from OSM (for example the chicago-dense-north `typeRules`, derived from `building:levels` on 1,756 principal houses), and are licensed separately from the ODbL data part. Is such a profile a Produced Work, an insubstantial extraction, or part of the Derivative Database (and so ODbL)?

---

## 10. Decisions for the owner

*2026-10-06: D1 is settled by 6a (the data part is ODbL, with a notice in every package that separates the data files from our own content; a physical package split was not decided), D2 by 6c (always visible), D3 by 6b (engine-provided credits), D5 by 6e and D7 by 6f; see §13. D4 is decided and done (the catalogue was replaced). D6 is not covered by these decisions.*

- **D1 – Package split.** Accept that the package's data files are ODbL and offered publicly? Split the package into an ODbL *data* part and a separately licensed *presentation* part (meshes, materials, palettes, profiles)? This would change `docs/package-format.md` and the exporter: a design decision to approve before code.
- **D2 – Attribution visibility.** Keep the OSM credit always visible (the CLAUDE.md rule, stricter than OSMF), or allow a collapse after 5 s or a games-style credit in a "clean view"?
- **D3 – Credits screen ownership.** Should the engine provide a generic credits/licence-notices component (like `WorldAttributionView`, fed with host-supplied weather attribution), or leave the screen to hosts? This is a design decision not covered by the plan.
- **D4 – Star catalog.** Keep HYG (CC BY-SA) or switch to a public-domain catalog to remove the Fab §6(a) and CC §3(b)(3) questions? **Decided 2026-10-06:** switch to the Yale Bright Star Catalogue (done).
- **D5 – Fab policy.** Buy Fab assets only for our own native apps, never in packages or white-label deliverables, possibly never on the web? Choose the tier (Personal vs Professional) per §2(a).
- **D6 – Weather for licensees.** White-label licensees bring their own weather provider and WeatherKit access; we never share keys or Apple-derived feeds.
- **D7 – Quick fixes.** Approve these small fixes: link the web credit (O2); add a licence notice file and ODbL URI to the package exporter (O8); burn credits into exported images (O4).

---

## 11. Sources (accessed 2026-10-05, except the rows and sections updated 2026-10-06: H1–H3, N1/N2, V1/O12, the live-feed block, the aerial and lidar groups and §13)

**OpenStreetMap / ODbL**
- Open Data Commons, *Open Database License 1.0*: https://opendatacommons.org/licenses/odbl/1-0/
- OpenStreetMap, *Copyright and License*: https://www.openstreetmap.org/copyright
- OSMF, *Licence and Legal FAQ* (§1.3–1.12, §5–7): https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ
- OSMF, *Community Guidelines* index: https://osmfoundation.org/wiki/Licence/Community_Guidelines
- OSMF, *Produced Work – Guideline* (endorsed 2014-06-06): https://osmfoundation.org/wiki/License/Community_Guidelines/Produced_Work_-_Guideline
- OSMF, *Substantial – Guideline* (endorsed 2014-06-06): https://osmfoundation.org/wiki/License/Community_Guidelines/Substantial_-_Guideline
- OSMF, *Collective Database Guideline* (endorsed 2016-06-17): https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline
- OSMF, *Horizontal Map Layers – Guideline* (endorsed 2014-06-06): https://osmfoundation.org/wiki/License/Community_Guidelines/Horizontal_Map_Layers_-_Guideline
- OSMF, *Trivial Transformations – Guideline* (page marked "proposal stage"): https://osmfoundation.org/wiki/License/Community_Guidelines/Trivial_Transformations_-_Guideline
- OSMF, *Regional Cuts – Guideline*: https://osmfoundation.org/wiki/Licence/Community_Guidelines/Regional_Cuts_-_Guideline
- OSMF, *Attribution Guideline* (adopted 2021-06-25): https://osmfoundation.org/wiki/Licence/Attribution_Guidelines
- OSMF wiki text is CC BY-SA 2.0 (per the page footers).

**Overture Maps**
- *Attribution and Licensing* (docs v2.0.0; footer "Last updated on May 15, 2026", per-source "Accessed" dates up to 2026-09): https://docs.overturemaps.org/attribution/
- *Buildings guide*: https://docs.overturemaps.org/guides/buildings/
- *Places guide*: https://docs.overturemaps.org/guides/places/
- *Community Data License Agreement – Permissive 2.0*: https://cdla.dev/permissive-2-0/

**Apple WeatherKit**
- *WeatherKit* (attribution requirements, pricing): https://developer.apple.com/weatherkit/
- *WeatherKit data sources*: https://developer.apple.com/weatherkit/data-source-attribution/
- *WeatherAttribution*: https://developer.apple.com/documentation/weatherkit/weatherattribution
- *WeatherMetadata*: https://developer.apple.com/documentation/weatherkit/weathermetadata
- *WeatherKit REST API*: https://developer.apple.com/documentation/weatherkitrestapi/
- REST *Attribution*: https://developer.apple.com/documentation/weatherkitrestapi/attribution
- REST *GET /attribution/{language}*: https://developer.apple.com/documentation/weatherkitrestapi/get-attribution-_language_
- REST *Metadata*: https://developer.apple.com/documentation/weatherkitrestapi/metadata
- The documentation pages above were read via Apple's documentation JSON.
- *Apple Developer Program License Agreement* (last updated 2026-08-18; §1.2, §2.6, §2.8, §2.9, §3.3.8(B), Attachments 8 and 9): https://developer.apple.com/support/terms/apple-developer-program-license-agreement/
- *App Store Review Guidelines* (last updated 2026-06-08; 4.2.6, 5.2.1, 5.2.5): https://developer.apple.com/app-store/review/guidelines/

**Star catalogue** (accessed 2026-10-06; sources cited by rows H1 and H2)
- NASA HEASARC, *Data policy*: https://heasarc.gsfc.nasa.gov/docs/heasarc/data_policy.html
- data.gov record, *Bright Star Catalog*: https://catalog.data.gov/dataset/bright-star-catalog
- HEASARC, *BSC5P* (Yale Bright Star Catalog, 5th rev. ed.): https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html
- IAU Catalog of Star Names (IAU-CSN): https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt

**HYG / Creative Commons** (kept for the record; HYG is replaced)
- HYG on Codeberg (live): https://codeberg.org/astronexus/hyg (README, LICENSE)
- HYG on GitHub (archive; README points to Codeberg): https://github.com/astronexus/HYG-Database
- *CC BY-SA 4.0 legal code*: https://creativecommons.org/licenses/by-sa/4.0/legalcode.en
- *Creative Commons FAQ*: https://creativecommons.org/faq/

**Fab**
- *Fab EULA* (last updated 2024-10-01; bot check on scripted fetches, read in a normal browser): https://www.fab.com/eula
- Epic Developer Community, *Licenses and Pricing in Fab*: https://dev.epicgames.com/documentation/en-us/fab/licenses-and-pricing-in-fab
- Not accessible: Fab support article https://support.fab.com/s/article/license-and-pricing (needs JavaScript; certificate error on fetch). Not needed, since the EULA is the binding text.

**Aerial imagery** (accessed 2026-10-06; details in `docs/research/aerial.md`)
- USDA NAIP via Microsoft Planetary Computer, collection `naip` (2023 Illinois, 0.3 m, 4 bands): https://planetarycomputer.microsoft.com/dataset/naip
- U.S. Census Bureau, TIGERweb *2020 Census ZIP Code Tabulation Areas* layer (accessed 2026-10-06; licence unverified, see Z1): https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/PUMA_TAD_TAZ_UGA_ZCTA/MapServer/7
- USDA FSA policies and links: https://www.fsa.usda.gov/help/policies-and-links

**Lidar** (accessed 2026-10-06; details in `docs/research/lidar-roofs.md`)
- USGS 3DEP Entwine Point Tiles, `s3://usgs-lidar-public/USGS_LPC_IL_4County_Cook_2017_LAS_2019/` (AWS Open Data registry: https://registry.opendata.aws/usgs-lidar/; registry source https://github.com/awslabs/open-data-registry/blob/main/datasets/usgs-lidar.yaml)
- FGDC metadata of the delivery tile: https://thor-f5.er.usgs.gov/ngtoc/metadata/waf/elevation/lidar_point_cloud/laz/IL_4County_Cook_2017/USGS_LPC_IL_4_County_QL1_LiDAR_2016_B16_LAS_15759550.xml (via ScienceBase item https://www.sciencebase.gov/catalog/item/64828bced34ef77fcafc9fc4)
- USGS copyrights and credits: https://www.usgs.gov/information-policies-and-instructions/copyrights-and-credits (HTTP 403 in the roof pilot; read 2026-10-06 for the terrain slope grids)
- The National Map terms of use FAQ (read 2026-10-06): https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map
- Terrain slope grids, Denver: USGS 3DEP Entwine Point Tiles `s3://usgs-lidar-public/CO_DRCOG_2_2020/`; FGDC metadata of tile https://thor-f5.er.usgs.gov/ngtoc/metadata/waf/elevation/lidar_point_cloud/laz/CO_DRCOG_2_2020/USGS_LPC_CO_DRCOG_2020_B20_w0495n4399.xml (ScienceBase item https://www.sciencebase.gov/catalog/item/61c57256d34e2ca389db8f7c); vendor metadata https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/metadata/CO_DRCOG_2020_B20/CO_DRCOG_2_2020/reports/vendor_provided_xml/312020336_USGS_DRCOG_Lidar_QL2_ClassifiedPointCloud.xml
- Terrain slope validation: USGS 3DEP 1 m DEM tiles of IL_4_County_QL1_LiDAR_2016_B16 and CO_DRCOG_2020_B20 on https://prd-tnm.s3.amazonaws.com/ (windowed reads; tile URLs in each `terrain-slope.json`), found through the TNM Access API https://tnmaccess.nationalmap.gov/api/v1/products

**Live transit and aircraft feeds** (accessed 2026-10-06; full list with read status in `docs/research/live-feeds.md` §7.4)
- Metra, all **unverified (site blocks automated access; confirm in a normal browser)**: https://metra.com/developers, https://metra.com/metra-gtfs-api, https://metra.com/gtfs-realtime-api-key-request-license-agreement, https://metra.com/terms-and-conditions
- CTA: https://www.transitchicago.com/developers/terms/ (DLA), https://www.transitchicago.com/developers/branding/, https://www.transitchicago.com/developers/traintracker/, https://www.transitchicago.com/developers/traintrackerapply/, https://www.transitchicago.com/developers/ttdocs/, https://www.transitchicago.com/developers/bustracker/, https://www.transitchicago.com/developers/gtfs/, https://transitdata.transitchicago.com/ (GTFS-RT beta)
- Pace: https://pacebus.com/route-timetable-data-services, https://pacebus.com/bus-tracker-tools; third party for the live URLs: https://raw.githubusercontent.com/transitland/transitland-atlas/main/feeds/pacebus.com.dmfr.json
- Denver RTD: https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement, https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds, https://www.rtd-denver.com/open-records/open-spatial-information/gtfs
- OpenSky: https://openskynetwork.github.io/opensky-api/index.html and https://openskynetwork.github.io/opensky-api/rest.html; its terms page https://opensky-network.org/about/terms-of-use and its https://opensky-network.org/data/api page are **unverified (site blocks automated access; confirm in a normal browser)**
- ADS-B Exchange / JETNET: https://www.adsbexchange.com/community/developer-hub/, https://www.jetnet.com/legal/terms-of-use/ (the older address https://www.adsbexchange.com/terms-of-use/ redirects there), https://www.adsbexchange.com/data-products/. Its support site (support.adsbexchange.com, only an archive copy was read, after a bot check) is **unverified (site blocks automated access; confirm in a normal browser)**; it is used as supporting evidence only (live-feeds §7.1 U10)
- adsb.lol: https://api.adsb.lol/api/openapi.json, https://www.adsb.lol/privacy-license/, ODbL summary https://opendatacommons.org/licenses/odbl/summary/
- adsb.fi: https://raw.githubusercontent.com/adsbfi/opendata/main/README.md
- airplanes.live: only archive copies and a third-party GitHub issue (repository `skylight`, issue 66; owner name omitted, so no link); **unverified (site blocks automated access; confirm in a normal browser)**
- FlightAware AeroAPI: https://www.flightaware.com/commercial/aeroapi/ and its Standard, Premium and Personal licence PDFs; https://www.flightaware.com/commercial/flightaware-terms-conditions-Sep2026.pdf
- Flightradar24: https://fr24api.flightradar24.com/docs/credit-overview, https://fr24api.flightradar24.com/subscriptions-and-credits, https://fr24api.flightradar24.com/docs/storage-rules; its ToS https://www.flightradar24.com/terms-of-service (archive copy) is **unverified (site blocks automated access; confirm in a normal browser)**
- LADD / PIA / others: https://www.faa.gov/pilots/ladd, https://nbaa.org/aircraft-operations/security/privacy/privacy-icao-address-pia/, https://www.faa.gov/air_traffic/technology/swim/products/get_connected, https://wingbits.com/terms-and-conditions/b2b, https://aviation-docs.spire.com/api/flights-live/introduction (Spire; price and licence unconfirmed)
- Relay hosting prices: https://developers.cloudflare.com/workers/platform/pricing/, https://fly.io/docs/about/pricing/, https://aws.amazon.com/lambda/pricing/, https://aws.amazon.com/cloudfront/pricing/

**Repo files referenced:** `CLAUDE.md`, `README.md`, `Sources/WorldEngine/WorldAttributionView.swift`, `Sources/WorldEngine/WorldView.swift`, `Data/areas/sloans-lake/{NOTICE.md,manifest.json,osm.overpassql,osm.json}`, `docs/package-format.md`, `Sources/WorldPackage/WorldPackage.swift`, `web/index.html`, `web/package-lock.json`, `Sources/WorldEnvironment/{WeatherProvider.swift,Stars.swift,EnvironmentState.swift}`, `Sources/WorldEnvironment/Catalog/{STARS-NOTICE.md,stars-bsc5-bright256.json}`, `scripts/data/build_star_catalog.py`, `Sources/WorldMesh/Earcut.swift`, `Apps/WorldLab/project.yml`, `docs/plan-m1.md`; added 2026-10-06: `docs/data-licensing.md`, `Sources/WorldGen/{Credits.swift,CreditBurnIn.swift,Profiles/credits.json}`, `Sources/WorldEngine/{WorldCredits.swift,WorldCreditsView.swift}`. Also the read-only proposals `docs/proposals/{experience-v1,weather-v1}`.

---

## 12. Live transit and aircraft feeds

Added 2026-10-06 from `docs/research/live-feeds.md`, which holds the per-feed tables, relay design and cost model. The engine uses no live feed today, so every row LT1–LT14, LA1–LA11 and LR1–LR3 in §1 is "N/A yet" or "To do (before using the feed)". New status wording used there: **Needs provider confirmation** means only the provider can answer, in writing. Quotes in this section are verbatim and under 15 words; everything else is paraphrased. Facts tagged **unverified (site blocks automated access; confirm in a normal browser)** were read after a site blocked automated access, by a route the owner does not accept, and must be re-checked in a normal browser before anyone relies on them: all Metra and NITA Data Hub pages, the OpenSky terms page and its `/data/api` page (live-feeds §7.1 U7), airplanes.live, the ADS-B Exchange support-site archive copy (live-feeds §7.1 U10) and the Flightradar24 terms of service. Wherever this section writes **[unverified]**, it means exactly that phrase.

### 12.1 What the obligations add up to

- **A relay is the shape the terms point to.** Metra requires redistribution through our own host [unverified]; CTA caps keys per account and can disable a key; Flightradar24 and FlightAware limit raw redistribution; ADS-B Exchange Enterprise does not allow a relay under its standard terms. Phones never hold keys (LR3, LT1, LT8).
- **Transit.**
  - *Pace:* data shared for "non commercial use"; live URLs undocumented. Do not use (LT11, LT12).
  - *CTA:* use is limited to assisting riders or promoting public transportation; delete all CTA Data on termination; branding limits (LT5–LT10).
  - *Metra* [unverified]: relay mandatory; non-affiliation statement and last-updated time on every display; "must not modify or delete Data" against area filtering (LT1–LT4).
  - *RTD:* the easiest; redistribution granted, paid use unaddressed, non-endorsement notice possible (LT13).
  - *All:* revocable, "as is", changeable without notice, with indemnities and forum clauses (LT14).
- **Aircraft.**
  - *Barred for commercial apps:* OpenSky public API, ADS-B Exchange Community API, adsb.fi, airplanes.live (LA1, LA2, LA5, LA6).
  - *adsb.lol:* ODbL, so attribution and share-alike apply to anything we publicly use that is derived from it; the operator asks production users to get in touch (LA4).
  - *Commercial feeds:* FlightAware Standard (B2C embedding and internal use, derived non-raw data, 30-day raw limit, "commercial aircraft situational displays" barred, no community backfill unless FlightAware agrees in writing), Flightradar24 (30-day storage; no raw redistribution [unverified]; credit [unverified]), ADS-B Exchange Enterprise (end-user presentation only for end users who are direct JETNET subscribers; a relay needs a special agreement) (LA3, LA7, LA9).
- **Privacy.** Drop LADD and PIA aircraft in the relay; send no registration or ICAO address to phones (LA10). Tile requests reveal approximate location, so log no tile together with an IP address or user id (Q30).
- **Retention.** Keep only the latest snapshot, expiring in minutes; no live data in the repo, packages, fixtures or exports (LR2). Metra's "must not ... delete Data" [unverified] may conflict with purging (Q22, Q30).
- **Attribution.** Each feed's credit rides in the relay response and is shown next to the OpenStreetMap credit; exports need the same credits burned in (LR1, O4–O6).

### 12.2 Blockers and risks for live feeds, ranked

1. **Pace is not usable commercially (High).** (LT11, LT12; Q23)
2. **CTA's purpose clause (High).** A decorative layer may be outside it; ask before shipping. (LT5; Q21)
3. **Metra's relay and no-modification wording (High, unverified).** (LT1–LT4; Q22)
4. **Aircraft licensing (High).** Only adsb.lol is open to commercial use, with a "contact me" condition; the commercial feeds restrict raw redistribution and cost about $1.6k to $18.4k per month for two metros at 30 aircraft per poll (live-feeds §5.4); the sensitivity table there reaches $36.8k at 60 aircraft per poll. (LA3–LA9; Q25–Q27)
5. **LADD and PIA (Medium).** Filter in the relay; confirm whether any duty applies to us. (LA10; Q28)
6. **Revocation and no uptime promise (Medium).** Kill switch and graceful degradation. (LT14; Q24)
7. **White-label (Medium).** CTA's licence is non-assignable and non-transferable; a shared relay may need per-licensee keys. (Q31)

---

## 13. Decisions (2026-10-06)

Owner decisions, implemented as described in `docs/data-licensing.md`:

- **6a. The world package is an ODbL Derivative Database.** Every package carries a licence notice (`LICENSE-DATA.md`); how the derived data will be offered publicly is documented (`docs/data-licensing.md` §2). No hosting yet. Rows O8, O9, O10.
- **6b. The engine provides the credits.** A standard credits data file (`Sources/WorldGen/Profiles/credits.json`) and component (`WorldCreditsView`, `WorldCreditsButton`); host apps must show it. Row O13.
- **6c. The OSM credit is always visible in interactive views and burned into every exported image.** A small (i) credits button complements the visible credit, per the OSMF attribution guideline; there are no credit-free exports (`CreditBurnIn`). Rows O3–O6.
- **6d.** Star catalog: HYG (CC BY-SA) replaced by the public-domain Yale Bright Star Catalogue (256 brightest stars, 254 of them the same as the HYG set; the two that differ sit at the magnitude cut; visibility rules and tests unchanged). Done 2026-10-06; see rows H1-H3 and §5.
- **6e. Fab: Personal tier for now.** Fab assets go only inside app bundles, never in world packages or white-label deliverables. The Fab EULA §6(a) lawyer question (Q13) stays. Rows F1–F6.
- **6f. Quick fixes approved:** (1) the web credit links to openstreetmap.org/copyright (O2, done); (2) a licence notice file and licence URL in the package exporter (O8, done); (3) credits burned into exported images (O4, helper done; export callers to do).

Re-checked 2026-10-06 for this section: https://www.openstreetmap.org/copyright (credit OpenStreetMap; make clear the data is under the ODbL; link the licence when distributing data) and the OSMF Attribution Guideline, interactive maps (an "(i) button in the corner" or an About option as the place licence information stays findable).

---

## 14. Live-world lane sources (added 2026-10-06)

Sources used by the renderer-neutral live-world layers in `Tools/livefeeds/` (specs in `docs/live-world/`). These layers
run in a cloud session whose **network policy denies most hosts** (CelesTrak, JPL, NASA LAADS and Black Marble, CDS,
CTA, RTD, adsb.lol). That is our own egress policy, not the sites blocking automated access, and nothing was fetched
around it: no mirror, archive copy or third-party repackaging was used. Rows marked **not read this pass** must be
checked from a normal connection before release. Status values as in §1.

| # | Source | Used for | Licence / terms | Attribution in the contract | Status |
|---|---|---|---|---|---|
| **LW1** | Yale Bright Star Catalogue 5th rev. ed., the engine's existing extract (`Sources/WorldEnvironment/Catalog/`) | Sky: stars | Public domain in practice (rows H1-H3, `STARS-NOTICE.md`); no new download | `bsc5`: "Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren), via NASA HEASARC. Star names: IAU Working Group on Star Names." (`required: true`, because the IAU names are CC BY and the contract carries them) | Done |
| **LW2** | Meeus, *Astronomical Algorithms* 2nd ed. (1998): formulas and coefficient tables (ch. 12, 16, 21, 22, 41, 47, 48) | Sky: time, frames, Moon, magnitudes | Book is copyrighted; we use the published algorithms and numeric coefficients (facts), not its text. The lunar tables were already in the engine (`Moon.swift`) | None required | Done |
| **LW3** | E. M. Standish, "Keplerian Elements for Approximate Positions of the Major Planets", JPL Solar System Dynamics (table 1) | Sky: planets | JPL/NASA publication; numeric elements (facts). Page not read this pass (host denied); elements reproduced from the published table and validated against DE421 to its stated accuracy | None required | Done (re-read the page from a normal connection) |
| **LW4** | Krisciunas & Schaefer (1991), PASP 103, 1033 | Sky: moonlight brightness | Published formula (facts) | None required | Done |
| **LW5** | NASA Black Marble VNP46A4 collection 5200 version 002 (VIIRS/NPP Lunar BRDF-Adjusted Nighttime Lights Yearly L3, 15 arc-second), DOI 10.5067/VIIRS/VNP46A4.002, 2025 composite from NASA LAADS DAAC | Sky: light pollution (`Tools/livefeeds/data/radiance/{chicago,denver,miami}-2025.json`, derived 30 arc-second means) | NASA Earth science data are openly shared without restriction under NASA's Earth Science Data and Information Policy; NASA asks for a citation. Downloaded 2026-10-07 with the owner's Earthdata token after the owner accepted LAADS's terms; only derived grids are in the repo, no raw granules | `nasa-black-marble`: "Night lights: NASA Black Marble (VIIRS Day/Night Band), NASA Goddard Space Flight Center." (`required: false`, courtesy), sent only when a grid is used | Baked 2026-10-07. To do before release: confirm the citation text on the policy page; cite the DOI. Suomi NPP deliveries end 2026-11-02: future updates use NOAA-20 `VJ146A4` (same layout, annual, on LAADS 5200 for 2022-2025); NOAA-21 has only `VJ246A1`/`VJ246A2` so far (daily), no annual product yet |
| **LW6** | Skyfield 1.55 (MIT) with `skyfield-data` 7.0.0 (JPL DE421, IERS finals2000A), from PyPI | Validation only (`Tools/livefeeds/validation/`), never shipped | MIT; DE421 is a JPL product; IERS data free | None (not shipped) | Done (dev only) |
| **LW7** | CelesTrak GP element sets (`celestrak.org/NORAD/elements/gp.php`), sourced from U.S. Space Force (18th/19th Space Defense Squadrons) public GP data | Satellites: orbits | **Read 2026-10-06**: the Usage Policy (`celestrak.org/usage-policy.php`, T.S. Kelso, updated 2026-05-22) and the GP data formats FAQ (`/NORAD/documentation/gp-data-formats.php`, updated 2026-03-26). They set usage rules, not a licence: download only what is needed, only once per update (GP every 2 hours); machine clients must stop on any non-200 response (301, 403, 404, 50x) and report to a human, or the IP is firewalled after repeated errors; organisations serving many devices should run a caching proxy rather than let every device query CelesTrak; prefer OMM/CSV/JSON (5-digit catalogue numbers ran out on 2026-07-11, TLE cannot carry new objects). Neither page states a licence, redistribution terms or an attribution requirement; the policy calls the data "freely available to all users". Implemented: 2-hour floor, honest User-Agent, redirects not followed, any HTTP error stops the fetcher for a day with `needsHuman`, JSON OMM only. With SGP4 moving onto the phone, phones need elements: they get them from our relay's cache (the caching proxy the policy asks for), never from CelesTrak directly. **Owner decision 2026-10-07**: phones download elements from the relay's cache (refreshed within CelesTrak's policy), never from CelesTrak directly, and never send their location; passes are computed on the phone (`Sources/LiveSky`). **Lawyer question**: may we redistribute CelesTrak elements (U.S. Space Force GP data) to our app users this way, and does Space-Track's user agreement (redistribution limits) reach data taken from CelesTrak? | `celestrak`: "Orbital elements: CelesTrak (celestrak.org), from U.S. Space Force public GP data." (`required: true`; not demanded by the pages, kept as courtesy and provenance) | Terms read; ask CelesTrak and lawyer (relaying elements to app clients, commercial app) |
| **LW8** | Vallado's SGP4 verification files `SGP4-VER.TLE` and `tcppver.out`, as shipped in the `sgp4` package (PyPI, MIT) | Validation only; nothing copied into the repo | MIT package; files from Vallado et al. 2006 | None (not shipped) | Done (dev only) |
| **LW9** | RTD static GTFS `trips.txt` and `shapes.txt` (same zip and licence as the routes table, row LT13 and live-feeds §2.5) | Transit: route-shape smoothing; shapes served to phones by `/v1/shapes` | RTD GTFS licence (redistribution granted; may be revoked). Shapes are served live from the relay and never baked into packages (live-feeds §4.4). Not re-read this pass (host denied by the session's network policy) | Same RTD credit and non-endorsement notice as the vehicles (`rtd`) | Done in code; re-read the licence before the first real download |
| **LW10** | CTA Train Tracker and Bus Tracker | Transit (Chicago): Train Tracker adapter built 2026-10-06; Bus Tracker adapter built 2026-10-07; CTA static GTFS (`google_transit.zip`: shapes and stops, same Developer License Agreement, which ships inside the zip) used from 2026-10-07 | CTA Developer License Agreement (live-feeds §2.3; purpose clause, blocker 2). Keys only as environment secrets | "Data provided by Chicago Transit Authority" (`required: true`), sent on every CTA response | Train key in use for development; waiting for the bus key and CTA's written answer (purpose clause) before shipping |
| **LW11** | OpenStreetMap runway geometry (ORD, DEN), copied from `docs/research/ambient-planes.md` table 2.3 into `Tools/livefeeds/data/ambient-planes/*.json` | Planes: simulated approach and departure corridors | ODbL 1.0 (a small derived database; same handling and lawyer question as the world package, ambient-planes §6). No flight data, so no aircraft-feed licence applies | `ambient`: "Illustrative air traffic, not live. Runway geometry © OpenStreetMap contributors." (`live: false`, `required: true`) | Done |
| **LW12** | adsb.lol live ADS-B | Planes: evaluated only, not used | ODbL; production users asked to contact the operator (live-feeds §3, rows LA4). Not re-read this pass (host denied by the session's network policy) | Would be the adsb.lol ODbL credit | Not used: needs the operator's written permission and the owner's ODbL decision |
| **LW13** | FAA NASR 28-day subscription (`APT_RWY.csv`, `APT_RWY_END.csv`: runway ends, coordinates, headings, thresholds), U.S. government work | Planes: Midway (MDW) runways for simulated traffic, instead of OSM/Overpass (owner decision 2026-10-07) | Public domain (17 U.S.C. 105, U.S. federal government work); no attribution required, courtesy credit "FAA NASR" | None required | **Fetched 2026-10-07 by P1** (from the Mac, which reaches nfdc.faa.gov): `https://nfdc.faa.gov/webContent/28DaySub/extra/01_Oct_2026_APT_CSV.zip` (cycle effective 2026-10-01, 8.0 MB, SHA-256 `aba48ea877f2…` in the file), linked from the FAA NASR Subscription page; MDW rows only → `Tools/livefeeds/data/ambient-planes/mdw.json` (runways only; flows pending the owner). The earlier cloud session was denied by its network policy; no mirror used |

## 15. OSM-derived vs independent layers (owner rule, 2026-10-06)

**Rule.** Layers derived only from public-domain non-OSM sources (lidar roofs and heights, NAIP canopy, 3DEP
slope/terrain) stay structurally separate from OSM-derived layers: separate files, joined at runtime by spatial
position or stable ID, never merged into OSM features. Goal: OSM-derived data is shareable under the ODbL;
independent layers stay proprietary, pending lawyer review (Q-new below). "Independent" here means no OSM or
Overture input at any step, including masks, block boundaries and keys.

| Layer | Where | Inputs | Class |
|---|---|---|---|
| `osm.json`, `context.json`, `relations.json` | area data | OSM | OSM (ODbL) |
| `overture-buildings.json` | area data | Overture buildings (ODbL as a whole: it incorporates OSM) | OSM-derived (ODbL) |
| `map/*.json` (map data layer v2), `mapmeta/*.json` | package | OSM, Overture, Census ZCTA tags, generator rules | OSM-derived (ODbL). ZCTA tags are public-domain values attached to OSM features (public domain stays public domain; nothing proprietary is lost) |
| `chunks/*`, `instances.json`, `collision.json`, `environment.json` | package | OSM geometry through the generator; profile values | OSM-derived (ODbL), as before (§2.3) |
| `terrain-slope.json` + `.bin` | area data; package `independent/terrain-slope.*` | USGS 3DEP lidar ground returns only, gridded in the area frame | **Independent** |
| `zcta.json` | area data | U.S. Census ZCTA5 2020 | Independent (public domain; cannot be made proprietary) |
| Lidar tree heights (`trees.py` → profile `trees.heightMeters` and `Tools/regionkit/lidar/results/trees.json`) | profiles, results | 3DEP vegetation and building classes only (OSM footprints used for diagnostics, not for the values) | **Independent** |
| `independent/lot-slope.json` | package | 3DEP slope **over OSM-derived lot outlines**, keyed by lot ID | **Not cleanly separable** (see below) |
| `lidar-roofs.json` | area data | 3DEP points classified **inside OSM/Overture footprints**, keyed by OSM/Overture IDs | **Not cleanly separable** |
| `roof-mix-blocks.json` | area data | the above, aggregated per **OSM street-bounded block** | **Not cleanly separable** |
| `canopy-blocks.json` | area data | NAIP canopy mask (independent) aggregated per **OSM street-bounded block**; parks and water from OSM | **Not cleanly separable** |
| Profile `canopyShare`, measured roof mixes and pitches, storey mixes (`provenance` entries) | `Sources/WorldGen/Profiles/*.json` | NAIP / lidar aggregated over OSM blocks, footprints or landuse | Aggregates of mixed inputs: lawyer question (insubstantial statistics?) |

**What changed in code (2026-10-06).** Lidar slope never goes into `map/lots.json`: NJ's contract adopted the same
split (D-57). The package carries the slope grid in `independent/terrain-slope.json` + `.bin` (joined by position in
the package frame) and the per-lot values in `independent/lot-slope.json` (joined by lot ID). Each file states its
own licence ("Proprietary (WorldEngine), pending legal review"), the USGS acknowledgement and its credit;
`independent/*` is classified as separately licensed, not part of the ODbL Derivative Database
(`WorldPackage.separatelyLicensedFiles`, world.json `dataLicense.separatelyLicensed`), and listed in world.json
`independentLayers`.

**What cannot be separated cleanly, and what would fix it.**

1. **Per-lot slope.** The number is a lidar measurement, but taken over a lawn outline built from OSM footprints and
   streets, and keyed by an ID built from an OSM ID. Separate file, but arguably still derived from OSM. Clean
   alternative: consumers sample `independent/terrain-slope.*` themselves at runtime over the lot polygon they
   already have; NJ's adapter already does this for lots without a confident record (contract D-80, D-81).
2. **Lidar roof hints** (`lidar-roofs.json`, `roof-mix-blocks.json`). Clean alternative: segment roofs from the
   lidar building class alone (own polygons, own IDs), and aggregate on a fixed grid (e.g. 100 m cells in the area
   frame) instead of OSM blocks; the generator then joins by position. Not done: P2 is wiring the current files.
3. **NAIP canopy blocks.** Clean alternative: canopy share on the same fixed grid, or the canopy mask itself as a
   raster; join by position. Not done yet.
4. **Profile aggregates.** Already summary numbers; whether an aggregate over OSM-defined areas is an insubstantial
   extract or a derivative is for the lawyer.

**Lawyer question (add to §9).** If a value is measured from a public-domain source but over an area or at points
defined by OSM geometry (a lot outline, a street block, a footprint), is the value part of an ODbL Derivative
Database when shipped in a separate file joined by an ID derived from an OSM ID? And does a fixed grid in the
package frame (the frame's origin is the area centre we chose, not OSM data) keep a layer independent?

### 15.1 Pre-distribution checklist (owner decision, 2026-10-06)

Nothing is distributed yet (no public package, no licensee), so no share-alike obligation applies today. Before
the **first public package or licensee**, and **after the lawyer review**:

- [ ] Redo the lidar roof hints on an OSM-free basis: roofs segmented from the lidar building class alone (own
      polygons, own IDs), aggregated on a fixed grid in the area frame; the generator joins by position. Replaces
      `lidar-roofs.json` and `roof-mix-blocks.json` (§15 item 2).
- [ ] Redo the NAIP canopy blocks on the same fixed grid (or ship the canopy mask as a raster); join by position.
      Replaces `canopy-blocks.json` (§15 item 3).
- [ ] Settle per-lot slope with the lawyer's answer: either keep `independent/lot-slope.json` (joined by lot ID) or
      have consumers sample `independent/terrain-slope.*` themselves (§15 item 1). NJ reads both (contract D-57,
      D-80, D-81).
- [ ] Re-check the profile aggregates (canopy share, measured roof mixes and pitches, storey mixes) against the
      lawyer's answer on aggregates over OSM-defined areas (§15 item 4).
- [ ] Confirm the separately licensed classification of `independent/*` in `LICENSE-DATA.md` and world.json
      `independentLayers` matches the final licence.
