"""Freeze actual live integration and explicitly list every unavailable move."""
import csv
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    source = ROOT / '.godot/live_integration_checks/gpu.json'
    result = json.loads(source.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    admitted = len(result['admission'][''])
    assert result['registered_clips'] == 1822 and len(result['runtime_samples']) == admitted
    assert len({row['move'] for row in result['runtime_samples']}) == admitted
    assert sum(len(ids) for ids in result['admission'].values()) == 919
    for path, expected in result['source_sha256'].items():
        assert sha(ROOT / path) == expected, path
    for capture in result['captures']:
        assert sha(ROOT / capture['path']) == capture['sha256']
    assert 'SCRIPT ERROR' not in (ROOT / '.godot/substitute_reference/live_gpu.log').read_text(encoding='utf-8-sig')
    definitions = json.loads((ROOT / 'data/normalized/pokemon_api.json').read_text(encoding='utf-8'))['moves']
    pack = ROOT / '.godot/live_battle_catalog/manifest.json'
    assert sha(pack) == result['visual_pack_sha256']
    catalog = json.loads(pack.read_text(encoding='utf-8'))
    unavailable = []
    for reason, ids in result['admission'].items():
        for move in ids:
            if reason:
                unavailable.append({'id': move, 'name': definitions[move].get('display_name', move),
                                    'classification': definitions[move]['classification'], 'reason': reason,
                                    'back_clip': move + '/back' in catalog['clips'], 'front_clip': move + '/front' in catalog['clips']})
    unavailable.sort(key=lambda row: row['id'])
    destination = ROOT / 'docs/current/LIVE_MOVE_UNAVAILABLE.csv'
    with destination.open('w', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=['id', 'name', 'classification', 'reason', 'back_clip', 'front_clip'])
        writer.writeheader()
        writer.writerows(unavailable)
    board = Image.new('RGB', (1280, 5 * 385), '#17231f')
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    names = [name for move in ['absorb', 'swords_dance', 'recover', 'double_team'] for name in [move + '_native', move + '_after']] + ['trainer_choice', 'trainer_resumed']
    for n, name in enumerate(names):
        with Image.open(source.parent / (name + '.png')) as image:
            thumb = ImageOps.contain(image.convert('RGB'), (640, 360), Image.Resampling.LANCZOS)
        x, y = n % 2 * 640, n // 2 * 385
        draw.text((x + 10, y + 2), name, font=font, fill='white')
        board.paste(thumb, (x, y + 25))
    sheet = source.parent / 'contact_sheet.png'
    board.save(sheet)
    output = {k: v for k, v in result.items() if k != 'runtime_samples'}
    output.update({'status': 'LIVE_LOCAL_INTEGRATION_VALIDATED_NOT_ALL_CANONICAL_MECHANICS', 'validation_status': 'PASS',
                   'admitted_move_count': admitted, 'unavailable_move_count': len(unavailable), 'canonical_move_count': 919,
                   'registered_visual_move_count': 900, 'fixture_execution_count': admitted,
                   'admitted_without_default_native_pair': sorted(move for move in result['admission'][''] if any(move + '/' + side not in catalog['clips'] for side in ['back', 'front'])),
                   'not_implemented_or_partial_count': sum(len(ids) for reason, ids in result['admission'].items() if reason.startswith('mechanics_')),
                   'content_excluded_count': len(result['admission'].get('content_excluded', [])),
                   'content_pending_count': len(result['admission'].get('content_pending', [])),
                   'doubles_only_count': len(result['admission'].get('requires_doubles', [])), 'unavailable': unavailable,
                   'unavailable_csv': {'path': str(destination.relative_to(ROOT)), 'sha256': sha(destination)},
                   'contact_sheet': {'path': str(sheet.relative_to(ROOT)), 'sha256': sha(sheet)},
                   'test_report': str(source.relative_to(ROOT)), 'test_report_sha256': sha(source),
                   'limits': ['The admitted moves execute in an isolated fixture without runtime/rejection errors; this is not full competitive interaction certification.',
                              'The registry validates all 1822 clips and first/middle/last frames structurally. Ten new GPU captures are samples, not a new visual review of every clip/species combination.',
                              'Earlier audited fine impact markers retain priority. General catalog HP resolves at clip completion; missing local assets retain the generic visual fallback.',
                              'Ally Switch stays in F12 doubles. The normal game is singles. The 18 special singles mechanics are enabled at ordinary game session creation.',
                              'NPC replacement uses own HP/moves and publicly visible opposing typing; professional root action selection remains the existing trainer intelligence pipeline.',
                              'Original data, source artwork and frozen renderer are unchanged. Native packs remain local cache resources; standalone export/distribution packaging is separate.']})
    (ROOT / 'docs/current/LIVE_MOVE_INTEGRATION.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'LIVE_INTEGRATION_SUMMARY PASS {admitted} usable / {len(unavailable)} unavailable; 900 registered visual IDs; 1822 clips')


if __name__ == '__main__':
    main()
