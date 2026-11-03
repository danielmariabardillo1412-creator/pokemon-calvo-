#!/usr/bin/env python3
"""Validador acumulativo de W04; comprueba fuentes reales sin simular Godot."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IDS = ("dawn_stone", "dusk_stone", "shiny_stone")
IDS_02 = ("sun_stone", "oval_stone", "black_augurite")
IDS_03 = ("dragon_scale", "dubious_disc", "electirizer")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ci", action="store_true")
    ap.parse_args()
    fixture = json.loads((ROOT / "tests/fixtures/parallel_items/w04_campaign_003.json").read_text())
    rows = list(csv.DictReader((ROOT / "docs/coordination/items_parallel_v1/reports/W04/CAMP_003_PROGRESO.csv").open()))
    scope = list(csv.DictReader((ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv").open(encoding="utf-8-sig")))
    script = (ROOT / "tests/gameplay/parallel_items_w04_campaign_003.gd").read_text()
    evolution = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text()
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text()
    checks = 0
    def check(cond, msg):
        nonlocal checks
        assert cond, msg
        checks += 1
    check(len(rows) == 3 and [r["bloque"] for r in rows] == ["01", "02", "03"], "progreso no incluye 01, 02 y 03")
    check(tuple(rows[2]["ids"].split(";")) == IDS_03, "IDs del bloque 03 cambiados")
    check(fixture["blocks"][2]["ids"] == list(IDS_03), "fixture bloque 03 inconsistente")
    check(tuple(rows[1]["ids"].split(";")) == IDS_02, "IDs del bloque 02 cambiados")
    check(fixture["blocks"][1]["ids"] == list(IDS_02), "fixture bloque 02 inconsistente")
    check(tuple(rows[0]["ids"].split(";")) == IDS, "IDs de cola cambiados")
    check(fixture["blocks"][0]["ids"] == list(IDS), "fixture inconsistente")
    for item in IDS + IDS_02 + IDS_03:
        matches = [r for r in scope if r["id"] == item]
        check(len(matches) == 1 and matches[0]["estado_contenido"] == "SELECCIONADO", item + " no seleccionado")
        check('"' + item + '"' in script, item + " no cubierto por Godot")
    for token in ("classify_record", "RUNTIME_SUPPORTED", "TRIGGER_USE_ITEM"):
        check(token in evolution, "contrato EvolutionSystem ausente: " + token)
    for token in ("func evolve(", "func evolution_options(", "replace_owned_same_identity", "_publish_bag"):
        check(token in service, "contrato FieldItemService ausente: " + token)
    for token in ("save_collection(", "repo.load(", "rechazo_ajeno", "rechazo_destino", "sin_segundo_consumo"):
        check(token in script, "escenario Godot ausente: " + token)
    for token in ("primer_dependiente", "intercambio_no_degradado_a_uso_directo", "opciones_condicionadas.is_empty()"):
        check(token in script, "falta asercion de dependencia de intercambio: " + token)
    print(f"CAMP003_W04_PY PASS blocks=3 checks={checks}")

if __name__ == "__main__":
    main()
