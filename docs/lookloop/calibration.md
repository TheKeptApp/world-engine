# Grader calibration

**Question.** Does the rubric give high scores to the concept images themselves? It should, if reviewers apply GRADING.md as intended.

**Method.**
- `Tools/lookloop/lookloop.sh calibrate` turns each target concept into a neutral, blind view (`cal-NN` in `Tools/lookloop/calibration.json`). Each view carries the metadata of its own preset or fixture (time, weather, camera, sun) and no target panel.
- The concepts are visual-v2 01, 03, 04, 06 and 09; experience-v1 01–11; and regions 01–06.
- Opus reviewers grade each view with the normal procedure.
- `calibrate.py --report <run>` summarises the result.
- `osm-credit-missing` is ignored here, because concept images carry no credit.

## Result

| | Before tuning (6 Oct, run 20261006-063927) | After tuning (run 20261006-064429) |
|---|---|---|
| Mean v2 score | 34.1/50 | **35.2/50** |
| Pass the v2 gate (≥ 40, no §8.3 score < 3, geography ≥ 4, character ≥ 4, no flags) | 1/22 | 1/22 |
| Geography mean | 3.10 | 3.45 |
| Pass the art-direction bar (all ≥ 3) | n/a (folded into the gate) | 11/22 |

| Frame | Concept | /50 before | /50 after | Geography after | Flags after |
|---|---|---|---|---|---|
| cal-01 | 01-autumn-golden-hour.png | 34.4 | 35.6 | 4 | osm-credit-missing |
| cal-02 | 09-data-grounded-street.png | 30.0 | 34.4 | 3 | osm-credit-missing |
| cal-03 | 03-rainy-dusk.png | 32.2 | 36.7 | 4 | osm-credit-missing |
| cal-04 | 04-summer-noon.png | 32.2 | 34.4 | 2 | wrong-sun-bearing |
| cal-05 | 06-aerial-golden-hour.png | 31.2 | 33.8 | 4 | osm-credit-missing |
| cal-06 | 01-clear-golden-hour.png | 32.5 | 35.0 | 2 | wrong-sun-bearing |
| cal-07 | 02-overcast.png | 32.5 | 35.0 | 4 | – |
| cal-08 | 03-light-rain.png | 33.8 | 35.0 | 4 | – |
| cal-09 | 04-thunderstorm.png | 35.0 | 36.3 | 4 | – |
| cal-10 | 05-fog.png | 37.5 | 35.0 | 4 | – |
| cal-11 | 06-wildfire-smoke.png | 33.8 | 35.0 | 3 | – |
| cal-12 | 07-falling-snow.png | 36.3 | 40.0 | 4 | – |
| cal-13 | 08-morning-after-snow.png | 33.8 | 32.5 | 4 | – |
| cal-14 | 09-clear-night.png | 36.3 | 36.3 | 3 | – |
| cal-15 | 10-aerial-rain.png | 32.5 | 33.8 | 4 | – |
| cal-16 | 11-aerial-snow-cover.png | 36.3 | 36.3 | 3 | – |
| cal-17 | 01-northshore-golden.png | 32.5 | 30.0 | 2 | wrong-sun-bearing |
| cal-18 | 02-northshore-rain.png | 33.8 | 33.8 | 4 | – |
| cal-19 | 03-northshore-fall.png | 35.0 | 36.2 | 4 | – |
| cal-20 | 04-northshore-snow.png | 36.3 | 38.8 | 4 | – |
| cal-21 | 05-chicago-three-flat.png | 31.3 | 31.3 | 2 | wrong-sun-bearing |
| cal-22 | 06-chicago-alley-snow.png | 40.0 | 38.8 | 4 | – |

## What changed in GRADING.md and grade.py

1. **Reference column restored.**
   - v2 §8.3 lists reference images for each criterion's 5 anchor, but GRADING.md had dropped that column.
   - It is back, verbatim, with a rule: a frame at the references' quality scores 4–5 on that criterion. 3 means clearly below the references but at the 3 anchor.
   - The references' documented limitations are still scored as faults wherever they appear: the enlarged dog, oversized sun disk, invented parcels, misplaced Moon and wrong shadow bearings.
2. **Geography guide.**
   - Reviewers had capped geography at 3 whenever they could not verify the map from pixels. That happened on every overcast, fog, night and aerial frame.
   - The rule is now:
     - **5:** bearing checked and layout clearly matches.
     - **4:** nothing visible contradicts the camera, sun or known layout.
     - **3:** something is doubtful.
     - **2 or below:** a visible contradiction.
   - "Can't verify" alone is never below 4.
3. **Gate restored to v2's own.**
   - "No score below 3" applies to the §8.3 criteria only.
   - The owner's three art-direction criteria now have their own bar (`adPass`: all ≥ 3), reported beside the gate.
   - Before, a 2 on "rich ground" failed the v2 gate. The concepts themselves average 2.8 on rich ground, so the owner's richness rule asks for more than the targets show. That is intended, and it stays visible in `adPass`.
4. **Half-up rounding** for /50. Python's `round(36.25, 1)` gave 36.2, where reviewers computed 36.3.

## Conclusion

The tuning removed real grader artefacts: the missing references, the "can't verify" cap and the art-direction criteria leaking into the v2 gate. Concept art still scores **about 35/50, not 40+**. Every remaining deduction is a fault visible in the concepts by v2's own anchors:

- identical sphere-cluster crowns (silhouettes 3.4)
- flat single-tone lawns with no leaf litter (ground 3.1)
- the 40 % dog (character 2.5)
- wrong shadow bearings in five concepts
- invented parcels with no garages or driveways (houses 3.5)

I did not loosen the anchors further. That would make the gate dishonest.

Every loop summary now reports **concept parity**: the view's /50 as a percentage of its target concept's calibrated /50 (from `calibration-scores.json`). Read the two numbers together:

- **v2 /50** is the absolute spec gate.
- **Parity** shows how close the render is to the art it is chasing.

**Owner decision (6 Oct 2026).**
- The gate is concept parity ≥ 100 % plus v2's per-criterion floors.
- 40/50 stays a long-term goal.
- Milestones for the mean parity: ≥ 85 % at the end of 5A's wrap, ≥ 100 % by the end of 5B.

Re-run calibration (`lookloop.sh calibrate`, then 22 Opus reviewers) after any change to GRADING.md that affects scoring, because parity depends on these concept scores.
