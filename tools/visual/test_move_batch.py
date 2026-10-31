"""Fault injection into conversion; not just a coverage counter."""
import copy
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from PIL import Image
from build_move_batch import Converter, dependencies
from unittest.mock import patch


def bake(timings, count):
    return [{"back": {"name": ""}, "front": {"name": ""}} for _ in range(count)]


def cel(pattern=0):
    value = [0] * 27
    for index, number in {2: 100, 6: 1, 7: pattern, 8: 255, 11: 100, 26: 1}.items():
        value[index] = number
    return value


class BatchTests(unittest.TestCase):
    def test_pinned_geometry_keeps_all_source_cells_and_rejects_stale_or_wrong_focus(self):
        self.animation.attrs["@name"] = "Move:TESTGEOMETRY"
        for frame in self.animation.attrs["@array"]:
            frame[0][26] = 3
        original = copy.deepcopy(self.animation.attrs)
        fingerprint = hashlib.sha256(json.dumps(original["@array"], separators=(",", ":")).encode()).hexdigest()
        with patch("build_move_batch.NATIVE_GEOMETRY_REPAIRS", {"Move:TESTGEOMETRY": fingerprint}):
            result = self.convert("back")
            self.assertEqual(result["frames"], original["@array"])
            self.assertEqual(result["affine_particle_patterns"], [0])
            self.assertEqual(self.animation.attrs, original)
            with self.assertRaisesRegex(ValueError, "requires_native_export"):
                self.convert("front")
            self.animation.attrs["@array"][0][0][0] = 1
            with self.assertRaisesRegex(ValueError, "geometry_repair_source_changed"):
                self.convert("back")
        self.animation.attrs = original
        self.animation.attrs["@array"][0][0][26] = 2
        fingerprint = hashlib.sha256(json.dumps(self.animation.attrs["@array"], separators=(",", ":")).encode()).hexdigest()
        with patch("build_move_batch.NATIVE_GEOMETRY_REPAIRS", {"Move:TESTGEOMETRY": fingerprint}):
            with self.assertRaisesRegex(ValueError, "requires_source_line"):
                self.convert("back")

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        Image.new("RGBA", (192, 192), (255, 0, 0, 255)).save(self.root / "effect.png")
        self.converter = Converter(self.root, bake, self.root / "derived")
        self.animation = SimpleNamespace(attrs={"@name": "Move:TACKLE", "@graphic": "effect", "@array": [[cel()], [cel()]]})
        self.move = {"display_name": "Placaje", "target": "selected-pokemon", "classification": "RUNTIME_SUPPORTED"}

    def convert(self, side="back"):
        return self.converter.convert("tackle", self.move, side, self.animation)

    def test_valid_pair_and_static_warning(self):
        clip = self.convert()
        self.assertIn("static_source", clip["audit_flags"])
        self.assertEqual(clip["slot_sides"], ["back", "front"])
        self.assertEqual(len(dependencies([clip])), 1)
        self.assertIn("mapped_opponent_not_native", self.convert("front")["audit_flags"])

    def test_native_opponent_and_self_target(self):
        self.animation.attrs["@name"] = "OppMove:TACKLE"
        self.assertTrue(self.convert("front")["opponent_export"])
        self.move["target"] = "user"
        self.assertEqual(self.convert("front")["slot_sides"], ["front", "front"])

    def test_unsupported_data_quarantined(self):
        original = copy.deepcopy(self.animation.attrs)
        cases = [({"@hue": 45.5}, "invalid_sheet_hue"), ({"@speed": 40}, "unsupported_speed"),
                 ({"@array": [[cel()]]}, "single_frame"), ({"@graphic": "absent"}, "missing_sheet"),
                 ({"@graphic": "../effect"}, "unsafe_sheet"),
                 ({"@array": [[cel(5)], [cel()]]}, "missing_pattern")]
        for change, reason in cases:
            with self.subTest(reason=reason):
                self.animation.attrs = {**copy.deepcopy(original), **change}
                with self.assertRaisesRegex(ValueError, reason):
                    self.convert()

    def test_hue_is_sheet_only_preserves_source_and_cache_and_zero_contract(self):
        original = copy.deepcopy(self.animation.attrs)
        source = (self.root / "effect.png").read_bytes()
        zero = self.convert()
        self.animation.attrs["@hue"] = 120
        # Even if a layer shares the effect filename it must retain zero hue.
        self.converter.bake_layers = lambda t, n: [{"back": {"name": "effect"}, "front": {"name": ""}} for _ in range(n)]
        first = self.convert()
        self.assertNotEqual(first["sheet"], zero["sheet"])
        self.assertEqual(first["layer_sheets"]["effect"], zero["sheet"])
        self.assertEqual(first["frames"], zero["frames"])
        self.assertEqual(first["sheet_hue"]["degrees"], 120)
        self.assertEqual(first["sheet_hue"]["source_sha256"], hashlib.sha256(source).hexdigest())
        with Image.open(self.converter.sheets[first["sheet"]]["source"]) as image:
            self.assertEqual(image.getpixel((0, 0)), (0, 255, 0, 255))
            self.assertEqual(image.size, (192, 192))
        self.assertEqual(first, self.convert())
        self.assertEqual((self.root / "effect.png").read_bytes(), source)
        self.assertEqual(self.animation.attrs, {**original, "@hue": 120})
        self.animation.attrs["@hue"] = 480
        self.assertEqual(self.convert(), first)
        self.animation.attrs = original
        self.converter.bake_layers = bake
        self.animation.attrs["@hue"] = 360
        self.assertEqual(self.convert(), zero)

    def test_hue_does_not_hide_missing_pattern_or_accept_malformed_values(self):
        for value in (None, True, "20", 20.0, float("nan"), float("inf")):
            self.animation.attrs["@hue"] = value
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "invalid_sheet_hue"):
                self.convert()
        self.animation.attrs["@hue"] = 120
        self.animation.attrs["@array"][0][0][7] = 5
        with self.assertRaisesRegex(ValueError, "missing_pattern"):
            self.convert()

    def test_non_finite_modes_and_capacity(self):
        for field, value, reason in [(0, float("nan"), "non_finite"), (26, 9, "cell_mode"), (21, 1, "cell_flash")]:
            with self.subTest(field=field):
                frames = [[cel()], [cel()]]
                frames[0][0][field] = value
                self.animation.attrs["@array"] = frames
                with self.assertRaisesRegex(ValueError, reason):
                    self.convert()
        self.animation.attrs["@array"] = [[None] * 60 + [cel()], [cel()]]
        with self.assertRaisesRegex(ValueError, "beyond_60"):
            self.convert()

    def test_transparent_pattern_detected_and_seed_metadata_cache(self):
        Image.new("RGBA", (192, 192), (0, 0, 0, 0)).save(self.root / "effect.png")
        first = self.convert()
        self.assertIn("no_opaque_particles_body_or_layers_only", first["audit_flags"])
        # A priority-pack sheet can already have metadata without an alpha cache.
        self.converter.pattern_alpha.clear()
        self.assertEqual(self.convert()["sheet"], first["sheet"])

    def test_pinned_camera_repair_only_changes_particle_focus_without_mutating_source(self):
        self.animation.attrs["@name"] = "OppMove:TEST"
        body = cel(-1)
        body[26] = 2
        self.animation.attrs["@array"] = [[body, cel()], [body, cel()]]
        original = copy.deepcopy(self.animation.attrs)
        fingerprint = hashlib.sha256(json.dumps(original["@array"], separators=(",", ":")).encode()).hexdigest()
        with patch("build_move_batch.NATIVE_FOCUS_REPAIRS", {"OppMove:TEST": fingerprint}):
            result = self.convert("front")
            self.assertEqual(result["camera_repair"]["changed_focus_cells"], 2)
            self.assertEqual(result["frames"][0][0], body)
            for frame in result["frames"]:
                self.assertEqual(frame[1][26], 3)
                self.assertEqual(frame[1][:26], cel()[:26])
            self.assertEqual(self.animation.attrs, original)
            self.assertNotIn("camera_repair", self.convert("back"))
            self.animation.attrs["@array"][0][1][0] = 1
            with self.assertRaisesRegex(ValueError, "camera_repair_source_changed"):
                self.convert("front")
        self.assertNotIn("camera_repair", self.convert("front"))

    def test_native_user_focus_repair_preserves_body_and_other_particle_foci(self):
        Image.new("RGBA", (384, 192), (255, 0, 0, 255)).save(self.root / "effect.png")
        self.animation.attrs["@name"] = "OppMove:TESTUSER"
        body = cel(-1)
        body[26] = 2
        user_particle = cel()
        user_particle[26] = 2
        other = cel()
        excluded = cel(1)
        excluded[26] = 2
        self.animation.attrs["@array"] = [[body, user_particle, other, excluded], [body, user_particle, other, excluded]]
        original = copy.deepcopy(self.animation.attrs)
        fingerprint = hashlib.sha256(json.dumps(original["@array"], separators=(",", ":")).encode()).hexdigest()
        with patch("build_move_batch.NATIVE_FOCUS_REPAIRS", {"OppMove:TESTUSER": fingerprint}), patch("build_move_batch.NATIVE_FOCUS_RULES", {"OppMove:TESTUSER": {"source": 2, "destination": 1, "patterns": [0]}}):
            result = self.convert("front")
            self.assertEqual(result["camera_repair"]["original_focus"], 2)
            self.assertEqual(result["camera_repair"]["changed_focus_cells"], 2)
            for frame in result["frames"]:
                self.assertEqual(frame[0], body)
                self.assertEqual(frame[1][26], 1)
                self.assertEqual(frame[1][:26], user_particle[:26])
                self.assertEqual(frame[2], other)
                self.assertEqual(frame[3], excluded)
            self.assertEqual(self.animation.attrs, original)


if __name__ == "__main__":
    unittest.main()
