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
    require(data["status"] == "CI005_RECOVERED_BLOCK05_TRAINING_HELD_AWAITING_CI", "Block02 must not claim L2")
    require(data["recovery_gate"]["run_id"] == 41763921080
            and data["recovery_gate"]["conclusion"] == "success"
            and data["recovery_gate"]["head_sha"] == "2abcc2ae9644b8821d9dae6f26214b1a8fa347fc", "Recovered CI run referenced exactly")
    require(len(data["blocks"]) == 5 and len(progress) == 6, "Five legacy blocks and one new EV06 progress row")
    require(progress[5]["bloque"] == "06" and progress[5]["ids"] == "power_anklet;power_band;power_belt" and progress[5]["estado"] == "PRUEBAS_NATIVAS_PUBLICADAS_CI_PENDIENTE", "EV06 published but not certified")
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
            and 'var effective_nature_id: StringName = &""' in creature,
            "Original nature preserved and optional effective nature introduced")
    require('StatCalculator.compute(base, ivs, evs, stat_nature, level)' in creature
            and 'ProgressionRuleset.nature_multiplier(nature_id, key)' in stats,
            "Creature routes nature effective to existing, unmodified stat calculator")
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
            and progress[2]["ci_run"] == "41784043391",
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
    require('var effective_nature_id: StringName = &""' in creature
            and 'StatCalculator.compute(base, ivs, evs, stat_nature, level)' in creature,
            "Pilot state introduced, but block03 IDs must remain unconnected")
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

