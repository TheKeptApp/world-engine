# Repo size report (P3, 2026-10-06)

| What | Size |
|---|---|
| `.git` (whole repo, all history) | 607 MB on disk; 750 MB of unique blobs uncompressed |
| `docs/proposals/` working tree | 328 MB (PNG files 200 MB; two ZIPs 69 MB) |
| History by area | proposals 327 MB · Data 148 MB · everything else 275 MB, of which `docs/lookloop` 103 MB |

Largest proposal folders: postcards-widgets-v1 95 MB (one SVG is 9 MB), visual-v2 85 MB (two review ZIPs of 34 and 35 MB duplicate its own images), look-fix-v1 38 MB, then 12–19 MB each for visual-v1, regions-chicagoland-miami, experience-v1, ground-v1, live-world-v1 and vegetation-v1.

**The design image packs are already past the ~100 MB mark (about 200 MB of PNG plus 69 MB of ZIP).** Every new pack adds 12–20 MB. Proposal (no history rewrite):

1. Set up Git LFS for `docs/proposals/**/*.png`, `*.zip` and large `*.svg` from now on (`.gitattributes` only). Existing history stays as it is; new packs go to LFS. Needs `git lfs install` on each machine that clones, and GitHub LFS storage (free tier 1 GB storage, 1 GB/month bandwidth; packs would use roughly 20 MB per pack).
2. Optionally drop the two visual-v2 review ZIPs from the working tree in a normal commit (they duplicate files already in the pack); history keeps them.
3. Look loop (my lane): each published run commits about 9 MB of frames and contact sheets in `docs/lookloop/latest/`, so history has grown by 103 MB today. I propose committing only the scoreboard, summary, regressions and grades JSON, and keeping frames and sheets in `.build/` (or in LFS with the packs). The daily before/after PNG (≈1 MB) stays in git.

Rewriting history to shrink `.git` (git filter-repo / lfs migrate) would need every worktree and session re-cloned; not proposed.

## 20 MB commit guard

From now on P3 runs `Tools/lookloop/commit_size.sh` before every push; it lists any commit that adds more than 20 MB of new or changed files and P3 reports it before pushing. Run on history: 11 commits are over 20 MB, the largest 104 MB (first proposals), 95 MB (postcards-widgets-v1) and 62 MB (5A device logs). Today's `bd24937` (ground-v1 + live-world-v1 packs, 32 MB) was over the limit and went out before this guard existed.

## Owner decision (2026-10-06)

No Git LFS. Design-pack images are gitignored from now on and stay local; README, JSON and prompts are committed; the two visual-v2 review ZIPs are removed from the current files; look-loop frames and sheets are local-only. No history rewrite. See `docs/decisions/owner-log.md`.
