"""CelesTrak GP (general perturbations) element sets: polite fetch and a small disk cache.

API: https://celestrak.org/NORAD/elements/gp.php?GROUP=<group>&FORMAT=json (OMM keys). CelesTrak asks
clients not to fetch the same data more often than it changes (GP data update about every 2 hours) and
blocks clients that do, so this store never fetches a group more often than `min_refresh_seconds`
(2 hours, configurable upward only) and uses an honest User-Agent. CelesTrak's usage policy (read 2026-10-06,
https://celestrak.org/usage-policy.php) says machine clients must stop on ANY non-200 response (301, 403, 404,
429, 50x) and report it to a human: redirects are not followed, and any HTTP error stops this store for a day
and is reported as `needsHuman` in the error text. Network errors (no HTTP status) retry after `min_refresh`.
The cache holds the latest response per group only (`.cache/`, git-ignored); raw elements are never sent
to phones (the contract carries computed positions and passes only).
"""

import json
import os
import tempfile
import time
from typing import Callable, Dict, List, Optional, Tuple

from .. import fetch
from .elements import ElementError, parse_omm_json
from .sgp4 import Elements

GP_URL = "https://celestrak.org/NORAD/elements/gp.php?GROUP=%s&FORMAT=json"
USER_AGENT = "WorldEngine-livefeeds-prototype/0.1 (satellite layer)"
MIN_REFRESH_SECONDS = 7200
BLOCKED_BACKOFF_SECONDS = 86400
ATTRIBUTION = {
    "source": "celestrak",
    "text": "Orbital elements: CelesTrak (celestrak.org), from U.S. Space Force public GP data.",
    "url": "https://celestrak.org/NORAD/elements/",
    "required": True,
}


class ElementStore:
    def __init__(self, cache_dir: str, min_refresh_seconds: float = MIN_REFRESH_SECONDS,
                 refresh_seconds: float = 21600, getter: Callable = None, clock: Callable[[], float] = time.time):
        self.cache_dir = cache_dir
        self.min_refresh = max(MIN_REFRESH_SECONDS, float(min_refresh_seconds))
        self.refresh = max(self.min_refresh, float(refresh_seconds))
        self.get = getter or (lambda url: fetch.http_get(url, user_agent=USER_AGENT, follow_redirects=False))
        self.clock = clock
        os.makedirs(cache_dir, exist_ok=True)

    def _path(self, group: str) -> str:
        safe = "".join(ch for ch in group.lower() if ch.isalnum() or ch in "-_")
        return os.path.join(self.cache_dir, "gp-%s.json" % safe)

    def _read(self, group: str) -> Optional[dict]:
        try:
            with open(self._path(group), "r", encoding="utf-8") as fh:
                return json.load(fh)
        except (OSError, ValueError):
            return None

    def _write(self, group: str, doc: dict) -> None:
        fd, tmp = tempfile.mkstemp(dir=self.cache_dir, suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(doc, fh)
        os.replace(tmp, self._path(group))

    def load(self, group: str, allow_fetch: bool = True) -> Tuple[List[Elements], Optional[float], Optional[str]]:
        """(elements, fetchedAt, error). Fetches only when the cached copy is older than `refresh`
        and the last attempt is older than `min_refresh` (or the back-off after a block has passed)."""
        now = self.clock()
        doc = self._read(group) or {}
        fetched = doc.get("fetchedAt")
        attempted = doc.get("attemptedAt")
        wait_until = doc.get("blockedUntil", 0)
        stale = fetched is None or now - fetched >= self.refresh
        error = doc.get("lastError")
        if allow_fetch and stale and (attempted is None or now - attempted >= self.min_refresh) and now >= wait_until:
            doc["attemptedAt"] = now
            try:
                res = self.get(GP_URL % group)
                records = json.loads(res.body.decode("utf-8")) if res.body else []
                parse_omm_json(records)  # validate before replacing the cache
                doc.update(records=records, fetchedAt=now, lastError=None)
                error = None
            except fetch.FetchError as exc:
                error = "fetch failed: %s" % exc
                if exc.status is not None:
                    doc["blockedUntil"] = now + BLOCKED_BACKOFF_SECONDS
                    error += " (needsHuman: CelesTrak answered non-200; stopped for a day)"
                doc["lastError"] = error
            except (ValueError, ElementError) as exc:
                error = "bad response: %s" % exc
                doc["lastError"] = error
            self._write(group, doc)
        records = doc.get("records") or []
        return parse_omm_json(records), doc.get("fetchedAt"), error
