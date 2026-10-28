"""Validate motion GPU captures and completely transparent wrap endpoints."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

GAME = Path(__file__).resolve().parents[2]
FRAMES = {'rock_climb': [0, 13, 20, 22, 23, 28], 'take_down': [0, 4, 8, 9, 10, 19], 'storm_throw': [0, 15, 19, 20, 23, 25]}


def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def read(p):
    return json.loads(p.read_text(encoding='utf-8'))


def capture(folder, c, arena):
    rel = Path(c['path'])
    assert not rel.is_absolute() and '..' not in rel.parts
    assert digest(folder / rel) == c['sha256']
    with Image.open(folder / rel) as im:
        assert im.size == tuple(arena)
        return im.convert('RGBA')


def build(path):
    report = read(path)
    assert report['gpu'] and report['failures'] == [] and report['states'] == 1600
    for key, file in [('index_sha256', '.godot/move_batch_catalog/index.json'), ('renderer_sha256', 'scenes/visual/community_move_preview.gd'), ('runner_sha256', 'tests/visual/move_motion_path_test_runner.gd'), ('renderer_before_sha256', '.godot/move_motion_path_checks/reference/preview_before.gd')]:
        assert report[key] == digest(GAME / file)
    samples = {}
    for row in report['samples']:
        key = row['id'], row['arena'][0], row['frame']
        assert key not in samples
        samples[key] = row
        for c in row['captures']:
            capture(path.parent, c, row['arena'])
        if not row['corrected']:
            assert row['captures'][0]['sha256'] == row['captures'][1]['sha256']
    assert len(samples) == 88
    endpoints = set()
    for row in report['endpoint_captures']:
        key = row['id'], tuple(row['pair']), tuple(row['arena']), row['frame']
        assert key not in endpoints
        endpoints.add(key)
        im = capture(path.parent, row, row['arena'])
        assert im.getchannel('A').getextrema() == (0, 0)
    assert len(endpoints) == report['hidden_wrap_endpoints'] == 80
    assert report['new_default_wrap_visible'] == 0 and report['old_default_wrap_visible'] > 0
    probe_path = GAME / '.godot/move_motion_path_checks/adc95fa7a8cd1694/result.json'
    probe = read(probe_path)
    assert probe['renderer_sha256'] == report['renderer_before_sha256']
    probe_rows = {(c['id'], c['mode']): c for c in probe['clips']}
    matched = 0
    for row in report['samples']:
        mode = 'candidate' + str(row['arena'][0])
        f = probe_rows[row['id'], mode]['frames'][row['frame']]
        if 'sha256' in f:
            assert row['captures'][1]['sha256'] == f['sha256']
            matched += 1
    assert matched == 84
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    pages = []
    for move, frames in FRAMES.items():
        board = Image.new('RGB', (1536, 66 + 4 * 190), '#111722')
        draw = ImageDraw.Draw(board)
        draw.text((10, 8), move + ' | ANTES / DESPUES | salida y reentrada conservadas', font=font, fill='white')
        draw.text((10, 31), 'Recorrido por linea de actores y fundido del cambio de borde. Storm Throw sin cambios. No se obliga a quedarse dentro.', font=small, fill='#afc4d6')
        for i, (side, phase) in enumerate((s, p) for s in ['back', 'front'] for p in [0, 1]):
            y = 66 + i * 190
            draw.text((10, y), side + (' / ANTES' if phase == 0 else ' / DESPUES'), font=font, fill='#ffba60')
            for j, n in enumerate(frames):
                row = samples[move + '/' + side, 640, n]
                im = capture(path.parent, row['captures'][phase], row['arena'])
                thumb = ImageOps.contain(im.convert('RGB'), (256, 156), Image.Resampling.LANCZOS)
                board.paste(thumb, (j * 256, y + 22))
                draw.text((j * 256 + 2, y + 176), f'f{n:02d}', font=small, fill='white')
        name = move + '_before_after.png'
        board.save(path.parent / name)
        pages.append({'path': name, 'sha256': digest(path.parent / name), 'clip_ids': [move + '/back', move + '/front']})
    result = {'version': 1, 'status': 'PASS', 'report_sha256': digest(path), 'builder_sha256': digest(Path(__file__)), 'source_probe_sha256': digest(probe_path), 'matched_candidate_samples': matched, 'transparent_gpu_endpoints': len(endpoints), 'pages': pages}
    (path.parent / 'boards.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('MOTION_REPAIR_SHEETS PASS', matched, 'candidate matches;', len(endpoints), 'transparent endpoints;', len(pages), 'pages', path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
