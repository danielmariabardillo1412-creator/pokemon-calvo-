"""Contact sheets of two explicit renders, preserving native GPU PNG evidence."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(path):
    report = json.loads(path.read_text(encoding='utf-8'))
    assert report['gpu'] and not report['errors'] and report['states'] >= 852
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)
    small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
    sources = {c['source']['id']: c['source'] for c in report['clips']}
    samples = {}
    for row in report['samples']:
        if row['arena'][0] != 640:
            continue
        for capture in row['captures']:
            assert sha(path.parent / capture['path']) == capture['sha256']
        samples.setdefault(row['id'], []).append(row)
    pages = []
    context_moves = sorted({row['id'].split('/')[0] for row in report['contract'].get('external_handoffs', [])})
    for move in sorted({key.split('/')[0] for key in samples}):
        if move in context_moves:
            continue
        board = Image.new('RGB', (1800, 52 + 4 * 187), '#111722')
        draw = ImageDraw.Draw(board)
        draw.text((10, 8), move + ' | ANTES / ' + ('CANDIDATO' if report['probe'] else 'FINAL'), fill='white', font=font)
        draw.text((10, 30), 'Muestras de todos los tramos. Eleccion visual; no habilita mecanicas ni cambios reales de equipo.', fill='#b5c5da', font=small)
        for row_index, (side, phase) in enumerate((s, p) for s in ['back', 'front'] for p in [0, 1]):
            y = 52 + row_index * 187
            draw.text((8, y), side + (' / ANTES' if phase == 0 else ' / DESPUES'), fill='#ffba60', font=font)
            rows = sorted(samples[move + '/' + side], key=lambda r: r['frame'])
            for col, index in enumerate([0, 2, 4, 5, 7, 9]):
                row = rows[index]
                capture = row['captures'][phase]
                with Image.open(path.parent / capture['path']) as image:
                    thumb = ImageOps.contain(image.convert('RGB'), (300, 153), Image.Resampling.LANCZOS)
                board.paste(thumb, (col * 300, y + 19))
                draw.text((col * 300 + 3, y + 172), 'f%03d / %d' % (row['frame'], sources[row['id']]['frames']), fill='white', font=small)
        name = move + '_before_after.png'
        board.save(path.parent / name)
        pages.append({'path': name, 'sha256': sha(path.parent / name), 'clip_ids': [move + '/back', move + '/front']})
    for side in ['back', 'front']:
        for group_index, start in enumerate(range(0, len(context_moves), 10)):
            group = context_moves[start:start + 10]
            board = Image.new('RGB', (1800, 56 + len(group) * 180), '#111722')
            draw = ImageDraw.Draw(board)
            draw.text((10, 6), 'FUENTES DE CONTEXTO | ' + side + ' | RESULTADO EXTERNO SIGUE PENDIENTE', fill='white', font=font)
            draw.text((10, 28), 'Revisar efecto nativo y salida/estado final. Estos PNG no muestran relevo/clima persistente ni aprueban mecanicas.', fill='#c0d0e0', font=small)
            clip_ids = []
            for row_index, move in enumerate(group):
                clip_id = move + '/' + side
                clip_ids.append(clip_id)
                y = 56 + row_index * 180
                draw.text((8, y), clip_id, fill='#ffba60', font=font)
                rows = sorted(samples[clip_id], key=lambda row: row['frame'])
                for col, index in enumerate([0, 2, 4, 5, 7, 9]):
                    row = rows[index]
                    capture = row['captures'][1]
                    with Image.open(path.parent / capture['path']) as image:
                        thumb = ImageOps.contain(image.convert('RGB'), (300, 146), Image.Resampling.LANCZOS)
                    board.paste(thumb, (col * 300, y + 18))
                    draw.text((col * 300 + 3, y + 164), 'f%03d / %d' % (row['frame'], sources[clip_id]['frames']), fill='white', font=small)
            name = 'context_%s_%02d.png' % (side, group_index + 1)
            board.save(path.parent / name)
            pages.append({'path': name, 'sha256': sha(path.parent / name), 'clip_ids': clip_ids,
                          'scope': 'NATIVE_SOURCE_REVIEW_EXTERNAL_PRESENTATION_UNRESOLVED'})
    (path.parent / 'boards.json').write_text(json.dumps({'version': 1, 'report_sha256': sha(path), 'builder_sha256': sha(Path(__file__)), 'pages': pages}, indent=2) + '\n', encoding='utf-8')
    print('GENERAL_SHEETS PASS', len(pages), 'pages', path.parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    build(parser.parse_args().report)
