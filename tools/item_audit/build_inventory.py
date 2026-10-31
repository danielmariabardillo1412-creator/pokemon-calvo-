"""Read-only census; content choice, native metadata and exercised behavior stay separate."""
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/item_audit_v1'


def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def family(id, row, native, evo):
    c, f = row['category'], native.get('fields', {})
    if id.endswith('_z_bag'): return 'Z_BAG_TOKEN'
    if c == 'z_crystals' or f.get('zMove'): return 'Z_CRYSTAL'
    if c == 'mega_stones': return 'MEGA_STONE'
    if c == 'all_machines': return 'MACHINE'
    if c in ['standard_balls', 'special_balls', 'apricorn_balls']: return 'CAPTURE_BALL'
    if f.get('isBerry'): return 'BERRY'
    if c in ['healing', 'status_cures', 'pp_recovery', 'revival', 'medicine']: return 'MEDICINE'
    if c == 'picky_healing': return 'BERRY_OR_FOOD_REVIEW'
    if id in evo or c == 'evolution': return 'EVOLUTION'
    if c in ['vitamins', 'effort_drop', 'effort_training', 'nature_mints', 'training']: return 'TRAINING'
    if c == 'stat_boosts': return 'BATTLE_STAT_USE'
    if c == 'species_candies': return 'SPECIES_SPECIFIC_TRAINING'
    if c == 'scarves': return 'SIDE_ACTIVITY_ACCESSORY'
    if c == 'dynamax_crystals': return 'RAID_EVENT_CRYSTAL'
    if c == 'tera_shard': return 'TERA_MATERIAL'
    if c == 'all_mail': return 'MAIL'
    if c == 'data_cards': return 'SIDE_ACTIVITY_RECORD'
    if c == 'tm_materials': return 'MACHINE_CRAFTING_MATERIAL'
    if c in ['curry_ingredients', 'sandwich_ingredients', 'picnic', 'baking_only']: return 'FOOD_OR_PICNIC_ACTIVITY'
    if c in ['loot', 'collectibles']: return 'TREASURE_OR_COLLECTIBLE'
    if c in ['apricorn_box', 'mulch']: return 'GROWING_OR_CRAFTING'
    if c in ['spelunking', 'flutes', 'catching_bonus']: return 'FIELD_USE'
    if c in ['plot_advancement', 'event_items', 'gameplay', 'dex_completion']: return 'STORY_KEY_OR_FORM_REVIEW'
    if c == 'miracle_shooter': return 'SIDE_MODE_ITEM'
    if c == 'unused': return 'LEGACY_OR_CATEGORY_REVIEW'
    if c in ['held_items', 'bad_held_items', 'choice', 'species_specific', 'type_enhancement', 'type_protection', 'in_a_pinch', 'jewels', 'plates', 'memories']: return 'HELD_COMBAT_CANDIDATE'
    return 'OTHER_REVIEW'


