"""Deterministic, explicit synthetic fixtures for external battle comparisons."""
from __future__ import annotations
import copy
import itertools

STATS = ('attack', 'defense', 'special_attack', 'special_defense', 'speed', 'accuracy', 'evasion')
MOVES = ('haze', 'topsy_turvy', 'heart_swap', 'power_swap', 'guard_swap',
         'acupressure', 'clear_smog', 'spectral_thief')
SCHEMA = 1
FIELDS = ('actor.stages', 'target.stages', 'actor.pp_spent', 'actor.move_used',
          'actor.substitute_present', 'target.substitute_present', 'benches')
FIXED_MOVES = ('dragon_rage', 'sonic_boom', 'seismic_toss', 'night_shade', 'super_fang', 'natures_madness', 'ruination')
FIXED_FIELDS = ('actor.hp', 'target.hp', 'actor.substitute_hp', 'target.substitute_hp',
                'actor.knocked_out', 'target.knocked_out', 'actor.pp_spent', 'actor.move_used',
                'actor.substitute_present', 'target.substitute_present', 'benches')
VARIABLE_MOVES = ('electro_ball','gyro_ball','flail','reversal','crush_grip','wring_out','hard_press','return','frustration','trump_card','punishment')
VARIABLE_FIELDS = ('power', 'contact', 'hit_received', 'actor.pp_spent', 'actor.move_used', 'benches')
BINDING_MOVES = ('bind','wrap','fire_spin','whirlpool','clamp','sand_tomb','magma_storm','infestation','snap_trap','thunder_cage')
BINDING_FIELDS = ('binding', 'lifecycle', 'actor.pp_spent', 'actor.move_used', 'benches')
HEALING_MOVES = ('aromatherapy','heal_bell','refresh','life_dew','jungle_healing','lunar_blessing','purify','rest')
HEALING_FIELDS = ('actor.hp','actor.status_id','target.hp','target.status_id','healing_benches','actor.pp_spent','actor.move_used')
FAMILY_FIELDS = {'stat_stages': FIELDS, 'fixed_damage': FIXED_FIELDS, 'variable_power': VARIABLE_FIELDS, 'binding': BINDING_FIELDS, 'healing': HEALING_FIELDS}
PATTERNS = {
    'mixed': ([-3, 2, -1, 4, -2, 3, -4], [2, -3, 4, -1, 3, -2, 1]),
    'neutral': ([0] * 7, [0] * 7),
    'positive': ([1, 2, 3, 4, 5, 3, 1], [6, 5, 4, 3, 2, 1, 3]),
    'negative': ([-1, -2, -3, -4, -5, -3, -1], [-6, -5, -4, -3, -2, -1, -3]),
    'extremes': ([-6, 6, -6, 6, -6, 6, -6], [6, -6, 6, -6, 6, -6, 6]),
    'capped': ([6] * 7, [6] * 7),
    'near_cap': ([5] * 7, [3] * 7),
}


def stages(values):
    return dict(zip(STATS, values, strict=True))


def make_case(move, label, side, seed, definitions, own=None, other=None, **changes):
    first, second = PATTERNS['mixed'] if own is None else (own, other)
    case = {'id': f'stat_stages/{move}/{label}/{side}/{seed}', 'family': 'stat_stages',
            'move_id': move, 'actor_side': side, 'seed': seed, 'compare': list(FIELDS),
            'contract': {k: definitions[move][k] for k in ('power', 'type_id', 'damage_class', 'accuracy', 'priority', 'pp')},
            'actor': {'species_id': 'mew', 'ability_id': '', 'stages': stages(first), 'substitute_hp': 0},
            'target': {'species_id': 'blastoise', 'ability_id': '', 'stages': stages(second), 'substitute_hp': 0},
            'bench_stages': {'actor': stages([2, -1, 3, 0, -4, 1, 0]), 'target': stages([-2, 1, 0, 3, 1, -1, 0])}}
    for key, value in changes.items():
        owner, field = key.split('__', 1)
        case[owner][field] = value
    # The adapters use different RNGs. This family compares successful strikes,
    # not independent accuracy rolls; both engines must have a guaranteed hit.
    if move == 'spectral_thief':
        case['actor']['stages']['accuracy'] = max(case['actor']['stages']['accuracy'], case['target']['stages']['evasion'])
    return case


