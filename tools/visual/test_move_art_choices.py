import copy
import unittest
from types import SimpleNamespace
from unittest.mock import patch
from move_art_choices import select_art_choice
from move_visual_equivalents import fingerprint


class ArtChoicesTests(unittest.TestCase):
    def fixture(self):
        names = {name: [SimpleNamespace(attrs={"@name": name, "@array": [[1], [2]]})]
                 for name in ["Move:SAVAGESPINOUT", "OppMove:SAVAGESPINOUT", "Move:SILVERWIND"]}
        return names, {name: fingerprint(values[0].attrs) for name, values in names.items()}

    def test_explicit_mapped_pair_never_claims_native_repair_or_mutates_source(self):
        names, hashes = self.fixture()
        before = {name: copy.deepcopy(v[0].attrs) for name, v in names.items()}
        with patch("move_art_choices.REJECTED_HASHES", hashes), patch("move_art_choices.SOURCE_HASHES", hashes):
            pair = select_art_choice("max_flutterby", names)
        self.assertEqual([s for s, _, _ in pair], ["back", "front"])
        for _, animation, meta in pair:
            self.assertEqual(animation.attrs, before["Move:SILVERWIND"])
            self.assertEqual(meta["replaced_source_status"], "renderable_but_art_rejected")
            self.assertFalse(meta["native_source_repaired"])
            self.assertFalse(meta["mechanics_enabled"])
            self.assertNotIn("primary_source_issue", meta)
        pair[0][1].attrs["@array"][0][0] = 9
        self.assertEqual(names["Move:SILVERWIND"][0].attrs, before["Move:SILVERWIND"])
        self.assertEqual(pair[1][1].attrs, before["Move:SILVERWIND"])

    def test_unknown_changed_rejected_or_selected_and_ambiguous_source_fail_closed(self):
        for changed in ("Move:SAVAGESPINOUT", "Move:SILVERWIND"):
            names, hashes = self.fixture()
            names[changed][0].attrs["@array"].append([3])
            with patch("move_art_choices.REJECTED_HASHES", hashes), patch("move_art_choices.SOURCE_HASHES", hashes):
                with self.subTest(changed=changed), self.assertRaisesRegex(ValueError, "art_source_changed"):
                    select_art_choice("max_flutterby", names)
        names, hashes = self.fixture()
        names["Move:SILVERWIND"] *= 2
        with self.assertRaisesRegex(ValueError, "unlisted_art"):
            select_art_choice("unlisted", names)
        with patch("move_art_choices.REJECTED_HASHES", hashes), patch("move_art_choices.SOURCE_HASHES", hashes):
            with self.assertRaisesRegex(ValueError, "ambiguous"):
                select_art_choice("max_flutterby", names)
