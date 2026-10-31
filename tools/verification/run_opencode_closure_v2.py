"""O190 joint closure gate: real processes, per-run logs, counts and full guards.

This runner orchestrates the O110 and O120 family gates, the O100 audit, the
affected encounter/save regressions and the graphical samples. It reuses
LocalPhase.run_godot, keeps one log per execution, never treats exit 0 without
checks as PASS, and computes the mission guard with --full before and after.
"""
from pathlib import Path
import argparse, json, re, shutil, struct, subprocess, sys, time
from local_phase import LocalPhase, sha, write

ROOT = Path(__file__).resolve().parents[2]
MISSION_BASE = '78c3b0f7d6ccfbe8f26f75070d9737ccdaa90035'
OUT = ROOT / '.godot/opencode_items_v2/closure'
GUARD = 'tools/verification/opencode_items_v2_guard.py'
SUPPORT_OUT = ROOT / '.godot/opencode_items_v2/support'
WORLD_OUT = ROOT / '.godot/opencode_items_v2/world_held'
CAPTURES = (
    ROOT / '.godot/opencode_battle_support_v2/battle_support_bag.png',
    ROOT / '.godot/opencode_world_held_v2/smoke_ball_bag.png',
    ROOT / '.godot/opencode_world_held_v2/smoke_ball_equipped.png',
)


def run_process(command, log_path, timeout=900, markers=()):
    log_path.parent.mkdir(parents=True, exist_ok=True)
    assert not log_path.exists(), 'Never overwrite execution evidence: ' + str(log_path)
    start = time.monotonic()
    try:
        completed = subprocess.run([str(part) for part in command], cwd=ROOT,
                                   capture_output=True, text=True, timeout=timeout)
        output = completed.stdout + completed.stderr
        log_path.write_text(output, encoding='utf-8')
        markers_found = [marker for marker in markers if marker in output]
        checks = len(re.findall(r'(?m)^PASS(?:\s|:)', output))
        status = 'PASS' if completed.returncode == 0 and len(markers_found) == len(markers) else 'FAIL'
        return {'status': status, 'exit_code': completed.returncode,
                'seconds': round(time.monotonic() - start, 2),
                'command': [str(part) for part in command],
                'log': str(log_path), 'log_sha256': sha(log_path),
                'checks': checks, 'markers_found': markers_found}
    except subprocess.TimeoutExpired:
        log_path.write_text('TIMEOUT after %ss' % timeout, encoding='utf-8')
        return {'status': 'FAIL', 'exit_code': -1, 'seconds': timeout, 'error': 'timeout',
                'command': [str(part) for part in command],
                'log': str(log_path), 'log_sha256': sha(log_path),
                'checks': 0, 'markers_found': []}


def mission_guard(dest, label):
    result = run_process([sys.executable, GUARD, '--full'],
                         dest / (label + '.json.log'), timeout=1800)
    text = Path(result['log']).read_text(encoding='utf-8')
    payload = None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('{'):
            payload = json.loads(line)
    if payload is None:
        raise AssertionError('guard produced no JSON: ' + result['log'])
    result['report'] = payload
    result['checks'] = 1 if int(payload.get('protected_files', 0)) > 0 else 0
    if payload.get('status') != 'PASS' or payload.get('mode') != 'FULL_CONTENT_HASHES':
        raise AssertionError('full mission guard failed: ' + json.dumps(payload))
    return result


def archive_captures(dest):
    preserved = []
    folder = dest / 'preserved_captures'
    for path in CAPTURES:
        if not path.is_file():
            continue
        folder.mkdir(parents=True, exist_ok=True)
        target = folder / (path.stem + '_' + sha(path)[:12] + path.suffix)
        assert not target.exists(), target
        shutil.copy2(path, target)
        preserved.append({'source': str(path), 'source_sha256': sha(path),
                          'preserved': str(target), 'preserved_sha256': sha(target),
                          'bytes': target.stat().st_size})
    return preserved


