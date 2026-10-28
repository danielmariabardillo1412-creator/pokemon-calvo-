"""Pinned before/after GPU water comparisons, with screenshot integrity checks."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]
MOVES = ['hydro_vortex_physical', 'hydro_vortex_special', 'max_geyser', 'sludge_wave', 'surf']


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(path):
    report = json.loads(path.read_text(encoding='utf-8'))
    assert report['gpu'] and report['failures'] == [] and report['clips'] == 10
    assert report['renderer_sha256'] == digest(GAME / 'scenes/visual/community_move_preview.gd')
    assert report['runner_sha256'] == digest(GAME / 'tests/visual/move_water_layer_test_runner.gd')
    assert report['index_sha256'] == digest(GAME / '.godot/move_batch_catalog/index.json')
    assert report['renderer_before_sha256'] == digest(GAME / '.godot/move_water_checks/reference/preview_before.gd')
    samples = {}
    for row in report['samples']:
        key = row['id'], row['frame']
        assert key not in samples
        samples[key] = row
        for name, sha in zip(row['paths'], row['pixels_sha256'], strict=True):
            rel = Path(name)
            assert not rel.is_absolute() and '..' not in rel.parts
            with Image.open(path.parent / rel) as im:
                assert im.size == (640, 360)
                assert hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest() == sha
        if not row['corrected']:
            assert row['pixels_sha256'][0] == row['pixels_sha256'][1]
    assert len(samples) == 90
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    board = Image.new('RGB', (1280, 70 + 5 * 330), '#111722')
    draw = ImageDraw.Draw(board)
    draw.text((10, 8), 'AGUA RIVAL | ANTES / DESPUES | 3 correcciones, 2 controles sin cambios', font=font, fill='white')
    draw.text((10, 32), 'Solo se oculta la franja secundaria de HYDROVORTEX. Cresta, cuerpos, particulas, tiempos y fuentes intactos.', font=small, fill='#afc4d6')
    for i, move in enumerate(MOVES):
        y = 70 + i * 330
        draw.text((10, y), move + '/front', font=font, fill='#ffba60')
        for phase in [0, 1]:
            for col, frame in enumerate([3, 7, 12, 14, 20]):
                row = samples[move + '/front', frame]
                with Image.open(path.parent / row['paths'][phase]) as im:
                    board.paste(im.convert('RGB').resize((256, 144), Image.Resampling.LANCZOS), (col * 256, y + 22 + phase * 154))
                draw.text((col * 256 + 3, y + 22 + phase * 154), ('ANTES ' if phase == 0 else 'DESPUES ') + f'f{frame:02d}', font=small, fill='white')
    board.save(path.parent / 'water_before_after.png')
    boards = {'version': 1, 'report_sha256': digest(path), 'builder_sha256': digest(Path(__file__)),
              'pages': [{'path': 'water_before_after.png', 'sha256': digest(path.parent / 'water_before_after.png'), 'clip_ids': [m + '/front' for m in MOVES]}]}
    (path.parent / 'boards.json').write_text(json.dumps(boards, indent=2) + '\n', encoding='utf-8')
    print('WATER_REPAIR_SHEETS PASS', len(samples), 'paired samples', path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
