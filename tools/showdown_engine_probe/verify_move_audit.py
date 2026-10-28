"""Validate audit completeness/provenance; NEVER certify all moves as functional."""
import collections
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/move_functional_audit'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    report = read(ROOT / 'docs/current/MOVE_FUNCTIONAL_AUDIT.json')
    native = read(OUT / 'native.json')
    manifest = read(OUT / 'manifest.json')
    rows = read(OUT / 'moves.json')
    before = read(OUT / 'before.json')
    canonical = read(ROOT / 'data/normalized/pokemon_api.json')['moves']
    assert len(rows) == len({r['id'] for r in rows}) == len(canonical) == 919
    assert {r['id'] for r in rows} == set(canonical)
    assert dict(collections.Counter(r['status'] for r in rows)) == report['counts']
    eligible = {r['id'] for r in rows if r['classification'] == 'ORDINARY'}
    assert len(eligible) == 832
    for id in eligible:
        scenarios = {(r['scenario'], r['seed']) for r in native['results'] if r['id'] == id and r['scenario'] not in ['contract', 'max']}
        assert scenarios == {(scenario, seed) for scenario in ['healthy', 'conditioned'] for seed in [1, 19]}, id
    assert len(native['results']) == manifest['cases'] == report['cases'] == 3362
    assert sum(r['steps'] for r in native['results']) == report['native_steps']
    assert all(r['status'] == 'NATIVE_EXECUTED' for r in native['results'])
    assert len(native['oracle']) == 15 and all(r['status'] == 'PASS' for r in native['oracle'])
    assert len(native['special']) == 19 and all(r['status'] == 'NATIVE_GEN8_ONLY' for r in native['special'])
    assert all(sha(ROOT / p) == old for p, old in before.items())
    for group in ['sources_sha256', 'evidence_sha256']:
        for p, expected in report[group].items(): assert sha(ROOT / p) == expected, p
    for file in manifest['batches']:
        assert (OUT / file).is_file()
    for name in ['export.log', 'native.log', 'godot.log']:
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR' not in text and '\nERROR:' not in text
    with (ROOT / 'docs/current/MOVE_FUNCTIONAL_AUDIT.csv').open(encoding='utf-8-sig', newline='') as file:
        csv_rows = list(csv.DictReader(file))
    assert {r['id']: r['status'] for r in csv_rows} == {r['id']: r['status'] for r in rows}
    assert report['all_moves_functional'] is False
    assert report['status'] == 'AUDIT_COMPLETE_WITH_OPEN_FINDINGS'
    print('MOVE_AUDIT_VERIFIED 919/919 inventoried; 3362 cases; open findings remain; protected files', len(before))


if __name__ == '__main__':
    main()
