"""HTTP with an on-disk cache and a download ledger.

Every response is stored under ``<cache>/http/<key>.bin`` where ``key`` is a SHA-256 of the
method, URL and body, so nothing is fetched twice. Every real network transfer is appended to
``<cache>/ledger.jsonl`` (URL, bytes, time) so the total download volume can be reported.

Overpass etiquette (owner rules): one request at a time, an identifying User-Agent, at least
5 s between requests, a status check for a free slot first, and a back-off of at least 60 s on
HTTP 429/504. Only ``out body``/``out geom``/``out tags``/``out center``/``out bb``/``out ids``/
``out count`` are allowed; ``out meta`` is refused (no contributor names, IDs or timestamps).
"""
import hashlib
import json
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = "WorldEngine-regionkit/0.1 (offline research tool)"
OVERPASS_PRIMARY = "https://overpass-api.de/api/interpreter"
OVERPASS_FALLBACK = "https://overpass.private.coffee/api/interpreter"
MIN_GAP_SECONDS = 5.0
BACKOFF_SECONDS = 60.0

_HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CACHE = os.path.join(os.path.dirname(_HERE), ".cache")


def cache_dir():
    """The cache directory: $REGIONKIT_CACHE, else Tools/regionkit/.cache (git-ignored)."""
    d = os.environ.get("REGIONKIT_CACHE") or DEFAULT_CACHE
    os.makedirs(os.path.join(d, "http"), exist_ok=True)
    return d


def cache_key(method, url, body=b""):
    """Stable key for a request (method + URL + body)."""
    if isinstance(body, str):
        body = body.encode("utf-8")
    h = hashlib.sha256()
    h.update(method.upper().encode("ascii"))
    h.update(b"\n")
    h.update(url.encode("utf-8"))
    h.update(b"\n")
    h.update(body or b"")
    return h.hexdigest()[:40]


def overpass_cache_key(query):
    """Overpass responses are keyed by the query text only (endpoint-independent), whitespace-normalised."""
    norm = " ".join(query.split())
    return "ovp-" + hashlib.sha256(norm.encode("utf-8")).hexdigest()[:40]


def _paths(key):
    d = os.path.join(cache_dir(), "http")
    return os.path.join(d, key + ".bin"), os.path.join(d, key + ".meta.json")


def cached(key):
    data_path, meta_path = _paths(key)
    if os.path.exists(data_path) and os.path.exists(meta_path):
        with open(data_path, "rb") as f:
            data = f.read()
        with open(meta_path) as f:
            meta = json.load(f)
        return data, meta
    return None


def _store(key, data, meta):
    data_path, meta_path = _paths(key)
    tmp = data_path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, data_path)
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=1, sort_keys=True)


