# Style B calibration v2

packs own content; this sheet owns look

Eight side-by-side sheets compare unchanged source-panel views (left) with Style B calibration edits (right). Sheet 05 contains two comparisons: the existing life pack has separate alley and L-train frames. Mobile layout stacks existing then calibration for legible inspection; downloadable PNG sheets retain the side-by-side format.

All packs inherit values.json sharedLook. Packs retain cameras, geometry, regional albedo colours, actors and weather/time. This pack owns coherent lighting, exposure, saturation, matte material response and distance-based actor detail. Weather/time replaces the clear-day fixture rather than adding another grade. Do not apply exposure or wetness twice.

The approved Bible calibration street is the visual anchor. House-contrast lighting provides the numeric clear-day authoring baseline. Numbers are authoring targets, not sampled pixels or tested renderer parameters. These are generated visual edits: camera composition and content were retained visually, without supplied engine camera matrices. This v2 proposal does not imply new user approval or an engine build.

## Source choices

- Lakeview: districts-chi-den-v1, first panel of its Lakeview street sheet.
- Brooklyn: nyc-hero-v1 brownstone sheet, street-view panel (third).
- Midtown: nyc-hero-v1 canyon sheet, sidewalk panel (first).
- SF: us-metros-wave2-v1/sf-r2/sf-block.png.
- Chicago alley and train: life-kit alley first panel and transit second panel.
- Sloan’s Lake: life-kit Denver moments, third panel.
- New Orleans: wave 3 new-orleans-block-before.png. The paintover PNG was truncated/unreadable (6,144 bytes), so the intact existing block frame is used.
- Miami: weather-moments-v1 Miami board, bottom-left daytime Ocean Drive panel.

source-selection.json records original paths, panel selections and SHA-256 hashes. sources/ contains byte-identical source copies plus browser-displayed panel crops. Crops select existing frames; originals were not retouched. No existing pack or project file was changed. All target frames exclude logos, readable signage, dogs, murals and host-app content.

## Files

index.html: responsive review gallery. sheets/01–08.png: exportable comparison sheets. frames/: calibrated frames. values.json: one inherited look block. prompts.json: imagegen prompts. phone-check/: mobile previews and verification.

Generated using the built-in imagegen tool and the imagegen skill. No git operations.
