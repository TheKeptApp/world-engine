"""Command line: `serve` the relay, or fetch `once` and print a summary.

    Tools/livefeeds/livefeeds.sh serve [--host H] [--port P] [--interval S] [--client-poll S]
                                       [--idle-seconds S] [--cache-dir DIR] [--areas FILE]
    Tools/livefeeds/livefeeds.sh once  [--cache-dir DIR] [--areas FILE]
    Tools/livefeeds/livefeeds.sh sky   --lat L --lon L [--elev M] [--time ISO8601] [--radiance FILE] [--catalog FILE]
    Tools/livefeeds/livefeeds.sh sats  --lat L --lon L [--elev M] [--time ISO8601] [--hours H] [--elements FILE] [--ids N,N]
    Tools/livefeeds/livefeeds.sh test
"""

import argparse
import datetime
import gzip
import json
import os
import sys
import time

from . import rtd, tiles
from .relay import Config, Relay, MIN_POLL_INTERVAL, load_areas
from .server import etag_for, make_server, vehicles_payload

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _log(message: str) -> None:
    sys.stderr.write("%s  %s\n" % (datetime.datetime.now(datetime.timezone.utc).strftime("%H:%M:%SZ"), message))
    sys.stderr.flush()


def _config(args) -> Config:
    cache = args.cache_dir or os.environ.get("LIVEFEEDS_CACHE") or os.path.join(HERE, ".cache")
    kwargs = {"cache_dir": cache}
    for name in ("interval", "client_poll", "idle_seconds"):
        value = getattr(args, name, None)
        if value is not None:
            kwargs[{"interval": "poll_interval", "client_poll": "client_poll_interval",
                    "idle_seconds": "idle_seconds"}[name]] = value
    return Config(**kwargs)


def densest_window(snapshot, side: int = 3):
    """The side x side tile window holding the most vehicles (for sizing a typical phone request)."""
    best = None
    for (x, y) in snapshot.tile_index:
        for dx in range(-(side - 1), 1):
            for dy in range(-(side - 1), 1):
                rect = tiles.Rect(tiles.ZOOM, x + dx, y + dy, x + dx + side - 1, y + dy + side - 1)
                n = sum(len(snapshot.tile_index.get(t, ())) for t in rect.tiles())
                if best is None or n > best[0]:
                    best = (n, rect)
    return best


def cmd_once(args) -> int:
    cfg = _config(args)
    relay = Relay(cfg, load_areas(args.areas), log=_log,
                  shapes_fetch=lambda: rtd.fetch_shapes(cfg.routes_url, cfg.user_agent))
    outcome = relay.poll_once()
    now = relay.clock()
    snap, state, reason = relay.view(now)
    st = relay.stats
    print("outcome: %s" % outcome)
    if snap is None:
        print("no data: %s" % relay.last_error)
        return 1
    print("feed: %s" % cfg.feed_url)
    print("payload: %d bytes on the wire (this run, all requests: %d); routes table: %d routes, "
          "%d bytes downloaded for it" % (snap.wire_bytes, st["bytes"], len(relay._routes or ()), st["routesBytes"]))
    ts = datetime.datetime.fromtimestamp(snap.feed_timestamp, datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")
    print("feed timestamp: %s (age %ds), state: %s (%s)" % (ts, now - snap.feed_timestamp, state, reason))
    print("vehicles served: %d  %s" % (len(snap.vehicles), json.dumps(snap.counts, sort_keys=True)))
    print("dropped: %s" % json.dumps(snap.dropped, sort_keys=True))
    best = densest_window(snap)
    if best:
        n, rect = best
        payload = vehicles_payload(relay, rect, now, True, state, snap)
        raw = json.dumps(payload, separators=(",", ":")).encode()
        print("densest 3x3 tile window %s: %d vehicles, JSON %d bytes raw, %d bytes gzip"
              % (rect.key(), len(payload["vehicles"]), len(raw), len(gzip.compress(raw, 6, mtime=0))))
    print("attribution: %s" % rtd.ATTRIBUTION["text"])
    return 0


def cmd_serve(args) -> int:
    cfg = _config(args)
    areas = load_areas(args.areas)
    relay = Relay(cfg, areas, log=_log, shapes_fetch=lambda: rtd.fetch_shapes(cfg.routes_url, cfg.user_agent))
    server = make_server(relay, args.host, args.port)
    host, port = server.server_address[:2]
    _log("livefeeds %s serving http://%s:%d/v1/vehicles?bbox=S,W,N,E  (poll every %ds, idle pause %ds, cache %s)"
         % ("0.1", host, port, cfg.poll_interval, cfg.idle_seconds, cfg.cache_dir))
    _log("attribution: " + rtd.ATTRIBUTION["text"])
    relay.start()
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        _log("stopping")
    finally:
        relay.stop()
        server.server_close()
    return 0


def _parse_time(text):
    if not text:
        return time.time()
    return datetime.datetime.fromisoformat(text.replace("Z", "+00:00")).timestamp()


def cmd_sky(args) -> int:
    from .sky import contract, skyglow
    from .sky.bodies import Observer
    grid = skyglow.RadianceGrid.load(args.radiance) if args.radiance else None
    doc = contract.build(_parse_time(args.time), Observer(args.lat, args.lon, args.elev), args.catalog, grid)
    print(json.dumps(doc, indent=1 if args.pretty else None, separators=None if args.pretty else (",", ":")))
    return 0


def cmd_sky_radiance(args) -> int:
    from .sky import skyglow
    with open(args.xyz, "r", encoding="utf-8") as fh:
        doc = skyglow.grid_from_xyz(fh, args.product, args.year, {"name": "NASA Black Marble " + args.product,
                                                                  "url": "https://blackmarble.gsfc.nasa.gov/",
                                                                  "file": args.source_file or os.path.basename(args.xyz)})
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, separators=(",", ":"))
    print("wrote %s: %d x %d cells" % (args.out, doc["grid"]["rows"], doc["grid"]["cols"]))
    return 0


