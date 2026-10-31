"""Independent proof of a geometry-metadata-only Oblivion Wing correction."""
import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path
from build_move_contact_sheets import catalog_clip_contracts, digest, read, write
from move_layer_timing import bake_layers

GAME = Path(__file__).resolve().parents[2]
EXPECTED = {"oblivion_wing/back", "oblivion_wing/front"}
SOURCE_HASHES = {
    "Move:OBLIVIONWING": "fc76f28e858d9961ddfbaea872d271c0f73500fc7d1f0769c601b2ffea60c9dc",
    "OppMove:OBLIVIONWING": "45ff47b7392aafd89e240f0d1aab7ed1c5b47138ed65bf5be632795a5b6c5fee",
}


def metadata_only(before, after):
    if before.keys() != after.keys():
        raise ValueError("clip membership changed")
    changed = {cid for cid in before if before[cid] != after[cid]}
    if changed != EXPECTED:
        raise ValueError("unexpected geometry change set")
    for cid in sorted(changed):
        old = json.loads(before[cid])
        new = copy.deepcopy(json.loads(after[cid]))
        clip = new[0]
        if "particle_geometry" in old[0] or "affine_particle_patterns" in old[0]:
            raise ValueError("baseline already has geometry repair")
        if not isinstance(clip.pop("particle_geometry", None), dict) or clip.pop("affine_particle_patterns", None) != [0, 1, 2, 3, 4]:
            raise ValueError("missing geometry declaration")
        flags = clip.get("audit_flags", [])
        if flags.count("audited_native_particle_geometry") != 1:
            raise ValueError("missing/duplicate geometry flag")
        flags.remove("audited_native_particle_geometry")
        if new != old:
            raise ValueError("non-geometry contract changed")
    return sorted(changed)


def audit(source, baseline):
    root = GAME / ".godot/move_batch_catalog"
    old, before = catalog_clip_contracts(baseline, digest(baseline), root)
    index, after = catalog_clip_contracts(root / "index.json", digest(root / "index.json"), root)
    changed = metadata_only(before, after)
    if old["canonical_hashes_unchanged"] != index["canonical_hashes_unchanged"]:
        raise ValueError("canonical contract changed")
    for path, sha in index["canonical_hashes_unchanged"].items():
        if digest(Path(path)) != sha:
            raise ValueError("canonical source changed")
    renderer = GAME / "scenes/visual/community_move_preview.gd"
    if digest(renderer) != digest(baseline.parent / "renderer_snapshot.gd"):
        raise ValueError("renderer changed")
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9
    names = {}
    for animation in load_gen9():
        if hasattr(animation, "attrs"):
            names.setdefault(animation.attrs.get("@name"), []).append(animation.attrs)
    move = read(GAME / "data/normalized/pokemon_api.json")["moves"]["oblivion_wing"]
    rows = []
    for cid in changed:
        clip = json.loads(after[cid])[0]
        expected = ("Move:" if cid.endswith("/back") else "OppMove:") + "OBLIVIONWING"
        if clip["name"] != expected or len(names.get(expected, [])) != 1:
            raise ValueError("wrong or ambiguous source")
        attrs = names[expected][0]
        sha = hashlib.sha256(json.dumps(attrs, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        if sha != SOURCE_HASHES[expected]:
            raise ValueError("source changed")
        array_sha = hashlib.sha256(json.dumps(attrs["@array"], separators=(",", ":")).encode()).hexdigest()
        if clip["particle_geometry"] != {"policy": "pinned_canonical_affine_particle_basis_v1",
                "source_frames_sha256": array_sha, "patterns": [0, 1, 2, 3, 4]}:
            raise ValueError("wrong geometry provenance")
        if clip["frames"] != [list(f[:60]) for f in attrs["@array"]] or len(clip["frames"]) != 35 or clip["fps"] != 20:
            raise ValueError("source cells/cadence changed")
        if clip["layers"] != bake_layers(attrs.get("@timing", []), 35):
            raise ValueError("source layers changed")
        if (clip["slot_sides"] != ["back", "front"] or clip["mapped_opponent"]
                or clip["opponent_export"] != expected.startswith("OppMove:")
                or clip["target_scope"] != move["target"] or clip["title"] != move["display_name"]
                or clip["classification_unchanged"] != move["classification"]):
            raise ValueError("actor/target/mechanics contract changed")
        if attrs["@hue"] != 140 or clip["sheet_hue"]["degrees"] != 140:
            raise ValueError("source hue changed")
        if any(c[26] != 3 for f in clip["frames"] for c in f if c is not None and c[7] >= 0):
            raise ValueError("particle not source-line anchored")
        rows.append({"id": cid, "source_sha256": sha, "source_frames_sha256": array_sha,
                     "frames": 35, "hue": 140, "source_cells_layers_and_art_preserved": True})
    report = {"version": 1, "index_sha256": digest(root / "index.json"), "baseline_sha256": digest(baseline),
              "renderer_sha256": digest(renderer), "runner_sha256": digest(Path(__file__)),
              "existing_identical_clips": len(before) - len(changed), "geometry_only_clips": rows,
              "battle_routes_added": 0, "scope": "Source and contract proof, not GPU geometry/art/mechanics approval"}
    output = GAME / ".godot/move_geometry_checks" / report["index_sha256"][:16] / "sources.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    write(output, report)
    print("GEOMETRY_SOURCES PASS unchanged=", report["existing_identical_clips"], "geometry_only=", len(rows), "output=", output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    args = parser.parse_args()
    audit(args.source_root.resolve(), args.baseline)
