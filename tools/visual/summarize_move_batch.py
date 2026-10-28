"""Collapse thousands of clips into actionable groups; reject stale QA evidence."""
import argparse
import collections
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]


def summarize(index_path, audit_path, output):
    index = json.loads(index_path.read_text(encoding="utf-8"))
    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    expected = hashlib.sha256(index_path.read_bytes()).hexdigest()
    if audit["index_sha256"] != expected or audit["failures"] or len(audit["clips"]) != index["converted_clips"]:
        raise ValueError("Stale/incomplete/failed audit: refusing to certify or summarize as passed")
    groups = collections.defaultdict(set)
    notes = collections.defaultdict(set)
    for move in index["moves"]:
        if move["status"] == "quarantined":
            groups["conversion/" + move["reason"].split(":")[0]].add(move["move_id"])
        if move.get("primary_source_issue"):
            groups["native_gap_covered_by_equivalent/" + move["primary_source_issue"].split(":")[0]].add(move["move_id"])
        for flag in move.get("flags", []):
            notes[flag].add(move["move_id"])
    for clip in audit["clips"]:
        move = clip["id"].split("/")[0]
        for warning in clip["warnings"]:
            groups["visual/" + warning.split("/")[0]].add(move)
        if "static_source" in clip["source_flags"]:
            groups["visual/static_source"].add(move)
    visual = set().union(*(ids for reason, ids in groups.items() if reason.startswith("visual/")))
    converted = {r["move_id"] for r in index["moves"] if r["status"] == "converted_lab_only"}
    queue = [{"group": reason, "move_count": len(ids), "move_ids": sorted(ids),
              "meaning": "Review trigger, not proof of bad art" if reason.startswith("visual/") else
                         "Renderable explicit equivalent; original source gap remains, not a native repair" if reason.startswith("native_gap_covered_by_equivalent/") else
                         "Not converted; requires a shared format/resource fix"}
             for reason, ids in sorted(groups.items())]
    report = {"index_sha256": expected, "gpu": audit["gpu"], "checks": audit["checks"], "frames": audit["frames"],
              "converted_moves": len(converted), "converted_clips": index["converted_clips"],
              "quarantined_moves": index["catalog_moves"] - len(converted),
              "explicit_visual_equivalent_moves": index.get("visual_equivalent_moves", 0),
              "explicit_art_equivalent_moves": index.get("art_equivalent_moves", 0),
              "native_source_gaps_retained": len(index.get("primary_source_gaps_retained", [])),
              "converted_moves_with_visual_triggers": len(visual), "converted_without_visual_triggers": len(converted - visual),
              "aesthetic_or_mechanical_approval": False, "battle_routes_added": 0, "groups": queue,
              "informational_flags": {flag: sorted(ids) for flag, ids in sorted(notes.items())}}
    output.mkdir(exist_ok=True, parents=True)
    (output / "review_queue.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["# Barrido automático de animaciones", "",
             f"Catálogo: {index['catalog_moves']} movimientos. Convertidos para laboratorio: {len(converted)} ({index['converted_clips']} clips). Cuarentena: {report['quarantined_moves']}.", "",
             f"Equivalentes explícitos: {report['explicit_visual_equivalent_moves']}; huecos de su fuente original conservados: {report['native_source_gaps_retained']}. No son restauraciones nativas.", "",
             f"Selecciones artísticas explícitas adicionales: {report['explicit_art_equivalent_moves']}; sustituyen referencias reproducibles rechazadas por arte, no reparan atlas.", "",
             f"Prueba {'GPU + geometría' if audit['gpu'] else 'solo geometría headless'}: {audit['checks']:,} comprobaciones, {audit['frames']:,} fotogramas/lado/tamaño; cero fallos fatales.", "",
             f"Convertidos con avisos visuales: {len(visual)}; sin estos avisos: {len(converted - visual)}. No equivale a aprobación artística o mecánica.", "",
             "Nuevas conexiones al combate: 0. El catálogo masivo se abre en el laboratorio, no altera daño, estados, aprendizaje, RNG ni contratos de soporte.", "",
             "Los avisos de borde pueden ser intencionados (barridos/mosaicos); las muestras GPU iguales pueden omitir un efecto breve. Se revisan los grupos, no se descartan automáticamente.", "",
             "## Grupos de revisión", ""]
    for group in queue:
        lines += [f"### {group['group']} — {group['move_count']} movimientos", "", ", ".join(group["move_ids"]), ""]
    lines += ["## Procedencia", "", f"Índice SHA-256: `{expected}`.", "",
              "Gen 9 Move Animation Project y exports de Toxillian ya descargados. Créditos/condiciones en docs/project_book/VISUAL_CATALOG.md; no autorización para redistribuir.", ""]
    (output / "summary.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k not in ("groups", "informational_flags")}, ensure_ascii=False))
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", type=Path, default=GAME / ".godot/move_batch_catalog/index.json")
    parser.add_argument("--audit", type=Path, default=GAME / ".godot/move_batch_checks/gpu_result.json")
    parser.add_argument("--output", type=Path, default=GAME / ".godot/move_batch_checks")
    args = parser.parse_args()
    summarize(args.index, args.audit, args.output)
