#!/usr/bin/env python3
"""Look-loop analysis: crops each capture to its 16:9 frame, measures it against its target
concept image(s) and the previous run, and draws one contact sheet per view.

  Tools/lookloop/analyze.py <run-dir> [--prev <dir of previous frames> [--prev-label TEXT]] [--manifest <views json>]

Reads  <run-dir>/raw/<id>.png, <run-dir>/logs/<id>.log, <run-dir>/capture.tsv, Tools/lookloop/views.json
Writes <run-dir>/frames/<id>.jpg   the 16:9 frame (phone width, JPEG)
       <run-dir>/sheets/<id>.jpg   target(s) | current | previous, histograms, numbers
       <run-dir>/overview.jpg      every current frame in one grid
       <run-dir>/signals.json      objective signals per view
Needs only Pillow (no numpy).
"""
import json, math, os, re, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageStat

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
STAT_W = 480          # stats are measured on a 480 x 270 copy (fast, resolution-independent)
PANEL_H = 360         # sheet panel height (640 x 360 per image)
BG, FG, DIM = (22, 22, 24), (236, 236, 236), (150, 150, 155)
COLORS = {"current": (255, 196, 64), "target": (90, 180, 255), "previous": (170, 170, 170)}


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def crop169(im):
    """The capture is a portrait phone screen with the 16:9 frame letterboxed in the middle."""
    im = im.convert("RGB")
    w, h = im.size
    if h > w:
        ch = round(w * 9 / 16)
        top = (h - ch) // 2
        return im.crop((0, top, w, top + ch))
    return im


def small(im):
    return im.convert("RGB").resize((STAT_W, round(STAT_W * im.height / im.width)), Image.BILINEAR)


def luma_image(im):
    # Rec. 709 weights on the sRGB values (a display-referred brightness, enough for comparison).
    return im.convert("L", (0.2126, 0.7152, 0.0722, 0))


def percentile(hist, q):
    total = sum(hist)
    acc = 0
    for i, n in enumerate(hist):
        acc += n
        if acc >= q * total:
            return i
    return len(hist) - 1


