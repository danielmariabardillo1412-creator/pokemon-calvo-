"""Require actual positive native/Godot coverage; never equate a valid failure to success."""
import csv
import hashlib
import json
from pathlib import Path
import re
from audit_moves import protected

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/unified_profile_checks'
SINGLE, DOUBLE = 'gen9calvounifiedv1', 'gen9calvounifieddoublesv1'


def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def lines(p): return [json.loads(line) for line in p.read_text(encoding='utf-8').splitlines()]


def main():
    policy = read(ROOT / 'config/randomlock_content_v1.json')
    data = read(ROOT / 'data/normalized/pokemon_api.json')
    excluded = {i for group in policy['move_exclusions'] for i in group['ids']} & data['moves'].keys()
    excluded.add('extreme_evoboost')
    assert len(data['moves']) == 919 and len(excluded) == 19
    allowed = set(data['moves']) - excluded
    native = read(OUT / 'general/native.json')
    assert len(native['inventory']) == 919 and all(r['status'] == 'NATIVE_EXECUTED' for r in native['results'])
    assert all(r['status'] == 'PASS' for r in native['oracle']) and len(native['oracle']) == 15
    general = lines(OUT / 'general/godot.jsonl')
    contexts = lines(OUT / 'contexts/godot.jsonl')
    assert len(general) == len(native['results'])
    assert len(contexts) == 72 and not any(r['status'] == 'CONTEXT_FAILURE' for r in read(OUT / 'contexts/native.json')['results'])
    assert all(not r['issues'] and r['accepted_steps'] == r['steps'] for r in general + contexts)
    positive = {r['id'] for r in general + contexts if r['successful_actor_actions'] > 0}
    z = read(OUT / 'z/native.json')['results']
    doubles = read(OUT / 'doubles/native.json')['results']
    assert len(z) == 200 and all(r['status'] == 'NATIVE_Z_VERIFIED' and r['format'] == SINGLE for r in z)
    assert len(doubles) == 44 and all(r['status'] == 'PASS' for r in doubles)
    special = read(OUT / 'special_projection.json')
    assert len(special) == 244 and all(r['ok'] and not r['unknown'] for r in special)
    assert {r['case_id'] for r in special} == {r['case_id'] for r in z + doubles}
    for kind in ['general', 'contexts']:
        manifest = read(OUT / kind / 'manifest.json')
        for name in manifest['batches']:
            assert all(r['format'] == SINGLE for r in read(OUT / kind / name)), (kind, name)
    assert all(r['before']['snapshot']['native']['formatid'] == DOUBLE for r in read(OUT / 'doubles/cases.json'))
    z_ids, double_ids = {r['id'] for r in z}, {r['id'] for r in doubles}
    assert positive | z_ids | double_ids == allowed, sorted(allowed - positive - z_ids - double_ids)
    max_ids = {r['id'] for r in native['inventory'] if r['classification'] == 'MAX_PROFILE_PENDING'}
    ordinary = positive - max_ids
    assert (len(ordinary), len(z_ids), len(max_ids), len(double_ids)) == (820, 50, 19, 11)
    contracts = read(OUT / 'contracts.json')
    assert contracts['status'] == 'PASS' and all(r['status'] == 'PASS' for r in contracts['results'])
    live, gpu, ui = read(OUT / 'live.json'), read(OUT / 'gpu.json'), read(OUT / 'doubles_ui/ui.json')
    assert all(r['status'] == 'PASS' and not r['errors'] for r in [live, gpu, ui])
    assert len(gpu['captures']) == 2
    review = read(OUT / 'visual_review.json')
    assert review['status'] == 'PASS' and review['captures'] == gpu['captures']
    for r in gpu['captures']: assert sha(ROOT / r['path']) == r['sha256']
    counts = {}
    patterns = {'field.log': r'FIELD_NATIVE PASS checks=(\d+)',
                'repair.log': r'SHOWDOWN_MOVE_REPAIR PASS checks=(\d+)',
                'adventure.log': r'SHOWDOWN_ADVENTURE PASS checks=(\d+)',
                'medicines.log': r'SHOWDOWN_MEDICINES PASS checks=(\d+)',
                'save_v2.log': r'SAVEGAME V2 TEST RESULT: (\d+) PASS / 0 FAIL',
                'save_adversarial.log': r'SAVEGAME V2 ADVERSARIAL RESULT: (\d+) PASS / 0 FAIL',
                'core.log': r'PROJECT TEST RESULT: (\d+) PASS / 0 FAIL',
                'legacy_visual.log': r'VISUAL FIELD RESULT: (\d+) PASS / 0 FAIL',
                'map_runtime.log': r'MAP RUNTIME RESULT: (\d+) PASS / 0 FAIL',
                'medicine_tests.cjs.log': r'SHOWDOWN_MEDICINES_NATIVE PASS (\d+)',
                'transaction_tests.cjs.log': r'SHOWDOWN_TRANSACTIONS PASS (\d+)',
                'adventure_transaction_tests.cjs.log': r'SHOWDOWN_ADVENTURE_NATIVE PASS (\d+)'}
    for name, pattern in patterns.items():
        text = (OUT / 'regressions' / name).read_text(encoding='utf-8-sig')
        match = re.search(pattern, text); assert match, name
        counts[name] = int(match[1])
    logs = [OUT / n for n in ['contracts.log', 'general_native.log', 'general_godot.log',
                             'contexts_native.log', 'contexts_godot.log', 'z_native.log', 'doubles_native.log',
                             'live.log', 'gpu.log', 'doubles_ui.log']]
    logs += [OUT / 'regressions' / n for n in patterns]
    for p in logs:
        text = p.read_text(encoding='utf-8-sig'); assert 'SCRIPT ERROR' not in text, p.name
        errors = [s for s in text.splitlines() if s.startswith('ERROR:') and not
                  (p.name == 'core.log' and s.startswith('ERROR: Parse JSON failed. Error at line 0: Expected key'))]
        assert not errors, (p.name, errors)
    before, after = read(OUT / 'before.json'), protected()
    changed = sorted(p for p, old in before.items() if after.get(p) != old)
    expected = {'modules/battle/backends/showdown/native_engine.cjs', 'modules/battle/backends/showdown/showdown_backend.gd',
                'modules/battle/backends/showdown/doubles_backend.gd', 'modules/battle/application/weather_rules.gd',
                'scenes/visual/field_demo.gd', 'scenes/visual/field_native_bridge.gd',
                'scenes/visual/native_doubles_demo.gd', 'scenes/visual/showdown_adventure_lab.gd'}
    assert set(changed) <= expected, changed
    assert all(after.get(p) == value for p, value in before.items()
               if p.startswith(('data/', 'config/', 'assets/')) or p == '.godot/move_batch_catalog/index.json')
    rows = []
    for id in sorted(data['moves']):
        group = 'EXCLUDED' if id in excluded else 'MAX' if id in max_ids else 'Z_DAMAGE' if id in z_ids else 'DOUBLES' if id in double_ids else 'ORDINARY'
        rows.append({'id': id, 'group': group, 'status': 'EXCLUDED_BY_POLICY' if id in excluded else 'NATIVE_AND_GODOT_POSITIVE',
                     'general_positive_cases': sum(r['id'] == id and r['successful_actor_actions'] > 0 for r in general),
                     'prepared_positive_cases': sum(r['id'] == id and r['successful_actor_actions'] > 0 for r in contexts),
                     'z_or_doubles_cases': sum(r['id'] == id for r in z + doubles)})
    with (ROOT / 'docs/current/UNIFIED_MOVE_SWEEP.csv').open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    sources = [*expected, 'modules/battle/backends/showdown/unified_profile.cjs',
               'tests/gameplay/unified_profile_test_runner.gd', 'tests/gameplay/native_doubles_visual_test_runner.gd']
    sources += ['tools/showdown_engine_probe/' + n for n in ['move_audit.cjs', 'move_audit.gd', 'context_cases.cjs',
                'z_move_cases.cjs', 'doubles_cases.cjs', 'unified_profile_tests.cjs', 'run_unified_sweep.py', 'verify_unified_sweep.py']]
    evidence = {p.relative_to(OUT).as_posix(): sha(p) for p in OUT.rglob('*') if p.is_file() and
                p.suffix in ['.log', '.json', '.jsonl'] and p.name not in ['field.json', 'trial.json']}
    report = {'status': 'PASS', 'date': '2026-10-28', 'sim_version': '0.10.11',
              'default_map_profile': SINGLE, 'doubles_profile': DOUBLE, 'base_generation': 9,
              'custom_profile_not_an_official_format': True,
              'coverage': {'catalogue': 919, 'allowed_positive': 900, 'ordinary': 820, 'damage_Z': 50, 'Max': 19, 'doubles': 11, 'excluded': 19},
              'cases': {'general': len(general), 'prepared': len(contexts), 'Z': len(z), 'doubles': len(doubles),
                        'native_decisions_general_and_prepared': sum(r['steps'] for r in general + contexts),
                        'independent_contracts': len(native['oracle']), 'profile_contracts': len(contracts['results'])},
              'checks': {'live_Godot': live['checks'], 'GPU': gpu['checks'], 'F12_UI': ui['checks']},
              'regressions': counts, 'protected_existing_files_changed': changed,
              'data_policy_resource_manifests_unchanged': True,
              'sources_sha256': {p: sha(ROOT / p) for p in sorted(sources)}, 'evidence_sha256': evidence,
              'persistence': 'Versioned explicit profiles. Existing Gen8/Gen9 saves keep their profile; no silent conversion. Unified checkpoints round-trip including Max allowance, base PP and HP.',
              'compatibility': 'One process-local availability hook scoped to registered Calvo profiles. Native Max conditions, damage, duration and side budgets unchanged. No copies of community mod files.',
              'fixed_visible_issue': 'Sunlight from Max Flare now has a nonempty Spanish label; no weather damage formula changed.',
              'out_of_scope': ['Every possible species/item/ability/move interaction', 'Professional trainer AI', 'Mega/Tera/Ultra integration and visuals',
                               'Shared Mega/Z/Max budget proposal', 'Randomized learnsets and four-life/permanent-death rules', 'Remaining objects and multiplayer']}
    (ROOT / 'docs/current/UNIFIED_MOVE_SWEEP.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('UNIFIED_VERIFIED PASS allowed=900 excluded=19 general=' + str(len(general)) + ' prepared=72 Z=200 doubles=44')


if __name__ == '__main__': main()