def stat_stage_cases(definitions, seeds=(1, 7, 19)):
    result = []
    for move, (label, pair), side, seed in itertools.product(MOVES, PATTERNS.items(), ('side_a', 'side_b'), seeds):
        own, other = map(list, pair)
        # Compare random Acupressure only when its selection is unambiguous.
        # Different RNG algorithms cannot be aligned by using the same seed.
        if move == 'acupressure' and label != 'capped':
            stat = list(PATTERNS).index(label) % 7
            if label == 'extremes': stat = 5  # accuracy; speed also covered by substitute/ability cases
            value = own[stat]
            if value == 6: value = 5
            own = [6] * 7
            own[stat] = value
            label += f'_single_{STATS[stat]}'
        result.append(make_case(move, label, side, seed, definitions, own, other))
    for move, hp, side, seed in itertools.product(MOVES, (1, 500), ('side_a', 'side_b'), seeds):
        own, other = map(list, PATTERNS['mixed'])
        if move == 'acupressure': own = [6, 6, 6, 6, 0, 6, 6]
        result.append(make_case(move, f'substitute_{hp}', side, seed, definitions, own, other,
                                actor__substitute_hp=hp, target__substitute_hp=hp))
    for move, ability, side, seed in itertools.product(MOVES, ('simple', 'contrary'), ('side_a', 'side_b'), seeds):
        own, other = map(list, PATTERNS['mixed'])
        if move == 'acupressure': own = [6, 6, 6, 6, 0, 6, 6]
        result.append(make_case(move, ability, side, seed, definitions, own, other,
                                actor__ability_id=ability, target__ability_id=ability))
    for move, hp, side, seed in itertools.product(('topsy_turvy', 'clear_smog'), (1, 500), ('side_a', 'side_b'), seeds):
        result.append(make_case(move, f'infiltrator_{hp}', side, seed, definitions,
                                actor__ability_id='infiltrator', target__substitute_hp=hp))
    for own_hp, target_hp, side, seed in itertools.product((0, 500), (0, 500), ('side_a', 'side_b'), seeds):
        result.append(make_case('topsy_turvy', f'magic_bounce_{own_hp}_{target_hp}', side, seed, definitions,
                                actor__substitute_hp=own_hp, target__substitute_hp=target_hp,
                                target__ability_id='magic_bounce'))
    for move, hp, side, seed in itertools.product(('clear_smog', 'spectral_thief'), (0, 500), ('side_a', 'side_b'), seeds):
        result.append(make_case(move, f'type_immunity_{hp}', side, seed, definitions,
                                target__species_id='steelix' if move == 'clear_smog' else 'snorlax', target__substitute_hp=hp))
    return result


