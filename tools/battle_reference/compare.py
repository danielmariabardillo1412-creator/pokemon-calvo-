"""Fail-closed comparator. Adapter errors/unsupported cases never count as matches."""
from __future__ import annotations
from fixtures import STATS, FAMILY_FIELDS


def checked_rows(cases, payload):
    if not cases or len({c['id'] for c in cases}) != len(cases):
        raise ValueError('Empty/duplicate fixture manifest')
    if not isinstance(payload, dict) or payload.get('schema_version') != 1 or not isinstance(payload.get('results'), list):
        raise ValueError('Invalid adapter output envelope')
    wanted = {c['id'] for c in cases}
    by_id = {c['id']: c for c in cases}
    result = {}
    for row in payload['results']:
        if not isinstance(row, dict) or row.get('id') not in wanted or row['id'] in result:
            raise ValueError('Duplicate/unknown result ID')
        if row.get('status') not in ('ok', 'unsupported', 'error'):
            raise ValueError('Invalid adapter status')
        if row['status'] == 'ok':
            if by_id[row['id']]['family'] == 'healing':
                statuses = ('','burn','poison','badly_poisoned','sleep','freeze','paralysis')
                if set(row.get('healing_benches',{})) != {'actor','target'}: raise ValueError('Missing healing bench observations')
                for unit in (row.get('actor',{}),row.get('target',{}),*row['healing_benches'].values()):
                    if type(unit.get('hp')) is not int or not 0 <= unit['hp'] <= 107: raise ValueError('Malformed healing HP')
                    if unit.get('status_id') not in statuses: raise ValueError('Malformed healing status')
                if any(set(unit) != {'hp','status_id'} for unit in row['healing_benches'].values()): raise ValueError('Incomplete healing bench')
            if by_id[row['id']]['family'] == 'binding':
                binding=row.get('binding',{})
                if set(binding) != {'present','blocked','residual_damage','move_id','clock_valid'}:raise ValueError('Incomplete binding observation')
                if any(type(binding[k]) is not bool for k in ('present','blocked','clock_valid')):raise ValueError('Malformed binding flags')
                if type(binding['residual_damage']) is not int or not 0 <= binding['residual_damage'] <= 20000:raise ValueError('Malformed residual damage')
                if not isinstance(binding['move_id'],str):raise ValueError('Malformed binding move')
                trace=row.get('lifecycle')
                if not isinstance(trace,list) or len(trace) != (8 if by_id[row['id']].get('lifecycle_turns',1)==8 else 0):raise ValueError('Incomplete lifecycle observations')
                for tick in trace:
                    if set(tick) != {'present','blocked','duration','residual_damage'} or type(tick['duration']) is not int or not 0 <= tick['duration'] <= 7 or type(tick['residual_damage']) is not int or not 0 <= tick['residual_damage'] <= 20000 or any(type(tick[k]) is not bool for k in ('present','blocked')):
                        raise ValueError('Malformed lifecycle observation')
            if by_id[row['id']]['family'] == 'variable_power':
                if type(row.get('power')) is not int or not 0 <= row['power'] <= 200:
                    raise ValueError('Missing/malformed power observation')
                if type(row.get('contact')) is not bool or type(row.get('hit_received')) is not bool:
                    raise ValueError('Missing contact/hit observation')
                if row['hit_received'] != (row['power'] > 0) or row['contact'] and not row['hit_received']:
                    raise ValueError('Inconsistent power observation')
            for owner in ('actor', 'target'):
                actor = row.get(owner, {})
                if set(actor.get('stages', {})) != set(STATS): raise ValueError('Incomplete stage observation')
                if any(type(v) is not int or not -6 <= v <= 6 for v in actor['stages'].values()): raise ValueError('Malformed stage observation')
                if type(actor.get('substitute_present')) is not bool: raise ValueError('Missing substitute observation')
                if by_id[row['id']]['family'] == 'fixed_damage':
                    for field in ('hp', 'substitute_hp'):
                        if type(actor.get(field)) is not int or not 0 <= actor[field] <= 20000:
                            raise ValueError('Missing/malformed fixed HP observation')
                    if type(actor.get('knocked_out')) is not bool or actor['knocked_out'] != (actor['hp'] == 0):
                        raise ValueError('Inconsistent knockout observation')
                    if actor['substitute_present'] != (actor['substitute_hp'] > 0):
                        raise ValueError('Inconsistent substitute observation')
            if type(row['actor'].get('pp_spent')) is not int or not 0 <= row['actor']['pp_spent'] <= 64 or type(row['actor'].get('move_used')) is not bool:
                raise ValueError('Missing action/PP observation')
            if set(row.get('benches', {})) != {'actor', 'target'}: raise ValueError('Missing bench observations')
            for stages in row['benches'].values():
                if set(stages) != set(STATS) or any(type(v) is not int or not -6 <= v <= 6 for v in stages.values()):
                    raise ValueError('Malformed bench observation')
        elif not isinstance(row.get('reason'), str) or not row['reason']:
            raise ValueError('Missing reason for uncomparable case')
        result[row['id']] = row
    if set(result) != wanted: raise ValueError('Missing adapter results')
    return result


def compare(cases, reference, actual):
    expected = checked_rows(cases, reference)
    observed = checked_rows(cases, actual)
    results = []
    for case in cases:
        a, b = expected[case['id']], observed[case['id']]
        if a['status'] != 'ok' or b['status'] != 'ok':
            results.append({'id': case['id'], 'move_id': case['move_id'], 'status': 'NOT_COMPARABLE',
                            'reference_status': a['status'], 'godot_status': b['status'],
                            'reason': '; '.join(x.get('reason', '') for x in (a, b) if x['status'] != 'ok'), 'differences': []})
            continue
        if not a['actor']['move_used'] or a['actor']['pp_spent'] != 1:
            results.append({'id': case['id'], 'move_id': case['move_id'], 'status': 'NOT_COMPARABLE',
                            'reason': 'Reference fixture did not execute exactly one paid action', 'differences': []})
            continue
        if case['family'] == 'binding' and not a['binding']['clock_valid']:
            results.append({'id':case['id'],'move_id':case['move_id'],'status':'NOT_COMPARABLE','reason':'Reference duration outside the pinned contract','differences':[]})
            continue
        differences = []
        for field in FAMILY_FIELDS[case['family']]:
            first, second = a, b
            for key in field.split('.'):
                first, second = first[key], second[key]
            if isinstance(first, dict):
                def flatten(obj, prefix):
                    for key, value in sorted(obj.items()):
                        yield from flatten(value, prefix + '.' + key) if isinstance(value, dict) else [(prefix + '.' + key, value)]
                left, right = dict(flatten(first, field)), dict(flatten(second, field))
                for path in sorted(left):
                    if left[path] != right[path]: differences.append({'field': path, 'reference': left[path], 'godot': right[path]})
            elif first != second:
                differences.append({'field': field, 'reference': first, 'godot': second})
        results.append({'id': case['id'], 'move_id': case['move_id'],
                        'status': 'MATCH' if not differences else 'MISMATCH', 'differences': differences})
    counts = {status: sum(row['status'] == status for row in results) for status in ('MATCH', 'MISMATCH', 'NOT_COMPARABLE')}
    return {'schema_version': 1, 'status': 'PASS' if counts['MATCH'] == len(cases) else 'NEEDS_REVIEW',
            'counts': counts, 'cases': len(cases), 'results': results}
