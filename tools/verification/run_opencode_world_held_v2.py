"""O120 family gate: real processes, per-run logs, counts and the mission guard.

Reuses LocalPhase.run_godot (the shared process runner), has a real CLI
entrypoint, and keeps O120 regressions plus its GPU sample.
"""
from pathlib import Path
import argparse, json, subprocess, sys, time
from local_phase import LocalPhase, sha, write

ROOT = Path(__file__).resolve().parents[2]
MISSION_BASE = '78c3b0f7d6ccfbe8f26f75070d9737ccdaa90035'
OUT = ROOT / '.godot/opencode_items_v2/world_held'
GUARD = 'tools/verification/opencode_items_v2_guard.py'


def run_process(command, log_path, timeout=900):
    log_path.parent.mkdir(parents=True, exist_ok=True)
    assert not log_path.exists(), 'Never overwrite execution evidence: ' + str(log_path)
    start = time.monotonic()
    try:
        completed = subprocess.run([str(part) for part in command], cwd=ROOT, capture_output=True, text=True, timeout=timeout)
        output = completed.stdout + completed.stderr
        log_path.write_text(output, encoding='utf-8')
        return {'status': 'PASS' if completed.returncode == 0 else 'FAIL', 'exit_code': completed.returncode,
                'seconds': round(time.monotonic() - start, 2), 'command': [str(part) for part in command],
                'log': str(log_path), 'log_sha256': sha(log_path)}
    except subprocess.TimeoutExpired:
        log_path.write_text('TIMEOUT after %ss' % timeout, encoding='utf-8')
        return {'status': 'FAIL', 'exit_code': -1, 'seconds': timeout, 'error': 'timeout',
                'command': [str(part) for part in command], 'log': str(log_path), 'log_sha256': sha(log_path)}


def mission_guard(dest, label='guard'):
    result = run_process([sys.executable, GUARD], dest / (label + '.json.log'), timeout=900)
    text = Path(result['log']).read_text(encoding='utf-8')
    payload = None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('{'): payload = json.loads(line)
    if payload is None: raise AssertionError('guard produced no JSON: ' + result['log'])
    result['report'] = payload
    if payload.get('status') != 'PASS': raise AssertionError('mission guard failed: ' + json.dumps(payload))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--piece', action='store_true', help='skip regressions and GPU groups')
    args = parser.parse_args()
    phase = LocalPhase(ROOT, MISSION_BASE, OUT, set())
    dest = OUT / 'runs' / str(time.time_ns())
    dest.mkdir(parents=True, exist_ok=True)
    report = {'status': 'RUNNING', 'family': 'O120', 'base': MISSION_BASE, 'groups': []}
    try:
        report['guard_before'] = mission_guard(dest, 'guard_before')
        python_groups = [
            ('world_import_test', [sys.executable, 'tests/tools/test_world_held_import_v2.py']),
            ('world_import_check', [sys.executable, 'tools/item_import/import_world_held_v2.py', '--check']),
        ]
        for name, command in python_groups:
            result = run_process(command, dest / (name + '.log'), timeout=120)
            report['groups'].append(result); write(dest / 'results.json', report)
            print(name, result['status'], flush=True)
            assert result['status'] == 'PASS', name
        node = run_process(['node', 'tools/showdown_engine_probe/opencode_world_held_v2.cjs'], dest / 'world_held_node.log', timeout=600)
        report['groups'].append(node); write(dest / 'results.json', report)
        assert node['status'] == 'PASS', 'world_held_node'
        print('world_held_node', node['status'], flush=True)
        godot_groups = [('world_held_godot', 'tests/gameplay/opencode_world_held_v2.gd')]
        if not args.piece:
            godot_groups += [
                ('native_field', 'tests/gameplay/field_native_test_runner.gd'),
                ('restore', 'tests/gameplay/field_restore_integration_test_runner.gd'),
                ('held_v20', 'tests/gameplay/field_held_v20.gd'),
                ('escape_v21', 'tests/gameplay/item_escape_v21.gd'),
            ]
        for name, script in godot_groups:
            if name == 'native_field':
                (ROOT / '.godot/field_native_checks').mkdir(parents=True, exist_ok=True)
            if name == 'escape_v21':
                (ROOT / '.godot/showdown_adventure_checks').mkdir(parents=True, exist_ok=True)
            result = phase.run_godot(name, script, dest)
            report['groups'].append(result); write(dest / 'results.json', report)
            assert result['status'] == 'PASS', name
        if not args.piece:
            result = phase.run_godot('world_held_gpu', 'tests/gameplay/opencode_world_held_v2.gd', dest, gpu=True, args=['--capture'])
            report['groups'].append(result); write(dest / 'results.json', report)
            assert result['status'] == 'PASS', 'world_held_gpu'
        report['tested_sources_sha256'] = {path: sha(ROOT / path) for path in sorted([
            'modules/battle/backends/showdown/native_engine.cjs',
            'modules/battle/backends/showdown/field_held_items.cjs',
            'modules/battle/backends/showdown/field_world_items_v2.json',
            'modules/gameplay/encounter_item_modifiers.gd',
            'modules/gameplay/held_escape_items.gd',
            'modules/gameplay/showdown_adventure_session.gd',
            'modules/gameplay/wild_adventure_session.gd',
            'scenes/visual/field_demo.gd',
            'tests/gameplay/opencode_world_held_v2.gd',
            'tools/showdown_engine_probe/opencode_world_held_v2.cjs',
            'tools/item_import/import_world_held_v2.py',
            'tests/tools/test_world_held_import_v2.py',
        ]) if (ROOT / path).is_file()}
        report['guard_after'] = mission_guard(dest, 'guard_after')
        report['status'] = 'PASS'
    except Exception as error:  # noqa: BLE001
        report['status'] = 'FAIL'
        report['error'] = str(error)
    write(dest / 'results.json', report)
    write(OUT / ('piece_results.json' if args.piece else 'results.json'), report)
    print('OPENCODE_WORLD_HELD_V2', report['status'], report.get('error', ''), flush=True)
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
