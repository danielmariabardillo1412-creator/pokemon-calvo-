"""Pin the body-only source timelines; never rebuild the frozen catalog."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    source = ROOT / '.godot/move_batch_catalog/index.json'
    assert sha(source) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    clips, proofs = [], []
    for shard in json.loads(source.read_text(encoding='utf-8'))['shards']:
        if not any(row['move_id'] == 'ally_switch' for row in shard['entries']):
            continue
        path = source.parent / shard['path']
        assert sha(path) == shard['sha256']
        for clip in json.loads(path.read_text(encoding='utf-8'))['clips']:
            if clip['move_id'] == 'ally_switch':
                clips.append(clip)
                proofs.append({'path': str(path.relative_to(ROOT)), 'sha256': sha(path), 'id': clip['id']})
    assert {c['id'] for c in clips} == {'ally_switch/back', 'ally_switch/front'}
    assert all(len(c['frames']) == 15 and c['fps'] == 20 and c['classification_unchanged'] == 'DATA_ONLY' for c in clips)
    assert all(not cell or cell[7] < 0 for clip in clips for frame in clip['frames'] for cell in frame)
    curves = {c['actor_side']: [frame[0][8] / 255 for frame in c['frames']] for c in clips}
    output = ROOT / '.godot/battle_ally_switch'
    output.mkdir(parents=True, exist_ok=True)
    result = {'version': 1, 'selection': 'ally_switch_positions_v1', 'clips': clips,
              'fade_curves': curves, 'source_clips': proofs, 'index_sha256': sha(source),
              'adaptation': 'Four actual active slots. Mirror the original 15-frame body fade around a real confirmed swap; no native particles or new artwork.',
              'license_review_required_before_distribution': True}
    path = output / 'manifest.json'
    path.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print('ALLY_SWITCH_TIMELINE_PASS', sha(path))


if __name__ == '__main__':
    build()
