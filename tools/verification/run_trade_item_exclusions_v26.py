"""Reviewed trade-item exclusions; no evolution-level conversion."""
from pathlib import Path
import argparse,sys,time
from local_phase import LocalPhase,write,sha,exclusive_lock
from run_encounter_held_v23 import process

ROOT=Path(__file__).resolve().parents[2]
BASE='e9a4812ca44bce5d14f9be72dbb2bd52a4190811'
OUT=ROOT/'.godot/trade_item_exclusions_v26'
ALLOWED={
    'AGENTS.md','config/item_selection_v1.json',
    'docs/current/START_HERE.md','docs/current/NEXT_STEPS.md','docs/current/PROJECT_STATE.md',
    'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json','docs/current/ITEM_TRADE_EXCLUSIONS_V26.md',
    'docs/current/ITEM_TRADE_EXCLUSIONS_V26.json','docs/current/TRADE_EVOLUTIONS_FUTURE.md',
    'tests/gameplay/item_selection_policy_test_runner.gd',
    'tests/gameplay/trade_item_exclusions_v26.gd','tests/gameplay/trade_item_exclusions_v26.gd.uid',
    'tools/showdown_engine_probe/trade_item_roles_v26.cjs',
    'tools/verification/run_trade_item_exclusions_v26.py',
}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--prepare',action='store_true');p.add_argument('--guard-only',action='store_true')
    args=p.parse_args();phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare:print(phase.prepare(),flush=True);return 0
        if args.guard_only:print(phase.verify(True),flush=True);return 0
        dest=OUT/'runs'/str(time.time_ns());dest.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            r=process(dest,'roles',['D:/Herramientas/NodeJS/node.exe','tools/showdown_engine_probe/trade_item_roles_v26.cjs'],True)
            report['groups'].append(r);write(dest/'results.json',report);assert r['status']=='PASS','roles'
            for name,script in [
                ('exclusions','tests/gameplay/trade_item_exclusions_v26.gd'),
                ('selection','tests/gameplay/item_selection_policy_test_runner.gd'),
                ('connections','tests/gameplay/item_connections_test_runner.gd'),
                ('field_effects','tests/gameplay/item_field_effects_v4.gd'),
            ]:
                r=phase.run_godot(name,script,dest);report['groups'].append(r);write(dest/'results.json',report)
                assert r['status']=='PASS' and r['checks_reported']>0,name
            report['tested_sources_sha256']={p:sha(ROOT/p)for p in sorted(ALLOWED)
                if p.startswith(('config/','tools/','tests/'))and(ROOT/p).is_file()}
            report['integrity_after']=phase.verify(True);report['status']='PASS'
        except Exception as error:
            report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/'results.json',report)
        print('TRADE_ITEM_EXCLUSIONS_V26',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS'else 1


if __name__=='__main__':raise SystemExit(main())
