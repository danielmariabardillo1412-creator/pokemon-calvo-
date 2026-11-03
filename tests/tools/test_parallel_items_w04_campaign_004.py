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
ITEMS_02 = ("love_sweet", "ribbon_sweet", "star_sweet")
RAW_IDS_02 = (1168, 1173, 1172)
ITEMS_03 = ("strawberry_sweet", "whipped_dream", "leaders_crest")


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
    check(len(done) == 3 and [r["bloque"] for r in done] == ["01", "02", "03"], "progreso de bloques 01 a 03")
    check(done[2]["ids"] == ";".join(ITEMS_03), "IDs de progreso 03")
    check(queue[2]["ids"] == ";".join(ITEMS_03), "reserva 03 distinta")
    check(done[1]["ids"] == ";".join(ITEMS_02), "IDs de progreso 02")
    check(queue[1]["ids"] == ";".join(ITEMS_02), "reserva 02 distinta")
    check(done[0]["ids"] == ";".join(ITEMS), "IDs de progreso")
    check(queue[0]["ids"] == ";".join(ITEMS), "reserva oficial distinta")
    check(len(fixture["blocks"]) == 3 and [v["block"] for v in fixture["blocks"]] == ["01", "02", "03"], "fixture acumulativo 01 a 03")
    check(fixture["blocks"][2]["ids"] == list(ITEMS_03), "fixture IDs 03")
    check(fixture["blocks"][1]["ids"] == list(ITEMS_02), "fixture IDs 02")
    check(fixture["blocks"][1]["canonical_trigger"] == "spin", "spin del bloque 02 no consta")
    check(fixture["blocks"][0]["ids"] == list(ITEMS), "fixture IDs 01")
    check(fixture["blocks"][0]["canonical_trigger"] == "spin", "no inventar trigger")
    for item, raw_id in zip(ITEMS + ITEMS_02, RAW_IDS + RAW_IDS_02):
        entries = [entry for entry in selected if entry["id"] == item]
        check(len(entries) == 1 and entries[0]["familia"] == "EVOLUTION" and entries[0]["estado_contenido"] == "SELECCIONADO", item + " fuera de selección")
        raw = json.loads((ROOT / f"data/api/v2/item/{raw_id}/index.json").read_text())
        check(raw["name"] == item.replace("_", "-") and raw["category"]["name"] == "evolution", item + " fuente PokeAPI incorrecta")
        en = [entry["text"].lower() for entry in raw["flavor_text_entries"] if entry["language"]["name"] == "en"]
        check(any("milcery" in text and "holds" in text for text in en), item + " contexto equipado no documentado")
        check('"' + item + '"' in runner, item + " sin runner")
    for item, familia in zip(ITEMS_03, ("EVOLUTION", "EVOLUTION", "FOOD_OR_PICNIC_ACTIVITY")):
        entries = [entry for entry in selected if entry["id"] == item]
        check(len(entries) == 1 and entries[0]["familia"] == familia and entries[0]["estado_contenido"] == "SELECCIONADO", item + " selección/categoría no respetada")
        check(("\"" + item + "\"") in runner, item + " sin cobertura Godot")
    strawberry = json.loads((ROOT / "data/api/v2/item/1167/index.json").read_text())
    check(strawberry["name"] == "strawberry-sweet" and strawberry["category"]["name"] == "evolution", "fuente de strawberry_sweet")
    check(any("milcery" in entry["text"].lower() and "spin" in entry["text"].lower() for entry in strawberry["flavor_text_entries"] if entry["language"]["name"] == "en"), "falta descripción canónica de giro")
    scope_notes = (ROOT / "docs/current/ITEM_SCOPE_V25.md").read_text()
    check("whipped_dream" in scope_notes and "swirlix" in scope_notes.lower(), "Dulce de Nata sin referencia de especie")
    content_notes = (ROOT / "docs/current/ITEM_CONTENT_SCOPE.md").read_text()
    check("leaders_crest" in content_notes, "Distintivo de Líder sin nota de categoría")
    for term in ("UNSUPPORTED_TRIGGERS", '&"spin"', "func classify_record(", "RUNTIME_SUPPORTED", "UNSUPPORTED"):
        check(term in engine, "no existe contrato en EvolutionSystem: " + term)
    for term in ("func configure(", "func evolution_options(", "func evolve(", "func use_item(", "func equip(", "func unequip(", "holdable("):
        check(term in service, "no existe contrato en FieldItemService: " + term)
    for term in ("catalogo.species(&\"milcery\")", "catalogo.species(&\"eevee\")", "classify_record(", "UNSUPPORTED", "sin_opcion_directa",
                 "uso_directo_rechazado_sin_consumo", "evolucion_forzada_rechazada", "equipar_no_simula_giro", "_persistencia(",
                 "save_collection(", "repo.load(", "schema_version == 2", "positivo_consumo_unico", "atributos_conservados"):
        check(term in runner, "no se ha escrito aserción comprobable: " + term)
    check("const BLOQUE_02 :=" in runner and "BLOQUE_01 + BLOQUE_02" in runner, "runner no ejecuta ambos bloques")
    for token in ("const BLOQUE_03 :=", "BLOQUE_03[0]", "BLOQUE_03[1]", "BLOQUE_03[2]", "three_defeated_bisharp", "destino_objetivo", "mecanica_condicionada_no_degradada", "_negativo(catalogo, item, origen, destino)", "intercambio_equipado_o_derrotas_requieren_contexto"):
        check(token in runner, "no hay escenario de bloque 03: " + token)
    check('&"three_defeated_bisharp"' in engine, "EvolutionSystem no reconoce disparador de Bisharp")
    check((ROOT / "tests/gameplay/parallel_items_w04_campaign_003.gd").exists(), "regresión CAMP003 ausente")
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_001.py").exists(), "regresión CAMP001 ausente")
    print(f"CAMP004_W04_PY PASS blocks=3 checks={checks}")


if __name__ == "__main__":
    main()
