# Outreach drafts: live transit and aircraft data providers

> **Drafts only. Nothing here has been sent, and no provider has been contacted.** Written 2026-10-06 for the project owner to review, edit and send himself. Per the owner's decision, nobody is contacted yet, and the aircraft budget is $0 for now, so adsb.lol is the only aircraft provider drafted.
>
> **Where the questions come from.** Per-provider questions: `live-feeds.md` §6. Terms analysis and relay design: `live-feeds.md` §1 to §4. Checklist rows and lawyer questions: `licensing.md` §12 and §9 (Q21 to Q31). Where a fact below is unverified, the "Before sending" list for that email says so, using the same tags as `live-feeds.md` ([V] verified, [O] observed, [U] unverified because the site blocks automated access, [T] third-party report, [C] unconfirmed).
>
> **How the contact channels were found.** From each provider's own public contact pages, read on 2026-10-06 with a normal client (the session's fetch tool, or curl with the honest User-Agent `WorldEngine-research/0.1`; no browser identity was imitated, no archive copy was used, and no blocked page was retried another way). **metra.com was not requested at all** for this document.
>
> **Suggested order, if and when you decide to send:** CTA, Metra, adsb.lol, then Pace. CTA and Metra are in the launch plan; Pace is not used under the current plan, so that email is optional.
>
> **For all four.**
> - Send from a company address, and replace every `[bracket]`.
> - Keep every reply in writing and save a dated copy (for CTA especially, the text that applies at key issue matters).
> - Do not attach `live-feeds.md` or `licensing.md`: they hold internal analysis, other providers' names and cost figures.
> - Read each provider's pages again in your own browser before sending, and delete any question the page already answers.
> - Edit the "commercial" wording so it matches what you actually plan (paid, subscription, ad-supported or free). The drafts say nothing about the app's size or revenue, and should not.

---

## 1. Metra (GTFS-realtime)

**To:** [Metra developer contact, see metra.com/developers]

**Subject:** Questions about the GTFS-realtime licence for a relay serving a consumer app

```text
Hello,

I'm [Your name] at [Company]. We're building [App name], a mobile app that
draws real places in 3D from open map data (OpenStreetMap). We'd like to show
Metra trains moving along the lines in that 3D scene, using your
GTFS-realtime positions feed. Nothing is live yet and we have not requested
a key.

Our plan is for one server of ours to fetch the feed on a schedule, keep only
the most recent copy for a few minutes, and pass the relevant trains on to the
app on each phone. The phones would never hold a key or contact Metra's
servers. We could not confirm the exact licence wording ourselves, so please
read what follows as questions, not as our reading of your terms.

1. Relay. We understand the licence may ask apps to redistribute the data
   through their own host. Would one server of ours serving many users of
   [App name] fit what you mean? Is there any limit on the number of end
   users?

2. "Modifying" the data. Does it count as modifying or deleting Data if our
   server (a) keeps only the trains inside a geographic area, (b) re-encodes
   the data into a more compact format, or (c) discards older copies after a
   few minutes? If any of these is a problem, what would you suggest instead?

3. Required wording. What exact non-affiliation statement and last-updated
   wording do you require, and where may it appear (for example in a credits
   panel, and on images or short videos that people save from the app)?

4. Rate limits. Is there a limit on keyed requests? (A request we made without
   a key showed an x-ratelimit-limit header of 200, and we do not know its
   unit.) Are keys issued per app or per person, and how long does approval
   usually take?

5. Commercial apps. May [App name] be [paid / subscription / ad-supported /
   free: keep what applies] and still use the feed?

A short written reply to each point would be very helpful. We are glad to
describe the app in more detail, or to show you how Metra would be credited,
before we apply for a key.

Thank you,
[Your name]
[Role], [Company]
[Website]
```

**Before sending (Metra)**

