#!/usr/bin/env python3
"""W03 AUTORUN V1: audit real producer provenance and frozen positive regression gates.
This is an audit; negative producer evidence is NEVER reported as new functional capture.
"""
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
PROGRESS = BASE / "reports/W03/AUTORUN_V1_PROGRESS.csv"
PASS = 0

def check(ok: bool, message: str) -> None:
    global PASS
    PASS += 1
    if not ok:
        raise AssertionError(message)

def src(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def main() -> None:
    with PROGRESS.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    check(len(rows) == 10, "exactly ten queue entries")
    check([r["fila"] for r in rows] == [f"{i:02d}" for i in range(1, 11)], "queue ordered")
    check(all(r["estado"] not in ("PENDIENTE", "EN_VERIFICACION", "") for r in rows), "unexamined row")
    check([r["estado"] for r in rows[:4]] == ["BLOQUEADO"] * 4, "producer blocked rows")
    check(rows[4]["estado"] == "PARCIAL" and rows[5]["estado"] == "BLOQUEADO", "special capture context pending")
    check(rows[6]["estado"] == "CERTIFICADO_EXISTENTE", "real previous positive row 07")
    check(all(r["estado"] == "QA_VERIFICADA" for r in rows[7:]), "QA tests actually scheduled")
    check(sum(r["funcional_nuevo"] == "true" for r in rows) == 0, "no new effects claimed")

    ctx = src("modules/capture/capture_battle_context.gd")
    for field in ("var completed_turns: int", "var catcher_level: int", "var is_wild: bool"):
        check(field in ctx, f"known context source changed: {field}")
    missing = ["encounter_origin", "fishing_method", "world_is_dark", "pokedex_caught",
               "is_safari_zone", "contest_capture_mode", "individual_gender"]
    for field in missing:
        check(field not in ctx, f"producer contract changed; re-audit {field}")
    showdown = src("modules/gameplay/showdown_adventure_session.gd")
    native = src("modules/gameplay/wild_adventure_session.gd")
    check("CaptureBattleContext.new()" in showdown and "CaptureBattleContext.new()" in native,
          "capture owner constructs actual battle context")
    rules = src("modules/capture/capture_ruleset.gd")
    basic = src("modules/capture/capture_ball_effects.gd")
    contextual = src("modules/capture/capture_context_ball_effects.gd")
    for missing_ball in ("dusk_ball", "dive_ball", "lure_ball", "love_ball", "moon_ball", "heavy_ball", "beast_ball"):
        check(f'&"{missing_ball}"' not in basic and f'&"{missing_ball}"' not in contextual,
              f"{missing_ball}: review new rule before marking blocked")
    # Repeat Ball is the sole approved later promotion; historical V1 findings remain frozen.
    check('&"repeat_ball"' in contextual
          and 'previously_caught_base_species' in contextual
          and (ROOT / "tests/gameplay/parallel_items_w03_repeat_history_v2.gd").exists(),
          "repeat promotion must include dedicated positive regression")
    check('&"safari_ball", &"sport_ball": return 1.5' in basic, "existing ungated modifier changed")
    check('&"friend_ball": target.friendship = 200' in basic
          and '&"heal_ball"' in basic and 'target.current_hp = target.stats.max_hp' in basic,
          "existing on-catch effects changed")
    for token in ['&"quick_ball": return 5.0 if context.completed_turns == 0 else 1.0',
                  '&"timer_ball": return minf(1.0 + 0.3 * context.completed_turns, 4.0)']:
        check(token in contextual, "existing battle-produced multiplier changed")
    check("ContextBallEffects.IDS" in rules and "BallEffects.IDS" in rules, "registrations changed")

    camp005 = src("tests/gameplay/parallel_items_w03_campaign_005.gd")
    camp006 = src("tests/gameplay/parallel_items_w03_campaign_006.gd")
    l3 = src("tests/gameplay/parallel_items_w03_repel_l3.gd")
    for marker in ('func _block_05(', 'func _block_09(', 'func _block_10(',
                   'CaptureInventoryService.resolve(', 'friend_ball', 'heal_ball', 'quick_ball', 'timer_ball'):
        check(marker in camp005, f"existing real capture regression missing: {marker}")
    for marker in ('func _block_01(', 'func _block_02(', 'func _block_03(',
                   'bag._use.pressed.emit()', 'await save.load_game()'):
        check(marker in camp006, f"existing rope/repel regression missing: {marker}")
    for marker in ('scene._native_battles.on_step(grass_position)', 
                   'not await scene._native_battles.load_game()', 
                   'await scene._native_battles.load_game()',
                   'effect.remaining_steps == 0', 
                   'equal-level wild is not repelled'):
        check(marker in l3, f"repel L3 real-world positive/negative regression missing: {marker}")
    progress = src("docs/coordination/items_parallel_v1/reports/W03/AUTORUN_V1_PRODUCER_BLOCKERS.md")
    check("EncounterOrigin" in progress and "Pokédex" in progress, "single precise producer ticket missing")
    print(f"W03_AUTORUN_V1_PY PASS examined=10 existing_functional_rows=1 new_functional=0 checks={PASS}")

if __name__ == "__main__":
    main()
