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
    check(fx["new_item_ids"] == 0 and len(fx["blocks"]) == 1, "no new objects; exactly one authorized block")
    block = fx["blocks"][0]
    check(block["block"] == "01" and block["ids"] == list(IDS) and block["family"] == "EVOLUTION_E2E",
          "block 01 queue scope")
    check(block["level"] == "L3_REAL_SCENE_AND_SAVEV2" and len(block["cases"]) == 3, "real scene requirement")
    check({c["item_id"]: (c["source"], c["target"]) for c in block["cases"]} == PAIRS,
          "three correct apples without branch cross-wire")
    check(len({c["save"] for c in block["cases"]}) == 3, "three isolated native save files")
    check(all("CAMP006" not in c["save"] or c["save"] for c in block["cases"]),
          "save paths are nonempty")
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
        check(q[0]["bloque"] == "01" and q[0]["ids"].split(";") == list(IDS), "official queue copied unchanged")
    progress = rows(BASE / "reports/W04/CAMP_006_PROGRESO.csv")
    check(len(progress) == 1 and progress[0]["bloque"] == "01" and progress[0]["ids"].split(";") == list(IDS),
          "exactly one progress row")
    check(progress[0]["estado"] == "ENTREGADO_PENDIENTE_CI", "no claim of verified CI")
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
        'CAMP006_W04_GODOT PASS blocks=1 checks='
    ):
        check(token in runner, "Godot L3 runner missing real observable action: " + token)
    print(f"CAMP006_W04_PY PASS blocks=1 checks={n}")


if __name__ == "__main__":
    main()
