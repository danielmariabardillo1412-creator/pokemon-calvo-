"""Verified before/after sheets for pinned field bodies and the shadow path."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(path):
    report = json.loads(path.read_text(encoding="utf-8"))
    assert report["gpu"] and not report["failures"]
    assert report["index_sha256"] == digest(GAME / ".godot/move_batch_catalog/index.json")
    assert report["renderer_sha256"] == digest(GAME / "scenes/visual/community_move_preview.gd")
    assert report["runner_sha256"] == digest(GAME / "tests/visual/move_projection_group_test_runner.gd")
    assert report["renderer_before_sha256"] == digest(GAME / ".godot/move_projection_checks/reference/preview_before.gd")
    pairs = {}
    assert len(report["samples"]) == 96
    for row in report["samples"]:
        for name, pixels in zip(row["paths"], row["pixels_sha256"], strict=True):
            relative = Path(name)
            assert not relative.is_absolute() and ".." not in relative.parts
            with Image.open(path.parent / relative) as image:
                assert image.size == (640, 360)
                assert hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest() == pixels
        if row["focal"]:
            pair = pairs.setdefault(row["move_id"], {})
            assert row["side"] not in pair
            pair[row["side"]] = row
    assert len(pairs) == 15 and all(set(p) == {"back", "front"} for p in pairs.values())
    folder = path.parent / "sheets"
    folder.mkdir(exist_ok=True)
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 14)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 12)
    ids, pages = sorted(pairs), []
    for start in range(0, len(ids), 5):
        selected = ids[start:start + 5]
        image = Image.new("RGB", (1280, 84 + len(selected) * 212), "#101824")
        draw = ImageDraw.Draw(image)
        draw.text((10, 8), "ESCUDOS Y SOMBRA | antes / despues | un fotograma focal por vista", font=font, fill="white")
        draw.text((10, 30), "Gate de todos los frames: tres parejas/dos arenas. Arte/capas intactos; solo proyecciones auditadas.", font=small, fill="#b7c8d8")
        for col, label in enumerate(["back ANTES", "back DESPUES", "front ANTES", "front DESPUES"]):
            draw.text((col * 320 + 10, 59), label, font=font, fill="white")
        for r, move in enumerate(selected):
            back, front = pairs[move]["back"], pairs[move]["front"]
            y = 84 + r * 212
            draw.text((10, y), f"{move} | {back['title']} | f{back['frame']}/f{front['frame']} | frontal corregido {front['corrected']}", font=small, fill="white")
            for col, (row, phase) in enumerate([(back, 0), (back, 1), (front, 0), (front, 1)]):
                with Image.open(path.parent / row["paths"][phase]) as capture:
                    image.paste(capture.convert("RGB").resize((320, 180), Image.Resampling.LANCZOS), (col * 320, y + 24))
        name = f"projection_{len(pages) + 1:02d}.png"
        image.save(folder / name)
        pages.append({"path": name, "sha256": digest(folder / name), "move_ids": selected})
    boards = {"version": 1, "report_sha256": digest(path), "builder_sha256": digest(Path(__file__)),
              "pages": pages, "scope": "Explicit focal image review required; not realtime motion/mechanics approval"}
    (folder / "boards.json").write_text(json.dumps(boards, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("PROJECTION_SHEETS PASS", len(pairs), "families", len(pages), "pages", folder)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    build(parser.parse_args().report)
