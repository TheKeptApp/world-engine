# Cross-lane handoffs

Work one lane needs from another, queued in the owner's order. Each row says who owns it, what is
needed, why, what it unblocks and where it sits in that lane's queue.

| # | From → To | Needed | Why | Unblocks | Queue position | Status |
|---|---|---|---|---|---|---|
| 1 | 5A → P2 | Cheaper mid-distance windows: at the mid building LOD (house still 20+ px tall, about 150–306 m), window rhythm with far fewer triangles (e.g. one quad per window band or a facade texture strip instead of per-window geometry) | Keeping windows until a house is below 20 px (house-archetypes-v1 detail tiers) added 10–55k triangles in view and broke the floor tier's 400k (owner decision 8 Oct: option A now, C next) | 5A can turn projected-size building LOD back on (code is in, off by default: look.json buildingLOD), first for the hero tier after a device measurement | After P2's tree crowns | Open (8 Oct) |

Tier note (owner, 8 Oct): 400k triangles / 100 draws in view is the FLOOR tier (iPhone 12/13, the owner's
phone). The hero tier (iPhone 15 Pro and later) may run the B-level window distance once measured on a
device. Do not trim skyline or grass to pay for it.
