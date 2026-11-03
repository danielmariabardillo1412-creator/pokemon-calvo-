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
ITEMS_04 = ("adamant_crystal", "blue_orb", "catching_charm")
ITEMS_05 = ("dna_splicers", "exp_charm", "gracidea")
ITEMS_06 = ("griseous_core", "lustrous_globe", "meteorite")
ITEMS_07 = ("rage_candy_bar", "red_orb", "reins_of_unity")
ITEMS_08 = ("reveal_glass", "rotom_catalog", "zygarde_cube")


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
    check(len(done) == 8 and [r["bloque"] for r in done] == ["01", "02", "03", "04", "05", "06", "07", "08"], "progreso de bloques 01 a 08")
    check(done[7]["ids"] == ";".join(ITEMS_08), "IDs de progreso 08")
    check(queue[7]["ids"] == ";".join(ITEMS_08), "reserva 08 distinta")
    check(done[6]["ids"] == ";".join(ITEMS_07), "IDs de progreso 07")
    check(queue[6]["ids"] == ";".join(ITEMS_07), "reserva 07 distinta")
    check(done[5]["ids"] == ";".join(ITEMS_06), "IDs progreso 06")
    check(queue[5]["ids"] == ";".join(ITEMS_06), "reserva 06 distinta")
    check(done[4]["ids"] == ";".join(ITEMS_05), "IDs de progreso 05")
    check(queue[4]["ids"] == ";".join(ITEMS_05), "reserva 05 distinta")
    check(done[3]["ids"] == ";".join(ITEMS_04), "IDs de progreso 04")
    check(queue[3]["ids"] == ";".join(ITEMS_04), "reserva 04 distinta")
    check(done[2]["ids"] == ";".join(ITEMS_03), "IDs de progreso 03")
    check(queue[2]["ids"] == ";".join(ITEMS_03), "reserva 03 distinta")
    check(done[1]["ids"] == ";".join(ITEMS_02), "IDs de progreso 02")
    check(queue[1]["ids"] == ";".join(ITEMS_02), "reserva 02 distinta")
    check(done[0]["ids"] == ";".join(ITEMS), "IDs de progreso")
    check(queue[0]["ids"] == ";".join(ITEMS), "reserva oficial distinta")
    check(len(fixture["blocks"]) == 8 and [v["block"] for v in fixture["blocks"]] == ["01", "02", "03", "04", "05", "06", "07", "08"], "fixture acumulativo 01 a 08")
    check(fixture["blocks"][7]["ids"] == list(ITEMS_08), "fixture IDs 08")
    check(fixture["blocks"][7]["family"] == "STORY_KEY_OR_FORM_REVIEW", "familia bloque08 cambiada")
    check(fixture["blocks"][6]["ids"] == list(ITEMS_07), "fixture IDs 07")
    check(fixture["blocks"][6]["family"] == "STORY_KEY_OR_FORM_REVIEW", "familia bloque07 cambiada")
    check(fixture["blocks"][5]["ids"] == list(ITEMS_06), "fixture IDs 06")
    check(fixture["blocks"][5]["family"] == "STORY_KEY_OR_FORM_REVIEW", "familia bloque 06 cambiada")
    check(fixture["blocks"][4]["ids"] == list(ITEMS_05), "fixture IDs 05")
    check(fixture["blocks"][4]["family"] == "STORY_KEY_OR_FORM_REVIEW", "familia 05 no conservada")
    check(fixture["blocks"][3]["ids"] == list(ITEMS_04), "fixture IDs 04")
    check(fixture["blocks"][3]["family"] == "STORY_KEY_OR_FORM_REVIEW", "categoría del encargo 04")
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
    for item in ITEMS_04:
        found = [entry for entry in selected if entry["id"] == item]
        check(len(found) == 1 and found[0]["estado_contenido"] == "SELECCIONADO" and found[0]["familia"] == "STORY_KEY_OR_FORM_REVIEW", item + " selección original")
        check(('"' + item + '"') in runner, item + " no cubierto por Godot")
    held = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text())["holdable_ids"]
    check("adamant_crystal" in held and "blue_orb" in held and "catching_charm" not in held, "contrato real de equipamiento cambiado")
    source_fields = {row["id"]: row for row in rows(ROOT / "docs/current/ITEM_FIELD_V8.csv.txt")}
    for item in ITEMS_04:
        check(source_fields[item]["field_use_status"] == "STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED", item + " auditoría de formas")
    check(source_fields["adamant_crystal"]["equipment_transfer"] == "VERIFIED", "adamant equipamiento")
    check(source_fields["blue_orb"]["equipment_transfer"] == "VERIFIED", "blue orb equipamiento")
    check(source_fields["catching_charm"]["equipment_transfer"] == "NOT_CERTIFIED", "captura fuera W04")
    for item in ITEMS_05:
        found = [entry for entry in selected if entry["id"] == item]
        check(len(found) == 1 and found[0]["estado_contenido"] == "SELECCIONADO" and found[0]["familia"] == "STORY_KEY_OR_FORM_REVIEW", item + " seleccion original")
        check(('"' + item + '"') in runner, item + " no cubierto por Godot")
        check(item not in held, item + " no debería ser equipable en el perfil actual")
        check(source_fields[item]["field_use_status"] == "STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED", item + " contexto especial no implementado")
        check(source_fields[item]["equipment_transfer"] == "NOT_CERTIFIED", item + " equipamiento erroneamente certificado")
    inventory_rows = {row["id"]: row for row in rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    for item in ITEMS_05:
        check(inventory_rows[item]["connection"] == "DATA_ONLY" and inventory_rows[item]["native_entry"] == "False", item + " sin runtime documentado")
    for item in ITEMS_06:
        found = [entry for entry in selected if entry["id"] == item]
        check(len(found) == 1 and found[0]["estado_contenido"] == "SELECCIONADO" and found[0]["familia"] == "STORY_KEY_OR_FORM_REVIEW", item + " selección/categoría")
        check(('"' + item + '"') in runner, item + " ausente del runner")
        check(source_fields[item]["field_use_status"] == "STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED", item + " contexto de forma no documentado")
    for item in ITEMS_06[:2]:
        check(item in held, item + " debe ser equipable")
        check(source_fields[item]["equipment_transfer"] == "VERIFIED", item + " equipamiento de fuente no verificado")
        check(inventory_rows[item]["connection"] == "NATIVE_ENTRY_REQUIRES_EFFECT_CASE", item + " entrada nativa pendiente")
        check(inventory_rows[item]["native_entry"] == "True", item + " entrada nativa no presente")
    check("meteorite" not in held, "Meteorite no debe ser equipable")
    check(source_fields["meteorite"]["equipment_transfer"] == "NOT_CERTIFIED", "Meteorite equipamiento no certificado")
    check(inventory_rows["meteorite"]["connection"] == "DATA_ONLY" and inventory_rows["meteorite"]["native_entry"] == "False", "Meteorite sin efecto de forma")
    for item in ITEMS_07:
        found = [entry for entry in selected if entry["id"] == item]
        check(len(found) == 1 and found[0]["estado_contenido"] == "SELECCIONADO" and found[0]["familia"] == "STORY_KEY_OR_FORM_REVIEW", item + " alcance original")
        check(('"' + item + '"') in runner, item + " sin runner Godot")
    check("red_orb" in held and "rage_candy_bar" not in held and "reins_of_unity" not in held, "perfil holdable bloque07 distinto")
    check(source_fields["red_orb"]["equipment_transfer"] == "VERIFIED", "Orbe Rojo equipamiento sin certificar")
    check(source_fields["rage_candy_bar"]["field_use_status"] == "MODERN_FIELD_RECOVERY_OWNERSHIP_CONSUMPTION_SAVE_AND_NATIVE_HANDOFF_VERIFIED", "Caramelo Furia requiere curación real")
    check(source_fields["reins_of_unity"]["equipment_transfer"] == "NOT_CERTIFIED", "Riendas no equipables")
    check(inventory_rows["red_orb"]["connection"] == "NATIVE_ENTRY_REQUIRES_EFFECT_CASE", "Orbe Rojo pendiente de efecto")
    check(inventory_rows["reins_of_unity"]["connection"] == "DATA_ONLY", "Riendas requieren fusión real")
    imported = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text())["items"]
    check(imported["rage_candy_bar"]["consume"] is True, "Caramelo Furia consume al curar")
    check(imported["rage_candy_bar"]["effect"]["cure"] == "all", "Caramelo Furia cura estados")
    check(imported["rage_candy_bar"]["effect"]["confusion"] is True, "Caramelo Furia quita confusión")
    field_effects = (ROOT / "modules/inventory/field_item_effects.gd").read_text()
    check("static func supports(" in field_effects and "_recovery.has(String(item_id))" in field_effects, "medicina no conectada al motor")
    for item in ITEMS_08:
        found = [entry for entry in selected if entry["id"] == item]
        check(len(found) == 1 and found[0]["estado_contenido"] == "SELECCIONADO" and found[0]["familia"] == "STORY_KEY_OR_FORM_REVIEW", item + " seleccion original")
        check(item not in held, item + " no figura como equipable en perfil actual")
        check(source_fields[item]["field_use_status"] == "STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED", item + " sin contrato especial documentado")
        check(source_fields[item]["equipment_transfer"] == "NOT_CERTIFIED", item + " equipamiento no certificado")
        check(inventory_rows[item]["connection"] == "DATA_ONLY" and inventory_rows[item]["native_entry"] == "False", item + " no es efecto directo nativo")
        check(('"' + item + '"') in runner, item + " sin coverage en Godot")
    check("missing_description" in inventory_rows["rotom_catalog"]["flags"], "falta descripción del Catalogo Rotom no consignada")
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
    for token in ("const BLOQUE_04 :=", "func _auditar_contexto_04(", "_auditar_contexto_04(catalogo, item, origen)", "sin_transformacion_por_uso", "equipar_no_activa_forma_o_reversion", "amuleto_no_es_equipable", "captura_pertenece_W03_no_certificada", "estado_forma_final_intacto", "_persistencia(pc, item"):
        check(token in runner, "no se ejecuta negativo real del bloque 04: " + token)
    for token in ("const BLOQUE_05 :=", "func _auditar_contexto_05(", "fusion_kyurem_no_implementada", "bono_experiencia_fuera_del_servicio_W04", "forma_shaymin_necesita_contexto", "no_equipable", "uso_sin_contrato_rechazado", "forma_y_estado_inalterados", "propietario_invalido_rechazado", "_persistencia(pc, item"):
        check(token in runner, "negativo del bloque 05 no cubierto: " + token)
    for token in ("const BLOQUE_06 :=", "giratina", "palkia", "deoxys", "forma_deoxys_meteorito_sin_servicio", "equipamiento_verificado_sin_ruta_forma_certificada", "_auditar_contexto_04(catalogo, item, origen)", "_auditar_contexto_05(catalogo, item, origen)", "ruta_forma_no_degradada", "_persistencia(pc, item"):
        check(token in runner, "escenario 06 ausente: " + token)
    for token in ("const BLOQUE_07 :=", "func _recuperacion_07(", "sano_sin_consumo", "curacion_consumo_unico", "cura_sin_evolucion", "sin_segunda_consumicion", "orbe_equipable_primal_no_certificado", "union_calyrex_fusion_no_conectada", "_auditar_contexto_04(catalogo, item, &\"groudon\")", "_auditar_contexto_05(catalogo, item, &\"calyrex\")", "CAMP004_W04_GODOT PASS blocks=8 checks="):
        check(token in runner, "bloque07 sin escenario real: " + token)
    for token in ("const BLOQUE_08 :=", "tornadus", "rotom", "zygarde", "tornadus_trio_cambio_forma_no_conectado", "rotom_cambio_electrodomestico_no_conectado", "zygarde_celulas_y_formas_no_conectadas", "_auditar_contexto_05(catalogo, item, origen)", "_auditar_contexto_05(catalogo, item, &\"eevee\")", "ruta_forma_08_no_degradada", "CAMP004_W04_GODOT PASS blocks=8 checks="):
        check(token in runner, "falta escenario real bloque08: " + token)
    check((ROOT / "tests/gameplay/parallel_items_w04_campaign_003.gd").exists(), "regresión CAMP003 ausente")
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_001.py").exists(), "regresión CAMP001 ausente")
    print(f"CAMP004_W04_PY PASS blocks=8 checks={checks}")


if __name__ == "__main__":
    main()
