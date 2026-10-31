"""Verify evidence and declared limits before publishing the item foundation report."""
from pathlib import Path
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/item_audit_v1'
sys.path.insert(0, str(ROOT / 'tools/showdown_engine_probe'))
from audit_moves import protected


def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    data = read(ROOT / 'data/normalized/pokemon_api.json')
    inventory = read(ROOT / 'docs/current/ITEM_INVENTORY.json')
    native = read(OUT / 'native_inventory.json')
    pilot = read(OUT / 'held_native.json')['results']
    cases = read(OUT / 'held_cases.json')
    projected = read(OUT / 'held_projection.json')
    live, policy = read(OUT / 'held_godot.json'), read(OUT / 'selection_policy.json')
    assert len(inventory['rows']) == len(data['items']) == 2222
    assert {r['id'] for r in inventory['rows']} == set(data['items'])
    assert sum(inventory['family_counts'].values()) == 2222
    assert len(native['rows']) == 2222 and sum(r['exists'] for r in native['rows']) == inventory['native_entries'] == 565
    assert len(pilot) == len(cases) == len(projected) == 42
    assert len({r['id'] for r in pilot}) == 21 and all(r['status'] == 'PASS' for r in pilot)
    assert all(r['mirror_ok'] and not r['unknown'] for r in projected)
    assert {r['case_id'] for r in projected} == {r['case_id'] for r in pilot}
    assert all(r['status'] == 'PASS' and not r['errors'] for r in [live, policy])
    excluded = {r['id'] for r in inventory['rows'] if r['content'] == 'EXCLUDED'}
    assert len(excluded) == 43 and excluded == set(policy['excluded_ids'])
    assert {'revive', 'max_revive', 'revival_herb', 'sacred_ash', 'max_honey', 'wide_lens', 'bright_powder'} <= excluded
    assert 'lax_incense' not in excluded and 'poke_doll' not in excluded
    assert all(r['source_category'] == 'all_mail' for r in inventory['rows'] if r['id'] in excluded - set(['revive', 'max_revive', 'revival_herb', 'sacred_ash', 'max_honey', 'wide_lens', 'bright_powder']))
    primary = read(OUT / 'sources/max_honey.json')
    assert primary['id'] == 1630 and primary['name'] == 'max-honey'
    assert any('Max Revive' in r['text'] for r in primary['flavor_text_entries'] if r['language']['name'] == 'en')
    art = read(ROOT / 'docs/current/ITEM_ART_PILOT.json')
    assert len(art['ids']) == 24 and not art['images_downloaded'] and not art['style_selected']
    assert not set(art['ids']) & excluded
    for row in inventory['rows']:
        assert row['connection'] != 'HELD_PILOT_VERIFIED' or row['id'] in {r['id'] for r in pilot}
    counts = {}
    patterns = {'regression_unified.log': r'UNIFIED_GODOT PASS checks=(\d+)',
                'regression_field.log': r'FIELD_NATIVE PASS checks=(\d+)',
                'regression_repair.log': r'SHOWDOWN_MOVE_REPAIR PASS checks=(\d+)',
                'regression_adventure.log': r'SHOWDOWN_ADVENTURE PASS checks=(\d+)',
                'regression_medicine.log': r'SHOWDOWN_MEDICINES PASS checks=(\d+)',
                'regression_save.log': r'SAVEGAME V2 TEST RESULT: (\d+) PASS / 0 FAIL',
                'regression_save_adversarial.log': r'SAVEGAME V2 ADVERSARIAL RESULT: (\d+) PASS / 0 FAIL',
                'regression_core.log': r'PROJECT TEST RESULT: (\d+) PASS / 0 FAIL'}
    for name, pattern in patterns.items():
        text = (OUT / name).read_text(encoding='utf-8-sig'); match = re.search(pattern, text)
        assert match, name
        counts[name] = int(match[1])
    for name in ['export.log', 'held_native.log', 'held_godot.log', 'selection_policy.log', *patterns]:
        text = (OUT / name).read_text(encoding='utf-8-sig'); assert 'SCRIPT ERROR' not in text, name
        errors = [s for s in text.splitlines() if s.startswith('ERROR:') and not
                  (name == 'regression_core.log' and s.startswith('ERROR: Parse JSON failed. Error at line 0: Expected key'))]
        assert not errors, (name, errors)
    before, after = read(OUT / 'before.json'), protected()
    changed = sorted(p for p, value in before.items() if after.get(p) != value)
    assert changed == ['modules/battle/backends/showdown/event_adapter.gd'], changed
    assert all(after.get(p) == value for p, value in before.items()
               if p.startswith(('data/', 'assets/')) or p in ['project.godot', 'config/randomlock_content_v1.json', '.godot/move_batch_catalog/index.json'])
    new_files = sorted(set(after) - set(before))
    assert new_files == ['config/item_selection_v1.json', 'modules/inventory/item_selection_policy.gd'], new_files
    sources = ['config/item_selection_v1.json', 'modules/inventory/item_selection_policy.gd', *changed,
               'tests/gameplay/item_inventory_export.gd', 'tests/gameplay/item_held_pilot_test_runner.gd',
               'tests/gameplay/item_selection_policy_test_runner.gd']
    sources += ['tools/item_audit/' + p for p in ['native_inventory.cjs', 'held_pilot.cjs', 'build_inventory.py', 'run.py', 'verify.py']]
    evidence_files = ['before.json', 'native_inventory.json', 'godot_inventory.json', 'held_native.json', 'held_cases.json',
                      'held_projection.json', 'held_godot.json', 'selection_policy.json', 'sources/max_honey.json',
                      'export.log', 'held_native.log', 'held_godot.log', 'selection_policy.log', *patterns]
    report = {'status': 'PASS', 'date': '2026-10-28', 'phase': 'ITEM_FOUNDATION_V1',
              'canonical_items_inventoried': 2222, 'native_entries': 565, 'native_entries_with_callbacks': inventory['native_entries_with_callbacks'],
              'held_pilot_types': 21, 'held_native_cases': 42, 'Godot_checks': live['checks'], 'content_policy_checks': policy['checks'],
              'confirmed_selection_exclusions': 43, 'medicine_connections_existing': 15, 'basic_capture_rules_existing': 4,
              'art_sample_ids_prepared': 24, 'art_style_selected': False, 'new_item_images_downloaded': 0,
              'prototype_state_and_capture': 'Consumed held berry survives JSON save/restore with complete canonical JSON state; real ownership publishes once after capture, without early writes or duplicate consumption.',
              'runtime_fix': 'Recognize native -clearnegativeboost emitted by White Herb; use native post-state, no new stat/effect formula.',
              'content_choice': 'Wide Lens and Bright Powder excluded by the named request; no additional Lax Incense ban. Max Honey included in the existing all-revival exclusion. Mail excluded.',
              'policy_integration': 'Pure selection guard requires content permission plus an explicit supported-ID set. Not wired to a new loot/shop pool; never removes existing inventory or save data.',
              'existing_runtime_files_changed': changed, 'data_move_policy_and_graphic_manifests_unchanged': True,
              'regressions': counts, 'sources_sha256': {p: sha(ROOT / p) for p in sources},
              'evidence_sha256': {p: sha(OUT / p) for p in evidence_files},
              'primary_metadata_source': 'https://github.com/PokeAPI/api-data/blob/master/data/api/v2/item/1630/index.json',
              'remaining': ['Equip/unequip ownership and bag UI', 'Full held-item context coverage beyond the 21-item pilot',
                            'Out-of-battle item use and consumption bridges', 'Explicit machine/version mapping',
                            'Special capture-ball conditions and field/story items', 'Art coverage/style comparison using 24 representatives'],
              'limitations': ['Native entry or callback presence is not a functionality certificate.', 'No new family is enabled just because its category/name exists.',
                              'Evolution support counts eligibility records, not completed bag-use routes.', 'No claim of all 2222 items playable.']}
    (ROOT / 'docs/current/ITEM_FOUNDATION_V1.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('ITEM_FOUNDATION_VERIFIED PASS inventory=2222 native=565 held=21 cases=42 exclusions=43')


if __name__ == '__main__': main()
