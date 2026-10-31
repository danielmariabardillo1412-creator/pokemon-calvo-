"""Bounded evidence verifier for the native F12 doubles integration."""
from pathlib import Path
import hashlib
import json
import re
from audit_moves import protected

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/native_doubles_checks'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    native = read(OUT / 'native.json')['results']
    assert len(native) == 44 and all(r['status'] == 'PASS' for r in native)
    ids = sorted({r['id'] for r in native})
    assert len(ids) == 11
    assert {(r['side'], r['seed']) for r in native} == {('p1', 1), ('p1', 19), ('p2', 1), ('p2', 19)}
    cases = read(OUT / 'cases.json')
    assert {r['case_id'] for r in cases} == {r['case_id'] for r in native}
    projection = read(OUT / 'projection.json')
    assert len(projection) == 44 and all(r['ok'] and not r['unknown'] for r in projection)
    live, ui, gpu = [read(OUT / n) for n in ['gameplay.json', 'ui.json', 'gpu.json']]
    assert all(r['status'] == 'PASS' and not r['errors'] for r in [live, ui, gpu])
    assert len(gpu['captures']) == 66
    reviewed = {r['sha256'] for r in read(OUT / 'visual_review.json')['captures']}
    for c in gpu['captures']:
        assert sha(ROOT / c['path']) == c['sha256'] and c['sha256'] in reviewed
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
    counts = {}
    for name in ['native.log', 'gameplay.log', 'ui.log', 'gpu.log', *patterns]:
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR' not in text, name
        errors = [line for line in text.splitlines() if line.startswith('ERROR:') and not
                  (name == 'core.log' and line.startswith('ERROR: Parse JSON failed. Error at line 0: Expected key'))]
        assert not errors, (name, errors)
        if name in patterns:
            match = re.search(patterns[name], text)
            assert match, name
            counts[name] = int(match[1])
    before, after = read(OUT / 'before.json'), protected()
    changed = sorted(p for p, old in before.items() if after.get(p) != old)
    allowed = {'modules/battle/backends/showdown/native_engine.cjs',
               'modules/battle/backends/showdown/showdown_backend.gd',
               'modules/battle/backends/showdown/event_adapter.gd',
               'scenes/visual/field_demo.gd', 'scenes/visual/doubles_battle_art.gd',
               'scenes/visual/community_move_preview.gd'}
    assert set(changed) <= allowed, changed
    assert all(after.get(p) == old for p, old in before.items()
               if p.startswith(('data/', 'config/', 'assets/')) or p == '.godot/move_batch_catalog/index.json')
    sources = [*allowed, 'modules/battle/backends/showdown/doubles_backend.gd',
               'scenes/visual/native_doubles_demo.gd', 'scenes/visual/native_doubles_timeline.gd',
               'tests/gameplay/native_doubles_test_runner.gd', 'tests/gameplay/native_doubles_visual_test_runner.gd',
               'tools/showdown_engine_probe/doubles_cases.cjs',
               'tools/showdown_engine_probe/run_doubles_integration.py',
               'tools/showdown_engine_probe/verify_doubles_integration.py',
               'tools/showdown_engine_probe/doubles_contact_sheets.py']

    evidence_names = ['native.json', 'cases.json', 'prototypes.json', 'projection.json',
                      'gameplay.json', 'ui.json', 'gpu.json', 'visual_review.json',
                      'native.log', 'gameplay.log', 'ui.log', 'gpu.log', *patterns]
    report = {'status': 'PASS', 'date': '2026-10-27', 'format': 'gen9doublescustomgame',
              'sim_version': '0.10.11', 'move_ids': ids, 'native_cases': 44,
              'live_godot_checks': live['checks'], 'ui_checks': ui['checks'], 'gpu_checks': gpu['checks'],
              'reviewed_temporal_captures': 66, 'regressions': counts,
              'existing_runtime_files_changed': changed,
              'data_config_resource_manifests_unchanged': True,
              'sources_sha256': {p: sha(ROOT / p) for p in sorted(sources)},
              'evidence_sha256': {name: sha(OUT / name) for name in evidence_names},
              'entry': 'JUGAR_DEMO.cmd / F12',
              'scope': 'Native four-active test surface, separate clones and separate atomic checkpoint; no campaign doubles encounters or rewards enabled.',
              'visual_adaptation': 'Existing immutable clips: real actor/recipient geometry, original body motion and particles; bystanders at shared layer depth. Aromatic Mist fog retained. Spotlight opaque black plate omitted to retain four-slot context. Ally Switch uses existing pinned fade curves.',
              'remaining': ['Final combined generation/special-mechanic profile', 'Final whole-catalogue sweep of that chosen profile'],
              'limitations': ['Positive fixtures and regressions do not certify every interaction of every move.', 'No Mega/Z/Max/Tera choices enabled implicitly for this doubles profile.']}
    (ROOT / 'docs/current/NATIVE_DOUBLES_INTEGRATION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'DOUBLES_VERIFIED PASS native=44 Godot={live["checks"]} UI={ui["checks"]} GPU={gpu["checks"]} captures=66')


if __name__ == '__main__':
    main()