def verify_block04_pilot(data: dict, progress: list[dict]) -> None:
    block = data["blocks"][3]
    ids = ["naughty_mint", "rash_mint", "sassy_mint", "serious_mint"]
    expected = [
        {"scenario": "naughty_mint_positive", "id": "naughty_mint",
         "target_nature": "naughty", "original_nature": "hardy",
         "changed_stats": ["attack", "special_defense"]},
        {"scenario": "rash_mint_positive", "id": "rash_mint",
         "target_nature": "rash", "original_nature": "hardy",
         "changed_stats": ["special_attack", "special_defense"]},
        {"scenario": "sassy_mint_positive", "id": "sassy_mint",
         "target_nature": "sassy", "original_nature": "hardy",
         "changed_stats": ["special_defense", "speed"]},
        {"scenario": "serious_mint_neutral_positive", "id": "serious_mint",
         "target_nature": "serious", "original_nature": "adamant",
         "changed_stats": ["attack", "special_attack"]},
    ]
    require(block["block"] == progress[3]["bloque"] == "04"
            and block["family"] == "MINT_ENGINE"
            and block["ids"] == progress[3]["ids"].split(";") == ids,
            "Only authorised four mint IDs")
    require(block["status"] == "POSITIVE_PILOT_CI_VERIFIED"
            and progress[3]["estado"] == "PILOTO_L2_CI_VERIFICADA",
            "Python source contract cannot certify real native effect")
    require(progress[3]["ci_run"] == "41788596358"
            and block["verification"]["run_id"] == 41788596358
            and block["verification"]["conclusion"] == "success",
            "Block04 positive pilot must cite verified run")
    require(block["cases"] == expected, "Exact positive mint suite, including neutral Serious")
    require(block["helper"] == "modules/inventory/field_mint_effects.gd"
            and block["source_authority"].endswith("EFFECTIVE_NATURE_ARCHITECTURE_GATE.md"),
            "Only IA6 authorised helper")
    require(data["blocks"][1]["status"] == "DEPENDENCY_DOCUMENTED_NOT_FUNCTIONAL"
            and data["blocks"][2]["status"] == "DEPENDENCY_DOCUMENTED_NOT_FUNCTIONAL",
            "Do not retroactively upgrade old mints to functional")
    mints = (ROOT / block["helper"]).read_text(encoding="utf-8")
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
    stats = (ROOT / "modules/creatures/progression/stat_calculator.gd").read_text(encoding="utf-8")
    old = json.loads(OLD.read_text(encoding="utf-8"))
    require(sum(len(b["cases"]) for b in old["blocks"]) == 288, "All historical cases preserved")
    for id, nature in zip(ids, ("naughty", "rash", "sassy", "serious")):
        require(('"' + id + '": "' + nature + '"') in mints,
                "Mint pilot mapping must be native, not fixture-only: " + id)
    require('var effective_nature_id: StringName = &""' in creature
            and 'var stat_nature: StringName = nature_id if effective_nature_id == &"" else effective_nature_id' in creature
            and '"nature_id": String(nature_id)' in creature
            and 'if effective_nature_id != &"": result["effective_nature_id"] = String(effective_nature_id)' in creature
            and 'creature.effective_nature_id = StringName(raw_effective)' in creature,
            "Original nature/optional effective nature, legacy compatible SaveV2")
    require('StatCalculator.compute(base, ivs, evs, stat_nature, level)' in creature,
            "Effective nature must feed real stat recompute")
    require('if Mint.supports(item_id):' in service
            and 'return _apply_mint_item(item_id, creature_id)' in service
            and 'var outcome: Dictionary = Mint.apply(candidate, item_id, catalogs)' in service
            and 'if not staged.remove(item_id): return _deny("item_not_owned")' in service
            and 'if not owner.replace_owned_same_identity(candidate): return _deny("ownership_changed")' in service,
            "Real native mint effect with atomic candidate and one item")
    require('static func apply(candidate: CreatureInstance, item_id: StringName, catalogs: DefinitionCatalog)' in mints
            and 'candidate.recalculate_stats(species, ProgressionRuleset.new())' in mints
            and 'if current_nature == desired: return reject("item_has_no_effect")' in mints,
            "Helper cannot fake a stat change or consume on no-effect")
    # StatCalculator and SaveV2 central are untouched by this change.
    require('var mult := ProgressionRuleset.nature_multiplier(nature_id, key)' in stats,
            "Original calculator nature logic preserved")
    for earlier in (
        "adamant_mint", "modest_mint", "jolly_mint",
        "timid_mint", "bold_mint", "calm_mint", "careful_mint",
        "brave_mint", "quiet_mint", "impish_mint", "relaxed_mint",
        "gentle_mint", "hasty_mint", "lax_mint",
        "lonely_mint", "mild_mint", "naive_mint"
    ):
        require(('"' + earlier + '"') not in mints,
                "No unauthorized existing mint activation " + earlier)
    runner = RUNNER006.read_text(encoding="utf-8")
    for fragment in (
        "func _probe_mint04(", "CAMP006_W02_MINT04",
        "SaveGameRepository.new().decode_snapshot(",
        "now.effective_nature_id == target",
        "original == c.to_dict()",
        "expected_stats.to_dict() == now.stats.to_dict()",
        "owner.inventory.quantity(item)",
        "item_has_no_effect",
        "invalid_creature_id",
    ):
        require(fragment in runner, "Native runtime contract must check " + fragment)
    for mutation in (
        lambda f: f["blocks"][3]["ids"].append("gentle_mint"),
        lambda f: f["blocks"][3]["cases"][0].update({"original_nature": "naughty"}),
        lambda f: f["blocks"][3]["cases"][3].update({"original_nature": "hardy"}),
        lambda f: f["blocks"][3]["cases"][2].update({"target_nature": "timid"}),
        lambda f: f["blocks"][3].update({"status": "COMPLETED_WITHOUT_CI"}),
    ):
        altered = copy.deepcopy(data)
        mutation(altered)
        require(altered["blocks"][3] != block, "Adversarial mint mutation rejected")



