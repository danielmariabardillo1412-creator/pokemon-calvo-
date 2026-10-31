"""Cord evolution adapter and passive-use hint; a fresh scope after V23."""
from pathlib import Path
import argparse, sys, time
from local_phase import LocalPhase, write, sha, exclusive_lock
from run_encounter_held_v23 import process

ROOT=Path(__file__).resolve().parents[2]
BASE='ac6365997a08aa926fd27272884bf071f293c19d'
OUT=ROOT/'.godot/linking_cord_v24'
ALLOWED={
    'AGENTS.md','docs/current/START_HERE.md','docs/current/NEXT_STEPS.md',
    'docs/current/PROJECT_STATE.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
    'docs/current/ITEM_LINKING_CORD_V24.md','docs/current/ITEM_LINKING_CORD_V24.json',
    'modules/inventory/linking_cord_profile_v24.json',
    'modules/inventory/linking_cord_effects.gd','modules/inventory/linking_cord_effects.gd.uid',
    'modules/inventory/field_item_service.gd',
    'modules/battle/backends/showdown/field_held_items.cjs',
    'scenes/visual/field_item_bag.gd',
    'tools/item_import/import_linking_cord_v24.py',
    'tests/tools/test_linking_cord_import_v24.py',
    'tools/showdown_engine_probe/linking_cord_v24.cjs',
    'tests/gameplay/linking_cord_v24.gd','tests/gameplay/linking_cord_v24.gd.uid',
    'tools/verification/run_linking_cord_v24.py',
}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare',action='store_true')
    parser.add_argument('--piece',action='store_true')
    parser.add_argument('--guard-only',action='store_true')
    args=parser.parse_args();phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        if args.guard_only:print(phase.verify(True),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            for name,command,is_json,marker in [
                ('import_tests',[sys.executable,'tests/tools/test_linking_cord_import_v24.py'],False,'All linking-cord import tests passed'),
                ('import_check',[sys.executable,'tools/item_import/import_linking_cord_v24.py','--check'],False,'LINKING_CORD_IMPORT PASS'),
                ('native',['D:/Herramientas/NodeJS/node.exe','tools/showdown_engine_probe/linking_cord_v24.cjs'],True,None),
            ]:
                result=process(dest,name,command,is_json,marker)
                report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS',name
            groups=[('cord','tests/gameplay/linking_cord_v24.gd')]
            if not args.piece:groups += [
                ('core','tests/test_runner.gd'),
                ('connections','tests/gameplay/item_connections_test_runner.gd'),
                ('field_effects','tests/gameplay/item_field_effects_v4.gd'),
                ('encounter_handoff','tests/gameplay/encounter_held_v23.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd'),
            ]
            for name,script in groups:
                result=phase.run_godot(name,script,dest)
                report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS' and result['checks_reported']>0,name
            if not args.piece:
                result=phase.run_godot('cord_gpu','tests/gameplay/linking_cord_v24.gd',dest,gpu=True,args=['--capture'])
                report['groups'].append(result);write(dest/'results.json',report)
                assert result['status']=='PASS' and result['checks_reported']>0,'GPU'
            report['tested_sources_sha256']={p:sha(ROOT/p)for p in sorted(ALLOWED)
                if p.startswith(('modules/','tools/','tests/','scenes/')) and (ROOT/p).is_file()}
            report['integrity_after']=phase.verify(not args.piece)
            report['status']='PASS'
        except Exception as error:
            report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/('piece_results.json'if args.piece else 'results.json'),report)
        print('LINKING_CORD_V24',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS'else 1


if __name__=='__main__':raise SystemExit(main())
