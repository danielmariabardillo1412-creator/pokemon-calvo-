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
    check(fx["new_item_ids"] == 0 and len(fx["blocks"]) == 2, "no new objects; exactly two authorized blocks")
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
        check(q[0]["bloque"] == "01" and q[0]["ids"].split(";") == list(IDS) and q[1]["bloque"] == "02" and q[1]["ids"].split(";") == list(POTS_02), "official queue copied unchanged")
    progress = rows(BASE / "reports/W04/CAMP_006_PROGRESO.csv")
    check(len(progress) == 2 and progress[0]["bloque"] == "01" and progress[0]["ids"].split(";") == list(IDS),
          "first progress row retained")
    check(progress[1]["bloque"] == "02" and progress[1]["ids"].split(";") == list(POTS_02),
          "progress row02 exact scope")
    check(progress[1]["estado"] in ("EN_CI_AUTOMATICA", "DEPENDENCIA_DOCUMENTADA"),
          "L3 species positive but form gate must not be falsely certified")
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
        'CAMP006_W04_GODOT PASS blocks=2 checks='
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
                  "CAMP006_W04_POT id=", "CAMP006_W04_GODOT PASS blocks=2 checks="):
        check(token in runner, "Godot must exercise real scene path: " + token)
    print(f"CAMP006_W04_PY PASS blocks=2 checks={n}")


if __name__ == "__main__":
    main()
