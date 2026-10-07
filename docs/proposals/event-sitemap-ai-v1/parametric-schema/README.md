# Parametric kit contract · 1.0.0

This is a proposed WorldEngine contract, not a supplier specification. It uses [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/json-schema-core). The schema, example data and runtime checks are local and require no service or repository.

## Start here

- [kit.schema.json](kit.schema.json): self-contained schema, identified by `urn:worldengine:kit-schema:1.0.0`.
- [examples/catalog.json](examples/catalog.json): ten complete part definitions.
- [examples/instances.json](examples/instances.json): ten placed instances, including a synthetic approval history.
- [examples/commands.json](examples/commands.json): typed natural-language proposals.
- [validate.py](validate.py): schema validation plus cross-field rules.
- [validation-report.json](validation-report.json): example and negative-case results.

Each requested part also has a standalone catalogue document: [stage](examples/stage.json), [canopy tent](examples/canopy-tent.json), [water table](examples/water-table.json), [barrier](examples/barrier.json), [finish arch](examples/finish-arch.json), [toilet block](examples/toilet-block.json), [gate](examples/gate.json), [sign](examples/sign.json), [generator](examples/generator.json), [sponsor booth](examples/sponsor-booth.json).

## Three document types

| Document | Purpose | Version pinned |
|---|---|---|
| `catalog` | Family definitions, parameter metadata, presets, envelopes, materials and rendering tiers | Schema, part and deterministic generator |
| `instanceSet` | Placed objects, complete resolved values, scene frame and approval provenance | Schema, part and scene revision |
| `commandSet` | Reversible create/move/rotate/resize/replace/array proposals | Schema, part and expected scene revision |

Closed objects reject accidental extra fields. The ten families have dedicated parameter-value schemas with exact required keys, types, enums and numerical bounds. A complete value set is intentional: resolve defaults before making a preview, and record them as proposed defaults. JSON Schema `default` metadata is not an instruction to silently insert missing values.

The family definition contract describes the supported authoring vocabulary. It is deliberately restricted to these ten v1 families. Adding a family requires a new schema minor version, its value schema, reviewed generator, example and semantic checks. Catalog metadata must agree with that family contract; `validate.py` checks defaults and presets against the corresponding value schema.

## Parameters, presets and suppliers

Numeric parameters record label, unit, minimum/maximum, UI step, default, editability and bound basis. Integer counts stay integers. Discrete construction options are enums; flags are booleans; labels have length limits. UI steps are editing increments, not a rounding requirement: a 3 ft riser stays exactly **0.9144 m** even when the usual control step is 0.01 m.

All ten examples include full planning and supplier-size candidate presets. **Every supplier candidate is unverified and illustrative**; null supplier/SKU/date prevents it being presented as booked or physically certified inventory. Examples include 24×16 ft stage dimensions, 10×10 ft canopy/booth and a 6 ft water table, converted exactly to metres. These are nominal candidates, not asserted manufacturer products. A `supplier_verified` preset requires a real supplier ID, SKU, checked time and linked supplier document; the validator enforces the metadata requirement. Supplier specifications and valid module combinations override planning defaults.

Catalogue ranges are modelling bounds, not building codes, crowd limits, power availability or engineering tolerances. The generator's `ratedPower` is a supplier-stated label placeholder; changing it does not design or certify a generator.

## Geometry and operating envelopes

Part-local axes are **right, forward, up**, with the pivot at the ground-level footprint centre. Scene coordinates are **East, North, Up** in a local ENU frame. Yaw is clockwise from geographic north. A browser renderer using Y-up must explicitly map ENU to its coordinate system; the review prototype uses Three.js `x=east, y=up, z=-north`.

Each example declares footprint, clearance, queue and utility boxes. Envelope offsets identify the box bottom-centre in part-local coordinates; width spans right, depth spans forward, and height extends upward. Dimensions and offsets use a small declarative expression tree: `constant`, `parameter`, `add`, `multiply`. No arbitrary executable strings are accepted. The stage footprint conservatively includes stair run even when stairs are hidden; supplier assembly geometry should replace this deliberately conservative v1 approximation. Utility ports record schematic position/direction and always request supplier confirmation.

The expressions recalculate when parameters change. Their source and basis distinguish proposed working space from supplier requirements. A clearance box is not proof of compliance; queue length is not an attendance capacity. The `blocksPlacement` flag guides collision review, with queues treated as visible advisory envelopes. Actual site keep-outs, service routes and operating requirements must be evaluated against reviewed geometry.

## Style B and detail tiers

