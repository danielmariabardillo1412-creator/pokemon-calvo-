#!/usr/bin/env python3
"""Compile the eleven reviewed O110 battle-support rows from pinned references.

The output is a Calvo profile manifest, not canonical data. Sources are hash
pinned before parsing; unknown or missing rows fail the import instead of
silently changing the contract. Consumption and target scope are transcribed
from the references, never guessed:

- RHH 8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c items.h: battleUsage and the
  flutes' notConsumed flag. The six X items, Dire Hit and Guard Spec spend one
  unit on success; the three flutes are reusable.
- Essentials 8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b battle scripts: active
  battler versus party targeting, the +6 stat cap, Focus Energy, Mist and the
  "battleitem" happiness gain used for the friendship subeffect.
"""
from pathlib import Path
import argparse, hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/item_import'))
import import_recovery as recovery

OUTPUT = ROOT / 'modules/inventory/battle_support_profile.json'
RHH_ITEMS = ROOT / '.godot/item_mochi_v13/references/items.h'
RHH_ITEMS_SHA256 = '107f1b78a457f3a9c48749f325d674b62fe559b0ebfc365db13e82b00b19ecd3'
RHH_COMMIT = '8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c'
ESSENTIALS_ROOT = Path('D:/Proyectos/Pokemon Calvo Referencias/fuentes/pokemon-essentials')
ESSENTIALS_COMMIT = '8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b'
ESSENTIALS_SHA256 = {
    'Data/Scripts/013_Items/003_Item_BattleEffects.rb': 'acd6f3d2f49e2d8084310b8b62f269973a26fa9c7a1ec4191a64d0b119f223e0',
    'Data/Scripts/014_Pokemon/001_Pokemon.rb': '3a7f233156f09a6d2e3729bdaa9d1962bfa946aaaa7403042aaea5dcdcdf8cb4',
    'Data/Scripts/002_BattleSettings.rb': '9d985b5ba37afaf39231601dff2b2143fab9a82b0d8755af095c6482b5481b24',
}

