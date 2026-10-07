# Technical feasibility: Event Site-map AI

Research cutoff: October 7, 2026. Verified means the linked primary source supports the stated capability or price; it does not mean WorldEngine has tested it. Architecture, acceptance targets and catalogue dimensions below are proposals.

## Recommendation

Ship constrained import-to-draft and text-to-parametric-layout together. Both should create the same typed scene objects and reversible proposal records. Treat generated meshes as an optional reviewed accessory pipeline after the core workflow works. No public evidence located establishes reliable end-to-end recognition accuracy for heterogeneous outdoor event site plans; do not promise a percentage or unattended conversion.

## A. Import pipeline and what AI can reasonably do

1. Upload, choose page/crop, preserve original, remove active content and parse in a restricted worker. Identify vector PDF, raster PDF/image, photograph or DXF. Keep source coordinates, labels, legend and extracted geometry separate from model interpretations.
2. Prefer deterministic extraction. Read DXF layers, INSERT blocks, text, polylines and dimensions; confirm units. PDF paths and text can avoid OCR where available. GDAL supports geospatial PDF vector/georeference extraction, but arbitrary PDF vector graphics are not already semantic tents/routes. [GDAL vector PDF](https://gdal.org/en/stable/drivers/vector/pdf.html)
3. For scans, deskew and tile at useful resolution; OCR labels and legend; detect symbols, polygons, lines and arrows; use a vision-language model to associate labels and shapes with a finite event taxonomy. A circle could be a table, tree or annotation: retain alternatives and abstain when ambiguous. Do not replace exact vector coordinates with language-model estimates.
4. Georeference before final true-scale placement. Show the source overlay and controllable transparency; map detections through the accepted transform. Put unidentified symbols into an unresolved tray. Keep original footprints visible until individually approved.
5. Per-item review shows source crop, label, proposed class, dimensions and their origin, position uncertainty and kit substitution. Approve, change part, correct size, move or dismiss. Bulk approval is a deliberate review convenience after inspection, never an invisible automatic publish.

Evidence: CubiCasa5K provides 5,000 indoor floorplan images and more than 80 categories. This demonstrates structured drawing parsing is an established research task, not an event-plan benchmark. OmniDocBench assesses diverse PDF extraction, not tent detection or geographical accuracy. Real5-OmniDocBench reconstructs 1,355 documents across five physical capture conditions and shows the digital-to-photo reality gap remains. Phone photos therefore need a lower-confidence path. [CubiCasa5K](https://arxiv.org/abs/1904.01920), [OmniDocBench](https://arxiv.org/abs/2412.07626), [Real5](https://arxiv.org/abs/2603.04205)

A 2026 floorplan-vectorization study reports that detection and sequence generation behave differently on scans and clean renders, and proposes an edit-cost metric. The useful product lesson is to measure human correction effort separately by input type; its wall metrics must not be represented as outdoor event accuracy. [Readout study, August 26, 2026](https://arxiv.org/abs/2608.25608)

### Georeferencing: the 2–3 point promise needs qualification

For a clean uniformly scaled plan, two distinct correspondences determine a 2D similarity transform (translation, rotation, uniform scale); use a third independent point to check error. Three non-collinear correspondences determine a six-parameter affine transform, including shear/nonuniform scale. More points allow residual checks; three exact affine fits have no redundant evidence of accuracy. QGIS documents minimum two GCPs for Helmert and three for first-order affine. [QGIS georeferencer](https://docs.qgis.org/testing/en/docs/user_manual/working_with_raster/georeferencer.html)

A phone photograph of a flat sheet generally requires perspective rectification with at least four correspondences/corners; a folded or curved sheet can need additional correction and may never become metrically trustworthy. A hand sketch not drawn to scale cannot be rescued into precise dimensions by two anchors. Import it as a spatial hint and ask for measured dimensions. Auto-suggest road intersections, building corners and field corners only when present in both sources; organizer confirms correspondence, compass orientation and scale.

Use WGS84 for exchange and a suitable local projected CRS or ENU frame for metric placement. Do not measure metres directly in longitude/latitude or assume Web Mercator scale is ground scale. Preserve datum, units, transform version and control points. PROJ describes local East/North/Up coordinates and the geographic-to-cartesian-to-topocentric sequence. [PROJ topocentric conversion](https://proj.org/en/stable/operations/conversions/topocentric.html)

DXF coordinate values are initially unitless; modelspace $INSUNITS and block units require interpretation, and inserted blocks do not receive implicit conversion. Ask the user when absent/conflicting. DWG is a separate format requiring a supported licensed conversion path; do not advertise CAD as universal. [ezdxf units](https://ezdxf.readthedocs.io/en/stable/concepts/units.html)

## B. Natural language → parametric parts → placement

The LLM should produce a validated command, not arbitrary generated scene code. Example: create(stage, width=?, depth=?, riser_height=0.9144 m, roof=?, stairs=?, anchor=field.north_boundary, offset=?). Three feet converts exactly to 0.9144 m; missing width/depth are explicitly proposed defaults, never inferred measurements. Show a footprint preview and label every assumed value.

Resolve references against a semantic map: named field polygons, entrances, route chainage, paths, prohibited zones and existing item IDs. North means geographic north, independent of camera rotation. “Mile 2” resolves to 3,218.688 metres along a specified route, rather than a straight-line radius. “Along the path” needs side, setback and spacing; “every 50 m” needs start/end and whether endpoint duplication is desired. “Near the entrance” needs an identified entrance and a visible proposed distance. “In shade at 9am” needs event date, timezone, vegetation/building geometry and sunlight model, and remains an estimate.

Store footprint and clearance envelope separately from render geometry. Validate allowed parameter combinations and kit module sizes, avoid protected areas and visible overlaps, then preview. Repeated barriers are instances with array spacing and alignment, not independently generated meshes. Store commands, scene version and provenance for undo/redo and rollback. A stage can change riser height while retaining the same stable object ID.

Parametric tooling already supports this pattern: Blender Geometry Nodes exposes per-instance/group inputs and warnings; viewport gizmos can manipulate those parameters. Autodesk Fusion supports named dimensions and parameter expressions; Unreal Engine PCG supports graph parameters and spatial asset spawning. These demonstrate authoring patterns, not a recommendation to embed a desktop engine. [Fusion parameters](https://help.autodesk.com/view/fusion360/ENU/?contextId=SLD-MODIFY-PARAMETERS), [Unreal PCG](https://dev.epicgames.com/documentation/en-us/unreal-engine/procedural-content-generation-overview). Browser performance and robust constraint handling remain WorldEngine engineering work. [Blender 4.5 Geometry Nodes modifier](https://docs.blender.org/manual/en/4.5/modeling/modifiers/generate/geometry_nodes.html), [gizmos](https://docs.blender.org/manual/en/4.5/modeling/geometry_nodes/gizmos.html)

Recommended common schema: metres/degrees internally; part and family version; width/depth/height; transform/elevation; discrete construction options; matte material palette; footprint; optional operating/queue/service envelope; support/slope metadata; cost/inventory source; reference image; object approval state. Catalog limits are modelling bounds, not engineering certification or crowd-capacity certification.

## C. Generated 3D: viable for visual exceptions, not exact event infrastructure

| Option | Verified capability/cost | Licensing and product implication |
|---|---|---|
| Meshy hosted API | Meshy 6/7 mesh task 20 credits; texture refine 10 for 2K/4K or 15 for 8K; standard image-to-3D 20 untextured/30 textured; Ultra adds 5. Remesh adds 5. USD API credit conversion not verified. | Paid output ownership qualified by applicable law; confirm SaaS end-user generation and distribution contract. Free rights and current download restrictions differ from paid. |
| Tripo hosted API | $1=100 credits. H2/H3 text 10 untextured/20 textured ($0.10/$0.20), image 20/30 ($0.20/$0.30); P1 text 30/40 ($0.30/$0.40), image 40/50 ($0.40/$0.50). Add-ons/conversion/retries increase accepted-asset cost. | Paid users generally hold output rights; official commercial-use help excludes redistribution through its foundation-model service without written authorization. Confirm WorldEngine API SaaS rights in writing. |
| Microsoft TRELLIS | Original supports text/image to meshes, radiance fields and Gaussians; authors recommend image-conditioned generation over text-conditioned quality. | Repository MIT; inspect weights and every dependency separately. No hosted per-call cost established. |
| Microsoft TRELLIS.2 | Image-to-3D with PBR; authors report ~3/17/60 seconds at 512/1024/1536 resolution on H100; requires ≥24GB NVIDIA GPU. These are vendor conditions, not browser/end-to-end latency. | Model/code MIT, with explicit separately licensed rendering dependencies. Self-host compute, ops and cleanup costs remain unverified. |
| Tencent Hunyuan3D-2.1 | Image-to-shape plus PBR texturing; repository describes 10GB shape, 21GB texture and 29GB combined VRAM. | Custom community licence excludes EU/UK/South Korea; >1m MAU at version release requires separate permission; output responsibility and usage restrictions remain. Unsuitable as an unrestricted worldwide default. |
| TripoSR local | Single-image reconstruction, about 6GB VRAM in default setup. | Official repo states code and pretrained models MIT; distinct from hosted Tripo commercial terms. Useful baseline, not proof of latest hosted quality. |

Sources: [Meshy API prices](https://docs.meshy.ai/en/api/pricing), [Meshy terms](https://www.meshy.ai/terms-of-use), [Meshy August 2026 plans](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra), [Tripo API prices](https://docs.tripo3d.ai/get-started/pricing.html), [Tripo billing](https://platform.tripo3d.ai/docs/billing), [Tripo terms](https://www.tripo3d.ai/terms), [Tripo commercial guidance](https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially), [TRELLIS](https://github.com/microsoft/TRELLIS), [TRELLIS MIT](https://github.com/microsoft/TRELLIS/blob/main/LICENSE), [TRELLIS.2](https://github.com/microsoft/TRELLIS.2), [Hunyuan 2.1](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1), [Hunyuan 2.1 license](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE), [TripoSR](https://github.com/VAST-AI-Research/TripoSR).

Meshy official web documentation and dated help differ in free-plan credits/download eligibility; API operation credits must not be converted using a web subscription ratio as if it were an API tariff. Tripo Studio credits are expressly separate from API credits. [Tripo account distinction](https://www.tripo3d.ai/help/api-plugins/tripo-studiotripo-api)

These sources establish available generation and formats, not centimetre accuracy, correct hidden geometry, arbitrary dimension editing, stable topology, Style B fidelity or safety. Generation metrics such as CLIP/ULIP similarity do not validate event-object dimensions. Restrict v1 AI-made items to noncritical visual decor/unique booth shells with a curated-kit substitute available. Keep stage decks, stairs, gates, barrier systems and toilets parametric or supplier-derived.

### Style B acceptance pipeline (proposed)

Curated orthographic reference → generation → human-confirmed physical bounding box and pivot → mesh cleanup/normal check → replace overly glossy/baked-light materials with approved matte palette → topology reduction and LODs → GLB → side-by-side reference review in canonical light plus real site light. Maintain `AI-made` badge, input rights, provider/model/task/version, creation date, asset licence and approval history. Generated tree crowns can exaggerate shade; shadow suitability needs additional geometry review. Never infer load rating or physical availability from an attractive model.

## D. Human approvals and validation

Organizer approves site identity, control points, measured scale, event date/timezone, imported classes, dimensions and final placement. Qualified suppliers/venue and appropriate authorities handle structural/tent anchoring, accessible routes, emergency egress, traffic, utilities and operational safety. Real-time weather is an uncertain forecast, not an automatic instruction to move infrastructure or certify shelter.

Proposed pilot: obtain rights-cleared plans from 30–50 organizers across segments; hold out organizers and drawing styles; include vector PDF, clean scans, DXF and genuinely photographed drawings. Double-annotate classes/footprints/labels; compare manual rebuild versus assisted rebuild. Report detection precision/recall per class and source, OCR error, centre/heading/size error in metres/degrees, route continuity and length error, georeference residual and independent checkpoint error, unresolved fraction, false accepted objects, correction clicks and total organizer minutes. Do not average easy CAD and difficult photos into one sales claim.

Proposed launch gate: assisted completion at least 50% faster than manual in the target segment; high-confidence draft precision ≥95% for core classes; all uncertain scale explicitly reviewed; no unknown object silently omitted; every proposal reversible. These are targets, not measured results. Publish the pilot distribution and failure cases before asserting accuracy. Independent field measurements are needed for metre-error claims; a low control-point residual alone does not establish ground truth.

Costs to model: per-page extraction/tile count, vision/OCR tokens, retry rate, human cleanup, asset generation/postprocessing, mapping/terrain/weather licences, storage/CDN and device rendering. Raw model generation can cost cents while reviewed, reusable assets cost much more. Unit economics and Style B success rate are UNVERIFIED until a representative pilot.

## E. Trust boundaries and operating cost

Treat OCR, uploaded labels and imported model metadata as untrusted data, never instructions. Isolate parsers, prohibit arbitrary generated code, preserve immutable originals, encrypt private organizer documents and keep medical/security/service layers out of guest and sponsor views. Separate protected real-world base geometry from event overlays. Every command binds to a scene revision; conflicting edits require revalidation.

Sun calculations require date, timezone, terrain/buildings and reviewed vegetation geometry; shade is a simulation with geometry uncertainty. Show weather provider, location, issue time and forecast validity. Forecasts cannot certify shelter or cause unattended infrastructure relocation.

Illustrative accepted-asset cost, not a measured tariff: five Tripo P1 untextured text attempts at $0.30 = $1.50, plus 20 minutes review at an assumed $60/hour = $20; $21.50 before cleanup, hosting, mapping, weather and failed integrations. Human review may dominate inference cost. Vendor integration rights, end-user asset delivery and regional restrictions need contract confirmation before launch.
