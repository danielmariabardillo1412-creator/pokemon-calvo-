"""V23: encounter items enter native battles; independent scope from closed V2."""
from pathlib import Path
import argparse, json, subprocess, sys, time
from local_phase import LocalPhase, read, write, sha, exclusive_lock

ROOT = Path(__file__).resolve().parents[2]
BASE = '2fee506c7f309c966efc2a348a13aaf6018b8415'
OUT = ROOT / '.godot/encounter_held_v23'
ALLOWED = {
    'AGENTS.md', 'docs/current/START_HERE.md', 'docs/current/NEXT_STEPS.md',
    'docs/current/PROJECT_STATE.md', 'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
    'docs/current/ITEM_ENCOUNTER_HELD_V23.md', 'docs/current/ITEM_ENCOUNTER_HELD_V23.json',
    'modules/battle/backends/showdown/field_held_items.cjs',
    'modules/battle/backends/showdown/field_encounter_items_v23.json',
    'tools/item_import/import_encounter_held_v23.py',
    'tests/tools/test_encounter_held_v23.py',
    'tools/showdown_engine_probe/encounter_held_v23.cjs',
    'tests/gameplay/encounter_held_v23.gd', 'tests/gameplay/encounter_held_v23.gd.uid',
    'tools/verification/run_encounter_held_v23.py',
}


def process(dest, name, command, json_output=False, marker=None):
    log = dest / (name + '.log')
    assert not log.exists()
    started = time.monotonic()
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=120)
    log.write_text(result.stdout + result.stderr, encoding='utf-8')
    passed = result.returncode == 0
    checks = 0
    if json_output and passed:
        payload = json.loads(result.stdout)
        checks = payload['checks']
        passed = checks > 0 and payload['failed'] == 0
    elif marker:
        passed = passed and marker in result.stdout
        checks = sum(line.startswith('PASS:') for line in result.stdout.splitlines())
        if checks == 0 and passed: checks = 1
    row = {'group':name, 'status':'PASS' if passed else 'FAIL',
           'exit_code':result.returncode, 'checks_reported':checks,
           'seconds':round(time.monotonic()-started, 2), 'command':command,
           'log':str(log), 'log_sha256':sha(log)}
    print(name, row['status'], 'checks='+str(checks), flush=True)
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--piece', action='store_true')
    parser.add_argument('--guard-only', action='store_true')
    args = parser.parse_args()
    phase = LocalPhase(ROOT, BASE, OUT, ALLOWED)
    with exclusive_lock(ROOT, OUT):
        if args.prepare:
            print(phase.prepare(), flush=True)
            return 0
        if args.guard_only:
            print(json.dumps(phase.verify(True)), flush=True)
            return 0
        dest = OUT / 'runs' / str(time.time_ns()); dest.mkdir(parents=True)
        report = {'status':'RUNNING', 'base':BASE, 'groups':[]}
        try:
            report['integrity_before'] = phase.verify()
            commands = [
                ('import_tests', [sys.executable, 'tests/tools/test_encounter_held_v23.py'], False, 'All encounter-held import tests passed'),
                ('import_check', [sys.executable, 'tools/item_import/import_encounter_held_v23.py', '--check'], False, 'ENCOUNTER_HELD_IMPORT PASS'),
                ('native', ['D:/Herramientas/NodeJS/node.exe', 'tools/showdown_engine_probe/encounter_held_v23.cjs'], True, None),
            ]
            for name, command, json_output, marker in commands:
                result = process(dest, name, command, json_output, marker)
                report['groups'].append(result); write(dest/'results.json', report)
                assert result['status'] == 'PASS', name
            groups = [('handoff', 'tests/gameplay/encounter_held_v23.gd')]
            if not args.piece:
                groups += [
                    ('world_regression', 'tests/gameplay/opencode_world_held_v2.gd'),
                    ('native_field', 'tests/gameplay/field_native_test_runner.gd'),
                    ('restore', 'tests/gameplay/field_restore_integration_test_runner.gd'),
                    ('support_regression', 'tests/gameplay/opencode_battle_support_v2.gd'),
                ]
            for name, script in groups:
                result = phase.run_godot(name, script, dest)
                report['groups'].append(result); write(dest/'results.json', report)
                assert result['status']=='PASS' and result['checks_reported']>0, name
            if not args.piece:
                result = phase.run_godot('handoff_gpu', 'tests/gameplay/encounter_held_v23.gd', dest, gpu=True, args=['--capture'])
                report['groups'].append(result); write(dest/'results.json', report)
                assert result['status']=='PASS' and result['checks_reported']>0, 'GPU'
            report['tested_sources_sha256'] = {p:sha(ROOT/p) for p in sorted(ALLOWED)
                if p.startswith(('modules/','tools/','tests/')) and (ROOT/p).is_file()}
            report['integrity_after'] = phase.verify(not args.piece)
            report['status'] = 'PASS'
        except Exception as error:
            report['status'] = 'FAIL'; report['error'] = str(error)
        write(dest/'results.json', report)
        write(OUT/('piece_results.json' if args.piece else 'results.json'), report)
        print('ENCOUNTER_HELD_V23', report['status'], report.get('error',''), flush=True)
        return 0 if report['status']=='PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
