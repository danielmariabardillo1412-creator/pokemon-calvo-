"""Deterministic QA contact sheets of actual Godot screenshots, not generated art.

Twenty animation families per batch, three temporal samples, separate actor sides.
Persistent reviews bind to exact sheet hashes; unviewed sheets stay pending.
"""
import argparse
import collections
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]
ROOT = GAME / ".godot/move_contact_review"
STATUSES = {"pending", "sampled_no_obvious_issue", "suspected_issue", "needs_motion_review", "confirmed_issue", "requires_external_presentation"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write(path, value):
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def load_evidence(root):
    pointer = read(root / "latest.json")
    relative = Path(pointer["path"])
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError("unsafe capture path")
    path = root / relative
    if digest(path) != pointer["sha256"]:
        raise ValueError("capture manifest hash")
    manifest = read(path)
    if manifest["index_sha256"] != digest(GAME / ".godot/move_batch_catalog/index.json"):
        raise ValueError("stale capture index")
    if manifest["renderer_sha256"] != digest(GAME / "scenes/visual/community_move_preview.gd"):
        raise ValueError("stale capture renderer")
    if manifest["audit_sha256"] != digest(GAME / ".godot/move_batch_checks/gpu_result.json"):
        raise ValueError("stale GPU audit evidence")
    return path.parent, manifest


def make_groups(clips, flagged, size):
    if not 1 <= size <= 20:
        raise ValueError("batch size must be 1..20")
    families = collections.defaultdict(dict)
    for clip in clips:
        side = clip["side"]
        if side in families[clip["family"]] or side not in ("back", "front"):
            raise ValueError("duplicate/invalid clip side")
        families[clip["family"]][side] = clip
    if any(set(pair) != {"back", "front"} for pair in families.values()):
        raise ValueError("missing paired side")
    ordered = sorted(families, key=lambda family: (family.split("/")[0] not in flagged, family))
    return families, [ordered[start:start + size] for start in range(0, len(ordered), size)]


def sampling_rechecks(clips, audit):
    old = {row["id"]: row for row in audit["clips"]}
    return [{"id": row["id"], "old_warning": "unchanged_GPU_samples_review", "new_distinct_samples": row["distinct_gpu_samples"],
             "finding": "Not globally static: distinct-state sampling renders different pixels; aesthetic/motion review still pending"}
            for row in clips if row["distinct_gpu_samples"] > 1 and any("unchanged_GPU_samples_review" in warning for warning in old[row["id"]]["warnings"])]


def build(root, size, pending_only=False):
    folder, manifest = load_evidence(root)
    queue = read(GAME / ".godot/move_batch_checks/review_queue.json")
    if queue["index_sha256"] != manifest["index_sha256"] or not queue["gpu"]:
        raise ValueError("stale/non-GPU review queue")
    flagged = {move for group in queue["groups"] if group["group"].startswith("visual/") for move in group["move_ids"]}
    clips = manifest["clips"]
    if pending_only:
        full = folder / ("sheets_%02d" % size)
        boards, ledger = read(full / "boards.json"), read(full / "review_log.json")
        if boards["index_sha256"] != manifest["index_sha256"] or boards["capture_manifest_sha256"] != digest(folder / "captures.json"):
            raise ValueError("pending review context changed")
        if any(digest(full / p["path"]) != p["sha256"] for p in boards["pages"]):
            raise ValueError("pending review board changed")
        valid = {p["sha256"] for p in boards["pages"]}
        reviewed = {c for e in ledger["reviews"] if e["index_sha256"] == manifest["index_sha256"] and e["board_sha256"] in valid for c in e["clip_ids"]}
        pending_families = {c["family"] for c in clips if c["id"] not in reviewed}
        clips = [c for c in clips if c["family"] in pending_families]
        if not clips:
            raise ValueError("no pending families")
    families, batches = make_groups(clips, flagged, size)
    sheets = folder / (("delta_sheets_%02d" if pending_only else "sheets_%02d") % size)
    sheets.mkdir(exist_ok=True)
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)
    bold = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 20)
    pages = []
    for number, batch in enumerate(batches, 1):
        for side in ("back", "front"):
            canvas = Image.new("RGB", (1584, 70 + ((len(batch) + 1) // 2) * 203), "#101722")
            draw = ImageDraw.Draw(canvas)
            draw.text((16, 9), f"LOTE {number:02d}/{len(batches):02d} | {side} | {len(batch)} familias | 3 momentos", font=bold, fill="white")
            draw.text((16, 39), "Naranja: aviso automatico. Capturas muestreadas; no prueban fluidez ni mecanica. Estado de revision: index.md.", font=small, fill="#c8d6e4")
            ids = []
            for cell, family in enumerate(batch):
                clip = families[family][side]
                source = folder / clip["path"]
                if digest(source) != clip["sha256"]:
                    raise ValueError("screenshot changed: " + clip["id"])
                with Image.open(source) as strip:
                    if strip.size != (1920, 360):
                        raise ValueError("invalid screenshot strip dimensions")
                    thumb = strip.convert("RGB").resize((768, 144), Image.Resampling.LANCZOS)
                x, y = 10 + (cell % 2) * 792, 68 + (cell // 2) * 203
                color = "#ffba60" if clip["move_id"] in flagged else "#dde7f2"
                draw.text((x, y), f"{cell + 1:02d}. {family}"[:91], font=font, fill=color)
                draw.text((x, y + 18), clip["title"][:91], font=small, fill="#b0bfce")
                canvas.paste(thumb, (x, y + 35))
                frames = "  |  ".join(f"f{sample['frame']:03d} {sample['seconds']:.2f}s" for sample in clip["samples"])
                draw.text((x, y + 180), frames + f" | distintos: {clip['distinct_gpu_samples']}/3", font=small, fill=color)
                ids.append(clip["id"])
            filename = f"batch_{number:02d}_{side}.png"
            canvas.save(sheets / filename)
            pages.append({"id": filename[:-4], "path": filename, "sha256": digest(sheets / filename), "clip_ids": ids, "batch": number, "side": side})
    board_manifest = {"version": 1, "index_sha256": manifest["index_sha256"], "capture_manifest_sha256": digest(folder / "captures.json"), "pending_only": pending_only,
                      "builder_sha256": digest(Path(__file__)), "families": len(families), "batch_size": size, "pages": pages,
                      "sampling_rechecks": sampling_rechecks(manifest["clips"], read(GAME / ".godot/move_batch_checks/gpu_result.json"))}
    write(sheets / "boards.json", board_manifest)
    ledger_path = sheets / "review_log.json"
    if not ledger_path.exists():
        write(ledger_path, {"version": 1, "index_sha256": manifest["index_sha256"], "reviews": []})
    render_index(sheets, board_manifest)
    print(json.dumps({"families": len(families), "batches": len(batches), "sheets": len(pages), "flagged_moves_first": len(flagged), "folder": str(sheets)}))
    return sheets


def record(sheets, board_id, status, note, clip_id=None):
    if status not in STATUSES - {"pending"} or not note.strip():
        raise ValueError("explicit status and evidence note required")
    boards = read(sheets / "boards.json")
    page = next(p for p in boards["pages"] if p["id"] == board_id)
    if digest(sheets / page["path"]) != page["sha256"]:
        raise ValueError("board changed; cannot attribute review")
    if clip_id and clip_id not in page["clip_ids"]:
        raise ValueError("clip not in board")
    ledger_path = sheets / "review_log.json"
    ledger = read(ledger_path)
    ledger["reviews"].append({"board": board_id, "board_sha256": page["sha256"], "index_sha256": boards["index_sha256"],
                              "clip_ids": [clip_id] if clip_id else page["clip_ids"], "status": status, "note": note})
    write(ledger_path, ledger)
    render_index(sheets, boards)


def catalog_clip_contracts(index_path, expected_hash, catalog_root):
    if digest(index_path) != expected_hash:
        raise ValueError("catalog proof hash changed")
    index = read(index_path)
    contracts = {}
    checked_pngs = {}
    for shard in index["shards"]:
        relative = Path(shard["path"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("unsafe catalog proof path")
        path = catalog_root / relative
        if digest(path) != shard["sha256"]:
            raise ValueError("catalog proof shard changed")
        pack = read(path)
        for clip in pack["clips"]:
            keys = {clip.get("sheet"), *clip.get("layer_sheets", {}).values()} - {"", None}
            sheets = {key: {field: pack["sheets"][key][field] for field in ("sha256", "dimensions")} for key in keys}
            for key, sheet in sheets.items():
                if Path(key).name != key or ".." in key:
                    raise ValueError("unsafe catalog proof PNG")
                png = path.parent / key
                if png not in checked_pngs:
                    checked_pngs[png] = digest(png)
                if checked_pngs[png] != sheet["sha256"]:
                    raise ValueError("catalog proof PNG changed")
            if clip["id"] in contracts:
                raise ValueError("duplicate catalog proof clip")
            contracts[clip["id"]] = json.dumps([clip, sheets], sort_keys=True)
    return index, contracts


def migrate_render_equivalent_clips(old_folder, new_folder, previous_index, catalog_root, proof_path=None):
    """Per-clip proof, including regrouping with an identical renderer. No new neighbours."""
    old, new = read(old_folder / "boards.json"), read(new_folder / "boards.json")
    before, after = read(old_folder.parent / "captures.json"), read(new_folder.parent / "captures.json")
    for folder, boards, captures in ((old_folder, old, before), (new_folder, new, after)):
        if digest(folder.parent / "captures.json") != boards["capture_manifest_sha256"] or captures["index_sha256"] != boards["index_sha256"]:
            raise ValueError("capture/catalog proof mismatch")
        for page in boards["pages"]:
            if digest(folder / page["path"]) != page["sha256"]:
                raise ValueError("board evidence changed")
    if previous_index is None:
        raise ValueError("renderer proof needs pinned previous index")
    catalog_root = catalog_root or GAME / ".godot/move_batch_catalog"
    old_index, old_clips = catalog_clip_contracts(previous_index, old["index_sha256"], catalog_root)
    new_index, new_clips = catalog_clip_contracts(catalog_root / "index.json", new["index_sha256"], catalog_root)
    if old_index["canonical_hashes_unchanged"] != new_index["canonical_hashes_unchanged"]:
        raise ValueError("canonical proof changed")
    if proof_path is None:
        if before["renderer_sha256"] != after["renderer_sha256"]:
            raise ValueError("cannot regroup across changed renderer without render equivalence")
        # Require the real pinned source, not a claimed hash in a manifest.
        if (digest(old_folder.parent / "renderer_snapshot.gd") != before["renderer_sha256"]
                or digest(new_folder.parent / "renderer_snapshot.gd") != after["renderer_sha256"]):
            raise ValueError("renderer snapshot changed")
        equivalent = old_clips.keys() & new_clips.keys()
        basis = "Identical renderer and complete source/sheets/native GPU samples of this clip ONLY; new neighbours NOT reviewed"
    else:
        proof = read(proof_path)
        expected = {"version": 1, "failures": [], "old_index_sha256": old["index_sha256"], "new_index_sha256": new["index_sha256"],
                    "old_renderer_sha256": before["renderer_sha256"], "new_renderer_sha256": after["renderer_sha256"],
                    "runner_sha256": digest(GAME / "tests/visual/move_render_equivalence_runner.gd")}
        if any(proof.get(k) != v for k, v in expected.items()):
            raise ValueError("render equivalence proof mismatch")
        equivalent, changed = proof["equivalent_clip_ids"], proof["changed_clip_ids"]
        all_ids = equivalent + changed
        frames = sum(len(json.loads(c)[0]["frames"]) * 2 for c in new_clips.values())
        if (len(all_ids) != len(set(all_ids)) or set(all_ids) != set(old_clips) or set(all_ids) != set(new_clips)
                or proof["frames"] != frames):
            raise ValueError("incomplete render equivalence proof")
        basis = "This clip ONLY: all-frame/two-arena draw equivalence, same complete source/sheets and native GPU samples; new neighbours NOT reviewed"
    old_images, new_images = ({row["id"]: row for row in m["clips"]} for m in (before, after))
    eligible = set(equivalent) & old_images.keys() & new_images.keys()
    eligible = {c for c in eligible if old_clips[c] == new_clips[c]
                and all(old_images[c][k] == new_images[c][k] for k in ("sha256", "samples", "title"))}
    for c in eligible:
        for folder, images in ((old_folder.parent, old_images), (new_folder.parent, new_images)):
            path = Path(images[c]["path"])
            if path.is_absolute() or ".." in path.parts or digest(folder / path) != images[c]["sha256"]:
                raise ValueError("native capture evidence changed")
    old_pages = {p["id"]: p for p in old["pages"]}
    new_pages = {c: p for p in new["pages"] for c in p["clip_ids"]}
    latest = {}
    for entry in read(old_folder / "review_log.json")["reviews"]:
        page = old_pages.get(entry["board"])
        if page and entry["index_sha256"] == old["index_sha256"] and entry["board_sha256"] == page["sha256"]:
            latest.update({c: entry for c in entry["clip_ids"] if c in page["clip_ids"]})
    target_path = new_folder / "review_log.json"
    target = read(target_path)
    protected = {c for e in target["reviews"] for c in e["clip_ids"] if c in new_pages
                 and e["index_sha256"] == new["index_sha256"] and e["board_sha256"] == new_pages[c]["sha256"]}
    migrated = 0
    for c in sorted(eligible & latest.keys() & new_pages.keys() - protected):
        entry, page = latest[c], new_pages[c]
        target["reviews"].append({**entry, "board": page["id"], "board_sha256": page["sha256"], "clip_ids": [c],
            "index_sha256": new["index_sha256"], "migration_from": str(old_folder),
            "note": "Conservada SOLO la revisión de este clip equivalente; no se afirma haber visto sus nuevos vecinos. " + entry["note"],
            "origin_board_sha256": entry["board_sha256"], "render_equivalence_sha256": digest(proof_path) if proof_path else None,
            "migration_basis": basis})
        migrated += 1
    write(target_path, target)
    render_index(new_folder, new)
    print("CONTACT_RENDER_MIGRATION PASS clips=", migrated)
    return migrated


def migrate_identical_boards(old_folder, new_folder, previous_index=None, catalog_root=None, render_equivalence=None, same_renderer_clips=False):
    """Default: exact boards. Renderer changes require explicit per-clip proof."""
    old, new = read(old_folder / "boards.json"), read(new_folder / "boards.json")
    before, after = read(old_folder.parent / "captures.json"), read(new_folder.parent / "captures.json")
    if render_equivalence is not None or same_renderer_clips:
        return migrate_render_equivalent_clips(old_folder, new_folder, previous_index, catalog_root, render_equivalence)
    if before["renderer_sha256"] != after["renderer_sha256"]:
        raise ValueError("cannot migrate across changed data/renderer")
    if digest(old_folder.parent / "captures.json") != old["capture_manifest_sha256"] or digest(new_folder.parent / "captures.json") != new["capture_manifest_sha256"]:
        raise ValueError("capture evidence changed")
    unchanged = None
    if old["index_sha256"] != new["index_sha256"]:
        if previous_index is None:
            raise ValueError("cannot migrate across changed data/renderer without pinned per-clip proof")
        if before.get("index_sha256") != old["index_sha256"] or after.get("index_sha256") != new["index_sha256"]:
            raise ValueError("capture/catalog proof mismatch")
        catalog_root = catalog_root or GAME / ".godot/move_batch_catalog"
        old_index, old_clips = catalog_clip_contracts(previous_index, old["index_sha256"], catalog_root)
        new_index, new_clips = catalog_clip_contracts(catalog_root / "index.json", new["index_sha256"], catalog_root)
        if old_index["canonical_hashes_unchanged"] != new_index["canonical_hashes_unchanged"]:
            raise ValueError("canonical proof changed")
        old_images, new_images = ({row["id"]: row for row in manifest["clips"]} for manifest in (before, after))
        unchanged = {key for key in old_clips.keys() & new_clips.keys() & old_images.keys() & new_images.keys()
                     if old_clips[key] == new_clips[key]
                     and old_images[key]["sha256"] == new_images[key]["sha256"]
                     and old_images[key]["samples"] == new_images[key]["samples"]}
    old_pages = {p["id"]: p for p in old["pages"]}
    identical = {}
    for page in new["pages"]:
        previous = old_pages.get(page["id"])
        if (previous and previous["sha256"] == page["sha256"] and previous["clip_ids"] == page["clip_ids"]
                and (unchanged is None or set(page["clip_ids"]) <= unchanged)):
            if digest(old_folder / previous["path"]) != previous["sha256"] or digest(new_folder / page["path"]) != page["sha256"]:
                raise ValueError("board evidence changed")
            identical[page["id"]] = page
    source = read(old_folder / "review_log.json")
    target_path = new_folder / "review_log.json"
    target = read(target_path)
    valid_target = {p["sha256"] for p in new["pages"]}
    protected = {c for e in target["reviews"] if e["index_sha256"] == new["index_sha256"] and e["board_sha256"] in valid_target for c in e["clip_ids"]}
    migrated = set()
    for entry in source["reviews"]:
        page = identical.get(entry["board"])
        if not page or entry["board_sha256"] != page["sha256"] or entry["index_sha256"] != old["index_sha256"]:
            continue
        ids = [c for c in entry["clip_ids"] if c in page["clip_ids"] and c not in protected]
        if ids:
            target["reviews"].append({**entry, "clip_ids": ids, "index_sha256": new["index_sha256"], "migration_from": str(old_folder),
                                      "migration_basis": "Identical board/membership/renderer; identical index or pinned identical clip contracts, sheets and GPU samples"})
            migrated.update(ids)
    write(target_path, target)
    render_index(new_folder, new)
    print("CONTACT_REVIEW_MIGRATION PASS clips=", len(migrated), "identical_boards=", len(identical))
    return len(migrated)


def render_index(sheets, boards):
    ledger = read(sheets / "review_log.json")
    latest = {}
    valid = {page["sha256"] for page in boards["pages"]}
    for entry in ledger["reviews"]:
        if entry["board_sha256"] in valid and entry["index_sha256"] == boards["index_sha256"]:
            for clip in entry["clip_ids"]:
                latest[clip] = entry["status"]
    lines = ["# Revisión visual por lotes", "", f"{boards['families']} familias, lotes de hasta {boards['batch_size']}, dos lados, tres momentos por clip.", "",
             f"Clips con anotación vigente: {len(latest)}. El resto sigue PENDING; ver una muestra no aprueba la animación completa.", "",
             "Los primeros lotes priorizan los avisos automáticos. La cuarentena de conversión no se dibuja como si funcionara.", ""]
    lines += ["Laboratorio completo: incluye cuerpos/capas de la fuente. No representa una nueva integración en combate; sus cinco rutas revisadas no cambian.", "",
              "requires_external_presentation: fuente revisada pero necesita estado/presentacion del juego; una simulacion opcional NO cierra su integracion ni aprueba mecanicas.", "",
              f"Avisos previos de inmovilidad revisados automáticamente: {len(boards.get('sampling_rechecks', []))} clips muestran ahora píxeles distintos al elegir estados visibles diferentes. No es aprobación humana.", ""]
    for page in boards["pages"]:
        counts = collections.Counter(latest.get(clip, "pending") for clip in page["clip_ids"])
        lines.append(f"- [{page['id']}]({page['path']}) — " + ", ".join(f"{key}: {value}" for key, value in sorted(counts.items())))
    lines += ["", "## Observaciones registradas", ""]
    for entry in ledger["reviews"]:
        current = entry["board_sha256"] in valid and entry["index_sha256"] == boards["index_sha256"]
        prefix = "" if current else "HISTORICO / evidencia anterior: "
        lines += [f"- {prefix}{entry['board']}: {entry['status']} ({len(entry['clip_ids'])} clips): {entry['note']}"]
    (sheets / "index.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--batch-size", type=int, default=20)
    parser.add_argument("--pending-only", action="store_true", help="Compose pending families only after guarded migration; include paired side for context, no automatic review")
    parser.add_argument("--review-folder", type=Path)
    parser.add_argument("--migrate-from", type=Path)
    parser.add_argument("--previous-index", type=Path)
    parser.add_argument("--render-equivalence", type=Path)
    parser.add_argument("--same-renderer-clips", action="store_true", help="Regroup identical source/sheet/GPU clips only; requires matching renderer snapshots, never approves new neighbours")
    parser.add_argument("--board")
    parser.add_argument("--clip")
    parser.add_argument("--status", choices=sorted(STATUSES))
    parser.add_argument("--note", default="")
    args = parser.parse_args()
    if args.migrate_from:
        migrate_identical_boards(args.migrate_from, args.review_folder, args.previous_index, render_equivalence=args.render_equivalence, same_renderer_clips=args.same_renderer_clips)
    elif args.board:
        record(args.review_folder, args.board, args.status, args.note, args.clip)
    else:
        build(args.root, args.batch_size, args.pending_only)
