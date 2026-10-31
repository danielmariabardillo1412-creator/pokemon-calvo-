"""Tests for the O100/O190 Item Closure V2 audit.

The audit is regenerated from the canonical catalog, the selection policy and
the reviewed evidence reports, then compared byte-for-byte with the stored
COVERAGE files. The assertions below pin the reconciled counters, the required
per-context vocabulary and concrete rows the O190 review called out.
"""
import csv
import hashlib
import io
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/item_import'))
import audit_item_closure_v2 as audit

COV_JSON = ROOT / 'docs/opencode/ITEM_CLOSURE_V2/COVERAGE.json'
COV_CSV = ROOT / 'docs/opencode/ITEM_CLOSURE_V2/COVERAGE.csv'
STATES = {
    'IMPLEMENTED_VERIFIED', 'IMPLEMENTED_UNVERIFIED', 'PARTIAL_VERIFIED',
    'DEPENDENCY_MISSING', 'EXCLUDED', 'NOT_APPLICABLE',
    'UNKNOWN_REQUIRES_REVIEW',
}
CONTEXTS = (
    'permission', 'art', 'equip', 'native_metadata', 'field_use',
    'battle_use', 'evolution', 'machine', 'scenario', 'overall',
)


def generated():
    audit.load_sources()
    canonical = audit.load(audit.CANON)['items']
    policy = audit.load(audit.POLICY)
    _, items = audit.build(canonical, policy)
    summary = audit.summarise(items)
    return audit.build_coverage(items, summary), items, summary


def stored():
    return json.loads(COV_JSON.read_text(encoding='utf-8'))


def row(items, item_id):
    return next(item for item in items if item['id'] == item_id)


def test_stored_files_match_generator():
    coverage, items, _ = generated()
    assert json.loads(audit.render_json(coverage)) == stored(), 'COVERAGE.json is stale'
    assert COV_CSV.read_text(encoding='utf-8') == audit.render_csv(items), 'COVERAGE.csv is stale'


def test_rows_cover_exactly_the_canonical_catalog():
    coverage, items, _ = generated()
    canonical = audit.load(audit.CANON)['items']
    assert len(items) == 2222 == len(canonical)
    assert coverage['total_canonical'] == coverage['total_processed'] == 2222
    assert [item['id'] for item in items] == sorted(canonical)
    assert len({item['id'] for item in items}) == 2222
    assert all(item['name_es'] for item in items), 'empty Spanish display name'
    assert all(item['name_en'] == '' for item in items), 'name_en must stay empty'
    assert all('display_name' in item['name_source'] for item in items)
    with COV_CSV.open(encoding='utf-8', newline='') as stream:
        csv_rows = list(csv.DictReader(stream))
    assert len(csv_rows) == 2222
    assert set(csv_rows[0]) == set(audit.CSV_FIELDS)


def test_state_vocabulary_is_closed_and_unknown_is_zero():
    coverage, items, summary = generated()
    for item in items:
        assert item['permission'] in {'PERMITTED', 'EXCLUDED', 'NOT_APPLICABLE'}
        for context in CONTEXTS[1:]:
            assert item[context] in STATES, (item['id'], context, item[context])
        assert isinstance(item['dependency'], str) and isinstance(item['notes'], str)
    assert coverage['unknown_rows'] == 0
    assert coverage['unknown_ids'] == []
    assert summary['unknown_ids'] == []
    assert 'UNKNOWN_REQUIRES_REVIEW' not in Counter(
        item[context] for item in items for context in CONTEXTS[1:])
    assert sum(coverage['state_distribution'].values()) == 2222
    for distribution in coverage['context_distributions'].values():
        assert sum(distribution.values()) == 2222


def test_permission_and_native_reconcile_631_625_619():
    coverage, items, _ = generated()
    assert coverage['permitted_holdable'] == 631
    assert coverage['excluded_count'] == 43
    assert coverage['permitted_after_exclusion'] == 625
    assert coverage['context_distributions']['permission'] == {
        'EXCLUDED': 43, 'NOT_APPLICABLE': 1554, 'PERMITTED': 625,
    }
    assert coverage['native_present'] == 619
    assert coverage['native_missing'] == 6
    assert coverage['context_distributions']['native_metadata'] == {
        'DEPENDENCY_MISSING': 6, 'IMPLEMENTED_VERIFIED': 619, 'NOT_APPLICABLE': 1597,
    }
    assert coverage['missing_native_ids'] == [
        'amulet_coin', 'cleanse_tag', 'exp_share', 'linking_cord',
        'luck_incense', 'pure_incense',
    ]
    assert 'smoke_ball' not in coverage['missing_native_ids']
    assert row(items, 'smoke_ball')['native_present'] is True
    assert row(items, 'smoke_ball')['native_metadata'] == 'IMPLEMENTED_VERIFIED'


