# Street trees by metro v1

Research date: October 7, 2026. WorldEngine research input, not an imported or production-approved vegetation model.

## Result and remaining gaps

The six requested files are saved. Coverage is **25 Census metros plus supplementary Las Vegas**: 260 core metro/taxon rows, two supplemental desert plants, 129 canonical form profiles, 26 seasonal-window rows and 34 inventory/report/guide/phenology-source leads.

This is **not yet a verified actual-mix dataset** for every metro. Thirty numeric shares were verified: ten each from Orlando's historical 2007 street inventory, San Francisco's limited 2012 survey and Phoenix's published parks/street mix (survey date/denominator count not stated). None establishes a current metro-wide street-plus-private-yard distribution. The other 230 core rows are explicitly candidates/proxies with missing shares. No shares were invented.

| Priority metro | What v1 establishes | What remains unverified |
| --- | --- | --- |
| Chicago | Historical street candidates and newer whole-city forest findings are separately cited. | Current street/yard top-ten shares; forest statistics dominated by small understory stems are not substituted. |
| Denver | Inventory metadata and ten regionally supported candidate trees; botanical form/height evidence for those candidates. | Actual inventory aggregation and current street/yard proportions. |
| Miami | County/extension plant evidence, palms and subtropical forms. | Street/yard abundance ranking; contradictory report percentages were withheld. |

Of 129 form profiles, 91 contain sourced height information and 79 contain sourced spread information; the remaining 38 height and 50 spread fields are missing/unverified. Botanical flowering and other trait gaps are marked row by row. There are 123 species-level profiles and six hybrid, infraspecific, horticultural or unresolved-genus profiles; these are not represented as 129 fully resolved species. All 26 metro calendar windows are marked heuristic rather than locally computed observation normals. All hexes are art approximations.

## Read this before using the percentages

This package distinguishes **measured inventory mix**, **historical or geographically limited proxies**, and **unverified rendering candidates**. Ten rows for a metro do not mean an authenticated current metro-wide top ten. Blank `share_pct` means no defensible numeric share was verified—not zero and not an invitation to assign an equal 10% mix. City street trees, private yards, parks, natural areas and an entire metropolitan statistical area are different populations.

Use a licensed point inventory for the actual tree at an actual location where possible. Use scoped inventory proportions only to fill missing locations in a matching setting. A planting recommendation list is evidence of suitability, not prevalence. An urban-forest survey dominated by small invasive understory stems is not a street-tree planting distribution. Survey date is separate from report publication or portal modification date. Old ash proportions in particular must not be presented as current after emerald ash borer removals.

## Files and scope

- `species-by-metro.csv`: ten best-supported inventory species or explicitly unverified candidates per metro, with share denominator, year, setting and source attached; supplemental saguaro and century plant are separately marked, not additional abundance ranks.
- `species-forms.csv`: one canonical row per represented taxon, including crown, mature dimensions, evergreen behavior, winter architecture, flowering and seasonal art colors. Genus/hybrid/unspecified groups remain groups rather than invented species.
- `phenology.csv`: metro seasonal windows, regional variation and warm/cold-year qualifications. Calendar windows marked heuristic are **unverified visual priors**, not observed climate normals or a live forecast.
- `inventories.csv`: source scope, species-field quality, dates, access and licence/commercial/redistribution status. An open endpoint is not itself a redistribution grant.
- `sources.md`: primary source bibliography and access/evidence limitations.

Chicago, Denver and Miami are ordered first. The national universe is the top 25 Census metropolitan statistical areas by July 1, 2025 population (latest consistent vintage at research time). These three are already inside that set. Las Vegas is a **26th supplementary metro** because the request explicitly calls for its palms/desert plants. [Census table](https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-metro-and-micro-statistical-areas.html), [underlying CSV](https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/metro/totals/cbsa-est2025-alldata.csv).

The other covered metros are New York, Los Angeles, Dallas–Fort Worth, Houston, Atlanta, Washington, Philadelphia, Phoenix, Boston, Riverside–San Bernardino, San Francisco–Oakland, Detroit, Seattle, Minneapolis–St. Paul, Tampa, San Diego, Orlando, Charlotte, Baltimore, St. Louis, San Antonio and Austin. CBSA identifiers in the CSVs disambiguate these geographic units. Central-city data does not automatically cover adjacent municipalities or the private-yard tree population.

## Evidence conventions

`source_urls` uses semicolon-separated citations. `evidence_status`, `notes`, `population_scope` and `share_basis` are part of the result, not optional footnotes. A candidate's row order is not an abundance rank unless its source establishes that ranking. Empty cells and text such as `unverified` or `unclear` must survive downstream handling.

Botanical mature heights/spreads are potential species ranges, in meters, not measurements of the local tree. Street pruning, root restriction, cultivars, age and site water can yield much smaller or differently shaped crowns. Do not place every instance at the species maximum. When the source did not verify a trait, the row says so; do not manufacture the missing value.

