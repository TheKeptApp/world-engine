# Star catalog notice

`stars-bsc5-bright256.json` is derived from the **Yale Bright Star Catalogue, 5th Revised Edition (preliminary version)** by
**Dorrit Hoffleit and Wayne H. Warren Jr.** (1991; CDS catalogue V/50), as distributed by **NASA HEASARC** (table `bsc5p`,
https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html; file
`https://heasarc.gsfc.nasa.gov/FTP/heasarc/dbase/tdat_files/heasarc_bsc5p.tdat.gz`, decompressed SHA-256
`e2b2f8e9d615426f9478f88061235976143d49d8b25c6c15df3f3661c7095b53`, retrieved 2026-10-06). It replaces the earlier
HYG-Database-based file (CC BY-SA 4.0), so **no share-alike licence applies to the star data any more**.

## Licence status: public domain in practice, one caveat

What the official sources say (checked 2026-10-06):

- **NASA HEASARC** (the distributor used): its data-use page says "HEASARC materials are all available freely for your use."
  (https://heasarc.gsfc.nasa.gov/docs/heasarc/data_policy.html). It asks for its standard acknowledgement only in research publications
  that HEASARC helped significantly; that is a courtesy, not a licence condition for an app.
- **data.gov record** for the HEASARC table (https://catalog.data.gov/dataset/bright-star-catalog; identifier `ivo://nasa.heasarc/bsc5p`):
  licence field `https://www.usa.gov/government-works`, publisher HEASARC / NASA, access level public. U.S. Government works carry no
  copyright in the United States.
- The HEASARC table page names the catalogue's authors and says it was built from a file obtained from the NASA Astronomical Data
  Center (ADC) or CDS. It states no copyright, licence or usage condition, and neither does any other page read for this check.

The caveat: usa.gov warns that not everything on a federal site is a U.S. Government work, and the catalogue was compiled by
Hoffleit (Yale) and Warren, so no source says in plain words that the *authors* waived copyright. The practical risk is very small
(positions and magnitudes of stars are facts, and the 256 brightest is an obvious selection), but this is not legal advice.
**Unverified:** the catalogue's own ReadMe on CDS (`https://cdsarc.cds.unistra.fr/ftp/cats/V/50/ReadMe`), where a copyright or
restriction line would normally appear. CDS blocks automated access (bot check, "Access Denied"), so it was not read. Note also
that CDS's VizieR terms say commercial use depends on the origin catalogue's rules, which is one reason HEASARC was used instead.

Not used: **Hipparcos** (ESA) is published under CC BY-NC 3.0 IGO (non-commercial); **HYG** is CC BY-SA 4.0 (share-alike).

## Star names

The Yale catalogue has no proper names. Names (Sirius, Betelgeuse, ...) come from the **IAU Catalog of Star Names**
(IAU Working Group on Star Names; https://www.iau.org/public/themes/naming_stars/; file
https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt, SHA-256
`84fac0c90f1b19abc491c2793469e0caa7b003ad1bc93a790ca41147010d0eb0`), joined on HR or HD number. The file header says "All
IAU-produced products (Images, Videos, Texts) are released under Creative Commons Attribution", so the names are credited here:
**Star names: IAU Catalog of Star Names, IAU Working Group on Star Names.** The names are labels in the data only; the engine does
not draw them. If an app ever shows them, add that credit beside the one below.

## Changes made

Excluded the 14 HR numbers that are not stars (no magnitude) and two entries listed at a peak magnitude they hold only briefly
(HR 5958 = T CrB, a recurrent nova; HR 681 = Mira, a long-period variable; the earlier HYG file also left both out); considered
stars to magnitude 6.5; merged components within 2 arcminutes into one point (combined flux, flux-weighted position); converted
the J2000 coordinates to unit vectors; used the HR number as `id`; kept the 256 brightest; added `distPc` (1 / BSC5 parallax) and
`velPcPerYear` from BSC5 proper motion, parallax and radial velocity for stars with a parallax of at least 0.001 arcsec. 40 stars
have no usable parallax and carry no motion (the largest neglected proper motion is 0.263 arcsec per year, HR 4763). BSC5
parallaxes predate Hipparcos and are rough for distant stars, so `distPc` only scales the motion and is not a quotable distance.
The extraction is reproducible with one command, which downloads both inputs from their official URLs:

    python3 scripts/data/build_star_catalog.py Sources/WorldEnvironment/Catalog/stars-bsc5-bright256.json

## Credit

Courtesy credit for wherever the stars are shown (`StarCatalog.attribution`; not a licence condition):

"Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren 1991), public domain."
