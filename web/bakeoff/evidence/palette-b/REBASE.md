# Palette B rebase — 9 October 2026

## Approved control gate

R's coordinator decision: the world region below the top 32 credit rows must be exact max/mean **0/0** against the c8c361d controls. Credits rows 0–31 are excluded from that comparison and documented, not removed from the images. The four fresh controls in `rebase-controls/{sloans-absent,sloans-off,lakeview-absent,lakeview-off}` are the baseline for post-rebase checks; paths and SHA-256 hashes are recorded in manifest.json and rebase-validation.json. These supersede the earlier pending-gate status.

All four pass: world max/mean 0/0, no differing channels. Absent/off are PNG-byte-identical to each other for both scenes. They are not full-PNG-identical to the historical controls. The only historical difference is row y=27, x=8..996, 2,967 RGB channels. Whole-image maximum is 80/255 (Sloan 150 m) and 59/255 (Lakeview 600 m); normalized means are 0.00030827642112187626 and 0.0003507248303568628. These whole-image statistics are diagnostic, not the approved gate.

## Credits cause investigation

The cause is **not established**. Both capture reports name Chrome 155.0.8059.39; renderer, HTML, CSS, fixture and camera inputs match. `web/bakeoff/style.css` gives the credits 9 px text, inherited 1.5 line height, 3 px vertical padding and top 8 px: the expected bottom edge is 8 + 9×1.5 + 6 = 27.5 px. The differing row aligns exactly with this fractional overlay edge; unchanged glyph pixels and a full-width edge difference support an overlay rasterization hypothesis, not a demonstrated font or browser-version change. Prior computed-font, device-scale and raster-backend snapshots are insufficient to isolate the cause. No CSS or image editing conceals the difference; required credits remain visible.

## Rebase and evidence reuse

Main advanced from af49fd6 to 69f7141. Kept main's capture tooling (existingExports, screen probes, resolved-pose checks, Wilmette/Lakeview ladders, MIME support, shutdown, watchdog and lock handling) and re-applied only palette query/metadata/filename plumbing and the Lakeview-150 alias. The sole latest conflict was the option list; both main's screen option and paletteB were retained. Main's spatialCells opt-in entry stays intact; absent that flag it still loads the same main.js. No palette-table, surface-role, grade, light, geometry or shadow changes.

Read-only audit verifies renderer hashes, default entry after excluding main's explicit opt-in routing, fixture and camera equality, and four baseline PNG hashes. Latest tooling adds read-only pose checks/contract hashing; screen probes are inactive and the extra-export loop is not used for these views. Thus the captured render inputs are unchanged: reuse the original 34 captures and their eligible-pixel measurements, plus the four approved fresh baselines; no new captures or scores. The earlier queued refresh was cancelled before it produced frames.

Tests: palette/policy/atmosphere/sky/overnight/foliage/crown arithmetic, original 34-frame evidence, capture-tooling and scene-budget qualification tests. The gate audit now asserts both exact world maximum and mean, plus absent/off PNG hashes. See rebase-validation.json and rebase-controls/comparison.json.

## Ledger text for A3

Palette B lot/tableA ready for scoring, default OFF; R-approved world gate passed 0/0, credits strip excluded, four fresh controls designated baseline. Surface-role rows remain deferred. No scores claimed. Used: palette-diagnosis §§3–4 and R's approved exact-world gate. Mock: c8c361d controls. Deviation: historical credits row 27 differs; cause unestablished.

Final merge base advanced again to 0ae426c during commit-message evidence checks. Rebase retained those main changes; the palette renderer and capture files are byte-identical to the tested 69f7141-based result. The read-only source/fixture/camera/control-hash audit passed again.
