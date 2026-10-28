"""Close the 112 held/berry fixture review; preserve explicit unsupported systems."""
import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/item_verification_v3'
DOC = ROOT / 'docs/current'
ADAPTER = 'modules/battle/backends/showdown/event_adapter.gd'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def protected():
    paths = list((ROOT / 'modules').rglob('*.gd')) + list((ROOT / 'modules').rglob('*.cjs'))
    paths += list((ROOT / 'modules').rglob('*.json'))
    connection = read(DOC / 'ITEM_CONNECTIONS_V1.json')
    paths += [ROOT / p for p in connection['data_policy_and_art_manifest_unchanged']]
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in paths}


def command(args, name):
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    print('ITEM_VERIFY_V3_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as handle:
        result = subprocess.run(args, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT,
                                timeout=500, startupinfo=startup)
    log = (OUT / name).read_text(encoding='utf-8-sig', errors='replace')
    assert result.returncode == 0 and 'SCRIPT ERROR' not in log and 'ERROR:' not in log, name
    print(log.strip().splitlines()[-1], flush=True)


def summarize():
    prior = read(DOC / 'ITEM_VERIFICATION_V2.json')
    # V2 is historical evidence. Its sources still match except the documented adapter repair.
    assert all(p == ADAPTER or sha(ROOT / p) == h for p, h in prior['sources_sha256'].items())
    assert all(sha(ROOT / p) == h for p, h in prior['protected_data_policy_art'].items())
    assert protected() == read(OUT / 'run_protected.json'), 'Runtime/data changed during verification'
    initial_path = OUT / 'protected_before.json'
    initial = read(initial_path) if initial_path.exists() else {ADAPTER: prior['sources_sha256'][ADAPTER]}
    changes = {p: {'before': h, 'after': sha(ROOT / p)} for p, h in initial.items() if sha(ROOT / p) != h}
    assert set(changes).issubset({ADAPTER}), changes
    native = read(OUT / 'native.json')
    godot = read(OUT / 'godot.json')
    deps = read(OUT / 'dependencies.json')
    cases = read(OUT / 'cases.json')
    assert not godot['errors'] and godot['pending_protocol_cases'] == 0
    assert all(r['status'] == 'NATIVE_SCENARIO_PASS' for r in native['results'])
    assert all(r['status'] == 'PASS' for r in native['branchChecks'])
    assert all(r['status'].endswith('_PASS') for r in godot['results'])
    case_ids = {r['case_id'] for r in native['results']}
    assert len(case_ids) == len(native['results']) == len(godot['results']) == len(cases)
    assert case_ids == {r['case_id'] for r in godot['results']} == {r['case_id'] for r in cases}
    by_id = defaultdict(list)
    for r in godot['results']:
        by_id[r['id']].append(r)
    verified = set(by_id)
    assert len(verified) == 65 and all(any(r.get('live_ipc') for r in group) for group in by_id.values())
    assert all(any(r.get('live_ipc') and r.get('activated_rng_branch') for r in by_id[b['id']]) for b in native['branchChecks'])
    pending = {r['id']: r for r in deps['pending']}
    assert len(pending) == 47 and verified.isdisjoint(pending)
    assert verified | set(pending) == set(deps['target_ids'])
    regression = read(OUT / 'v2_projection.json')
    assert not regression['errors'] and regression['pending_protocol_cases'] == 0
    pilot = read(ROOT / '.godot/item_audit_v1/held_godot.json')
    assert pilot['status'] == 'PASS'
    per_item = []
    matrix = []
    for previous in prior['rows']:
        row = dict(previous)
        item_id = row['id']
        row['v3_scenarios'] = len(by_id[item_id])
        row['v3_dependency_group'] = pending.get(item_id, {}).get('group', '')
        if item_id in verified:
            row['battle_effect_status'] = 'HELD_EFFECT_SCENARIOS_VERIFIED_NOT_EXHAUSTIVE'
            row['live_ipc_case'] = True
            per_item.append({'id': item_id, 'name_es': row['name_es'], 'family': row['family'],
                             'status': 'NATIVE_GODOT_AND_LIVE_IPC_PASS', 'scenarios': len(by_id[item_id])})
        elif item_id in pending:
            row['battle_effect_status'] = 'EXPLICIT_DEPENDENCY_OR_NONBATTLE_CONTEXT_PENDING'
            per_item.append(dict(pending[item_id], status='DEPENDENCY_PENDING_NOT_PASS'))
        matrix.append(row)
    assert len(matrix) == 2222 and len(per_item) == 112
    all_verified = sum(r['battle_effect_status'] == 'HELD_EFFECT_SCENARIOS_VERIFIED_NOT_EXHAUSTIVE' for r in matrix)
    assert all_verified == 189
    sources = ['tools/item_audit/held_effect_sweep_v3.cjs', 'tools/item_audit/item_dependencies_v3.cjs',
               'tests/gameplay/item_effect_templates_v3.gd', 'tests/gameplay/item_effect_projection_v3.gd',
               'tools/item_audit/run_verification_v3.py', ADAPTER,
               'modules/battle/backends/showdown/native_engine.cjs',
               'modules/creatures/domain/creature_instance.gd', 'modules/inventory/field_item_service.gd',
               '.godot/battle_reference/runtime/node_modules/@pkmn/sim/package.json',
               '.godot/battle_reference/runtime/node_modules/@pkmn/sim/build/cjs/data/items.js']
    logs = {p.name: p.read_text(encoding='utf-8-sig', errors='replace').strip().splitlines()[-1]
            for p in OUT.glob('regression_*.log')}
    assert len(logs) == 7, logs
    evidence = ['native.json', 'cases.json', 'godot.json', 'dependencies.json', 'prototypes.json',
                'v2_projection.json', 'native.log', 'godot.log', 'v2_projection.log', 'pilot.log'] + sorted(logs)
    report = {
        'phase': 'ITEM_VERIFICATION_V3', 'date': '2026-10-28',
        'status': 'AVAILABLE_SCENARIOS_PASS_EXPLICIT_DEPENDENCIES_PENDING',
        'all_item_effects_complete': False, 'reviewed_target_ids': 112,
        'new_verified_ids': len(verified), 'new_verified_families': dict(Counter(r['family'] for r in per_item if r['id'] in verified)),
        'new_native_scenarios': len(cases), 'projected_steps': sum(len(r['steps']) for r in cases),
        'godot_checks': godot['checks'], 'live_ipc_ids': len(verified),
        'total_ids_with_bounded_effect_verification': all_verified,
        'protocol_pending_cases': godot['pending_protocol_cases'],
        'dependency_ids': len(pending), 'dependency_groups': deps['group_counts'],
        'remaining_other_native_context_ids': sum(r['battle_effect_status'] == 'SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING' for r in matrix),
        'battle_effect_status_counts': dict(Counter(r['battle_effect_status'] for r in matrix)),
        'rng_branch_checks': native['branchChecks'], 'runtime_changes': changes,
        'regressions': logs, 'v2_projection_checks_repeated': regression['checks'],
        'pilot_checks_repeated': pilot['checks'],
        'protected_data_policy_art': prior['protected_data_policy_art'],
        'sources_sha256': {p: sha(ROOT / p) for p in sources},
        'evidence_sha256': {name: sha(OUT / name) for name in evidence},
        'scope': 'Diagnostic isolated singles scenarios and controls, not exhaustive interactions, exact probability certification, all damage rounding, item eligibility, breeding or missing world systems. One live IPC case per item; every native case/step is projected.',
        'target_results': per_item, 'rows': matrix,
    }
    (DOC / 'ITEM_VERIFICATION_V3.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (DOC / 'ITEM_VERIFICATION_PENDING_V3.json').write_text(json.dumps({
        'reviewed_target_pending': deps['pending'], 'form_dependency_probes': deps['probes'],
        'other_system_groups': prior['pending']['missing_mechanic_or_bridge'],
        'other_native_contexts_not_reviewed_in_this_batch': [r['id'] for r in matrix if r['battle_effect_status'] == 'SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING'],
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (DOC / 'ITEM_VERIFICATION_V3.csv').open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(matrix[0])); writer.writeheader(); writer.writerows(matrix)
    status = read(DOC / 'ITEM_SYSTEM_CURRENT_STATUS.json')
    status.update(latest_report='docs/current/ITEM_VERIFICATION_V3.json', notes='docs/current/ITEM_VERIFICATION_V3.md',
                  full_item_matrix='docs/current/ITEM_VERIFICATION_V3.csv', latest_verification='ITEM_VERIFICATION_V3',
                  held_item_ids_with_verified_effect_scenarios=all_verified,
                  untested_native_contexts=report['remaining_other_native_context_ids'],
                  reviewed_held_and_berry_dependencies_pending=len(pending), verification_all_effects_complete=False,
                  next=['Outside-battle medicine and permanent training item bridges',
                        '26 species-form item routes and gender/infatuation/breeding contract',
                        '6 training berries and 14 food/contest/world-context berries',
                        'Special capture balls, legacy machine profile, conditional evolutions, Escape Rope/world systems',
                        'Other item families require their own mechanic/context review; 323 native-recognized IDs are not 323 failed held items'])
    (DOC / 'ITEM_SYSTEM_CURRENT_STATUS.json').write_text(json.dumps(status, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    note = f'''# Verificación de equipados y bayas V3 — 2026-10-28

Se cierra la clasificación de los **80 equipados y 32 bayas** que quedaron sin
escenario en V2. Esto no declara terminados todos los sistemas de objetos.

## Resultado comprobado

- **65 IDs adicionales**: 53 equipados y 12 bayas.
- **{len(cases)} escenarios nativos**, con controles sin objeto y semillas reproducibles.
- **{report['projected_steps']} transiciones** proyectadas a Godot y **{godot['checks']} comprobaciones**, sin errores ni mensajes de protocolo pendientes.
- **65 escenarios por IPC real**, uno por objeto, con hash final idéntico y sin mutación prematura del equipo de entrada. Las otras variantes se ejecutan y proyectan, pero no se anuncian como ejecuciones IPC independientes.
- Acumulado: **189 IDs con escenarios de efecto verificados**, conservando el alcance de V1/V2.

El lote cubre potenciadores de especie y tipo, objetos de defensa, peso y orden,
habilidades protegidas, semillas y terrenos, duración del clima, trampas y cambio,
críticos, precisión, curación, PP, consumo y transferencia. Incluye secuencias de
varios turnos para Transformación, Metrónomo, Garra Garfio, Muda Concha y Baya Lagro.

Las expectativas están declaradas en el verificador. Los controles mantienen la
misma semilla, especie y acciones salvo el objeto; el control de Muda Concha se
detiene antes de intentar un cambio que estaría prohibido. Preparar no publica
el turno; restaurar cada snapshot conserva su hash. Las plantillas proceden de
CreatureFactory y aíslan los efectos con habilidades vacías, salvo donde la
habilidad es precisamente el contexto probado. No son equipos legales de campaña.

Los ocho grupos probabilísticos usan semillas fijas y comprueban ambas ramas;
**no certifican sus porcentajes exactos**. Los potenciadores se contrastan por
dirección del daño y controles negativos, sin afirmar una segunda implementación
independiente de todos los redondeos. Tampoco se certifica cada interacción en
dobles, crianza, botín o tiendas.

## Corrección de conexión encontrada

Escudo Habilidad funcionaba en el motor nativo, pero su mensaje `-block` detenía
la publicación del turno en Godot. El adaptador reconoce ahora exclusivamente
`item: Ability Shield`, conserva el destinatario y publica ITEM_TRIGGERED con
motivo `ability_protected`. Un mensaje de bloqueo desconocido sigue rechazándose.
Se verifica el aviso, la protección de la habilidad y la repetición por IPC.

Es el único archivo de ejecución modificado en este lote. No se regeneran datos
ni se cambian vetos o imágenes. Los hashes de datos, políticas y
manifiesto artístico siguen coincidiendo con V2.

## 47 dependencias explícitas, sin PASS ficticio

| Grupo | IDs | Motivo |
| --- | ---: | --- |
| Formas de especie | 26 | 17 memorias de Silvally, 4 discos de Genesect, 3 máscaras de Ogerpon y Espada/Escudo Oxidados necesitan una ruta de forma y proyección válida. |
| Entrenamiento fuera del combate | 6 | Bayas de reducción de EV/amistad: falta conectar el cambio persistente al dueño real. |
| Comida, concursos u otro uso del mundo | 14 | Su uso no se certifica mediante un efecto pasivo de combate; requiere decidir y conectar su sistema. |
| Lazo Destino | 1 | Falta un contrato explícito de género para enamoramiento y un sistema de crianza. |

El catálogo canónico actual contiene las especies base de esas 26 rutas, sin las
formas específicas requeridas. Las sondas de inicio del motor muestran también
por qué no basta con poner el objeto: los discos/memorias/máscaras no sustituyen
la ruta de forma; los objetos oxidados sí producen una forma coronada que falta
en el catálogo/proyección. Esto no equivale a que falten sus dibujos, ni autoriza
a descartarlos del contenido. Los IDs y motivos están en el registro pendiente.

Las otras familias conservan sus límites previos: medicinas fuera del combate,
bolas condicionales, máquinas antiguas, evoluciones condicionadas y sistemas de
mundo. Los **323 otros IDs reconocidos por el motor** que aún requieren un
contexto propio no son 323 equipados fallidos ni forman parte de estos 112.

## Regresiones y reproducción

Se repiten la proyección V2 (368 casos), el piloto anterior, medicina de combate,
inventario/captura, campo nativo, guardado, guardado adversarial, política de
selección y conexiones de mochila/MT/evolución. No se ha cambiado la interfaz;
este lote no añade una nueva certificación artística o de GPU.

```text
python tools/item_audit/run_verification_v3.py
```

El proceso es secuencial y no publica un informe nuevo ante un fallo. La matriz
CSV/JSON conserva los 2.222 IDs y separa uso, transferencia y efecto; el informe
guarda hashes de fuentes y evidencia. `ITEM_VERIFICATION_PENDING_V3.json` conserva
los 47 motivos y los demás sistemas pendientes. `ITEM_SYSTEM_CURRENT_STATUS.json`
apunta a este estado, manteniendo `all_item_effects_certified: false`.
'''
    (DOC / 'ITEM_VERIFICATION_V3.md').write_text(note, encoding='utf-8')
    print(json.dumps({k: report[k] for k in ['status', 'new_verified_ids', 'new_native_scenarios', 'projected_steps', 'godot_checks', 'dependency_ids', 'dependency_groups', 'total_ids_with_bounded_effect_verification']}, ensure_ascii=True))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--summarize', action='store_true', help='Publish complete matching evidence already produced by the default run.')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if not args.summarize:
        (OUT / 'run_protected.json').write_text(json.dumps(protected(), indent=2), encoding='utf-8')
        godot = os.environ.get('GODOT_BIN') or shutil.which('godot') or r'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
        node = shutil.which('node') or r'D:\Herramientas\NodeJS\node.exe'
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_effect_templates_v3.gd'], 'export.log')
        command([node, 'tools/item_audit/held_effect_sweep_v3.cjs'], 'native.log')
        command([node, 'tools/item_audit/item_dependencies_v3.cjs'], 'dependencies.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_effect_projection_v3.gd'], 'godot.log')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_effect_projection_v2.gd'], 'v2_projection.log')
        shutil.copyfile(ROOT / '.godot/item_verification_v2/godot.json', OUT / 'v2_projection.json')
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_held_pilot_test_runner.gd'], 'pilot.log')
        for name in ['showdown_medicine', 'item_existing_groups_v2', 'field_native', 'savegame_v2',
                     'savegame_v2_adversarial', 'item_selection_policy', 'item_connections']:
            script = name + ('.gd' if name == 'item_existing_groups_v2' else '_test_runner.gd')
            command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/' + script], 'regression_' + name + '.log')
    summarize()


if __name__ == '__main__':
    main()
