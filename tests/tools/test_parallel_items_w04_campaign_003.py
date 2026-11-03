#!/usr/bin/env python3
"""Validador acumulativo de W04; comprueba fuentes reales sin simular Godot."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IDS = ("dawn_stone", "dusk_stone", "shiny_stone")

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
    check(len(rows) == 1 and rows[0]["bloque"] == "01", "progreso no es bloque 01")
    check(tuple(rows[0]["ids"].split(";")) == IDS, "IDs de cola cambiados")
    check(fixture["blocks"][0]["ids"] == list(IDS), "fixture inconsistente")
    for item in IDS:
        matches = [r for r in scope if r["id"] == item]
        check(len(matches) == 1 and matches[0]["estado_contenido"] == "SELECCIONADO", item + " no seleccionado")
        check('"' + item + '"' in script, item + " no cubierto por Godot")
    for token in ("classify_record", "RUNTIME_SUPPORTED", "TRIGGER_USE_ITEM"):
        check(token in evolution, "contrato EvolutionSystem ausente: " + token)
    for token in ("func evolve(", "func evolution_options(", "replace_owned_same_identity", "_publish_bag"):
        check(token in service, "contrato FieldItemService ausente: " + token)
    for token in ("save_collection(", "repo.load(", "rechazo_ajeno", "rechazo_destino", "sin_segundo_consumo"):
        check(token in script, "escenario Godot ausente: " + token)
    print(f"CAMP003_W04_PY PASS blocks=1 checks={checks}")

if __name__ == "__main__":
    main()
