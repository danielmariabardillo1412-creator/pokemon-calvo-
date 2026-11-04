#!/usr/bin/env python3
"""IA2/W02 CAMP006 block01: reproduce/regress actual CAMP005 failure 41742682811."""
from __future__ import annotations

import argparse
import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_006.json"
OLD = ROOT / "tests/fixtures/parallel_items/w02_campaign_005.json"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv"
REF = ROOT / "tests/fixtures/progression_growth_curves/reference_contract.json"
GODOT = ROOT / "tests/gameplay/parallel_items_w02_campaign_005.gd"
RUNNER006 = ROOT / "tests/gameplay/parallel_items_w02_campaign_006.gd"
RULES = ROOT / "modules/creatures/progression/progression_ruleset.gd"

class CheckError(AssertionError):
    pass

checks = 0
def require(condition: bool, name: str) -> None:
    global checks
    checks += 1
    if not condition:
        raise CheckError(name)

def verify() -> None:
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    old = json.loads(OLD.read_text(encoding="utf-8"))
    with PROGRESS.open(encoding="utf-8", newline="") as file:
        progress = list(csv.DictReader(file))
    require(data["worker"] == "W02" and data["campaign"] == "CAMP_006", "Identity")
    require(data["kind"] == "RECOVERY_THEN_NEW", "Family")
    require(data["status"] == "CI005_RECOVERY_AWAITING_RUN", "Not certified prematurely")
    require(len(data["blocks"]) == len(progress) == 1, "Only block01 permitted")
    require(data["blocks"][0]["block"] == progress[0]["bloque"] == "01", "Progress continuity")
    require(data["blocks"][0]["ids"] == progress[0]["ids"].split(";") ==
            ["exp_candy_xl", "relaxed_mint"], "Exact reserved IDs")
    require(progress[0]["estado"] == "EN_CI_AUTOMATICA", "CI remains pending")
    require(old["completed_blocks"] == list(range(1, 11)) and len(old["blocks"]) == 10,
            "All 10 CAMP005 blocks preserved")
    require(sum(len(x["cases"]) for x in old["blocks"]) == 288, "288 CAMP005 test cases preserved")
    case_index = {case["scenario"]: case for block in old["blocks"] for case in block["cases"]}
    require(len(case_index) == 288, "No duplicate CAMP005 cases")
    cases = data["blocks"][0]["cases"]
    require(len(cases) == 3, "Three distinct recovery regressions")
    require([x["scenario"] for x in cases] == [
        "exp_candy_xl_level99_gain", "exp_candy_xl_level99_cap_50xp",
        "relaxed_mint_level100"], "Recovery case identity")
    x, cap, mint = cases
    source_x = case_index[x["scenario"]]
    source_cap = case_index[cap["scenario"]]
    source_mint = case_index[mint["scenario"]]
    require(source_x["id"] == "exp_candy_xl" and source_x["exp_amount"] == 30000,
            "Real XL nominal amount")
    require(source_x["level"] == 99 and source_x.get("expect_no_cap") is True
            and not source_x.get("expect_cap"), "XL level99 asserts NON cap, not just omitted check")
    table = json.loads(REF.read_text(encoding="utf-8"))["tables"]["medium-slow"]["levels_1_to_100"]
    xp99, xp100 = int(table[98]), int(table[99])
    require((xp99, xp100) == (1027103, 1059860), "Independent growth table values")
    require(xp100 - xp99 == 32757 > 30000, "XL cannot cap from initial level99")
    require(x["medium_slow_level99"] == xp99 and x["medium_slow_level100"] == xp100,
            "Fixture independent curve numbers")
    require(x["expected_exp"] == xp99 + 30000 and x["exp_remaining"] == 2757
            and x["expected_level"] == 99 and x["expected_cap"] is False,
            "XL actual remaining XP expected")
    require(source_cap["exp_until_next"] == 50 and source_cap.get("expect_cap") is True
            and source_cap.get("expected_exp_gain") == 50, "XL cap near threshold not weakened")
    require(cap["expected_exp"] == xp100 and cap["expected_exp_gain"] == 50
            and cap["expected_level"] == 100 and cap["expected_cap"] is True,
            "XL cap cross-threshold positive case")
    require(source_mint["kind"] == "mint_dependency" and source_mint["level"] == 100
            and source_mint["applies"] is False, "Mint case preserved, still negative")
    require(mint["expected_applies"] is False and mint["expected_status"] == "DEPENDENCY_MISSING"
            and mint["expected_reason"] == "field_effect_not_connected",
            "Mint explicit no-consumption rejection")
    gd = GODOT.read_text(encoding="utf-8")
    gd6 = RUNNER006.read_text(encoding="utf-8")
    rules = RULES.read_text(encoding="utf-8")
    for fragment in ('bool(spec.get("expect_no_cap", false))',
                     'expected_exp < cap_exp and gain_expected == nominal_exp',
                     'next_level == start_level and now.level == start_level'):
        require(fragment in gd, "Godot old-suite positive regression: " + fragment)
    for fragment in ("_probe_training(spec, mode)", "CAMP006_W02_GODOT",
                     "exp_candy_xl_level99_gain", "relaxed_mint_level100"):
        require(fragment in gd6, "New Godot recovery runner: " + fragment)
    require('"medium-slow"' in rules, "No growth model rewrite")
    for mutation in (
        lambda d: d["blocks"][0]["cases"][0].update({"expected_exp": xp100}),
        lambda d: d["blocks"][0]["cases"][0].update({"expected_level": 100}),
        lambda d: d["blocks"][0]["cases"][0].update({"exp_remaining": 0}),
        lambda d: d["blocks"][0]["cases"][1].update({"expected_exp_gain": 30000}),
        lambda d: d["blocks"][0]["cases"][1].update({"expected_cap": False}),
        lambda d: d["blocks"][0]["cases"][2].update({"expected_applies": True}),
    ):
        altered = copy.deepcopy(data)
        mutation(altered)
        after = altered["blocks"][0]["cases"]
        require(after != cases, "Adversarial changed fixture")
        require(not (after[0]["expected_exp"] == xp99 + 30000
                     and after[0]["expected_level"] == 99
                     and after[0]["exp_remaining"] == 2757
                     and after[1]["expected_exp_gain"] == 50
                     and after[1]["expected_cap"] is True
                     and after[2]["expected_applies"] is False), "Adversarial contract rejected")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    verify()
    print(f"CAMP006_W02_PY PASS blocks=1 checks={checks}")

if __name__ == "__main__":
    main()
