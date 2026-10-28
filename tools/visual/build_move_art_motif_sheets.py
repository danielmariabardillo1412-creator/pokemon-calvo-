"""Verify declared motif choices against previewed candidates and preserve evidence."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

GAME = Path(__file__).resolve().parents[2]
MOVES = ['behemoth_bash', 'catastropika']


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
    assert report['gpu'] and report['failures'] == [] and report['states'] == 2136
    for field, source in [('index_sha256', '.godot/move_batch_catalog/index.json'), ('renderer_sha256', 'scenes/visual/community_move_preview.gd'), ('runner_sha256', 'tests/visual/move_art_motif_test_runner.gd'), ('renderer_before_sha256', '.godot/move_art_motif_checks/reference/preview_before.gd')]:
        assert report[field] == digest(GAME / source)
    probe_path = GAME / '.godot/move_art_motif_checks/8a1434b41c22a68d/result.json'
    probe = read(probe_path)
    assert probe['renderer_sha256'] == report['renderer_before_sha256'] and probe['states'] == 808 and probe['failures'] == []
    assert probe['runner_sha256'] == digest(GAME / 'tests/visual/move_art_motif_probe.gd')
    candidates = {(c['id'], c['arena'][0]): c for c in probe['clips'] if c['candidate']}
    samples = {}
    matches = 0
    for row in report['samples']:
        key = row['id'], row['arena'][0], row['frame']
        assert key not in samples
        samples[key] = row
        for c in row['captures']:
            capture(path.parent, c, row['arena'])
        if not row['art_choice']:
            assert row['captures'][0]['sha256'] == row['captures'][1]['sha256']
        else:
            expected = candidates[row['id'], row['arena'][0]]['frames'][row['frame']]
            assert row['captures'][1]['sha256'] == expected['sha256']
            assert digest(probe_path.parent / expected['path']) == expected['sha256']
            matches += 1
    assert len(samples) == 88 and matches == 64
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    pages = []
    for move in MOVES:
        board = Image.new('RGB', (1536, 64 + 4 * 190), '#111722')
        draw = ImageDraw.Draw(board)
        draw.text((10, 8), move + ' | eleccion artistica PARCIAL | ANTES / DESPUES', font=font, fill='white')
        draw.text((10, 31), 'Sin nuevos dibujos: impacto metalico neutro / fase electrica sin insignia. No cambia mecanicas ni repara la fuente original.', font=small, fill='#afc4d6')
        for i, (side, phase) in enumerate((s, p) for s in ['back', 'front'] for p in [0, 1]):
            y = 64 + i * 190
            draw.text((10, y), side + (' / ANTES' if phase == 0 else ' / DESPUES'), font=font, fill='#ffba60')
            for j, n in enumerate([0, 4, 7, 14, 20, 40]):
                row = samples[move + '/' + side, 640, n]
                im = capture(path.parent, row['captures'][phase], row['arena'])
                thumb = ImageOps.contain(im.convert('RGB'), (256, 156), Image.Resampling.LANCZOS)
                board.paste(thumb, (j * 256, y + 22))
                draw.text((j * 256 + 3, y + 176), f'f{n:02d}', font=small, fill='white')
        name = move + '_before_after.png'
        board.save(path.parent / name)
        pages.append({'path': name, 'sha256': digest(path.parent / name), 'clip_ids': [move + '/back', move + '/front']})
    boards = {'version': 1, 'status': 'PASS', 'report_sha256': digest(path), 'builder_sha256': digest(Path(__file__)), 'probe_sha256': digest(probe_path), 'matched_candidate_samples': matches, 'pages': pages}
    (path.parent / 'boards.json').write_text(json.dumps(boards, indent=2) + '\n', encoding='utf-8')
    print('ART_MOTIF_SHEETS PASS', matches, 'candidate samples;', len(pages), 'pages', path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
