"""Verify binding lifecycle, visible-game evidence, and shared regressions."""
import json
import re
from collections import Counter
from summarize_fixed_damage_moves import ROOT, KNOWN_DATA_FAILURES, read, sha, protected_sources

FOLDER=ROOT/'.godot/binding_checks'
REFERENCE=ROOT/'.godot/battle_reference/latest'


def main():
    focal=read(FOLDER/'gpu.json');live=read(ROOT/'docs/current/LIVE_MOVE_INTEGRATION.json');reference=read(REFERENCE/'report.json')
    assert focal['status']=='PASS' and focal['gpu'] and focal['cases']==240 and len(focal['moves'])==10 and len(focal['captures'])==20
    assert len(focal['visual_samples'])==10 and all(x['target_hp']==x['displayed_hp'] and x['residual_damage']==500 for x in focal['visual_samples'])
    assert live['validation_status']=='PASS' and live['admitted_move_count']==612 and live['not_implemented_or_partial_count']==238
    for report in (focal,live):
        for path,expected in report['source_sha256'].items():assert sha(ROOT/path)==expected,path
    for capture in focal['captures']:assert sha(ROOT/capture['path'])==capture['sha256']
    assert reference['status']=='PASS' and reference['counts']=={'MATCH':5910,'MISMATCH':0,'NOT_COMPARABLE':0} and reference['protected_sources']['unchanged']
    for name,expected in reference['tool_sha256'].items():assert sha(ROOT/'tools/battle_reference'/name)==expected,name
    for name,expected in reference['observations_sha256'].items():assert sha(REFERENCE/name)==expected,name
    assert sha(REFERENCE/'manifest.json')==reference['manifest_sha256']
    cases=read(REFERENCE/'manifest.json')['cases'];families=dict(Counter(x['family'] for x in cases))
    assert families=={'stat_stages':600,'fixed_damage':1332,'variable_power':3018,'binding':960}
    assert len({x['id'] for x in cases})==5910 and sum(x.get('lifecycle_turns')==8 for x in cases)==60
    controls=read(ROOT/'.godot/battle_reference/negative_controls/checks.json')
    assert controls['status']=='PASS' and controls['checks']==3
    unit_log=(ROOT/'.godot/battle_reference/self_test.log').read_text(encoding='utf-8-sig')
    assert 'Ran 36 tests' in unit_log and '\nOK' in unit_log
    for name,marker in [('gpu.log','BINDING_MOVES PASS'),('core.log','472 PASS / 0 FAIL'),('trainer.log','628 PASS / 0 FAIL'),('playback.log','"passed":20809'),('data_v3.log','624 PASS / 9 FAIL')]:
        text=(FOLDER/name).read_text(encoding='utf-8-sig');assert marker in text and 'SCRIPT ERROR' not in text,name
        if name=='gpu.log':assert 'ERROR:' not in text
        if name=='data_v3.log':assert set(re.findall(r'^ERROR: FAIL\s+(\S+)',text,re.M))==KNOWN_DATA_FAILURES
    before,after=read(FOLDER/'before.json'),protected_sources()
    changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
    expected=['modules/battle/application/'+n+'.gd' for n in ['binding_move_rules','live_move_profile','switch_move_rules','turn_executor']]
    expected+=['modules/battle/effects/battle_effect_executor.gd','modules/battle/server/authoritative_battle_server.gd',
        'modules/gameplay/wild_adventure_session.gd','modules/localization/spanish_game_text.gd',
        'modules/trainer_ai/trainer_observation_builder.gd','modules/trainer_ai/trainer_plausible_world_factory.gd']
    expected+=['modules/battle/presentation/'+n+'.gd' for n in ['battle_presentation_controller','trainer_battle_presentation_controller','live_move_event_text']]
    assert set(changed)==set(expected),changed
    for p in ['data/raw/pokemon_api.json','data/normalized/pokemon_api.json','scenes/visual/community_move_preview.gd',
              'assets/local_battle_catalog/manifest.json','assets/local_battle_variants/manifest.json','.godot/move_batch_catalog/index.json']:
        assert sha(ROOT/p)==before[p],p
    for path,expected_hash in read(ROOT/'.godot/move_self_body_checks/reference/baseline.json').items():
        if path!='head':assert sha(ROOT/path)==expected_hash,path
    regression={'core':{'passed':472,'failed':0},'playback':{'passed':20809,'failed':0},'trainer_corpus':{'passed':628,'failed':0},
                'data_v3':{'passed':624,'failed':9,'unchanged_known_failures':sorted(KNOWN_DATA_FAILURES)}}
    evidence=[FOLDER/n for n in ['gpu.json','gpu.log','core.log','trainer.log','playback.log','data_v3.log','contact_native.png','contact_after.png']]
    evidence+=[REFERENCE/n for n in ['report.json','manifest.json','reference.json','godot.json','sources_before.json']]
    evidence+=[ROOT/'.godot/battle_reference/negative_controls/checks.json',ROOT/'.godot/battle_reference/self_test.log']
    helper={key:reference[key] for key in ['reference','engine_versions','counts','cases','comparison_fields','limits','batches','elapsed_seconds','protected_sources','tool_sha256']}
    helper.update({'schema_version':1,'status':'LOCAL_BATTLE_REFERENCE_VALIDATED','date':'2026-10-26',
        'scope':'Actual authoritative Godot server vs pinned Showdown; stages/fixed damage/variable power/binding',
        'cases_by_family':families,'self_tests':{'status':'PASS','unit_tests':36,'real_adapter_negative_controls':3},
        'evidence':{p.relative_to(ROOT).as_posix():sha(p) for p in evidence if 'battle_reference' in p.parts},
        'documentation':'tools/battle_reference/README.md','credits':'tools/battle_reference/THIRD_PARTY_NOTICES.md','github_publication_performed':False})
    (ROOT/'docs/current/BATTLE_REFERENCE_VALIDATION.json').write_text(json.dumps(helper,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    focal.update({'status':'LOCAL_BINDING_BATCH_VALIDATED','newly_admitted':focal['moves'],
        'admitted_move_count_at_validation':612,'remaining_mechanics_count_at_validation':238,
        'external_reference_cases':5910,'external_binding_cases':960,'self_tests':helper['self_tests'],'regressions':regression,
        'protected_game_source_changes':changed,'evidence':{p.relative_to(ROOT).as_posix():sha(p) for p in evidence},
        'reference_conditions_sha256':sha(ROOT/'.godot/battle_reference/runtime/node_modules/@pkmn/sim/build/cjs/data/conditions.js'),
        'visual_review':'Ten native clips plus after-playback states inspected; HUD equals authoritative HP. Actual blocked RUN and capture cleanup tested.',
        'ai_privacy':'Announced source/move/start and estimated clock only; private duration/divisor do not cross either side view. Public proxy restores estimates.',
        'limits':['Normal singles binding only. G-Max, underwater/Dive, suppression and broader ability/held-item interactions remain outside this batch.',
            'Natural duration is validated as a range, not equal RNG draws; eight-turn parity uses native deterministic Grip Claw.',
            'Exact residual component only, not exact ordinary hit damage. Existing combined poison/burn/held-item ordering limits remain; Leftovers before binding is tested.',
            'Ghost and Shed Shell bypass the binding block; other escape calculations retain the existing wild ruleset.',
            'No new randomlock rules, canonical classification/item pool edits, images, export or GitHub publication. Nine preexisting DATA V3 failures remain.']})
    (ROOT/'docs/current/BINDING_MOVES.json').write_text(json.dumps(focal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('BINDING_SUMMARY PASS: 10 admitted; 1883 focal checks; 5910 reference matches; 612 available / 238 mechanics pending')


if __name__=='__main__':main()
