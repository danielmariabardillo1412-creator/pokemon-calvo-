"""Compile a bounded RHH declarative family; never execute upstream C/Ruby.

Unknown expressions, extra flags, ambiguous IDs and changed source bytes cannot
silently become working effects. Output is a Calvo manifest, not canonical data.
"""
from pathlib import Path
import argparse
from collections import Counter
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
COMMIT = '8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c'
SOURCE = 'https://github.com/rh-hideout/pokeemerald-expansion/tree/' + COMMIT
HASHES = {
    'items.h': '107f1b78a457f3a9c48749f325d674b62fe559b0ebfc365db13e82b00b19ecd3',
    'item_effects.h': '6cf395c29bbfcf425eeb965f2101edb8ba139c6cb24beef0521b92f6853a5e5f',
    'item_effect_constants.h': '264f2957eeb8bcfd26e24fd15d800f38a8e1418dd8688ed4155e40a5336e2139',
}
MANIFEST = ROOT / 'modules/inventory/imported_recovery_v19.json'
AUDIT = ROOT / 'docs/current/ITEM_IMPORT_V19_AUDIT.json'
CONDITIONS = {'I_SITRUS_BERRY_HEAL >= GEN_4': True}
STATUS = {'ITEM3_PARALYSIS': ['par'], 'ITEM3_FREEZE': ['frz'],
          'ITEM3_BURN': ['brn'], 'ITEM3_POISON': ['psn', 'tox'], 'ITEM3_SLEEP': ['slp']}

class Unsupported(ValueError):
    """A source construct needs a new reviewed capability, not an approximation."""

def digest(data): return hashlib.sha256(data).hexdigest()
def encode(value): return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + '\n'
def load(path): return json.loads(path.read_text(encoding='utf-8'))

def uncomment(text):
    # Preserve strings so comment-like text inside descriptions cannot become code.
    token = r'"(?:\\.|[^"\\])*"|/\*.*?\*/|//[^\n]*'
    return re.sub(token, lambda m: m[0] if m[0].startswith('"') else '', text, flags=re.S)

def choose_branches(text):
    active = True; stack = []; output = []
    for line in text.splitlines():
        directive = re.fullmatch(r'\s*#(if|else|endif)\b\s*(.*?)\s*', line)
        if directive:
            op, expression = directive.groups()
            if op == 'if':
                if expression not in CONDITIONS: raise Unsupported('unknown conditional: ' + expression)
                stack.append((active, CONDITIONS[expression], False)); active = active and CONDITIONS[expression]
            elif op == 'else':
                if expression or not stack or stack[-1][2]: raise Unsupported('invalid else')
                parent, condition, _ = stack[-1]; stack[-1] = (parent, condition, True); active = parent and not condition
            else:
                if expression or not stack: raise Unsupported('invalid endif')
                active = stack.pop()[0]
        elif line.lstrip().startswith('#'): raise Unsupported('unsupported preprocessor')
        elif active: output.append(line)
    if stack: raise Unsupported('unterminated conditional')
    return '\n'.join(output)

def integer(expression):
    expression = expression.strip()
    modern = re.fullmatch(r'I_HEALTH_RECOVERY\s*>=\s*GEN_7\s*\?\s*(\d+)\s*:\s*(\d+)', expression)
    if modern: return int(modern[1])
    if not re.fullmatch(r'-?\d+', expression): raise Unsupported('unsupported number: ' + expression)
    return int(expression)

def flags(expression, allowed):
    terms = [part.strip() for part in expression.split('|')]
    if len(terms) != len(set(terms)) or not set(terms) <= allowed: raise Unsupported('unsupported flags: ' + expression)
    return set(terms)

