"""Read-only PokéAPI -> canonical -> normalized audit, independent of the adapter.

Never imports/runs the dataset generator. Only writes a new evidence directory.
The local API bytes must match the project's pinned Git tree before a clean
comparison can be claimed. Field equality does not certify gameplay mechanics.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = Path(r'F:\pokemon roma el calvo\pokeapi-api-data\data\api\v2')
ENDPOINTS = {'pokemon', 'pokemon-species', 'evolution-chain', 'move', 'ability',
             'item', 'type', 'nature', 'growth-rate', 'machine'}
# Explicitly restated from the documented dataset profile, not adapter code.
VERSION_PRIORITY = ('scarlet-violet', 'brilliant-diamond-shining-pearl',
 'sword-shield', 'lets-go-pikachu-lets-go-eevee', 'ultra-sun-ultra-moon',
 'sun-moon', 'omega-ruby-alpha-sapphire', 'x-y', 'black-2-white-2',
 'black-white', 'heartgold-soulsilver', 'platinum', 'diamond-pearl',
 'firered-leafgreen', 'emerald', 'ruby-sapphire', 'crystal', 'gold-silver',
 'yellow', 'red-blue')
TYPES = set('normal fire water electric grass ice fighting poison ground flying '
            'psychic bug rock ghost dragon dark steel fairy'.split())
SECTIONS = ('species', 'moves', 'abilities', 'items', 'types', 'statuses')


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], text=True).strip()


def slug(value):
    return re.sub('[^a-z0-9]+', '_', str(value or '').lower()).strip('_')


def resource(value):
    return slug(value.get('name', '')) if isinstance(value, dict) else ''


def stable(value):
    # Godot JSON serializes some integer-valued fields as floats. This is not a
    # data difference. Preserve booleans separately (False is not numeric zero).
    if isinstance(value, float) and value.is_integer():
        return int(value)
    if isinstance(value, dict):
        return {k: stable(v) for k, v in value.items()}
    if isinstance(value, list):
        return [stable(v) for v in value]
    return value


def token(value):
    return json.dumps(stable(value), ensure_ascii=False, sort_keys=True, separators=(',', ':'))


def bag(values):
    return Counter(token(v) for v in values)


def source_blob(data, expected):
    def blob(value):
        return hashlib.sha1(b'blob ' + str(len(value)).encode() + b'\0' + value).hexdigest()
    exact = blob(data)
    lf = blob(data.replace(b'\r\n', b'\n'))
    return exact if exact == expected else lf, 'EXACT' if exact == expected else 'CRLF_TO_LF' if lf == expected else 'MISMATCH'


def serialized_effect(spec):
    # Serialized defaults from BattleEffectSpec.from_dict/to_dict; preserve order
    # and all supplied values. Unknown keys are reported, not discarded.
    result = dict(kind='', target='opponent', value=0, ratio_basis_points=0,
        chance_basis_points=10000, status_id='', stat_id='', min_hits=0,
        max_hits=0, min_turns=0, max_turns=0, children=[])
    result.update(spec)
    result['children'] = [serialized_effect(x) for x in spec.get('children', [])]
    return result


def localized(record, field='names'):
    entries = record.get(field) or []
    for lang in ('es', 'es-419', 'en'):
        for entry in entries:
            if (entry.get('language') or {}).get('name') != lang:
                continue
            value = (entry.get('name') if field == 'names' else
                     entry.get('short_effect') or entry.get('effect'))
            if value:
                return str(value).strip() if field != 'names' else str(value), lang
    if field == 'names':
        return str(record['name']), 'source_identifier'
    for entry in entries:
        value = entry.get('short_effect') or entry.get('effect')
        if value:
            return str(value).strip(), (entry.get('language') or {}).get('name', 'unknown')
    return '', 'absent'


def select_group(pokemon):
    groups = {d['version_group']['name'] for m in pokemon.get('moves', [])
              for d in m.get('version_group_details', [])}
    return next((g for g in VERSION_PRIORITY if g in groups), '')


def learnset(pokemon, group):
    result = {}
    for move in pokemon.get('moves', []):
        for detail in move.get('version_group_details', []):
            if detail['version_group']['name'] != group:
                continue
            row = {'move_id': resource(move['move']),
                   'method': resource(detail['move_learn_method']),
                   'level': detail.get('level_learned_at') or 0, 'version_group': group}
            order = detail.get('order')
            if isinstance(order, int) and not isinstance(order, bool) and order >= 0:
                row['order'] = order
            result[token(row)] = row
    return list(result.values())


def condition(value):
    if isinstance(value, dict) and 'name' in value:
        return resource(value)
    return value


def evolution(target, detail):
    row = {'species_id': slug(target), 'trigger': resource(detail.get('trigger')) or 'level_up',
           'min_level': detail.get('min_level') or 0, 'item_id': resource(detail.get('item'))}
    if detail.get('version_group'):
        row['version_group'] = resource(detail['version_group'])
    if detail.get('is_default') is False:
        row['is_default'] = False
    conditions = {}
    for key, value in detail.items():
        if key in {'trigger', 'min_level', 'item', 'version_group', 'is_default'}:
            continue
        # Crucial: relative_physical_stats=0 means equal Attack/Defense.
        # Never use `value in (False, 0, ...)` to filter numeric conditions.
        if value is None or value is False or value == '' or value == [] or value == {}:
            continue
        conditions[key] = condition(value)
    if conditions:
        row['conditions'] = conditions
    return row


def evolution_map(chains):
    result = defaultdict(list)
    def walk(node):
        for child in node.get('evolves_to', []):
            for detail in child.get('evolution_details') or [{}]:
                result[resource(node['species'])].append(evolution(child['species']['name'], detail))
            walk(child)
    for chain in chains:
        walk(chain['chain'])
    return result


class Audit:
    def __init__(self):
        self.findings = []
        self.checks = Counter()
        self.localization = []
        self.decisions = []

    def issue(self, layer, section, record, field, expected, actual, kind='VALUE_MISMATCH'):
        self.findings.append(dict(layer=layer, section=section, record=record, field=field,
                                  kind=kind, expected=expected, actual=actual))

    def check(self, layer, section, record, field, expected, actual, unordered=False):
        self.checks[layer + '/' + section] += 1
        if unordered and isinstance(expected, list) and isinstance(actual, list):
            e, a = bag(expected), bag(actual)
            if e != a:
                self.issue(layer, section, record, field,
                           [json.loads(k) for k in sorted(e-a) for _ in range((e-a)[k])],
                           [json.loads(k) for k in sorted(a-e) for _ in range((a-e)[k])],
                           'COLLECTION_DIFFERENCE')
        elif token(expected) != token(actual):
            self.issue(layer, section, record, field, expected, actual)

    def fields(self, layer, section, rid, expected, actual):
        for key, value in expected.items():
            self.check(layer, section, rid, key, value, actual.get(key),
                       key in {'learnset', 'evolutions', 'ability_slots'})

    def label(self, section, source, actual, rid=None):
        rid = rid or slug(source['name'])
        expected, lang = localized(source)
        self.localization.append(dict(section=section, record=rid, field='display_name', language=lang))
        self.check('api_to_raw', section, rid, 'display_name', expected, actual.get('display_name'))

    def description(self, section, source, actual, fields):
        rid = slug(source['name'])
        expected, lang = localized(source, 'effect_entries')
        self.localization.append(dict(section=section, record=rid, field='description', language=lang))
        for field in fields:
            self.check('api_to_raw', section, rid, field, expected, actual.get(field))


def physical(pokemon):
    expected = {'base_experience': pokemon.get('base_experience') or 0,
        'types': [resource(x['type']) for x in sorted(pokemon['types'], key=lambda x: x['slot'])],
        'ability_ids': [resource(a['ability']) for a in pokemon['abilities']],
        'ability_slots': [{'ability_id': resource(a['ability']), 'slot': a['slot'],
                           'is_hidden': a['is_hidden']} for a in pokemon['abilities']],
        'ev_yield': {resource(s['stat']): s['effort'] for s in pokemon['stats']}}
    expected.update({'base_' + resource(s['stat']): s['base_stat'] for s in pokemon['stats']})
    return expected


def index_records(audit, section, rows):
    result = {}
    for row in rows:
        key = row.get('id')
        if key in result:
            audit.issue('structure', section, str(key), 'id', 'unique', 'duplicate', 'DUPLICATE_ID')
        result[key] = row
    return result


def load_source(source, audit):
    tree = git('rev-parse', 'HEAD:data/api/v2')
    manifest = read(ROOT/'data/manifests/pokemon_api_manifest.json')
    audit.check('source_integrity', 'snapshot', 'api_tree', 'git_tree',
                manifest['provenance']['source_api_tree'], tree)
    records = defaultdict(list)
    inventory = []
    expected_paths = set()
    for line in git('ls-tree', '-r', 'HEAD:data/api/v2').splitlines():
        meta, rel = line.split('\t', 1)
        parts = rel.split('/')
        if len(parts) != 3 or parts[0] not in ENDPOINTS or not parts[1].isdigit() or parts[2] != 'index.json':
            continue
        expected_paths.add(rel)
        path = source/rel
        if not path.is_file():
            audit.issue('source_integrity', parts[0], parts[1], 'path', rel, None, 'MISSING_SOURCE_FILE')
            continue
        data = path.read_bytes()
        oid, checkout_mode = source_blob(data, meta.split()[2])
        audit.check('source_integrity', parts[0], parts[1], 'git_blob', meta.split()[2], oid)
        inventory.append({'path': rel, 'sha256': sha(data), 'bytes': len(data),
                          'git_blob': oid, 'checkout_mode': checkout_mode})
        try:
            record = json.loads(data)
        except (ValueError, UnicodeError) as exc:
            audit.issue('source_integrity', parts[0], parts[1], 'json', 'parseable', str(exc), 'INVALID_JSON')
            continue
        audit.check('source_integrity', parts[0], parts[1], 'numeric_id', int(parts[1]), record.get('id'))
        records[parts[0]].append(record)
    for ep in sorted(ENDPOINTS):
        if not (source/ep).is_dir():
            continue
        for path in (source/ep).glob('*/index.json'):
            rel = path.relative_to(source).as_posix()
            if path.parent.name.isdigit() and rel not in expected_paths:
                audit.issue('source_integrity', ep, path.parent.name, 'path', None, rel, 'UNPINNED_SOURCE_FILE')
    print('API loaded and checked: ' + str(len(inventory)) + ' source files', flush=True)
    return records, inventory, tree


def compare(audit, api, raw, normalized, variants, machine_profile):
    canonical = {s: index_records(audit, s, raw.get(s, [])) for s in SECTIONS}
    expected_ids = defaultdict(set)
    pokemon = {slug(p['name']): p for p in api['pokemon']}
    evo = evolution_map(api['evolution-chain'])
    for source in api['pokemon-species']:
        sid = slug(source['name']); expected_ids['species'].add(sid)
        actual = canonical['species'].get(sid, {})
        audit.label('species', source, actual)
        defaults = [v for v in source['varieties'] if v['is_default']]
        audit.check('api_to_raw', 'species', sid, 'default_variety_count', 1, len(defaults))
        if len(defaults) != 1:
            continue
        pname = resource(defaults[0]['pokemon'])
        p = pokemon.get(pname)
        if p is None:
            audit.issue('api_to_raw', 'species', sid, 'source_pokemon', pname, None, 'MISSING_REFERENCE')
            continue
        group = select_group(p)
        expected = physical(p)
        expected.update(growth_rate=source['growth_rate']['name'], capture_rate=source['capture_rate'],
                        learnset=learnset(p, group), evolutions=evo.get(sid, []))
        audit.fields('api_to_raw', 'species', sid, expected, actual)
        metadata = {k: source[k] for k in ('gender_rate','base_happiness','is_baby',
            'is_legendary','is_mythical','hatch_counter','has_gender_differences','forms_switchable')}
        metadata.update(source_pokemon_id=pname, learnset_version_group=group,
            learnset_selection_reason='mainline_priority' if group else 'no_learnset_data',
            generation=resource(source['generation']), egg_groups=[resource(g) for g in source['egg_groups']])
        audit.check('api_to_raw', 'species', sid, 'source_metadata', metadata, actual.get('source_metadata'))
    for source in api['move']:
        sid = slug(source['name'])
        if resource(source['type']) not in TYPES:
            audit.decisions.append(dict(section='moves', record=sid, reason='NON_STANDARD_TYPE_NOT_IN_18_TYPE_PROFILE'))
            continue
        expected_ids['moves'].add(sid)
        actual = canonical['moves'].get(sid, {})
        audit.label('moves', source, actual)
        audit.description('moves', source, actual, ['effect_summary'])
        audit.fields('api_to_raw', 'moves', sid, {
            'power': source.get('power') or 0, 'pp': source.get('pp') or 0,
            'accuracy': source['accuracy'] if source['accuracy'] is not None else -1,
            'priority': source['priority'], 'damage_class': source['damage_class']['name'],
            'type_id': resource(source['type']), 'target': source['target']['name']}, actual)
    for ep, section in [('ability', 'abilities'), ('item', 'items'), ('type', 'types')]:
        grouped = defaultdict(list)
        for source in api[ep]:
            grouped[slug(source['name'])].append(source)
        for sid, sources in grouped.items():
            if section == 'types' and sid not in TYPES:
                audit.decisions.append(dict(section=section, record=sid, reason='NON_STANDARD_TYPE'))
                continue
            expected_ids[section].add(sid)
            # A source slug collision is an ambiguity, never silently considered correct.
            sources.sort(key=lambda s: s['id'])
            if len(sources) > 1:
                audit.issue('source_ambiguity', section, sid, 'normalized_id',
                            'one API record', [s['id'] for s in sources], 'SOURCE_ID_COLLISION')
            source = sources[0]; actual = canonical[section].get(sid, {})
            audit.label(section, source, actual)
            if section != 'types':
                audit.description(section, source, actual,
                                  ['description', 'effect_summary'] if ep == 'ability' else ['description'])
            if ep == 'item':
                audit.check('api_to_raw', section, sid, 'category', resource(source['category']), actual.get('category'))
            if ep == 'ability':
                audit.check('api_to_raw', section, sid, 'effect_id', sid, actual.get('effect_id'))
            if ep == 'type':
                effectiveness = {resource(t): value for key, value in
                    [('double_damage_to', 2), ('half_damage_to', .5), ('no_damage_to', 0)]
                    for t in source['damage_relations'][key] if resource(t) in TYPES}
                audit.check('api_to_raw', section, sid, 'effectiveness', effectiveness, actual.get('effectiveness'))
    for section, ids in expected_ids.items():
        audit.check('api_to_raw', section, 'ALL', 'ids', sorted(ids), sorted(canonical[section]))
    # Every serialized raw field is checked, including project-generated effect specs.
    # They are preserved across import; their semantic correctness is a separate gate.
    for section in SECTIONS:
        target = normalized.get(section, {})
        audit.check('raw_to_normalized', section, 'ALL', 'ids', sorted(canonical[section]), sorted(target))
        for sid, record in canonical[section].items():
            expected = dict(record)
            if section == 'species':
                expected['type_ids'] = expected.pop('types')
                expected['primary_type_id'] = record.get('primary_type_id', 'normal')
                expected['secondary_type_id'] = record.get('secondary_type_id', '')
            if section == 'moves':
                expected['effect_specs'] = [serialized_effect(x) for x in record.get('effect_specs', [])]
            actual = target.get(sid, {})
            audit.fields('raw_to_normalized', section, sid, expected, actual)
            audit.check('raw_to_normalized', section, sid, 'serialized_keys', sorted(expected), sorted(actual))
            audit.check('structure', section, sid, 'key_matches_record_id', sid, actual.get('id'))
    species = canonical['species']
    # Regional definitions are an explicit overlay, never inferred from hyphens.
    by_number = {p['id']: p for p in api['pokemon']}
    source_species = {slug(p['name']): p for p in api['pokemon-species']}
    expected_regionals = {slug(p['name']) for p in api['pokemon']
        if re.search(r'-(alola|galar|hisui|paldea)(-|$)', p['name'])
        and '-cap' not in p['name'] and '-totem-' not in p['name'] and not p['name'].endswith('-zen')}
    audit.check('regional_overlay', 'species', 'ALL', 'regional_ids',
                sorted(expected_regionals), sorted(variants.get('regional_species', {})))
    for sid, actual in variants.get('regional_species', {}).items():
        meta = actual.get('source_metadata', {})
        p = by_number.get(meta.get('source_pokemon_id'))
        if p is None:
            audit.issue('regional_overlay', 'species', sid, 'source_pokemon', meta, None, 'MISSING_REFERENCE')
            continue
        base = resource(p['species']); ps = source_species[base]
        audit.check('regional_overlay', 'species', sid, 'id', slug(p['name']), actual.get('id'))
        audit.check('regional_overlay', 'species', sid, 'base_species', base, meta.get('base_species_id'))
        expected = physical(p); expected['type_ids'] = expected.pop('types')
        expected.update(primary_type_id=expected['type_ids'][0],
                        secondary_type_id=expected['type_ids'][1] if len(expected['type_ids']) > 1 else '',
                        growth_rate=ps['growth_rate']['name'], capture_rate=ps['capture_rate'],
                        learnset=learnset(p, select_group(p)))
        regional_evo = []
        for row in evo.get(base, []):
            conditions = dict(row.get('conditions', {}))
            if conditions.get('base_form') != sid:
                continue
            conditions.pop('base_form')
            target = conditions.pop('evolved_form', row['species_id'])
            if target not in species and target not in variants['regional_species']:
                audit.issue('regional_overlay', 'species', sid, 'evolution_target', target, None, 'MISSING_REFERENCE')
                continue
            row = dict(row, species_id=target, conditions=conditions)
            if not conditions:
                row.pop('conditions')
            regional_evo.append(row)
        actual_evo = [dict(row) for row in actual.get('evolutions', [])]
        for row in actual_evo:
            if not row.get('conditions'):
                row.pop('conditions', None)
        expected['evolutions'] = regional_evo
        audit.fields('regional_overlay', 'species', sid, expected, dict(actual, evolutions=actual_evo))
        audit.check('regional_overlay', 'species', sid, 'version_group', select_group(p), meta.get('learnset_version_group'))
    # Referential integrity in both canonical layers, including level-up entries.
    for label, catalogs in [('raw', canonical), ('normalized', normalized)]:
        for sid, sp in catalogs.get('species', {}).items():
            refs = [('types', t) for t in sp.get('types', sp.get('type_ids', []))]
            refs += [('abilities', t) for t in sp.get('ability_ids', [])]
            refs += [('moves', x['move_id']) for x in sp.get('learnset', [])]
            refs += [('species', x['species_id']) for x in sp.get('evolutions', [])]
            for section, ref in refs:
                audit.check('references/' + label, section, sid, ref, True, ref in catalogs.get(section, {}))
    for sid, sp in variants.get('regional_species', {}).items():
        refs = [('types', t) for t in sp.get('type_ids', [])]
        refs += [('abilities', t) for t in sp.get('ability_ids', [])]
        refs += [('moves', x['move_id']) for x in sp.get('learnset', [])]
        for section, ref in refs:
            audit.check('references/regional', section, sid, ref, True, ref in canonical.get(section, {}))
    for sid, sp in {**canonical['species'], **variants.get('regional_species', {})}.items():
        for row in sp.get('evolutions', []):
            refs = [('items', row.get('item_id'))]
            for key, section in [('held_item','items'), ('known_move','moves'), ('used_move','moves'),
                ('known_move_type','types'), ('party_type','types'), ('party_species','species'), ('trade_species','species')]:
                refs.append((section, row.get('conditions', {}).get(key)))
            for section, ref in refs:
                if ref:
                    audit.check('references/evolution', section, sid, ref, True, ref in canonical.get(section, {}))
    machines = defaultdict(dict)
    for machine in api['machine']:
        machines[resource(machine['item'])][machine['version_group']['name']] = resource(machine['move'])
    for item, versions in machine_profile.get('machine_rows', {}).items():
        for version, move in versions.items():
            audit.check('machine_overlay', 'items', item, version, machines.get(item, {}).get(version), move)
    audit.check('regional_overlay', 'binding', 'canonical', 'sha256',
                sha((ROOT/'data/normalized/pokemon_api.json').read_bytes()), variants.get('canonical_sha256'))
    return canonical


def compare_progression_tables(audit, api, growth_reference, rules_text):
    block = re.search(r'const NATURE_MODIFIERS := \{(.*?)\n\}', rules_text, re.S)
    if block is None:
        audit.issue('progression_tables', 'natures', 'ALL', 'constant', 'readable table', None, 'UNRECOGNIZED_TABLE')
        return
    actual = {rid: [up, down] for rid, up, down in
              re.findall(r'&"([a-z_]+)":\s*\["([a-z_]*)",\s*"([a-z_]*)"\]', block.group(1))}
    audit.check('progression_tables', 'natures', 'ALL', 'ids',
                sorted(slug(n['name']) for n in api['nature']), sorted(actual))
    for n in api['nature']:
        audit.check('progression_tables', 'natures', n['name'], 'increased_decreased',
            [resource(n.get('increased_stat')), resource(n.get('decreased_stat'))], actual.get(slug(n['name'])))
    for growth in api['growth-rate']:
        stored = growth_reference.get('tables', {}).get(growth['name'], {}).get('levels_1_to_100', [])
        levels = {row['level']: row['experience'] for row in growth['levels']}
        audit.check('progression_tables', 'experience', growth['name'], 'levels', list(range(1, 101)), sorted(levels))
        for level in range(1, 101):
            audit.check('progression_tables', 'experience', growth['name'], str(level),
                        levels.get(level), stored[level-1] if len(stored) >= level else None)


def run(source, out):
    source = source.resolve(); out = out.resolve()
    assert source.is_dir(), f'Missing API root: {source}'
    assert out.is_relative_to(ROOT/'.godot/pokeapi_data_audit'), 'Evidence must stay in dedicated cache'
    assert not out.exists(), 'Never overwrite audit evidence'
    out.mkdir(parents=True)
    audit = Audit()
    paths = ['data/raw/pokemon_api.json', 'data/normalized/pokemon_api.json',
        'data/manifests/pokemon_api_manifest.json', 'config/pokemon_variants_v1.json',
        'modules/inventory/item_connections_v1.json',
        'modules/creatures/progression/progression_ruleset.gd',
        'tests/fixtures/progression_growth_curves/reference_contract.json',
        'modules/battle/effects/battle_effect_spec.gd']
    before = {p: sha((ROOT/p).read_bytes()) for p in paths}
    auditor_sha256 = sha(Path(__file__).read_bytes())
    api, inventory, tree = load_source(source, audit)
    inventory_by_path = {row['path']: row for row in inventory}
    for sid, sp in read(ROOT/paths[3]).get('regional_species', {}).items():
        meta = sp.get('source_metadata', {})
        rel = 'pokemon/' + str(meta.get('source_pokemon_id')) + '/index.json'
        audit.check('regional_overlay', 'provenance', sid, 'source_sha256',
                    inventory_by_path.get(rel, {}).get('sha256'), meta.get('source_sha256'))
    canonical = compare(audit, api, read(ROOT/paths[0]), read(ROOT/paths[1]),
                        read(ROOT/paths[3]), read(ROOT/paths[4]))
    compare_progression_tables(audit, api, read(ROOT/paths[6]), (ROOT/paths[5]).read_text(encoding='utf-8'))
    # Optional auxiliary data must not masquerade as already connected runtime data.
    auxiliary = ROOT/'data/reports/pokeapi_v3_auxiliary.json'
    if auxiliary.is_file():
        aux = {n['id']: n for n in read(auxiliary).get('natures', [])}
        before[str(auxiliary.relative_to(ROOT))] = sha(auxiliary.read_bytes())
        for n in api['nature']:
            sid = slug(n['name'])
            audit.fields('api_to_auxiliary', 'natures', sid, {'id': sid,
                'display_name': localized(n)[0], 'increased_stat': resource(n.get('increased_stat')),
                'decreased_stat': resource(n.get('decreased_stat'))}, aux.get(sid, {}))
    print('Catalog comparison finished; verifying inputs remain unchanged', flush=True)
    after = {p: sha((ROOT/p).read_bytes()) for p in before}
    audit.check('read_only', 'canonical_files', 'ALL', 'sha256', before, after)
    for row in inventory:
        audit.check('read_only', 'source_files', row['path'], 'sha256', row['sha256'], sha((source/row['path']).read_bytes()))
    counts = Counter(f['layer'] for f in audit.findings)
    report = {'status': 'FINDINGS_REVIEW_REQUIRED' if audit.findings else 'PASS_WITH_LIMITS',
        'created_utc': datetime.now(timezone.utc).isoformat(), 'project': str(ROOT),
        'head': git('rev-parse','HEAD'), 'working_tree_changes': git('status','--short'),
        'auditor_sha256': auditor_sha256,
        'source': str(source), 'source_api_tree': tree,
        'source_records': {k: len(v) for k,v in sorted(api.items())},
        'canonical_records': {k: len(v) for k,v in canonical.items()},
        'checks': dict(sorted(audit.checks.items())), 'total_checks': sum(audit.checks.values()),
        'finding_counts_by_layer': dict(counts), 'findings': audit.findings,
        'profile_exclusions': audit.decisions,
        'localization_counts': dict(Counter(x['section'] + '/' + x['field'] + '/' + x['language'] for x in audit.localization)),
        'localization_non_spanish': [x for x in audit.localization if x['language'] not in {'es','es-419'}],
        'source_inventory_sha256': sha(token(inventory).encode()), 'input_sha256': before,
        'source_checkout_modes': dict(Counter(row['checkout_mode'] for row in inventory)),
        'record_totals': {'learnset_entries': sum(len(s.get('learnset', [])) for s in canonical['species'].values()),
            'evolution_routes': sum(len(s.get('evolutions', [])) for s in canonical['species'].values()),
            'regional_species': len(read(ROOT/paths[3])['regional_species'])},
        'haunter_evolutions': canonical['species'].get('haunter',{}).get('evolutions'),
        'limits': [
            'Snapshot equality, not independent proof that PokeAPI itself is correct or up to date.',
            'No dataset, source snapshot, policy, save, artwork or gameplay code modified.',
            'Current snapshot fields compared; historical changes are not merged across game versions.',
            'Learnsets use one documented latest conventional version per Pokemon; fallback is not modernization.',
            'Effect specs/classifications/contact/critical rules are checked for import preservation, not semantic accuracy against API.',
            'Native Showdown engine, combat combinations and excluded content availability are outside this data audit.',
            'Descriptions preserve API language fallback; a correct English fallback is a localization backlog, not numeric corruption.',
            '25 runtime nature modifiers and 600 stored XP reference values checked; formula execution remains a separate test.',
            'Only CRLF-to-LF checkout differences are accepted when they exactly reproduce pinned Git blobs; source bytes remain untouched.',
            'Regional labels are project-owned; numerical fields, learnsets and routed evolution records are compared.',
            'Machine overlay mappings checked where present; absence may reflect deliberately retained version profile.',
        ]}
    for name, value in [('report.json', report), ('source_inventory.json', inventory)]:
        (out/name).write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'status': report['status'], 'checks': report['total_checks'],
                      'findings': len(audit.findings), 'layers': dict(counts), 'report': str(out/'report.json')}))
    return 2 if counts.get('source_integrity') or counts.get('read_only') else 1 if audit.findings else 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=DEFAULT_SOURCE)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    output = args.output or ROOT/'.godot/pokeapi_data_audit'/datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S_%fZ')
    raise SystemExit(run(args.source, output))
