"""Temporal QA sheets from full-frame Godot captures; never generates art/approval."""
import argparse
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from build_move_contact_sheets import GAME, read, write, digest, catalog_clip_contracts


def sample_frames(frames):
    if not frames:
        raise ValueError("empty sequence")
    last = len(frames) - 1
    samples = sorted({round(last * i / 7) for i in range(8)})
    peak = max(range(len(frames)), key=lambda n: frames[n]["visible_source_particles"])
    if peak not in samples:
        candidates = samples[1:-1]
        if candidates:
            samples.remove(min(candidates, key=lambda n: abs(n - peak)))
            samples.append(peak)
            samples.sort()
    while len(samples) < 8:
        samples.append(last)
    return samples


def validate(report_path):
    report = read(report_path)
    index_path = GAME / ".godot/move_batch_catalog/index.json"
    if report.get("version") != 1 or report.get("failures") != []:
        raise ValueError("failed/missing capture gate")
    for key, path in (("index_sha256", index_path),
                      ("renderer_sha256", GAME / "scenes/visual/community_move_preview.gd"),
                      ("runner_sha256", GAME / "tests/visual/move_temporal_review.gd")):
        if report.get(key) != digest(path):
            raise ValueError("stale evidence: " + key)
    _, contracts = catalog_clip_contracts(index_path, report["index_sha256"], index_path.parent)
    seen = set()
    total = 0
    import json
    for clip in report["clips"]:
        key = clip["id"]
        if key in seen or key not in contracts or not clip["cleanup_matches_baseline"]:
            raise ValueError("duplicate/missing clip or failed cleanup")
        seen.add(key)
        source = json.loads(contracts[key])[0]
        if len(clip["frames"]) != len(source["frames"]) or clip["fps"] != 20 or clip["source_name"] != source["name"]:
            raise ValueError("incomplete source sequence")
        for n, frame in enumerate(clip["frames"]):
            path = Path(frame["path"])
            if n != frame["frame"] or abs(frame["seconds"] - n / 20) > 1e-6:
                raise ValueError("invalid frame order/time")
            if path.is_absolute() or ".." in path.parts or digest(report_path.parent / path) != frame["sha256"]:
                raise ValueError("native frame changed")
            total += 1
    if not seen or total != report["frames"]:
        raise ValueError("incomplete capture coverage")
    requested = report.get("requested_moves", [])
    if requested and (len(set(requested)) != len(requested) or len(requested) > 10
                      or seen != {m + "/" + s for m in requested for s in ("back", "front")}):
        raise ValueError("incomplete bounded comparison")
    return report


def build(report_path):
    report = validate(report_path)
    folder = report_path.parent
    families = {}
    for clip in report["clips"]:
        pair = families.setdefault(clip["move_id"], {})
        if clip["side"] in pair:
            raise ValueError("duplicate family side")
        pair[clip["side"]] = clip
    names = sorted(families)
    count = math.ceil(len(names) / 10)
    size = math.ceil(len(names) / count)
    groups = [names[n:n + size] for n in range(0, len(names), size)]
    output = folder / "sheets"
    output.mkdir(exist_ok=True)
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 16)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)
    title = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 22)
    pages = []
    for group_n, group in enumerate(groups, 1):
        for side in ("back", "front"):
            canvas = Image.new("RGB", (1944, 78 + 188 * len(group)), "#101722")
            draw = ImageDraw.Draw(canvas)
            draw.text((12, 8), f"SECUENCIA {group_n}/{len(groups)} | {side} | {len(group)} movimientos | 8 tiempos", font=title, fill="white")
            draw.text((12, 41), "Capturados TODOS los frames; esta lamina solo muestra ocho. No es revision a velocidad normal ni aprobacion mecanica.", font=small, fill="#c8d6e4")
            rows = []
            for row, name in enumerate(group):
                clip = families[name].get(side)
                if clip is None:
                    draw.text((12, 78 + 188 * row), name + " / lado no capturado", font=font, fill="#ffba60")
                    continue
                y = 78 + 188 * row
                draw.text((12, y), f"{clip['id']} | {clip['title']} | {len(clip['frames']) / 20:.2f}s | previo: {clip['previous_status']}", font=font, fill="white")
                selection = sample_frames(clip["frames"])
                for col, number in enumerate(selection):
                    frame = clip["frames"][number]
                    with Image.open(folder / frame["path"]) as image:
                        if image.size != (640, 360):
                            raise ValueError("wrong native dimensions")
                        thumb = image.convert("RGB").resize((240, 135), Image.Resampling.LANCZOS)
                    x = 12 + 240 * col
                    canvas.paste(thumb, (x, y + 24))
                    draw.text((x + 2, y + 161), f"f{number:03} {number / 20:.2f}s", font=small, fill="#c8d6e4")
                rows.append({"id": clip["id"], "frames": selection})
            filename = f"temporal_{group_n:02}_{side}.png"
            canvas.save(output / filename)
            pages.append({"id": filename[:-4], "path": filename, "sha256": digest(output / filename), "clips": rows})
    write(output / "boards.json", {"version": 1, "index_sha256": report["index_sha256"],
          "renderer_sha256": report["renderer_sha256"], "report_sha256": digest(report_path),
          "builder_sha256": digest(Path(__file__)), "pages": pages,
          "scope": "Eight temporal samples from full captured sequences, including endpoints and particle peak; not realtime-motion approval"})
    print({"clips": len(report["clips"]), "full_frames": report["frames"], "families": len(families), "pages": len(pages), "folder": str(output)})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    build(parser.parse_args().report)
