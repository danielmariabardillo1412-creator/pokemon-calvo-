import copy
import unittest
from pathlib import Path
from unittest.mock import patch
import build_external_context_sheets as sheets


class ExternalContextEvidenceTests(unittest.TestCase):
    def fixture(self):
        lengths = {"rain_dance": 26, "hail": 13, "snowscape": 13, "chilly_reception": 30, "substitute": 14, "transform": 15}
        clips = [{"id": name + "/" + side, "arena": list(arena), "source_frames": count, "context_frames": 30,
                  "frames": [{"frame": n, "path": "frame.png", "sha256": "pin", "post_source": n >= count} for n in range(count + 30)]}
                 for name, count in lengths.items() for side in ("back", "front") for arena in ((640, 360), (400, 300))]
        report = {"version": 1, "failures": [], "gpu": True, "states": 1164, "clips": clips,
                  "context_manifest_path": "res://manifest.json", "context_manifest_sha256": "pin",
                  **{key: "pin" for key in ("index_sha256", "renderer_sha256", "adapter_sha256", "ui_sha256", "runner_sha256")}}
        manifest = {"bindings": {name + "/" + side: {"source_frames": count} for name, count in lengths.items() for side in ("back", "front")}}
        return report, manifest

    def validate(self, report, manifest):
        with patch.object(sheets, "read", side_effect=lambda p: report if Path(p).name == "report.json" else manifest), patch.object(sheets, "digest", return_value="pin"):
            return sheets.validate(Path("report.json"))

    def test_complete_paired_native_and_simulation_matrix(self):
        report, manifest = self.fixture()
        self.assertEqual(self.validate(report, manifest), report)

    def test_failed_stale_missing_duplicate_or_wrong_source_rejected(self):
        report, manifest = self.fixture()
        for field, value in (("gpu", False), ("failures", ["failed"]), ("adapter_sha256", "stale"), ("states", 1163)):
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.validate({**report, field: value}, manifest)
        for operation in ("missing", "duplicate", "length", "order", "phase", "path", "hash"):
            bad = copy.deepcopy(report)
            if operation == "missing":
                bad["clips"].pop()
            elif operation == "duplicate":
                bad["clips"][-1] = copy.deepcopy(bad["clips"][0])
            elif operation == "length":
                bad["clips"][0]["source_frames"] += 1
            else:
                key, value = {"order": ("frame", 1), "phase": ("post_source", True), "path": ("path", "../escape.png"), "hash": ("sha256", "tampered")}[operation]
                bad["clips"][0]["frames"][0][key] = value
            with self.subTest(operation=operation), self.assertRaises(ValueError):
                self.validate(bad, manifest)


if __name__ == "__main__":
    unittest.main()
