"""Run pinned external comparisons in bounded batches, without changing the game."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone

from fixtures import stat_stage_cases, fixed_damage_cases, variable_power_cases, binding_cases, healing_cases, FAMILY_FIELDS, validate_manifest
from compare import compare

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
CACHE = ROOT / '.godot/battle_reference'
RUNTIME = CACHE / 'runtime'
VERSION = '0.10.11'


def sha(path):
    with Path(path).open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def write(path, value):
    path = Path(path)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temp.replace(path)


def executable(explicit, name, fallback):
    candidate = explicit or shutil.which(name) or (str(fallback) if Path(fallback).is_file() else None)
    if not candidate or not Path(candidate).is_file(): raise ValueError(f'Missing {name}; provide its executable path')
    return str(Path(candidate).resolve())


def command(args, log, timeout=120, append=False):
    started = time.perf_counter()
    with Path(log).open('a' if append else 'w', encoding='utf-8') as stream:
        process = subprocess.run(args, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout, check=False)
    if process.returncode: raise RuntimeError(f'Process exited {process.returncode}; see {log}')
    return round(time.perf_counter() - started, 3)


def protected_sources():
    # Hash the actual working sources, not HEAD: this workspace already contains
    # local runtime work. A comparison must not mutate any of these files.
    paths = set()
    for folder, pattern in [('modules', '*.gd'), ('scenes', '*.gd'), ('config', '*.json')]:
        paths.update((ROOT / folder).rglob(pattern))
    for rel in ('data/raw/pokemon_api.json', 'data/normalized/pokemon_api.json',
                'assets/local_battle_catalog/manifest.json', 'assets/local_battle_variants/manifest.json',
                '.godot/move_batch_catalog/index.json'):
        paths.add(ROOT / rel)
    return {p.relative_to(ROOT).as_posix(): sha(p) if p.is_file() else None for p in sorted(paths)}


def setup_runtime(install, npm, log):
    if install:
        RUNTIME.mkdir(parents=True, exist_ok=True)
        for filename in ('package.json', 'package-lock.json'):
            shutil.copyfile(HERE / filename, RUNTIME / filename)
        command([npm, 'ci', '--prefix', str(RUNTIME), '--ignore-scripts', '--no-audit', '--no-fund',
                 '--cache', str(CACHE / 'npm-cache')], log, timeout=180)
    for filename in ('package.json', 'package-lock.json'):
        if not (RUNTIME / filename).is_file() or sha(RUNTIME / filename) != sha(HERE / filename):
            raise ValueError('Missing/stale reference installation; rerun with --install')
    if read(RUNTIME / 'node_modules/@pkmn/sim/package.json')['version'] != VERSION:
        raise ValueError('Reference version differs from pinned version; rerun with --install')


def output_tables(output, report):
    with (output / 'differences.csv').open('w', newline='', encoding='utf-8-sig') as file:
        writer = csv.writer(file)
        writer.writerow(['case', 'move', 'status', 'field', 'reference', 'godot', 'reason'])
        for row in report['results']:
            if row['status'] == 'MATCH': continue
            for diff in row['differences'] or [{}]:
                writer.writerow([row['id'], row['move_id'], row['status'], diff.get('field', ''),
                                 diff.get('reference', ''), diff.get('godot', ''), row.get('reason', '')])
    counts = report['counts']
    lines = ['# Comparación externa de combate', '', f"Resultado: **{report['status']}**. Casos: {report['cases']}.", '',
             f"MATCH: {counts['MATCH']}; MISMATCH: {counts['MISMATCH']}; NOT_COMPARABLE: {counts['NOT_COMPARABLE']}.", '',
             'Familias y campos: consultar comparison_fields en report.json. Etapas, daño fijo, potencia variable y atrapamiento en individuales.', '',
             'Daño/HP exactos solo para fixed_damage. No certifica daño ordinario, distribución de azar, eventos/animaciones, dobles ni todas las habilidades. Referencia: @pkmn/sim@0.10.11, gen9customgame.', '',
             '## Diferencias', '']
    if not counts['MISMATCH'] and not counts['NOT_COMPARABLE']: lines.append('Ninguna en los campos comparados.')
    for row in report['results']:
        if row['status'] != 'MATCH': lines.append(f"- `{row['id']}`: {row['status']}; {row.get('reason') or json.dumps(row['differences'], ensure_ascii=False)}")
    (output / 'summary.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--install', action='store_true', help='Install exact dev dependencies with npm ci (network)')
    parser.add_argument('--family', choices=['stat_stages', 'fixed_damage', 'variable_power', 'binding', 'healing', 'all'], default='all')
    parser.add_argument('--batch-size', type=int, default=100)
    parser.add_argument('--limit', type=int)
    parser.add_argument('--manifest', type=Path, help='Optional explicit schema-1 fixture manifest')
    parser.add_argument('--output', type=Path, default=CACHE / 'latest')
    parser.add_argument('--node')
    parser.add_argument('--npm')
    parser.add_argument('--godot')
    args = parser.parse_args()
    if not 1 <= args.batch_size <= 1000 or args.limit is not None and args.limit < 1:
        parser.error('batch-size must be 1..1000 and limit must be positive')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    report = {'schema_version': 1, 'status': 'RUNNING', 'family': args.family,
              'started_utc': datetime.now(timezone.utc).isoformat()}
    write(output / 'report.json', report)
    (output / 'summary.md').write_text('Comparación en curso; consultar report.json.\n', encoding='utf-8')
    (output / 'differences.csv').write_text('case,move,status,field,reference,godot,reason\n', encoding='utf-8')
    before = None
    started = time.perf_counter()
    try:
        before = protected_sources()
        write(output / 'sources_before.json', before)
        node = executable(args.node, 'node', 'D:/Herramientas/NodeJS/node.exe')
        godot = executable(args.godot, 'godot', 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe')
        if not (ROOT / '.godot/global_script_class_cache.cfg').is_file():
            raise ValueError('Import this Godot project once in the editor before running the comparison')
        npm = executable(args.npm, 'npm.cmd' if sys.platform == 'win32' else 'npm', 'D:/Herramientas/NodeJS/npm.cmd') if args.install else None
        setup_runtime(args.install, npm, output / 'install.log')
        definitions = read(ROOT / 'data/normalized/pokemon_api.json')['moves']
        if args.manifest:
            supplied = read(args.manifest)
            if supplied.get('schema_version') != 1: raise ValueError('Unsupported manifest schema')
            cases = validate_manifest(supplied.get('cases'))
        else:
            cases = []
            if args.family in ('stat_stages', 'all'): cases.extend(stat_stage_cases(definitions))
            if args.family in ('fixed_damage', 'all'): cases.extend(fixed_damage_cases(definitions))
            if args.family in ('variable_power', 'all'): cases.extend(variable_power_cases(definitions))
            if args.family in ('binding', 'all'): cases.extend(binding_cases(definitions))
            if args.family in ('healing', 'all'): cases.extend(healing_cases(definitions))
            cases = validate_manifest(cases)
        if args.limit: cases = cases[:args.limit]
        manifest = {'schema_version': 1, 'family': args.family, 'cases': cases}
        write(output / 'manifest.json', manifest)
        reference = {'schema_version': 1, 'results': []}
        actual = {'schema_version': 1, 'results': []}
        batches = []
        for index, offset in enumerate(range(0, len(cases), args.batch_size), 1):
            subset = cases[offset:offset + args.batch_size]
            write(output / 'batch_input.json', {'schema_version': 1, 'cases': subset})
            # A crashed process must never leave last batch's observations usable.
            for filename in ('batch_reference.json', 'batch_godot.json'):
                (output / filename).unlink(missing_ok=True)
            ref_seconds = command([node, str(HERE / 'reference.cjs'), str(output / 'batch_input.json'),
                                   str(output / 'batch_reference.json'), str(RUNTIME)], output / 'reference.log', append=index > 1)
            godot_seconds = command([godot, '--headless', '--path', str(ROOT), '--script', 'res://tools/battle_reference/godot_runner.gd',
                                     '--', '--input', str(output / 'batch_input.json'), '--output', str(output / 'batch_godot.json')],
                                    output / 'godot.log', append=index > 1)
            if 'SCRIPT ERROR:' in (output / 'godot.log').read_text(encoding='utf-8'):
                raise RuntimeError('Godot script error; see godot.log')
            ref_batch, actual_batch = read(output / 'batch_reference.json'), read(output / 'batch_godot.json')
            for combined, batch, adapter in ((reference, ref_batch, 'showdown'), (actual, actual_batch, 'godot')):
                if batch.get('adapter') != adapter or not isinstance(batch.get('version'), str):
                    raise ValueError('Invalid adapter identity/version')
                if combined.get('version', batch['version']) != batch['version']:
                    raise ValueError('Adapter version changed between batches')
                combined.update({'adapter': adapter, 'version': batch['version']})
            batch_report = compare(subset, ref_batch, actual_batch)
            reference['results'].extend(ref_batch['results'])
            actual['results'].extend(actual_batch['results'])
            write(output / 'reference.json', reference)
            write(output / 'godot.json', actual)
            batches.append({'batch': index, 'cases': len(subset), 'counts': batch_report['counts'],
                            'reference_seconds': ref_seconds, 'godot_seconds': godot_seconds})
            print(f"Batch {index}: {len(subset)} cases; {batch_report['counts']}", flush=True)
        report.update(compare(cases, reference, actual))
        report.update({'reference': {'package': '@pkmn/sim', 'version': VERSION, 'format': 'gen9customgame',
                                    'lock_sha256': sha(HERE / 'package-lock.json')},
                       'executables': {'node': node, 'godot': godot}, 'batches': batches,
                       'engine_versions': {'node': subprocess.check_output([node, '--version'], text=True).strip(), 'godot': actual['version']},
                       'manifest_sha256': sha(output / 'manifest.json'),
                       'observations_sha256': {name: sha(output / name) for name in ('reference.json', 'godot.json')},
                       'tool_sha256': {p.name: sha(p) for p in sorted(HERE.iterdir()) if p.suffix in ('.py', '.cjs', '.gd', '.json')},
                       'comparison_fields': {family: list(FAMILY_FIELDS[family]) for family in sorted({c['family'] for c in cases})},
                       'limits': ['Exact body HP for fixed_damage/healing and residual component for binding; no ordinary damage or RNG distribution parity', 'No animation/event parity',
                                  'healing compares initial move HP/status/PP and reserve HP/status in explicit singles contexts; full Rest lifecycle remains in the server focal gate',
                                  'variable_power observes actual BasePower event/damage metadata, contact and hit; not ordinary HP parity',
                                  'binding compares natural duration range, first tick and blocked switch; exact eight-turn lifecycle only with native Grip Claw',
                                  'Only explicit synthetic singles contexts in each family; not all admitted moves/ability interactions',
                                  'Ruination canonical power 1 is explicitly normalized against reference basePower 0/current-HP effect']})
        output_tables(output, report)
    except Exception as error:
        report.update({'status': 'ERROR', 'error': f'{type(error).__name__}: {error}'})
        print(report['error'], file=sys.stderr, flush=True)
    finally:
        if before is not None:
            after = protected_sources()
            changed = sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))
            report['protected_sources'] = {'count': len(before), 'unchanged': not changed, 'changed': changed,
                                           'snapshot_sha256': sha(output / 'sources_before.json')}
            if changed: report.update({'status': 'ERROR', 'error': 'Protected game sources changed during comparison'})
        report['elapsed_seconds'] = round(time.perf_counter() - started, 3)
        write(output / 'report.json', report)
        if report['status'] == 'ERROR':
            (output / 'summary.md').write_text('# Comparación externa: ERROR\n\n' + report['error'] + '\n', encoding='utf-8')
    print(f"BATTLE_REFERENCE {report['status']}; {output / 'report.json'}", flush=True)
    return 0 if report['status'] == 'PASS' else (1 if report['status'] == 'NEEDS_REVIEW' else 2)


if __name__ == '__main__':
    sys.exit(main())
