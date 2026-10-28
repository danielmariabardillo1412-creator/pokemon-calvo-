"""Independent source/role proof of the ten explicit equivalents, not native repair."""
import argparse
import copy
import json
import sys
from pathlib import Path
from build_move_contact_sheets import catalog_clip_contracts, digest, read, write
from move_visual_equivalents import CHOICES, SOURCE_HASHES, fingerprint
from move_layer_timing import bake_layers

GAME = Path(__file__).resolve().parents[2]


def changed_contracts(before, after, replacement_moves=()):
    """Require exactly the declared paired replacement, or original additions."""
    expected = {m + "/" + s for m in (replacement_moves or CHOICES) for s in ("back", "front")}
    if replacement_moves:
        if len(set(replacement_moves)) != len(replacement_moves) or not set(replacement_moves) <= CHOICES.keys():
            raise ValueError("invalid replacement moves")
        changed = {cid for cid in before.keys() & after.keys() if before[cid] != after[cid]}
        if before.keys() != after.keys() or changed != expected:
            raise ValueError("unexpected replacement contract set")
    else:
        if not before.keys() <= after.keys() or any(after[c] != v for c, v in before.items()):
            raise ValueError("previous contract changed")
        if after.keys() - before.keys() != expected:
            raise ValueError("unexpected equivalent set")
    return sorted(expected)


def audit(source, baseline, replacement_moves=()):
    root = GAME / ".godot/move_batch_catalog"
    old, before = catalog_clip_contracts(baseline, digest(baseline), root)
    index, after = catalog_clip_contracts(root / "index.json", digest(root / "index.json"), root)
    selected = changed_contracts(before, after, replacement_moves)
    prior = {r["move_id"]: r for r in old["moves"]}
    if old["canonical_hashes_unchanged"] != index["canonical_hashes_unchanged"]:
        raise ValueError("canonical contract changed")
    for p, sha in index["canonical_hashes_unchanged"].items():
        if digest(Path(p)) != sha:
            raise ValueError("canonical data changed")
    moves = read(GAME / "data/normalized/pokemon_api.json")["moves"]
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9
    names = {}
    for animation in load_gen9():
        if hasattr(animation, "attrs"):
            names.setdefault(animation.attrs.get("@name"), []).append(animation.attrs)
    rows, frame_count = [], 0
    graphics = source / "Gen9_Move_Animations/Graphics/Animations"
    for cid in selected:
        c = json.loads(after[cid])[0]
        label, reason, kind = CHOICES[c["move_id"]]
        previous_row = prior[c["move_id"]]
        if previous_row.get("primary_source_issue", previous_row.get("reason")) != reason:
            raise ValueError("native gap changed")
        meta = c["visual_equivalent"]
        side = c["actor_side"]
        expected_name = ("OppMove:" if side == "front" and names.get("OppMove:" + label) else "Move:") + label
        if c["name"] != expected_name or len(names[expected_name]) != 1:
            raise ValueError("wrong source/export side")
        a = names[expected_name][0]
        if fingerprint(a) != SOURCE_HASHES[expected_name] or meta["source_sha256"] != fingerprint(a):
            raise ValueError("unreviewed source")
        if (meta["primary_source_status"] != "quarantined" or meta["native_gap_fixed"] is not False
                or meta["mechanics_enabled"] is not False or meta["primary_source_issue"] != reason or meta["kind"] != kind):
            raise ValueError("misleading equivalent provenance")
        expected_frames = [list(f[:60]) for f in a["@array"]]
        if c["frames"] != expected_frames or c["fps"] != 20:
            raise ValueError("frames/timing changed")
        timing = copy.deepcopy(a.get("@timing", []))
        if c["move_id"] == "flower_trick":
            changed = [t for t in timing if t.get("@name") == "uwu.png" and t.get("@timingType") == 1]
            if len(changed) != 1:
                raise ValueError("flower background contract changed")
            changed[0]["@name"] = "PRAS- Petal BG.png"
            if meta["source_modifications"] != [{"field": "timing_background_name", "from": "uwu.png", "to": "PRAS- Petal BG.png"}]:
                raise ValueError("unreported background change")
        elif meta["source_modifications"]:
            raise ValueError("unexpected source modification")
        if c["layers"] != bake_layers(timing, len(c["frames"])):
            raise ValueError("layer timing changed")
        for name, key in c["layer_sheets"].items():
            path = graphics / name
            path = path if path.suffix else path.with_suffix(".png")
            if digest(path) + ".png" != key:
                raise ValueError("layer artwork changed")
        graphic = graphics / a["@graphic"]
        graphic = graphic if graphic.suffix else graphic.with_suffix(".png")
        if a.get("@hue", 0) != 0 or digest(graphic) + ".png" != c["sheet"]:
            raise ValueError("effect artwork/hue changed")
        native = side == "front" and expected_name.startswith("OppMove:")
        mapped = side == "front" and not native
        expected_sides = [side, side] if moves[c["move_id"]]["target"] == "user" else ["front", "back"] if mapped else ["back", "front"]
        if c["slot_sides"] != expected_sides or c["opponent_export"] != native or c["mapped_opponent"] != mapped:
            raise ValueError("wrong actor/target roles")
        if (c["classification_unchanged"] != moves[c["move_id"]]["classification"]
                or c["target_scope"] != moves[c["move_id"]]["target"]
                or c["title"] != moves[c["move_id"]]["display_name"]):
            raise ValueError("mechanics classification/target/title changed")
        rows.append({"id": cid, "source_name": expected_name, "frames": len(c["frames"]), "primary_source_issue": reason, "kind": kind})
        frame_count += len(c["frames"]) * 2
    if index["visual_equivalent_moves"] != 10 or len(index["primary_source_gaps_retained"]) != 10:
        raise ValueError("native gaps not retained in index")
    out = GAME / ".godot/move_equivalent_checks"
    out.mkdir(parents=True, exist_ok=True)
    report = {"version": 1, "index_sha256": digest(root / "index.json"), "baseline_sha256": digest(baseline),
        "runner_sha256": digest(Path(__file__)), "existing_identical_clips": len(before) - (len(selected) if replacement_moves else 0),
        "replacement_moves": list(replacement_moves), "replaced_clips": rows if replacement_moves else [],
        "new_clips": [] if replacement_moves else rows,
        "expected_frame_side_arena_states": frame_count, "native_gaps_fixed": 0, "battle_routes_added": 0}
    target = out / ("replacement_" + report["index_sha256"][:16] + ".json" if replacement_moves else "sources.json")
    write(target, report)
    print("MOVE_EQUIVALENT_SOURCES PASS existing=", report["existing_identical_clips"], "replaced=" if replacement_moves else "new=", len(rows), "frame/side/arena=", frame_count, "native_gaps_fixed=0", "output=", target)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--replace-moves", nargs="+", default=[], help="Exactly these existing pairs may change; all other contracts must match")
    args = parser.parse_args()
    audit(args.source_root.resolve(), args.baseline, args.replace_moves)
