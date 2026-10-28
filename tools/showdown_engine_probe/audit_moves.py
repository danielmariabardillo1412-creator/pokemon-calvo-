"""Read-only whole-catalogue move audit, native batches + actual Godot adapter."""
import collections
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/move_functional_audit'
NODE = 'D:/Herramientas/NodeJS/node.exe'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def protected():
    files = [p for folder in ['modules', 'scenes', 'config', 'data'] for p in (ROOT / folder).rglob('*')
             if p.is_file() and p.suffix in ['.gd', '.cjs', '.json', '.tscn']]
    files += [ROOT / 'project.godot', ROOT / 'assets/local_battle_catalog/manifest.json',
              ROOT / 'assets/local_battle_variants/manifest.json', ROOT / '.godot/move_batch_catalog/index.json']
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in files}


def run(args, name):
    print('MOVE_AUDIT_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as stream:
        p = subprocess.run(args, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=900)
    text = (OUT / name).read_text(encoding='utf-8-sig')
    if p.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise RuntimeError(f'{name} failed; inspect {OUT / name}')
    print(text.splitlines()[-1], flush=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    before = protected()
    (OUT / 'before.json').write_text(json.dumps(before, indent=2), encoding='utf-8')
    started = time.monotonic()
    run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tools/showdown_engine_probe/move_audit.gd', '--', '--export'], 'export.log')
    run([NODE, 'tools/showdown_engine_probe/move_audit.cjs'], 'native.log')
    run([GODOT, '--headless', '--path', str(ROOT), '--script', 'tools/showdown_engine_probe/move_audit.gd'], 'godot.log')
    native = read(OUT / 'native.json')
    projected = {r['case_id']: r for line in (OUT / 'godot.jsonl').read_text(encoding='utf-8').splitlines() if (r := json.loads(line))}
    findings = collections.defaultdict(list)
    for result in native['results']:
        findings[result['id']].append(result)
    rows = []
    for entry in native['inventory']:
        row = dict(entry)
        cases = findings[entry['id']]
        results = [projected[r['case_id']] for r in cases if r['case_id'] in projected]
        issues = [dict(issue, case_id=r['case_id']) for r in results for issue in r['issues']]
        native_errors = [r for r in cases if r['status'] != 'NATIVE_EXECUTED']
        oracles = [r for r in native['oracle'] if r['id'] == entry['id']]
        ordinary = [r for r in cases if r['scenario'] != 'contract']
        executed_without_context_failure = any(r.get('successful_actor_actions', 0) for r in results)
        if entry['classification'] == 'MAX_PROFILE_PENDING' and cases:
            status = 'MAX_GEN8_INTEGRATION_OK' if not native_errors and not issues and executed_without_context_failure else 'MAX_GODOT_BLOCKED'
        elif entry['classification'] != 'ORDINARY':
            status = entry['classification']
        elif native_errors:
            status = 'NATIVE_OR_FIXTURE_ERROR'
        elif issues:
            status = 'BLOCKED_GAME_ADAPTER'
        elif not executed_without_context_failure:
            status = 'CONTEXT_REQUIRED'
        elif any(r['status'] == 'FAIL' for r in oracles):
            status = 'EXPECTED_RESULT_MISMATCH'
        else:
            status = 'INTEGRATION_OK_IN_TESTED_CONTEXTS'
        row.update(status=status, cases=len(cases), steps=sum(r['steps'] for r in cases),
                   native_errors=[{'case_id': r['case_id'], 'error': r.get('error')} for r in native_errors],
                   adapter_issues=issues, context_failures=sum(r['failed_context'] for r in ordinary),
                   independent_contracts=oracles, independently_certified_all_effects=False)
        rows.append(row)
    assert len(rows) == len(read(ROOT / 'data/normalized/pokemon_api.json')['moves'])
    assert len(projected) == sum(r['status'] == 'NATIVE_EXECUTED' for r in native['results'])
    after = protected()
    assert before == after, [p for p in before if before[p] != after.get(p)]
    counts = dict(collections.Counter(r['status'] for r in rows))
    (OUT / 'moves.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
    with (ROOT / 'docs/current/MOVE_FUNCTIONAL_AUDIT.csv').open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f)
        writer.writerow(['id', 'status', 'cases', 'steps', 'context_failures', 'independent_contracts', 'adapter_reasons'])
        for row in rows:
            reasons = sorted({json.dumps(p['reason'], ensure_ascii=False) for p in row['adapter_issues'] if 'reason' in p})
            writer.writerow([row['id'], row['status'], row['cases'], row['steps'], row['context_failures'], len(row['independent_contracts']), '; '.join(reasons)])
    sources = [ROOT / 'tools/showdown_engine_probe' / name for name in ['audit_moves.py', 'move_audit.cjs', 'move_audit.gd']]
    evidence = [OUT / name for name in ['before.json', 'manifest.json', 'native.json', 'moves.json', 'godot.jsonl', 'export.log', 'native.log', 'godot.log']]
    report = {'status': 'AUDIT_COMPLETE_WITH_OPEN_FINDINGS', 'all_moves_functional': False,
              'date': '2026-10-27', 'inventory': len(rows), 'counts': counts,
              'cases': len(native['results']), 'native_steps': sum(r['steps'] for r in native['results']),
              'snapshot_roundtrips': sum(r['roundtrips'] for r in native['results']),
              'saved_continuations': sum(r['replay'] for r in native['results']),
              'independent_expected_contracts': native['oracle'], 'max_gen8_probes': native['special'],
              'godot_projection_cases': len(projected), 'protected_files_unchanged': len(before),
              'seconds': round(time.monotonic() - started, 2),
              'cases_use': 'Actual CreatureFactory DTOs, current NativeEngine prepare/commit, current Godot event adapter and mirror in offline bounded batches.',
              'limits': ['Generic healthy/conditioned fixtures, two seeds, up to four native decisions; not all interactions.',
                         'Context failures require targeted scenarios and are not automatically defects.',
                         'Successful native replay checks determinism, not independent Pokemon correctness.',
                         'Max connects through explicit Gen8 Godot profile; Gen9 remains separate.',
                         'This is not GPU/per-move VFX certification.',
                         'Default legacy backend remains separate (620 admitted; 230 mechanics pending).'],
              'blockers': [{'id': r['id'], 'status': r['status'], 'reasons': sorted({json.dumps(p.get('reason'), ensure_ascii=False) for p in r['adapter_issues']})}
                           for r in rows if r['status'] not in ['INTEGRATION_OK_IN_TESTED_CONTEXTS', 'EXCLUDED', 'Z_PENDING']],
              'sources_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in sources},
              'evidence_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence}}
    (ROOT / 'docs/current/MOVE_FUNCTIONAL_AUDIT.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('MOVE_AUDIT_COMPLETE', json.dumps({'inventory': len(rows), 'counts': counts, 'cases': len(native['results']), 'steps': report['native_steps'], 'oracles_failed': sum(r['status'] == 'FAIL' for r in native['oracle'])}), flush=True)


if __name__ == '__main__':
    main()
