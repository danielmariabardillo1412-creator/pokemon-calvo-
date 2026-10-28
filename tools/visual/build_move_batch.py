"""Offline, inert-data batch conversion. Quarantine bad pairs, never change mechanics.

Reads the previously downloaded research cache; executes no Ruby and fetches nothing.
Outputs disposable, bounded laboratory shards, not battle approval or final assets.
"""
import argparse
import collections
import copy
import hashlib
import io
import json
import math
import re
import shutil
import sys
from pathlib import Path
from PIL import Image
from move_layer_timing import bake_layers
from move_sheet_hue import normalize_hue, rotate_sheet
from move_gap_repairs import load_gap_sheet, normalize_priority, omit_invisible_missing_layers
from move_visual_equivalents import select_equivalent
from move_art_choices import ART_CHOICES, select_art_choice

GAME = Path(__file__).resolve().parents[2]
LIMIT_CLIPS = 64
LIMIT_PIXELS = 32_000_000
ARCHIVE_HASH = "931691c2e0b4b7817aa891aaa6653febdd7c7d0870dc657dad331f16752af24b"
# Audited source defects exposed by a camera different from the canonical one.
# Pin the entire exported frame array; never guess focus from coordinates globally.
NATIVE_FOCUS_REPAIRS = {
    "OppMove:HYPERDRILL": "0dde2bbd1ac78616f8799bb48d539e6a2e4e8190989552c7adb3a802965b45e8",
    "OppMove:ROLLINGKICK": "2edcbc47f37b75b1bb018278584db01a715ddf1e678cdb7e109fc593c1ac7131",
    "OppMove:UPPERHAND": "0c8cd3ff06b3244d05efb86857d8f9456e80d9b10e21bbfae0a56eff4d62df64",
    "OppMove:CHILLYRECEPTION": "47ca1e982613b1aad620ea0ebe847d9c68a7ac894eff0e4b4626de598bd8cd2d",
    "OppMove:MALIGNANTCHAIN": "bd11b9dc2bb6d99383f3dd304e92296d7aafb0b312fed8eea2e62d6a159299c0",
}
NATIVE_FOCUS_RULES = {
    # These are rigid actor-attached objects, NOT affine projectiles. Preserve
    # chain tile spacing and leave the cold-joke ice on its original rear slot.
    "OppMove:CHILLYRECEPTION": {"source": 2, "destination": 1, "patterns": [2]},
    "OppMove:MALIGNANTCHAIN": {"source": 1, "destination": 2},
}
NATIVE_GEOMETRY_REPAIRS = {
    "Move:MOONGEISTBEAM": "1a9648e5701dbfbf380ba50e99eca45c71362a274180093b94b9e05fe36a671d",
    "OppMove:MOONGEISTBEAM": "c837857dab8bd1a80464a879925e42d2fe80d41bb279a309027ced9ce2b71c62",
    # Independently reproduced: all Oblivion Wing particles use source-line
    # focus, and the uniform particle basis loses target coverage in our camera.
    # Preserve its separate flight choreography, hue and complete source array.
    "Move:OBLIVIONWING": "e9cd57608d129b10080b6376fee93f91f7de76e32e91ccf741bcdf14f8f748ab",
    "OppMove:OBLIVIONWING": "c22a3f81cb5bb7c7e92c229c6534e7cdbfc41f76ffa46aa31edb3c1a791c61bf",
}


def native_particle_geometry(animation, frames):
    name = animation.get("@name")
    if name not in NATIVE_GEOMETRY_REPAIRS:
        return None
    fingerprint = hashlib.sha256(json.dumps(animation["@array"], separators=(",", ":")).encode()).hexdigest()
    require(fingerprint == NATIVE_GEOMETRY_REPAIRS[name], "geometry_repair_source_changed")
    particles = [c for frame in frames for c in frame if c is not None and c[7] >= 0]
    require(particles and all(c[26] == 3 for c in particles), "geometry_repair_requires_source_line")
    return {"policy": "pinned_canonical_affine_particle_basis_v1", "source_frames_sha256": fingerprint,
            "patterns": sorted({int(c[7]) for c in particles})}


