# UK launch data research

Reviewed 7 October 2026. Primary-source desk review. No data downloaded or integrated in these concept images. Dataset availability does not certify tile coverage, parcel accuracy or permission for every derivative output.

## Terrain and building heights

**Verified:** the Environment Agency 1m composite DTM catalogue describes approximately 99% coverage of England, OGL licensing and a 2022 composite assembled from surveys spanning 2000–2022. Use the survey index for capture date; 1m cell spacing is not 1m height accuracy. This is suitable as an England terrain candidate for London and Manchester, not Edinburgh. [EA DTM catalogue](https://www.data.gov.uk/dataset/01b3ee39-da3f-47b6-83da-dc98e73a461f/lidar-composite-digital-terrain-model-dtm-1m).

**Verified:** EA DSM includes terrain, buildings, vegetation and vehicles and is also listed under OGL. **Inference:** co-registered DSM minus DTM can propose object heights; filter trees, inspect roof geometry and capture-date mismatch, and attach uncertainty. It is not a certified building-height field. [EA DSM](https://environment.data.gov.uk/dataset/9ba4d5ac-d596-445a-9056-dae3ddec0178).

**Edinburgh UNVERIFIED:** the Scottish Government remote-sensing portal is a candidate for Scottish lidar. Exact Edinburgh tile coverage, survey dates, vertical datum and licence of selected products were not established in this review. Do not extend the EA England coverage claim to Scotland. [Scottish portal](https://remotesensingdata.gov.scot/).

## OS OpenData versus MasterMap

**Verified:** OS OpenData covers Great Britain and permits commercial and personal reuse under OGL. This is a product portfolio, not unrestricted access to every OS dataset. [OS OpenData](https://www.ordnancesurvey.co.uk/products/open-data).

**Verified:** OS OpenMap Local is generalised street-level context at 1:10,000, with raster/vector downloads and six-monthly updates. Use its building representation as context, not automatically as individual surveyed parcels or height-bearing 3D geometry. [OpenMap Local](https://www.ordnancesurvey.co.uk/products/os-open-map-local).

**Verified:** OS separately licences usage, publishing and distribution. MasterMap access through a free API allowance does not convert it into OGL data. The open-MasterMap programme page describes royalty-free thresholds for some premium API usage; current commercial entitlement and derived-geometry redistribution must follow the actual selected contract. **UNVERIFIED:** WorldEngine-specific MasterMap storage, client mesh delivery, export and derivative database rights or price. [OS licensing](https://www.ordnancesurvey.co.uk/licensing), [open-MasterMap programme](https://www.ordnancesurvey.co.uk/products/open-mastermap-programme).

## OSM completeness

**Verified:** OSM is distributed under ODbL, with attribution and applicable share-alike obligations. [OSM copyright and licence](https://www.openstreetmap.org/copyright).

**UNVERIFIED:** no current numerical completeness result was established for London, Manchester or Edinburgh. Do not call a visually dense map complete. Assess building recall against independently licensed reference data, footprints split by terrace/parcel, height and building:levels coverage, road direction, sidewalks, crossings, entrances and tree points separately. Date the extract and retain provenance. The proposed audit is a data acceptance check, not a validation pilot plan.

## Met Office: application display, no raw redistribution

**Verified:** the current Weather DataHub FAQ permits commercial application use subject to its licence and requires attribution. The linked terms restrict original-form onward distribution and reverse engineering of the supplied products. A live weather view therefore needs an application presentation layer, not a downloadable raw feed or generic JSON proxy. No attribution is placed in these scenery images because they contain no actual Met Office data. [FAQ](https://datahub.metoffice.gov.uk/support/faqs), [linked terms, dated 15 August 2024](https://www.metoffice.gov.uk/api/assets/file/met-office-weatherdatahub-terms-and-conditionspdf?prefix=assets).

**UNVERIFIED:** permission for a particular WorldEngine embed/export architecture, retention period, transformed scene-state API, selected subscription and caching design. Confirm against the accepted product contract before integration. Do not apply this restriction indiscriminately to unrelated Met Office open datasets with their own licences.

## TfL open transport data

**Verified:** the Transport Data Service licence is based on OGL v2 with TfL amendments. It permits commercial reuse subject to attribution, specified third-party credits, protected intellectual property and service limits; it does not grant TfL branding rights or endorsement. The terms state a maximum of 500 calls per minute per feed, subject to throttling. Registration and actual endpoint quotas still need checking at integration. [TfL data terms](https://tfl.gov.uk/corporate/terms-and-conditions/transport-data-service), [open-data entry point](https://tfl.gov.uk/info-for/open-data-users/).

The generic red bus, black cab and station stairwell are authored assets, not extracted TfL designs or data. There are no roundels, TfL marks, service numbers or readable destination signs. **UNVERIFIED:** Manchester and Edinburgh live transit licences; TfL terms do not cover these cities.

## London public realm trees

**Verified:** the GLA public-realm dataset is listed under OGL v3 and includes species/location records from public inventories. It is not all London trees: borough coverage, age and location availability vary, with gaps and retained older records. Useful for species-aware placement after inspecting individual record date and location confidence. [London Public Realm Trees](https://data.london.gov.uk/dataset/london-public-realm-trees-2r45m).

The values JSON tree proportions and dimensions are **UNVERIFIED authored modeling targets**, not measured London-wide species shares. The three requested species are presented as representative visual forms; species suitability and management constraints remain site-specific.

## Integration recommendation

Use OGL terrain and generalised OS context where suitable, OSM with explicit attribution and feature-specific quality checks, and record-level public tree data. Licence detailed OS geometry separately when required. Keep weather presentation within the accepted Met Office application terms and TfL data attribution outside scene textures. Record source, licence URL/version, capture date, coordinate system, vertical datum, confidence and derived-output rights for every imported dataset.
