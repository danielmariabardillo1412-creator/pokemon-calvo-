"""Build the local visual pack, without changing source images or gameplay data.

Requires Pillow. Inputs are the previously audited source manifest and candidate
registry. All output paths in the runtime manifest are game-relative. GIF timing,
transparency and complete frames are preserved; no guessed back/front aliases.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import shutil
from statistics import median

from PIL import Image
from build_battle_sprite_metrics import build_metrics


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build_species(job):
    key, definition, source, candidate, heights, pack = job
    folder = pack / "atlases" / key
    folder.mkdir(parents=True, exist_ok=True)
    row = {"display_name": definition["display_name"], "states": {}, "art_approved": False}
    provenance = {"species": key, "inputs": []}
    if candidate:
        row["source_family"] = "local_3d_candidate"
        row["provisional"] = True
        row["pokeapi_pokemon_id"] = candidate["identity"]["pokeapi_pokemon_id"]
        for state, views in candidate["states"].items():
            row["states"][state] = {}
            for side, view in views.items():
                original = Path(view["atlas"])
                assert digest(original) == view["sha256"], original
                destination = folder / f"{state}_{side}.png"
                shutil.copyfile(original, destination)
                with Image.open(destination) as atlas:
                    atlas.load()
                    dimensions = list(atlas.size)
                count = len(view["frames"])
                row["states"][state][side] = {
                    "atlas": f"atlases/{key}/{destination.name}",
                    "sha256": view["sha256"], "dimensions": dimensions,
                    "regions": [f["region"] for f in view["frames"]],
                    "durations": [view["seconds"] / count] * count,
                    "loop": view["loop"], "pivot": candidate["pivot"],
                    "unit_scale": 1.0,
                }
                provenance["inputs"].append({"path": str(original), "sha256": view["sha256"]})
        return key, row, provenance

    row["source_family"] = "showdown_rendered"
    row["provisional"] = False
    assert source.get("back"), f"Missing audited back: {key}"
    source_id = int(Path(source["front"]["path"]).stem.split("-")[0])
    row["pokeapi_pokemon_id"] = source_id
    height_metres = float(read(heights / str(source_id) / "index.json")["height"]) / 10.0
    target = min(220.0, max(64.0, 120.0 * height_metres ** 0.35)) * 0.99
    pending = {}
    gains = []
    for side in ("front", "back"):
        item = source[side]
        original = Path(item["path"])
        assert digest(original) == item["sha256"], f"Source changed: {original}"
        frames, boxes, durations = [], [], []
        with Image.open(original) as image:
            for index in range(image.n_frames):
                image.seek(index)
                frame = image.convert("RGBA")
                box = frame.getchannel("A").getbbox()
                assert box, f"Empty frame: {key}/{side}/{index}"
                frames.append(frame)
                boxes.append(box)
                milliseconds = int(image.info.get("duration", 0))
                if image.n_frames == 1 and milliseconds <= 0:
                    milliseconds = 1000  # Static still; no animation/timing inferred.
                assert milliseconds > 0, f"Missing/zero timing: {key}/{side}/{index}"
                durations.append(milliseconds / 1000.0)
        assert len(frames) == item["frames"]
        w, h = frames[0].size
        columns = min(len(frames), max(1, math.ceil(math.sqrt(len(frames) * h / w))))
        rows = math.ceil(len(frames) / columns)
        assert max(columns * w, rows * h) <= 4096, (key, side, w, h, len(frames))
        atlas = Image.new("RGBA", (columns * w, rows * h))
        regions = []
        for index, frame in enumerate(frames):
            x, y = (index % columns) * w, (index // columns) * h
            atlas.paste(frame, (x, y))  # Copy RGBA; no alpha-mask double multiplication.
            regions.append([x, y, w, h])
        destination = folder / f"reposo_{side}.png"
        atlas.save(destination, compress_level=3)
        pivot = [median([(b[0] + b[2]) / 2 for b in boxes]), median([b[3] for b in boxes])]
        scale = target / median([b[3] - b[1] for b in boxes])
        # Stable per-view calibration, never per-frame fitting. Shared safety gain
        # keeps wide/tall species within the arena without clipping animation.
        horizontal = max(max(abs(b[0] - pivot[0]), abs(b[2] - pivot[0])) for b in boxes) * scale
        vertical = max(max(abs(b[1] - pivot[1]), abs(b[3] - pivot[1])) for b in boxes) * scale
        gains.append(min(1.0, 178.0 / max(horizontal, 1), 240.0 / max(vertical, 1)))
        pending[side] = {
            "atlas": f"atlases/{key}/{destination.name}", "sha256": digest(destination),
            "dimensions": list(atlas.size), "regions": regions, "durations": durations,
            "loop": True, "pivot": pivot, "unit_scale": scale,
        }
        provenance["inputs"].append({"path": str(original), "sha256": item["sha256"]})
    gain = min(gains)
    for view in pending.values():
        view["unit_scale"] *= gain
    row["states"]["reposo"] = pending
    row["height_metres"] = height_metres
    row["size_safety_gain"] = gain
    return key, row, provenance


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-manifest", required=True, type=Path)
    parser.add_argument("--candidate-registry", required=True, type=Path)
    parser.add_argument("--pokemon-height-directory", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    game = Path(__file__).resolve().parents[2]
    pack = game / "assets/local_battle_catalog"
    pack.mkdir(parents=True, exist_ok=True)
    definitions = read(game / "data/normalized/pokemon_api.json")["species"]
    source = read(args.source_manifest)["species"]
    candidates = {c["identity"]["game_species_key"].replace("-", "_"): c
                  for c in read(args.candidate_registry)["candidates"] if c["kind"] == "base_candidate"}
    assert len(definitions) == 1025 and set(source) == set(definitions)
    assert len(candidates) == 14 and set(candidates) <= set(definitions)
    jobs = [(key, value, source[key], candidates.get(key), args.pokemon_height_directory, pack)
            for key, value in sorted(definitions.items())]
    species, provenance = {}, []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for index, (key, row, origin) in enumerate(pool.map(build_species, jobs), 1):
            species[key] = row
            provenance.append(origin)
            if index % 100 == 0:
                print(f"BUILD {index}/1025", flush=True)
    manifest = {"version": 1, "scope": "1025 base species, normal colour only",
                "not_certified": ["alternate forms", "shiny", "move VFX", "all combat mechanics", "final art"],
                "species": species}
    # Publish only after every species succeeds; never expose a partial new catalog.
    temporary = pack / "manifest.json.tmp"
    write(temporary, manifest)
    temporary.replace(pack / "manifest.json")
    build_metrics(game, args.report.with_name("presentation_metrics_build.json"))
    atlases = list((pack / "atlases").rglob("*.png"))
    report = {"status": "PASS", "species": len(species), "front_back_pairs": len(species),
              "atlas_files": len(atlases), "atlas_bytes": sum(p.stat().st_size for p in atlases),
              "frames": sum(len(v["regions"]) for r in species.values() for s in r["states"].values() for v in s.values()),
              "static_idle_views": [f"{k}/{s}" for k, r in species.items() for s, v in r["states"]["reposo"].items() if len(v["regions"]) == 1],
              "source_manifest_sha256": digest(args.source_manifest),
              "candidate_registry_sha256": digest(args.candidate_registry), "provenance": provenance}
    args.report.parent.mkdir(parents=True, exist_ok=True)
    write(args.report, report)
    print(json.dumps({k: v for k, v in report.items() if k != "provenance"}, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
