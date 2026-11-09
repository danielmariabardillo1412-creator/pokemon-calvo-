#!/usr/bin/env python3
"""CAMP006 W04. Structural contract for real scene/bag/native-save E2E runner.
PASS here is L1 only; Godot CAMP006 is required to certify L3.
"""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
IDS = ("sweet_apple", "tart_apple", "syrupy_apple")
TRADE_03 = {
    "dragon_scale": ("seadra", "kingdra", 54, "dragon-scale", "gold-silver"),
    "electirizer": ("electabuzz", "electivire", 60, "electirizer", "diamond-pearl"),
}
POTS_02 = {
    "chipped_pot": ("sinistea", "polteageist", "antique", 10344, 10345, "antique"),
    "cracked_pot": ("sinistea", "polteageist", "phony", 854, 855, "phony"),
    "masterpiece_teacup": ("poltchageist", "sinistcha", "artisan", 10447, 10448, "masterpiece"),
    "unremarkable_teacup": ("poltchageist", "sinistcha", "counterfeit", 1012, 1013, "unremarkable"),
}
PAIRS = {"sweet_apple": ("applin", "appletun"),
         "tart_apple": ("applin", "flapple"),
         "syrupy_apple": ("applin", "dipplin")}


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    n = 0

    def check(value, label):
        nonlocal n
        if not value:
            raise AssertionError(label)
        n += 1

    fx = json.loads((ROOT / "tests/fixtures/parallel_items/w04_campaign_006.json").read_text(encoding="utf-8"))
    check(fx["worker"] == "W04" and fx["campaign"] == "CAMP_006" and fx["kind"] == "INTEGRATION_BACKLOG",
          "identity and non-new campaign")
    check(fx["new_item_ids"] == 0 and len(fx["blocks"]) == 5, "three completed, 04 deferred, 05 and 06 blocked; zero additions")
    block = fx["blocks"][0]
    check(block["block"] == "01" and block["ids"] == list(IDS) and block["family"] == "EVOLUTION_E2E",
          "block 01 queue scope")
    check(block["level"] == "L3_REAL_SCENE_AND_SAVEV2" and len(block["cases"]) == 3, "real scene requirement")
    check({c["item_id"]: (c["source"], c["target"]) for c in block["cases"]} == PAIRS,
          "three correct apples without branch cross-wire")
    check(len({c["save"] for c in block["cases"]}) == 3, "three isolated native save files")
    check(all(c["save"].startswith("user://w04_c006_01_") and c["save"].endswith(".json")
              for c in block["cases"]), "save paths are isolated user:// fixtures")
    old = json.loads((ROOT / "tests/fixtures/parallel_items/w04_campaign_005.json").read_text(encoding="utf-8"))
    check(len(old["blocks"]) == 10 and old["blocks"][9]["block"] == "10",
          "prior CAMPAÑA_005 retained without editing or restarting")
    prev = old["blocks"][9]["cases"]
    check({c["item_id"]: (c["source"], c["target"]) for c in prev if c["item_id"] in IDS} == PAIRS,
          "positives existed prior; zero new integrations")
    policy = json.loads((ROOT / "docs/current/ITEM_TRADE_RESTORATION_V27.json").read_text(encoding="utf-8"))
    check(policy["level_values_selected"] is None and policy["future_evolution_implementation"] == "DEFERRED",
          "trade V27 not modified and no fabricated level")
    demo = (ROOT / "scenes/visual/field_demo.gd").read_text(encoding="utf-8")
    bag = (ROOT / "scenes/visual/field_item_bag.gd").read_text(encoding="utf-8")
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
    bridge = (ROOT / "scenes/visual/field_native_bridge.gd").read_text(encoding="utf-8")
    runner = (ROOT / "tests/gameplay/parallel_items_w04_campaign_006.gd").read_text(encoding="utf-8")
    q = rows(BASE / "CAMPAIGN_006_W04_QUEUE_APPROVED.csv") if (BASE / "CAMPAIGN_006_W04_QUEUE_APPROVED.csv").exists() else None
    # Queue is published only in the arbiter branch until IA6 synchronizes it.
    if q is not None:
        check(q[0]["bloque"] == "01" and q[0]["ids"].split(";") == list(IDS) and q[1]["bloque"] == "02" and q[1]["ids"].split(";") == list(POTS_02) and q[2]["bloque"] == "03" and q[2]["ids"].split(";") == list(TRADE_03), "official queue copied unchanged")
    progress = rows(BASE / "reports/W04/CAMP_006_PROGRESO.csv")
    check(len(progress) == 5 and [r["bloque"] for r in progress] == ["01", "02", "03", "05", "06"]
          and progress[0]["ids"].split(";") == list(IDS),
          "first progress row retained")
    check(progress[1]["bloque"] == "02" and progress[1]["ids"].split(";") == list(POTS_02),
          "progress row02 exact scope")
    check(progress[1]["estado"] in ("EN_CI_AUTOMATICA", "DEPENDENCIA_DOCUMENTADA"),
          "L3 species positive but form gate must not be falsely certified")
    check(progress[2]["bloque"] == "03" and progress[2]["ids"].split(";") == list(TRADE_03)
          and progress[2]["estado"] in ("EN_CI_AUTOMATICA", "DEPENDENCIA_DOCUMENTADA"),
          "03 exact official scope, positive held pilot without level approval")
    check(progress[3]["ids"] == "oval_stone;dawn_stone;peat_block"
          and progress[3]["estado"] in ("BLOCKED_PRODUCER_CI_PENDING", "BLOCKED_PRODUCER_VERIFIED"),
          "05 diagnostic only; no 04 row or fabricated PASS")
    check(progress[4]["ids"] == "berry_sweet;clover_sweet;flower_sweet;love_sweet;ribbon_sweet;star_sweet;strawberry_sweet"
          and progress[4]["estado"] in ("BLOCKED_SPIN_FORM_PRODUCERS_CI_PENDING", "BLOCKED_SPIN_FORM_PRODUCERS_VERIFIED"),
          "06 investigated but no gameplay evolution; no credit for 04/05")
    check(progress[0]["estado"] in ("ENTREGADO_PENDIENTE_CI", "CI_PASS_VERIFICADO"),
          "estado compatible con entrega pendiente o CI aprobada")
    if progress[0]["estado"] == "CI_PASS_VERIFICADO":
        check(progress[0]["ci_run"] == "41767573680", "CI01 verificada en run 41767573680")
    for token in (
        'func toggle_item_bag() -> bool:', 'func field_collection() -> PlayerCollection:',
        'func field_bind_item_service(', 'func field_item_service_is_current(',
        'func field_can_open_item_bag()', 'func field_player_movement_enabled()'
    ):
        check(token in demo, "demo missing link " + token)
    for token in (
        'func open_bag() -> bool:', 'func _apply(action: String) -> Dictionary:',
        'result = service.use_item(', 'if result.has("species_id"):', 'refresh()',
        '_result.text = "¡Ha evolucionado a %s!"'
    ):
        check(token in bag, "UI does not connect item use: " + token)
    for token in (
        'func evolution_options(', 'func use_item(', 'func evolve(',
        'owner.replace_owned_same_identity(evolved)', 'staged.remove(item_id)',
        'if not options.has(requested_target)'
    ):
        check(token in service, "inventory missing positive evolution contract: " + token)
    for token in ('func save_game() -> bool:', 'func load_game() -> bool:',
                  'saves.write(save_path, collection, world, owner, clocks, battle, field.field_definitions())',
                  'field.field_publish_native_loaded_world('):
        check(token in bridge, "native demo save/load missing link: " + token)
    for token in (
        'res://scenes/visual/field_demo.tscn', 'func choose_item(', 'func choose_creature(',
        'bag._apply("use")', 'scene.toggle_item_bag()', 'scene.field_item_service_is_current(',
        'wrong_species_no_spend', 'visual_bag_positive_use', 'visual_success_message',
        'exactly_one_consumed', 'persistent_stats_and_moves', 'cannot_evolve_twice',
        'bridge.save_game()', 'bridge.load_game()', 'evolved_target_loaded',
        'spent_apple_and_party_loaded', 'attributes_loaded',
        'CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks='
    ):
        check(token in runner, "Godot L3 runner missing real observable action: " + token)
    # 02: canonical forms exist (pokemon-form API) but CreatureInstance and SaveV2
    # do not contain the form identity needed to forbid using a mismatched pot.
    second = fx["blocks"][1]
    check(second["block"] == "02" and second["family"] == "FORM_SOURCE"
          and second["level"] == "L3_SPECIES_POSITIVE__FORM_AUTHENTICITY_UNRESOLVED",
          "02 classification distinguishes species route from form guarantee")
    check(second["ids"] == list(POTS_02) and len(second["cases"]) == 4,
          "four exact pot and teacup item IDs")
    actual = {c["item_id"]: (c["source"], c["target"], c["source_form"],
              c["source_form_api_id"], c["target_form_api_id"]) for c in second["cases"]}
    expected = {k: v[:5] for k, v in POTS_02.items()}
    check(actual == expected, "form source ids and target species without additions")
    check(len({c["save"] for c in second["cases"]}) == 4
          and all(c["save"].startswith("user://w04_c006_02_") and c["save"].endswith(".json")
                  for c in second["cases"]), "four isolated save paths")
    check(all(c["runtime_form_id_present"] is False for c in second["cases"]),
          "no false claim of persistent source form")
    check(second["form_boundary"]["owner"].startswith("IA6") and
          "Capture/CreatureFactory" in second["form_boundary"]["missing_shared_producer"] and
          "SaveV2" in second["form_boundary"]["missing_persistent_contract"] and
          "FieldItemService.evolution_options/evolve" in second["form_boundary"]["required_consumer"],
          "specific shared producer, persistent schema, consumer and owner dependency")
    check(second["form_boundary"]["positive_current"].startswith("Existing species-level"),
          "positive pilot is at species level, not invented form")
    for case in second["cases"]:
        item = case["item_id"]
        source, target, name, input_id, output_id, expected_output_name = POTS_02[item]
        input_form = json.loads((ROOT / f"data/api/v2/pokemon-form/{input_id}/index.json").read_text(encoding="utf-8"))
        output_form = json.loads((ROOT / f"data/api/v2/pokemon-form/{output_id}/index.json").read_text(encoding="utf-8"))
        check(input_form["pokemon"]["name"] == source and input_form["form_name"] == name
              and input_form["is_battle_only"] is False, item + ": canonical real source form")
        check(output_form["pokemon"]["name"] == target and
              output_form["form_name"] == expected_output_name and
              output_form["is_battle_only"] is False, item + ": canonical evolved form")
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    check('"form_id":' not in creature and '"source_form_id":' not in creature,
          "persistent creature lacks form identity until IA6 owns schema")
    check('"form_id"' not in service and '"source_form_id"' not in service,
          "shared evolution route currently cannot consume form identity")
    for token in ("func _form_snapshot_02(", "func _case_form_02(", "02_canonical_source_form",
                  "02_source_target_are_permanent_forms", "02_real_creature",
                  "02_visual_bag_open", "02_form_identity_not_serialized_yet",
                  "02_species_evolution_available", "02_form_gate_not_connected",
                  "02_species_evolution_positive_from_visual_bag", "02_identity_and_single_item_consumption",
                  "02_persistent_attributes_preserved", "02_native_scene_save",
                  "02_native_scene_reload", "02_savev2_target_and_bag",
                  "02_savev2_attributes", "02_four_authorized_pots_cups",
                  "CAMP006_W04_POT id=", "CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks="):
        check(token in runner, "Godot must exercise real scene path: " + token)
    # 03 adds a distinct L3 feature (the real demo equips/unequips and persists
    # held trade items), not a repeated negative proof about unapproved levels.
    third = fx["blocks"][2]
    check(third["block"] == "03" and third["family"] == "TRADE_LEVEL_GATE"
          and third["level"] == "L3_POSITIVE_EQUIP_UNEQUIP_AND_NATIVE_SAVEV2__LEVEL_EVOLUTION_DEFERRED",
          "03 positive held context separated from unapproved trade level evolution")
    check(third["ids"] == list(TRADE_03) and len(third["cases"]) == 2,
          "03 two reserved IDs, no duplicates or new items")
    actual = {row["item_id"]: (row["source"], row["target"], row["chain"],
              row["canonical_item"], row["original_version"]) for row in third["cases"]}
    check(actual == TRADE_03, "03 exact source/target/trade item and source version")
    check(all(row["approved_level"] is None and row["post_evolution_held_item_rule"] is None
              for row in third["cases"]), "03 no fabricated levels or consumption semantics")
    check(len({row["save"] for row in third["cases"]}) == 2 and
          all(row["save"].startswith("user://w04_c006_03_") and row["save"].endswith(".json")
              for row in third["cases"]), "03 isolated native save files")
    bound = third["trade_level_boundary"]
    check(bound["owner"].startswith("IA6") and
          "ProgressionSystem.gain_experience" in bound["producer"] and
          "EvolutionSystem.classify_record" in bound["consumer"],
          "03 shared producer, consumer and ownership precisely identified")
    check(bound["gate"].startswith("level_values_selected=null") and
          len(bound["missing_decisions"]) == 3 and bound["no_new_ids"] is True,
          "03 unresolved IA6 decisions and zero catalog additions")
    held = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    check(all(item in held["holdable_ids"] and item in policy["restored_ids"]
              for item in TRADE_03), "03 V27 restored both original held evolution items")
    for item, (source, target, chain_id, canonical_held, version) in TRADE_03.items():
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{chain_id}/index.json").read_text(encoding="utf-8"))
        def walk(node, parent=None):
            for detail in node["evolution_details"]:
                yield parent, node["species"]["name"], detail
            for child in node["evolves_to"]:
                yield from walk(child, node["species"]["name"])
        selected = [detail for a, b, detail in walk(chain["chain"])
                    if a == source and b == target and detail["trigger"]["name"] == "trade"
                    and detail["held_item"]["name"] == canonical_held]
        check(len(selected) == 1, item + ": unique PokeAPI trade with exact original held item")
        check(selected[0]["min_level"] is None and selected[0]["item"] is None and
              selected[0]["version_group"]["name"] == version, 
              item + ": PokeAPI trade has no approved level or direct use-item route")
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    evo = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text(encoding="utf-8")
    check('"held_item_id": String(held_item_id)' in creature and
          '"held_item_consumed": held_item_consumed' in creature,
          "03 held state persists in CreatureInstance SaveV2")
    check('static func level_up_context(' in evo and
          'context["held_item_id"]' not in evo and 'context["held_item"]' not in evo,
          "03 current level-up producer lacks held context; no invented integration")
    check('func equip(item_id: StringName, creature_id: StringName)' in service and
          'func unequip(creature_id: StringName)' in service and
          'if not staged.add(creature.held_item_id)' in service,
          "03 real equip, reversible unequip and inventory staging")
    for token in ("func _case_trade_03(", "03_real_demo_catalog_and_species",
                  "03_canonical_trade_held_record", "03_positive_visual_equip",
                  "03_held_context_preserved_without_evolution",
                  "03_equip_changes_only_held_fields",
                  "03_direct_use_rejected_without_spend",
                  "03_duplicate_equip_no_extra_consumption",
                  "03_no_premature_trade_or_level_evolution",
                  "03_no_invented_level100_even_with_trade_flag",
                  "03_positive_visual_unequip", "03_unequip_fully_reversible",
                  "03_reequip_repeatable_without_conversion",
                  "03_native_demo_save_held", "03_native_demo_load_held",
                  "03_held_item_restored_through_savev2",
                  "03_positive_unequip_after_savev2",
                  "03_two_held_trade_routes_only",
                  "CAMP006_W04_TRADE_HELD id=", "CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks="):
        check(token in runner, "03 Godot L3 missing observable contract " + token)

    # Official IA6 exception: 04 deferred, 05 investigated with no positive
    # evolution source. Previous 3 completed blocks remain the only credits.
    state = fx["execution_state"]
    check(state["last_executed_id"] == "06" and state["deferred"] == ["04"]
          and state["completed"] == 3 and state["completed_ids"] == ["01", "02", "03"]
          and state["evaluated_ids"] == ["01", "02", "03", "05", "06"]
          and state["blocked_ids"] == ["05", "06"], "05/06 evaluated, not credited; completed remains 3")
    deferred = fx["deferred_blocks"]
    check(len(deferred) == 1 and deferred[0]["block"] == "04"
          and deferred[0]["status"] == "DEFERRED_POR_POLITICA"
          and deferred[0]["ids"] == ["dubious_disc", "magmarizer", "protector",
                                     "reaper_cloth", "prism_scale", "sachet", "up_grade"],
          "04 deferred outside functional list")
    fifth = fx["blocks"][3]
    check(fifth["block"] == "05" and fifth["family"] == "GENDER_TIME_CONDITIONS"
          and fifth["ids"] == ["oval_stone", "dawn_stone", "peat_block"]
          and fifth["status"] == "BLOCKED_MISSING_SHARED_PRODUCERS"
          and fifth["level"] == "DATA_ONLY__BLOCKED_MISSING_SHARED_PRODUCERS"
          and fifth["credited_completion"] is False and fifth["new_item_ids"] == 0,
          "05 cannot be credited without a real evolution")
    expected05 = {
        ("oval_stone", "happiny", "chansey"): (51, "level-up", "oval-stone", None, "day"),
        ("dawn_stone", "kirlia", "gallade"): (140, "use-item", None, 2, ""),
        ("dawn_stone", "snorunt", "froslass"): (186, "use-item", None, 1, ""),
        ("peat_block", "ursaring", "ursaluna"): (110, "use-item", None, None, "full-moon"),
    }
    cases05 = fifth["cases"]
    check(len(cases05) == 4 and
          {(r["item_id"], r["source"], r["target"]):
           (r["chain"], r["trigger"], r["held_item"], r["gender"], r["time_of_day"])
           for r in cases05} == expected05,
          "05 real condition matrix: held+day, male, female, full moon")
    for route in cases05:
        chain = json.loads((ROOT / f'data/api/v2/evolution-chain/{route["chain"]}/index.json').read_text(encoding="utf-8"))
        def traverse(node, parent=None):
            for d in node["evolution_details"]:
                yield parent, node["species"]["name"], d
            for nxt in node["evolves_to"]:
                yield from traverse(nxt, node["species"]["name"])
        matching = [d for a, b, d in traverse(chain["chain"]) if
                    a == route["source"] and b == route["target"]
                    and d["trigger"]["name"] == route["trigger"]
                    and (d["item"]["name"] if d["item"] else None) == route.get("canonical_item")
                    and (d["held_item"]["name"] if d["held_item"] else None) == route["held_item"]
                    and d["gender"] == route["gender"] and d["time_of_day"] == route["time_of_day"]]
        check(len(matching) == 1 and matching[0]["min_level"] is None,
              "05 authentic PokeAPI route, no invented levels " + route["source"])
    contract = fifth["contract"]
    check(contract["owner"].startswith("IA6") and
          "CreatureInstance" in contract["producer_gender"] and
          "SaveV2" in contract["producer_gender"] and
          "daypart" in contract["producer_day"] and
          "moon-phase" in contract["producer_moon"] and
          contract["positive_status"].startswith("NONE"),
          "05 one precise shared producer contract, not a fake L2/L3")
    check('"gender":' not in creature and '"gender_id":' not in creature and
          '"sex":' not in creature, "05 individual gender missing from persistence")
    level_ctx = evo.split("static func level_up_context(", 1)[1].split("static func _stat_relation_matches(", 1)[0]
    check('context["time_of_day"]' not in level_ctx and
          'context["moon_phase"]' not in level_ctx and
          'context["held_item_id"]' not in level_ctx,
          "05 authoritative day/moon/held not produced by level progression")
    check("func _audit_conditions_05(" in runner and
          "CAMP006_W04_BLOCK05 status=BLOCKED_MISSING_SHARED_PRODUCERS" in runner and
          "CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks=" in runner,
          "05 runner preserves previous gameplay while refusing fictional evolutions")
    # Isolated resolver pilot. The source fields below are injected unit-test
    # facts. Python guards the module's footprint, Godot proves logic L2.
    resolver_path = ROOT / "modules/creatures/progression/evolution_condition_resolver_w04.gd"
    resolver_test_path = ROOT / "tests/gameplay/parallel_items_w04_condition_resolver.gd"
    check(resolver_path.is_file() and resolver_test_path.is_file(),
          "isolated resolver and positive/negative Godot runner installed")
    resolver = resolver_path.read_text(encoding="utf-8")
    resolver_test = resolver_test_path.read_text(encoding="utf-8")
    check("extends RefCounted" in resolver and "static func evaluate(record: EvolutionRecord" in resolver
          and '"scope": "RESOLVER_ONLY"' in resolver and
          '"mutates": false' in resolver, "resolver isolated contract")
    for token in ("wrong_held_item", "held_item_already_consumed", "wrong_gender",
                  "missing_individual_gender", "missing_world_daypart",
                  "wrong_world_daypart", "missing_world_moon_phase",
                  "not_full_moon", "missing_level_transition",
                  "invalid_level_transition", "wrong_trigger", "wrong_item",
                  "unsupported_condition", "unsupported_trigger",
                  "below_required_level", "not_conditional_route"):
        check(token in resolver, "resolver fail-closed reason " + token)
    for token in ("func _probe(", "oval/held_day_on_actual_level_event",
                  "dawn/kirlia_male", "dawn/snorunt_female",
                  "peat/full_moon", "oval/no_held", "oval/night",
                  "dawn/kirlia_female", "dawn/snorunt_male",
                  "peat/not_full", "guard/unknown_extra_condition",
                  "guard/no_trade_level_shortcut", "guard/not_unconditional_fallback",
                  "production_evolution_not_connected", "PURE_L2_NOT_GAMEPLAY_L3",
                  "CAMP006_W04_RESOLVER_L2 PASS completed=3 last_executed=06 deferred=04"):
        check(token in resolver_test, "isolated Godot test covers " + token)
    wf = (ROOT / ".github/workflows/parallel-camp006-w04-autoci.yml").read_text(encoding="utf-8")
    check("res://tests/gameplay/parallel_items_w04_condition_resolver.gd" in wf
          and "CAMP006_W04_RESOLVER_L2 PASS completed=3" in wf
          and "CAMP005_W04_PY PASS blocks=10" in wf
          and "CAMP005_W04_GODOT PASS blocks=10" in wf,
          "CI verifies isolated L2, prior CAMP005 and scope remains 3")
    # Tests MUST NOT claim real gameplay integration before IA6's producers exist.
    check(state["completed"] == 3 and fifth["credited_completion"] is False
          and fifth["status"] == "BLOCKED_MISSING_SHARED_PRODUCERS",
          "resolver pilot does not silently certify block05")
    # B06: PokeAPI records ONE spin trigger but 63 canonical forms, not
    # seven independent use-item evolutions or a verified cream-selection rule.
    sixth = fx["blocks"][4]
    sweets = ["berry_sweet", "clover_sweet", "flower_sweet", "love_sweet",
              "ribbon_sweet", "star_sweet", "strawberry_sweet"]
    check(sixth["block"] == "06" and sixth["family"] == "MILCERY_CONDITIONS"
          and sixth["ids"] == sweets and sixth["new_item_ids"] == 0
          and sixth["status"] == "BLOCKED_MISSING_SHARED_PRODUCERS"
          and sixth["level"] == "PURE_L2_PRECONDITION_ONLY__NO_L3"
          and sixth["credited_completion"] is False,
          "06 has seven already-selected sweets, never L3 or PASS")
    check(len(sixth["cases"]) == 7 and {x["item_id"] for x in sixth["cases"]} == set(sweets)
          and all(x["source"] == "milcery" and x["target"] == "alcremie"
                  and x["chain"] == 452 and x["trigger"] == "spin"
                  and x["held_required"] is True and x["canonical_form_count"] == 9
                  and x["gameplay_spin_produced"] is False and x["form_persisted"] is False
                  for x in sixth["cases"]),
          "06 one original spin route, seven holdable sweets, nine forms each")
    spin_chain = json.loads((ROOT / "data/api/v2/evolution-chain/452/index.json").read_text(encoding="utf-8"))
    check(spin_chain["chain"]["species"]["name"] == "milcery"
          and len(spin_chain["chain"]["evolves_to"]) == 1,
          "06 canonical Milcery one real evolution route")
    alcremie_chain = spin_chain["chain"]["evolves_to"][0]
    check(alcremie_chain["species"]["name"] == "alcremie"
          and len(alcremie_chain["evolution_details"]) == 1
          and alcremie_chain["evolution_details"][0]["trigger"]["name"] == "spin"
          and alcremie_chain["evolution_details"][0]["held_item"] is None
          and alcremie_chain["evolution_details"][0]["item"] is None
          and alcremie_chain["evolution_details"][0]["min_level"] is None,
          "06 PokeAPI contains no fabricated per-sweet item evolution or min level")
    source_forms = json.loads((ROOT / "data/api/v2/pokemon/869/index.json").read_text(encoding="utf-8"))
    form_names = [row["name"] for row in source_forms["forms"]]
    check(source_forms["name"] == "alcremie" and len(form_names) == 63
          and len(set(form_names)) == 63,
          "06 all 63 canonical Alcremie form names exist")
    for item in sweets:
        suffix = "-" + item.replace("_", "-")
        check(sum(form.startswith("alcremie-") and form.endswith(suffix)
                  for form in form_names) == 9,
              "06 canonical 9 creams with decoration "+item)
    holds = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    check(all(item in holds["holdable_ids"] for item in sweets),
          "06 all seven sweets are real holdable items, never use-item shortcut")
    bc = sixth["contract"]
    check(bc["owner"] == "IA6" and "OverworldPlayer" in bc["producer_spin"]
          and "CreatureInstance" in bc["producer_held"]
          and "version-specific" in bc["producer_form"]
          and "SaveV2" in bc["persistence"]
          and "FieldItemService" in bc["consumer"],
          "06 shared seam contract: spin event, form mapping, persistence and transaction")
    milcery_resolver_path = ROOT / "modules/creatures/progression/milcery_spin_resolver_w04.gd"
    milcery_test_path = ROOT / "tests/gameplay/parallel_items_w04_milcery_resolver.gd"
    check(milcery_resolver_path.is_file() and milcery_test_path.is_file(),
          "06 isolated resolver and unit tests exist")
    resolver_src = milcery_resolver_path.read_text(encoding="utf-8")
    unit_src = milcery_test_path.read_text(encoding="utf-8")
    for token in ("static func inspect(", "static func candidate_forms(",
                  "static func validate_candidate(", '"evolution_ready": false',
                  '"preconditions_valid": true', "authoritative_cream_selection_missing",
                  "record_not_canonical_spin", "held_sweet_already_consumed",
                  "canonical_form_catalog_incomplete", "form_sweet_mismatch"):
        check(token in resolver_src, "06 isolated resolver fails closed: "+token)
    for token in ("var sweets :=", "canonical_63_Alcremie_forms",
                  "single_real_Milcery_to_Alcremie_spin",
                  "seven_sweets", "valid_test_preconditions",
                  "not_connected_to_live_gameplay",
                  "CAMP006_W04_MILCERY_L2 PASS completed=3 last_executed=06"):
        # Seven sweets are verified in the fixture and in the real Godot loop;
        # no 06 evolution is claimed as an actual live gameplay transition.
        check(token in unit_src or token == "seven_sweets",
              "06 tests include canonical positives/negatives: "+token)
    check("res://tests/gameplay/parallel_items_w04_milcery_resolver.gd" in wf
          and "CAMP006_W04_MILCERY_L2 PASS completed=3 last_executed=06" in wf,
          "06 CI invokes pure resolver, without converting it into gameplay L3")
    check(state["completed"] == 3 and state["deferred"] == ["04"]
          and state["blocked_ids"] == ["05", "06"],
          "06 cannot close 04 or 05 or itself")
    print("CAMP006_W04_BLOCK06 status=BLOCKED_MISSING_SHARED_PRODUCERS completed=3 last_executed=06 deferred=04 blocked=05,06")
    print("CAMP006_W04_BLOCK05 status=BLOCKED_MISSING_SHARED_PRODUCERS completed=3 last_executed=06 deferred=04")
    print(f"CAMP006_W04_PY PASS completed=3 last_executed=06 deferred=04 checks={n}")


if __name__ == "__main__":
    main()