def validate_case(case):
    if not isinstance(case, dict) or not isinstance(case.get('id'), str) or not case['id']:
        raise ValueError('Missing case ID')
    family = case.get('family')
    if family not in FAMILY_FIELDS or case.get('move_id') not in {'stat_stages':MOVES, 'fixed_damage':FIXED_MOVES,'variable_power':VARIABLE_MOVES,'binding':BINDING_MOVES,'healing':HEALING_MOVES}.get(family, ()):
        raise ValueError(f'Unsupported fixture family/move: {case["id"]}')
    if case.get('actor_side') not in ('side_a', 'side_b'):
        raise ValueError('Invalid actor side')
    if type(case.get('seed')) is not int or not 1 <= case['seed'] <= 0xFFFFFFFF:
        raise ValueError('Invalid deterministic seed')
    if tuple(case.get('compare', [])) != FAMILY_FIELDS[family]:
        raise ValueError('Missing/unknown comparison fields')
    for owner in ('actor', 'target'):
        row = case.get(owner, {})
        if set(row.get('stages', {})) != set(STATS): raise ValueError('All seven stages are required')
        if any(type(v) is not int or not -6 <= v <= 6 for v in row['stages'].values()): raise ValueError('Invalid stage')
        if type(row.get('substitute_hp')) is not int or row['substitute_hp'] not in ((0, 1, 500) if family != 'fixed_damage' else (0, 1, 25, 500)): raise ValueError('Invalid substitute fixture')
        if not isinstance(row.get('species_id'), str) or not isinstance(row.get('ability_id'), str): raise ValueError('Invalid identity')
        if family == 'stat_stages':
            allowed_species = ('mew',) if owner == 'actor' else ('blastoise', 'steelix', 'snorlax')
            allowed_abilities = ('', 'simple', 'contrary', 'infiltrator') if owner == 'actor' else ('', 'simple', 'contrary', 'magic_bounce')
        elif family == 'fixed_damage':
            allowed_species = ('mew', 'dragonite', 'snorlax', 'machamp', 'gengar', 'togekiss', 'tyranitar') if owner == 'actor' else ('blastoise', 'steelix', 'snorlax', 'gengar', 'gardevoir', 'crobat', 'umbreon', 'machamp')
            allowed_abilities = ('', 'infiltrator', 'huge_power') if owner == 'actor' else ('', 'multiscale', 'iron_barbs')
            if type(row.get('level')) is not int or not 1 <= row['level'] <= 100:
                raise ValueError('Invalid fixture level')
            if type(row.get('hp')) is not int or not 1 <= row['hp'] <= 20000:
                raise ValueError('Invalid fixture HP')
        elif family == 'healing':
            if set(row) != {'species_id','ability_id','stages','substitute_hp','max_hp','hp','status_id'}: raise ValueError('Unknown healing input field')
            allowed_species = ('mew',) if owner == 'actor' else ('blastoise',)
            allowed_abilities = ('','infiltrator','insomnia','vital_spirit','comatose','sweet_veil','purifying_salt','soundproof','sap_sipper','good_as_gold') if owner == 'actor' else ('','magic_bounce','good_as_gold')
            if type(row.get('max_hp')) is not int or not 100 <= row['max_hp'] <= 107: raise ValueError('Invalid healing max HP')
            if type(row.get('hp')) is not int or not 1 <= row['hp'] <= row['max_hp']: raise ValueError('Invalid healing HP')
            if row.get('status_id') not in ('','burn','poison','badly_poisoned'): raise ValueError('Random action-preventing status is outside healing fixture contract')
        elif family == 'binding':
            allowed_species = ('mew',) if owner == 'actor' else ('blastoise','gengar','sandshrew')
            allowed_abilities = ('','infiltrator') if owner == 'actor' else ('','magic_guard')
            if type(row.get('max_hp')) is not int or not 256 <= row['max_hp'] <= 20000: raise ValueError('Invalid binding HP')
            if row.get('item_id') not in ('','binding_band','grip_claw','shed_shell','leftovers'): raise ValueError('Unsupported binding item')
        else:
            allowed_species = ('mew',) if owner == 'actor' else ('blastoise','snorlax','gengar','steelix','sandshrew')
            allowed_abilities = ('','infiltrator') if owner == 'actor' else ('',)
            for field, low, high in [('hp',1,20000),('max_hp',1,20000),('speed',1,10000),('friendship',0,255)]:
                if type(row.get(field)) is not int or not low <= row[field] <= high: raise ValueError('Invalid variable-power '+field)
            if row['hp'] > row['max_hp']: raise ValueError('HP exceeds maximum')
            if row.get('status_id') not in ('','paralysis') or owner == 'actor' and row['status_id']:
                raise ValueError('Random action prevention outside comparison scope')
            if owner == 'actor' and (type(row.get('pp')) is not int or not 1 <= row['pp'] <= case['contract']['pp']):
                raise ValueError('Invalid prepaid fixture PP')
        if row['species_id'] not in allowed_species or row['ability_id'] not in allowed_abilities:
            raise ValueError('Species/ability context is outside this adapter contract')
    if family == 'healing':
        if set(case.get('healing_bench', {})) != {'actor','target'}: raise ValueError('Missing healing bench')
        for row in case['healing_bench'].values():
            if set(row) != {'hp','status_id','ability_id'} or type(row['hp']) is not int or not 0 <= row['hp'] <= 101: raise ValueError('Invalid healing bench HP')
            if row['status_id'] not in ('','burn','poison','badly_poisoned','sleep','freeze','paralysis'): raise ValueError('Invalid healing bench status')
            if row['ability_id'] not in ('','soundproof','sap_sipper','good_as_gold'): raise ValueError('Unsupported healing bench ability')
    if set(case.get('bench_stages', {})) != {'actor', 'target'}:
        raise ValueError('Both bench stage fixtures are required')
    for row in case['bench_stages'].values():
        if set(row) != set(STATS) or any(type(v) is not int or not -6 <= v <= 6 for v in row.values()):
            raise ValueError('Invalid bench stages')
    contract = case.get('contract', {})
    if set(contract) != {'power', 'type_id', 'damage_class', 'accuracy', 'priority', 'pp'}:
        raise ValueError('Incomplete move contract')
    for key in ('power', 'accuracy', 'priority', 'pp'):
        if type(contract[key]) is not int: raise ValueError('Invalid numeric move contract')
    if not isinstance(contract['type_id'], str) or contract['damage_class'] not in ('status', 'physical', 'special'):
        raise ValueError('Invalid move type/category')
    if case['move_id'] == 'spectral_thief' and case['actor']['stages']['accuracy'] < case['target']['stages']['evasion']:
        raise ValueError('Independent accuracy rolls are outside this comparison contract')
    if case['move_id'] == 'acupressure' and sum(v < 6 for v in case['actor']['stages'].values()) > 1:
        raise ValueError('Random selection is outside this comparison contract')
    if family == 'fixed_damage' and (case['actor']['stages']['accuracy'] != 6 or case['target']['stages']['evasion'] != -6):
        raise ValueError('Fixed damage comparisons require guaranteed accuracy')
    if family == 'variable_power' and case['actor']['stages']['accuracy'] != 6:
        raise ValueError('Variable power comparisons require guaranteed accuracy')
    if family == 'binding' and (case['actor']['stages']['accuracy'] != 6 or case['target']['stages']['evasion'] != -6):
        raise ValueError('Binding comparisons require guaranteed accuracy')
    if family == 'binding' and (case.get('lifecycle_turns',1) not in (1,8) or case.get('lifecycle_turns',1) == 8 and case['actor']['item_id'] != 'grip_claw'):
        raise ValueError('Binding lifecycle requires the deterministic Grip Claw contract')
    return copy.deepcopy(case)


