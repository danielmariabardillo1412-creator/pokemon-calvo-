"""Copy four reviewed native casts and the original doll. No catalog regeneration."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    source = ROOT / '.godot/move_batch_catalog/index.json'
    assert sha(source) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    index = json.loads(source.read_text(encoding='utf-8'))
    output = ROOT / '.godot/battle_substitute'
    output.mkdir(parents=True, exist_ok=True)
    clips, sheets, proofs, profiles = [], {}, [], {}
    for shard in index['shards']:
        if not any(row['move_id'] in ['substitute', 'shed_tail'] for row in shard['entries']):
            continue
        path = source.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for clip in pack['clips']:
            if clip['move_id'] not in ['substitute', 'shed_tail']:
                continue
            assert clip['fps'] == 20 and clip['classification_unchanged'] == 'DATA_ONLY'
            assert len(clip['frames']) == (14 if clip['move_id'] == 'substitute' else 20)
            cue = next(i for i, frame in enumerate(clip['frames']) if any(c and c[7] >= 0 and c[6] == 1 and c[8] > 0 for c in frame))
            profiles[clip['id']] = {'frames': len(clip['frames']), 'cue': cue, 'reference': clip['reference_animation_id']}
            clips.append(clip)
            proofs.append({'path': str(path.relative_to(ROOT)), 'sha256': sha(path), 'id': clip['id']})
            for key in {clip['sheet'], *clip['layer_sheets'].values()} - {''}:
                assert sha(path.parent / key) + '.png' == key
                shutil.copyfile(path.parent / key, output / key)
                sheets[key] = pack['sheets'][key]
    assert len(clips) == 4 and len(profiles) == 4
    context_path = ROOT / '.godot/move_external_context/e1221ddaae3b2375/context.json'
    context = json.loads(context_path.read_text(encoding='utf-8'))
    doll_name = context['doll_sheet']
    assert doll_name == 'e4cb8b5708589c81ce97fb5c9be30dbf60477f5437c0c17554abbded3a8ed093.png'
    doll = context_path.parent / doll_name
    assert sha(doll) + '.png' == doll_name
    shutil.copyfile(doll, output / 'doll.png')
    result = {'version': 1, 'selection': 'substitute_v1', 'clips': clips,
              'sheets': dict(sorted(sheets.items())), 'profiles': profiles,
              'doll_sha256': sha(doll), 'doll_bounds': context['doll_bounds'],
              'source_clips': proofs, 'index_sha256': sha(source),
              'builder_sha256': sha(Path(__file__)), 'license_review_required_before_distribution': True}
    manifest = output / 'manifest.json'
    manifest.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print('SUBSTITUTE_PACK PASS 4 native clips; SHA', sha(manifest))


if __name__ == '__main__':
    build()
