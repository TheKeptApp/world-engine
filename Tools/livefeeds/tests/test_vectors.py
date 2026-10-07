"""The committed Swift test vectors must equal what the Python reference produces now."""

import os
import unittest

from livefeeds import vectors


class VectorsTest(unittest.TestCase):
    def test_committed_vectors_match_the_reference(self):
        with open(vectors.DEFAULT_OUT, "r", encoding="utf-8") as fh:
            committed = fh.read()
        self.assertEqual(committed, vectors.dumps(vectors.build()),
                         "regenerate with: Tools/livefeeds/livefeeds.sh vectors")

    def test_vectors_cover_every_layer(self):
        doc = vectors.build()
        self.assertEqual(len(doc["sky"]), len(vectors.PLACES) * len(vectors.INSTANTS))
        self.assertTrue(all(p["passes"] for p in doc["satellites"]["passes"]))
        self.assertTrue(os.path.basename(vectors.DEFAULT_OUT).endswith(".json"))


if __name__ == "__main__":
    unittest.main()
