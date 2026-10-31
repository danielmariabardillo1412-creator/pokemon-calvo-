"""Reviewed field-held descriptor bridge; native item mechanics remain authoritative."""
from pathlib import Path
import argparse,time,subprocess
from local_phase import LocalPhase,read,write,sha,exclusive_lock

ROOT=Path(__file__).resolve().parents[2]
BASE='cff1b50'
OUT=ROOT/'.godot/field_held_v14'
ALLOWED={'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
 'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_FIELD_HELD_V14.md','docs/current/ITEM_FIELD_HELD_V14.json',
 'modules/battle/backends/showdown/field_held_items.cjs','modules/battle/backends/showdown/native_engine.cjs',
 'tests/gameplay/item_mochi_v13.gd','tests/gameplay/field_held_v14.gd','tests/gameplay/field_held_v14.gd.uid',
 'tools/showdown_engine_probe/field_held_v14.cjs','tools/verification/run_field_held_v14.py'}

def native_probe(dest):
    command=['D:/Herramientas/NodeJS/node.exe','tools/showdown_engine_probe/field_held_v14.cjs']
    log=dest/'native_items.log'
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    with log.open('w',encoding='utf-8') as output:
        result=subprocess.run(command,cwd=ROOT,stdout=output,stderr=subprocess.STDOUT,timeout=45,startupinfo=startup)
    report=read(OUT/'node.json');write(dest/'native_items.json',report)
    passed=result.returncode==0 and report['status']=='PASS' and len(report['checks'])==11 and all(x['status']=='PASS' for x in report['checks'])
    gate={'group':'native_items','status':'PASS' if passed else 'FAIL','exit_code':result.returncode,
          'checks_reported':len(report['checks']),'log':str(log),'log_sha256':sha(log),'command':command}
    print('native_items',gate['status'],'checks='+str(gate['checks_reported']),flush=True)
    return gate

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare',action='store_true');p.add_argument('--piece',action='store_true');args=p.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            result=native_probe(dest);report['groups'].append(result);write(dest/'results.json',report)
            assert result['status']=='PASS','native_items'
            groups=[('import','IMPORT'),('field_held','tests/gameplay/field_held_v14.gd')]
            if not args.piece:groups += [('core','tests/test_runner.gd'),
                ('growth','tests/gameplay/item_field_growth_v9.gd'),('mochis','tests/gameplay/item_mochi_v13.gd'),
                ('training','tests/gameplay/item_field_training_v7.gd'),('native','tests/gameplay/field_native_test_runner.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd')]
            for name,script in groups:
                result=phase.run_godot(name,script,dest);report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            if not args.piece:
                result=phase.run_godot('held_gpu','tests/gameplay/field_held_v14.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);assert result['status']=='PASS','GPU'
            report['integrity_after']=phase.verify(True)
            report['tested_sources_sha256']={f:sha(ROOT/f) for f in sorted(ALLOWED)
                if (ROOT/f).is_file() and f.startswith(('modules/','scenes/','tests/','tools/'))}
            report['status']='PASS'
        except Exception as error:report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json' if args.piece else 'results.json'),report)
        print('FIELD_HELD_V14',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__':raise SystemExit(main())
