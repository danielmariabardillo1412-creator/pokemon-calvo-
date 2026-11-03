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
                check('const IDS: Array[StringName] = [&"quick_ball", &"timer_ball", &"level_ball"]'
                      in effects and "ContextBallEffects.IDS" in rules,
                      "Referencia positiva de contexto previo cambió")
                check('CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"quick_ball", ctx)'
                      in runner and '"timer_ball", target, species, ctx), 1.0'
                      in runner and '"level_ball", target, species, ctx), 4.0'
                      in runner, "Godot no contrasta productores funcionales existentes")
                check("unknown_ball" not in runner,
                      "La campaña repite la prueba negativa de CAMP004")
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
