"""Hash-bound source-camera / adapted-camera water diagnostic sheets."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]
MOVES = ['hydro_vortex_physical', 'hydro_vortex_special', 'max_geyser', 'sludge_wave', 'surf']
MODES = {'canonical_512': (512, 384), 'adapted_640': (640, 360), 'adapted_400': (400, 300)}


def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def build(path):
    report = json.loads(path.read_text(encoding='utf-8'))
    assert report['gpu'] and report['failures'] == []
    for field, source in [('renderer_sha256', 'scenes/visual/community_move_preview.gd'),
                          ('runner_sha256', 'tests/visual/move_water_layer_probe.gd'),
                          ('index_sha256', '.godot/move_batch_catalog/index.json')]:
        assert report[field] == digest(GAME / source)
    expected = {(m + '/' + s, mode) for m in MOVES for s in ['back', 'front'] for mode in MODES}
    clips = {(c['id'], c['mode']): c for c in report['clips']}
    assert len(clips) == len(report['clips']) and set(clips) == expected
    assert sum(len(c['frames']) for c in clips.values()) == report['frames']
    for clip in clips.values():
        assert [f['frame'] for f in clip['frames']] == list(range(len(clip['frames'])))
        assert len(clip['layers']) == len(clip['frames'])
        for f in clip['frames']:
            if 'path' in f:
                p = Path(f['path'])
                assert not p.is_absolute() and '..' not in p.parts
                assert digest(path.parent / p) == f['sha256']
                with Image.open(path.parent / p) as im:
                    assert im.size == MODES[clip['mode']]
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    pages = []
    for side in ['back', 'front']:
        sheet = Image.new('RGB', (1296, 70 + 5 * 320), '#111722')
        draw = ImageDraw.Draw(sheet)
        draw.text((10, 8), 'AGUA | puestos canonicos / camara adaptada | ' + side, font=font, fill='white')
        draw.text((10, 30), 'Capturas Godot con BG/FG completos. Referencia geometrica; NO juego original ni aprobacion de mecanicas.', font=small, fill='#afc4d6')
        for row, move in enumerate(MOVES):
            key = move + '/' + side
            y = 70 + row * 320
            draw.text((10, y), key, font=font, fill='#ffba60')
            for mode_n, mode in enumerate(['canonical_512', 'adapted_640']):
                clip = clips[key, mode]
                for col, n in enumerate([3, 7, 12, 14, 20, len(clip['frames']) - 1]):
                    f = clip['frames'][n]
                    with Image.open(path.parent / f['path']) as im:
                        thumb = im.convert('RGB').resize((216, 122), Image.Resampling.LANCZOS)
                    x = col * 216
                    sy = y + 22 + mode_n * 146
                    sheet.paste(thumb, (x, sy))
                    draw.text((x + 2, sy + 123), f'{mode} f{n:02d}', font=small, fill='white')
        name = 'water_' + side + '.png'
        sheet.save(path.parent / name)
        pages.append({'path': name, 'sha256': digest(path.parent / name), 'clip_ids': [m + '/' + side for m in MOVES]})
    boards = {'version': 1, 'report_sha256': digest(path), 'builder_sha256': digest(Path(__file__)), 'pages': pages}
    (path.parent / 'boards.json').write_text(json.dumps(boards, indent=2) + '\n', encoding='utf-8')
    print('WATER_SHEETS PASS', len(clips), 'camera clips, 2 pages', path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
