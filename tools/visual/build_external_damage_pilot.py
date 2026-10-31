"""Copy ten reviewed clips for confirmed-damage presentation, not special effects."""
import hashlib
import json
import shutil
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
PROFILES = {
    'circle_throw': {'frames': 19, 'impact_frame': 2, 'hp_end_frame': 10, 'reference': 'CIRCLETHROW', 'classification': 'RUNTIME_SUPPORTED', 'type_id': 'fighting', 'category': 'physical', 'power': 60},
    'dragon_tail': {'frames': 20, 'impact_frame': 7, 'hp_end_frame': 15, 'reference': 'DRAGONTAIL', 'classification': 'RUNTIME_SUPPORTED', 'type_id': 'dragon', 'category': 'physical', 'power': 60},
    'flip_turn': {'frames': 30, 'impact_frame': 12, 'hp_end_frame': 20, 'reference': 'FLIPTURN', 'classification': 'PARTIAL_RUNTIME', 'type_id': 'water', 'category': 'physical', 'power': 60},
    'u_turn': {'frames': 28, 'impact_frame': 14, 'hp_end_frame': 22, 'reference': 'UTURN', 'classification': 'RUNTIME_SUPPORTED', 'type_id': 'bug', 'category': 'physical', 'power': 70},
    'volt_switch': {'frames': 26, 'impact_frame': 18, 'hp_end_frame': 24, 'reference': 'VOLTSWITCH', 'classification': 'RUNTIME_SUPPORTED', 'type_id': 'electric', 'category': 'special', 'power': 70},
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    index_path = GAME / '.godot/move_batch_catalog/index.json'
    assert sha(index_path) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    output = GAME / '.godot/battle_external_damage'
    output.mkdir(parents=True, exist_ok=True)
    clips, sheets, proofs = [], {}, []
    for shard in index['shards']:
        if not any(e['move_id'] in PROFILES for e in shard['entries']):
            continue
        path = index_path.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for clip in pack['clips']:
            if clip['move_id'] not in PROFILES:
                continue
            profile = PROFILES[clip['move_id']]
            assert len(clip['frames']) == profile['frames'] and clip['fps'] == 20
            assert clip['classification_unchanged'] == profile['classification']
            assert any(c and c[7] >= 0 and c[6] == 1 and c[8] > 0 for c in clip['frames'][profile['impact_frame']]), clip['id']
            clips.append(clip)
            proofs.append({'id': clip['id'], 'source_path': str(path.relative_to(GAME)), 'sha256': shard['sha256']})
            for key in {clip['sheet'], *clip['layer_sheets'].values()} - {''}:
                assert sha(path.parent / key) + '.png' == key
                sheets[key] = pack['sheets'][key]
                shutil.copyfile(path.parent / key, output / key)
    assert {c['id'] for c in clips} == {m + '/' + s for m in PROFILES for s in ['back', 'front']}
    manifest = {'version': 1, 'selection': 'battle_external_damage_v1', 'scope': 'CONFIRMED_DAMAGE_ONLY_NO_PIVOT_OR_PHAZE',
                'fps': 20, 'clips': clips, 'sheets': dict(sorted(sheets.items())), 'profiles': PROFILES,
                'index_sha256': sha(index_path), 'source_clips': proofs, 'builder_sha256': sha(Path(__file__)),
                'license_review_required_before_distribution': True}
    path = output / 'manifest.json'
    path.write_text(json.dumps(manifest, separators=(',', ':'), ensure_ascii=False) + '\n', encoding='utf-8')
    print('EXTERNAL_DAMAGE_PACK PASS 10 clips;', sum((output / k).stat().st_size for k in sheets), 'PNG bytes; manifest SHA', sha(path))


if __name__ == '__main__':
    build()
