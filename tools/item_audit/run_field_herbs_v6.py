"""Verify modern bitter medicines without altering the earlier recovery contract."""
from pathlib import Path
import json,subprocess,sys,csv
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/item_audit'))
import run_field_recovery_v5 as common
run_checks=common.run_checks
OUT=ROOT/'.godot/item_field_v6'
BASE='5bbf7d1'
ALLOWED={'modules/inventory/field_item_effects.gd','scenes/visual/field_item_bag.gd',
 'tools/item_audit/run_field_recovery_v5.py','tools/item_audit/run_field_herbs_v6.py',
 'tests/gameplay/item_field_herbs_v6.gd','tests/gameplay/item_field_herbs_v6.gd.uid',
 'tests/fixtures/item_field_v6/reference_contract.json','docs/current/DEVELOPMENT_CURRENT.md',
 'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json','docs/current/ITEM_FIELD_V6.json',
 'docs/current/ITEM_FIELD_V6.md','docs/current/ITEM_FIELD_V6.csv.txt','docs/current/ITEM_PENDING_V6.json'}
HERBS={'energy_powder','energy_root','heal_powder'}

def scope(full):
 changed=subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines()
 new=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
 assert set(changed+new)<=ALLOWED,sorted(set(changed+new)-ALLOWED)
 # V5 is already accepted: its changes remain exempt from the older T006B hashes.
 # The stricter V6 delta above freezes every accepted V5 path not authorized here.
 result=common.scope(full,base=BASE,allowed=common.ALLOWED|ALLOWED)
 result['current_phase_allowed_files']=sorted(ALLOWED)
 return result

def publish(report):
 old=common.read(ROOT/'docs/current/ITEM_FIELD_V5.json')
 head=common.read(OUT/'godot.json');gpu=common.read(OUT/'gpu.json')
 for r in [head,gpu]:
  assert r['status']=='PASS' and not r['errors'] and len(r['rows'])==144
  assert {x['id'] for x in r['rows']}==HERBS
 assert gpu['gpu'] and not head['gpu']
 for p,h in old['protected_data_policy_art'].items():assert common.sha(ROOT/p)==h,p
 rows=old['rows']
 for row in rows:
  if row['id'] in HERBS:row['field_use_status']='BITTER_MEDICINE_HP_STATUS_FRIENDSHIP_CONSUMPTION_SAVE_NATIVE_VERIFIED'
 with (ROOT/'docs/current/ITEM_FIELD_V6.csv.txt').open('w',encoding='utf-8',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
 result={'phase':'ITEM_FIELD_V6','date':'2026-10-29','status':'BITTER_MEDICINE_SLICE_PASS_WITH_EXPLICIT_PENDING','all_item_effects_certified':False,'new_ids':sorted(HERBS),'total_connected_field_effect_ids':47,'field_recovery_ids_verified':41,'headless_checks':head['checks'],'gpu_checks':gpu['checks'],'positive_contexts':len(head['rows']),'reference':common.read(ROOT/'tests/fixtures/item_field_v6/reference_contract.json'),'verification':report,'sources_sha256':{p:common.sha(ROOT/p) for p in sorted(ALLOWED) if p.startswith(('modules/','scenes/','tools/','tests/'))},'protected_data_policy_art':old['protected_data_policy_art'],'previous_full_report':'docs/current/ITEM_FIELD_V5.json','full_item_matrix':'docs/current/ITEM_FIELD_V6.csv.txt','limitations':['No revival or native-battle medicine protocol changes.','Existing 41 form/world/breeding routes and 323 unreviewed native contexts remain pending.','Vitamins, feathers, XP/IV/nature/ability, origin metadata, legacy machines, special balls and conditioned evolution/world routes remain pending.']}
 common.write(ROOT/'docs/current/ITEM_FIELD_V6.json',result)
 pending=common.read(ROOT/'docs/current/ITEM_PENDING_V5.json')
 for group in pending['other_system_groups']:
  if group['group']=='outside_battle_medicine':group['reason']='41 recovery medicine IDs connected outside battle, including three bitter herbs with negative friendship. Unlisted effects still need explicit routes; revival stays banned.'
 common.write(ROOT/'docs/current/ITEM_PENDING_V6.json',pending)
 status=common.read(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json')
 status.update({'latest_report':'docs/current/ITEM_FIELD_V6.json','notes':'docs/current/ITEM_FIELD_V6.md','full_item_matrix':'docs/current/ITEM_FIELD_V6.csv.txt','latest_verification':'ITEM_FIELD_V6','latest_phase_checks_headless':head['checks'],'latest_phase_checks_gpu':gpu['checks'],'headless_checks':head['checks'],'gpu_checks':gpu['checks'],'field_recovery_ids_verified':41,'total_connected_field_effect_ids':47})
 status['next'][0]='Vitamins/feathers and other permanent training item routes'
 common.write(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json',status)

def main():
 OUT.mkdir(exist_ok=True)
 report={'status':'RUNNING','scope':'ITEM_FIELD_V6','base_commit':BASE,'groups':[]}
 common.write(OUT/'results.json',report)
 try:
  report['integrity_before']=scope(False)
  report['import']=run_checks.command([run_checks.GODOT,'--headless','--path','.','--editor','--import','--quit'],OUT/'import.log')
  assert report['import']['status']=='PASS','Import'
  groups=[('field_v6','item_field_herbs_v6.gd'),('field_v5','item_field_recovery_v5.gd'),
   ('field_v4','item_field_effects_v4.gd'),('connections','item_connections_test_runner.gd'),
   ('api_integration','field_api_integration_test_runner.gd'),('restore_integration','field_restore_integration_test_runner.gd'),
   ('medicine','showdown_medicine_test_runner.gd'),('policy','item_selection_policy_test_runner.gd')]
  for name,script in groups:
   r=run_checks.command([run_checks.GODOT,'--headless','--path','.','--script','tests/gameplay/'+script],OUT/(name+'.log'))
   r['group']=name;report['groups'].append(r);common.write(OUT/'results.json',report)
   print(name,r['status'],r['last_line'],flush=True);assert r['status']=='PASS',name
  r=run_checks.command([run_checks.GODOT,'--path','.','--resolution','1280x720','--script','tests/gameplay/item_field_herbs_v6.gd','--','--capture'],OUT/'gpu.log')
  r['group']='gpu';report['groups'].append(r);common.write(OUT/'results.json',report)
  print('gpu',r['status'],r['last_line'],flush=True);assert r['status']=='PASS','GPU'
  report['integrity_after']=scope(True)
  report['status']='PASS';publish(report)
 except Exception as e:report['status']='FAIL';report['error']=str(e)
 finally:common.write(OUT/'results.json',report)
 print('ITEM_FIELD_V6_RESULT',report['status'],report.get('error',''),flush=True)
 return 0 if report['status']=='PASS' else 1
if __name__=='__main__':sys.exit(main())
