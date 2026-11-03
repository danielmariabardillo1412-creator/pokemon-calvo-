#!/usr/bin/env python3
"""IA2/W02 CAMPAÑA_005: contrato real, adversarial y acumulativo por fila."""
from __future__ import annotations

import argparse
import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_005.json"
QUEUE = BASE / "CAMPAIGN_005_W02_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W02/CAMP_005_PROGRESO.csv"
ABILITY = ROOT / "modules/inventory/field_ability_effects.gd"
GROWTH = ROOT / "modules/inventory/field_growth_effects.gd"
PPBOOST = ROOT / "modules/inventory/field_pp_boost_effects.gd"
TRAINING = ROOT / "modules/inventory/field_training_effects.gd"
FRIENDSHIP = ROOT / "modules/inventory/field_friendship_effects.gd"
MOCHI = ROOT / "modules/inventory/field_mochi_effects.gd"
FIELD_EFFECTS = ROOT / "modules/inventory/field_item_effects.gd"
HIST_MOCHI = ROOT / "tests/gameplay/item_mochi_v13.gd"
HIST_TRAINING = ROOT / "tests/gameplay/field_held_v17.gd"
SERVICE = ROOT / "modules/inventory/field_item_service.gd"
RUNNER = ROOT / "tests/gameplay/parallel_items_w02_campaign_005.gd"
HIST_ABILITY = ROOT / "tests/gameplay/item_field_ability_v10.gd"
HIST_GROWTH = ROOT / "tests/gameplay/item_field_growth_v9.gd"
HIST_PP = ROOT / "tests/gameplay/item_field_pp_v8.gd"

EXPECTED_01 = json.loads(r'''[
  {
    "scenario": "capsule_normal_1_to_2",
    "id": "ability_capsule",
    "kind": "ability",
    "applies": true,
    "ability": "intimidate",
    "expected_ability": "flash_fire"
  },
  {
    "scenario": "capsule_normal_2_to_1",
    "id": "ability_capsule",
    "kind": "ability",
    "applies": true,
    "ability": "flash_fire",
    "expected_ability": "intimidate"
  },
  {
    "scenario": "capsule_hidden_rejected",
    "id": "ability_capsule",
    "kind": "ability",
    "applies": false,
    "ability": "justified"
  },
  {
    "scenario": "capsule_explicit_slot_rejected",
    "id": "ability_capsule",
    "kind": "ability",
    "applies": false,
    "ability": "intimidate",
    "slot": 0
  },
  {
    "scenario": "patch_normal_1_to_hidden",
    "id": "ability_patch",
    "kind": "ability",
    "applies": true,
    "ability": "intimidate",
    "expected_ability": "justified"
  },
  {
    "scenario": "patch_normal_2_to_hidden",
    "id": "ability_patch",
    "kind": "ability",
    "applies": true,
    "ability": "flash_fire",
    "expected_ability": "justified"
  },
  {
    "scenario": "patch_hidden_to_first_normal",
    "id": "ability_patch",
    "kind": "ability",
    "applies": true,
    "ability": "justified",
    "expected_ability": "intimidate"
  },
  {
    "scenario": "patch_explicit_slot_rejected",
    "id": "ability_patch",
    "kind": "ability",
    "applies": false,
    "ability": "flash_fire",
    "slot": 1
  },
  {
    "scenario": "rare_level_50_to_51",
    "id": "rare_candy",
    "kind": "growth",
    "applies": true,
    "level": 50,
    "expected_level": 51
  },
  {
    "scenario": "rare_level_99_to_100",
    "id": "rare_candy",
    "kind": "growth",
    "applies": true,
    "level": 99,
    "expected_level": 100
  },
  {
    "scenario": "rare_level_100_no_effect",
    "id": "rare_candy",
    "kind": "growth",
    "applies": false,
    "level": 100
  },
  {
    "scenario": "rare_explicit_move_slot_rejected",
    "id": "rare_candy",
    "kind": "growth",
    "applies": false,
    "level": 50,
    "slot": 0
  },
  {
    "scenario": "pp_up_zero_boost",
    "id": "pp_up",
    "kind": "pp",
    "applies": true,
    "boosts": 0,
    "start_pp": 30,
    "slot": 0,
    "expected_boosts": 1
  },
  {
    "scenario": "pp_up_one_boost",
    "id": "pp_up",
    "kind": "pp",
    "applies": true,
    "boosts": 1,
    "start_pp": 32,
    "slot": 0,
    "expected_boosts": 2
  },
  {
    "scenario": "pp_up_second_move",
    "id": "pp_up",
    "kind": "pp",
    "applies": true,
    "boosts": 0,
    "start_pp": 6,
    "slot": 1,
    "expected_boosts": 1
  },
  {
    "scenario": "pp_up_max_boost_rejected",
    "id": "pp_up",
    "kind": "pp",
    "applies": false,
    "boosts": 3,
    "start_pp": 40,
    "slot": 0
  },
  {
    "scenario": "pp_up_no_slot_rejected",
    "id": "pp_up",
    "kind": "pp",
    "applies": false,
    "boosts": 0,
    "start_pp": 30,
    "slot": -1
  },
  {
    "scenario": "pp_up_invalid_slot_rejected",
    "id": "pp_up",
    "kind": "pp",
    "applies": false,
    "boosts": 0,
    "start_pp": 30,
    "slot": 99
  }
]''')
IDS_01 = ["ability_capsule","ability_patch","rare_candy","pp_up"]
SOURCES_01 = ["modules/inventory/field_ability_effects.gd","modules/inventory/field_growth_effects.gd","modules/inventory/field_pp_boost_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_ability_v10.gd","tests/gameplay/item_field_growth_v9.gd","tests/gameplay/item_field_pp_v8.gd"]

EXPECTED_02 = json.loads(r'''[
  {
    "scenario": "pp_max_zero_boost_first",
    "id": "pp_max",
    "kind": "pp",
    "applies": true,
    "boosts": 0,
    "start_pp": 30,
    "slot": 0,
    "expected_boosts": 3
  },
  {
    "scenario": "pp_max_one_boost_first",
    "id": "pp_max",
    "kind": "pp",
    "applies": true,
    "boosts": 1,
    "start_pp": 33,
    "slot": 0,
    "expected_boosts": 3
  },
  {
    "scenario": "pp_max_two_boost_second",
    "id": "pp_max",
    "kind": "pp",
    "applies": true,
    "boosts": 2,
    "start_pp": 6,
    "slot": 1,
    "expected_boosts": 3
  },
  {
    "scenario": "pp_max_three_boost_reject",
    "id": "pp_max",
    "kind": "pp",
    "applies": false,
    "boosts": 3,
    "start_pp": 40,
    "slot": 0
  },
  {
    "scenario": "pp_max_no_slot_reject",
    "id": "pp_max",
    "kind": "pp",
    "applies": false,
    "boosts": 0,
    "start_pp": 30,
    "slot": -1
  },
  {
    "scenario": "pp_max_invalid_slot_reject",
    "id": "pp_max",
    "kind": "pp",
    "applies": false,
    "boosts": 0,
    "start_pp": 30,
    "slot": 99
  },
  {
    "scenario": "hp_up_zero_ev",
    "id": "hp_up",
    "kind": "vitamin",
    "applies": true,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "hp_up_near_stat_cap",
    "id": "hp_up",
    "kind": "vitamin",
    "applies": true,
    "stat": "hp",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "hp_up_stat_cap_reject",
    "id": "hp_up",
    "kind": "vitamin",
    "applies": false,
    "stat": "hp",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "hp_up_global_508_capped",
    "id": "hp_up",
    "kind": "vitamin",
    "applies": true,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "hp_up_global_510_reject",
    "id": "hp_up",
    "kind": "vitamin",
    "applies": false,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "hp_up_unexpected_slot_reject",
    "id": "hp_up",
    "kind": "vitamin",
    "applies": false,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "protein_zero_ev",
    "id": "protein",
    "kind": "vitamin",
    "applies": true,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "protein_near_stat_cap",
    "id": "protein",
    "kind": "vitamin",
    "applies": true,
    "stat": "attack",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "protein_stat_cap_reject",
    "id": "protein",
    "kind": "vitamin",
    "applies": false,
    "stat": "attack",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "protein_global_508_capped",
    "id": "protein",
    "kind": "vitamin",
    "applies": true,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "protein_global_510_reject",
    "id": "protein",
    "kind": "vitamin",
    "applies": false,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "protein_unexpected_slot_reject",
    "id": "protein",
    "kind": "vitamin",
    "applies": false,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "iron_zero_ev",
    "id": "iron",
    "kind": "vitamin",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "iron_near_stat_cap",
    "id": "iron",
    "kind": "vitamin",
    "applies": true,
    "stat": "defense",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "iron_stat_cap_reject",
    "id": "iron",
    "kind": "vitamin",
    "applies": false,
    "stat": "defense",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "iron_global_508_capped",
    "id": "iron",
    "kind": "vitamin",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "iron_global_510_reject",
    "id": "iron",
    "kind": "vitamin",
    "applies": false,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "iron_unexpected_slot_reject",
    "id": "iron",
    "kind": "vitamin",
    "applies": false,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  }
]''')
IDS_02 = ["pp_max","hp_up","protein","iron"]
SOURCES_02 = ["modules/inventory/field_pp_boost_effects.gd","modules/inventory/field_training_effects.gd","modules/inventory/field_friendship_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_pp_v8.gd","tests/gameplay/field_held_v17.gd"]

