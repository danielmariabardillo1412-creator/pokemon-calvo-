"""Three imported escape consumables: real native bag actions and settlement."""
from pathlib import Path
import argparse,subprocess,sys,time
from local_phase import LocalPhase,read,write,sha,exclusive_lock

ROOT=Path(__file__).resolve().parents[2]
BASE='167487e4'
OUT=ROOT/'.godot/item_escape_v21'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_ESCAPE_V21.md','docs/current/ITEM_ESCAPE_V21.json',
 'modules/inventory/battle_escape_profile.gd','modules/inventory/battle_escape_profile.gd.uid',
 'modules/inventory/battle_escape_profile.json','modules/gameplay/showdown_adventure_session.gd',
 'scenes/visual/showdown_adventure_lab.gd','tools/item_import/import_escape_v21.py',
 'tests/tools/test_escape_import_v21.py','tests/gameplay/item_escape_v21.gd','tests/gameplay/item_escape_v21.gd.uid',
 'tools/verification/run_item_escape_v21.py'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            for name,command in [('compiler',[sys.executable,'tests/tools/test_escape_import_v21.py']),
             ('regeneration',[sys.executable,'tools/item_import/import_escape_v21.py','--check'])]:
                result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,timeout=90)
                log=dest/(name+'.log');log.write_text(result.stdout+result.stderr,encoding='utf-8')
                row={'group':name,'status':'PASS' if result.returncode==0 else 'FAIL','exit_code':result.returncode,'log':str(log)}
                report['groups'].append(row);write(dest/'results.json',report)
                print(name,row['status'],flush=True);assert result.returncode==0,name
            groups=[('import','IMPORT'),('escape_items','tests/gameplay/item_escape_v21.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('adventure','tests/gameplay/showdown_adventure_test_runner.gd'),
                ('medicine','tests/gameplay/showdown_medicine_test_runner.gd'),
                ('native','tests/gameplay/field_native_test_runner.gd'),('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                if name=='adventure':(ROOT/'.godot/showdown_adventure_checks').mkdir(parents=True,exist_ok=True)
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('escape_gpu','tests/gameplay/item_escape_v21.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
                result=phase.run_godot('medicine_gpu','tests/gameplay/showdown_medicine_visual_test_runner.gd',dest,gpu=True)
                report['groups'].append(result);assert result['status']=='PASS','medicine GPU'
            report['integrity_after']=phase.verify(not args.piece)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('ITEM_ESCAPE_V21',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
