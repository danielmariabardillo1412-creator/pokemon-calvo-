"""Current opt-in adventure gate; previous phase reports remain historical."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / '.godot/showdown_adventure_checks'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    session = read(FOLDER / 'gameplay.json')
    visual = read(FOLDER / 'visual.json')
    native = read(FOLDER / 'native.json')
    backend = read(FOLDER / 'backend.json')
    assert session == {'status': 'PASS', 'checks': 86, 'errors': []}, session
    assert visual['status'] == 'PASS' and visual['checks'] == 28 and visual['gpu'] and not visual['errors']
    assert len(visual['captures']) == 5
    assert native['status'] == 'PASS' and len(native['checks']) == 7
    assert all(c['status'] == 'PASS' for c in native['checks'])
    assert backend['status'] == 'PASS' and backend['checks'] == 100 and len(backend['captures']) == 13 and not backend['errors']
    for capture in visual['captures'] + backend['captures']:
        assert sha(ROOT / capture['path']) == capture['sha256'], capture['path']
    markers = {'gameplay.log': 'SHOWDOWN_ADVENTURE PASS checks=86',
               'visual.log': 'SHOWDOWN_ADVENTURE_VISUAL PASS checks=28',
               'backend.log': 'SHOWDOWN_BACKEND PASS checks=100',
               'core.log': '472 PASS / 0 FAIL', 'playback.log': '"passed":20809',
               'trainer.log': '628 PASS / 0 FAIL'}
    for name, marker in markers.items():
        text = (FOLDER / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'SCRIPT ERROR' not in text, name
        errors = [line for line in text.splitlines() if line.startswith('ERROR:')]
        expected = ['ERROR: Parse JSON failed. Error at line 0: Expected key'] if name == 'core.log' else []
        assert errors == expected, (name, errors)
    before = read(FOLDER / 'before.json')
    changed = sorted(p for p, old in before.items() if not (ROOT / p).is_file() or sha(ROOT / p) != old)
    expected_changes = sorted(['modules/battle/backends/showdown/native_engine.cjs',
                              'modules/battle/backends/showdown/showdown_backend.gd',
                              'scenes/visual/showdown_battle_playback.gd'])
    assert changed == expected_changes, changed
    legacy = read(ROOT / '.godot/showdown_backend_checks/before.json')
    assert all(sha(ROOT / p) == old for p, old in legacy.items())
    sources = [ROOT / p for p in changed + [
        'modules/gameplay/showdown_adventure_session.gd',
        'scenes/visual/showdown_adventure_lab.gd',
        'scenes/visual/showdown_adventure_lab.tscn',
        'tests/gameplay/showdown_adventure_test_runner.gd',
        'tests/gameplay/showdown_adventure_visual_test_runner.gd',
        'tools/showdown_engine_probe/adventure_transaction_tests.cjs',
        'tools/showdown_engine_probe/verify_adventure.py',
        'JUGAR_AVENTURA_SHOWDOWN.cmd',
    ]]
    evidence = [FOLDER / name for name in [
        'gameplay.json', 'visual.json', 'native.json', 'backend.json',
        *markers.keys(), 'before.json', 'git-before.txt']]
    result = {
        'status': 'OPT_IN_COLLECTION_SESSION_AND_VISUAL_SLICE_VALIDATED', 'date': '2026-10-27',
        'backend': 'showdown_singles_v1', 'sim_version': '0.10.11', 'format': 'gen9customgame',
        'launcher': 'JUGAR_AVENTURA_SHOWDOWN.cmd', 'collection_lifetime_in_launcher': 'in_memory_across_encounters',
        'session_checks': session, 'visual_checks': visual, 'native_reaction_checks': native,
        'backend_regression': {'checks': 100, 'gpu_captures': 13},
        'other_regressions': {'core': 472, 'playback': 20809, 'trainer_evaluation_corpus': 628},
        'reused_services': ['CaptureInventoryService', 'CaptureSystem', 'CaptureOwnershipRouter',
                            'WildEscapeRuleset', 'BattleOutcome', 'ProgressionSystem', 'BattleAnimationPlayback'],
        'preserved_prior_legacy_production_files': len(legacy),
        'current_phase_baseline_files': len(before), 'existing_files_changed': changed,
        'other_baseline_files_unchanged': len(before) - len(changed),
        'default_backend_changed': False, 'main_scene_changed': False, 'save_v2_modified': False,
        'data_or_art_changed': False, 'image_substitutions': [], 'github_published': False,
        'limits': ['Bag supports capture balls; medicines not connected',
                   'NPC uses own first legal request, professional trainer AI pending',
                   'Map/campaign save owner and complete campaign rules not connected',
                   'Not a certification of every Showdown mechanic',
                   'Persistent sleep reimport still rejected pending conversion contract',
                   'Temporary forms/substitutes and combined Gen9/Dynamax profile pending',
                   'Development runtime/launcher not an autonomous export'],
        'sources_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in sources},
        'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence},
    }
    (ROOT / 'docs/current/SHOWDOWN_ADVENTURE_INTEGRATION.json').write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('SHOWDOWN_ADVENTURE_GATE PASS 86 session / 28 GPU / 7 native / 100 backend; legacy preserved', len(legacy))


if __name__ == '__main__':
    main()