- **Unverified [U]: every Metra term.** The relay requirement, "must not modify or delete Data", the non-affiliation and last-updated wording, "no published rate limit" and the absence of "commercial" wording were read from metra.com with a browser-style User-Agent after a 403 (`live-feeds.md` §2.2, §7.1 U1 to U5). That route is not accepted, so none of it is relied on. The email is deliberately phrased as questions. Open `metra.com/developers`, the GTFS API page and the licence in your own browser, compare, and drop or reword any question the pages already answer.
- **Observed [O], not documented:** the unauthenticated request to `gtfspublic.metrarr.com/gtfs/public/positions` returned HTTP 401 with `x-ratelimit-limit: 200`. It was one request from an honest client. Delete the bracket sentence in question 4 if you would rather not mention it.
- **Unknown [C]:** approval turnaround, per-app or per-person keys, any limit on keyed traffic, whether paid use is allowed, whether area filtering is "modify or delete".
- **Contact channel not looked up.** The placeholder points to Metra's developer page. Find the contact route (or the key-request form's contact line) in your own browser; do not use the key-request form to ask these questions, because it carries a licence tick-box. Do not submit it until you have the answers.
- **Not in this draft (optional extras from `live-feeds.md` §6):** whether line names and colours (for example UP-N) may be shown (Q6); how changes or withdrawal of the feed are announced (Q7).
- **Attach or link:** nothing needs attaching. Optionally add your app's website, or a screenshot of a rendered area with no Metra marks in it.

---

## 2. CTA (Train Tracker, Bus Tracker, GTFS-RT beta)

**To:** [CTA developer contact: the address shown on transitchicago.com/developers/ for developer questions and daily-limit requests; copy it from the page in your browser]

**Subject:** Developer licence questions: live vehicles in a 3D map app, served through one server

```text
Hello,

I'm [Your name] at [Company]. We're building [App name], a mobile app that
draws real places in 3D from open map data (OpenStreetMap). We'd like to show
CTA trains and buses moving through that 3D scene, using Train Tracker, Bus
Tracker and, if possible, the GTFS-RT beta feeds. The vehicles would be an
ambient part of the scene, not a trip planner. Nothing is live yet and we
have not requested a key.

Our plan is for one server of ours to fetch each feed about every 30 seconds
(only the routes near areas people are viewing), keep only the latest copy in
memory for a few minutes, and pass the vehicles on to the app on each phone.
The phones would never hold a key or contact CTA's servers. We have read the
Developer License Agreement and would like to be sure our use fits it before
we apply.

1. Purpose. The agreement allows use for the purpose of assisting riders or
   promoting public transportation. Does a 3D visualization of CTA vehicles
   in a consumer app (including images or short videos people save from it)
   fit that purpose? If not, what express permission would CTA need to give?

2. One server, many users. May a server of ours serve one key's data to many
   users of [App name]? Please also confirm the daily limits per key: the
   Train Tracker overview and documentation give different figures (50,000 and
   100,000), and the Bus Tracker limit is 100,000. How do we ask for more, and
   would CTA like us to use a fixed server address?

3. Which text applies. The agreement on the key-application page differs from
   the one on the current terms page (neither is dated). Which one applies
   when a key is issued, and can you send us a dated copy of it?

4. GTFS-RT beta. The beta page says to register through the Developer Center.
   Does a Train Tracker or Bus Tracker key work there, or is it a separate
   key? What are the refresh rate, request limits and terms, and is the feed
   expected to stay available?

5. Deleting data. The agreement asks us to delete all CTA Data when it
   terminates. If our server keeps only the latest copy in memory for a few
   minutes, with no history stored, is that enough, and is there a form of
   written confirmation you would expect?

A short written reply to each point would be very helpful. We would be glad
to describe the app or show you how CTA would be credited.

Thank you,
[Your name]
[Role], [Company]
[Website]
```

**Before sending (CTA)**

