"""Bounded declarative integration verifier; never installs item mechanics."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
BASE = '47f42aef1a518eefb744ad310f89b6e2d3ce7108'
DESCRIPTOR = 'tests/fixtures/item_automation_v28/choice_items.json'
PASSIVE_DESCRIPTOR = 'tests/fixtures/item_automation_v28/passive_items.json'
ENTRY_DESCRIPTOR = 'tests/fixtures/item_automation_v28/entry_items.json'
DESCRIPTORS = [DESCRIPTOR, PASSIVE_DESCRIPTOR, ENTRY_DESCRIPTOR]
sys.path.insert(0, str(ROOT/'tools/item_audit'))
SCRIPT = 'tests/gameplay/item_automation_v28.gd'
IDS = {'choice_band', 'choice_specs', 'choice_scarf'}
SCENARIOS = {'physical_damage', 'special_damage', 'speed_order', 'lock_restore_switch', 'map_bag_owner_save'}
DOC = 'docs/handoff/ITEMS_V28/'
ALLOWED = {DESCRIPTOR, SCRIPT, SCRIPT+'.uid', 'tools/item_audit/automation_v28.py',
           'tests/tools/test_item_automation_v28.py', '.github/workflows/item-closure-v3.yml',
           PASSIVE_DESCRIPTOR, 'tests/gameplay/item_automation_effects_v28.gd',
           'tests/gameplay/item_automation_effects_v28.gd.uid', 'tools/item_audit/automation_contracts_v28.py',
           'tests/tools/test_item_automation_passive_v28.py', ENTRY_DESCRIPTOR,
           'tests/gameplay/item_automation_entry_v28.gd','tests/gameplay/item_automation_entry_v28.gd.uid',
           'tests/gameplay/item_automation_opponent_v28.gd','tests/gameplay/item_automation_opponent_v28.gd.uid',
           'tools/item_audit/automation_entry_v28.py','tests/tools/test_item_automation_entry_v28.py'} | {
    DOC+n for n in ['WORK_ORDER.md', 'START_HERE.md', 'STATE.json', 'PROGRESS.md', 'RESULTADOS.json',
                   'COMPETITIVE_COVERAGE_AUDIT.md', 'AUTOMATION_PROTOTYPE.md', 'AUTOMATION_RESULTS.json']}
ENGINE_METADATA = {'modules/creatures/progression/battle_ev_rewards.gd.uid',
                   'tests/gameplay/competitive_damage_items_v28.gd.uid',
                   'tests/gameplay/competitive_protection_items_v28.gd.uid',
                   'tests/gameplay/item_closure_v3_test_runner.gd.uid'}


def read(path): return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def write(path, value): Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def git(*args): return subprocess.check_output(['git', *args], cwd=ROOT, text=True, encoding='utf-8').strip()


def validate_descriptor(d):
    if d.get('family') == 'entry_hazard_items':
        from automation_entry_v28 import validate_descriptor as entry_descriptor
        return entry_descriptor(d)
    if d.get('family') == 'passive_reactive_held_items':
        from automation_contracts_v28 import validate_passive_descriptor
        return validate_passive_descriptor(d)
    if set(d) != {'schema_version','family','format','seed','level','actor_species','damage_target','speed_target',
                  'physical_move','special_move','speed_move','consumption','variants','scenarios','items'}:
        raise ValueError('Unknown/missing descriptor fields')
    if d['schema_version'] != 1 or d['family'] != 'choice_held_items' or d['format'] != 'gen9calvounifiedv1':
        raise ValueError('Unreviewed family/format')
    if d['consumption'] != 'retained' or d['variants'] != ['active','none','reserve']:
        raise ValueError('Required controls/retention missing')
    if len(d['scenarios']) != 5 or set(d['scenarios']) != SCENARIOS:
        raise ValueError('Required scenario omitted/duplicated')
    if len(d['items']) != 3 or {r['id'] for r in d['items']} != IDS:
        raise ValueError('Only the three reviewed Choice IDs are authorized')
    if len(d['seed']) != 4 or any(type(n) is not int or not 0 <= n < 65536 for n in d['seed']):
        raise ValueError('Invalid native seed')
    if d['level'] != 100 or d['actor_species'] != 'mew' or d['damage_target'] != 'snorlax' or d['speed_target'] != 'gengar':
        raise ValueError('Unreviewed species/level fixture')
    if [d[k] for k in ['physical_move','special_move','speed_move']] != ['tackle','confusion','water_gun']:
        raise ValueError('Unreviewed trigger')
    expected = {'choice_band':(197,'greater','equal','unchanged'),
                'choice_specs':(274,'equal','greater','unchanged'),
                'choice_scarf':(264,'equal','equal','reversed')}
    for r in d['items']:
        if set(r) != {'id','api_id','physical_damage','special_damage','speed_order'}:
            raise ValueError('Unknown item expectation')
        if tuple(r[k] for k in ['api_id','physical_damage','special_damage','speed_order']) != expected[r['id']]:
            raise ValueError('Expectation does not match the reviewed Choice contract')
    return d


def guard():
    for p in [PASSIVE_DESCRIPTOR,'tests/tools/test_item_automation_passive_v28.py',
              'tools/item_audit/automation_contracts_v28.py','tests/gameplay/item_automation_effects_v28.gd']:
        if git('diff','4d39d3aa1413c36485d96fc5108872a28deb03b0','--',p):
            raise ValueError('Previous family contract/tests changed: '+p)
    for p in [DESCRIPTOR, 'tests/tools/test_item_automation_v28.py']:
        if git('diff','648a2c86541b6a381424413e2b2e28231d127353','--',p):
            raise ValueError('Historical Choice descriptor/tests changed: '+p)
    untracked = set(git('ls-files','--others','--exclude-standard').splitlines())
    metadata = untracked & ENGINE_METADATA
    for p in metadata:
        if not re.fullmatch(r'uid://[a-z0-9]+\s*', (ROOT/p).read_text(encoding='utf-8')):
            raise ValueError('Unexpected generated UID content: '+p)
    changed = set(git('diff','--name-only',BASE).splitlines()) | (untracked-metadata)
    if changed - ALLOWED: raise ValueError('Outside exact allowlist: '+repr(sorted(changed-ALLOWED)))
    absent = [s[2:] for s in git('ls-files','-v').splitlines() if s.startswith('S ')]
    if any((ROOT/p).exists() for p in absent): raise ValueError('Protected absent dataset materialized')
    runtime = ROOT/'.godot/battle_reference/runtime'
    if read(runtime/'node_modules/@pkmn/sim/package.json')['version'] != '0.10.11':
        raise ValueError('Pinned runtime missing/mismatched; do not replace it')
    return {'base':BASE,'changed_allowed':sorted(changed),'engine_generated_untracked_uids':sorted(metadata),'absent_skip_worktree':len(absent),
            'runtime_hashes':{p.relative_to(ROOT).as_posix():digest(p) for p in sorted(runtime.rglob('*')) if p.is_file()}}


def provenance(d):
    # Reuse current inventory classification, not a second catalog/policy engine.
    from item_closure_v3 import generate
    inventory = {r['id']:r for r in generate()['rows']}
    index_path = 'data/api/v2/item/index.json'
    original_index = json.loads(git('show',BASE+':'+index_path))
    by_name = {r['name']:r for r in original_index['results']}
    rows = []
    for spec in d['items']:
        item_id = spec['id']; original_name = item_id.replace('_','-')
        path = f"data/api/v2/item/{spec['api_id']}/index.json"
        original = json.loads(git('show',BASE+':'+path))
        attrs = {r['name'] for r in original['attributes']}
        from automation_contracts_v28 import reviewed_attribute_gap
        from automation_entry_v28 import source_metadata_supported
        source_blob = git('rev-parse',BASE+':'+path)
        attribute_gap = reviewed_attribute_gap(item_id, original) or source_metadata_supported(item_id, original, source_blob)
        if (inventory[item_id]['excluded'] or not inventory[item_id]['equip_permitted'] or
            original['id'] != spec['api_id'] or original['name'] != original_name or
            by_name[original_name]['url'] != f"/api/v2/item/{spec['api_id']}/" or
            (not {'holdable','holdable-active'} <= attrs and not attribute_gap) or not original['game_indices']):
            raise ValueError('Official/allowed/equipable provenance failed: '+item_id)
        rows.append({'id':item_id,'api_id':spec['api_id'],'source_path':path,
                     'source_blob':source_blob,'category':original['category']['name'],
                     'generation_indices':len(original['game_indices']),'equip_permitted':True,'excluded':False,
                     'attribute_evidence':('reviewed_empty_attributes_pokeapi_583_gen5_9_contact_effect' if item_id=='rocky_helmet' else 'reviewed_exact_entry_item_source_blob_and_generation_indices') if attribute_gap else 'explicit_holdable_attributes'})
    return rows


def validate_report(d, report, out):
    if (report.get('status') != 'SCOPED_VERIFIED' or report.get('errors') or report.get('items') != 3 or
        type(report.get('checks')) is not int or report['checks'] <= 0):
        raise ValueError('Godot did not report a nonempty successful execution')
    expected = {(r['id'],s) for r in d['items'] for s in d['scenarios']}
    rows = report.get('scenarios',[])
    if len(rows) != 15 or {(r['id'],r['scenario']) for r in rows} != expected:
        raise ValueError('Missing, unexpected or duplicate scenario')
    specs = {r['id']:r for r in d['items']}
    for r in rows:
        if r.get('status') != 'SCOPED_VERIFIED' or r.get('errors') or r.get('checks',0) < 10:
            raise ValueError('Unverified scenario '+r['id']+'/'+r['scenario'])
        obs = r['observed']; scenario = r['scenario']
        variants = [obs] if scenario == 'map_bag_owner_save' else list(obs.values())
        if scenario != 'map_bag_owner_save' and set(obs) != set(d['variants']):
            raise ValueError('A control was omitted')
        for v in variants:
            if v.get('valid') is not True: raise ValueError('Unexecuted variant')
            filename = v.get('evidence',v.get('map_save',''))
            path = (out/filename).resolve()
            if not filename or path.parent != out.resolve() or not path.is_file() or digest(path) != v.get('sha256'):
                raise ValueError('Missing, corrupt or out-of-scope raw evidence')
        if scenario.endswith('_damage'):
            a,b,c = (obs[k]['damage'] for k in d['variants'])
            relation = specs[r['id']][scenario]
            if b <= 0 or c != b or not (a > b if relation == 'greater' else a == b):
                raise ValueError('Specific damage/control effect not demonstrated')
        elif scenario == 'speed_order':
            desired = 'own' if specs[r['id']]['speed_order'] == 'reversed' else 'foe'
            if obs['active']['first_actor'] != desired or any(obs[k]['first_actor'] != 'foe' for k in ['none','reserve']):
                raise ValueError('Specific speed/control effect not demonstrated')
        elif scenario == 'lock_restore_switch':
            for mode in d['variants']:
                v = obs[mode]
                if (v.get('restored') is not True or v.get('disabled') != (mode=='active') or
                    v.get('alternate_accepted') != (mode!='active') or v.get('unlocked_after_switch') is not True):
                    raise ValueError('Choice restriction/restore/reset not demonstrated')
        elif obs.get('physical_units') != 2 or not obs.get('battle_owner') or obs.get('battle_owner') == obs.get('second_owner'):
            raise ValueError('Physical owner/stock missing')
    if report['checks'] < sum(r['checks'] for r in rows): raise ValueError('Inconsistent assertion count')
    return True


def validate_combined_report(descriptors, report, out):
    from automation_contracts_v28 import validate_passive_report
    if report.get('status')!='SCOPED_VERIFIED' or report.get('errors') or report.get('items')!=6 or report.get('checks',0)<1935:
        raise ValueError('Combined execution failed or Choice assertion floor lost')
    rows=report.get('scenarios',[])
    ids=[s['id'] for d in descriptors for s in d['items']]
    if len(ids)!=len(set(ids)) or len(rows)!=30: raise ValueError('Omitted/duplicate family/items')
    families=[]
    for d in descriptors:
        selected=[r for r in rows if r['id'] in {s['id'] for s in d['items']}]
        partition={**report,'items':len(d['items']),'scenarios':selected}
        if d['family']=='choice_held_items':
            validate_report(d,partition,out)
            if sum(r['checks'] for r in selected)<663: raise ValueError('Old Choice assertions were removed')
        else:
            validate_passive_report(d,partition,out,digest)
            if sum(r['checks'] for r in selected)<1263: raise ValueError('Previous passive assertions were removed')
        families.append({'family':d['family'],'items':len(d['items']),'scenarios':len(selected),
                         'scenario_checks':sum(r['checks'] for r in selected),'status':'SCOPED_VERIFIED'})
    if set(r['id'] for r in rows)!=set(ids) or report['checks']<sum(r['checks'] for r in rows):
        raise ValueError('Unreviewed object or inconsistent assertion count')
    return families


def execute_group(args, paths, common, out, name):
    from verify_update import execute, prepare_output_dirs
    definitions=[validate_descriptor(read(ROOT/p)) for p in paths]
    count=30 if name=='prior' else sum(len(s['cases'])+1 for s in definitions[0]['items'])
    inputs={**common,'descriptors':[{'path':p,'sha256':digest(ROOT/p)} for p in paths],
            'expected_rows':count,'minimum_checks':1935 if name=='prior' else 1400}
    out.mkdir();write(out/'inputs.json',inputs);prepare_output_dirs(SCRIPT)
    execution=execute('item_automation',[args.godot,'--headless','--path',str(ROOT),'--script','res://'+SCRIPT,'--',out.relative_to(ROOT).as_posix()],out,SCRIPT)
    report=read(out/'godot.json')
    if execution['exit_code']!=0: raise ValueError('Godot failed in '+name)
    if name=='prior': families=validate_combined_report(definitions,report,out)
    else:
        from automation_entry_v28 import validate_report as validate_entry
        validate_entry(definitions[0],report,out,digest)
        families=[{'family':'entry_hazard_items','items':2,'scenarios':count,'scenario_checks':sum(r['checks'] for r in report['scenarios']),'status':'SCOPED_VERIFIED'}]
    if report.get('descriptor_hashes')!={p:digest(ROOT/p) for p in paths}: raise ValueError('Descriptors not exercised: '+name)
    log=(out/'item_automation.log').read_text(encoding='utf-8',errors='replace')
    pid=[s for s in log.splitlines() if re.search(r'ERROR: The process .+ does not exist or is not a child',s)]
    if execution['status']!='PASS':
        extra=[s for s in log.splitlines() if 'ERROR:' in s and s not in pid]
        if not pid or extra or re.search(r'SCRIPT ERROR|Parse Error|timeout',log): raise ValueError('Unexpected diagnostics: '+repr(execution))
    return {'name':name,'directory':out.name,'checks':report['checks'],'items':report['items'],'scenarios':len(report['scenarios']),
            'families':families,'execution':execution,'worker_pid_diagnostics':pid,'status':'SCOPED_VERIFIED'}, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',default=shutil.which('godot') or 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe')
    parser.add_argument('--node',default=shutil.which('node') or 'D:/Herramientas/NodeJS/node.exe')
    parser.add_argument('--only-entry',action='store_true',help='Local development only; produces PARTIAL_SCOPED_VERIFIED, never full certification')
    args = parser.parse_args()
    out = ROOT/'.godot/item_automation_v28/runs'/str(time.time_ns()); out.mkdir(parents=True)
    receipt = {'status':'FAILED','all_item_effects_certified':False,'errors':[]}
    try:
        selected=DESCRIPTORS[2:] if args.only_entry else DESCRIPTORS
        descriptors = [validate_descriptor(read(ROOT/p)) for p in selected]
        specs = [s for d in descriptors for s in d['items']]
        before = guard()
        checkout = git('rev-parse','HEAD')
        inputs = {'functional_sha':os.getenv('ITEM_AUTOMATION_FUNCTIONAL_SHA') or checkout,'checkout_sha':checkout,
                  'run_url':os.getenv('ITEM_AUTOMATION_RUN_URL',''),'descriptor_sha256':digest(ROOT/DESCRIPTOR),
                  'descriptors':[{'path':p,'sha256':digest(ROOT/p)} for p in selected],
                  'provenance':[r for d in descriptors for r in provenance(d)],'base':BASE,
                  'test_sources_sha256':{p:digest(ROOT/p) for p in ALLOWED if (ROOT/p).is_file() and not p.startswith(DOC)},
                  'ability_checkpoint':{'branch':'codex/ability-audit-v1','functional_sha':'72548cde','resume_note_commit':'5d5f8ae','integrated_here':False}}
        write(out/'inputs.json',inputs)
        os.environ['POKEMON_CALVO_NODE'] = str(Path(args.node).resolve())
        sys.path.insert(0,str(ROOT/'tools/distribution'))
        groups=[];rows=[];families=[]
        for name,paths in ([('entry',[ENTRY_DESCRIPTOR])] if args.only_entry else [('prior',DESCRIPTORS[:2]),('entry',[ENTRY_DESCRIPTOR])]):
            group,report=execute_group(args,paths,inputs,out/name,name)
            groups.append(group);families.extend(group['families'])
            rows.extend({**r,'evidence_directory':name} for r in report['scenarios'])
            receipt.update(groups=groups,scenario_results=rows,checks=sum(g['checks'] for g in groups))
            write(out/'results.json',receipt)
        if len(rows)!=(10 if args.only_entry else 40) or {r['id'] for r in rows}!={s['id'] for s in specs}: raise ValueError('Missing requested family/scenario')
        after = guard()
        if before['runtime_hashes'] != after['runtime_hashes'] or before['absent_skip_worktree'] != after['absent_skip_worktree']:
            raise ValueError('Protected runtime or absent snapshots changed')
        for p,sha in inputs['test_sources_sha256'].items():
            if digest(ROOT/p) != sha: raise ValueError('Test source changed while executing: '+p)
        receipt.update(status='PARTIAL_SCOPED_VERIFIED' if args.only_entry else 'SCOPED_VERIFIED',functional_sha=inputs['functional_sha'],
                       all_configured_families_verified=not args.only_entry,worker_pid_diagnostics=[s for g in groups for s in g['worker_pid_diagnostics']],
                       checkout_sha=checkout,run_url=inputs['run_url'],items=len(specs),scenarios=len(rows),families=families,
                       per_item=[{'id':s['id'],'status':'SCOPED_VERIFIED','scenarios':[r for r in rows if r['id']==s['id']]} for s in specs],
                       provenance=inputs['provenance'],protected={'runtime_files':len(after['runtime_hashes']),'absent_skip_worktree':after['absent_skip_worktree'], 'outside_allowlist_changed':False,'engine_generated_untracked_uids':after['engine_generated_untracked_uids']},
                       test_sources_sha256=inputs['test_sources_sha256'],descriptor_sha256=inputs['descriptor_sha256'],descriptor_hashes={p:digest(ROOT/p) for p in selected},
                       limitations=['Headless only; GPU pending','Empty abilities, no suppression/gravity/transfer interactions','PID diagnostics recorded separately; no clean Linux-console claim'])
    except Exception as e:
        receipt['errors'].append(str(e))
    write(out/'results.json',receipt)
    write(ROOT/'.godot/item_automation_v28/latest.json',{'status':receipt['status'],'results':str(out/'results.json')})
    print('ITEM_AUTOMATION_V28',receipt['status'],'checks='+str(receipt.get('checks',0)),out,flush=True)
    if receipt['errors']: print(json.dumps(receipt['errors'],ensure_ascii=True))
    return 0 if receipt['status'] in ['SCOPED_VERIFIED','PARTIAL_SCOPED_VERIFIED'] else 1


if __name__ == '__main__': raise SystemExit(main())
