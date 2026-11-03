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
                    "quit(1 if not errors.is_empty() else 0)" in runner,
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
            else:
                # Un nuevo bloque sin puerta de test concreta debe fallar, no presentar PASS vacío.
                audit.check(False, "Falta contrato incremental específico para " + block["bloque"])
        audit.check(audit.checks > 0, "Sin comprobaciones")
    except (ValueError, OSError, KeyError, IndexError, AssertionError, TypeError) as exc:
        print("CAMP003_W03_PY FAIL " + str(exc), file=sys.stderr)
        return 1
    print(f"CAMP003_W03_PY PASS blocks={len(done)} checks={audit.checks}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
