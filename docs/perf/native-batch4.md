# Native Batch 4: far parent, tree cells, extended area, phone (5A, 10 Oct 2026)

No look values, shader or palette changed. The Simulator captures ran through `scripts/capture-native.sh`, using the Sloan's ladder pose (39.7511195,-105.0389, heading 270, pitch 45, FOV 50, 1005×565, 2026-10-15T20:30Z) on `sloans-lake-extended`, with pinned exposure. Frames and logs stay local (`scratchpad/b4`).

## 1. Native port (default off; part of `-diag roam`, also `-diag farParent` / `-diag treeCells`)

- **Far parent** (`Sources/WorldEngine/FarParent.swift`):
  - **Admission:** A4's rule. The camera's nearest 3D distance to the whole core must be **≥ 400 m**. The core is the union of every chunk's bounds and every building level's bounds, padded by 0.5 m.
  - **What it swaps:** the parent replaces every building cell and tile.
  - **Buildings:** each 800 m tile merges its buildings at `.far` (web's LOD1: the generator's simple detail *is* `.far`) and at `.skyline`. Each tile picks one by `BuildingLOD.forDistance` of its 3D distance.
  - **Ground and water:** stay the unchanged LOD0 chunk tiles, as on web.
  - **Exclusivity:** the parent and its children are never drawn together, and the children return exactly.
  - **Streaming:** wants no near level while the parent is admitted.
- **Shadows (deviation from web):** RealityKit has no shadow-only draw, so the parent casts its own shadow, toggled by reach under shadow cells. On web, the original children keep casting.
- **Variants tried and measured, then dropped:**
  - *Ground merged into the parent:* 600 m main 715k/68, shadow 157k.
  - *`.far` only:* 600 m main 774k/165.
- **Tree cells:** under shadow cells, a tree's casting instances draw from one batch per 200 m cell instead of one whole-world batch, so RealityKit culls them per cell. They use the same instances and transforms. Non-casting twins stay whole, and cells are bypassed while the far parent is admitted.
- **Tests:** `Tests/WorldEngineTests/FarParentTests.swift` covers:
  - default off;
  - the 399.9 / 400.1 m boundary;
  - exclusive parent/children and exact restoration;
  - tree cells hold the same instance counts per kind/slot/casting at 40/150/600 m.

## 2. Extended area vs the floor (Simulator; analytic counts)

Floor: <400k main triangles, ≤150k shadow, ≤100 draws. **roam (B4)** adds the far parent and tree cells to Batch 3's roam (shadow cells + streaming).

| Height | Off | Batch 3 roam | **roam (B4)** | Lever: simple ground outside core (measure only) |
|---|---|---|---|---|
| 40 m | 492,424/62, sh 308,047 | 454,488/69, sh 173,124 | **443,713/82, sh 170,386** | 370,531/82, sh 141,468 |
| 150 m | 512,177/52, sh 271,217 | 479,555/64, sh 162,685 | **476,635/99, sh 149,555** | 389,714/97, sh 117,875 |
| 600 m | 662,146/78, sh 129,017 | 655,020/110, sh 53,433 | **685,619/95, sh 123,336** | 380,029/53, sh 123,236 |

Main-view splits for **roam (B4)**:

| Height | Chunks | Buildings | Foliage | Props |
|---|---|---|---|---|
| 40 m | 197k | 35k | 165k | 41k |
| 600 m | 351k | 97k | 151k | 77k |

In Batch 3 roam at 600 m, buildings were 67k.

**Pixels for roam (B4):**

| Height | vs Batch 3 roam | vs off |
|---|---|---|
| 40 m | **byte-identical** | 2 px, max 2/255 (shadow cells) |
| 150 m | 102 px, max 1/255 (tree-cell draw order) | 157 px, max 2/255 |
| 600 m | 5,065 px (0.89 %), max 129/255, mean 0.076 | 4,959 px (0.87 %), max 129/255, mean 0.076 |

The far parent is not admitted at 40 m or 150 m. At 600 m, A3 paired scoring is needed.

**Still failing:**

- **Main triangles at every height** (444k / 477k / 686k).
- **Shadow at 40 m** (170k).
- **150 m draws** are at 99, on the limit.

**What the far parent does natively:** it cuts 600 m draws (110 → 95) but adds triangles. Its 800 m tiles cull less finely than 100 m cells, which already draw `.skyline` beyond 600 m by 2D distance. It also adds a 70k shadow, because the parent casts. Tree cells move 40/150 m main and shadow by about 10k, at a cost of 13 to 35 draws.