EXPECTED_03 = json.loads(r'''[
  {
    "scenario": "calcium_zero_ev",
    "id": "calcium",
    "kind": "vitamin",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "calcium_stat_248_to_252",
    "id": "calcium",
    "kind": "vitamin",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "calcium_stat_252_reject",
    "id": "calcium",
    "kind": "vitamin",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "calcium_total_508_to_510",
    "id": "calcium",
    "kind": "vitamin",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "calcium_total_510_reject",
    "id": "calcium",
    "kind": "vitamin",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "calcium_wrong_slot_reject",
    "id": "calcium",
    "kind": "vitamin",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "zinc_zero_ev",
    "id": "zinc",
    "kind": "vitamin",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "zinc_stat_248_to_252",
    "id": "zinc",
    "kind": "vitamin",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "zinc_stat_252_reject",
    "id": "zinc",
    "kind": "vitamin",
    "applies": false,
    "stat": "special_defense",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "zinc_total_508_to_510",
    "id": "zinc",
    "kind": "vitamin",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "zinc_total_510_reject",
    "id": "zinc",
    "kind": "vitamin",
    "applies": false,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "zinc_wrong_slot_reject",
    "id": "zinc",
    "kind": "vitamin",
    "applies": false,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "carbos_zero_ev",
    "id": "carbos",
    "kind": "vitamin",
    "applies": true,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "carbos_stat_248_to_252",
    "id": "carbos",
    "kind": "vitamin",
    "applies": true,
    "stat": "speed",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "carbos_stat_252_reject",
    "id": "carbos",
    "kind": "vitamin",
    "applies": false,
    "stat": "speed",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "carbos_total_508_to_510",
    "id": "carbos",
    "kind": "vitamin",
    "applies": true,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "carbos_total_510_reject",
    "id": "carbos",
    "kind": "vitamin",
    "applies": false,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "carbos_wrong_slot_reject",
    "id": "carbos",
    "kind": "vitamin",
    "applies": false,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "exp_candy_xs_level_20_plus_100",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": true,
    "level": 20,
    "exp_gain": 100
  },
  {
    "scenario": "exp_candy_xs_level_50_plus_100",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": true,
    "level": 50,
    "exp_gain": 100
  },
  {
    "scenario": "exp_candy_xs_level_99_plus_100",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": true,
    "level": 99,
    "exp_gain": 100
  },
  {
    "scenario": "exp_candy_xs_level_99_near_cap",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": true,
    "level": 99,
    "exp_gain": 50,
    "exp_until_next": 50
  },
  {
    "scenario": "exp_candy_xs_level_50_crosses",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": true,
    "level": 50,
    "exp_gain": 100,
    "exp_until_next": 40
  },
  {
    "scenario": "exp_candy_xs_level_100_reject",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": false,
    "level": 100,
    "exp_gain": 0
  },
  {
    "scenario": "exp_candy_xs_wrong_slot_reject",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": false,
    "level": 50,
    "slot": 0,
    "exp_gain": 0
  },
  {
    "scenario": "exp_candy_xs_friendship_high",
    "id": "exp_candy_xs",
    "kind": "growth",
    "applies": true,
    "level": 50,
    "start_friendship": 200,
    "exp_gain": 100
  }
]''')
IDS_03 = ["calcium","zinc","carbos","exp_candy_xs"]
SOURCES_03 = ["modules/inventory/field_training_effects.gd","modules/inventory/field_friendship_effects.gd","modules/inventory/field_growth_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_growth_v9.gd","tests/gameplay/field_held_v17.gd"]

