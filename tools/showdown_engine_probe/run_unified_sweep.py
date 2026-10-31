"""Reuses prepared fixtures in independent output folders; no dataset imports."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/unified_profile_checks'
NODE = 'D:/Herramientas/NodeJS/node.exe'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
SINGLE = 'gen9calvounifiedv1'
DOUBLE = 'gen9calvounifieddoublesv1'


def run(args, name, env=None):
    print('UNIFIED_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as f:
        p = subprocess.run(args, cwd=ROOT, env=env, stdout=f, stderr=subprocess.STDOUT, timeout=900)
    text = (OUT / name).read_text(encoding='utf-8-sig')
    if p.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise RuntimeError(f'{name}: exit {p.returncode}; inspect log')
    print(text.splitlines()[-1][:220] if text.splitlines() else 'OK', flush=True)


def main():
    OUT.mkdir(exist_ok=True)
    run([NODE, 'tools/showdown_engine_probe/unified_profile_tests.cjs'], 'contracts.log')
    for kind, source, generator in [
            ('general', 'move_functional_audit', 'move_audit.cjs'),
            ('contexts', 'showdown_context_checks', 'context_cases.cjs'),
            ('z', 'showdown_z_checks', 'z_move_cases.cjs'),
            ('doubles', 'native_doubles_checks', 'doubles_cases.cjs')]:
        target = OUT / kind
        target.mkdir(exist_ok=True)
        shutil.copyfile(ROOT / '.godot' / source / 'prototypes.json', target / 'prototypes.json')
        env = dict(os.environ, CALVO_AUDIT_OUT=str(target), CALVO_AUDIT_FORMAT=SINGLE,
                   CALVO_AUDIT_MAX_FORMAT=SINGLE, CALVO_DOUBLES_FORMAT=DOUBLE)
        run([NODE, 'tools/showdown_engine_probe/' + generator], kind + '_native.log', env)
        if kind in ['general', 'contexts']:
            run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tools/showdown_engine_probe/move_audit.gd'], kind + '_godot.log', env)
    print('UNIFIED_SWEEP_NATIVE_COMPLETE', flush=True)

    if '--sweep-only' in sys.argv:
        return
    run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tests/gameplay/unified_profile_test_runner.gd'], 'live.log')
    run([GODOT, '--path', str(ROOT), '--script', 'tests/gameplay/unified_profile_test_runner.gd'], 'gpu.log')
    env = dict(os.environ, CALVO_DOUBLES_UI_OUT=str(OUT / 'doubles_ui'))
    run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tests/gameplay/native_doubles_visual_test_runner.gd'], 'doubles_ui.log', env)
    import run_doubles_integration as regressions
    regressions.OUT = OUT / 'regressions'
    regressions.OUT.mkdir(exist_ok=True)
    previous = sys.argv
    try:
        sys.argv = ['run_doubles_integration.py', '--regressions-only']
        regressions.main()
    finally:
        sys.argv = previous
    print('UNIFIED_CHECKS_COMPLETE: review GPU captures, then run verify_unified_sweep.py', flush=True)


if __name__ == '__main__':
    main()
