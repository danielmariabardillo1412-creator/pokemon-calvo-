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
    require(data["status"] == "CI005_RECOVERED_BLOCK03_DEPENDENCY", "Block02 must not claim L2")
    require(data["recovery_gate"]["run_id"] == 41763921080
            and data["recovery_gate"]["conclusion"] == "success"
            and data["recovery_gate"]["head_sha"] == "2abcc2ae9644b8821d9dae6f26214b1a8fa347fc", "Recovered CI run referenced exactly")
    require(len(data["blocks"]) == len(progress) == 3, "Only blocks01-03, not block04")
    require(data["blocks"][0]["block"] == progress[0]["bloque"] == "01", "Progress continuity")
    require(data["blocks"][0]["ids"] == progress[0]["ids"].split(";") ==
            ["exp_candy_xl", "relaxed_mint"], "Exact reserved IDs")
    require(progress[0]["estado"] == "CI_RECUPERADA_VERIFICADA"
            and progress[0]["ci_run"] == "41763921080", "Recovery CI actually verified")
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


def verify_mint_dependency(data: dict, progress: list[dict]) -> None:
    """A single missing shared producer, not N duplicate negative mint tests."""
    block = data["blocks"][1]
    require(block["block"] == progress[1]["bloque"] == "02", "Exactly block02 in progress")
    ids = ["gentle_mint", "hasty_mint", "lax_mint"]
    require(block["family"] == "MINT_ENGINE" and block["ids"] == ids
            and progress[1]["ids"].split(";") == ids, "Three assigned new mints")
    require(block["status"] == "DEPENDENCY_DOCUMENTED_NOT_FUNCTIONAL"
            and progress[1]["estado"] == "DEPENDENCIA_DOCUMENTADA", "No false L2")
    require(progress[1]["ci_run"] == "41778869360", "Block02 CI success does not imply L2")
    expected_modifiers = {
        "gentle": {"nature_id": "gentle", "up": "special_defense", "down": "defense"},
        "hasty": {"nature_id": "hasty", "up": "speed", "down": "defense"},
        "lax": {"nature_id": "lax", "up": "defense", "down": "special_defense"},
    }
    require(block["expected_nature_modifiers"] == expected_modifiers,
            "Independent mapping of three NATURE_MODIFIERS")
    rules = RULES.read_text(encoding="utf-8")
    for name, contract in expected_modifiers.items():
        token = ('&"' + name + '": ["' + contract["up"] + '", "' +
                 contract["down"] + '"]')
        require(token in rules, "Actual nature multiplier " + name)
    cases = block["cases"]
    require(cases == [{
        "scenario": "gentle_mint_missing_effect_route", "id": "gentle_mint",
        "kind": "mint_dependency", "applies": False, "nature": "hardy",
        "expect_status": "DEPENDENCY_MISSING",
        "expect_reason": "field_effect_not_connected"
    }], "Exactly one representative negative sentinel, not repetitive tests")
    deps = block["dependency"]
    require(deps["key"] == "MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02"
            and deps["level"] == "L1_DEPENDENCY_NOT_L2", "One shared issue for all three")
    require(deps["owner"].startswith("IA6:") and bool(deps["positive_test_pending"])
            and bool(deps["producer"]) and bool(deps["consumers"]),
            "Shared producer, consumers, owner and positive test explicitly identified")
    for path in block["source_evidence"]:
        require((ROOT / path).is_file(), "Grounded source not found " + path)
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
    effects = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    stats = (ROOT / "modules/creatures/progression/stat_calculator.gd").read_text(encoding="utf-8")
    with (ROOT / "config/item_selection_v1.json").open(encoding="utf-8") as file:
        policy = json.load(file)
    require('return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")' in service,
            "No item executor fallback changed unexpectedly")
    for id in ids:
        require(id not in service and id not in effects,
                "Mint executor appeared; reauditoría L2 required " + id)
        require(id not in policy["excluded_ids"]
                and "nature_mints" not in policy["excluded_categories"],
                "Mint excluded by policy instead of missing handler " + id)
    require('var nature_id: StringName' in creature
            and '"nature_id": String(nature_id)' in creature
            and "effective_nature_id" not in creature,
            "Original vs effective nature schema changed; redo integration")
    require('StatCalculator.compute(base, ivs, evs, nature_id, level)' in creature
            and 'ProgressionRuleset.nature_multiplier(nature_id, key)' in stats,
            "Stat consumer still reads original nature only")
    runner = RUNNER006.read_text(encoding="utf-8")
    require('gentle_mint_missing_effect_route' in runner
            and '_probe_training(mint_spec, mode)' in runner,
            "One native rejection across 3 modes with SaveV2 is required")
    for path in ["modules/save/save_game_data.gd",
                 "modules/save/save_game_repository.gd"]:
        require((ROOT / path).is_file(), "SaveV2 shared dependency exists: " + path)


