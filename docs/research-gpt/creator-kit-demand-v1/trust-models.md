# Trust models and the WorldEngine two-layer design
Research checked 2026-10-07. Platform practices below are documented; WorldEngine controls are recommendations, not implemented features or evidence of effectiveness.

## What comparable platforms actually do

| Platform | Documented control | Useful lesson | Limitation |
|---|---|---|---|
| OpenStreetMap | Community review, discussion and changeset reverts; serious vandalism escalates to the Data Working Group and account blocks. | Preserve provenance/history and a human escalation path. | Open editing is not universal prepublication verification; rollback can conflict with later edits. |
| Waze | Editor ranks, geographic editing areas and object locks; some place changes become review requests. | Limit authority by object and role; protect critical geography. | Rules vary by region. The US documentation explicitly says automatic traffic locks are disabled there; do not assume they operate everywhere. |
| Google Maps | Suggested edits pass through moderation with pending/accepted/not-accepted status; fake engagement is prohibited. | Keep submitted corrections distinct from accepted base updates; show status. | Approval is not a survey guarantee; detailed scoring/detection performance is not public in these sources. |
| Wikipedia | Page history, reversion and selective protection; pending changes on protected pages holds certain edits for review. | Publish an accepted revision while edits remain a draft; restrict troubled objects. | Pending review is not enabled for every article, nor a guarantee against plausible misinformation. |
| Matterport | Organization ownership and space-specific view/editor collaborators; controlled transfer between organizations. | Tenant-owned spaces and scoped permissions suit customer overlays. | These are ownership/access controls, not independent verification of depicted conditions. |

