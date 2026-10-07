# Rain pack verification
6 October 2026.

Passed: six generated sheets visually inspected; one edit each on 01/06; final raster dimensions/hashes recorded; three JSON files parse; 25 material-state rows have darkening <=12% and exact multiplier arithmetic; wet suballocation .35 ms and particle suballocation .20 ms reconcile; deterministic SVG has all 25 swatches; local README links resolve.

Phone review is supplied as 390/320 CSS px crops in index.html. The crop scales the original reference, not a real engine render. No calibrated scene-distance/camera, native iPhone screen, animated rain, shader parity, GPU timing, thermal run or participant readability pass is claimed.

Known image exceptions: DOOF label on drying roof swatch; residual microdetail/long streaks in some sheets; near-blanket snow aerial despite generic patchy heading; covered-snow road retained clear as a clearing demo. JSON + README govern implementation. Generated masks do not establish real drainage or plowing history.

Browser review: gallery loaded; width switch verified at exactly 390 and 320 CSS px under a 390px viewport; no observed console warnings/errors. Initial narrow-window padding reduced scene width, then corrected with edge-to-edge mobile panels. Temporary viewport override reset. Local Mac preview serves only this folder on loopback port 8771.