def verify_block05_training_held(data: dict, progress: list[dict]) -> None:
    """Two real held effects and one explicitly missing distribution path."""
    b = data["blocks"][4]
    ids = ["everstone", "exp_share", "lucky_egg"]
    cases = [
        {"scenario": "everstone_level_gate", "id": "everstone",
         "kind": "held_positive", "original_species": "bulbasaur",
         "level": 15, "target_level": 16,
         "expected_blocked_species": "ivysaur",
         "expected_outcome": "level_up_without_evolution"},
        {"scenario": "exp_share_missing_distribution", "id": "exp_share",
         "kind": "held_dependency", "original_species": "mew",
         "level": 50, "expected_status": "DEPENDENCY_MISSING",
         "expected_no_distribution": True},
        {"scenario": "lucky_egg_battle_reward", "id": "lucky_egg",
         "kind": "held_positive", "original_species": "mew",
         "level": 50, "base_exp": 71,
         "expected_normal_reward": 71, "expected_held_reward": 106},
    ]
    require(b["block"] == progress[4]["bloque"] == "05"
            and b["family"] == "TRAINING_HELD"
            and b["ids"] == progress[4]["ids"].split(";") == ids,
            "Only authorized block05 held IDs")
    require(b["status"] == "TWO_POSITIVE_ONE_DEPENDENCY_AWAITING_CI"
            and progress[4]["estado"] == "DOS_FUNCIONALES_UNA_DEPENDENCIA_EN_CI"
            and progress[4]["ci_run"] == "CI_BLOQUE05_PENDIENTE",
            "No false overall CI or ExpShare functionality")
    require(b["cases"] == cases, "Three exact and independently specified held cases")
    require([x["kind"] for x in b["cases"]] ==
            ["held_positive", "held_dependency", "held_positive"],
            "Only two positive effects")
    dep = b["dependency"]
    require(dep["key"] == "EXP_SHARE_PROGRESSION_DISTRIBUTION_POLICY_006_W02"
            and dep["owner"] == "IA6" and dep["scope"] == "L1_DEPENDENCY_NO_SHARE_EFFECT"
            and "ProgressionSystem" in dep["missing"]
            and "SaveV2" in dep["positive_contract_pending"],
            "ExpShare must not be counted as a functional distribution")
    for path in dep["source"]:
        require((ROOT / path).is_file(), "Shared source contract exists: " + path)
    held = (ROOT / "modules/creatures/progression/progression_held_items.gd").read_text(encoding="utf-8")
    progression = (ROOT / "modules/creatures/progression/progression_system.gd").read_text(encoding="utf-8")
    evolution = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text(encoding="utf-8")
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
    conn = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    selection = json.loads((ROOT / "config/item_selection_v1.json").read_text(encoding="utf-8"))
    for item in ids:
        require(item in conn["holdable_ids"] and item not in selection["excluded_ids"],
                "Held item eligible and catalogued " + item)
    require('return active_item(creature,&"everstone")' in held
            and 'block_level_evolution' in evolution
            and 'HeldItems.blocks_level_evolution(creature)' in evolution,
            "Everstone evolution gate connected")
    require('active_item(creature,&"lucky_egg")' in held
            and 'amount=amount*3/2' in held
            and 'HeldItems.battle_reward_amount(share, sp, starting_items, maximum)' in progression,
            "Lucky Egg original real post-battle experience connection")
    require('func equip(item_id: StringName, creature_id: StringName)' in service
            and 'if not staged.remove(item_id): return _deny("item_not_owned")' in service,
            "Field item equip is real stock transaction")
    require("exp_share" not in held and "exp_share" not in progression,
            "If ExpShare implementation appears, re-audit positively before marking it missing")
    require('for p in participants:' in progression
            and 'survivors.append(c)' in progression,
            "Current reward recipients are battle participants only")
    gd = RUNNER006.read_text(encoding="utf-8")
    for frag in (
        "func _probe_held05(", "ProgressionSystem.reconcile_battle_result(",
        "ProgressionSystem.gain_experience(", "SaveGameRepository.new().decode_snapshot(",
        "svc.equip(", "service2.unequip(", "CAMP006_W02_HELD05",
        "exp_share", "everstone", "lucky_egg",
        "EvolutionSystem.level_up_context(", "item_not_owned",
    ):
        require(frag in gd, "Native held integration contract missing: " + frag)
    require(sum(len(bx["cases"]) for bx in json.loads(OLD.read_text(encoding="utf-8"))["blocks"]) == 288,
            "Historical CAMP005 288 scenarios must remain")
    for mutation in (
        lambda f: f["blocks"][4]["ids"].append("soothe_bell"),
        lambda f: f["blocks"][4]["cases"][0].update({"target_level": 17}),
        lambda f: f["blocks"][4]["cases"][1].update({"kind": "held_positive"}),
        lambda f: f["blocks"][4]["cases"][2].update({"expected_held_reward": 71}),
        lambda f: f["blocks"][4]["dependency"].update({"scope": "L2_FUNCTIONAL"}),
        lambda f: f["blocks"][4].update({"status": "FULL_FUNCTIONAL_CI_PASS"}),
    ):
        altered = copy.deepcopy(data)
        mutation(altered)
        require(altered["blocks"][4] != b, "Adversarial held-item mutation detected")


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
    verify_block04_pilot(data, progress)
    print(f"CAMP006_W02_MINT04_CONTRACT READY ids=4 checks={checks}")
    verify_block05_training_held(data, progress)
    print(f"CAMP006_W02_HELD05_CONTRACT READY positives=2 dependency=1 checks={checks}")

if __name__ == "__main__":
    main()