# Reviewed rows. expected_usage / expected_field are verified against the pinned
# source; a change in the source rows fails the import.
ROWS = {
    'x_attack': {'effect': 'increase_stat', 'stat': 'attack', 'stages': 2, 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_INCREASE_STAT'},
    'x_defense': {'effect': 'increase_stat', 'stat': 'defense', 'stages': 2, 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_INCREASE_STAT'},
    'x_sp_atk': {'effect': 'increase_stat', 'stat': 'special_attack', 'stages': 2, 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_INCREASE_STAT'},
    'x_sp_def': {'effect': 'increase_stat', 'stat': 'special_defense', 'stages': 2, 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_INCREASE_STAT'},
    'x_speed': {'effect': 'increase_stat', 'stat': 'speed', 'stages': 2, 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_INCREASE_STAT'},
    'x_accuracy': {'effect': 'increase_stat', 'stat': 'accuracy', 'stages': 2, 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_INCREASE_STAT'},
    'dire_hit': {'effect': 'focus_energy', 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_SET_FOCUS_ENERGY'},
    'guard_spec': {'effect': 'mist', 'consumable': True, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_SET_MIST'},
    'blue_flute': {'effect': 'cure_status', 'cure': 'sleep', 'consumable': False, 'target': 'any_own_living', 'expected_usage': 'EFFECT_ITEM_CURE_STATUS'},
    'yellow_flute': {'effect': 'cure_volatile', 'cure': 'confusion', 'consumable': False, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_CURE_STATUS'},
    'red_flute': {'effect': 'cure_volatile', 'cure': 'attraction', 'consumable': False, 'target': 'active_own', 'expected_usage': 'EFFECT_ITEM_CURE_STATUS'},
}

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def essentials_file(rel):
    path = ESSENTIALS_ROOT / rel
    if not path.is_file():
        raise ValueError('missing pinned Essentials source: ' + str(path))
    actual = digest(path)
    if actual != ESSENTIALS_SHA256[rel]:
        raise ValueError('pinned Essentials hash mismatch: ' + rel)
    return path.read_text(encoding='utf-8', errors='replace')

def source_rows():
    if digest(RHH_ITEMS) != RHH_ITEMS_SHA256:
        raise ValueError('pinned RHH items.h hash mismatch: ' + str(RHH_ITEMS))
    items, _ = recovery.indexes(RHH_ITEMS.read_text(encoding='utf-8'), (ROOT / '.godot/item_mochi_v13/references/item_effects.h').read_text(encoding='utf-8'))
    return items

def build():
    items = source_rows()
    profile = {
        'schema_version': 1,
        'profile': 'calvo_battle_support_v1',
        'scope': 'Bounded battle-bag rows only; held metadata and world effects are separate contexts.',
        'source': {
            'rhh': {
                'repository': 'https://github.com/rh-hideout/pokeemerald-expansion',
                'commit': RHH_COMMIT,
                'path': 'src/data/items.h',
                'sha256': RHH_ITEMS_SHA256,
                'scope': 'battleUsage, notConsumed and fling metadata for the eleven rows',
            },
            'essentials': {
                'repository': 'https://github.com/Maruno17/pokemon-essentials',
                'commit': ESSENTIALS_COMMIT,
                'files': {rel: ESSENTIALS_SHA256[rel] for rel in sorted(ESSENTIALS_SHA256)},
                'scope': 'target scope, +6 cap, Focus Energy, Mist, "battleitem" happiness gain',
            },
        },
        'settings': {
            'x_item_stages': 2,
            'x_item_cap': 6,
            'friendship_method': 'battleitem',
            'friendship_gains': [1, 1, 0],
            'friendship_ranges': [0, 100, 200],
            'friendship_soft_cap': False,
            'friendship_origin_or_luxury_bonus': 'DEPENDENCY_MISSING: origin-map and Luxury Ball metadata absent; base gain implemented',
        },
        'items': {},
        'limits': [
            'No X2/X3/X6 or Dire Hit 2/3 variants are authorized or imported.',
            'The medicine branch and the V21 escape items are untouched.',
            'Flutes cure only their declared condition and never spend a unit.',
            'Guard Spec applies the native Mist side condition; it does not block every status move.',
            'The base "battleitem" friendship gain is represented; origin-map and Luxury Ball extras need absent metadata.',
        ],
    }
    for item_id, row in sorted(ROWS.items()):
        block = items.get(item_id)
        if block is None:
            raise ValueError('missing pinned source row: ' + item_id)
        usage = recovery.field(block, 'battleUsage')
        if usage != row['expected_usage']:
            raise ValueError('source battleUsage changed for ' + item_id + ': ' + str(usage))
        consumed = recovery.field(block, 'notConsumed', 'FALSE')
        is_consumed = consumed != 'TRUE'
        if is_consumed != row['consumable']:
            raise ValueError('source consumption changed for ' + item_id + ': ' + str(consumed))
        entry = {key: value for key, value in row.items() if not key.startswith('expected_')}
        entry['source_battle_usage'] = usage
        entry['source_not_consumed'] = consumed == 'TRUE'
        profile['items'][item_id] = entry
    # The three flutes and the eight boosters are the only rows; no placeholders.
    if set(profile['items']) != set(ROWS):
        raise ValueError('row set mismatch')
    return profile

def encoded(profile):
    return json.dumps(profile, ensure_ascii=False, indent=2) + '\n'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='verify the stored profile equals the compiled one')
    args = parser.parse_args()
    profile = build()
    text = encoded(profile)
    if args.check:
        stored = OUTPUT.read_text(encoding='utf-8') if OUTPUT.exists() else ''
        if stored != text:
            raise SystemExit('battle_support_profile.json is not the pinned compilation')
        print('BATTLE_SUPPORT_IMPORT PASS rows=' + str(len(profile['items'])))
        return 0
    OUTPUT.write_text(text, encoding='utf-8', newline='\n')
    print('BATTLE_SUPPORT_IMPORT WROTE rows=' + str(len(profile['items'])) + ' sha256=' + hashlib.sha256(text.encode('utf-8')).hexdigest())
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
