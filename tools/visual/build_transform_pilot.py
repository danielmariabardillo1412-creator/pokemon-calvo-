"""Pin the original Transform timeline. It contains body tracks, no particles."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    source = ROOT / '.godot/move_batch_catalog/index.json'
    assert sha(source) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    index = json.loads(source.read_text(encoding='utf-8'))
    clips, proofs = [], []
    for shard in index['shards']:
        if not any(row['move_id'] == 'transform' for row in shard['entries']):
            continue
        path = source.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for clip in pack['clips']:
            if clip['move_id'] != 'transform':
                continue
            assert clip['fps'] == 20 and len(clip['frames']) == 15
            assert clip['reference_animation_id'] == 'TRANSFORM' and clip['classification_unchanged'] == 'UNSUPPORTED'
            assert all(not cell or cell[7] < 0 for frame in clip['frames'] for cell in frame)
            clips.append(clip)
            proofs.append({'id': clip['id'], 'path': str(path.relative_to(ROOT)), 'sha256': sha(path)})
    assert {c['id'] for c in clips} == {'transform/back', 'transform/front'}
    context_path = ROOT / '.godot/move_external_context/e1221ddaae3b2375/context.json'
    context = json.loads(context_path.read_text(encoding='utf-8'))
    assert context['definitions']['transform']['handoff_frame'] == 8
    output = ROOT / '.godot/battle_transform'
    output.mkdir(parents=True, exist_ok=True)
    result = {'version': 1, 'selection': 'transform_v1', 'clips': clips,
              'frames': 15, 'fps': 20, 'handoff_frame': 8, 'native_particle_count': 0,
              'source_clips': proofs, 'context_sha256': sha(context_path),
              'index_sha256': sha(source), 'builder_sha256': sha(Path(__file__)),
              'presentation_adaptation': 'Existing species artwork, brief squeeze/fade around frame 8. No native particle animation claimed.',
              'license_review_required_before_distribution': True}
    path = output / 'manifest.json'
    path.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print('TRANSFORM_PACK PASS 2 body timelines; no particles or PNG changes; SHA', sha(path))


if __name__ == '__main__':
    build()
