# World scoreboard v0 — automatic technical screen

Status: **completed-with-failures**. Commit `054391324f83c911893dea90ae16e029a541f710`; 1003.5 s wall time, including admission waits.
Selection: all 8 held areas, sorted by ID; shortfall to 12: 4. No data fetched.
Renderer: `shipping-web-modules/WebGL2/package-light-state/crown-off/no-host-character`. Counts are submissions, not package totals; standard limits are provisional. No human grades.

| Block | Type | m | Main tris/draws | Shadow tris/draws | Floor | Standard | Blank ground | Buildings source/export | Water source/export | Parks source/export | Tunnel strips | Near clip triangles |
|---|---|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|
| evanston-south | suburban | 40 | 544177/214 | 419142/125 | FAIL | FAIL | 10.5% | 887/887 | 0/0 | 3/3 | 0 | 0 |
| evanston-south | suburban | 150 | 506058/204 | 424718/150 | FAIL | FAIL | 14.3% | 887/887 | 0/0 | 3/3 | 0 | 0 |
| evanston-south | suburban | 600 | 342496/211 | 56720/4 | FAIL | FAIL | 71.7% | 887/887 | 0/0 | 3/3 | 0 | 0 |
| greenville-downtown | park/water | 40 | 417590/111 | 307703/35 | FAIL | FAIL | 11.1% | 681/681 | 7/7 | 8/8 | 0 | 0 |
| greenville-downtown | park/water | 150 | 461301/171 | 312464/70 | FAIL | FAIL | 28.6% | 681/681 | 7/7 | 8/8 | 0 | 0 |
| greenville-downtown | park/water | 600 | 429835/199 | 0/0 | FAIL | FAIL | 63.4% | 681/681 | 7/7 | 8/8 | 0 | 0 |
| kenilworth-station | suburban | 40 | 430028/198 | 264349/108 | FAIL | FAIL | 32.8% | 816/816 | 0/0 | 4/4 | 1 | 0 |
| kenilworth-station | suburban | 150 | 425114/216 | 345470/138 | FAIL | FAIL | 14.7% | 816/816 | 0/0 | 4/4 | 1 | 0 |
| kenilworth-station | suburban | 600 | 361786/213 | 49127/4 | FAIL | FAIL | 66.4% | 816/816 | 0/0 | 4/4 | 1 | 0 |
| lakeview-sheil-park | dense grid | 40 | 1057862/210 | 924485/123 | FAIL | FAIL | 17.9% | 2823/2823 | 0/0 | 3/3 | 0 | 0 |
| lakeview-sheil-park | dense grid | 150 | 1181951/224 | 996184/149 | FAIL | FAIL | 6.8% | 2823/2823 | 0/0 | 3/3 | 0 | 0 |
| lakeview-sheil-park | dense grid | 600 | 936137/203 | 2280/1 | FAIL | FAIL | 66.2% | 2823/2823 | 0/0 | 3/3 | 0 | 0 |
| sloans-lake | park/water | 40 | 656467/169 | 560465/111 | FAIL | FAIL | 3.0% | 1399/1399 | 5/5 | 2/1 | 0 | 0 |
| sloans-lake | park/water | 150 | 785361/238 | 572162/113 | FAIL | FAIL | 1.5% | 1399/1399 | 5/5 | 2/1 | 0 | 0 |
| sloans-lake | park/water | 600 | 502798/285 | 75831/4 | FAIL | FAIL | 31.1% | 1399/1399 | 5/5 | 2/1 | 0 | 0 |
| west-highland | park/water | 40 | 818648/233 | 678189/138 | FAIL | FAIL | 2.6% | 2495/2495 | 0/0 | 1/1 | 0 | 0 |
| west-highland | park/water | 150 | 747771/239 | 790133/146 | FAIL | FAIL | 2.1% | 2495/2495 | 0/0 | 1/1 | 0 | 0 |
| west-highland | park/water | 600 | 599781/222 | 147346/9 | FAIL | FAIL | 65.2% | 2495/2495 | 0/0 | 1/1 | 0 | 0 |
| wilmette-vattmann-park | mixed | 40 | 553853/191 | 410139/114 | FAIL | FAIL | 19.9% | 1259/1258 | 0/0 | 4/4 | 0 | 0 |
| wilmette-vattmann-park | mixed | 150 | 534459/207 | 454124/154 | FAIL | FAIL | 2.7% | 1259/1258 | 0/0 | 4/4 | 0 | 0 |
| wilmette-vattmann-park | mixed | 600 | 366066/197 | 34776/2 | FAIL | FAIL | 66.8% | 1259/1258 | 0/0 | 4/4 | 0 | 0 |
| winnetka-village-green | suburban | 40 | 326717/180 | 224875/102 | FAIL | FAIL | 6.8% | 582/582 | 0/0 | 4/4 | 1 | 0 |
| winnetka-village-green | suburban | 150 | 324009/197 | 253587/130 | FAIL | FAIL | 21.4% | 582/582 | 0/0 | 4/4 | 1 | 0 |
| winnetka-village-green | suburban | 600 | 236963/202 | 0/0 | FAIL | FAIL | 74.1% | 582/582 | 0/0 | 4/4 | 1 | 0 |

