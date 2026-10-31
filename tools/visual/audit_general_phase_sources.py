"""Compare all 48 native clips with inert upstream source data; no export rebuild."""
import argparse
import collections
import hashlib
import json
import sys
from pathlib import Path
from inspect_general_sources import GAME, MOVES
from move_layer_timing import bake_layers


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit(root):
    sys.path.insert(0, str(root))
    from audit_pack_inventory import load_gen9
    names = collections.defaultdict(list)
    for animation in load_gen9():
        if hasattr(animation, 'attrs'):
            names[animation.attrs.get('@name')].append(animation.attrs)
    index_path = GAME / '.godot/move_batch_catalog/index.json'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    proof = []
    for shard in index['shards']:
        if not any(e['move_id'] in MOVES for e in shard['entries']):
            continue
        path = index_path.parent / shard['path']
        assert sha(path) == shard['sha256']
        for clip in json.loads(path.read_text(encoding='utf-8'))['clips']:
            if clip['move_id'] not in MOVES:
                continue
            assert len(names[clip['name']]) == 1, clip['name']
            source = names[clip['name']][0]
            expected_frames = json.loads(json.dumps([list(f[:60]) for f in source['@array']]))
            prior_focus_changes = 0
            if clip['id'] == 'chilly_reception/front':
                expected_sha = '47ca1e982613b1aad620ea0ebe847d9c68a7ac894eff0e4b4626de598bd8cd2d'
                assert hashlib.sha256(json.dumps(source['@array'], separators=(',', ':')).encode()).hexdigest() == expected_sha
                assert clip['camera_repair'] == {
                    'policy': 'pinned_native_particle_slot_anchor_v1', 'source_frames_sha256': expected_sha,
                    'changed_focus_cells': 11, 'original_focus': 2, 'adapted_focus': 1}
                for frame in expected_frames:
                    for cel in frame:
                        if cel and cel[7] == 2 and cel[26] == 2:
                            cel[26] = 1
                            prior_focus_changes += 1
                assert prior_focus_changes == 11
            assert clip['frames'] == expected_frames, clip['id']
            assert clip['layers'] == bake_layers(source.get('@timing', []), len(clip['frames'])), clip['id']
            proof.append({'id': clip['id'], 'source_name': clip['name'],
                          'source_sha256': hashlib.sha256(json.dumps(source, sort_keys=True, separators=(',', ':')).encode()).hexdigest(),
                          'frames': len(clip['frames']), 'graphic': source.get('@graphic', ''),
                          'source_arrays_match_after_documented_adaptation': True,
                          'prior_focus_changes': prior_focus_changes, 'source_layers_match': True})
    assert {r['id'] for r in proof} == {m + '/' + s for m in MOVES for s in ['back', 'front']}
    separate = []
    for name, expected in {
        'Move:DOOMDUMMY': 'b9278b30d79739bbfe8110f31e24228ad53d5e996e00e34accd787d4080c34b2',
        'OppMove:DOOMDUMMY': 'ee71af42646489dc2382aebedd0cbdf14b6423dee94e9d3c7ea6a9c90b31e353',
        'Common:Sandstorm': '25db6fbf3ab3b290bc57cd05d7b022ad9a6b7e20aa9d952d7ee5a5ceae162b03',
    }.items():
        source = names[name][0]
        assert len(names[name]) == 1
        digest = hashlib.sha256(json.dumps(source, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        assert digest == expected
        separate.append({'name': name, 'source_sha256': digest, 'frames': len(source['@array']),
                         'graphic': source.get('@graphic'), 'connected_by_this_audit': False})
    output = GAME / '.godot/move_general_checks/reference/phase_sources.json'
    output.write_text(json.dumps({'version': 1, 'index_sha256': sha(index_path),
        'auditor_sha256': sha(Path(__file__)), 'source_root': str(root), 'clips': proof,
        'separate_resources': separate, 'scope': 'Source verification only; no new resources, exports or mechanics.'}, indent=2) + '\n', encoding='utf-8')
    print('GENERAL_PHASE_SOURCES PASS', len(proof), 'clips;', len(separate), 'separate resources identified;', output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    audit(parser.parse_args().source_root.resolve())