def compile_effect(body, size):
    """Only HP/status/PP recovery and explicit negative friendship tails."""
    body = choose_branches(uncomment(body))
    values = {}
    for assignment in body.split(','):
        if not assignment.strip(): continue
        m = re.fullmatch(r'\s*\[(\d+)\]\s*=\s*(.*?)\s*', assignment, re.S)
        if not m: raise Unsupported('unsupported array entry')
        index = int(m[1])
        if index in values or not 0 <= index < size: raise Unsupported('duplicate/out-of-range array index')
        values[index] = m[2]
    if set(values) - {3, 4, 5, 6, 7, 8, 9}: raise Unsupported('non-recovery capability')
    result = {}; used = set()
    if 3 in values:
        status = flags(values[3], set(STATUS) | {'ITEM3_CONFUSION', 'ITEM3_STATUS_ALL'})
        if 'ITEM3_STATUS_ALL' in status:
            if len(status) != 1: raise Unsupported('mixed full-status mask')
            result.update(cure='all', confusion=True)
        else:
            codes = [code for name in sorted(status) for code in STATUS.get(name, [])]
            if codes: result['cure'] = codes
            if 'ITEM3_CONFUSION' in status: result['confusion'] = True
        used.add(3)
    if 4 in values:
        bits = flags(values[4], {'ITEM4_HEAL_HP', 'ITEM4_HEAL_PP', 'ITEM4_HEAL_PP_ONE'})
        if bits == {'ITEM4_HEAL_HP'}:
            raw = values.get(6, '')
            amount = {'ITEM6_HEAL_HP_FULL': 'full', 'ITEM6_HEAL_HP_QUARTER': 'quarter'}.get(raw)
            if amount is None:
                amount = integer(raw)
                if not 1 <= amount <= 254: raise Unsupported('invalid HP amount')
            result['heal'] = amount
        elif bits in ({'ITEM4_HEAL_PP'}, {'ITEM4_HEAL_PP', 'ITEM4_HEAL_PP_ONE'}):
            raw = values.get(6, '')
            amount = 'full' if raw == 'ITEM6_HEAL_PP_FULL' else integer(raw)
            if amount != 'full' and not 1 <= amount < 127: raise Unsupported('invalid PP amount')
            result.update(pp=amount, scope='one' if 'ITEM4_HEAL_PP_ONE' in bits else 'all')
        else: raise Unsupported('unsupported recovery flag combination')
        used.update({4, 6})
    if not result: raise Unsupported('no recovery effect')
    expected_size = 7 if 4 in values else 6
    if 5 in values:
        if values[5] != 'ITEM5_FRIENDSHIP_ALL': raise Unsupported('unsupported friendship flags')
        start = expected_size  # next argument after HP/PP, otherwise after masks
        changes = [integer(values.get(i, '')) for i in range(start, start + 3)]
        if not all(-255 <= value < 0 for value in changes): raise Unsupported('nonnegative friendship needs separate capability')
        result['friendship_loss'] = [-value for value in changes]
        used.update({5, *range(start, start + 3)}); expected_size += 3
    if used != set(values) or size != expected_size: raise Unsupported('unconsumed effect data')
    return result

def field(block, name, default=None):
    entries = re.findall(r'^\s*\.' + name + r'\s*=\s*([^,\n]+)\s*,', block, re.M)
    if len(entries) > 1: raise Unsupported('ambiguous field: ' + name)
    return entries[0].strip() if entries else default

def indexes(items_text, effects_text):
    items = {}; effects = {}
    for match in re.finditer(r'^    \[ITEM_([A-Z0-9_]+)\] =\s*\{(.*?)^    \},', uncomment(items_text), re.M | re.S):
        id = match[1].lower()
        if id in items: raise ValueError('duplicate source ID: ' + id)
        items[id] = match[2]
    for match in re.finditer(r'const u8 (gItemEffect_\w+)\[(\d+)\] =\s*\{(.*?)\};', effects_text, re.S):
        if match[1] in effects: raise ValueError('duplicate effect symbol: ' + match[1])
        effects[match[1]] = (match[3], int(match[2]))
    if not items or not effects: raise ValueError('no structured source records')
    return items, effects

def compile_item(block, effects):
    # Ignore cosmetic/held branches, but never guess conditional routing fields.
    # Unknown directives are harmless only when no routing field depends on them.
    conditions = []; routing = []
    for line in block.splitlines():
        directive = re.fullmatch(r'\s*#(if|ifdef|ifndef|elif|else|endif)\b\s*(.*?)\s*', line)
        if directive:
            op, expression = directive.groups()
            if op in ('if', 'ifdef', 'ifndef'): conditions.append(CONDITIONS.get(expression))
            elif not conditions: raise Unsupported('invalid item conditional')
            elif op == 'endif': conditions.pop()
            elif op == 'else': conditions[-1] = None if conditions[-1] is None else not conditions[-1]
            else: conditions[-1] = None
        elif re.match(r'\s*\.(fieldUseFunc|effect|notConsumed|type)\s*=', line):
            if False in conditions: continue
            if None in conditions: raise Unsupported('routing depends on unknown conditional')
            routing.append(line)
    if conditions: raise Unsupported('unterminated item conditional')
    block = '\n'.join(routing)
    function = field(block, 'fieldUseFunc')
    if function not in ('ItemUseOutOfBattle_Medicine', 'ItemUseOutOfBattle_PPRecovery'):
        raise Unsupported('field handler outside recovery pilot: ' + str(function))
    symbol = field(block, 'effect')
    if symbol not in effects: raise Unsupported('unresolved effect symbol: ' + str(symbol))
    consumed = field(block, 'notConsumed', 'FALSE')
    if consumed not in ('TRUE', 'FALSE'): raise Unsupported('unknown consumption rule')
    spec = compile_effect(*effects[symbol])
    target = 'ITEM_USE_PARTY_MENU_MOVES' if spec.get('scope') == 'one' else 'ITEM_USE_PARTY_MENU'
    if field(block, 'type') != target: raise Unsupported('unsupported field targeting')
    if (function == 'ItemUseOutOfBattle_PPRecovery') != ('pp' in spec): raise Unsupported('handler/effect mismatch')
    return spec, consumed != 'TRUE', symbol

