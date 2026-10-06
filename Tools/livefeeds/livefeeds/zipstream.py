"""Read one member from the front of a ZIP download without fetching the rest.

RTD's static GTFS zip is about 10 MB but routes.txt sits in the first ~110 KB. ZIP local file
headers are written in order, so a forward-only reader can stop as soon as the wanted member has
been inflated. Only the standard `zlib` and `struct` modules are used.

Supports stored and deflated members, with or without data descriptors (flag bit 3). Anything
else (ZIP64 descriptors, other compression methods, a stream that ends early or exceeds the byte
budget) raises StreamUnsupported so the caller can fall back to a full download plus `zipfile`.
"""

import struct
import zlib
from typing import Callable, Optional

SIG_LOCAL = b"PK\x03\x04"
SIG_CENTRAL = b"PK\x01\x02"
SIG_EOCD = b"PK\x05\x06"
SIG_DESCRIPTOR = b"PK\x07\x08"
_KNOWN_AFTER_MEMBER = (SIG_LOCAL, SIG_CENTRAL, SIG_EOCD)
_LOCAL_HEADER = struct.Struct("<4sHHHHHIIIHH")  # 30 bytes


class StreamUnsupported(Exception):
    """The archive cannot be walked forward-only within the byte budget."""


class _Buffer:
    def __init__(self, read: Callable[[int], bytes], budget: int, chunk: int = 32768):
        self._read = read
        self._chunk = chunk
        self.budget = budget
        self.data = bytearray()
        self.total = 0           # bytes pulled from the stream so far
        self.ended = False

    def fill(self, n: int) -> bool:
        """Make at least n bytes available; False if the stream ended first."""
        while len(self.data) < n and not self.ended:
            if self.total >= self.budget:
                raise StreamUnsupported("byte budget exceeded before the member was found")
            chunk = self._read(self._chunk)
            if not chunk:
                self.ended = True
            else:
                self.total += len(chunk)
                self.data += chunk
        return len(self.data) >= n

    def need(self, n: int) -> None:
        if not self.fill(n):
            raise StreamUnsupported("stream ended inside an entry")

    def take(self, n: int) -> bytes:
        self.need(n)
        out = bytes(self.data[:n])
        del self.data[:n]
        return out

    def skip(self, n: int) -> None:
        while n > 0:
            if not self.data:
                self.need(1)
            k = min(n, len(self.data))
            del self.data[:k]
            n -= k


def _inflate(buf: _Buffer, keep: bool, max_output: int) -> bytes:
    d = zlib.decompressobj(-15)  # raw deflate
    out = bytearray()
    pending = b""
    while not d.eof:
        if not pending:
            buf.need(1)
            pending = bytes(buf.data)
            buf.data.clear()
        try:
            chunk = d.decompress(pending, 1 << 20)
        except zlib.error as e:
            raise StreamUnsupported("bad deflate data: %s" % e)
        pending = d.unconsumed_tail
        if keep:
            out += chunk
            if len(out) > max_output:
                raise StreamUnsupported("member larger than %d bytes" % max_output)
    buf.data[:0] = d.unused_data   # bytes that follow the deflate stream
    return bytes(out)


def _skip_descriptor(buf: _Buffer) -> None:
    """Consume a (non-ZIP64) data descriptor and check that a known signature follows it."""
    buf.fill(4)
    n = 16 if bytes(buf.data[:4]) == SIG_DESCRIPTOR else 12
    buf.need(n + 4)
    if bytes(buf.data[n:n + 4]) not in _KNOWN_AFTER_MEMBER:
        raise StreamUnsupported("unrecognised data descriptor (ZIP64?)")
    del buf.data[:n]


def extract_member(read: Callable[[int], bytes], wanted: str,
                   max_stream_bytes: int = 2_000_000, max_output_bytes: int = 8_000_000) -> Optional[bytes]:
    """Return the bytes of member `wanted`, or None if the archive's entries end without it.

    `read(n)` returns up to n bytes, or b"" at the end of the stream.
    """
    buf = _Buffer(read, max_stream_bytes)
    while True:
        if not buf.fill(4):
            raise StreamUnsupported("stream ended without a central directory")
        sig = bytes(buf.data[:4])
        if sig in (SIG_CENTRAL, SIG_EOCD):
            return None
        if sig != SIG_LOCAL:
            raise StreamUnsupported("unexpected signature %r" % sig)
        buf.need(_LOCAL_HEADER.size)
        (_, _ver, flags, method, _mt, _md, _crc, csize, _usize, nlen, elen) = _LOCAL_HEADER.unpack(
            bytes(buf.data[:_LOCAL_HEADER.size]))
        del buf.data[:_LOCAL_HEADER.size]
        name = buf.take(nlen).decode("utf-8", "replace")
        buf.skip(elen)
        keep = name == wanted
        if method == 8:
            content = _inflate(buf, keep, max_output_bytes)
            if flags & 8:
                _skip_descriptor(buf)
        elif method == 0 and not flags & 8:
            if keep:
                if csize > max_output_bytes:
                    raise StreamUnsupported("member too large")
                content = buf.take(csize)
            else:
                buf.skip(csize)
                content = b""
        else:
            raise StreamUnsupported("unsupported entry (method %d, flags %#x)" % (method, flags))
        if keep:
            return content