def native_particle_focus(animation, side, frames):
    name = animation.get("@name")
    if side != "front" or name not in NATIVE_FOCUS_REPAIRS:
        return None
    fingerprint = hashlib.sha256(json.dumps(animation["@array"], separators=(",", ":")).encode()).hexdigest()
    require(fingerprint == NATIVE_FOCUS_REPAIRS[name], "camera_repair_source_changed")
    rule = NATIVE_FOCUS_RULES.get(name, {"source": 1, "destination": 3})
    original_focus, adapted_focus = rule["source"], rule["destination"]
    # Count frame/slot fields before mutating: inert Marshal data may share a cel
    # object across frames, and deepcopy preserves those aliases.
    targets = [cel for frame in frames for cel in frame
               if cel is not None and cel[7] >= 0 and cel[26] == original_focus
               and ("patterns" not in rule or cel[7] in rule["patterns"])]
    changed = len(targets)
    for cel in targets:
        cel[26] = adapted_focus
    require(changed > 0, "camera_repair_has_no_cells")
    policy = "pinned_native_particle_canonical_line_v1" if adapted_focus == 3 else "pinned_native_particle_slot_anchor_v1"
    return {"policy": policy, "source_frames_sha256": fingerprint,
            "changed_focus_cells": changed, "original_focus": original_focus, "adapted_focus": adapted_focus}


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    temporary.replace(path)


