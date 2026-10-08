# Mock exceptions

Purpose: the engine must match every R-approved mock value (`Resources/look/mock-values.json`, mapped in `Tools/lookloop/mock-mapping.json`). A deliberate departure is allowed only when it is listed here **and** its Status says "R approved". Rows without R approval do not count; `Tools/lookloop/conformance.py` still fails them.

Columns: Mock key (as in mock-values.json, or `<pack>/<name>` for a non-approved pack) | Engine value | Reason | R approval date | Status

| Mock key | Engine value | Reason | R approval date | Status |
|---|---|---|---|---|
| rain-v1/wetPathDarkening | `look.json` wetPaving.darkenScale 3.8 (about 40 % on concrete/asphalt in steady rain) vs rain-v1's about 10 % | Owner's phone check: wet paths unreadable at the pack value until 5A's sheen/reflection lands | 2026-10-07 | REMOVED 2026-10-07 (5A wet surfaces: rain-v1 darkening once, patchy sheen; R's phone note: darkening at most 12 %, once) |
