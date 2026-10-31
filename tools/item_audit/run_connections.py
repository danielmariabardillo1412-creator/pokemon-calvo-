"""Reproduce the item-connection sweep and publish an honest per-item capability report."""
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
OUT = ROOT / '.godot/item_connections_v1'
DOC = ROOT / 'docs/current'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(args, logfile, timeout=240):
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    with (OUT / logfile).open('w', encoding='utf-8') as handle:
        result = subprocess.run(args, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT, timeout=timeout, startupinfo=startup)
    log = (OUT / logfile).read_text(encoding='utf-8-sig', errors='replace')
    assert result.returncode == 0 and 'SCRIPT ERROR' not in log and 'ERROR:' not in log, logfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--gpu', action='store_true')
    parser.add_argument('--regressions', action='store_true')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    (ROOT / '.godot/item_audit_v1').mkdir(parents=True, exist_ok=True)
    godot = os.environ.get('GODOT_BIN') or shutil.which('godot') or r'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
    node = shutil.which('node') or r'D:\Herramientas\NodeJS\node.exe'
    assert Path(godot).exists() and Path(node).exists(), 'Godot/Node runtime not found; set GODOT_BIN or install existing project dependencies.'
    command([node, 'tools/item_audit/native_inventory.cjs'], 'native_metadata.log')
    command([sys.executable, 'tools/item_audit/prepare_connections_v1.py'], 'prepare.log')
    command([godot, '--headless', '--path', '.', '--editor', '--import', '--quit'], 'import.log')
    command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_inventory_export.gd'], 'eligibility_export.log')
    command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_connections_test_runner.gd'], 'godot.log')
    headless = read(OUT / 'godot.json')
    assert headless['status'] == 'PASS' and not headless['errors']
    gpu = None
    if args.gpu:
        command([godot, '--path', '.', '--script', 'tests/gameplay/item_connections_test_runner.gd', '--resolution', '1280x720', '--', '--capture'], 'gpu.log')
        gpu = read(OUT / 'gpu.json')
        assert gpu['status'] == 'PASS' and not gpu['errors']
    regressions = {}
    if args.regressions:
        for name in ['field_native', 'savegame_v2', 'savegame_v2_adversarial', 'item_selection_policy']:
            command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/' + name + '_test_runner.gd'], 'regression_' + name + '.log')
            regressions[name] = (OUT / ('regression_' + name + '.log')).read_text(encoding='utf-8-sig', errors='replace').strip().splitlines()[-1]
    protected = read(OUT / 'before.json')
    assert all(sha(ROOT / path) == digest for path, digest in protected.items())
    data = read(ROOT / 'data/normalized/pokemon_api.json')
    profile = read(ROOT / 'modules/inventory/item_connections_v1.json')
    inventory = {row['id']: row for row in read(DOC / 'ITEM_INVENTORY.json')['rows']}
    equip = {r['id'] for r in headless['equip_cases']}
    taught = {r['id'] for r in headless['machine_cases'] if r['status'] == 'TEACH_AND_CONSUMPTION_VERIFIED'}
    assert len(equip) == 625 and len(taught) == 229
    evolution = defaultdict(list)
    for row in headless['evolution_cases']:
        if 'item_id' in row:
            evolution[row['item_id']].append(row)
    native_pilot = {r['id'] for r in inventory.values() if r['connection'] == 'HELD_PILOT_VERIFIED'}
    prior = read(DOC / 'ITEM_FOUNDATION_V1.json')
    rows = []
    for item_id, item in sorted(data['items'].items()):
        baseline = inventory[item_id]
        excluded = baseline['content'] == 'EXCLUDED'
        applied = [r for r in evolution[item_id] if r['status'] == 'BAG_EVOLUTION_VERIFIED']
        if excluded:
            field_status = 'CONTENT_EXCLUDED'
        elif item_id in taught:
            field_status = 'TEACH_AND_CONSUMPTION_VERIFIED'
        elif applied:
            field_status = 'BAG_EVOLUTION_VERIFIED_WITH_SUPPORTED_TARGETS'
        elif item_id in profile['machine_rows']:
            field_status = 'NEEDS_MACHINE_VERSION_PROFILE'
        elif item_id == 'escape_rope':
            field_status = 'NEEDS_DUNGEON_EXIT_AND_ROPE_RULES'
        elif baseline['family'] == 'MACHINE' or evolution[item_id]:
            field_status = 'DEPENDENCY_OR_EVOLUTION_CONTEXT_MISSING'
        elif baseline['family'] in {'HELD_COMBAT_CANDIDATE', 'MEGA_STONE', 'Z_CRYSTAL'}:
            field_status = 'HELD_OR_BATTLE_ACTION_ITEM_NOT_DIRECT_FIELD_USE'
        elif baseline['family'] == 'CAPTURE_BALL':
            field_status = 'BATTLE_CAPTURE_ITEM_NOT_DIRECT_FIELD_USE'
        elif baseline['family'] == 'Z_BAG_TOKEN':
            field_status = 'BAG_TO_HELD_ROUTE_NEEDS_CONTEXT'
        elif baseline['family'] == 'MACHINE_CRAFTING_MATERIAL':
            field_status = 'CRAFTING_SYSTEM_CONTEXT_NEEDED'
        elif baseline['family'] == 'RAID_EVENT_CRYSTAL':
            field_status = 'RAID_SYSTEM_NOT_ACTIVE'
        elif baseline['family'] == 'TERA_MATERIAL':
            field_status = 'TERA_TYPE_CHANGE_SYSTEM_NEEDED'
        elif baseline['family'] in {'STORY_KEY_OR_FORM_REVIEW', 'LEGACY_OR_CATEGORY_REVIEW', 'SIDE_MODE_ITEM'}:
            field_status = 'STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED'
        elif baseline['family'] == 'TREASURE_OR_COLLECTIBLE':
            field_status = 'SELL_TRADE_OR_TRAINING_CONTEXT_NEEDED'
        elif baseline['family'] in {'FOOD_OR_PICNIC_ACTIVITY', 'GROWING_OR_CRAFTING'}:
            field_status = 'FOOD_GROWING_OR_CRAFTING_CONTEXT_NEEDED'
        elif baseline['family'] == 'EVOLUTION':
            field_status = 'TRADE_OR_OTHER_EVOLUTION_CONTEXT_NEEDED'
        else:
            field_status = 'FIELD_USE_NOT_CONNECTED'
        battle_status = 'NATIVE_HELD_PILOT_VERIFIED_PREVIOUS_PHASE' if item_id in native_pilot else 'MEDICINE_BATTLE_PATH_PREVIOUS_PHASE' if baseline['connection'] == 'EXISTING_BATTLE_MEDICINE_PATH' else 'BASIC_CAPTURE_PATH_PREVIOUS_PHASE' if baseline['connection'] == 'EXISTING_BASIC_CAPTURE_RULE' else 'EFFECT_NEEDS_CONTEXT_TEST'
        rows.append({'id': item_id, 'name_es': item['display_name'], 'family': baseline['family'], 'field_use_status': field_status, 'equipment_transfer': 'VERIFIED' if item_id in equip else 'NOT_CERTIFIED', 'battle_effect_status': battle_status, 'supported_evolution_routes_tested': len(applied), 'other_evolution_routes': len(evolution[item_id]) - len(applied), 'machine_active_version': profile['active_machine_version'] if item_id in profile['machine_rows'] else '', 'native_definition_present': baseline['native_entry']})
    assert len(rows) == 2222
    files = ['modules/inventory/field_item_service.gd', 'modules/inventory/item_connections_v1.json', 'scenes/visual/field_item_bag.gd', 'scenes/visual/field_demo.gd', 'scenes/visual/field_native_bridge.gd', 'tests/gameplay/item_connections_test_runner.gd', 'tests/fixtures/item_connections_v1/primary/sources.json', 'tools/item_audit/prepare_connections_v1.py', 'tools/item_audit/run_connections.py', 'docs/current/ITEM_FOUNDATION_V1.json', 'docs/current/ITEM_INVENTORY.json']
    report = {'status': 'CONNECTION_SLICE_PASS_NOT_ALL_ITEM_EFFECTS_CERTIFIED', 'date': '2026-10-28', 'phase': 'ITEM_CONNECTIONS_V1', 'canonical_entries_audited': len(rows), 'headless_checks': headless['checks'], 'gpu_checks': gpu['checks'] if gpu else None, 'equipment_transfer_ids_verified': len(equip), 'machine_teaching_ids_verified': len(taught), 'machine_ids_mapped_by_version': 338, 'active_machine_version': profile['active_machine_version'], 'machine_profiles_pending': 109, 'evolution_route_results': dict(Counter(r['status'] for r in headless['evolution_cases'])), 'field_status_counts': dict(Counter(r['field_use_status'] for r in rows)), 'prior_held_effect_pilot_count': len(native_pilot), 'prior_medicine_connections': prior['medicine_connections_existing'], 'prior_capture_connections': prior['basic_capture_rules_existing'], 'regressions': regressions, 'data_policy_and_art_manifest_unchanged': protected, 'sources_sha256': {p: sha(ROOT / p) for p in files}, 'limitations': ['Equipment transfer validation does not certify 625 held-item effects.', '229 machines tested with one compatible species each plus rejection/consumption boundaries, not every species-machine pair.', '15 conditioned/form evolution routes remain deferred; no conditions are discarded.', 'Escape Rope needs an explicit dungeon exit and consumption/reuse rule; portal traversal alone is not an item-use bridge.', 'Field medicines, training, special balls and world/story systems still have outstanding connections.', 'Prior native effect/medicine/capture results retain their original scope and date; they are not silently rerun or relabeled as new full coverage.'], 'rows': rows}
    (DOC / 'ITEM_CONNECTIONS_V1.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (DOC / 'ITEM_CONNECTIONS_V1.csv').open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
    print(json.dumps({k: v for k, v in report.items() if k not in ['rows', 'sources_sha256', 'limitations', 'data_policy_and_art_manifest_unchanged']}, ensure_ascii=True))


if __name__ == '__main__':
    main()