def main():
    data = read(ROOT / 'data/normalized/pokemon_api.json')
    policy = read(ROOT / 'config/item_selection_v1.json')
    godot = read(OUT / 'godot_inventory.json')
    natives = read(OUT / 'native_inventory.json')
    native = {r['id']: r for r in natives['rows']}
    evidence = read(OUT / 'held_native.json')['results']
    projection = read(OUT / 'held_projection.json')
    passed = {r['id'] for r in evidence if r['status'] == 'PASS'}
    projected = {r['id'] for r in projection if r['mirror_ok'] and not r['unknown']}
    verified = passed & projected
    medicine, balls = set(godot['medicine']), set(godot['capture_balls'])
    evo = defaultdict(list)
    for r in godot['evolution_references']: evo[r['item_id']].append(r)
    rows = []
    for id, row in sorted(data['items'].items()):
        n = native[id]
        reason = policy['excluded_ids'].get(id, policy['excluded_categories'].get(row['category'], ''))
        if id in verified: status = 'HELD_PILOT_VERIFIED'
        elif id in medicine: status = 'EXISTING_BATTLE_MEDICINE_PATH'
        elif id in balls: status = 'EXISTING_BASIC_CAPTURE_RULE'
        elif n.get('fields', {}).get('zMove'): status = 'EXISTING_Z_PATH_WITH_USER_REQUIREMENTS'
        elif id in evo: status = 'EVOLUTION_ELIGIBILITY_RULES_NO_BAG_BRIDGE'
        elif n['exists']: status = 'NATIVE_ENTRY_REQUIRES_EFFECT_CASE'
        else: status = 'DATA_ONLY'
        flags = []
        if not row['description']: flags.append('missing_description')
        if 'XXX ' in row['description']: flags.append('placeholder_description')
        if row['category'] == 'all_machines': flags.append('needs_explicit_machine_version_relation')
        if row['category'] in ['mega_stones', 'tera_shard']: flags.append('special_mechanic_not_integrated')
        if id.endswith('_z_bag'): flags.append('not_equivalent_to_held_crystal')
        if n.get('fields', {}).get('forcedForme'): flags.append('requires_form_route')
        if id == 'poke_doll': flags.append('functional_escape_not_pure_decoration')
        if id == 'max_honey': flags.append('revival_confirmed_by_primary_flavor_text')
        if id == 'wide_lens': flags.append('named_ban_despite_accuracy_not_evasion')
        rows.append({'id': id, 'name_es': row['display_name'], 'source_category': row['category'],
                     'family': family(id, row, n, evo), 'content': 'EXCLUDED' if reason else 'CANDIDATE', 'exclusion_reason': reason,
                     'connection': status, 'native_entry': n['exists'], 'native_id': n.get('native_id', ''),
                     'native_hooks': '|'.join(n.get('hooks', [])), 'evolution_links': len(evo[id]), 'flags': '|'.join(flags)})
    counts = Counter(r['family'] for r in rows)
    sources = ['data/normalized/pokemon_api.json', 'config/item_selection_v1.json',
               'modules/inventory/battle_medicine_profile.json', 'modules/capture/capture_ruleset.gd']
    report = {'status': 'INVENTORIED', 'date': '2026-10-28', 'canonical_count': len(rows),
              'native_runtime': natives['version'], 'native_entries': sum(r['native_entry'] for r in rows),
              'native_entries_with_callbacks': sum(n['exists'] and bool(n.get('hooks')) for n in native.values()),
              'existing_battle_medicines': len(medicine), 'existing_basic_capture_balls': len(balls),
              'native_held_pilot_items': len(passed), 'Godot_projected_held_pilot_items': len(verified),
              'confirmed_content_exclusions': sum(r['content'] == 'EXCLUDED' for r in rows),
              'category_counts': dict(sorted(Counter(r['source_category'] for r in rows).items())),
              'family_counts': dict(sorted(counts.items())), 'connection_counts': dict(sorted(Counter(r['connection'] for r in rows).items())),
              'missing_descriptions': sum('missing_description' in r['flags'] for r in rows),
              'placeholder_descriptions': sum('placeholder_description' in r['flags'] for r in rows),
              'machine_entries': sum(r['family'] == 'MACHINE' for r in rows),
              'machine_learnset_versions': dict(Counter(e['version_group'] for sp in data['species'].values() for e in sp['learnset'] if e['method'] == 'machine')),
              'machine_mapping': 'No structured item-to-move/version relation in ItemDefinition; do not infer from multi-generation descriptions.',
              'evolution_items_referenced': len(evo), 'evolution_links_by_rule_support': dict(Counter(r['classification'] for r in godot['evolution_references'])),
              'scope': 'Catalog census and selected runtime experiments. A native entry/category is never a full use/equip/shop/loot/field certification.',
              'selection_scope': 'Pure content policy plus explicit supported-ID generation guard. No new shop/loot pools or automatic inventory cleanup enabled.',
              'sources_sha256': {p: sha(ROOT / p) for p in sources}, 'rows': rows}
    (ROOT / 'docs/current/ITEM_INVENTORY.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (ROOT / 'docs/current/ITEM_INVENTORY.csv').open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    pilot = ['potion', 'super_potion', 'full_restore', 'ether', 'poke_ball', 'great_ball', 'ultra_ball', 'master_ball',
             'dusk_ball', 'sitrus_berry', 'lum_berry', 'figy_berry', 'leftovers', 'life_orb', 'focus_sash', 'choice_band',
             'assault_vest', 'heavy_duty_boots', 'fire_stone', 'rare_candy', 'adamant_mint', 'tm01', 'escape_rope', 'repel']
    assert len(pilot) == 24 and all(id in data['items'] and id not in policy['excluded_ids'] for id in pilot)
    (ROOT / 'docs/current/ITEM_ART_PILOT.json').write_text(json.dumps({'status': 'SAMPLE_LIST_ONLY', 'ids': pilot,
        'purpose': 'Compare style and coverage using these representative icons at actual bag size before bulk import.',
        'images_downloaded': False, 'style_selected': False}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('ITEM_INVENTORY', len(rows), 'entries;', report['native_entries'], 'native;', report['confirmed_content_exclusions'], 'excluded;', len(verified), 'held pilot types')


if __name__ == '__main__': main()