- **Verified [V], read 2026-10-06 with an honest client:** the purpose clause; the delete-on-termination and certification wording; the two differing agreement copies (the key-page copy has an unfilled "[Insert Link]" placeholder and a narrower grant; neither is dated); Train Tracker 50,000 (overview) against 100,000 (docs); Bus Tracker 100,000; the GTFS-RT beta page's key and Developer Center registration wording.
- **Unconfirmed [C]:** whether our relay is "your application"; the GTFS-RT beta refresh rate, limits and terms; which Train Tracker limit is right; any rule on cloud or fixed egress addresses. A third-party report [T] says Train Tracker and Bus Tracker keys are rejected by the GTFS-RT beta; question 4 asks without citing it.
- **Recipient address:** CTA's pages protect their e-mail addresses against automated harvesting, so this draft does not include one. Open `transitchicago.com/developers/` in your browser and copy the developer contact address shown there. The Bus Tracker page also offers a limit-increase request to the same address.
- **Re-read before sending** (note anything that has changed): `/developers/terms/`, `/developers/traintrackerapply/`, `/developers/ttdocs/`, `/developers/traintracker/`, `/developers/bustracker/`, `transitdata.transitchicago.com`.
- **Do not apply for any key yet.** When you do, use a company-owned Bus Tracker account (one key per account, tied to a person's account), and keep a dated copy of the agreement text shown at that moment.
- **Not in this draft (optional extras from `live-feeds.md` §6):** whether attribution is required and whether route colours and icons may appear in a 3D scene (Q7); the recommended polling interval and the accuracy of `ttpositions` (Q8). Reminder if you add the first: CTA's branding rules forbid other CTA logos and official maps, so show no CTA marks.
- **Attach or link:** link the CTA pages named above if useful. Optionally attach one screenshot of a rendered area with no CTA logos, so "3D visualization" is concrete. Nothing else.

---

## 3. Pace

**To:** Pace's general contact route: the Contact Pace page on pacebus.com (`pacebus.com/contact`, which links the online customer-service form), or `Passenger.Services@PaceBus.com`, the general address listed there. Neither page nor the directory names a data or GTFS contact, so ask for the message to be passed to whoever manages Pace's GTFS data.

**Subject:** GTFS data: commercial use, and the GTFS-realtime files on tmweb.pacebus.com

```text
Hello,

I'm [Your name] at [Company]. We're building [App name], a mobile app that
draws real places in 3D from open map data (OpenStreetMap). We'd like to show
Pace buses moving through that 3D scene. Could you please pass this message
to whoever manages Pace's GTFS data? Nothing is live yet and we have not used
Pace data in any product.

Pace's GTFS page says the data is shared "for non commercial use". [App name]
may be [paid / subscription / ad-supported / free: keep what applies]. We
also found GTFS-realtime files on a Pace address, but not on any Pace page,
so we are asking before relying on them. Our plan is for one server of ours
to fetch the data, keep only the latest copy for a few minutes, and pass the
buses on to the app on each phone, so that phones never contact Pace's
servers.

1. Commercial use. Does "non commercial use" rule out an app like ours? If it
   does, can Pace give written permission for commercial use, and on what
   terms?

2. GTFS-realtime files. These three addresses appear in a third-party
   catalogue (Transitland), not on a Pace page:
   https://tmweb.pacebus.com/TMGTFSRealTimeWebService/vehicle/VehiclePositions.pb
   https://tmweb.pacebus.com/TMGTFSRealTimeWebService/tripupdate/tripupdates.pb
   https://tmweb.pacebus.com/TMGTFSRealTimeWebService/alert/alerts.pb
   Are they official Pace addresses? May we use them, and relay the data to
   our app users from our own server? Are there terms, rate limits or an
   expected refresh interval, and is there a supported developer route?

3. Attribution. What credit do you require, if any? The GTFS licence says the
   Pace name and logo need prior written consent: may the app show route names
   and numbers as plain text without that clause applying?

A short written reply to each point would be very helpful. We are glad to
describe the app in more detail.

Thank you,
[Your name]
[Role], [Company]
[Website]
```

**Before sending (Pace)**

- **Verified [V]:** the page's intro sentence ("for non commercial use"); the licence's grant, and its name-and-logo consent clause; that the page says Bus Tracker predictions are not available for download.
- **Observed [O]:** the three `tmweb.pacebus.com` files answered a header request with HTTP 200, unauthenticated, refreshing about every 30 s. The email says only that we found them and have "not used Pace data in any product"; if you want to be more explicit, add that one header check each was made and nothing was downloaded or stored.
- **Third-party [T] and unconfirmed [C]:** the three addresses come from Transitland Atlas, not from a Pace page. That they are Pace's own system (same host as Pace's Bus Tracker links) is inference, and no Pace page, licence or document covers them. Whether the intro's "non commercial use" is binding beyond the licence text is a lawyer question (`licensing.md` Q23).
- **Contact channel:** the general form or Passenger Services is the only route found, and no data or IT contact is given. The directory lists a named media-relations person; do not use that individual's address for this. If there is no useful reply, follow up through the form.
- **Plan note:** the current plan does not use Pace data at all (`live-feeds.md` §1 blocker 1). Treat this email as optional, and do not use the files until a written answer arrives.
- **Attach or link:** nothing to attach. The page to link or quote is `pacebus.com/route-timetable-data-services`.

