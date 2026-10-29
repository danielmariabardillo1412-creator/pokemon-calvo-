"""Discover runnable Godot tests through their inheritance, with explicit exclusions."""
from pathlib import Path
from collections import Counter
import re,hashlib
from snapshot import ROOT,SOURCES,DEST,write
EXCLUDED={
 'tests/gameplay/item_inventory_export.gd':'Inventory exporter, no assertion gate.',
 'tests/gameplay/item_effect_templates_v2.gd':'Generates item fixture templates; not a test gate.',
 'tests/gameplay/item_effect_templates_v3.gd':'Generates item fixture templates; not a test gate.',
 'tests/trainer_ai/trainer_search_limit_horizon_diagnostic.gd':'Diagnostic intentionally ignores assertions.',
}
LEGACY_REQUIRED={
 'tests/gameplay/map_runtime_test_runner.gd','tests/gameplay/visual_field_test_runner.gd',
 'tests/battle/ally_switch_pilot_test_runner.gd','tests/battle/live_move_integration_test_runner.gd',
 'tests/battle/status_switch_move_test_runner.gd','tests/battle/substitute_pilot_test_runner.gd',
 'tests/battle/switch_move_continuation_test_runner.gd','tests/battle/transform_pilot_test_runner.gd',
 'tests/battle/weather_pilot_test_runner.gd','tests/gameplay/pokemon_variant_test_runner.gd',
 'tests/visual/battle_animation_playback_test_runner.gd','tests/visual/battle_community_pilot_test_runner.gd',
 'tests/visual/battle_external_integration_test_runner.gd','tests/visual/battle_move_visuals_test_runner.gd',
 'tests/visual/catalog_integration_test_runner.gd',
}
EXTRA=[
 ('tests/gameplay/field_api_test_runner.gd',['--legacy-field']),
 ('tests/gameplay/field_bridge_world_test_runner.gd',['--legacy-field']),
 ('tests/gameplay/field_diagnostics_integration_test_runner.gd',['--legacy-field']),
 ('tests/gameplay/field_restore_contract_test_runner.gd',['--legacy-field']),
]
def tree_script(p,root,seen=None):
 seen=set() if seen is None else seen
 if p in seen:return False
 seen.add(p)
 s=p.read_text(encoding='utf-8-sig',errors='replace')
 m=re.search(r'^extends\s+([^\r\n]+)',s,re.M)
 if not m:return False
 base=m[1].strip()
 if base=='SceneTree':return True
 m=re.fullmatch(r'"res://([^"\n]+)"',base)
 return tree_script(root/m[1],root,seen) if m and (root/m[1]).is_file() else False

def inventory():
 available={label:{p.relative_to(src).as_posix():p for p in (src/'tests').rglob('*.gd') if tree_script(p,src)} for label,src in SOURCES.items()}
 cases=[];excluded=[]
 for rel in sorted(set().union(*(set(v) for v in available.values()))):
  if rel in EXCLUDED:excluded.append({'script':rel,'reason':EXCLUDED[rel]});continue
  name=Path(rel).name
  if rel.startswith('tests/visual/') and not name.endswith('_test_runner.gd'):
   excluded.append({'script':rel,'reason':'Bulk visual collector/probe; no bounded default regression contract. Existing individual visual test gates are retained.'});continue
  present=[label for label in SOURCES if rel in available[label]]
  hashes={label:hashlib.sha256(available[label][rel].read_bytes()).hexdigest() for label in present}
  same=len(present)==2 and len(set(hashes.values()))==1
  mode='gpu' if rel.startswith('tests/visual/') or '_visual_test_runner' in name else 'headless'
  args=['--legacy-field'] if rel in LEGACY_REQUIRED else []
  if mode=='gpu' and '--capture' in available[present[-1]][rel].read_text(encoding='utf-8-sig'):args.append('--capture')
  case={'id':rel.removeprefix('tests/').removesuffix('.gd').replace('/','__'),'script':rel,'labels':present,'same_test_bytes':same,'test_sha256':hashes,'mode':mode,'args':args,'group':rel.split('/')[1] if '/' in rel[6:] else 'foundation','timeout_seconds':600}
  cases.append(case)
 for rel,args in EXTRA:
  case=next((c.copy() for c in cases if c['script']==rel),None)
  if case:case.update({'id':case['id']+'__legacy','args':args});cases.append(case)
 for rel in ['tools/showdown_engine_probe/unified_profile_tests.cjs','tools/showdown_engine_probe/transaction_tests.cjs','tools/showdown_engine_probe/adventure_transaction_tests.cjs','tools/showdown_engine_probe/medicine_tests.cjs','tools/showdown_engine_probe/field_clock_tests.cjs','tools/showdown_engine_probe/probe_tests.cjs']:
  hashes={label:hashlib.sha256((src/rel).read_bytes()).hexdigest() for label,src in SOURCES.items()}
  cases.append({'id':'native__'+Path(rel).stem,'script':rel,'labels':list(SOURCES),'same_test_bytes':len(set(hashes.values()))==1,'test_sha256':hashes,'mode':'node','args':[],'group':'native_contracts','timeout_seconds':900})
 cases.append({'id':'native__complete_move_sweep','script':'tools/regression_comparator/native_sweep.py','labels':list(SOURCES),'same_test_bytes':True,'mode':'native_sweep','args':[],'group':'native_move_coverage','timeout_seconds':3000})
 result={'schema':1,'cases':cases,'excluded':excluded,'discovered':{k:len(v) for k,v in available.items()},'counts':dict(Counter((('paired' if len(c['labels'])==2 else 'current_only' if c['labels']==['organized'] else 'original_only')+'_'+c['mode']) for c in cases)),'coverage_limits':['Finite regression scenarios are not exhaustive proof of all play histories.','Bulk artistic contact-sheet review collectors are listed but not rerun.','Same-test gate outcomes are compared; state-trace probe provides deterministic behavioral comparison separately.','New capabilities are verified on the organized version, not treated as old regressions.']}
 write(DEST/'cases.json',result);return result
if __name__=='__main__':print(inventory()['counts'])