def validate_manifest(cases):
    if not isinstance(cases, list) or not cases: raise ValueError('No fixtures to compare')
    result = [validate_case(case) for case in cases]
    if len({case['id'] for case in result}) != len(result): raise ValueError('Duplicate fixture IDs')
    return result


def healing_cases(definitions, seeds=(1,7,19)):
    result=[]
    def add(move,label,side,seed,bench=None,**changes):
        case=make_case(move,label,side,seed,definitions,own=[0]*7,other=[0]*7)
        case.update(id=case['id'].replace('stat_stages/','healing/',1),family='healing',compare=list(HEALING_FIELDS),
                    healing_bench={'actor':{'hp':55,'status_id':'burn','ability_id':''},'target':{'hp':55,'status_id':'poison','ability_id':''}})
        case['actor'].update(max_hp=101,hp=17,status_id='burn')
        case['target'].update(max_hp=101,hp=87,status_id='burn')
        for key,value in changes.items():
            owner,field=key.split('__',1);case[owner][field]=value
        if bench: case['healing_bench']['actor'].update(bench)
        result.append(case)
    for move,side,seed in itertools.product(HEALING_MOVES,('side_a','side_b'),seeds):
        for hp in range(100,108): add(move,'hp_'+str(hp),side,seed,actor__max_hp=hp)
        add(move,'full',side,seed,actor__hp=101)
        add(move,'cap',side,seed,actor__hp=100)
        for status in ('','poison','badly_poisoned'): add(move,'user_'+(status or 'healthy'),side,seed,actor__status_id=status)
        for status in ('','poison','badly_poisoned'): add(move,'target_'+(status or 'healthy'),side,seed,target__status_id=status)
        for status in ('sleep','freeze','paralysis'): add(move,'reserve_'+status,side,seed,bench={'status_id':status})
        add(move,'reserve_ko',side,seed,bench={'hp':0})
        for ability in ('soundproof','sap_sipper','good_as_gold'): add(move,'reserve_'+ability,side,seed,bench={'ability_id':ability})
        add(move,'user_sub',side,seed,actor__substitute_hp=1)
        add(move,'target_sub',side,seed,target__substitute_hp=1)
        add(move,'infiltrate',side,seed,actor__ability_id='infiltrator',target__substitute_hp=1)
        for ability in ('magic_bounce','good_as_gold'): add(move,'target_'+ability,side,seed,target__ability_id=ability)
        if move=='rest':
            for ability in ('insomnia','vital_spirit','comatose','sweet_veil','purifying_salt'): add(move,'user_'+ability,side,seed,actor__ability_id=ability)
    return result