EXPECTED_04 = json.loads(r'''[
  {
    "scenario": "exp_candy_s_level50_gain",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": true,
    "exp_amount": 800,
    "level": 50
  },
  {
    "scenario": "exp_candy_s_level90_gain",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": true,
    "exp_amount": 800,
    "level": 90
  },
  {
    "scenario": "exp_candy_s_level99_gain",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": true,
    "exp_amount": 800,
    "level": 99
  },
  {
    "scenario": "exp_candy_s_level99_cap_50xp",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": true,
    "exp_amount": 800,
    "level": 99,
    "exp_until_next": 50,
    "expected_exp_gain": 50,
    "expect_cap": true
  },
  {
    "scenario": "exp_candy_s_level50_cross_80xp",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": true,
    "exp_amount": 800,
    "level": 50,
    "exp_until_next": 80,
    "expect_level_up": true
  },
  {
    "scenario": "exp_candy_s_level100_no_effect",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": false,
    "exp_amount": 800,
    "level": 100
  },
  {
    "scenario": "exp_candy_s_explicit_slot_rejected",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": false,
    "exp_amount": 800,
    "level": 50,
    "slot": 0
  },
  {
    "scenario": "exp_candy_s_friendship_high_200",
    "id": "exp_candy_s",
    "kind": "growth",
    "applies": true,
    "exp_amount": 800,
    "level": 50,
    "start_friendship": 200
  },
  {
    "scenario": "exp_candy_m_level50_gain",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": true,
    "exp_amount": 3000,
    "level": 50
  },
  {
    "scenario": "exp_candy_m_level90_gain",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": true,
    "exp_amount": 3000,
    "level": 90
  },
  {
    "scenario": "exp_candy_m_level99_gain",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": true,
    "exp_amount": 3000,
    "level": 99
  },
  {
    "scenario": "exp_candy_m_level99_cap_50xp",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": true,
    "exp_amount": 3000,
    "level": 99,
    "exp_until_next": 50,
    "expected_exp_gain": 50,
    "expect_cap": true
  },
  {
    "scenario": "exp_candy_m_level50_cross_80xp",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": true,
    "exp_amount": 3000,
    "level": 50,
    "exp_until_next": 80,
    "expect_level_up": true
  },
  {
    "scenario": "exp_candy_m_level100_no_effect",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": false,
    "exp_amount": 3000,
    "level": 100
  },
  {
    "scenario": "exp_candy_m_explicit_slot_rejected",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": false,
    "exp_amount": 3000,
    "level": 50,
    "slot": 0
  },
  {
    "scenario": "exp_candy_m_friendship_high_200",
    "id": "exp_candy_m",
    "kind": "growth",
    "applies": true,
    "exp_amount": 3000,
    "level": 50,
    "start_friendship": 200
  },
  {
    "scenario": "exp_candy_l_level50_gain",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": true,
    "exp_amount": 10000,
    "level": 50
  },
  {
    "scenario": "exp_candy_l_level90_gain",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": true,
    "exp_amount": 10000,
    "level": 90
  },
  {
    "scenario": "exp_candy_l_level99_gain",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": true,
    "exp_amount": 10000,
    "level": 99
  },
  {
    "scenario": "exp_candy_l_level99_cap_50xp",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": true,
    "exp_amount": 10000,
    "level": 99,
    "exp_until_next": 50,
    "expected_exp_gain": 50,
    "expect_cap": true
  },
  {
    "scenario": "exp_candy_l_level50_cross_80xp",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": true,
    "exp_amount": 10000,
    "level": 50,
    "exp_until_next": 80,
    "expect_level_up": true
  },
  {
    "scenario": "exp_candy_l_level100_no_effect",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": false,
    "exp_amount": 10000,
    "level": 100
  },
  {
    "scenario": "exp_candy_l_explicit_slot_rejected",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": false,
    "exp_amount": 10000,
    "level": 50,
    "slot": 0
  },
  {
    "scenario": "exp_candy_l_friendship_high_200",
    "id": "exp_candy_l",
    "kind": "growth",
    "applies": true,
    "exp_amount": 10000,
    "level": 50,
    "start_friendship": 200
  },
  {
    "scenario": "exp_candy_xl_level50_gain",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": true,
    "exp_amount": 30000,
    "level": 50
  },
  {
    "scenario": "exp_candy_xl_level90_gain",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": true,
    "exp_amount": 30000,
    "level": 90
  },
  {
    "scenario": "exp_candy_xl_level99_gain",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": true,
    "exp_amount": 30000,
    "level": 99,
    "expect_cap": true
  },
  {
    "scenario": "exp_candy_xl_level99_cap_50xp",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": true,
    "exp_amount": 30000,
    "level": 99,
    "exp_until_next": 50,
    "expected_exp_gain": 50,
    "expect_cap": true
  },
  {
    "scenario": "exp_candy_xl_level50_cross_80xp",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": true,
    "exp_amount": 30000,
    "level": 50,
    "exp_until_next": 80,
    "expect_level_up": true
  },
  {
    "scenario": "exp_candy_xl_level100_no_effect",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": false,
    "exp_amount": 30000,
    "level": 100
  },
  {
    "scenario": "exp_candy_xl_explicit_slot_rejected",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": false,
    "exp_amount": 30000,
    "level": 50,
    "slot": 0
  },
  {
    "scenario": "exp_candy_xl_friendship_high_200",
    "id": "exp_candy_xl",
    "kind": "growth",
    "applies": true,
    "exp_amount": 30000,
    "level": 50,
    "start_friendship": 200
  }
]''')
IDS_04 = ["exp_candy_s","exp_candy_m","exp_candy_l","exp_candy_xl"]
SOURCES_04 = ["modules/inventory/field_growth_effects.gd","modules/inventory/field_friendship_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_growth_v9.gd","tests/fixtures/progression_growth_curves/reference_contract.json"]

EXPECTED_05 = json.loads(r'''[
  {
    "scenario": "health_wing_base_0_ev",
    "id": "health_wing",
    "kind": "wing",
    "applies": true,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 1
  },
  {
    "scenario": "health_wing_near_stat_251",
    "id": "health_wing",
    "kind": "wing",
    "applies": true,
    "stat": "hp",
    "start_ev": 251,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "health_wing_stat_cap_252_reject",
    "id": "health_wing",
    "kind": "wing",
    "applies": false,
    "stat": "hp",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "health_wing_near_total_509",
    "id": "health_wing",
    "kind": "wing",
    "applies": true,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 200,
    "expected_ev_gain": 1
  },
  {
    "scenario": "health_wing_total_cap_510_reject",
    "id": "health_wing",
    "kind": "wing",
    "applies": false,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "health_wing_unexpected_slot_reject",
    "id": "health_wing",
    "kind": "wing",
    "applies": false,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "health_wing_friendship_254_cap",
    "id": "health_wing",
    "kind": "wing",
    "applies": true,
    "stat": "hp",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 1
  },
  {
    "scenario": "health_wing_dual_cap_target250_total509",
    "id": "health_wing",
    "kind": "wing",
    "applies": true,
    "stat": "hp",
    "start_ev": 250,
    "other_ev_total": 259,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "muscle_wing_base_0_ev",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": true,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 1
  },
  {
    "scenario": "muscle_wing_near_stat_251",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": true,
    "stat": "attack",
    "start_ev": 251,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "muscle_wing_stat_cap_252_reject",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": false,
    "stat": "attack",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "muscle_wing_near_total_509",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": true,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 200,
    "expected_ev_gain": 1
  },
  {
    "scenario": "muscle_wing_total_cap_510_reject",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": false,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "muscle_wing_unexpected_slot_reject",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": false,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "muscle_wing_friendship_254_cap",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": true,
    "stat": "attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 1
  },
  {
    "scenario": "muscle_wing_dual_cap_target250_total509",
    "id": "muscle_wing",
    "kind": "wing",
    "applies": true,
    "stat": "attack",
    "start_ev": 250,
    "other_ev_total": 259,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "resist_wing_base_0_ev",
    "id": "resist_wing",
    "kind": "wing",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 1
  },
  {
    "scenario": "resist_wing_near_stat_251",
    "id": "resist_wing",
    "kind": "wing",
    "applies": true,
    "stat": "defense",
    "start_ev": 251,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "resist_wing_stat_cap_252_reject",
    "id": "resist_wing",
    "kind": "wing",
    "applies": false,
    "stat": "defense",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "resist_wing_near_total_509",
    "id": "resist_wing",
    "kind": "wing",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 200,
    "expected_ev_gain": 1
  },
  {
    "scenario": "resist_wing_total_cap_510_reject",
    "id": "resist_wing",
    "kind": "wing",
    "applies": false,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "resist_wing_unexpected_slot_reject",
    "id": "resist_wing",
    "kind": "wing",
    "applies": false,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "resist_wing_friendship_254_cap",
    "id": "resist_wing",
    "kind": "wing",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 1
  },
  {
    "scenario": "resist_wing_dual_cap_target250_total509",
    "id": "resist_wing",
    "kind": "wing",
    "applies": true,
    "stat": "defense",
    "start_ev": 250,
    "other_ev_total": 259,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "genius_wing_base_0_ev",
    "id": "genius_wing",
    "kind": "wing",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 1
  },
  {
    "scenario": "genius_wing_near_stat_251",
    "id": "genius_wing",
    "kind": "wing",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 251,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "genius_wing_stat_cap_252_reject",
    "id": "genius_wing",
    "kind": "wing",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "genius_wing_near_total_509",
    "id": "genius_wing",
    "kind": "wing",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 200,
    "expected_ev_gain": 1
  },
  {
    "scenario": "genius_wing_total_cap_510_reject",
    "id": "genius_wing",
    "kind": "wing",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "genius_wing_unexpected_slot_reject",
    "id": "genius_wing",
    "kind": "wing",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "genius_wing_friendship_254_cap",
    "id": "genius_wing",
    "kind": "wing",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 1
  },
  {
    "scenario": "genius_wing_dual_cap_target250_total509",
    "id": "genius_wing",
    "kind": "wing",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 250,
    "other_ev_total": 259,
    "start_friendship": 100,
    "expected_ev_gain": 1
  }
]''')
IDS_05 = ["health_wing","muscle_wing","resist_wing","genius_wing"]
SOURCES_05 = ["modules/inventory/field_training_effects.gd","modules/inventory/field_friendship_effects.gd","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/parallel_items_w02_campaign_005.gd"]

