# Regional evidence and mapping limits

The rendering sample consists of ambient light-duty vehicles visible on ordinary streets, not all road registrations. Commercial heavy trucks, buses, motorcycles and transit belong to separate kits. A parked sample and moving sample differ from ownership: deliveries, commuters, taxis and business fleets can be overrepresented in observed traffic. Do not convert a sales percentage, registration count or traffic flow directly into parked street density.

All seven-category fine body shares and eight-colour regional distributions in values.json are **UNVERIFIED authoring fixtures**, except the Canadian national SUV/passenger aggregates used as a proxy. Every density, hour multiplier, parking-location share, age distribution and condition percentage is likewise a proposal. They sum correctly and are intended to make the artwork reproducible, not imply a fleet survey was done.

## Regional source routes

| Region | Public evidence | Gap before measured fine mix |
|---|---|---|
| Chicago | [FHWA Illinois registrations](https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm) | State automobiles/trucks do not split sedans/SUVs/pickups; city street sample needed |
| Denver | [FHWA Colorado](https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm); [Colorado2023 county registration report](https://cdor.colorado.gov/sites/revenue/files/documents/2023_Annual_Report_DR4000_0.pdf) | County administrative types need body crosswalk; latest local fine-body shares unverified |
| Greenville SC | [FHWA South Carolina](https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm) | Metro fine body/age distribution not verified |
| NYC | [FHWA New York](https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm) | Borough traffic differs from state owned fleet; taxis/deliveries need separate observed weights |
| SF | [FHWA California](https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm); [SFMTA parking](https://www.sfmta.com/getting-around/drive-park/how-avoid-parking-tickets) | Fine local body and BEV stock share unverified; keep steep geometry from map |
| Miami | [FHWA Florida](https://www.fhwa.dot.gov/policyinformation/statistics/2024/mv1.cfm) | Fine metro mix and colour/age unverified; white-heavy fixture is an estimate |
| Canada | [Statistics Canada 2024 stock](https://www150.statcan.gc.ca/n1/daily-quotidien/251017/dq251017c-eng.htm) | National SUV/crossover 41.9 and passenger 35.0% verified; sedan/hatch split, pickup/van split and Toronto fixture remain estimates |
| UK | [DfT2025 licensing](https://www.gov.uk/government/statistics/vehicle-licensing-statistics-2025/vehicle-licensing-statistics-united-kingdom-2025) | Broad licensed body/fuel/local authority data; fine hatch/SUV mapping and local sample unverified |
| Netherlands | [CBS stock](https://www.cbs.nl/nl-nl/cijfers/detail/85237NED); [RDW open data](https://www.rdw.nl/over-rdw/dienstverlening/open-data) | Aggregate body/colour extraction was not completed; no individual plates retained |
| Mexico | [INEGI VMRC](https://www.inegi.org.mx/programas/vehiculosmotor/) | Broad municipality classes; cargo/pickup/SUV taxonomy crosswalk unresolved; urban default is not all Mexico |
| Australia | [BITRE2025 registrations](https://www.bitre.gov.au/resource/roads-vehicles/road-vehicles-australia-january-2025) | Passenger category includes SUVs; fine SUV/ute/hatch split requires body mapping; no current ABS census assumption |
| Japan | [JAMA2025 stock table, printed p6 / PDF p8](https://www.jama.or.jp/english/reports/docs/MIoJ2025_e.pdf) | Mini passenger 23,504,976 / all passenger62,321,025 =37.716%; separate mini trucks.38% urban kei fixture is a rounded reference-informed estimate, not local registrations |

## Colours, age and condition

[Axalta2025](https://www.axalta.com/content/dam/New%20Axalta%20Corporate%20Website/Public/Documents/US/axalta-global-automotive-color-popularity_2025.pdf) is automotive build data: global white29%, black23%, grey22%, silver7%, blue6%, red3%, green3%, gold/yellow3%, brown/beige2%, other2%. Broad production preferences justify mostly neutrals; they do not verify city in-use colour shares. The JSON uses eight finish groups and keeps yellow-gold taxi/service accents outside the privately owned colour fixture. If adding that fleet, allocate its share explicitly rather than silently breaking totals. Bright paint still receives the same shared world light and grading; no city-specific saturation overrides.

[UK DfT](https://www.gov.uk/government/statistics/vehicle-licensing-statistics-2025/vehicle-licensing-statistics-united-kingdom-2025) reports licensed cars average 10years at end 2025. [BITRE](https://www.bitre.gov.au/resource/roads-vehicles/road-vehicles-australia-january-2025) reports passenger vehicles 11.3years in January2025. These are means, not the three-band distributions authored here. [S&P Global Mobility](https://press.spglobal.com/2025-05-21-U-S-Vehicle-Age-Rises-Again-to-12-8-Years-in-2025%2C-According-to-S-P-Global-Mobility) reports US light vehicles average 12.8years in 2025; this does not verify a city age mix. [SMMT](https://www.smmt.co.uk/grey-tops-uk-car-colour-chart-for-eighth-year/) ranks grey first for UK new cars in 2025, also not in-use stock. Age affects broad silhouette generation and possible finish fading, never automatically rust, damage or neglect. All regions share the same broad condition default; weather/travel/wash history controls dirt.

## Side, plates and parking

UK/Australia/Japan default left-side travel, the others right. Sources/status are in sources.md. Directions always follow mapped lane topology, one-way streets and restrictions. In the forward-looking witness, right-hand traffic approaches on image-left; left-hand traffic approaches on image-right. Parked orientation is a separate mapped property. Blank plate rectangles preserve typical proportions/colour family; no serials, country codes, seals, flags, logos or state art. This intentional simplification is artwork, not a legal plate model. Plate dimensions outside the California12x6in evidence are labelled unverified design proxies; plate-issue variability remains.

SF hill parking uses steering: downhill toward curb; uphill away with curb. Vehicles rest on road grade while building floors remain level. Angle parking only in mapped marked bays. Do not block driveways, crossings, fire accesses or cycle lanes to reach a target count. Japan street sheet uses off-street pads; no blanket assumption of unrestricted residential curb parking. Country sheets are explicit representative defaults, not nationwide scenery or regulatory rules.

## Weather and phone implementation

Rain, road film, salt and parked snow caps appear on a shared state atlas embedded in each regional sheet, with regional trigger notes. They are material/geometry examples, not claims about snow frequency. No automatic tropical or national winter preset. Rain is a broad sheen, dirt/salt a smooth lower-body mask, snow a shallow cap that follows parked duration, snowfall, melt and travel. No procedural grit, bead fields or individual flakes on paint. Snow history missing means unknown, not a generated layer. Keep driving glass clear; do not spawn moving cars with obstructed windows.

Density means simultaneous vehicles per 100 m, not vehicles/hour. values.json includes all12 regions ×5 street classes ×5 local-time bands. Use seeded fractional expectations, mapped curb capacity, actual driveway pads, travel direction and collision/headway constraints. Weather/events can change observed density but are not modelled by a region label. All proposed counts/speeds/headways are visual simulation targets, not traffic or road-design guidance.

Projected-size tiers use drawable pixels:48+ selected structural form,16–48 class/glass groups,5–16 silhouette/colour,under5 cull ambient vehicles. No badge or legible plate at any size. Shared calibration-v2 is copied unchanged; wet state overrides vehicle material once, not the whole-world exposure. Browser phone checks do not validate iPhone GPU performance.