**Cheapest next lever, measured:** set the extended area's focus to the hero core (Sloan's focus box) instead of the whole box (Batch 3's data choice). Chunks and buildings outside the core then generate at simple detail, with no curbs or sidewalk edges. The engine's existing focus rule needs no code change.

- **Effect:** **all three heights pass the floor with roam (B4).**

  | Height | Main | Shadow |
  |---|---|---|
  | 40 m | 371k/82 | 141k |
  | 150 m | 390k/97 | 118k |
  | 600 m | 380k/53 | 123k |

- **Cost:** it changes the look outside the core at every height. Against roam (B4):

  | Height | Pixels changed | Max diff |
  |---|---|---|
  | 40 m | 2.0 % | 212/255 |
  | 150 m | 2.3 % | 213/255 |
  | 600 m | 6.2 % | 187/255 |

  Roaming outside the core keeps far-level buildings. This is R's call, with A3 paired scoring.
- **Remaining margin:** at 150 m, draws are 97 (3 left) and foliage is 156k. The next lever after this is tree LOD distance or crown cost (P2's area).

## 3. Lakeview street-view count reconciled

Both numbers come from the same estimator (`World.estimateView`), at different poses. Native Simulator, this build:

| Count | Source | Pose | Native now |
|---|---|---|---|
| **~414k** (P2) | `ViewDrawBudgetTests` "lakeview-street" (Mac) | **street level**: eye 1.65 m at 41.943402,-87.66075, heading 270, pitch down 3°, vFOV 50 (W Roscoe St, = look-loop `lakeview-street-afternoon` camera `roscoe-street`) | **416,471/93** |
| **295,759** (5A ladder) | Batch 0 ladder, `p2-native-ladder-b0` | **40 m ladder**: 41.945182,-87.66432, 40 m AGL, heading 270, pitch 45, FOV 50 | **295,759/56** (unchanged) |

The street view sees far down the street (chunks 191k, buildings 115k), so it is over the floor. The 40 m ladder pose is not.

## 4. Phone (iPhone 14 Pro)

Reachable ("available (paired)") and the Batch 4 build installed. **Every launch was refused: the phone was locked** ("Unable to launch … because the device was not, or could not be, unlocked"). The confirming Sloan's pan, the extended pan, the extended-pose memory runs and the upload-frame gate were **not run**. The phone numbers from Batches 2 and 3 stay pending. **R: unlock the iPhone and keep it unlocked (Settings → Display & Brightness → Auto-Lock → Never, for the run), then tell 5A.**

## 5. Hold-out areas in WorldLab (P2 request)

`-area west-highland` and `-area greenville-downtown` are bundled (`Apps/WorldLab/project.yml`) and listed in `demo.json`. Areas open only with `-area`, so normal users never see them.

- **Untuned:** focus is each manifest's approved bounds, and the profile and phenology are chosen by location. West Highland resolves to front-range (Denver calendar). Greenville resolves to the default profile, with no regional phenology.
- **Ladder poses:** manifest centre, heading 270, pitch 45, at 40/150/600 m (`a3-capture-contract.json` `pendingHoldouts`).
- **Proof frames:** Simulator, 150 m, `--exposure settled`, 2026-10-15T20:30Z.

| Area | Settled gain | Main | Shadow |
|---|---|---|---|
| West Highland | 1.1249 | 379,037/49 | 187,538 |
| Greenville Downtown | 0.5150 | 185,502/36 | 49,052 |

Both frames render the area (West Highland: dense autumn street grid; Greenville: towers, parking, Reedy River). Sloan's and Lakeview frames and budgets are untouched: data and app config only, no engine change.

## Used / Mock / Deviation

Used: docs/execution/simplified-far-parent.md (Decision; Native plan); docs/perf/native-batch3.md §C; docs/perf/native-batch2.md §2 (shadow cells); `BuildingLOD` (P2); ViewDrawBudgetTests "lakeview-street"; docs/lookloop/captures/p2-native-ladder-b0. Mock: none. No look values changed; the 600 m far-parent frame is look-changing by design and is handed to A3 unscored. Deviation:

- The parent casts its own shadows, because RealityKit has no shadow-only draw.
- Each tile picks `.far` or `.skyline` instead of web's `.far` only.
- Ground is not merged into the parent (both measured worse).
- The far parent raises 600 m triangles natively.
- The floor is still failed without the focus lever.
- Phone runs were not done (phone locked).
