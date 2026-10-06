"""Command line: `serve` the relay, or fetch `once` and print a summary.

    Tools/livefeeds/livefeeds.sh serve [--host H] [--port P] [--interval S] [--client-poll S]
                                       [--idle-seconds S] [--cache-dir DIR] [--areas FILE]
    Tools/livefeeds/livefeeds.sh once  [--cache-dir DIR] [--areas FILE]
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
    relay = Relay(cfg, load_areas(args.areas), log=_log)
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
    relay = Relay(cfg, areas, log=_log)
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

    args = p.parse_args(argv)
    try:
        return args.func(args)
    except ValueError as e:
        sys.stderr.write("error: %s\n" % e)
        return 2


if __name__ == "__main__":
    sys.exit(main())
