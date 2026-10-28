import copy
import unittest
from review_move_temporal_batches import make_plan, select_samples, review_clip_ids


class TemporalBatchTests(unittest.TestCase):
    def test_mixed_page_cannot_approve_unviewed_or_duplicate_clips(self):
        page = {"clips": [{"id": "acid/back"}, {"id": "absorb/back"}]}
        self.assertEqual(review_clip_ids(page, ["acid/back"]), ["acid/back"])
        self.assertEqual(review_clip_ids(page), ["acid/back", "absorb/back"])
        for selected in (["acid/front"], ["acid/back", "acid/back"]):
            with self.assertRaises(ValueError):
                review_clip_ids(page, selected)

    def fixture(self):
        names = [f"move_{n:03}" for n in range(103)]
        clips = [{"move_id": name, "id": name + "/" + side} for name in names for side in ("back", "front")]
        clips += [{"move_id": names[0], "id": names[0] + "/extra/" + side} for side in ("back", "front")]
        return {"moves": [{"move_id": name, "status": "converted_lab_only"} for name in names], "shards": [{"entries": clips}], "converted_clips": len(clips)}

    def test_partition_covers_every_move_clip_and_variant_once(self):
        value = self.fixture()
        plan = make_plan(value, "index", "renderer", "builder")
        self.assertEqual([len(b["move_ids"]) for b in plan["batches"]], [50, 50, 3])
        ids = [cid for b in plan["batches"] for cid in b["clip_ids"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(ids), value["converted_clips"])
        self.assertFalse(plan["mechanics_approved"])
        self.assertEqual(plan, make_plan(value, "index", "renderer", "builder"))

    def test_missing_side_duplicate_wrong_count_or_unknown_membership_rejected(self):
        for mode in ("side", "duplicate", "count", "unknown"):
            value = self.fixture()
            if mode == "side":
                value["shards"][0]["entries"].pop()
                value["converted_clips"] -= 1
            elif mode == "duplicate":
                value["shards"][0]["entries"].append(copy.deepcopy(value["shards"][0]["entries"][0]))
                value["converted_clips"] += 1
            elif mode == "count":
                value["converted_clips"] += 1
            else:
                value["shards"][0]["entries"][0]["move_id"] = "unknown"
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                make_plan(value, "i", "r", "b")

    def test_temporal_samples_keep_endpoints_peak_and_short_sequences(self):
        for count in (2, 13, 16, 35, 100):
            clip = {"frames": [{"source_visible_particle_cels": 10 if n == count // 2 else 0} for n in range(count)]}
            differences = [0.0] * count
            differences[min(7, count - 1)] = 1.0
            result = select_samples(clip, differences)
            self.assertEqual(len(result), 16)
            self.assertEqual(result, sorted(result))
            self.assertIn(0, result)
            self.assertIn(count - 1, result)
            self.assertIn(count // 2, result)
            if count <= 16:
                self.assertEqual(set(result), set(range(count)))
            else:
                self.assertIn(6, result)
                self.assertIn(7, result)
