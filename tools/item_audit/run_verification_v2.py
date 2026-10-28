"""Verify existing capabilities and publish explicit pending work; does not implement new effects."""
import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/item_verification_v2'
DOC = ROOT / 'docs/current'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(args, name, timeout=400):
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    print('ITEM_VERIFY_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as handle:
        result = subprocess.run(args, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT, timeout=timeout, startupinfo=startup)
    text = (OUT / name).read_text(encoding='utf-8-sig', errors='replace')
    assert result.returncode == 0 and 'SCRIPT ERROR' not in text and 'ERROR:' not in text, name
    print(text.strip().splitlines()[-1] if text.strip() else 'OK', flush=True)


def summarize():
    connection = read(DOC / 'ITEM_CONNECTIONS_V1.json')
    assert all(sha(ROOT / p) == h for p, h in connection['sources_sha256'].items())
    assert all(sha(ROOT / p) == h for p, h in connection['data_policy_and_art_manifest_unchanged'].items())
    native = read(OUT / 'native.json')['results']
    projection = read(OUT / 'godot.json')
    previous_native = read(ROOT / '.godot/item_audit_v1/held_native.json')['results']
    previous_godot = read(ROOT / '.godot/item_audit_v1/held_godot.json')
    groups = read(OUT / 'existing_groups.json')
    medicine = read(ROOT / '.godot/showdown_medicine_checks/gameplay.json')
    assert len(native) == 368 and len({r['id'] for r in native}) == 103 and all(r['status'] == 'NATIVE_SCENARIO_PASS' for r in native)
    assert len(previous_native) == 42 and len({r['id'] for r in previous_native}) == 21 and all(r['status'] == 'PASS' for r in previous_native)
    assert previous_godot['status'] == groups['status'] == 'PASS' and not projection['errors']
    assert medicine['status'] == 'PASS' and not medicine['errors'] and set(medicine['items']) == set(read(ROOT / 'modules/inventory/battle_medicine_profile.json')['items'])
    previous_projection = read(ROOT / '.godot/item_audit_v1/held_projection.json')
    assert len(previous_projection) == 42 and all(r['mirror_ok'] and not r['unknown'] for r in previous_projection)
    assert len(projection['results']) == 368
    assert {r['case_id'] for r in projection['results']} == {r['case_id'] for r in native}
    by_id = defaultdict(list)
    for row in projection['results']:
        by_id[row['id']].append(row)
    verified, pending_protocol = set(), {}
    for item_id, cases in by_id.items():
        if all(r['status'].endswith('_PASS') for r in cases) and any(r.get('live_ipc') and r['status'] == 'NATIVE_AND_GODOT_SCENARIO_PASS' for r in cases):
            verified.add(item_id)
        else:
            pending_protocol[item_id] = [r for r in cases if not r['status'].endswith('_PASS')]
    prior = {r['id'] for r in previous_native}
    assert not verified.intersection(prior)
    all_verified = verified | prior
    profile = read(ROOT / 'modules/inventory/battle_medicine_profile.json')['items']
    rows = []
    source_native = {r['id']: r for r in read(ROOT / '.godot/item_audit_v1/native_inventory.json')['rows']}
    for previous in connection['rows']:
        row = dict(previous)
        item_id = row['id']
        if row['field_use_status'] == 'CONTENT_EXCLUDED':
            row['battle_effect_status'] = 'EXCLUDED'
        elif item_id in all_verified:
            row['battle_effect_status'] = 'HELD_EFFECT_SCENARIOS_VERIFIED_NOT_EXHAUSTIVE'
        elif item_id in pending_protocol:
            row['battle_effect_status'] = 'NATIVE_PASS_GODOT_PROTOCOL_PENDING'
        elif item_id in profile:
            row['battle_effect_status'] = 'MEDICINE_BATTLE_GROUP_REVERIFIED'
        elif row['battle_effect_status'] == 'BASIC_CAPTURE_PATH_PREVIOUS_PHASE':
            row['battle_effect_status'] = 'BASIC_CAPTURE_GROUP_REVERIFIED'
        elif source_native[item_id].get('exists'):
            row['battle_effect_status'] = 'SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING'
        else:
            row['battle_effect_status'] = 'NO_HELD_EFFECT_CERTIFICATION_OR_NOT_APPLICABLE'
        row['new_effect_scenarios'] = len(by_id[item_id])
        row['live_ipc_case'] = any(r.get('live_ipc') for r in by_id[item_id])
        rows.append(row)
    assert len(rows) == 2222
    pending = {
        'missing_mechanic_or_bridge': [
            {'group': 'escape_rope', 'reason': 'Dungeon exit destination and consumption/reuse rules are not connected.'},
            {'group': 'outside_battle_medicine', 'reason': 'Battle use is verified; the outside-battle bridge is still pending.'},
            {'group': 'training_items', 'reason': 'Permanent-stat/ability/nature/XP item routes still require their owned-state bridge.'},
            {'group': 'legacy_machines', 'count': 109, 'reason': 'Mappings exist, but a compatible gameplay version/profile has not been activated.'},
            {'group': 'conditioned_evolution', 'count': 15, 'reason': 'Gender, region, forms and other preserved conditions must not be discarded.'},
            {'group': 'special_capture_balls', 'reason': 'The base four-ball capture rules do not certify the remaining conditional balls.'},
            {'group': 'story_crafting_raid_food_trade', 'reason': 'Depends on which world systems/content the game retains.'},
        ],
        'fixtures_pending_not_necessarily_missing_mechanics': [r['id'] for r in rows if r['battle_effect_status'] == 'SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING'],
        'godot_protocol_pending': pending_protocol,
    }
    sources = ['tools/item_audit/held_effect_sweep_v2.cjs', 'tests/gameplay/item_effect_templates_v2.gd', 'tests/gameplay/item_effect_projection_v2.gd', 'tests/gameplay/item_existing_groups_v2.gd', 'tools/item_audit/run_verification_v2.py', 'modules/battle/backends/showdown/native_engine.cjs', 'modules/battle/backends/showdown/event_adapter.gd', '.godot/battle_reference/runtime/node_modules/@pkmn/sim/package.json']
    report = {'status': 'VERIFIABLE_GROUPS_PASS_REMAINDER_EXPLICITLY_PENDING', 'date': '2026-10-28', 'phase': 'ITEM_VERIFICATION_V2', 'canonical_items_classified': 2222, 'additional_held_item_ids_with_verified_scenarios': len(verified), 'total_held_item_ids_with_verified_scenarios': len(all_verified), 'new_native_scenarios': len(native), 'previous_native_scenarios_reverified': len(previous_native), 'new_godot_projected_scenarios': len(projection['results']), 'new_live_ipc_items': sum(any(c.get('live_ipc') for c in cases) for cases in by_id.values()), 'new_godot_checks': projection['checks'], 'protocol_pending_items': sorted(pending_protocol), 'equipment_transfer_ids_verified': connection['equipment_transfer_ids_verified'], 'evolution_route_results': connection['evolution_route_results'], 'machine_teaching_ids_verified': connection['machine_teaching_ids_verified'], 'connection_checks': connection['headless_checks'], 'connection_gpu_checks': connection['gpu_checks'], 'medicine_group_items_reverified': len(profile), 'inventory_and_capture_checks': groups['checks'], 'battle_effect_status_counts': dict(Counter(r['battle_effect_status'] for r in rows)), 'pending': pending, 'protected_data_policy_art': connection['data_policy_and_art_manifest_unchanged'], 'sources_sha256': {p: sha(ROOT / p) for p in sources}, 'scope': 'Bounded scenario verification, not exhaustive item-interaction certification. Native differential tests do not independently reimplement every canonical damage formula.', 'rows': rows}
    (DOC / 'ITEM_VERIFICATION_V2.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (DOC / 'ITEM_VERIFICATION_PENDING_V2.json').write_text(json.dumps(pending, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (DOC / 'ITEM_VERIFICATION_V2.csv').open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
    report['medicine_checks'] = medicine['checks']
    report['existing_held_godot_checks'] = previous_godot['checks']
    evidence = ['native.json', 'godot.json', 'cases.json', 'prototypes.json', 'existing_groups.json', 'connections.log', 'previous_native.log', 'previous_godot.log', 'medicine.log', 'existing_groups.log']
    report['evidence_sha256'] = {name: sha(OUT / name) for name in evidence}
    (DOC / 'ITEM_VERIFICATION_V2.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    status = read(DOC / 'ITEM_SYSTEM_CURRENT_STATUS.json')
    status.update(latest_report='docs/current/ITEM_VERIFICATION_V2.json', notes='docs/current/ITEM_VERIFICATION_V2.md', full_item_matrix='docs/current/ITEM_VERIFICATION_V2.csv', latest_verification='ITEM_VERIFICATION_V2', held_item_ids_with_verified_effect_scenarios=len(all_verified), untested_native_contexts=len(pending['fixtures_pending_not_necessarily_missing_mechanics']), verification_all_effects_complete=False)
    (DOC / 'ITEM_SYSTEM_CURRENT_STATUS.json').write_text(json.dumps(status, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k not in {'rows', 'sources_sha256', 'protected_data_policy_art', 'pending', 'scope', 'evidence_sha256'}}, ensure_ascii=True))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--summarize', action='store_true', help='Publish already verified local evidence; no tests are skipped in the default run.')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if not args.summarize:
        godot = os.environ.get('GODOT_BIN') or shutil.which('godot') or r'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
        node = shutil.which('node') or r'D:\Herramientas\NodeJS\node.exe'
        command([sys.executable, 'tools/item_audit/run_connections.py', '--gpu', '--regressions'], 'connections.log')
        command([node, 'tools/item_audit/held_pilot.cjs'], 'previous_native.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_held_pilot_test_runner.gd'], 'previous_godot.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_effect_templates_v2.gd'], 'export.log')
        command([node, 'tools/item_audit/held_effect_sweep_v2.cjs'], 'native.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_effect_projection_v2.gd'], 'godot.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/showdown_medicine_test_runner.gd'], 'medicine.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_existing_groups_v2.gd'], 'existing_groups.log')
    summarize()


if __name__ == '__main__':
    main()
