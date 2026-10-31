"""Verify the current medicine slice without rewriting prior phase reports."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/showdown_medicine_checks'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    gameplay, native, visual, backend = [read(OUT / (name + '.json')) for name in ('gameplay', 'native', 'visual', 'backend')]
    assert gameplay['status'] == 'PASS' and gameplay['checks'] == 120 and not gameplay['errors']
    profile = read(ROOT / 'modules/inventory/battle_medicine_profile.json')
    assert len(profile['items']) == 15 and set(gameplay['items']) == set(profile['items'])
    assert native['status'] == 'PASS' and len(native['checks']) == 21 and all(c['status'] == 'PASS' for c in native['checks'])
    assert visual['status'] == 'PASS' and visual['checks'] == 23 and len(visual['captures']) == 5 and not visual['errors']
    assert backend['status'] == 'PASS' and backend['checks'] == 100 and len(backend['captures']) == 13 and not backend['errors']
    for capture in visual['captures'] + backend['captures']:
        assert sha(ROOT / capture['path']) == capture['sha256'], capture['path']
    markers = {'gameplay.log': 'SHOWDOWN_MEDICINES PASS checks=120',
               'visual.log': 'SHOWDOWN_MEDICINES_VISUAL PASS checks=23',
               'adventure.log': 'SHOWDOWN_ADVENTURE PASS checks=86',
               'backend.log': 'SHOWDOWN_BACKEND PASS checks=100'}
    for name, marker in markers.items():
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'SCRIPT ERROR' not in text and '\nERROR:' not in text, name
    transactions = read(ROOT / '.godot/showdown_backend_checks/transactions.json')
    reactions = read(ROOT / '.godot/showdown_adventure_checks/native.json')
    assert transactions['status'] == 'PASS' and len(transactions['checks']) == 10
    assert reactions['status'] == 'PASS' and len(reactions['checks']) == 7
    baseline = read(OUT / 'before.json')
    changed = sorted(p for p, old in baseline.items() if not (ROOT / p).is_file() or sha(ROOT / p) != old)
    expected = sorted(['modules/gameplay/showdown_adventure_session.gd', 'modules/battle/backends/showdown/event_adapter.gd',
                       'modules/battle/backends/showdown/native_engine.cjs', 'modules/battle/backends/showdown/showdown_backend.gd',
                       'scenes/visual/showdown_adventure_lab.gd'])
    assert changed == expected, changed
    legacy = read(ROOT / '.godot/showdown_backend_checks/before.json')
    assert all(sha(ROOT / p) == old for p, old in legacy.items())
    sources = expected + ['modules/inventory/battle_medicine_profile.gd', 'modules/inventory/battle_medicine_profile.json',
                          'tests/gameplay/showdown_medicine_test_runner.gd', 'tests/gameplay/showdown_medicine_visual_test_runner.gd',
                          'tools/showdown_engine_probe/medicine_tests.cjs', 'tools/showdown_engine_probe/verify_medicines.py']
    evidence = [OUT / name for name in ['before.json', 'gameplay.json', 'native.json', 'visual.json', 'backend.json', *markers]]
    evidence += [ROOT / '.godot/showdown_backend_checks/transactions.json', ROOT / '.godot/showdown_adventure_checks/native.json']
    report = {
        'status': 'OPT_IN_MEDICINE_BAG_GROUP_VALIDATED', 'date': '2026-10-27', 'profile': profile,
        'gameplay': gameplay, 'native': native, 'visual': visual,
        'regressions': {'adventure': 86, 'backend': 100, 'native_transactions': 10, 'native_reactions': 7},
        'legacy_production_sources_preserved': len(legacy), 'baseline_files': len(baseline), 'changed_baseline_files': changed,
        'default_scene_changed': False, 'legacy_server_changed': False, 'data_or_art_changed': False,
        'ai_changed': False, 'custom_randomlock_rules_implemented': False, 'save_v2_changed': False,
        'github_published': False, 'image_substitutions': [], 'adventure_checkpoint_schema': 2,
        'runtime': 'Gen9 singles / @pkmn/sim 0.10.11',
        'source_basis': 'Existing BattleEffectRegistry heal values; local canonical cure/PP descriptions; local Essentials reference checked for modern amount/confusion/Embargo behavior. No Ruby code copied.',
        'priority': 'Finish basic Pokemon systems, retain basic NPC. Professional AI and custom rules later.',
        'future_rules_recorded_not_implemented': ['Four lives', 'Remove dead Pokemon instead of keeping fainted party members'],
        'limits': ['Other bag groups including Revive not connected', 'Out-of-battle item use pending',
                   'Default map/save owner not connected; launcher collection is in memory',
                   'Previous sleep-import/forms/substitute/combined Dynamax boundaries remain',
                   'Not a complete certification of all Pokemon systems'],
        'sources_sha256': {p: sha(ROOT / p) for p in sources},
        'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence},
    }
    (ROOT / 'docs/current/SHOWDOWN_MEDICINE_INTEGRATION.json').write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('SHOWDOWN_MEDICINES_GATE PASS 15 items / 120 Godot / 21 Node / 23 GPU; existing legacy preserved', len(legacy))


if __name__ == '__main__':
    main()
