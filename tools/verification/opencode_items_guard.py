"""Scope/integrity gate for OpenCode O001. This is NOT a gameplay test."""
from pathlib import Path
import argparse, sys
from local_phase import LocalPhase, read, write, sha

ROOT=Path(__file__).resolve().parents[2]
BASE='815967d7139006715b0d2c1f543383e320189fac'
OUT=ROOT/'.godot/opencode_items_o001'
CONTRACTS=['docs/opencode/START_HERE.md','docs/opencode/O001_ABILITY_ITEMS.md',
 'tools/verification/opencode_items_guard.py']
ALLOWED=set(CONTRACTS) | {'AGENTS.md','docs/current/NEXT_STEPS.md',
 'docs/opencode/TASKS.json','docs/opencode/PROGRESS.md',
 'docs/opencode/evidence/O001/REVIEW.md','docs/opencode/evidence/O001/results.json',
 'modules/inventory/field_ability_effects.gd','modules/inventory/field_ability_effects.gd.uid',
 'modules/inventory/field_item_effects.gd','modules/inventory/field_item_service.gd',
 'scenes/visual/field_item_bag.gd','tests/gameplay/item_field_ability_o001.gd',
 'tests/gameplay/item_field_ability_o001.gd.uid','tools/verification/run_opencode_ability_o001.py'}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--prepare',action='store_true');parser.add_argument('--full',action='store_true');args=parser.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    bootstrap=OUT/'contracts.json'
    if args.prepare:
        assert not bootstrap.exists(),'Contract hashes already fixed; never reseal'
        result=phase.prepare()
        write(bootstrap,{rel:sha(ROOT/rel) for rel in CONTRACTS+['AGENTS.md','docs/current/NEXT_STEPS.md']})
        print(result);return 0
    for rel,digest in read(bootstrap).items(): assert sha(ROOT/rel)==digest,'Protected handoff contract changed: '+rel
    result=phase.verify(args.full)
    print(result)
    print('SCOPE_ONLY: mechanics require the separate O001 tests and Codex review.')
    return 0

if __name__=='__main__': raise SystemExit(main())