def cmd_sats(args) -> int:
    from .sats import celestrak, contract as scontract, elements as selements
    cfg = scontract.load_config()
    fetched, err = None, None
    if args.elements:
        with open(args.elements, "r", encoding="utf-8") as fh:
            text = fh.read()
        els = selements.parse_omm_json(json.loads(text)) if text.lstrip().startswith("[") else selements.parse_tle_text(text)
        fetched = os.path.getmtime(args.elements)
    else:
        cache = args.cache_dir or os.environ.get("LIVEFEEDS_CACHE") or os.path.join(HERE, ".cache")
        store = celestrak.ElementStore(cache, cfg.get("minRefreshSeconds", 7200), cfg.get("refreshSeconds", 21600))
        els, errs = [], []
        for group in cfg["groups"]:
            e, f, er = store.load(group, allow_fetch=not args.offline)
            els += e
            fetched = f if fetched is None or (f and f < fetched) else fetched
            if er:
                errs.append("%s: %s" % (group, er))
        err = "; ".join(errs) or None
    ids = [int(x) for x in args.ids.split(",")] if args.ids else None
    doc = scontract.build(els, args.lat, args.lon, args.elev, _parse_time(args.time), args.hours, fetched, err,
                          cfg, ids, visible_only=args.visible_only)
    print(json.dumps(doc, indent=1 if args.pretty else None, separators=None if args.pretty else (",", ":")))
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="livefeeds", description="RTD Denver live-vehicle relay prototype")
    sub = p.add_subparsers(dest="command", required=True)

    def common(sp):
        sp.add_argument("--cache-dir", help="cache directory (default $LIVEFEEDS_CACHE or Tools/livefeeds/.cache)")
        sp.add_argument("--areas", default=os.path.join(HERE, "areas.json"), help="areas allowlist (data)")

    s = sub.add_parser("serve", help="poll RTD and serve /v1/vehicles")
    common(s)
    s.add_argument("--host", default="127.0.0.1")
    s.add_argument("--port", type=int, default=8765, help="0 picks a free port")
    s.add_argument("--interval", type=float, help="upstream poll seconds, at least %d (default 30)" % MIN_POLL_INTERVAL)
    s.add_argument("--client-poll", type=int, help="pollIntervalSeconds hint for phones (default 15)")
    s.add_argument("--idle-seconds", type=float, help="pause polling after this long without a request; 0 = never (default 120)")
    s.set_defaults(func=cmd_serve)

    o = sub.add_parser("once", help="fetch once and print a summary")
    common(o)
    o.set_defaults(func=cmd_once)

    k = sub.add_parser("sky", help="print the sky contract (worldengine.live.sky/1) for a place and time")
    k.add_argument("--lat", type=float, required=True)
    k.add_argument("--lon", type=float, required=True)
    k.add_argument("--elev", type=float, default=0.0, help="metres above the ellipsoid")
    k.add_argument("--time", help="ISO 8601 instant, e.g. 2026-10-06T02:00:00Z (default now)")
    k.add_argument("--radiance", help="worldengine.radiance/1 grid (Black Marble derived)")
    k.add_argument("--catalog", help="worldengine.stars/1 catalogue (default: the engine's BSC5 extract)")
    k.add_argument("--pretty", action="store_true")
    k.set_defaults(func=cmd_sky)

    r = sub.add_parser("sky-radiance", help="bake a worldengine.radiance/1 grid from GDAL XYZ text")
    r.add_argument("xyz")
    r.add_argument("out")
    r.add_argument("--product", default="VNP46A4")
    r.add_argument("--year", type=int, required=True, help="composite year")
    r.add_argument("--source-file", help="original granule name, recorded in the output")
    r.set_defaults(func=cmd_sky_radiance)

    t = sub.add_parser("sats", help="print the satellites contract (worldengine.live.satellites/1)")
    t.add_argument("--lat", type=float, required=True)
    t.add_argument("--lon", type=float, required=True)
    t.add_argument("--elev", type=float, default=0.0)
    t.add_argument("--time", help="window start, ISO 8601 (default now)")
    t.add_argument("--hours", type=float, default=48.0)
    t.add_argument("--elements", help="local TLE text or OMM JSON instead of CelesTrak")
    t.add_argument("--ids", help="comma-separated NORAD ids to keep")
    t.add_argument("--offline", action="store_true", help="use cached CelesTrak data only")
    t.add_argument("--visible-only", action="store_true", help="keep only passes visible to the eye")
    t.add_argument("--cache-dir")
    t.add_argument("--pretty", action="store_true")
    t.set_defaults(func=cmd_sats)

    args = p.parse_args(argv)
    try:
        return args.func(args)
    except ValueError as e:
        sys.stderr.write("error: %s\n" % e)
        return 2


if __name__ == "__main__":
    sys.exit(main())
