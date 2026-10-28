"""Offline regression against the immutable snapshot, not the live PokéAPI."""
import copy
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import pokeapi_adapter as adapter

SOURCE_BLOB = "121f719bc1b51595e5229f5f9a422786cce69073"
SOURCE_SHA256 = "eeca6b6db91b92f8009472a09b801a1146d4be2b49513e50f9c1e8e8bb4cce26"


class TeraBlastAdapterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        raw = subprocess.check_output(["git", "cat-file", "blob", SOURCE_BLOB], cwd=ROOT)
        if hashlib.sha256(raw).hexdigest() != SOURCE_SHA256:
            raise AssertionError("Pinned Tera Blast source changed")
        cls.source = json.loads(raw)

    def test_normal_subset_has_no_unconditional_debuff(self):
        original = copy.deepcopy(self.source)
        specs, crit, contact, coverage, _, _ = adapter.generate_move_specs(self.source, set())
        self.assertEqual(specs, [])
        self.assertEqual(coverage, "PARTIAL_RUNTIME")
        self.assertEqual((crit, contact), (0, False))
        self.assertEqual(self.source, original)

    def test_source_shape_changes_fail_closed(self):
        for key, value in [("id", 999), ("power", 100), ("accuracy", None),
                           ("pp", 20), ("target", {"name": "user"}),
                           ("damage_class", {"name": "physical"}),
                           ("type", {"name": "stellar"}), ("stat_changes", [])]:
            with self.subTest(key=key):
                changed = copy.deepcopy(self.source)
                changed[key] = value
                with self.assertRaises(RuntimeError):
                    adapter.generate_move_specs(changed, set())

    def test_neighboring_moves_keep_existing_semantics(self):
        for endpoint, slug in [(94, "psychic"), (315, "overheat"), (568, "noble_roar")]:
            raw = subprocess.check_output(
                ["git", "show", f"HEAD:data/api/v2/move/{endpoint}/index.json"], cwd=ROOT)
            move = json.loads(raw)
            self.assertEqual(adapter.slug(move["name"]), slug)
            specs = adapter.generate_move_specs(move, set())[0]
            stages = adapter._matching_effects(specs, "modify_stat_stage")
            self.assertTrue(stages)
            self.assertTrue(all(s["target"] == ("self" if slug == "overheat" else "opponent") for s in stages))


if __name__ == "__main__":
    unittest.main()
