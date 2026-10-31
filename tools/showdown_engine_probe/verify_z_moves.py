"""Verify current Z evidence and account for every canonical move honestly."""
import collections
import csv
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/showdown_z_checks'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    native = read(OUT / 'native.json')
    gameplay = read(OUT / 'gameplay.json')
    visual = read(OUT / 'visual.json')
    projected = [json.loads(line) for line in (OUT / 'godot.jsonl').read_text().splitlines()]
    assert len(native['results']) == len(projected) == 400
    assert all(r['status'] == 'NATIVE_Z_VERIFIED' for r in native['results'])
    assert collections.Counter(r['status'] for r in projected) == {'PASS': 400}
    assert len({r['id'] for r in projected if r['status'] == 'PASS'}) == 50
    assert gameplay['status'] == visual['status'] == 'PASS' and not gameplay['errors'] and not visual['errors']
    assert len(visual['captures']) == 4
    for capture in visual['captures']: assert sha(ROOT / capture['path']) == capture['sha256']
    log_counts = {}
    markers = {'repair.log': r'SHOWDOWN_MOVE_REPAIR PASS checks=(\d+)',
               'repair_visual.log': r'SHOWDOWN_MOVE_REPAIR_VISUAL PASS checks=(\d+)',
               'backend.log': r'SHOWDOWN_BACKEND PASS checks=(\d+)',
               'adventure.log': r'SHOWDOWN_ADVENTURE PASS checks=(\d+)',
               'medicines.log': r'SHOWDOWN_MEDICINES PASS checks=(\d+)',
               'playback.log': r'"passed":\s*(\d+)',
               'policy.log': r'RANDOMLOCK CONTENT: (\d+) checks; 0 failures'}
    for name, regex in markers.items():
        text = (OUT / name).read_text(encoding='utf-8-sig')
        match = re.search(regex, text)
        assert match and 'SCRIPT ERROR' not in text and '\nERROR:' not in text, name
        log_counts[name] = int(match[1])
    for name in ['native.log', 'gameplay.log', 'visual.log', 'content.log', 'medicine_tests.cjs.log', 'transaction_tests.cjs.log', 'adventure_transaction_tests.cjs.log']:
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR' not in text and '\nERROR:' not in text and 'FAIL' not in text, name
    policy = read(ROOT / 'config/randomlock_content_v1.json')
    assert policy['z_moves']['decision'] == 'damage_only'
    assert len(policy['z_moves']['ids']) == 53 and len(policy['protected_max_move_ids']) == 19
    source_rows = list(csv.DictReader((ROOT / 'docs/current/MOVE_CONNECTION_REPAIR.csv').open(encoding='utf-8-sig')))
    descriptors = {d['id']: d for d in native['descriptors']}
    statuses = {'PLAYABLE': 'Z_INTEGRATION_OK', 'STATUS_Z_EXCLUDED': 'EXCLUDED', 'USER_EXCLUDED': 'EXCLUDED'}
    signature_bans = {'hyperspace_fury', 'light_that_burns_the_sky', '10_000_000_volt_thunderbolt'}
    denied = {id for group in policy['move_exclusions'] for id in group['ids']}
    assert signature_bans <= denied
    for row in source_rows:
        if row['id'] in descriptors:
            d = descriptors[row['id']]
            row['status'] = statuses[d['status']]
            row['profile'] = 'gen8customgame / gen9customgame'
            row['note'] = {'PLAYABLE': 'Native crystal/species/base-move requirements; both sides, two seeds, two profiles; Godot live and projection verified.',
                           'STATUS_Z_EXCLUDED': 'User bans every status Z effect; ordinary status moves remain eligible.',
                           'USER_EXCLUDED': 'Explicit user exclusion: required form is absent/excluded. Not a pending implementation.'}[d['status']]
        if row['id'] in signature_bans:
            row['status'] = 'EXCLUDED'
            row['note'] = 'Explicit user exclusion: required form is absent/excluded. Do not add the form or substitute a user to enable this move.'
    counts = dict(collections.Counter(r['status'] for r in source_rows))
    assert len(source_rows) == len({r['id'] for r in source_rows}) == 919
    assert counts == {'INTEGRATION_OK_IN_TESTED_CONTEXTS': 784, 'TARGETED_CONTEXT_VERIFIED': 36,
                      'MAX_GEN8_INTEGRATION_OK': 19, 'Z_INTEGRATION_OK': 50, 'DOUBLES_NATIVE_ONLY': 11,
                      'EXCLUDED': 19}, counts
    baseline = read(OUT / 'before.json')
    changed = sorted(p for p, old in baseline.items() if sha(ROOT / p) != old)
    allowed = {'config/randomlock_content_v1.json', 'modules/gameplay/randomlock_content_policy.gd',
               'modules/battle/backends/showdown/native_engine.cjs', 'modules/battle/backends/showdown/showdown_backend.gd',
               'modules/battle/backends/showdown/event_adapter.gd', 'scenes/visual/showdown_battle_lab.gd',
               'scenes/visual/showdown_adventure_lab.gd', 'tests/gameplay/randomlock_content_test_runner.gd',
               'docs/current/NEXT_STEPS.md', 'docs/current/PROJECT_STATE.md', 'docs/project_book/README.md',
               'docs/project_book/RANDOMLOCK_RULES.md', 'modules/battle/backends/showdown/README.md',
               'tools/showdown_engine_probe/MOVE_AUDIT.md'}
    assert set(changed) <= allowed, changed
    csv_path = ROOT / 'docs/current/Z_MOVE_INTEGRATION.csv'
    with csv_path.open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['id', 'status', 'profile', 'note'])
        writer.writeheader(); writer.writerows(source_rows)
    sources = sorted(allowed | {'tools/showdown_engine_probe/z_move_cases.cjs',
        'tools/showdown_engine_probe/run_z_moves.py', 'tools/showdown_engine_probe/verify_z_moves.py',
        'tests/gameplay/showdown_z_move_test_runner.gd', 'tests/gameplay/showdown_z_visual_test_runner.gd',
        'JUGAR_COMBATE_Z.cmd'})
    evidence = [p for p in OUT.iterdir() if p.is_file() and p.suffix in ['.json', '.jsonl', '.png', '.log'] and p.name not in ['verify.log', 'run.log']]
    evidence += [csv_path, ROOT / 'docs/current/MOVE_CONNECTION_REPAIR.json', ROOT / 'docs/current/MOVE_CONNECTION_REPAIR.csv', ROOT / 'docs/current/CONTENT_POOL_AUDIT.json']
    report = {'status': 'Z_INTEGRATED_FOR_CURRENT_CONTENT_POLICY', 'date': '2026-10-27',
        'inventory': 919, 'counts': counts, 'singles_with_existing_content': 889,
        'z': {'inventory': 53, 'damage_catalogued': 52, 'damage_allowed': 50, 'connected_existing_users': 50, 'status_excluded': 1,
              'signature_user_excluded': 2, 'pending_missing_forms': 0,
              'native_cases': 400, 'godot_projections': 400, 'live_moves': 50, 'gameplay_checks': gameplay['checks'],
              'GPU_checks': visual['checks'], 'GPU_captures': len(visual['captures'])},
        'regression_checks': log_counts, 'changed_baseline_files': changed,
        'unchanged_baseline_files': len(baseline)-len(changed), 'image_substitutions': [],
        'launcher': 'JUGAR_COMBATE_Z.cmd', 'default_map_backend_changed': False,
        'policy': 'Damaging Z only, plus three explicit absent/excluded signature-user bans. Other researched bans and shared Mega/Z/Max budget not applied.',
        'signature_moves_excluded': sorted(signature_bans),
        'limits': ['11 moves need a doubles presentation/command path; positive native doubles tests remain historical evidence.',
                   'Hyperspace Fury, Light That Burns the Sky and 10,000,000 Volt Thunderbolt are excluded by user decision, not pending form work.',
                   'Ordinary map/save owner still uses the historical backend; this work closes Z in the opt-in connection.',
                   'Gen8 and Gen9 are separate native profiles, not a newly implemented cross-generation ruleset.',
                   'Batch integration tests and representative GPU checks do not certify all possible move interactions.'],
        'sources_sha256': {p: sha(ROOT / p) for p in sources},
        'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(evidence)}}
    (ROOT / 'docs/current/Z_MOVE_INTEGRATION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('Z_VERIFIED 919 accounted; 50 Z connected; 400 native/400 Godot; 889 tested singles actions; 11 doubles; 19 excluded; 0 missing-form moves pending')


if __name__ == '__main__':
    main()
