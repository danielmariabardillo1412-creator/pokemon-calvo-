"""Verify six growth items and their staged decision/ownership/UI boundaries."""
from pathlib import Path
import argparse, sys, time
from local_phase import LocalPhase, read, write, sha, exclusive_lock

ROOT=Path(__file__).resolve().parents[2]
BASE='ce0dc71e'
OUT=ROOT/'.godot/item_field_v9'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_FIELD_V9.md','docs/current/ITEM_FIELD_V9.json',
 'modules/inventory/field_growth_effects.gd','modules/inventory/field_growth_effects.gd.uid',
 'modules/inventory/field_growth_transaction.gd','modules/inventory/field_growth_transaction.gd.uid',
 'modules/inventory/field_item_service.gd','scenes/visual/field_item_bag.gd',
 'scenes/visual/field_growth_choices.gd','scenes/visual/field_growth_choices.gd.uid',
 'tests/gameplay/item_field_growth_v9.gd','tests/gameplay/item_field_growth_v9.gd.uid',
 'tools/verification/run_field_growth_v9.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare: print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        result={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            result['integrity_before']=phase.verify()
            groups=[('import','IMPORT'),('growth_items','tests/gameplay/item_field_growth_v9.gd')]
            if not args.piece: groups += [('core','tests/test_runner.gd'),
                ('growth_curves','tests/gameplay/progression_growth_curves_test_runner.gd'),
                ('evolution','tests/gameplay/pokeapi_repairs_test_runner.gd'),
                ('pp_items','tests/gameplay/item_field_pp_v8.gd'),
                ('training','tests/gameplay/item_field_training_v7.gd'),
                ('native_field','tests/gameplay/field_native_test_runner.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                row=phase.run_godot(name,script,dest);result['groups'].append(row)
                write(dest/'results.json',result);assert row['status']=='PASS',name
            if not args.piece:
                row=phase.run_godot('growth_gpu','tests/gameplay/item_field_growth_v9.gd',dest,gpu=True,args=['--capture'])
                result['groups'].append(row);assert row['status']=='PASS','GPU'
            result['integrity_after']=phase.verify(True)
            result['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            result['status']='PASS'
        except Exception as error: result['status']='FAIL';result['error']=str(error)
        write(dest/'results.json',result);write(OUT/('piece_results.json' if args.piece else 'results.json'),result)
        print('FIELD_GROWTH_V9',result['status'],result.get('error',''),flush=True)
        return 0 if result['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
