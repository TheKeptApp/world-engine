# Privacy and UX contract

## Non-negotiable architecture

- No background GPS or individual movement recording, even for anti-cheat. Completion is self-reported; optional on-device timer has no coordinates and is discarded after local summary.
- Choose a broad browsing area manually. It is not a claim of residence. No identity-to-area subscription on the server. Public map assets/weather should be fetched through a relay with broad prefetching, short-lived cache and no account identifiers; network logs must not recreate individual browsing routines.
- Home location is unnecessary for v1. If a later local convenience stores it, store locally under device protection, exclude OS/cloud backups, analytics, crash logs, invitation metadata and server requests. Never render a home pin. Device migration must not silently sync it.
- Local progress and saved plans remain on device. No visit times, routes, resident lists, faces, photo uploads, friend dots, last-seen, attendance tracking or proximity alerts. Strip metadata from exports.
- Default contribution sharing is off. The app must work when declined. Proposed opt-in sends only challenge ID and a completion token through an unlinkable relay; no account, device, exact time, GPS, address or persistent identifier. Avoid exposing tokens in logs. Independent token issuer / aggregator roles and non-linkable issuance are required; this is a design requirement, not implemented cryptography.
- Aggregate release proposal: weekly batch; a broad public district; at least 30 distinct contributors; only coarse bands (30–49, 50–99, 100+), with a fixed differentially private release. No filters, drill-down, live counts, overlapping cohort queries or neighbour comparisons. Threshold checks must be private and themselves accounted for; exact unique counts may never be exposed. The epsilon, budget, cohort size, retention and threat model are unverified until specialist review. “30” alone does not establish anonymity.
- Below threshold: “A shared project for this area” with no numeric progress or inference that others were absent. Sparse/rural areas merge or suppress; do not lower the threshold for engagement. Synthetic mock totals are labeled.
- Event interest uses anonymous coarse counts on a fixed release schedule, never a roster or per-person RSVP. Invitation URLs are unguessable, revocable and short-lived; no third-party preview tracking. Recipients may forward them, so the preview contains only a public meeting place. Prototype creates no real invitation or link.
- Public engagement posts are not in scope. Plan choices use constrained options; report/block is available if later user-authored collaboration exists. No covert social-graph or residential identity collection.

## Weather and public-place constraints

Weather source time, forecast horizon and unavailable state must be visible. The app never presents a safe-route score derived from rendered light. Severe-weather or stale-data state offers browse/another-day options without completion penalty. Public-space access and route accessibility are verified separately; no tasks on private property, driveways, roofs or restricted sites. Keep phone interaction to before/after the walk. No speed prizes, night-only goals or urgency.

## Adult-first social design

18+ onboarding declaration; no child/family tracking, school-ground challenges or home-based play. Age assurance, jurisdictional legal obligations and safeguards would require a separate release review. A declaration alone is not robust age verification. Avoid names/avatars on spatial screens; social context lives in aggregate goals or plans. No dogs or host-app content. No push notifications in the pilot.

## Ten-screen narrative

01 Choose a broad area manually; browse-only and sharing-off are clear.
02 Pick a short challenge; show weather source freshness and alternatives.
03 Read the play card; no live self dot or recording; pocket the phone.
04 Record completion locally; aggregate opt-in remains a separate choice.
05 See a delayed synthetic group result with a suppression explanation.
06 Gather: choose a vetted public place; plan is private by default.
07 Arrange a few Builder objects; keep a clear access corridor.
08 Compare time/weather scenarios; unavailable forecast fallback.
09 Review the conceptual layout and unresolved permissions.
10 Preview a public-place invitation; it is still a draft, with no real share action.

UI feedback is explicit: local save, draft saved, unavailable weather and invitation preview. Navigation never requests location permission. Buttons in the static mock affect only local demonstration state; no telemetry, network writes or social messages.
