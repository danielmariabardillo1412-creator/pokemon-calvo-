"""Validate independent cropped-tile GPU oracles and build local-effect sheets."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[2]
FOCAL = {'acupressure': 8, 'aromatic_mist': 20, 'entrainment': 29, 'flatter': 12}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_capture(folder, capture, size):
    rel = Path(capture['path'])
    assert not rel.is_absolute() and '..' not in rel.parts
    assert digest(folder / rel) == capture['sha256']
    with Image.open(folder / rel) as im:
        assert im.size == size
        return im.convert('RGBA')


def build(path):
    report = json.loads(path.read_text(encoding='utf-8'))
    assert report['gpu'] and report['failures'] == [] and report['states'] == 1800
    for key, rel in [('index_sha256', '.godot/move_batch_catalog/index.json'),
                     ('renderer_sha256', 'scenes/visual/community_move_preview.gd'),
                     ('runner_sha256', 'tests/visual/move_local_effect_test_runner.gd'),
                     ('renderer_before_sha256', '.godot/move_local_effect_checks/reference/preview_before.gd')]:
        assert report[key] == digest(GAME / rel)
    samples = {}
    for row in report['samples']:
        key = row['id'], row['arena'][0], row['frame']
        assert key not in samples
        samples[key] = row
        for capture in row['captures']:
            verify_capture(path.parent, capture, tuple(row['arena']))
        if not row['corrected']:
            assert row['captures'][0]['sha256'] == row['captures'][1]['sha256']
    expected = {('flatter/' + side, width, f) for side in ['back', 'front'] for width in [640, 400] for f in range(24)}
    keys = set()
    worst_error = 0
    for row in report['oracles']:
        key = row['id'], row['arena'][0], row['frame']
        assert key not in keys
        keys.add(key)
        actual = verify_capture(path.parent, row['actual'], tuple(row['arena']))
        oracle = verify_capture(path.parent, row['oracle'], tuple(row['arena']))
        error = max(maximum for minimum, maximum in ImageChops.difference(actual, oracle).getextrema())
        assert error <= 2, (key, error)
        worst_error = max(worst_error, error)
    assert keys == expected and report['old_clipped_states'] > 0 and report['new_clipped_states'] == 0
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    board = Image.new('RGB', (1280, 80 + 4 * 215), '#111722')
    draw = ImageDraw.Draw(board)
    draw.text((10, 8), 'EFECTOS LOCALES | antes / despues | 3 IDs corregidos, 1 verificado sin cambio', font=font, fill='white')
    draw.text((10, 30), 'Acupresion: referencia sobre uno mismo. Danza Amiga: descenso acotado. Camelo: aislamiento del atlas. Sin mecanicas nuevas.', font=small, fill='#afc4d6')
    for j, label in enumerate(['back ANTES', 'back DESPUES', 'front ANTES', 'front DESPUES']):
        draw.text((j * 320 + 10, 57), label, font=font, fill='white')
    for i, (move, f) in enumerate(FOCAL.items()):
        y = 80 + i * 215
        draw.text((10, y), move + f' | f{f:02d}', font=font, fill='#ffba60')
        for j, (side, phase) in enumerate([('back', 0), ('back', 1), ('front', 0), ('front', 1)]):
            row = samples[move + '/' + side, 640, f]
            with Image.open(path.parent / row['captures'][phase]['path']) as im:
                board.paste(im.convert('RGB').resize((320, 180), Image.Resampling.LANCZOS), (j * 320, y + 25))
    name = 'local_effects_before_after.png'
    board.save(path.parent / name)
    result = {'version': 1, 'status': 'PASS', 'report_sha256': digest(path), 'builder_sha256': digest(Path(__file__)),
              'oracle_pairs': len(keys), 'max_channel_error': worst_error, 'allowed_channel_error': 2,
              'pages': [{'path': name, 'sha256': digest(path.parent / name), 'move_ids': list(FOCAL)}],
              'scope': 'All cropped-tile GPU frames checked at two arenas; observed sheets still require explicit review.'}
    (path.parent / 'boards.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('LOCAL_EFFECT_PIXEL_GATE PASS', len(keys), 'oracle pairs; max channel error', worst_error, path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