def _ledger(url, nbytes, status, note=""):
    with open(os.path.join(cache_dir(), "ledger.jsonl"), "a") as f:
        f.write(json.dumps({"url": url, "bytes": nbytes, "status": status, "note": note,
                            "time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}) + "\n")


def ledger_total():
    """Total bytes actually downloaded (sum of the ledger)."""
    p = os.path.join(cache_dir(), "ledger.jsonl")
    if not os.path.exists(p):
        return 0, 0
    total, n = 0, 0
    with open(p) as f:
        for line in f:
            try:
                total += json.loads(line)["bytes"]
                n += 1
            except (ValueError, KeyError):
                pass
    return total, n


_SSL = [None]


def _ssl_context():
    """Default verified TLS context; falls back to the macOS system bundle when the python.org
    build has no CA store installed. Verification is never disabled."""
    if _SSL[0] is None:
        ctx = ssl.create_default_context()
        if ctx.cert_store_stats().get("x509_ca", 0) == 0:
            for cafile in ("/etc/ssl/cert.pem", "/private/etc/ssl/cert.pem"):
                if os.path.exists(cafile):
                    ctx = ssl.create_default_context(cafile=cafile)
                    break
        _SSL[0] = ctx
    return _SSL[0]


def _raw(method, url, body=None, headers=None, timeout=240):
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("User-Agent", USER_AGENT)
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=_ssl_context()) as r:
            data = r.read()
            return r.status, data
    except urllib.error.HTTPError as e:
        data = e.read() if hasattr(e, "read") else b""
        return e.code, data


def get(url, timeout=120, note=""):
    """Cached GET. Returns bytes. Raises RuntimeError on non-200."""
    key = cache_key("GET", url)
    hit = cached(key)
    if hit:
        return hit[0]
    if os.environ.get("REGIONKIT_OFFLINE"):
        raise RuntimeError("offline mode and not cached: " + url)
    status, data = _raw("GET", url, timeout=timeout)
    _ledger(url, len(data), status, note)
    if status != 200:
        raise RuntimeError("HTTP %d for %s" % (status, url))
    _store(key, data, {"url": url, "status": status, "bytes": len(data),
                       "fetchedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())})
    return data


# ---------------------------------------------------------------------------------------------
# Overpass

_last_request = [0.0]
FORBIDDEN_OUT = re.compile(r"\bout\s+[^;]*\bmeta\b|\bout\s+meta\b", re.I)


def check_query(query):
    """Refuses `out meta` (and `out ... meta`) so contributor metadata never enters the cache."""
    if FORBIDDEN_OUT.search(query):
        raise ValueError("refusing Overpass query with `out meta` (owner rule: no contributor metadata)")
    if "attic" in query.lower() or "[date:" in query.lower():
        raise ValueError("refusing historical queries")


def _status_url(endpoint):
    return endpoint.replace("/interpreter", "/status")


def wait_for_slot(endpoint, log=print, max_wait=240):
    """Polls /status until a slot is free (overpass-api.de reports 'N slots available now').
    The fallback endpoint's status page is optional: one failed check there means "proceed"."""
    t0 = time.time()
    while True:
        try:
            status, data = _raw("GET", _status_url(endpoint), timeout=30)
            _ledger(_status_url(endpoint), len(data), status, "status")
        except Exception as e:  # network hiccup: wait and retry
            log("  status check failed: %s" % e)
            status, data = 0, b""
            if endpoint != OVERPASS_PRIMARY:
                return True
        text = data.decode("utf-8", "replace")
        if status == 200:
            m = re.search(r"(\d+) slots? available now", text)
            if m and int(m.group(1)) > 0:
                return True
            waits = [int(x) for x in re.findall(r"in (\d+) seconds", text)]
            if not waits and "Rate limit" not in text:
                return True  # endpoint without the de-style status text: proceed
            w = max(MIN_GAP_SECONDS, min(waits) + 1 if waits else 15)
        else:
            w = 15
        if time.time() - t0 > max_wait:
            return False
        log("  waiting %.0f s for an Overpass slot" % w)
        time.sleep(w)


def overpass(query, log=print, endpoints=None):
    """Runs an Overpass query (cached by query text). Returns (bytes, meta)."""
    check_query(query)
    key = overpass_cache_key(query)
    hit = cached(key)
    if hit:
        return hit
    if os.environ.get("REGIONKIT_OFFLINE") or os.environ.get("REGIONKIT_NO_OVERPASS"):
        raise RuntimeError("offline / no-Overpass mode and Overpass query not cached")
    endpoints = endpoints or [OVERPASS_PRIMARY, OVERPASS_FALLBACK]
    body = ("data=" + urllib.parse.quote(query, safe="")).encode("ascii")
    last = "no endpoint tried"
    for attempt in range(3):
        for ep in endpoints:
            gap = time.time() - _last_request[0]
            if gap < MIN_GAP_SECONDS:
                time.sleep(MIN_GAP_SECONDS - gap)
            if not wait_for_slot(ep, log=log):
                last = "%s: no free slot" % ep
                continue
            log("  POST %s (%d-char query)" % (ep, len(query)))
            t = time.time()
            try:
                status, data = _raw("POST", ep, body=body,
                                    headers={"Content-Type": "application/x-www-form-urlencoded"}, timeout=300)
            except Exception as e:
                status, data = 0, str(e).encode()
            _last_request[0] = time.time()
            _ledger(ep, len(data), status, "overpass")
            if status == 200 and data[:1] == b"{":
                try:
                    j = json.loads(data)
                except ValueError:
                    last = "%s: invalid JSON" % ep
                    continue
                remark = j.get("remark")
                if remark and ("runtime error" in remark or "Query timed out" in remark or "out of memory" in remark):
                    last = "%s: %s" % (ep, remark)
                    log("  remark: " + remark)
                    time.sleep(BACKOFF_SECONDS)
                    continue
                meta = {"endpoint": ep, "status": status, "bytes": len(data), "seconds": round(time.time() - t, 1),
                        "fetchedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                        "timestamp_osm_base": (j.get("osm3s") or {}).get("timestamp_osm_base"),
                        "query": query}
                _store(key, data, meta)
                log("  ok: %d bytes in %.1f s" % (len(data), time.time() - t))
                return data, meta
            last = "%s: HTTP %s (%d bytes)" % (ep, status, len(data))
            log("  " + last)
            if status in (429, 504):
                log("  backing off %.0f s" % BACKOFF_SECONDS)
                time.sleep(BACKOFF_SECONDS)
        time.sleep(BACKOFF_SECONDS)
    raise RuntimeError("Overpass failed: " + last)


def log_stderr(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()
