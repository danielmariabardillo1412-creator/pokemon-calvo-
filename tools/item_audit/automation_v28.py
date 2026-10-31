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
SCRIPT = 'tests/gameplay/item_automation_v28.gd'
IDS = {'choice_band', 'choice_specs', 'choice_scarf'}
SCENARIOS = {'physical_damage', 'special_damage', 'speed_order', 'lock_restore_switch', 'map_bag_owner_save'}
DOC = 'docs/handoff/ITEMS_V28/'
ALLOWED = {DESCRIPTOR, SCRIPT, SCRIPT+'.uid', 'tools/item_audit/automation_v28.py',
           'tests/tools/test_item_automation_v28.py', '.github/workflows/item-closure-v3.yml'} | {
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
        if (inventory[item_id]['excluded'] or not inventory[item_id]['equip_permitted'] or
            original['id'] != spec['api_id'] or original['name'] != original_name or
            by_name[original_name]['url'] != f"/api/v2/item/{spec['api_id']}/" or
            not {'holdable','holdable-active'} <= attrs or not original['game_indices']):
            raise ValueError('Official/allowed/equipable provenance failed: '+item_id)
        rows.append({'id':item_id,'api_id':spec['api_id'],'source_path':path,
                     'source_blob':git('rev-parse',BASE+':'+path),'category':original['category']['name'],
                     'generation_indices':len(original['game_indices']),'equip_permitted':True,'excluded':False})
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',default=shutil.which('godot') or 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe')
    parser.add_argument('--node',default=shutil.which('node') or 'D:/Herramientas/NodeJS/node.exe')
    args = parser.parse_args()
    out = ROOT/'.godot/item_automation_v28/runs'/str(time.time_ns()); out.mkdir(parents=True)
    receipt = {'status':'FAILED','all_item_effects_certified':False,'errors':[]}
    try:
        d = validate_descriptor(read(ROOT/DESCRIPTOR))
        before = guard()
        checkout = git('rev-parse','HEAD')
        inputs = {'functional_sha':os.getenv('ITEM_AUTOMATION_FUNCTIONAL_SHA') or checkout,'checkout_sha':checkout,
                  'run_url':os.getenv('ITEM_AUTOMATION_RUN_URL',''),'descriptor_sha256':digest(ROOT/DESCRIPTOR),
                  'provenance':provenance(d),'base':BASE,
                  'test_sources_sha256':{p:digest(ROOT/p) for p in ALLOWED if (ROOT/p).is_file() and not p.startswith(DOC)},
                  'ability_checkpoint':{'branch':'codex/ability-audit-v1','functional_sha':'72548cde','resume_note_commit':'5d5f8ae','integrated_here':False}}
        write(out/'inputs.json',inputs)
        os.environ['POKEMON_CALVO_NODE'] = str(Path(args.node).resolve())
        sys.path.insert(0,str(ROOT/'tools/distribution'))
        from verify_update import execute, prepare_output_dirs
        prepare_output_dirs(SCRIPT)
        execution = execute('item_automation', [args.godot,'--headless','--path',str(ROOT),'--script','res://'+SCRIPT,'--',out.relative_to(ROOT).as_posix()],out,SCRIPT)
        receipt['execution'] = execution
        report = read(out/'godot.json')
        receipt.update(checks=report.get('checks',0),godot_report='godot.json',scenario_results=report.get('scenarios',[]))
        validate_report(d,report,out)
        if execution['exit_code'] != 0: raise ValueError('Godot process failed')
        # Preserve known process-lifecycle diagnostics verbatim; never suppress
        # script/parser/assertion failures or misreport a clean engine console.
        log = (out/'item_automation.log').read_text(encoding='utf-8',errors='replace')
        pid_lines = [s for s in log.splitlines() if re.search(r'ERROR: The process .+ does not exist or is not a child',s)]
        receipt['worker_pid_diagnostics'] = pid_lines
        if execution['status'] != 'PASS':
            if not pid_lines or re.search(r'SCRIPT ERROR|Parse Error|timeout',log):
                raise ValueError('Execution diagnostics require investigation: '+repr(execution))
            unexpected = [s for s in log.splitlines() if 'ERROR:' in s and s not in pid_lines]
            if unexpected: raise ValueError('Unexpected engine errors: '+repr(unexpected))
            receipt['execution_classification_note'] = 'Assertions passed; known PID lifecycle errors remain recorded technical debt, not a clean console.'
        after = guard()
        if before['runtime_hashes'] != after['runtime_hashes'] or before['absent_skip_worktree'] != after['absent_skip_worktree']:
            raise ValueError('Protected runtime or absent snapshots changed')
        for p,sha in inputs['test_sources_sha256'].items():
            if digest(ROOT/p) != sha: raise ValueError('Test source changed while executing: '+p)
        receipt.update(status='SCOPED_VERIFIED',checks=report['checks'],functional_sha=inputs['functional_sha'],
                       checkout_sha=checkout,run_url=inputs['run_url'],items=3,scenarios=15,
                       per_item=[{'id':s['id'],'status':'SCOPED_VERIFIED','scenarios':[r for r in report['scenarios'] if r['id']==s['id']]} for s in d['items']],
                       provenance=inputs['provenance'],protected={'runtime_files':len(after['runtime_hashes']),'absent_skip_worktree':after['absent_skip_worktree'], 'outside_allowlist_changed':False,'engine_generated_untracked_uids':after['engine_generated_untracked_uids']},
                       test_sources_sha256=inputs['test_sources_sha256'],descriptor_sha256=inputs['descriptor_sha256'],limitations=report['limits'])
    except Exception as e:
        receipt['errors'].append(str(e))
    write(out/'results.json',receipt)
    write(ROOT/'.godot/item_automation_v28/latest.json',{'status':receipt['status'],'results':str(out/'results.json')})
    print('ITEM_AUTOMATION_V28',receipt['status'],'checks='+str(receipt.get('checks',0)),out,flush=True)
    if receipt['errors']: print(json.dumps(receipt['errors'],ensure_ascii=True))
    return 0 if receipt['status']=='SCOPED_VERIFIED' else 1


if __name__ == '__main__': raise SystemExit(main())
