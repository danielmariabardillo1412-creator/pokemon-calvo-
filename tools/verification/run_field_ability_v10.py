"""Codex resumes the two ability items; the OpenCode handoff remains historical."""
from pathlib import Path
import argparse,time
from local_phase import LocalPhase,read,write,sha,exclusive_lock

ROOT=Path(__file__).resolve().parents[2]
BASE='ce4a4243'
OUT=ROOT/'.godot/item_field_v10'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_FIELD_V10.md','docs/current/ITEM_FIELD_V10.json',
 'docs/opencode/TASKS.json','docs/opencode/PROGRESS.md',
 'modules/inventory/field_ability_effects.gd','modules/inventory/field_ability_effects.gd.uid',
 'modules/inventory/field_item_effects.gd','modules/inventory/field_item_service.gd',
 'scenes/visual/field_item_bag.gd','tests/gameplay/item_field_ability_v10.gd',
 'tests/gameplay/item_field_ability_v10.gd.uid','tools/verification/run_field_ability_v10.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            groups=[('import','IMPORT'),('ability_items','tests/gameplay/item_field_ability_v10.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('growth','tests/gameplay/item_field_growth_v9.gd'),('pp','tests/gameplay/item_field_pp_v8.gd'),
                ('training','tests/gameplay/item_field_training_v7.gd'),('native','tests/gameplay/field_native_test_runner.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('ability_gpu','tests/gameplay/item_field_ability_v10.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
            report['integrity_after']=phase.verify(True)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('FIELD_ABILITY_V10',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
