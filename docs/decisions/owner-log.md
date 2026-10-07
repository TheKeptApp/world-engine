# Owner decision log

The single list of R's decisions, newest first, one line each: date, decision, where it is applied. Maintained by P3; every owner decision passed to P3 is added here and mentioned in P3's next report. Pack-specific decisions are also cross-listed in `docs/design-registry.md`.

## 2026-10-06

- **Candidate NASA layers for later:** VIIRS land surface phenology (real leaf-out and fall-colour timing), NSIDC daily snow cover, NASADEM global elevation, GPM IMERG rainfall. Applied: not yet (candidates).
- **Suomi NPP delivery ends 2 Nov 2026:** Black Marble night lights use the existing archive years; future night lights come from the NOAA-20/21 equivalents. Applied: night-lights data plan.
- **Earthdata access:** R's NASA account (worldengine) is set up; LAADS and GES DISC are approved; the token is stored in the cloud Default environment as `EARTHDATA_TOKEN` (expires Dec 2026; the value is never written to the repo). Applied: cloud environment.
- **Design images backed up to iCloud** (`WorldEngine-Design-Backup/proposals/`), copy only, never delete; repeated whenever a pack lands; look-loop frames skipped. Applied: `Tools/lookloop/backup_design_images.sh`; registry.
- **Every lane:** no logs or images over 1 MB committed without a stated reason; device logs stay local. Applied: README "Contributing notes"; `.gitignore`; L1 handoff; messaged 5A, P2, P1.
- **Look loop commits** only the scoreboard, summary, regressions, grades and the daily before/after sheet; frames and contact sheets stay local. Applied: `.gitignore`; look-loop docs.
- **Duplicate review ZIPs removed** from visual-v2 (ordinary commit; history keeps them). Applied: `docs/proposals/visual-v2/`.
- **No Git LFS.** Design-pack images (PNG, JPG, ZIP, SVG over 1 MB) are not committed from now on and stay in R's local checkout; README, JSON and prompts stay committed; no history rewrite. Applied: `.gitignore`; `docs/repo-size.md`.
- **Repo size guard:** flag any single commit over 20 MB before pushing. Applied: `Tools/lookloop/commit_size.sh`, `docs/repo-size.md`.
- **Neighborhood paused** for cloud credit; resumes when the v2 export lands. Applied: neighborhood-jobs repo (`docs/handoff/nj-f1-paused-for-credit.md` there); registry external row.
- **Lock priority** 5A (P0) > P2 > P3 > P1; FoodZen paused. Applied: `~/.agent-heavy-lock` turn-taking; `docs/lookloop/README.md`.
- **Gate trigger:** a routine Sonnet loop at ≥ 92 % parity (85 % + measured 7-point offset) triggers the full Opus gate; milestones are read only from Opus gate runs. Applied: `docs/lookloop/README.md`, `scoreboard.md`, `/lookloop` skill.
- **Stable IDs and provenance:** stable IDs (GERS + OSM) and observed / inferred / simulated labels on all exported data. Applied: export and live-world contracts (L1, P1).
- **Layer separation:** OSM-derived and independent layers kept separate; roof and canopy regrid before first distribution (pre-distribution checklist). Applied: data pipeline (P1); pre-distribution checklist.
- **Satellite elements** reach phones via our relay cache, never from CelesTrak directly. Applied: live-world L1 relay.
- **Live ADS-B not built;** ambient planes are labelled illustrative. Applied: live-world L1 layer 4 (simulated ambient planes).
- **Live world lane (L1) runs in the cloud;** Python is the reference and relay; sky and satellite maths port to Swift and run on the phone. Applied: L1 lane; live-world-v1.
- **No dedicated Mac app;** three.js becomes the computer/web renderer after the look gate; look values live in shared spec files (look as data). Applied: renderer plan; spec files.
- **Shadows:** blob shadows beyond the 60 m shadow range. Applied: 5A shadows.
- **Priority:** stop lawn micro-detail passes; next is trees → shadows → rain. Applied: P2 (trees, hedges), 5A (shadows, rain).
- **Lawn contrast may exceed look-fix §1.1** (owner override). Applied: P2 ground pass 2 (`ec7a62a`); registry look-fix-v1 row.
- **Style target B, rich stylized;** push toward photoreal only in colour, light and weather. Applied: `docs/decisions/style-target.md`; GRADING.md §S; anchors regions 03/04/06.