def build(source_dir):
    sources = {}
    for name, expected in HASHES.items():
        raw = (source_dir / name).read_bytes()
        if digest(raw) != expected: raise ValueError('pinned source hash mismatch: ' + name)
        sources[name] = raw.decode('utf-8')
    source_items, effects = indexes(sources['items.h'], sources['item_effects.h'])
    catalog = load(ROOT/'data/normalized/pokemon_api.json')['items']
    policy = load(ROOT/'config/item_selection_v1.json')
    # Compare accepted contracts before replacing any runtime lookup. Herbs were
    # previously composed; this independent description includes their side effect.
    existing = load(ROOT/'modules/inventory/field_recovery_profile.json')['items']
    existing.update(load(ROOT/'modules/inventory/battle_medicine_profile.json')['items'])
    existing.update(energy_powder={'heal': 60, 'friendship_loss': [5, 5, 10]},
                    energy_root={'heal': 120, 'friendship_loss': [10, 10, 15]},
                    heal_powder={'cure': 'all', 'confusion': True, 'friendship_loss': [5, 5, 10]})
    imported = {}; rows = []; conflicts = []
    for id, definition in sorted(catalog.items()):
        if definition['id'] != id or not re.fullmatch('[a-z0-9_]+', id): raise ValueError('ambiguous canonical ID: ' + id)
        row = {'id': id, 'source_match': id in source_items}
        if id in policy['excluded_ids'] or definition.get('category') in policy['excluded_categories']:
            row.update(status='POLICY_EXCLUDED', reason=policy['excluded_ids'].get(id, 'excluded_category'))
        elif id not in source_items: row.update(status='NO_EXACT_SOURCE_ID', reason='no guessed alias')
        else:
            try:
                spec, consume, symbol = compile_item(source_items[id], effects)
                if id in existing and (spec != existing[id] or not consume):
                    conflicts.append(id); row.update(status='CONFLICT', reason='accepted profile differs', candidate=spec)
                else:
                    imported[id] = {'effect': spec, 'consume': consume, 'source_effect': symbol}
                    row.update(status='COMPILED_FIELD_RECOVERY', previous_field_route=id in existing)
            except Unsupported as error: row.update(status='OUTSIDE_PILOT', reason=str(error))
        rows.append(row)
    missing = sorted(set(existing) - set(imported))
    if conflicts or missing: raise ValueError('accepted recovery contracts not preserved: ' + str({'conflicts': conflicts, 'missing': missing}))
    manifest = {'schema_version': 1, 'profile': 'rhh_modern_field_recovery_v19',
        'source': SOURCE, 'source_sha256': HASHES,
        'settings': {'I_HEALTH_RECOVERY': 'GEN_9', 'I_SITRUS_BERRY_HEAL': 'GEN_9'}, 'items': imported}
    audit = {'catalog_count': len(catalog), 'source_item_count': len(source_items),
        'counts': dict(sorted(Counter(row['status'] for row in rows).items())),
        'compiled_ids': sorted(imported), 'preserved_existing_ids': sorted(existing),
        'new_field_ids': sorted(set(imported) - set(existing)),
        'input_sha256': {'canonical_catalog': digest((ROOT/'data/normalized/pokemon_api.json').read_bytes()),
                         'policy': digest((ROOT/'config/item_selection_v1.json').read_bytes())},
        'manifest_sha256': digest(encode(manifest).encode()),
        'scope': 'field recovery only; uncompiled rows do not imply missing or broken mechanics in other families',
        'rows': rows}
    return manifest, audit

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source-dir', type=Path, default=ROOT/'.godot/item_mochi_v13/references')
    mode = p.add_mutually_exclusive_group(required=True); mode.add_argument('--check', action='store_true'); mode.add_argument('--write', action='store_true')
    args = p.parse_args(); manifest, audit = build(args.source_dir)
    outputs = [(MANIFEST, encode(manifest)), (AUDIT, encode(audit))]
    if args.check:
        for path, expected in outputs:
            if path.read_text(encoding='utf-8') != expected: raise ValueError('generated artifact differs: ' + str(path))
    else:
        for path, value in outputs:
            path.parent.mkdir(parents=True, exist_ok=True); path.write_text(value, encoding='utf-8', newline='\n')
    print('ITEM_IMPORT', 'CHECK' if args.check else 'WRITE', 'PASS', json.dumps(audit['counts']), 'new=', audit['new_field_ids'])
    return 0

if __name__ == '__main__': raise SystemExit(main())
