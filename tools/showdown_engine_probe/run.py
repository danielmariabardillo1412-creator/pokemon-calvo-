"""Reproduce the isolated Showdown-as-backend feasibility experiment."""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import shutil
import subprocess
import sys
from collections import Counter

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUTPUT = ROOT / '.godot/showdown_engine_probe'
sys.path.insert(0, str(ROOT / 'tools/battle_reference'))
from run import protected_sources


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def execute(arguments, name):
    with (OUTPUT / name).open('w', encoding='utf-8') as log:
        result = subprocess.run(arguments, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=120)
    if result.returncode: raise RuntimeError(f'Probe failed: {name} (exit {result.returncode})')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--node', default=shutil.which('node') or 'D:/Herramientas/NodeJS/node.exe')
    parser.add_argument('--godot', default=shutil.which('godot') or 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe')
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    before = protected_sources()
    (OUTPUT / 'sources_before.json').write_text(json.dumps(before, indent=2) + '\n', encoding='utf-8')
    report = {'status': 'RUNNING', 'date': '2026-10-26'}
    try:
        execute([args.node, str(HERE / 'probe_tests.cjs')], 'node.log')
        execute([args.godot, '--headless', '--path', str(ROOT), '--script', str(HERE / 'godot_probe.gd'), '--', args.node], 'godot.log')
        node, godot, catalog, smoke = [read(OUTPUT / name) for name in ('node_tests.json', 'godot_tests.json', 'catalog.json', 'native_smoke.json')]
        assert node['status'] == godot['status'] == 'PASS'
        assert smoke['counts'] == {'EXECUTED_AND_SERIALIZED': 2496}
        assert catalog['species']['total'] == catalog['species']['matched'] == 1082
        assert not catalog['species']['data_differences']
        assert catalog['moves']['total'] == catalog['moves']['matched'] == 919
        assert sum('Generation 8 native max_' in x['name'] and x['status'] == 'PASS' for x in node['checks']) == 19
        assert not godot['worker_stderr']
        for log_name in ('node.log', 'godot.log'):
            text = (OUTPUT / log_name).read_text(encoding='utf-8')
            assert 'SCRIPT ERROR' not in text and 'ERROR:' not in text
        ability_analysis = {'status': 'not_fetched_in_this_run'}
        source = OUTPUT / 'abilities_source.csv'
        if source.is_file():
            with source.open(encoding='utf-8') as stream:
                rows = {r['identifier'].replace('-', '_'): r for r in csv.DictReader(stream)}
            missing = catalog['abilities']['missing']
            ability_analysis = {'source': read(OUTPUT / 'abilities_source.json'), 'sha256': sha(source),
                'non_main_series_missing': [r['id'] for r in missing if rows.get(r['id'], {}).get('is_main_series') == '0'],
                'main_series_or_unknown_missing': [r['id'] for r in missing if rows.get(r['id'], {}).get('is_main_series') != '0']}
        runtime = ROOT / '.godot/battle_reference/runtime/node_modules'
        runtime_bytes = sum(p.stat().st_size for p in runtime.rglob('*') if p.is_file())
        critical = [ROOT / 'tools/battle_reference/package-lock.json', ROOT / 'tools/battle_reference/THIRD_PARTY_NOTICES.md']
        critical += [ROOT / 'modules/battle/backends/showdown/native_engine.cjs', ROOT / 'modules/battle/backends/showdown/pipe_client.gd']
        critical += [runtime / '@pkmn/sim' / p for p in ('package.json', 'build/cjs/sim/battle.js', 'build/cjs/sim/state.js', 'build/cjs/data/moves.js', 'build/cjs/data/abilities.js', 'build/cjs/data/items.js', 'build/cjs/data/pokedex.js')]
        report.update({
            'status': 'PASS', 'decision': 'GO_FOR_ISOLATED_BACKEND_INTEGRATION_NOT_PRODUCTION_REPLACEMENT',
            'production_backend': 'unchanged AuthoritativeBattleServer; 620 admitted/230 mechanics pending',
            'reference': {'package': '@pkmn/sim', 'version': '0.10.11', 'license': 'MIT; preserve existing THIRD_PARTY_NOTICES',
                          'urls': ['https://github.com/pkmn/ps/tree/main/sim', 'https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md']},
            'node_assertions': sum(x['status'] == 'PASS' for x in node['checks']),
            'godot_assertions': len(godot['checks']), 'native_smoke': smoke['counts'],
            'smoke_moves': len({x['id'] for x in smoke['cases']}), 'native_protocol_kinds_observed': len(smoke['protocol_kinds']),
            'smoke_context_failures': sum(x.get('failed_in_fixture', False) for x in smoke['cases']),
            'coverage_caveat': 'First-turn execution and native serialization only; an effect can legitimately fail in a generic fixture. No claim of independent verification or complete Godot event/policy support.',
            'catalog': {k: {key: value for key, value in v.items() if key != 'entries'} for k, v in catalog.items() if isinstance(v, dict)},
            'ability_provenance': ability_analysis,
            'integration': {'transport': godot['transport'], 'godot': godot['godot'], 'rpc_median_ms': godot['rpc_median_ms'],
                'measurements_not_guarantees': [x for x in node['checks'] if x['status'] == 'MEASUREMENT'],
                'presentation': godot['presentation_probe'], 'local_dependency_bytes': runtime_bytes,
                'node_executable_bytes': Path(args.node).stat().st_size},
            'reuse_assessment': {
                'native_combat': 'Strong candidate: damage/type rules, status/stages, move effects, abilities, held items, weather/terrain/hazards, switches/forms and native generation-specific gimmicks.',
                'species_types_stats_natures_weights': 'Reusable data/calculation; actual CreatureFactory DTO imports tested, 1082 base/region rows match base stats/types after explicit aliases. Weights are in catalog entries.',
                'items': '530 matching item entries. Held-item battle behavior is reusable. Generic item descriptions are not bag-use implementations.',
                'capture_bag_escape': 'Not supplied as adventure commands. Native normal-turn pass is rejected; reaction/failed capture/bag actions need a deliberate extension. Preserve our existing campaign modules.',
                'progression_evolution_learnsets': 'Species/learnset/evolution data can be reference; simulator does not run campaign XP, levelling, shops, inventory, PC or level-slot randomization.',
                'trainer_ai': 'Native snapshots and batches support planning technically; keep our professional policy/memory and feed sanitized plausible worlds. Never use raw authoritative opponent state for real trainer search.',
                'multiplayer': 'Deterministic choice/request/protocol model can support future authoritative battles. No coliseum/lobby/account/network integration provided by this probe.',
                'art_world': 'Keep our existing Godot maps, art and reviewed move clips. Existing timeline accepts the sampled translated native turn; complete event translation remains work.'},
            'required_before_production': [
                'Define a versioned opt-in backend facade around choices, requests, native snapshot and persistent creature reconciliation; keep legacy in-flight saves on their backend.',
                'Translate the shared protocol/event classes, explicitly reject or flag unknown effects and keep trusted visual state separate from AI/player views.',
                'Preserve HP/PP/status/items/instance identity and temporary form/Dynamax overlays without corrupting PC/campaign data. Legacy sleep/toxic clocks require explicit conversion tests.',
                'Choose a versioned generation/rules profile: native Gen9 rejects Dynamax, while all 19 generated Max moves pass in native Gen8. Hybrid rules are not silently enabled.',
                'Resolve 60 move-field differences (mostly generated Z variants; six other rows), generic Embody Aspect form mapping and external held items such as Smoke Ball.',
                'Adapt failed capture/bag/escape reactions and maintain finite inventory and randomlock/permanent death rules outside the simulator.',
                'Adapt existing trainer observation/action-space/plausible-world/fork boundaries and benchmark actual search workloads, not just the 64-branch experiment.',
                'Package a portable Node/helper or separately evaluate native PSVM/GDExtension; preserve licenses, child lifecycle, timeouts and offline startup. Current experiment uses local development runtimes.',
                'Use integration tests/invariants and external expectations. Comparing the adopted simulator against itself would not independently certify its rules.'
            ],
            'alternatives': [{'project': 'PSVM', 'url': 'https://github.com/ethanl21/psvm',
                'assessment': 'README describes work in progress and Godot example planned. Native option for later packaging; not built/tested here, no ready-made Godot integration assumed.'},
                {'project': 'Downloaded Godot/Ruby engines', 'assessment': 'Retained as references. Their generation limits/licensing/dependency issues make them weaker replacement candidates than this tested simulator route.'}],
            'credits': 'tools/battle_reference/THIRD_PARTY_NOTICES.md',
            'probe_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in HERE.iterdir() if p.suffix in ('.cjs', '.gd', '.py', '.md')},
            'runtime_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for p in critical},
            'evidence': {p.relative_to(ROOT).as_posix(): sha(p) for p in OUTPUT.iterdir() if p.name in ('node_tests.json', 'godot_tests.json', 'catalog.json', 'native_smoke.json', 'node.log', 'godot.log')},
        })
    except Exception as error:
        report.update(status='ERROR', error=f'{type(error).__name__}: {error}')
    finally:
        after = protected_sources()
        changed = sorted(p for p in before.keys() | after.keys() if before.get(p) != after.get(p))
        report['protected_sources'] = {'count': len(before), 'unchanged': not changed, 'changed': changed}
        if changed: report.update(status='ERROR', error='Protected production sources changed during isolated probe')
        (OUTPUT / 'sources_after.json').write_text(json.dumps(after, indent=2) + '\n', encoding='utf-8')
        (OUTPUT / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        (ROOT / 'docs/current/SHOWDOWN_BACKEND_FEASIBILITY.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('SHOWDOWN_BACKEND_PROBE', report['status'], report.get('decision', report.get('error')))
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