class Converter:
    def __init__(self, graphics, bake_layers, derived_root=None, gap_sources=None):
        self.graphics, self.bake_layers = graphics, bake_layers
        self.derived_root = derived_root
        self.hue_sheets = {}
        self.sheets = {}
        self.pattern_alpha = {}
        self.gap_sources = gap_sources
        self.gap_provenance = {}

    def sheet(self, name, hue=0):
        degrees = normalize_hue(hue)
        require(isinstance(name, str) and name and Path(name).name == name and ".." not in name, "unsafe_sheet")
        path = self.graphics / name
        if not path.suffix:
            path = path.with_suffix(".png")
        provenance = None
        if not path.is_file():
            path, provenance = load_gap_sheet(path.name, self.gap_sources)
        if degrees:
            original = self.sheet(name)
            identity = (original, degrees)
            if identity not in self.hue_sheets:
                require(self.derived_root is not None, "missing_derived_sheet_directory")
                require(self.derived_root.resolve() != self.graphics.resolve(), "unsafe_derived_sheet_directory")
                self.derived_root.mkdir(parents=True, exist_ok=True)
                with Image.open(path) as image:
                    derived = rotate_sheet(image, degrees)
                buffer = io.BytesIO()
                derived.save(buffer, format="PNG")
                data = buffer.getvalue()
                target = self.derived_root / (hashlib.sha256(data).hexdigest() + ".png")
                if not target.exists() or digest(target) != target.stem:
                    temporary = target.with_suffix(".tmp")
                    temporary.write_bytes(data)
                    temporary.replace(target)
                self.hue_sheets[identity] = target
            path = self.hue_sheets[identity]
        key = digest(path) + ".png"
        if key not in self.pattern_alpha:
            with Image.open(path) as image:
                image.verify()
            with Image.open(path) as image:
                w, h = image.size
                require(0 < w <= 8192 and 0 < h <= 8192 and w * h <= LIMIT_PIXELS, "sheet_pixel_budget")
                alpha = image.convert("RGBA").getchannel("A")
                self.pattern_alpha[key] = {
                    y // 192 * 5 + x // 192: alpha.crop((x, y, min(x + 192, w), min(y + 192, h))).getbbox() is not None
                    for y in range(0, h, 192) for x in range(0, min(w, 960), 192)}
            self.sheets[key] = {"dimensions": [w, h], "sha256": key[:-4], "source": str(path), "bytes": path.stat().st_size}
        if provenance:
            self.gap_provenance[key] = provenance
        return key

    def convert(self, move_id, move, side, animation):
        a = animation.attrs
        hue = normalize_hue(a.get("@hue", 0))
        require(a.get("@speed", 20) in (None, 20), "unsupported_speed")
        original = a.get("@array", [])
        require(2 <= len(original) <= 200, "single_frame_or_length_limit")
        require(all(all(c is None for c in f[60:]) for f in original), "active_cells_beyond_60")
        frames = copy.deepcopy([list(f[:60]) for f in original])
        priority_repair = normalize_priority(a, frames)
        key = self.sheet(a["@graphic"], hue) if a.get("@graphic") else ""
        dimensions = self.sheets[key]["dimensions"] if key else [0, 0]
        clipped, opaque_patterns = [], set()
        for index, frame in enumerate(frames):
            for slot, cel in enumerate(frame):
                if cel is None:
                    continue
                require(len(cel) == 27, "cell_schema")
                require(all(isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)
                            for field, x in enumerate(cel) if field not in (9, 10)), "non_finite_cell")
                require(cel[5] in (0, 1, 2) and cel[26] in (1, 2, 3, 4) and cel[25] in (0, 1, 2, 3), "unsupported_cell_mode")
                require(cel[7] >= -2 and cel[7] == int(cel[7]), "invalid_pattern")
                require(not any(cel[21:25]), "unsupported_cell_flash")
                pattern = int(cel[7])
                if pattern >= 0:
                    x, y = pattern % 5 * 192, pattern // 5 * 192
                    require(x < dimensions[0] and y < dimensions[1], "missing_pattern:" + str(pattern))
                    if x + 192 > dimensions[0] or y + 192 > dimensions[1]:
                        clipped.append({"frame": index, "slot": slot, "pattern": pattern})
                    if self.pattern_alpha[key].get(pattern) and cel[6] == 1 and cel[8] > 0 and cel[2] != 0 and cel[11] != 0:
                        opaque_patterns.add(pattern)
        timings = a.get("@timing", [])
        require(all(t.get("@flashScope", 0) == 0 for t in timings), "unsupported_timing_flash")
        layers = self.bake_layers(timings, len(frames))
        invisible_layers = omit_invisible_missing_layers(layers, self.graphics)
        layer_sheets = {layer["name"]: self.sheet(layer["name"]) for frame in layers for layer in frame.values() if layer["name"]}
        native = side == "front" and a["@name"].startswith("OppMove:")
        mapped = side == "front" and not native
        sides = [side, side] if move["target"] == "user" else ["front", "back"] if mapped else ["back", "front"]
        flags = []
        if clipped:
            flags.append("partial_edge_patterns")
        if not opaque_patterns:
            flags.append("no_opaque_particles_body_or_layers_only")
        if len({json.dumps([f, layer], sort_keys=True) for f, layer in zip(frames, layers)}) == 1:
            flags.append("static_source")
        if mapped:
            flags.append("mapped_opponent_not_native")
        if move["classification"] != "RUNTIME_SUPPORTED":
            flags.append("mechanics_not_fully_supported")
        camera_repair = native_particle_focus(a, side, frames)
        if camera_repair:
            flags.append("audited_native_particle_camera_repair")
        geometry_repair = native_particle_geometry(a, frames)
        if geometry_repair:
            require(not mapped, "geometry_repair_requires_native_export")
            flags.append("audited_native_particle_geometry")
        if priority_repair:
            flags.append("audited_native_priority_fallback")
        if invisible_layers:
            flags.append("proven_invisible_missing_layer_omitted")
        result = {"id": move_id + "/" + side, "move_id": move_id, "title": move["display_name"],
                "actor_side": side, "slot_sides": sides, "opponent_export": native, "mapped_opponent": mapped,
                "target_scope": move["target"], "classification_unchanged": move["classification"],
                "reference_animation_id": a["@name"].removeprefix("OppMove:").removeprefix("Move:"),
                "name": a["@name"], "fps": 20, "sheet": key, "frames": frames, "layers": layers,
                "layer_sheets": layer_sheets, "uniform_screen_patterns": [0] if "SHATTEREDPSYCHE" in a["@name"] else [],
                "clipped_cells": clipped, "audit_flags": flags,
                "audio_events_omitted": sum(t.get("@timingType", 0) == 0 for t in timings)}
        if camera_repair:
            result["camera_repair"] = camera_repair
        if geometry_repair:
            result["particle_geometry"] = geometry_repair
            result["affine_particle_patterns"] = geometry_repair["patterns"]
        if hue and key:
            result["sheet_hue"] = {"policy": "offline_hsv_integer_degrees_v1", "degrees": hue,
                "source_sha256": self.sheet(a["@graphic"])[:-4], "derived_sha256": key[:-4]}
        if priority_repair:
            result["priority_repair"] = priority_repair
        if invisible_layers:
            result["invisible_missing_layers"] = invisible_layers
        supplied = {name: self.gap_provenance[k] for name, k in layer_sheets.items() if k in self.gap_provenance}
        if supplied:
            result["supplemental_layer_sources"] = supplied
            flags.append("pinned_supplemental_layer_sheet")
        return result


def dependencies(clips):
    return {key for clip in clips for key in [clip["sheet"], *clip["layer_sheets"].values()] if key}


