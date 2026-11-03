#!/usr/bin/env python3
"""IA3/W03 CAMP004: auditor acumulativo; no confundir rechazo con efecto funcional."""
from __future__ import annotations
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w03_campaign_004.json"
RUNNER = ROOT / "tests/gameplay/parallel_items_w03_campaign_004.gd"

def rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ci", action="store_true")
    ap.parse_args()
    checks = 0
    def test(ok: bool, msg: str) -> None:
        nonlocal checks
        checks += 1
        if not ok:
            raise AssertionError(msg)
    try:
        fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
        done = rows(BASE / "reports/W03/CAMP_004_PROGRESO.csv")
        queue = rows(BASE / "CAMPAIGN_004_W03_QUEUE_APPROVED.csv")
        runner = RUNNER.read_text(encoding="utf-8")
        rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
        basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(encoding="utf-8")
        effects = (ROOT / "modules/capture/capture_context_ball_effects.gd").read_text(encoding="utf-8")
        context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(encoding="utf-8")
        engine = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
        inventory = (ROOT / "modules/inventory/capture_inventory_service.gd").read_text(encoding="utf-8")
        test(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_004"
             and fixture["worker"] == "W03", "Identidad fixture inválida")
        test(len(queue) == 10 and 1 <= len(done) <= 10, "Cola/progreso incorrectos")
        test(len(fixture["blocks"]) == len(done), "Fixture no igual a progreso")
        test("func _run_campaign()" in runner and "func _finish(" in runner
             and "CAMP004_W03_GODOT PASS blocks=" in runner
             and "if errors.is_empty()" in runner and "quit(1)" in runner,
             "Godot runner no falla de forma estricta")
        test("CaptureInventoryService.resolve(" in runner
             and "CaptureSystem.validate_attempt(attempt, catalogs)" in runner,
             "Godot no ejecuta captura real")
        used: set[str] = set()
        for i, block in enumerate(fixture["blocks"]):
            assigned, delivered = queue[i], done[i]
            ids = block["ids"]
            test(block["bloque"] == assigned["bloque"] == delivered["bloque"],
                 "Deriva de orden")
            test(";".join(ids) == assigned["ids"] == delivered["ids"],
                 "IDs no autorizados")
            test(not used.intersection(ids), "IDs repetidos")
            used.update(ids)
            test(block["familia"] == assigned["familia"] and block["ci_required"],
                 "Familia o puerta CI incorrecta")
            test(f'"{block["bloque"]}": _block_{block["bloque"]}(block)' in runner,
                 "Bloque no conectado al runner")
            if block["bloque"] == "01":
                test(ids == ["dive_ball", "dusk_ball", "repeat_ball"],
                     "Reserva 01 alterada")
                test(block["current_state"] == "NEGATIVO_VERIFICADO_NO_IMPLEMENTADO"
                     and block["functional_effect_certified"] is False,
                     "No certificar bonus inexistente")
                test(block["missing_authoritative_signals"] ==
                     ["encounter_is_underwater_or_surfing", "encounter_is_dark_or_cave",
                      "species_previously_caught_in_pokedex"], "Dependencias de contexto incompletas")
                for id in ids:
                    test(f'&"{id}"' not in rules and f'&"{id}"' not in basic
                         and f'&"{id}"' not in effects,
                         "Hay bola nueva en motor, requiere pruebas positivas: " + id)
                test('return "unknown_ball"' in engine
                     and "CaptureSystem.validate_attempt(attempt, catalogs)" in inventory
                     and "inventory.remove(attempt.ball_id, 1)" in inventory,
                     "No está demostrado preflight sin consumo")
                test(not any(re.search(r"^var\\s+" + re.escape(field) + r"\\b", context, re.M)
                             for field in block["missing_authoritative_signals"]),
                     "Contexto evolucionó; reauditar fuentes")
                test("func _block_01(block: Dictionary)" in runner
                     and "rng.state == before_rng" in runner
                     and "inv.to_dict() == before_inv" in runner
                     and "target.to_dict() == before_target" in runner,
                     "Faltan negativos y prueba de no mutación")
                test({x["species_id"] for x in block["cases"]} == {"mew", "caterpie"}
                     and block["hp_modes"] == ["full", "one_hp"],
                     "Falta variación de especie/PS")
                test(set(block["invalid_cases"]) ==
                     {"trainer_battle_not_capturable", "battle_finished",
                      "target_knocked_out", "item_not_owned"},
                     "Faltan rechazos prioritarios")
            elif block["bloque"] == "02":
                test(ids == ["black_flute", "blue_flute", "escape_rope"],
                     "Reserva oficial 02 alterada")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(encoding="utf-8")
                recovery = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(encoding="utf-8"))
                connections = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
                selected = {row["id"]: row for row in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                test(all(selected[id]["familia"] == "FIELD_USE" and
                         selected[id]["estado_contenido"] == "SELECCIONADO" for id in ids),
                     "Los tres deben estar seleccionados como campo")
                test(all(id in connections["holdable_ids"] for id in
                         ["black_flute", "blue_flute"]),
                     "Revisar metadatos de equipable de las flautas")
                blue = recovery["items"]["blue_flute"]
                test(blue["effect"]["cure"] == ["slp"] and blue["consume"] is False,
                     "La Flauta Azul tiene curación existente y es reutilizable")
                test('if FieldEffects.supports(item_id):' in service and
                     'if EncounterModifiers.supports(item_id):' in service and
                     'return _apply_field_effect(item_id, creature_id' in service,
                     "Ruta real de curación de campo no está conectada")
                test('if cure:' in field and
                     'creature.status_state.clear_persistent()' in field and
                     'if FieldEffects.consumes_on_use(item_id)' in service,
                     "Revisar curación real y consumo según perfil")
                test(all(id not in field and id not in modifiers for id in
                         ["black_flute", "escape_rope"]) and
                     all(id not in recovery["items"] for id in
                         ["black_flute", "escape_rope"]),
                     "Otro objeto de campo cambió soporte; reauditar")
                test('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service,
                     "Falta rechazo seguro para Flauta Negra y Cuerda")
                test(block["per_id_status"]["blue_flute"] == "FUNCIONAL_PENDIENTE_CI"
                     and block["per_id_status"]["black_flute"] == "DEPENDENCIA_COMPARTIDA"
                     and block["per_id_status"]["escape_rope"] == "DEPENDENCIA_COMPARTIDA",
                     "Se certifica indebidamente soporte de campo")
                test('func _block_02(block: Dictionary)' in runner
                     and '"02": _block_02(block)' in runner
                     and 'service.use_item(id, target.instance_id)' in runner,
                     "No se usan servicios reales de campo")
                test('result.get("accepted", false) == true' in runner
                     and 'after.status_state.persistent_id == &""' in runner
                     and 'service.sleep_clocks.is_empty()' in runner
                     and 'service.owner.inventory.quantity(id) == quantity' in runner,
                     "Falta caso positivo de Flauta Azul curando sueño sin consumo")
                test('expected = "item_not_owned" if quantity == 0 else "item_has_no_effect"' in runner
                     and 'expected: String = "field_effect_not_connected"' in runner
                     and 'snapshot(service) == before' in runner,
                     "Faltan negativos sin posesión/sin sueño")
                test('PlayerInventory.from_dict(saved)' in runner and
                     'loaded.to_dict() == saved' in runner,
                     "No se comprueba persistencia básica de mochila")
                test('String(denied.get("reason", "")) == "field_locked"' in runner
                     and 'String(invalid.get("reason", "")) == "invalid_inventory"' in runner,
                     "Faltan guardas de campo/corrupción")
                test(set(block["inventory_counts"]) == {0, 2} and
                     {entry["status"] for entry in block["cases"]} == {"none", "sleep"},
                     "No se prueban ambos estados y posesión")
                test(set(block["invalid_cases"]) ==
                     {"field_locked", "invalid_inventory", "unknown_target"},
                     "Negativos de campo incompletos")
            elif block["bloque"] == "03":
                test(ids == ["fluffy_tail", "golden_razz_berry", "lure"],
                     "Reserva 03 alterada")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(encoding="utf-8")
                recovery = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(encoding="utf-8"))
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                test(all(selected[id]["familia"] == "FIELD_USE"
                         and selected[id]["estado_contenido"] == "SELECCIONADO"
                         for id in ids), "Objetos 03 fuera de selección aprobada")
                test(all(id not in recovery["items"] for id in ids),
                     "Algún objeto 03 ya tiene efecto de recuperación: reauditar")
                test(all(id not in field and id not in modifiers for id in ids),
                     "Algún objeto 03 entró en motor de campo/encuentros: reauditar")
                test('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service,
                     "Falta contrato de rechazo de campo")
                test('if FieldEffects.supports(item_id):' in service and
                     'if EncounterModifiers.supports(item_id):' in service,
                     "Orden de ejecutores cambió, reauditar")
                test(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                     and block["functional_effect_certified"] is False
                     and all(value == "DEPENDENCIA_COMPARTIDA"
                             for value in block["per_id_status"].values()),
                     "Prohibido certificar efectos simulados")
                test(block["missing_authoritative_integrations"] ==
                     ["battle_escape_action_for_fluffy_tail",
                      "catch_encounter_berry_mechanic_for_golden_razz_berry",
                      "overworld_encounter_rate_duration_for_lure"],
                     "Falta un contexto real por objeto")
                test('func _block_03(block: Dictionary)' in runner
                     and '"03": _block_03(block)' in runner
                     and 'service.use_item(id, creature.instance_id)' in runner,
                     "Prueba Godot 03 no conectada al servicio real")
                test('String(result.get("reason", "")) == "field_effect_not_connected"' in runner
                     and 'String(result.get("status", "")) == "DEPENDENCY_MISSING"' in runner
                     and 'snapshot(service) == before' in runner,
                     "Sin rechazo y snapshot reales")
                test('PlayerInventory.from_dict(saved)' in runner
                     and 'restored.to_dict() == saved' in runner
                     and 'restored.quantity(id) == count' in runner,
                     "Falta roundtrip estricto de inventario")
                test('String(denied.get("reason", "")) == "field_locked"' in runner
                     and 'String(invalid.get("reason", "")) == "invalid_inventory"' in runner
                     and 'String(foreign.get("reason", "")) == "field_effect_not_connected"' in runner,
                     "Faltan negativos de límites reales")
                test({r["status"] for r in block["cases"]} == {"none", "sleep"}
                     and set(block["inventory_counts"]) == {0, 2},
                     "No se comprueban estados y posesión")
                test(set(block["invalid_cases"]) ==
                     {"field_locked", "invalid_inventory", "unknown_target"},
                     "Faltan casos negativos aprobados")
            elif block["bloque"] == "04":
                test(ids == ["max_lure", "max_repel", "red_flute"],
                     "Reserva 04 alterada")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(encoding="utf-8")
                recovery = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(encoding="utf-8"))
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                test(all(selected[id]["familia"] == "FIELD_USE"
                         and selected[id]["estado_contenido"] == "SELECCIONADO"
                         for id in ids), "Selección de campo 04 alterada")
                test(all(id not in recovery["items"] for id in ids),
                     "Una curación ya existe y requiere positivos")
                test(all(id not in field and id not in modifiers for id in ids),
                     "Una ruta ya registra ID: no asumir rechazo")
                test('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service,
                     "Contrato de rechazo de campo perdido")
                test('if FieldEffects.supports(item_id):' in service
                     and 'if EncounterModifiers.supports(item_id):' in service,
                     "Enrutamiento de campo cambiado")
                test(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                     and block["functional_effect_certified"] is False
                     and set(block["per_id_status"]) == set(ids)
                     and all(s == "DEPENDENCIA_COMPARTIDA"
                             for s in block["per_id_status"].values()),
                     "No atribuir funcionalidad que no está conectada")
                test(block["missing_authoritative_integrations"] ==
                     ["max_lure_overworld_encounter_rate_duration",
                      "max_repel_overworld_encounter_suppression_steps",
                      "red_flute_confusion_heal_field_route"],
                     "Dependencias de campo incompletas")
                test('func _block_04(block: Dictionary)' in runner
                     and '"04": _block_04(block)' in runner
                     and 'service.use_item(id, creature.instance_id)' in runner,
                     "Falta prueba real de campo")
                test('response.get("accepted", true) == false' in runner
                     and 'String(response.get("reason", "")) == "field_effect_not_connected"' in runner
                     and 'String(response.get("status", "")) == "DEPENDENCY_MISSING"' in runner
                     and 'snapshot(service) == before' in runner,
                     "No se verifica rechazo con estado completo")
                test('creature.status_state.has_volatile(&"confusion")' in runner,
                     "Flauta Roja no prueba la confusión retenida")
                test('PlayerInventory.from_dict(saved)' in runner
                     and 'loaded.to_dict() == saved' in runner
                     and 'loaded.quantity(id) == count' in runner,
                     "Falta prueba de persistencia de mochila")
                test('String(denied.get("reason", "")) == "field_locked"' in runner
                     and 'String(invalid.get("reason", "")) == "invalid_inventory"' in runner
                     and 'String(foreign.get("reason", "")) == "field_effect_not_connected"' in runner,
                     "Faltan guardas sobre campo e inventario")
                test({r["status"] for r in block["cases"]} ==
                     {"none", "sleep", "confusion"}
                     and set(block["inventory_counts"]) == {0, 2},
                     "Falta matriz de estado/posesión")
                test(set(block["invalid_cases"]) ==
                     {"field_locked", "invalid_inventory", "unknown_target"},
                     "Faltan negativos de campo")
            elif block["bloque"] == "05":
                test(ids == ["repel", "silver_razz_berry", "super_lure"],
                     "Reserva bloque05 alterada")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(encoding="utf-8")
                recovery = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(encoding="utf-8"))
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                test(all(selected[id]["familia"] == "FIELD_USE"
                         and selected[id]["estado_contenido"] == "SELECCIONADO"
                         for id in ids), "Los tres IDs deben seguir seleccionados")
                test(all(id not in recovery["items"] for id in ids),
                     "Apareció contrato de recuperación: requiere nuevas pruebas")
                test(all(id not in field and id not in modifiers for id in ids),
                     "Apareció ejecutor: revisar funcionamiento antes de caracterizar rechazo")
                test('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service
                     and 'if FieldEffects.supports(item_id):' in service
                     and 'if EncounterModifiers.supports(item_id):' in service,
                     "Cambió el enrutamiento del servicio de campo")
                test(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                     and block["functional_effect_certified"] is False
                     and set(block["per_id_status"]) == set(ids)
                     and all(s == "DEPENDENCIA_COMPARTIDA"
                             for s in block["per_id_status"].values()),
                     "No se puede certificar sin integración de campo")
                test(block["missing_authoritative_integrations"] ==
                     ["repel_overworld_encounter_steps_and_lead_level",
                      "silver_razz_berry_catch_bait_transaction",
                      "super_lure_overworld_encounter_rate_and_duration"],
                     "Dependencias de Repel, Frambu Plateada o Supercolonia incompletas")
                test('"05": _block_05(block)' in runner and
                     'func _block_05(block: Dictionary)' in runner and
                     'service.use_item(id, creature.instance_id)' in runner,
                     "Falta integración de prueba Godot")
                test('String(result.get("reason", "")) == "field_effect_not_connected"' in runner
                     and 'String(result.get("status", "")) == "DEPENDENCY_MISSING"' in runner
                     and 'snapshot(service) == before' in runner,
                     "No se comprueba rechazo y ausencia de efectos secundarios")
                test('PlayerInventory.from_dict(saved)' in runner
                     and 'loaded.to_dict() == saved' in runner
                     and 'loaded.quantity(id) == count' in runner,
                     "Falta serialización real de mochila")
                test('String(denied.get("reason", "")) == "field_locked"' in runner
                     and 'String(invalid.get("reason", "")) == "invalid_inventory"' in runner
                     and 'String(foreign.get("reason", "")) == "field_effect_not_connected"' in runner,
                     "Faltan pruebas de guardas")
                test({r["status"] for r in block["cases"]} ==
                     {"none", "sleep", "confusion"}
                     and set(block["inventory_counts"]) == {0, 2},
                     "No se prueban variaciones de estado/inventario")
                test(set(block["invalid_cases"]) ==
                     {"field_locked", "invalid_inventory", "unknown_target"},
                     "Negativos incompletos")
            elif block["bloque"] == "06":
                test(ids == ["super_repel", "white_flute", "yellow_flute"],
                     "La reserva del bloque 06 no coincide")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(encoding="utf-8")
                recovery = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(encoding="utf-8"))
                selected = {r["id"]: r for r in rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                test(all(selected[id]["familia"] == "FIELD_USE"
                         and selected[id]["estado_contenido"] == "SELECCIONADO" for id in ids),
                     "La selección oficial del bloque 06 ha cambiado")
                test(all(id not in recovery["items"] and id not in field
                         and id not in modifiers for id in ids),
                     "Hay efectos registrados: revisar el contrato real")
                test('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service,
                     "La ruta de rechazo ya no coincide")
                test(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                     and block["functional_effect_certified"] is False
                     and set(block["per_id_status"]) == set(ids)
                     and all(v == "DEPENDENCIA_COMPARTIDA"
                             for v in block["per_id_status"].values()),
                     "No certificar una funcionalidad ausente")
                test(block["missing_authoritative_integrations"] ==
                     ["super_repel_overworld_encounter_steps_and_lead_level",
                      "white_flute_overworld_encounter_modifier",
                      "yellow_flute_confusion_cure_field_route"],
                     "Dependencias incompletas")
                test('"06": _block_06(block)' in runner
                     and 'func _block_06(block: Dictionary)' in runner
                     and 'service.use_item(id, creature.instance_id)' in runner,
                     "Falta la prueba con el servicio de campo real")
                test('String(result.get("reason", "")) == "field_effect_not_connected"' in runner
                     and 'snapshot(service) == before' in runner
                     and 'creature.status_state.has_volatile(&"confusion")' in runner,
                     "No se comprueban los rechazos y la conservación del estado")
                test('PlayerInventory.from_dict(saved)' in runner
                     and 'loaded.to_dict() == saved' in runner,
                     "No se verifica la serialización de inventario")
                test({r["status"] for r in block["cases"]} == {"none", "sleep", "confusion"}
                     and set(block["inventory_counts"]) == {0, 2}
                     and set(block["invalid_cases"]) ==
                     {"field_locked", "invalid_inventory", "unknown_target"},
                     "La matriz de casos no está completa")
            elif block["bloque"] == "07":
                test(ids == ["bug_tera_shard", "dark_tera_shard", "dragon_tera_shard",
                             "electric_tera_shard", "fairy_tera_shard"],
                     "Teralitos bloque07 fuera de cola")
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                test(all(selected[id]["familia"] == "TERA_MATERIAL"
                         and selected[id]["estado_contenido"] == "SELECCIONADO"
                         for id in ids), "Teralitos no seleccionados como material")
                selection = json.loads((ROOT / "config/item_selection_v1.json").read_text(encoding="utf-8"))
                test(all(id not in selection["excluded_ids"] for id in ids),
                     "Algún material Tera ha sido excluido")
                source = (ROOT / "modules/inventory/player_inventory.gd").read_text(encoding="utf-8")
                policy = (ROOT / "modules/inventory/inventory_ruleset.gd").read_text(encoding="utf-8")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
                recovery = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(encoding="utf-8"))
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(encoding="utf-8")
                test(all(id not in recovery["items"] and id not in field
                         and id not in modifiers for id in ids),
                     "Hay una ruta funcional nueva de Tera, reauditar")
                test('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service,
                     "Cambió la respuesta de uso de campo")
                test(all(f"func {name}(" in source
                         for name in ["quantity", "has", "add", "remove", "to_dict", "from_dict"]),
                     "No existe contrato completo de inventario")
                test('const MAX_STACK := 999' in policy
                     and 'not loaded.add(id)' in runner,
                     "Límite del inventario no comprobado")
                test(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                     and block["no_terastallization_certified"] is True
                     and set(block["per_id_status"]) == set(ids)
                     and all(s == "DEPENDENCIA_COMPARTIDA"
                             for s in block["per_id_status"].values()),
                     "Los fragmentos no son prueba de teracristalizacion")
                test(block["missing_shared_integration"] ==
                     "tera_type_change_and_resource_consumption_battle_or_overworld_api",
                     "No se ha documentado la dependencia de mecánica")
                test('"07": _block_07(block)' in runner
                     and 'func _block_07(block: Dictionary)' in runner
                     and 'service.use_item(id, &"field_item_target")' in runner,
                     "El bloque07 no prueba el servicio real")
                test('snapshot(service) == before' in runner
                     and 'String(result.get("reason", "")) == "field_effect_not_connected"' in runner,
                     "La prueba debe demostrar rechazo sin mutación")
                test('PlayerInventory.from_dict(serialized)' in runner
                     and 'loaded.to_dict() == serialized' in runner
                     and 'loaded.remove(id)' in runner and 'loaded.add(id)' in runner,
                     "No se prueba carga, extracción y reposición")
                test(set(block["inventory_counts"]) == {0, 1, 25, 999}
                     and set(block["mutations"]) == {"add", "remove", "roundtrip"},
                     "Casos de inventario Tera incompletos")
            else:
                test(False, "Bloque sin implementación de test: " + block["bloque"])
        test(checks > 0, "Sin verificaciones")
    except (KeyError, OSError, ValueError, TypeError, AssertionError) as e:
        print("CAMP004_W03_PY FAIL " + str(e), file=sys.stderr)
        return 1
    print(f"CAMP004_W03_PY PASS blocks={len(done)} checks={checks}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
