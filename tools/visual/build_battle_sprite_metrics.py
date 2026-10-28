"""Measure opaque animation bounds for the existing local pack; never resample art.

The measurements are presentation data, not official Pokemon game scales.
Every state contributes to one fixed per-view envelope, so attacks never trigger
per-frame fitting or size pumping. Requires Pillow; no source library/network.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path

from PIL import Image


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def measure(job):
    key, row, pack = job
    views = {}
    frames = 0
    atlases = 0
    for side in ("front", "back"):
        bounds = None
        for state, sides in row["states"].items():
            view = sides[side]
            path = pack / view["atlas"]
            if sha(path) != view["sha256"]:
                raise ValueError(f"Atlas changed: {key}/{state}/{side}")
            with Image.open(path) as image:
                image.load()
                if list(image.size) != view["dimensions"]:
                    raise ValueError(f"Unexpected dimensions: {key}/{state}/{side}")
                alpha = image.getchannel("A")
                pivot_x, pivot_y = view["pivot"]
                scale = view["unit_scale"]
                if scale <= 0:
                    raise ValueError(f"Invalid scale: {key}/{state}/{side}")
                for x, y, w, h in view["regions"]:
                    if min(x, y) < 0 or min(w, h) <= 0 or x + w > image.width or y + h > image.height:
                        raise ValueError(f"Out-of-bounds region: {key}/{state}/{side}")
                    box = alpha.crop((x, y, x + w, y + h)).getbbox()
                    if box is None:
                        raise ValueError(f"Empty frame: {key}/{state}/{side}")
                    current = [(box[0] - pivot_x) * scale, (box[1] - pivot_y) * scale,
                               (box[2] - pivot_x) * scale, (box[3] - pivot_y) * scale]
                    if bounds is None:
                        bounds = current
                    else:
                        bounds = [min(bounds[0], current[0]), min(bounds[1], current[1]),
                                  max(bounds[2], current[2]), max(bounds[3], current[3])]
                    frames += 1
            atlases += 1
        views[side] = {"bounds": bounds}
    return key, views, frames, atlases


def build_metrics(game, report=None):
    pack = Path(game) / "assets/local_battle_catalog"
    manifest_path = pack / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    rows = manifest["species"]
    if len(rows) != 1025:
        raise ValueError("Expected complete 1025 base-species pack")
    measured, frames, atlases = {}, 0, 0
    with ThreadPoolExecutor(max_workers=4) as pool:
        jobs = ((key, row, pack) for key, row in sorted(rows.items()))
        for index, (key, views, count, files) in enumerate(pool.map(measure, jobs), 1):
            measured[key] = views
            frames += count
            atlases += files
            if index % 100 == 0:
                print(f"METRICS {index}/1025", flush=True)
    result = {"version": 1, "manifest_sha256": sha(manifest_path),
              "scope": "opaque bounds of all frames/states; not official game scales",
              "frames_measured": frames, "atlas_files": atlases, "species": measured}
    temporary = pack / "presentation_metrics.json.tmp"
    temporary.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(pack / "presentation_metrics.json")
    summary = {"status": "PASS", "species": len(measured), "frames_measured": frames,
               "atlas_files": atlases, "manifest_sha256": result["manifest_sha256"],
               "metrics_sha256": sha(pack / "presentation_metrics.json"),
               "original_images_changed": False}
    if report:
        report = Path(report)
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary), flush=True)
    return summary


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    build_metrics(Path(__file__).resolve().parents[2], args.report)
