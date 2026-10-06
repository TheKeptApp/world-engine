# Live world: renderer-neutral data layers

Data modules for the live world (sky, satellites, transit, planes). They are built in the cloud lane, in
`Tools/livefeeds/` (Python 3 standard library, runs on Linux and macOS, offline unit tests), and each emits
one documented JSON contract that phase 5A renders later. No renderer, engine or app code depends on them yet.

| Layer | Contract | Spec | Code |
|---|---|---|---|
| 1. Sky (stars, Sun, Moon, planets, light pollution) | `worldengine.live.sky/1` | [sky.md](sky.md) | `Tools/livefeeds/livefeeds/sky/` |
| 2. Satellites (positions, passes, visibility) | `worldengine.live.satellites/1` | [satellites.md](satellites.md) | `Tools/livefeeds/livefeeds/sats/` |
| 3. Transit (live vehicles smoothed along route shapes) | relay schema 1 (`live-feeds.md` §8) plus `motion` and `/v1/shapes` | [transit.md](transit.md) | `Tools/livefeeds/livefeeds/transit/`, relay |
| 4. Planes (simulated ambient traffic; live ADS-B evaluated) | `live-feeds.md` §8 schema 1, `live: false`, `basis: "simulated"` | [planes.md](planes.md) | `Tools/livefeeds/livefeeds/planes/` |

## Shared vocabulary (every contract)

**`basis`** labels where a value comes from. Every object that carries numbers has a `basis`, and every number
in that object shares it unless a nested object carries its own.

| `basis` | Meaning | Example |
|---|---|---|
| `observed` | Measured by someone and passed through (possibly reformatted) | A vehicle's GPS fix, a satellite radiance composite |
| `inferred` | Derived from observations or catalogues by a deterministic model | Planet positions, limiting magnitude from radiance |
| `forecast` | A prediction of a future state whose quality decays with time | A satellite pass computed from orbital elements |
| `simulated` | Invented, plausible but not real | Ambient aircraft on approach paths |

**`state`** says whether a layer may be shown as current:

| `state` | Meaning | Renderer rule |
|---|---|---|
| `fresh` | Inputs are inside the layer's freshness limit | Show normally |
| `stale` | Inputs are older than the limit but still useful | Show, visibly marked as not current; never as live |
| `unavailable` | No usable input | Show nothing from this layer (or the layer's documented fallback) |

**`live`** is `true` only for data that reflects the world now (live transit). Computed and simulated layers are
`live: false`. **`attribution`** is a list of `{source, text, url, required}`; entries with `required: true` must be
visible whenever the layer's data is on screen, next to the OpenStreetMap credit. Times are POSIX seconds (UTC),
angles degrees, distances as named in the field (`Km`, `Au`, `M`).