Where only an upper height, single reported dimension or unequal range was verified, the text preserves that qualification instead of implying a complete statistical range. The final profile selection favors a directly cited, dimensioned botanical reference over a generic draft; it does not average conflicting references or imply the selected reference describes every regional cultivar. The shared `species_key` joins the metro rows to those profiles.

**All hex colors are original stylized sRGB approximations**, not measured reflectance, sampled source photographs or authoritative botanic color specifications. Treat them as art-direction starting points. For deciduous taxa, winter hex describes a bark/twig material where noted, not winter foliage; the canopy should be absent. Evergreen taxa retain a crown but still shed/replace individual leaves or needles. Flower colors and generic flowering seasons need location/cultivar adjustment; they are not metro-specific flowering predictions.

## Seasonal rendering: use states, not a single switch

Distinguish bud break, emerging leaves, full crown, color transition and leaf fall. They can overlap on one individual. USA-NPN defines phenophases as observable states of particular plants, including deciduous, evergreen and drought-deciduous groups. A palm should not borrow a northern maple's bare-winter state. Live oak can replace old leaves around spring flush rather than show a northern autumn leaf-drop cycle. [USA-NPN definitions](https://www.usanpn.org/files/npn/reports/USA-NPN_Plant_and_Animal_Phenophase_Definitions_v2.1.pdf), [UF/IFAS southern live oak](https://ask.ifas.ufl.edu/publication/ST564).

The proposed runtime use is:

1. Use the recorded species at a licensed inventory point; keep unknown genus/species resolution honest.
2. Apply that species' foliage retention and crown architecture—not a metro-wide winter toggle.
3. Start from the marked calendar window only when no better observations/model exist.
4. Calibrate by species and local setting against phenology observations before calling a date reliable.
5. Apply weather anomalies cautiously; do not move every species by a fixed number of days or treat street-level geography as street-level observation.

USA-NPN's Spring Indices offer useful regional temperature-driven anomalies and historical baselines, but their early-season reference plants are lilac and honeysuckle. The index is **not every tree's actual leaf-out date**. Current maps use approximately 4 km inputs; they do not establish block-level precision. For species-specific calibration, use identified observations and inspect their temporal/site coverage. [Index documentation](https://usanpn.org/data/maps/spring), [observation access](https://data.usanpn.org/observations/).

Warm spring conditions often advance leaf development, but warm winters can reduce required chilling and complicate that direction. Fall color and drop also respond to moisture, frost, wind and photoperiod. Drought can shorten the display; a storm can strip already colored leaves. There is no defensible universal “warm year = seven days later fall” constant in this package. [USA-NPN research summaries](https://www.usanpn.org/news/article?page=11), [NOAA autumn mechanisms](https://www.noaa.gov/stories/cool-autumn-weather-reveals-nature-s-true-hues).

## Licence and implementation boundaries

City/county data is not automatically US federal public-domain data. Retain explicit licence notices and attribution; where commercial use or redistribution is unclear, obtain written clarification before putting raw points or a derivative database into a shipped WorldEngine package. Botanical facts were researched and summarized; source prose, photos and drawings were not licensed as app assets.

USA-NPN database data is offered under CC BY 4.0, including commercial sharing/adaptation with credit. Its website content, images and protocols have distinct conditions; do not assume the database grant licenses everything on the site. The CSV includes the national phenology source separately from city tree inventories. [USA-NPN terms and attribution policy](https://www.usanpn.org/about/terms).

No blocked-site bypass, signup, paid data purchase, engine change, repository change or git operation was performed. Failed page/API access is an evidence limitation, not permission to infer its contents.

The Phoenix saguaro supplement is a Sonoran regional reference, not a surveyed city share. Do not populate Las Vegas with it by geographic analogy: Las Vegas is in the Mojave setting. The Las Vegas century-plant supplement is from a local landscape guide, not an inventory; its large flowering stalk is a separate infrequent life-stage event, not the rosette's height or an annual summer bloom. [NPS saguaro range](https://www.nps.gov/sagu/learn/nature/saguaro.htm), [SNWA century plant](https://www.snwa.com/landscapes/plants/?id=14665).

## Package validation

All four CSVs were parsed and field counts checked; all 26 metros have ten core rows; every metro taxon resolves to a unique canonical form key; numeric shares are within 0–100 and the three scoped top-ten sums do not exceed 100. Unverified ranks/shares remain blank. Source URLs, form gaps and taxonomy resolution are preserved. Whitespace checks passed. Regional working files were consolidated into the six deliverables, not left as competing versions.

## Checks before production

- Confirm street versus yard shares separately for Chicago, Denver and Miami; do not silently substitute forest or planting-list evidence.
- Aggregate licensed inventories using alive trees, one current snapshot, known taxon handling and an explicit denominator. Do not count archive snapshots repeatedly or include empty planting sites as living trees.
- Preserve source-year effects, removals, unknown species and the unlisted remainder; a top-ten list normally does not sum to 100%.
- Resolve cultivar and palm hybrid uncertainty before attaching a species-specific form.
- Validate regional phenology against local observations; broad calendar priors and hex art values remain marked unverified.
- Review inventory redistribution rights separately from the botanical reference pages and USA-NPN data licence.
