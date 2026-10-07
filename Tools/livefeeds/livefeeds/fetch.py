"""Polite HTTP client for the upstream feed (standard library urllib only).

Honest, descriptive User-Agent (never a browser identity), conditional GET (ETag and
If-Modified-Since, when the server sends them), gzip accepted, a size cap and a timeout.
"""

import gzip
import os
import ssl
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Dict, Optional

USER_AGENT = "WorldEngine-livefeeds-prototype/0.1"
DEFAULT_TIMEOUT = 20.0
MAX_BODY_BYTES = 8 * 1024 * 1024


# System CA bundles to try when Python's own default has none (python.org builds on macOS ship
# without certificates unless "Install Certificates.command" was run). Verification is never disabled.
_CA_BUNDLES = ("/etc/ssl/cert.pem", "/etc/ssl/certs/ca-certificates.crt", "/etc/pki/tls/certs/ca-bundle.crt",
               "/etc/ssl/ca-bundle.pem")
_context: Optional[ssl.SSLContext] = None


def ssl_context() -> ssl.SSLContext:
    """Default verifying context; if it holds no CA certificates, load a system bundle."""
    global _context
    if _context is None:
        ctx = ssl.create_default_context()
        if ctx.cert_store_stats().get("x509_ca", 0) == 0:
            env = os.environ.get("SSL_CERT_FILE")
            for path in ((env,) if env else ()) + _CA_BUNDLES:
                if path and os.path.exists(path):
                    try:
                        ctx.load_verify_locations(cafile=path)
                        break
                    except (ssl.SSLError, OSError):
                        continue
        _context = ctx
    return _context


def _network_error(e: Exception) -> "FetchError":
    reason = getattr(e, "reason", e)
    hint = ""
    if isinstance(reason, ssl.SSLCertVerificationError):
        hint = " (no usable CA certificates: set SSL_CERT_FILE to a CA bundle, see README)"
    return FetchError("network error: %s%s" % (reason, hint))


class FetchError(Exception):
    """A request that did not produce usable data. status is None for network errors."""

    def __init__(self, message: str, status: Optional[int] = None, retry_after: Optional[float] = None):
        super().__init__(message)
        self.status = status
        self.retry_after = retry_after


@dataclass
class FetchResult:
    status: int                       # 200 or 304
    body: Optional[bytes]             # None for 304
    etag: Optional[str]
    last_modified: Optional[str]
    wire_bytes: int                   # bytes received for the body (compressed size if gzip)


def _retry_after(headers) -> Optional[float]:
    value = headers.get("Retry-After") if headers is not None else None
    if value is None:
        return None
    try:
        return max(0.0, float(value))
    except ValueError:
        return None  # an HTTP-date form is ignored; the caller's own backoff applies


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # urllib then raises HTTPError with the 3xx code


def http_get(url: str, user_agent: str = USER_AGENT, etag: Optional[str] = None,
             last_modified: Optional[str] = None, timeout: float = DEFAULT_TIMEOUT,
             max_bytes: int = MAX_BODY_BYTES, follow_redirects: bool = True) -> FetchResult:
    """follow_redirects=False turns a 3xx into FetchError(status=3xx) (CelesTrak asks clients to treat 301 as an error)."""
    headers: Dict[str, str] = {"User-Agent": user_agent, "Accept-Encoding": "gzip"}
    if etag:
        headers["If-None-Match"] = etag
    if last_modified:
        headers["If-Modified-Since"] = last_modified
    req = urllib.request.Request(url, headers=headers)
    try:
        handlers = [urllib.request.HTTPSHandler(context=ssl_context())]
        if not follow_redirects:
            handlers.append(_NoRedirect())
        with urllib.request.build_opener(*handlers).open(req, timeout=timeout) as resp:
            raw = resp.read(max_bytes + 1)
            if len(raw) > max_bytes:
                raise FetchError("response larger than %d bytes" % max_bytes, resp.status)
            body = raw
            if resp.headers.get("Content-Encoding", "").lower() == "gzip":
                try:
                    body = gzip.decompress(raw)
                except (OSError, EOFError) as e:
                    raise FetchError("bad gzip body: %s" % e, resp.status)
            return FetchResult(resp.status, body, resp.headers.get("ETag"),
                               resp.headers.get("Last-Modified"), len(raw))
    except urllib.error.HTTPError as e:
        try:
            if e.code == 304:
                return FetchResult(304, None, e.headers.get("ETag") or etag,
                                   e.headers.get("Last-Modified") or last_modified, 0)
            raise FetchError("HTTP %d" % e.code, e.code, _retry_after(e.headers))
        finally:
            e.close()
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise _network_error(e)


def http_get_headers(url: str, user_agent: Optional[str], last_modified: Optional[str] = None, accept: Optional[str] = None,
                     timeout: float = DEFAULT_TIMEOUT, max_bytes: int = MAX_BODY_BYTES):
    """Like http_get, plus an Accept header, returning (FetchResult, response headers) so the caller can honour
    Cache-Control / Expires. user_agent must be given (APIs that ask for a contact address get one)."""
    if not user_agent:
        raise FetchError("no User-Agent configured")
    headers: Dict[str, str] = {"User-Agent": user_agent, "Accept-Encoding": "gzip"}
    if accept:
        headers["Accept"] = accept
    if last_modified:
        headers["If-Modified-Since"] = last_modified
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.build_opener(urllib.request.HTTPSHandler(context=ssl_context())).open(req, timeout=timeout) as resp:
            raw = resp.read(max_bytes + 1)
            if len(raw) > max_bytes:
                raise FetchError("response larger than %d bytes" % max_bytes, resp.status)
            body = raw
            if resp.headers.get("Content-Encoding", "").lower() == "gzip":
                try:
                    body = gzip.decompress(raw)
                except (OSError, EOFError) as e:
                    raise FetchError("bad gzip body: %s" % e, resp.status)
            return (FetchResult(resp.status, body, resp.headers.get("ETag"), resp.headers.get("Last-Modified"), len(raw)),
                    dict(resp.headers.items()))
    except urllib.error.HTTPError as e:
        try:
            if e.code == 304:
                return (FetchResult(304, None, e.headers.get("ETag"), e.headers.get("Last-Modified") or last_modified, 0),
                        dict(e.headers.items()))
            raise FetchError("HTTP %d" % e.code, e.code, _retry_after(e.headers))
        finally:
            e.close()
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise _network_error(e)


def open_stream(url: str, user_agent: str = USER_AGENT, timeout: float = DEFAULT_TIMEOUT):
    """Open a streaming response (redirects followed). Caller closes it. No gzip, no size cap:
    the caller reads only what it needs."""
    req = urllib.request.Request(url, headers={"User-Agent": user_agent})
    try:
        return urllib.request.urlopen(req, timeout=timeout, context=ssl_context())
    except urllib.error.HTTPError as e:
        try:
            raise FetchError("HTTP %d" % e.code, e.code, _retry_after(e.headers))
        finally:
            e.close()
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise _network_error(e)
