# Status

**R approved – 2026-10-08.** Approved for the Builder phase.

**Owner lane:** Builder. **Phase:** Builder phase (after the engine look gate).

ChatGPT research and rules for how Builder AI should propose a race village: 29 rules, three size profiles (500, 2,000 and 10,000 runners), checklists for seven race types, and six concept images for Denver, Chicago and Greenville SC. Every layout stays an unapproved proposal.

Binding rules from the pack:
- Safety and permission before appearance. Builder AI may propose a village and course, never authorize one. Unknown usable width, jurisdiction, site capacity, accessible route, emergency access, medical plan or weather policy block approval, and the plan stays pending. An image can never approve anything.
- Precedence: permit conditions and local law, then approved medical, fire, crowd and traffic plans, then sanction rules, then verified scoped guidance, then pack assumptions. Every rule keeps its status (V verified, A assumption, U unverified), scope and source. Unknown numbers stay null, never guessed.
- Reserve before decorating: medical and evacuation, the finish runoff (first 30 m kept clear) and start holding come before toilets, registration, gear, food, expo and stage. Use full footprints including ballast, guy lines and queues. Never invent paths or pavement; a site that cannot hold the reservations is reduced or relocated.
- Starting counts are assumptions, not capacity: toilets = runners / 50 rounded up, accessible units 5% rounded up per cluster (at least 1). For 500, 2,000 and 10,000 runners: 10, 40 and 200 toilets (1, 2 and 12 accessible), finish runoff 50, 80 and 150 m, waves of 100, 250 and 500.
- Heat and lightning: heat thresholds ship as null, because a medical director must approve the policy; the AI never makes an automatic go or no-go call. Lightning: stop, move to a substantial building or closed hard-top vehicle, wait 30 minutes after the last thunder. Tents and trees are not shelter.
- Art and look limits: images are concepts that cannot prove counts, geography or clearances, and the JSON wins over the art. Look inherits calibration-v2 unchanged. No logos, readable signs, dogs or animals. No Red Cross emblem: use a neutral first-aid marker. A human reviews medical, accessibility, fire, traffic and permit conditions.

Authored or unverified: (1) 18 of 29 rules are authored planning assumptions, and 15 of them cite no source: 0.75 sq m per runner, release flow 0.8 runners per second per metre, 60 s wave buffer, 6.1 m emergency lane. Tent spacing and heat thresholds are unknown (null). (2) The 9 verified rules and 26 of 28 sources are the pack's own claim, checked 7 Oct 2026; not yet spot-checked by us. One source URL is a staging host (denver.prelive.opencities.com). Greenville Permit B lead time and the World Athletics heat PDF stay unverified. (3) The six images are AI concepts (one generation plus one cleanup edit each) with no camera matrices and no measured route; routeGeometry is null in all three layouts. The pack says the art cannot prove counts. The Greenville finish spur shown is an unverified candidate. (4) Permit timelines (Denver 60 days, Chicago 14 to 21 day floors, Greenville Permit B unknown) come from 2024 and 2025 documents and need reconfirming for 2026. validate.py checks structure only, not safety. No Builder test has been run.

Flags for R:
- Look: look-values.json is an exact copy of style-b-calibration-v2 sharedLook, so its sky stops (#73A5CC, #A2C4DC, #DBDCD1) are the pale JSON values that R's images-beat-JSON rule corrected to #7AAFE2, #8FBAE7, #A0C8F2. Calibration-v2 owns look and wins; do not compile this pack's look block.
- venues-campuses-v1 (approved by R on 8 Oct for the Builder phase) sets the small stage deck at 8 x 6 m, 1 m high; this pack's stageDeck module is 4 x 3 m. Tent sizes agree within 2% (3 and 6 m against 10 and 20 ft). Unclear which wins; the approved pack is the safer default until R rules.
- builder-event-templates-v1 (pending R) uses different sanitation rules: toilets = max(2, guests / 75) with at least 10% accessible, against this pack's runners / 50 and 5% accessible per cluster. Both are authored. Races and other events may justify different ratios, but no pack says which one Builder uses.
- Scope gap: the rules are US-only (ADA, USATF, NWS, three US cities' permits) with one UK toilet ratio; none of R's six launch countries has rules. Not on the lawyer list (Q1 to Q55): liability and disclaimer wording for AI-proposed layouts that touch crowd safety, ADA, fire and permits, and Red Cross emblem rules. Add before any customer use.

Not compiled into `mock-values.json`: this content is for the Builder phase, and the engine stays generic (CLAUDE.md).
