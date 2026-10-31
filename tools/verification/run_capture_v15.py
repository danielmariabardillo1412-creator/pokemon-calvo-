"""Four balls with no new world/history/save requirements; frozen V15 scope."""
from pathlib import Path
import argparse,time
from local_phase import LocalPhase,write,sha,exclusive_lock

ROOT=Path(__file__).resolve().parents[2]
BASE='b467470'
OUT=ROOT/'.godot/item_capture_v15'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_CAPTURE_V15.md','docs/current/ITEM_CAPTURE_V15.json',
 'modules/capture/capture_ball_effects.gd',
 'tests/gameplay/item_capture_v15.gd','tests/gameplay/item_capture_v15.gd.uid',
 'tools/verification/run_capture_v15.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            groups=[('import','IMPORT'),('new_balls','tests/gameplay/item_capture_v15.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('previous_balls','tests/gameplay/item_capture_v11.gd'),
                ('context_balls','tests/gameplay/item_capture_v12.gd'),
                ('inventory_capture','tests/gameplay/item_existing_groups_v2.gd'),
                ('legacy_capture_ui','tests/battle/battle_capture_presentation_test_runner.gd'),
                ('native','tests/gameplay/field_native_test_runner.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('balls_gpu','tests/gameplay/item_capture_v15.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
            report['integrity_after']=phase.verify(True)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('ITEM_CAPTURE_V15',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
