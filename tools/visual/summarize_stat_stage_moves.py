"""Validate evidence for the stat-stage batch and update its current report."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / '.godot/stat_stage_move_checks'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    result = json.loads((FOLDER / 'gpu.json').read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and result['cases'] == 192
    assert len(result['moves']) == 8 and len(result['newly_admitted']) == 6 and len(result['captures']) == 16
    for path, expected in result['source_sha256'].items():
        assert sha(ROOT / path) == expected, path
    for capture in result['captures']:
        assert sha(ROOT / capture['path']) == capture['sha256']
    log = (FOLDER / 'gpu.log').read_text(encoding='utf-8')
    assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log
    frozen = json.loads((ROOT / '.godot/move_self_body_checks/reference/baseline.json').read_text(encoding='utf-8'))
    for path, expected in frozen.items():
        if path != 'head': assert sha(ROOT / path) == expected, path
    assert sha(ROOT / 'scenes/visual/community_move_preview.gd') == '7674d3a61e113e085d12132a4e10461aedd3a760516ab68700f2868f0f3fd4de'
    board = Image.new('RGB', (1600, 1000), '#172d2b')
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 15)
    for i, capture in enumerate(result['captures']):
        path = ROOT / capture['path']
        with Image.open(path) as source:
            thumb = ImageOps.contain(source.convert('RGB'), (400, 225), Image.Resampling.LANCZOS)
        x, y = i % 4 * 400, i // 4 * 250
        draw.text((x + 6, y + 4), path.stem, font=font, fill='white')
        board.paste(thumb, (x, y + 25))
    sheet = FOLDER / 'contact_sheet.png'
    board.save(sheet)
    result.update({
        'status': 'LOCAL_STAT_STAGE_BATCH_VALIDATED',
        'corrected_existing_admitted': ['clear_smog', 'spectral_thief'],
        'scope': 'Live singles stage clear/swap/inversion/random boost and before-damage theft; frozen DATA V3 unchanged',
        'validation_report': '.godot/stat_stage_move_checks/gpu.json',
        'reference_urls': ['https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts',
                           'https://github.com/smogon/pokemon-showdown/blob/master/sim/battle-actions.ts'],
        'contact_sheet': {'path': str(sheet.relative_to(ROOT)), 'sha256': sha(sheet)},
        'limits': [
            'The normal game remains singles. Acupressure selects the user; ally targeting belongs to a future doubles implementation.',
            'Direct stage assignments are separate events and do not pretend to be ordinary boost/drop triggers.',
            'Simple/Contrary are handled for receiving these specific boosts, not certified as complete abilities across the engine.',
            'Topsy-Turvy handles substitute, Infiltrator and one Magic Bounce reflection; general ability suppression, Mold Breaker and future protection mechanics remain outside this batch.',
            'Spectral Thief contact uses the existing retaliation framework; its previously documented defender-KO limitations are unchanged.',
            'Psych Up and stored-stat swaps are deferred; they require their separate critical-state or temporary-stat contracts.',
            'No new artwork, canonical data edits, source PNG edits, export or GitHub publication.',
        ],
    })
    live = json.loads((ROOT / 'docs/current/LIVE_MOVE_INTEGRATION.json').read_text(encoding='utf-8'))
    result['admitted_move_count_at_validation'] = live['admitted_move_count']
    result['remaining_mechanics_count_at_validation'] = live['not_implemented_or_partial_count']
    path = ROOT / 'docs/current/STAT_STAGE_MOVES.json'
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'STAT_STAGE_SUMMARY PASS {result["checks"]} checks; 192 cases; 6 newly admitted; 2 corrected; 16 captures')


if __name__ == '__main__':
    main()
