#!/usr/bin/env python3
"""W02 CAMP004: contratos explícitos de los IDs reservados; Godot verifica ejecución real."""
from __future__ import annotations
import argparse
import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W02_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W02/CAMP_004_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_004.json"
NATIVE = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
FIELD_EFFECTS = ROOT / "modules/inventory/field_item_effects.gd"
RECOVERY = ROOT / "modules/inventory/imported_recovery_v19.json"
HISTORIC = ROOT / "tests/gameplay/item_field_effects_v4.gd"


def held(scenario, item, foe_move, consumed, **kw):
    result = dict(scenario=scenario, id=item,
                  kind="heal_flavor" if item == "figy_berry" else "lum_held",
                  nature="hardy", start="full", status="", actor_species="mew",
                  foe_species="mew", foe_move=foe_move, consumes=consumed,
                  confuses=False, own_move="reflect")
    result.update(kw)
    return result


def ev(scenario, amount, friendship, accepted, removed, gain):
    return dict(scenario=scenario, id="kelpsy_berry", kind="field_ev_training",
                stat="attack", start_ev=amount, start_friendship=friendship,
                start_hp="full", applies=accepted, ev_removed=removed,
                friendship_gain=gain)


def pp(scenario, current, slot, accepted, gain):
    return dict(scenario=scenario, id="leppa_berry", kind="field_pp",
                pp_start=current, slot=slot, applies=accepted,
                expected_delta=gain)


def lum(scenario, status, confused, accepted):
    return dict(scenario=scenario, id="lum_berry", kind="field_lum",
                status=status, confused=confused, applies=accepted)


EXPECTED_01 = [
    held("figy_disliked_modest_c004", "figy_berry", "endeavor", True,
         nature="modest", foe_species="snorlax", foe_initial_hp=1, confuses=True),
    held("figy_neutral_hardy_c004", "figy_berry", "endeavor", True,
         foe_species="snorlax", foe_initial_hp=1),
    held("figy_high_no_trigger_c004", "figy_berry", "amnesia", False,
         nature="modest", start="near_full"),
    ev("kelpsy_ev20_friend100_c004", 20, 100, True, 10, 5),
    ev("kelpsy_ev0_friend200_c004", 0, 200, True, 0, 2),
    ev("kelpsy_ev0_friend255_noop_c004", 0, 255, False, 0, 0),
    pp("leppa_zero_pp_c004", 0, 0, True, 10),
    pp("leppa_low_pp_c004", 3, 0, True, 10),
    pp("leppa_full_pp_noop_c004", "full", 0, False, 0),
    pp("leppa_missing_slot_c004", 0, -1, False, 0),
    held("lum_poison_held_c004", "lum_berry", "amnesia", True, status="poison"),
    held("lum_healthy_held_c004", "lum_berry", "amnesia", False),
    lum("lum_poison_field_c004", "poison", False, True),
    lum("lum_confusion_field_c004", "", True, True),
    lum("lum_healthy_field_noop_c004", "", False, False),
]
EXPECTED_IDS_01 = ["figy_berry", "kelpsy_berry", "leppa_berry", "lum_berry"]
SOURCES_01 = [
    "tools/item_audit/held_effect_sweep_v3.cjs",
    "modules/inventory/field_item_effects.gd",
    "modules/inventory/imported_recovery_v19.json",
    "tests/gameplay/item_field_effects_v4.gd",
]

EXPECTED_02 = json.loads(r'''[
  {
    "scenario": "qualot_ev20_friend100_c004",
    "id": "qualot_berry",
    "kind": "field_ev_training",
    "stat": "defense",
    "start_ev": 20,
    "start_friendship": 100,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 10,
    "friendship_gain": 5
  },
  {
    "scenario": "qualot_ev0_friend200_c004",
    "id": "qualot_berry",
    "kind": "field_ev_training",
    "stat": "defense",
    "start_ev": 0,
    "start_friendship": 200,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 0,
    "friendship_gain": 2
  },
  {
    "scenario": "qualot_ev0_friend255_noop_c004",
    "id": "qualot_berry",
    "kind": "field_ev_training",
    "stat": "defense",
    "start_ev": 0,
    "start_friendship": 255,
    "start_hp": "full",
    "applies": false,
    "ev_removed": 0,
    "friendship_gain": 0
  },
  {
    "scenario": "razz_field_missing_contract_c004",
    "id": "razz_berry",
    "kind": "field_unsupported",
    "status": "",
    "confused": false,
    "applies": false
  },
  {
    "scenario": "razz_held_inert_c004",
    "id": "razz_berry",
    "kind": "inert_held",
    "nature": "hardy",
    "start": "near_full",
    "status": "",
    "actor_species": "mew",
    "foe_species": "mew",
    "foe_move": "amnesia",
    "consumes": false,
    "confuses": false,
    "own_move": "reflect"
  },
  {
    "scenario": "sitrus_held_low_hp_c004",
    "id": "sitrus_berry",
    "kind": "heal_quarter_held",
    "nature": "hardy",
    "start": "full",
    "status": "",
    "actor_species": "mew",
    "foe_species": "snorlax",
    "foe_move": "endeavor",
    "consumes": true,
    "confuses": false,
    "own_move": "reflect",
    "foe_initial_hp": 1
  },
  {
    "scenario": "sitrus_held_high_hp_c004",
    "id": "sitrus_berry",
    "kind": "heal_quarter_held",
    "nature": "hardy",
    "start": "near_full",
    "status": "",
    "actor_species": "mew",
    "foe_species": "mew",
    "foe_move": "amnesia",
    "consumes": false,
    "confuses": false,
    "own_move": "reflect"
  },
  {
    "scenario": "sitrus_field_half_hp_c004",
    "id": "sitrus_berry",
    "kind": "field_heal",
    "start_hp": "half",
    "applies": true,
    "heal_denominator": 4
  },
  {
    "scenario": "sitrus_field_full_hp_noop_c004",
    "id": "sitrus_berry",
    "kind": "field_heal",
    "start_hp": "full",
    "applies": false,
    "heal_denominator": 4
  },
  {
    "scenario": "tamato_ev20_friend100_c004",
    "id": "tamato_berry",
    "kind": "field_ev_training",
    "stat": "speed",
    "start_ev": 20,
    "start_friendship": 100,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 10,
    "friendship_gain": 5
  },
  {
    "scenario": "tamato_ev0_friend200_c004",
    "id": "tamato_berry",
    "kind": "field_ev_training",
    "stat": "speed",
    "start_ev": 0,
    "start_friendship": 200,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 0,
    "friendship_gain": 2
  },
  {
    "scenario": "tamato_ev0_friend255_noop_c004",
    "id": "tamato_berry",
    "kind": "field_ev_training",
    "stat": "speed",
    "start_ev": 0,
    "start_friendship": 255,
    "start_hp": "full",
    "applies": false,
    "ev_removed": 0,
    "friendship_gain": 0
  }
]''')
EXPECTED_IDS_02 = ["qualot_berry","razz_berry","sitrus_berry","tamato_berry"]
SOURCES_02 = ["modules/inventory/field_item_effects.gd","modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_service.gd","modules/inventory/item_connections_v1.json"]