def build(args):
    source = args.source_root.resolve()
    require(digest(source / "Gen9_Move_Animations.zip") == ARCHIVE_HASH, "source_archive_hash_changed")
    # Local audited reader/helpers only; no package code from the archives is imported.
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9, canonical
    moves_path = GAME / "data/normalized/pokemon_api.json"
    raw_path = GAME / "data/raw/pokemon_api.json"
    protected = {str(p): digest(p) for p in (moves_path, raw_path)}
    moves = json.loads(moves_path.read_text(encoding="utf-8-sig"))["moves"]
    names = collections.defaultdict(list)
    for animation in load_gen9():
        if hasattr(animation, "attrs"):
            names[animation.attrs.get("@name", "")].append(animation)
    converter = Converter(source / "Gen9_Move_Animations/Graphics/Animations", bake_layers,
                          args.output.resolve() / "hue_sheets", GAME / ".godot/move_gap_sources")
    seed_path = args.priority_pack.resolve()
    seed = json.loads(seed_path.read_text(encoding="utf-8"))
    require(seed.get("selection") == "priority_visual_set" and len(seed["clips"]) == 70, "priority_pack_contract")
    priority = collections.defaultdict(list)
    for clip in seed["clips"]:
        require(clip["classification_unchanged"] == moves[clip["move_id"]]["classification"], "stale_priority_classification")
        priority[clip["move_id"]].append(clip)
    pairs, rows = [], []
    for move_id, move in sorted(moves.items()):
        row = {"move_id": move_id, "classification": move["classification"], "battle_enabled_by_batch": False}
        try:
            if move_id in ART_CHOICES:
                # A reviewed ART rejection is not a failed native conversion.
                # Keep the old priority pilot/battle packs immutable; only the
                # current batch catalogue selects this explicitly labelled pair.
                references = select_art_choice(move_id, names)
                pair = []
                for side, animation, metadata in references:
                    clip = converter.convert(move_id, move, side, animation)
                    clip["visual_art_choice"] = metadata
                    clip["audit_flags"].append("explicit_reviewed_art_equivalent")
                    pair.append(clip)
                selected = [pair]
                row.update(mapping="reviewed_art_equivalent", art_choice_reason=references[0][2]["reason"])
            elif move_id in priority:
                grouped = collections.defaultdict(list)
                for original in priority[move_id]:
                    clip = copy.deepcopy(original)
                    clip["audit_flags"] = ["previously_reviewed_priority_reference"]
                    grouped[clip["id"].rsplit("/", 1)[0]].append(clip)
                    for key in dependencies([clip]):
                        data = seed["sheets"][key]
                        path = seed_path.parent / key
                        require(digest(path) == data["sha256"], "priority_sheet_hash_changed")
                        converter.sheets[key] = {**data, "source": str(path)}
                selected = list(grouped.values())
                row["mapping"] = "existing_priority_references"
            else:
                name = canonical(move_id)
                mapping = "exact_label"
                if not names.get("Move:" + name):
                    alias = re.sub(r"_(physical|special)$", "", move_id)
                    alias = "vise_grip" if alias == "vice_grip" else alias
                    if alias != move_id and names.get("Move:" + canonical(alias)):
                        name, mapping = canonical(alias), "explicit_spelling_or_z_category_alias"
                require(len(names.get("Move:" + name, [])) == 1, "missing_or_ambiguous_label")
                require(len(names.get("OppMove:" + name, [])) <= 1, "ambiguous_opponent_label")
                back = names["Move:" + name][0]
                front = names["OppMove:" + name][0] if names.get("OppMove:" + name) else back
                try:
                    selected = [[converter.convert(move_id, move, side, animation) for side, animation in (("back", back), ("front", front))]]
                    row["mapping"] = mapping
                except ValueError as primary_error:
                    references = select_equivalent(move_id, names, str(primary_error))
                    pair = []
                    for side, animation, metadata in references:
                        clip = converter.convert(move_id, move, side, animation)
                        clip["visual_equivalent"] = metadata
                        clip["audit_flags"].append("explicit_visual_equivalent_native_gap_retained")
                        pair.append(clip)
                    selected = [pair]
                    row.update(mapping="explicit_visual_equivalent", primary_source_issue=str(primary_error),
                               native_gap_fixed=False, equivalent_kind=references[0][2]["kind"])
            for pair in selected:
                require(len(pair) == 2 and {c["actor_side"] for c in pair} == {"back", "front"}, "incomplete_pair")
                pairs.append(pair)
            row.update(status="converted_lab_only", clip_ids=[c["id"] for pair in selected for c in pair],
                       flags=sorted({flag for pair in selected for c in pair for flag in c["audit_flags"]}))
        except (ValueError, KeyError, TypeError, IndexError, OSError) as error:
            row.update(status="quarantined", reason=str(error))
        rows.append(row)
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    helper_hashes = {name: digest(source / name) for name in ("audit_pack_inventory.py", "build_resource_pilot.py")}
    helper_hashes["local_move_layer_timing.py"] = digest(Path(__file__).with_name("move_layer_timing.py"))
    helper_hashes["local_move_sheet_hue.py"] = digest(Path(__file__).with_name("move_sheet_hue.py"))
    helper_hashes["local_move_gap_repairs.py"] = digest(Path(__file__).with_name("move_gap_repairs.py"))
    helper_hashes["local_move_visual_equivalents.py"] = digest(Path(__file__).with_name("move_visual_equivalents.py"))
    helper_hashes["local_move_art_choices.py"] = digest(Path(__file__).with_name("move_art_choices.py"))
    source_data_hash = digest(source / "Gen9_Move_Animations/Data/PkmnAnimations.rxdata")
    # Content-address the generation, not just its directory names. A previous
    # index remains usable while a rebuild is in progress; publish index last.
    generation_inputs = [digest(Path(__file__)), digest(seed_path), protected[str(moves_path)], helper_hashes, source_data_hash, pairs]
    generation = "generation_" + hashlib.sha256(json.dumps(generation_inputs, sort_keys=True).encode()).hexdigest()[:16]
    generation_root = out / generation
    generation_root.mkdir(exist_ok=True)
    shards, pending = [], []

    def publish(clips):
        if not clips:
            return
        directory = generation_root / ("shard_%03d" % len(shards))
        directory.mkdir(exist_ok=True)
        keys = dependencies(clips)
        sheets = {key: converter.sheets[key] for key in sorted(keys)}
        require(sum(v["dimensions"][0] * v["dimensions"][1] for v in sheets.values()) <= LIMIT_PIXELS, "shard_pixel_budget")
        for key, data in sheets.items():
            path = directory / key
            if not path.exists() or digest(path) != data["sha256"]:
                shutil.copyfile(data["source"], path)
            require(digest(path) == data["sha256"], "copy_hash")
        manifest = {"version": 1, "selection": "automated_batch_v1", "scope": "LAB_ONLY_NOT_BATTLE_APPROVAL",
                    "fps": 20, "sheets": sheets, "clips": clips, "license_review_required_before_distribution": True}
        write_json(directory / "manifest.json", manifest)
        shards.append({"path": generation + "/" + directory.name + "/manifest.json", "sha256": digest(directory / "manifest.json"), "clips": len(clips),
                       "entries": [{"id": c["id"], "title": c["title"], "move_id": c["move_id"], "actor_side": c["actor_side"]} for c in clips]})

    for pair in pairs:
        keys = dependencies(pending + pair)
        pixels = sum(converter.sheets[k]["dimensions"][0] * converter.sheets[k]["dimensions"][1] for k in keys)
        if pending and (len(pending) + len(pair) > LIMIT_CLIPS or pixels > LIMIT_PIXELS):
            publish(pending)
            pending = []
        pending.extend(pair)
    publish(pending)
    require(all(digest(Path(p)) == value for p, value in protected.items()), "canonical_data_changed")
    counts = dict(collections.Counter(r["status"] for r in rows))
    report = {"version": 1, "scope": "Conversion/static checks only; GPU/geometry audit separate; no mechanics or battle routes enabled",
              "counts": counts, "catalog_moves": len(moves), "converted_clips": sum(s["clips"] for s in shards),
              "source_archive_sha256": ARCHIVE_HASH, "priority_manifest_sha256": digest(seed_path),
              "visual_equivalent_moves": sum(r.get("mapping") == "explicit_visual_equivalent" and r["status"] == "converted_lab_only" for r in rows),
              "art_equivalent_moves": sum(r.get("mapping") == "reviewed_art_equivalent" and r["status"] == "converted_lab_only" for r in rows),
              "primary_source_gaps_retained": [{"move_id": r["move_id"], "reason": r["primary_source_issue"]} for r in rows if r.get("primary_source_issue")],
              "builder_sha256": digest(Path(__file__)),
              "helper_sha256": helper_hashes, "extracted_animation_data_sha256": source_data_hash,
              "canonical_hashes_unchanged": protected, "shards": shards, "moves": rows,
              "quarantine_reasons": dict(collections.Counter(r["reason"].split(":")[0] for r in rows if r["status"] == "quarantined")),
              "credits": seed["credits"], "license_review_required_before_distribution": True}
    write_json(out / "index.json", report)
    print(json.dumps({key: report[key] for key in ("counts", "catalog_moves", "converted_clips", "quarantine_reasons")}, ensure_ascii=False))
    print("Shards:", len(shards), "Index:", out / "index.json", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--priority-pack", type=Path, default=GAME / ".godot/move_resource_pilot/manifest.json")
    parser.add_argument("--output", type=Path, default=GAME / ".godot/move_batch_catalog")
    build(parser.parse_args())
