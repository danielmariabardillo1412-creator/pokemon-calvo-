"""Compile two encounter-item descriptors from immutable local references.

Their real overworld rate effect already lives in encounter_item_modifiers.gd.
This adds native identity/Fling metadata, not a new passive battle mechanic.
"""
from pathlib import Path
import argparse, hashlib, json, re
from import_recovery import indexes, field

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'modules/battle/backends/showdown/field_encounter_items_v23.json'
REFERENCES = ROOT / '.godot/field_held_v16/references'
SOURCE = ROOT / '.godot/item_mochi_v13/references/items.h'
SOURCE_SHA = '107f1b78a457f3a9c48749f325d674b62fe559b0ebfc365db13e82b00b19ecd3'
EFFECTS_SHA = '6cf395c29bbfcf425eeb965f2101edb8ba139c6cb24beef0521b92f6853a5e5f'
GEN_SHA = {
    'pokered_item_constants.asm':'b5a1db015fbf0de637381eb39350f21f35a436a8088e2f6657f65c79f118f97f',
    'pokecrystal_item_constants.asm':'bb870ffb3448845aa886ede0030a114a7773d7cb6924d2c59acdca0c53a02e58',
    'pokeemerald_items.h':'6e3a9728b4d90cc23fee0aae9b9ffa9fbd71541e6b3cb2b966f334930b6ad6f8',
    'pokeplatinum_items.txt':'9b5e48100fff0baf7a899a5355dca6bbe86b46acca5fe4854ede462296c4acb5',
}
ROWS = {'cleanse_tag':('Cleanse Tag',2,30), 'pure_incense':('Pure Incense',4,10)}


def pinned(path, expected):
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected:
        raise ValueError('source hash mismatch: '+str(path))
    return raw.decode('utf-8')


def metadata(item_id, block):
    name, gen, power = ROWS[item_id]
    if re.search(r'^\s*#', block, re.M):
        raise ValueError('conditional metadata requires review: '+item_id)
    if field(block,'name') != 'ITEM_NAME("'+name+'")':
        raise ValueError('name mismatch: '+item_id)
    if field(block,'holdEffect') != 'HOLD_EFFECT_REPEL':
        raise ValueError('overworld effect mismatch: '+item_id)
    if field(block,'flingPower') != str(power):
        raise ValueError('Fling mismatch: '+item_id)
    return {'name':name, 'gen':gen, 'fling':{'basePower':power}}


def build():
    text = pinned(SOURCE, SOURCE_SHA)
    blocks, _ = indexes(text, pinned(SOURCE.with_name('item_effects.h'), EFFECTS_SHA))
    generations = {name:pinned(REFERENCES/name,digest) for name,digest in GEN_SHA.items()}
    if (not re.search(r'\bconst\s+CLEANSE_TAG\b',generations['pokecrystal_item_constants.asm'])
            or re.search(r'\bconst\s+CLEANSE_TAG\b',generations['pokered_item_constants.asm'])):
        raise ValueError('Cleanse Tag generation mismatch')
    if ('ITEM_PURE_INCENSE' not in generations['pokeplatinum_items.txt']
            or 'PURE_INCENSE' in generations['pokeemerald_items.h']
            or 'PURE_INCENSE' in generations['pokecrystal_item_constants.asm']):
        raise ValueError('Pure Incense generation mismatch')
    catalog = json.loads((ROOT/'data/normalized/pokemon_api.json').read_text(encoding='utf-8'))['items']
    policy = json.loads((ROOT/'config/item_selection_v1.json').read_text(encoding='utf-8'))
    connections = json.loads((ROOT/'modules/inventory/item_connections_v1.json').read_text(encoding='utf-8'))
    result = {}
    for item_id in ROWS:
        if (item_id not in catalog or item_id not in connections['holdable_ids']
                or item_id in policy['excluded_ids'] or catalog[item_id]['category'] in policy['excluded_categories']):
            raise ValueError('item not permitted: '+item_id)
        result[item_id.replace('_','')] = metadata(item_id,blocks[item_id])
    return {
        'schema_version':1, 'profile':'calvo_encounter_held_v23',
        'source':'https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c',
        'source_sha256':{'items.h':SOURCE_SHA, 'item_effects.h':EFFECTS_SHA}, 'generation_source_sha256':GEN_SHA,
        'items':result,
        'effect_owner':'modules/gameplay/encounter_item_modifiers.gd',
        'scope':'Native battle identity, Fling and ownership for the existing encounter-rate items. No callbacks or new battle effects.',
        'limits':['PARTIAL_VERIFIED_RATE_ONLY: 2/3 rate in the current profile; minimum-step semantics remain absent.',
                  'No direct bag use or new save fields; native Fling/Trick/Knock Off remain authoritative.'],
    }


def encoded(value): return json.dumps(value,ensure_ascii=False,indent=2)+'\n'


def main():
    p=argparse.ArgumentParser(description=__doc__)
    group=p.add_mutually_exclusive_group(required=True)
    group.add_argument('--write',action='store_true');group.add_argument('--check',action='store_true')
    args=p.parse_args(); text=encoded(build())
    if args.write: OUTPUT.write_text(text,encoding='utf-8',newline='\n')
    elif OUTPUT.read_text(encoding='utf-8') != text: raise ValueError('encounter descriptors differ from pinned compilation')
    print('ENCOUNTER_HELD_IMPORT PASS rows=2')
    return 0


if __name__=='__main__': raise SystemExit(main())
