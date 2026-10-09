# Export-time spatial cells and merged far tiles — 2026-10-08

## Recommendation and limits

Recommend one hierarchy: **100 m visibility leaves → 200 m resident content pages → 400/800 m exact-compatible draw groups**, with a separate **800 m geometric far parent** considered beyond 800 m. Visibility and draw grouping are independent. Fully interior leaves use bulk ranges; partial leaves retain exact feature/instance selection. Exact draw groups may combine selected ranges at any distance without adding omitted geometry; they must not submit an entire intersecting parent merely to save calls. Static vertex/prototype resources stay immutable; bounded index/instance buffers are reused. Geometric far parents have a separate error/coverage gate and are optional.

This choice keeps smaller visibility/residency units without paying one instance/material draw in every leaf. The 200 m page size matches the retained source-page scale (48 Sloan and 25 each Lakeview/Wilmette chunks); grid phase/origin must be explicit rather than assumed identical; 400/800 m draw aggregation addresses measured fragmentation. A 200 m-only draw policy is insufficient: fine/global-instance Wilmette 150 m is 103 draws (400 m 83, 800 m 71), and Wilmette 40 m is 132 (400 m 108, 800 m 96). Use compatible aggregation across page boundaries, not a camera/block exception. Even 800 m gives 112 at Sloan 600 m: **no full floor solution is proved**. The recommendation is an architecture for a separately qualified prototype, not permission to adopt afc72bd.

Keep original feature/instance IDs, padded actual bounds, transforms, material/layout/prototype keys and deterministic ordering. Oversized complete features get independent pages; their future savings are unmodeled. Default renderer, exporters, assets, budgets, v3 and allocator remain unchanged. No exports or captures were run.

[Qualification 887057d](scene-budget-qualification.md) shows why the runtime packing prototype must not be adopted: exact pixel failures in Lakeview 150 m and both motion paths; selection 11–25 ms plus pooling 22–31 ms, sustained buffer/CPU backing-store growth, and descent 13/21 frames over 100 draws. Sloan 150 m fine visible content is 205,349 triangles versus 791,795 submitted; that does not imply a 200 m or 800 m whole tile costs 205k. Cell-size, compatibility, coarse-bound overdraw and state fragmentation must all be accounted for.

## Model, calibration and evidence scope

Read-only Node/Three reconstruction of existing exports, frozen foliage/crown OFF conditions and saved camera/fixture contracts. Dates: Sloan/Lakeview October 15; Wilmette September 15. Main sky costs 1,984 triangles/1 draw, already charged. No occlusion savings or missing context is credited. Padded feature/instance bounds use the existing 0.5 m diagnostic margin; future deformation bounds remain unproved. DEM atoms retain complete existing 2 km patch triangles; no tessellation/clipping was performed.

Camera-contract discrepancy: Wilmette's retained camera eye/target implies **3° downward pitch**, heading 90°, FOV 50° (40 m target altitude 34.75922207169588 at 100 m horizontal distance), although the capture annotation says `inspection.pitchDown:45`. The actual eye/target governs this reconstruction; both stationary and uncaptured motion models retain 3°. This explains its mostly-sky 600 m view and limits its usefulness as an aerial coverage hold-out. Sloan/Lakeview retain their actual 45° targets. Fixing annotations or recapturing is outside this docs-only task.

Four grid sizes use the same local-ENU zero origin and half-open floor addressing. Assign whole static features and selected instances by their complete padded bound's x/z center, retain original vertices/transforms, and union actual geometry bounds per cell. Thus 100 m is an **address spacing**, not a guaranteed geometric diameter: a crossing road, lake, facade batch or DEM patch may extend beyond it. The boundary lawn remains its existing whole feature. A future stable owner ID/origin and separately paged oversized features can change these counts and must be re-accounted; no unmeasured savings are banked.

**Whole-cell T/D** submits every atom of an intersecting actual cell bound and one draw per occupied exact-compatible material/state/layout/model/prototype key. It is a conservative cell-submission model, not GPU timing. A backend may further cull individual material bounds, which is not credited. **Fine T/[D]** independently selects padded features/instances within source meshes that the current renderer submits, then pools per cell; bracketed draws count the padded candidates before pooled-object GPU sphere culling and are therefore conservative at that later stage. The reference fineT column uses the calibrated 800 m/global-instance policy after its pooled sphere cull; this is not a per-cell GPU triangle prediction or a count of depth-visible pixels. Copying all features of an intersecting cell generally costs more. All triangles/draws are main only; shadow reach and post are separate. Future byte/vertex/triangle caps may require more batches and raise draws; no native 40k tile-cap, compression, index-width or buffer-residency saving is credited to these new count predictions.

Compatibility includes material identity, vertex/index/prototype values, layout types/normalization, instance attributes, exact static model matrix, render order/category and transparent source ordering. “Per-material pooling” cannot safely mean material name alone. Global-instance pooling is shown separately where relevant; it never makes unlike prototypes compatible.

Calibration reproduces **all 51 measured default and variant triangle/draw pairs exactly** (nine stationary area/height pairs plus 42 Sloan motion frames). Variant calibration uses 800 m static bins and global compatible visible instances, matching afc72bd; the experimental per-cell-only scheme is different. The initial new model counted padded candidates before the backend's pooled-instance sphere cull: pan 15/20 were conservative by 534 triangles/1 draw, descent 15 by 3/1. Computing the same prototype-sphere union with submitted Float32 instance transforms explains those exact residuals and makes the calibration exact. The main per-cell tables deliberately retain the conservative whole-cell and candidate-key counts; they do not silently apply a one-draw correction to unmeasured cell sizes. No multiplier fitted at one camera was applied elsewhere. Lakeview/Wilmette motion predictions are **uncaptured**, despite exact stationary calibration.

