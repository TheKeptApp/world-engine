# Licensing demo v1 — evidence register

Accessed 7 October 2026 local time (some fetches stored on 8 October UTC). Primary-source research. Vendor pricing is USD list pricing, before taxes, contracts and discounts. Sources were read for research only; no provider tiles or customer logos are used in the mock. Buyer expectations and WorldEngine offer design are inference, with no customer interviews. Exact production terms, OEM permissions and SLA would require review against the signed account contract. The rendered research page places citations beside claims.

## Mapbox

- [Pricing](https://www.mapbox.com/pricing): GL JS monthly-load meter and marginal usage bands. Not all map services share this meter.
- [Attribution](https://docs.mapbox.com/help/dive-deeper/attribution/): provider and data credits/logo handling.
- [API caching](https://docs.mapbox.com/help/dive-deeper/api-caching/): API-specific behavior and HTTP cache lifetimes; no universal offline entitlement.
- [Terms](https://www.mapbox.com/legal/tos): hosted-service obligations; exact purchased-product terms remain applicable.
- [SLA](https://www.mapbox.com/legal/sla): active executed-order condition, covered API availability, monthly measure, credits and exclusions.

## Cesium

- [ion plans](https://cesium.com/platform/cesium-ion/pricing/): subscription plans and quotas; distinguish hosted service from open renderer.
- [ion terms](https://cesium.com/legal/terms-of-service): commercial use within organization versus negotiated commercial sublicensing/integration licence; content-specific terms.
- [Content attribution guide](https://cesium.com/learn/ion/content-usage-and-attribution-guide/): credit and source conditions vary by content. Offline/OEM applicability of a WorldEngine deployment is unverified.

## Google

- [Global pricing](https://developers.google.com/maps/billing-and-pricing/pricing): current Photorealistic 3D Tiles rate/free cap/volume bands. Different from Google Maps Embed or other 3D products.
- [Usage and billing](https://developers.google.com/maps/documentation/tile/usage-and-billing): root request quota and child-tile access window.
- [GA announcement](https://mapsplatform.google.com/resources/blog/build-immersive-maps-at-scale-with-photorealistic-3d-2d-and-street-view-tiles-now-in-ga/): historical explicit root-request billing. Current general SKU wording may differ; account billing should be confirmed before a cost guarantee.
- [Map Tiles policies](https://developers.google.com/maps/documentation/tile/policies): attribution, visualization scope, caching/extraction/offline restrictions and EEA differences. No permission inferred to convert proprietary meshes into stylized redistributable assets.
- [Support](https://developers.google.com/maps/support): support options and plan-dependent commitments. No WorldEngine SLA inferred.

## ArcGIS / Esri

- [Location Platform pricing](https://location.arcgis.com/pricing/): basemap tile and session models, service/hosting meters. Not a blanket SceneView or 3D content price.
- [Billing](https://location.arcgis.com/help/billing/): session versus tile semantics and ordinary browser cache usage treatment.
- [JavaScript SDK licensing](https://developers.arcgis.com/javascript/latest/licensing/): Esri/data attribution and service account requirements.
- [ArcGIS terms](https://www.arcgis.com/home/termsofuse.html): representations, licensed offline products and source-content rights; third-party/scene item restrictions remain relevant.
- [Location Platform SLA PDF](https://www.esri.com/content/dam/esrisites/en-us/media/legal/referenced-files/service-level-agmt-arcgis-platform.pdf): covered services and availability credits/conditions; no client frame-rate guarantee.

## Mock data and visual sources

- [NWS API documentation](https://www.weather.gov/documentation/services-web-api): open observations, lifecycle caching and rate limits.
- [KDEN latest observation endpoint](https://api.weather.gov/stations/KDEN/observations/latest): real response saved in `assets/weather-snapshot.json`; source timestamp retained. Airport station, not local-street weather; refresh may fail, observations may be delayed or stale.
- [OSM copyright](https://www.openstreetmap.org/copyright): intended product attribution and ODbL context. Synthetic mock geometry does not include an OSM extract or establish database licence compliance for a later product.
- [NOAA solar calculation background](https://gml.noaa.gov/grad/solcalc/calcdetails.html): calculated versus observed sun positions and accuracy limitations. The mock uses a simple equatorial approximation, not a validated implementation of NOAA's calculator; its elevation/azimuth is unverified for technical use.
- [three.js r180 package](https://cdn.jsdelivr.net/npm/three@0.180.0/): pinned module/core and MIT licence bundled in `vendor/`.
- [Style B calibration v2](~/Desktop/worldengine-gpt-drop/style-b-calibration-v2/README.md): user-selected visual anchor and shared-look inheritance. Unchanged reference frames and values copied into this drop; procedural mock approximates them.
- [Prior web stack](~/Desktop/worldengine-gpt-drop/web-stack-v1/README.md): iframe/SDK/MapLibre sequence, phone/browser constraints and proposed successful-session meter. Earlier research informs design; APIs and demand remain unverified.

## Interpretation and boundaries

iframe, SDK and plug-in are delivery paths, not separate automatic data rights. A provider's free allowance does not make content open. Viewer software, cloud usage, proprietary/third-party data, customer models, redistribution/OEM scope and service commitment must be reviewed separately. Avoid describing unspecified offline storage as permitted caching. Accessible alternatives, stable API versions, documentation, incident response and usage visibility are proposed evaluation requirements inferred from provider practice, not surveyed purchasing criteria.