def binding_cases(definitions, seeds=(1,7,19)):
    result=[]
    def add(move,label,side,seed,**changes):
        own,other=[0]*7,[0]*7;own[5]=6;other[6]=-6
        case=make_case(move,label,side,seed,definitions,own,other)
        case.update(id=case['id'].replace('stat_stages/','binding/',1),family='binding',compare=list(BINDING_FIELDS))
        for role in ('actor','target'):case[role].update(max_hp=20000,item_id='')
        for key,value in changes.items():
            role,field=key.split('__',1);case[role][field]=value
        result.append(case)
    for move,side,seed in itertools.product(BINDING_MOVES,('side_a','side_b'),seeds):
        for hp in (256,257,999,20000):add(move,f'hp_{hp}',side,seed,target__max_hp=hp)
        for item in ('binding_band','grip_claw'):add(move,item,side,seed,actor__item_id=item)
        for item in ('shed_shell','leftovers'):add(move,item,side,seed,target__item_id=item)
        for hp in (1,500):
            add(move,f'sub_{hp}',side,seed,target__substitute_hp=hp)
            add(move,f'infiltrator_{hp}',side,seed,target__substitute_hp=hp,actor__ability_id='infiltrator')
        add(move,'ghost',side,seed,target__species_id='gengar')
        add(move,'ground',side,seed,target__species_id='sandshrew')
        add(move,'magic_guard',side,seed,target__ability_id='magic_guard')
        add(move,'grip_claw_cycle',side,seed,actor__item_id='grip_claw')
        result[-1]['lifecycle_turns']=8
    return result


