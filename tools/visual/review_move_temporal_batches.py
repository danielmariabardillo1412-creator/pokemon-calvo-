"""Resumable 50-move temporal sampling, separate from battle/mechanics approval."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont
from build_move_contact_sheets import GAME, read, write, digest, catalog_clip_contracts

ROOT = GAME / ".godot/move_temporal_batches"
INDEX = GAME / ".godot/move_batch_catalog/index.json"
RENDERER = GAME / "scenes/visual/community_move_preview.gd"
RUNNER = GAME / "tests/visual/move_temporal_batch_runner.gd"


def make_plan(index, index_sha, renderer_sha, builder_sha):
    moves = sorted(row["move_id"] for row in index["moves"] if row["status"] == "converted_lab_only")
    mapping = collections.defaultdict(list)
    for shard in index["shards"]:
        for clip in shard["entries"]:
            mapping[clip["move_id"]].append(clip["id"])
    if len(moves) != len(set(moves)) or set(mapping) != set(moves):
        raise ValueError("invalid move/clip membership")
    if sum(map(len, mapping.values())) != index["converted_clips"]:
        raise ValueError("incomplete clip coverage")
    batches = []
    for start in range(0, len(moves), 50):
        selected = moves[start:start + 50]
        ids = sorted(cid for move in selected for cid in mapping[move])
        if len(ids) != len(set(ids)):
            raise ValueError("duplicate clip")
        for family in {cid.rsplit("/", 1)[0] for cid in ids}:
            if not {family + "/back", family + "/front"} <= set(ids):
                raise ValueError("incomplete family pair")
        batches.append({"number": len(batches) + 1, "move_ids": selected, "clip_ids": ids})
    return {"version": 1, "scope": "TEMPORAL_LAB_REVIEW_NOT_BATTLE_TEST", "batch_size": 50,
            "index_sha256": index_sha, "renderer_sha256": renderer_sha, "builder_sha256": builder_sha,
            "move_count": len(moves), "clip_count": index["converted_clips"], "batches": batches,
            "mechanics_approved": False, "battle_routes_added": 0}


def plan():
    index, _ = catalog_clip_contracts(INDEX, digest(INDEX), INDEX.parent)
    value = make_plan(index, digest(INDEX), digest(RENDERER), digest(Path(__file__)))
    generation = hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()[:16]
    folder = ROOT / generation
    folder.mkdir(parents=True, exist_ok=True)
    write(folder / "plan.json", value)
    if not (folder / "review.json").exists():
        write(folder / "review.json", {"version": 1, "plan_sha256": digest(folder / "plan.json"), "reviews": []})
    write(ROOT / "latest.json", {"path": generation + "/plan.json", "sha256": digest(folder / "plan.json")})
    print("TEMPORAL_BATCH_PLAN PASS", len(value["batches"]), "batches", value["move_count"], "moves", value["clip_count"], "clips", folder)


def validate_report(path):
    report = read(path)
    if report.get("version") != 1 or report.get("failures") != [] or not report.get("gpu"):
        raise ValueError("failed/missing GPU batch gate")
    for key, file in (("index_sha256", INDEX), ("renderer_sha256", RENDERER), ("runner_sha256", RUNNER)):
        if report.get(key) != digest(file):
            raise ValueError("stale evidence: " + key)
    plan_path = GAME / report["plan_path"].removeprefix("res://")
    if digest(plan_path) != report["plan_sha256"]:
        raise ValueError("plan changed")
    current_plan = read(plan_path)
    if current_plan != make_plan(read(INDEX), digest(INDEX), digest(RENDERER), digest(Path(__file__))):
        raise ValueError("stale or invalid batch plan")
    batch = next(b for b in current_plan["batches"] if b["number"] == report["batch"])
    ids = [c["id"] for c in report["clips"]]
    if len(ids) != len(set(ids)) or set(ids) != set(batch["clip_ids"]):
        raise ValueError("incomplete/duplicate batch clips")
    _, contracts = catalog_clip_contracts(INDEX, digest(INDEX), INDEX.parent)
    count = 0
    for clip in report["clips"]:
        source = json.loads(contracts[clip["id"]])[0]
        if clip["source_name"] != source["name"] or len(clip["frames"]) != len(source["frames"]) or not clip["cleanup_matches_baseline"]:
            raise ValueError("changed/incomplete source or failed cleanup")
        for n, frame in enumerate(clip["frames"]):
            relative = Path(frame["path"])
            if frame["frame"] != n or frame["seconds"] != n / 20:
                raise ValueError("invalid frame order/time")
            if relative.is_absolute() or ".." in relative.parts or digest(path.parent / relative) != frame["sha256"]:
                raise ValueError("frame PNG changed")
            count += 1
    if count != report["frames"]:
        raise ValueError("incomplete frame count")
    return report, current_plan, plan_path


def select_samples(clip, differences, count=16):
    length = len(clip["frames"])
    if not length:
        raise ValueError("empty temporal sequence")
    if length <= count:
        return list(range(length)) + [length - 1] * (count - length)
    # Endpoints, particle peak, largest actual pixel transitions and neighbours.
    required = {0, length - 1, max(range(length), key=lambda n: clip["frames"][n]["source_visible_particle_cels"])}
    for n in sorted(range(1, length), key=lambda n: (-differences[n], n))[:3]:
        required.update((n - 1, n))
    samples = sorted(required)
    for n in (round((length - 1) * i / (count - 1)) for i in range(count)):
        if n not in samples and len(samples) < count:
            samples.append(n)
    for n in range(length):
        if len(samples) >= count:
            break
        if n not in samples:
            samples.append(n)
    return sorted(samples)


def build(path):
    report, _, _ = validate_report(path)
    families = collections.defaultdict(dict)
    metrics = {}
    for clip in report["clips"]:
        differences = [0.0]
        previous = None
        for frame in clip["frames"]:
            with Image.open(path.parent / frame["path"]) as image:
                current = image.convert("RGB")
            if previous is not None:
                bounds = ImageChops.difference(previous, current).getbbox()
                differences.append(0.0 if bounds is None else (bounds[2] - bounds[0]) * (bounds[3] - bounds[1]) / (640 * 360))
            previous = current
        flags = []
        if len({f["pixels_sha256"] for f in clip["frames"]}) <= 1:
            flags.append("static_GPU_sequence")
        if max(differences) > 0.9:
            flags.append("large_transition_bbox_not_necessarily_a_fault")
        if any(not b["visible"] or b["opacity"] < 0.99 for b in clip["frames"][-1]["bodies"]):
            flags.append("source_ends_with_hidden_or_faded_body_requires_context")
        selection = select_samples(clip, differences)
        metrics[clip["id"]] = {"samples": selection, "flags": flags, "max_transition_bbox_fraction": max(differences)}
        family, side = clip["id"].rsplit("/", 1)
        families[family][side] = clip
    output = path.parent / "sheets"
    output.mkdir(exist_ok=True)
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 12)
    title = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 20)
    names = sorted(families)
    pages = []
    for start in range(0, len(names), 5):
        group = names[start:start + 5]
        for side in ("back", "front"):
            canvas = Image.new("RGB", (1304, 76 + 254 * len(group)), "#101722")
            draw = ImageDraw.Draw(canvas)
            draw.text((12, 8), f"BLOQUE {report['batch']:02} | pagina {start // 5 + 1} | {side} | 16 tiempos/vista", font=title, fill="white")
            draw.text((12, 39), "TODOS los frames capturados. Se ven 16 muestras, NO pelicula completa ni prueba de combate.", font=small, fill="#c8d6e4")
            rows = []
            for row, family in enumerate(group):
                clip = families[family][side]
                metric = metrics[clip["id"]]
                y = 76 + row * 254
                draw.text((12, y), f"{clip['id']} | {clip['title']} | {len(clip['frames']) / 20:.2f}s", font=font, fill="white")
                draw.text((12, y + 19), ", ".join(metric["flags"]) or "Sin disparador automatico; revision humana pendiente", font=small, fill="#ffba60")
                for col, number in enumerate(metric["samples"]):
                    frame = clip["frames"][number]
                    with Image.open(path.parent / frame["path"]) as image:
                        if image.size != (640, 360):
                            raise ValueError("wrong native dimensions")
                        thumb = image.convert("RGB").resize((160, 90), Image.Resampling.LANCZOS)
                    x = 12 + (col % 8) * 160
                    sy = y + 38 + (col // 8) * 107
                    canvas.paste(thumb, (x, sy))
                    draw.text((x + 2, sy + 91), f"f{number:03} {number / 20:.2f}s", font=small, fill="#c8d6e4")
                rows.append({"id": clip["id"], **metric})
            filename = f"batch_{report['batch']:02}_page_{start // 5 + 1:02}_{side}.png"
            canvas.save(output / filename)
            pages.append({"path": filename, "sha256": digest(output / filename), "clips": rows})
    write(output / "boards.json", {"version": 1, "report_sha256": digest(path), "builder_sha256": digest(Path(__file__)),
          "index_sha256": report["index_sha256"], "batch": report["batch"], "pages": pages,
          "scope": "16 temporal samples, not realtime motion/battle/mechanics approval"})
    print("TEMPORAL_BATCH_SHEETS PASS", len(families), "families", len(pages), "pages", report["frames"], "full frames", output)


def review_clip_ids(page, selected=None):
    available = [row["id"] for row in page["clips"]]
    ids = list(selected) if selected else available
    if not ids or len(ids) != len(set(ids)) or not set(ids) <= set(available):
        raise ValueError("review clips must be unique members of the viewed page")
    return ids


def record(path, page_name, status, note, selected=None):
    if status not in ("temporal_samples_checked", "needs_targeted_review", "requires_external_presentation") or not note.strip():
        raise ValueError("explicit limited review status/note required")
    report, _, plan_path = validate_report(path)
    folder = path.parent / "sheets"
    boards = read(folder / "boards.json")
    page = next(p for p in boards["pages"] if p["path"] == page_name)
    if boards["report_sha256"] != digest(path) or boards["builder_sha256"] != digest(Path(__file__)) or digest(folder / page_name) != page["sha256"]:
        raise ValueError("review evidence changed")
    ledger_path = plan_path.parent / "review.json"
    ledger = read(ledger_path)
    if ledger["plan_sha256"] != digest(plan_path):
        raise ValueError("review plan changed")
    ledger["reviews"].append({"batch": report["batch"], "report_sha256": digest(path), "page": page_name,
        "page_sha256": page["sha256"], "clip_ids": review_clip_ids(page, selected), "status": status, "note": note,
        "mechanics_approved": False, "realtime_motion_watched": False})
    write(ledger_path, ledger)
    print("TEMPORAL_PAGE_RECORDED", page_name, status)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", action="store_true")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--page")
    parser.add_argument("--status")
    parser.add_argument("--note", default="")
    parser.add_argument("--clip", action="append", help="Record only this clip on the viewed page; repeat for mixed findings")
    args = parser.parse_args()
    if args.plan:
        plan()
    elif args.page:
        record(args.report, args.page, args.status, args.note, args.clip)
    else:
        build(args.report)
