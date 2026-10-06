"""Small statistics helpers (deterministic, standard library)."""
import math
from collections import Counter


def percentile(values, p):
    """Linear interpolation between closest ranks (Hyndman-Fan type 7, numpy's default)."""
    v = sorted(values)
    if not v:
        return None
    h = (len(v) - 1) * p
    lo = int(math.floor(h))
    hi = min(lo + 1, len(v) - 1)
    return v[lo] + (h - lo) * (v[hi] - v[lo])


def ecdf(values, x):
    """Share of values <= x."""
    if not values:
        return None
    return sum(1 for v in values if v <= x) / len(values)


def dist(values, digits=2):
    """n, mean and p10/p25/p50/p75/p90 (None when empty)."""
    v = [x for x in values if x is not None]
    if not v:
        return {"n": 0}
    r = lambda x: None if x is None else round(x, digits)
    return {"n": len(v), "mean": r(sum(v) / len(v)), "p10": r(percentile(v, 0.10)), "p25": r(percentile(v, 0.25)),
            "p50": r(percentile(v, 0.50)), "p75": r(percentile(v, 0.75)), "p90": r(percentile(v, 0.90))}


def shares(counter, total=None, digits=3, top=None):
    """{value: {"n", "share"}} sorted by count desc then key."""
    total = sum(counter.values()) if total is None else total
    items = sorted(counter.items(), key=lambda kv: (-kv[1], str(kv[0])))
    if top:
        items = items[:top]
    return {str(k): {"n": n, "share": round(n / total, digits) if total else None} for k, n in items}


def share(n, total, digits=3):
    return round(n / total, digits) if total else None


def count(values):
    return Counter(values)


def shrink(measured, prior, n, k):
    """(n * measured + k * prior) / (n + k)."""
    if measured is None or n <= 0:
        return prior
    return (n * measured + k * prior) / (n + k)