def png_info(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', str(path)
    width, height = struct.unpack('>II', data[16:24])
    return {'path': str(path), 'sha256': sha(path), 'bytes': len(data),
            'width': width, 'height': height}


def inspect_captures():
    result = []
    for path in CAPTURES:
        if not path.is_file():
            raise AssertionError('missing GPU capture: ' + str(path))
        info = png_info(path)
        assert info['bytes'] > 10000, info
        result.append(info)
    return result


def family_run(family, command, root_results, marker, dest, timeout):
    log = dest / (family.lower() + '_family.log')
    result = run_process(command, log, timeout=timeout, markers=[marker])
    result['marker'] = marker
    if result['status'] != 'PASS':
        return result
    if not root_results.is_file():
        result['status'] = 'FAIL'
        result['error'] = 'missing family results: ' + str(root_results)
        return result
    nested = json.loads(root_results.read_text(encoding='utf-8'))
    result['results_path'] = str(root_results)
    result['results_sha256'] = sha(root_results)
    result['family_status'] = nested.get('status')
    result['groups'] = nested.get('groups', [])
    for group in result['groups']:
        if not group.get('group'):
            command = group.get('command') or []
            group['group'] = Path(command[-1]).name if command else 'unnamed'
    result['checks_total'] = sum(int(group.get('checks_reported', 0))
                                 for group in result['groups'])
    result['guard_before'] = nested.get('guard_before', {}).get('report')
    result['guard_after'] = nested.get('guard_after', {}).get('report')
    if nested.get('status') != 'PASS':
        result['status'] = 'FAIL'
        result['error'] = 'family results status: ' + str(nested.get('status'))
    elif not result['groups']:
        result['status'] = 'FAIL'
        result['error'] = 'family reported no groups'
    elif any(group.get('status') != 'PASS' for group in result['groups']):
        result['status'] = 'FAIL'
        result['error'] = 'family group failed'
    elif result['checks_total'] <= 0:
        result['status'] = 'FAIL'
        result['error'] = 'family reported no checks'
    return result


def godot_group(phase, name, script, dest, gpu=False, args=()):
    result = phase.run_godot(name, script, dest, gpu=gpu, args=args)
    if result['status'] == 'PASS' and int(result.get('checks_reported', 0)) <= 0:
        result['status'] = 'FAIL'
        result['error'] = 'exit 0 without checks'
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--skip-families', action='store_true',
                        help='debug only: skip the nested O110/O120 full gates')
    args = parser.parse_args()
    phase = LocalPhase(ROOT, MISSION_BASE, OUT, set())
    dest = OUT / 'runs' / str(time.time_ns())
    dest.mkdir(parents=True, exist_ok=True)
    report = {'status': 'RUNNING', 'family': 'O190', 'base': MISSION_BASE,
              'started_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
              'groups': [], 'families': {}, 'captures': []}
    try:
        report['git'] = {
            'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip(),
            'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            'status_porcelain': subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).splitlines(),
        }
        assert report['git']['head'] == MISSION_BASE or subprocess.run(
            ['git', 'merge-base', '--is-ancestor', MISSION_BASE, report['git']['head']],
            cwd=ROOT).returncode == 0, report['git']['head']
        report['preserved_captures'] = archive_captures(dest)

        report['guard_before'] = mission_guard(dest, 'guard_before')

        if not args.skip_families:
            report['families']['O110'] = family_run(
                'O110', [sys.executable, 'tools/verification/run_opencode_support_v2.py'],
                SUPPORT_OUT / 'results.json', 'OPENCODE_SUPPORT_V2 PASS',
                dest, timeout=3600)
            write(dest / 'results.json', report)
            assert report['families']['O110']['status'] == 'PASS', 'O110 family gate failed'
            report['families']['O120'] = family_run(
                'O120', [sys.executable, 'tools/verification/run_opencode_world_held_v2.py'],
                WORLD_OUT / 'results.json', 'OPENCODE_WORLD_HELD_V2 PASS',
                dest, timeout=2400)
            write(dest / 'results.json', report)
            assert report['families']['O120']['status'] == 'PASS', 'O120 family gate failed'

        audit_tests = run_process(
            [sys.executable, 'tests/tools/test_item_closure_audit_v2.py'],
            dest / 'audit_test.log', timeout=300,
            markers=['All item closure audit tests passed'])
        audit_tests['expected_checks'] = 10
        audit_tests['group'] = 'audit_test'
        if audit_tests['status'] == 'PASS' and audit_tests['checks'] < 10:
            audit_tests['status'] = 'FAIL'
            audit_tests['error'] = 'fewer than 10 audit assertions'
        report['groups'].append(audit_tests)
        write(dest / 'results.json', report)
        assert audit_tests['status'] == 'PASS', 'audit test failed'

        audit_check = run_process(
            [sys.executable, 'tools/item_import/audit_item_closure_v2.py', '--check'],
            dest / 'audit_check.log', timeout=300, markers=['COVERAGE_CHECK PASS'])
        audit_check['checks'] = 1 if audit_check['status'] == 'PASS' else 0
        audit_check['group'] = 'audit_check'
        report['groups'].append(audit_check)
        write(dest / 'results.json', report)
        assert audit_check['status'] == 'PASS', 'audit --check failed'

        godot_groups = [
            ('wild_encounter', 'tests/gameplay/wild_encounter_test_runner.gd'),
            ('savegame_v2', 'tests/gameplay/savegame_v2_test_runner.gd'),
            ('savegame_v2_adversarial', 'tests/gameplay/savegame_v2_adversarial_test_runner.gd'),
            ('restore_contract', 'tests/gameplay/field_restore_contract_test_runner.gd'),
        ]
        for name, script in godot_groups:
            result = godot_group(phase, name, script, dest)
            report['groups'].append(result)
            write(dest / 'results.json', report)
            assert result['status'] == 'PASS', name

        report['captures'] = inspect_captures()
        report['tested_sources_sha256'] = {
            path: sha(ROOT / path) for path in sorted([
                'docs/opencode/ITEM_CLOSURE_V2/COVERAGE.json',
                'docs/opencode/ITEM_CLOSURE_V2/COVERAGE.csv',
                'docs/opencode/ITEM_CLOSURE_V2/CONTRACT.json',
                'tests/tools/test_item_closure_audit_v2.py',
                'tools/item_import/audit_item_closure_v2.py',
                'tools/verification/run_opencode_closure_v2.py',
                'tools/verification/run_opencode_support_v2.py',
                'tools/verification/run_opencode_world_held_v2.py',
                'tools/verification/local_phase.py',
                'tools/verification/opencode_items_v2_guard.py',
                'modules/battle/backends/showdown/native_engine.cjs',
                'modules/battle/backends/showdown/native_bag_effects.cjs',
                'modules/battle/backends/showdown/field_held_items.cjs',
                'modules/battle/backends/showdown/field_world_items_v2.json',
                'modules/gameplay/encounter_item_modifiers.gd',
                'modules/gameplay/held_escape_items.gd',
                'modules/gameplay/showdown_adventure_session.gd',
                'modules/gameplay/wild_adventure_session.gd',
                'modules/inventory/battle_support_profile.gd',
                'modules/inventory/battle_support_profile.json',
                'scenes/visual/field_demo.gd',
                'scenes/visual/showdown_adventure_lab.gd',
                'tests/gameplay/opencode_battle_support_v2.gd',
                'tests/gameplay/opencode_world_held_v2.gd',
            ]) if (ROOT / path).is_file()
        }

        report['guard_after'] = mission_guard(dest, 'guard_after')
        report['finished_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        report['summary'] = {
            'closure_groups': len(report['groups']),
            'closure_groups_passed': sum(1 for group in report['groups'] if group['status'] == 'PASS'),
            'closure_checks': sum(int(group.get('checks', 0)) + int(group.get('checks_reported', 0))
                                  for group in report['groups']),
            'family_checks': sum(int(value.get('checks_total', 0))
                                 for value in report['families'].values()),
            'captures': len(report['captures']),
        }
        assert report['summary']['closure_checks'] > 0
        assert report['summary']['captures'] == len(CAPTURES)
        report['status'] = 'PASS'
    except Exception as error:  # noqa: BLE001 - the report records the real failure
        report['status'] = 'FAIL'
        report['error'] = str(error)
        report['finished_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    write(dest / 'results.json', report)
    write(OUT / 'results.json', report)
    print('OPENCODE_CLOSURE_V2', report['status'], report.get('error', ''), flush=True)
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
