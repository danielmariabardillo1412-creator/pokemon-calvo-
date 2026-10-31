import copy
import unittest
from build_move_trajectory_sheets import check_matrix, display_frames, MOVES, MODES


class TrajectoryTests(unittest.TestCase):
    def fixture(self):
        return {"frames": len(MOVES) * 2 * len(MODES) * 2, "clips": [{"id": move + "/" + side, "mode": mode,
            "frames": [{"frame": 0}, {"frame": 1}], "sample_frames": [0, 1]}
            for move in MOVES for side in ("back", "front") for mode in MODES]}

    def test_complete_matrix(self):
        check_matrix(self.fixture())

    def test_oblivion_has_all_sides_and_cameras(self):
        keys = {(c["id"], c["mode"]) for c in self.fixture()["clips"] if c["id"].startswith("oblivion_wing/")}
        self.assertEqual(keys, {("oblivion_wing/" + side, mode) for side in ("back", "front") for mode in MODES})

    def test_silhouette_peak_included_without_claiming_damage(self):
        clip = {"frames": [{} for _ in range(28)], "sample_frames": [8, 14, 20, 27], "body_peak_frame": 16}
        self.assertEqual(display_frames(clip), [8, 16, 20, 27])
        clip["body_peak_frame"] = 28
        with self.assertRaisesRegex(ValueError, "invalid silhouette peak"):
            display_frames(clip)

    def test_missing_duplicate_or_wrong_mode_rejected(self):
        for variant in ("missing", "duplicate", "mode"):
            report = self.fixture()
            if variant == "missing":
                report["clips"].pop()
            elif variant == "duplicate":
                report["clips"][-1] = copy.deepcopy(report["clips"][0])
            else:
                report["clips"][0]["mode"] = "unknown"
            with self.subTest(variant=variant), self.assertRaises(ValueError):
                check_matrix(report)

    def test_frame_order_samples_and_count_rejected(self):
        for variant in ("order", "sample", "count"):
            report = self.fixture()
            if variant == "order":
                report["clips"][0]["frames"][1]["frame"] = 0
            elif variant == "sample":
                report["clips"][0]["sample_frames"] = [2]
            else:
                report["frames"] -= 1
            with self.subTest(variant=variant), self.assertRaises(ValueError):
                check_matrix(report)


if __name__ == "__main__":
    unittest.main()