## Failures and warnings

- evanston-south/40: budget-floor, budget-standard
- evanston-south/150: budget-floor, budget-standard
- evanston-south/600: blank-ground, budget-floor, budget-standard
- greenville-downtown/40: budget-floor, budget-standard
- greenville-downtown/150: budget-floor, budget-standard
- greenville-downtown/600: blank-ground, budget-floor, budget-standard
- kenilworth-station/40: tunnel, budget-floor, budget-standard
- kenilworth-station/150: tunnel, budget-floor, budget-standard
- kenilworth-station/600: tunnel, blank-ground, budget-floor, budget-standard
- lakeview-sheil-park/40: budget-floor, budget-standard
- lakeview-sheil-park/150: budget-floor, budget-standard
- lakeview-sheil-park/600: blank-ground, budget-floor, budget-standard
- sloans-lake/40: budget-floor, budget-standard
- sloans-lake/150: budget-floor, budget-standard
- sloans-lake/600: budget-floor, budget-standard
- west-highland/40: budget-floor, budget-standard
- west-highland/150: budget-floor, budget-standard
- west-highland/600: blank-ground, budget-floor, budget-standard
- wilmette-vattmann-park/40: budget-floor, budget-standard
- wilmette-vattmann-park/150: budget-floor, budget-standard
- wilmette-vattmann-park/600: blank-ground, budget-floor, budget-standard
- winnetka-village-green/40: tunnel, budget-floor, budget-standard
- winnetka-village-green/150: tunnel, budget-floor, budget-standard
- winnetka-village-green/600: tunnel, blank-ground, budget-floor, budget-standard

## Diff against previous JSON

```json
{
  "status": "compared",
  "previousCommit": "ee66770058a5b5904677101f636532169a3c88df",
  "added": [],
  "removed": [],
  "changes": [
    {
      "key": "evanston-south/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "evanston-south/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "evanston-south/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "greenville-downtown/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "greenville-downtown/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "greenville-downtown/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "kenilworth-station/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "kenilworth-station/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "kenilworth-station/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "tunnel",
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "tunnel",
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "lakeview-sheil-park/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "lakeview-sheil-park/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "lakeview-sheil-park/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "sloans-lake/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "sloans-lake/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "sloans-lake/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "west-highland/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "west-highland/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "west-highland/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "wilmette-vattmann-park/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "wilmette-vattmann-park/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "wilmette-vattmann-park/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "winnetka-village-green/40",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "winnetka-village-green/150",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "winnetka-village-green/600",
      "comparable": false,
      "reason": "camera, source, renderer kind, harness, or detector contract changed",
      "metrics": {},
      "failuresBefore": [
        "tunnel",
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "tunnel",
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    }
  ]
}
```
