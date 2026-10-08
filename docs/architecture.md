# WorldEngine architecture

8 Oct 2026 · Map only · Summary of existing contracts, not a new capability claim.

```text
Authorized, licensed sources → normalized area data → WorldGen / WorldBuild
                                                       ├→ RealityKit (in-process)
                                                       └→ WorldPackage → web renderer
```

**Data is evidence; generators decide inferred detail; renderers display it.** The shared contract is [package-format.md](package-format.md). RealityKit builds through WorldBuild in-process; the other renderer path loads the exported package. The isolated A2 bake-off contains experiments beyond the production package consumer, so its presence on main does not establish production parity.

| Layer | Existing files / contract | Owner and boundary |
|---|---|---|
| Source selection and readiness | [A5 country-readiness-v1](research/country-readiness-v1.md), [licensing record](data-licensing.md), source manifests/notices | A5 supplies research; A1 owns data intake/source QA. Named-source ratings do not authorize an entire country or prove coverage. |
| Area data and adapters | `Tools/regionkit/`, `Data/areas/`, `Sources/WorldMap/`, `Sources/WorldGeo/`; [A1 tracker](tracking/a1-data.md) | A1 (P1 area): approved bounds, licence/source dates, coordinates/datums, observed height/roof/terrain sidecars and quality reports. Nulls and inferred values remain distinguishable. Data delivery does not prove renderer consumption. |
| Generation | `Sources/WorldGen/`, regional profiles, WorldBuild | P2 owns buildings, yards and vegetation generators; 5A owns shared look/light profiles and renderer-facing look wiring. Actual map tags override regional defaults; inferred detail is deterministic. No hand-tuned building or camera exceptions. |
| Package/export | `Sources/WorldPackage/`, `Sources/worldbake/`, `scripts/export-package.sh`; [format](package-format.md) | A1/P1 owns package/export code under the current lane map; P2/5A own the generated content/look semantics. Package metadata carries sources, recipe, hashes, credits and data licence. Consumers must respect those decisions rather than independently reinvent roofs, placement or seeds. |
| Rendering | `Sources/WorldEngine/`, `Sources/WorldEnvironment/`, `Sources/LiveSky/`; `web/src/`; `web/bakeoff/` | 5A owns iOS rendering, sky/weather and iOS water. A2 owns the experimental web bake-off only, including water there; this does not assign A2 the whole production web viewer. Check ownership before production-viewer changes. Host apps own app logic and UI; engine content is generic. |
| Verification and records | `Tools/lookloop/`, `scripts/`, [GRADING](lookloop/GRADING.md), [handoffs](tracking/handoffs.md) | A3 owns current look scoring, filing and trackers; P3 is paused. No A7 scripts ownership transfer is recorded without R's explicit “yes A7”. Existing script ownership is unchanged. |

**Hold-outs apply at both boundaries.** A1 runs the same pipeline/configuration method across areas and reports source age, coverage, missingness and quality; a new source adapter must be verified, not presumed portable. A3 compares frozen Sloan's and untuned hold-outs with the same renderer, camera, weather/date and rubric. Lakeview and Wilmette have iOS baseline evidence; web comparisons currently use Sloan's/Lakeview. Additional Denver/Greenville views require capture-ready inputs and frozen cameras; data presence alone is insufficient. See [paired tracker](tracking/look-gate.md).

Report each before/after score separately. Reject-flag a Sloan's gain paired with a hold-out loss; missing evidence is pending, never pass. The full look gate remains all four heroes ≥4/5 and every aspect ≥3, with the existing confirmation requirement. Web/iOS baselines stay separate; changed fixtures limit causal comparisons. Use the [weekend scoring procedure](tracking/weekend-brief.md), and its source/unit checks before porting any value. No automatic merges or unattended scoring.