EXPECTED_06 = json.loads(r'''[
  {
    "scenario": "clever_wing_zero",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 1
  },
  {
    "scenario": "clever_wing_stat_near",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": true,
    "start_ev": 251,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "clever_wing_stat_reject",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": false,
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "clever_wing_total_near",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 200,
    "expected_ev_gain": 1
  },
  {
    "scenario": "clever_wing_total_reject",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "clever_wing_slot_reject",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "clever_wing_friend_254",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 1
  },
  {
    "scenario": "clever_wing_total_509",
    "id": "clever_wing",
    "kind": "wing",
    "stat": "special_defense",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "swift_wing_zero",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 1
  },
  {
    "scenario": "swift_wing_stat_near",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": true,
    "start_ev": 251,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "swift_wing_stat_reject",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": false,
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "swift_wing_total_near",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 200,
    "expected_ev_gain": 1
  },
  {
    "scenario": "swift_wing_total_reject",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "swift_wing_slot_reject",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "swift_wing_friend_254",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 1
  },
  {
    "scenario": "swift_wing_total_509",
    "id": "swift_wing",
    "kind": "wing",
    "stat": "speed",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "health_mochi_zero",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "health_mochi_stat_near",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": true,
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "health_mochi_stat_reject",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": false,
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "health_mochi_total_near",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "health_mochi_total_reject",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "health_mochi_slot_reject",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "health_mochi_friend_254",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 10
  },
  {
    "scenario": "health_mochi_total_509",
    "id": "health_mochi",
    "kind": "mochi",
    "stat": "hp",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "muscle_mochi_zero",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "muscle_mochi_stat_near",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": true,
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "muscle_mochi_stat_reject",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": false,
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "muscle_mochi_total_near",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "muscle_mochi_total_reject",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "muscle_mochi_slot_reject",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": false,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "muscle_mochi_friend_254",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 10
  },
  {
    "scenario": "muscle_mochi_total_509",
    "id": "muscle_mochi",
    "kind": "mochi",
    "stat": "attack",
    "applies": true,
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  }
]''')
IDS_06 = ["clever_wing","swift_wing","health_mochi","muscle_mochi"]
SOURCES_06 = ["modules/inventory/field_training_effects.gd","modules/inventory/field_mochi_effects.gd","modules/inventory/field_item_effects.gd","modules/inventory/field_friendship_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_mochi_v13.gd"]

EXPECTED_07 = json.loads(r'''[
  {
    "scenario": "resist_mochi_zero_ev",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "resist_mochi_near_stat_cap_248",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "defense",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "resist_mochi_stat_cap_252_reject",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "defense",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "resist_mochi_near_total_508",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "resist_mochi_total_510_reject",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "resist_mochi_unexpected_slot_reject",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "resist_mochi_friendship_254_preserved",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 10
  },
  {
    "scenario": "resist_mochi_total_509_one_ev",
    "id": "resist_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "defense",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "genius_mochi_zero_ev",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "genius_mochi_near_stat_cap_248",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "genius_mochi_stat_cap_252_reject",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "genius_mochi_near_total_508",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "genius_mochi_total_510_reject",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "genius_mochi_unexpected_slot_reject",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "genius_mochi_friendship_254_preserved",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 10
  },
  {
    "scenario": "genius_mochi_total_509_one_ev",
    "id": "genius_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_attack",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "clever_mochi_zero_ev",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "clever_mochi_near_stat_cap_248",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "clever_mochi_stat_cap_252_reject",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "special_defense",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "clever_mochi_near_total_508",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "clever_mochi_total_510_reject",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "clever_mochi_unexpected_slot_reject",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "clever_mochi_friendship_254_preserved",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 10
  },
  {
    "scenario": "clever_mochi_total_509_one_ev",
    "id": "clever_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "special_defense",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  },
  {
    "scenario": "swift_mochi_zero_ev",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "expected_ev_gain": 10
  },
  {
    "scenario": "swift_mochi_near_stat_cap_248",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "speed",
    "start_ev": 248,
    "other_ev_total": 0,
    "start_friendship": 100,
    "expected_ev_gain": 4
  },
  {
    "scenario": "swift_mochi_stat_cap_252_reject",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "speed",
    "start_ev": 252,
    "other_ev_total": 0,
    "start_friendship": 200
  },
  {
    "scenario": "swift_mochi_near_total_508",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 508,
    "start_friendship": 200,
    "expected_ev_gain": 2
  },
  {
    "scenario": "swift_mochi_total_510_reject",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 510,
    "start_friendship": 100
  },
  {
    "scenario": "swift_mochi_unexpected_slot_reject",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": false,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 99,
    "slot": 0
  },
  {
    "scenario": "swift_mochi_friendship_254_preserved",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 0,
    "start_friendship": 254,
    "expected_ev_gain": 10
  },
  {
    "scenario": "swift_mochi_total_509_one_ev",
    "id": "swift_mochi",
    "kind": "mochi",
    "applies": true,
    "stat": "speed",
    "start_ev": 0,
    "other_ev_total": 509,
    "start_friendship": 100,
    "expected_ev_gain": 1
  }
]''')
IDS_07 = ["resist_mochi","genius_mochi","clever_mochi","swift_mochi"]
SOURCES_07 = ["modules/inventory/field_mochi_effects.gd","modules/inventory/field_training_effects.gd","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_mochi_v13.gd","docs/current/ITEM_MOCHI_V13.md"]

