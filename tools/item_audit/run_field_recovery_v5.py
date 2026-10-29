"""Bounded field recovery verification; historical architecture baselines stay intact."""
from pathlib import Path
from collections import Counter
import argparse,csv,hashlib,json,subprocess,sys,shutil
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/architecture_handoff'))
import run_checks,guard
OUT=ROOT/'.godot/item_field_v5'
BASE='0e2cd3a'
ALLOWED={
 'AGENTS.md','docs/current/DEVELOPMENT_CURRENT.md',
 'modules/inventory/field_item_effects.gd','modules/inventory/field_item_service.gd',
 'modules/inventory/field_recovery_profile.json','scenes/visual/field_item_bag.gd',
 'tests/gameplay/item_field_recovery_v5.gd','tests/gameplay/item_field_recovery_v5.gd.uid',
 'tests/fixtures/item_field_v5/reference_contract.json','tools/item_audit/run_field_recovery_v5.py',
 'docs/current/ITEM_FIELD_V5.json','docs/current/ITEM_FIELD_V5.md',
 'docs/current/ITEM_FIELD_V5.csv.txt','docs/current/ITEM_PENDING_V5.json',
 'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json'}

def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,data): p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def scope(full):
 guard.check_root()
 assert subprocess.check_output(['git','remote'],cwd=ROOT,text=True).strip()==''
 changed=subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines()
 new=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
 assert set(changed+new)<=ALLOWED, sorted(set(changed+new)-ALLOWED)
 frozen=read(guard.BASE/'protected_files.json')
 checked=0
 for row in frozen:
  if row['path'] in ALLOWED: continue
  p=ROOT/row['path']; assert p.is_file() and not p.is_symlink(),row['path']
  stat=p.stat()
  if full or row['text'] or stat.st_size!=row['bytes'] or stat.st_mtime_ns!=row['mtime_ns']:
   assert sha(p)==row['sha256'],row['path']
  checked+=1
 # Accepted map and bridge functions remain sealed; no new world authority here.
 for rel,expected in read(guard.BASE/'function_seals.json').items():
  source=guard.function_sources((ROOT/rel).read_text(encoding='utf-8'))
  for name,digest in expected.items():assert hashlib.sha256(source[name].encode()).hexdigest()==digest,rel+':'+name
 return {'status':'PASS','historical_protected_files_checked':checked,'authorized_exceptions':sorted(set(r['path'] for r in frozen)&ALLOWED),'mode':'FULL_CONTENT_HASHES' if full else 'TEXT_AND_METADATA','scope_base_commit':BASE}

