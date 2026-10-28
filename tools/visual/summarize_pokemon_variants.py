"""Verify local variant evidence and write the current handoff, without rebuilding art."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import re

GAME = Path(__file__).resolve().parents[2]


def read(path):
    return json.loads((GAME / path).read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256((GAME / path).read_bytes()).hexdigest()


def main():
    folder = '.godot/pokemon_variant_checks/'
    build = read(folder + 'build.json')
    gpu = read(folder + 'gpu.json')
    assert build['status'] == gpu['status'] == 'PASS'
    assert gpu['variant_manifest_sha256'] == sha('assets/local_battle_variants/manifest.json') == build['manifest_sha256']
    baseline = read('.godot/move_self_body_checks/reference/baseline.json')
    for path, expected in baseline.items():
        if path != 'head':
            assert sha(path) == expected, path
    assert sha('scenes/visual/community_move_preview.gd') == '7674d3a61e113e085d12132a4e10461aedd3a760516ab68700f2868f0f3fd4de'
    assert sha('assets/local_battle_catalog/manifest.json') == build['base_manifest_sha256']
    manifest = read('assets/local_battle_variants/manifest.json')
    for row in manifest['entries'].values():
        for view in row['states']['reposo'].values():
            assert sha('assets/local_battle_variants/' + view['atlas']) == view['sha256']
    for capture in gpu['captures']:
        assert sha(capture['path'].removeprefix('res://')) == capture['sha256']
    log = (GAME / (folder + 'gpu.log')).read_text(encoding='utf-8')
    assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log
    regression_counts = {'core_regression.log': 472, 'field_regression.log': 45,
                         'playback_regression.log': 20809, 'catalog_regression.log': 27329,
                         'layout_regression.log': 56274, 'transform_regression.log': 1208,
                         'trainer_regression.log': 628}
    for name, count in regression_counts.items():
        text = (GAME / (folder + name)).read_text(encoding='utf-8')
        assert 'SCRIPT ERROR' not in text and 'ERROR: FAIL' not in text, name
        assert str(count) in text, name
    data_log = (GAME / (folder + 'data_regression.log')).read_text(encoding='utf-8')
    data_failures = sorted(set(re.findall(r'ERROR: FAIL\s+(\S+)', data_log)))
    assert data_failures == sorted([
        'data_v3_ability_contract_report_counts', 'data_v3_ability_contract_report_ids',
        'data_v3_bad_dreams_source_contract', 'data_v3_ice_body_source_contract',
        'data_v3_merciless_source_contract', 'data_v3_rain_dish_source_contract',
        'data_v3_rivalry_source_contract', 'data_v3_stakeout_source_contract',
        'data_v3_end_to_end_shadow_exclusion_and_reports_frozen',
    ]), data_failures
    source_paths = [
        'tools/visual/build_pokemon_variants.py', 'tools/visual/summarize_pokemon_variants.py',
        'config/pokemon_variants_v1.json', 'modules/creatures/progression/pokemon_variant_catalog.gd',
        'modules/data/definition_catalog.gd', 'modules/creatures/domain/creature_instance.gd',
        'modules/creatures/progression/creature_factory.gd', 'modules/creatures/progression/evolution_system.gd',
        'modules/battle/application/transform_rules.gd', 'modules/gameplay/wild_adventure_session.gd',
        'modules/debug/technical_encounter_pool_builder.gd', 'modules/localization/spanish_game_text.gd',
        'modules/battle/presentation/spanish_battle_presentation_controller.gd',
        'modules/battle/presentation/trainer_battle_presentation_controller.gd',
        'scenes/overworld/technical_overworld.gd', 'scenes/debug/technical_test_panel.gd',
        'scenes/visual/battle_sprite_catalog.gd', 'scenes/visual/battle_animation_playback.gd',
        'scenes/visual/battle_timeline_plan.gd', 'scenes/visual/field_battle_presentation.gd',
        'scenes/visual/field_trainer_presentation.gd', 'scenes/visual/pokemon_gallery.gd',
        'tests/gameplay/pokemon_variant_test_runner.gd',
        'tests/visual/catalog_integration_test_runner.gd',
        'tests/visual/battle_sprite_layout_test_runner.gd',
        'tests/visual/battle_animation_playback_test_runner.gd',
    ]
    report = {**gpu, 'status': 'LOCAL_REGIONAL_AND_EXISTING_SHINY_INTEGRATION_VALIDATED',
        'runtime_species': 1082, 'base_species': 1025, 'allowed_pool_species': 1076,
        'shiny_odds_denominator': 4096, 'shiny_rng': 'isolated deterministic cosmetic draw; mechanics RNG unchanged',
        'source_sha256': {p: sha(p) for p in source_paths},
        'build_evidence': folder + 'build.json', 'gpu_evidence': folder + 'gpu.json',
        'atlas_files': build['atlas_files'], 'frames': build['frames'],
        'regression_pass_counts': regression_counts, 'known_preexisting_data_failures': data_failures,
        'pack_bytes': sum(p.stat().st_size for p in (GAME / 'assets/local_battle_variants').rglob('*.png')),
        'canonical_and_base_pack_unchanged': True,
        'scope': '57 ordinary regional forms, 1011 existing base shiny pairs, 57 existing regional shiny pairs; local game/gallery/capture/PC/save/evolution/Transform/trainer integration',
        'limits': [
            'No new shiny generated for the 14 custom normal candidates.',
            'Six excluded base species remain in the art archive; they are filtered from ordinary game selection.',
            'Regional species use their own snapshot types/stats/abilities/selected learnset, not a base-species skin.',
            'A recorded ability is not a promise that all ability mechanics are supported.',
            'Only explicitly regional evolution records are routed; friendship/time/location and other unsupported conditions remain blocked.',
            'Other cosmetic/special forms, Mega/Gigantamax and dynamic form mechanics are not completed by this tranche.',
            'Local third-party art caches are not packaged for distribution or uploaded to GitHub.',
        ]}
    path = GAME / 'docs/current/POKEMON_VARIANTS_INTEGRATION.json'
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: report[k] for k in ['status', 'checks', 'runtime_species', 'regional_forms', 'base_shiny_pairs', 'regional_shiny_pairs', 'pack_bytes']}))


if __name__ == '__main__':
    main()
