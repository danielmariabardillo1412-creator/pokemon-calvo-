"""Pinned, optional laboratory context resources. No battle/domain data changes."""
import argparse
import collections
import hashlib
import json
import shutil
import sys
from pathlib import Path
from PIL import Image
from build_move_batch import Converter, dependencies
from build_move_contact_sheets import GAME, catalog_clip_contracts, digest, read, write
from move_layer_timing import bake_layers

COMMON = {
    "Common:Rain": "6f8d655aee7508dfd062ef570456932e1147b6201d2d13954e56ae4ae5f23bdb",
    "Common:Hail": "ffe9874a4531dbb05bdaa2c1196cb4f26d0c157864b451e5af1f9f31a71440e5",
    "Common:Snow": "a90db1c2ca664dc594465d155d2ec5b1cf86b05d0c74632d0a3672739c91e5f3",
}
DEFINITIONS = {
    "rain_dance": {"kind": "weather", "weather": 0, "label": "Muestra de lluvia común; persistencia y reglas pendientes"},
    "hail": {"kind": "weather", "weather": 1, "label": "Muestra de granizo común; sin daño ni reglas de clima"},
    "snowscape": {"kind": "weather", "weather": 2, "label": "Muestra de nieve del pack; comparte arte con granizo, no sus reglas"},
    "chilly_reception": {"kind": "withdrawal_snow", "weather": 2, "label": "Retirada nativa y muestra de nieve; sin cambio real de equipo"},
    "substitute": {"kind": "doll", "label": "Muñeco de muestra; sin coste de PS ni protección real"},
    "transform": {"kind": "appearance", "handoff_frame": 8, "label": "Apariencia del rival de muestra; no copia estadísticas, tipos ni movimientos"},
}
DOLL_SHA = "e4cb8b5708589c81ce97fb5c9be30dbf60477f5437c0c17554abbded3a8ed093"


def build(source):
    index_path = GAME / ".godot/move_batch_catalog/index.json"
    index, contracts = catalog_clip_contracts(index_path, digest(index_path), index_path.parent)
    protected = {p: digest(Path(p)) for p in index["canonical_hashes_unchanged"]}
    if protected != index["canonical_hashes_unchanged"]:
        raise ValueError("canonical data changed")
    sys.path.insert(0, str(source))
    from audit_pack_inventory import load_gen9
    names = collections.defaultdict(list)
    for animation in load_gen9():
        if hasattr(animation, "attrs"):
            names[animation.attrs.get("@name")].append(animation)
    converter = Converter(source / "Gen9_Move_Animations/Graphics/Animations", bake_layers)
    clips, proofs = [], []
    for number, (name, expected) in enumerate(COMMON.items()):
        if len(names[name]) != 1:
            raise ValueError("missing/ambiguous common animation")
        animation = names[name][0]
        fingerprint = hashlib.sha256(json.dumps(animation.attrs, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        if fingerprint != expected:
            raise ValueError("common source changed")
        move = {"display_name": name, "target": "entire-field", "classification": "DATA_ONLY"}
        clip = converter.convert("lab_weather_" + str(number), move, "back", animation)
        if len(clip["frames"]) != 30:
            raise ValueError("common cadence changed")
        clips.append(clip)
        proofs.append({"name": name, "source_sha256": fingerprint, "frames": 30})
    doll = converter.sheet("PRAS- Substitute.png")
    if doll != DOLL_SHA + ".png":
        raise ValueError("doll source changed")
    with Image.open(converter.sheets[doll]["source"]) as image:
        doll_bounds = {}
        for side, x in (("front", 0), ("back", 192)):
            box = image.convert("RGBA").getchannel("A").crop((x, 0, x + 192, 192)).getbbox()
            if box is None:
                raise ValueError("empty native doll view")
            doll_bounds[side] = [box[0], box[1], box[2] - box[0], box[3] - box[1]]
    bindings = {}
    for shard in index["shards"]:
        for entry in shard["entries"]:
            if entry["move_id"] not in DEFINITIONS:
                continue
            clip = json.loads(contracts[entry["id"]])[0]
            bindings[entry["id"]] = {"source_shard_sha256": shard["sha256"], "source_name": clip["name"],
                "source_frames": len(clip["frames"]), "classification_unchanged": clip["classification_unchanged"]}
    if set(bindings) != {m + "/" + s for m in DEFINITIONS for s in ("back", "front")}:
        raise ValueError("incomplete context binding set")
    renderer_sha = digest(GAME / "scenes/visual/community_move_preview.gd")
    # Renderer changes invalidate this binding too. Give the refreshed context
    # its own generation instead of overwriting evidence of the previous one.
    identity = [digest(index_path), renderer_sha, digest(Path(__file__)), proofs, bindings, doll]
    generation = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()[:16]
    output = GAME / ".godot/move_external_context" / generation
    output.mkdir(parents=True, exist_ok=True)
    sheets = {k: converter.sheets[k] for k in sorted(dependencies(clips) | {doll})}
    if sum(v["dimensions"][0] * v["dimensions"][1] for v in sheets.values()) > 32_000_000:
        raise ValueError("context pixel budget")
    for key, data in sheets.items():
        shutil.copyfile(data["source"], output / key)
        if digest(output / key) != data["sha256"]:
            raise ValueError("context art copy changed")
    pack_path = output / "weather.json"
    write(pack_path, {"version": 1, "selection": "automated_batch_v1", "scope": "LAB_ONLY_NOT_BATTLE_APPROVAL",
          "fps": 20, "clips": clips, "sheets": sheets, "license_review_required_before_distribution": True})
    manifest = {"version": 1, "scope": "LAB_ONLY_NOT_BATTLE_APPROVAL", "catalog_index_sha256": digest(index_path),
        "renderer_sha256": renderer_sha,
        "builder_sha256": digest(Path(__file__)), "extension_frames": 30, "definitions": DEFINITIONS,
        "bindings": bindings, "weather_path": "weather.json", "weather_sha256": digest(pack_path),
        "doll_sheet": doll, "doll_bounds": doll_bounds, "source_proofs": proofs,
        "snow_and_hail_share_source_art": clips[1]["frames"] == clips[2]["frames"] and clips[1]["sheet"] == clips[2]["sheet"],
        "mechanics_enabled": False, "battle_routes_added": 0, "license_review_required_before_distribution": True}
    path = output / "context.json"
    write(path, manifest)
    write(output.parent / "latest.json", {"path": generation + "/context.json", "sha256": digest(path)})
    if digest(index_path) != manifest["catalog_index_sha256"] or digest(GAME / "scenes/visual/community_move_preview.gd") != renderer_sha or any(digest(Path(p)) != sha for p, sha in protected.items()):
        raise ValueError("inputs changed while building")
    print("EXTERNAL_CONTEXT_RESOURCES PASS", path, "common=3 bindings=12 no mechanics; snow shares hail art=", manifest["snow_and_hail_share_source_art"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    build(parser.parse_args().source_root.resolve())
