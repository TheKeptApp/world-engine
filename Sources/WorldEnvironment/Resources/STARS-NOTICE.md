# Star catalog notice

`stars-hyg-v41-bright256.json` is derived from the **HYG Database v4.1** by **David Nash / Astronomy Nexus**
(https://github.com/astronexus/HYG-Database, file `hyg/CURRENT/hygdata_v41.csv`, git blob
`ba2dec4eb0f6768914c7fc1051258100214ddf84`, SHA-256 `d9f69fd86bbf90a4e4d52b4c5c53eacfa6dfc0bfdef85bfd94f095e0bebe4ebd`),
licensed under the Creative Commons Attribution-ShareAlike 4.0 International License
(https://creativecommons.org/licenses/by-sa/4.0/).

**Changes made:** selected the 256 brightest stars after excluding the Sun; merged components within 2 arcminutes into one
point (combined flux, flux-weighted position); converted coordinates to unit vectors; rounded values; added component lists.
The extraction is reproducible with `scripts/data/build_star_catalog.py`.

**License of this derived file:** CC BY-SA 4.0. This applies to the data file only, not to WorldEngine's source code.

Required credit wherever the stars are shown or the data is redistributed:
"Stars: HYG Database v4.1, David Nash / Astronomy Nexus, CC BY-SA 4.0 (modified)."
