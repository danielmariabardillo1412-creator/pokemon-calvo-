"""Entry-item contracts and raw-evidence predicates; no simulation or mutation."""
import json
from automation_contracts_v28 import _native_row

FAMILY='entry_hazard_items'
IDS={'air_balloon','heavy_duty_boots'}
HAZARDS={'stealth_rock_reentry':('stealthrock','stealth_rock'),'spikes_reentry':('spikes','spikes'),
         'toxic_spikes_reentry':('toxicspikes','toxic_spikes'),'sticky_web_reentry':('stickyweb','sticky_web'),
         'no_hazard_control':('','growl')}
BALLOON={
 'ground_break_ground':(['earthquake','tackle','amnesia'],['move 1','move 2','move 1'],['ground','break','ground']),
 'status_then_ground':(['growl','earthquake','amnesia'],['move 1','move 2'],['status','ground']),
 'special_break_ground':(['water_gun','earthquake','amnesia'],['move 1','move 2'],['break','ground'])}
SOURCE_BLOBS={'air_balloon':'c1f399f00287d70a50a06ecd062b069f96057b0b','heavy_duty_boots':'2ccf41014b4aa2de1d28c829f22088ceed04d059'}


def source_metadata_supported(id, original, blob):
    num,api=(541,584) if id=='air_balloon' else (1120,1178)
    return (id in IDS and blob==SOURCE_BLOBS[id] and original.get('id')==api and original.get('name')==id.replace('_','-')
            and original.get('category',{}).get('name')=='held-items' and original.get('attributes')==[]
            and bool(original.get('game_indices')) and all(x['game_index']==num for x in original['game_indices']))


def validate_descriptor(d):
    if set(d)!={'schema_version','family','format','seed','level','actor_species','damage_target','physical_move','variants','items'}:
        raise ValueError('Unknown/missing entry descriptor field')
    if (d['schema_version']!=3 or d['family']!=FAMILY or d['format']!='gen9calvounifiedv1' or d['seed']!=[23,19,29,43]
        or d['level']!=100 or d['actor_species']!='mew' or d['damage_target']!='mew' or d['physical_move']!='amnesia'
        or d['variants']!=['active','none','reserve']): raise ValueError('Unreviewed entry fixture/control')
    if len(d['items'])!=2 or {s['id'] for s in d['items']}!=IDS: raise ValueError('Missing/duplicate/unreviewed entry item')
    for spec in d['items']:
        if set(spec)!={'id','api_id','consumption','own_moves','cases'} or spec['own_moves']!=['amnesia','seismic_toss']: raise ValueError('Invalid native moves/item fields')
        balloon=spec['id']=='air_balloon'
        if (spec['api_id']!=(584 if balloon else 1178) or spec['consumption']!=('on_damaging_hit' if balloon else 'retained')
            or len(spec['cases'])!=(3 if balloon else 5) or {c['id'] for c in spec['cases']}!=set(BALLOON if balloon else HAZARDS)):
            raise ValueError('Missing trigger/negative control')
        for c in spec['cases']:
            if balloon:
                moves,commands,phases=BALLOON[c['id']]
                if set(c)!={'id','op','foe_moves','p1','p2','phases'} or c['op']!='balloon_transition' or c['foe_moves']!=moves or c['p1']!=['move 1']*len(commands) or c['p2']!=commands or c['phases']!=phases: raise ValueError('Invalid pop/immunity timeline')
            else:
                hazard,move=HAZARDS[c['id']]; moves=[move,'amnesia','growl' if hazard else 'reflect']
                if set(c)!={'id','op','hazard','foe_moves'} or c['op']!='hazard_reentry' or c['hazard']!=hazard or c['foe_moves']!=moves: raise ValueError('Invalid real hazard trigger')
    return d


def check_frames(spec,c,mode,frames):
    p1=c.get('p1',['move 1','switch_reserve','switch_own','switch_reserve','switch_own'])
    p2=c.get('p2',['move 1','move 2','move 2','move 2','move 2'])
    if len(frames)!=len(p1): raise ValueError('Missing entry/withdrawal/reentry')
    for i,f in enumerate(frames):
        if f['p1']!=p1[i] or f['p2']!=p2[i]: raise ValueError('Wrong legal turn input')
        a,b=f['before'],f['after']
        if i and a!=frames[i-1]['after']: raise ValueError('State discontinuity between turns')
        if c['op']=='balloon_transition':
            loss=a['own']['hp']-b['own']['hp']; held=a['own']['item']=='airballoon';phase=c['phases'][i]
            if phase=='ground' and not (loss==0 if held else loss>0): raise ValueError('Ground immunity/loss not activated')
            if phase=='status' and loss!=0: raise ValueError('Invalid status damage')
            if phase=='break' and loss<=0: raise ValueError('No actual breaking hit')
            popped=held and phase=='break'
            if b['own']['item']!=('' if popped else a['own']['item']): raise ValueError('Wrong item transition')
            if popped and (not b['own']['consumed'] or not any(l.startswith('|-enditem|p1a:') and '|Air Balloon' in l for l in f['log'])):
                raise ValueError('Pop not observed in native protocol')
        else:
            hazard=c['hazard']
            if (hazard and hazard not in b['hazards']) or (not hazard and b['hazards']): raise ValueError('Hazards not actually present/control polluted')
            if i==0:
                if a['hazards']: raise ValueError('Hazards injected before move')
                if hazard and not any(l.startswith('|-sidestart|p1:') for l in f['log']): raise ValueError('No real hazard placement notification')
                continue
            incoming='reserve' if i in [1,3] else 'own'
            if b['active_id']!=incoming: raise ValueError('Wrong reentry owner')
            x,y=a[incoming],b[incoming]
            if not hazard or x['item']=='heavydutyboots':
                if x['hp']!=y['hp'] or y['status'] or y['spe']!=0: raise ValueError('Protected/control entry has hazard effect')
            elif hazard in ['spikes','stealthrock']:
                if x['hp']-y['hp']!=x['max_hp']//8: raise ValueError('Unprotected entry damage missing')
            elif hazard=='toxicspikes':
                if y['status']!='poison' or y['hp']>=x['hp']: raise ValueError('Unprotected entry poison missing')
            elif y['spe']!=-1 or y['hp']!=x['hp']: raise ValueError('Unprotected web effect missing')
            if any(a[id]['item']!=b[id]['item'] for id in ['own','reserve']): raise ValueError('Boots unexpectedly lost')
    # Equipment controls must be present at the start, not just asserted in JSON.
    for id in ['own','reserve']:
        expected=spec['id'].replace('_','') if mode==('active' if id=='own' else 'reserve') else ''
        if frames[0]['before'][id]['item']!=expected: raise ValueError('Wrong native initial equipment owner')
    return True


