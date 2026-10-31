"""Record the seven Z phase sheets explicitly reviewed by the operator.

This records a bounded visual decision, never a gameplay/mechanics approval.
"""
import argparse
import hashlib
import json
from pathlib import Path
from inspect_z_sources import GAME, MOVES, BEFORE_SHA


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def close(report_path):
    report = read(report_path)
    assert report['gpu'] and not report['probe'] and report['errors'] == []
    assert report['contract']['states'] == 16320
    assert report['contract']['rejected_changed_exports'] == 14
    assert report['contract']['bounded_leap_frames'] == report['contract']['expected_leap_frames'] == 80
    for field, source in [('index_sha256', '.godot/move_batch_catalog/index.json'),
                          ('renderer_sha256', 'scenes/visual/community_move_preview.gd'),
                          ('runner_sha256', 'tests/visual/move_z_review_runner.gd')]:
        assert report[field] == sha(GAME / source)
    assert sha(GAME / '.godot/move_z_checks/reference/preview_before.gd') == BEFORE_SHA
    baseline = read(GAME / '.godot/move_self_body_checks/reference/baseline.json')
    for path, digest in baseline.items():
        if path != 'head':
            assert sha(GAME / path) == digest, path
    previous_path = GAME / '.godot/move_art_motif_checks/21fa00b2ed6f3953/gpu/review.json'
    assert sha(previous_path) == '9967c418ad6de0b6a3d4905f998beb09139e96fefd7288692614737f570efe96'
    previous = read(previous_path)
    boards_path = report_path.parent / 'boards.json'
    boards = read(boards_path)
    assert boards['report_sha256'] == sha(report_path)
    expected = {m + '/' + side for m in MOVES for side in ['back', 'front']}
    assert {c['source']['id'] for c in report['clips']} == expected
    assert {cid for page in boards['pages'] for cid in page['clip_ids']} == expected
    for page in boards['pages']:
        assert sha(report_path.parent / page['path']) == page['sha256']
    pending = previous['pending_baseline_clip_ids']
    assert expected <= pending.keys()
    closed = set(previous['cumulative_closed_baseline_clip_ids'])
    assert not closed & expected
    closed |= expected
    remaining = {cid: state for cid, state in pending.items() if cid not in expected}
    groups = {kind: sorted(set(ids) - set(MOVES)) for kind, ids in previous['pending_ids'].items()}
    assert len(closed) == 109 and len(remaining) == 47
    assert len(groups['needs_targeted_review']) == 5 and len(groups['requires_external_presentation']) == 19
    prototype_path = GAME / '.godot/move_z_checks/99afa865d23c88ca/gpu/result.json'
    prototype = read(prototype_path)
    old_samples = {(r['id'], tuple(r['arena']), r['frame']): r['captures'] for r in prototype['samples']}
    matches = 0
    for row in report['samples']:
        old = old_samples[row['id'], tuple(row['arena']), row['frame']]
        assert [c['sha256'] for c in row['captures']] == [c['sha256'] for c in old]
        for capture in row['captures']:
            assert sha(report_path.parent / capture['path']) == capture['sha256']
        matches += 1
    assert matches == 280
    art_ids = set(MOVES) - {'guardian_of_alola', 'soul_stealing_7_star_strike'}
    review = {
        'version': 1, 'report_sha256': sha(report_path), 'boards_sha256': sha(boards_path),
        'renderer_sha256': report['renderer_sha256'],
        'previous_review_path': str(previous_path.relative_to(GAME)), 'previous_review_sha256': sha(previous_path),
        'baseline_review_sha256': previous['baseline_review_sha256'],
        'resolved_move_ids': sorted(MOVES), 'resolved_baseline_clip_ids': sorted(expected),
        'art_choice_baseline_clip_ids': sorted(cid for cid in expected if cid.split('/')[0] in art_ids),
        'repaired_baseline_clip_ids': ['soul_stealing_7_star_strike/back', 'soul_stealing_7_star_strike/front'],
        'verified_unchanged_baseline_clip_ids': ['guardian_of_alola/back', 'guardian_of_alola/front'],
        'cumulative_closed_baseline_clip_ids': sorted(closed),
        'pending_baseline_clip_ids': dict(sorted(remaining.items())), 'pending_ids': groups,
        'source_proof': {'path': '.godot/move_z_checks/reference/sources.json', 'sha256': sha(GAME / '.godot/move_z_checks/reference/sources.json')},
        'pinned_exports': [c['source'] for c in report['clips']], 'reviews': boards['pages'],
        'matched_candidate_samples': matches, 'context_generation': '3bcab4075e9a7662',
        'mechanics_approved': False, 'realtime_motion_watched': False,
        'notes': [
            'User explicitly resumed Z visual work; final game inclusion remains undecided.',
            'Five partial artistic choices use the same immutable atlases; no new images or source edits.',
            'Savage Spin Out duplicate-cocoon candidate was rejected; selected version omits fixed Pokemon only.',
            'Soul-Stealing Z fits only the user emergence beyond the receiver; size/fades/timing and particles are unchanged.',
            'Guardian of Alola matches its original fades, including final target alpha225/255. It is verified unchanged, not made fully opaque.',
            'Seven phase sheets observed; all-frame render-state comparisons and geometry checks supplement those static samples.',
            'Not a claim of realtime-motion viewing, new battle routes, final game-pool approval or exact native Z choreography.'
        ]
    }
    output = report_path.parent / 'review.json'
    output.write_text(json.dumps(review, indent=2) + '\n', encoding='utf-8')
    (report_path.parent / 'runner_snapshot.gd').write_bytes((GAME / 'tests/visual/move_z_review_runner.gd').read_bytes())
    print('Z_REVIEW_CLOSED', len(MOVES), 'IDs /', len(expected), 'clips;', len(closed), 'closed clips;', len(remaining), 'pending clips;', output)
    print('REVIEW_SHA256', sha(output))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--phase-sheets-observed', action='store_true', required=True,
                        help='Operator confirms viewing all seven before/after phase sheets.')
    close(parser.parse_args().report)
