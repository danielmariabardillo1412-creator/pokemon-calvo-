"""Pin hue provenance/alpha and unchanged baseline; prepare independent Godot oracle."""
import argparse
import json
import sys
from pathlib import Path
from PIL import Image
from build_move_contact_sheets import catalog_clip_contracts, digest, read, write

GAME = Path(__file__).resolve().parents[2]


def audit(source, baseline, output):
    root = GAME / ".godot/move_batch_catalog"
    old, before = catalog_clip_contracts(baseline, digest(baseline), root)
    index, after = catalog_clip_contracts(root / "index.json", digest(root / "index.json"), root)
    if not before.keys() <= after.keys() or any(value != after[key] for key, value in before.items()):
        raise ValueError("existing clip contract changed")
    if old["canonical_hashes_unchanged"] != index["canonical_hashes_unchanged"]:
        raise ValueError("canonical contract changed")
    for path, sha in index["canonical_hashes_unchanged"].items():
        if digest(Path(path)) != sha:
            raise ValueError("canonical source changed")
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9
    names = {}
    for a in load_gen9():
        if hasattr(a, "attrs"):
            names.setdefault(a.attrs.get("@name"), []).append(a.attrs)
    rows = {}
    new_ids = sorted(after.keys() - before.keys())
    zero_ids = []
    quarantine = {r["move_id"]: r.get("reason") for r in old["moves"]}
    for clip_id in new_ids:
        clip = json.loads(after[clip_id])[0]
        if quarantine.get(clip["move_id"]) != "unsupported_hue":
            raise ValueError("new clip unrelated to hue quarantine")
        matches = names[clip["name"]]
        if len(matches) != 1:
            raise ValueError("ambiguous hue source")
        original = matches[0]
        path = source / "Gen9_Move_Animations/Graphics/Animations" / original["@graphic"]
        if not path.suffix:
            path = path.with_suffix(".png")
        if clip["frames"] != [list(f[:60]) for f in original["@array"]]:
            raise ValueError("hue conversion changed cells")
        if original.get("@hue", 0) == 0:
            if "sheet_hue" in clip or clip["sheet"] != digest(path) + ".png":
                raise ValueError("zero hue export changed")
            zero_ids.append(clip_id)
            continue
        hue = clip["sheet_hue"]
        if digest(path) != hue["source_sha256"] or original["@hue"] % 360 != hue["degrees"]:
            raise ValueError("hue provenance mismatch")
        derived = root / "hue_sheets" / clip["sheet"]
        if digest(derived) != hue["derived_sha256"]:
            raise ValueError("hue derived sheet mismatch")
        with Image.open(path) as a, Image.open(derived) as b:
            if a.size != b.size or a.convert("RGBA").getchannel("A").tobytes() != b.getchannel("A").tobytes():
                raise ValueError("hue dimensions/alpha changed")
            identity = (str(path), str(derived), hue["degrees"])
            if identity not in rows:
                rows[identity] = {"original": str(path), "derived": str(derived), **hue,
                                  "pixels": a.width * a.height, "clip_ids": []}
            rows[identity]["clip_ids"].append(clip_id)
    report = {"version": 1, "index_sha256": digest(root / "index.json"), "baseline_sha256": digest(baseline),
        "builder_sha256": digest(Path(__file__)), "existing_identical_clips": len(before), "new_clip_ids": new_ids,
        "zero_hue_clip_ids_unchanged": zero_ids,
        "all_alpha_pixels_checked": sum(r["pixels"] for r in rows.values()), "rows": list(rows.values()),
        "scope": "Source cells/hash/alpha/dimensions only; RGB oracle separate, no art/motion/mechanics approval"}
    output.parent.mkdir(parents=True, exist_ok=True)
    write(output, report)
    print("MOVE_HUE_SOURCES PASS", len(new_ids), "new clips;", len(rows), "sheet/hue pairs;",
          report["all_alpha_pixels_checked"], "alpha pixels;", len(before), "unchanged existing clips")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=GAME / ".godot/move_hue_checks/sources.json")
    args = parser.parse_args()
    audit(args.source_root.resolve(), args.baseline, args.output)
