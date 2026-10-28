"""Count installed/prepared/provisional item art without treating retained IDs as final content."""
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/current'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    sources = {
        'scope': DOC / 'ITEM_ART_SCOPE.json',
        'manifest': ROOT / 'assets/local_item_catalog/manifest.json',
        'prepared': ROOT / 'art_review/item_icons_generated_completion_v1/review.json',
        'data': ROOT / 'data/normalized/pokemon_api.json',
        'runtime_policy': ROOT / 'config/item_selection_v1.json',
    }
    before = {key: sha(path) for key, path in sources.items()}
    scope = read(sources['scope'])
    manifest = read(sources['manifest'])
    installed = manifest['items']
    all_prepared = read(sources['prepared'])['items']
    prepared = {k: v for k, v in all_prepared.items() if k not in installed}
    for item_id in set(all_prepared).intersection(installed):
        assert installed[item_id]['sha256'] == all_prepared[item_id]['sha256'], item_id
    v5 = any(batch['phase'] == 'ITEM_ART_REVIEWED_V5' for batch in manifest.get('art_batches', []))
    report_stem = 'ITEM_ART_COVERAGE_V5' if v5 else 'ITEM_ART_COVERAGE_AUDIT_V1'
    canonical = read(sources['data'])['items']
    assert len(canonical) == len(scope['rows']) == 2222
    assert set(installed).isdisjoint(prepared)
    records = []
    for entry in scope['rows']:
        item_id = entry['id']
        is_excluded = entry['scope'].startswith('EXCLUDED')
        image = ''
        if is_excluded:
            assert item_id not in installed and item_id not in prepared
            state = 'EXCLUDED_FROM_ART_PLAN'
        elif item_id in installed:
            row = installed[item_id]
            image = row['texture'].removeprefix('res://')
            assert sha(ROOT / image) == row['sha256']
            state = 'INSTALLED_PROVISIONAL_STYLE' if row['small_fallback'] else 'INSTALLED'
        elif item_id in prepared:
            row = prepared[item_id]
            image = row['selected_file']
            assert sha(ROOT / image) == row['sha256']
            state = 'PREPARED_NOT_INSTALLED'
        else:
            state = 'CONTENT_REVIEW_WITHOUT_PREPARED_ART'
        records.append({
            'id': item_id, 'name_es': canonical[item_id]['display_name'],
            'family': entry['family'], 'category': entry['category'],
            'art_state': state, 'image': image,
            'source_candidate_metadata_only': bool(entry['sv_candidate'] or entry['dw_candidate'] or entry['other_illustration_candidate']),
            'content_scope': entry['scope'], 'exclusion_reason': entry['reason'],
        })
    counts = dict(Counter(row['art_state'] for row in records))
    expected_counts = {
        'INSTALLED': 653, 'CONTENT_REVIEW_WITHOUT_PREPARED_ART': 1405,
        'PREPARED_NOT_INSTALLED': 7, 'EXCLUDED_FROM_ART_PLAN': 156,
        'INSTALLED_PROVISIONAL_STYLE': 1,
    }
    if v5:
        expected_counts = {'INSTALLED': 1010, 'CONTENT_REVIEW_WITHOUT_PREPARED_ART': 1055, 'EXCLUDED_FROM_ART_PLAN': 156, 'INSTALLED_PROVISIONAL_STYLE': 1}
    assert counts == expected_counts, counts
    remaining = [row for row in records if row['art_state'] == 'CONTENT_REVIEW_WITHOUT_PREPARED_ART']
    machines = [row for row in records if row['family'] == 'MACHINE']
    machine_prefixes = Counter('MO' if row['id'].startswith('hm') else 'DT' if row['id'].startswith('tr') else 'MT' for row in machines)
    report = {
        'status': 'PASS', 'date': '2026-10-28', 'phase': report_stem,
        'canonical_entries': len(records), 'counts': counts,
        'installed_total': len(installed), 'prepared_total': len(prepared),
        'installed_or_prepared_total': len(installed) + len(prepared),
        'unique_installed_or_prepared_image_hashes': len({sha(ROOT / row['image']) for row in records if row['image']}),
        'remaining_content_review_by_family': dict(Counter(row['family'] for row in remaining)),
        'machines_total_by_kind': dict(machine_prefixes),
        'machine_entries_without_prepared_art': sum(row['family'] == 'MACHINE' for row in remaining),
        'provisional_style_ids': [row['id'] for row in records if row['art_state'] == 'INSTALLED_PROVISIONAL_STYLE'],
        'prepared_ids': sorted(prepared),
        'source_candidate_hints_unverified_among_remaining': sum(row['source_candidate_metadata_only'] for row in remaining),
        'core_families_without_installed_or_prepared_art': sum(row['family'] in {'BERRY', 'HELD_COMBAT_CANDIDATE', 'MEDICINE', 'EVOLUTION', 'CAPTURE_BALL'} for row in remaining),
        'scope': 'Read-only coverage audit. Remaining source entries are not confirmed final game content or required distinct illustrations.',
        'notes': [
            str(len(remaining)) + ' is an exact count of non-excluded source IDs without installed/prepared art, not a drawing commission.',
            'Source image filename hints are not verified assets and do not count as prepared.',
            'Distinct IDs may share artwork. MT/MO/DT redesign and machine-to-move/version mapping remain undecided.',
            'Rokikos already has a small provisional icon; it is not one of the absent prepared entries.',
            'No new content exclusions are inferred from empty descriptions, unused category, missing callbacks or age.',
            'No generation or redesign occurs in this audit.',
        ],
        'sources_sha256': {str(path.relative_to(ROOT)): before[key] for key, path in sources.items()},
        'rows': records,
    }
    assert before == {key: sha(path) for key, path in sources.items()}
    (DOC / (report_stem + '.json')).write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for filename, rows in [(report_stem + '.csv', records), ('ITEM_ART_REMAINING_REVIEW_V5.csv' if v5 else 'ITEM_ART_REMAINING_REVIEW_V1.csv', remaining)]:
        with (DOC / filename).open('w', encoding='utf-8-sig', newline='') as out:
            writer = csv.DictWriter(out, fieldnames=list(records[0]))
            writer.writeheader()
            writer.writerows(rows)
    print(json.dumps({key: value for key, value in report.items() if key not in {'rows', 'notes', 'sources_sha256'}}, ensure_ascii=True))


if __name__ == '__main__':
    main()
