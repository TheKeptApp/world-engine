#!/usr/bin/env python3
"""Generate a build-only foliage variant; never modify the shipping source."""
import argparse
from pathlib import Path

BLOCK = "    // foliage-exp1-spec.md Exact candidate math + R's approved mask amendment, 8 Oct 2026.\n    // Experimental coefficients are fixed guesses. Off retains the original initialized inputs.\n    const int foliageExp1Default = FOLIAGE_EXP1_MODE; // 0=off, 1=remove, 2=layered; shipping default.\n    int foliageExp1Mode = foliageExp1Default;\n    if (foliageExp1Mode < 0 || foliageExp1Mode > 2) { foliageExp1Mode = foliageExp1Default; }\n    bool eligible = extra.y > 0.0 && extra.z < 0.5 && !su.leafCut &&\n        (uint(paint.z + 0.5) & 512u) == 0u &&\n        ((slot >= 3u && slot <= 6u) || (slot >= 24u && slot <= 28u));\n    if (foliageExp1Mode != 0 && eligible) {\n        su.emissive = half3(0.00h);\n        if (foliageExp1Mode == 2) {\n            float A0 = clamp(extra.x, 0.65, 1.00);\n            float t = smoothstep(0.65, 1.00, A0);\n            float A1 = 0.65 + 0.35 * t;\n            float M = 0.94 + 0.06 * t;\n            su.ao = half(A1);\n            su.base *= half(M);\n        }\n    }\n"

p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[1]
s=(root/'Sources/WorldEngine/Shaders/WorldShaders.metal').read_text()
start=s.index('void worldFoliageSurface(');end=s.index('\n/// R10 sway',start)
f=s[start:end];needle='    finish(params, g, su, wp);'
assert f.count(needle)==1
f=f.replace(needle, BLOCK+needle)
a.output.write_text('#ifndef FOLIAGE_EXP1_MODE\n#define FOLIAGE_EXP1_MODE 0\n#endif\n'+s[:start]+f+s[end:])
