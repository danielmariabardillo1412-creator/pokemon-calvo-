"""Merge full catalogue/context evidence and verify this integration repair."""
import collections
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/showdown_move_repair_checks'
CONTEXT = ROOT / '.godot/showdown_context_checks'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    broad = read(ROOT / 'docs/current/MOVE_FUNCTIONAL_AUDIT.json')
    rows = read(ROOT / '.godot/move_functional_audit/moves.json')
    context = read(CONTEXT / 'native.json')
    projections = [json.loads(line) for line in (CONTEXT / 'godot.jsonl').read_text().splitlines()]
    by_case = {r['case_id']: r for r in projections}
    assert len(context['results']) == len(projections) == 74
    assert all(r['status'] == 'NATIVE_CONTEXT_VERIFIED' for r in context['results'])
    doubles = {r['id']: r for r in context['doubles']}
    assert len(doubles) == 11 and all(r['status'] == 'NATIVE_DOUBLES_CONTEXT_VERIFIED' for r in doubles.values())
    for row in rows:
        if row['status'] != 'CONTEXT_REQUIRED':
            continue
        id = row['id']
        cases = [r for r in context['results'] if r['id'] == id]
        if id in doubles:
            row['status'] = 'DOUBLES_NATIVE_ONLY'
            row['context_note'] = 'Native doubles positive fixture; no ally in current singles is an expected limitation, not an exclusion.'
        else:
            assert len(cases) == 2, id
            issues = [issue for case in cases for issue in by_case[case['case_id']]['issues']]
            row['status'] = 'FORM_CATALOG_REQUIRED' if issues else 'TARGETED_CONTEXT_VERIFIED'
            row['targeted_cases'] = [case['case_id'] for case in cases]
            row['targeted_issues'] = issues
            if issues:
                assert id == 'hyperspace_fury'
                row['context_note'] = 'Requires Hoopa-Unbound; current canonical catalogue and art contain Hoopa only. No substitute picture/form is silently used.'
    counts = dict(collections.Counter(r['status'] for r in rows))
    assert counts == {'Z_PENDING': 53, 'INTEGRATION_OK_IN_TESTED_CONTEXTS': 784,
                      'TARGETED_CONTEXT_VERIFIED': 36, 'DOUBLES_NATIVE_ONLY': 11,
                      'FORM_CATALOG_REQUIRED': 1, 'EXCLUDED': 15, 'MAX_GEN8_INTEGRATION_OK': 19}, counts
    assert len(rows) == len({r['id'] for r in rows}) == 919
    game, visual, backend = [read(OUT / (name + '.json')) for name in ['gameplay', 'visual', 'backend']]
    assert game == {'status': 'PASS', 'checks': 99, 'errors': []}, game
    assert visual['status'] == 'PASS' and visual['checks'] == 51 and len(visual['captures']) == 8 and not visual['errors']
    assert 'max_strike/back' in visual['clip_keys']
    assert backend['status'] == 'PASS' and backend['checks'] == 100 and not backend['errors']
    for capture in visual['captures'] + backend['captures']:
        assert sha(ROOT / capture['path']) == capture['sha256'], capture['path']
    markers = {'gameplay.log': 'SHOWDOWN_MOVE_REPAIR PASS checks=99',
               'visual.log': 'SHOWDOWN_MOVE_REPAIR_VISUAL PASS checks=51',
               'backend.log': 'SHOWDOWN_BACKEND PASS checks=100',
               'adventure.log': 'SHOWDOWN_ADVENTURE PASS checks=86',
               'medicines.log': 'SHOWDOWN_MEDICINES PASS checks=120',
               'medicine_visual.log': 'SHOWDOWN_MEDICINES_VISUAL PASS checks=23',
               'playback.log': '"passed":20809'}
    for name, marker in markers.items():
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'SCRIPT ERROR' not in text and '\nERROR:' not in text, name
    for log in [CONTEXT / 'godot.log', CONTEXT / 'native.log']:
        text = log.read_text(encoding='utf-8-sig'); assert 'SCRIPT ERROR' not in text and '\nERROR:' not in text
    # The broad audit is based on current runtime code, not the first failing run.
    for group in ['sources_sha256', 'evidence_sha256']:
        for p, expected in broad[group].items(): assert sha(ROOT / p) == expected, p
    baseline = read(OUT / 'before.json')
    changes = sorted(p for p, old in baseline.items() if sha(ROOT / p) != old)
    allowed = {'modules/battle/backends/showdown/native_engine.cjs', 'modules/battle/backends/showdown/showdown_backend.gd',
               'modules/battle/backends/showdown/event_adapter.gd', 'modules/gameplay/showdown_adventure_session.gd',
               'scenes/visual/showdown_adventure_lab.gd', 'scenes/visual/showdown_battle_lab.gd',
               'scenes/visual/showdown_battle_playback.gd', 'scenes/visual/battle_timeline_plan.gd', 'scenes/visual/battle_art.gd'}
    assert set(changes) <= allowed, changes
    policy = read(ROOT / 'config/randomlock_content_v1.json')
    assert policy['z_moves']['decision'] == 'pending'
    native_evidence = [ROOT / '.godot' / p for p in ['showdown_medicine_checks/native.json', 'showdown_backend_checks/transactions.json', 'showdown_adventure_checks/native.json']]
    for path, count in zip(native_evidence, [21, 10, 7]):
        result = read(path); assert result['status'] == 'PASS' and len(result['checks']) == count
    csv_path = ROOT / 'docs/current/MOVE_CONNECTION_REPAIR.csv'
    with csv_path.open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f); writer.writerow(['id', 'status', 'profile', 'note'])
        for row in rows:
            profile = 'gen8customgame' if row['status'] == 'MAX_GEN8_INTEGRATION_OK' else ('gen9doublescustomgame_native_only' if row['status'] == 'DOUBLES_NATIVE_ONLY' else 'gen9customgame')
            writer.writerow([row['id'], row['status'], profile, row.get('context_note', '')])
    sources = list(allowed) + ['JUGAR_COMBATE_MAXI.cmd', 'tests/gameplay/showdown_move_repair_test_runner.gd',
        'tests/gameplay/showdown_move_repair_visual_test_runner.gd', 'tests/battle/showdown_backend_test_runner.gd',
        'tests/gameplay/showdown_adventure_test_runner.gd', 'tests/gameplay/showdown_medicine_test_runner.gd',
        'tools/showdown_engine_probe/context_cases.cjs', 'tools/showdown_engine_probe/verify_move_connections.py',
        'tools/showdown_engine_probe/run_move_connections.py']
    evidence = [OUT / name for name in [*markers, 'gameplay.json', 'visual.json', 'backend.json', 'before.json']]
    evidence += [CONTEXT / name for name in ['native.json', 'godot.jsonl', 'godot.log', 'batch_contexts.json', 'prototypes.json']]
    evidence += [csv_path, ROOT / 'docs/current/MOVE_FUNCTIONAL_AUDIT.json']
    evidence += native_evidence
    report = {'status': 'MOVE_CONNECTION_REPAIRS_AND_CONTEXTS_VALIDATED_WITH_DECLARED_LIMITS', 'date': '2026-10-27',
        'inventory': 919, 'counts': counts, 'singles_tested': 820, 'max_gen8_connected': 19,
        'general_audit': {'cases': broad['cases'], 'native_decisions': broad['native_steps'], 'adapter_blocked_moves': 0},
        'targeted_contexts': {'native_cases': 74, 'godot_positive_cases': 72, 'form_blocked_cases': 2, 'doubles_native_cases': 11},
        'checks': {'dedicated_gameplay': 99, 'GPU': 51, 'GPU_captures': 8, 'backend': 100, 'adventure': 86, 'medicines': 120, 'medicine_GPU': 23, 'native': [21, 10, 7], 'legacy_playback': 20809},
        'max_launcher': 'JUGAR_COMBATE_MAXI.cmd',
        'policy_decision': {'z': 'Remain pending per current user response; quoted friend message does not specify a definitive list of 53.',
                            'max': 'Include all 19, explicitly confirmed priority.', 'new_exclusions': []},
        'changed_existing_sources': changes, 'all_other_baseline_files_unchanged': len(baseline) - len(changes),
        'default_map_backend_changed': False, 'data_or_art_assets_changed': False, 'image_substitutions': [],
        'legacy_shared_consumers': 'Timeline accepts explicit native HP/maxHP and Dynamax flag; art scales only explicitly flagged Dynamax views. No legacy combat formulas changed.',
        'limits': ['11 doubles-only moves have positive native doubles fixtures; Godot doubles UI is not implemented.',
                   'Hyperspace Fury native context passes; Hoopa-Unbound data/art are absent, so its game form remains blocked.',
                   'Gen8 Max and Gen9 are explicit separate profiles; no hybrid mechanics implied.',
                   'Sleeping legacy import, other temporary forms/Tera/Mega and campaign map/save owner remain outside this slice.',
                   'Tested contexts do not certify every move interaction or every per-move VFX.',
                   'Default adventure still uses historical backend; no global migration/activation.'],
        'sources_sha256': {p: sha(ROOT / p) for p in sorted(sources)},
        'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence}}
    (ROOT / 'docs/current/MOVE_CONNECTION_REPAIR.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('MOVE_CONNECTION_REPAIR_VERIFIED 919 accounted; 820 singles tested; 19 Max Gen8; 11 doubles/1 form/53 Z pending; 15 excluded')


if __name__ == '__main__':
    main()
