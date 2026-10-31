"""Tests for the O110 battle-support import.

Validates the compiled profile against the pinned references and the authorized
scope: exactly eleven rows, no X2/X3/X6 or Dire Hit 2/3 variants, the eight
boosters consume and the three flutes are reusable, and the sources are pinned.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/item_import'))
import import_battle_support_v2 as importer

PROFILE = ROOT / 'modules/inventory/battle_support_profile.json'
SUPPORT_IDS = {
    'x_attack', 'x_defense', 'x_sp_atk', 'x_sp_def', 'x_speed', 'x_accuracy',
    'dire_hit', 'guard_spec', 'blue_flute', 'yellow_flute', 'red_flute',
}
CONSUMABLE = {'x_attack', 'x_defense', 'x_sp_atk', 'x_sp_def', 'x_speed', 'x_accuracy', 'dire_hit', 'guard_spec'}
REUSABLE = {'blue_flute', 'yellow_flute', 'red_flute'}
FORBIDDEN = {'x_attack2', 'x_attack3', 'x_attack6', 'x_defense2', 'x_defense3', 'x_defense6',
             'x_special2', 'x_special3', 'x_special6', 'dire_hit2', 'dire_hit3'}


def test_profile_matches_compiled_rows():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    compiled = importer.build()
    assert stored == compiled, 'battle_support_profile.json is not the pinned compilation'


def test_exact_scope():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    ids = set(stored['items'])
    assert ids == SUPPORT_IDS, 'unexpected row set: %s' % sorted(ids ^ SUPPORT_IDS)
    assert not (ids & FORBIDDEN), 'unauthorized variants present'
    for item_id, row in stored['items'].items():
        assert row.get('source_battle_usage', '').startswith('EFFECT_ITEM_'), item_id
        assert row.get('consumable') is (item_id in CONSUMABLE)
        assert row.get('source_not_consumed') is (item_id in REUSABLE)


def test_consumption_contract():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    for item_id in CONSUMABLE:
        assert stored['items'][item_id]['consumable'] is True, item_id
    for item_id in REUSABLE:
        assert stored['items'][item_id]['consumable'] is False, item_id


def test_x_items_and_targets():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    stats = {'x_attack': 'attack', 'x_defense': 'defense', 'x_sp_atk': 'special_attack',
             'x_sp_def': 'special_defense', 'x_speed': 'speed', 'x_accuracy': 'accuracy'}
    for item_id, stat in stats.items():
        row = stored['items'][item_id]
        assert row['effect'] == 'increase_stat' and row['stat'] == stat
        assert row['stages'] == stored['settings']['x_item_stages'] == 2
        assert row['target'] == 'active_own'
    assert stored['settings']['x_item_cap'] == 6
    assert stored['items']['blue_flute']['target'] == 'any_own_living'
    assert stored['items']['yellow_flute']['target'] == 'active_own'
    assert stored['items']['red_flute']['target'] == 'active_own'
    assert stored['items']['blue_flute']['cure'] == 'sleep'
    assert stored['items']['yellow_flute']['cure'] == 'confusion'
    assert stored['items']['red_flute']['cure'] == 'attraction'
    assert stored['items']['dire_hit']['effect'] == 'focus_energy'
    assert stored['items']['guard_spec']['effect'] == 'mist'


def test_friendship_subeffect_is_declared():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    settings = stored['settings']
    assert settings['friendship_method'] == 'battleitem'
    assert settings['friendship_gains'] == [1, 1, 0]
    assert settings['friendship_soft_cap'] is False
    assert settings['friendship_origin_or_luxury_bonus'].startswith('DEPENDENCY_MISSING')


if __name__ == '__main__':
    test_profile_matches_compiled_rows()
    print('PASS: test_profile_matches_compiled_rows')
    test_exact_scope()
    print('PASS: test_exact_scope')
    test_consumption_contract()
    print('PASS: test_consumption_contract')
    test_x_items_and_targets()
    print('PASS: test_x_items_and_targets')
    test_friendship_subeffect_is_declared()
    print('PASS: test_friendship_subeffect_is_declared')
    print('All battle-support import tests passed.')
