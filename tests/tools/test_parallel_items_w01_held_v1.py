"""Validador W01: contrato y evidencias de Godot; no implementa efectos."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DESCRIPTOR = ROOT / 'tests/fixtures/parallel_items/w01_held_v1.json'
REPORT = ROOT / '.godot/parallel_items/w01_held_v1/report.json'
VARIANTS = ('active', 'none', 'reserve')
OPERATIONS = {
    'vest_status_gate': ('assault_vest', 'status_gate'),
    'vest_special_defense': ('assault_vest', 'special_resistance'),
    'vest_physical_control': ('assault_vest', 'physical_control'),
    'dice_bullet_seed': ('loaded_dice', 'multihit_variable'),
    'dice_fixed_two': ('loaded_dice', 'fixed_multihit_control'),
    'dice_single_hit': ('loaded_dice', 'single_hit_control'),
    'sash_full_hp_ko': ('focus_sash', 'lethal_full'),
    'sash_partial_hp_ko': ('focus_sash', 'lethal_partial'),
    'sash_nonlethal': ('focus_sash', 'nonlethal_control'),
}
MOVES = {'tackle', 'reflect', 'amnesia', 'water_gun', 'bullet_seed', 'double_kick',
         'growl', 'double_edge'}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path: Path) -> dict:
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    if not isinstance(data, dict):
        raise ValueError(f'No es objeto JSON: {path}')
    return data


def validate_fixture(spec: dict) -> set[tuple[str, int]]:
    if set(spec) != {'schema_version', 'family', 'format', 'variants', 'cases'}:
        raise ValueError('Campos de cabecera no revisados')
    if spec['schema_version'] != 1 or spec['family'] != 'held_combat_w01' or spec['format'] != 'gen9calvounifiedv1':
        raise ValueError('Perfil/version no aprobados')
    if spec['variants'] != list(VARIANTS) or not isinstance(spec['cases'], list):
        raise ValueError('Controles de propiedad requeridos')
    found = set()
    executions = set()
    for row in spec['cases']:
        if not isinstance(row, dict) or set(row) != {
            'id', 'item_id', 'op', 'actor_species', 'actor_level', 'foe_species',
            'foe_level', 'own_moves', 'foe_move', 'hp', 'seeds'
        }:
            raise ValueError('Caso no declarado/revisado')
        cid = row['id']
        if cid not in OPERATIONS or (row['item_id'], row['op']) != OPERATIONS[cid] or cid in found:
            raise ValueError(f'Duplicado/caso fuera de lote {cid}')
        found.add(cid)
        if row['actor_species'] not in {'mew', 'pikachu'} or row['foe_species'] != 'mew':
            raise ValueError('Especie de fixture no aprobada')
        if type(row['actor_level']) is not int or type(row['foe_level']) is not int:
            raise ValueError('Niveles no enteros')
        if row['actor_level'] not in {1, 100} or row['foe_level'] not in {1, 100}:
            raise ValueError('Nivel fuera del escenario')
        if not isinstance(row['own_moves'], list) or not row['own_moves'] or any(m not in MOVES for m in row['own_moves']) or row['foe_move'] not in MOVES:
            raise ValueError('Movimiento de fixture no aprobado')
        if row['hp'] not in {'full', 'minus_one'}:
            raise ValueError('PS de fixture desconocidos')
        if not isinstance(row['seeds'], list) or not row['seeds'] or len(set(row['seeds'])) != len(row['seeds']):
            raise ValueError('Semillas vacias o duplicadas')
        if any(type(s) is not int or not 0 <= s <= 65535 for s in row['seeds']):
            raise ValueError('Semilla nativa invalida')
        for seed in row['seeds']:
            executions.add((cid, seed))
    if found != set(OPERATIONS):
        raise ValueError('Faltan casos obligatorios ' + str(sorted(set(OPERATIONS) - found)))
    require = {
        'vest_status_gate': ('mew', 100, 100, ['tackle', 'reflect'], 'amnesia', 'full'),
        'vest_special_defense': ('mew', 100, 100, ['tackle'], 'water_gun', 'full'),
        'vest_physical_control': ('mew', 100, 100, ['tackle'], 'tackle', 'full'),
        'dice_bullet_seed': ('mew', 100, 100, ['bullet_seed'], 'amnesia', 'full'),
        'dice_fixed_two': ('mew', 100, 100, ['double_kick'], 'amnesia', 'full'),
        'dice_single_hit': ('mew', 100, 100, ['tackle'], 'amnesia', 'full'),
        'sash_full_hp_ko': ('pikachu', 1, 100, ['growl'], 'double_edge', 'full'),
        'sash_partial_hp_ko': ('pikachu', 1, 100, ['growl'], 'double_edge', 'minus_one'),
        'sash_nonlethal': ('mew', 100, 1, ['growl'], 'tackle', 'full'),
    }
    for row in spec['cases']:
        tuple_seen = (row['actor_species'], row['actor_level'], row['foe_level'], row['own_moves'], row['foe_move'], row['hp'])
        if tuple_seen != require[row['id']]:
            raise ValueError('Fixture cambia el control fisico aprobado: ' + row['id'])
    return executions


def assert_effect(op: str, o: dict) -> None:
    a, n, r = (o[mode] for mode in VARIANTS)
    damage = lambda x: x['hp_before'] - x['hp_after']
    foe_loss = lambda x: x['foe_hp_before'] - x['foe_hp_after']
    if any(x['bench_consumed'] or not x['owner_unchanged'] or not x['restored'] for x in (a, n, r)):
        raise ValueError('Propiedad o guardado inconsistente')
    if op == 'status_gate':
        valid = a['disabled'] and not n['disabled'] and not r['disabled'] and a['rejected_unchanged'] and not a['consumed'] and a['native_units'] == 2
    elif op == 'special_resistance':
        valid = damage(n) > 0 and 0 <= damage(a) < damage(n) == damage(r) and not a['consumed'] and a['native_units'] == 2
    elif op == 'physical_control':
        valid = damage(a) == damage(n) == damage(r) and not a['consumed'] and a['native_units'] == 2
    elif op == 'multihit_variable':
        valid = a['hit_count'] in (4, 5) and r['hit_count'] == n['hit_count'] and not a['consumed'] and a['native_units'] == 2
    elif op == 'fixed_multihit_control':
        valid = a['hit_count'] == n['hit_count'] == r['hit_count'] == 2 and not a['consumed']
    elif op == 'single_hit_control':
        valid = foe_loss(a) == foe_loss(n) == foe_loss(r) and not a['consumed']
    elif op == 'lethal_full':
        valid = a['hp_after'] == 1 and n['hp_after'] == r['hp_after'] == 0 and a['consumed'] and a['native_units'] == 1
    elif op == 'lethal_partial':
        valid = a['hp_after'] == n['hp_after'] == r['hp_after'] == 0 and not a['consumed'] and a['native_units'] == 2
    elif op == 'nonlethal_control':
        valid = 0 < a['hp_after'] < a['hp_before'] and not a['consumed'] and a['native_units'] == 2
    else:
        raise ValueError('Operación desconocida')
    if not valid:
        raise ValueError('Asercion del efecto incumplida: ' + op)


def validate_report(report: dict, fixture: dict, base: Path) -> int:
    keys = {'schema_version', 'family', 'execution_mode', 'descriptor_sha256', 'status', 'checks', 'errors', 'rows', 'limits'}
    if set(report) != keys or report['schema_version'] != 1 or report['family'] != 'held_combat_w01' or report['execution_mode'] != 'godot_4_7_native':
        raise ValueError('Reporte invalido/no generado por el runner previsto')
    if report['descriptor_sha256'] != digest(DESCRIPTOR) or report['status'] != 'PASS' or report['errors'] or report['checks'] < 40:
        raise ValueError('Reporte sin PASS o descriptor no coincide')
    wanted = validate_fixture(fixture)
    if not isinstance(report['rows'], list) or len(report['rows']) != len(wanted):
        raise ValueError('Numero de experimentos incompleto')
    observed = set()
    for row in report['rows']:
        if set(row) != {'id', 'item_id', 'op', 'seed', 'checks', 'status', 'observed'}:
            raise ValueError('Fila no cumple contrato')
        key = (row['id'], row['seed'])
        if key not in wanted or key in observed or (row['item_id'], row['op']) != OPERATIONS[row['id']]:
            raise ValueError('Caso inesperado/duplicado')
        observed.add(key)
        if row['status'] != 'PASS' or row['checks'] < 10 or set(row['observed']) != set(VARIANTS):
            raise ValueError('Caso sin todas las comprobaciones')
        for mode in VARIANTS:
            point = row['observed'][mode]
            expected = {'valid', 'restored', 'evidence', 'sha256', 'hp_before', 'hp_after', 'foe_hp_before', 'foe_hp_after',
                        'hit_count', 'disabled', 'consumed', 'bench_consumed', 'native_units', 'owner_unchanged', 'rejected_unchanged'}
            if set(point) != expected or point['valid'] is not True or point['restored'] is not True:
                raise ValueError('Lectura parcial/sin restauracion')
            name = point['evidence']
            if not isinstance(name, str) or name != f"{row['id']}_{row['seed']}_{mode}.json":
                raise ValueError('Ruta de evidencia no revisada')
            path = (base / name).resolve()
            if path.parent != base.resolve() or not path.is_file() or digest(path) != point['sha256']:
                raise ValueError('Evidencia ausente/alterada')
            evidence = read(path)
            if evidence.get('id') != row['id'] or evidence.get('item_id') != row['item_id'] or evidence.get('mode') != mode or evidence.get('seed') != row['seed']:
                raise ValueError('Identidad de evidencia incorrecta')
            for prop in expected - {'valid', 'restored', 'evidence', 'sha256'}:
                if evidence.get(prop) != point[prop]:
                    raise ValueError('Escalar no coincide con evidencia nativa')
            if not isinstance(evidence.get('before'), dict) or not isinstance(evidence.get('after'), dict):
                raise ValueError('Snapshot bruto ausente')
        assert_effect(row['op'], row['observed'])
    if observed != wanted:
        raise ValueError('Escenarios esperados ausentes')
    return len(observed)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contracts', action='store_true', help='Solo validador de fixture; NO es PASS Godot')
    parser.add_argument('--report', type=Path, default=REPORT, help='Informe Godot real con evidencia')
    args = parser.parse_args()
    spec = read(DESCRIPTOR)
    cases = validate_fixture(spec)
    if args.contracts:
        print(f'W01_CONTRACTS_PASS scenarios={len(spec["cases"])} runs={len(cases)} godot=SIN_EJECUTAR')
    else:
        if not args.report.is_file():
            raise SystemExit('W01_SIN_EJECUTAR: falta report.json de Godot; no se declara PASS de efecto')
        count = validate_report(read(args.report), spec, args.report.parent)
        print(f'W01_NATIVE_EVIDENCE_PASS runs={count} variants={count * len(VARIANTS)}')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError) as exc:
        raise SystemExit('W01_VALIDATION_FAIL: ' + str(exc)) from exc
