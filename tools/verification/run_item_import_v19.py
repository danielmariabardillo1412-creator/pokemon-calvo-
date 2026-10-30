"""Pinned declarative item import and field transaction batch pilot."""
from pathlib import Path
import argparse, subprocess, sys, time
from local_phase import LocalPhase, write, sha, exclusive_lock

ROOT = Path(__file__).resolve().parents[2]
BASE = '0a139088'
OUT = ROOT / '.godot/item_import_v19_validation'
ALLOWED = {'AGENTS.md', 'docs/current/START_HERE.md', 'docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md', 'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_IMPORT_V19.md', 'docs/current/ITEM_IMPORT_V19.json',
 'docs/current/ITEM_IMPORT_V19_AUDIT.json',
 'modules/inventory/imported_recovery_v19.json',
 'modules/inventory/field_item_effects.gd', 'modules/inventory/field_item_service.gd',
 'scenes/visual/field_item_bag.gd',
 'tools/item_import/import_recovery.py', 'tests/tools/test_item_import_v19.py',
 'tests/gameplay/item_import_v19.gd', 'tests/gameplay/item_import_v19.gd.uid',
 'tools/verification/run_item_import_v19.py'}

def main():
    p = argparse.ArgumentParser(); p.add_argument('--prepare', action='store_true'); p.add_argument('--piece', action='store_true'); args = p.parse_args()
    phase = LocalPhase(ROOT, BASE, OUT, ALLOWED)
    with exclusive_lock(ROOT, OUT):
        if args.prepare: print(phase.prepare(), flush=True); return 0
        dest = OUT / 'runs' / str(time.time_ns()); dest.mkdir(parents=True)
        report = {'status': 'RUNNING', 'base': BASE, 'groups': []}
        try:
            report['integrity_before'] = phase.verify()
            for name, command in [('compiler', [sys.executable, 'tests/tools/test_item_import_v19.py']),
                                  ('regeneration', [sys.executable, 'tools/item_import/import_recovery.py', '--check'])]:
                result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=90)
                log = dest / (name + '.log'); log.write_text(result.stdout + result.stderr, encoding='utf-8')
                row = {'group': name, 'status': 'PASS' if result.returncode == 0 else 'FAIL', 'exit_code': result.returncode, 'log': str(log)}
                report['groups'].append(row); write(dest/'results.json', report)
                print(name, row['status'], flush=True); assert result.returncode == 0, name
            groups = [('import', 'IMPORT'), ('batch', 'tests/gameplay/item_import_v19.gd')]
            if not args.piece:
                groups += [('medicine_field', 'tests/gameplay/item_field_effects_v4.gd'),
                 ('recovery', 'tests/gameplay/item_field_recovery_v5.gd'),
                 ('training', 'tests/gameplay/item_field_training_v7.gd'),
                 ('native_medicine', 'tests/gameplay/showdown_medicine_test_runner.gd'),
                 ('native', 'tests/gameplay/field_native_test_runner.gd'),
                 ('restore', 'tests/gameplay/field_restore_integration_test_runner.gd')]
            for name, script in groups:
                result = phase.run_godot(name, script, dest)
                report['groups'].append(result); write(dest/'results.json', report)
                assert result['status'] == 'PASS', name
            if not args.piece:
                result = phase.run_godot('batch_gpu', 'tests/gameplay/item_import_v19.gd', dest, gpu=True, args=['--capture'])
                report['groups'].append(result); assert result['status'] == 'PASS', 'GPU'
            report['integrity_after'] = phase.verify(not args.piece)
            report['tested_sources_sha256'] = {f: sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/', 'tests/', 'tools/'))}
            report['status'] = 'PASS'
        except Exception as error: report['status'] = 'FAIL'; report['error'] = str(error)
        write(dest/'results.json', report); write(OUT/('piece_results.json' if args.piece else 'results.json'), report)
        print('ITEM_IMPORT_V19', report['status'], report.get('error', ''), flush=True)
        return 0 if report['status'] == 'PASS' else 1

if __name__ == '__main__': raise SystemExit(main())
