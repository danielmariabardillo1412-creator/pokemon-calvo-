#!/usr/bin/env python3
"""IA4/W04 CAMP004: valida fuentes reales y contratos de la campaña; no simula Godot."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
ITEMS = ("berry_sweet", "clover_sweet", "flower_sweet")
RAW_IDS = (1169, 1170, 1171)


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ci", action="store_true")
    ap.parse_args()

    fixture = json.loads((ROOT / "tests/fixtures/parallel_items/w04_campaign_004.json").read_text())
    queue = rows(BASE / "CAMPAIGN_004_W04_QUEUE_APPROVED.csv")
    done = rows(BASE / "reports/W04/CAMP_004_PROGRESO.csv")
    selected = rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")
    runner = (ROOT / "tests/gameplay/parallel_items_w04_campaign_004.gd").read_text()
    engine = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text()
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text()
    checks = 0

    def check(value, message):
        nonlocal checks
        if not value:
            raise AssertionError(message)
        checks += 1

    check(fixture["worker"] == "W04" and fixture["campaign"] == "CAMP_004", "identidad/fixture")
    check(len(queue) == 10, "cola de diez bloques")
    check(len(done) == 1 and done[0]["bloque"] == "01", "progreso bloque 01")
    check(done[0]["ids"] == ";".join(ITEMS), "IDs de progreso")
    check(queue[0]["ids"] == ";".join(ITEMS), "reserva oficial distinta")
    check(len(fixture["blocks"]) == 1 and fixture["blocks"][0]["block"] == "01", "fixture de un bloque")
    check(fixture["blocks"][0]["ids"] == list(ITEMS), "fixture IDs 01")
    check(fixture["blocks"][0]["canonical_trigger"] == "spin", "no inventar trigger")
    for item, raw_id in zip(ITEMS, RAW_IDS):
        entries = [entry for entry in selected if entry["id"] == item]
        check(len(entries) == 1 and entries[0]["familia"] == "EVOLUTION" and entries[0]["estado_contenido"] == "SELECCIONADO", item + " fuera de selección")
        raw = json.loads((ROOT / f"data/api/v2/item/{raw_id}/index.json").read_text())
        check(raw["name"] == item.replace("_", "-") and raw["category"]["name"] == "evolution", item + " fuente PokeAPI incorrecta")
        en = [entry["text"].lower() for entry in raw["flavor_text_entries"] if entry["language"]["name"] == "en"]
        check(any("milcery" in text and "holds" in text for text in en), item + " contexto equipado no documentado")
        check('"' + item + '"' in runner, item + " sin runner")
    for term in ("UNSUPPORTED_TRIGGERS", '&"spin"', "func classify_record(", "RUNTIME_SUPPORTED", "UNSUPPORTED"):
        check(term in engine, "no existe contrato en EvolutionSystem: " + term)
    for term in ("func configure(", "func evolution_options(", "func evolve(", "func use_item(", "func equip(", "func unequip(", "holdable("):
        check(term in service, "no existe contrato en FieldItemService: " + term)
    for term in ("catalogo.species(&\"milcery\")", "catalogo.species(&\"eevee\")", "classify_record(", "UNSUPPORTED", "sin_opcion_directa",
                 "uso_directo_rechazado_sin_consumo", "evolucion_forzada_rechazada", "equipar_no_simula_giro", "_persistencia(",
                 "save_collection(", "repo.load(", "schema_version == 2", "positivo_consumo_unico", "atributos_conservados"):
        check(term in runner, "no se ha escrito aserción comprobable: " + term)
    check((ROOT / "tests/gameplay/parallel_items_w04_campaign_003.gd").exists(), "regresión CAMP003 ausente")
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_001.py").exists(), "regresión CAMP001 ausente")
    print(f"CAMP004_W04_PY PASS blocks=1 checks={checks}")


if __name__ == "__main__":
    main()
