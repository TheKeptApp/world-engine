import unittest
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import crown_budget_variant as variant

class CrownBudgetVariantTests(unittest.TestCase):
    def test_deterministic_hook_and_shipping_source_untouched(self):
        path = variant.ROOT / 'Sources/WorldEngine/World.swift'
        shipping = path.read_bytes()
        output = variant.generate(shipping.decode())
        self.assertEqual(output, variant.generate(shipping.decode()))
        self.assertEqual(path.read_bytes(), shipping)
        self.assertIn('buckets = candidateBuckets', output)
        self.assertIn('if crownBudget.adapter.enabled', output)
        self.assertIn('inst.species == "ulmus_americana", stats.season != 3', output)
        self.assertIn('crownBudget.referenceCrownHeight?', output)
        self.assertIn('CROWN_ADAPTER_FAILED', output)
    def test_changed_anchor_refuses_generation(self):
        with self.assertRaises(ValueError): variant.generate('changed native renderer')
