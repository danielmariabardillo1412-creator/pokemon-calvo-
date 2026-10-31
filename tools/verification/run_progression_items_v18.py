"""Lucky Egg and Everstone progression: owned-item semantics and real settlement."""
from pathlib import Path
import argparse,time
from local_phase import LocalPhase,read,write,sha,exclusive_lock
from run_field_held_v16 import probe

ROOT=Path(__file__).resolve().parents[2]
BASE='28c550a4'
OUT=ROOT/'.godot/progression_items_v18'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_PROGRESSION_V18.md','docs/current/ITEM_PROGRESSION_V18.json',
 'modules/battle/backends/showdown/field_held_items.cjs',
 'modules/creatures/progression/progression_held_items.gd','modules/creatures/progression/progression_held_items.gd.uid',
 'modules/creatures/progression/progression_system.gd','modules/creatures/progression/evolution_system.gd',
 'modules/inventory/field_growth_effects.gd',
 'modules/gameplay/showdown_adventure_session.gd','modules/gameplay/wild_adventure_session.gd','modules/gameplay/trainer_battle_session.gd',
 'tools/showdown_engine_probe/held_item_reference_rows.cjs','tools/showdown_engine_probe/field_held_v16.cjs',
 'tools/showdown_engine_probe/field_held_v17.cjs','tools/showdown_engine_probe/field_held_v18.cjs',
 'tests/gameplay/progression_items_v18.gd','tests/gameplay/progression_items_v18.gd.uid',
 'tools/verification/run_progression_items_v18.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            for name,script,source in [('native_progression','tools/showdown_engine_probe/field_held_v18.cjs',OUT/'node.json'),
                ('native_previous','tools/showdown_engine_probe/field_held_v17.cjs',ROOT/'.godot/field_held_v17/node.json')]:
                result=probe(dest,name,script,source);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            groups=[('import','IMPORT'),('progression_items','tests/gameplay/progression_items_v18.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('growth','tests/gameplay/item_field_growth_v9.gd'),('growth_curves','tests/gameplay/progression_growth_curves_test_runner.gd'),
                ('native_adventure','tests/gameplay/showdown_adventure_test_runner.gd'),
                ('trainer_session','tests/trainer_ai/trainer_battle_session_test_runner.gd'),
                ('native','tests/gameplay/field_native_test_runner.gd'),('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                # This historical standalone runner expects its parent output
                # directory to exist. Supply it without editing its assertions.
                if name=='native_adventure':(ROOT/'.godot/showdown_adventure_checks').mkdir(parents=True,exist_ok=True)
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('progression_gpu','tests/gameplay/progression_items_v18.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
            report['integrity_after']=phase.verify(not args.piece)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('PROGRESSION_ITEMS_V18',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
