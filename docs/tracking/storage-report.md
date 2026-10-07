# Storage report: "System Data" audit (R, 7 Oct 2026)

Maintained by P3 on R's instruction. Sizes are GB (1024³), measured 7 Oct 2026 14:30–15:30 while three lanes were working, so they drift. Names of other projects are left out of this file on purpose (CLAUDE.md: the repo does not reference other repos); the click-ready list R decides from is in the chat report.

**Disk (Data volume, 460 GB):** 413 GB used and **4.3 GB free** when the deletions started (below the 8 GB floor) → **19.3 GB free** after the SAFE deletions below (≈17.9 GB removed by size; the difference is other lanes writing meanwhile). Time Machine local snapshots: none. Docker, Ollama, Hugging Face and Homebrew: not installed.

**Classes:** SAFE = regenerable cache; NEEDS R = personal files, another project's data, unmerged work, or anything outside the pre-approved list; NEVER = this repo, `docs/proposals` and the mock images, the design backup, locks, system files, session history.

## 1. Everything measured, biggest first

Top-level items do not overlap; "inside" lines are parts of the item above them.

| # | Item | GB | Class | What it is | Done |
|---|---|---:|---|---|---|
| 1 | `~/Library/Developer/CoreSimulator/Devices` | 67.8 | NEEDS R | 18 simulator phones and iPads with their app data: 3 for this project (7.3 GB), 9 for other projects (35.4 GB), 5 plain Apple-named (25.0 GB, owner unclear). None is "unavailable". | none |
| 2 | `~/.codex` | 30.1 | NEEDS R | The Codex app's own history: sessions 20.6, thread history 5.4, generated images 2.8, logs 0.6. | none |
| 3 | `/private/var/folders/…/T` (user temp) | 28.3 | NEEDS R (looks SAFE) | 97 leftover Instruments recording temp files (`instruments*.ktrace`, 0.3–1.1 GB each), all older than 2 hours, none open, no recorder running. Not on the pre-approved list. | none |
| 4 | Other projects' folders in the home folder (7 folders) | 31.1 | NEEDS R | Checkouts of another repo and its side branches. Not read, not touched. | none |
| 5 | `/private/tmp` outside the Claude folder | 37.9 | NEEDS R | Another project's review checkouts (46 folders, 24.3 GB), test-result bundles (`*.xcresult`, 6.7 GB) and 587 smaller entries. | none |
| 6 | This repo, owner checkout (`~/Desktop/world-engine`) excluding nested worktrees | 8.2 | NEVER | `docs` 4.35 (the proposal images), `.build` 2.7, `.git` 0.66. It is on a lane branch with 7 unpushed commits and a build in use. | none |
| 7 | This repo's nested helper and lane worktrees (`.claude/worktrees`) | 23.7 → 20.7 | mixed | 38 worktrees at the start. See section 3. | 3 removed (3.0 GB) |
| 8 | `/Library/Developer/CoreSimulator` | 19.1 | NEVER | The iOS 26.4 simulator runtime (the only one, the newest): 16.1 GB volume plus support files. | none |
| 9 | `/Applications` | 17.1 | NEVER | Installed apps. | none |
| 10 | `~/Library/Developer/Xcode` | 14.4 → 7.5 | mixed | DerivedData 8.6 → 1.75 (SAFE), iOS DeviceSupport 5.5 (the phone's current iOS 26.4.2: kept), Archives 0.15 (NEEDS R), UserData 0.04. | DerivedData 6.9 removed |
| 11 | `~/Library/Application Support/Claude` | 13.3 | NEEDS R | The Claude desktop app: virtual-machine images 8.5, simulator build outputs 3.1, caches 1.3. | none |
| 12 | `/private/tmp/claude-501` | 12.5 → 10.7 | NEEDS R | Running agents' scratch folders (this project's 10 GB includes helper worktrees, see section 3). | 2 scratch worktrees removed (1.9 GB) |
| 13 | `~/Library/Caches` | 12.0 | NEEDS R (one SAFE) | Music-app cache 2.3, Codex 3.7, browser 1.6, app-update installers 1.9, Swift package cache 0.85 (SAFE, left for when the heavy lock is free), the rest small. | none |
| 14 | `~/Desktop` outside this repo | 20.0 | NEEDS R / NEVER | A personal folder 10.2, the ChatGPT drop folder 3.3 (NEVER), other projects' folders and backups ≈6.5. | none |
| 15 | `~/.npm` | 5.9 → 0 | SAFE | npm download cache 4.3 and npx cache 1.6. | **removed** |
| 16 | `~/.claude` | 3.6 | NEVER | Session transcripts, memory and settings (`projects` 3.56). | none |
| 17 | System files: `/Library/Application Support` 3.7, `/private/var/db` 3.5, `/Library/Updates` 2.0, `/private/var/vm` 2.0 | 11.2 | NEVER | macOS itself. | none |
| 18 | `~/Library/Containers` and Group Containers | 2.6 | NEEDS R | Apps' private data; largest is the Xcode device-service cache 1.1. | none |
| 19 | `~/.cache` | 1.8 → 1.6 | mixed | Codex runtimes 1.6 (NEEDS R), firebase 0.13, uv package cache 0.16 (SAFE). | uv removed |
| 20 | `~/Library/Mobile Documents` (iCloud Drive) | 1.3 | NEVER | Includes `WorldEngine-Design-Backup`. | none |
| 21 | `~/Downloads` | 1.3 | NEEDS R | Personal downloads. | none |
| 22 | `~/Library/Logs` | 1.1 | NEEDS R | Simulator logs 0.6, Codex logs 0.3. | none |
| 23 | pip cache | 0.08 | SAFE | Python package download cache. | **removed** |

