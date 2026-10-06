import os
import shutil
import tempfile
import unittest

from regionkit import net


class CacheKeys(unittest.TestCase):
    def test_overpass_key_ignores_whitespace_only(self):
        a = net.overpass_cache_key("[out:json];\nnode(1,2,3,4);\nout body;")
        b = net.overpass_cache_key("[out:json];  node(1,2,3,4);   out body;")
        c = net.overpass_cache_key("[out:json]; node(1,2,3,5); out body;")
        self.assertEqual(a, b)
        self.assertNotEqual(a, c)
        self.assertTrue(a.startswith("ovp-"))

    def test_http_key_depends_on_method_url_body(self):
        k = net.cache_key("GET", "https://example.org/a")
        self.assertEqual(k, net.cache_key("get", "https://example.org/a"))
        self.assertNotEqual(k, net.cache_key("GET", "https://example.org/b"))
        self.assertNotEqual(net.cache_key("POST", "u", "x"), net.cache_key("POST", "u", "y"))

    def test_out_meta_refused(self):
        with self.assertRaises(ValueError):
            net.check_query("[out:json]; node(1,2,3,4); out meta;")
        with self.assertRaises(ValueError):
            net.check_query("[out:json]; way(1,2,3,4); out body meta qt;")
        net.check_query("[out:json]; way(1,2,3,4); out body qt;")  # fine


class CacheRoundTrip(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.old = os.environ.get("REGIONKIT_CACHE")
        os.environ["REGIONKIT_CACHE"] = self.tmp
        os.environ["REGIONKIT_OFFLINE"] = "1"

    def tearDown(self):
        shutil.rmtree(self.tmp)
        if self.old is None:
            os.environ.pop("REGIONKIT_CACHE", None)
        else:
            os.environ["REGIONKIT_CACHE"] = self.old
        os.environ.pop("REGIONKIT_OFFLINE", None)

    def test_store_and_hit_without_network(self):
        q = "[out:json]; node(0,0,1,1); out body;"
        key = net.overpass_cache_key(q)
        net._store(key, b'{"elements": []}', {"query": q})
        data, meta = net.overpass(q)          # offline: must come from the cache
        self.assertEqual(data, b'{"elements": []}')
        with self.assertRaises(RuntimeError):
            net.overpass("[out:json]; node(5,5,6,6); out body;")   # not cached and offline


if __name__ == "__main__":
    unittest.main()
