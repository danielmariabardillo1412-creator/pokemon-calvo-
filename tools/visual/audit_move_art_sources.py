"""Independent source/roles and unchanged-baseline proof of two art decisions."""
import argparse
import json
import sys
from pathlib import Path
from build_move_contact_sheets import GAME, read, write, digest, catalog_clip_contracts
from move_art_choices import SOURCE_HASHES, REJECTED_HASHES
from move_visual_equivalents import fingerprint
from move_layer_timing import bake_layers

EXPECTED = {"armor_cannon": "FLAMEBURST", "max_flutterby": "SILVERWIND"}


def audit(source, baseline):
    root = GAME / ".godot/move_batch_catalog"
    old, before = catalog_clip_contracts(baseline, digest(baseline), root)
    index, after = catalog_clip_contracts(root / "index.json", digest(root / "index.json"), root)
    changed = {cid for cid in before.keys() & after.keys() if before[cid] != after[cid]}
    if before.keys() != after.keys() or changed != {m + "/" + s for m in EXPECTED for s in ("back", "front")}:
        raise ValueError("unexpected changed art contract set")
    if old["canonical_hashes_unchanged"] != index["canonical_hashes_unchanged"] or any(digest(Path(p)) != sha for p, sha in index["canonical_hashes_unchanged"].items()):
        raise ValueError("canonical data changed")
    if index["priority_manifest_sha256"] != old["priority_manifest_sha256"] or digest(GAME / ".godot/move_resource_pilot/manifest.json") != old["priority_manifest_sha256"]:
        raise ValueError("historical priority seed changed")
    if index["art_equivalent_moves"] != 2 or index["visual_equivalent_moves"] != 10 or len(index["primary_source_gaps_retained"]) != 10 or index["counts"] != old["counts"]:
        raise ValueError("art choice confused with source-gap repair/coverage")
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9
    names = {}
    for animation in load_gen9():
        if hasattr(animation, "attrs"):
            names.setdefault(animation.attrs.get("@name"), []).append(animation.attrs)
    moves = read(GAME / "data/normalized/pokemon_api.json")["moves"]
    rows = []
    for cid in sorted(changed):
        clip = json.loads(after[cid])[0]
        previous = json.loads(before[cid])[0]
        label = EXPECTED[clip["move_id"]]
        expected_name = ("OppMove:" if clip["actor_side"] == "front" and names.get("OppMove:" + label) else "Move:") + label
        if clip["name"] != expected_name or len(names.get(expected_name, [])) != 1:
            raise ValueError("incorrect selected source/export")
        attrs = names[expected_name][0]
        meta = clip["visual_art_choice"]
        if fingerprint(attrs) != SOURCE_HASHES[expected_name] or meta["source_sha256"] != fingerprint(attrs):
            raise ValueError("selected source changed")
        old_name = meta["replaced_source_name"]
        if old_name != previous["name"] or len(names.get(old_name, [])) != 1 or fingerprint(names[old_name][0]) != REJECTED_HASHES[old_name] or meta["replaced_source_sha256"] != fingerprint(names[old_name][0]):
            raise ValueError("unreviewed rejected source")
        if meta["native_source_repaired"] is not False or meta["mechanics_enabled"] is not False or meta["replaced_source_status"] != "renderable_but_art_rejected" or meta["source_modifications"]:
            raise ValueError("misleading art provenance")
        if clip["frames"] != [list(f[:60]) for f in attrs["@array"]] or clip["fps"] != 20 or clip["layers"] != bake_layers(attrs.get("@timing", []), len(clip["frames"])):
            raise ValueError("source cells/cadence/layers changed")
        graphics = source / "Gen9_Move_Animations/Graphics/Animations"
        for filename, key in {**clip["layer_sheets"], attrs["@graphic"]: clip["sheet"]}.items():
            path = graphics / filename
            if not path.suffix:
                path = path.with_suffix(".png")
            if digest(path) + ".png" != key:
                raise ValueError("source artwork changed")
        native = clip["actor_side"] == "front" and expected_name.startswith("OppMove:")
        mapped = clip["actor_side"] == "front" and not native
        if clip["opponent_export"] != native or clip["mapped_opponent"] != mapped or clip["slot_sides"] != (["front", "back"] if mapped else ["back", "front"]):
            raise ValueError("wrong actor/target roles")
        move = moves[clip["move_id"]]
        if clip["title"] != move["display_name"] or clip["target_scope"] != move["target"] or clip["classification_unchanged"] != move["classification"]:
            raise ValueError("title/target/mechanics changed")
        rows.append({"id": cid, "source_name": expected_name, "frames": len(clip["frames"]), "replaced_source_name": old_name})
    report = {"version": 1, "index_sha256": digest(root / "index.json"), "baseline_sha256": digest(baseline),
        "runner_sha256": digest(Path(__file__)), "existing_identical_clips": len(before) - len(changed),
        "replaced_art_clips": rows, "native_gaps_fixed": 0, "battle_routes_added": 0,
        "priority_seed_unchanged": index["priority_manifest_sha256"], "scope": "Art-source proof only, not GPU/art-motion/mechanics approval"}
    output = GAME / ".godot/move_art_checks" / report["index_sha256"][:16] / "sources.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    write(output, report)
    print("ART_SOURCES PASS unchanged=", report["existing_identical_clips"], "replaced=4 native_gaps_fixed=0 output=", output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    args = parser.parse_args()
    audit(args.source_root.resolve(), args.baseline)
