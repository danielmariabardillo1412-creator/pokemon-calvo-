#!/usr/bin/env python3
"""Compile the reviewed O120 world-item metadata (Smoke Ball) from pinned sources.

Only the Smoke Ball descriptor is imported and only after its real effect was
connected and tested at the session Run boundary. Cleanse Tag and Pure Incense
keep their separate encounter-rate context and are NOT registered as neutral.
Sources are hash pinned before parsing.
"""
from pathlib import Path
import argparse, hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/item_import'))
import import_recovery as recovery

OUTPUT = ROOT / 'modules/battle/backends/showdown/field_world_items_v2.json'
RHH_ITEMS = ROOT / '.godot/item_mochi_v13/references/items.h'
RHH_ITEMS_SHA256 = '107f1b78a457f3a9c48749f325d674b62fe559b0ebfc365db13e82b00b19ecd3'
RHH_COMMIT = '8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c'
GEN_SOURCES = {
    'pokecrystal_item_constants.asm': 'bb870ffb3448845aa886ede0030a114a7773d7cb6924d2c59acdca0c53a02e58',
    'pokeemerald_items.h': '6e3a9728b4d90cc23fee0aae9b9ffa9fbd71541e6b3cb2b966f334930b6ad6f8',
    'pokered_item_constants.asm': 'b5a1db015fbf0de637381eb39350f21f35a436a8088e2f6657f65c79f118f97f',
}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def build():
    if digest(RHH_ITEMS) != RHH_ITEMS_SHA256:
        raise ValueError('pinned RHH items.h hash mismatch')
    items, _ = recovery.indexes(RHH_ITEMS.read_text(encoding='utf-8'), (ROOT / '.godot/item_mochi_v13/references/item_effects.h').read_text(encoding='utf-8'))
    block = items.get('smoke_ball')
    if block is None:
        raise ValueError('missing pinned Smoke Ball row')
    name_match = re.search(r'\.name\s*=\s*ITEM_NAME\("([^"]+)"\)', block)
    if not name_match or name_match[1] != 'Smoke Ball':
        raise ValueError('unexpected Smoke Ball name')
    hold = recovery.field(block, 'holdEffect')
    if hold != 'HOLD_EFFECT_CAN_ALWAYS_RUN':
        raise ValueError('unexpected Smoke Ball hold effect: ' + str(hold))
    fling = recovery.field(block, 'flingPower')
    if fling != '30':
        raise ValueError('unexpected Smoke Ball fling power: ' + str(fling))
    # Generation grounding: present in the Gen 2 constants, absent from Gen 1.
    for rel, expected in GEN_SOURCES.items():
        path = ROOT / '.godot/field_held_v16/references' / rel
        if digest(path) != expected:
            raise ValueError('generation source hash mismatch: ' + rel)
    crystal = (ROOT / '.godot/field_held_v16/references/pokecrystal_item_constants.asm').read_text(encoding='utf-8')
    red = (ROOT / '.godot/field_held_v16/references/pokered_item_constants.asm').read_text(encoding='utf-8')
    if 'SMOKE_BALL' not in crystal or 'SMOKE_BALL' in red:
        raise ValueError('Smoke Ball generation grounding failed')
    profile = {
        'schema_version': 1,
        'profile': 'calvo_field_world_items_v2',
        'scope': 'Reviewed native metadata for the one O120 item whose connected effect needs the item to exist in native battles. No callbacks: the Smoke Ball guarantee lives at the session Run boundary and uses the checkpoint\'s real held-item activity (ignoringItem).',
        'source': 'https://github.com/rh-hideout/pokeemerald-expansion/tree/' + RHH_COMMIT,
        'source_sha256': {'items.h': RHH_ITEMS_SHA256},
        'generation_source_sha256': GEN_SOURCES,
        'generation': {'smoke_ball': 2},
        'items': {
            'smokeball': {'name': 'Smoke Ball', 'gen': 2, 'fling': {'basePower': 30}},
        },
        'separate_contexts': [
            'cleanse_tag and pure_incense effects are the validated wild encounter-rate copy in encounter_item_modifiers.gd; their native descriptors stay absent until reviewed, so they are not registered as neutral',
            'amulet_coin, exp_share, linking_cord and luck_incense remain unregistered pending their own systems',
        ],
    }
    return profile


def encoded(profile):
    return json.dumps(profile, ensure_ascii=False, indent=2) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    profile = build()
    text = encoded(profile)
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding='utf-8') != text:
            raise SystemExit('field_world_items_v2.json is not the pinned compilation')
        print('WORLD_HELD_IMPORT PASS rows=' + str(len(profile['items'])))
        return 0
    OUTPUT.write_text(text, encoding='utf-8', newline='\n')
    print('WORLD_HELD_IMPORT WROTE rows=' + str(len(profile['items'])) + ' sha256=' + hashlib.sha256(text.encode('utf-8')).hexdigest())
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
