"""Salted, rotating vehicle ids (docs/research/live-feeds.md 4.5 and 4.9).

The relay never sends the agency's own vehicle id. It sends
    "<source>:" + first 12 hex digits of HMAC-SHA256(salt_of_the_service_day, "<source>:<raw id>")
The salt is 32 random bytes from the operating system (secrets), kept in the cache directory so
ids stay stable across restarts within one service day, and replaced when the service day
changes. Yesterday's salt is discarded, so yesterday's ids cannot be recomputed from today's
feed. (This is a security salt, not world-generation randomness, so the repo's seeded-random
rule for generated detail does not apply.)

The service day is the local date of (now - day_start_hour) in the area's time zone, which
comes from data (areas.json). If the zone database is missing, UTC is used.
"""

import datetime
import hashlib
import hmac
import json
import os
import secrets
import threading
from typing import Optional

try:  # zoneinfo needs the system tz database
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover
    ZoneInfo = None  # type: ignore


class DailySalt:
    def __init__(self, cache_dir: Optional[str], timezone: str = "UTC", day_start_hour: int = 3):
        self.path = os.path.join(cache_dir, "salt.json") if cache_dir else None
        self.day_start_hour = day_start_hour
        self._tz = None
        if ZoneInfo is not None:
            try:
                self._tz = ZoneInfo(timezone)
            except Exception:
                self._tz = None
        self._lock = threading.Lock()
        self._day: Optional[str] = None
        self._salt: Optional[bytes] = None
        self._load()

    # -- service day -------------------------------------------------------------------------
    def service_day(self, now: float) -> str:
        tz = self._tz or datetime.timezone.utc
        local = datetime.datetime.fromtimestamp(now, tz) - datetime.timedelta(hours=self.day_start_hour)
        return local.date().isoformat()

    # -- persistence -------------------------------------------------------------------------
    def _load(self) -> None:
        if not self.path:
            return
        try:
            with open(self.path, "r", encoding="utf-8") as f:
                d = json.load(f)
            salt = bytes.fromhex(d["salt"])
            if len(salt) >= 16 and isinstance(d["day"], str):
                self._day, self._salt = d["day"], salt
        except (OSError, ValueError, KeyError, TypeError):
            pass

    def _save(self) -> None:
        if not self.path:
            return
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            tmp = self.path + ".tmp"
            fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"day": self._day, "salt": self._salt.hex()}, f)
            os.replace(tmp, self.path)
        except OSError:
            pass  # ids are still correct for this process; only restart stability is lost

    # -- ids ---------------------------------------------------------------------------------
    def salt_for(self, now: float) -> bytes:
        day = self.service_day(now)
        with self._lock:
            if self._salt is None or self._day != day:
                self._day, self._salt = day, secrets.token_bytes(32)
                self._save()
            return self._salt

    def vehicle_id(self, source: str, raw_id: str, now: float) -> str:
        mac = hmac.new(self.salt_for(now), ("%s:%s" % (source, raw_id)).encode("utf-8"), hashlib.sha256)
        return "%s:%s" % (source, mac.hexdigest()[:12])
