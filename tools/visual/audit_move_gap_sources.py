"""Independent source-diff audit: allowed changes only, and real supplier pixels."""
import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image
from build_move_contact_sheets import catalog_clip_contracts, digest, read, write
from move_layer_timing import bake_layers

GAME = Path(__file__).resolve().parents[2]
EXPECTED = {"clangorous_soulblaze", "giga_impact", "lick", "luster_purge"}


def audit(source, baseline):
    root = GAME / ".godot/move_batch_catalog"
    old, before = catalog_clip_contracts(baseline, digest(baseline), root)
    index, after = catalog_clip_contracts(root / "index.json", digest(root / "index.json"), root)
    if not before.keys() <= after.keys() or any(v != after[c] for c, v in before.items()):
        raise ValueError("previous clip changed")
    new_ids = sorted(after.keys() - before.keys())
    if set(new_ids) != {move + "/" + side for move in EXPECTED for side in ("back", "front")}:
        raise ValueError("unexpected recovered set")
    if old["canonical_hashes_unchanged"] != index["canonical_hashes_unchanged"]:
        raise ValueError("canonical contract changed")
    for path, sha in index["canonical_hashes_unchanged"].items():
        if digest(Path(path)) != sha:
            raise ValueError("canonical source changed")
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9
    names = {a.attrs.get("@name"): a.attrs for a in load_gen9() if hasattr(a, "attrs")}
    rows, supplier_pixels, priorities = [], 0, 0
    for clip_id in new_ids:
        clip = json.loads(after[clip_id])[0]
        original = names[clip["name"]]
        expected = copy.deepcopy([list(f[:60]) for f in original["@array"]])
        priority_cells = []
        if clip["move_id"] == "clangorous_soulblaze":
            # Collect before assignment: Marshal can share cells across frames.
            priority_cells = [[f, slot] for f, frame in enumerate(expected) for slot, c in enumerate(frame) if c is not None and c[25] == 4]
            for f, slot in priority_cells:
                expected[f][slot][25] = 1
            if len(priority_cells) != clip["priority_repair"]["changed_priority_cells"]:
                raise ValueError("priority repair counter mismatch")
            fingerprint = hashlib.sha256(json.dumps(original["@array"], separators=(",", ":")).encode()).hexdigest()
            if fingerprint != clip["priority_repair"]["source_frames_sha256"]:
                raise ValueError("priority source fingerprint mismatch")
        if clip["frames"] != expected or clip["fps"] != 20:
            raise ValueError("unexpected cells/cadence change")
        layers = bake_layers(original.get("@timing", []), len(expected))
        omissions = clip.get("invisible_missing_layers", [])
        for omitted in omissions:
            states = [v for f in layers for v in f.values() if v["name"] == omitted["name"]]
            if not states or len(states) != omitted["uses"] or any(v["opacity"] != 0 for v in states):
                raise ValueError("not completely invisible")
            for v in states:
                v["name"] = ""
        if clip["layers"] != layers:
            raise ValueError("unexpected layer change")
        for name, meta in clip.get("supplemental_layer_sources", {}).items():
            original_png = GAME / ".godot/move_gap_sources" / (meta["source_sha256"] + ".png")
            normalized = GAME / ".godot/move_gap_sources" / (meta["derived_sha256"] + ".png")
            if digest(original_png) != meta["source_sha256"] or digest(normalized) != meta["derived_sha256"]:
                raise ValueError("supplier checksum mismatch")
            with Image.open(original_png) as a, Image.open(normalized) as b:
                a, b = a.convert("RGBA"), b.convert("RGBA")
                scale = meta["scale"]
                if b.size != (a.width * scale, a.height * scale) or b.size != (512, 384):
                    raise ValueError("supplier canvas mismatch")
                # Independent integer-pixel oracle, not resize() used in importer.
                for y in range(b.height):
                    for x in range(b.width):
                        if b.getpixel((x, y)) != a.getpixel((x // scale, y // scale)):
                            raise ValueError("supplier pixel mismatch")
                supplier_pixels += b.width * b.height
        priorities += len(priority_cells)
        rows.append({"id": clip_id, "priority_cells": priority_cells, "omitted_layers": omissions,
                     "frame_count": len(expected), "source_name": clip["name"]})
    report = {"version": 1, "index_sha256": digest(root / "index.json"), "baseline_sha256": digest(baseline),
        "runner_sha256": digest(Path(__file__)), "existing_identical_clips": len(before), "new_clip_ids": new_ids,
        "supplier_pixels_checked": supplier_pixels, "priority_fields_checked": priorities, "rows": rows,
        "scope": "Allowed exact source differences only; no art/motion/mechanics approval"}
    out = GAME / ".godot/move_gap_checks"
    out.mkdir(parents=True, exist_ok=True)
    write(out / "sources.json", report)
    print("MOVE_GAP_SOURCES PASS existing=", len(before), "new=", len(new_ids), "supplier_pixels=", supplier_pixels, "priority_fields=", priorities)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    args = parser.parse_args()
    audit(args.source_root.resolve(), args.baseline)
