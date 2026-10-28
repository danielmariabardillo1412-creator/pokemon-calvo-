import unittest
import copy
import tempfile
from pathlib import Path
from unittest.mock import patch
import build_move_temporal_sheets as temporal
from build_move_contact_sheets import digest, write
from build_move_temporal_sheets import sample_frames


class TemporalTests(unittest.TestCase):
    def test_capture_validation_rejects_stale_failed_incomplete_or_changed_frames(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            cat = root / ".godot/move_batch_catalog"
            cat.mkdir(parents=True)
            source = {"id": "test/back", "name": "Move:TEST", "frames": [[], []]}
            write(cat / "shard.json", {"sheets": {}, "clips": [source]})
            write(cat / "index.json", {"shards": [{"path": "shard.json", "sha256": digest(cat / "shard.json")}]})
            for relative in ("scenes/visual/community_move_preview.gd", "tests/visual/move_temporal_review.gd"):
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"pinned test source")
            frames = []
            for n in range(2):
                path = root / f"frame_{n}.png"
                path.write_bytes(b"pinned screenshot bytes")
                frames.append({"frame": n, "seconds": n / 20, "path": path.name, "sha256": digest(path)})
            report = {"version": 1, "failures": [], "frames": 2, "index_sha256": digest(cat / "index.json"),
                      "renderer_sha256": digest(root / "scenes/visual/community_move_preview.gd"),
                      "runner_sha256": digest(root / "tests/visual/move_temporal_review.gd"),
                      "clips": [{"id": "test/back", "source_name": "Move:TEST", "fps": 20,
                                 "cleanup_matches_baseline": True, "frames": frames}]}
            path = root / "result.json"
            with patch.object(temporal, "GAME", root):
                write(path, report)
                self.assertEqual(temporal.validate(path), report)
                variants = []
                for field, value in (("failures", ["fail"]), ("renderer_sha256", "bad"), ("runner_sha256", "bad"), ("frames", 3)):
                    variants.append({**copy.deepcopy(report), field: value})
                bad = copy.deepcopy(report)
                bad["clips"][0]["frames"].pop()
                variants.append(bad)
                bad = copy.deepcopy(report)
                bad["clips"][0]["frames"][1]["frame"] = 0
                variants.append(bad)
                bad = copy.deepcopy(report)
                bad["clips"][0]["cleanup_matches_baseline"] = False
                variants.append(bad)
                variants.append({**copy.deepcopy(report), "clips": report["clips"] * 2})
                # Explicit comparisons must include both sides of every unique
                # requested move, and cannot claim a larger/different selection.
                for names in (["test"], ["test", "test"], ["unknown"], [f"move_{n}" for n in range(11)]):
                    variants.append({**copy.deepcopy(report), "requested_moves": names})
                for n, bad in enumerate(variants):
                    write(path, bad)
                    with self.subTest(case=n), self.assertRaises(ValueError):
                        temporal.validate(path)
                write(path, report)
                (root / "frame_0.png").write_bytes(b"tampered")
                with self.assertRaisesRegex(ValueError, "native frame changed"):
                    temporal.validate(path)

    def test_short_sequences_cover_every_frame_and_endpoints(self):
        for count in range(1, 9):
            with self.subTest(count=count):
                frames = [{"visible_source_particles": 0} for _ in range(count)]
                selection = sample_frames(frames)
                self.assertEqual(len(selection), 8)
                self.assertEqual(set(selection), set(range(count)))
                self.assertEqual(selection, sorted(selection))

    def test_short_impact_peak_not_lost_between_percentiles(self):
        frames = [{"visible_source_particles": int(n == 3) * 10} for n in range(80)]
        result = sample_frames(frames)
        self.assertEqual(len(set(result)), 8)
        self.assertIn(0, result)
        self.assertIn(79, result)
        self.assertIn(3, result)

    def test_empty_rejected_and_long_selection_deterministic(self):
        with self.assertRaises(ValueError):
            sample_frames([])
        frames = [{"visible_source_particles": n % 13} for n in range(200)]
        result = sample_frames(frames)
        self.assertEqual(result, sample_frames(frames))
        self.assertEqual(result, sorted(result))
        self.assertIn(12, result)
        self.assertEqual((result[0], result[-1]), (0, 199))


if __name__ == "__main__":
    unittest.main()
