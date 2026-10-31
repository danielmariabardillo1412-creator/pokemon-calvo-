import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from summarize_move_batch import summarize


class SummaryTests(unittest.TestCase):
    def test_equivalent_is_renderable_but_native_source_gap_stays_visible(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            index = root / "index.json"
            audit = root / "audit.json"
            index.write_text(json.dumps({"catalog_moves": 2, "converted_clips": 2, "visual_equivalent_moves": 1,
                "primary_source_gaps_retained": [{"move_id": "rest", "reason": "missing_pattern:5"}],
                "moves": [{"move_id": "rest", "status": "converted_lab_only", "primary_source_issue": "missing_pattern:5"},
                          {"move_id": "unknown", "status": "quarantined", "reason": "missing_label"}]}), encoding="utf-8")
            sha = hashlib.sha256(index.read_bytes()).hexdigest()
            audit.write_text(json.dumps({"index_sha256": sha, "failures": [], "gpu": True, "checks": 3, "frames": 4,
                "clips": [{"id": "rest/" + side, "warnings": [], "source_flags": []} for side in ("back", "front")]}), encoding="utf-8")
            report = summarize(index, audit, root)
            self.assertEqual(report["converted_moves"], 1)
            self.assertEqual(report["quarantined_moves"], 1)
            self.assertEqual(report["native_source_gaps_retained"], 1)
            self.assertEqual(report["explicit_visual_equivalent_moves"], 1)
            self.assertEqual(report["battle_routes_added"], 0)
            self.assertFalse(report["aesthetic_or_mechanical_approval"])
            self.assertTrue(any(g["group"].startswith("native_gap_covered_by_equivalent/") for g in report["groups"]))

    def test_stale_failed_incomplete_evidence_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            index = root / "index.json"
            audit = root / "audit.json"
            index.write_text(json.dumps({"converted_clips": 2}), encoding="utf-8")
            digest = hashlib.sha256(index.read_bytes()).hexdigest()
            for sha, failures, clips in [("wrong", [], [{}, {}]), (digest, ["failed"], [{}, {}]), (digest, [], [{}])]:
                with self.subTest(sha=sha, failures=failures, clips=len(clips)):
                    audit.write_text(json.dumps({"index_sha256": sha, "failures": failures, "clips": clips}), encoding="utf-8")
                    with self.assertRaisesRegex(ValueError, "Stale/incomplete/failed"):
                        summarize(index, audit, root)


if __name__ == "__main__":
    unittest.main()
