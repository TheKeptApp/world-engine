# Look loop: regressions

This run (2026-10-06 06:39, engine `651649b`) against the previous published run (2026-10-06 01:02, engine `04d66ad`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 17 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

Caution: graders differ (claude-opus-5-5 then, claude-sonnet-5-5 now). A one-point move can be grader variance; check the two sheets side by side before acting.

**11 regression flag(s) in 9 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | houseVariety | 3 | 2 | Only one near house, a featureless box with no entry detail beyond a small step and shrubs. The yellow blocks on the right are a repeated apartment-like kit. Distant brick and garage forms add little variety and there is |
| [v2-04](sheets/v2-04.jpg) | v2 /50 | 30.0 | 27.8 | At phone size this is a clean but sterile low-poly street: flat green lawns, a boxy dark house and repeated lollipop trees, with the black dog the only well-readable element. The biggest gap is ground and building richne |
| [v2-04](sheets/v2-04.jpg) | softnessAO | 3 | 2 | Dog has a soft contact blob and the shrubs sit on the ground, but the house base is a hard dark band with no eave, porch or step occlusion, and trees and lamp posts have no visible base AO or crown shadows. |
| [v2-04](sheets/v2-04.jpg) | houseVariety | 3 | 2 | Near house is a single large grey box with a big window and no entry or porch visible; the distant buildings are a tan flat-roof block and a small red/garage form, so the mix of old and modern kits is weak. |
| [showcase-02](sheets/showcase-02.jpg) | adRegional | 3 | 2 | Reads as a generic park with autumn deciduous trees and conifers; no bungalow or foursquare houses, no low-profile Front Range cue, and no shoreline character like the target's curved lakeside lawn with shrubs. |
| [showcase-03](sheets/showcase-03.jpg) | softnessAO | 3 | 2 | Trunks and the bench meet the lawn with no contact darkening or base occlusion; trunks look planted on a flat plane. Only the large soft tree shadows on the path give any grounding. |
| [showcase-05](sheets/showcase-05.jpg) | adRegional | 3 | 2 | Generic park: autumn lollipop trees, one spruce and a lake; no bungalow or foursquare cues, no cottonwood character, and no western mountain band, so little says Sloan's Lake or Front Range. |
| [showcase-06](sheets/showcase-06.jpg) | adRegional | 3 | 2 | Autumn gold trees and a conifer give a vague cue, but there are no bungalows or foursquares, and the park reads as a generic lakeside; no regional signature beyond the absent western mountains (correct for ESE). |
| [showcase-10](sheets/showcase-10.jpg) | adRainReadable | 2 | 1 | Nothing reads as rain: no particles, no grey cast, no wet sheen or puddles, and the green and teal are bright and saturated. It looks like a dry bright day. |
| [ordinary-street](sheets/ordinary-street.jpg) | softnessAO | 3 | 2 | Shrubs sit against the wall with slight contact, but the house base is a dark flat band, no eave or porch occlusion, no bevel glints; dog has only a faint blob shadow. |
| [light-rain-street](sheets/light-rain-street.jpg) | characterReadability | 4 | 3 | Black Luna reads clearly against the light grey sidewalk, contact is intact and framing is about 18-20% of height; the coat is a flat black blob with little detail and a grey belly patch. |
