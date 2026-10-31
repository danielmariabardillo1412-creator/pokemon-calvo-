"""Contact sheets of optional LAB composition; never native/mechanical approval."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from build_move_contact_sheets import GAME, read, write, digest
from build_move_external_context import DEFINITIONS


def validate(path):
    report = read(path)
    if report.get("version") != 1 or report.get("failures") != [] or report.get("gpu") is not True:
        raise ValueError("missing successful GPU context gate")
    for key, relative in (("index_sha256", ".godot/move_batch_catalog/index.json"),
                          ("renderer_sha256", "scenes/visual/community_move_preview.gd"),
                          ("adapter_sha256", "scenes/visual/move_external_context.gd"),
                          ("ui_sha256", "scenes/visual/move_resource_lab.gd"),
                          ("runner_sha256", "tests/visual/move_external_context_test_runner.gd")):
        if report[key] != digest(GAME / relative):
            raise ValueError("stale context evidence: " + key)
    manifest_path = GAME / report["context_manifest_path"].removeprefix("res://")
    if digest(manifest_path) != report["context_manifest_sha256"]:
        raise ValueError("context manifest changed")
    manifest = read(manifest_path)
    expected = {(move + "/" + side, (w, h)) for move in DEFINITIONS for side in ("back", "front") for w, h in ((640, 360), (400, 300))}
    actual = [(row["id"], tuple(row["arena"])) for row in report["clips"]]
    if len(actual) != len(set(actual)) or set(actual) != expected:
        raise ValueError("incomplete/duplicate composition matrix")
    count = 0
    for clip in report["clips"]:
        length = clip["source_frames"] + 30
        if clip["source_frames"] != manifest["bindings"][clip["id"]]["source_frames"]:
            raise ValueError("native source length changed")
        if clip["context_frames"] != 30 or len(clip["frames"]) != length:
            raise ValueError("incomplete source/context timeline")
        for n, frame in enumerate(clip["frames"]):
            relative = Path(frame["path"])
            if frame["frame"] != n or frame["post_source"] != (n >= clip["source_frames"]):
                raise ValueError("incorrect context phase/order")
            if relative.is_absolute() or ".." in relative.parts or digest(path.parent / relative) != frame["sha256"]:
                raise ValueError("context screenshot changed")
            count += 1
    if count != report["states"] or count != 1164:
        raise ValueError("incomplete context state coverage")
    return report


def build(path):
    report = validate(path)
    clips = {(row["id"], tuple(row["arena"])): row for row in report["clips"]}
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)
    title = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 21)
    output = path.parent / "sheets"
    output.mkdir(exist_ok=True)
    pages = []
    for arena in ((640, 360), (400, 300)):
        for side in ("back", "front"):
            canvas = Image.new("RGB", (1944, 78 + 188 * len(DEFINITIONS)), "#101722")
            draw = ImageDraw.Draw(canvas)
            draw.text((12, 8), f"SIMULACION LOCAL OPCIONAL | {side} | {arena[0]}x{arena[1]} | NO mecanicas", font=title, fill="white")
            draw.text((12, 41), "Fuente y contexto DEMO separados; Transformacion cambia bajo el destello. NO demuestra mecanicas, persistencia ni copia de atributos.", font=small, fill="#c8d6e4")
            for row, name in enumerate(DEFINITIONS):
                clip = clips[name + "/" + side, arena]
                length = clip["source_frames"]
                samples = [0, (length - 1) // 2, length - 1, length, length + 7, length + 15, length + 22, length + 29]
                y = 78 + row * 188
                draw.text((12, y), f"{clip['id']} | {clip['title']} | fuente {length} f + contexto 30 f", font=font, fill="white")
                for col, n in enumerate(samples):
                    frame = clip["frames"][n]
                    with Image.open(path.parent / frame["path"]) as image:
                        if image.size != arena:
                            raise ValueError("context dimensions changed")
                        thumb = image.convert("RGB")
                        thumb.thumbnail((240, 135), Image.Resampling.LANCZOS)
                    x = 12 + col * 240
                    canvas.paste(thumb, (x + (240 - thumb.width) // 2, y + 24))
                    demo = n >= length or (name == "transform" and n >= 8)
                    draw.text((x + 2, y + 161), ("CONTEXTO " if demo else "FUENTE ") + f"f{n:03}", font=small, fill="#ffba60" if demo else "#c8d6e4")
            filename = f"context_{arena[0]}_{side}.png"
            canvas.save(output / filename)
            pages.append({"path": filename, "sha256": digest(output / filename), "arena": list(arena), "side": side})
    write(output / "boards.json", {"version": 1, "report_sha256": digest(path), "builder_sha256": digest(Path(__file__)), "pages": pages,
          "scope": "Samples of optional LAB simulation, NOT an approval of native clips/mechanics/integration"})
    print("EXTERNAL_CONTEXT_SHEETS PASS pages=4 states=1164 folder=", output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    build(parser.parse_args().report)