Time Machine local snapshots, unavailable simulators, simulator runtimes older than the newest, and DeviceSupport older than the phone's iOS: **none exist**, so nothing was deleted under those headings.

## 2. Deleted (SAFE, pre-approved list)

| Item | GB |
|---|---:|
| DerivedData project folders (four projects' build products; the module cache stays until the heavy lock is free) | 6.9 |
| npm download cache and npx cache | 5.9 |
| pip and uv caches | 0.2 |
| Six stale merged worktrees (branch fully in main, clean, unlocked, untouched for over 6 hours, no heavy lock held by their lane) | 4.9 |
| **Total** | **17.9** |

Left for when the heavy lock is free (P2 held it for the whole audit): DerivedData module cache 1.7 GB and the Swift package cache 0.85 GB.

## 3. This repo's worktrees (39 at the start, 63.4 GB listed and 39.7 GB unique; 33 remain)

| Group | Count | GB | Class | Why |
|---|---:|---:|---|---|
| Owner checkout, in use | 1 | 8.2 (without the nested worktrees counted in the rows below) | NEVER | Lane branch with 7 unpushed commits; 5A's build is running there. |
| P3 worktrees, in use | 2 | 3.3 | NEVER | Look loop capture and docs. |
| Uncommitted changes (two P2 worktrees and one older session) | 3 | 3.7 | NEVER | Unsaved work. |
| Locked by a lane (6 merged, 2 unmerged) | 8 | 5.9 | NEVER | Another lane's lock. |
| Merged, clean, unlocked, but touched in the last 6 hours | 3 | 5.0 | left | Probably in use. |
| Unmerged helper checkouts, clean, unlocked | 15 | 6.7 | NEEDS R | Nothing uncommitted. 9 of the 17 unmerged helper checkouts (counting the 2 locked) have no commit that is not already in main by patch; 8 hold commits that exist only in their branch. Removing a folder keeps its branch. |
| An active lane's unmerged scratch branch | 1 | 2.1 | NEEDS R | 5A's. |
| Merged, clean, unlocked and stale | 6 | 4.9 | SAFE | **Removed.** |

## 4. Decisions left for R

See the chat report; in order of size: simulator phones from other projects (35 GB), the Instruments temp files (28 GB), the Codex history (30 GB), another project's review folders in `/private/tmp` (31 GB with test bundles), other projects' checkouts at home (31 GB), old helper worktrees (4–8 GB), the Claude app's VM images (8.5 GB) and app caches (≈10 GB), the personal `Moving` folder (10 GB).
