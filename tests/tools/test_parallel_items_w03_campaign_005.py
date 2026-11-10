#!/usr/bin/env python3
"""IA3/W03 CAMP005: verifica productores reales de contexto, NO repite unknown_ball."""
from __future__ import annotations
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w03_campaign_005.json"
RUNNER = ROOT / "tests/gameplay/parallel_items_w03_campaign_005.gd"

def rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ci", action="store_true")
    ap.parse_args()
    checks = 0
    def check(ok: bool, msg: str) -> None:
        nonlocal checks
        checks += 1
        if not ok:
            raise AssertionError(msg)
    try:
        fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
        queue = rows(BASE / "CAMPAIGN_005_W03_QUEUE_APPROVED.csv")
        progress = rows(BASE / "reports/W03/CAMP_005_PROGRESO.csv")
        runner = RUNNER.read_text(encoding="utf-8")
        check(fixture["campaign"] == "CAMP_005" and fixture["worker"] == "W03"
              and fixture["kind"] == "FUNCTIONAL_BACKLOG", "Identidad incorrecta")
        check(len(queue) == 10 and len(progress) == len(fixture["blocks"]) > 0,
              "Divergencia de cola, progreso y fixture")
        check('CAMP005_W03_GODOT PASS blocks=' in runner
              and 'if errors.is_empty()' in runner and 'quit(1)' in runner,
              "Runner no falla de forma estricta")
        for i, block in enumerate(fixture["blocks"]):
            ids = block["ids"]
            check(block["bloque"] == queue[i]["bloque"] == progress[i]["bloque"]
                  and ";".join(ids) == queue[i]["ids"] == progress[i]["ids"],
                  "Progreso sin correspondencia con autorización")
            check(block["familia"] == queue[i]["familia"] and block["ci_required"],
                  "Familia o gate no autorizado")
            check(f'"{block["bloque"]}": _block_{block["bloque"]}(block)' in runner,
                  "Falta ruta de Godot para este bloque")
            if block["bloque"] == "01":
                check(ids == ["dive_ball", "dusk_ball", "repeat_ball"],
                      "IDs de backlog de captura incorrectos")
                check(block["current_state"] == "DEPENDENCIA_CONCRETA"
                      and block["functional_effect_certified"] is False,
                      "No se puede declarar corrección funcional sin fuente")
                capture_ctx = (ROOT / "modules/capture/capture_battle_context.gd").read_text(
                    encoding="utf-8")
                session = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(
                    encoding="utf-8")
                effects = (ROOT / "modules/capture/capture_context_ball_effects.gd").read_text(
                    encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(
                    encoding="utf-8")
                # Aislar función real capture() para no confundir otras menciones
                # con el productor que alimenta CaptureInventoryService.
                capture = re.search(r"(?ms)^func capture\([^\n]*\).*?(?=^func |\Z)", session)
                check(capture is not None, "No se localiza productor de captura")
                body = capture.group()
                check("CaptureBattleContext.new()" in body
                      and "context.completed_turns = battle_state().turn" in body
                      and "context.catcher_level = catcher.level" in body
                      and "CaptureInventoryService.resolve(" in body,
                      "El productor de turno/nivel dejó de ser verificable")
                check(all(f'var {x}:' in capture_ctx
                          for x in ("completed_turns", "catcher_level", "is_wild")),
                      "Contrato actual de captura no coincide")
                expected = {
                    "dive_ball": ("origin_water_kind", "encounter_was_fishing_or_surfing_or_underwater"),
                    "dusk_ball": ("time_of_day", "map_is_cave_or_dark"),
                    "repeat_ball": ("captured_base_species_ids", "pokedex_state_revision"),
                }
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Falta propuesta de frontera por bola")
                for producer in block["required_producers"]:
                    item = producer["id"]
                    check(tuple(producer["missing_fields"]) == expected[item],
                          "Contrato propuesto de fuente incompleto: " + item)
                    for field in producer["missing_fields"]:
                        check(not re.search(r"(?m)^var\s+" + re.escape(field) + r"\s*:", capture_ctx)
                              and field not in body,
                              "Apareció fuente nueva: sustituir dependencia por prueba funcional")
                    check("ShowdownAdventureSession.capture" in producer["consumer"]
                          and producer["decision"].strip() and producer["producer"].strip(),
                          "Productor, consumidor o decisión sin especificar")
                # Versioned migration whitelist W03: Repeat Ball alone promoted; protect all
                # original contextual entries and require a dedicated positive live-ledger test.
                ids_line = re.search(r'const IDS: Array\\[StringName\\] = \\[(.*?)\\]', effects)
                check(ids_line is not None and ids_line.group(1).replace(" ", "") ==
                      '&"quick_ball",&"timer_ball",&"level_ball",&"repeat_ball"' and
                      "ContextBallEffects.IDS" in rules and
                      (ROOT / "tests/gameplay/parallel_items_w03_repeat_history_v2.gd").exists(),
                      "W03 repeat-only migration must preserve prior contextual balls")
                check('CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"quick_ball", ctx)'
                      in runner and '"timer_ball", target, species, ctx), 1.0'
                      in runner and '"level_ball", target, species, ctx), 4.0'
                      in runner, "Godot no contrasta productores funcionales existentes")
                check('result.result.reason == "unknown_ball"' not in runner
                      and 'expected_rejection == "unknown_ball"' not in runner,
                      "La campaña repite la prueba negativa de CAMP004")
            elif block["bloque"] == "02":
                check(ids == ["luxury_ball", "lure_ball"],
                      "Reserva de dos bolas contextual modificada")
                check(block["current_state"] == "DEPENDENCIA_CONCRETA"
                      and block["functional_effect_certified"] is False,
                      "No certificar bonus sin productor")
                creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(
                    encoding="utf-8")
                friendship = (ROOT / "modules/inventory/field_friendship_effects.gd").read_text(
                    encoding="utf-8")
                system = (ROOT / "modules/capture/capture_system.gd").read_text(
                    encoding="utf-8")
                context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(
                    encoding="utf-8")
                session = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(
                    encoding="utf-8")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(
                    encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(
                    encoding="utf-8")
                selection = {r["id"]: r for r in
                             rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selection[id]["estado_contenido"] == "SELECCIONADO"
                          for id in ids), "Bolas no seleccionadas")
                check("func increase(creature: CreatureInstance, gains: Array)" in friendship
                      and 'creature.held_item_id == &"soothe_bell"' in friendship
                      and "creature.friendship = mini(255, before + gain)" in friendship,
                      "Ruta positiva de amistad cambió")
                check('"friendship": friendship' in creature
                      and 'creature.friendship = int(data.get("friendship", 0))' in creature,
                      "Contrato actual de guardado amistad ausente")
                check('original_capture_ball_id' not in creature
                      and 'capture_ball_id' not in creature,
                      "Origen de captura apareció: hay que integrar y probar")
                check('origin_ball' not in friendship and 'luxury_ball' not in friendship,
                      "Se ha conectado Luxury: las pruebas necesitan positivo real")
                check('func on_catch(' in basic
                      and 'crs.BallEffects.on_catch(attempt.ball_id, target)' in system,
                      "No se identifica punto de aplicación tras éxito")
                check("encounter_method" not in context
                      and "fishing_provenance" not in context
                      and "context.completed_turns = battle_state().turn" in session,
                      "Hay nueva fuente de pesca que exige prueba funcional")
                check('luxury_ball' not in rules and 'lure_ball' not in rules
                      and 'luxury_ball' not in basic and 'lure_ball' not in basic,
                      "Bolas ahora conectadas: reauditar efectos")
                expected = {"luxury_ball": {"original_capture_ball_id",
                                           "origin_ball_friendship_multiplier_policy"},
                            "lure_ball": {"encounter_method", "fishing_provenance"}}
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Productores no definidos para ambos IDs")
                for producer in block["required_producers"]:
                    check(set(producer["missing_fields"]) == expected[producer["id"]]
                          and producer["producer"].strip()
                          and producer["consumer"].strip()
                          and producer["decision"].strip(),
                          "Falta el contrato preciso de " + producer["id"])
                check('"02": _block_02(block)' in runner
                      and 'func _block_02(block: Dictionary)' in runner,
                      "Godot bloque02 no se ejecuta")
                check('friendship_effects.increase(restored, [5, 3, 2])' in runner
                      and 'bell_gain == 7' in runner and 'baseline == 5' in runner,
                      "Faltan positivos de amistad reales")
                check('CreatureInstance.from_dict(serialized)' in runner
                      and 'restored.to_dict() == serialized' in runner,
                      "No se verifica persistencia de amistad")
                check('not context_fields.has("encounter_method")' in runner
                      and 'not original_keys.has("original_capture_ball_id")' in runner,
                      "No se detectan productores ausentes")
            elif block["bloque"] == "03":
                check(ids == ["love_ball", "moon_ball"],
                      "Reserva del bloque03 ha cambiado")
                check(block["current_state"] == "DEPENDENCIA_CONCRETA"
                      and block["functional_effect_certified"] is False,
                      "No certificar bonus Love/Moon sin fuente")
                creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(
                    encoding="utf-8")
                species = (ROOT / "modules/creatures/domain/creature_species.gd").read_text(
                    encoding="utf-8")
                records = (ROOT / "modules/creatures/domain/evolution_record.gd").read_text(
                    encoding="utf-8")
                evolutions = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text(
                    encoding="utf-8")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(
                    encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(
                    encoding="utf-8")
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selected[id]["estado_contenido"] == "SELECCIONADO" for id in ids),
                      "Bolas fuera de selección vigente")
                check(not re.search(r"(?m)^var\\s+(?:gender|gender_id|sex|individual_gender_id)\\s*:", creature)
                      and '"gender_id":' not in creature,
                      "Ha aparecido género individual y exige prueba positiva")
                check('var source_metadata: Dictionary' in species
                      and 'var item_id: StringName' in records
                      and 'var version_group: StringName' in records
                      and 'var conditions: Dictionary' in records,
                      "Faltan datos canónicos de versión o evolución")
                check('rec.item_id' in evolutions
                      and 'TRIGGER_USE_ITEM' in evolutions
                      and 'evolution_candidates(' in evolutions,
                      "No existe ruta de elegibilidad real de piedra")
                check(all(id not in basic and id not in rules for id in
                          ['&"love_ball"', '&"moon_ball"']),
                      "Se registró una bola nueva: certificar factor positivo")
                expected = {"love_ball": {"individual_gender_id",
                                          "target_and_active_species_gender_validity"},
                            "moon_ball": {"selected_evolution_version_group",
                                          "moon_stone_target_evolution_predicate"}}
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Falta productor para alguna bola")
                for producer in block["required_producers"]:
                    check(set(producer["missing_fields"]) == expected[producer["id"]]
                          and producer["producer"].strip()
                          and producer["consumer"].strip()
                          and producer["decision"].strip(),
                          "Contrato insuficiente de " + producer["id"])
                check('"03": _block_03(block)' in runner
                      and 'func _block_03(block: Dictionary)' in runner
                      and 'EvolutionSystem.evolution_candidates(' in runner
                      and 'EvolutionSystem.classify_record(' in runner,
                      "No se prueba la ruta real de evolución")
                check('CreatureInstance.from_dict(saved)' in runner
                      and 'not saved.has("gender")' in runner
                      and 'not other.has(record)' in runner
                      and 'moon_candidates > 0' in runner,
                      "Faltan persistencia y positivos/negativos Piedra Lunar")
            elif block["bloque"] == "04":
                check(ids == ["beast_ball", "heavy_ball"], "Reserva bloque04 alterada")
                check(block["current_state"] == "DEPENDENCIA_CONCRETA"
                      and block["functional_effect_certified"] is False,
                      "No atribuir funcionamiento Beast/Heavy")
                species = (ROOT / "modules/creatures/domain/creature_species.gd").read_text(
                    encoding="utf-8")
                capture = (ROOT / "modules/capture/capture_system.gd").read_text(
                    encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(
                    encoding="utf-8")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(
                    encoding="utf-8")
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selected[item]["estado_contenido"] == "SELECCIONADO"
                          for item in ids), "Bolas fuera de selección oficial")
                check("var source_metadata: Dictionary" in species
                      and '"source_metadata"' in species
                      and "CreatureSpecies" in species,
                      "No existe transporte de metadatos canónicos")
                check(not re.search(r"(?m)^@?export\\s+var\\s+(?:weight_hectograms|weight_kg|is_ultra_beast)\\b", species)
                      and "var weight_hectograms" not in species
                      and "var is_ultra_beast" not in species,
                      "Apareció campo nuevo y exige casos positivos")
                check("func catch_probability(" in rules
                      and "CAPTURE_RATE_MIN := 1" in rules
                      and "CAPTURE_RATE_MAX := 255" in rules
                      and "crs.catch_probability(" in capture,
                      "Contrato actual de tasa de captura alterado")
                check('&"beast_ball"' not in basic and '&"heavy_ball"' not in basic
                      and '&"beast_ball"' not in rules and '&"heavy_ball"' not in rules,
                      "Se ha implementado efecto: reauditar multiplicadores")
                expected = {"beast_ball": {"is_ultra_beast",
                                          "beast_ball_versioned_factor"},
                            "heavy_ball": {"weight_hectograms",
                                           "heavy_ball_versioned_weight_tiers"}}
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Productores incompletos")
                for producer in block["required_producers"]:
                    check(set(producer["missing_fields"]) == expected[producer["id"]]
                          and producer["producer"].strip()
                          and producer["consumer"].strip()
                          and producer["decision"].strip(),
                          "Frontera no definida para " + producer["id"])
                check('"04": _block_04(block)' in runner
                      and "func _block_04(block: Dictionary)" in runner,
                      "Sin prueba Godot de bloque04")
                check("CreatureSpecies.from_dict(original)" in runner
                      and "species.source_metadata" in runner
                      and "rules.catch_probability(" in runner
                      and "not properties.has(\"weight_hectograms\")" in runner,
                      "Sin evidencias positivas de metadatos y cálculo")
            elif block["bloque"] == "05":
                check(ids == ["safari_ball", "sport_ball"], "Reserva Safari/Sport alterada")
                check(block["current_state"] == "PARTIAL_EXISTING_EFFECT_UNGATED"
                      and block["functional_effect_certified"] is False,
                      "La bonificación genérica no certifica el contexto especial")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(
                    encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(
                    encoding="utf-8")
                context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(
                    encoding="utf-8")
                session = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(
                    encoding="utf-8")
                capture = (ROOT / "modules/capture/capture_system.gd").read_text(
                    encoding="utf-8")
                check('&"safari_ball", &"sport_ball"' in basic
                      and '&"safari_ball", &"sport_ball": return 1.5' in basic,
                      "El multiplicador actual cambió: reauditar integración")
                check("for id: StringName in BallEffects.IDS" in rules
                      and "crs.BallEffects.multiplier(attempt.ball_id, target, species)" in capture,
                      "La bonificación no está conectada al motor")
                check(all(x not in context and x not in session
                          for x in ["is_safari_zone", "is_bug_contest_zone",
                                    "safari_capture_mode", "contest_capture_mode"]),
                      "Hay fuente de zona nueva: cambiar a pruebas funcionales")
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selected[item]["estado_contenido"] == "SELECCIONADO"
                          for item in ids), "Bolas fuera de selección")
                expected = {
                    "safari_ball": {"is_safari_zone", "safari_capture_mode",
                                    "safari_profile_version"},
                    "sport_ball": {"is_bug_contest_zone", "contest_capture_mode",
                                   "sport_profile_version"},
                }
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Productores no asignados")
                for producer in block["required_producers"]:
                    check(set(producer["missing_fields"]) == expected[producer["id"]]
                          and producer["producer"].strip()
                          and producer["consumer"].strip()
                          and producer["decision"].strip(),
                          "Falta contrato concreto para " + producer["id"])
                check('"05": _block_05(block)' in runner
                      and 'func _block_05(block: Dictionary)' in runner,
                      "Falta runner Godot propio")
                check('CaptureSystem.validate_attempt(CaptureAttempt.new(target, id, ctx)' in runner
                      and 'CaptureRuleset.BallEffects.multiplier(id, target, species)' in runner
                      and 'is_equal_approx(bonus_p, base_p * 1.5)' in runner,
                      "Faltan positivos del multiplicador real y probabilidad")
                check('not ctx_fields.has("is_safari_zone")' in runner
                      and 'not ctx_fields.has("is_bug_contest_zone")' in runner,
                      "No se vigila el contrato de zona")
            elif block["bloque"] == "06":
                check(ids == ["repel", "super_repel", "max_repel"],
                      "Reserva de repelentes alterada")
                check(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                      and block["functional_effect_certified"] is False,
                      "No certificar una mecánica sin pasos del mundo")
                encounter = (ROOT / "modules/encounters/wild_encounter_system.gd").read_text(
                    encoding="utf-8")
                table = (ROOT / "modules/encounters/wild_encounter_table.gd").read_text(
                    encoding="utf-8")
                inventory = (ROOT / "modules/inventory/field_item_service.gd").read_text(
                    encoding="utf-8")
                modifiers = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(
                    encoding="utf-8")
                check('if table.encounter_chance_bp == 0:' in encounter
                      and 'out.status = WildEncounterResult.NONE' in encounter
                      and 'out.reason = "chance_miss"' in encounter,
                      "Frontera positiva de encuentros no verificable")
                check("func resolve(" in encounter
                      and "encounter_chance_bp" in table
                      and "func to_dict()" in table
                      and "static func from_dict(" in table,
                      "Contratos básicos de encuentro cambiados")
                check("CLEANSE_TAG" in modifiers and "PURE_INCENSE" in modifiers
                      and "func prepare_table(" in modifiers,
                      "No existe precedente de modificación de encuentros")
                check(all(item not in inventory and item not in modifiers
                          and item not in encounter
                          for item in ['&"repel"', '&"super_repel"', '&"max_repel"']),
                      "Apareció ruta de repelentes: auditar funcionalidad")
                selected = {x["id"]: x for x in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selected[item]["estado_contenido"] == "SELECCIONADO"
                          for item in ids), "Repelentes fuera del alcance aprobado")
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Productores incompletos")
                for producer in block["required_producers"]:
                    check(producer["producer"] == "overworld_steps"
                          and producer["consumer"] == "encounter_coordinator"
                          and set(producer["missing_fields"]) ==
                          {"remaining_steps", "effective_lead_level", "wild_level_filter"}
                          and producer["decision"].strip(),
                          "Frontera de pasos insuficiente")
                check('"06": _block_06(block)' in runner
                      and "func _block_06(block: Dictionary)" in runner
                      and "WildEncounterSystem.resolve(" in runner
                      and "rng.state == previous_state" in runner,
                      "Falta prueba positiva Godot de encuentros y RNG")
                check("WildEncounterTable.from_dict(packed)" in runner
                      and "found.level == 8" in runner,
                      "Falta roundtrip y límite de nivel")
            elif block["bloque"] == "07":
                expected_ids = ["black_flute", "white_flute", "lure",
                                "super_lure", "max_lure"]
                check(ids == expected_ids, "Reserva bloque07 cambiada")
                check(block["current_state"] == "DEPENDENCIA_COMPARTIDA"
                      and block["functional_effect_certified"] is False,
                      "No certificar modificación de mundo sin productor")
                modifier = (ROOT / "modules/gameplay/encounter_item_modifiers.gd").read_text(
                    encoding="utf-8")
                table = (ROOT / "modules/encounters/wild_encounter_table.gd").read_text(
                    encoding="utf-8")
                resolver = (ROOT / "modules/encounters/wild_encounter_system.gd").read_text(
                    encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_service.gd").read_text(
                    encoding="utf-8")
                check("func modified_chance_bp(" in modifier
                      and "RATE_NUMERATOR := 2" in modifier
                      and "RATE_DENOMINATOR := 3" in modifier
                      and "func prepare_table(" in modifier,
                      "La regla positiva de frecuencia dejó de existir")
                check("encounter_chance_bp" in table
                      and "func validate(" in table
                      and "func to_dict(" in table
                      and "static func from_dict(" in table,
                      "No se verifica transporte de probabilidad")
                check("table.encounter_chance_bp" in resolver
                      and "WildEncounterRuleset.CHANCE_BP_MAX" in resolver,
                      "La frontera del resolver cambió")
                check(all(f'&"{item}"' not in modifier and
                          f'&"{item}"' not in field for item in ids),
                      "Ha aparecido integración: reauditar con pruebas positivas")
                scope = {r["id"]: r for r in
                         rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(scope[item]["estado_contenido"] == "SELECCIONADO"
                          for item in ids), "Un objeto salió del alcance aprobado")
                check({p["id"] for p in block["required_producers"]} == set(ids),
                      "Productores o IDs ausentes")
                for producer in block["required_producers"]:
                    check(producer["producer"] == "overworld_movement_encounter_scheduler"
                          and all(v in producer["missing_fields"] for v in
                                  ["active_field_encounter_modifier",
                                   "remaining_effect_steps_or_duration",
                                   "minimum_steps_between_encounters"])
                          and producer["consumer"].strip()
                          and producer["decision"].strip(),
                          "Contrato de mundo insuficiente")
                check('"07": _block_07(block)' in runner and
                      "func _block_07(block: Dictionary)" in runner
                      and "modifier.modified_chance_bp(6000) == 4000" in runner
                      and "WildEncounterTable.from_dict(packed)" in runner
                      and "reduced.validate(catalogs).ok" in runner,
                      "No se ejecutan pruebas positivas de frecuencia")
            elif block["bloque"] == "08":
                check(ids == ["red_flute", "yellow_flute", "blue_flute"],
                      "Reserva del bloque08 ha cambiado")
                check(block["current_state"] == "PARTIAL_BLUE_FIELD_FUNCTIONAL"
                      and block["functional_effect_certified"] is False,
                      "No certificar Red/Yellow como funcionales en campo")
                profile = json.loads((ROOT / "modules/inventory/imported_recovery_v19.json").read_text(
                    encoding="utf-8"))
                blue = profile["items"].get("blue_flute", {})
                check(blue.get("consume") is False
                      and blue.get("effect", {}).get("cure") == ["slp"],
                      "Fuente real Azul no reutilizable o no cura sueño")
                field = (ROOT / "modules/inventory/field_item_effects.gd").read_text(
                    encoding="utf-8")
                service = (ROOT / "modules/inventory/field_item_service.gd").read_text(
                    encoding="utf-8")
                battle = json.loads((ROOT / "modules/inventory/battle_support_profile.json").read_text(
                    encoding="utf-8"))["items"]
                check(battle["blue_flute"]["cure"] == "sleep"
                      and battle["red_flute"]["cure"] == "attraction"
                      and battle["yellow_flute"]["cure"] == "confusion",
                      "Contrato externo de flautas no coincide")
                check('FieldEffects.consumes_on_use(item_id)' in service
                      and 'sleep_clocks.erase(String(creature_id))' in service
                      and 'FieldEffects.apply(copy, item_id, move_slot, catalogs)' in service,
                      "Transacción y reloj de sueño no comprobables")
                check('creature.status_state.clear_persistent()' in field
                      and 'STATUS.get(code) == status' in field
                      and 'return _recovery.has(String(item_id))' in field,
                      "Ruta de medicina importada no identificada")
                check("red_flute" not in profile["items"]
                      and "yellow_flute" not in profile["items"],
                      "Hay ruta de campo nueva: reauditar efectos positivos")
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selected[item]["estado_contenido"] == "SELECCIONADO"
                          for item in ids), "Flautas fuera de alcance")
                check({p["id"] for p in block["required_producers"]} ==
                      {"red_flute", "yellow_flute"}, "Contratos volátiles incompletos")
                check('"08": _block_08(block)' in runner
                      and "func _block_08(block: Dictionary)" in runner
                      and 'service.use_item(&"blue_flute", target.instance_id)' in runner
                      and 'service.owner.inventory.quantity(&"blue_flute") == 2' in runner
                      and 'service.sleep_clocks.is_empty()' in runner
                      and 'snapshot(service) == no_effect_before' in runner,
                      "Faltan positivos y negativos reales de Flauta Azul")
            elif block["bloque"] == "09":
                check(ids == ["escape_rope", "fluffy_tail"],
                      "Reserva del bloque09 incorrecta")
                check(block["current_state"] == "PARTIAL_FLUFFY_BATTLE_ESCAPE"
                      and block["functional_effect_certified"] is False,
                      "No declarar teletransporte de Cuerda Huida")
                escape = json.loads((ROOT / "modules/inventory/battle_escape_profile.json").read_text(
                    encoding="utf-8"))["items"]
                check(escape["fluffy_tail"] == {
                    "consume": 1, "guaranteed": True,
                    "rng_consumed": False, "wild_only": True},
                    "Contrato de huida garantizada cambió")
                check("escape_rope" not in escape,
                      "Se conectó Cuerda Huida al perfil de batalla")
                profile = (ROOT / "modules/inventory/battle_escape_profile.gd").read_text(
                    encoding="utf-8")
                session = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(
                    encoding="utf-8")
                field = (ROOT / "modules/inventory/field_item_service.gd").read_text(
                    encoding="utf-8")
                check("func _use_escape_item(" in session
                      and "Escape.supports(item_id)" in session
                      and "bag.remove(item_id)" in session
                      and '_finish("FLED", bag)' in session
                      and 'Escape.resolution(escape_attempts)' in session,
                      "La huida de batalla ya existente no es comprobable")
                check('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in field
                      and "&\"escape_rope\"" not in field
                      and "&\"fluffy_tail\"" not in field,
                      "Ruta de campo modificada: reauditar")
                check("static func resolution(" in profile
                      and '"rng_consumed": false' in profile,
                      "No se garantiza huida sin RNG")
                check({x["id"] for x in block["required_producers"]} == set(ids),
                      "Productores faltantes")
                for producer in block["required_producers"]:
                    check(producer["producer"].strip()
                          and producer["consumer"].strip()
                          and producer["decision"].strip(),
                          "No se precisó contrato de " + producer["id"])
                check('"09": _block_09(block)' in runner
                      and "func _block_09(block: Dictionary)" in runner
                      and 'service.use_item(id, &"field_item_target")' in runner
                      and "snapshot(service) == before" in runner,
                      "No hay tests reales de rechazo sin gasto")
            elif block["bloque"] == "10":
                check(ids == ["friend_ball", "heal_ball", "quick_ball", "timer_ball"],
                      "Cola final modificada")
                check(block["current_state"] == "EXISTING_FUNCTIONAL_CAPTURE_CONTRACTS"
                      and block["functional_effect_certified"] is True
                      and block["no_new_objects"] is True,
                      "Los efectos son existentes, no nuevas altas")
                check(block["savev2_scope"] ==
                      "creature_serialization_roundtrip_only_no_full_SaveV2_end_to_end",
                      "No certificar SaveV2 completo por serialización parcial")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(
                    encoding="utf-8")
                contextual = (ROOT / "modules/capture/capture_context_ball_effects.gd").read_text(
                    encoding="utf-8")
                capture = (ROOT / "modules/capture/capture_system.gd").read_text(
                    encoding="utf-8")
                session = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(
                    encoding="utf-8")
                creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(
                    encoding="utf-8")
                check('if id == &"friend_ball": target.friendship = 200' in basic
                      and 'if id != &"heal_ball": return' in basic
                      and 'target.current_hp = target.stats.max_hp' in basic
                      and 'slot.current_pp = slot.max_pp' in basic,
                      "Friend/Heal éxito ya no tiene contrato verificable")
                check('&"quick_ball", &"timer_ball", &"level_ball"' in contextual
                      and 'context.completed_turns < 0' in contextual
                      and 'context.completed_turns == 0' in contextual
                      and '0.3 * context.completed_turns' in contextual,
                      "Quick/Timer no reciben contrato por turno")
                check('crs.BallEffects.on_catch(attempt.ball_id, target)' in capture
                      and 'crs.ContextBallEffects.multiplier(' in capture
                      and 'var invalid_reason := validate_attempt(attempt, catalogs)' in capture,
                      "No está probado el punto de éxito y validación")
                check('context.completed_turns = battle_state().turn' in session
                      and 'CaptureInventoryService.resolve(' in session
                      and 'if resolution.result.status == CaptureResult.INVALID:' in session,
                      "La sesión no produce contexto de turno seguro")
                check('"friendship": friendship' in creature
                      and '"current_hp": current_hp' in creature
                      and '"moveset": serialized_moveset' in creature
                      and "static func from_dict(" in creature,
                      "La persistencia serializable de criatura cambió")
                check({p["id"] for p in block["required_producers"]} == set(ids)
                      and all(not p["missing_fields"] for p in
                              block["required_producers"]),
                      "No se deben declarar productores ficticios")
                check('"10": _block_10(block)' in runner
                      and 'func _block_10(block: Dictionary)' in runner
                      and 'CaptureInventoryService.resolve(' in runner,
                      "Falta captura ejecutable propia")
                check('outcome.result.status == CaptureResult.SUCCESS' in runner
                      and 'c.friendship == 200' in runner
                      and 'c.current_hp == c.stats.max_hp' in runner
                      and 'CreatureInstance.from_dict(c.to_dict())' in runner,
                      "Faltan casos positivos y serialización de Friend/Heal")
                check('context.completed_turns = 10' in runner
                      and 'context.completed_turns = -1' in runner
                      and 'rng.state == before_rng' in runner
                      and 'bag.to_dict() == before_bag' in runner,
                      "Faltan límites Quick/Timer y rechazo sin consumo")
                selected = {r["id"]: r for r in
                            rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
                check(all(selected[id]["estado_contenido"] == "SELECCIONADO"
                          for id in ids), "Bolas fuera del alcance aprobado")
            else:
                check(False, "Bloque sin nueva prueba: " + block["bloque"])
        check(checks > 0, "Sin verificaciones")
    except (KeyError, OSError, ValueError, TypeError, AssertionError) as exc:
        print(f"CAMP005_W03_PY FAIL {exc}", file=sys.stderr)
        return 1
    print(f"CAMP005_W03_PY PASS blocks={len(progress)} checks={checks}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
