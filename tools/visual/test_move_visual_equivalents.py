import copy
import unittest
from types import SimpleNamespace
from unittest.mock import patch
from move_visual_equivalents import CHOICES, select_equivalent, fingerprint


class EquivalentTests(unittest.TestCase):
    def test_prismatic_uses_both_pinned_psybeam_exports_without_repairing_native_gap(self):
        self.assertEqual(CHOICES["prismatic_laser"], ("PSYBEAM", "missing_pattern:11",
                         "psychic_ring_beam_equivalent_not_native_laser"))
        names = {prefix + "PSYBEAM": [SimpleNamespace(attrs={"@name": prefix + "PSYBEAM",
                 "@array": [[1], [2]], "@graphic": "beam.png"})] for prefix in ("Move:", "OppMove:")}
        before = {name: copy.deepcopy(values[0].attrs) for name, values in names.items()}
        hashes = {name: fingerprint(attrs) for name, attrs in before.items()}
        with patch("move_visual_equivalents.SOURCE_HASHES", hashes):
            pairs = select_equivalent("prismatic_laser", names, "missing_pattern:11")
            self.assertEqual([a.attrs["@name"] for _, a, _ in pairs], ["Move:PSYBEAM", "OppMove:PSYBEAM"])
            for _, animation, meta in pairs:
                self.assertEqual(animation.attrs, before[meta["source_name"]])
                self.assertFalse(meta["native_gap_fixed"])
                self.assertFalse(meta["mechanics_enabled"])
                self.assertEqual(meta["source_modifications"], [])
            names["OppMove:PSYBEAM"][0].attrs["@array"][0][0] = 9
            with self.assertRaisesRegex(ValueError, "equivalent_source_changed:OppMove:PSYBEAM"):
                select_equivalent("prismatic_laser", names, "missing_pattern:11")

    def test_missing_opponent_is_explicitly_mapped_without_mutating_source(self):
        attrs = {"@name": "Move:SLEEPTALK", "@array": [[1], [2]], "@graphic": "sleep.png"}
        before = copy.deepcopy(attrs)
        names = {"Move:SLEEPTALK": [SimpleNamespace(attrs=attrs)]}
        with patch("move_visual_equivalents.SOURCE_HASHES", {"Move:SLEEPTALK": fingerprint(attrs)}):
            pairs = select_equivalent("rest", names, "missing_pattern:5")
            self.assertEqual([r[0] for r in pairs], ["back", "front"])
            for side, animation, meta in pairs:
                self.assertEqual(animation.attrs, before)
                self.assertFalse(meta["native_gap_fixed"])
                self.assertFalse(meta["mechanics_enabled"])
                self.assertEqual(meta["primary_source_status"], "quarantined")
                self.assertEqual(meta["primary_source_issue"], "missing_pattern:5")
            pairs[0][1].attrs["@array"][0][0] = 9
            self.assertEqual(attrs, before)
            self.assertEqual(pairs[1][1].attrs, before)

    def test_wrong_failure_unknown_move_changed_source_and_ambiguity_rejected(self):
        attrs = {"@name": "Move:SLEEPTALK", "@array": [[1], [2]]}
        names = {"Move:SLEEPTALK": [SimpleNamespace(attrs=attrs)]}
        with patch("move_visual_equivalents.SOURCE_HASHES", {"Move:SLEEPTALK": fingerprint(attrs)}):
            for move, reason in [("unknown", "missing_pattern:5"), ("rest", "unsupported_cell_mode"), ("rest", "missing_pattern:6")]:
                with self.subTest(move=move, reason=reason), self.assertRaises(ValueError):
                    select_equivalent(move, names, reason)
            attrs["@array"].append([3])
            with self.assertRaisesRegex(ValueError, "equivalent_source_changed"):
                select_equivalent("rest", names, "missing_pattern:5")
        names["Move:SLEEPTALK"] *= 2
        with self.assertRaisesRegex(ValueError, "missing_or_ambiguous"):
            select_equivalent("rest", names, "missing_pattern:5")

    def test_flower_changes_only_background_name_with_explicit_provenance(self):
        attrs = {"@name": "Move:FLOWERTRICK", "@array": [[1], [2]], "@timing": [
            {"@name": "uwu.png", "@timingType": 1, "@opacity": 149},
            {"@name": "sound", "@timingType": 0}]}
        before = copy.deepcopy(attrs)
        names = {"Move:FLOWERTRICK": [SimpleNamespace(attrs=attrs)]}
        with patch("move_visual_equivalents.SOURCE_HASHES", {"Move:FLOWERTRICK": fingerprint(attrs)}):
            pairs = select_equivalent("flower_trick", names, "missing_sheet:uwu.png")
        for _, animation, meta in pairs:
            restored = copy.deepcopy(animation.attrs)
            self.assertEqual(restored["@timing"][0]["@name"], "PRAS- Petal BG.png")
            restored["@timing"][0]["@name"] = "uwu.png"
            self.assertEqual(restored, before)
            self.assertEqual(meta["source_modifications"][0]["from"], "uwu.png")
        self.assertEqual(attrs, before)


if __name__ == "__main__":
    unittest.main()
