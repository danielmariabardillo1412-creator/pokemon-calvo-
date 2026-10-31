import copy
import json
import unittest
from audit_move_geometry_sources import metadata_only


class GeometryProofTests(unittest.TestCase):
    def fixture(self):
        before = {"other/back": json.dumps([{"frames": [[1]]}, {}])}
        after = dict(before)
        for side in ("back", "front"):
            cid = "oblivion_wing/" + side
            old = [{"id": cid, "frames": [[1]], "audit_flags": ["existing"]}, {"sheet": "pinned"}]
            new = copy.deepcopy(old)
            new[0].update(particle_geometry={"policy": "test"}, affine_particle_patterns=[0, 1, 2, 3, 4])
            new[0]["audit_flags"].append("audited_native_particle_geometry")
            before[cid], after[cid] = json.dumps(old), json.dumps(new)
        return before, after

    def test_accepts_exact_paired_metadata_only_change(self):
        before, after = self.fixture()
        self.assertEqual(metadata_only(before, after), ["oblivion_wing/back", "oblivion_wing/front"])

    def test_rejects_extra_partial_or_membership_change(self):
        before, after = self.fixture()
        for bad in (dict(after, **{"other/back": "changed"}), dict(after, **{"oblivion_wing/front": before["oblivion_wing/front"]}),
                    {k: v for k, v in after.items() if k != "other/back"}, dict(after, extra="new")):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                metadata_only(before, bad)

    def test_rejects_source_art_flags_or_pattern_changes(self):
        before, after = self.fixture()
        for field, value in (("frames", [[2]]), ("sheet", "new art"), ("title", "changed"),
                             ("affine_particle_patterns", [0]), ("audit_flags", ["audited_native_particle_geometry"]),
                             ("particle_geometry", None)):
            bad = dict(after)
            data = json.loads(bad["oblivion_wing/back"])
            data[0][field] = value
            bad["oblivion_wing/back"] = json.dumps(data)
            with self.subTest(field=field), self.assertRaises(ValueError):
                metadata_only(before, bad)


if __name__ == "__main__":
    unittest.main()
