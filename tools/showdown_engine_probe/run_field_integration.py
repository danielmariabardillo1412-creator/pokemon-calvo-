"""Real map/native campaign checkpoints plus persistence and combat regressions."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/field_native_checks'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
NODE = 'D:/Herramientas/NodeJS/node.exe'


def run(args, name, expected_parse_error=False):
    print('FIELD_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as f:
        result = subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT, timeout=300)
    text = (OUT / name).read_text(encoding='utf-8-sig')
    unexpected = [line for line in text.splitlines() if line.startswith('ERROR:') and not
                  (expected_parse_error and line.startswith('ERROR: Parse JSON failed. Error at line 0: Expected key'))]
    if result.returncode or 'SCRIPT ERROR' in text or unexpected:
        raise RuntimeError(f'{name}: exit {result.returncode}; {unexpected[:2]}')
    print(text.splitlines()[-1][:220] if text.splitlines() else 'OK', flush=True)


def godot(source, name, gpu=False, extra=(), **kwargs):
    run([GODOT, *([] if gpu else ['--headless']), '--path', str(ROOT), '--script', source, *extra], name, **kwargs)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    run([NODE, 'tools/showdown_engine_probe/field_clock_tests.cjs'], 'native_clocks.log')
    godot('tests/gameplay/field_native_test_runner.gd', 'gameplay.log')
    godot('tests/gameplay/field_native_test_runner.gd', 'gpu.log', gpu=True)
    for source, name in [('tests/gameplay/savegame_v2_test_runner.gd', 'save_v2.log'),
                         ('tests/gameplay/savegame_v2_adversarial_test_runner.gd', 'save_adversarial.log'),
                         ('tests/gameplay/showdown_move_repair_test_runner.gd', 'repair.log'),
                         ('tests/gameplay/showdown_adventure_test_runner.gd', 'adventure.log'),
                         ('tests/gameplay/showdown_medicine_test_runner.gd', 'medicines.log')]:
        godot(source, name)
    godot('tests/test_runner.gd', 'core.log', expected_parse_error=True)
    godot('tests/gameplay/visual_field_test_runner.gd', 'legacy_visual.log', extra=['--', '--legacy-field'])
    godot('tests/gameplay/map_runtime_test_runner.gd', 'map_runtime.log', extra=['--', '--legacy-field'])
    for source in ['medicine_tests.cjs', 'transaction_tests.cjs', 'adventure_transaction_tests.cjs']:
        run([NODE, 'tools/showdown_engine_probe/' + source], source + '.log')
    run([sys.executable, 'tools/showdown_engine_probe/verify_field_integration.py'], 'verify.log')
    print('FIELD_INTEGRATION_COMPLETE', flush=True)


if __name__ == '__main__':
    main()
