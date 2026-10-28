"""Record reviewed source candidates and conditional style work, without changing gameplay."""
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/current'
OUT = Path(r'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\review_batch_v4')


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def write(p, data):
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    frozen = read(DOC / 'ITEM_ART_COVERAGE_AUDIT_V1.json')
    protected = frozen['sources_sha256']
    assert all(sha(ROOT / p) == value for p, value in protected.items())
    scan = read(OUT / 'candidates.json')
    assert scan['status'] == 'SOURCE_SCAN_COMPLETE' and len(scan['rows']) == 768
    candidates = {r['id']: r for r in scan['rows']}
    aliases = {r['id']: r for r in read(OUT / 'punctuation_aliases.json')['rows']}
    assert len(aliases) == 28 and not any('error' in row for row in aliases.values())
    groups = defaultdict(list)
    ready, conditional = {}, {}
    for item_id, row in candidates.items():
        if row['status'] == 'READY':
            path = Path(row['file'])
            assert sha(path) == row['sha256']
            with Image.open(path) as image:
                image.load()
                assert image.size == (row['width'], row['height']) and min(image.size) >= 80
                assert image.convert('RGBA').getchannel('A').getbbox()
            ready[item_id] = {**row, 'review_status': 'SOURCE_IMAGE_VISUALLY_REVIEWED_CONTENT_PENDING', 'installed': False, 'contact_sheet': 'all_contact_' + str(len(ready) // 96 + 1) + '.png'}
            groups[row['sha256']].append(item_id)
        else:
            path = Path(aliases[item_id]['file']) if item_id in aliases else OUT / 'downloads' / item_id / 'POKEAPI_ROOT.png'
            assert path.exists(), item_id
            with Image.open(path) as image:
                image.load()
                size = image.size
                assert min(size) < 80 and image.convert('RGBA').getchannel('A').getbbox()
            conditional[item_id] = {'id': item_id, 'display_name': row.get('display_name', ''), 'family': row.get('family', ''), 'reference_file': str(path), 'reference_sha256': sha(path), 'reference_size': list(size), 'action': 'SEARCH_MATCHING_ILLUSTRATION_OR_REDRAW_IF_CONTENT_RETAINED', 'content_decision': 'PENDING_NOT_BANNED', 'reason': 'Small source sprite located; no matching modern artwork selected in this scan.', 'filename_alias_resolved': item_id in aliases}
    assert len(ready) == 350 and len(conditional) == 418 and len(groups) == 125
    optional_style = {item_id: {'id': item_id, 'reason': 'The source illustration has a simple flat outline and deliberately pixel-shaped central symbol; visually simpler than the detailed SV items.', 'action': 'OPTIONAL_STYLE_REVIEW_IF_ROTOM_POWERS_RETAINED; NOT_A_CORRUPT_IMAGE'} for item_id in ready if item_id.startswith('roto_') and item_id != 'roto_stick'}
    assert len(optional_style) == 11
    ledger = []
    for row in frozen['rows']:
        item_id = row['id']
        state, action = row['art_state'], ''
        if item_id in ready:
            state, action = 'SOURCE_ART_REVIEWED_CONTENT_PENDING', 'KEEP_SOURCE_CANDIDATE_UNTIL_CONTENT_AND_RUNTIME_INTEGRATION'
        elif item_id in conditional:
            state, action = 'SMALL_REFERENCE_STYLE_REVIEW_IF_RETAINED', conditional[item_id]['action']
        elif state == 'CONTENT_REVIEW_WITHOUT_PREPARED_ART' and row['family'] == 'MACHINE':
            state, action = 'MACHINE_ART_AND_MAPPING_DEFERRED', 'KEEP_CURRENT_DISC_DESIGN_DIRECTION; DEFER_REDESIGN_PER_USER'
        elif state == 'CONTENT_REVIEW_WITHOUT_PREPARED_ART' and row['family'] == 'RAID_EVENT_CRYSTAL':
            state, action = 'RAID_SYSTEM_CONTENT_REVIEW', 'REVIEW_EVENT_SYSTEM_BEFORE_REQUESTING_300_INDIVIDUAL_IMAGES'
        elif state == 'INSTALLED_PROVISIONAL_STYLE':
            action = 'REDRAW_OR_FIND_BETTER_MATCH; EXISTING_ICON_STAYS_UNTIL_REPLACEMENT_REVIEW'
        elif state == 'PREPARED_NOT_INSTALLED':
            action = 'GENERATED_CANDIDATE_PREPARED; NO_NEW_DRAWING_NEEDED'
        ledger.append({**row, 'review_state': state, 'next_action': action})
    counts = dict(Counter(row['review_state'] for row in ledger))
    assert sum(counts.values()) == 2222
    report = {'status': 'SOURCE_AND_STYLE_REVIEW_COMPLETE_FOR_NON_MACHINE_NON_RAID_PENDING_FAMILIES', 'date': '2026-10-28', 'phase': 'ITEM_ART_REVIEW_V4', 'source_entries_scanned': 768, 'source_entries_with_reviewed_illustrations': 350, 'distinct_reviewed_image_hashes': 125, 'reviewed_contact_sheets': 4, 'conditional_small_reference_entries': 418, 'small_references_with_filename_punctuation_resolved': 28, 'confirmed_existing_style_replacement': ['pewter_crunchies'], 'generated_candidates_already_prepared': frozen['prepared_ids'], 'new_corrupt_or_visibly_broken_illustrations_detected': [], 'reviewed_source_families': dict(Counter(row['family'] for row in ready.values())), 'shared_art_groups': [{'sha256': key, 'ids': ids} for key, ids in groups.items() if len(ids) > 1], 'full_ledger_counts': counts, 'research_directory': str(OUT), 'runtime_catalog_entries': 654, 'runtime_and_data_unchanged': True, 'review_limitations': ['Contact-sheet visual review and image decoding are not item-effect or native-bag integration tests.', 'A visually acceptable source image does not approve the item for final content.', 'Shared generic bags for 222 crafting materials are source-provided representations, not 222 bespoke depictions of the ingredients.', 'Small references are conditional style work, not a request to generate 418 images.', 'Modern-world styling, MT/MO/DT redesign and game-specific story items remain separate content/design decisions.'], 'source_sha256': {'docs/current/ITEM_ART_COVERAGE_AUDIT_V1.json': sha(DOC / 'ITEM_ART_COVERAGE_AUDIT_V1.json'), 'candidates.json': sha(OUT / 'candidates.json'), 'punctuation_aliases.json': sha(OUT / 'punctuation_aliases.json')}, 'reviewed_source_candidates': ready, 'conditional_style_queue': conditional}
    report['optional_style_review'] = optional_style
    report['catalog_classification_observation'] = {'leaders_crest': 'Source category picnic is not sufficient to discard this functional evolution-related item. Its illustration was found and reviewed; do not exclude it with decorative picnic objects.'}
    write(DOC / 'ITEM_ART_REVIEW_V4.json', report)
    write(DOC / 'ITEM_ART_FIX_QUEUE_V1.json', {'date': '2026-10-28', 'confirmed_existing_replacement': {'pewter_crunchies': {'name_es': 'Rokikos', 'reason': 'Existing provisional small sprite; original larger corrupt candidate remains rejected.', 'action': 'GENERATE_OR_FIND_MATCHING_ILLUSTRATION; DO_NOT_REMOVE_EXISTING_ICON'}}, 'already_generated_no_redraw_needed': frozen['prepared_ids'], 'conditional_style_queue': conditional, 'optional_style_review': optional_style, 'runtime_changes': 'NONE'})
    for filename, rows in [('ITEM_ART_REVIEW_V4.csv', ledger), ('ITEM_ART_STYLE_QUEUE_V1.csv', list(conditional.values()))]:
        with (DOC / filename).open('w', encoding='utf-8-sig', newline='') as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
    assert all(sha(ROOT / p) == value for p, value in protected.items())
    status = read(DOC / 'ITEM_ART_CURRENT_STATUS.json')
    status['latest_source_art_review'] = {'report': 'docs/current/ITEM_ART_REVIEW_V4.json', 'ledger': 'docs/current/ITEM_ART_REVIEW_V4.csv', 'fix_queue': 'docs/current/ITEM_ART_FIX_QUEUE_V1.json', 'source_images_reviewed_for_entries': 350, 'source_image_hashes': 125, 'small_reference_style_review_if_retained': 418, 'runtime_entries_unchanged': 654, 'machines_deferred': 337, 'raid_items_await_content_review': 300}
    write(DOC / 'ITEM_ART_CURRENT_STATUS.json', status)
    print(json.dumps({'status': 'PASS', 'scanned': 768, 'source_images_reviewed_for_entries': 350, 'unique_hashes': 125, 'conditional_small_reference_entries': 418, 'confirmed_replacement': ['pewter_crunchies'], 'full_ledger_counts': counts}))


if __name__ == '__main__':
    main()
