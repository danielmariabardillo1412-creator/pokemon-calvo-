import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from PIL import Image
from move_gap_repairs import load_gap_sheet, normalize_priority, omit_invisible_missing_layers
from build_move_batch import Converter
from test_move_batch import cel, bake
from types import SimpleNamespace


class GapTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)

    def test_priority_fallback_changes_only_pinned_priority_and_preserves_aliases(self):
        particle = cel()
        particle[25] = 4
        body = cel(-1)
        frames = [[body, particle], [body, particle]]
        original = copy.deepcopy(frames)
        sha = hashlib.sha256(json.dumps(frames, separators=(",", ":")).encode()).hexdigest()
        a = {"@name": "Move:TEST", "@array": original}
        snapshot = copy.deepcopy(a)
        with patch("move_gap_repairs.PRIORITY_FALLBACK_EXPORTS", {"Move:TEST": sha}):
            meta = normalize_priority(a, frames)
            self.assertEqual(meta["changed_priority_cells"], 2)
            for row in frames:
                self.assertEqual(row[0], body)
                self.assertEqual(row[1][:25], snapshot["@array"][0][1][:25])
                self.assertEqual(row[1][25], 1)
                self.assertEqual(row[1][26], 1)
            self.assertEqual(a, snapshot)
            a["@array"][0][0][0] += 1
            with self.assertRaisesRegex(ValueError, "priority_fallback_source_changed"):
                normalize_priority(a, frames)

    def test_unknown_priority_four_still_rejected(self):
        Image.new("RGBA", (192, 192), "white").save(self.root / "test.png")
        c = cel(); c[25] = 4
        a = SimpleNamespace(attrs={"@name": "Move:TACKLE", "@graphic": "test.png", "@array": [[c], [c]]})
        move = {"display_name": "Test", "classification": "RUNTIME_SUPPORTED", "target": "selected-pokemon"}
        with self.assertRaisesRegex(ValueError, "unsupported_cell_mode"):
            Converter(self.root, bake).convert("tackle", move, "back", a)

    def test_missing_layer_omission_requires_all_baked_uses_invisible(self):
        for value in (1, 0.00001, float("nan"), float("inf"), None, True):
            frames = [{"back": {"name": "absent.png", "opacity": 0}}, {"front": {"name": "absent.png", "opacity": value}}]
            original = copy.deepcopy(frames)
            with self.subTest(value=value):
                self.assertEqual(omit_invisible_missing_layers(frames, self.root), [])
                self.assertEqual([r[next(iter(r))]["name"] for r in frames], ["absent.png"] * 2)
        frames = [{"back": {"name": "absent.png", "opacity": 0, "colorAlpha": 255}} for _ in range(3)]
        meta = omit_invisible_missing_layers(frames, self.root)
        self.assertEqual(meta[0]["uses"], 3)
        self.assertTrue(all(f["back"]["name"] == "" and f["back"]["opacity"] == 0 for f in frames))

    def test_existing_invisible_sheet_and_unsafe_missing_path_are_not_omitted(self):
        (self.root / "present.png").write_bytes(b"presence only")
        frames = [{"back": {"name": "present.png", "opacity": 0}}]
        self.assertEqual(omit_invisible_missing_layers(frames, self.root), [])
        with self.assertRaisesRegex(ValueError, "unsafe_sheet"):
            omit_invisible_missing_layers([{"back": {"name": "../absent.png", "opacity": 0}}], self.root)

    def test_converter_keeps_cells_and_rejects_a_missing_layer_that_fades_in_later(self):
        from move_layer_timing import bake_layers
        Image.new("RGBA", (192, 192), "white").save(self.root / "test.png")
        a = SimpleNamespace(attrs={"@name": "OppMove:TEST", "@graphic": "test.png", "@array": [[cel()] for _ in range(8)],
            "@timing": [{"@frame": 0, "@timingType": 1, "@name": "absent.png", "@opacity": 0}]})
        original = copy.deepcopy(a.attrs)
        move = {"display_name": "Test", "classification": "RUNTIME_SUPPORTED", "target": "selected-pokemon"}
        converter = Converter(self.root, bake_layers)
        clip = converter.convert("test", move, "front", a)
        self.assertEqual(clip["frames"], original["@array"])
        self.assertEqual(a.attrs, original)
        self.assertEqual(clip["invisible_missing_layers"][0]["uses"], 8)
        self.assertNotIn("absent.png", clip["layer_sheets"])
        a.attrs["@timing"].append({"@frame": 2, "@timingType": 2, "@opacity": 255, "@duration": 3})
        with self.assertRaisesRegex(ValueError, "missing_sheet"):
            converter.convert("test", move, "front", a)

    def _source(self):
        image = Image.new("RGBA", (2, 2))
        image.putdata([(1, 2, 3, 0), (200, 80, 15, 64), (40, 20, 10, 128), (255, 255, 255, 255)])
        tmp = self.root / "raw.png"
        image.save(tmp)
        raw = tmp.read_bytes();sha = hashlib.sha256(raw).hexdigest()
        source = self.root / (sha + ".png");tmp.rename(source)
        return image, source, {"source_sha256": sha, "source_size": [2, 2], "scale": 2, "commit": "pinned"}

    def test_pinned_sheet_integer_replication_no_new_colors_or_source_changes(self):
        image, source, spec = self._source()
        original = source.read_bytes()
        with patch("move_gap_repairs.GAP_SHEETS", {"test.png": spec}):
            path, meta = load_gap_sheet("test.png", self.root)
            with Image.open(path) as result:
                self.assertEqual(result.size, (4, 4))
                for y in range(4):
                    for x in range(4):
                        self.assertEqual(result.getpixel((x, y)), image.getpixel((x // 2, y // 2)))
            self.assertEqual(load_gap_sheet("test.png", self.root)[0], path)
            self.assertEqual(source.read_bytes(), original)
            spec["scale"] = 1
            self.assertEqual(load_gap_sheet("test.png", self.root)[0], source)

    def test_missing_tampered_wrong_dimensions_and_unlisted_sheet_rejected(self):
        _, source, spec = self._source()
        with patch("move_gap_repairs.GAP_SHEETS", {"test.png": spec}):
            spec["source_size"] = [9, 9]
            with self.assertRaisesRegex(ValueError, "gap_sheet_dimensions"):
                load_gap_sheet("test.png", self.root)
            source.write_bytes(b"tampered")
            with self.assertRaisesRegex(ValueError, "gap_sheet_source_changed"):
                load_gap_sheet("test.png", self.root)
            source.unlink()
            with self.assertRaisesRegex(ValueError, "missing_pinned_gap_sheet"):
                load_gap_sheet("test.png", self.root)
            with self.assertRaisesRegex(ValueError, "missing_sheet"):
                load_gap_sheet("unknown.png", self.root)


if __name__ == "__main__":
    unittest.main()
