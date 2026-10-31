"""Reproduce the Z decision, complete Z batches and connection regressions."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/showdown_z_checks'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
NODE = 'D:/Herramientas/NodeJS/node.exe'


def run(args, name):
    print('Z_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as stream:
        result = subprocess.run(args, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=300)
    text = (OUT / name).read_text(encoding='utf-8-sig')
    if result.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise RuntimeError(f'{name}: exit {result.returncode}; see {OUT / name}')
    print(text.splitlines()[-1][:200] if text.splitlines() else 'OK', flush=True)


def godot(source, log, gpu=False, extra=()):
    run([GODOT, *([] if gpu else ['--headless']), '--path', str(ROOT), '--script', source, *extra], log)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    run([NODE, 'tools/showdown_engine_probe/z_move_cases.cjs', '--catalog'], 'cases.log')
    godot('tests/gameplay/showdown_z_move_test_runner.gd', 'export.log', extra=['--', '--export'])
    run([NODE, 'tools/showdown_engine_probe/z_move_cases.cjs'], 'native.log')
    godot('tests/gameplay/showdown_z_move_test_runner.gd', 'gameplay.log')
    godot('tests/gameplay/showdown_z_visual_test_runner.gd', 'visual.log', gpu=True)
    for source, name, gpu in [
        ('tests/gameplay/randomlock_content_test_runner.gd', 'policy.log', False),
        ('tests/gameplay/showdown_move_repair_test_runner.gd', 'repair.log', False),
        ('tests/gameplay/showdown_move_repair_visual_test_runner.gd', 'repair_visual.log', True),
        ('tests/battle/showdown_backend_test_runner.gd', 'backend.log', True),
        ('tests/gameplay/showdown_adventure_test_runner.gd', 'adventure.log', False),
        ('tests/gameplay/showdown_medicine_test_runner.gd', 'medicines.log', False),
        ('tests/visual/battle_animation_playback_test_runner.gd', 'playback.log', False),
    ]:
        godot(source, name, gpu=gpu)
    for source in ['medicine_tests.cjs', 'transaction_tests.cjs', 'adventure_transaction_tests.cjs']:
        run([NODE, 'tools/showdown_engine_probe/' + source], source + '.log')
    godot('tools/visual/audit_randomlock_content.gd', 'content.log')
    run([sys.executable, 'tools/showdown_engine_probe/verify_z_moves.py'], 'verify.log')
    print('Z_RUN_COMPLETE', flush=True)


if __name__ == '__main__':
    main()
