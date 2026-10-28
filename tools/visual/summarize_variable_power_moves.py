"""Validate current variable-power, comparison and regression evidence."""
import json
import re
from collections import Counter
from pathlib import Path
from summarize_fixed_damage_moves import ROOT, KNOWN_DATA_FAILURES, read, sha, protected_sources

FOLDER = ROOT / '.godot/variable_power_checks'
REFERENCE = ROOT / '.godot/battle_reference/latest'


def main():
    focal = read(FOLDER / 'gpu.json')
    live = read(ROOT / 'docs/current/LIVE_MOVE_INTEGRATION.json')
    reference = read(REFERENCE / 'report.json')
    assert focal['status'] == 'PASS' and focal['gpu'] and focal['cases'] == 264 and len(focal['moves']) == 11 and len(focal['captures']) == 22
    assert live['validation_status'] == 'PASS' and live['admitted_move_count'] == 602 and live['not_implemented_or_partial_count'] == 248
    for report in (focal, live):
        for path, expected in report['source_sha256'].items(): assert sha(ROOT / path) == expected, path
    for capture in focal['captures']: assert sha(ROOT / capture['path']) == capture['sha256']
    assert reference['status'] == 'PASS' and reference['counts'] == {'MATCH':4950, 'MISMATCH':0, 'NOT_COMPARABLE':0}
    assert reference['protected_sources']['unchanged']
    for name, expected in reference['tool_sha256'].items(): assert sha(ROOT / 'tools/battle_reference' / name) == expected, name
    for name, expected in reference['observations_sha256'].items(): assert sha(REFERENCE / name) == expected, name
    assert sha(REFERENCE / 'manifest.json') == reference['manifest_sha256']
    cases = read(REFERENCE / 'manifest.json')['cases']
    families = dict(Counter(c['family'] for c in cases))
    assert families == {'stat_stages':600, 'fixed_damage':1332, 'variable_power':3018}
    assert len({c['id'] for c in cases}) == 4950
    controls = read(ROOT / '.godot/battle_reference/negative_controls/checks.json')
    assert controls['status'] == 'PASS' and controls['checks'] == 3
    unit_log = (ROOT / '.godot/battle_reference/self_test.log').read_text(encoding='utf-8-sig')
    assert 'Ran 30 tests' in unit_log and '\nOK' in unit_log
    for name, marker in [('gpu.log','VARIABLE_POWER_MOVES PASS'),('core.log','472 PASS / 0 FAIL'),('trainer.log','628 PASS / 0 FAIL'),('playback.log','"passed":20809'),('data_v3.log','624 PASS / 9 FAIL')]:
        text = (FOLDER / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'SCRIPT ERROR' not in text, name
        if name == 'gpu.log': assert 'ERROR:' not in text
        if name == 'data_v3.log': assert set(re.findall(r'^ERROR: FAIL\s+(\S+)',text,re.M)) == KNOWN_DATA_FAILURES
    before, after = read(FOLDER / 'before.json'), protected_sources()
    changed = sorted(p for p in before.keys() | after.keys() if before.get(p) != after.get(p))
    assert set(changed) == {'modules/battle/application/variable_power_move_rules.gd',
        'modules/battle/application/live_move_profile.gd','modules/battle/application/turn_executor.gd',
        'modules/battle/domain/turn_resolver.gd','modules/battle/effects/battle_effect_executor.gd'},changed
    for path in ['data/raw/pokemon_api.json','data/normalized/pokemon_api.json','scenes/visual/community_move_preview.gd',
                 'assets/local_battle_catalog/manifest.json','assets/local_battle_variants/manifest.json','.godot/move_batch_catalog/index.json']:
        assert sha(ROOT / path) == before[path],path
    for path, expected in read(ROOT / '.godot/move_self_body_checks/reference/baseline.json').items():
        if path != 'head': assert sha(ROOT / path) == expected,path
    regression = {'core':{'passed':472,'failed':0},'playback':{'passed':20809,'failed':0},'trainer_corpus':{'passed':628,'failed':0},
                  'data_v3':{'passed':624,'failed':9,'unchanged_known_failures':sorted(KNOWN_DATA_FAILURES)}}
    evidence = [FOLDER / n for n in ['gpu.json','gpu.log','core.log','trainer.log','playback.log','data_v3.log','contact_native.png','contact_after.png']]
    evidence += [REFERENCE / n for n in ['report.json','manifest.json','reference.json','godot.json','sources_before.json']]
    evidence += [ROOT / '.godot/battle_reference/negative_controls/checks.json',ROOT / '.godot/battle_reference/self_test.log']
    helper = {key:reference[key] for key in ['reference','engine_versions','counts','cases','comparison_fields','limits','batches','elapsed_seconds','protected_sources','tool_sha256']}
    helper.update({'schema_version':1,'status':'LOCAL_BATTLE_REFERENCE_VALIDATED','date':'2026-10-26',
        'scope':'Actual Godot authoritative server vs pinned Showdown; stages, fixed damage and observed variable power',
        'cases_by_family':families,'self_tests':{'status':'PASS','unit_tests':30,'real_adapter_negative_controls':3},
        'evidence':{p.relative_to(ROOT).as_posix():sha(p) for p in evidence if 'battle_reference' in p.parts},
        'documentation':'tools/battle_reference/README.md','credits':'tools/battle_reference/THIRD_PARTY_NOTICES.md','github_publication_performed':False})
    (ROOT / 'docs/current/BATTLE_REFERENCE_VALIDATION.json').write_text(json.dumps(helper,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    focal.update({'status':'LOCAL_VARIABLE_POWER_BATCH_VALIDATED','scope':'Live singles dynamic base power over frozen DATA V3',
        'newly_admitted':focal['moves'],'admitted_move_count_at_validation':602,'remaining_mechanics_count_at_validation':248,
        'external_reference_cases':4950,'external_variable_power_cases':3018,'self_tests':helper['self_tests'],'regressions':regression,
        'protected_game_source_changes':changed,'evidence':{p.relative_to(ROOT).as_posix():sha(p) for p in evidence},
        'reference_definition_sha256':sha(ROOT / '.godot/battle_reference/runtime/node_modules/@pkmn/sim/build/cjs/data/moves.js'),
        'visual_review':'Eleven existing native clips and after-playback states inspected in 22 GPU samples; actors and HUD restore.',
        'speed_correction':'Live singles ordering and dynamic power share exact rational stage rounding, paralysis and 10000 speed cap. Legacy flag-off order/RNG remains unchanged.',
        'limits':['Exact external base power/contact/hit/PP parity in listed contexts, not exact ordinary damage/critical/RNG parity.',
            'Existing ability, held-item, protection, defender-KO retaliation and doubles limitations are unchanged; speed modifiers beyond the implemented status/stages remain pending.',
            'Weight moves remain pending source-backed weight data. Move-calling mechanics and future dynamic-power families are not enabled.',
            'No heuristic redesign for trainers, randomizer/learnset changes, canonical-data edits, new artwork, export or GitHub publication.',
            'DATA V3 retains exactly nine preexisting failures.']})
    (ROOT / 'docs/current/VARIABLE_POWER_MOVES.json').write_text(json.dumps(focal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('VARIABLE_POWER_SUMMARY PASS: 11 admitted, 1854 focal checks, 4950 reference matches, 602 available / 248 mechanics pending')


if __name__ == '__main__': main()
