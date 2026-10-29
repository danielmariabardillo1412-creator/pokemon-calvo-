"""Reviewed training/boost item metadata; shared native contracts, frozen scope."""
from pathlib import Path
import argparse,time
from local_phase import LocalPhase,read,write,sha,exclusive_lock
from run_field_held_v16 import probe

ROOT=Path(__file__).resolve().parents[2]
BASE='32286f73'
OUT=ROOT/'.godot/field_held_v17'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_FIELD_HELD_V17.md','docs/current/ITEM_FIELD_HELD_V17.json',
 'modules/battle/backends/showdown/field_held_items.cjs',
 'tools/showdown_engine_probe/field_held_v16.cjs','tools/showdown_engine_probe/field_held_v17.cjs',
 'tools/showdown_engine_probe/held_item_contract.cjs','tools/showdown_engine_probe/held_item_reference_rows.cjs',
 'tests/gameplay/field_held_v16.gd','tests/gameplay/field_held_v17.gd','tests/gameplay/field_held_v17.gd.uid',
 'tools/verification/run_field_held_v17.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            for name,script,source in [('native_training','tools/showdown_engine_probe/field_held_v17.cjs',OUT/'node.json'),
                ('native_medicines','tools/showdown_engine_probe/field_held_v16.cjs',ROOT/'.godot/field_held_v16/node.json'),
                ('bell_regression','tools/showdown_engine_probe/field_held_v14.cjs',ROOT/'.godot/field_held_v14/node.json')]:
                result=probe(dest,name,script,source);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            groups=[('import','IMPORT'),('held_training','tests/gameplay/field_held_v17.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('held_medicine_regression','tests/gameplay/field_held_v16.gd'),
                ('field_training','tests/gameplay/item_field_training_v7.gd'),
                ('pp_boosts','tests/gameplay/item_field_pp_v8.gd'),
                ('growth','tests/gameplay/item_field_growth_v9.gd'),
                ('native','tests/gameplay/field_native_test_runner.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('training_gpu','tests/gameplay/field_held_v17.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
            report['integrity_after']=phase.verify(True)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('FIELD_HELD_V17',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
