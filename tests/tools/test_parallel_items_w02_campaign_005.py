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
            chk.demand(case["kind"] in {"ability", "growth", "pp", "vitamin"}
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
        'elif String(spec.kind) == "vitamin":',
        'var expected_evs: Dictionary = start_evs.duplicate(true)',
        'StatCalculator.compute(',
        'var friendship_added: int = [5, 3, 2][tier]',
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
