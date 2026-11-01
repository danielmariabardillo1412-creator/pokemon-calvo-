"""Minimal replay feasibility: original native oracles + shared V28 integration."""
import argparse
import json
import os
import subprocess
import time
from pathlib import Path
import automation_v28 as common

ROOT=common.ROOT
# Three compatible type boosters extend the original V2 causal replay without new effect rules.
PILOT_TYPE_IDS=('silk_scarf','soft_sand','spell_tag')
IDS=['black_glasses','colbur_berry','toxic_orb','sticky_barb',*PILOT_TYPE_IDS]
SCRIPT='tests/gameplay/item_case_replay_v28.gd'


def select(sources,ids,type_ids=()):
    if len(set(ids))!=len(ids) or not set(type_ids)<=set(ids):
        raise ValueError('Duplicate IDs or unrequested type pilots')
    selected=[]
    for rows,proof in sources:
        passed={r['case_id']:r['status'] for r in proof['results']}
        for row in rows:
            if row['id'] not in ids: continue
            if passed.get(row['case_id'])!='NATIVE_SCENARIO_PASS' or not row['commands'] or len(row['commands'])!=len(row['steps']):
                raise ValueError('Missing native assertion proof/commands: '+row['case_id'])
            selected.append(row)
    if {r['id'] for r in selected}!=set(ids) or len({r['case_id'] for r in selected})!=len(selected):
        raise ValueError('Missing item or duplicate case')
    expected_pairs={(family,seed) for family in ('type_boost','type_boost_nonmatching') for seed in (1,19)}
    for item in type_ids:
        actual=[(row.get('family'),row.get('seed')) for row in selected if row['id']==item]
        if len(actual)!=len(expected_pairs) or set(actual)!=expected_pairs:
            raise ValueError('Missing or duplicated original matching/nonmatching proof: '+item)
    return selected


