"""Close the five contrasts; retain the 19 verified external dependencies."""
import argparse
import hashlib
import json
from pathlib import Path
from inspect_general_sources import GAME, MOVES, BEFORE_SHA

CONTRAST = {'aeroblast', 'clanging_scales', 'court_change', 'destiny_bond', 'doom_desire'}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def close(path):
    report = read(path)
    assert report['gpu'] and not report['errors'] and report['states'] == 2532
    contract = report['contract']
    assert contract['states'] == 12660 and contract['target_anchor_checks'] == 540
    assert contract['court_final_anchor_checks'] == 40 and contract['rejected_changed_exports'] == 4
    for field, source in [('index_sha256', '.godot/move_batch_catalog/index.json'),
                          ('renderer_sha256', 'scenes/visual/community_move_preview.gd'),
                          ('runner_sha256', 'tests/visual/move_general_review_runner.gd')]:
        assert report[field] == sha(GAME / source)
    assert sha(GAME / '.godot/move_general_checks/reference/preview_before.gd') == BEFORE_SHA
    baseline = read(GAME / '.godot/move_self_body_checks/reference/baseline.json')
    for file, digest in baseline.items():
        if file != 'head':
            assert sha(GAME / file) == digest
    previous_path = GAME / '.godot/move_z_checks/c2a52b27e855bafa/gpu/review.json'
    assert sha(previous_path) == '1be9f5844bbe15fd7eb487d01c8a07d36eed7f8ab0ebfa911518112347793913'
    previous = read(previous_path)
    boards_path = path.parent / 'boards.json'
    boards = read(boards_path)
    assert boards['report_sha256'] == sha(path) and len(boards['pages']) == 9
    all_clips = {m + '/' + side for m in MOVES for side in ['back', 'front']}
    assert {c['source']['id'] for c in report['clips']} == all_clips
    assert {cid for p in boards['pages'] for cid in p['clip_ids']} == all_clips
    for page in boards['pages']:
        assert sha(path.parent / page['path']) == page['sha256']
    for row in report['samples']:
        for capture in row['captures']:
            assert sha(path.parent / capture['path']) == capture['sha256']
        if row['id'].split('/')[0] not in {'clanging_scales', 'court_change'}:
            assert row['captures'][0]['sha256'] == row['captures'][1]['sha256']
    source_path = GAME / '.godot/move_general_checks/reference/phase_sources.json'
    sources = read(source_path)
    assert len(sources['clips']) == 48 and sources['index_sha256'] == report['index_sha256']
    pending = previous['pending_baseline_clip_ids']
    resolved = {cid for cid in pending if cid.split('/')[0] in CONTRAST}
    assert len(resolved) == 9
    remaining = {cid: status for cid, status in pending.items() if cid not in resolved}
    external = contract['external_handoffs']
    assert {row['id'] for row in external} == remaining.keys()
    assert len(external) == 38 and all(not row['external_presentation_resolved'] for row in external)
    closed = sorted(set(previous['cumulative_closed_baseline_clip_ids']) | resolved)
    assert len(closed) == 118 and len(remaining) == 38
    pointer = read(GAME / '.godot/move_external_context/latest.json')
    review = {
        'version': 1, 'report_sha256': sha(path), 'boards_sha256': sha(boards_path),
        'renderer_sha256': report['renderer_sha256'],
        'previous_review_path': str(previous_path.relative_to(GAME)), 'previous_review_sha256': sha(previous_path),
        'baseline_review_sha256': previous['baseline_review_sha256'],
        'resolved_move_ids': sorted(CONTRAST), 'resolved_baseline_clip_ids': sorted(resolved),
        'repaired_baseline_clip_ids': sorted(cid for cid in resolved if cid.split('/')[0] in {'clanging_scales', 'court_change'}),
        'additional_repaired_nonqueued_clip_ids': ['clanging_scales/back'],
        'verified_unchanged_baseline_clip_ids': sorted(cid for cid in resolved if cid.split('/')[0] not in {'clanging_scales', 'court_change'}),
        'cumulative_closed_baseline_clip_ids': closed,
        'pending_baseline_clip_ids': dict(sorted(remaining.items())),
        'pending_ids': {'needs_targeted_review': [], 'requires_external_presentation': sorted(set(MOVES) - CONTRAST)},
        'native_context_reviewed_clip_ids': sorted(remaining),
        'external_handoffs': external,
        'source_proof': {'path': str(source_path.relative_to(GAME)), 'sha256': sha(source_path)},
        'reviews': boards['pages'], 'context_generation': pointer['path'].split('/')[0],
        'mechanics_approved': False, 'realtime_motion_watched': False,
        'notes': [
            'All 24 sources/48 views examined; five contrast IDs close nine queued clips, not ten.',
            'Clanging Scales rear view is also corrected but was not in the unresolved baseline; do not count it twice.',
            'Aeroblast asymmetry and Destiny Bond ellipse belong to their sources and are verified unchanged.',
            'Doom Desire original source verified. Separate DOOMDUMMY candidate identified; its final charge/impact phase assignment and battle binding are not certified here.',
            'Nineteen native source pairs were reviewed; their external gameplay presentation remains unresolved.',
            'Six optional LAB simulations are preserved. They are not evidence of full battle integration.',
            'No new artwork, source export, mechanical support, game-pool change or native Z decision.'
        ]
    }
    output = path.parent / 'review.json'
    output.write_text(json.dumps(review, indent=2) + '\n', encoding='utf-8')
    (path.parent / 'runner_snapshot.gd').write_bytes((GAME / 'tests/visual/move_general_review_runner.gd').read_bytes())
    print('GENERAL_REVIEW_CLOSED 5 IDs / 9 queued clips; 74 IDs / 118 clips closed; 19 external IDs / 38 clips remain')
    print('REVIEW_SHA256', sha(output))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--sheets-observed', action='store_true', required=True)
    close(parser.parse_args().report)
