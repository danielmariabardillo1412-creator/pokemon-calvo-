"""Verify healing/server/GPU/reference evidence without changing source datasets."""
import json
import re
from collections import Counter
from summarize_fixed_damage_moves import ROOT, KNOWN_DATA_FAILURES, read, sha, protected_sources

FOLDER = ROOT / '.godot/healing_checks'
REFERENCE = ROOT / '.godot/battle_reference/latest'
EXPECTED_CHANGES = {
    'modules/battle/application/healing_move_rules.gd',
    'modules/battle/application/live_move_profile.gd',
    'modules/battle/application/turn_executor.gd',
    'modules/status/application/status_system.gd',
    'modules/status/domain/battle_status_state.gd',
    'modules/battle/presentation/live_move_event_text.gd',
}


def main():
    focal = read(FOLDER / 'gpu.json')
    live = read(ROOT / 'docs/current/LIVE_MOVE_INTEGRATION.json')
    reference = read(REFERENCE / 'report.json')
    assert focal['status'] == 'PASS' and focal['gpu'] and focal['cases'] == 192
    assert len(focal['moves']) == 8 and len(focal['captures']) == 16
    assert len(focal['visual_samples']) == 8
    assert all(x['player_hp'] == x['displayed_player_hp'] and x['enemy_hp'] == x['displayed_enemy_hp'] for x in focal['visual_samples'])
    assert live['validation_status'] == 'PASS' and live['admitted_move_count'] == 620
    assert live['not_implemented_or_partial_count'] == 230
    for report in (focal, live):
        for path, expected in report['source_sha256'].items(): assert sha(ROOT / path) == expected, path
    for capture in focal['captures']: assert sha(ROOT / capture['path']) == capture['sha256']
    assert reference['status'] == 'PASS' and reference['counts'] == {'MATCH': 7284, 'MISMATCH': 0, 'NOT_COMPARABLE': 0}
    assert reference['protected_sources']['unchanged']
    for name, expected in reference['tool_sha256'].items(): assert sha(ROOT / 'tools/battle_reference' / name) == expected, name
    for name, expected in reference['observations_sha256'].items(): assert sha(REFERENCE / name) == expected, name
    assert sha(REFERENCE / 'manifest.json') == reference['manifest_sha256']
    cases = read(REFERENCE / 'manifest.json')['cases']
    families = dict(Counter(c['family'] for c in cases))
    assert families == {'stat_stages': 600, 'fixed_damage': 1332, 'variable_power': 3018, 'binding': 960, 'healing': 1374}
    controls = read(ROOT / '.godot/battle_reference/negative_controls/checks.json')
    assert controls['status'] == 'PASS' and controls['checks'] == 3
    unit_log = (ROOT / '.godot/battle_reference/self_test.log').read_text(encoding='utf-8-sig')
    assert 'Ran 42 tests' in unit_log and '\nOK' in unit_log
    for name, marker in [('gpu.log', 'HEALING_MOVES PASS'), ('live_gpu.log', 'LIVE_MOVE_INTEGRATION PASS'),
                         ('core.log', '472 PASS / 0 FAIL'), ('trainer.log', '628 PASS / 0 FAIL'),
                         ('playback.log', '"passed":20809'), ('data_v3.log', '624 PASS / 9 FAIL')]:
        text = (FOLDER / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'SCRIPT ERROR' not in text, name
        if name in ('gpu.log', 'live_gpu.log'): assert 'ERROR:' not in text
        if name == 'data_v3.log': assert set(re.findall(r'^ERROR: FAIL\s+(\S+)', text, re.M)) == KNOWN_DATA_FAILURES
    before, after = read(FOLDER / 'before.json'), protected_sources()
    changed = {p for p in before.keys() | after.keys() if before.get(p) != after.get(p)}
    assert changed == EXPECTED_CHANGES, changed
    guards = {p: after[p] for p in after if p not in EXPECTED_CHANGES}
    evidence = [REFERENCE / name for name in ('report.json', 'manifest.json', 'reference.json', 'godot.json')]
    evidence += [FOLDER / name for name in ('gpu.json', 'gpu.log', 'live_gpu.log', 'core.log', 'trainer.log', 'playback.log', 'data_v3.log', 'before.json')]
    evidence += [ROOT / '.godot/battle_reference/self_test.log', ROOT / '.godot/battle_reference/negative_controls/checks.json']
    evidence += [ROOT / 'docs/current/LIVE_MOVE_INTEGRATION.json']
    source_hashes = dict(focal['source_sha256'])
    source_hashes.update({p: after[p] for p in sorted(EXPECTED_CHANGES)})
    helper = {key: reference[key] for key in ('reference', 'engine_versions', 'counts', 'cases', 'comparison_fields', 'limits', 'batches', 'elapsed_seconds', 'protected_sources', 'tool_sha256')}
    helper.update({'schema_version': 1, 'status': 'LOCAL_BATTLE_REFERENCE_VALIDATED', 'date': '2026-10-26',
                   'scope': 'Actual authoritative Godot server vs pinned Showdown; stages/fixed damage/variable power/binding/healing',
                   'cases_by_family': families, 'self_tests': {'status': 'PASS', 'unit_tests': 42, 'real_adapter_negative_controls': 3},
                   'evidence': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence if 'battle_reference' in p.parts},
                   'documentation': 'tools/battle_reference/README.md', 'credits': 'tools/battle_reference/THIRD_PARTY_NOTICES.md', 'github_publication_performed': False})
    (ROOT / 'docs/current/BATTLE_REFERENCE_VALIDATION.json').write_text(json.dumps(helper, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    output = {
        'status': 'PASS', 'date': '2026-10-26', 'scope': 'Eight live singles healing/cure moves; no doubles rollout',
        'newly_admitted': focal['moves'], 'admitted': 620, 'unavailable': 299, 'mechanics_pending': 230,
        'pending_classifications': {'DATA_ONLY': 162, 'PARTIAL_RUNTIME': 57, 'UNSUPPORTED': 11},
        'focal_checks': focal['checks'], 'focal_cases': focal['cases'], 'captures': focal['captures'],
        'visual_samples': focal['visual_samples'], 'visual_review': '16 current captures inspected as two contact sheets; native clips and final HUD; no source art substitution',
        'live_checks': live.get('checks', live.get('validation_checks')), 'live_report': 'docs/current/LIVE_MOVE_INTEGRATION.json',
        'reference_counts': reference['counts'], 'reference_families': families,
        'reference_manifest_sha256': reference['manifest_sha256'], 'reference_tool_sha256': reference['tool_sha256'],
        'negative_controls': {'unit_tests': 42, 'real_adapter_controls': 3, 'status': 'PASS'},
        'regressions': {'core': 472, 'playback': 20809, 'trainer_corpus': 628, 'data_v3_pass': 624, 'data_v3_known_failures': sorted(KNOWN_DATA_FAILURES)},
        'rules': [
            'Party cures reach living reserves; reserve abilities are inactive and do not stop modern Heal Bell/Aromatherapy.',
            'Life Dew, Jungle Healing and Lunar Blessing heal only active user in singles, not reserves; last two also cure persistent status.',
            'Life Dew quarter HP rounds exact halves up; Jungle Healing/Lunar Blessing use native modifier rounding, exact halves down.',
            'Refresh only cures burn/paralysis/poison/toxic. Persistent cures reset legacy status IDs, sleep counter, toxic counter and Rest marker.',
            'Purify cures target first; only success heals source by ceil(maxHP/2), including reflection, substitute/Infiltrator and Good as Gold boundaries.',
            'Rest fails at full HP or with sleep-blocking abilities; otherwise replaces status with fixed two-action sleep without sleep RNG. Early Bird reduces lost actions to one.',
            'Rest marker is additive in status snapshots, omitted when false; persists through switching/save/load and is cleared by party cure. Legacy/default wire format and ordinary sleep remain unchanged.',
            'All new status moves bypass opposing accuracy/evasion and consume PP for attempted effects; no canonical data changes.'
        ],
        'source_sha256': source_hashes, 'protected_sources_changed': sorted(changed),
        'evidence': {p.relative_to(ROOT).as_posix(): sha(p) for p in evidence},
        'protected_sources_unchanged': guards, 'art_substitutions': [],
        'references': [
            {'project': 'Pokemon Showdown / @pkmn/sim', 'version': '0.10.11', 'url': 'https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts',
             'use': 'Independent execution of native effects; local code written for our server; existing tool NOTICE retained.'},
            {'project': 'Downloaded Godot/Ruby sources', 'inventory': 'docs/current/EXTERNAL_SOURCE_AUDIT.json',
             'use': 'Source investigation only; no code with unresolved or incompatible terms copied into runtime.'}
        ],
        'limits': [
            'Synthetic singles coverage, not certification of all ability/item/competitive interactions or all admitted moves.',
            'The shared status/ability engine keeps its existing broader limits; general sleep AI estimates, ability suppression/Mold Breaker, new terrain restrictions, Snatch and doubles remain separate work.',
            'Heal Block/protect markers guard already queued effects; their casting/selection systems are not enabled by this family.',
            'Rest sleep duration is checked across real server turns/save/replay/switching, including Early Bird. External family compares exact HP/status/PP/reserves for the initial move, not full sleep lifecycle.',
            'AI forks execute these effects and retain owned Rest snapshots; no new trainer strategy or opponent private sleep clock is exposed.',
            'Canonical data, art/manifests, frozen renderer, content policy, F: library and GitHub are unchanged.'
        ],
    }
    (ROOT / 'docs/current/HEALING_MOVES.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('HEALING_SUMMARY PASS: eight admitted; 192 cases; 16 GPU captures; 7284 external matches; frozen guards intact')


if __name__ == '__main__':
    main()
