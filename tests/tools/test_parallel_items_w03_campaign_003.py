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
