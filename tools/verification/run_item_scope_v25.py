"""Withdraw Linking Cord; audit obsolete candidates without changing evolutions."""
from pathlib import Path
import argparse, sys, time
from local_phase import LocalPhase, write, sha, exclusive_lock
from run_encounter_held_v23 import process

ROOT=Path(__file__).resolve().parents[2]
BASE='4ac657f55fad2466a30ac25b631b55db01717126'
OUT=ROOT/'.godot/item_scope_v25'
REMOVED={
    'modules/inventory/linking_cord_effects.gd','modules/inventory/linking_cord_effects.gd.uid',
    'modules/inventory/linking_cord_profile_v24.json',
    'tools/item_import/import_linking_cord_v24.py','tests/tools/test_linking_cord_import_v24.py',
    'tools/showdown_engine_probe/linking_cord_v24.cjs',
    'tests/gameplay/linking_cord_v24.gd','tests/gameplay/linking_cord_v24.gd.uid',
    'tools/verification/run_linking_cord_v24.py',
}
ALLOWED=REMOVED|{
    'AGENTS.md','config/item_selection_v1.json','modules/inventory/field_item_service.gd',
    'modules/battle/backends/showdown/field_held_items.cjs',
    'docs/current/START_HERE.md','docs/current/NEXT_STEPS.md','docs/current/PROJECT_STATE.md',
    'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json','docs/current/ITEM_SCOPE_V25.md',
    'docs/current/ITEM_SCOPE_V25.json','docs/current/TRADE_EVOLUTIONS_FUTURE.md',
    'tools/item_import/audit_obsolete_items_v25.py','tests/gameplay/item_scope_v25.gd',
    'tests/gameplay/item_scope_v25.gd.uid','tests/gameplay/item_selection_policy_test_runner.gd',
    'tools/verification/run_item_scope_v25.py',
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
            for rel in REMOVED:assert not (ROOT/rel).exists(),'Retired code remains: '+rel
            r=process(dest,'audit',[sys.executable,'tools/item_import/audit_obsolete_items_v25.py','--check'],False,'ITEM_SCOPE_AUDIT PASS')
            report['groups'].append(r);write(dest/'results.json',report);assert r['status']=='PASS','audit'
            for name,script in [
                ('withdrawal','tests/gameplay/item_scope_v25.gd'),
                ('selection','tests/gameplay/item_selection_policy_test_runner.gd'),
                ('connections','tests/gameplay/item_connections_test_runner.gd'),
                ('field_effects','tests/gameplay/item_field_effects_v4.gd'),
            ]:
                r=phase.run_godot(name,script,dest);report['groups'].append(r);write(dest/'results.json',report)
                assert r['status']=='PASS' and r['checks_reported']>0,name
            report['tested_sources_sha256']={p:sha(ROOT/p)for p in sorted(ALLOWED)
                if p.startswith(('config/','modules/','tools/','tests/')) and (ROOT/p).is_file()}
            report['integrity_after']=phase.verify(True);report['status']='PASS'
        except Exception as error:
            report['status']='FAIL';report['error']=str(error)
        write(dest/'results.json',report);write(OUT/'results.json',report)
        print('ITEM_SCOPE_V25',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS'else 1


if __name__=='__main__':raise SystemExit(main())