def validate(rows,report,out):
    if not rows or report.get('checks',0)<=0 or report.get('status')!='REPLAY_INTEGRATION_PASS' or report.get('errors') or report.get('full_item_certification') is not False:
        raise ValueError('Failed/overclaimed replay')
    actual=report['cases']
    if len(actual)!=len(rows) or {r['case_id'] for r in actual}!={r['case_id'] for r in rows}: raise ValueError('Missing replay')
    originals={r['case_id']:r for r in rows}
    for r in actual:
        v=r['observed'];p=(out/v['evidence']).resolve()
        if r['errors'] or not v['valid'] or p.parent!=out.resolve() or common.digest(p)!=v['sha256']: raise ValueError('Invalid raw replay evidence')
        raw=common.read(p);expected=originals[r['case_id']]['steps'][-1]['state_hash']
        if v['final_hash']!=expected or raw['matched_replay_hash']!=expected or raw['checkpoint']['native']!=originals[r['case_id']]['steps'][-1]['snapshot']: raise ValueError('Replay differs from original asserted result')
        owner=raw['owner_after'];item=r['id']
        quantity=owner['inventory']['quantities'].get(item,0)
        units=quantity+sum(c['held_item_id']==item and not c['held_item_consumed'] for c in owner['creatures'])
        if units!=v['physical_units'] or units!=raw['physical_units'] or quantity!=1: raise ValueError('Persisted stock differs')
        native={c['instance_id']:c for c in originals[r['case_id']]['steps'][-1]['roster'][0]['pokemon']}
        for c in owner['creatures']:
            n=native[c['instance_id']]
            held='' if c['held_item_consumed'] else c['held_item_id'].replace('_','')
            if c['current_hp']!=n.get('persistent_hp',n['hp']) or held!=n['item'] or c['status_state']['persistent_id']!=n['status_id']:
                raise ValueError('Persisted HP/item/status differs from asserted native result')
    if set(report['maps'])!={r['id'] for r in rows}: raise ValueError('Missing map/bag route')
    for v in report['maps'].values():
        p=(out/v['map_save']).resolve()
        if not v['valid'] or p.parent!=out.resolve() or common.digest(p)!=v['sha256']: raise ValueError('Invalid map evidence')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',default='C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe')
    parser.add_argument('--node',default='D:/Herramientas/NodeJS/node.exe')
    args=parser.parse_args();out=ROOT/'.godot/item_automation_v28/runs'/('replay_'+str(time.time_ns()));out.mkdir(parents=True)
    before=common.guard();timings=[]
    os.environ['POKEMON_CALVO_NODE']=args.node
    def run(command,name):
        start=time.monotonic()
        with (out/(name+'.log')).open('w',encoding='utf-8') as log:
            result=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=480,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
        text=(out/(name+'.log')).read_text(encoding='utf-8',errors='replace')
        if result.returncode or 'SCRIPT ERROR' in text or any('ERROR:' in l and not ('ERROR: The process ' in l and 'does not exist or is not a child' in l) for l in text.splitlines()): raise ValueError(name+' failed; inspect log')
        timings.append({'stage':name,'seconds':round(time.monotonic()-start,2),'exit_code':result.returncode,'pid_diagnostics':sum('ERROR: The process ' in l for l in text.splitlines())})
    sources=[];originals=[];hashes={}
    for version in [2,3]:
        template=f'tests/gameplay/item_effect_templates_v{version}.gd';generator=f'tools/item_audit/held_effect_sweep_v{version}.cjs'
        run([args.godot,'--headless','--path',str(ROOT),'--script','res://'+template],f'templates_v{version}')
        run([args.node,generator],f'native_v{version}')
        path=f'.godot/item_verification_v{version}/';sources.append({'cases':path+'cases.json','proof':path+'native.json'})
        originals.append((common.read(ROOT/(path+'cases.json')),common.read(ROOT/(path+'native.json'))))
        for name in [template,generator,path+'cases.json',path+'native.json',path+'prototypes.json']: hashes[name]=common.digest(ROOT/name)
    rows=select(originals,IDS,type_ids=PILOT_TYPE_IDS)
    common.write(out/'selected_cases.json',rows)
    meta={'ids':IDS,'type_pilot_ids':list(PILOT_TYPE_IDS),'case_count':len(rows),'sources':sources,'sources_sha256':hashes,'functional_sha':os.getenv('ITEM_AUTOMATION_FUNCTIONAL_SHA') or common.git('rev-parse','HEAD')}
    common.write(out/'inputs.json',meta)
    run([args.godot,'--headless','--path',str(ROOT),'--script','res://'+SCRIPT,'--',out.relative_to(ROOT).as_posix()],'replay')
    report=common.read(out/'godot.json');validate(rows,report,out)
    after=common.guard()
    if before['runtime_hashes']!=after['runtime_hashes'] or before['absent_skip_worktree']!=after['absent_skip_worktree'] or any(common.digest(ROOT/p)!=sha for p,sha in hashes.items()): raise ValueError('Protected sources changed')
    result={'verdict':'VIABLE_SCOPED_REPLAY_NOT_FULL_CERTIFICATION','functional_sha':meta['functional_sha'],'ids':IDS,'type_pilot_ids':list(PILOT_TYPE_IDS),'cases':len(rows),'checks':report['checks'],'full_item_certification':False,'counts_unchanged':[27,30,4],'timings':timings,'source_sha256':hashes,'per_item':{id:[r['case_id'] for r in rows if r['id']==id] for id in IDS},'code_sha256':{p:common.digest(ROOT/p) for p in [SCRIPT,SCRIPT+'.uid','tools/item_audit/replay_v28.py','tests/tools/test_item_case_replay_v28.py']},'limitations':['Native assertion closures are executed by original generators, not serialized in cases.json','Replay exact hashes transfer those bounded native proofs; not an independent complete Pokemon oracle','FLED via existing Poke Doll checks settlement, not victory/defeat/capture','No new absent/wrong-owner/immunity/transfer-to-owned-recipient scenarios; the type pilots reuse V2 matching/nonmatching controls','Map/bag routes do not certify all effect triggers','PID lifecycle and GPU remain independent']}
    common.write(out/'results.json',result)
    print('ITEM_CASE_REPLAY_V28 VIABLE cases='+str(len(rows))+' checks='+str(report['checks'])+' '+str(out),flush=True)


if __name__=='__main__': main()
