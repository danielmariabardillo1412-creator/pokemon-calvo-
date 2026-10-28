"""Hash-bound motion diagnostics: canonical slots, old layout, candidate path."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

GAME = Path(__file__).resolve().parents[2]
FRAMES = {'rock_climb': [0, 13, 20, 22, 23, 28], 'storm_throw': [0, 15, 19, 20, 23, 25], 'take_down': [0, 4, 8, 9, 10, 19]}


def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def build(path):
    report = json.loads(path.read_text(encoding='utf-8'))
    assert report['gpu'] and report['failures'] == [] and report['states'] == 800
    for field, source in [('index_sha256', '.godot/move_batch_catalog/index.json'), ('renderer_sha256', 'scenes/visual/community_move_preview.gd'), ('runner_sha256', 'tests/visual/move_motion_path_probe.gd')]:
        assert report[field] == digest(GAME / source)
    clips = {(c['id'], c['mode']): c for c in report['clips']}
    expected = {(m + '/' + s, mode) for m in FRAMES for s in ['back', 'front'] for mode in ['canonical', 'before640', 'candidate640', 'before400', 'candidate400']}
    assert len(clips) == len(report['clips']) and set(clips) == expected
    for c in clips.values():
        assert [f['frame'] for f in c['frames']] == list(range(len(c['frames'])))
        for f in c['frames']:
            if 'path' in f:
                rel = Path(f['path'])
                assert not rel.is_absolute() and '..' not in rel.parts
                assert digest(path.parent / rel) == f['sha256']
                with Image.open(path.parent / rel) as im:
                    assert im.size == tuple(c['arena'])
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    pages = []
    for move, frames in FRAMES.items():
        board = Image.new('RGB', (1536, 64 + 6 * 190), '#111722')
        draw = ImageDraw.Draw(board)
        draw.text((10, 8), move + ' | salidas / reentradas: no forzar todos los cuerpos dentro de pantalla', font=font, fill='white')
        draw.text((10, 31), 'Puestos canonicos con nuestros sprites, NO juego original. Candidato: recorrido del usuario por linea de actores; solo prueba.', font=small, fill='#afc4d6')
        for i, (side, mode) in enumerate((s, m) for s in ['back', 'front'] for m in ['canonical', 'before640', 'candidate640']):
            y = 64 + i * 190
            draw.text((10, y), side + ' / ' + mode, font=font, fill='#ffba60')
            c = clips[move + '/' + side, mode]
            for j, n in enumerate(frames):
                f = c['frames'][n]
                with Image.open(path.parent / f['path']) as im:
                    thumb = ImageOps.contain(im.convert('RGB'), (256, 156), Image.Resampling.LANCZOS)
                board.paste(thumb, (j * 256 + (256 - thumb.width) // 2, y + 22))
                draw.text((j * 256 + 2, y + 176), f'f{n:02d}', font=small, fill='white')
        name = move + '_motion.png'
        board.save(path.parent / name)
        pages.append({'path': name, 'sha256': digest(path.parent / name), 'clip_ids': [move + '/back', move + '/front']})
    boards = {'version': 1, 'report_sha256': digest(path), 'builder_sha256': digest(Path(__file__)), 'pages': pages}
    (path.parent / 'boards.json').write_text(json.dumps(boards, indent=2) + '\n', encoding='utf-8')
    print('MOTION_PATH_SHEETS PASS', len(pages), 'pages', path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