def test_art_machine_evolution_and_field_counters():
    coverage, items, _ = generated()
    assert coverage['art_entries_with_art'] == 1011
    assert coverage['art_non_excluded_without_prepared'] == 1055
    assert coverage['art_excluded_from_plan'] == 156
    assert (coverage['art_entries_with_art']
            + coverage['art_non_excluded_without_prepared']
            + coverage['art_excluded_from_plan']) == 2222
    assert coverage['machine_ids_mapped'] == 338
    assert coverage['machine_verified'] == 229
    assert coverage['machine_pending'] == 109
    assert coverage['evolution_routes_supported'] == 57
    assert coverage['evolution_routes_other'] == 15
    assert coverage['evolution_item_ids'] == 26
    assert coverage['evolution']['edges'] == 72
    with (ROOT / 'docs/current/ITEM_FIELD_V8.csv.txt').open(encoding='utf-8', newline='') as stream:
        matrix = {r['id']: r for r in csv.DictReader(stream)}
    assert sum(int(r['supported_evolution_routes_tested'] or 0) for r in matrix.values()) == 57
    assert sum(int(r['other_evolution_routes'] or 0) for r in matrix.values()) == 15
    assert sum(1 for r in matrix.values()
               if int(r['supported_evolution_routes_tested'] or 0)
               or int(r['other_evolution_routes'] or 0)) == 26
    assert sum(1 for r in items if r['machine'] == 'IMPLEMENTED_VERIFIED') == 229
    # The 42 V19 recovery rows and 35 V13/V19 training rows are present as
    # concrete field states, not as global presence claims.
    recovery = audit.load(audit.V19_AUDIT)['compiled_ids']
    assert len(recovery) == 42
    assert all(row(items, item_id)['field_use'] == 'IMPLEMENTED_VERIFIED' for item_id in recovery)
    assert len(audit.FIELD_TRAINING_PARTIAL) == 35
    assert all(row(items, item_id)['field_use'] == 'PARTIAL_VERIFIED'
               for item_id in audit.FIELD_TRAINING_PARTIAL)


def test_every_dependency_missing_row_has_a_concrete_reason():
    coverage, items, _ = generated()
    assert coverage['state_distribution']['DEPENDENCY_MISSING'] == 1604
    missing = [item for item in items if item['overall'] == 'DEPENDENCY_MISSING']
    assert len(missing) == 1604
    assert all(item['dependency'].strip() for item in missing)
    assert all(len(item['dependency']) > 20 for item in missing)


def test_o110_and_o120_rows_are_the_only_claimed_effects():
    coverage, items, _ = generated()
    support = set(audit.load(audit.SUPPORT_PROFILE)['items'])
    assert len(support) == 11
    assert set(coverage['o110']['reviewed_ids']) == support
    for item_id in support:
        item = row(items, item_id)
        assert item['battle_use'] == 'IMPLEMENTED_VERIFIED', item_id
        assert item['scenario'] == 'IMPLEMENTED_VERIFIED', item_id
        assert item['overall'] == 'IMPLEMENTED_VERIFIED', item_id
    assert set(coverage['o120']['concrete_dependencies']) == {
        'amulet_coin', 'exp_share', 'linking_cord', 'luck_incense'}
    smoke = row(items, 'smoke_ball')
    assert smoke['battle_use'] == 'IMPLEMENTED_VERIFIED'
    assert smoke['native_metadata'] == 'IMPLEMENTED_VERIFIED'
    assert smoke['overall'] == 'IMPLEMENTED_VERIFIED'
    for item_id in ('cleanse_tag', 'pure_incense'):
        item = row(items, item_id)
        assert item['scenario'] == 'PARTIAL_VERIFIED'
        assert item['overall'] == 'PARTIAL_VERIFIED'
        assert 'PARTIAL_VERIFIED_RATE_ONLY' in item['dependency']
        assert item['native_metadata'] == 'DEPENDENCY_MISSING'
    for item_id in ('amulet_coin', 'exp_share', 'linking_cord', 'luck_incense'):
        assert row(items, item_id)['overall'] == 'DEPENDENCY_MISSING'


def test_reviewed_specific_rows_do_not_regress_to_unknown():
    _, items, _ = generated()
    # R6 called out these exact rows.
    capsule = row(items, 'ability_capsule')
    assert capsule['field_use'] == 'PARTIAL_VERIFIED' and capsule['overall'] == 'PARTIAL_VERIFIED'
    tm = row(items, 'tm01')
    assert tm['machine'] == 'IMPLEMENTED_VERIFIED' and tm['overall'] == 'IMPLEMENTED_VERIFIED'
    doll = row(items, 'poke_doll')
    assert doll['battle_use'] == 'IMPLEMENTED_VERIFIED' and doll['overall'] == 'IMPLEMENTED_VERIFIED'
    assert row(items, 'soothe_bell')['field_use'] == 'PARTIAL_VERIFIED'
    assert row(items, 'macho_brace')['overall'] == 'DEPENDENCY_MISSING'
    assert 'EV-gain multiplier' in row(items, 'macho_brace')['dependency']
    assert row(items, 'blank_plate')['overall'] == 'NOT_APPLICABLE'
    assert row(items, 'max_mushrooms')['overall'] == 'DEPENDENCY_MISSING'


def test_sources_sha256_match_the_real_files():
    coverage = stored()
    assert coverage['sources_sha256']
    for relative, expected in coverage['sources_sha256'].items():
        path = ROOT / relative
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert digest == expected, relative


def test_csv_columns_and_rows_match_json():
    coverage = stored()
    with COV_CSV.open(encoding='utf-8', newline='') as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == len(coverage['rows']) == 2222
    for csv_row, json_row in zip(rows, coverage['rows']):
        assert csv_row['id'] == json_row['id']
        assert csv_row['overall'] == json_row['overall']
        assert csv_row['name_es'] == json_row['name_es']
        assert csv_row['name_en'] == ''


if __name__ == '__main__':
    tests = [value for name, value in sorted(globals().items())
             if name.startswith('test_') and callable(value)]
    for test in tests:
        test()
        print('PASS:', test.__name__)
    print('All item closure audit tests passed:', len(tests))
