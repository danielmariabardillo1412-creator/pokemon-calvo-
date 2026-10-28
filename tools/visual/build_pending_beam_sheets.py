"""Paired camera diagnostics from Godot; no new artwork or automatic approval."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
from build_move_contact_sheets import GAME, read, write, digest, catalog_clip_contracts

MOVES = {"twin_beam", "dragon_pulse", "glacial_lance"}
MODES = {"canonical_512": (512, 384), "adapted_640": (640, 360), "adapted_400": (400, 300)}


def display_frames(clip):
    samples = list(clip["sample_frames"])
    if "body_peak_frame" in clip:
        peak = clip["body_peak_frame"]
        if not 0 <= peak < len(clip["frames"]):
            raise ValueError("invalid silhouette peak")
        samples[1] = peak
    return sorted(samples)


def check_matrix(report):
    expected = {(move + "/" + side, mode) for move in MOVES for side in ("back", "front") for mode in MODES}
    keys = [(c["id"], c["mode"]) for c in report["clips"]]
    if len(keys) != len(set(keys)) or set(keys) != expected:
        raise ValueError("incomplete/duplicate camera matrix")
    for clip in report["clips"]:
        if [f["frame"] for f in clip["frames"]] != list(range(len(clip["frames"]))):
            raise ValueError("incomplete frame order")
        if not clip["frames"] or any(n < 0 or n >= len(clip["frames"]) for n in clip["sample_frames"]):
            raise ValueError("invalid samples")
        display_frames(clip)
    if sum(len(c["frames"]) for c in report["clips"]) != report["frames"]:
        raise ValueError("incomplete frame count")


def build(path):
    report = read(path)
    if report.get("version") != 1 or report.get("failures") != []:
        raise ValueError("failed camera probe")
    for field, file in (("index_sha256", GAME / ".godot/move_batch_catalog/index.json"),
                        ("renderer_sha256", GAME / "scenes/visual/community_move_preview.gd"),
                        ("runner_sha256", GAME / "tests/visual/move_pending_beam_probe.gd")):
        if report[field] != digest(file):
            raise ValueError("stale probe")
    check_matrix(report)
    _, contracts = catalog_clip_contracts(GAME / ".godot/move_batch_catalog/index.json", report["index_sha256"], GAME / ".godot/move_batch_catalog")
    for clip in report["clips"]:
        if len(json.loads(contracts[clip["id"]])[0]["frames"]) != len(clip["frames"]):
            raise ValueError("source frame count")
        for frame in clip["frames"]:
            if "path" not in frame:
                continue
            relative = Path(frame["path"])
            if relative.is_absolute() or ".." in relative.parts or digest(path.parent / relative) != frame["sha256"]:
                raise ValueError("screenshot changed")
    clips = {(c["id"], c["mode"]): c for c in report["clips"]}
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 16)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)
    title = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 22)
    pages = []
    for side in ("back", "front"):
        canvas = Image.new("RGB", (1304, 70 + 434 * len(MOVES)), "#101722")
        draw = ImageDraw.Draw(canvas)
        draw.text((12, 8), "CAMARA CANONICA FIJA / ADAPTADA | " + side, font=title, fill="white")
        draw.text((12, 40), "Referencia geometrica, NO captura del juego original. Cobertura del ancla NO demuestra dano/contacto corporal ni aprobacion artistica.", font=small, fill="#c8d6e4")
        ids = []
        for row, name in enumerate(sorted(MOVES)):
            y = 70 + row * 434
            key = name + "/" + side
            draw.text((12, y), key + " | " + clips[key, "adapted_640"]["title"], font=font, fill="white")
            for mode_n, mode in enumerate(("canonical_512", "adapted_640")):
                clip = clips[key, mode]
                mode_y = y + 25 + mode_n * 202
                label = "512x384 puestos canonicos" if mode == "canonical_512" else "640x360 camara actual"
                draw.text((12, mode_y), label + f" | ancla: {clip['anchor_covered_frames']}/{len(clip['frames'])} f | incluye pico de silueta (NO dano)", font=small, fill="#ffba60")
                for col, n in enumerate(display_frames(clip)):
                    frame = clip["frames"][n]
                    with Image.open(path.parent / frame["path"]) as image:
                        if image.size != MODES[mode]:
                            raise ValueError("native screenshot dimensions")
                        thumb = ImageOps.contain(image.convert("RGB"), (320, 160), Image.Resampling.LANCZOS)
                    x = 12 + 320 * col
                    canvas.paste(thumb, (x + (320 - thumb.width) // 2, mode_y + 18))
                    draw.text((x + 2, mode_y + 180), f"f{n:03d} {n / 20:.2f}s", font=small, fill="#c8d6e4")
            ids.append(key)
        filename = "camera_comparison_" + side + ".png"
        canvas.save(path.parent / filename)
        pages.append({"path": filename, "sha256": digest(path.parent / filename), "clip_ids": ids})
    write(path.parent / "boards.json", {"version": 1, "report_sha256": digest(path), "builder_sha256": digest(Path(__file__)), "pages": pages})
    print({"families": len(MOVES), "pages": len(pages), "folder": str(path.parent)})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    build(parser.parse_args().report)
