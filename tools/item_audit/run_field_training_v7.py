"""Verify living-target EV item routes, base friendship, persistence and native entry."""
from pathlib import Path
import subprocess,sys,csv
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/item_audit'))
import run_field_recovery_v5 as common
import run_field_herbs_v6 as previous
run_checks=common.run_checks
OUT=ROOT/'.godot/item_field_v7'
BASE='87a96506'
ALLOWED={'modules/inventory/field_training_effects.gd','modules/inventory/field_training_effects.gd.uid',
 'modules/inventory/field_item_effects.gd','modules/inventory/field_item_service.gd','scenes/visual/field_item_bag.gd',
 'tools/item_audit/run_field_training_v7.py','tests/gameplay/item_field_training_v7.gd','tests/gameplay/item_field_training_v7.gd.uid',
 'tests/fixtures/item_field_v7/reference_contract.json','docs/current/DEVELOPMENT_CURRENT.md','docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',
 'docs/current/ITEM_FIELD_V7.json','docs/current/ITEM_FIELD_V7.md','docs/current/ITEM_FIELD_V7.csv.txt','docs/current/ITEM_PENDING_V7.json'}
IDS={'hp_up','protein','iron','calcium','zinc','carbos','health_wing','muscle_wing','resist_wing','genius_wing','clever_wing','swift_wing'}

def scope(full):
 changed=subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines()
 new=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
 assert set(changed+new)<=ALLOWED,sorted(set(changed+new)-ALLOWED)
 result=common.scope(full,base=BASE,allowed=common.ALLOWED|previous.ALLOWED|ALLOWED)
 result['current_phase_allowed_files']=sorted(ALLOWED)
 return result

def publish(report):
 last=common.read(ROOT/'docs/current/ITEM_FIELD_V6.json')
 head=common.read(OUT/'godot.json');gpu=common.read(OUT/'gpu.json')
 for r in [head,gpu]:
  assert r['status']=='PASS' and not r['errors'] and len(r['rows'])==504
  assert {x['id'] for x in r['rows']}==IDS
 assert gpu['gpu'] and not head['gpu']
 for p,h in last['protected_data_policy_art'].items():assert common.sha(ROOT/p)==h,p
 with (ROOT/'docs/current/ITEM_FIELD_V6.csv.txt').open(encoding='utf-8',newline='') as f:rows=list(csv.DictReader(f))
 for row in rows:
  if row['id'] in IDS:row['field_use_status']='EV_TRAINING_STAT_CAP_TOTAL_CAP_BASE_FRIENDSHIP_SAVE_NATIVE_VERIFIED_ORIGIN_BONUS_PENDING'
 with (ROOT/'docs/current/ITEM_FIELD_V7.csv.txt').open('w',encoding='utf-8',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
 result={'phase':'ITEM_FIELD_V7','date':'2026-10-29','status':'EV_TRAINING_BASE_ROUTE_PASS_ORIGIN_CONTEXT_PENDING','all_item_effects_certified':False,'new_ids':sorted(IDS),'total_connected_field_effect_ids':59,'field_recovery_ids_verified':41,'field_training_ids_verified':18,'headless_checks':head['checks'],'gpu_checks':gpu['checks'],'positive_contexts':len(head['rows']),'reference':common.read(ROOT/'tests/fixtures/item_field_v7/reference_contract.json'),'verification':report,'sources_sha256':{p:common.sha(ROOT/p) for p in sorted(ALLOWED) if p.startswith(('modules/','scenes/','tools/','tests/'))},'protected_data_policy_art':last['protected_data_policy_art'],'previous_report':'docs/current/ITEM_FIELD_V6.json','full_item_matrix':'docs/current/ITEM_FIELD_V7.csv.txt','limitations':['Only living targets at the established field boundary; no revival.','Capture-ball/map friendship bonuses remain pending for all 18 EV training/berry IDs.','The 41 reviewed form/world/breeding dependencies and 323 unreviewed native contexts remain pending.','No XP/IV/mint/ability, legacy machine, special-ball or conditioned-evolution/world mechanics are activated.']}
 common.write(ROOT/'docs/current/ITEM_FIELD_V7.json',result)
 pending=common.read(ROOT/'docs/current/ITEM_PENDING_V6.json')
 for group in pending['other_system_groups']:
  if group['group']=='training_items':group['reason']='Six EV berries plus six vitamins and six wings have owned-state EV/base friendship routes. Capture-origin friendship bonuses, PP boosts, XP, IV, nature and ability routes remain pending.'
 origin=pending['field_friendship_origin_context_pending'];origin['items']=sorted(set(origin['items'])|IDS)
 origin['reason']='CreatureInstance does not retain capture ball/map. EV changes, base friendship and live Soothe Bell verified; origin bonuses not inferred. Includes 6 EV berries, 6 vitamins and 6 wings.'
 common.write(ROOT/'docs/current/ITEM_PENDING_V7.json',pending)
 status=common.read(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json')
 status.update({'latest_report':'docs/current/ITEM_FIELD_V7.json','notes':'docs/current/ITEM_FIELD_V7.md','full_item_matrix':'docs/current/ITEM_FIELD_V7.csv.txt','latest_verification':'ITEM_FIELD_V7','headless_checks':head['checks'],'gpu_checks':gpu['checks'],'latest_phase_checks_headless':head['checks'],'latest_phase_checks_gpu':gpu['checks'],'field_training_ids_verified':18,'total_connected_field_effect_ids':59})
 status['next'][0]='General differential comparator requested by user, after current item slice; PP boosts/XP/IV/nature/ability routes remain separate pending work'
 common.write(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',status)

def main():
 OUT.mkdir(exist_ok=True)
 report={'status':'RUNNING','scope':'ITEM_FIELD_V7','base_commit':BASE,'groups':[]}
 common.write(OUT/'results.json',report)
 try:
  report['integrity_before']=scope(False)
  report['import']=run_checks.command([run_checks.GODOT,'--headless','--path','.','--editor','--import','--quit'],OUT/'import.log')
  assert report['import']['status']=='PASS','Import'
  groups=[('field_v7','item_field_training_v7.gd'),('field_v6','item_field_herbs_v6.gd'),('field_v5','item_field_recovery_v5.gd'),('field_v4','item_field_effects_v4.gd'),('connections','item_connections_test_runner.gd'),('api_integration','field_api_integration_test_runner.gd'),('restore_integration','field_restore_integration_test_runner.gd'),('medicine','showdown_medicine_test_runner.gd'),('policy','item_selection_policy_test_runner.gd')]
  for name,script in groups:
   r=run_checks.command([run_checks.GODOT,'--headless','--path','.','--script','tests/gameplay/'+script],OUT/(name+'.log'))
   r['group']=name;report['groups'].append(r);common.write(OUT/'results.json',report)
   print(name,r['status'],r['last_line'],flush=True);assert r['status']=='PASS',name
  r=run_checks.command([run_checks.GODOT,'--path','.','--resolution','1280x720','--script','tests/gameplay/item_field_training_v7.gd','--','--capture'],OUT/'gpu.log')
  r['group']='gpu';report['groups'].append(r);common.write(OUT/'results.json',report)
  print('gpu',r['status'],r['last_line'],flush=True);assert r['status']=='PASS','GPU'
  report['integrity_after']=scope(True)
  report['status']='PASS';publish(report)
 except Exception as e:report['status']='FAIL';report['error']=str(e)
 finally:common.write(OUT/'results.json',report)
 print('ITEM_FIELD_V7_RESULT',report['status'],report.get('error',''),flush=True)
 return 0 if report['status']=='PASS' else 1
if __name__=='__main__':sys.exit(main())
