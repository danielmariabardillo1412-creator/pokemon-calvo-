"""Verify fixed-damage/reference evidence and record the current local scope."""
import hashlib
import json
from pathlib import Path
import re
import sys
from collections import Counter

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/battle_reference'))
from run import protected_sources

FOLDER = ROOT / '.godot/fixed_damage_checks'
REFERENCE = ROOT / '.godot/battle_reference/latest'
KNOWN_DATA_FAILURES = {
    'data_v3_ability_contract_report_counts', 'data_v3_ability_contract_report_ids',
    'data_v3_bad_dreams_source_contract', 'data_v3_ice_body_source_contract',
    'data_v3_merciless_source_contract', 'data_v3_rain_dish_source_contract',
    'data_v3_rivalry_source_contract', 'data_v3_stakeout_source_contract',
    'data_v3_end_to_end_shadow_exclusion_and_reports_frozen',
}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    result, live, reference = read(FOLDER / 'gpu.json'), read(ROOT / 'docs/current/LIVE_MOVE_INTEGRATION.json'), read(REFERENCE / 'report.json')
    assert result['status'] == 'PASS' and result['gpu'] and result['cases'] == 168 and len(result['captures']) == 14
    assert len(result['moves']) == 7 and len(result['newly_admitted']) == 6 and result['corrected_existing'] == ['ruination']
    assert live['validation_status'] == 'PASS' and live['admitted_move_count'] == 591 and live['not_implemented_or_partial_count'] == 259
    for evidence in (result, live):
        for path, expected in evidence['source_sha256'].items(): assert sha(ROOT / path) == expected, path
    for capture in result['captures']: assert sha(ROOT / capture['path']) == capture['sha256']
    assert reference['status'] == 'PASS' and reference['counts'] == {'MATCH':1932, 'MISMATCH':0, 'NOT_COMPARABLE':0}
    assert reference['protected_sources']['unchanged']
    for name, expected in reference['tool_sha256'].items(): assert sha(ROOT / 'tools/battle_reference' / name) == expected, name
    for name, expected in reference['observations_sha256'].items(): assert sha(REFERENCE / name) == expected, name
    assert sha(REFERENCE / 'manifest.json') == reference['manifest_sha256']
    manifest = read(REFERENCE / 'manifest.json')['cases']
    assert Counter(c['family'] for c in manifest) == {'stat_stages':600, 'fixed_damage':1332}
    assert len({c['id'] for c in manifest}) == 1932
    for c in manifest: assert c['id'].startswith(c['family'] + '/')
    controls = read(ROOT / '.godot/battle_reference/negative_controls/checks.json')
    assert controls['status'] == 'PASS' and controls['checks'] == 3
    tests_log = (ROOT / '.godot/battle_reference/self_test.log').read_text(encoding='utf-8-sig')
    assert 'Ran 24 tests' in tests_log and '\nOK' in tests_log
    for log in ['gpu.log','core.log','trainer.log','data_v3.log','playback.log']:
        text = (FOLDER / log).read_text(encoding='utf-8-sig')
        assert 'SCRIPT ERROR' not in text, log
        if log == 'gpu.log': assert 'ERROR:' not in text
        if log == 'core.log': assert '472 PASS / 0 FAIL' in text
        if log == 'trainer.log': assert '628 PASS / 0 FAIL' in text
        if log == 'data_v3.log':
            assert '624 PASS / 9 FAIL' in text
            assert set(re.findall(r'^ERROR: FAIL\s+(\S+)', text, re.M)) == KNOWN_DATA_FAILURES
        if log == 'playback.log': assert '"passed":20809' in text and '"status":"PASS"' in text
    before, after = read(FOLDER / 'before.json'), protected_sources()
    changed = sorted(p for p in before.keys() | after.keys() if before.get(p) != after.get(p))
    assert set(changed) == {'modules/battle/application/fixed_damage_move_rules.gd',
                            'modules/battle/application/live_move_profile.gd', 'modules/battle/application/turn_executor.gd'}, changed
    for p in ['data/raw/pokemon_api.json', 'data/normalized/pokemon_api.json', 'scenes/visual/community_move_preview.gd',
              'assets/local_battle_catalog/manifest.json', 'assets/local_battle_variants/manifest.json', '.godot/move_batch_catalog/index.json']:
        assert sha(ROOT / p) == before[p], p
    frozen = read(ROOT / '.godot/move_self_body_checks/reference/baseline.json')
    for path, expected in frozen.items():
        if path != 'head': assert sha(ROOT / path) == expected, path
    regressions = {'core':{'passed':472,'failed':0}, 'playback':{'passed':20809,'failed':0},
                   'trainer_corpus':{'passed':628,'failed':0},
                   'data_v3':{'passed':624,'failed':9,'unchanged_known_failures':sorted(KNOWN_DATA_FAILURES)}}
    evidence = [FOLDER / name for name in ['gpu.json','gpu.log','core.log','trainer.log','data_v3.log','playback.log','contact_native.png','contact_after.png']]
    evidence += [REFERENCE / name for name in ['report.json','manifest.json','reference.json','godot.json','sources_before.json']]
    evidence += [ROOT / '.godot/battle_reference/negative_controls/checks.json', ROOT / '.godot/battle_reference/self_test.log']
    current_reference = {
        'schema_version':1, 'status':'LOCAL_BATTLE_REFERENCE_VALIDATED', 'date':'2026-10-26',
        'scope':'Development-only actual authoritative Godot server vs pinned Showdown; stat_stages + fixed_damage',
        'reference':reference['reference'], 'engine_versions':reference['engine_versions'], 'counts':reference['counts'],
        'cases':1932, 'cases_by_family':dict(Counter(c['family'] for c in manifest)),
        'comparison_fields':reference['comparison_fields'], 'limits':reference['limits'],
        'batches':reference['batches'], 'elapsed_seconds':reference['elapsed_seconds'],
        'protected_sources':reference['protected_sources'], 'tool_sha256':reference['tool_sha256'],
        'self_tests':{'status':'PASS','unit_tests':24,'real_adapter_negative_controls':3},
        'evidence':{p.relative_to(ROOT).as_posix():sha(p) for p in evidence if 'battle_reference' in p.parts},
        'documentation':'tools/battle_reference/README.md', 'credits':'tools/battle_reference/THIRD_PARTY_NOTICES.md',
        'github_publication_performed':False,
    }
    (ROOT / 'docs/current/BATTLE_REFERENCE_VALIDATION.json').write_text(json.dumps(current_reference,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    result.update({'status':'LOCAL_FIXED_DAMAGE_BATCH_VALIDATED',
                   'scope':'Live singles fixed constants/level/current-HP damage; canonical data and artwork unchanged',
                   'admitted_move_count_at_validation':591,'remaining_mechanics_count_at_validation':259,
                   'external_reference_cases':1932,'external_fixed_damage_cases':1332,
                   'self_tests':current_reference['self_tests'], 'regressions':regressions,
                   'protected_game_source_changes':changed,
                   'evidence':{p.relative_to(ROOT).as_posix():sha(p) for p in evidence},
                   'reference_definition_sha256':sha(ROOT / '.godot/battle_reference/runtime/node_modules/@pkmn/sim/build/cjs/data/moves.js'),
                   'visual_review':'Seven native and seven after-playback GPU captures inspected; clips/HUD restore and exact displayed HP confirmed in these samples.',
                   'fixture_correction':'The first UI fixture used excluded Splash, which became Struggle and KOed the low-HP target by recoil. Replaced only that test action with admitted Swords Dance and reran the complete focal gate.',
                   'limits':['Singles only; no Dynamax, doubles or universal ability/protection certification.',
                             'Ruination power 1 and Super Fang contact=false remain frozen in canonical data; the live extension supplies the correct effect/contact.',
                             'Only fixed damage has exact external HP parity; ordinary damage variance/critical calculations are outside this comparison.',
                             'Contact retaliation reuses the existing framework, including its previous defender-KO limitations; tested external contact cases keep the defender alive.',
                             'Trainer AI uses the existing legal candidates and authoritative simulation; no new heuristic calibration or randomlock rules.',
                             'DATA V3 retains exactly nine preexisting failures. No data regeneration, new images, GitHub publication or export packaging.']})
    (ROOT / 'docs/current/FIXED_DAMAGE_MOVES.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('FIXED_DAMAGE_SUMMARY PASS: 6 newly admitted, Ruination corrected; 1364 focal checks, 1932 reference matches; 591 admitted / 259 mechanics pending')


if __name__ == '__main__': main()
