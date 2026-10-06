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
stars to magnitude 6.5; merged components within 2 arcminutes into one point (combined flux, flux-weighted position, with the
shared-V rule below); converted the J2000 coordinates to unit vectors; used the HR number as `id`; kept the 256 brightest (sorted
by magnitude, then HR number; the faintest kept is V 3.40); added `distPc` (1 / BSC5 parallax) and
`velPcPerYear` from BSC5 proper motion, parallax and radial velocity for stars with a parallax of at least 0.001 arcsec. 40 stars
have no usable parallax and carry no motion (`distPc` and `velPcPerYear` are null; the largest neglected proper motion is 0.263
arcsec per year, HR 4763). 175 of the 256 stars carry an IAU proper name. BSC5
parallaxes predate Hipparcos and are rough for distant stars, so `distPc` only scales the motion and is not a quotable distance.

**Shared combined V (rule added 2026-10-06, after an independent check).** Summing the fluxes of merged components is right only
when each row carries its own component's V. For some close pairs BSC5 gives both components the *same* V while its multiple-star
fields (HEASARC `m_cnt`, `m_id`, `m_mdiff` = magnitude difference of the two brightest components, `m_sep` = their separation)
say the two differ: that V is the light of the pair together, and summing it twice makes the pair 0.75 mag too bright. The case that
exposed it was delta Ser (HR 5788 + 5789): both rows read V 3.80 with `m_mdiff` 1.1 at 3.9 arcsec, the flux sum was 3.047 (inside the
256), and the true combined V of 3.80 is fainter than the cut. The rule: within one merged group, components with exactly the same V
and `m_mdiff` > 0 count as one measurement, so that V is used once; rows with different V (alpha Cen, Castor, Mizar, Rasalgethi and
every other resolved pair) are flux-summed as before, and identical V with `m_mdiff` 0 or missing would still be summed (none
occurs). Every one of the 93 merged groups among the candidates was checked: four have identical V (HR 5788/5789 delta Ser,
HR 887/888 epsilon Ari, HR 4968/4969 alpha Com, HR 6749/6750), all four with `m_mdiff` > 0, and only delta Ser was inside the 256.
Their combined magnitudes become 3.80 (was 3.047), 4.63 (3.877), 5.22 (4.467) and 5.77 (5.017). That the shared V is a combined
magnitude is inferred from the data (equal V against a positive `m_mdiff`); the HEASARC page defines the multiple-star fields but
does not say how V is shared, and the catalogue's own CDS ReadMe, where it would be stated, could not be read (see above), so this
reading is **unverified**. Effect on the file: delta Ser left the 256 and theta2 Tau (HR 1412, V 3.40, "Chamukuy") entered; the other
255 stars are unchanged. At the cut, theta2 Tau and V337 Car (HR 4050) both read V 3.40; the HR-number tie-break keeps theta2 Tau.

Against the previous HYG file, 254 of the 256 stars are the same. HYG only: psi Vel (HR 3786; one BSC5 row at V 3.60, where the
HYG file had 3.25) and V337 Car (HR 4050, V 3.40 here, 3.39 in HYG). BSC5 only: mu Cen (HR 5193, V 3.04) and theta2 Tau (HR 1412).

The extraction is reproducible with one command, which downloads both inputs from their official URLs:

    python3 scripts/data/build_star_catalog.py Sources/WorldEnvironment/Catalog/stars-bsc5-bright256.json

## Credit

Courtesy credit for wherever the stars are shown (`StarCatalog.attribution`; not a licence condition):

"Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren 1991), public domain."
