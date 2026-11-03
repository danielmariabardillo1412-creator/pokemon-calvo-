#!/usr/bin/env python3
"""IA3/W03 CAMP003: contratos incrementales, sin emular el motor.
Cada PASS requiere fuente real, fixture autorizado y runner Godot del mismo bloque.
"""
from __future__ import annotations
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = Path("docs/coordination/items_parallel_v1")
FIXTURE = Path("tests/fixtures/parallel_items/w03_campaign_003.json")
RUNNER = Path("tests/gameplay/parallel_items_w03_campaign_003.gd")


def rows(path: Path) -> list[dict[str, str]]:
    with (ROOT / path).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


class Audit:
    checks = 0

    def check(self, value: bool, label: str) -> None:
        self.checks += 1
        if not value:
            raise AssertionError(label)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true", help="Contrato de salida estricta para IA6")
    opts = parser.parse_args()
    audit = Audit()
    try:
        fixture = json.loads((ROOT / FIXTURE).read_text(encoding="utf-8"))
        done = rows(BASE / "reports/W03/CAMP_003_PROGRESO.csv")
        queue = [r for r in rows(BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv")
                 if r["trabajadora"] == "W03"]
        audit.check(len(queue) == 10, "La cola W03 debe conservar exactamente 10 bloques")
        audit.check(1 <= len(done) <= 10, "Se necesita al menos un bloque publicado")
        audit.check(fixture["schema_version"] == 1 and
                    fixture["campaign"] == "CAMP_003" and fixture["worker"] == "W03",
                    "Identidad o esquema de fixture equivocado")
        audit.check(fixture["scope"] == "AUDITORIA_Y_PRUEBAS_NO_PRODUCCION",
                    "No se autorizó código de producción")
        blocks = fixture["blocks"]
        audit.check(len(blocks) == len(done), "Fixture y progreso no contienen los mismos bloques")
        runner = (ROOT / RUNNER).read_text(encoding="utf-8")
        audit.check('func _run_campaign()' in runner and
                    "CAMP003_W03_GODOT PASS blocks=" in runner and
                    "if errors.is_empty()" in runner and
                    "quit(0)" in runner and "quit(1)" in runner,
                    "Falta runner real y fallo estricto")
        audit.check("CaptureInventoryService.resolve(" in runner and
                    "CaptureResult.INVALID" in runner and
                    "rng.state == control.state" in runner,
                    "Falta test de consumo y RNG real")
        seen: set[str] = set()
        for index, block in enumerate(blocks):
            assigned = queue[index]
            delivered = done[index]
            ids = block["ids"]
            audit.check(block["bloque"] == assigned["bloque"] == delivered["bloque"],
                        "Número de bloque no coincide")
            audit.check(";".join(ids) == assigned["ids"] == delivered["ids"],
                        "ID fuera de cola o duplicado")
            audit.check(assigned["familia"] == "CAPTURE_BALL" and len(ids) == 2,
                        "Reserva de dos bolas inválida")
            audit.check(not seen.intersection(ids), "IDs repetidos entre bloques")
            seen.update(ids)
            audit.check(not block["implementation_authorized"] and block["ci_required"],
                        "Implementación no autorizada o CI deshabilitada")
            audit.check(f'"{block["bloque"]}"' in runner,
                        "Bloque no conectado al runner acumulativo")
            for path in block["prior_evidence"]["sources"]:
                audit.check((ROOT / path).is_file(), "Fuente histórica no accesible: " + path)
            if block["bloque"] == "01":
                audit.check(ids == ["poke_ball", "great_ball"], "Bloque 01 alterado")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                system = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
                inventory = (ROOT / "modules/inventory/capture_inventory_service.gd").read_text(encoding="utf-8")
                historical = (ROOT / "tests/gameplay/item_capture_v11.gd").read_text(encoding="utf-8")
                for ball in block["balls"]:
                    expected = f'&"{ball["id"]}": CaptureBallDefinition.new(&"{ball["id"]}", {ball["multiplier"]:.1f}, false)'
                    audit.check(expected in rules, "Definición base ha cambiado: " + ball["id"])
                    audit.check(not ball["guaranteed"], "No son Master Ball")
                audit.check("rng.randf() < p" in system and
                            "crs.catch_probability(" in system,
                            "Motor no tiene una tirada RNG canónica")
                audit.check("inventory.remove(attempt.ball_id, 1)" in inventory and
                            "CaptureSystem.validate_attempt(attempt, catalogs)" in inventory,
                            "No se conserva el límite transaccional")
                audit.check("func _matrix()" in historical and
                            "one throw one RNG one ball" in historical,
                            "Se perdió la matriz histórica, no duplicarla")
                audit.check(len(block["cases"]) >= 3 and
                            {c["species_id"] for c in block["cases"]} ==
                            {"caterpie", "pikachu", "mew"}, "Cobertura de especies alterada")
                audit.check(block["health_modes"] == ["full", "one_hp"],
                            "Falta contraste PS altos/bajos")
                audit.check(set(block["invalid_cases"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned"},
                            "No se cubren ambos rechazos sin RNG")
                audit.check("func _block_01(" in runner and
                            "reglas.catch_probability(" in runner and
                            "p_grande >= p_normal" in runner,
                            "Falta comparación de probabilidades reales de ambas bolas")
            elif block["bloque"] == "02":
                audit.check(ids == ["ultra_ball", "master_ball"],
                            "No coincide la reserva oficial 02")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                system = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
                inv = (ROOT / "modules/inventory/capture_inventory_service.gd").read_text(encoding="utf-8")
                defined = {item["id"]: item for item in block["balls"]}
                audit.check(set(defined) == set(ids), "Definiciones de fixture desviadas")
                audit.check(defined["ultra_ball"]["multiplier"] == 2 and
                            defined["ultra_ball"]["guaranteed"] is False,
                            "Ultra Ball no es 2x ordinaria")
                audit.check(defined["master_ball"]["multiplier"] == 1 and
                            defined["master_ball"]["guaranteed"] is True,
                            "Master Ball no es garantizada")
                for item in block["balls"]:
                    flag = "true" if item["guaranteed"] else "false"
                    expected = (f'&"{item["id"]}": CaptureBallDefinition.new('
                                f'&"{item["id"]}", {item["multiplier"]:.1f}, {flag})')
                    audit.check(expected in rules, "Cambio en tabla canónica " + item["id"])
                audit.check("if not guaranteed:" in system and
                            "var success := guaranteed or" in system and
                            "rng.randf() < p" in system,
                            "RNG de Master debe hacer cortocircuito")
                audit.check("inventory.remove(attempt.ball_id, 1)" in inv,
                            "Límite de descuento compartido cambiado")
                audit.check("func _block_02(" in runner and
                            '"02": _block_02(bloque)' in runner,
                            "Falta ejecución de suite02")
                audit.check("is_zero_approx(result.result.probability)" in runner
                            and "rng.state == before_rng" in runner
                            and "rng.state == probe.state" in runner,
                            "No se controla RNG de Ultra y Master")
                audit.check("CaptureDisposition.STORAGE_REQUIRED" in runner
                            and "CaptureOwnershipRouter.new().route(" in runner,
                            "No se comprueba propietario y PC de Master")
                audit.check("result.result.reason == razon" in runner
                            and "not result.result.consume_item" in runner,
                            "Faltan rechazos sin gasto")
                audit.check(set(block["invalid_cases"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned",
                             "target_knocked_out"}, "Negativos insuficientes")
                audit.check({c["species_id"] for c in block["cases"]} ==
                            {"mew", "pikachu", "caterpie"}, "No se prueban tres especies")
                audit.check(block["health_modes"] == ["full", "one_hp"],
                            "Falta variación de PS")
            elif block["bloque"] == "03":
                audit.check(ids == ["quick_ball", "timer_ball"], "Reserva 03 alterada")
                context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(encoding="utf-8")
                effects = (ROOT / "modules/capture/capture_context_ball_effects.gd").read_text(encoding="utf-8")
                wild = (ROOT / "modules/gameplay/wild_adventure_session.gd").read_text(encoding="utf-8")
                showdown = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                audit.check('var completed_turns: int = -1' in context,
                            "Contexto ausente debe valer -1, nunca cero")
                audit.check('capture_turn_context_missing' in effects and
                            'context.completed_turns < 0' in effects,
                            "No se rechazan turnos incompletos")
                audit.check('&"quick_ball"' in effects and '&"timer_ball"' in effects and
                            '&"level_ball"' in effects,
                            "Registro contextual compartido alterado")
                audit.check('context.completed_turns == 0' in effects and
                            '5.0 if context.completed_turns == 0 else 1.0' in effects,
                            "Quick debe bonificar únicamente primer turno")
                audit.check('minf(1.0 + 0.3 * context.completed_turns, 4.0)' in effects,
                            "Timer debe saturar a 4.0 desde 10 turnos")
                audit.check('for id: StringName in ContextBallEffects.IDS:' in rules,
                            "El registro contextual no llega a CaptureRuleset")
                audit.check('context.completed_turns = _battle_server.state.turn' in wild,
                            "Sesión Wild no transmite turnos del combate real")
                audit.check('context.completed_turns = battle_state().turn' in showdown,
                            "Sesión Showdown no transmite turnos del combate real")
                audit.check('func _block_03(' in runner and
                            '"03": _block_03(bloque)' in runner and
                            'CAMP003_W03_TURN_EFFECTS.multiplier(' in runner,
                            "No existe prueba Godot del efecto contextual real")
                audit.check('CaptureSystem.validate_attempt(' in runner and
                            'capture_turn_context_missing' in runner and
                            'rng.state == before_rng' in runner,
                            "No se garantiza rechazo sin contexto y sin consumir RNG")
                audit.check('rng.state == control.state' in runner and
                            'CaptureInventoryService.resolve(' in runner and
                            'inv.quantity(id) == 1' in runner,
                            "No se verifica consumo de un ítem y un RNG válido")
                audit.check(set(block["ids"]) ==
                            {item["id"] for item in block["balls"]},
                            "Factor reservado de objeto diferente")
                audit.check({int(t) for t in block["completed_turns"]} ==
                            {0, 1, 3, 9, 10, 11},
                            "Faltan turnos 0, fronteras y saturación Timer")
                audit.check(set(block["invalid_context_turns"]) == {-1, -2},
                            "No se cubre ausencia y negativo explícito")
                audit.check(set(block["other_rejections"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned"},
                            "Faltan rechazos de entrenador o propiedad")
                audit.check(block["hp_modes"] == ["full", "one_hp"],
                            "No se prueban ambos extremos PS")
                audit.check({row["species_id"] for row in block["cases"]} ==
                            {"mew", "caterpie"}, "No se prueban ambas tasas de captura")
                audit.check(not block["implementation_authorized"] and block["ci_required"],
                            "Prohibido inventar turnos o modificar producción")
            elif block["bloque"] == "04":
                audit.check(ids == ["level_ball", "nest_ball"], "Reserva 04 alterada")
                contextual = (ROOT / "modules/capture/capture_context_ball_effects.gd").read_text(encoding="utf-8")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(encoding="utf-8")
                context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(encoding="utf-8")
                wild = (ROOT / "modules/gameplay/wild_adventure_session.gd").read_text(encoding="utf-8")
                showdown = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                level = block["level_ball"]
                nest = block["nest_ball"]
                audit.check("var catcher_level: int = -1" in context,
                            "Nivel del capturador ausente no puede ser nivel 1")
                audit.check('capture_active_level_context_missing' in contextual
                            and "context.catcher_level < 1 or context.catcher_level > 100" in contextual,
                            "Validación de Level no rechaza nivel desconocido")
                audit.check('context.catcher_level >= target.level * 4' in contextual
                            and 'context.catcher_level >= target.level * 2' in contextual
                            and 'context.catcher_level > target.level' in contextual,
                            "Faltan fronteras 8x/4x/2x de Level")
                audit.check("return minf(factor, 255.0 / species.capture_rate)" in contextual,
                            "Level requiere límite al ratio 255/capture_rate")
                audit.check('maxf((41.0 - target.level) / 10.0, 1.0)' in basic
                            and '&"nest_ball"' in basic,
                            "Nest requiere nivel del salvaje y suelo de 1x")
                audit.check('for id: StringName in ContextBallEffects.IDS:' in rules
                            and 'for id: StringName in BallEffects.IDS:' in rules,
                            "Las bolas no comparten catálogo de registro")
                audit.check("context.catcher_level = catcher.level" in wild
                            and "context.catcher_level = catcher.level" in showdown,
                            "El nivel real del activo no llega a ambas sesiones")
                audit.check('func _block_04(' in runner
                            and '"04": _block_04(bloque)' in runner
                            and 'func _check_block04_capture(' in runner
                            and 'func _check_block04_reject(' in runner,
                            "Faltan pruebas de captura y negativos de bloque04")
                audit.check("CAMP003_W03_TURN_EFFECTS.multiplier(" in runner
                            and "CAMP003_W03_BASIC_EFFECTS.multiplier(" in runner,
                            "No se comprueba adaptador existente de Level y Nest")
                audit.check('capture_active_level_context_missing' in runner
                            and 'CaptureSystem.validate_attempt(' in runner,
                            "Falta rechazo por nivel del capturador ausente")
                audit.check('rng.state == control.state' in runner
                            and 'rng.state == rng_before' in runner
                            and 'inv.quantity(id) == 1' in runner,
                            "Faltan controles de RNG y gasto en capturas/rechazos")
                audit.check(level["target_level"] == 10
                            and level["catcher_levels"] == [9, 10, 11, 19, 20, 39, 40, 100]
                            and level["independent_multipliers"] == [1, 1, 2, 2, 4, 4, 8, 8],
                            "No se cubren valores estrictos y no estrictos de Level")
                audit.check(level["capped_at_modified_rate"] == 255,
                            "Level debe saturar tasa de especie a 255")
                audit.check(level["missing_catcher_levels"] == [-1, 0, 101]
                            and level["expected_missing_reason"] ==
                            "capture_active_level_context_missing",
                            "Faltan inválidos por nivel del capturador")
                audit.check(nest["target_levels"] == [1, 30, 31, 40, 100]
                            and nest["independent_multipliers"] == [4, 1.1, 1, 1, 1],
                            "Nest requiere fronteras en 30 y 31")
                audit.check(nest["verify_without_catcher_level"] is True
                            and 'ctx.catcher_level = catcher_level' in runner,
                            "Nest no puede depender de nivel del capturador")
                audit.check({x["species_id"] for x in block["species_cases"]} ==
                            {"mew", "caterpie"} and
                            block["hp_modes"] == ["full", "one_hp"],
                            "Faltan tasa baja/alta y extremos de PS")
                audit.check(set(block["invalid_cases"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned"},
                            "Faltan negativos canónicos de Level/Nest")
                audit.check(not block["implementation_authorized"] and block["ci_required"],
                            "No existe autorización de producción")
            elif block["bloque"] == "05":
                audit.check(ids == ["fast_ball", "dream_ball"], "Reserva 05 alterada")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                system = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
                v11 = (ROOT / "tests/gameplay/item_capture_v11.gd").read_text(encoding="utf-8")
                audit.check('&"fast_ball"' in basic and '&"dream_ball"' in basic,
                            "Fast y Dream no están ambas en adaptador canónico")
                audit.check("species.base_speed >= 100" in basic and
                            "minf(4.0, 255.0 / species.capture_rate)" in basic,
                            "Fast debe usar base_speed y limitar captura a 255")
                audit.check('target.status_state.persistent_id == &"sleep"' in basic
                            and '4.0 if target.status_state.persistent_id' in basic,
                            "Dream requiere sueño persistente, no Bostezo")
                audit.check("for id: StringName in BallEffects.IDS:" in rules
                            and "crs.BallEffects.multiplier(" in system,
                            "Los efectos no llegan al motor real")
                audit.check("func _matrix()" in v11 and
                            'status_state.add_volatile(&"yawn")' in v11,
                            "Pruebas V11/Yawn históricas ausentes")
                audit.check('func _block_05(' in runner
                            and '"05": _block_05(bloque)' in runner
                            and 'func _block05_capture(' in runner
                            and 'func _block05_reject(' in runner,
                            "Falta suite acumulativa de bloque05")
                audit.check('CAMP003_W03_BASIC_EFFECTS.multiplier(' in runner
                            and 'CaptureInventoryService.resolve(' in runner
                            and 'control.randf() < expected' in runner,
                            "No se ejecuta el servicio de captura y RNG reales")
                audit.check('target.status_state.add_volatile(&"yawn")' in runner
                            and 'status(target, &"sleep")' in runner
                            and 'target.status_state.persistent_id == expected_status' in runner,
                            "No se prueba diferencia entre Yawn y sueño")
                audit.check('rng.state == control.state' in runner
                            and 'rng.state == before_rng' in runner
                            and 'inv.quantity(id) == 1' in runner
                            and 'not result.result.consume_item' in runner,
                            "Falta controlar gastos y RNG en capturas y rechazos")
                fast = {item["species_id"]: item for item in block["fast_cases"]}
                audit.check(set(fast) == {"pikachu", "mew", "raichu"},
                            "Fast debe cubrir 90, 100 y 110 de base_speed")
                audit.check(fast["pikachu"]["base_speed"] == 90
                            and fast["pikachu"]["expected_factor"] == 1
                            and fast["mew"]["base_speed"] == 100
                            and fast["mew"]["expected_factor"] == 4
                            and fast["raichu"]["base_speed"] == 110
                            and fast["raichu"]["capture_rate"] == 75
                            and fast["raichu"]["expected_factor"] == 3.4,
                            "Fast altera la frontera 100 o el límite 255")
                audit.check({item["state"]: (item["expected_factor"], item["status_bonus"])
                             for item in block["dream_states"]} ==
                            {"none": (1, 1), "yawn": (1, 1), "sleep": (4, 2)},
                            "Dream mezcla sueño persistente y volátil")
                audit.check(set(block["dream_species"]) == {"mew", "caterpie"}
                            and block["hp_modes"] == ["full", "one_hp"],
                            "Faltan especies de tasa distinta y PS extremos")
                audit.check(set(block["invalid_cases"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned",
                             "target_knocked_out"}, "Negativos Fast/Dream incompletos")
                audit.check(block["prior_evidence"]["state"] == "YA_VERIFICADO_NO_DUPLICAR"
                            and not block["implementation_authorized"],
                            "La fase no autoriza implementar efectos")
            elif block["bloque"] == "06":
                audit.check(ids == ["friend_ball", "heal_ball"], "Reserva 06 desviada")
                basic = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(encoding="utf-8")
                system = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
                inventory = (ROOT / "modules/inventory/capture_inventory_service.gd").read_text(encoding="utf-8")
                old_v11 = (ROOT / "tests/gameplay/item_capture_v11.gd").read_text(encoding="utf-8")
                router = (ROOT / "modules/creatures/storage/capture_ownership_router.gd").read_text(encoding="utf-8")
                audit.check('if id == &"friend_ball": target.friendship = 200' in basic,
                            "Amigo debe fijar amistad EXACTAMENTE en 200")
                audit.check('if id != &"heal_ball": return' in basic
                            and "target.current_hp = target.stats.max_hp" in basic
                            and "target.status_state.clear_persistent()" in basic
                            and "target.status_ids.clear()" in basic,
                            "Sana debe curar PS/estado únicamente en captura")
                audit.check('for slot: BattleMoveSlot in target.moveset: slot.current_pp = slot.max_pp' in basic,
                            "Sana restaura PP hasta máximo existente")
                audit.check('id == &"friend_ball" and (target.friendship < 0 or target.friendship > 255)' in basic
                            and 'invalid_ball_friendship_state' in basic,
                            "Amigo debe validar amistad fuera de 0..255")
                audit.check('id == &"heal_ball"' in basic
                            and 'slot.max_pp < 1 or slot.current_pp < 0 or slot.current_pp > slot.max_pp' in basic
                            and 'invalid_ball_pp_state' in basic,
                            "Sana debe validar PP incoherentes antes de gastar")
                audit.check('crs.BallEffects.on_catch(attempt.ball_id, target)' in system
                            and "if success:" in system
                            and "inventory.remove(attempt.ball_id, 1)" in inventory,
                            "Efecto postcaptura no está protegido por éxito y consumo")
                audit.check('Heal applied before storage' in old_v11
                            and 'special ball cost settled exactly once' in old_v11,
                            "No existe la evidencia histórica V11 de Sana/PC")
                audit.check("CaptureDisposition.STORAGE_REQUIRED:" in router
                            and "out.stored = storage.add_creature(c)" in router,
                            "No hay enrutamiento seguro al PC")
                audit.check('func _block_06(' in runner and
                            '"06": _block_06(bloque)' in runner
                            and 'func _block06_capture(' in runner
                            and 'func _block06_reject(' in runner
                            and 'func _block06_seed_for(' in runner,
                            "No hay ejecución real de 06 con éxito, fallo y rechazo")
                audit.check("CaptureInventoryService.resolve(" in runner
                            and "CaptureOwnershipRouter.new().route(" in runner
                            and "CaptureSystem.validate_attempt(" in runner,
                            "No se prueban servicios reales de captura, validación y PC")
                audit.check('status(target, &"sleep")' in runner
                            and 'status(target, &"poison")' in runner
                            and 'target.moveset[0].max_pp = maximum_pp' in runner
                            and 'target.friendship = friendship_value' in runner,
                            "No se preparan estados/PP/amistad reales de captura")
                audit.check('expected["friendship"] = 200' in runner
                            and 'expected["status_state"] = BattleStatusState.new().to_dict()' in runner
                            and 'slot.current_pp = slot.max_pp' in runner,
                            "Falta comparación del efecto postcaptura completo")
                audit.check("result.result.status == CaptureResult.FAILED" in runner
                            and "target.to_dict() == before" in runner
                            and "rng.state == rng_before" in runner
                            and "not result.result.consume_item" in runner,
                            "No se garantizan fallos e inválidos sin efectos")
                audit.check("rng.state == control.state" in runner
                            and "inv.quantity(id) == 1" in runner,
                            "No se contrasta una tirada/una bola")
                audit.check([c["friendship"] for c in block["friend_cases"]] ==
                            [0, 117, 200, 240, 255, 240]
                            and [c["outcome"] for c in block["friend_cases"]] ==
                            ["success", "success", "success", "success", "success", "failure"]
                            and block["expected_friendship_on_catch"] == 200,
                            "Amigo debe cubrir límite, reducción superior a 200 y fallo")
                audit.check({(c["species_id"], c["status"], c["outcome"])
                             for c in block["heal_cases"]} ==
                            {("mew", "sleep", "success"),
                             ("mew", "sleep", "failure"),
                             ("caterpie", "poison", "success"),
                             ("mew", "none", "success")},
                            "Sana no cubre sueño, veneno, normal y fallo")
                audit.check(block["invalid_friendship"] == [-1, 256]
                            and {(c["pp_current"], c["pp_max"]) for c in block["invalid_pp"]} ==
                            {(-1, 64), (65, 64), (0, 0)},
                            "No se prueban datos de amistad/PP fuera de rango")
                audit.check(set(block["invalid_cases"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned",
                             "target_knocked_out"}
                            and set(block["route_full_party"]) ==
                            {"friend_ball", "heal_ball"},
                            "Faltan rechazos o rutas reales a PC")
                audit.check(block["seed_search_range"] == [1, 4096]
                            and 'trial.randf() < probability' in runner,
                            "No se selecciona una semilla mediante RNG real")
                audit.check(not block["implementation_authorized"] and block["ci_required"]
                            and block["prior_evidence"]["state"] == "YA_VERIFICADO_NO_DUPLICAR",
                            "El bloque06 no autoriza rediseñar captura")
            elif block["bloque"] == "07":
                audit.check(ids == ["safari_ball", "sport_ball"],
                            "IDs de Safari/Sport fuera de la reserva 07")
                effects = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(encoding="utf-8")
                context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(encoding="utf-8")
                engine = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                inventory = (ROOT / "modules/inventory/capture_inventory_service.gd").read_text(encoding="utf-8")
                historical = (ROOT / "tests/gameplay/item_capture_v11.gd").read_text(encoding="utf-8")
                audit.check('&"safari_ball", &"sport_ball": return 1.5' in effects,
                            "El factor genérico de ambas bolas ha cambiado")
                audit.check('&"safari_ball"' in effects
                            and '&"sport_ball"' in effects
                            and "for id: StringName in BallEffects.IDS:" in rules,
                            "Registro de Safari/Sport no compartido")
                audit.check('crs.BallEffects.multiplier(attempt.ball_id, target, species)' in engine
                            and 'rng.randf() < p' in engine
                            and 'inventory.remove(attempt.ball_id, 1)' in inventory,
                            "Faltan integración, RNG o consumo reales")
                fields = set(re.findall(r"^var\s+([a-zA-Z_]\w*)", context, re.M))
                audit.check(not any("safari" in field or "sport" in field
                                    or "contest" in field or "encounter_mode" in field
                                    for field in fields),
                            "El motor cambió el contrato de contexto; reauditar")
                audit.check('safari_ball' not in engine
                            and 'sport_ball' not in engine,
                            "Existe validación contextual desconocida; no afirmar ausencia")
                audit.check("func _matrix()" in historical,
                            "Se perdió el test histórico; prohibido duplicar V11")
                audit.check('func _block_07(' in runner
                            and '"07": _block_07(bloque)' in runner
                            and 'func _block07_reject(' in runner,
                            "Faltan casos Godot del bloque 07")
                audit.check('CAMP003_W03_BASIC_EFFECTS.multiplier(' in runner
                            and 'CaptureInventoryService.resolve(' in runner
                            and 'CaptureRuleset.ordered_ball_ids().count(id) == 1' in runner,
                            "Falta factor real o protección contra bolas duplicadas")
                audit.check('rng.state == control.state' in runner
                            and 'rng.state == before_rng' in runner
                            and 'inventory.quantity(id) == 1' in runner,
                            "Falta comprobar un RNG, una bola y rechazo sin gasto")
                audit.check('target.to_dict() == before' in runner
                            and 'results.has("safari_ball")' in runner
                            and 'results.has("sport_ball")' in runner,
                            "No se comprueba inmutabilidad/paridad de ambas bolas")
                audit.check(block["current_multiplier"] == 1.5
                            and block["context_effect_certified"] is False,
                            "Factor global no significa contexto Safari funcional")
                audit.check(block["prior_evidence"]["state"] ==
                            "FACTOR_YA_IMPLEMENTADO_CONTEXTO_PENDIENTE"
                            and block["implementation_authorized"] is False,
                            "Intento de certificar recinto sin fuente/gate")
                audit.check(block["missing_authoritative_signals"] ==
                            ["encounter_is_safari", "encounter_is_bug_catching_contest"],
                            "Faltan contratos independientes de Safari y concurso")
                audit.check(block["contexts"] ==
                            [{"name": "sin_origen", "completed_turns": -1, "catcher_level": -1},
                             {"name": "combate_documentado", "completed_turns": 0, "catcher_level": 35}],
                            "El fixture pretende simular origen inexistente")
                audit.check({row["species_id"] for row in block["cases"]} ==
                            {"mew", "caterpie"}
                            and block["hp_modes"] == ["full", "one_hp"]
                            and block["statuses"] == ["none", "sleep"],
                            "Falta comparación de tasa, PS y sueño")
                audit.check(set(block["invalid_cases"]) ==
                            {"trainer_battle_not_capturable", "item_not_owned",
                             "target_knocked_out", "battle_finished"},
                            "Faltan rechazos generales de Safari/Sport")
                audit.check(block["ci_required"] and block["required_new_gate"],
                            "La dependencia debe quedar registrada para IA6")
            elif block["bloque"] == "08":
                audit.check(ids == ["luxury_ball", "lure_ball"], "Reserva 08 no coincide")
                rules = (ROOT / "modules/capture/capture_ruleset.gd").read_text(encoding="utf-8")
                effects = (ROOT / "modules/capture/capture_ball_effects.gd").read_text(encoding="utf-8")
                context_effects = (ROOT / "modules/capture/capture_context_ball_effects.gd").read_text(encoding="utf-8")
                battle_context = (ROOT / "modules/capture/capture_battle_context.gd").read_text(encoding="utf-8")
                engine = (ROOT / "modules/capture/capture_system.gd").read_text(encoding="utf-8")
                inventory = (ROOT / "modules/inventory/capture_inventory_service.gd").read_text(encoding="utf-8")
                audit.check(all(f'&"{ball}"' not in rules
                                and f'&"{ball}"' not in effects
                                and f'&"{ball}"' not in context_effects
                                for ball in ids),
                            "Se han registrado bolas nuevas; reauditar los contratos de captura")
                audit.check(all(f'"{signal}"' not in battle_context
                                for signal in block["missing_authoritative_signals"]),
                            "Se añadió contexto: revisar autenticidad y propagación")
                audit.check(block["missing_authoritative_signals"] ==
                            ["capture_origin_ball_for_friendship_gain", "encounter_is_fishing"],
                            "Faltan señales autoritativas de amistad/pesca")
                audit.check(block["prior_evidence"]["state"] == "DEPENDENCIA_COMPARTIDA"
                            and block["functional_effect_certified"] is False,
                            "No certificar multiplicador ni amistad futura")
                audit.check(block["expected_current_rejection"] == "unknown_ball"
                            and 'return "unknown_ball"' in engine,
                            "No existe rechazo seguro de bola desconocida")
                audit.check("CaptureSystem.validate_attempt(attempt, catalogs)" in inventory
                            and "inventory.remove(attempt.ball_id, 1)" in inventory,
                            "El rechazo debe preceder a consumo")
                audit.check('func _block_08(' in runner
                            and '"08": _block_08(bloque)' in runner
                            and "CaptureInventoryService.resolve(" in runner
                            and "CaptureSystem.validate_attempt(attempt, catalogs)" in runner,
                            "Falta integración real del test de rechazo W03 08")
                audit.check("rng.state == before_rng" in runner
                            and "inv.to_dict() == before_inv" in runner
                            and "target.to_dict() == before_target" in runner,
                            "Falta verificar ausencia de efectos secundarios")
                audit.check({x["species_id"] for x in block["cases"]} ==
                            {"mew", "caterpie"} and block["hp_modes"] == ["full", "one_hp"],
                            "No se cubre diversidad de especies y PS")
                audit.check(len(block["contexts"]) == 2
                            and block["contexts"][0]["name"] == "sin_senales"
                            and block["contexts"][1]["name"] == "combate_real_sin_pesca",
                            "No crear señales falsas de pesca")
            else:
                audit.check(False, "Falta contrato incremental específico para " + block["bloque"])
        audit.check(audit.checks > 0, "Sin comprobaciones")
    except (ValueError, OSError, KeyError, IndexError, AssertionError, TypeError) as exc:
        print("CAMP003_W03_PY FAIL " + str(exc), file=sys.stderr)
        return 1
    print(f"CAMP003_W03_PY PASS blocks={len(done)} checks={audit.checks}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
