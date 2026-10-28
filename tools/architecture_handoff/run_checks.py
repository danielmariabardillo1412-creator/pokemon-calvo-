"""Sequential Godot regressions for the isolated copy; failures never become PASS."""
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
import guard

ROOT = guard.ROOT
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
GROUPS = [
    ('field_native', 'field_native_test_runner.gd', []),
    ('map_runtime', 'map_runtime_test_runner.gd', ['--', '--legacy-field']),
    ('visual_legacy', 'visual_field_test_runner.gd', ['--', '--legacy-field']),
    ('field_items', 'item_field_effects_v4.gd', []),
    ('item_connections', 'item_connections_test_runner.gd', []),
    ('medicine', 'showdown_medicine_test_runner.gd', []),
    ('savegame', 'savegame_v2_test_runner.gd', []),
    ('save_adversarial', 'savegame_v2_adversarial_test_runner.gd', []),
    ('item_policy', 'item_selection_policy_test_runner.gd', []),
    ('inventory_capture', 'item_existing_groups_v2.gd', []),
]


def command(args, logfile):
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO(); startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    start = time.monotonic()
    with logfile.open('w', encoding='utf-8') as f:
        p = subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT,
                           timeout=360, startupinfo=startup)
    text = logfile.read_text(encoding='utf-8-sig', errors='replace')
    passed = p.returncode == 0 and 'SCRIPT ERROR' not in text and 'ERROR:' not in text
    return {'status': 'PASS' if passed else 'FAIL', 'exit_code': p.returncode,
            'seconds': round(time.monotonic() - start, 2), 'command': args,
            'last_line': text.strip().splitlines()[-1] if text.strip() else '',
            'log': logfile.relative_to(ROOT).as_posix()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--phase', choices=['baseline', 'T001', 'T002'], required=True)
    parser.add_argument('--quick', action='store_true')
    args = parser.parse_args(); guard.check_root()
    out = ROOT / 'docs/kilo/evidence' / args.phase; out.mkdir(parents=True, exist_ok=True)
    results = []
    try:
        guard_before = guard.verify()
        if args.phase != 'baseline':
            imported = command([GODOT, '--headless', '--path', '.', '--editor', '--import', '--quit'], out / 'import.log')
            assert imported['status'] == 'PASS', 'Import failed; see phase import.log'
        groups = [g for g in GROUPS if g[0] in ['field_native', 'field_items', 'item_connections']] if args.quick else GROUPS
        if args.phase != 'baseline':
            assert (ROOT / 'tests/gameplay/field_hud_contract_test_runner.gd').exists(), 'Missing HUD contract test'
            groups = [('hud_contract', 'field_hud_contract_test_runner.gd', [])] + groups
        for name, script, extra in groups:
            print('ARCHITECTURE_CHECK', args.phase, name, flush=True)
            result = command([GODOT, '--headless', '--path', '.', '--script', 'tests/gameplay/' + script] + extra, out / (name + '.log'))
            result['group'] = name; results.append(result)
            print(result['status'], result['last_line'], flush=True)
            if result['status'] != 'PASS': break
        if not args.quick and len(results) == len(groups) and all(r['status'] == 'PASS' for r in results):
            print('ARCHITECTURE_CHECK', args.phase, 'field_items_gpu', flush=True)
            result = command([GODOT, '--path', '.', '--resolution', '1280x720', '--script',
                              'tests/gameplay/item_field_effects_v4.gd', '--', '--capture'], out / 'field_items_gpu.log')
            result['group'] = 'field_items_gpu'; results.append(result)
            groups = groups + [('field_items_gpu', '', [])]
            if result['status'] == 'PASS':
                shutil.copyfile(ROOT / '.godot/item_field_v4/field_medicine_bag.png', out / 'field_items_gpu.png')
            print(result['status'], result['last_line'], flush=True)
        guard_after = guard.verify()
        good = len(results) == len(groups) and all(r['status'] == 'PASS' for r in results)
        report = {'status': 'PASS' if good else 'FAIL', 'phase': args.phase, 'quick': args.quick,
                  'groups': results, 'guard_before': guard_before, 'guard_after': guard_after}
    except Exception as e:
        report = {'status': 'FAIL', 'phase': args.phase, 'quick': args.quick, 'groups': results, 'error': str(e)}
    (out / 'results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('ARCHITECTURE_RESULT', report['status'], flush=True)
    sys.exit(0 if report['status'] == 'PASS' else 1)


if __name__ == '__main__':
    main()
