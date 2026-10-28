"""Item census, real held-item pilot and focused regressions. No data regeneration."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/item_audit_v1'
NODE = 'D:/Herramientas/NodeJS/node.exe'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'


def run(args, name, expected_parse_error=False):
    print('ITEM_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as f:
        result = subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT, timeout=360)
    text = (OUT / name).read_text(encoding='utf-8-sig')
    errors = [s for s in text.splitlines() if s.startswith('ERROR:') and not
              (expected_parse_error and s.startswith('ERROR: Parse JSON failed. Error at line 0: Expected key'))]
    if result.returncode or 'SCRIPT ERROR' in text or errors: raise RuntimeError(f'{name}: {result.returncode}; {errors[:2]}')
    print(text.splitlines()[-1] if text.splitlines() else 'OK', flush=True)


def gd(source, name, **kwargs):
    run([GODOT, '--headless', '--path', str(ROOT), '--script', source], name, **kwargs)


def main():
    OUT.mkdir(exist_ok=True)
    if '--regressions-only' not in sys.argv:
        gd('tests/gameplay/item_inventory_export.gd', 'export.log')
        run([NODE, 'tools/item_audit/native_inventory.cjs'], 'native_inventory.log')
        run([NODE, 'tools/item_audit/held_pilot.cjs'], 'held_native.log')
        gd('tests/gameplay/item_held_pilot_test_runner.gd', 'held_godot.log')
        gd('tests/gameplay/item_selection_policy_test_runner.gd', 'selection_policy.log')
        run([sys.executable, 'tools/item_audit/build_inventory.py'], 'inventory.log')
    for source, log in [('tests/gameplay/unified_profile_test_runner.gd', 'regression_unified.log'),
                        ('tests/gameplay/field_native_test_runner.gd', 'regression_field.log'),
                        ('tests/gameplay/showdown_move_repair_test_runner.gd', 'regression_repair.log'),
                        ('tests/gameplay/showdown_adventure_test_runner.gd', 'regression_adventure.log'),
                        ('tests/gameplay/showdown_medicine_test_runner.gd', 'regression_medicine.log'),
                        ('tests/gameplay/savegame_v2_test_runner.gd', 'regression_save.log'),
                        ('tests/gameplay/savegame_v2_adversarial_test_runner.gd', 'regression_save_adversarial.log')]:
        gd(source, log)
    gd('tests/test_runner.gd', 'regression_core.log', expected_parse_error=True)
    run([sys.executable, 'tools/item_audit/verify.py'], 'verify.log')
    print('ITEM_AUDIT_COMPLETE', flush=True)


if __name__ == '__main__': main()
