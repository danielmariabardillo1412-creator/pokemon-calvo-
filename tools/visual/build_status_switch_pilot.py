"""Copy ten already-reviewed status clips; never rebuild the dataset/catalog."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILES = {
    'roar': {'frames': 21, 'cue': 5, 'reference': 'ROAR', 'type_id': 'normal', 'target': 'selected-pokemon'},
    'whirlwind': {'frames': 26, 'cue': 1, 'reference': 'GUST', 'type_id': 'normal', 'target': 'selected-pokemon'},
    'teleport': {'frames': 21, 'cue': 6, 'reference': 'TELEPORT', 'type_id': 'psychic', 'target': 'user'},
    'baton_pass': {'frames': 31, 'front_frames': 35, 'cue': 0, 'reference': 'BATONPASS', 'type_id': 'normal', 'target': 'user'},
    'parting_shot': {'frames': 26, 'cue': 2, 'reference': 'PARTINGSHOT', 'type_id': 'dark', 'target': 'selected-pokemon'},
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    index_path = ROOT / '.godot/move_batch_catalog/index.json'
    assert sha(index_path) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    output = ROOT / '.godot/battle_status_switch'
    output.mkdir(parents=True, exist_ok=True)
    clips, sheets, proofs = [], {}, []
    for shard in index['shards']:
        if not any(row['move_id'] in PROFILES for row in shard['entries']):
            continue
        path = index_path.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for clip in pack['clips']:
            if clip['move_id'] not in PROFILES:
                continue
            profile = PROFILES[clip['move_id']]
            frames = profile.get('front_frames', profile['frames']) if clip['actor_side'] == 'front' else profile['frames']
            assert len(clip['frames']) == frames and clip['fps'] == 20
            assert clip['classification_unchanged'] == 'DATA_ONLY' and clip['reference_animation_id'] == profile['reference']
            assert any(c and c[7] >= 0 and c[6] == 1 and c[8] > 0 for c in clip['frames'][profile['cue']])
            clips.append(clip)
            proofs.append({'id': clip['id'], 'source_path': str(path.relative_to(ROOT)), 'sha256': sha(path)})
            for key in {clip['sheet'], *clip['layer_sheets'].values()} - {''}:
                assert sha(path.parent / key) + '.png' == key
                shutil.copyfile(path.parent / key, output / key)
                sheets[key] = pack['sheets'][key]
    assert {c['id'] for c in clips} == {move + '/' + side for move in PROFILES for side in ['back', 'front']}
    result = {'version': 1, 'selection': 'status_switch_v1', 'scope': 'EXPLICIT_SINGLES_CONFIRMED_STATUS_ONLY',
              'clips': clips, 'sheets': dict(sorted(sheets.items())), 'profiles': PROFILES,
              'source_clips': proofs, 'index_sha256': sha(index_path), 'builder_sha256': sha(Path(__file__)),
              'license_review_required_before_distribution': True}
    manifest = output / 'manifest.json'
    manifest.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print('STATUS_SWITCH_PACK PASS 10 clips;', sum((output / key).stat().st_size for key in sheets), 'PNG bytes; SHA', sha(manifest))


if __name__ == '__main__':
    build()
