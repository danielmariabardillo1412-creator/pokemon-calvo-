import json
import tempfile
import unittest
from pathlib import Path
import build_move_contact_sheets as contacts
from build_move_contact_sheets import make_groups, record, render_index, digest, write, sampling_rechecks, migrate_identical_boards


class ContactTests(unittest.TestCase):
    def test_catalog_contract_rechecks_real_png_not_just_claimed_metadata(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            image = root / "texture.png"
            image.write_bytes(b"original image")
            shard = root / "shard.json"
            write(shard, {"sheets": {"texture.png": {"sha256": digest(image), "dimensions": [1, 1]}},
                "clips": [{"id": "a/back", "sheet": "texture.png", "frames": [[], []]}]})
            index = root / "index.json"
            write(index, {"shards": [{"path": shard.name, "sha256": digest(shard)}]})
            self.assertIn("a/back", contacts.catalog_clip_contracts(index, digest(index), root)[1])
            image.write_bytes(b"tampered image with unchanged metadata")
            with self.assertRaisesRegex(ValueError, "catalog proof PNG changed"):
                contacts.catalog_clip_contracts(index, digest(index), root)

    def test_same_renderer_regrouping_keeps_old_exception_not_new_neighbours(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            cat = root / "catalog"
            cat.mkdir()
            old, new = root / "old/sheets", root / "new/sheets"
            for version, folder in (("old", old), ("new", new)):
                folder.mkdir(parents=True)
                ids = ["a/back"] if version == "old" else ["new/back", "a/back"]
                shard = cat / (version + ".json")
                write(shard, {"sheets": {}, "clips": [{"id": c, "frames": [[], []]} for c in ids]})
                idx = cat / (version + "_index.json")
                write(idx, {"canonical_hashes_unchanged": {}, "shards": [{"path": shard.name, "sha256": digest(shard)}]})
                snapshot = folder.parent / "renderer_snapshot.gd"
                snapshot.write_bytes(b"same renderer")
                images = []
                for c in ids:
                    image = folder.parent / (c.split("/")[0] + ".png")
                    image.write_bytes(c.encode())
                    images.append({"id": c, "title": c, "path": image.name, "sha256": digest(image), "samples": [0, 1, 1]})
                write(folder.parent / "captures.json", {"index_sha256": digest(idx), "renderer_sha256": digest(snapshot), "clips": images})
                (folder / "board.png").write_bytes(version.encode())
                write(folder / "boards.json", {"families": len(ids), "batch_size": 20, "index_sha256": digest(idx),
                    "capture_manifest_sha256": digest(folder.parent / "captures.json"), "pages": [{"id": "board", "path": "board.png", "sha256": digest(folder / "board.png"), "clip_ids": ids}]})
                write(folder / "review_log.json", {"reviews": []})
            write(cat / "index.json", contacts.read(cat / "new_index.json"))
            record(old, "board", "suspected_issue", "Keep previous exception")
            previous = cat / "old_index.json"
            self.assertEqual(migrate_identical_boards(old, new, previous, cat), 0)
            (new.parent / "renderer_snapshot.gd").write_bytes(b"changed snapshot")
            with self.assertRaisesRegex(ValueError, "renderer snapshot changed"):
                migrate_identical_boards(old, new, previous, cat, same_renderer_clips=True)
            (new.parent / "renderer_snapshot.gd").write_bytes(b"same renderer")
            capture_path = new.parent / "captures.json"
            captured = contacts.read(capture_path)
            captured["renderer_sha256"] = "other"
            write(capture_path, captured)
            boards = contacts.read(new / "boards.json")
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            with self.assertRaisesRegex(ValueError, "changed renderer"):
                migrate_identical_boards(old, new, previous, cat, same_renderer_clips=True)
            captured["renderer_sha256"] = digest(new.parent / "renderer_snapshot.gd")
            captured["clips"][1]["samples"] = [1, 1, 1]
            write(capture_path, captured)
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            self.assertEqual(migrate_identical_boards(old, new, previous, cat, same_renderer_clips=True), 0)
            captured["clips"][1]["samples"] = [0, 1, 1]
            write(capture_path, captured)
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            self.assertEqual(migrate_identical_boards(old, new, previous, cat, same_renderer_clips=True), 1)
            ledger = contacts.read(new / "review_log.json")
            self.assertEqual(ledger["reviews"][0]["clip_ids"], ["a/back"])
            self.assertEqual(ledger["reviews"][0]["status"], "suspected_issue")
            self.assertIn("pending: 1", (new / "index.md").read_text(encoding="utf-8"))
            self.assertEqual(migrate_identical_boards(old, new, previous, cat, same_renderer_clips=True), 0)

    def test_renderer_migration_is_clip_scoped_and_requires_complete_matching_proof(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            cat = root / "catalog"
            cat.mkdir()
            old, new = root / "old/sheets", root / "new/sheets"
            ids = ["a/back", "b/back", "c/back"]
            for version, folder in (("old", old), ("new", new)):
                folder.mkdir(parents=True)
                clips = [{"id": c, "frames": [[], []], "value": 2 if version == "new" and c == "b/back" else 1} for c in ids]
                shard = cat / (version + "_shard.json")
                write(shard, {"sheets": {}, "clips": clips})
                index = cat / (version + "_index.json")
                write(index, {"canonical_hashes_unchanged": {"data": "same"}, "shards": [{"path": shard.name, "sha256": digest(shard)}]})
                images = []
                for c in ids:
                    path = folder.parent / (c[0] + ".png")
                    path.write_bytes(b"identical native screenshot")
                    images.append({"id": c, "path": path.name, "sha256": digest(path), "samples": [0, 1, 1], "title": c})
                write(folder.parent / "captures.json", {"index_sha256": digest(index), "renderer_sha256": version, "clips": images})
                (folder / "board.png").write_bytes(version.encode())
                write(folder / "boards.json", {"families": 3, "batch_size": 20, "index_sha256": digest(index),
                    "capture_manifest_sha256": digest(folder.parent / "captures.json"), "pages": [{"id": "board", "path": "board.png", "sha256": digest(folder / "board.png"), "clip_ids": ids}]})
                write(folder / "review_log.json", {"reviews": []})
            write(cat / "index.json", json.loads((cat / "new_index.json").read_text()))
            record(old, "board", "sampled_no_obvious_issue", "Previous page")
            record(old, "board", "needs_motion_review", "Exception stays", "a/back")
            previous = cat / "old_index.json"
            with self.assertRaisesRegex(ValueError, "changed data/renderer"):
                migrate_identical_boards(old, new, previous, cat)
            proof_path = root / "proof.json"
            proof = {"version": 1, "failures": [], "frames": 12,
                "old_index_sha256": digest(previous), "new_index_sha256": digest(cat / "index.json"),
                "old_renderer_sha256": "old", "new_renderer_sha256": "new",
                "runner_sha256": digest(contacts.GAME / "tests/visual/move_render_equivalence_runner.gd"),
                "equivalent_clip_ids": ids[:2], "changed_clip_ids": ids[2:]}
            for field, bad in (("runner_sha256", "bad"), ("old_index_sha256", "bad"), ("new_renderer_sha256", "bad"), ("failures", ["fail"]), ("frames", 11), ("changed_clip_ids", []), ("equivalent_clip_ids", ids)):
                write(proof_path, {**proof, field: bad})
                with self.subTest(field=field), self.assertRaises(ValueError):
                    migrate_identical_boards(old, new, previous, cat, proof_path)
            write(proof_path, proof)
            capture_path = new.parent / "captures.json"
            captures = contacts.read(capture_path)
            altered = json.loads(json.dumps(captures))
            altered["clips"][0]["samples"] = [1, 1, 1]
            write(capture_path, altered)
            boards = contacts.read(new / "boards.json")
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            self.assertEqual(migrate_identical_boards(old, new, previous, cat, proof_path), 0)
            write(capture_path, captures)
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            image = new.parent / "a.png"
            image.write_bytes(b"tampered native image")
            with self.assertRaisesRegex(ValueError, "native capture evidence changed"):
                migrate_identical_boards(old, new, previous, cat, proof_path)
            image.write_bytes(b"identical native screenshot")
            self.assertEqual(migrate_identical_boards(old, new, previous, cat, proof_path), 1)
            ledger = json.loads((new / "review_log.json").read_text())
            self.assertEqual(ledger["reviews"][0]["clip_ids"], ["a/back"])
            self.assertEqual(ledger["reviews"][0]["status"], "needs_motion_review")
            self.assertIn("neighbours NOT reviewed", ledger["reviews"][0]["migration_basis"])
            self.assertEqual(migrate_identical_boards(old, new, previous, cat, proof_path), 0)

    def test_twenty_paired_families_and_alerts_first(self):
        clips = [{"family": f"move_{n:03d}", "side": side} for n in range(43) for side in ("back", "front")]
        families, groups = make_groups(clips, {"move_042"}, 20)
        self.assertEqual([len(g) for g in groups], [20, 20, 3])
        self.assertEqual(groups[0][0], "move_042")
        self.assertEqual(len({name for group in groups for name in group}), 43)
        self.assertEqual(set(families["move_042"]), {"back", "front"})

    def test_bad_size_duplicate_or_missing_side_rejected(self):
        clips = [{"family": "tackle", "side": "back"}]
        for data, size in [(clips, 20), (clips * 2, 20), ([], 21), ([], 0)]:
            with self.subTest(data=data, size=size), self.assertRaises(ValueError):
                make_groups(data, set(), size)

    def test_static_sample_recheck_does_not_approve_art(self):
        clips = [{"id": "mimic/back", "distinct_gpu_samples": 3}, {"id": "still/back", "distinct_gpu_samples": 1}]
        audit = {"clips": [{"id": row["id"], "warnings": ["unchanged_GPU_samples_review/(640, 360)"]} for row in clips]}
        result = sampling_rechecks(clips, audit)
        self.assertEqual([row["id"] for row in result], ["mimic/back"])
        self.assertIn("still pending", result[0]["finding"])

    def test_review_hashes_pending_and_clip_scoped_overrides(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            image = root / "board.png"
            image.write_bytes(b"fake evidence for hash test")
            page = {"id": "batch_01_back", "path": "board.png", "sha256": digest(image), "clip_ids": ["a/back", "b/back"]}
            boards = {"version": 1, "index_sha256": "index_a", "families": 2, "batch_size": 20, "pages": [page]}
            write(root / "boards.json", boards)
            write(root / "review_log.json", {"version": 1, "index_sha256": "index_a", "reviews": []})
            render_index(root, boards)
            self.assertIn("pending: 2", (root / "index.md").read_text(encoding="utf-8"))
            record(root, "batch_01_back", "sampled_no_obvious_issue", "Viewed static sheet, no motion approval")
            record(root, "batch_01_back", "suspected_issue", "Looks cropped; inspect motion", "b/back")
            text = (root / "index.md").read_text(encoding="utf-8")
            self.assertIn("sampled_no_obvious_issue: 1", text)
            self.assertIn("suspected_issue: 1", text)
            with self.assertRaisesRegex(ValueError, "clip not in board"):
                record(root, "batch_01_back", "confirmed_issue", "Wrong membership", "c/back")
            image.write_bytes(b"changed evidence")
            with self.assertRaisesRegex(ValueError, "board changed"):
                record(root, "batch_01_back", "sampled_no_obvious_issue", "Cannot reuse old review")
            boards["pages"][0]["sha256"] = digest(image)
            render_index(root, boards)
            self.assertIn("pending: 2", (root / "index.md").read_text(encoding="utf-8"))
            self.assertIn("HISTORICO", (root / "index.md").read_text(encoding="utf-8"))

    def test_migrate_only_identical_boards_with_matching_context(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            old, new = root / "old/sheets", root / "new/sheets"
            for folder in (old, new):
                folder.mkdir(parents=True)
                write(folder.parent / "captures.json", {"renderer_sha256": "same_renderer"})
                (folder / "first.png").write_bytes(b"identical image bytes")
                (folder / "second.png").write_bytes(b"old image" if folder == old else b"different image")
                pages = [{"id": "batch_01_back", "path": "first.png", "sha256": digest(folder / "first.png"), "clip_ids": ["a/back", "b/back"]},
                         {"id": "batch_02_back", "path": "second.png", "sha256": digest(folder / "second.png"), "clip_ids": ["c/back"]}]
                write(folder / "boards.json", {"version": 1, "index_sha256": "same_index", "families": 3, "batch_size": 20, "pages": pages,
                                               "capture_manifest_sha256": digest(folder.parent / "captures.json")})
                write(folder / "review_log.json", {"version": 1, "index_sha256": "same_index", "reviews": []})
            record(old, "batch_01_back", "sampled_no_obvious_issue", "Viewed")
            record(old, "batch_01_back", "suspected_issue", "Exception override", "b/back")
            record(old, "batch_02_back", "needs_motion_review", "Changed image must not inherit")
            self.assertEqual(migrate_identical_boards(old, new), 2)
            text = (new / "index.md").read_text(encoding="utf-8")
            self.assertIn("suspected_issue: 1", text)
            self.assertIn("sampled_no_obvious_issue: 1", text)
            self.assertIn("pending: 1", text)
            self.assertEqual(migrate_identical_boards(old, new), 0)
            changed = json.loads((new / "boards.json").read_text(encoding="utf-8"))
            changed["index_sha256"] = "different_index"
            write(new / "boards.json", changed)
            with self.assertRaisesRegex(ValueError, "changed data/renderer"):
                migrate_identical_boards(old, new)

    def test_changed_index_requires_identical_pinned_clip_contract_and_gpu_samples(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            cat = root / "catalog"
            cat.mkdir()
            for version in ("old", "new"):
                write(cat / (version + "_shard.json"), {"sheets": {}, "clips": [
                    {"id": "a/back", "source_value": 1},
                    {"id": "b/back", "source_value": 1 if version == "old" else 2}]})
                write(cat / (version + "_index.json"), {"canonical_hashes_unchanged": {"dataset": "same"},
                      "shards": [{"path": version + "_shard.json", "sha256": digest(cat / (version + "_shard.json"))}]})
            write(cat / "index.json", json.loads((cat / "new_index.json").read_text()))
            old, new = root / "old/sheets", root / "new/sheets"
            for version, folder in (("old", old), ("new", new)):
                folder.mkdir(parents=True)
                clips = [{"id": c + "/back", "sha256": "same_pixels", "samples": [1, 2, 3]} for c in ("a", "b")]
                idx = digest(cat / (version + "_index.json"))
                write(folder.parent / "captures.json", {"renderer_sha256": "same", "clips": clips, "index_sha256": idx})
                pages = []
                for i, key in enumerate(("a", "b"), 1):
                    (folder / (key + ".png")).write_bytes(b"identical image even for changed source")
                    pages.append({"id": f"batch_{i:02}_back", "path": key + ".png", "sha256": digest(folder / (key + ".png")), "clip_ids": [key + "/back"]})
                idx = digest(cat / (version + "_index.json"))
                write(folder / "boards.json", {"index_sha256": idx, "families": 2, "batch_size": 20, "pages": pages,
                      "capture_manifest_sha256": digest(folder.parent / "captures.json")})
                write(folder / "review_log.json", {"reviews": []})
            record(old, "batch_01_back", "needs_motion_review", "Original exception survives")
            record(old, "batch_02_back", "sampled_no_obvious_issue", "Source will change")
            with self.assertRaisesRegex(ValueError, "changed data/renderer"):
                migrate_identical_boards(old, new)
            capture_path = new.parent / "captures.json"
            captures = json.loads(capture_path.read_text())
            changed_captures = json.loads(capture_path.read_text())
            changed_captures["clips"][0]["samples"] = [7, 8, 9]
            write(capture_path, changed_captures)
            boards = json.loads((new / "boards.json").read_text())
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            self.assertEqual(migrate_identical_boards(old, new, cat / "old_index.json", cat), 0)
            write(capture_path, captures)
            boards["capture_manifest_sha256"] = digest(capture_path)
            write(new / "boards.json", boards)
            self.assertEqual(migrate_identical_boards(old, new, cat / "old_index.json", cat), 1)
            text = (new / "index.md").read_text(encoding="utf-8")
            self.assertIn("needs_motion_review: 1", text)
            self.assertIn("pending: 1", text)
            self.assertEqual(migrate_identical_boards(old, new, cat / "old_index.json", cat), 0)
            (cat / "old_index.json").write_text("{}")
            with self.assertRaisesRegex(ValueError, "proof hash"):
                migrate_identical_boards(old, new, cat / "old_index.json", cat)


if __name__ == "__main__":
    unittest.main()
