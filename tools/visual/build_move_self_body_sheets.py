"""Before/after contact sheets of GPU captures for the primary self-body repair."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(report_path):
    report = json.loads(report_path.read_text(encoding="utf-8"))
    assert report["gpu"] and not report["failures"], "GPU gate must pass first"
    assert report["index_sha256"] == digest(GAME / ".godot/move_batch_catalog/index.json")
    assert report["renderer_sha256"] == digest(GAME / "scenes/visual/community_move_preview.gd")
    assert report["runner_sha256"] == digest(GAME / "tests/visual/move_self_body_test_runner.gd")
    assert report["renderer_before_sha256"] == digest(GAME / ".godot/move_self_body_checks/reference/preview_before.gd")
    pairs = {}
    for row in report["samples"]:
        assert row["side"] in ("back", "front")
        pair = pairs.setdefault(row["move_id"], {})
        assert row["side"] not in pair
        pair[row["side"]] = row
        for path, expected in zip(row["paths"], row["pixels_sha256"], strict=True):
            relative = Path(path)
            assert not relative.is_absolute() and ".." not in relative.parts
            with Image.open(report_path.parent / relative) as image:
                assert image.size == (640, 360)
                assert hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest() == expected
    assert len(report["samples"]) == 76 and len(pairs) == 38
    assert all(set(pair) == {"back", "front"} for pair in pairs.values())
    folder = report_path.parent / "sheets"
    folder.mkdir(exist_ok=True)
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 14)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 12)
    ids = sorted(pairs)
    pages = []
    for start in range(0, len(ids), 5):
        selected = ids[start:start + 5]
        sheet = Image.new("RGB", (1280, 84 + len(selected) * 212), "#101824")
        draw = ImageDraw.Draw(sheet)
        draw.text((10, 8), "CUERPOS PROPIOS | antes / despues | un fotograma focal por vista", font=font, fill="white")
        draw.text((10, 30), "Gate de todos los frames del grupo por dos arenas; estas imagenes NO son toda la animacion.", font=small, fill="#b7c8d8")
        for col, label in enumerate(["back ANTES", "back DESPUES", "front ANTES", "front DESPUES"]):
            draw.text((col * 320 + 10, 59), label, font=font, fill="white")
        for r, move in enumerate(selected):
            y = 84 + r * 212
            back, front = pairs[move]["back"], pairs[move]["front"]
            label = f"{move} | {back['title']} | f{back['frame']}/f{front['frame']} | cambios GPU {back['changed']}/{front['changed']}"
            draw.text((10, y), label, font=small, fill="white")
            for col, (row, phase) in enumerate([(back, 0), (back, 1), (front, 0), (front, 1)]):
                with Image.open(report_path.parent / row["paths"][phase]) as image:
                    sheet.paste(image.convert("RGB").resize((320, 180), Image.Resampling.LANCZOS), (col * 320, y + 24))
        name = f"self_bodies_{len(pages) + 1:02d}.png"
        sheet.save(folder / name)
        pages.append({"path": name, "sha256": digest(folder / name), "move_ids": selected})
    boards = {"version": 1, "report_sha256": digest(report_path), "builder_sha256": digest(Path(__file__)),
              "renderer_sha256": report["renderer_sha256"], "pages": pages,
              "scope": "Paired focal GPU frames; review remains explicit, not automatic approval"}
    (folder / "boards.json").write_text(json.dumps(boards, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("SELF_BODY_SHEETS PASS", len(pairs), "families", len(pages), "pages", folder)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    build(parser.parse_args().report)