def publish(report):
 new=read(ROOT/'modules/inventory/field_recovery_profile.json')['items']
 godot=read(OUT/'godot.json');gpu=read(OUT/'gpu.json')
 for r in [godot,gpu]:
  assert r['status']=='PASS' and not r['errors'] and len(r['rows'])==46
  assert {x['id'] for x in r['rows']}==set(new)
 assert not godot['gpu'] and gpu['gpu']
 old=read(ROOT/'docs/current/ITEM_FIELD_V4.json')
 rows=old['rows']
 for row in rows:
  if row['id'] in new:row['field_use_status']='MODERN_FIELD_RECOVERY_OWNERSHIP_CONSUMPTION_SAVE_AND_NATIVE_HANDOFF_VERIFIED'
 pending=read(ROOT/'docs/current/ITEM_PENDING_V4.json')
 for group in pending['other_system_groups']:
  if group['group']=='outside_battle_medicine':group['reason']='38 medicine/recovery IDs connected outside battle. Bitter herbs/friendship and any additional unlisted medicines need separate routes. Revival remains banned.'
 result={'phase':'ITEM_FIELD_V5','date':'2026-10-29','status':'CONNECTED_RECOVERY_SLICE_PASS_WITH_EXPLICIT_PENDING','all_item_effects_certified':False,'new_field_recovery_ids':sorted(new),'new_field_item_ids':23,'total_connected_field_effect_ids':44,'previous_medicine_ids':15,'previous_ev_berry_ids':6,'headless_checks':godot['checks'],'gpu_checks':gpu['checks'],'new_field_context_cases':len(godot['rows']),'reference':read(ROOT/'tests/fixtures/item_field_v5/reference_contract.json'),'verification':report,'sources_sha256':{p:sha(ROOT/p) for p in sorted(ALLOWED) if p.startswith(('modules/','scenes/','tests/','tools/'))},'protected_data_policy_art':old['protected_data_policy_art'],'field_use_status_counts':dict(Counter(r['field_use_status'] for r in rows)),'rows':rows,'limitations':['Field recovery only; no new battle medicine protocol or held trigger certification.','41 reviewed dependency routes plus 323 unreviewed native contexts are still pending.','Vitamins/feathers/XP/IV/nature/ability, herbs, capture origin, legacy machines and conditional world/evolution routes remain pending.']}
 for p,h in result['protected_data_policy_art'].items():assert sha(ROOT/p)==h,p
 write(ROOT/'docs/current/ITEM_FIELD_V5.json',result)
 write(ROOT/'docs/current/ITEM_PENDING_V5.json',pending)
 with (ROOT/'docs/current/ITEM_FIELD_V5.csv.txt').open('w',encoding='utf-8',newline='') as f:
  writer=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');writer.writeheader();writer.writerows(rows)
 status=read(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json')
 status.update({'date':'2026-10-29','latest_report':'docs/current/ITEM_FIELD_V5.json','notes':'docs/current/ITEM_FIELD_V5.md','full_item_matrix':'docs/current/ITEM_FIELD_V5.csv.txt','latest_verification':'ITEM_FIELD_V5','latest_phase_checks_headless':godot['checks'],'latest_phase_checks_gpu':gpu['checks'],'field_recovery_ids_verified':38,'total_connected_field_effect_ids':44,'all_item_effects_certified':False,'verification_all_effects_complete':False})
 status['next']=['Bitter herbs and friendship; vitamins/feathers and other permanent training routes','Capture-ball/map metadata before origin friendship bonuses','26 species-form routes and gender/infatuation/breeding contract','14 food/contest/world-context berries','Special capture balls, legacy machines, conditional evolutions and Escape Rope/world systems']
 write(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',status)

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--full-integrity',action='store_true');args=parser.parse_args()
 OUT.mkdir(exist_ok=True)
 report={'status':'RUNNING','scope':'ITEM_FIELD_V5','base_commit':BASE,'groups':[]}
 write(OUT/'results.json',report)
 try:
  report['integrity_before']=scope(False)
  groups=[('import',['--editor','--import','--quit']),
    ('field_v5',['--script','tests/gameplay/item_field_recovery_v5.gd']),
    ('field_v4',['--script','tests/gameplay/item_field_effects_v4.gd']),
    ('connections',['--script','tests/gameplay/item_connections_test_runner.gd']),
    ('medicine',['--script','tests/gameplay/showdown_medicine_test_runner.gd']),
    ('api_native',['--script','tests/gameplay/field_api_test_runner.gd']),
    ('api_legacy',['--script','tests/gameplay/field_api_test_runner.gd','--','--legacy-field']),
    ('api_integration',['--script','tests/gameplay/field_api_integration_test_runner.gd']),
    ('restore_integration',['--script','tests/gameplay/field_restore_integration_test_runner.gd']),
    ('item_policy',['--script','tests/gameplay/item_selection_policy_test_runner.gd']),
    ('inventory_capture',['--script','tests/gameplay/item_existing_groups_v2.gd'])]
  for name,command_args in groups:
   r=run_checks.command([run_checks.GODOT,'--headless','--path','.']+command_args,OUT/(name+'.log'))
   r['group']=name;report['groups'].append(r);write(OUT/'results.json',report)
   print(name,r['status'],r['last_line'],flush=True);assert r['status']=='PASS',name
  r=run_checks.command([run_checks.GODOT,'--path','.','--resolution','1280x720','--script','tests/gameplay/item_field_recovery_v5.gd','--','--capture'],OUT/'gpu.log')
  r['group']='gpu';report['groups'].append(r);write(OUT/'results.json',report)
  print('gpu',r['status'],r['last_line'],flush=True);assert r['status']=='PASS','GPU'
  report['integrity_after']=scope(args.full_integrity)
  report['status']='PASS';publish(report)
 except Exception as e:report['status']='FAIL';report['error']=str(e)
 finally:write(OUT/'results.json',report)
 print('ITEM_FIELD_V5_RESULT',report['status'],report.get('error',''),flush=True)
 return 0 if report['status']=='PASS' else 1
if __name__=='__main__':sys.exit(main())
