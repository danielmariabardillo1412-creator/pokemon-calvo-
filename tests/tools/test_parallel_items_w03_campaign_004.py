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