def verify_block03(data: dict, progress: list[dict]) -> None:
    block = data["blocks"][2]
    ids = ["lonely_mint", "mild_mint", "naive_mint"]
    expected = {
        "lonely": {"nature_id": "lonely", "up": "attack", "down": "defense"},
        "mild": {"nature_id": "mild", "up": "special_attack", "down": "defense"},
        "naive": {"nature_id": "naive", "up": "speed", "down": "special_defense"},
    }
    require(block["block"] == progress[2]["bloque"] == "03"
            and block["family"] == "MINT_ENGINE"
            and block["ids"] == progress[2]["ids"].split(";") == ids,
            "Authorized block03 identity")
    require(block["status"] == "DEPENDENCY_DOCUMENTED_NOT_FUNCTIONAL"
            and progress[2]["estado"] == "DEPENDENCIA_DOCUMENTADA"
            and progress[2]["ci_run"] == "CI_BLOQUE03_PENDIENTE",
            "Block03 cannot claim L2 or completed CI")
    require(block["dependency_ref"] == data["blocks"][1]["dependency"]["key"]
            == "MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02"
            and block["dependency_owner"] == "IA6", "Reused shared IA6 dependency")
    require(block["cases"] == []
            and "gentle_mint_missing_effect_route" in block["native_negative_reuse"],
            "No redundant negatives; native three-mode sentinel reused")
    require(block["expected_nature_modifiers"] == expected
            and "SaveV2" in block["positive_test_pending"],
            "Independent stat mapping and pending positive SaveV2 contract")
    rules = RULES.read_text(encoding="utf-8")
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
    effects = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    with (ROOT / "config/item_selection_v1.json").open(encoding="utf-8") as fh:
        policy = json.load(fh)
    for item, nature in zip(ids, expected):
        fields = expected[nature]
        token = ('&"' + nature + '": ["' + fields["up"] + '", "' +
                 fields["down"] + '"]')
        require(token in rules, "Native nature modifier " + nature)
        require(item not in service and item not in effects,
                "Handler added; reauditar efectos positivos " + item)
        require(item not in policy["excluded_ids"] and
                "nature_mints" not in policy["excluded_categories"],
                "Policy unexpectedly excluded mint " + item)
    require("effective_nature_id" not in creature
            and 'StatCalculator.compute(base, ivs, evs, nature_id, level)' in creature,
            "Pending nature producer still missing")
    for path in block["source_evidence"]:
        require((ROOT / path).is_file(), "Grounded source missing: " + path)
    runner = RUNNER006.read_text(encoding="utf-8")
    require("block=03 ids=3 checks=" in runner
            and "gentle_mint_missing_effect_route" in runner,
            "Godot native negative reused and block03 checked")
    for mutation in (
        lambda b: b["ids"].append("rash_mint"),
        lambda b: b.update({"status": "FUNCTIONAL"}),
        lambda b: b.update({"dependency_ref": "invalid"}),
        lambda b: b["cases"].append({"fake": True}),
        lambda b: b["expected_nature_modifiers"]["naive"].update({"up": "attack"}),
    ):
        changed = copy.deepcopy(block)
        mutation(changed)
        require(changed != block, "Mutation control detected")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    verify()
    print(f"CAMP006_W02_PY PASS blocks=1 checks={checks}")
    with FIXTURE.open(encoding="utf-8") as file:
        data = json.load(file)
    with PROGRESS.open(encoding="utf-8", newline="") as file:
        progress = list(csv.DictReader(file))
    verify_mint_dependency(data, progress)
    print(f"CAMP006_W02_DEPENDENCY BLOCKED block=02 ids=3 checks={checks}")
    verify_block03(data, progress)
    print(f"CAMP006_W02_DEPENDENCY BLOCKED block=03 ids=3 checks={checks}")

if __name__ == "__main__":
    main()
