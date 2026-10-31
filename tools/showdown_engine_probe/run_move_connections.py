"""Reproduce catalogue + targeted contexts + live/GPU repair regressions."""
import json
from pathlib import Path
import shutil
import subprocess
import sys

from audit_moves import protected

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/showdown_move_repair_checks'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
NODE = 'D:/Herramientas/NodeJS/node.exe'


def run(args, log):
    print('MOVE_CONNECTIONS_STAGE', log.name, flush=True)
    with log.open('w', encoding='utf-8') as file:
        result = subprocess.run(args, cwd=ROOT, stdout=file, stderr=subprocess.STDOUT, timeout=900)
    text = log.read_text(encoding='utf-8-sig')
    if result.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise RuntimeError(f'{log} failed (exit {result.returncode})')
    print(text.splitlines()[-1][:300] if text.splitlines() else 'OK', flush=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if not (OUT / 'before.json').exists():
        (OUT / 'before.json').write_text(json.dumps(protected(), indent=2), encoding='utf-8')
    context = ROOT / '.godot/showdown_context_checks'; context.mkdir(parents=True, exist_ok=True)
    run([sys.executable, 'tools/showdown_engine_probe/audit_moves.py'], OUT / 'broad.log')
    run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tools/showdown_engine_probe/move_audit.gd', '--', '--contexts', '--export'], context / 'export.log')
    run([NODE, 'tools/showdown_engine_probe/context_cases.cjs'], context / 'native.log')
    run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tools/showdown_engine_probe/move_audit.gd', '--', '--contexts'], context / 'godot.log')
    tests = [
        ('tests/gameplay/showdown_move_repair_test_runner.gd', 'gameplay.log', True, []),
        ('tests/gameplay/showdown_move_repair_visual_test_runner.gd', 'visual.log', False, []),
        ('tests/battle/showdown_backend_test_runner.gd', 'backend.log', False, ['--', '--capture']),
        ('tests/gameplay/showdown_adventure_test_runner.gd', 'adventure.log', True, []),
        ('tests/gameplay/showdown_medicine_test_runner.gd', 'medicines.log', True, []),
        ('tests/gameplay/showdown_medicine_visual_test_runner.gd', 'medicine_visual.log', False, []),
        ('tests/visual/battle_animation_playback_test_runner.gd', 'playback.log', True, []),
    ]
    for source, log, headless, extra in tests:
        run([GODOT, *(['--headless'] if headless else []), '--path', str(ROOT), '--script', source, *extra], OUT / log)
        if log == 'backend.log': shutil.copyfile(ROOT / '.godot/showdown_backend_checks/gpu.json', OUT / 'backend.json')
    for source in ['medicine_tests.cjs', 'transaction_tests.cjs', 'adventure_transaction_tests.cjs']:
        run([NODE, 'tools/showdown_engine_probe/' + source], OUT / (source + '.log'))
    for source in ['verify_move_audit.py', 'verify_move_connections.py']:
        run([sys.executable, 'tools/showdown_engine_probe/' + source], OUT / (source + '.log'))
    print('MOVE_CONNECTIONS_RUN_COMPLETE', flush=True)


if __name__ == '__main__':
    main()