def variable_power_cases(definitions, seeds=(1,7,19)):
    result = []
    def add(move, label, side, seed, **changes):
        own, other = [0]*7, [0]*7
        own[5], other[6] = 6, -6
        case = make_case(move,label,side,seed,definitions,own,other)
        case.update(id=case['id'].replace('stat_stages/','variable_power/',1), family='variable_power', compare=list(VARIABLE_FIELDS))
        for role in ('actor','target'):
            case[role].update(hp=20000,max_hp=20000,speed=200 if role=='actor' else 100,friendship=127,status_id='')
        case['actor']['pp'] = definitions[move]['pp']
        for key,value in changes.items():
            role,field=key.split('__',1); case[role][field]=value
        result.append(case)
    for side,seed in itertools.product(('side_a','side_b'),seeds):
        for move,pair,boosts,status in itertools.product(('electro_ball','gyro_ball'),
                ((1,1),(3,3),(4,3),(99,100),(100,100),(199,100),(200,100),(299,100),(300,100),(399,100),(400,100),(600,1),(1,600),(10000,7)),
                ((0,0),(-1,0),(0,-1),(6,-6),(-6,6)), ('','paralysis')):
            a,t=pair; ab,tb=boosts
            own,other=dict.fromkeys(STATS,0),dict.fromkeys(STATS,0)
            own.update(accuracy=6,speed=ab);other.update(evasion=-6,speed=tb)
            add(move,f'speed_{a}_{t}_{ab}_{tb}_{status}',side,seed,actor__speed=a,target__speed=t,actor__stages=own,target__stages=other,target__status_id=status)
        for move,maximum in itertools.product(('flail','reversal'),(48,4800,20000)):
            values={1,maximum}
            for cut in (2,5,10,17,33):
                boundary=(cut*maximum+47)//48
                values.update(max(1,min(maximum,boundary+d)) for d in (-1,0,1))
            for hp in sorted(values): add(move,f'own_hp_{hp}_{maximum}',side,seed,actor__hp=hp,actor__max_hp=maximum)
        for move,maximum in itertools.product(('crush_grip','wring_out','hard_press'),(100,4096,20000)):
            for hp in sorted({1,2,3,maximum//4,maximum//2,maximum-1,maximum}):
                add(move,f'target_hp_{hp}_{maximum}',side,seed,target__hp=hp,target__max_hp=maximum)
        for move,value in itertools.product(('return','frustration'),(0,1,2,3,4,127,128,254,255)):
            add(move,f'friendship_{value}',side,seed,actor__friendship=value)
        for pp in range(1,6): add('trump_card',f'prepaid_pp_{pp}',side,seed,actor__pp=pp)
        for label,values in [('neutral',[0]*7),('negative',[-6]*7),('one',[1,0,0,0,0,0,0]),('accuracy',[0,0,0,0,0,6,0]),('evasion',[0,0,0,0,0,0,3]),('capped',[6]*7),('mixed',[3,-6,4,-6,0,2,-3])]:
            other=dict(zip(STATS,values)) # user accuracy +6 guarantees these 100%-accuracy strikes
            add('punishment',label,side,seed,target__stages=other)
        for move in VARIABLE_MOVES:
            for infiltrator in (False,True):
                add(move,f'substitute_{infiltrator}',side,seed,target__substitute_hp=500,actor__ability_id='infiltrator' if infiltrator else '')
        for move,species in {'electro_ball':'sandshrew','flail':'gengar','reversal':'gengar','crush_grip':'gengar','wring_out':'gengar','return':'gengar','frustration':'gengar','trump_card':'gengar'}.items():
            add(move,'immunity',side,seed,target__species_id=species)
    return result


def fixed_damage_cases(definitions, seeds=(1, 7, 19)):
    result = []
    stab = dict(zip(FIXED_MOVES, ('dragonite','snorlax','machamp','gengar','snorlax','togekiss','tyranitar'), strict=True))
    resisted = dict(zip(FIXED_MOVES, ('steelix','steelix','crobat','umbreon','steelix','steelix','machamp'), strict=True))
    immunities = {'dragon_rage':'gardevoir','sonic_boom':'gengar','seismic_toss':'gengar','night_shade':'snorlax','super_fang':'gengar'}

    def add(move, label, side, seed, hp=101, level=50, **changes):
        own = [0] * 7
        other = [0] * 7
        own[5], other[6] = 6, -6
        case = make_case(move, label, side, seed, definitions, own, other)
        case['id'] = case['id'].replace('stat_stages/', 'fixed_damage/', 1)
        case.update(family='fixed_damage', compare=list(FIXED_FIELDS))
        case['actor'].update(level=level, hp=20000)
        case['target'].update(level=50, hp=hp)
        for key, value in changes.items():
            owner, field = key.split('__', 1)
            case[owner][field] = value
        result.append(case)

    for move, side, seed in itertools.product(FIXED_MOVES, ('side_a','side_b'), seeds):
        for level, hp in itertools.product((1,50,100), (1,3,37,100,101)):
            add(move, f'level_{level}_hp_{hp}', side, seed, hp, level)
        for doll, hp in itertools.product((1,25,500), (3,101)):
            add(move, f'sub_{doll}_hp_{hp}', side, seed, hp, target__substitute_hp=doll)
        for doll in (1,25,500):
            add(move, f'infiltrator_{doll}', side, seed, target__substitute_hp=doll, actor__ability_id='infiltrator')
        add(move, 'stab', side, seed, actor__species_id=stab[move])
        add(move, 'resisted', side, seed, target__species_id=resisted[move])
        for value in (-6,6):
            own, other = dict.fromkeys(STATS, value), dict.fromkeys(STATS, -value)
            own['accuracy'], other['evasion'] = 6, -6
            add(move, f'combat_stages_{value}', side, seed, actor__stages=own, target__stages=other)
        add(move, 'huge_power_ignored', side, seed, actor__ability_id='huge_power')
        add(move, 'multiscale_ignored', side, seed, hp=20000, target__ability_id='multiscale')
        if move in immunities:
            for doll in (0,500):
                add(move, f'immunity_sub_{doll}', side, seed, target__species_id=immunities[move], target__substitute_hp=doll)
        if move in ('seismic_toss','super_fang'):
            add(move, 'iron_barbs_contact', side, seed, hp=2000, target__ability_id='iron_barbs')
    return result
