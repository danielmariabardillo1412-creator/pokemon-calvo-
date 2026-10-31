"""Verify real field item mutations, save/load and native hand-off before reporting."""
import argparse
from collections import Counter
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.godot/item_field_v4'
DOC = ROOT / 'docs/current'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(args, name):
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    print('ITEM_FIELD_V4_STAGE', name, flush=True)
    with (OUT / name).open('w', encoding='utf-8') as f:
        result = subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT,
                                timeout=300, startupinfo=startup)
    log = (OUT / name).read_text(encoding='utf-8-sig', errors='replace')
    assert result.returncode == 0 and 'SCRIPT ERROR' not in log and 'ERROR:' not in log, name
    print(log.strip().splitlines()[-1], flush=True)


def summarize():
    previous = read(DOC / 'ITEM_VERIFICATION_V3.json')
    assert all(sha(ROOT / p) == h for p, h in previous['protected_data_policy_art'].items())
    original = OUT / 'before.json'
    if original.exists():
        changed = {p for p, h in read(original).items() if sha(ROOT / p) != h}
        assert changed.issubset({'modules/inventory/field_item_service.gd', 'scenes/visual/field_item_bag.gd'}), changed
    medicine = read(ROOT / 'modules/inventory/battle_medicine_profile.json')['items']
    fixture = read(ROOT / 'tests/fixtures/item_field_v4/reference_contract.json')
    training = {'pomeg_berry', 'kelpsy_berry', 'qualot_berry', 'hondew_berry', 'grepa_berry', 'tamato_berry'}
    headless, gpu = read(OUT / 'godot.json'), read(OUT / 'gpu.json')
    for report in [headless, gpu]:
        assert report['status'] == 'PASS' and not report['errors']
        assert {r['id'] for r in report['rows']} == set(medicine) | training
        assert all(r['status'].endswith('_PASS') for r in report['rows'])
    assert gpu['gpu'] and not headless['gpu']
    matrix = []
    for previous_row in previous['rows']:
        row = dict(previous_row)
        if row['id'] in medicine:
            row['field_use_status'] = 'MEDICINE_FIELD_USE_OWNERSHIP_CONSUMPTION_AND_SAVE_VERIFIED'
        elif row['id'] in training:
            row['field_use_status'] = 'EV_BERRY_FIELD_USE_AND_BASE_FRIENDSHIP_VERIFIED_ORIGIN_BONUS_PENDING'
            row['battle_effect_status'] = 'NONBATTLE_TRAINING_FIELD_ROUTE_VERIFIED'
            row['v3_dependency_group'] = 'FIELD_TRAINING_BASE_ROUTE_CLOSED_ORIGIN_BONUSES_PENDING'
        matrix.append(row)
    pending = read(DOC / 'ITEM_VERIFICATION_PENDING_V3.json')
    pending['reviewed_target_pending'] = [r for r in pending['reviewed_target_pending'] if r['id'] not in training]
    assert len(pending['reviewed_target_pending']) == 41
    pending['field_friendship_origin_context_pending'] = {
        'items': sorted(training),
        'reason': 'CreatureInstance has no capture-ball or capture-map metadata. Base berry friendship and held Soothe Bell are connected; origin bonuses are not guessed or certified.'}
    for group in pending['other_system_groups']:
        if group['group'] == 'outside_battle_medicine':
            group['reason'] = '15 items from the shared modern medicine contract now work outside battle. Additional drinks, food, healing berries and other medicines require separate profiles/context.'
        elif group['group'] == 'training_items':
            group['reason'] = 'Six EV-lowering berries now have an owned-state route. Vitamins, feathers, XP, IV, nature and ability items remain separate pending routes.'
    regressions = {p.name: p.read_text(encoding='utf-8-sig', errors='replace').strip().splitlines()[-1]
                   for p in OUT.glob('regression_*.log')}
    assert len(regressions) == 7
    sources = ['modules/inventory/field_item_service.gd', 'modules/inventory/field_item_effects.gd',
               'modules/inventory/battle_medicine_profile.json', 'scenes/visual/field_item_bag.gd',
               'tests/gameplay/item_field_effects_v4.gd', 'tests/fixtures/item_field_v4/reference_contract.json',
               'tools/item_audit/run_field_v4.py']
    result = {
        'phase': 'ITEM_FIELD_V4', 'date': '2026-10-28',
        'status': 'CONNECTED_FIELD_SLICE_PASS_WITH_EXPLICIT_PENDING', 'all_item_effects_certified': False,
        'field_medicine_ids': sorted(medicine), 'field_ev_berry_ids': sorted(training),
        'new_field_item_ids': 21, 'headless_checks': headless['checks'], 'gpu_checks': gpu['checks'],
        'field_context_cases': len(headless['rows']), 'regressions': regressions,
        'reviewed_held_berry_core_dependencies_remaining': 41,
        'field_friendship_origin_context_pending': pending['field_friendship_origin_context_pending'],
        'reference': fixture, 'protected_data_policy_art': previous['protected_data_policy_art'],
        'sources_sha256': {p: sha(ROOT / p) for p in sources},
        'evidence_sha256': {p.name: sha(p) for p in OUT.glob('*.json') if p.name != 'before.json'},
        'field_use_status_counts': dict(Counter(r['field_use_status'] for r in matrix)),
        'limitations': ['15 shared-profile medicines, not every healing item in the raw catalog.',
                        'Training berries reject fainted targets and preserve a minimum of 1 HP on a maximum-HP reduction.',
                        'Base friendship and Soothe Bell only; missing origin bonuses remain explicit.',
                        'No new battle medicine rules, art, bans, randomlocke rules, or world mechanics are activated.'],
        'rows': matrix,
    }
    (DOC / 'ITEM_FIELD_V4.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (DOC / 'ITEM_PENDING_V4.json').write_text(json.dumps(pending, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    # .csv.txt remains a normal downloadable CSV, without Godot translation imports.
    with (DOC / 'ITEM_FIELD_V4.csv.txt').open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(matrix[0])); writer.writeheader(); writer.writerows(matrix)
    status = read(DOC / 'ITEM_SYSTEM_CURRENT_STATUS.json')
    status.update(latest_report='docs/current/ITEM_FIELD_V4.json', notes='docs/current/ITEM_FIELD_V4.md',
                  full_item_matrix='docs/current/ITEM_FIELD_V4.csv.txt', latest_verification='ITEM_FIELD_V4',
                  field_medicine_ids_verified=15, field_ev_berry_ids_verified=6,
                  reviewed_held_and_berry_dependencies_pending=41,
                  next=['Other field medicines and healing berries, vitamins and other permanent-training item routes',
                        'Capture-ball/map metadata before certifying origin friendship bonuses',
                        '26 species-form item routes and gender/infatuation/breeding contract',
                        '14 food/contest/world-context berries',
                        'Special capture balls, legacy machines, conditional evolutions and Escape Rope/world systems'])
    (DOC / 'ITEM_SYSTEM_CURRENT_STATUS.json').write_text(json.dumps(status, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (DOC / 'ITEM_FIELD_V4.md').write_text(f'''# Objetos fuera del combate V4 — 2026-10-28

Se conectan **21 IDs** a la mochila real de la demo existente: las **15 medicinas**
del contrato moderno ya utilizado en combate y **6 bayas reductoras de EV**.
No se cambia la selección de objetos permitidos ni se activan nuevas reglas de
randomlocke. No se modifica ningún dataset bruto, imagen o perfil de combate.

## Conexiones

- Poción, Superpoción, Hiperpoción, Poción Máxima y Restaurar Todo recuperan PS
  según el mismo contrato utilizado por el motor nativo.
- Antídoto, Antiquemar, Antihielo, Despertar, Antiparalizador y Cura Total curan
  sus estados; Restaurar Todo combina la recuperación con su curación.
- Éter y Éter Máximo exigen seleccionar un movimiento. Elixir y Elixir Máximo
  restauran los movimientos del Pokémon, respetando sus máximos actuales de PP.
- Grana, Algama, Ispero, Meluce, Uvav y Tamate reducen hasta 10 EV de la
  estadística correspondiente y aplican la amistad base con Campana Alivio.

El servicio prepara una copia, valida el dueño y consume exactamente una unidad
al publicar un efecto real. Un objeto sin efecto, un objetivo ajeno, la mochila
corrupta, una actividad que bloquee el campo o un Pokémon debilitado no gastan
el objeto ni alteran el estado. Los vetos se siguen comprobando antes de actuar.
La curación puede operar sobre el mismo dueño en equipo o PC; la UI muestra el
equipo. Las pruebas de bayas de este lote usan objetivos en el equipo.

Curar sueño retira también su reloj nativo compartido; así el guardado no conserva
un reloj huérfano. Las bayas recalculan las estadísticas usando el sistema
existente. Al bajar PS máximos conservan el déficit con un mínimo de 1 PS para un
objetivo vivo. No se provoca un debilitamiento ni se revive a un Pokémon.

La mochila muestra PS actuales/máximos, ofrece selección de PP y mantiene visible
el objeto seleccionado después de refrescar la lista. Las MT conservan su
selección explícita de sustitución.

## Evidencia

- Sin ventana: **{headless['checks']} comprobaciones, PASS**.
- Con GPU: **{gpu['checks']} comprobaciones, PASS**.
- **{len(headless['rows'])} contextos positivos registrados** entre medicinas en equipo/PC y
  bayas con distintos EV/amistad. Las pruebas negativas y de guardado son
  comprobaciones adicionales, no IDs adicionales.
- Casos límite: PP aumentados, selección inválida, estados incorrectos, confusión,
  límites de amistad/EV, Campana Alivio consumida, Pomeg a 1 PS, propiedad ambigua,
  ausencia de objeto, actividad de combate y datos temporales de Transformación.
- El flujo real abre B, cura sueño, usa Poción/Éter/Grana, guarda y carga en un
  archivo de prueba separado, y entra en el combate nativo con los PS, EV, PP y
  estado resultantes. No se usa el archivo de partida habitual.
- Regresiones: conexiones de 625 equipados, 229 MT y rutas de evolución; medicina
  en combate; campo; guardado normal/adversarial; política; inventario/captura.
  Todas PASS.

Reproducción:

```text
python tools/item_audit/run_field_v4.py
```

El ejecutor lanza la ventana de prueba oculta, comprueba errores de script y
publica los informes solo después de pasar todas las fases. La evidencia local
queda en `.godot/item_field_v4/`; el JSON conserva hashes de fuentes y resultados.
La matriz de 2.222 IDs se publica como CSV con extensión `.csv.txt` para evitar
que Godot la importe como un recurso de traducción.

## Alcance pendiente

Las seis bayas ya tienen conexión de EV y amistad base. **Los bonus por Poké Ball
de captura y mapa de origen siguen pendientes**: CreatureInstance no conserva
esos metadatos. No se adivinan ni se certifican esos bonus. Campana Alivio sí se
comprueba mediante el estado real del objeto equipado.

De los 47 pendientes concretos del barrido V3, quedan **41 conexiones principales**:
26 rutas de formas, 14 usos de comida/concursos/mundo y Lazo Destino. Los bonus de
origen de las seis bayas se conservan aparte en `ITEM_PENDING_V4.json`.

Esto no cierra todo el catálogo: otros alimentos/medicinas/bayas de curación,
vitaminas, plumas, caramelos, IV, naturalezas y habilidades necesitan sus rutas;
también siguen las bolas condicionales, máquinas antiguas, evoluciones
condicionadas y Cuerda Huida. Los 189 IDs con escenarios de efecto de combate
verificados en fases previas conservan su alcance; estas 21 conexiones de campo
no se suman como 21 efectos equipados nuevos.

## Referencias y agradecimientos para créditos

Se reutiliza el contrato local `battle_medicine_profile.json` y los servicios
existentes de estadísticas, propiedad, inventario y guardado. Para las bayas se
contrasta el comportamiento con **Maruno17 y colaboradores de Pokémon Essentials**,
commit `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`:

- [Uso de bayas reductoras](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/013_Items/001_Item_Utilities.rb).
- [Amistad y recálculo de PS](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/014_Pokemon/001_Pokemon.rb).

La adaptación en GDScript usa nuestro estado transaccional; no ejecuta Ruby ni
instala otro motor. `tests/fixtures/item_field_v4/reference_contract.json`
conserva el commit, hashes y los límites de contexto para futuras revisiones.
''', encoding='utf-8')
    print(json.dumps({k: result[k] for k in ['status', 'new_field_item_ids', 'headless_checks', 'gpu_checks', 'field_context_cases', 'reviewed_held_berry_core_dependencies_remaining']}))


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--summarize', action='store_true')
    args = parser.parse_args(); OUT.mkdir(parents=True, exist_ok=True)
    if not args.summarize:
        godot = os.environ.get('GODOT_BIN') or shutil.which('godot') or r'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
        command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/item_field_effects_v4.gd'], 'godot.log')
        command([godot, '--path', '.', '--resolution', '1280x720', '--script', 'tests/gameplay/item_field_effects_v4.gd', '--', '--capture'], 'gpu.log')
        for name in ['item_connections', 'showdown_medicine', 'field_native', 'savegame_v2',
                     'savegame_v2_adversarial', 'item_selection_policy', 'item_existing_groups_v2']:
            script = name + ('.gd' if name == 'item_existing_groups_v2' else '_test_runner.gd')
            command([godot, '--headless', '--path', '.', '--script', 'tests/gameplay/' + script], 'regression_' + name + '.log')
    summarize()


if __name__ == '__main__':
    main()
