# Data licensing, credits and the ODbL offer

> **Not legal advice.** Engineering plan for the owner decisions of 2026-10-06 (6a–6f, listed in `docs/research/licensing.md` §13). Background, sources and lawyer questions: `docs/research/licensing.md`.

## 1. What is decided

- **The world package is an ODbL Derivative Database (6a).** Its data files (`world.json`, `chunks/*/scene.json`, chunk GLBs, `instances.json`, `clutter-tufts.bin`, `collision.json`, `environment.json`) are licensed under ODbL 1.0. Every package carries `LICENSE-DATA.md` (`docs/package-format.md`, Licensing).
- **The engine provides the credits; host apps must show them (6b).** Data: `Sources/WorldGen/Profiles/credits.json` (model and merge: `Sources/WorldGen/Credits.swift`). UI: `WorldCreditsView` and `WorldCreditsButton` (`Sources/WorldEngine/WorldCreditsView.swift`).
- **The OSM credit is always visible, and burned into every export (6c).** `WorldAttributionView` stays on screen, never collapsed. The (i) `WorldCreditsButton` adds the licence information, as the OSMF attribution guideline describes for interactive maps. Every exported image passes through `CreditBurnIn` / `WorldCredits.burnIn(...)`. There are no credit-free exports.
- **Fab (6e).** Personal tier for now. Fab assets go only inside app bundles (compiled, not extractable), never into world packages, the public data download or white-label deliverables. The Fab EULA §6(a) question stays with the lawyer.

## 2. The ODbL offer (§4.6): what we will publish

ODbL §4.6 requires anyone who publicly uses a Derivative Database, or a Produced Work made from one (every frame on screen, postcard or video), to offer recipients the database, or the alterations and method, as a free machine-readable download.

**What.** For each published area and package version:
- the package's **data part**: exactly the ODbL file set above, plus `LICENSE-DATA.md`, as one archive;
- the **unmodified source extracts** the package was built from (`Data/areas/<area>/osm.json`, `manifest.json`, `NOTICE.md`, `osm.overpassql`), so the data timestamp and hash in the notice can be checked.

We offer the derivative database itself (§4.6(a)), not the method (§4.6(b)), so the generator code never has to be published. Only if counsel confirms that our pipeline is a trivial transformation (lawyer Q2) could the offer shrink to the extracts plus the exact build method (generator version, profile, recipe), which `world.json` already records.

**Where.** A static download page, URL **to be decided; no hosting yet**. Proposed shape: one immutable archive per area and version (`<base>/<area-id>/<generator-version>/world-data.zip`) and an index page listing each archive with its licence and notice. Free, no account, no terms beyond the ODbL, at least as easy to reach as the copy inside the app, so it also serves as the parallel unrestricted copy (§4.7). Archives stay up for as long as any app version, web build or shared image that uses them is in circulation.

**How the credits link to it.** One URL, set in one place: the `url` of the `odbl-offer` entry in `credits.json` (it is a placeholder today, marked `ODBL_OFFER_URL_PENDING`). Once set:
- `WorldCreditsView` shows it as "World data download" (the button sheet and every host credits screen);
- the exporter writes it into `LICENSE-DATA.md` ("Public download") and `world.json` (`dataLicense.offer`);
- share pages for postcards and video should carry the same link next to the burned-in credit (host work);
- the web renderer should get a credits link to it as well. Today its OSM credit links to openstreetmap.org/copyright (quick fix 1).

**What stays proprietary** (not ODbL, never in the download):
- engine, generator and renderer code, shaders, tools (ODbL §2.3(a));
- WorldEngine content files: `palettes.json`, `materials.json`, `profiles/*.json`, prototype meshes, `boundary.glb`, sky images (independent contents, §2.4; licensed separately by the publisher);
- host app UI and host data, including per-building user overrides, which are never merged into published data (licensing O11);
- Fab and other store-licensed assets (6e).

The generated per-building choices in `scene.json` (house type, colours, roof shape) *are* part of the Derivative Database, so anyone may reuse them under the ODbL.

## 3. Release gate

The offer must be live **before any public release**: App Store, public web, or delivery to any third party. Before release:
1. `CreditsCatalog.bundled().placeholders` is empty: the offer URL is set (the star catalog credit is filled in since the Yale Bright Star Catalogue replaced HYG).
2. The download page serves the data part of every package version that ships.
3. The host app shows `WorldCreditsView` (credits screen or `WorldCreditsButton`), and keeps `WorldAttributionView` visible whenever the world is on screen.
4. Every export path (postcards, snapshots, share images, widget images, video) goes through the burn-in helper.
5. The lawyer questions on the offer (Q1–Q3) and on widgets (Q4) are answered.

## 4. Credits data

`credits.json` holds the static engine credits, each with the surfaces it applies to (`app`, `web`, `package`, `image`), a `condition` (`always`, `naipDerivedValues`, `hostSupplied`) and `burnIn`:

| Entry | Applies to | Notes |
|---|---|---|
| OpenStreetMap | all surfaces, burned in | "© OpenStreetMap contributors", link to /copyright, "available under the Open Database License" |
| ODbL offer | app, web, package | Placeholder until the download URL exists |
| Star catalog | app, web | "Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren 1991), public domain." (courtesy; IAU star names credited in STARS-NOTICE.md) |
| NAIP | app, web, package | Only when NAIP-derived values are used; "NAIP imagery provided by USDA Farm Service Agency" |
| Weather provider | app, web, image | Host-supplied: filled from the host `WeatherProvider`'s attribution (Apple Weather mark, legal link, modified-data notice) |
| Earcut | app | ISC, full notice text |
| three.js | web | MIT, full notice text |

`CreditsCatalog.merged(sources:weather:naipDerivedValues:surface:)` adds one credit per distinct manifest source (licence plus attribution, de-duplicated; OSM tiles fold into the OSM entry), so any new source, such as Overture buildings, is credited from its own manifest `attribution` and `license` without code changes.
