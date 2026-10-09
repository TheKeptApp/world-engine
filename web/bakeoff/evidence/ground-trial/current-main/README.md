# Rebased validation

**Update, R 9 October:** fresh unmodified current-main OFF is now the approved control, with exact trial OFF equality. c8c361d is historical only. See [adapter/gate update](../REGIONAL-ADAPTER.md); old blocker text below is retained as history.

Parent main `591e4be` changes exporter water selection and tunnel handling. These fresh pairs supersede the pre-rebase captures for review; the historical gate below remains failed. Historical evidence is retained one directory above. No scores.


## Historical control gate — FAILED at 600 m

Fresh Sloan OFF on main parent `591e4be`: 40 and 150 m RGB world-region max/mean 0/0 against c8c361d; 600 m max **25/255**, mean **0.002770388209/255**, **590** changed RGB components below the top 32 credit rows. Fresh/repeat PNGs remain exact. The exporter now emits 451,851/133,103 LOD0/LOD1 chunk triangles versus 451,993/133,245 previously (142 fewer each), following main's A1 water classification correction. No ground-trial code runs in OFF; the old renderer source-identity test is retained. Attribution to water/export changes is consistent with the changed source and package, and a fresh bare-main replay now isolates it: unmodified `591e4be:web/bakeoff/main.js` produces a PNG byte-identical to trial OFF at 600 m using the same current dependencies/export. See `control-replays.json`.

R has been asked whether a fresh current-main 600 m control may replace the historical gate. This is **not** an approved baseline reset. Merge remains blocked under the requested c8c361d exact gate. Other paired captures continue as authorized evidence; no scores or promotion.

## Empty far-LOD correction

West Highland's first ON attempt rejected five legitimate empty `lod1.glb` files as incomplete companion coverage. The files have zero primitives; A4 correctly emits no records for them. The production reader now verifies every package GLB's hash and actual primitive inventory, allowing zero records only when the actual file has zero primitives. Missing records for nonempty files still reject at primitive lookup. The failed attempt remains in `west-highland-on-rejected-empty-lod/`; no package files or exporter rules were changed.


## Tests

Passed under heavy admission (load 3.53) with `WORLDENGINE_ASSETS` set to this checkout: ground-trial, surface-roles (31 positive/rejection cases), palette-B, light-trial, policy, atmosphere, sky-colour, overnight, foliage-exp1 (1,056 identity cases), crown-v2, crown-v3 (228 cases), plus all 16 capture-tooling tests. An earlier broad-suite invocation omitted the asset-root environment variable and stopped in the overnight test; rerunning with its required setting passed. No renderer fix was made for that invocation error.


## Completed captures and costs

Sloan 40/150/600, Lakeview 150, Wilmette 150 and the frozen West Highland view have OFF/ON pairs with independent fresh/repeat launches. Every repeat is PNG-exact, and every main/shadow/post ledger bucket is unchanged within a pair. The post pass is 1 triangle / 1 draw in every view. Existing absolute budget overages are not fixed or promoted by zero added cost.

| View | Main tris/draws OFF=ON | Shadow tris/draws OFF=ON | Added tris/draws (all passes) |
|---|---:|---:|---:|
| sloans-40 | 729,089 / 182 | 69,639 / 62 | 0 / 0 |
| sloans-150 | 791,749 / 251 | 67,961 / 42 | 0 / 0 |
| sloans-600 | 624,291 / 292 | 0 / 0 | 0 / 0 |
| lakeview | 323,901 / 131 | 73,212 / 62 | 0 / 0 |
| wilmette-150 | 624,169 / 246 | 66,723 / 38 | 0 / 0 |
| west-highland | 1,044,327 / 209 | 25,875 / 5 | 0 / 0 |

Lakeview's literal historical 600 m control is also PNG-exact. There is no historical c8c361d matching-pose PNG for Wilmette or West Highland in this batch; do not label those as historical pixel proofs. Their fresh/repeat checks, source default-off identity and paired cost checks passed. Greenville was not captured or substituted.

The final West Highland retry passed after the verified-empty-LOD correction. No camera, lighting, palette, geometry, shadow-selection or date changes were made between regions. Crown, palette and light trials remained OFF in these pairs. `blind/` contains byte-preserving A/B copies; `blind-key.json` is for the coordinator, not a score.
