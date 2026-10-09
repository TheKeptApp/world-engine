# World scoreboard v0 — automatic technical screen

Status: **completed-with-failures**. Commit `1fcb2331dafc891d001a23e7eab2446e5a6025a8`; 871.5 s wall time, including admission waits.
Selection: all 8 held areas, sorted by ID; shortfall to 12: 4. No data fetched.
Renderer: `shipping-web-modules/WebGL2/package-light-state/crown-off/no-host-character`. Counts are submissions, not package totals; standard limits are provisional. No human grades.

| Block | Type | m | Main tris/draws | Shadow tris/draws | Floor | Standard | Blank ground | Buildings source/export | Water source/export | Parks source/export | Tunnel strips | Near clip triangles |
|---|---|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|
| evanston-south | suburban | 40 | 544177/214 | 419142/125 | FAIL | FAIL | 10.5% | 887/887 | 0/0 | 3/3 | 0 | 0 |
| evanston-south | suburban | 150 | 506058/204 | 424718/150 | FAIL | FAIL | 14.3% | 887/887 | 0/0 | 3/3 | 0 | 0 |
| evanston-south | suburban | 600 | 342496/211 | 56720/4 | FAIL | FAIL | 71.7% | 887/887 | 0/0 | 3/3 | 0 | 0 |
| greenville-downtown | park/water | 40 | 417520/111 | 307703/35 | FAIL | FAIL | 11.1% | 681/681 | 7/7 | 8/8 | 0 | 0 |
| greenville-downtown | park/water | 150 | 461065/170 | 312464/70 | FAIL | FAIL | 28.6% | 681/681 | 7/7 | 8/8 | 0 | 0 |
| greenville-downtown | park/water | 600 | 429771/199 | 0/0 | FAIL | FAIL | 63.4% | 681/681 | 7/7 | 8/8 | 0 | 0 |
| kenilworth-station | suburban | 40 | 430026/198 | 264347/108 | FAIL | FAIL | 32.8% | 816/816 | 0/0 | 4/4 | 0 | 0 |
| kenilworth-station | suburban | 150 | 425112/216 | 345468/138 | FAIL | FAIL | 14.7% | 816/816 | 0/0 | 4/4 | 0 | 0 |
| kenilworth-station | suburban | 600 | 361784/213 | 49127/4 | FAIL | FAIL | 66.4% | 816/816 | 0/0 | 4/4 | 0 | 0 |
| lakeview-sheil-park | dense grid | 40 | 1057862/210 | 924485/123 | FAIL | FAIL | 17.9% | 2823/2823 | 0/0 | 3/3 | 0 | 0 |
| lakeview-sheil-park | dense grid | 150 | 1181951/224 | 996184/149 | FAIL | FAIL | 6.8% | 2823/2823 | 0/0 | 3/3 | 0 | 0 |
| lakeview-sheil-park | dense grid | 600 | 936137/203 | 2280/1 | FAIL | FAIL | 66.2% | 2823/2823 | 0/0 | 3/3 | 0 | 0 |
| sloans-lake | park/water | 40 | 656455/169 | 560465/111 | FAIL | FAIL | 3.0% | 1399/1399 | 5/5 | 2/1 | 0 | 0 |
| sloans-lake | park/water | 150 | 785315/238 | 572162/113 | FAIL | FAIL | 1.5% | 1399/1399 | 5/5 | 2/1 | 0 | 0 |
| sloans-lake | park/water | 600 | 502656/285 | 75831/4 | FAIL | FAIL | 31.1% | 1399/1399 | 5/5 | 2/1 | 0 | 0 |
| west-highland | park/water | 40 | 818648/233 | 678189/138 | FAIL | FAIL | 2.6% | 2495/2495 | 0/0 | 1/1 | 0 | 0 |
| west-highland | park/water | 150 | 747771/239 | 790133/146 | FAIL | FAIL | 2.1% | 2495/2495 | 0/0 | 1/1 | 0 | 0 |
| west-highland | park/water | 600 | 599781/222 | 147346/9 | FAIL | FAIL | 65.2% | 2495/2495 | 0/0 | 1/1 | 0 | 0 |
| wilmette-vattmann-park | mixed | 40 | 553853/191 | 410139/114 | FAIL | FAIL | 19.9% | 1259/1258 | 0/0 | 4/4 | 0 | 0 |
| wilmette-vattmann-park | mixed | 150 | 534459/207 | 454124/154 | FAIL | FAIL | 2.7% | 1259/1258 | 0/0 | 4/4 | 0 | 0 |
| wilmette-vattmann-park | mixed | 600 | 366066/197 | 34776/2 | FAIL | FAIL | 66.8% | 1259/1258 | 0/0 | 4/4 | 0 | 0 |
| winnetka-village-green | suburban | 40 | 326713/180 | 224875/102 | FAIL | FAIL | 6.8% | 582/582 | 0/0 | 4/4 | 0 | 0 |
| winnetka-village-green | suburban | 150 | 324005/197 | 253587/130 | FAIL | FAIL | 21.4% | 582/582 | 0/0 | 4/4 | 0 | 0 |
| winnetka-village-green | suburban | 600 | 236959/202 | 0/0 | FAIL | FAIL | 74.1% | 582/582 | 0/0 | 4/4 | 0 | 0 |