Sources: [OSM vandalism](https://wiki.openstreetmap.org/wiki/Vandalism), [rollback conflicts](https://wiki.openstreetmap.org/wiki/Change_rollback), [DWG actual case report](https://osmfoundation.org/wiki/Data_Working_Group/DWG_Activity_Report_Q4_2025), [Waze US restrictions](https://www.waze.com/discuss/t/editing-restrictions/377974), [Waze ranks](https://www.waze.com/discuss/t/your-rank-and-points/377943), [Google edit moderation](https://support.google.com/maps/answer/7055486?hl=en), [fake-engagement policy](https://support.google.com/contributionpolicy/answer/11414422?hl=en), [Wikipedia protection](https://en.wikipedia.org/wiki/Wikipedia:Protection_policy), [Matterport organization/space permissions](https://support.matterport.com/s/article/How-To-Transfer-a-Space-Between-Organizations?language=en_US).

These sources describe mechanisms, not comparable vandalism rates, false-positive rates or proven superiority. A small private editor should borrow scoped authority and revision control before attempting global reputation systems.

## Layer 1: protected, sourced base
Store a versioned base with provider, licence, capture/update date and geometry quality. Customers cannot overwrite shared roads, neighbouring buildings, terrain or trees. “Verified base” should mean the provenance and applicable review are known, not that every feature has been surveyed or is current. Crowdsourced OSM is not automatically verified ground truth.

Provide a separate correction queue: proposed change, supporting evidence, reviewer, disposition and base-release version. A paid customer's request or many votes must not automatically become public geography. Site-specific measured geometry can be attached as a reviewed customer layer without asserting cadastral ownership.

Freeze a published scene against a known base version until changes are reviewed. Notify an owner when a new base invalidates objects, paths or shadow assumptions; preserve the old published snapshot while they resolve it.

## Layer 2: private customer overlays
Use separate tenant storage and permissions for routes, fields, tents, signs, staging, planned buildings and scenarios. The public renderer combines the approved base version with an approved overlay revision. Hide/removal of a base object for a planning scenario must be a visibly labeled scenario override, never an alteration to the public base.

Roles: owner/admin invites and manages rights; editor makes private changes; publisher approves the public revision; viewer reads only. One small business may assign editor and publisher to the same account, but publishing remains explicit. An organization-domain check or authorization evidence verifies publishing authority, not land ownership or the truth of every claim.

Drafts are authenticated and private by default. An unlisted URL is not adequate protection for staff, medical, construction or security layers. Enforce server-side tenant authorization, revoke shared access, and exclude private data entirely from public downloads and embeds. Avoid gathering visitor location histories in V1; adding GPS later needs separate consent and retention design.

## Publication and correction workflow
1. Select a place and a licensed base; show source/date/quality.
2. Add objects and routes from a curated, dimensioned Style B kit. Require object status: existing, temporary/event, proposed or illustrative.
3. Add validity dates, a plain-language owner statement and last-reviewed time. Enter operational status manually; forecast rain does not automatically mean a farm path is closed.
4. Preview the exact public export, including text/2D fallback and layer visibility. Publisher approves a revision.
5. Serve that immutable revision; new edits stay private until republished. Support share-link revocation, edition expiry and rollback to a previous accepted revision.
6. Viewers submit issue reports. Prioritize false closures, unsafe access claims, privacy leaks and impersonation; contact the publisher or quarantine the affected public layer. Retain evidence and offer an appeal. No public direct editing at launch.
7. Clone a previous event/season into a private draft, then recheck dates, routes, accessibility and weather modes before publishing.

Technical controls: allowlisted assets and bounded geometry; sanitize labels/URLs and uploads; no arbitrary customer scripts in public scenes; rate limits on account creation, publishing and reports; audit records without publicly exposing staff personal data. Detect impossible scales or out-of-site objects as prompts for review, not proof of malicious intent. Add public asset uploads or community editing only after moderation capacity exists.

## Segment-specific truth boundaries

| Segment | Customer may publish | Required distinction |
|---|---|---|
| Races | Organizer-approved course/village/parking | Course visualization versus certified measured route; public spectators versus private crews; edition validity. |
| Venues | Venue-approved layout and rain-plan variant | Planned tent/table versus existing infrastructure; entered dimensions and accessibility review; not code approval. |
| Construction | Private scenario or approved neighbourhood notice | Existing versus future site; approved traffic plan versus illustrative diversion; no clearance or crane-safety certification. |
| Farms | Seasonal attractions and confirmed open/closed areas | Operator confirmation versus estimated mud/wetness; private staff areas; field boundary versus permission to enter. |
| Real estate | Rights-cleared exterior/amenity companion | Existing versus proposed amenity; no deceptive removal of inconvenient surroundings; branded/unbranded listing requirements. |
| Institutions | Staff-approved visitor/event overlay | Last-reviewed accessible route; public visitor versus security layers; link to official closure/status information. |

Precise sun position does not make an approximate shadow accurate: missing roof/tree geometry and seasons matter. Show “simulated shadow” and geometry quality. Separate observed weather, forecast and manually chosen illustrative weather with source and issue time. Do not dress future event weather outside the forecast horizon as a forecast. Operational closures come from the accountable organization.

## Data rights are part of trust
[OSM's licence page](https://www.openstreetmap.org/copyright) requires attribution and explains ODbL obligations for adapted data. Whether a combined base/overlay is a derivative database, collective database or produced work needs review of the actual implementation; “private overlays” alone does not settle licensing. The public OSM tile/API services are not an unlimited commercial hosting entitlement.

[Google Maps end-user terms](https://www.google.com/help/terms_maps/) restrict copying, mass downloading and repurposing map content. Using a Google product today does not authorize extracting its buildings, imagery or textures into WorldEngine. Licensed developer APIs have their own terms; review the specific service rather than treating these end-user terms as the complete API contract.

[CRMLS's 2026 media FAQ](https://kb.crmls.org/wp-content/uploads/2019/04/2026_Photographs_and_Media_FAQs.pdf) addresses display/reproduction rights and unbranded media. Its indexed primary text was available but direct PDF retrieval failed: reconfirm local rules before integration. [Zillow's FAQ](https://www.zillow.com/3d-home/faq/) also prohibits concealing material property features with blur. An illustration is not permission to misrepresent actual conditions.