---

## 4. adsb.lol operator (aircraft)

**To:** `info@adsb.lol`, which the adsb.lol privacy-and-licence page gives for any question or concern. Alternative channels on the home page: the project's Zulip chat (`adsblol.zulipchat.com`), its GitHub organisation (`github.com/adsblol`) and Mastodon. The API specification's "please contact me" does not name an address, so use the email first and the chat as a fallback (not confirmed that the operator reads either).

**Subject:** Permission for production use of the API through one server (two areas, 30 to 60 s polling)

```text
Hello,

I'm [Your name] at [Company]. We're building [App name], a mobile app that
draws real places in 3D from open map data (OpenStreetMap), and we are
considering showing aircraft passing overhead in that scene. Thank you for
running adsb.lol and keeping the data open. Your API description asks
production users to get in touch, so I'm writing before we use it that way.
Nothing is live yet.

Our plan is for one server of ours to call /v2/point for two metro areas
(each about 30 km across), no more often than once every 30 to 60 seconds per
area, with a descriptive User-Agent and a way to contact us:
[User-Agent string and contact URL]. The server would keep only the latest
copy in memory for a few minutes and pass the positions on to the app on each
phone, which would never call your API. [App name] may be [paid /
subscription / ad-supported / free: keep what applies].

1. Permission. Are you happy for a commercial app to use the API in
   production in this way? Is that polling rate acceptable, and what notice
   would you give us before changes that could affect us?

2. Attribution and ODbL. We would credit adsb.lol (with a link) in the app's
   credits, next to the OpenStreetMap credit, and comply with the ODbL. What
   wording do you prefer? Our server keeps no history and publishes no
   database, only transient copies for the app. Is there anything more you
   would expect from us under share-alike?

3. Privacy filtering. We plan to drop any aircraft flagged as LADD or PIA in
   the dbFlags field (bit values 8 and 4, as we understand them from the
   ADS-B Exchange format) before storing or logging anything, and never to
   send registration or ICAO addresses to phones. Is dbFlags reliable for
   this, or would you suggest also checking /v2/ladd and /v2/pia from time to
   time? Do you have a policy we should follow?

4. API keys and limits. The API description says a key will be required in
   future, available by feeding to adsb.lol. How would a production user that
   is not a feeder get a key? What request rate do you consider reasonable
   for us, and is there anything we should do to avoid breaking your service?

5. Support. Is there a sponsorship or support route for the project?

Thank you again. A short reply to each point would be very helpful, and I'm
happy to adjust our plan to what works for you.

[Your name]
[Role], [Company]
[Website]
```

**Before sending (adsb.lol)**

- **Verified [V], read 2026-10-06 from the API specification (`api.adsb.lol/api/openapi.json`):** "please contact me" for production purposes; a key to be required in future, obtained by feeding to adsb.lol; the ODbL licence; the `/v2/point`, `/v2/ladd` and `/v2/pia` endpoints; a `dbFlags` field in the aircraft schema; no published rate limit. The contact email and Zulip/GitHub/Mastodon channels are read from the home and privacy-and-licence pages.
- **Unverified or assumed:** the `dbFlags` bit meanings (PIA = 4, LADD = 8) were verified against ADS-B Exchange's specification, and are assumed to hold on adsb.lol [C]; that is why question 3 states them as "as we understand". adsb.lol's attribution wording, refresh rate and rate limits are not published [C]. A third-party report [T] of heavy rate limiting at a 4 s poll is not in the email, but is the reason the email proposes 30 to 60 s.
- **Not a legal answer.** The operator's view of attribution and share-alike is useful, but it does not settle whether the relay snapshot is a Derivative Database or whether phones "Convey" transient copies; that stays a lawyer question (`licensing.md` Q25).
- **Fill in before sending:** the real User-Agent string and contact URL (do not invent one in the draft), and the two metro areas if you prefer to name them (the draft keeps them generic).
- **If refused or unworkable:** aircraft stay off. The $0 aircraft budget means no commercial feed is the fallback (`live-feeds.md` §5.6).
- **Do not use the API in production** (or build on it commercially) before a reply. Keep any testing small and use a descriptive User-Agent.
- **Attach or link:** nothing to attach. Optionally link your app's website, and one screenshot of a rendered area without live aircraft.
