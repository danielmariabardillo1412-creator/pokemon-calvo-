"""Verify the playable opt-in backend evidence and preserved existing game."""
import hashlib
import json
from pathlib import Path
import sys
import subprocess

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / '.godot/showdown_backend_checks'
sys.path.insert(0, str(ROOT / 'tools/battle_reference'))
from run import protected_sources


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert subprocess.run(['git', 'diff', '--quiet', '--', 'project.godot'], cwd=ROOT).returncode == 0
    focal = read(FOLDER / 'gpu.json')
    assert focal['status'] == 'PASS' and focal['gpu'] and not focal['errors']
    assert focal['checks'] == 100 and len(focal['captures']) == 13
    assert {'protect/back', 'reflect/back'} <= set(focal['clip_keys'])
    for capture in focal['captures']: assert sha(ROOT / capture['path']) == capture['sha256']
    transactions = read(FOLDER / 'transactions.json')
    assert transactions['status'] == 'PASS' and len(transactions['checks']) == 10
    probe = read(ROOT / '.godot/showdown_engine_probe/report.json')
    assert probe['status'] == 'PASS' and probe['protected_sources']['unchanged']
    assert probe['node_assertions'] == 39 and probe['godot_assertions'] == 27
    assert probe['native_smoke'] == {'EXECUTED_AND_SERIALIZED': 2496}
    for field in ('probe_sha256', 'runtime_sha256', 'evidence'):
        for path, expected in probe[field].items(): assert sha(ROOT / path) == expected, path
    for name, marker in [('gpu.log', 'SHOWDOWN_BACKEND PASS'), ('core.log', '472 PASS / 0 FAIL'),
                         ('playback.log', '"passed":20809'), ('trainer.log', '628 PASS / 0 FAIL')]:
        text = (FOLDER / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'SCRIPT ERROR' not in text, name
        error_lines = [line for line in text.splitlines() if line.startswith('ERROR:')]
        expected_errors = ['ERROR: Parse JSON failed. Error at line 0: Expected key'] if name == 'core.log' else []
        assert error_lines == expected_errors, (name, error_lines)
    before, after = read(FOLDER / 'before.json'), protected_sources()
    changed = [p for p in before if before[p] != after.get(p)]
    assert not changed, changed
    added = sorted(set(after) - set(before))
    assert set(added) == {
        'modules/battle/backends/showdown/event_adapter.gd',
        'modules/battle/backends/showdown/pipe_client.gd',
        'modules/battle/backends/showdown/showdown_backend.gd',
        'scenes/visual/showdown_battle_lab.gd',
        'scenes/visual/showdown_battle_playback.gd',
    }
    files = list((ROOT / 'modules/battle/backends/showdown').iterdir())
    files += [ROOT / p for p in ('scenes/visual/showdown_battle_lab.gd', 'scenes/visual/showdown_battle_lab.tscn',
        'scenes/visual/showdown_battle_playback.gd', 'tests/battle/showdown_backend_test_runner.gd',
        'JUGAR_COMBATE_SHOWDOWN.cmd', 'tools/showdown_engine_probe/engine.cjs',
        'tools/showdown_engine_probe/pipe_client.gd', 'tools/showdown_engine_probe/transaction_tests.cjs',
        'tools/showdown_engine_probe/run.py', 'tools/showdown_engine_probe/verify_backend.py')]
    evidence = [FOLDER / p for p in ('gpu.json', 'gpu.log', 'transactions.json', 'core.log', 'playback.log', 'trainer.log', 'before.json')]
    output = {
        'status': 'LOCAL_OPT_IN_SHOWDOWN_BATTLE_VALIDATED', 'date': '2026-10-27',
        'backend': 'showdown_singles_v1', 'sim_version': '0.10.11', 'format': 'gen9customgame',
        'default_backend_changed': False, 'main_scene_changed': False,
        'launcher': 'JUGAR_COMBATE_SHOWDOWN.cmd', 'scene': 'scenes/visual/showdown_battle_lab.tscn',
        'focal': focal, 'transaction_checks': 10,
        'regressions': {'core': 472, 'playback': 20809, 'trainer_corpus': 628},
        'shared_core_probe': {'node_assertions': 39, 'godot_assertions': 27, 'native_executions_and_snapshots': 2496,
            'report': 'docs/current/SHOWDOWN_BACKEND_FEASIBILITY.json'},
        'existing_protected_files': len(before), 'existing_protected_files_changed': changed,
        'new_protected_sources': added, 'ordinary_game_admitted': 620, 'ordinary_game_mechanics_pending': 230,
        'source_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(files) if p.is_file() and p.suffix != '.uid'},
        'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence},
        'tested': ['real move and switch requests', 'native HP/PP/Protect/Reflect/healing', 'mid-turn U-turn save/restore',
            'forced replacements, KO and player victory', 'matching native replay events/RNG', 'immutable visual playback',
            'two-phase native commit/abort and stale token rejection', 'rejected unknown transition without source mutation',
            'worker crash and last-confirmed-snapshot recovery', 'content exclusions, regional aliases and shiny appearance'],
        'preserved': ['canonical raw/normalized datasets', 'artwork/manifests/frozen renderer', 'legacy server and default launch',
            'campaign save format, F: source library, randomlock policy and professional trainer AI'],
        'limits': ['Opt-in trainer lab with independent sample teams; not rolled into ordinary wild/campaign battles.',
            'No capture/bag/escape, campaign settlement or professional AI adapter yet. Lab opponent uses only its own first legal request.',
            'No implicit legacy save/LCG/sleep-clock migration. Native snapshots are versioned with data/policy hashes.',
            'Temporary forms/move replacement/substitute/unsupported protocol reject prepared turns. Mirror is presentation-only.',
            'Gen9 profile only; combined Dynamax/modern profile and portable helper packaging remain separate.',
            'Development Node and pinned dependency installation required; 256 KiB request/8 MiB response bounds.',
            'Native smoke is not independent certification of every move. Existing nine DATA V3 failures are not claimed fixed.'],
        'documentation': 'modules/battle/backends/showdown/README.md',
        'credits': 'tools/battle_reference/THIRD_PARTY_NOTICES.md', 'github_publication_performed': False,
    }
    (ROOT / 'docs/current/SHOWDOWN_BACKEND_INTEGRATION.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('SHOWDOWN_BACKEND_SUMMARY PASS: playable battle, 100 GPU checks, 13 captures, 10 transaction checks; existing game preserved')


if __name__ == '__main__':
    main()
