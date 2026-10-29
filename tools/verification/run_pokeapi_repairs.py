"""Bounded verification for the user-authorized corrections following API audit V1."""
from pathlib import Path
import argparse, json, subprocess, sys, time
from local_phase import LocalPhase, read, write, sha, exclusive_lock

ROOT = Path(__file__).resolve().parents[2]
BASE = '680b655'
OUT = ROOT/'.godot/pokeapi_repairs_v1'
ALLOWED = {
 'AGENTS.md','docs/current/START_HERE.md','docs/current/PROJECT_STATE.md',
 'docs/current/POKEAPI_DATA_REPAIRS_V1.md','docs/current/POKEAPI_DATA_REPAIRS_V1.json',
 'data/raw/pokemon_api.json','data/normalized/pokemon_api.json','config/pokemon_variants_v1.json',
 'tools/pokeapi_adapter_v3.py','modules/creatures/progression/evolution_system.gd',
 'modules/creatures/progression/progression_system.gd','modules/gameplay/wild_adventure_session.gd',
 'tools/verification/run_pokeapi_repairs.py','tools/verification/test_pokeapi_repairs.py',
 'tests/gameplay/pokeapi_repairs_test_runner.gd','tests/gameplay/pokeapi_repairs_test_runner.gd.uid',
}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--prepare',action='store_true');args=parser.parse_args()
    phase=LocalPhase(ROOT,BASE,OUT,ALLOWED)
    with exclusive_lock(ROOT,OUT):
        if args.prepare: print(phase.prepare(),flush=True);return 0
        directory=OUT/'runs'/str(time.time_ns());directory.mkdir(parents=True)
        report={'status':'RUNNING','base':BASE,'groups':[]}
        try:
            report['integrity_before']=phase.verify()
            # Check the complete JSON structure: a permitted data file is not a
            # license to change unrelated records or generated effects.
            for rel in ['data/raw/pokemon_api.json','data/normalized/pokemon_api.json']:
                prior=json.loads(subprocess.check_output(['git','show',BASE+':'+rel],cwd=ROOT))
                species=prior['species']
                tyrogue=next(s for s in species if s['id']=='tyrogue') if isinstance(species,list) else species['tyrogue']
                next(e for e in tyrogue['evolutions'] if e['species_id']=='hitmontop')['conditions']={'relative_physical_stats':0}
                assert prior==read(ROOT/rel),'Unrelated dataset edit: '+rel
            prior=json.loads(subprocess.check_output(['git','show',BASE+':config/pokemon_variants_v1.json'],cwd=ROOT))
            prior['canonical_sha256']=sha(ROOT/'data/normalized/pokemon_api.json')
            prior['regional_species']['lilligant_hisui']['source_metadata']['source_sha256']='68478720211044090dcf422ef0da95e1723c3a23bbd8618c511798760d423593'
            assert prior==read(ROOT/'config/pokemon_variants_v1.json'),'Unrelated regional overlay edit'
            report['exact_data_delta']='PASS: one evolution condition per catalog, two binding/provenance hashes'
            command=[sys.executable,'-m','unittest','discover','-s','tools/verification','-p','test_pokeapi_repairs.py','-v']
            proc=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
            log=directory/'adapter_tests.log';log.write_text(proc.stdout+proc.stderr,encoding='utf-8')
            assert proc.returncode==0 and 'OK' in proc.stderr,'adapter controls'
            report['adapter_tests']={'status':'PASS','command':command,'exit_code':proc.returncode,'log':str(log),'log_sha256':sha(log)}
            tests=[('import','IMPORT'),('repairs','tests/gameplay/pokeapi_repairs_test_runner.gd'),
                ('core','tests/test_runner.gd'),('growth','tests/gameplay/progression_growth_curves_test_runner.gd'),
                ('variants','tests/gameplay/pokemon_variant_test_runner.gd'),
                ('native_field','tests/gameplay/field_native_test_runner.gd'),
                ('restore','tests/gameplay/field_restore_integration_test_runner.gd'),
                ('items','tests/gameplay/item_field_pp_v8.gd')]
            for name,script in tests:
                # This existing suite explicitly drives legacy presentations;
                # native battle/save integration has separate gates below.
                if name=='variants': (ROOT/'.godot/pokemon_variant_checks').mkdir(exist_ok=True)
                result=phase.run_godot(name,script,directory,args=['--legacy-field'] if name=='variants' else ())
                report['groups'].append(result)
                write(directory/'results.json',report);assert result['status']=='PASS',name
            report['integrity_after']=phase.verify(True)
            report['tested_sources_sha256']={p:sha(ROOT/p) for p in sorted(ALLOWED)
                if (ROOT/p).is_file() and p.startswith(('modules/','tools/','tests/','data/','config/'))}
            report['status']='PASS'
        except Exception as error:
            report['status']='FAIL';report['error']=str(error)
        write(directory/'results.json',report);write(OUT/'results.json',report)
        print('POKEAPI_REPAIRS',report['status'],report.get('error',''),flush=True)
        return 0 if report['status']=='PASS' else 1

if __name__=='__main__': raise SystemExit(main())
