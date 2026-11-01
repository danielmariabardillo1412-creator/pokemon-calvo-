"""New declarative assertion contracts; no simulator, storage or execution code."""
import json

PASSIVE_IDS = {'leftovers', 'life_orb', 'rocky_helmet'}
MAP = 'map_bag_owner_save'
REVIEWED = {
 'leftovers': (211, {'op':'residual_heal','divisor':16,'basis':'holder_max_hp'},
               {'heal_partial','heal_cap','full_hp_control','heal_switched_owner'}),
 'life_orb': (247, {'op':'damage_recoil','divisor':10,'basis':'holder_max_hp'},
              {'physical_boost_recoil','special_boost_recoil','status_no_recoil','immune_no_recoil'}),
 'rocky_helmet': (583, {'op':'contact_retaliation','divisor':6,'basis':'attacker_max_hp'},
                  {'contact_damage','special_no_contact','physical_no_contact','contact_switched_owner'}),
}


def reviewed_attribute_gap(item_id, original):
    # This pinned PokeAPI record has no attributes; its explicit held-effect
    # text and Gen V-IX indices still identify the official held item.
    english=[r.get('effect','') for r in original.get('effect_entries',[]) if r.get('language',{}).get('name')=='en']
    indices=original.get('game_indices',[])
    return (item_id=='rocky_helmet' and original.get('id')==583 and original.get('name')=='rocky-helmet'
            and original.get('attributes')==[] and original.get('category',{}).get('name')=='held-items'
            and {r.get('generation',{}).get('name') for r in indices}=={'generation-v','generation-vi','generation-vii','generation-viii','generation-ix'}
            and all(r.get('game_index')==540 for r in indices)
            and any('Held' in text and 'contact move' in text and '1/6' in text for text in english))


def scenarios(d):
    return {(s['id'], c['id']) for s in d['items'] for c in s['cases']} | {(s['id'], MAP) for s in d['items']}


def validate_passive_descriptor(d):
    fields={'schema_version','family','format','seed','level','actor_species','damage_target','physical_move','consumption','variants','items'}
    if set(d)!=fields or d['schema_version']!=2 or d['family']!='passive_reactive_held_items':
        raise ValueError('Unknown passive descriptor fields/version/family')
    if (d['format']!='gen9calvounifiedv1' or d['level']!=100 or d['actor_species']!='mew' or
        d['damage_target']!='mew' or d['physical_move']!='tackle' or d['consumption']!='retained' or
        d['variants']!=['active','none','reserve'] or d['seed']!=[23,19,29,43]):
        raise ValueError('Unreviewed passive fixture/control')
    if len(d['items'])!=3 or {s['id'] for s in d['items']}!=PASSIVE_IDS:
        raise ValueError('Only reviewed passive/reactive IDs authorized')
    for spec in d['items']:
        if set(spec)!={'id','api_id','effect','cases'}: raise ValueError('Unknown item field')
        api,effect,ids=REVIEWED[spec['id']]
        if spec['api_id']!=api or spec['effect']!=effect: raise ValueError('Unreviewed effect contract')
        if len(spec['cases'])!=4 or {c['id'] for c in spec['cases']}!=ids: raise ValueError('Omitted/duplicate trigger')
        for c in spec['cases']:
            fields={'id','hp','target','own_move','foe_move','foe_species','commands'}
            if spec['id']!='leftovers': fields.add('activates')
            if set(c)!=fields: raise ValueError('Unknown trigger field')
            target='reserve' if 'switched_owner' in c['id'] else 'own'
            if c['target']!=target: raise ValueError('Wrong owner condition')
            two=c['id'] in {'heal_partial','heal_switched_owner','physical_boost_recoil','contact_damage','contact_switched_owner'}
            commands=(['switch_to_reserve','move 1'] if target=='reserve' else ['move 1']*(2 if two else 1))
            if c['commands']!=commands: raise ValueError('Unreviewed trigger/timeline')
            hp='half' if c['id'] in {'heal_partial','heal_switched_owner'} else ('near_full' if c['id']=='heal_cap' else 'full')
            own='reflect' if spec['id']=='leftovers' or c['id']=='status_no_recoil' else ('amnesia' if spec['id']=='rocky_helmet' else ('water_gun' if c['id']=='special_boost_recoil' else 'tackle'))
            foe={'special_no_contact':'water_gun','physical_no_contact':'earthquake'}.get(c['id'],'tackle' if spec['id']=='rocky_helmet' else 'amnesia')
            if c['hp']!=hp or c['own_move']!=own or c['foe_move']!=foe or c['foe_species']!=('gengar' if c['id']=='immune_no_recoil' else 'mew'):
                raise ValueError('Trigger does not isolate declared effect')
            if 'activates' in c and (type(c['activates']) is not bool or c['activates']!=(c['id'] in {'physical_boost_recoil','special_boost_recoil','contact_damage','contact_switched_owner'})):
                raise ValueError('Wrong activation expectation')
    return d


