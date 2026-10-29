"""Verify the source growth aliases and every XP threshold before candy integration."""
from pathlib import Path
import argparse, json, subprocess, sys, time
from local_phase import LocalPhase, read, write, sha, exclusive_lock

ROOT = Path(__file__).resolve().parents[2]
BASE = '52c37164'
OUT = ROOT/'.godot/progression_growth_curves_audit'
ALLOWED = {'AGENTS.md','docs/current/START_HERE.md','docs/current/PROJECT_STATE.md',
 'docs/current/NEXT_STEPS.md','docs/current/DEVELOPMENT_CURRENT.md',
 'docs/current/PROGRESSION_GROWTH_CURVES_FIX.md','docs/current/PROGRESSION_GROWTH_CURVES_FIX.json',
 'modules/creatures/progression/progression_ruleset.gd',
 'tests/gameplay/progression_growth_curves_test_runner.gd','tests/gameplay/progression_growth_curves_test_runner.gd.uid',
 'tests/fixtures/progression_growth_curves/reference_contract.json',
 'tools/verification/local_phase.py','tools/verification/run_growth_curves.py'}

def references():
    contract = read(ROOT/'tests/fixtures/progression_growth_curves/reference_contract.json')
    for curve, row in contract['tables'].items():
        blob = subprocess.check_output(['git','show',BASE+':'+row['source_path']],cwd=ROOT)
        assert __import__('hashlib').sha256(blob).hexdigest() == row['source_sha256'], curve
        levels = {r['level']:r['experience'] for r in json.loads(blob)['levels']}
        assert row['levels_1_to_100'] == [levels[n] for n in range(1,101)], curve
    source = Path('D:/Proyectos/Pokemon Calvo Referencias/fuentes/pokemon-essentials')/contract['community_source']
    assert sha(source) == contract['community_sha256']
    return {'status':'PASS','values':600,'canonical_curves':6,'source_git_checkpoint':contract['git_checkpoint'],
            'community_commit':contract['community_commit'],'reference_sha256':sha(ROOT/'tests/fixtures/progression_growth_curves/reference_contract.json')}

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--prepare',action='store_true'); args = parser.parse_args()
    phase = LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare: print(phase.prepare(),flush=True); return 0
        directory = OUT/'runs'/str(time.time_ns()); directory.mkdir(parents=True)
        report = {'status':'RUNNING','scope':'PROGRESSION_GROWTH_CURVES_FIX','base':BASE,'groups':[]}
        try:
            report['reference'] = references(); report['integrity_before'] = phase.verify()
            tests = [('import','IMPORT'),('growth_curves','tests/gameplay/progression_growth_curves_test_runner.gd'),
                     ('core','tests/test_runner.gd'),('native_field','tests/gameplay/field_native_test_runner.gd'),
                     ('restore','tests/gameplay/field_restore_integration_test_runner.gd'),
                     ('pp_v8','tests/gameplay/item_field_pp_v8.gd'),('training_v7','tests/gameplay/item_field_training_v7.gd'),
                     ('trainer_corpus','tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd')]
            for name, script in tests:
                r = phase.run_godot(name,script,directory); report['groups'].append(r); write(directory/'results.json',report)
                assert r['status'] == 'PASS', name
            r = phase.run_godot('pp_v8_gpu','tests/gameplay/item_field_pp_v8.gd',directory,gpu=True,args=['--capture'])
            report['groups'].append(r); assert r['status'] == 'PASS', 'GPU'
            report['integrity_after'] = phase.verify(True)
            report['growth_result'] = read(ROOT/'.godot/progression_growth_curves/results.json')
            assert report['growth_result']['status'] == 'PASS'
            report['status'] = 'PASS'
            report['sources_sha256'] = {rel:sha(ROOT/rel) for rel in sorted(ALLOWED) if (ROOT/rel).is_file() and rel.startswith(('modules/','tests/','tools/'))}
            report['limits'] = ['No candy integration is claimed by this prerequisite fix.','Source IDs/data remain unchanged; excluded species stay excluded.','No save/schema rewrite or automatic migration of historic XP values.','Independent tables cover levels 1-100 for all six curves, plus aliases and real canonical species.']
            write(ROOT/'docs/current/PROGRESSION_GROWTH_CURVES_FIX.json',report)
        except Exception as error: report['status'] = 'FAIL'; report['error'] = str(error)
        write(directory/'results.json',report); write(OUT/'results.json',report)
        print('GROWTH_CURVES_AUDIT',report['status'],report.get('error',''),flush=True)
        return 0 if report['status'] == 'PASS' else 1

if __name__ == '__main__': sys.exit(main())