## Failures and warnings

- evanston-south/40: budget-floor, budget-standard
- evanston-south/150: budget-floor, budget-standard
- evanston-south/600: blank-ground, budget-floor, budget-standard
- greenville-downtown/40: budget-floor, budget-standard
- greenville-downtown/150: budget-floor, budget-standard
- greenville-downtown/600: blank-ground, budget-floor, budget-standard
- kenilworth-station/40: budget-floor, budget-standard
- kenilworth-station/150: budget-floor, budget-standard
- kenilworth-station/600: blank-ground, budget-floor, budget-standard
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
- winnetka-village-green/40: budget-floor, budget-standard
- winnetka-village-green/150: budget-floor, budget-standard
- winnetka-village-green/600: blank-ground, budget-floor, budget-standard

## Diff against previous JSON

```json
{
  "status": "compared",
  "previousCommit": "d82a68de8ed53e9f28f5671a078a8630c2c57a0b",
  "added": [],
  "removed": [],
  "changes": [
    {
      "key": "greenville-downtown/40",
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 417590,
          "current": 417520,
          "delta": -70
        }
      },
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
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 461301,
          "current": 461065,
          "delta": -236
        },
        "mainDraws": {
          "previous": 171,
          "current": 170,
          "delta": -1
        }
      },
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
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 429835,
          "current": 429771,
          "delta": -64
        }
      },
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
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 430028,
          "current": 430026,
          "delta": -2
        },
        "shadowTriangles": {
          "previous": 264349,
          "current": 264347,
          "delta": -2
        },
        "tunnelSurfaceRanges": {
          "previous": 1,
          "current": 0,
          "delta": -1
        }
      },
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "kenilworth-station/150",
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 425114,
          "current": 425112,
          "delta": -2
        },
        "shadowTriangles": {
          "previous": 345470,
          "current": 345468,
          "delta": -2
        },
        "tunnelSurfaceRanges": {
          "previous": 1,
          "current": 0,
          "delta": -1
        }
      },
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "kenilworth-station/600",
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 361786,
          "current": 361784,
          "delta": -2
        },
        "tunnelSurfaceRanges": {
          "previous": 1,
          "current": 0,
          "delta": -1
        }
      },
      "failuresBefore": [
        "tunnel",
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
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 656467,
          "current": 656455,
          "delta": -12
        }
      },
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
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 785361,
          "current": 785315,
          "delta": -46
        }
      },
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
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 502798,
          "current": 502656,
          "delta": -142
        }
      },
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
      "key": "winnetka-village-green/40",
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 326717,
          "current": 326713,
          "delta": -4
        },
        "tunnelSurfaceRanges": {
          "previous": 1,
          "current": 0,
          "delta": -1
        }
      },
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "winnetka-village-green/150",
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 324009,
          "current": 324005,
          "delta": -4
        },
        "tunnelSurfaceRanges": {
          "previous": 1,
          "current": 0,
          "delta": -1
        }
      },
      "failuresBefore": [
        "tunnel",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "budget-floor",
        "budget-standard"
      ]
    },
    {
      "key": "winnetka-village-green/600",
      "comparable": true,
      "reason": null,
      "metrics": {
        "mainTriangles": {
          "previous": 236963,
          "current": 236959,
          "delta": -4
        },
        "tunnelSurfaceRanges": {
          "previous": 1,
          "current": 0,
          "delta": -1
        }
      },
      "failuresBefore": [
        "tunnel",
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ],
      "failuresAfter": [
        "blank-ground",
        "budget-floor",
        "budget-standard"
      ]
    }
  ]
}
```