EXPECTED_08 = json.loads(r'''[
  {
    "scenario": "reset_hp_100",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "hp": 100
    }
  },
  {
    "scenario": "reset_attack_252",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "attack": 252
    }
  },
  {
    "scenario": "reset_defense_60_spatk_70",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "defense": 60,
      "special_attack": 70
    }
  },
  {
    "scenario": "reset_all_six_10",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "hp": 10,
      "attack": 10,
      "defense": 10,
      "special_attack": 10,
      "special_defense": 10,
      "speed": 10
    }
  },
  {
    "scenario": "reset_full_510",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "hp": 252,
      "attack": 252,
      "defense": 6
    }
  },
  {
    "scenario": "reset_speed_150",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "speed": 150
    }
  },
  {
    "scenario": "reset_friendship_254",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": true,
    "reset_evs": {
      "hp": 100,
      "speed": 50
    },
    "start_friendship": 254
  },
  {
    "scenario": "reset_already_zero",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": false,
    "reset_evs": {}
  },
  {
    "scenario": "reset_invalid_slot",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": false,
    "reset_evs": {
      "hp": 100
    },
    "slot": 0
  },
  {
    "scenario": "reset_510_wrong_slot",
    "id": "fresh_start_mochi",
    "kind": "mochi_reset",
    "applies": false,
    "reset_evs": {
      "hp": 252,
      "attack": 252,
      "defense": 6
    },
    "slot": 1
  },
  {
    "scenario": "adamant_mint_hardy_target",
    "id": "adamant_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "adamant",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "hardy"
  },
  {
    "scenario": "adamant_mint_same_nature",
    "id": "adamant_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "adamant",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "adamant"
  },
  {
    "scenario": "adamant_mint_foreign_nature",
    "id": "adamant_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "adamant",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "modest"
  },
  {
    "scenario": "adamant_mint_friendship_254",
    "id": "adamant_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "adamant",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "start_friendship": 254
  },
  {
    "scenario": "adamant_mint_with_slot",
    "id": "adamant_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "adamant",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "slot": 0
  },
  {
    "scenario": "adamant_mint_at_level100",
    "id": "adamant_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "adamant",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "level": 100
  },
  {
    "scenario": "modest_mint_hardy_target",
    "id": "modest_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "modest",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "hardy"
  },
  {
    "scenario": "modest_mint_same_nature",
    "id": "modest_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "modest",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "modest"
  },
  {
    "scenario": "modest_mint_foreign_nature",
    "id": "modest_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "modest",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "adamant"
  },
  {
    "scenario": "modest_mint_friendship_254",
    "id": "modest_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "modest",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "start_friendship": 254
  },
  {
    "scenario": "modest_mint_with_slot",
    "id": "modest_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "modest",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "slot": 0
  },
  {
    "scenario": "modest_mint_at_level100",
    "id": "modest_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "modest",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "level": 100
  },
  {
    "scenario": "jolly_mint_hardy_target",
    "id": "jolly_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "jolly",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "hardy"
  },
  {
    "scenario": "jolly_mint_same_nature",
    "id": "jolly_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "jolly",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "jolly"
  },
  {
    "scenario": "jolly_mint_foreign_nature",
    "id": "jolly_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "jolly",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "nature": "adamant"
  },
  {
    "scenario": "jolly_mint_friendship_254",
    "id": "jolly_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "jolly",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "start_friendship": 254
  },
  {
    "scenario": "jolly_mint_with_slot",
    "id": "jolly_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "jolly",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "slot": 0
  },
  {
    "scenario": "jolly_mint_at_level100",
    "id": "jolly_mint",
    "kind": "mint_dependency",
    "applies": false,
    "wanted_nature": "jolly",
    "expect_status": "DEPENDENCY_MISSING",
    "expect_reason": "field_effect_not_connected",
    "level": 100
  }
]''')
IDS_08 = ["fresh_start_mochi","adamant_mint","modest_mint","jolly_mint"]
SOURCES_08 = ["modules/inventory/field_mochi_effects.gd","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","modules/creatures/progression/progression_ruleset.gd","config/item_selection_v1.json","tests/gameplay/item_mochi_v13.gd"]


class ContractError(ValueError):
    pass


class Checks:
    def __init__(self):
        self.count = 0

    def demand(self, condition, message):
        self.count += 1
        if not condition:
            raise ContractError(message)


def csv_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def verify(fixture, queue, progress, chk):
    chk.demand(type(fixture) is dict, "Fixture incorrecta")
    chk.demand(set(fixture) == {
        "schema_version", "campaign", "worker", "kind", "purpose",
        "blocks", "format", "modes", "completed_blocks", "seed", "limitations"
    }, "Esquema CAMP005 alterado")
    chk.demand(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_005"
               and fixture["worker"] == "W02" and fixture["kind"] == "TRAINING",
               "Identidad/campaña/familia distintas")
    chk.demand(fixture["format"] == "gen9calvounifiedv1"
               and fixture["modes"] == ["active", "none", "reserve"]
               and fixture["seed"] == 1412, "Formato, semilla o modos cambiados")
    chk.demand(len(fixture["limitations"]) >= 3, "Limitaciones contractuales retiradas")
    chk.demand(len(queue) == 10 and all(
        row["trabajadora"] == "W02" and row["bloque"] == f"{n:02d}"
        for n, row in enumerate(queue, 1)), "Cola autorizada IA6 alterada")
    chk.demand(len(progress) == len(fixture["blocks"]) and 1 <= len(progress) <= 10,
               "Progreso sin correspondencia con bloques")
    chk.demand(fixture["completed_blocks"] == list(range(1, len(progress) + 1)),
               "Bloques ejecutados discontinuos")
    chk.demand(all(row["estado"] in {
        "EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "DEPENDENCIA_DOCUMENTADA",
        "CI_PASS_VERIFICADO"} for row in progress), "Estado CI no autorizado")
    all_ids, all_scenarios = set(), set()
    for index, block in enumerate(fixture["blocks"]):
        official = queue[index]
        progress_row = progress[index]
        chk.demand(block["block"] == official["bloque"]
                   and block["family"] == official["familia"] == "TRAINING"
                   and block["ids"] == official["ids"].split(";")
                   and progress_row["bloque"] == official["bloque"]
                   and progress_row["ids"] == official["ids"],
                   "IDs/familia no corresponden con IA6")
        chk.demand(len(block["ids"]) == 4 and not all_ids.intersection(block["ids"]),
                   "ID duplicado o número incorrecto")
        all_ids.update(block["ids"])
        chk.demand(len(block["cases"]) > 0, "Bloque sin escenarios funcionales")
        for case in block["cases"]:
            chk.demand(case["id"] in block["ids"] and case["scenario"] not in all_scenarios,
                       "Escenario repetido o ID no asignado")
            chk.demand(case["kind"] in {"ability", "growth", "pp", "vitamin", "wing", "mochi", "mochi_reset", "mint_dependency"}
                       and type(case["applies"]) is bool,
                       "Caso sin operación real ni decisión de aplicación")
            all_scenarios.add(case["scenario"])
        if index == 0:
            chk.demand(block["ids"] == IDS_01 and block["source_evidence"] == SOURCES_01,
                       "Contrato de ID/fuente 01 modificado")
            chk.demand(len(block["cases"]) == len(EXPECTED_01) == 18,
                       "Bloque 01 no tiene 18 escenarios")
            for actual, expected in zip(block["cases"], EXPECTED_01):
                chk.demand(type(actual) is dict and actual == expected,
                           "Mutación de escenario: " + expected["scenario"])
        elif index == 1:
            chk.demand(block["ids"] == IDS_02 and block["source_evidence"] == SOURCES_02,
                       "IDs/fuentes bloque02 distintos de cola IA6")
            chk.demand(len(block["cases"]) == len(EXPECTED_02) == 24,
                       "Bloque02 debe contener 24 escenarios")
            for actual, expected in zip(block["cases"], EXPECTED_02):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario02 modificado: " + expected["scenario"])
        elif index == 2:
            chk.demand(block["ids"] == IDS_03 and block["source_evidence"] == SOURCES_03,
                       "IDs y fuentes del bloque 03 divergentes")
            chk.demand(len(block["cases"]) == len(EXPECTED_03) == 26,
                       "Bloque 03 debe contener exactamente 26 escenarios")
            for actual, expected in zip(block["cases"], EXPECTED_03):
                chk.demand(type(actual) is dict and actual == expected,
                           "Caso del bloque 03 alterado: " + expected["scenario"])
        elif index == 3:
            chk.demand(block["ids"] == IDS_04 and block["source_evidence"] == SOURCES_04,
                       "IDs/fuentes del bloque04 distintos de cola IA6")
            chk.demand(len(block["cases"]) == len(EXPECTED_04) == 32,
                       "Bloque04 no contiene los 32 escenarios")
            for actual, expected in zip(block["cases"], EXPECTED_04):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario04 distinto del contrato: " + expected["scenario"])
        elif index == 4:
            chk.demand(block["ids"] == IDS_05 and block["source_evidence"] == SOURCES_05,
                       "IDs o fuentes del bloque 05 no autorizadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_05) == 32,
                       "Bloque 05 requiere exactamente 32 escenarios")
            for actual, expected in zip(block["cases"], EXPECTED_05):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario 05 no coincide: " + expected["scenario"])
        elif index == 5:
            chk.demand(block["ids"] == IDS_06 and block["source_evidence"] == SOURCES_06,
                       "IDs o fuentes de fila 06 no autorizadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_06) == 32,
                       "Bloque06 necesita exactamente 32 casos")
            for actual, expected in zip(block["cases"], EXPECTED_06):
                chk.demand(type(actual) is dict and actual == expected,
                           "Caso06 alterado: " + expected["scenario"])
        elif index == 6:
            chk.demand(block["ids"] == IDS_07 and block["source_evidence"] == SOURCES_07,
                       "IDs/fuentes del bloque 07 alterados")
            chk.demand(len(block["cases"]) == len(EXPECTED_07) == 32,
                       "Bloque 07 necesita exactamente 32 escenarios")
            for actual, expected in zip(block["cases"], EXPECTED_07):
                chk.demand(type(actual) is dict and actual == expected,
                           "Mochi 07 diferente del golden: " + expected["scenario"])
        elif index == 7:
            chk.demand(block["ids"] == IDS_08 and block["source_evidence"] == SOURCES_08,
                       "Fila08 IDs/fuentes distintos de IA6")
            chk.demand(len(block["cases"]) == len(EXPECTED_08) == 28,
                       "Bloque08 requiere 28 casos: 10 Mochi reset y 18 dependencias menta")
            for actual, expected in zip(block["cases"], EXPECTED_08):
                chk.demand(type(actual) is dict and actual == expected,
                           "Bloque08 mutado: " + expected["scenario"])
        else:
            raise ContractError("Contrato futuro sin autorización nueva: " + block["block"])
    return len(progress)


