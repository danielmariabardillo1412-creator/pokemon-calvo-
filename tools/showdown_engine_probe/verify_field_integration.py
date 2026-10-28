"""Verify the actual map owner, native checkpoints and unchanged canonical inputs."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/field_native_checks'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    gameplay, gpu, clocks = [read(OUT / n) for n in ['gameplay.json', 'gpu.json', 'native_clocks.json']]
    assert all(r['status'] == 'PASS' for r in [gameplay, gpu, clocks])
    assert not gameplay['errors'] and not gpu['errors'] and len(gpu['captures']) == 5
    assert len(clocks['checks']) == 8 and all(c['status'] == 'PASS' for c in clocks['checks'])
    for c in gpu['captures']: assert sha(ROOT / c['path']) == c['sha256']
    review_path = OUT / 'visual_review.json'
    reviewed = read(review_path).get('captures', []) if review_path.exists() else []
    reviewed_hashes = {c['sha256'] for c in reviewed}
    reviewed_count = sum(c['sha256'] in reviewed_hashes for c in gpu['captures'])
    markers = {'save_v2.log': r'SAVEGAME V2 TEST RESULT: (\d+) PASS / 0 FAIL',
               'save_adversarial.log': r'SAVEGAME V2 ADVERSARIAL RESULT: (\d+) PASS / 0 FAIL',
               'core.log': r'PROJECT TEST RESULT: (\d+) PASS / 0 FAIL',
               'legacy_visual.log': r'VISUAL FIELD RESULT: (\d+) PASS / 0 FAIL',
               'map_runtime.log': r'MAP RUNTIME RESULT: (\d+) PASS / 0 FAIL',
               'repair.log': r'SHOWDOWN_MOVE_REPAIR PASS checks=(\d+)',
               'adventure.log': r'SHOWDOWN_ADVENTURE PASS checks=(\d+)',
               'medicines.log': r'SHOWDOWN_MEDICINES PASS checks=(\d+)',
               'medicine_tests.cjs.log': r'SHOWDOWN_MEDICINES_NATIVE PASS (\d+)',
               'transaction_tests.cjs.log': r'SHOWDOWN_TRANSACTIONS PASS (\d+)',
               'adventure_transaction_tests.cjs.log': r'SHOWDOWN_ADVENTURE_NATIVE PASS (\d+)'}
    counts = {}
    for name, pattern in markers.items():
        text = (OUT / name).read_text(encoding='utf-8-sig')
        match = re.search(pattern, text)
        assert match and 'SCRIPT ERROR' not in text, name
        unexpected = [line for line in text.splitlines() if line.startswith('ERROR:') and not
                      (name == 'core.log' and line.startswith('ERROR: Parse JSON failed. Error at line 0: Expected key'))]
        assert not unexpected, (name, unexpected[:2])
        counts[name] = int(match[1])
    for name in ['gameplay.log', 'gpu.log', 'native_clocks.log']:
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR' not in text and '\nERROR:' not in text, name
    allowed = {'project.godot', 'scenes/visual/field_demo.gd', 'scenes/debug/technical_test_panel.gd',
               'modules/save/save_game_repository.gd', 'modules/save/save_game_serializer.gd',
               'modules/battle/backends/showdown/native_engine.cjs', 'modules/battle/backends/showdown/showdown_backend.gd',
               'modules/gameplay/showdown_adventure_session.gd'}
    baseline = read(OUT / 'before.json')
    changes = sorted(p for p, old in baseline.items() if sha(ROOT / p) != old)
    assert set(changes) <= allowed, changes
    assert 'run/main_scene="res://scenes/visual/field_demo.tscn"' in (ROOT / 'project.godot').read_text()
    sources = sorted(allowed | {'modules/gameplay/field_native_session.gd', 'modules/save/field_native_save.gd',
        'scenes/visual/field_native_bridge.gd', 'scenes/visual/field_native_presentation.gd',
        'tests/gameplay/field_native_test_runner.gd', 'tools/showdown_engine_probe/field_clock_tests.cjs',
        'tools/showdown_engine_probe/run_field_integration.py', 'tools/showdown_engine_probe/verify_field_integration.py'})
    evidence = [OUT / name for name in [*markers, 'gameplay.json', 'gpu.json', 'gameplay.log', 'gpu.log',
        'native_clocks.json', 'native_clocks.log', 'before.json']]
    if review_path.exists(): evidence.append(review_path)
    prior = ROOT / 'docs/current/Z_MOVE_INTEGRATION.json'
    report = {'status': 'DEFAULT_FIELD_NATIVE_COMBAT_AND_SAVE_VALIDATED', 'date': '2026-10-27',
        'entry_scene': 'scenes/visual/field_demo.tscn', 'launcher': 'JUGAR_DEMO.cmd',
        'default_map_backend_changed': True, 'default_format': 'gen9customgame', 'optional_explicit_format': 'gen8customgame',
        'checks': {'native_map': gameplay['checks'], 'GPU_map': gpu['checks'], 'GPU_captures_generated': 5, 'GPU_captures_reviewed': reviewed_count,
                   'native_sleep_clocks': len(clocks['checks']), 'regressions': counts},
        'save': {'path': 'user://pokemon_calvo_field.json', 'envelope': 'calvo_field_native_v1',
                 'collection': 'Existing canonical SaveGame V2 embedded unchanged',
                 'atomic_IO': 'Existing last-known-good serializer reused; failed publish rollback tested',
                 'active_battle': 'Native state/RNG plus baseline collection, staged inventory/journal, trainer, map position and encounter RNG',
                 'publication': 'Decode and native recovery finish before replacing the active campaign',
                 'controls': ['Ctrl+S', 'Ctrl+L', 'Guardar partida', 'Cargar partida']},
        'covered': ['Keyboard movement and grass-to-native encounter in the existing field.',
                    'Capture to real party/PC, failed load without publication, active checkpoint rollback, no duplicate capture/XP.',
                    'Map medicine staged/spent inventory, escape, KO, replacement, victory, defeat and return to exploration.',
                    'Trainer owned object HP/PP/status settlement and no automatic recovery/rematch after all KO.',
                    'Observed sleep clock across capture, save/load and next encounter; unknown legacy sleep still rejected.',
                    'Worker death/recovery, commands locked during load, native Z and explicit Gen8 Max checkpoint.'],
        'limits': ['11 doubles-context moves still need the native Godot doubles command/presentation path.',
                   'Gen8/Gen9 remain separate explicit profiles; final combined special-mechanic rules are not defined here.',
                   'Trainer opponent uses the existing basic native policy; professional AI is retained in the diagnostic legacy path.',
                   'Random learnset generation, custom permanent death/four lives and multiplayer remain later systems.',
                   'Map scenarios do not recertify all possible interactions of the 889 previously tested singles actions.'],
        'prior_move_inventory': {'path': prior.relative_to(ROOT).as_posix(), 'sha256': sha(prior),
                                 'note': 'Historical catalogue evidence, not a verifier for the subsequently changed map/backend sources.'},
        'changed_existing_sources': changes, 'other_protected_files_unchanged': len(baseline)-len(changes),
        'data_or_art_substitutions': [], 'legacy_regression_mode': '--legacy-field (explicit compatibility only, no automatic fallback)',
        'sources_sha256': {p: sha(ROOT / p) for p in sources},
        'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence}}
    (ROOT / 'docs/current/FIELD_NATIVE_INTEGRATION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('FIELD_NATIVE_VERIFIED default field + native battle/save; checks', gameplay['checks'], gpu['checks'], 'captures 5; protected', len(baseline)-len(changes))


if __name__ == '__main__':
    main()