EXPECTED_03 = json.loads(r'''[
  {
    "scenario": "antidote_poison_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "antidote_badly_poisoned_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "antidote_burn_reject_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "antidote_healthy_reject_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "awakening_sleep_c004",
    "id": "awakening",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "awakening_poison_reject_c004",
    "id": "awakening",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "awakening_healthy_reject_c004",
    "id": "awakening",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "berry_juice_half_hp_c004",
    "id": "berry_juice",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "berry_juice_near_full_c004",
    "id": "berry_juice",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "berry_juice_full_reject_c004",
    "id": "berry_juice",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "big_malasada_poison_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "big_malasada_freeze_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "big_malasada_confusion_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "big_malasada_poison_confusion_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "big_malasada_healthy_reject_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_03 = ["antidote","awakening","berry_juice","big_malasada"]
SOURCES_03 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]

EXPECTED_04 = json.loads(r'''[
  {
    "scenario": "burn_heal_burn_c004",
    "id": "burn_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "burn_heal_poison_reject_c004",
    "id": "burn_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "burn_heal_sleep_reject_c004",
    "id": "burn_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "burn_heal_healthy_reject_c004",
    "id": "burn_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "casteliacone_burn_c004",
    "id": "casteliacone",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "casteliacone_toxic_c004",
    "id": "casteliacone",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "casteliacone_sleep_c004",
    "id": "casteliacone",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "casteliacone_confusion_c004",
    "id": "casteliacone",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "casteliacone_poison_confusion_c004",
    "id": "casteliacone",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "casteliacone_healthy_reject_c004",
    "id": "casteliacone",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "elixir_both_empty_c004",
    "id": "elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp0_start": 0,
    "pp1_start": 0,
    "pp_gain": 10
  },
  {
    "scenario": "elixir_one_full_other_low_c004",
    "id": "elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp0_start": "full",
    "pp1_start": 2,
    "pp_gain": 10
  },
  {
    "scenario": "elixir_two_full_reject_c004",
    "id": "elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp0_start": "full",
    "pp1_start": "full",
    "pp_gain": 10
  },
  {
    "scenario": "elixir_wrong_slot_reject_c004",
    "id": "elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp0_start": 0,
    "pp1_start": 0,
    "pp_gain": 10,
    "slot": 0
  },
  {
    "scenario": "energy_powder_hp_half_friend100_c004",
    "id": "energy_powder",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 100,
    "friendship_loss": 5
  },
  {
    "scenario": "energy_powder_hp_half_friend200_c004",
    "id": "energy_powder",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 200,
    "friendship_loss": 10
  },
  {
    "scenario": "energy_powder_hp_half_friend0_c004",
    "id": "energy_powder",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 0,
    "friendship_loss": 5
  },
  {
    "scenario": "energy_powder_hp_missing7_friend199_c004",
    "id": "energy_powder",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 199,
    "friendship_loss": 5
  },
  {
    "scenario": "energy_powder_hp_full_reject_c004",
    "id": "energy_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 200,
    "friendship_loss": 10
  }
]''')
EXPECTED_IDS_04 = ["burn_heal","casteliacone","elixir","energy_powder"]
SOURCES_04 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]

EXPECTED_05 = json.loads(r'''[
  {
    "scenario": "energy_root_half_friend0_c004",
    "id": "energy_root",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 0,
    "friendship_loss": 10
  },
  {
    "scenario": "energy_root_half_friend100_c004",
    "id": "energy_root",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 100,
    "friendship_loss": 10
  },
  {
    "scenario": "energy_root_half_friend200_c004",
    "id": "energy_root",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 200,
    "friendship_loss": 15
  },
  {
    "scenario": "energy_root_nearfull_friend199_c004",
    "id": "energy_root",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 199,
    "friendship_loss": 10
  },
  {
    "scenario": "energy_root_full_reject_c004",
    "id": "energy_root",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 200,
    "friendship_loss": 15
  },
  {
    "scenario": "ether_first_empty_c004",
    "id": "ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_scope": "one",
    "pp0_start": 0,
    "pp1_start": 2,
    "slot": 0,
    "pp_gain": 10
  },
  {
    "scenario": "ether_second_empty_c004",
    "id": "ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_scope": "one",
    "pp0_start": 2,
    "pp1_start": 0,
    "slot": 1,
    "pp_gain": 10
  },
  {
    "scenario": "ether_selected_full_reject_c004",
    "id": "ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_scope": "one",
    "pp0_start": "full",
    "pp1_start": 0,
    "slot": 0,
    "pp_gain": 10
  },
  {
    "scenario": "ether_missing_slot_reject_c004",
    "id": "ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_scope": "one",
    "pp0_start": 0,
    "pp1_start": 0,
    "slot": -1,
    "pp_gain": 10
  },
  {
    "scenario": "ether_invalid_slot_reject_c004",
    "id": "ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_scope": "one",
    "pp0_start": 0,
    "pp1_start": 0,
    "slot": 99,
    "pp_gain": 10
  },
  {
    "scenario": "fresh_water_half_c004",
    "id": "fresh_water",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 30,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "fresh_water_missing7_c004",
    "id": "fresh_water",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 30,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "fresh_water_full_reject_c004",
    "id": "fresh_water",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 30,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "full_heal_poison_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "full_heal_toxic_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "full_heal_sleep_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "full_heal_burn_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "full_heal_confusion_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "full_heal_poison_confusion_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "full_heal_healthy_reject_c004",
    "id": "full_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_05 = ["energy_root","ether","fresh_water","full_heal"]
SOURCES_05 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]

EXPECTED_06 = json.loads(r'''[
  {
    "scenario": "full_restore_half_poison_confused_c004",
    "id": "full_restore",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true,
    "heal_full": true
  },
  {
    "scenario": "full_restore_half_sleep_c004",
    "id": "full_restore",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "heal_full": true,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "full_restore_full_burn_c004",
    "id": "full_restore",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "full_restore_half_healthy_c004",
    "id": "full_restore",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "full_restore_full_confusion_c004",
    "id": "full_restore",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true,
    "heal_full": true
  },
  {
    "scenario": "full_restore_full_healthy_reject_c004",
    "id": "full_restore",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "heal_powder_poison_friend0_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "start_friendship": 0,
    "friendship_loss": 5
  },
  {
    "scenario": "heal_powder_poison_friend100_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "start_friendship": 100,
    "friendship_loss": 5
  },
  {
    "scenario": "heal_powder_poison_friend200_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "start_friendship": 200,
    "friendship_loss": 10
  },
  {
    "scenario": "heal_powder_confusion_friend199_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true,
    "start_friendship": 199,
    "friendship_loss": 5
  },
  {
    "scenario": "heal_powder_sleep_friend100_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "start_friendship": 100,
    "friendship_loss": 5,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "heal_powder_poison_confusion_friend0_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true,
    "start_friendship": 0,
    "friendship_loss": 5
  },
  {
    "scenario": "heal_powder_healthy_friend200_reject_c004",
    "id": "heal_powder",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "start_friendship": 200,
    "friendship_loss": 10
  },
  {
    "scenario": "hopo_field_unsupported_full_c004",
    "id": "hopo_berry",
    "kind": "field_unsupported",
    "status": "",
    "confused": false,
    "applies": false
  },
  {
    "scenario": "hopo_field_unsupported_half_c004",
    "id": "hopo_berry",
    "kind": "field_unsupported",
    "status": "",
    "confused": false,
    "applies": false,
    "start_hp": "half"
  },
  {
    "scenario": "hopo_field_unsupported_poison_c004",
    "id": "hopo_berry",
    "kind": "field_unsupported",
    "status": "poison",
    "confused": true,
    "applies": false
  },
  {
    "scenario": "hyper_potion_half_c004",
    "id": "hyper_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "hyper_potion_missing7_c004",
    "id": "hyper_potion",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "hyper_potion_full_reject_c004",
    "id": "hyper_potion",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "hyper_potion_half_poison_keeps_status_c004",
    "id": "hyper_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 120,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_06 = ["full_restore","heal_powder","hopo_berry","hyper_potion"]
SOURCES_06 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","data/api/v2/item/2278/index.json","docs/current/ITEM_FIELD_V8.csv.txt"]

EXPECTED_07 = json.loads(r'''[
  {
    "scenario": "ice_heal_freeze_c004",
    "id": "ice_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "ice_heal_freeze_confusion_preserved_c004",
    "id": "ice_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "ice_heal_poison_reject_c004",
    "id": "ice_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "ice_heal_burn_reject_c004",
    "id": "ice_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "ice_heal_healthy_reject_c004",
    "id": "ice_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "lava_cookie_burn_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "lava_cookie_toxic_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "lava_cookie_sleep_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "lava_cookie_freeze_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "lava_cookie_confusion_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "lava_cookie_poison_confusion_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "lava_cookie_healthy_reject_c004",
    "id": "lava_cookie",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "lemonade_half_hp_c004",
    "id": "lemonade",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 70,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "lemonade_missing7_c004",
    "id": "lemonade",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 70,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "lemonade_full_reject_c004",
    "id": "lemonade",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 70,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "lemonade_half_poison_preserved_c004",
    "id": "lemonade",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 70,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "lumiose_galette_poison_c004",
    "id": "lumiose_galette",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "lumiose_galette_toxic_c004",
    "id": "lumiose_galette",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "lumiose_galette_sleep_c004",
    "id": "lumiose_galette",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "lumiose_galette_confusion_c004",
    "id": "lumiose_galette",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "lumiose_galette_poison_confusion_c004",
    "id": "lumiose_galette",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "lumiose_galette_healthy_reject_c004",
    "id": "lumiose_galette",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_07 = ["ice_heal","lava_cookie","lemonade","lumiose_galette"]
SOURCES_07 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]

EXPECTED_08 = json.loads(r'''[
  {
    "scenario": "max_elixir_both_empty_c004",
    "id": "max_elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "all",
    "pp0_start": 0,
    "pp1_start": 0,
    "slot": -1
  },
  {
    "scenario": "max_elixir_first_full_second_zero_c004",
    "id": "max_elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "all",
    "pp0_start": "full",
    "pp1_start": 0,
    "slot": -1
  },
  {
    "scenario": "max_elixir_first_5_second_2_c004",
    "id": "max_elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "all",
    "pp0_start": 5,
    "pp1_start": 2,
    "slot": -1
  },
  {
    "scenario": "max_elixir_both_full_reject_c004",
    "id": "max_elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "all",
    "pp0_start": "full",
    "pp1_start": "full",
    "slot": -1
  },
  {
    "scenario": "max_elixir_unexpected_slot_reject_c004",
    "id": "max_elixir",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "all",
    "pp0_start": 0,
    "pp1_start": 0,
    "slot": 0
  },
  {
    "scenario": "max_ether_first_zero_c004",
    "id": "max_ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "one",
    "pp0_start": 0,
    "pp1_start": 3,
    "slot": 0
  },
  {
    "scenario": "max_ether_second_zero_c004",
    "id": "max_ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "one",
    "pp0_start": 2,
    "pp1_start": 0,
    "slot": 1
  },
  {
    "scenario": "max_ether_first_partial_c004",
    "id": "max_ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "one",
    "pp0_start": 7,
    "pp1_start": 0,
    "slot": 0
  },
  {
    "scenario": "max_ether_selected_full_other_empty_reject_c004",
    "id": "max_ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "one",
    "pp0_start": "full",
    "pp1_start": 0,
    "slot": 0
  },
  {
    "scenario": "max_ether_without_slot_reject_c004",
    "id": "max_ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "one",
    "pp0_start": 0,
    "pp1_start": 0,
    "slot": -1
  },
  {
    "scenario": "max_ether_invalid_slot_reject_c004",
    "id": "max_ether",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "pp_full": true,
    "pp_scope": "one",
    "pp0_start": 0,
    "pp1_start": 0,
    "slot": 99
  },
  {
    "scenario": "max_potion_half_c004",
    "id": "max_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "max_potion_missing7_c004",
    "id": "max_potion",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "max_potion_full_reject_c004",
    "id": "max_potion",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "max_potion_half_poison_persists_c004",
    "id": "max_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "max_potion_half_confusion_persists_c004",
    "id": "max_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false,
    "heal_full": true
  },
  {
    "scenario": "moomoo_milk_half_c004",
    "id": "moomoo_milk",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 100,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "moomoo_milk_missing7_c004",
    "id": "moomoo_milk",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 100,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "moomoo_milk_full_reject_c004",
    "id": "moomoo_milk",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 100,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "moomoo_milk_half_poison_persists_c004",
    "id": "moomoo_milk",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 100,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_08 = ["max_elixir","max_ether","max_potion","moomoo_milk"]
SOURCES_08 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]

EXPECTED_09 = json.loads(r'''[
  {
    "scenario": "old_gateau_poison_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "old_gateau_toxic_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "old_gateau_sleep_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "old_gateau_freeze_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "old_gateau_confusion_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "old_gateau_poison_confusion_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "old_gateau_healthy_reject_c004",
    "id": "old_gateau",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "paralyze_heal_paralysis_c004",
    "id": "paralyze_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "paralysis",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "paralyze_heal_paralysis_confusion_stays_c004",
    "id": "paralyze_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "paralysis",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "paralyze_heal_poison_reject_c004",
    "id": "paralyze_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "paralyze_heal_sleep_reject_c004",
    "id": "paralyze_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "paralyze_heal_healthy_reject_c004",
    "id": "paralyze_heal",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "pewter_crunchies_burn_c004",
    "id": "pewter_crunchies",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "pewter_crunchies_toxic_c004",
    "id": "pewter_crunchies",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "pewter_crunchies_sleep_c004",
    "id": "pewter_crunchies",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "pewter_crunchies_confusion_c004",
    "id": "pewter_crunchies",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "pewter_crunchies_poison_confusion_c004",
    "id": "pewter_crunchies",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "pewter_crunchies_healthy_reject_c004",
    "id": "pewter_crunchies",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "potion_half_hp_c004",
    "id": "potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "potion_missing7_c004",
    "id": "potion",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "potion_full_hp_reject_c004",
    "id": "potion",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "potion_half_poison_stays_c004",
    "id": "potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_09 = ["old_gateau","paralyze_heal","pewter_crunchies","potion"]
SOURCES_09 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]

EXPECTED_10 = json.loads(r'''[
  {
    "scenario": "shalour_sable_poison_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "shalour_sable_toxic_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "shalour_sable_sleep_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "shalour_sable_freeze_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "shalour_sable_confusion_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "shalour_sable_paralysis_confusion_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "paralysis",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "shalour_sable_healthy_reject_c004",
    "id": "shalour_sable",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "soda_pop_half_c004",
    "id": "soda_pop",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 50,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "soda_pop_missing7_c004",
    "id": "soda_pop",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 50,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "soda_pop_full_reject_c004",
    "id": "soda_pop",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 50,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "soda_pop_half_poison_persists_c004",
    "id": "soda_pop",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 50,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "soda_pop_half_confusion_persists_c004",
    "id": "soda_pop",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 50,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "super_potion_half_c004",
    "id": "super_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "super_potion_missing7_c004",
    "id": "super_potion",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "super_potion_full_reject_c004",
    "id": "super_potion",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "super_potion_half_poison_persists_c004",
    "id": "super_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "super_potion_half_confusion_persists_c004",
    "id": "super_potion",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 60,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "sweet_heart_half_c004",
    "id": "sweet_heart",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "sweet_heart_missing7_c004",
    "id": "sweet_heart",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "sweet_heart_full_reject_c004",
    "id": "sweet_heart",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "sweet_heart_half_poison_persists_c004",
    "id": "sweet_heart",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "sweet_heart_half_confusion_persists_c004",
    "id": "sweet_heart",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_10 = ["shalour_sable","soda_pop","super_potion","sweet_heart"]
SOURCES_10 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]


class ContractError(ValueError):
    pass


class Checks:
    def __init__(self):
        self.count = 0

    def demand(self, assertion, error):
        self.count += 1
        if not assertion:
            raise ContractError(error)


def rows(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def verify(fixture, queue, progress, chk):
    chk.demand(type(fixture) is dict, "Fixture debe ser Dictionary")
    chk.demand(set(fixture) == {
        "schema_version", "campaign", "worker", "active_policy", "purpose",
        "format", "level", "seed", "modes", "completed_blocks", "blocks",
        "limitations"}, "Esquema de fixture alterado")
    chk.demand(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_004_W02"
               and fixture["worker"] == "W02", "Identidad distinta")
    chk.demand(fixture["active_policy"] == "RANDOMLOCK_ITEMS_BUILD_SCOPE_V2"
               and fixture["format"] == "gen9calvounifiedv1"
               and fixture["seed"] == [23, 19, 29, 43]
               and fixture["level"] == 100, "Motor, política, nivel o semilla alterados")
    chk.demand(fixture["modes"] == ["active", "none", "reserve"], "Propietarios incompletos")
    chk.demand(type(fixture["limitations"]) is list and len(fixture["limitations"]) >= 2,
               "Limitaciones retiradas")
    chk.demand(len(queue) == 10 and all(
        r["trabajadora"] == "W02" and r["bloque"] == f"{i+1:02d}"
        for i, r in enumerate(queue)), "Cola oficial modificada")
    chk.demand(1 <= len(progress) <= 10 and len(progress) == len(fixture["blocks"]),
               "Progreso no corresponde con número de bloques")
    chk.demand(fixture["completed_blocks"] == list(range(1, len(progress)+1)),
               "Bloques discontinuos")
    for i, block in enumerate(fixture["blocks"]):
        allowed = queue[i]
        chk.demand(block["block"] == allowed["bloque"]
                   and block["ids"] == allowed["ids"].split(";")
                   and progress[i]["bloque"] == allowed["bloque"]
                   and progress[i]["ids"] == allowed["ids"], "IDs/orden no autorizados")
        chk.demand(block["family"] == allowed["familia"], "Familia distinta de la cola")
        chk.demand(progress[i]["estado"] in {
            "EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "DEPENDENCIA_DOCUMENTADA",
            "CI_PASS_VERIFICADO"}, "Estado de progreso inválido")
        chk.demand(type(block["cases"]) is list and len(block["cases"]) >= 1,
                   "Bloque sin casos reales")
        if i == 0:
            chk.demand(block["ids"] == EXPECTED_IDS_01 and block["family"] == "BERRY",
                       "Cuatro bayas del bloque 01 no coinciden")
            chk.demand(block["source_evidence"] == SOURCES_01, "Fuentes no trazables")
            chk.demand(len(block["cases"]) == len(EXPECTED_01), "No hay 15 escenarios")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_01):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario alterado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Escenario duplicado")
                names.add(actual["scenario"])
            chk.demand(names == {case["scenario"] for case in EXPECTED_01},
                       "Falta alguno de los escenarios Figy Kelpsy Leppa Lum")
        elif i == 1:
            chk.demand(block["ids"] == EXPECTED_IDS_02 and block["family"] == "BERRY",
                       "IDs bayas 02 distintos de cola")
            chk.demand(block["source_evidence"] == SOURCES_02, "Fuentes bloque 02 alteradas")
            chk.demand(len(block["cases"]) == len(EXPECTED_02), "Faltan escenarios bloque 02")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_02):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario bloque 02 alterado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Escenario bloque 02 duplicado")
                names.add(actual["scenario"])
            chk.demand(names == {case["scenario"] for case in EXPECTED_02},
                       "Escenarios bloque 02 incompletos")
        elif i == 2:
            chk.demand(block["ids"] == EXPECTED_IDS_03 and block["family"] == "MEDICINE",
                       "IDs o familia de medicinas 03 incorrectos")
            chk.demand(block["source_evidence"] == SOURCES_03,
                       "Fuentes del bloque de medicinas cambiadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_03),
                       "No hay 15 escenarios de medicina")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_03):
                chk.demand(type(actual) is dict and actual == expected,
                           "Medicina alterada: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Medicina duplicada")
                names.add(actual["scenario"])
            chk.demand(names == {x["scenario"] for x in EXPECTED_03},
                       "Escenarios MEDICINE 03 incompletos")
        elif i == 3:
            chk.demand(block["ids"] == EXPECTED_IDS_04 and block["family"] == "MEDICINE",
                       "IDs/familia bloque 04 cambian respecto a la cola")
            chk.demand(block["source_evidence"] == SOURCES_04,
                       "Fuentes de medicinas 04 modificadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_04),
                       "Bloque 04 no contiene 19 escenarios")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_04):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario medicina 04 alterado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Escenario 04 duplicado")
                names.add(actual["scenario"])
            chk.demand(names == {case["scenario"] for case in EXPECTED_04},
                       "Bloque 04 no cubre la matriz completa")
        elif i == 4:
            chk.demand(block["ids"] == EXPECTED_IDS_05 and block["family"] == "MEDICINE",
                       "IDs/familia bloque 05 cambian")
            chk.demand(block["source_evidence"] == SOURCES_05,
                       "Fuentes medicinas 05 distintas")
            chk.demand(len(block["cases"]) == len(EXPECTED_05),
                       "20 escenarios de medicina 05 no completos")
            seen = set()
            for actual, expected in zip(block["cases"], EXPECTED_05):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario medicina 05 alterado: "+str(expected["scenario"]))
                chk.demand(actual["scenario"] not in seen, "Escenario 05 duplicado")
                seen.add(actual["scenario"])
            chk.demand(seen == {case["scenario"] for case in EXPECTED_05},
                       "IDs y escenarios bloque 05 incompletos")
        elif i == 5:
            chk.demand(block["ids"] == EXPECTED_IDS_06 and block["family"] == "MEDICINE",
                       "IDs/familia bloque 06 distintos de la cola IA6")
            chk.demand(block["source_evidence"] == SOURCES_06,
                       "Evidencia bloque 06 distinta de fuente")
            chk.demand(len(block["cases"]) == len(EXPECTED_06),
                       "Bloque 06 sin 20 escenarios exactos")
            seen = set()
            for actual, expected in zip(block["cases"], EXPECTED_06):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario medicina 06 modificado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in seen, "Escenario 06 repetido")
                seen.add(actual["scenario"])
            chk.demand(seen == {row["scenario"] for row in EXPECTED_06},
                       "Bloque 06 no cubre todos sus casos")
        elif i == 6:
            chk.demand(block["ids"] == EXPECTED_IDS_07 and block["family"] == "MEDICINE",
                       "IDs o familia del bloque 07 distintos de cola IA6")
            chk.demand(block["source_evidence"] == SOURCES_07,
                       "Fuentes del bloque 07 modificadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_07),
                       "Bloque 07 carece de los 22 escenarios esperados")
            seen = set()
            for actual, expected in zip(block["cases"], EXPECTED_07):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario de medicina 07 distinto: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in seen,
                           "Escenario 07 duplicado")
                seen.add(actual["scenario"])
            chk.demand(seen == {x["scenario"] for x in EXPECTED_07},
                       "Cobertura 07 no contiene todos los escenarios")
        elif i == 7:
            chk.demand(block["ids"] == EXPECTED_IDS_08 and block["family"] == "MEDICINE",
                       "IDs/familia 08 no coinciden con autoridad IA6")
            chk.demand(block["source_evidence"] == SOURCES_08,
                       "Fuentes de 08 cambiadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_08),
                       "Bloque 08 no contiene 20 escenarios")
            seen = set()
            for actual, expected in zip(block["cases"], EXPECTED_08):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario medicina 08 distinto de contrato: "+str(expected["scenario"]))
                chk.demand(actual["scenario"] not in seen, "Escenario 08 duplicado")
                seen.add(actual["scenario"])
            chk.demand(seen == {z["scenario"] for z in EXPECTED_08},
                       "Escenarios 08 no cubiertos por completo")
        elif i == 8:
            chk.demand(block["ids"] == EXPECTED_IDS_09 and block["family"] == "MEDICINE",
                       "IDs/familia del bloque 09 distintos de la cola")
            chk.demand(block["source_evidence"] == SOURCES_09,
                       "Fuente de bloque09 modificada")
            chk.demand(len(block["cases"]) == len(EXPECTED_09),
                       "Bloque 09 carece de los 22 escenarios")
            seen = set()
            for actual, expected in zip(block["cases"], EXPECTED_09):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario 09 alterado: "+str(expected["scenario"]))
                chk.demand(actual["scenario"] not in seen,
                           "Duplicado bloque09")
                seen.add(actual["scenario"])
            chk.demand(seen == {x["scenario"] for x in EXPECTED_09},
                       "Matriz de bloque09 incompleta")
        elif i == 9:
            chk.demand(block["ids"] == EXPECTED_IDS_10 and block["family"] == "MEDICINE",
                       "IDs/familia del bloque 10 distintos de la cola IA6")
            chk.demand(block["source_evidence"] == SOURCES_10,
                       "Fuentes del bloque 10 cambiadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_10),
                       "Bloque 10 carece de sus 22 escenarios")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_10):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario 10 alterado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names,
                           "Escenario 10 duplicado")
                names.add(actual["scenario"])
            chk.demand(names == {x["scenario"] for x in EXPECTED_10},
                       "Matriz de bloque 10 incompleta")
        else:
            raise ContractError("No hay contrato específico de bloque futuro")
    return len(progress)


def verify_sources(chk):
    native = NATIVE.read_text(encoding="utf-8")
    effects = FIELD_EFFECTS.read_text(encoding="utf-8")
    old = HISTORIC.read_text(encoding="utf-8")
    profile = json.loads(RECOVERY.read_text(encoding="utf-8"))
    for fragment in ("heal_and_disliked_flavor", "heal_without_confusion",
                     "foeMoves:['endeavor']", "add('leppa_berry','empty_pp'",
                     "add('leppa_berry','nonempty_pp'"):
        chk.demand(fragment in native, "Precedente Showdown ausente: " + fragment)
    for fragment in ('"kelpsy_berry": "attack"', "static func _ev_berry(",
                     "Friendship.increase(creature, [10, 5, 2])",
                     "creature.evs[stat] = maxi(0, old_ev - 10)"):
        chk.demand(fragment in effects, "Implementación canónica EV ausente: " + fragment)
    for fragment in ('"kelpsy_berry": "attack"', "berry EV -10 lower bound",
                     "full health follows new maximum"):
        chk.demand(fragment in old, "Regresión EV histórica ausente: " + fragment)
    for item, expected in {
        "leppa_berry": {"pp": 10, "scope": "one"},
        "lum_berry": {"confusion": True, "cure": "all"},
    }.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil recuperación nativo alterado: " + item)
    chk.demand(profile["items"]["sitrus_berry"]["effect"] == {"heal": "quarter"}
               and profile["items"]["sitrus_berry"]["consume"] is True,
               "Sitrus no conserva curación de cuarto de PS")
    chk.demand('"qualot_berry": "defense"' in effects and
               '"tamato_berry": "speed"' in effects,
               "Qualot y Tamato no tienen ruta canónica EV")
    chk.demand('"razz_berry"' not in effects and "razz_berry" not in profile["items"],
               "Razz ya tiene ruta de campo: reevaluar dependencia, no inventar")
    connections = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    chk.demand(all(x in connections["holdable_ids"] for x in EXPECTED_IDS_02),
               "Las 4 bayas deben conservar el contrato equipado permitido")
    expected_medicines = {
        "antidote": {"cure": ["psn", "tox"]},
        "awakening": {"cure": ["slp"]},
        "berry_juice": {"heal": 20},
        "big_malasada": {"confusion": True, "cure": "all"},
    }
    for item, expected in expected_medicines.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Contrato nativo medicina no coincide: " + item)
    chk.demand("static func apply(" in effects and
               "static func _recovery_spec(" in effects and
               "creature.status_state.clear_persistent()" in effects,
               "Motor de medicina/cura no conectado")
    chk.demand("confusion-only effect" in old and
               '"antidote": "badly_poisoned"' in old and
               '"awakening": "sleep"' in old,
               "Regresiones históricas de estado no disponibles")
    expected_04_profiles = {
        "burn_heal": {"cure": ["brn"]},
        "casteliacone": {"confusion": True, "cure": "all"},
        "elixir": {"pp": 10, "scope": "all"},
        "energy_powder": {"friendship_loss": [5, 5, 10], "heal": 60},
    }
    for item, expected in expected_04_profiles.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil real medicina 04 distinto: " + item)
    for fragment in ('spec.scope == "one"', "slots.assign(creature.moveset)",
                     "creature.friendship = maxi(0, creature.friendship - int(spec.friendship_loss[tier]))",
                     'creature.recover_hp(amount)', 'return deny("item_has_no_effect")'):
        chk.demand(fragment in effects, "Ruta real para PP/amistad/PS incompleta: " + fragment)
    chk.demand('"burn_heal": "burn"' in old and
               '"elixir"' in old and '"burn"' in old,
               "Regresiones históricas para Burn Heal y Elixir ausentes")
    expected_05_profiles = {
        "energy_root": {"friendship_loss": [10, 10, 15], "heal": 120},
        "ether": {"pp": 10, "scope": "one"},
        "fresh_water": {"heal": 30},
        "full_heal": {"confusion": True, "cure": "all"},
    }
    for item, expected in expected_05_profiles.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil de medicina 05 desviado: "+item)
    chk.demand("if move_slot < 0 or move_slot >= creature.moveset.size()" in effects
               and "slots.append(creature.moveset[move_slot])" in effects,
               "Eter: ranura obligatoria no conectada")
    chk.demand('"full_heal": "poison"' in old and '"ether"' in old,
               "Regresión histórica Full Heal/Eter ausente; Agua Fresca contrastada con perfil")
    expected_06_profiles = {
        "full_restore": {"heal": "full", "cure": "all", "confusion": True},
        "heal_powder": {"cure": "all", "confusion": True, "friendship_loss": [5, 5, 10]},
        "hyper_potion": {"heal": 120},
    }
    for item, expected in expected_06_profiles.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil de medicina 06 desviado: " + item)
    chk.demand("hopo_berry" not in profile["items"],
               "Hopo tiene perfil nativo: revisar dependencia antes de afirmar rechazo")
    hopo = json.loads((ROOT / "data/api/v2/item/2278/index.json").read_text(encoding="utf-8"))
    chk.demand(hopo["id"] == 2278 and hopo["name"] == "hopo-berry"
               and hopo["category"]["name"] == "pp-recovery"
               and hopo["effect_entries"] == [],
               "Hopo: fuente importada no respalda cantidad ni mecanica PP")
    inventory = (ROOT / "docs/current/ITEM_FIELD_V8.csv.txt").read_text(encoding="utf-8")
    chk.demand(any(line.startswith("hopo_berry,hopo-berry,MEDICINE,FIELD_USE_NOT_CONNECTED,NOT_CERTIFIED")
                   for line in inventory.splitlines()),
               "Inventario histórico no acredita dependencia de Hopo")
    expected_07_profiles = {
        "ice_heal": {"cure": ["frz"]},
        "lava_cookie": {"confusion": True, "cure": "all"},
        "lemonade": {"heal": 70},
        "lumiose_galette": {"confusion": True, "cure": "all"},
    }
    for item, expected in expected_07_profiles.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil real de medicina 07 distinto: " + item)
    chk.demand('"frz": "freeze"' in effects and
               'STATUS.get(code) == status' in effects and
               'creature.status_state.remove_volatile(&"confusion")' in effects and
               'creature.recover_hp(amount)' in effects,
               "Motor de congelación/confusión/HP no conserva ruta nativa")
    chk.demand('"ice_heal": "freeze"' in old,
               "Regresión de Antihielo histórica ausente")
    expected_08_profiles = {
        "max_elixir": {"pp": "full", "scope": "all"},
        "max_ether": {"pp": "full", "scope": "one"},
        "max_potion": {"heal": "full"},
        "moomoo_milk": {"heal": 100},
    }
    for item, expected in expected_08_profiles.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil de medicina 08 no coincide: " + item)
    for fragment in ('spec.scope == "one"', "slots.assign(creature.moveset)",
                     "slot.current_pp + (slot.max_pp if spec.pp is String else int(spec.pp))",
                     'if move_slot != -1: return deny("unexpected_move_slot")',
                     'creature.recover_hp(amount)'):
        chk.demand(fragment in effects, "Contrato Max PP/PS de motor alterado: " + fragment)
    chk.demand('"max_potion": 9999' in old,
               "Regresión histórica de Max Potion ausente")
    expected_09_profiles = {
        "old_gateau": {"confusion": True, "cure": "all"},
        "paralyze_heal": {"cure": ["par"]},
        "pewter_crunchies": {"confusion": True, "cure": "all"},
        "potion": {"heal": 20},
    }
    for item, expected in expected_09_profiles.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil 09 no coincide con los datos nativos: " + item)
    chk.demand('"par": "paralysis"' in effects
               and 'STATUS.get(code) == status' in effects
               and 'creature.status_state.remove_volatile(&"confusion")' in effects
               and "creature.recover_hp(amount)" in effects,
               "Rutas de estado/confusión/PS 09 no conectadas")
    chk.demand('"paralyze_heal": "paralysis"' in old
               and '"potion": 20' in old,
               "Regresión histórica Antiparalizador/Poción ausente")


def negative_controls(fixture, queue, progress, chk):
    edits = [
        lambda f: f.update({"worker": "W03"}),
        lambda f: f.update({"campaign": "CAMP_003"}),
        lambda f: f.update({"format": "gen8ou"}),
        lambda f: f["blocks"][0]["ids"].append("sitrus_berry"),
        lambda f: f["blocks"][0]["cases"].pop(),
        lambda f: f["blocks"][0]["cases"].append(copy.deepcopy(f["blocks"][0]["cases"][0])),
        lambda f: f["blocks"][0]["source_evidence"].pop(),
    ]
    for j, expected in enumerate(EXPECTED_01):
        key = next(k for k in ("nature", "stat", "slot", "status", "pp_start",
                               "applies", "start_ev", "consumes", "confused",
                               "expected_delta", "friendship_gain") if k in expected)
        value = expected[key]
        if type(value) is bool:
            other = not value
        elif type(value) is int:
            other = value + 1
        elif type(value) is str:
            other = value + "_BAD"
        else:
            raise ContractError("No hay mutación de test definida")
        edits.append(lambda f, j=j, key=key, other=other:
                     f["blocks"][0]["cases"][j].update({key: other}))
    if len(fixture["blocks"]) >= 2:
        edits.extend([
            lambda f: f["blocks"][1]["ids"].append("figy_berry"),
            lambda f: f["blocks"][1]["cases"].pop(),
            lambda f: f["blocks"][1]["cases"][3].update({"applies": True}),
            lambda f: f["blocks"][1]["cases"][5].update({"consumes": False}),
            lambda f: f["blocks"][1]["cases"][7].update({"heal_denominator": 3}),
            lambda f: f["blocks"][1]["cases"][9].update({"stat": "defense"}),
        ])
    if len(fixture["blocks"]) >= 3:
        edits.extend([
            lambda f: f["blocks"][2]["ids"].append("potion"),
            lambda f: f["blocks"][2]["cases"].pop(),
            lambda f: f["blocks"][2]["cases"][0].update({"applies": False}),
            lambda f: f["blocks"][2]["cases"][4].update({"cures_status": False}),
            lambda f: f["blocks"][2]["cases"][8].update({"heal_amount": 7}),
            lambda f: f["blocks"][2]["cases"][12].update({"cures_confusion": False}),
            lambda f: f["blocks"][2]["cases"][14].update({"applies": True}),
        ])
    if len(fixture["blocks"]) >= 4:
        edits.extend([
            lambda f: f["blocks"][3]["ids"].append("energy_root"),
            lambda f: f["blocks"][3]["cases"].pop(),
            lambda f: f["blocks"][3]["cases"][0].update({"applies": False}),
            lambda f: f["blocks"][3]["cases"][4].update({"cures_status": False}),
            lambda f: f["blocks"][3]["cases"][10].update({"pp_gain": 5}),
            lambda f: f["blocks"][3]["cases"][12].update({"applies": True}),
            lambda f: f["blocks"][3]["cases"][14].update({"friendship_loss": 10}),
            lambda f: f["blocks"][3]["cases"][18].update({"friendship_loss": 0}),
        ])
    if len(fixture["blocks"]) >= 5:
        edits.extend([
            lambda f: f["blocks"][4]["ids"].append("max_ether"),
            lambda f: f["blocks"][4]["cases"].pop(),
            lambda f: f["blocks"][4]["cases"][2].update({"friendship_loss": 10}),
            lambda f: f["blocks"][4]["cases"][5].update({"slot": -1}),
            lambda f: f["blocks"][4]["cases"][6].update({"pp_gain": 7}),
            lambda f: f["blocks"][4]["cases"][7].update({"applies": True}),
            lambda f: f["blocks"][4]["cases"][10].update({"heal_amount": 20}),
            lambda f: f["blocks"][4]["cases"][15].update({"cures_status": False}),
            lambda f: f["blocks"][4]["cases"][18].update({"cures_confusion": False}),
            lambda f: f["blocks"][4]["cases"][19].update({"applies": True}),
        ])
    if len(fixture["blocks"]) >= 6:
        edits.extend([
            lambda f: f["blocks"][5]["ids"].append("max_potion"),
            lambda f: f["blocks"][5]["cases"].pop(),
            lambda f: f["blocks"][5]["cases"][0].update({"heal_full": False}),
            lambda f: f["blocks"][5]["cases"][2].update({"cures_status": False}),
            lambda f: f["blocks"][5]["cases"][7].update({"friendship_loss": 10}),
            lambda f: f["blocks"][5]["cases"][9].update({"cures_confusion": False}),
            lambda f: f["blocks"][5]["cases"][13].update({"applies": True}),
            lambda f: f["blocks"][5]["cases"][14].update({"kind": "field_medicine"}),
            lambda f: f["blocks"][5]["cases"][17].update({"heal_amount": 60}),
            lambda f: f["blocks"][5]["cases"][19].update({"cures_status": True}),
        ])
    if len(fixture["blocks"]) >= 7:
        edits.extend([
            lambda f: f["blocks"][6]["ids"].append("full_heal"),
            lambda f: f["blocks"][6]["cases"].pop(),
            lambda f: f["blocks"][6]["source_evidence"].pop(),
            lambda f: f["blocks"][6]["cases"][0].update({"cures_status": False}),
            lambda f: f["blocks"][6]["cases"][1].update({"cures_confusion": True}),
            lambda f: f["blocks"][6]["cases"][3].update({"applies": True}),
            lambda f: f["blocks"][6]["cases"][8].update({"cures_status": False}),
            lambda f: f["blocks"][6]["cases"][9].update({"cures_confusion": False}),
            lambda f: f["blocks"][6]["cases"][13].update({"heal_amount": 30}),
            lambda f: f["blocks"][6]["cases"][14].update({"applies": True}),
            lambda f: f["blocks"][6]["cases"][18].update({"expect_sleep_clock_clear": False}),
            lambda f: f["blocks"][6]["cases"][20].update({"cures_confusion": False}),
            lambda f: f["blocks"][6]["cases"][21].update({"applies": True}),
        ])
    if len(fixture["blocks"]) >= 8:
        edits.extend([
            lambda f: f["blocks"][7]["ids"].append("ether"),
            lambda f: f["blocks"][7]["cases"].pop(),
            lambda f: f["blocks"][7]["source_evidence"].pop(),
            lambda f: f["blocks"][7]["cases"][0].update({"pp_full": False}),
            lambda f: f["blocks"][7]["cases"][1].update({"pp_scope": "one"}),
            lambda f: f["blocks"][7]["cases"][3].update({"applies": True}),
            lambda f: f["blocks"][7]["cases"][4].update({"slot": -1}),
            lambda f: f["blocks"][7]["cases"][5].update({"slot": 1}),
            lambda f: f["blocks"][7]["cases"][8].update({"applies": True}),
            lambda f: f["blocks"][7]["cases"][10].update({"slot": 0}),
            lambda f: f["blocks"][7]["cases"][11].update({"heal_full": False}),
            lambda f: f["blocks"][7]["cases"][12].update({"start_hp": "full"}),
            lambda f: f["blocks"][7]["cases"][15].update({"cures_confusion": True}),
            lambda f: f["blocks"][7]["cases"][16].update({"heal_amount": 60}),
            lambda f: f["blocks"][7]["cases"][18].update({"applies": True}),
            lambda f: f["blocks"][7]["cases"][19].update({"cures_status": True}),
        ])
    if len(fixture["blocks"]) >= 9:
        edits.extend([
            lambda f: f["blocks"][8]["ids"].append("full_heal"),
            lambda f: f["blocks"][8]["cases"].pop(),
            lambda f: f["blocks"][8]["source_evidence"].pop(),
            lambda f: f["blocks"][8]["cases"][0].update({"cures_status": False}),
            lambda f: f["blocks"][8]["cases"][2].update({"expect_sleep_clock_clear": False}),
            lambda f: f["blocks"][8]["cases"][5].update({"cures_confusion": False}),
            lambda f: f["blocks"][8]["cases"][7].update({"applies": False}),
            lambda f: f["blocks"][8]["cases"][8].update({"cures_confusion": True}),
            lambda f: f["blocks"][8]["cases"][10].update({"applies": True}),
            lambda f: f["blocks"][8]["cases"][12].update({"cures_status": False}),
            lambda f: f["blocks"][8]["cases"][15].update({"cures_confusion": False}),
            lambda f: f["blocks"][8]["cases"][19].update({"heal_amount": 15}),
            lambda f: f["blocks"][8]["cases"][20].update({"applies": True}),
            lambda f: f["blocks"][8]["cases"][21].update({"cures_status": True}),
        ])
    for i, edit in enumerate(edits):
        altered = copy.deepcopy(fixture)
        edit(altered)
        rejected = False
        try:
            verify(altered, queue, progress, Checks())
        except (ContractError, KeyError, TypeError):
            rejected = True
        chk.demand(rejected, f"Mutación adversarial {i} aceptada sin error")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    queue = rows(QUEUE)
    progress = rows(PROGRESS)
    c = Checks()
    count = verify(fixture, queue, progress, c)
    verify_sources(c)
    negative_controls(fixture, queue, progress, c)
    print(f"CAMP004_W02_PY PASS blocks={count} checks={c.count}"
          if args.ci else f"W02 CAMP004 static check: blocks={count} checks={c.count}; NO equivale a Godot")


if __name__ == "__main__":
    main()