def verify_sources(chk):
    ability = ABILITY.read_text(encoding="utf-8")
    growth = GROWTH.read_text(encoding="utf-8")
    pp = PPBOOST.read_text(encoding="utf-8")
    service = SERVICE.read_text(encoding="utf-8")
    runner = RUNNER.read_text(encoding="utf-8")
    old_ability = HIST_ABILITY.read_text(encoding="utf-8")
    old_growth = HIST_GROWTH.read_text(encoding="utf-8")
    old_pp = HIST_PP.read_text(encoding="utf-8")
    training = TRAINING.read_text(encoding="utf-8")
    friendship = FRIENDSHIP.read_text(encoding="utf-8")
    historic_training = HIST_TRAINING.read_text(encoding="utf-8")
    mochi = MOCHI.read_text(encoding="utf-8")
    field_effects = FIELD_EFFECTS.read_text(encoding="utf-8")
    historic_mochi = HIST_MOCHI.read_text(encoding="utf-8")
    for fragment in (
        'item_id in [&"ability_capsule", &"ability_patch"]',
        'destination = 2 if current == 1 else 1',
        'destination = 1 if current == 3 else 3',
        'ability_form_route_pending',
    ):
        chk.demand(fragment in ability, "Ruta habilidad nativa ausente: " + fragment)
    for fragment in (
        'item_id == &"rare_candy"',
        'ProgressionRuleset.experience_for_level(species.growth_rate, c.level + 1)',
        'ProgressionSystem.gain_experience(',
        'return deny("item_has_no_effect")',
    ):
        chk.demand(fragment in growth, "Ruta Caramelo Raro incompleta: " + fragment)
    for fragment in (
        'item_id in [&"pp_up", &"pp_max"]',
        'if before_count == 3:',
        'new_max - slot.max_pp',
        'slot.current_pp += added',
    ):
        chk.demand(fragment in pp, "Ruta Mas PP incompleta: " + fragment)
    for fragment in (
        'if Growth.supports(item_id):',
        'if FieldEffects.supports(item_id):',
        'FieldEffects.Abilities.preview(creature, item_id, catalogs)',
        'owner.replace_owned_same_identity(',
        'if not staged.remove(item_id)',
    ):
        chk.demand(fragment in service, "Transacción real no conectada: " + fragment)
    for fragment in (
        '_probe_training(spec, mode)',
        'service.use_item(item, &"own", slot, &"", stamp)',
        'SaveGameRepository.new().decode_snapshot(state)',
        'FileAccess.get_sha256(',
        'original',
    ):
        chk.demand(fragment in runner, "Runner real o recibos incompletos: " + fragment)
    for fragment in (
        'var count := 3 if item_id == &"pp_max" else before_count + 1',
        'var new_max := base_pp + base_pp * count / 5',
        'slot.current_pp += added',
        'if before_count == 3:',
    ):
        chk.demand(fragment in pp, "PP Max contrato nativo distinto: " + fragment)
    for fragment in (
        '"hp_up": "hp"',
        '"protein": "attack"',
        '"iron": "defense"',
        'ProgressionRuleset.EV_PER_STAT_MAX - old_ev',
        'ProgressionRuleset.EV_TOTAL_MAX - total',
        'creature.recalculate_stats(',
        'Friendship.increase(creature, [5, 3, 2]',
        '"action": "ev_training"',
    ):
        chk.demand(fragment in training, "Vitaminas contrato nativo distinto: " + fragment)
    for fragment in ('gains[mini(2, creature.friendship / 100)]',
                     'creature.friendship = mini(255, before + gain)'):
        chk.demand(fragment in friendship, "Tramos de amistad modificados")
    for fragment in (
        'elif String(spec.kind) in ["vitamin", "wing", "mochi"]:',
        'var expected_evs: Dictionary = start_evs.duplicate(true)',
        'StatCalculator.compute(',
        'var friendship_added: int = (0 if String(spec.kind) == "mochi" else ([3, 2, 1] if String(spec.kind) == "wing" else [5, 3, 2])[tier])',
    ):
        chk.demand(fragment in runner, "Arnés vitamina incompleto: " + fragment)
    for fragment in ('&"hp_up"', '&"iron"', '&"pp_max"', '&"protein"'):
        chk.demand(fragment in historic_training,
                   "Regresión previa entrenamiento ausente: " + fragment)
    for fragment in (
        '"calcium": "special_attack"',
        '"zinc": "special_defense"',
        '"carbos": "speed"',
        'var gain := mini(10 if vitamin else 1',
        'ProgressionRuleset.EV_PER_STAT_MAX - old_ev',
        'ProgressionRuleset.EV_TOTAL_MAX - total',
    ):
        chk.demand(fragment in training, "Límites y mapa de vitamina 03 cambiados: " + fragment)
    for fragment in (
        'const EXP := {"exp_candy_xs": 100',
        'item_id == &"rare_candy" or EXP.has(String(item_id))',
        'var target := mini(maximum, c.experience + int(EXP.get(String(item_id), 0)))',
        'ProgressionSystem.gain_experience(',
        'if summary.exp_gained > 0: Friendship.increase(c, [5, 3, 2])',
    ):
        chk.demand(fragment in growth, "Caramelo Exp XS no respaldado por motor: " + fragment)
    for fragment in (
        'if spec.has("exp_until_next"):',
        'c.experience = ProgressionRuleset.experience_for_level(curve, c.level + 1)',
        'ProgressionRuleset.level_for_experience(curve, expected_exp)',
        'int(result.get("exp_gained", -1)) == gain_expected',
    ):
        chk.demand(fragment in runner, "Escenario XP real 03 no instrumentado: " + fragment)
    for fragment in (
        '"exp_candy_s": 800',
        '"exp_candy_m": 3000',
        '"exp_candy_l": 10000',
        '"exp_candy_xl": 30000',
        'var target := mini(maximum, c.experience + int(EXP.get(String(item_id), 0)))',
        'ProgressionSystem.gain_experience(',
        'if summary.exp_gained > 0: Friendship.increase(c, [5, 3, 2])',
    ):
        chk.demand(fragment in growth, "Caramelos S/M/L/XL: magnitudes/rutas no corresponden: "+fragment)
    for fragment in (
        'var nominal_exp: int = int(spec.get("exp_amount", 100))',
        'expected_exp = mini(cap_exp, c.experience + nominal_exp)',
        'var gain_expected: int = expected_exp - c.experience',
        'gain_expected > 0 and gain_expected <= nominal_exp',
        'int(result.get("exp_gained", -1)) == gain_expected',
        'bool(spec.get("expect_cap", false))',
        'bool(spec.get("expect_level_up", false))',
    ):
        chk.demand(fragment in runner, "Caramelos S/M/L/XL: prueba Godot incompleta: "+fragment)
    chk.demand((ROOT / "tests/fixtures/progression_growth_curves/reference_contract.json").is_file(),
               "Sin referencia independiente de curva de crecimiento")
    for fragment in (
        '"health_wing": "hp"',
        '"muscle_wing": "attack"',
        '"resist_wing": "defense"',
        '"genius_wing": "special_attack"',
        'var vitamin := VITAMINS.has(String(item_id))',
        'var gain := mini(10 if vitamin else 1',
        'Friendship.increase(creature, [5, 3, 2] if vitamin else [3, 2, 1])',
    ):
        chk.demand(fragment in training, "Contrato plumas 05 fuera del motor: " + fragment)
    for fragment in (
        'if String(spec.kind) in ["vitamin", "wing", "mochi"]:',
        'elif String(spec.kind) in ["vitamin", "wing", "mochi"]:',
        'var friendship_added: int = (0 if String(spec.kind) == "mochi" else ([3, 2, 1] if String(spec.kind) == "wing" else [5, 3, 2])[tier])',
        'now.evs == expected_evs',
        'expected_total <= 510',
        'and now.stats.max_hp - now.current_hp == start_hp_deficit',
    ):
        chk.demand(fragment in runner, "Arnés plumas 05 no implementa EV y amistad: " + fragment)
    for fragment in (
        '"clever_wing": "special_defense"',
        '"swift_wing": "speed"',
        'Friendship.increase(creature, [5, 3, 2] if vitamin else [3, 2, 1])',
    ):
        chk.demand(fragment in training, "Plumas 06 sin +1 EV ni amistad por banda: " + fragment)
    for fragment in (
        '"health_mochi": "hp"',
        '"muscle_mochi": "attack"',
        'var gain := 0 if reset else mini(10',
        'ProgressionRuleset.EV_PER_STAT_MAX',
        'ProgressionRuleset.EV_TOTAL_MAX',
        'c.recalculate_stats(',
        'if (reset and total == 0) or (not reset and gain == 0)',
    ):
        chk.demand(fragment in mochi, "Mochi 06 desconectado o cambiado: " + fragment)
    for fragment in (
        'const Mochi = preload("res://modules/inventory/field_mochi_effects.gd")',
        'if Mochi.supports(item_id): return Mochi.validation_error',
        'if Mochi.supports(item_id): return Mochi.apply(',
    ):
        chk.demand(fragment in field_effects, "Despacho mochi fuera de FieldItemService: " + fragment)
    chk.demand('const ITEMS := {"health_mochi": "hp", "muscle_mochi": "attack"' in historic_mochi
               and 'var expected := _expected(c, item)' in historic_mochi,
               "Regresión histórica Mochi V13 ausente")
    for fragment in (
        '"resist_mochi": "defense"',
        '"genius_mochi": "special_attack"',
        '"clever_mochi": "special_defense"',
        '"swift_mochi": "speed"',
        'var gain := 0 if reset else mini(10',
        'ProgressionRuleset.EV_TOTAL_MAX - total',
        'c.recalculate_stats(',
    ):
        chk.demand(fragment in mochi, "Mochis bloque07: perfil real alterado " + fragment)
    chk.demand("Friendship.increase(" not in mochi,
               "Mochis bloque07: amistad nativa cambió, actualizar oráculo mediante IA6")
    for fragment in (
        'const MOCHI_STATS_005 := {"health_mochi": "hp", "muscle_mochi": "attack"',
        '"resist_mochi": "defense"',
        '"genius_mochi": "special_attack"',
        '"clever_mochi": "special_defense"',
        '"swift_mochi": "speed"',
        'var native_gain: int = mini(10, mini(',
        'real_stat == stat and gain == native_gain',
        'and now.stats.max_hp - now.current_hp == start_hp_deficit',
    ):
        chk.demand(fragment in runner, "Mochis bloque07: runner Godot incompleto " + fragment)
    for old, token in (
        (old_ability, 'TRANSITIONS'),
        (old_growth, 'rare_candy'),
        (old_pp, 'pp_up'),
    ):
        chk.demand(token in old, "Regresión histórica ausente: " + token)


