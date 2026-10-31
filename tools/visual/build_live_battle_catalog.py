"""Index existing reviewed clips for lazy battle loading. Never rebuild source art/data."""
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def build():
    source = ROOT / '.godot/move_batch_catalog/index.json'
    assert sha(source) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    index = json.loads(source.read_text(encoding='utf-8'))
    rows = {}
    for shard in index['shards']:
        path = source.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for n, clip in enumerate(pack['clips']):
            assert clip['id'] not in rows
            rows[clip['id']] = {'path': str(path.relative_to(ROOT)).replace('\\', '/'),
                                'sha256': shard['sha256'], 'index': n, 'frames': len(clip['frames']),
                                'move_id': clip['move_id'], 'side': clip['actor_side'], 'fps': clip['fps']}
    result = {'version': 1, 'scope': 'RESOLVED_EVENTS_ONLY_LAZY_EXISTING_CATALOG',
              'index_sha256': sha(source), 'builder_sha256': sha(Path(__file__)), 'clips': rows,
              'note': 'Registry availability does not certify mechanics. HP resolves at clip completion; original fine impact markers are retained for the earlier audited bindings.'}
    output = ROOT / '.godot/live_battle_catalog'
    output.mkdir(parents=True, exist_ok=True)
    path = output / 'manifest.json'
    path.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print('LIVE_CATALOG', len(rows), 'clips', len({r['move_id'] for r in rows.values()}), 'move IDs; SHA', sha(path))


if __name__ == '__main__':
    build()
