"""Import the size table for the very render family used by the local pack.

Fetches small public metadata files, never executes downloaded JavaScript, never
downloads images or rewrites Pokemon data. The imported scale cancels the old
height-based normalization so the authored relative sizes are retained. Custom
3D candidates are explicitly separate, not falsely certified as Showdown sprites.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
from statistics import median
import urllib.request
from PIL import Image

META_URL = "https://play.pokemonshowdown.com/data/pokedex-mini.js"
DEX_URL = "https://raw.githubusercontent.com/smogon/pokemon-showdown-client/master/play.pokemonshowdown.com/src/battle-dex.ts"
SCENE_URL = "https://raw.githubusercontent.com/smogon/pokemon-showdown-client/master/play.pokemonshowdown.com/src/battle-animations.ts"
CSS_URL = "https://play.pokemonshowdown.com/style/battle.css"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def parse_metadata(text):
    result = {}
    for line in text.splitlines():
        found = re.fullmatch(r"\s*([a-z0-9]+):(\{.*\}),?\s*", line)
        if not found:
            continue
        # Accept data literals only. No eval, JS engine, imports or source execution.
        quoted = re.sub(r"([,{])\s*([A-Za-z][A-Za-z0-9]*):",
                        lambda m: m[1] + json.dumps(m[2]) + ":", found[2])
        result[found[1]] = json.loads(quoted)
    if len(result) < 1000:
        raise ValueError("Unexpected/incomplete Showdown metadata")
    return result


def local_medians(pack, view):
    with Image.open(pack / view["atlas"]) as image:
        alpha = image.getchannel("A")
        boxes = [alpha.crop((x, y, x + w, y + h)).getbbox() for x, y, w, h in view["regions"]]
    if any(b is None for b in boxes):
        raise ValueError("Empty local animation frame")
    return [median(b[2] - b[0] for b in boxes), median(b[3] - b[1] for b in boxes)]


def reference_medians(path, dimensions):
    boxes = []
    with Image.open(path) as image:
        if list(image.size) != dimensions:
            raise ValueError(f"Reference GIF dimensions do not match table: {path}")
        for index in range(image.n_frames):
            image.seek(index)
            boxes.append(image.convert("RGBA").getchannel("A").getbbox())
    if any(b is None for b in boxes):
        raise ValueError(f"Empty reference frame: {path}")
    return [median(b[2] - b[0] for b in boxes), median(b[3] - b[1] for b in boxes)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference-directory", required=True, type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    args.reference_directory.mkdir(parents=True, exist_ok=True)
    sources = []
    for name, url in [("pokedex-mini.js", META_URL), ("battle-dex.ts", DEX_URL), ("battle-animations.ts", SCENE_URL), ("battle.css", CSS_URL)]:
        destination = args.reference_directory / name
        if not destination.exists():
            with urllib.request.urlopen(url, timeout=30) as response:
                payload = response.read(1_500_001)
            if len(payload) > 1_500_000:
                raise ValueError("Unexpectedly large reference file")
            destination.write_bytes(payload)
        sources.append({"url": url, "local_file": str(destination), "sha256": sha(destination),
                        "bytes": destination.stat().st_size})
    metadata = parse_metadata((args.reference_directory / "pokedex-mini.js").read_text(encoding="utf-8"))
    scene_text = (args.reference_directory / "battle-animations.ts").read_text(encoding="utf-8")
    dex_text = (args.reference_directory / "battle-dex.ts").read_text(encoding="utf-8")
    # Fail if the documented reference policy changes upstream.
    if "spriteData.w = animationData[facing].w" not in dex_text or "spriteData.h = animationData[facing].h" not in dex_text:
        raise ValueError("Showdown dimension policy changed")
    if "1.5 - 0.5 * ((loc.z!) / 200)" not in scene_text:
        raise ValueError("Showdown modern-sprite perspective policy changed")
    game = Path(__file__).resolve().parents[2]
    pack = game / "assets/local_battle_catalog"
    manifest_path = pack / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    dimensions_match, missing, mismatches, adapted = [], [], [], []
    output, candidate_keys = {}, []
    compensation = []
    for key, row in manifest["species"].items():
        if row["source_family"] != "showdown_rendered":
            candidate_keys.append(key)
            continue
        identity = re.sub("[^a-z0-9]", "", key)
        entry = metadata.get(identity, {})
        if entry and entry.get("num") != row["pokeapi_pokemon_id"]:
            raise ValueError(f"Species ID mismatch for {key}: {entry.get('num')} / {row['pokeapi_pokemon_id']}")
        views = {}
        for side, view in row["states"]["reposo"].items():
            table = entry.get(side)
            local_dimensions = view["regions"][0][2:]
            match = bool(table and local_dimensions == [table["w"], table["h"]])
            if not table:
                missing.append([key, side, identity])
            elif not match:
                mismatches.append([key, side, local_dimensions, [table["w"], table["h"]]])
            else:
                dimensions_match.append([key, side])
            factor = 1.0 / view["unit_scale"]
            if match:
                compensation.append(factor)
            details = {}
            adapted_view = False
            if table and not match:
                filename = key.replace("_", "-") + "_" + side + ".gif"
                reference_path = args.reference_directory / "mismatched_gif_references" / filename
                if reference_path.exists():
                    local_box = local_medians(pack, view)
                    reference_box = reference_medians(reference_path, [table["w"], table["h"]])
                    silhouette_gain = min(reference_box[0] / local_box[0], reference_box[1] / local_box[1])
                    factor *= silhouette_gain
                    adapted_view = True
                    details = {"reference_gif_sha256": sha(reference_path),
                               "reference_gif_url": "https://play.pokemonshowdown.com/sprites/" + ("ani-back/" if side == "back" else "ani/") + key.replace("_", "-") + ".gif",
                               "local_median_opaque_size": local_box, "reference_median_opaque_size": reference_box,
                               "silhouette_gain": silhouette_gain,
                               "pose_revision_art_review_pending": True}
                    adapted.append([key, side])
            views[side] = {"factor": factor,
                           "status": "reference_dimensions_match" if match else ("reference_silhouette_adapted" if adapted_view else "local_native_dimensions_only"),
                           "reference_id": identity, "local_dimensions": local_dimensions,
                           "reference_dimensions": [table["w"], table["h"]] if table else None,
                           **details}
        output[key] = views
    # Single cross-family unit conversion for all custom candidates, shared across
    # front/back and every state. It is not an external reference for those 14.
    candidate_conversion = median(compensation)
    for key in candidate_keys:
        output[key] = {side: {"factor": candidate_conversion,
                              "status": "custom_candidate_calibration_not_external_reference"}
                       for side in ("front", "back")}
    result = {"version": 1, "manifest_sha256": sha(manifest_path), "species": output,
              "reference": {"family": "Showdown modern animated renders", "sources": sources,
                            "world_arena": [640, 360], "front_perspective": 1.0, "back_perspective": 1.5},
              "not_official_game_scale_certification": True}
    write(args.reference_directory / "scale_reference_candidate.json", result)
    resolved = not missing and len(adapted) == len(mismatches)
    report = {"status": "PASS" if resolved else "REVIEW_REQUIRED",
              "species": len(output), "matched_views": len(dimensions_match),
              "adapted_views": len(adapted), "reference_covered_species": len(output) - len(candidate_keys),
              "missing": missing, "dimension_mismatches": mismatches,
              "custom_candidates": sorted(candidate_keys), "custom_conversion": candidate_conversion,
              "source_files": sources, "applied": False}
    if args.apply:
        if not resolved:
            raise ValueError("Resolve reference exceptions before applying")
        destination = pack / "scale_reference.json"
        temporary = pack / "scale_reference.json.tmp"
        write(temporary, result)
        temporary.replace(destination)
        report["applied"] = True
        report["runtime_reference_sha256"] = sha(destination)
    write(args.reference_directory / "reference_report.json", report)
    print(json.dumps(report, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
