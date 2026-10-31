"""Batch reviewed non-passive held metadata, native semantics and real field UI."""
from pathlib import Path
import argparse, subprocess, sys, time
from local_phase import LocalPhase, read, write, sha, exclusive_lock
from run_field_held_v16 import probe

ROOT=Path(__file__).resolve().parents[2]
BASE='aeb2c8b1'
OUT=ROOT/'.godot/field_held_v20'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_FIELD_HELD_V20.md','docs/current/ITEM_FIELD_HELD_V20.json',
 'modules/battle/backends/showdown/field_held_items.cjs',
 'modules/battle/backends/showdown/field_misc_items_v20.json',
 'tools/item_import/import_held_v20.py','tests/tools/test_held_import_v20.py',
 'tools/showdown_engine_probe/held_item_contract.cjs','tools/showdown_engine_probe/held_item_reference_rows.cjs',
 'tools/showdown_engine_probe/field_held_v16.cjs','tools/showdown_engine_probe/field_held_v17.cjs',
 'tools/showdown_engine_probe/field_held_v18.cjs','tools/showdown_engine_probe/field_held_v20.cjs',
 'tests/gameplay/field_held_v20.gd','tests/gameplay/field_held_v20.gd.uid',
 'tools/verification/run_field_held_v20.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            for name,command in [('compiler',[sys.executable,'tests/tools/test_held_import_v20.py']),
             ('regeneration',[sys.executable,'tools/item_import/import_held_v20.py','--check'])]:
                result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,timeout=90)
                log=dest/(name+'.log');log.write_text(result.stdout+result.stderr,encoding='utf-8')
                row={'group':name,'status':'PASS' if result.returncode==0 else 'FAIL','exit_code':result.returncode,'log':str(log)}
                report['groups'].append(row);write(dest/'results.json',report)
                print(name,row['status'],flush=True);assert result.returncode==0,name
            for name,script,source in [('native_misc','tools/showdown_engine_probe/field_held_v20.cjs',OUT/'node.json'),
                ('native_previous','tools/showdown_engine_probe/field_held_v18.cjs',ROOT/'.godot/progression_items_v18/node.json')]:
                result=probe(dest,name,script,source);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            groups=[('import','IMPORT'),('misc','tests/gameplay/field_held_v20.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('recovery_import','tests/gameplay/item_import_v19.gd'),
                ('native','tests/gameplay/field_native_test_runner.gd'),('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('misc_gpu','tests/gameplay/field_held_v20.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
            report['integrity_after']=phase.verify(not args.piece)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('FIELD_HELD_V20',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
