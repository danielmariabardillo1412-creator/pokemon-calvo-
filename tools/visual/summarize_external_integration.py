"""Freeze an honest capability report from the actual 19-move engine audit."""
import hashlib
import json
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

GAME = Path(__file__).resolve().parents[2]
ROOT = GAME / '.godot/battle_external_integration'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def summarize_ally_switch_pilot():
    path = GAME / '.godot/ally_switch_checks/gpu.json'
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    assert len(result['core_samples']) == 48 and len(result['captures']) == 16
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    for capture in result['captures']:
        assert sha(GAME / capture['path']) == capture['sha256']
    assert sha(GAME / '.godot/battle_ally_switch/manifest.json') == result['pack_sha256']
    assert 'SCRIPT ERROR' not in (GAME / '.godot/substitute_reference/ally_gpu.log').read_text(encoding='utf-8-sig')
    output = dict(result)
    output.pop('core_samples')
    output['status'] = 'DOUBLES_POSITION_PILOT_VALIDATED_NOT_COMPLETE_DOUBLES_ENGINE'
    output['validation_status'] = 'PASS'
    output['server_sample_count'] = 48
    output['test_report'] = str(path.relative_to(GAME))
    output['test_report_sha256'] = sha(path)
    output['mechanics_added'] = ['ally_switch']
    output['remaining_unimplemented_in_original_19_pilots'] = []
    output['production_rollout_complete'] = False
    output['enabled_scope'] = 'F12 isolated four-participant adapter inside the existing field demo, no main party mutation or rollout to trainer AI.'
    output['notes'] = [
        'Target creature IDs are validated and bound to their selected positions before ordering; a swap changes the occupant subsequently hit.',
        'Original identity, HP, PP, status, stages and party order stay on the creature. It is not a reserve switch and emits no SWITCHED event.',
        'Priority +2; repeat attempts use 1/3, 1/9 ... 1/729, reset on failure and expire after an intervening turn. Snapshot and packet permutation preserve RNG/results.',
        'Two sides, either initial slot, 12 seeds; additional repeat/tie/KO/unsupported-scope/terminal tests. UI replays do not change the authoritative snapshot.',
        'Original 15-frame/20-fps body-only fades are mirrored around a real position swap. Four-body camera, motion and generic diagnostic hit effects are recorded adaptations; original PNGs/catalog/renderer are unchanged.',
        'Singles APIs explicitly reject four-active-actor commands instead of forwarding them to the historical two-action resolver.'
    ]
    sheets = []
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    for kind, suffixes in [('positions', ['before', 'after']), ('motion', ['swap', 'redirected_hit'])]:
        board = Image.new('RGB', (1280, 4 * 385), '#17231f')
        draw = ImageDraw.Draw(board)
        for row, (side, slot) in enumerate([(side, slot) for side in ['side_a', 'side_b'] for slot in [0, 1]]):
            for column, suffix in enumerate(suffixes):
                name = f'{side}_{slot}_{suffix}.png'
                with Image.open(path.parent / name) as image:
                    thumb = ImageOps.contain(image.convert('RGB'), (640, 360), Image.Resampling.LANCZOS)
                x, y = column * 640, row * 385
                draw.text((x + 10, y + 2), name, font=font, fill='white')
                board.paste(thumb, (x, y + 25))
        sheet = path.parent / (kind + '_contact_sheet.png')
        board.save(sheet)
        sheets.append({'path': str(sheet.relative_to(GAME)), 'sha256': sha(sheet)})
    output['contact_sheets'] = sheets
    (GAME / 'docs/current/ALLY_SWITCH_PILOT.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


def summarize_transform_pilot():
    path = GAME / '.godot/transform_checks/gpu.json'
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    assert len(result['core_samples']) == 72 and len(result['captures']) == 12
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    for capture in result['captures']:
        assert sha(GAME / capture['path']) == capture['sha256']
    assert sha(GAME / '.godot/battle_transform/manifest.json') == result['pack_sha256']
    log = GAME / '.godot/substitute_reference/transform_gpu.log'
    assert 'SCRIPT ERROR' not in log.read_text(encoding='utf-8-sig')
    output = dict(result)
    output.pop('core_samples')
    output['status'] = 'SINGLES_TRANSFORM_PILOT_VALIDATED_NOT_GLOBAL_ROLLOUT'
    output['validation_status'] = 'PASS'
    output['server_sample_count'] = 72
    output['test_report'] = str(path.relative_to(GAME))
    output['test_report_sha256'] = sha(path)
    output['mechanics_added'] = ['transform']
    output['remaining_unimplemented'] = ['ally_switch']
    output['production_rollout_complete'] = False
    output['notes'] = [
        'F11 cycles Ditto against Wailord, Pikachu and Charizard, with the previous switch/weather/substitute pilots enabled only in this disposable preset.',
        'Copies current species/static typing, non-HP stats, stages, represented crit volatile, ability and moves. Copied PP are min(5, base PP), independent of target current PP.',
        'Keeps own current/max HP, level, instance ID, progression, item and persistent status. Original move PP after paying Transform are restored on leaving.',
        'Restore covers switch, KO, terminal battle, forced escape, session capture/run cleanup and post-battle reconciliation. Capture probability and XP identity use original species.',
        'Three front-side projections and three real player encounters are captured. Actual wild-opponent Transform followed by capture and player Transform followed by run are also tested.',
        'Source classification UNSUPPORTED and source artwork remain unchanged. There are no native particle cells in the original two clips; the appearance transition is an explicitly recorded adaptation.'
    ]
    names = [f'{species}_{suffix}' for species in ['wailord', 'pikachu', 'charizard']
             for suffix in ['transition', 'back_copied', 'front_copied', 'restored']]
    board = Image.new('RGB', (1280, 6 * 385), '#17231f')
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    for n, name in enumerate(names):
        with Image.open(path.parent / (name + '.png')) as image:
            thumb = ImageOps.contain(image.convert('RGB'), (640, 360), Image.Resampling.LANCZOS)
        x, y = n % 2 * 640, n // 2 * 385
        draw.text((x + 10, y + 2), name, font=font, fill='white')
        board.paste(thumb, (x, y + 25))
    sheet = path.parent / 'contact_sheet.png'
    board.save(sheet)
    output['contact_sheet'] = {'path': str(sheet.relative_to(GAME)), 'sha256': sha(sheet)}
    (GAME / 'docs/current/TRANSFORM_PILOT.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


def summarize_substitute_pilot():
    path = GAME / '.godot/substitute_checks/gpu.json'
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    assert len(result['core_samples']) == 48 and len(result['captures']) == 9
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    for capture in result['captures']:
        assert sha(GAME / capture['path']) == capture['sha256']
    assert sha(GAME / '.godot/battle_substitute/manifest.json') == result['pack_sha256']
    output = dict(result)
    output.pop('core_samples')
    output['status'] = 'SINGLES_SUBSTITUTE_PILOT_VALIDATED_NOT_GLOBAL_ROLLOUT'
    output['validation_status'] = 'PASS'
    output['server_sample_count'] = 48
    output['test_report'] = str(path.relative_to(GAME))
    output['test_report_sha256'] = sha(path)
    output['mechanics_added'] = ['substitute', 'shed_tail']
    output['remaining_unimplemented'] = ['transform', 'ally_switch']
    output['production_rollout_complete'] = False
    output['limitations'] = [
        'Explicit singles pilot only; default sessions and trainer UI/AI/search remain disabled.',
        'No full competitive certification of suppression/Mold Breaker, Dynamax, doubles or move-specific exceptions.',
        'Interception applies to damage and effect families represented by this engine; unsupported move mechanics remain unsupported.',
        'Native creation is projected onto the doll feet. Hits on a doll use the existing generic type impact, not an original attack binding certified for doll-sized targets.'
    ]
    output['visual_adaptations'] = ['substitute: native original doll creation aligned to feet; persistent doll hidden during native creation to avoid duplicates.',
                                  'shed_tail: native original tail/doll cast aligned to feet; existing doll transferred to the selected reserve.',
                                  'No original PNGs or catalog entries changed. Front/back original doll tiles remain distinct.']
    names = ['substitute_back_native', 'substitute_front_native', 'shed_tail_back_native', 'shed_tail_front_native',
             'substitute_persistent', 'shed_tail_persistent', 'shed_entry_doll', 'substitute_broken', 'shed_tail_broken']
    board = Image.new('RGB', (1280, 5 * 385), '#17231f')
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    for n, name in enumerate(names):
        with Image.open(path.parent / (name + '.png')) as image:
            thumb = ImageOps.contain(image.convert('RGB'), (640, 360), Image.Resampling.LANCZOS)
        x, y = n % 2 * 640, n // 2 * 385
        draw.text((x + 10, y + 2), name, font=font, fill='white')
        board.paste(thumb, (x, y + 25))
    sheet = path.parent / 'contact_sheet.png'
    board.save(sheet)
    output['contact_sheet'] = {'path': str(sheet.relative_to(GAME)), 'sha256': sha(sheet)}
    (GAME / 'docs/current/SUBSTITUTE_PILOT.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


def summarize_weather_pilot():
    path = GAME / '.godot/weather_checks/gpu.json'
    if not path.exists(): return None
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    assert len(result['core_samples']) == 120 and len(result['captures']) == 11
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    for capture in result['captures']:
        assert sha(GAME / capture['path']) == capture['sha256']
    output = dict(result)
    output['status'] = 'SINGLES_WEATHER_PILOT_VALIDATED_NOT_GLOBAL_ROLLOUT'
    output['validation_status'] = 'PASS'
    output['server_sample_count'] = len(output.pop('core_samples'))
    output['production_rollout_complete'] = False
    output['test_report'] = str(path.relative_to(GAME))
    output['test_report_sha256'] = sha(path)
    output['resource_sha256'] = {'.godot/battle_weather/' + name: sha(GAME / '.godot/battle_weather' / name) for name in ['manifest.json', 'common.json', 'casts.json']}
    output['common_loop_frames'] = [30, 30, 30, 20]
    output['native_cast_clips_loaded'] = 10
    output['notes'] = ['Only F9 enables this weather scope; default snapshots/AI behavior are unchanged.',
                       'Weather expiration is checked before its final residual callback, following the reference event order. Five-turn weather therefore has four residual callbacks after setting it.',
                       'Sandstorm boosts Rock special defense; snow boosts Ice physical defense. Snow has no hail chip damage.',
                       'Common snow/hail share the original artwork, while their mechanics remain distinct.',
                       'Only back-side weather casts and persistent loops have new GPU captures here. Both sides are covered by the authoritative core samples; this is not a new complete front-side visual certification.',
                       'Chilly Reception establishes snow before requesting a replacement; existing snow still permits the pivot without restarting its timer.',
                       'Pokemon sent out after weather KO do not receive another end-turn status/held-item transaction in this pilot.']
    output['references'] = ['https://github.com/smogon/pokemon-showdown/blob/master/data/conditions.ts',
                            'https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts',
                            'https://github.com/smogon/pokemon-showdown/blob/master/sim/battle.ts']
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    board = Image.new('RGB', (1280, 55 + 5 * 383), '#17231f')
    draw = ImageDraw.Draw(board)
    draw.text((12, 10), 'F9 | CINCO MOVIMIENTOS DE CLIMA | ACTIVACION Y ESTADO PERSISTENTE', font=font, fill='white')
    for i, move in enumerate(output['mechanics_added']):
        for j, suffix in enumerate(['cast', 'persistent']):
            name = f'{move}_{suffix}.png'
            with Image.open(path.parent / name) as image:
                thumb = ImageOps.contain(image.convert('RGB'), (640, 358), Image.Resampling.LANCZOS)
            draw.text((j * 640 + 10, 55 + i * 383), name, font=font, fill='#f1c789')
            board.paste(thumb, (j * 640, 77 + i * 383))
    sheet = path.parent / 'weather_contact_sheet.png'
    board.save(sheet)
    output['contact_sheet'] = {'path': str(sheet.relative_to(GAME)), 'sha256': sha(sheet)}
    destination = GAME / 'docs/current/WEATHER_PILOT.json'
    destination.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


def summarize_status_pilot():
    path = GAME / '.godot/status_switch_checks/gpu.json'
    if not path.exists():
        return None
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    assert len(result['core_samples']) == 120 and len(result['captures']) == 18 and len(result['native_clip_ids']) == 10
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    for capture in result['captures']:
        assert sha(GAME / capture['path']) == capture['sha256']
    assert sha(GAME / '.godot/battle_status_switch/manifest.json') == result['pack_sha256']
    output = dict(result)
    output['status'] = 'SINGLES_STATUS_PILOT_VALIDATED_NOT_GLOBAL_ROLLOUT'
    output['validation_status'] = 'PASS'
    output['test_report'] = str(path.relative_to(GAME))
    output['test_report_sha256'] = sha(path)
    output['production_rollout_complete'] = False
    output.pop('core_samples')
    output['server_sample_count'] = 120
    output['notes'] = ['F8 explicitly enables five status-switch mechanics in wild singles. Trainer-format engine tests do not certify trainer UI/AI rollout.',
                       'Modern Teleport pivots an owned Pokemon even in wild encounters; only a wild user ends the encounter.',
                       'Baton Pass transfers stages before entry triggers and only the declared volatile subset; persistent status stays with its owner.',
                       'Whirlwind retains its already-selected GUST visual equivalent. No new image replacements or original PNG changes.',
                       'Exact integral JSON payload values are canonicalized only on enabled snapshots, preserving fractions and legacy disabled wire format.']
    output['references'] = ['https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts',
                            'https://github.com/smogon/pokemon-showdown/blob/master/sim/pokemon.ts',
                            'https://bulbapedia.bulbagarden.net/wiki/Teleport']
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    root = path.parent
    moves = ['roar', 'whirlwind', 'teleport', 'baton_pass', 'parting_shot']
    sheets = []
    for mode in ['native', 'live']:
        board = Image.new('RGB', (1280, 55 + 5 * 383), '#17231f')
        draw = ImageDraw.Draw(board)
        title = '5 MOVIMIENTOS DE ESTADO | FUENTES NATIVAS SOBRE EVENTOS REALES | AMBOS LADOS' if mode == 'native' else 'F8 | COMBATE SALVAJE REAL | ESTADO Y ELECCION DE RESERVA'
        draw.text((12, 10), title, font=font, fill='white')
        for i, move in enumerate(moves):
            names = [f'{move}_{side}_native.png' for side in ['back', 'front']] if mode == 'native' else [f'{move}_live.png'] + ([f'{move}_choice.png'] if move in moves[2:] else [])
            for j, name in enumerate(names):
                with Image.open(root / name) as image:
                    thumb = ImageOps.contain(image.convert('RGB'), (640, 358), Image.Resampling.LANCZOS)
                draw.text((j * 640 + 10, 55 + i * 383), name, font=font, fill='#f1c789')
                board.paste(thumb, (j * 640, 77 + i * 383))
        target = root / (mode + '_contact_sheet.png')
        board.save(target)
        sheets.append({'path': str(target.relative_to(GAME)), 'sha256': sha(target)})
    output['contact_sheets'] = sheets
    destination = GAME / 'docs/current/STATUS_SWITCH_MOVES.json'
    destination.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


def summarize_pilot():
    path = GAME / '.godot/switch_move_checks/gpu.json'
    if not path.exists():
        return None
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['gpu'] and not result['errors']
    assert len(result['core_samples']) == 120 and len(result['captures']) == 11
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    for capture in result['captures']:
        assert sha(GAME / capture['path']) == capture['sha256']
    current = GAME / '.godot/switch_move_checks/data_foundation_v3_domain_test_runner.log'
    before = GAME / '.godot/switch_move_checks/data_baseline.log'
    failures = lambda p: sorted(re.findall(r'ERROR: FAIL  (\S+)', p.read_text(encoding='utf-8-sig')))
    assert failures(current) == failures(before) and len(failures(before)) == 9
    regression = {}
    for label, name in [('core', 'test_runner'), ('commands', 'battle_commands_test_runner'),
                        ('manual_switch', 'battle_switch_presentation_test_runner'),
                        ('capture', 'battle_capture_presentation_test_runner'),
                        ('run', 'battle_run_presentation_test_runner'),
                        ('vertical_slice', 'vertical_slice_test_runner'),
                        ('save_v2', 'savegame_v2_test_runner'), ('field', 'visual_field_test_runner'),
                        ('trainer_evaluation', 'trainer_evaluation')]:
        log = GAME / '.godot/switch_move_checks' / (name + '.log')
        summary = re.findall(r'=== .* RESULT: (\d+) PASS / (\d+) FAIL ===', log.read_text(encoding='utf-8-sig'))
        assert summary and summary[-1][1] == '0', name
        regression[label] = {'passed': int(summary[-1][0]), 'failed': 0, 'log': str(log.relative_to(GAME)), 'sha256': sha(log)}
    for label, name in [('playback', 'battle_animation_playback_test_runner'), ('prior_native_bindings', 'battle_community_pilot_test_runner')]:
        log = GAME / '.godot/switch_move_checks' / (name + '.log')
        marker = 'BATTLE_ANIMATION_RESULT ' if label == 'playback' else 'BATTLE_COMMUNITY_PILOT_RESULT '
        line = next(line for line in log.read_text(encoding='utf-8-sig').splitlines() if line.startswith(marker))
        validation = json.loads(line[len(marker):])
        assert validation['status'] == 'PASS' and not validation['failures']
        regression[label] = {'passed': validation['passed'], 'failed': 0, 'log': str(log.relative_to(GAME)), 'sha256': sha(log)}
    output = {'version': 1, 'status': 'SINGLES_PILOT_VALIDATED_NOT_GLOBAL_ROLLOUT',
              'validation_status': 'PASS', 'checks': result['checks'], 'core_samples': 120,
              'captures': result['captures'], 'source_sha256': result['source_sha256'],
              'test_report': str(path.relative_to(GAME)), 'test_report_sha256': sha(path),
              'mechanics_pilot_move_ids': ['circle_throw', 'dragon_tail', 'flip_turn', 'u_turn', 'volt_switch'],
              'mechanics_pilot_move_count': 5, 'production_rollout_complete': False,
              'default_mode_full_special_effects_completed': 0,
              'remaining_unimplemented_move_ids': ['ally_switch', 'baton_pass', 'chilly_reception', 'hail', 'parting_shot', 'rain_dance', 'roar', 'sandstorm', 'shed_tail', 'snowscape', 'substitute', 'teleport', 'transform', 'whirlwind'],
              'enabled_scope': result['enabled_scope'], 'limitations': result['limitations'],
              'regressions': regression,
              'preexisting_data_audit': {'passed': 624, 'failed': 9, 'identical_before_and_after': True,
                                       'failures': failures(before), 'baseline_log': str(before.relative_to(GAME)), 'baseline_sha256': sha(before),
                                       'current_log': str(current.relative_to(GAME)), 'current_sha256': sha(current)},
              'notes': ['F7 explicitly enables the pilot for new wild demo encounters; restart restores the natural team/learnset and disables it.',
                        'Trainer-format authoritative engine is tested on both sides; trainer UI/AI/search continuation is not enabled.',
                        'Pause serializes pending replacement and remaining ordered actions; choosing a bench resumes the same turn without extra PP or end-turn ticks.',
                        'Four physical contact flags are corrected on detached execution definitions only in the pilot. Frozen catalog definitions remain unchanged.',
                        'The 19 global external handoffs remain open until mechanics interactions and production consumers are certified.'],
              'references': ['https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts',
                             'https://github.com/smogon/pokemon-showdown/blob/master/sim/battle-actions.ts',
                             'https://bulbapedia.bulbagarden.net/wiki/Dragon_Tail']}
    status_pilot = summarize_status_pilot()
    if status_pilot is not None:
        output['version'] = 2
        output['test_reports'] = [
            {'path': output.pop('test_report'), 'sha256': output.pop('test_report_sha256'),
             'move_count': 5, 'checks': result['checks'], 'server_samples': 120},
            {'path': status_pilot['test_report'], 'sha256': status_pilot['test_report_sha256'],
             'move_count': 5, 'checks': status_pilot['checks'], 'server_samples': 120}]
        output['checks'] += status_pilot['checks']
        output['core_samples'] += status_pilot['server_sample_count']
        output['captures'] += status_pilot['captures']
        output['source_sha256'].update(status_pilot['source_sha256'])
        output['mechanics_pilot_move_ids'] += status_pilot['mechanics_added']
        output['mechanics_pilot_move_count'] = 10
        output['remaining_unimplemented_move_ids'] = status_pilot['remaining_unimplemented']
        output['enabled_scope'] = 'Explicit F7/F8 wild singles pilot, ten moves; trainer-format core tested on both sides, trainer UI/AI rollout pending.'
        output['limitations'] += status_pilot['limitations']
        output['notes'].append('F8 adds five status-switch moves. See STATUS_SWITCH_MOVES.json for its separate source/visual evidence. The 19 global handoffs remain open.')
        output['status_move_report'] = {'path': 'docs/current/STATUS_SWITCH_MOVES.json', 'sha256': sha(GAME / 'docs/current/STATUS_SWITCH_MOVES.json')}
    weather_pilot = summarize_weather_pilot()
    if weather_pilot is not None:
        output['version'] = 3
        output['test_reports'].append({'path': weather_pilot['test_report'], 'sha256': weather_pilot['test_report_sha256'],
                                       'move_count': 5, 'checks': weather_pilot['checks'], 'server_samples': 120})
        output['checks'] += weather_pilot['checks']
        output['core_samples'] += 120
        output['captures'] += weather_pilot['captures']
        output['source_sha256'].update(weather_pilot['source_sha256'])
        output['mechanics_pilot_move_ids'] += weather_pilot['mechanics_added']
        output['mechanics_pilot_move_count'] = 15
        output['remaining_unimplemented_move_ids'] = weather_pilot['remaining_unimplemented']
        output['limitations'] += weather_pilot['limitations']
        output['enabled_scope'] = 'Explicit F7/F8/F9 wild singles pilot, fifteen moves; trainer-format core tested on both sides, trainer UI/AI rollout pending.'
        output['weather_move_report'] = {'path': 'docs/current/WEATHER_PILOT.json', 'sha256': sha(GAME / 'docs/current/WEATHER_PILOT.json')}
        output['notes'].append('F9 adds four weather setters and Chilly Reception; WEATHER_PILOT.json records the narrower tested interactions and visual scope.')
    substitute = summarize_substitute_pilot()
    output['version'] = 4
    output['test_reports'].append({'path': substitute['test_report'], 'sha256': substitute['test_report_sha256'],
                                   'move_count': 2, 'checks': substitute['checks'], 'server_samples': 48})
    output['checks'] += substitute['checks']
    output['core_samples'] += substitute['server_sample_count']
    output['captures'] += substitute['captures']
    output['source_sha256'].update(substitute['source_sha256'])
    output['mechanics_pilot_move_ids'] += substitute['mechanics_added']
    output['mechanics_pilot_move_count'] = 17
    output['remaining_unimplemented_move_ids'] = substitute['remaining_unimplemented']
    output['enabled_scope'] = 'Explicit F7/F8/F9/F10 wild singles pilots, seventeen base mechanics; trainer-format core tested on both sides, trainer UI/AI rollout pending.'
    # Per-stage reports preserve their historical scopes. Describe current combined limits here.
    output['limitations'] = substitute['limitations'] + [
        'Baton Pass transfers only the declared represented volatile subset.',
        'Weather retains the specific move/ability limits recorded in WEATHER_PILOT.json.',
        'All 19 production handoffs remain open; seventeen opt-in base mechanics are not seventeen fully competitive implementations.'
    ]
    output['substitute_report'] = {'path': 'docs/current/SUBSTITUTE_PILOT.json', 'sha256': sha(GAME / 'docs/current/SUBSTITUTE_PILOT.json')}
    output['notes'].append('F10 adds Substitute and Shed Tail: distinct doll HP, capped per-strike damage, blocked target effects, queued selected replacement, JSON restore and original doll art. See SUBSTITUTE_PILOT.json.')
    transform = summarize_transform_pilot()
    output['version'] = 5
    output['test_reports'].append({'path': transform['test_report'], 'sha256': transform['test_report_sha256'],
                                   'move_count': 1, 'checks': transform['checks'], 'server_samples': 72})
    output['checks'] += transform['checks']
    output['core_samples'] += transform['server_sample_count']
    output['captures'] += transform['captures']
    output['source_sha256'].update(transform['source_sha256'])
    output['mechanics_pilot_move_ids'] += transform['mechanics_added']
    output['mechanics_pilot_move_count'] = 18
    output['remaining_unimplemented_move_ids'] = transform['remaining_unimplemented']
    output['enabled_scope'] = 'Explicit F7/F8/F9/F10/F11 wild singles pilots, eighteen base mechanics; trainer-format core tested on both sides, trainer UI/AI rollout pending.'
    output['limitations'] = substitute['limitations'] + transform['limitations'] + [
        'Baton Pass transfers only the declared represented volatile subset.',
        'Weather retains the specific move/ability limits recorded in WEATHER_PILOT.json.',
        'All 19 production handoffs remain open; eighteen opt-in base mechanics are not eighteen fully competitive implementations.'
    ]
    output['transform_report'] = {'path': 'docs/current/TRANSFORM_PILOT.json', 'sha256': sha(GAME / 'docs/current/TRANSFORM_PILOT.json')}
    output['notes'].append('F11 adds reversible Transform with original capture/XP identity, temporary copied PP, real menu updates and an adapted appearance handoff. See TRANSFORM_PILOT.json.')
    ally = summarize_ally_switch_pilot()
    output['version'] = 6
    output['status'] = 'EXPLICIT_SINGLES_AND_DOUBLES_PILOTS_VALIDATED_NOT_GLOBAL_ROLLOUT'
    output['test_reports'].append({'path': ally['test_report'], 'sha256': ally['test_report_sha256'],
                                   'move_count': 1, 'checks': ally['checks'], 'server_samples': 48, 'format': ally['format']})
    output['checks'] += ally['checks']
    output['core_samples'] += ally['server_sample_count']
    output['captures'] += ally['captures']
    output['source_sha256'].update(ally['source_sha256'])
    output['mechanics_pilot_move_ids'] += ally['mechanics_added']
    output['mechanics_pilot_move_count'] = 19
    output['remaining_unimplemented_move_ids'] = []
    output['pending_production_certification_move_ids'] = sorted(output['mechanics_pilot_move_ids'])
    output['enabled_scope'] = 'F7-F11: 18 opt-in wild singles base mechanics. F12: Ally Switch in a separate four-participant position adapter. These are not a complete shared production battle engine.'
    output['pilot_format_counts'] = {'wild_singles_move_count': 18, 'isolated_doubles_move_count': 1}
    output['limitations'] = substitute['limitations'] + transform['limitations'] + ally['limitations'] + [
        'No global gameplay/trainer AI rollout or full competitive certification. All 19 production handoffs remain open.',
        'The doubles adapter does not enable the eighteen singles pilots in doubles. Weather and Baton Pass retain their earlier documented limits.'
    ]
    output['ally_switch_report'] = {'path': 'docs/current/ALLY_SWITCH_PILOT.json', 'sha256': sha(GAME / 'docs/current/ALLY_SWITCH_PILOT.json')}
    output['notes'].append('F12 adds real ally position swaps with position-bound incoming damage, four-action ordering, repeat probability and an isolated four-body UI. All 19 now have scoped base pilots; production integration remains open.')
    live_path = GAME / 'docs/current/LIVE_MOVE_INTEGRATION.json'
    if live_path.exists():
        live = json.loads(live_path.read_text(encoding='utf-8'))
        for file, expected in live['source_sha256'].items():
            assert sha(GAME / file) == expected, file
        output['version'] = 7
        output['status'] = 'LOCAL_GAME_SINGLES_PROFILE_ENABLED_COMPETITIVE_CERTIFICATION_OPEN'
        output['game_session_single_specials_enabled'] = 18
        output['live_runtime_admitted_move_count'] = live['admitted_move_count']
        output['live_visual_registered_move_count'] = live['registered_visual_move_count']
        output['live_game_report'] = {'path': str(live_path.relative_to(GAME)), 'sha256': sha(live_path)}
        output['enabled_scope'] = f"Ordinary local game sessions enable the implemented singles mechanics through the live profile. F12 remains an isolated doubles adapter. Original per-pilot counts are retained; the separate live report audits all {live['admitted_move_count']} admitted moves and 1822 registered clips."
        output['limitations'] = live['limits'] + ['Full competitive interaction certification and standalone distribution/export remain separate.']
        output['notes'].append('Earlier per-stage limitations describe their original boundaries. LIVE_MOVE_INTEGRATION.json supersedes the old default-game rollout status; low-level flags-off behavior remains a compatibility contract.')
    destination = GAME / 'docs/current/SWITCH_MOVE_PILOT.json'
    destination.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return {'path': str(destination.relative_to(GAME)), 'sha256': sha(destination),
            'status': output['status'], 'move_count': output['mechanics_pilot_move_count'], 'unimplemented_move_count': len(output['remaining_unimplemented_move_ids']),
            'production_rollout_complete': False}


def summarize():
    path = ROOT / 'gpu_result.json'
    result = json.loads(path.read_text(encoding='utf-8'))
    assert result['status'] == 'PASS' and result['errors'] == [] and result['gpu']
    assert len(result['core_cases']) == 38 and result['full_special_effects_completed'] == 0
    for file, expected in result['source_sha256'].items():
        assert sha(GAME / file) == expected, file
    assert sha(GAME / '.godot/battle_external_damage/manifest.json') == result['binding_pack_sha256']
    baseline = json.loads((GAME / '.godot/move_self_body_checks/reference/baseline.json').read_text(encoding='utf-8'))
    for file, expected in baseline.items():
        if file != 'head':
            assert sha(GAME / file) == expected
    for row in result['screenshots']:
        assert sha(ROOT / row['path']) == row['sha256']
    cases = {}
    for row in result['core_cases']:
        cases.setdefault(row['move_id'], []).append(row)
    moves = []
    for move, pair in sorted(cases.items()):
        assert {row['side'] for row in pair} == {'back', 'front'}
        assert all(not row['switched'] and not row['full_special_effect_resolved'] for row in pair)
        damage_only = all(row['damage'] > 0 for row in pair)
        assert all(row['native_damage_binding'] == damage_only for row in pair)
        if not damage_only:
            for row in pair:
                assert {e['kind'] for e in row['events']} == {'action_used', 'pp_changed', 'turn_ended'}
                assert any(e['kind'] == 'pp_changed' and e['amount'] == -1 for e in row['events'])
        moves.append({'move_id': move, 'classification_in_preserved_dataset': pair[0]['classification'],
                      'registered_effect_kinds': pair[0]['registered_effect_kinds'],
                      'confirmed_damage_visual_connected': damage_only, 'full_special_effect_resolved': False,
                      'observed_no_effect_beyond_pp_and_action': not damage_only,
                      'remaining_requirement': pair[0]['requirement']})
    damage_ids = [row['move_id'] for row in moves if row['confirmed_damage_visual_connected']]
    assert len(damage_ids) == 5 and len(moves) == 19
    output = {
        'version': 1, 'status': 'PARTIAL', 'validation_status': 'PASS',
        'requested_move_count': 19, 'confirmed_damage_visual_bindings': 5,
        'full_special_effects_completed': 0, 'full_special_effects_remaining': 19,
        'observed_no_effect_moves': 14, 'server_samples': 38,
        'native_live_battle_hits': result['native_hits'], 'checks': result['checks'],
        'test_report': str(path.relative_to(GAME)), 'test_report_sha256': sha(path),
        'source_sha256': result['source_sha256'], 'pack_sha256': result['binding_pack_sha256'],
        'moves': moves,
        'scope': 'Five damage-only native particle bindings; original bodies and battle outcomes remain authoritative. All 19 special mechanics remain incomplete.',
        'notes': [
            'The 38 server samples use the authoritative reaction-turn API in both directions. Five ordinary wild battles and one trainer KO test the actual presentation seam.',
            'Four RUNTIME_SUPPORTED tags currently result in ordinary damage only. Metadata alone does not certify pivoting or forced switching.',
            'Thirteen DATA_ONLY moves and Transform (UNSUPPORTED) consume PP without their special effect in these server fixtures.',
            'Manual switching and KO replacement already emit real SWITCHED events; neither is proof of a pivot/phaze move implementation.',
            'No mechanic is invented in presentation, no definitions/learnsets/type chart/AI/RNG or source artwork are changed.',
            'F6 offers an explicit disposable damage-only preset. This is not a permanent learnset or a complete move implementation.'
        ]
    }
    pilot = summarize_pilot()
    if pilot is not None:
        output['explicit_singles_mechanics_pilot'] = pilot
        output['notes'].append('The counts above describe default/legacy mode. The separate F7-F12 report counts validated opt-in base mechanics across singles and isolated doubles; it does not enable trainer AI or close the 19 global handoffs.')
    live_path = GAME / 'docs/current/LIVE_MOVE_INTEGRATION.json'
    if live_path.exists():
        output['legacy_comparison_only'] = True
        output['live_game_report'] = {'path': str(live_path.relative_to(GAME)), 'sha256': sha(live_path)}
        output['notes'].append('The engine/default counts here are the explicit flags-off compatibility comparison. Actual ordinary game sessions now use the live singles profile; consult the linked live report rather than treating these nineteen legacy no-ops as current gameplay.')
    destination = GAME / 'docs/current/BATTLE_EXTERNAL_INTEGRATION.json'
    destination.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    board = Image.new('RGB', (1280, 58 + 5 * 382), '#111722')
    draw = ImageDraw.Draw(board)
    draw.text((12, 8), 'COMBATE REAL: SOLO DANO | RELEVOS/EXPULSIONES ESPECIALES TODAVIA PENDIENTES', font=font, fill='white')
    draw.text((12, 30), 'Dos direcciones por movimiento. Originales conservados; no se habilitan mecanicas por mostrar una imagen.', font=font, fill='#b5c6d8')
    for row, move in enumerate(damage_ids):
        y = 58 + row * 382
        for col, side in enumerate(['back', 'front']):
            name = move + '_' + move + '_' + side + '.png'
            with Image.open(ROOT / name) as image:
                thumb = ImageOps.contain(image.convert('RGB'), (640, 358), Image.Resampling.LANCZOS)
            draw.text((col * 640 + 8, y), move + '/' + side, font=font, fill='#ffc176')
            board.paste(thumb, (col * 640, y + 22))
    board.save(ROOT / 'confirmed_damage_contact_sheet.png')
    print('EXTERNAL_INTEGRATION_SUMMARY PASS: 5 damage visuals connected; 19 full special effects still pending;', destination)
    print('REPORT_SHA256', sha(destination))


if __name__ == '__main__':
    summarize()
