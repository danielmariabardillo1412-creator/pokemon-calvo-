#!/usr/bin/env python3
"""W05 CAMP004: contrato acumulativo REAL contra el catálogo versionado.
Solo valida datos, versiones, política y learnset; Godot prueba enseñanza/SaveV2.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w05_campaign_004.json"
PROGRESS = BASE / "reports/W05/CAMP_004_PROGRESO.csv"
QUEUE = BASE / "CAMPAIGN_004_W05_QUEUE_APPROVED.csv"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
NORMALIZED = ROOT / "data/normalized/pokemon_api.json"
POLICY = ROOT / "config/randomlock_content_v1.json"
OLD = {"tm01", "tm02", "tm03", "tm04", "tm05", "tm06", "tm07", "tm08", "tm09", "tm10", "tm11", "tm12", "tm13", "tm14", "tm15", "tm16", "tm17", "tm18", "tm19", "tm20", "tm21", "tm22", "tm23", "tm24", "tm25", "tm26", "tm27", "tm28", "tm29", "tm30", "tm31", "tm32", "tm33", "tm34", "tm35", "tm36", "tm37", "tm38", "tm39", "tm40", "tm41", "tm42", "tm43", "tm44", "tm45", "tm46", "tm47", "tm48", "tm49", "tm50", "tm51", "tm52", "tm53", "tm54", "tm55", "tm56", "tm57", "tm58", "tm59", "tm60", "tm61", "tm62", "tm63", "tm64", "tm65", "tm66", "tm67", "tm68", "tm69", "tm70", "tm71", "tm72", "tm73", "tm74", "tm75", "tm76", "tm77", "tm78", "tm79", "tm80", "tm81"}


def load_json(p: Path) -> dict:
    with p.open(encoding="utf-8-sig") as f:
        v = json.load(f)
    if not isinstance(v, dict):
        raise ValueError(f"JSON no es objeto: {p}")
    return v


def load_csv(p: Path) -> list[dict]:
    with p.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def validate() -> tuple[int, int, list[dict]]:
    q = [r for r in load_csv(QUEUE) if r["trabajadora"] == "W05"]
    progress = load_csv(PROGRESS)
    fixture = load_json(FIXTURE)
    profile = load_json(PROFILE)
    dataset = load_json(NORMALIZED)
    policy = load_json(POLICY)
    if len(q) != 10 or [r["bloque"] for r in q] != [f"{n:02d}" for n in range(1, 11)]:
        raise ValueError("La cola W05 no contiene exactamente diez filas ordenadas")
    if not 1 <= len(progress) <= 10 or len(progress) != len(fixture.get("blocks", [])):
        raise ValueError("Debe existir un bloque de fixture por cada bloque del CSV de progreso")
    if fixture.get("schema_version") != 1 or fixture.get("campaign") != "CAMP_004_W05":
        raise ValueError("Fixture ajeno o formato incorrecto")
    if fixture.get("active_version") != "scarlet-violet":
        raise ValueError("Versión activa de fixture inválida")
    if profile.get("active_machine_version") != "scarlet-violet":
        raise ValueError("Se intentó activar una máquina de otra versión")
    if profile.get("profile_id") != "calvo_item_connections_v1":
        raise ValueError("Perfil canónico inesperado")
    moves = dataset.get("moves", {})
    species = dataset.get("species", {})
    items = dataset.get("items", {})
    mapping = profile.get("machine_rows", {})
    if not all(isinstance(x, dict) and x for x in (moves, species, items, mapping)):
        raise ValueError("Fuente canónica incompleta")
    banned_moves = {
        item_id
        for group in policy.get("move_exclusions", [])
        for item_id in group.get("ids", [])
    }
    banned_moves.update(policy.get("z_moves", {}).get("ids", []))
    banned_moves.update(policy.get("protected_max_move_ids", []))
    banned_species = set(policy.get("excluded_species_ids", []))
    # Índice inverso de learnsets reales, sin presuponer una especie compatible.
    eligible: dict[str, list[str]] = {}
    for species_id, entry in species.items():
        if species_id in banned_species or not isinstance(entry, dict):
            continue
        for le in entry.get("learnset", []):
            if (isinstance(le, dict) and le.get("method") == "machine"
                    and le.get("version_group") == "scarlet-violet"
                    and isinstance(le.get("move_id"), str)):
                eligible.setdefault(le["move_id"], []).append(species_id)
    checks = 0
    receipts = []
    global_ids: set[str] = set()
    for n, (actual, authorized, group) in enumerate(
            zip(progress, q[:len(progress)], fixture["blocks"], strict=True), 1):
        block = f"{n:02d}"
        ids = authorized["ids"].split(";")
        if len(ids) != 6 or len(set(ids)) != 6:
            raise ValueError("Cola W05 alterada: se exigen seis máquinas distintas")
        if actual["bloque"] != block or actual["ids"] != authorized["ids"]:
            raise ValueError("Progreso distinto a la cola autorizada " + block)
        if group.get("block") != block or not isinstance(group.get("items"), list):
            raise ValueError("Fixture incompleto en " + block)
        cases = group["items"]
        if [x.get("item_id") for x in cases] != ids:
            raise ValueError("Fixture no coincide exactamente con IDs del bloque " + block)
        for x in cases:
            item_id = x["item_id"]
            if item_id in global_ids or item_id in OLD:
                raise ValueError("ID repetido o ya probado: " + item_id)
            global_ids.add(item_id)
            if item_id not in items or item_id not in mapping:
                raise ValueError("Máquina ausente de fuente: " + item_id)
            move_id = mapping[item_id].get("scarlet-violet", "")
            if not move_id or move_id != x.get("move_id") or move_id not in moves:
                raise ValueError("Mapeo SV desviado " + item_id)
            if move_id in banned_moves:
                raise ValueError("Movimiento prohibido por política " + item_id)
            meta = moves[move_id]
            if (meta.get("damage_class") not in {"physical", "special", "status"}
                    or not meta.get("type_id")
                    or type(meta.get("pp")) is not int or meta["pp"] <= 0):
                raise ValueError("Datos PP/tipo/clase inválidos " + item_id)
            species_found = sorted(set(eligible.get(move_id, [])))
            if not species_found:
                raise ValueError("SIN_LEARNSET: no existe especie SV compatible para " + item_id)
            receipts.append({
                "block": block, "item_id": item_id, "move_id": move_id,
                "species_id": species_found[0], "pp": meta["pp"],
                "type_id": meta["type_id"],
                "compatibility": "LEARNSET_SV_STATIC_ONLY_NOT_GODOT",
            })
            checks += 9  # fuente, unicidad, versión, política, metadatos y learnset
        checks += 4  # bloque, reserva, orden, cuota
    if len(receipts) != len(progress) * 6:
        raise ValueError("Cuota de seis por bloque incompleta")
    return len(progress), checks, receipts


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--ci", action="store_true")
    p.add_argument("--report", action="store_true")
    args = p.parse_args()
    try:
        blocks, checks, receipts = validate()
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as e:
        print("CAMP004_W05_PY FAIL: " + str(e), file=sys.stderr)
        return 1
    if args.report:
        print(json.dumps({
            "status": "CONTRATO_ESTATICO_NO_GODOT", "blocks": blocks,
            "checks": checks, "sample": receipts}, indent=2, ensure_ascii=False))
    if args.ci:
        print(f"CAMP004_W05_PY PASS blocks={blocks} checks={checks}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