The first diagnosis's 800 m predictions 41/89/129 versus first strict compatible implementation 45/102/186 underestimated by **4/13/57 draws (9.8%/14.6%/44.2%)** at 40/150/600 m. It omitted model-matrix/layout/category/transparent-order distinctions. Final global-instance pooling then reduced 102→75 and 186→112; comparing 129 against 112 conflates that different pooling policy and is not evidence the old per-cell key was conservative. The stricter new model retains those keys and is calibrated directly against the measured final policy.

Temporary offline analyzer: `/private/tmp/a10-spatial-model.mjs`, SHA-256 `ce2b4ad38f9be7612f7939e395e8895b6699b5123711a39bfb2186e65a340c7a`; results `/private/tmp/a10-spatial-model-results.json`, SHA-256 `dc7f45995faa610a76cba63e490bd78e33aeb708153a8db73aad0c22dad2c911`. These paths are not durable assets; all cell counts and hierarchy static results are retained in the tables below. Inputs are existing core exports/capture JSONs referenced by [887057d's manifest](../../web/bakeoff/evidence/scene-budget-qualification/manifest.json). No renderer/exporter code or asset changed. Initial adapter failure reading the existing relative DEM path was fixed only in the temporary analyzer; no failed-run counts are used.

## Ladder results

Cell entries are **whole-cell triangles / draws [fine-selected per-cell candidate draws]**. The separate reference fineT column is the calibrated 800 m/global-instance policy; see the sphere-cull distinction above. Counts are predictions unless explicitly marked measured; no pixel-equivalence claim.

| Area/height | Measured OFF T/D | Measured fine variant T/D | Reference fine T | 100 m | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|---:|---:|
| sloans-40 | 729101/182 | 49844/45 | 49844 | 312,157/564 [97] | 424,536/338 [90] | 593,879/277 [62] | 685,514/176 [45] |
| sloans-150 | 791795/251 | 205349/75 | 205349 | 439,857/1011 [519] | 540,784/501 [287] | 604,388/295 [153] | 824,329/219 [102] |
| sloans-600 | 624433/292 | 320036/112 | 320036 | 413,060/1244 [1041] | 459,083/562 [499] | 462,742/317 [280] | 848,518/251 [186] |
| lakeview-40 | 320733/112 | 47686/43 | 47686 | 204,674/281 [82] | 342,725/290 [57] | 416,759/239 [54] | 489,607/225 [54] |
| lakeview-150 | 323901/131 | 150628/64 | 150628 | 255,028/429 [262] | 311,443/301 [171] | 368,006/228 [130] | 403,471/181 [111] |
| lakeview-600 | 209528/101 | 72065/32 | 72065 | 215,345/407 [180] | 330,475/338 [131] | 381,801/245 [100] | 403,471/181 [44] |
| wilmette-40 | 616918/278 | 328418/96 | 328418 | 528,171/1430 [1019] | 643,052/764 [506] | 681,729/360 [245] | 767,464/258 [179] |
| wilmette-150 | 599588/252 | 250788/71 | 250788 | 383,287/1144 [809] | 470,169/614 [404] | 681,729/360 [192] | 767,464/258 [126] |
| wilmette-600 | 43549/12 | 1986/2 | 1986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |

**Interpretation:** none of the four whole-cell schemes meets both floor limits at all three 150 m area views. Sloan 100 m is 439,857/1,011; even global-instance pooling leaves 163 draws. Its 200 m whole-cell 540,784/501 contrasts with fine-selection 205,349/287, or 84 with global instances. Thus export-time cells alone cannot be credited with the 205k visible-content result: boundary selection and compatible batching are required. Fine 800 m/global-instance stationary 150 m counts 75/64/71 demonstrate the useful compatibility target, but they do not prove the new resource architecture's pixels or timing. Wilmette 600 m is mainly sky/core boundary; whole-cell pooling pulls hidden/behind-camera content into the candidate cell bounds, inflating 11,559→167,187 as bins grow. That is a conservative submission effect, not newly visible city or proof of complete context.

Fine-selection/global-instance draw projections (static material bins still per cell), ordered 100/200/400/800 m:

- sloans-40: 55/48/48/45; whole-cell/global-instance draws 105/118/132/132.
- sloans-150: 111/84/80/75; whole-cell/global-instance draws 163/134/142/152.
- sloans-600: 209/127/117/112; whole-cell/global-instance draws 233/153/145/176.
- lakeview-40: 51/46/43/43; whole-cell/global-instance draws 92/111/109/105.
- lakeview-150: 94/83/73/64; whole-cell/global-instance draws 126/117/108/95.
- lakeview-600: 69/61/49/32; whole-cell/global-instance draws 118/126/114/95.
- wilmette-40: 166/132/108/96; whole-cell/global-instance draws 198/172/144/127.
- wilmette-150: 127/103/83/71; whole-cell/global-instance draws 159/135/144/127.
- wilmette-600: 2/2/2/2; whole-cell/global-instance draws 32/50/56/56.

## Moving paths

Same 10 s logical timeline as qualification, fixed 2 Hz, 21 frames per path including endpoints. Sloan positions/cameras are the measured ones. Lakeview/Wilmette repeat the same generic 200 m east-west pan at 150 m and 600→40 m descent at their saved eye/orientation; these are model predictions, not new captures. Dynamic near plane remains altitude/4. All rows, including non-capture samples, are retained. T/D notation matches the ladder table.

### sloans pan

| Frame/time/alt | Reference fine T | 100 m T/D [fineD] | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|
| 0/0 s/150 m | 132,648 | 283,167/657 [388] | 359,162/375 [204] | 427,487/234 [113] | 857,094/253 [101] |
| 1/0.5 s/150 m | 137,829 | 275,903/648 [407] | 351,837/370 [213] | 420,162/232 [119] | 855,505/252 [103] |
| 2/1 s/150 m | 142,296 | 268,926/643 [410] | 344,740/370 [214] | 413,065/232 [120] | 855,085/251 [102] |
| 3/1.5 s/150 m | 154,251 | 301,822/734 [414] | 337,816/367 [215] | 493,574/284 [119] | 853,946/249 [101] |
| 4/2 s/150 m | 160,780 | 289,156/673 [406] | 313,098/334 [210] | 417,435/246 [111] | 853,873/250 [91] |
| 5/2.5 s/150 m | 165,044 | 284,901/662 [409] | 308,777/329 [219] | 413,186/241 [116] | 856,259/249 [93] |
| 6/3 s/150 m | 170,910 | 282,061/665 [421] | 305,387/327 [226] | 409,868/237 [118] | 857,065/250 [94] |
| 7/3.5 s/150 m | 177,623 | 415,925/892 [431] | 527,780/497 [233] | 612,813/295 [123] | 832,635/217 [94] |
| 8/4 s/150 m | 189,114 | 420,132/905 [462] | 548,473/507 [255] | 610,939/293 [138] | 830,793/217 [98] |
| 9/4.5 s/150 m | 196,817 | 445,820/999 [479] | 545,263/507 [266] | 608,173/294 [144] | 828,094/218 [100] |
| 10/5 s/150 m | 205,349 | 439,857/1011 [519] | 540,784/501 [287] | 604,388/295 [153] | 824,329/219 [102] |
| 11/5.5 s/150 m | 210,333 | 437,462/1003 [529] | 539,401/497 [297] | 603,705/293 [162] | 823,687/219 [112] |
| 12/6 s/150 m | 214,966 | 484,573/1091 [546] | 539,016/498 [307] | 604,686/293 [170] | 824,753/219 [115] |
| 13/6.5 s/150 m | 225,129 | 498,407/1120 [564] | 539,555/504 [319] | 605,647/297 [187] | 825,750/219 [122] |
| 14/7 s/150 m | 231,147 | 495,302/1088 [562] | 539,934/501 [321] | 606,922/305 [197] | 827,076/220 [127] |
| 15/7.5 s/150 m | 236,425 | 494,764/1072 [572] | 539,396/491 [331] | 607,558/302 [196] | 827,732/219 [128] |
| 16/8 s/150 m | 244,292 | 494,457/1064 [593] | 539,054/491 [339] | 607,824/300 [195] | 827,975/220 [127] |
| 17/8.5 s/150 m | 250,016 | 498,562/1052 [615] | 563,459/490 [346] | 599,763/282 [194] | 691,627/176 [125] |
| 18/9 s/150 m | 258,524 | 493,555/1028 [644] | 562,615/482 [344] | 598,919/277 [191] | 690,758/176 [126] |
| 19/9.5 s/150 m | 265,850 | 516,232/1092 [678] | 558,787/484 [347] | 595,091/277 [191] | 686,896/176 [124] |
| 20/10 s/150 m | 266,066 | 510,521/1084 [668] | 555,561/478 [341] | 591,877/277 [195] | 683,643/176 [127] |

### sloans descent

| Frame/time/alt | Reference fine T | 100 m T/D [fineD] | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|
| 0/0 s/600 m | 320,036 | 413,060/1244 [1041] | 459,083/562 [499] | 462,742/317 [280] | 848,518/251 [186] |
| 1/0.5 s/572 m | 324,090 | 412,304/1235 [1045] | 459,083/562 [502] | 462,742/317 [281] | 848,518/251 [187] |
| 2/1 s/544 m | 328,917 | 412,304/1235 [1043] | 459,083/562 [502] | 462,742/317 [281] | 848,518/251 [187] |
| 3/1.5 s/516 m | 334,140 | 454,562/1316 [1045] | 454,562/552 [500] | 454,562/305 [279] | 848,518/251 [185] |
| 4/2 s/488 m | 349,598 | 454,562/1316 [1079] | 454,562/552 [500] | 454,562/305 [279] | 848,518/251 [185] |
| 5/2.5 s/460 m | 364,817 | 454,562/1316 [1103] | 454,562/552 [499] | 454,562/305 [279] | 848,518/251 [185] |
| 6/3 s/432 m | 355,607 | 452,257/1303 [1089] | 454,562/552 [494] | 454,562/305 [281] | 848,518/251 [190] |
| 7/3.5 s/404 m | 345,277 | 438,313/1217 [1078] | 454,562/552 [493] | 454,562/305 [286] | 848,518/251 [200] |
| 8/4 s/376 m | 329,871 | 423,772/1149 [1020] | 426,627/493 [455] | 454,562/305 [268] | 848,518/251 [186] |
| 9/4.5 s/348 m | 327,007 | 413,412/1132 [962] | 425,503/484 [451] | 542,556/344 [267] | 848,518/251 [191] |
| 10/5 s/320 m | 312,041 | 401,710/1114 [907] | 425,503/484 [423] | 542,556/344 [234] | 848,518/251 [189] |
| 11/5.5 s/292 m | 288,775 | 375,703/1017 [837] | 380,857/437 [401] | 469,975/275 [214] | 848,518/251 [174] |
| 12/6 s/264 m | 261,586 | 350,283/961 [768] | 380,857/437 [383] | 469,975/275 [206] | 848,518/251 [166] |
| 13/6.5 s/236 m | 237,454 | 437,782/1079 [677] | 540,584/540 [344] | 684,302/346 [196] | 848,518/251 [151] |
| 14/7 s/208 m | 225,676 | 446,969/1069 [615] | 559,881/544 [327] | 684,302/346 [191] | 848,518/251 [137] |
| 15/7.5 s/180 m | 218,092 | 446,963/1067 [580] | 559,881/544 [317] | 684,302/346 [183] | 848,518/251 [125] |
| 16/8 s/152 m | 205,378 | 439,857/1011 [518] | 540,784/501 [286] | 604,388/295 [154] | 824,329/219 [102] |
| 17/8.5 s/124 m | 185,843 | 400,657/882 [454] | 535,731/490 [260] | 593,879/277 [136] | 685,514/176 [93] |
| 18/9 s/96 m | 132,398 | 435,850/899 [297] | 535,731/490 [157] | 593,879/277 [95] | 685,514/176 [67] |
| 19/9.5 s/68 m | 83,041 | 366,617/693 [196] | 476,858/384 [140] | 593,879/277 [84] | 685,514/176 [60] |
| 20/10 s/40 m | 49,844 | 312,157/564 [97] | 424,536/338 [90] | 593,879/277 [62] | 685,514/176 [45] |

### lakeview pan

| Frame/time/alt | Reference fine T | 100 m T/D [fineD] | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|
| 0/0 s/150 m | 86,629 | 218,632/338 [143] | 310,403/298 [101] | 373,451/208 [82] | 409,127/170 [63] |
| 1/0.5 s/150 m | 88,493 | 223,350/347 [146] | 313,351/302 [105] | 376,519/212 [87] | 412,279/173 [68] |
| 2/1 s/150 m | 91,130 | 223,964/354 [159] | 314,345/307 [116] | 377,573/216 [94] | 413,393/176 [74] |
| 3/1.5 s/150 m | 95,895 | 223,951/367 [174] | 315,920/316 [126] | 379,208/225 [100] | 414,649/182 [80] |
| 4/2 s/150 m | 102,294 | 221,465/373 [181] | 313,704/310 [129] | 377,172/224 [102] | 412,613/181 [82] |
| 5/2.5 s/150 m | 113,957 | 218,671/379 [199] | 311,780/313 [139] | 375,248/227 [102] | 410,713/182 [82] |
| 6/3 s/150 m | 116,528 | 214,243/376 [203] | 309,458/305 [139] | 373,106/224 [99] | 408,571/180 [79] |
| 7/3.5 s/150 m | 125,117 | 213,673/386 [239] | 315,993/323 [166] | 371,896/230 [113] | 407,361/183 [93] |
| 8/4 s/150 m | 128,041 | 210,075/378 [252] | 313,725/317 [176] | 369,868/228 [122] | 405,333/181 [102] |
| 9/4.5 s/150 m | 133,693 | 242,018/412 [258] | 313,675/312 [178] | 369,938/224 [124] | 405,403/179 [105] |
| 10/5 s/150 m | 150,628 | 255,028/429 [262] | 311,443/301 [171] | 368,006/228 [130] | 403,471/181 [111] |
| 11/5.5 s/150 m | 152,464 | 274,076/453 [266] | 368,602/355 [173] | 434,831/282 [131] | 490,641/229 [112] |
| 12/6 s/150 m | 158,671 | 272,902/455 [283] | 367,872/352 [182] | 434,161/281 [136] | 489,971/228 [116] |
| 13/6.5 s/150 m | 164,891 | 296,408/496 [299] | 373,737/365 [190] | 434,849/277 [140] | 490,659/226 [117] |
| 14/7 s/150 m | 170,683 | 295,964/503 [315] | 373,891/365 [199] | 435,003/268 [134] | 490,813/221 [114] |
| 15/7.5 s/150 m | 175,627 | 295,972/514 [323] | 374,223/374 [202] | 435,395/272 [131] | 491,229/225 [111] |
| 16/8 s/150 m | 179,814 | 294,490/517 [324] | 373,437/374 [199] | 434,609/269 [126] | 490,443/224 [110] |
| 17/8.5 s/150 m | 179,872 | 294,961/536 [347] | 372,677/379 [204] | 433,849/269 [126] | 489,707/225 [113] |
| 18/9 s/150 m | 180,567 | 313,440/537 [348] | 372,450/373 [200] | 433,622/265 [123] | 489,540/221 [115] |
| 19/9.5 s/150 m | 187,221 | 314,356/497 [346] | 358,055/334 [196] | 423,838/241 [119] | 490,626/218 [115] |
| 20/10 s/150 m | 203,181 | 322,052/469 [318] | 356,478/318 [191] | 417,650/226 [114] | 490,594/213 [111] |

### lakeview descent

| Frame/time/alt | Reference fine T | 100 m T/D [fineD] | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|
| 0/0 s/600 m | 72,065 | 215,345/407 [180] | 330,475/338 [131] | 381,801/245 [100] | 403,471/181 [44] |
| 1/0.5 s/572 m | 88,453 | 215,345/407 [191] | 330,475/338 [134] | 381,801/245 [101] | 403,471/181 [45] |
| 2/1 s/544 m | 90,505 | 215,345/407 [191] | 330,475/338 [134] | 381,801/245 [100] | 403,471/181 [45] |
| 3/1.5 s/516 m | 93,584 | 215,345/407 [203] | 330,475/338 [134] | 381,801/245 [99] | 403,471/181 [46] |
| 4/2 s/488 m | 93,868 | 215,345/407 [207] | 330,475/338 [132] | 381,801/245 [96] | 403,471/181 [46] |
| 5/2.5 s/460 m | 93,982 | 218,041/414 [208] | 330,475/338 [132] | 381,801/245 [96] | 403,471/181 [46] |
| 6/3 s/432 m | 118,404 | 239,366/448 [246] | 330,475/338 [161] | 381,801/245 [122] | 403,471/181 [75] |
| 7/3.5 s/404 m | 119,224 | 239,366/448 [255] | 330,475/338 [167] | 381,801/245 [125] | 403,471/181 [80] |
| 8/4 s/376 m | 119,056 | 239,366/448 [258] | 330,475/338 [171] | 381,801/245 [121] | 403,471/181 [82] |
| 9/4.5 s/348 m | 122,141 | 233,912/433 [261] | 330,475/338 [176] | 381,801/245 [120] | 403,471/181 [82] |
| 10/5 s/320 m | 131,675 | 231,673/426 [261] | 330,475/338 [177] | 381,801/245 [116] | 403,471/181 [82] |
| 11/5.5 s/292 m | 142,319 | 227,555/419 [274] | 324,631/329 [186] | 381,801/245 [118] | 403,471/181 [85] |
| 12/6 s/264 m | 143,717 | 227,555/419 [273] | 324,631/329 [186] | 381,801/245 [119] | 403,471/181 [88] |
| 13/6.5 s/236 m | 144,020 | 221,975/405 [295] | 318,961/321 [203] | 370,287/235 [136] | 403,471/181 [106] |
| 14/7 s/208 m | 143,083 | 221,975/405 [296] | 318,961/321 [202] | 370,287/235 [137] | 403,471/181 [111] |
| 15/7.5 s/180 m | 145,550 | 269,415/454 [279] | 318,961/321 [189] | 370,287/235 [137] | 403,471/181 [113] |
| 16/8 s/152 m | 151,371 | 255,028/429 [264] | 311,443/301 [172] | 368,006/228 [130] | 403,471/181 [111] |
| 17/8.5 s/124 m | 133,849 | 265,493/425 [217] | 365,467/350 [139] | 431,576/272 [107] | 489,607/225 [99] |
| 18/9 s/96 m | 115,229 | 249,768/366 [194] | 342,725/290 [128] | 416,759/239 [103] | 489,607/225 [103] |
| 19/9.5 s/68 m | 94,563 | 233,023/313 [156] | 342,725/290 [111] | 416,759/239 [94] | 489,607/225 [94] |
| 20/10 s/40 m | 47,686 | 204,674/281 [82] | 342,725/290 [57] | 416,759/239 [54] | 489,607/225 [54] |

### wilmette pan

| Frame/time/alt | Reference fine T | 100 m T/D [fineD] | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|
| 0/0 s/150 m | 341,766 | 479,384/1379 [1063] | 566,100/643 [486] | 655,706/350 [268] | 753,566/232 [175] |
| 1/0.5 s/150 m | 332,058 | 480,543/1393 [1022] | 570,835/653 [483] | 661,013/354 [262] | 757,305/239 [177] |
| 2/1 s/150 m | 324,280 | 472,532/1381 [1000] | 575,362/661 [486] | 666,152/357 [261] | 761,115/240 [178] |
| 3/1.5 s/150 m | 314,363 | 474,059/1370 [990] | 576,986/680 [494] | 668,182/367 [267] | 761,709/253 [186] |
| 4/2 s/150 m | 305,008 | 475,391/1385 [986] | 579,832/690 [492] | 671,596/365 [263] | 763,481/254 [184] |
| 5/2.5 s/150 m | 297,022 | 422,292/1253 [966] | 463,020/586 [479] | 674,968/359 [249] | 766,179/255 [178] |
| 6/3 s/150 m | 289,982 | 398,901/1189 [947] | 464,331/596 [469] | 676,316/360 [240] | 766,255/257 [168] |
| 7/3.5 s/150 m | 280,089 | 400,841/1209 [928] | 466,325/607 [455] | 677,892/365 [227] | 766,731/262 [157] |
| 8/4 s/150 m | 272,130 | 393,234/1196 [907] | 467,585/611 [446] | 679,095/366 [222] | 767,124/263 [153] |
| 9/4.5 s/150 m | 266,600 | 394,175/1181 [860] | 468,562/613 [438] | 680,665/361 [215] | 767,618/259 [149] |
| 10/5 s/150 m | 250,788 | 383,287/1144 [809] | 470,169/614 [404] | 681,729/360 [192] | 767,464/258 [126] |
| 11/5.5 s/150 m | 241,609 | 385,185/1162 [807] | 472,133/618 [396] | 683,236/363 [188] | 768,191/260 [123] |
| 12/6 s/150 m | 228,458 | 376,415/1138 [784] | 442,252/573 [385] | 684,237/365 [184] | 768,688/260 [120] |
| 13/6.5 s/150 m | 224,157 | 378,068/1145 [771] | 443,964/581 [370] | 684,761/374 [181] | 768,768/262 [118] |
| 14/7 s/150 m | 213,898 | 334,620/1038 [746] | 445,890/579 [357] | 686,217/376 [174] | 769,864/260 [112] |
| 15/7.5 s/150 m | 207,724 | 322,417/994 [723] | 423,172/543 [356] | 640,947/340 [174] | 772,488/262 [112] |
| 16/8 s/150 m | 200,318 | 323,055/995 [720] | 425,844/545 [354] | 642,123/342 [173] | 773,699/260 [111] |
| 17/8.5 s/150 m | 193,094 | 318,930/980 [691] | 428,043/556 [349] | 640,235/346 [172] | 771,846/260 [110] |
| 18/9 s/150 m | 185,750 | 303,136/931 [664] | 432,278/552 [339] | 640,471/345 [172] | 772,087/255 [111] |
| 19/9.5 s/150 m | 178,157 | 303,866/936 [653] | 436,856/557 [333] | 641,237/348 [170] | 772,813/258 [110] |
| 20/10 s/150 m | 171,193 | 304,908/929 [620] | 444,076/557 [326] | 643,582/350 [167] | 775,088/265 [109] |

### wilmette descent

| Frame/time/alt | Reference fine T | 100 m T/D [fineD] | 200 m | 400 m | 800 m |
|---|---:|---:|---:|---:|---:|
| 0/0 s/600 m | 1,986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |
| 1/0.5 s/572 m | 1,986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |
| 2/1 s/544 m | 1,986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |
| 3/1.5 s/516 m | 1,986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |
| 4/2 s/488 m | 1,986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |
| 5/2.5 s/460 m | 1,986 | 11,559/32 [2] | 43,373/50 [2] | 118,741/56 [2] | 167,187/56 [2] |
| 6/3 s/432 m | 3,277 | 34,546/132 [25] | 83,778/136 [22] | 199,698/132 [19] | 299,518/108 [14] |
| 7/3.5 s/404 m | 12,503 | 40,797/172 [69] | 135,105/217 [53] | 299,518/184 [40] | 299,518/108 [22] |
| 8/4 s/376 m | 22,372 | 53,090/248 [111] | 156,132/244 [83] | 299,518/184 [64] | 299,518/108 [23] |
| 9/4.5 s/348 m | 32,462 | 62,454/274 [151] | 156,132/244 [102] | 299,518/184 [73] | 299,518/108 [25] |
| 10/5 s/320 m | 50,661 | 120,242/432 [234] | 183,996/271 [141] | 299,518/184 [104] | 299,518/108 [50] |
| 11/5.5 s/292 m | 79,534 | 128,746/457 [365] | 221,980/321 [184] | 299,518/184 [124] | 299,518/108 [61] |
| 12/6 s/264 m | 108,558 | 191,509/629 [405] | 283,422/393 [212] | 299,518/184 [124] | 299,518/108 [61] |
| 13/6.5 s/236 m | 147,950 | 259,151/814 [544] | 283,422/393 [302] | 299,518/184 [128] | 299,518/108 [63] |
| 14/7 s/208 m | 185,264 | 319,963/977 [619] | 413,498/526 [334] | 633,794/315 [149] | 767,464/258 [83] |
| 15/7.5 s/180 m | 220,303 | 319,963/977 [744] | 413,498/526 [366] | 633,794/315 [163] | 767,464/258 [97] |
| 16/8 s/152 m | 247,559 | 383,287/1144 [806] | 470,169/614 [402] | 681,729/360 [190] | 767,464/258 [124] |
| 17/8.5 s/124 m | 276,885 | 399,530/1190 [884] | 470,169/614 [448] | 681,729/360 [220] | 767,464/258 [154] |
| 18/9 s/96 m | 297,570 | 468,857/1321 [941] | 588,741/715 [454] | 681,729/360 [225] | 767,464/258 [159] |
| 19/9.5 s/68 m | 311,175 | 528,171/1430 [985] | 643,052/764 [474] | 681,729/360 [242] | 767,464/258 [176] |
| 20/10 s/40 m | 328,418 | 528,171/1430 [1019] | 643,052/764 [506] | 681,729/360 [245] | 767,464/258 [179] |

## Far-parent merging and geometric LOD

Lossless count model uses 200 m children and 800 m parents. A parent is eligible only if **its complete actual padded union bound** has nearest 3D eye distance ≥threshold; otherwise retain 200 m children. Selection is exclusive parent-or-children; whole intersecting tiles are submitted. Triangle simplification receives **zero** credit. Parent merging retains the exact compatibility keys, so this is not the material-name-only lower bound.

| Area 600 m | 400 m merge threshold T/D | 800 m threshold T/D | 1600 m threshold T/D |
|---|---:|---:|---:|
| sloans | 848,518/251 | 459,083/562 | 459,083/562 |
| lakeview | 403,471/181 | 330,475/338 | 330,475/338 |
| wilmette | 167,187/56 | 43,373/50 | 43,373/50 |

The measured fine/global-static counterfactual at Sloan 600 m was 320,036/109, exact pixels, only 3 draws fewer than 112. It is a **different policy** from per-cell parent merging and cannot be substituted for the table. No tested current exact-compatibility rule reaches ≤100 there. The parent model is not a pixel test, and any further geometry/material/transform merging needs separate proof.

At 600 m, the 400 m distance threshold selects 4 Sloan /3 Lakeview /1 Wilmette parents and predicts 251/181/56 draws; 800 m and 1600 m select none in these frozen core views, leaving 562/338/50. Sloan's aggressive aggregation increases 459,083→848,518 triangles while lowering 562→251 draws. Therefore 800 m is a conservative **starting hypothesis**, not a calibrated optimum or a solution for the current 600 m core draw excess. Large crossing features inflate parent bounds; independently paging them changes eligibility and needs a fresh model. The recommended all-child-selected guard can restrict aggregation further. **A simplified-parent 600 m draw count remains unmeasured without an export**; no invented ≤100 result is claimed.

**Exact aggregation and geometric simplification are different operations.** An exact parent keeps all child triangles, attributes, transforms and draw ordering; it may submit extra off-frustum geometry and consume more triangles. It need not reduce draws if child materials, model matrices, vertex layouts or ordering are incompatible. A simplified parent removes detail and changes pixels; it needs projected-error limits, matched repeat controls, hold-outs and A3 review. Do not call it exact because projected height is small or fog makes a difference hard to see.

Candidate distance: select an 800 m parent only when all its represented child content is selected, its **entire actual padded bound** is at least 800 m in 3D from the eye, all children are loaded, all children meet the same chosen representation/error contract and material/order compatibility is satisfied. Compare 400/800/1600 m thresholds above rather than using camera altitude as a special case. Use 10% enter/exit hysteresis as an authored starting hypothesis, then test transitions; do not combine parent and children in main. If the parent is partly visible or exceeds the main budget, retain leaf/child selection; “far” does not override a triangle/draw ceiling. A 200 m resident page is a storage grouping, not permission to disable its 100 m child visibility metadata or feature bounds at partial leaves. Use precomputed immutable vertex data plus bounded reused index/instance ranges; index changes and any copied transforms still incur CPU/upload cost. WebGL2 cannot be presumed to submit arbitrary disjoint spans as one draw without a supported, tested batching path. Per-leaf draws alone do not meet the measured floor. Compatible 400/800 m render groups retain selected ranges without requiring the full parent tile. Additional intra-leaf boundary selection and cross-cell instance pooling are essential parts of this candidate, with unmeasured runtime cost. The distance-only parent table above is a conservative experiment; adding the all-child-selected guard can only restrict merging further.

A lossless parent must preserve original floating-point vertex values plus transforms and deterministic primitive/instance order. Existing chunk-relative model matrices split otherwise shared water/static materials. Rebaking into one common coordinate frame can reduce those splits, but changes floating-point arithmetic and potentially depth ties; it is **not yet pixel-exact**. Never remove a compatibility key merely to reproduce an optimistic model. A hypothetical exporter with one shared coordinate frame/state may have a lower draw count, but that is a new equivalence experiment, not a measured saving here.

For a simplified parent, record a conservative object-space error bound `E` and evaluate projected error using drawable height, vertical FOV and minimum positive camera-space depth of the complete bound. The planning relation is `errorPx ≈ E × heightPx / (2 × tan(FOVy/2) × depthMin)`; it is not an exact pixel guarantee and must be tightened for perspective, silhouette and near-plane crossings. Retain children if the bound crosses the eye/near plane. A nonzero error threshold is a quality decision for R/A3, not an approved value in this design. Exact parents declare zero geometry error but still require ordering and floating-point equivalence tests.

Existing package LOD1 is a separate, visibly risky option: the old Sloan diagnosis modeled 400 m chunk-distance replacement at 600 m from 624,433 to 393,675 triangles, **still 292 draws**, before fine visibility. Savings overlap culling, cannot be added to the 205k/320k fine-selected figures, and are not a proof of our hierarchical tile costs. At 600 m a 10 m feature roughly 1 km away can still span 6 px in this 565 px/50° viewport. Silhouettes, road markings, shore boundaries, roof depth and shadows can therefore change well before a tile is “far.” Preserve roads/water continuity and original feature identity; no block-specific LOD, missing-city camouflage, tree deletion or budget promotion by camera class.

## Exporter contract

A future exporter must emit deterministic, versioned data, not camera-fitted meshes:

- Shared world/local frame, vertical datum, grid origin and half-open integer cell addressing; retain exact existing vertex/attribute bytes and per-source transform identity in the lossless representation. Whole features get one owner leaf based on a deterministic representative point; actual bounds include cross-cell geometry. Oversized features such as lakes/terrain need explicit multi-cell dependencies or independent bounded pages, never duplicated full geometry in every overlapping leaf. Clipping/retessellation is a separate pixel-risk operation. Retain factual source IDs and provenance.
- Leaf bounds, category counts, per-feature ranges, instance/prototype/recipe/season identities, immutable index spans and material/state/layout keys; bounds include every vertex and required animation margin. Per-LOD byte/triangle/draw estimates describe actual submitted batches, not a nominal one-material/one-tile shortcut. Stable ordering keys cover coplanar and transparent content. Multiple spans do not automatically equal one draw; web and RealityKit must account for their chosen submission mechanism.
- A parent/child hierarchy at 200/400/800 m, with coverage masks, child hashes, shared resources, replacement exclusivity, parent-bound/error data and material-compatible batches. Exact and simplified representations are explicitly distinguished. Include road/water seam contracts and core/context exclusion IDs. Parents can reuse index/vertex resources where supported; otherwise charge duplicated storage and old/new overlap.
- Manifest byte counts/hashes and allocation descriptors for compressed transfer, decoded arrays, instance/index/vertex buffers, textures and render targets. Publish resident and transition upper bounds from actual layouts. Supply main and shadow bounds/costs independently; off-camera casters remain required where their shadows enter receivers. No measured compression or native-memory claim is inferred from a triangle count.

These are requested future schema fields, not a file-format edit in this task. A1/A4/P2/5A need an explicit implementation handoff before consuming them. Preserve backwards compatibility or version-gate the new format; “the loader reads unchanged” cannot be assumed for premerged parents.

## Renderer responsibilities

**Web:** replace per-frame geometry clones/merge/dispose/upload with resident immutable batches and reused bounded instance/index buffers. Traverse precomputed bounds/hierarchy; select stable spans/tiles and make atomic parent↔children transitions. Rendering API may still require one draw per compatible span: count it, do not assume WebGL multidraw or material arrays are pixel-equivalent. Reuse capacity, charge updates/upload queues, enforce cancellation/eviction and prevent disposed/retired buffers remaining reachable. Keep default route separate until qualified. Preserve the original material/shader/exposure/near-plane rules and main/shadow separation. Existing 1001 instance-capacity workaround is an implementation artifact, not a packaging budget.

**RealityKit:** preserve native widened-frustum/shadow-union and 3D foliage policy (`World.swift:828–896`), existing adaptive ground/building tiles and bounds. Map immutable pages to actual compatible mesh/material/instance resources; native auto-batching and Metal submissions may differ from web. `estimateView` CPU accounting is not actual draw proof. Measure main and every shadow pass, instance counts, CPU selection/update time, uploads, allocation peaks and sustained device thermal behavior. Do not promise that a web tile is one RealityKit draw or transplant web cache/material UUID/GL buffer counts. R's 14 Pro is the standard test device, not floor certification.

Both must reconcile actual submitted costs against the floor **<400k main, ≤150k all-shadow triangles, ≤100 main draws**, including sky, context, props and foliage. Keep a coarse parent only as a truthful loading fallback; preserve coverage and do not show unknown data as complete. Scene-ready includes selected coverage/resources and completed frames, not merely completed file downloads. Test 40/150/600, continuous translation/descent/rotation, boundary crossings, FOV/resolution changes, cache eviction and source-season changes.

## Streamed context and crowns

Combine with **A5's streamed-context design** in [world-edge-options](world-edge-options.md), preserving that document's package/runtime ownership handoffs. Core and context use the same cell/hierarchy/coverage protocol; clip/deduplicate context by source identity against the detailed core. Keep one conservative coarse parent resident while finer children arrive, prefetch along camera motion and evict outside bounded residency. Core export reorganization does not supply missing city: existing web context source provenance is not renderable context geometry. Lakeview building coverage is only 0.5 km beyond the core, smaller than its 600 m ground frustum; no tessellation choice can invent the missing band or repair omitted Lake Michigan relations. Audit full road/shore/water coverage before exporting a band.

The plan's extra 20–40k main triangles / 4–8 context draws are **planning envelopes**, not new measurements. Charge them against the same whole-scene budget before crowns; current Sloan 600 m 112 draws already leaves negative floor draw headroom. A coarse distant land/water tier may lower the context cost only beyond approved feature readability, not at the arbitrary core edge. Package bytes, decoded/GPU residency and parent-child overlap must remain bounded on the phone/network path.

Crowns use the same visible-instance IDs and persistent resources, but keep allocator policy separate from spatial residency. Count the actual selected recipe/LOD/season/prototype costs and occupied material slots; nearest-first promotions use 3D eye distance and stable source-ID tie-breaks. Reserve non-foliage/context N, unchanged non-elm foliage U, shadow reach and draw reserve before deriving F/E per [crowns](crowns.md). Do not spend a guessed cell-model saving on near crowns. Parent simplification must not duplicate/omit trees or freeze a parent crown LOD inconsistent with the allocator. If an exact parent cannot coexist with mixed crown LOD/material slots, retain instances/children and report the draw cost. Shape LOD is pixel-changing and needs its own gate; export-time cells do not rehabilitate the failed v3/allocator combination.

## Unproved work and next decision

This offline model establishes count tradeoffs for existing core exports and frozen conditions. It does **not** prove pixels, bounds under future shaders, ordering across cells, GPU/CPU timing, peak residency, streaming coverage, phone thermal performance, native batch counts or crown/context costs. The already observed pixel failures forbid an exactness claim even where a model reproduces triangles/draws. A successful design will require a separately authorized exporter prototype and renderer adapter, then immutable-resource accounting, matched default repeats and hold-outs, motion transitions and actual device measurements. No new export, render code, capture, score, budget change or default activation was made here.

Offline validation: all 135 modeled poses (9 ladder +126 motion), all 4 cell sizes, integer/count/subset arithmetic checked; 51/51 measured default/variant pairs match. Final model admission load 12.72<25; lock released immediately on exit 0. Docs-only merge needs no renderer build, full test suite or new capture.

## Ledger text for A3

A10 export-time spatial-cell design only: calibrated against 887057d measured core counts; proposes 100 m visibility leaves, 200 m resident pages, compatible 400/800 m draw groups and conditional 800 m geometric far parents with stable resources. All model tables distinguish fine visible content from whole-tile submitted work and preserve compatibility fragmentation. No exact pixel, floor/device or context/crown adoption claim. Exporter schema/renderer handoff and measured resident/transition costs remain pending. No INTEGRATION/STATE/handoffs edits by A10.

Used: scene-budget-qualification.md §§Hold-outs–RealityKit; scene-budget-diagnosis.md §Fine visibility; world-edge-options.md; crowns.md §Budget and nearest-first allocation. Mock: retained measured default ladder/motion frames. Deviation: offline count model/design only; no exports, captures or pixel proof.
