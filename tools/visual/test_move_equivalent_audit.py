import unittest
from unittest.mock import patch
from audit_move_equivalents import changed_contracts


class ReplacementContractTests(unittest.TestCase):
    def setUp(self):
        self.before = {"prismatic_laser/back": "old-b", "prismatic_laser/front": "old-f", "other/back": "untouched"}
        self.after = {**self.before, "prismatic_laser/back": "new-b", "prismatic_laser/front": "new-f"}

    def test_only_declared_complete_pair_may_change(self):
        self.assertEqual(changed_contracts(self.before, self.after, ["prismatic_laser"]),
                         ["prismatic_laser/back", "prismatic_laser/front"])

    def test_reject_extra_partial_missing_added_or_unknown(self):
        variants = [dict(self.after, **{"other/back": "changed"}),
                    dict(self.after, **{"prismatic_laser/front": "old-f"}),
                    {k: v for k, v in self.after.items() if k != "other/back"},
                    dict(self.after, **{"extra/front": "added"}), self.before]
        for after in variants:
            with self.subTest(after=after), self.assertRaises(ValueError):
                changed_contracts(self.before, after, ["prismatic_laser"])
        for names in (["unknown"], ["prismatic_laser", "prismatic_laser"]):
            with self.assertRaises(ValueError):
                changed_contracts(self.before, self.after, names)

    def test_original_additions_mode_still_rejects_existing_changes(self):
        with patch("audit_move_equivalents.CHOICES", {"prismatic_laser": ()}):
            before = {"other/back": "untouched"}
            self.assertEqual(len(changed_contracts(before, self.after)), 2)
            with self.assertRaises(ValueError):
                changed_contracts(before, dict(self.after, **{"other/back": "changed"}))


if __name__ == "__main__":
    unittest.main()