def negative_controls(fixture, queue, progress, chk):
    mutations = [
        lambda v: v.update({"worker": "W03"}),
        lambda v: v.update({"campaign": "CAMP_004"}),
        lambda v: v.update({"format": "gen8ou"}),
        lambda v: v["completed_blocks"].append(2),
        lambda v: v["blocks"][0]["ids"].append("pp_max"),
        lambda v: v["blocks"][0]["source_evidence"].pop(),
        lambda v: v["blocks"][0]["cases"].pop(),
        lambda v: v["blocks"][0]["cases"].append(copy.deepcopy(v["blocks"][0]["cases"][0])),
        lambda v: v["blocks"][0]["cases"][0].update({"expected_ability": "justified"}),
        lambda v: v["blocks"][0]["cases"][2].update({"applies": True}),
        lambda v: v["blocks"][0]["cases"][8].update({"expected_level": 53}),
        lambda v: v["blocks"][0]["cases"][10].update({"applies": True}),
        lambda v: v["blocks"][0]["cases"][12].update({"expected_boosts": 3}),
        lambda v: v["blocks"][0]["cases"][15].update({"applies": True}),
        lambda v: v["blocks"][0]["cases"][17].update({"slot": 0}),
    ]
    if len(fixture["blocks"]) >= 2:
        mutations.extend([
            lambda v: v["blocks"][1]["ids"].append("zinc"),
            lambda v: v["blocks"][1]["source_evidence"].pop(),
            lambda v: v["blocks"][1]["cases"].pop(),
            lambda v: v["blocks"][1]["cases"][0].update({"expected_boosts": 1}),
            lambda v: v["blocks"][1]["cases"][1].update({"boosts": 3}),
            lambda v: v["blocks"][1]["cases"][3].update({"applies": True}),
            lambda v: v["blocks"][1]["cases"][5].update({"slot": 0}),
            lambda v: v["blocks"][1]["cases"][6].update({"expected_ev_gain": 5}),
            lambda v: v["blocks"][1]["cases"][7].update({"start_ev": 242}),
            lambda v: v["blocks"][1]["cases"][8].update({"applies": True}),
            lambda v: v["blocks"][1]["cases"][9].update({"expected_ev_gain": 10}),
            lambda v: v["blocks"][1]["cases"][10].update({"applies": True}),
            lambda v: v["blocks"][1]["cases"][12].update({"stat": "hp"}),
            lambda v: v["blocks"][1]["cases"][18].update({"stat": "attack"}),
            lambda v: v["blocks"][1]["cases"][23].update({"applies": True}),
        ])
    if len(fixture["blocks"]) >= 3:
        mutations.extend([
            lambda v: v["blocks"][2]["ids"].append("exp_candy_s"),
            lambda v: v["blocks"][2]["source_evidence"].pop(),
            lambda v: v["blocks"][2]["cases"].pop(),
            lambda v: v["blocks"][2]["cases"][0].update({"stat": "attack"}),
            lambda v: v["blocks"][2]["cases"][1].update({"expected_ev_gain": 10}),
            lambda v: v["blocks"][2]["cases"][2].update({"applies": True}),
            lambda v: v["blocks"][2]["cases"][3].update({"expected_ev_gain": 10}),
            lambda v: v["blocks"][2]["cases"][6].update({"stat": "hp"}),
            lambda v: v["blocks"][2]["cases"][12].update({"stat": "special_attack"}),
            lambda v: v["blocks"][2]["cases"][18].update({"exp_gain": 800}),
            lambda v: v["blocks"][2]["cases"][21].update({"exp_gain": 100}),
            lambda v: v["blocks"][2]["cases"][22].update({"exp_until_next": 1000}),
            lambda v: v["blocks"][2]["cases"][23].update({"applies": True}),
            lambda v: v["blocks"][2]["cases"][24].update({"applies": True}),
            lambda v: v["blocks"][2]["cases"][25].update({"start_friendship": 99}),
        ])
    if len(fixture["blocks"]) >= 4:
        mutations.extend([
            lambda v: v["blocks"][3]["ids"].append("exp_candy_xs"),
            lambda v: v["blocks"][3]["source_evidence"].pop(),
            lambda v: v["blocks"][3]["cases"].pop(),
            lambda v: v["blocks"][3]["cases"][0].update({"exp_amount": 100}),
            lambda v: v["blocks"][3]["cases"][1].update({"level": 99}),
            lambda v: v["blocks"][3]["cases"][3].update({"expected_exp_gain": 800}),
            lambda v: v["blocks"][3]["cases"][4].update({"expect_level_up": False}),
            lambda v: v["blocks"][3]["cases"][5].update({"applies": True}),
            lambda v: v["blocks"][3]["cases"][6].update({"slot": -1}),
            lambda v: v["blocks"][3]["cases"][7].update({"start_friendship": 99}),
            lambda v: v["blocks"][3]["cases"][8].update({"exp_amount": 800}),
            lambda v: v["blocks"][3]["cases"][16].update({"exp_amount": 3000}),
            lambda v: v["blocks"][3]["cases"][24].update({"exp_amount": 10000}),
            lambda v: v["blocks"][3]["cases"][26].update({"expect_cap": False}),
            lambda v: v["blocks"][3]["cases"][28].update({"exp_until_next": 500}),
            lambda v: v["blocks"][3]["cases"][31].update({"start_friendship": 199}),
        ])
    if len(fixture["blocks"]) >= 5:
        mutations.extend([
            lambda v: v["blocks"][4]["ids"].append("clever_wing"),
            lambda v: v["blocks"][4]["source_evidence"].pop(),
            lambda v: v["blocks"][4]["cases"].pop(),
            lambda v: v["blocks"][4]["cases"][0].update({"expected_ev_gain": 10}),
            lambda v: v["blocks"][4]["cases"][1].update({"start_ev": 250}),
            lambda v: v["blocks"][4]["cases"][2].update({"applies": True}),
            lambda v: v["blocks"][4]["cases"][3].update({"expected_ev_gain": 2}),
            lambda v: v["blocks"][4]["cases"][4].update({"applies": True}),
            lambda v: v["blocks"][4]["cases"][5].update({"slot": -1}),
            lambda v: v["blocks"][4]["cases"][6].update({"start_friendship": 100}),
            lambda v: v["blocks"][4]["cases"][7].update({"other_ev_total": 260}),
            lambda v: v["blocks"][4]["cases"][8].update({"stat": "hp"}),
            lambda v: v["blocks"][4]["cases"][16].update({"stat": "attack"}),
            lambda v: v["blocks"][4]["cases"][24].update({"stat": "defense"}),
            lambda v: v["blocks"][4]["cases"][27].update({"other_ev_total": 510}),
            lambda v: v["blocks"][4]["cases"][31].update({"expected_ev_gain": 0}),
        ])
    if len(fixture["blocks"]) >= 6:
        mutations.extend([
            lambda f: f["blocks"][5]["ids"].append("resist_mochi"),
            lambda f: f["blocks"][5]["source_evidence"].pop(),
            lambda f: f["blocks"][5]["cases"].pop(),
            lambda f: f["blocks"][5]["cases"][0].update({"stat": "attack"}),
            lambda f: f["blocks"][5]["cases"][1].update({"expected_ev_gain": 10}),
            lambda f: f["blocks"][5]["cases"][2].update({"applies": True}),
            lambda f: f["blocks"][5]["cases"][3].update({"other_ev_total": 508}),
            lambda f: f["blocks"][5]["cases"][6].update({"start_friendship": 99}),
            lambda f: f["blocks"][5]["cases"][8].update({"stat": "hp"}),
            lambda f: f["blocks"][5]["cases"][12].update({"applies": True}),
            lambda f: f["blocks"][5]["cases"][16].update({"expected_ev_gain": 1}),
            lambda f: f["blocks"][5]["cases"][17].update({"start_ev": 251}),
            lambda f: f["blocks"][5]["cases"][19].update({"expected_ev_gain": 10}),
            lambda f: f["blocks"][5]["cases"][22].update({"start_friendship": 200}),
            lambda f: f["blocks"][5]["cases"][24].update({"kind": "vitamin"}),
            lambda f: f["blocks"][5]["cases"][30].update({"start_friendship": 99}),
        ])
    if len(fixture["blocks"]) >= 7:
        mutations.extend([
            lambda f: f["blocks"][6]["ids"].append("health_mochi"),
            lambda f: f["blocks"][6]["source_evidence"].pop(),
            lambda f: f["blocks"][6]["cases"].pop(),
            lambda f: f["blocks"][6]["cases"][0].update({"stat": "attack"}),
            lambda f: f["blocks"][6]["cases"][1].update({"start_ev": 247}),
            lambda f: f["blocks"][6]["cases"][2].update({"applies": True}),
            lambda f: f["blocks"][6]["cases"][3].update({"expected_ev_gain": 10}),
            lambda f: f["blocks"][6]["cases"][4].update({"applies": True}),
            lambda f: f["blocks"][6]["cases"][5].update({"slot": -1}),
            lambda f: f["blocks"][6]["cases"][6].update({"start_friendship": 99}),
            lambda f: f["blocks"][6]["cases"][8].update({"stat": "defense"}),
            lambda f: f["blocks"][6]["cases"][10].update({"applies": True}),
            lambda f: f["blocks"][6]["cases"][16].update({"expected_ev_gain": 1}),
            lambda f: f["blocks"][6]["cases"][22].update({"start_friendship": 200}),
            lambda f: f["blocks"][6]["cases"][24].update({"kind": "vitamin"}),
            lambda f: f["blocks"][6]["cases"][31].update({"expected_ev_gain": 10}),
        ])
    for index, mutation in enumerate(mutations):
        altered = copy.deepcopy(fixture)
        mutation(altered)
        rejected = False
        try:
            verify(altered, queue, progress, Checks())
        except (ContractError, KeyError, TypeError, IndexError):
            rejected = True
        chk.demand(rejected, f"Mutación adversarial {index} no rechazada")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    queue = csv_rows(QUEUE)
    progress = csv_rows(PROGRESS)
    checks = Checks()
    count = verify(fixture, queue, progress, checks)
    verify_sources(checks)
    negative_controls(fixture, queue, progress, checks)
    if args.ci:
        print(f"CAMP005_W02_PY PASS blocks={count} checks={checks.count}")
    else:
        print(f"W02 CAMP005 static verified blocks={count} checks={checks.count}; no Godot runtime")


if __name__ == "__main__":
    main()
