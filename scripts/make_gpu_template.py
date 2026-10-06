#!/usr/bin/env python3
"""Writes a Metal System Trace template whose GPU performance state is "Default" (not pinned).

Xcode's stock template records with the GPU induced to its minimum clock (performance state 0 →
Minimum on device), which inflates GPU times. Setting gpuperformancestate to 4 records the GPU at
its own clocks. Values (checked with xctrace 26.4): 1 Minimum, 2 Medium, 3 Maximum, 4 Default.

  scripts/make_gpu_template.py [out.tracetemplate] [state]
"""
import copy, plistlib, sys

SRC = "/Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Packages/GPU.instrdst/Contents/Templates/Metal System Trace.tracetemplate"
out = sys.argv[1] if len(sys.argv) > 1 else ".build/templates/MetalSystemTrace-default.tracetemplate"
state = int(sys.argv[2]) if len(sys.argv) > 2 else 4
d = plistlib.load(open(SRC, "rb"))
objs = d["$objects"]
val = lambda u: objs[u.data] if isinstance(u, plistlib.UID) else u
for o in objs:
    if isinstance(o, dict) and "NS.keys" in o:
        keys = [val(k) for k in o["NS.keys"]]
        if "gpuperformancestate" in keys:
            objs.append(state)
            uid = plistlib.UID(len(objs) - 1)
            for name in ("gpuperformancestate", "gpuperformancestateinternal"):
                o["NS.objects"][keys.index(name)] = uid
            break
else:
    sys.exit("gpuperformancestate not found in the template")
import os
os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
plistlib.dump(d, open(out, "wb"), fmt=plistlib.FMT_BINARY)
print(out)