def validate_collection(owner,item,own,other,mode,consumed,hp=None):
    creatures={c['instance_id']:c for c in owner['creatures']}
    a,b=creatures[own],creatures[other]
    if a['held_item_id']!=(item if mode=='active' else '') or b['held_item_id']!=(item if mode=='reserve' else ''):
        raise ValueError('Saved equipment has wrong owner')
    if a['held_item_consumed']!=consumed or b['held_item_consumed']: raise ValueError('Saved consumption differs')
    quantity=owner['inventory']['quantities'].get(item,0)
    total=quantity+sum(c['held_item_id']==item and not c['held_item_consumed'] for c in creatures.values())
    if total!=(1 if consumed else 2) or quantity!=(2 if mode=='none' else 1): raise ValueError('Saved physical stock differs')
    if hp is not None and a['current_hp']!=hp: raise ValueError('Saved HP differs from terminal native state')


def validate_report(d,report,out,digest):
    expected={(s['id'],c['id']) for s in d['items'] for c in s['cases']} | {(s['id'],'map_bag_owner_save') for s in d['items']}
    rows=report.get('scenarios',[])
    if report.get('status')!='SCOPED_VERIFIED' or report.get('errors') or len(rows)!=len(expected) or report.get('checks',0)<1400 or {(r['id'],r['scenario']) for r in rows}!=expected:
        raise ValueError('Missing/failed third-family coverage')
    specs={s['id']:s for s in d['items']}
    def evidence(v,name,sha):
        path=(out/name).resolve()
        if not name or path.parent!=out.resolve() or not path.is_file() or digest(path)!=sha: raise ValueError('Missing/corrupt entry evidence')
        return json.loads(path.read_text(encoding='utf-8'))
    for r in rows:
        if r.get('status')!='SCOPED_VERIFIED' or r.get('errors') or r.get('checks',0)<10: raise ValueError('Unverified entry row')
        spec=specs[r['id']];obs=r['observed']
        if r['scenario']=='map_bag_owner_save':
            saved=evidence(obs,obs.get('map_save',''),obs.get('sha256'))
            consume=spec['id']=='air_balloon'
            if not obs.get('valid') or obs.get('physical_units')!=(1 if consume else 2) or obs.get('consumed_transition')!=consume or obs.get('battle_owner')==obs.get('second_owner'): raise ValueError('Physical consumption/persistence missing')
            validate_collection(saved['payload']['collection'],spec['id'],obs['battle_owner'],obs['second_owner'],'active',consume)
            if consume:
                receipt=obs['breaking_evidence'];raw=evidence(receipt,receipt.get('evidence',''),receipt.get('sha256'))
                a,b=(_native_row(raw[k],obs['battle_owner']) for k in ['before','after'])
                log=raw['after']['native']['native']['log'][len(raw['before']['native']['native']['log']):]
                if a['item']!='airballoon' or b['item']!='' or b['hp']>=a['hp'] or not any(l.startswith('|-enditem|p1a:') and '|Air Balloon' in l for l in log): raise ValueError('Map breaking hit not observed')
            continue
        if set(obs)!=set(d['variants']): raise ValueError('Missing owner/absent control')
        c=next(c for c in spec['cases'] if c['id']==r['scenario'])
        for mode,v in obs.items():
            if not v.get('valid') or not v.get('restored'): raise ValueError('Unexecuted/unrestored native scenario')
            raw=evidence(v,v.get('evidence',''),v.get('sha256'))
            if raw['frames']!=v['frames']: raise ValueError('Report differs from raw frames')
            check_frames(spec,c,mode,v['frames'])
            for f in v['frames']:
                native=f['checkpoint']['native']['native']
                if native['sides'][0]['sideConditions']!=f['after']['hazards']: raise ValueError('Hazards differ from native state')
                for id in ['own','reserve']:
                    row=_native_row(f['checkpoint'],id);m=f['after'][id]
                    status={'psn':'poison','tox':'badly_poisoned'}.get(row['status'],row['status'])
                    if row['hp']!=m['hp'] or row['item']!=m['item'] or status!=m['status'] or row['boosts']['spe']!=m['spe']: raise ValueError('Observation differs from checkpoint')
            owner=evidence(v,v.get('owner_evidence',''),v.get('owner_sha256'))
            if owner['owner']!=raw['owner_after']: raise ValueError('Campaign save differs from settlement')
            expected_units=1 if v['frames'][-1]['after']['own']['consumed'] else 2
            if v['settled_units']!=expected_units or v['consumed']!=(expected_units==1) or raw['expected_units']!=expected_units: raise ValueError('Consumption not preserved')
            validate_collection(owner['owner'],spec['id'],'own','reserve',mode,expected_units==1,_native_row(raw['terminal'],'own')['hp'])
    return True