def signals(im):
    """Objective signals of one image (all 0-255 scale unless noted)."""
    s = small(im)
    lum = luma_image(s)
    lh = lum.histogram()
    stat = ImageStat.Stat(s)
    hsv = s.convert("HSV")
    sat = ImageStat.Stat(hsv.getchannel("S")).mean[0]
    # Colourfulness (Hasler & Suesstrunk 2003) from the opponent channels.
    r, g, b = [list(c.get_flattened_data()) for c in s.split()]
    rg = [a - c for a, c in zip(r, g)]
    yb = [0.5 * (a + c) - d for a, c, d in zip(r, g, b)]
    def ms(x):
        m = sum(x) / len(x)
        return m, math.sqrt(sum((v - m) ** 2 for v in x) / len(x))
    (mrg, srg), (myb, syb) = ms(rg), ms(yb)
    colorfulness = math.sqrt(srg ** 2 + syb ** 2) + 0.3 * math.sqrt(mrg ** 2 + myb ** 2)
    # Detail: mean edge response of the luma (a proxy for surface richness and noise).
    edges = ImageStat.Stat(lum.filter(ImageFilter.FIND_EDGES)).mean[0]
    # Hue histogram (12 bins of 30 degrees), weighted by saturation; greys do not vote.
    hh = [0.0] * 12
    for hv, sv, _ in hsv.get_flattened_data():
        hh[hv * 12 // 256] += sv
    tot = sum(hh) or 1
    return {
        "lumaMean": round(ImageStat.Stat(lum).mean[0], 1),
        "lumaP5": percentile(lh, 0.05), "lumaP50": percentile(lh, 0.5), "lumaP95": percentile(lh, 0.95),
        "clipBlackPct": round(100 * sum(lh[:4]) / sum(lh), 2), "clipWhitePct": round(100 * sum(lh[252:]) / sum(lh), 2),
        "rgbMean": [round(v, 1) for v in stat.mean],
        "saturationMean": round(sat, 1),
        "colorfulness": round(colorfulness, 1),
        "edgeMean": round(edges, 2),
        "hueHist": [round(v / tot, 3) for v in hh],
        "_lumaHist": bins(lh, 32),
        "_rgbHist": [bins(s.getchannel(c).histogram(), 32) for c in "RGB"],
    }


def bins(hist256, n):
    step = 256 // n
    out = [sum(hist256[i:i + step]) for i in range(0, 256, step)]
    tot = sum(out) or 1
    return [v / tot for v in out]


def intersection(a, b):
    return round(sum(min(x, y) for x, y in zip(a, b)), 3)


def compare(cur, ref):
    """How close the current frame's distributions are to a reference (1 = identical)."""
    return {
        "lumaHistIntersection": intersection(cur["_lumaHist"], ref["_lumaHist"]),
        "rgbHistIntersection": round(sum(intersection(a, b) for a, b in zip(cur["_rgbHist"], ref["_rgbHist"])) / 3, 3),
        "hueHistIntersection": intersection(cur["hueHist"], ref["hueHist"]),
        "dLumaMean": round(cur["lumaMean"] - ref["lumaMean"], 1),
        "dSaturation": round(cur["saturationMean"] - ref["saturationMean"], 1),
        "dColorfulness": round(cur["colorfulness"] - ref["colorfulness"], 1),
        "dEdge": round(cur["edgeMean"] - ref["edgeMean"], 2),
        "dRGB": [round(a - b, 1) for a, b in zip(cur["rgbMean"], ref["rgbMean"])],
    }


def pixel_change(a, b):
    """Mean absolute per-pixel difference (0-255) between two frames at stats size."""
    a = small(a)
    b = small(b).resize(a.size)
    return round(sum(ImageStat.Stat(ImageChops.difference(a, b)).mean) / 3, 2)


def parse_log(path):
    """STATS (triangles, draws) and RENDER (fps, GPU ms) lines printed by WorldLab."""
    out = {}
    if not os.path.exists(path):
        return out
    text = open(path, errors="replace").read()
    m = re.search(r"^STATS (.*)$", text, re.M)
    if m:
        kv = dict(re.findall(r"(\w+)=(\S+)", m.group(1)))
        for k in ("static", "props", "trees", "instances", "draws", "chunks", "meshBytes"):
            if k in kv and kv[k].isdigit():
                out[k] = int(kv[k])
        if all(k in out for k in ("static", "props", "trees")):
            out["triangles"] = out["static"] + out["props"] + out["trees"]
        # Whole-world counters. Trees are GPU-instanced (in `instances`), so STATS `trees` counts only
        # non-instanced tree triangles: 0 does not mean "no trees". Renamed so nobody reads it that way.
        if "trees" in out:
            out["treeTrianglesNonInstanced"] = out.pop("trees")
        out["countersScope"] = "whole world (not in view)"
        for k in ("profile", "season", "build"):
            if k in kv:
                out[k] = kv[k]
    fps, gpu = [], []
    # Only frames after the world is built (before STATS the view is empty, fps 0).
    after = text[m.end():] if m else ""
    for f, g in re.findall(r"RENDER t=\d+ fps=([\d.]+) gpu=(\S+)", after):
        fps.append(float(f))
        if g != "-":
            gpu.append(float(g))
    def med(x):
        x = sorted(x)
        return round(x[len(x) // 2], 2) if x else None
    # The first two seconds after load are a warm-up; keep the rest.
    out["fpsMedian"] = med(fps[2:] or fps)
    out["frameMsMedian"] = round(1000 / out["fpsMedian"], 2) if out.get("fpsMedian") else None
    out["gpuMsMedian"] = med(gpu[2:] or gpu)
    out["renderSamples"] = len(fps)
    # In-view counts (5A's hook): VIEW lines once a second, and the VIEWSHOT line of a view-list capture.
    vt = [(int(t), int(d)) for t, d in re.findall(r"^VIEW t=\d+ triangles=(\d+) draws=(\d+)", after, re.M)]
    shot = re.search(r"^VIEWSHOT id=\S+ .*?triangles=(\d+) draws=(\d+)", text, re.M)
    if shot:
        out["viewTriangles"], out["viewDraws"] = int(shot.group(1)), int(shot.group(2))
    elif vt:
        out["viewTriangles"], out["viewDraws"] = sorted(vt)[len(vt) // 2]
    sm = re.findall(r"RENDER t=\d+ fps=[\d.]+ gpu=\S+ ([\d.]+)× (\d+x\d+)", after)
    if sm:
        out["renderScale"], out["renderSize"] = float(sm[-1][0]), sm[-1][1]
    if "Failed to build world" in text:
        out["error"] = "Failed to build world"
    return out


def histogram_plot(series, w, h, title):
    """Overlaid luma histograms: current, target(s), previous."""
    im = Image.new("RGB", (w, h), (32, 32, 36))
    d = ImageDraw.Draw(im)
    d.text((8, 4), title, fill=DIM, font=font(15))
    top, bottom = 26, h - 6
    peak = max((max(s) for _, s in series), default=1) or 1
    n = len(series[0][1]) if series else 32
    for name, s in series:
        col = COLORS.get(name.split(":")[0], (200, 200, 200))
        pts = [(6 + i * (w - 12) / (n - 1), bottom - (bottom - top) * v / peak) for i, v in enumerate(s)]
        d.line(pts, fill=col, width=3 if name == "current" else 2)
    return im


def fit(im, h):
    return im.resize((round(im.width * h / im.height), h), Image.LANCZOS)


def label_panel(im, text, color):
    p = Image.new("RGB", (im.width, im.height + 30), BG)
    p.paste(im, (0, 30))
    d = ImageDraw.Draw(p)
    d.rectangle((0, 0, 8, 26), fill=color)
    d.text((14, 4), text, fill=FG, font=font(17))
    return p


def sheet(view, frame, targets, prev, sig, perf):
    # At most three target panels (the calibrated concept first); further references are listed by name.
    panels = [label_panel(fit(t, PANEL_H), "TARGET  " + lab, COLORS["target"]) for lab, t in targets[:3]]
    panels.append(label_panel(fit(frame, PANEL_H), "CURRENT  " + view["id"], COLORS["current"]))
    if prev is not None:
        panels.append(label_panel(fit(prev[1], PANEL_H), "PREVIOUS  " + prev[0], COLORS["previous"]))
    else:
        blank = Image.new("RGB", (round(PANEL_H * 16 / 9), PANEL_H), (40, 40, 44))
        ImageDraw.Draw(blank).text((20, PANEL_H // 2 - 10), "no previous run", fill=DIM, font=font(20))
        panels.append(label_panel(blank, "PREVIOUS", COLORS["previous"]))
    gap = 10
    width = sum(p.width for p in panels) + gap * (len(panels) - 1) + 20
    head_h, foot_h = 64, 210
    out = Image.new("RGB", (width, head_h + panels[0].height + foot_h), BG)
    d = ImageDraw.Draw(out)
    d.text((10, 6), view["title"], fill=FG, font=font(26))
    d.text((10, 38), f"{view['local']}  ({view['utc']})   weather: {view['weather']}   season: {view['season']}"
                     f"   character: {'yes' if view.get('character') else 'no'}", fill=DIM, font=font(17))
    x = 10
    for p in panels:
        out.paste(p, (x, head_h))
        x += p.width + gap
    y = head_h + panels[0].height + 10
    series = [("current", sig["current"]["_lumaHist"])]
    for i, (_, t) in enumerate(targets[:1]):  # histogram against the calibrated concept only
        series.append((f"target:{i}", sig["targets"][i]["_lumaHist"]))
    if prev is not None:
        series.append(("previous", sig["previous"]["_lumaHist"]))
    out.paste(histogram_plot(series, 520, foot_h - 20, "luma histogram  (yellow current, blue target, grey previous)"), (10, y))
    c = sig["current"]
    lines = [
        f"luma mean {c['lumaMean']}  p5/p50/p95 {c['lumaP5']}/{c['lumaP50']}/{c['lumaP95']}  clip black {c['clipBlackPct']}%  white {c['clipWhitePct']}%",
        f"saturation {c['saturationMean']}  colourfulness {c['colorfulness']}  edge (detail) {c['edgeMean']}  RGB {c['rgbMean']}",
    ]
    for i, cmp in enumerate(sig["vsTargets"][:3]):
        lines.append(f"vs target {i + 1}: luma hist {cmp['lumaHistIntersection']}  RGB hist {cmp['rgbHistIntersection']}  hue {cmp['hueHistIntersection']}"
                     f"  dLuma {cmp['dLumaMean']:+}  dSat {cmp['dSaturation']:+}  dColour {cmp['dColorfulness']:+}  dEdge {cmp['dEdge']:+}")
    if sig.get("vsPrevious"):
        p = sig["vsPrevious"]
        lines.append(f"vs previous: pixel change {p['pixelChange']}  dLuma {p['dLumaMean']:+}  dSat {p['dSaturation']:+}  dEdge {p['dEdge']:+}")
    tri = perf.get("triangles")
    lines.append("Simulator (not device): " + ", ".join(filter(None, [
        f"in view {perf['viewTriangles']:,} tris / {perf['viewDraws']} draws" if perf.get("viewTriangles") else None,
        f"world {tri:,} tris" if tri else None, f"draws {perf['draws']}" if perf.get("draws") and not perf.get("viewDraws") else None,
        f"frame {perf['frameMsMedian']} ms ({perf['fpsMedian']} fps)" if perf.get("frameMsMedian") else "frame time n/a",
        f"GPU {perf['gpuMsMedian']} ms" if perf.get("gpuMsMedian") else "GPU n/a",
        f"world built in {perf['loadSeconds']} s" if perf.get("loadSeconds") else None])))
    ty = y
    for ln in lines:
        d.text((545, ty), ln, fill=FG, font=font(16))
        ty += 24
    return out


def main():
    run = sys.argv[1]
    prev_dir = sys.argv[sys.argv.index("--prev") + 1] if "--prev" in sys.argv else None
    prev_label = sys.argv[sys.argv.index("--prev-label") + 1] if "--prev-label" in sys.argv else "previous run"
    manifest = sys.argv[sys.argv.index("--manifest") + 1] if "--manifest" in sys.argv else os.path.join(ROOT, "Tools/lookloop/views.json")
    views = {v["id"]: v for v in json.load(open(manifest))["views"]}
    load = {}
    if os.path.exists(os.path.join(run, "capture.tsv")):
        for ln in open(os.path.join(run, "capture.tsv")):
            p = ln.rstrip("\n").split("\t")
            if len(p) == 3:
                load[p[0]] = (p[1], p[2])
    for sub in ("frames", "sheets"):
        os.makedirs(os.path.join(run, sub), exist_ok=True)
    rp = os.path.join(run, "reused.json")
    reused = json.load(open(rp)) if os.path.exists(rp) else {}
    target_cache, out, frames = {}, {}, []
    for vid, v in views.items():
        raw = os.path.join(run, "raw", f"{vid}.png")
        if not os.path.exists(raw):
            continue
        frame = crop169(Image.open(raw))
        frame.save(os.path.join(run, "frames", f"{vid}.jpg"), quality=85, optimize=True)
        frames.append((vid, frame))
        if vid in reused:
            # Unchanged since the last published run (plan.py): keep its frame's numbers.
            perf = dict(reused[vid].get("perf", {}), reusedFrom=reused[vid].get("stamp"))
        else:
            perf = parse_log(os.path.join(run, "logs", f"{vid}.log"))
        if vid in load and load[vid][1] != "-":
            perf["loadSeconds"] = float(load[vid][1])
        targets = []
        for t in v.get("targets", []):
            path = os.path.join(ROOT, t["path"])
            if os.path.exists(path):
                if path not in target_cache:
                    im = Image.open(path).convert("RGB")
                    target_cache[path] = (im, signals(im))
                targets.append((t["label"], target_cache[path]))
        cur = signals(frame)
        sig = {"current": cur, "targets": [ts for _, (_, ts) in targets], "vsTargets": [compare(cur, ts) for _, (_, ts) in targets]}
        prev = None
        if prev_dir:
            pp = os.path.join(prev_dir, f"{vid}.jpg")
            if os.path.exists(pp):
                pim = Image.open(pp).convert("RGB")
                prev = (prev_label, pim)
                ps = signals(pim)
                sig["previous"] = ps
                sig["vsPrevious"] = dict(compare(cur, ps), pixelChange=pixel_change(frame, pim))
        sheet(v, frame, [(lab, im) for lab, (im, _) in targets], prev, sig, perf).save(
            os.path.join(run, "sheets", f"{vid}.jpg"), quality=78, optimize=True)
        def public(s):
            return {k: val for k, val in s.items() if not k.startswith("_")}
        out[vid] = {
            "current": public(cur),
            "targets": [{"label": lab, "path": t["path"], **public(ts)} for (lab, (_, ts)), t in
                        zip(targets, [t for t in v.get("targets", []) if os.path.exists(os.path.join(ROOT, t["path"]))])],
            "vsTargets": sig["vsTargets"],
            "vsPrevious": sig.get("vsPrevious"),
            "perf": perf,
        }
        print(f"  {vid}: luma {cur['lumaMean']}  vs target luma-hist {sig['vsTargets'][0]['lumaHistIntersection'] if sig['vsTargets'] else '-'}"
              f"  tris {perf.get('triangles', '-')}  frame {perf.get('frameMsMedian', '-')} ms")
    json.dump(out, open(os.path.join(run, "signals.json"), "w"), indent=1)
    if frames:
        cols, tw, th = 4, 480, 270
        rows = (len(frames) + cols - 1) // cols
        ov = Image.new("RGB", (cols * (tw + 6) + 6, rows * (th + 30) + 6), BG)
        d = ImageDraw.Draw(ov)
        for i, (vid, f) in enumerate(frames):
            x, y = 6 + (i % cols) * (tw + 6), 6 + (i // cols) * (th + 30)
            d.text((x + 2, y + 4), vid, fill=FG, font=font(17))
            ov.paste(f.resize((tw, th), Image.LANCZOS), (x, y + 26))
        ov.save(os.path.join(run, "overview.jpg"), quality=80, optimize=True)
    print(f"analyzed {len(frames)} views -> {run}")


if __name__ == "__main__":
    main()