def check_observations(spec, case, obs):
    """Independently evaluate measured deltas, never regenerate damage rules."""
    mode_owner='active' if case['target']=='own' else 'reserve'
    for mode in ['active','none','reserve']:
        v=obs[mode]
        if v.get('valid') is not True or v.get('restored') is not True: raise ValueError('Unexecuted/unrestored effect')
        if len(v['frames'])!=len(case['commands']): raise ValueError('Incomplete timeline')
        for i,frame in enumerate(v['frames']):
            a,b=frame['before'],frame['after']; p=obs['none']['frames'][i]
            if frame['command']!=case['commands'][i] or b['active_id']!=case['target']: raise ValueError('Wrong action/active owner')
            if not (0<a['target_hp']<=a['target_max_hp'] and 0<=b['target_hp']<=b['target_max_hp']): raise ValueError('Invalid HP observation')
            delta=b['target_hp']-a['target_hp']; damage=a['foe_hp']-b['foe_hp']; plain=p['before']['foe_hp']-p['after']['foe_hp']
            enabled=mode==mode_owner
            op=spec['effect']['op']; divisor=spec['effect']['divisor']
            if op=='residual_heal':
                wanted=min(a['target_max_hp']//divisor,a['target_max_hp']-a['target_hp']) if enabled else 0
                if delta!=wanted or damage!=0: raise ValueError('Specific residual recovery/cap failed')
            elif op=='damage_recoil':
                enabled=enabled and case['activates']
                if -delta!=(a['target_max_hp']//divisor if enabled else 0): raise ValueError('Recoil/negative control failed')
                if case['activates']:
                    if plain<=0 or not (damage>plain if enabled else damage==plain): raise ValueError('Specific damage boost/owner failed')
                elif damage!=0 or plain!=0: raise ValueError('Status/immune negative control failed')
            elif op=='contact_retaliation':
                wanted=a['foe_max_hp']//divisor if enabled and case['activates'] else 0
                if damage!=wanted or delta>=0 or delta!=p['after']['target_hp']-p['before']['target_hp']:
                    raise ValueError('Contact-specific retaliation/control failed')
            else: raise ValueError('Unknown predicate')
    return True


def _native_row(snapshot, identity):
    mapping=snapshot['native']['identities']
    for side in snapshot['native']['native']['sides']:
        for c in side['pokemon']:
            if mapping.get(c['set']['name'])==identity: return c
    raise ValueError('Missing native owner '+identity)


def validate_passive_report(d, report, out, digest):
    rows=report.get('scenarios',[])
    if report.get('status')!='SCOPED_VERIFIED' or report.get('errors') or len(rows)!=15 or {(r['id'],r['scenario']) for r in rows}!=scenarios(d):
        raise ValueError('Incomplete/failed passive scenario coverage')
    by_id={s['id']:s for s in d['items']}
    for r in rows:
        if r.get('status')!='SCOPED_VERIFIED' or r.get('errors') or r.get('checks',0)<10: raise ValueError('Unverified passive row')
        obs=r['observed']; spec=by_id[r['id']]
        variants=[obs] if r['scenario']==MAP else list(obs.values())
        if r['scenario']!=MAP and set(obs)!=set(d['variants']): raise ValueError('Missing owner/negative control')
        for v in variants:
            name=v.get('evidence',v.get('map_save','')); p=(out/name).resolve()
            if v.get('valid') is not True or not name or p.parent!=out.resolve() or not p.is_file() or digest(p)!=v.get('sha256'):
                raise ValueError('Missing/corrupt raw passive evidence')
        if r['scenario']==MAP:
            if obs.get('physical_units')!=2 or not obs.get('battle_owner') or obs.get('battle_owner')==obs.get('second_owner'): raise ValueError('Physical owner/units missing')
            continue
        case=next(c for c in spec['cases'] if c['id']==r['scenario'])
        check_observations(spec,case,obs)
        for mode,v in obs.items():
            raw=json.loads((out/v['evidence']).read_text(encoding='utf-8'))
            if raw['frames']!=v['frames']: raise ValueError('Report differs from raw timeline')
            for edge,metrics in [('before',v['frames'][0]['before']),('after',v['frames'][-1]['after'])]:
                target=_native_row(raw[edge],case['target']); foe=_native_row(raw[edge],'foe')
                if target['hp']!=metrics['target_hp'] or target['maxhp']!=metrics['target_max_hp'] or foe['hp']!=metrics['foe_hp'] or foe['maxhp']!=metrics['foe_max_hp']:
                    raise ValueError('Scalar observations differ from native checkpoint')
                for cid in ['own','reserve']:
                    item=r['id'].replace('_','') if (mode=='active' and cid=='own' or mode=='reserve' and cid=='reserve') else ''
                    if _native_row(raw[edge],cid)['item']!=item: raise ValueError('Native held owner/retention differs')
    return True
