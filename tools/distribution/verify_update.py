"""Portable pre-publication regression gate; historical local seals stay immutable."""
from pathlib import Path
from contextlib import nullcontext
import argparse
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/regression_comparator'))
from runner import classify_log, expected_negative_diagnostic
from run_lock import exclusive_lock

SCRIPTS = [
    'tests/test_runner.gd',
    'tests/gameplay/field_hud_render_test_runner.gd',
    'tests/gameplay/field_diagnostics_test_runner.gd',
    'tests/gameplay/field_diagnostics_integration_test_runner.gd',
    'tests/gameplay/field_api_test_runner.gd',
    'tests/gameplay/field_api_integration_test_runner.gd',
    'tests/gameplay/field_bridge_world_test_runner.gd',
    'tests/gameplay/field_bridge_runtime_test_runner.gd',
    'tests/gameplay/field_restore_contract_test_runner.gd',
    'tests/gameplay/field_restore_integration_test_runner.gd',
    'tests/gameplay/field_native_test_runner.gd',
    'tests/gameplay/trade_item_restoration_v27.gd',
    'tests/gameplay/item_selection_policy_test_runner.gd',
    'tests/gameplay/item_connections_test_runner.gd',
    'tests/gameplay/opencode_battle_support_v2.gd',
    'tests/gameplay/opencode_world_held_v2.gd',
    'tests/gameplay/savegame_v2_test_runner.gd',
]


def prepare_output_dirs(script, seen=None):
    seen = set() if seen is None else seen
    if script in seen: return
    seen.add(script)
    text = (ROOT / script).read_text(encoding='utf-8-sig')
    for relative in re.findall(r'"res://(\.godot/[^"\n]+/)"', text):
        path = (ROOT / relative).resolve()
        if not path.is_relative_to((ROOT / '.godot').resolve()): raise ValueError(relative)
        path.mkdir(parents=True, exist_ok=True)
    parent = re.search(r'^extends\s+"res://([^"\n]+)"', text, re.M)
    if parent: prepare_output_dirs(parent[1], seen)


def execute(name, command, out, script='', no_checks=False):
    log = out / (name + '.log')
    start = time.monotonic()
    timed_out = False
    with log.open('w', encoding='utf-8') as output:
        kwargs = {'creationflags': subprocess.CREATE_NO_WINDOW} if os.name == 'nt' else {'start_new_session': True}
        process = subprocess.Popen(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, **kwargs)
        while process.poll() is None:
            try: process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                timed_out = time.monotonic() - start >= 480
                if timed_out or b'SCRIPT ERROR' in log.read_bytes()[-65536:]:
                    if os.name == 'nt':
                        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    else: os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                    break
    text, expected = expected_negative_diagnostic(log.read_text(encoding='utf-8', errors='replace'), {'script': script})
    result = classify_log(text, process.returncode, timed_out)
    if no_checks and result['status'] == 'INCONCLUSIVE_NO_ASSERTION_COUNT': result['status'] = 'PASS'
    if name == 'resource_installer':
        count = re.search(r'Ran (\d+) tests? in', text)
        result['checks_reported'] = int(count[1]) if count else 0
        if not count or int(count[1]) <= 0 or not re.search(r'^OK$', text, re.M): result['status'] = 'FAIL'
    if name.startswith('native_'):
        data = json.loads(text)
        if not isinstance(data.get('checks'), int) or data['checks'] <= 0 or data.get('failed') != 0:
            result['status'] = 'FAIL'
    result.update(name=name, exit_code=process.returncode, seconds=round(time.monotonic()-start, 2),
                  log=log.relative_to(ROOT).as_posix(), expected_negative_diagnostics=expected)
    print(name, result['status'], 'checks=' + str(result['checks_reported']), flush=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=shutil.which('godot') or 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe')
    parser.add_argument('--node', default=shutil.which('node') or 'D:/Herramientas/NodeJS/node.exe')
    parser.add_argument('--gpu', action='store_true', help='Also run the existing real bag/GPU integration suite')
    args = parser.parse_args()
    os.environ['POKEMON_CALVO_NODE'] = str(Path(args.node).resolve())
    out = ROOT / '.godot/publication_v27/runs' / str(time.time_ns())
    out.mkdir(parents=True)
    report = {'status': 'RUNNING', 'scope': 'Pre-publication regressions; not all game mechanics or all item contexts', 'groups': []}
    with (exclusive_lock(ROOT, out) if os.name == 'nt' else nullcontext()):
        try:
            commands = [('resource_installer', [sys.executable, '-B', 'tests/tools/test_restore_resources_v27.py'], '', True),
                        ('import', [args.godot, '--headless', '--path', str(ROOT), '--editor', '--import', '--quit'], '', True)]
            for name in ['opencode_battle_support_v2', 'opencode_world_held_v2']:
                commands.append(('native_' + name, [args.node, 'tools/showdown_engine_probe/' + name + '.cjs'], '', False))
            for script in SCRIPTS:
                prepare_output_dirs(script)
                commands.append((Path(script).stem, [args.godot, '--headless', '--path', str(ROOT), '--script', 'res://' + script], script, False))
            if args.gpu:
                script = 'tests/gameplay/item_field_effects_v4.gd'
                prepare_output_dirs(script)
                commands.append(('field_items_gpu', [args.godot, '--path', str(ROOT), '--resolution', '1280x720', '--script', 'res://' + script, '--', '--capture'], script, False))
            for name, command, script, no_checks in commands:
                result = execute(name, command, out, script, no_checks)
                report['groups'].append(result)
                (out / 'results.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
                if result['status'] != 'PASS': raise RuntimeError(name)
            report['status'] = 'PASS'
        except Exception as error:
            report.update(status='FAIL', error=str(error))
        (out / 'results.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
        print('PUBLICATION_V27', report['status'], out, flush=True)
        return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__': raise SystemExit(main())
