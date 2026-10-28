"""Freeze renderer and inspect immutable artwork for the seven queued Z IDs."""
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]
MOVES = ['extreme_evoboost', 'genesis_supernova', 'guardian_of_alola',
         'lets_snuggle_forever', 'savage_spin_out_physical',
         'savage_spin_out_special', 'soul_stealing_7_star_strike']
BEFORE_SHA = 'a9e655948ae20b50b2f2d8ee34b906f3729db6e29d0bb7b9a45b1a704aca9ce2'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run():
    folder = GAME / '.godot/move_z_checks/reference'
    folder.mkdir(parents=True, exist_ok=True)
    before = folder / 'preview_before.gd'
    source = GAME / 'scenes/visual/community_move_preview.gd'
    if not before.exists():
        assert sha(source) == BEFORE_SHA, 'unexpected starting renderer'
        before.write_bytes(source.read_bytes())
    assert sha(before) == BEFORE_SHA
    index_path = GAME / '.godot/move_batch_catalog/index.json'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    rows = []
    seen = set()
    for shard in index['shards']:
        if not any(e['move_id'] in MOVES for e in shard['entries']):
            continue
        path = index_path.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for clip in pack['clips']:
            if clip['move_id'] not in MOVES:
                continue
            patterns = sorted({int(c[7]) for f in clip['frames'] for c in f
                               if c and c[7] >= 0 and c[6] == 1 and c[8] > 0})
            sheet = path.parent / clip['sheet']
            assert sha(sheet) + '.png' == clip['sheet']
            layers = sorted({v for v in clip['layer_sheets'].values()})
            rows.append({'id': clip['id'], 'name': clip['name'], 'frames': len(clip['frames']),
                         'patterns': patterns, 'sheet': str(sheet.relative_to(GAME)),
                         'layers': layers, 'opponent_export': clip['opponent_export'],
                         'mapped_opponent': clip['mapped_opponent'],
                         'target': clip['target_scope'], 'shard_sha256': shard['sha256']})
            atlas_key = (clip['sheet'], tuple(patterns))
            if atlas_key in seen:
                continue
            seen.add(atlas_key)
            with Image.open(sheet) as im:
                im = im.convert('RGBA')
                board = Image.new('RGB', (8 * 145, 50 + math.ceil(len(patterns) / 8) * 160), '#263343')
                draw = ImageDraw.Draw(board)
                font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 15)
                draw.text((8, 8), clip['move_id'] + ' | source patterns, no changes', fill='white', font=font)
                for n, pattern in enumerate(patterns):
                    x, y = (pattern % 5) * 192, (pattern // 5) * 192
                    tile = im.crop((x, y, x + 192, y + 192))
                    tile.thumbnail((140, 140))
                    bx, by = (n % 8) * 145, 50 + (n // 8) * 160
                    board.paste(tile, (bx, by), tile)
                    draw.text((bx + 4, by + 140), str(pattern), fill='white', font=font)
                suffix = '_front_source.png' if clip['actor_side'] == 'front' else '_source.png'
                board.save(folder / (clip['move_id'] + suffix))
    assert {r['id'] for r in rows} == {m + '/' + s for m in MOVES for s in ['back', 'front']}
    report = {'version': 1, 'index_sha256': sha(index_path), 'renderer_before_sha256': BEFORE_SHA, 'clips': rows}
    (folder / 'sources.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    for row in rows:
        print(json.dumps(row))


if __name__ == '__main__':
    run()
