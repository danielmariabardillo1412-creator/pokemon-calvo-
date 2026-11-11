#!/usr/bin/env python3
"""W03 V2: producer contracts for region-specific balls; no fabricated contexts."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
CAP = ROOT / "modules" / "capture"
B01 = ("poke_ball", "great_ball", "ultra_ball", "master_ball",
       "nest_ball", "fast_ball", "dream_ball", "heal_ball",
       "premier_ball", "friend_ball")
B02 = ("safari_ball", "sport_ball", "cherish_ball", "quick_ball",
       "timer_ball", "level_ball", "net_ball", "repeat_ball",
       "dive_ball", "dusk_ball")
B03 = ("lure_ball", "love_ball", "moon_ball", "heavy_ball", "beast_ball")
CONTEXTUAL = (*B02[-2:], *B03)
checks = 0


def ck(condition: bool, message: str):
    global checks
    checks += 1
    if not condition:
        raise AssertionError(message)


def src(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main():
    ck(len(B01 + B02 + B03) == 25, "exactly 25 authorized unique ball IDs")
    ck(len(set(B01 + B02 + B03)) == 25, "all IDs unique")
    rules = src(CAP / "capture_ruleset.gd")
    basic = src(CAP / "capture_ball_effects.gd")
    battle = src(CAP / "capture_context_ball_effects.gd")
    context = src(CAP / "capture_battle_context.gd")
    native = src(ROOT / "modules/gameplay/showdown_adventure_session.gd")
    native_capture = native.split("func capture(", 1)[1].split("\nfunc ", 1)[0]
    registered = set(re.findall(r'&"([a-z][a-z0-9_]+)"',
                                rules.split("func _init(", 1)[0]
                                + basic.split("static func multiplier(", 1)[0]
                                + battle.split("static func validation_error(", 1)[0]))
    for item in B01:
        ck(item in registered, f"B01 {item} registered in capture catalog")
    for item in B02[:8]:
        ck(item in registered, f"B02 {item} pre-registered")
    for item in CONTEXTUAL:
        ck(item not in registered,
           f"{item}: new registration requires authentic regional producer")
    ck("var previously_caught_base_species: bool" in context,
       "existing live Repeat source")
    ck("context.previously_caught_base_species = player.has_previously_caught" in native_capture,
       "Repeat ledger from native owner")
    ck("context.completed_turns = battle_state().turn" in native_capture,
       "Quick/Timer actual native turn count")
    ck("context.catcher_level = catcher.level" in native_capture,
       "Level Ball actual native lead")
    ck("&\"safari_ball\", &\"sport_ball\": return 1.5" in basic,
       "Safari/Sport existing ungated x1.5 must not be credited as zone gating")
    for field in ("is_safari_zone", "is_bug_contest_zone", "fishing_method",
                  "encounter_origin", "surfing", "underwater", "world_is_dark",
                  "is_cave", "individual_gender", "moon_stone_evolution",
                  "species_weight", "is_ultra_beast"):
        ck(re.search(r"\bvar " + field + r"\b", context) is None,
           "missing world-owned producer: " + field)
        ck("context." + field not in native_capture,
           "native may not synthesize regional context: " + field)
    ck("var is_wild: bool" in context, "native wild context exists")
    ck("var target_side_id: StringName" in context, "native target side exists")
    print(f"W03_CONT_V2_SOURCE PASS checked=25 blocked_context=7 partial_zone=2 checks={checks}")
    print("W03_CONT_V2_SOURCE_TICKET missing authentic world producers: "
          "dive/fishing-surf; dusk/night-cave; lure/fishing; love/individual-sex; "
          "moon/evolution-line; heavy/weight-form; beast/ultra-beast; "
          "Safari/Sport zone/contest")


if __name__ == "__main__":
    main()