Every family has six material slots: structure, fabric, deck, panel, hardware and label. The examples use restrained ivory/forest/slate colours, high roughness, low metalness, no baked lighting and optional albedo-only label textures. Instance overrides must reference a defined slot and approved colour. This is a material contract for the approved Style B system, not evidence that these JSON files alone generate approved meshes.

The three tiers are `footprint`, `balanced` and `close`: 24 / 3,000 / 12,000 maximum triangles per part in the examples, with instancing, shadow/label/small-prop flags and screen-size thresholds. These budgets are proposed engineering targets. The renderer selects the tier based on projected size and device limits; it must preserve the physical dimensions, identity and envelope across tiers. No generated 3D assets or production generator implementations are included in this schema package.

## Placement language

The language model produces a typed intent, then deterministic geometry resolves it:

| Phrase | Representation | Required resolution |
|---|---|---|
| “north side of the field” | `boundary`: polygon ID, compass sector N, inside/on/outside, setback, along-fraction | Geographic north, named reviewed boundary, valid setback |
| “6 m east of the west entrance” | `near_anchor`: named anchor, distance, bearing 90° | One unambiguous entrance and desired facing direction |
| “at mile 2, right side” | `route_chainage`: route/version, 3218.688 m chainage, right offset | Route direction, start point, length and service-side access |
| “along the path” | Route-based array or chainage placement | Which path, side, setback, start/end and spacing |
| “every 50 m” | Array: spacing 50, route/line basis, extents, endpoint policy and max count | Extents and inclusion policy; one reversible array command |
| “face the entrance” | `orientation: face_anchor` | Anchor exists and is current |

“Near” without a distance and “the field” with multiple matches remain `needs_clarification`; record the ambiguities. An explicit proposed distance may be presented for approval. Compass directions are geographic, not camera-relative. Chainage is distance along a versioned route, not a radial distance from the start. The sample barrier array repeats along a chute at 2.4 m; the same contract accepts the 50 m pattern.

An array's line endpoints apply to line basis; route ID/chainage applies to route basis. `include_start` includes the start and excludes the end; `include_both_if_exact` adds the end only when spacing lands exactly on it; `exclude_both` drops both endpoints. A command is a proposal for multiple stable child instance IDs, not a single stretched mesh. Resolve count before applying and reject counts above `maxCount`.

## Provenance and approval

Sources carry ID, kind, URI, optional SHA-256, page/crop, rights status and note. Parameter origins independently distinguish measured, supplier-stated, extracted dimension, human edit and proposed default. A model score is not accuracy: confidence includes calibration status and dataset, with null permitted for unscored design defaults. `aiMade` requires model/task/version and licence provenance; an AI-generated mesh remains flagged after human editing.

Approval events carry actor/role/time, monotonically increasing revision, action, prior event ID, reason, optional bulk-group ID and a digest of the subject being reviewed. The digest is SHA-256 of canonical sorted-key JSON containing `instanceId`, `partId`, `partVersion`, `parameterValues`, and `resolvedTransform`. Hash formatting is defined by `digest()` in the validator; use matching number serialization across implementations. The prototype supplies synthetic actors/history and is not an identity or signing service.

Changing values, family, alignment or transform reopens approval. The latest accepted event must match the current subject digest; a stale accept cannot approve new geometry. Group approval writes one event per item with a shared group ID. History must be append-only in production storage; the validator checks the chain, not tamper-proof signing or user authorization. `system` may propose/reopen but cannot approve on behalf of an organizer.

## Enforcement boundaries

JSON Schema checks shape, version, required fields, scalar types and per-family numerical bounds. The included semantic validator checks dependent dimensions, parameter source references, positive envelope dimensions, preset values, required supplier metadata, palette/tier validity, chainage conversion, bounded array counts, approval chain/digest, duplicate IDs and scene revisions.

A production resolver must additionally load referenced boundaries/routes/anchors and validate route lengths, geometry intersections, referenced route lengths, supplier assembly combinations, forbidden zones, elevation/slope, time/date context and authorization. It must reject stale commands via `expectedSceneRevision`, calculate resolved transforms itself and prevent publication of uncertain alignment or unresolved items. A well-formed JSON document can still describe an impractical or unsafe layout.

Run with Python and `jsonschema>=4.18`:

```sh
python3 validate.py
```

## Versioning and migrations

Schema version, family version, generator version and scene revision are independent. Pin immutable catalogue snapshots in a scene. Patch versions clarify metadata without changing accepted behaviour; minor versions add supported families/options with explicit compatibility handling; major versions change units, coordinate meaning or required structures. The 1.0.0 contract accepts exactly 1.0.0—no implicit forward compatibility. Migrations must be explicit, retain old source/history, preview geometry differences and reopen affected approvals. Supplier updates create new preset/part versions rather than silently changing existing approved events.
