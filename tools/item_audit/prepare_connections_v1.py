"""Build an additive item adapter from pinned primary CSVs; never rewrite canonical data."""
from collections import defaultdict
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tests/fixtures/item_connections_v1/primary'
OUT = ROOT / '.godot/item_connections_v1'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def table(name):
    path = SOURCE / (name + '.txt')
    assert hashlib.sha256(path.read_bytes()).hexdigest() == read(SOURCE / 'sources.json')['files'][name]['sha256']
    return list(csv.DictReader(path.open(encoding='utf-8-sig')))


def canonical(value):
    return value.replace('-', '_').replace('__', '_')


def main():
    OUT.mkdir(exist_ok=True)
    protected = ['data/raw/pokemon_api.json', 'data/normalized/pokemon_api.json', 'config/item_selection_v1.json', 'config/randomlock_content_v1.json', 'assets/local_item_catalog/manifest.json']
    hashes = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in protected}
    if not (OUT / 'before.json').exists():
        (OUT / 'before.json').write_text(json.dumps(hashes, indent=2) + '\n', encoding='utf-8')
    assert hashes == read(OUT / 'before.json')
    data = read(ROOT / 'data/normalized/pokemon_api.json')
    source_items = {r['id']: canonical(r['identifier']) for r in table('items.csv')}
    moves = {r['id']: canonical(r['identifier']) for r in table('moves.csv')}
    versions = {r['id']: r for r in table('version_groups.csv') if int(r['id']) <= 27}
    machines = defaultdict(dict)
    for row in table('machines.csv'):
        item_id = source_items[row['item_id']]
        if item_id not in data['items'] or row['version_group_id'] not in versions:
            continue
        move_id = moves[row['move_id']]
        if move_id not in data['moves']:
            continue
        version = versions[row['version_group_id']]['identifier']
        assert version not in machines[item_id]
        machines[item_id][version] = move_id
    expected = {k for k, r in data['items'].items() if r['category'] == 'all_machines'}
    assert set(machines) == expected and len(machines) == 338
    primary_holdable = {source_items[r['item_id']] for r in table('item_flag_map.csv') if r['item_flag_id'] in {'5', '6', '7'}}
    native = read(ROOT / '.godot/item_audit_v1/native_inventory.json')
    assert native['version'] == '0.10.11'
    native_holdable = {r['id'] for r in native['rows'] if r.get('exists') and (r.get('hooks') or any(r.get('fields', {}).get(k) for k in ['fling', 'isBerry', 'isGem', 'isPokeball', 'megaStone', 'zMove', 'zMoveType']))}
    holdable = sorted((primary_holdable | native_holdable) & set(data['items']))
    profile = {'schema_version': 1, 'profile_id': 'calvo_item_connections_v1', 'active_machine_version': 'scarlet-violet', 'machine_rows': dict(sorted(machines.items())), 'holdable_ids': holdable, 'holdable_source': {'primary_flag_ids': sorted(primary_holdable & set(data['items'])), 'native_held_metadata_ids': sorted(native_holdable)}, 'machine_scope': 'Mapping preserves version. Active field use currently follows Scarlet/Violet; other mappings require an explicitly selected profile and matching species learnset provenance.', 'source': read(SOURCE / 'sources.json')}
    (ROOT / 'modules/inventory/item_connections_v1.json').write_text(json.dumps(profile, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    # Keep independent, source-numbered rows for the verifier rather than using runtime lookup output as its oracle.
    (OUT / 'source_machine_rows.json').write_text(json.dumps({'rows': table('machines.csv'), 'items': table('items.csv'), 'moves': table('moves.csv'), 'versions': table('version_groups.csv')}, indent=2) + '\n', encoding='utf-8')
    available = defaultdict(list)
    for species_id, species in data['species'].items():
        for entry in species['learnset']:
            if entry['method'] == 'machine' and entry.get('version_group') == 'scarlet-violet':
                available[entry['move_id']].append(species_id)
    fixtures = []
    for item_id, rows in sorted(machines.items()):
        if 'scarlet-violet' in rows:
            fixtures.append({'item_id': item_id, 'expected_move': rows['scarlet-violet'], 'compatible_species': sorted(set(available[rows['scarlet-violet']]))})
    (OUT / 'machine_fixtures.json').write_text(json.dumps(fixtures, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'mapped_machine_ids': len(machines), 'holdable_metadata_ids': len(holdable), 'active_version': 'scarlet-violet', 'active_machine_ids': sum('scarlet-violet' in r for r in machines.values())}))


if __name__ == '__main__':
    main()
