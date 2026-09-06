from pathlib import Path
import subprocess

BOOK = Path('docs/project_book/TRAINER_AI.md')
HELPERS = [
    Path('.github/scripts/c3fas_freeze_26_67.py'),
    Path('.github/workflows/c3fas-freeze-26-67.yml'),
    Path('.github/triggers/c3fas-freeze-26-67.trigger'),
]
EXPECTED_BASE = '401475efc95dff45871668b7f2a4315d33e68da3'

SECTION = r'''

## 26.67 — Freeze final C3f-as: Trainer AI runtime system CLOSED / COMPLETED

Estado: **FREEZE FINAL / C3f-as DOBLEMENTE CERTIFICADA / `TRAINER_AI_RUNTIME_SYSTEM_FINAL_CLOSURE_VALIDATED` / 4/4 COMPLETADO / TRAINER AI RUNTIME SYSTEM CLOSED-COMPLETED / 0 PRODUCCIÓN EN EL CIERRE / SIN SIGUIENTE MICROTRANCHE AUTORIZADA**.

C3f-as ejecuta la única frontera restante autorizada por 26.66 y cierra el plan de cuatro pasos. No añade funcionalidad nueva: vuelve a someter el sistema Trainer AI ya integrado al `run/main_scene` real, conserva las regresiones anteriores y añade un cierre E2E independiente de derrota sobre una instancia fresca de la escena ejecutable.

La ejecución no descubre ningún blocker de producción. En consecuencia, C3f-as permanece estrictamente **TEST/AUDIT-ONLY** y el sistema Trainer AI integrado queda cerrado bajo el alcance construido y certificado en este cuaderno.

### 26.67.1 Genealogía final

Baseline exclusivo — freeze 26.66:

`7113c3c4f81d0c37e3af36d41eb247e086d49fd4`

Checkpoint técnico C3f-as:

`3bf9a0ad80b495f6d002f88dfcb13615d09f48de`

Checkpoint humano C3f-as:

`401475efc95dff45871668b7f2a4315d33e68da3`

Los dos checkpoints son siblings reales:

- parent común: `7113c3c4f81d0c37e3af36d41eb247e086d49fd4`;
- tree común: `8d43ce9694cfb7f06d23f34bdcd5163ba9b6b625`;
- ninguno desciende del otro.

La rama se movió del checkpoint técnico al humano mediante actualización explícita de ref porque dos siblings no forman fast-forward entre sí. Esto no altera `main` ni introduce divergencia de contenido: ambos checkpoints apuntan al mismo tree.

### 26.67.2 Scope exacto: cierre test-only

Diff C3f-as contra 26.66:

1. **NUEVO test** `tests/trainer_ai/trainer_ai_runtime_final_closure_test_suite.gd` — `+174 / -0`;
2. **MODIFICADO test runner** `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd` — `+1 / -0`.

Cambios de producción: **0**.

No se modifica:

- `TrainerBattleSession`;
- Battle Core;
- `TrainerBattlePresentationController`;
- `technical_overworld.gd`;
- `technical_overworld.tscn`;
- `WildAdventureSession`;
- controller Wild;
- Capture/Run;
- Trainer Brain general/default;
- scheduler/shared budget/660;
- FASE34.

### 26.67.3 Certificación técnica final

Checkpoint técnico `3bf9a0ad80b495f6d002f88dfcb13615d09f48de`:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Evaluation Corpus run: `34003476835`;
- artifact: `9980195278`;
- artifact digest: `sha256:8b87170f5759c3c8cbbf01671f52e9e4516db7f56f8877564704c9b45ff9d241`;
- literal: **`380 PASS / 0 FAIL`**;
- **67/67 checks C3f-as PASS**;
- aggregate: `TRAINER_AI_RUNTIME_SYSTEM_FINAL_CLOSURE_VALIDATED`;
- Evaluation test log SHA256: `9c47df03770d949088e5ee0e75138c5121313e6da200a7b172d051712ac420c2`;
- Trainer Battle Session run: `34003476950`;
- artifact: `9980190851`;
- artifact digest: `sha256:cc0a11edf687a79aeea80ba3e032b6c4e0ad785e504d693cd4e99a74bcc7d56a`;
- literal: **`66 PASS / 0 FAIL`**;
- Battle test log SHA256: `123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Trainer Team Composition run: `34003477024`;
- artifact: `9980250274`;
- artifact digest: `sha256:5c25cb84cc962ed40cdd642e1d7b655a282866d04345b8d6c52df891857bd8c5`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- Team test log SHA256: `996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- sin `SCRIPT ERROR` ni traceback en los logs inspeccionados.

### 26.67.4 Certificación humana final

Checkpoint humano `401475efc95dff45871668b7f2a4315d33e68da3`:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Evaluation Corpus run: `34003756240`;
- artifact: `9980279574`;
- artifact digest: `sha256:39cbacb9976097bf63414accb5187bdfcf791295aec14fae26184d887276831b`;
- literal: **`380 PASS / 0 FAIL`**;
- mismos **67/67 checks C3f-as PASS**;
- mismo aggregate: `TRAINER_AI_RUNTIME_SYSTEM_FINAL_CLOSURE_VALIDATED`;
- Evaluation test log SHA256: `9c47df03770d949088e5ee0e75138c5121313e6da200a7b172d051712ac420c2`;
- Trainer Battle Session run: `34003756242`;
- artifact: `9980275986`;
- artifact digest: `sha256:57c7904fc0c391c63753b2e2f5da86bdd618ce5e9959e0d56a1cf09c0cc54252`;
- literal: **`66 PASS / 0 FAIL`**;
- Battle test log SHA256: `123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Trainer Team Composition run: `34003756659`;
- artifact: `9980322079`;
- artifact digest: `sha256:ddf25e4de7bf2c33a85f302062aec06b7f4e610010a9606c43f94eed9c5889cf`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- Team test log SHA256: `996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- sin `SCRIPT ERROR` ni traceback en los logs inspeccionados.

Los tres logs de test relevantes son byte-idénticos técnico↔humano. No se observa nondeterminismo entre los siblings finales.

### 26.67.5 Qué valida específicamente C3f-as

La suite final conserva primero todas las pruebas C3f-ar ya ejecutadas dentro del mismo Evaluation Corpus, incluyendo el ciclo real de victoria Trainer y la comprobación de que Wild sigue funcionando después del combate de entrenador.

Sobre una **segunda instancia fresca** del `run/main_scene`, C3f-as añade un cierre independiente de derrota:

1. carga `res://scenes/overworld/technical_overworld.tscn`;
2. entra al combate por movimiento físico del `OverworldPlayer` sobre `TrainerTrigger`;
3. confirma que Trainer arranca y Wild permanece inactivo;
4. confirma que el movimiento del Overworld queda congelado;
5. mantiene `TrainerBattleSession` y trainer memory operativas;
6. establece únicamente una frontera determinista de QA sobre HP/Speed para garantizar la derrota, sin sustituir reglas de Battle Core;
7. el jugador sigue enviando exclusivamente acciones `side_a` mediante el controller Trainer;
8. `side_b` sigue naciendo de `submit_player_action_with_autonomous_trainer(...)`;
9. durante los turnos no terminales se observa `SUBSTITUTION_READY`;
10. `caller_action = null`;
11. `caller_fallback_used = false`;
12. Trainer Brain general permanece no integrado;
13. scheduler/shared budget permanecen nulos;
14. FASE34 permanece cerrada;
15. Battle Core termina la batalla con derrota del jugador;
16. `TrainerBattleSession` alcanza `COMPLETED_DEFEAT`;
17. la presentación espera Continue;
18. `continue_after_completion()` resetea la sesión a `READY`;
19. el overlay Trainer se oculta;
20. el Overworld recupera movimiento.

No se necesitó ninguna modificación productiva para que este ciclo pasase.

### 26.67.6 Cobertura final combinada victoria + derrota + aislamiento Wild

C3f-ar y C3f-as, ejecutadas juntas en el corpus final, dejan cubierta la ruta runtime integrada en ambos resultados terminales relevantes:

**Victoria Trainer:**

`Overworld → TrainerTrigger → MOVE/SWITCH side_a → side_b autónomo → Battle Core → FINISHED/Victory → settlement → Continue/reset → Overworld`

**Derrota Trainer:**

`Overworld fresco → TrainerTrigger → side_a del jugador → side_b autónomo → Battle Core → FINISHED/Defeat → settlement → Continue/reset → Overworld`

**Aislamiento Wild:**

- Wild usa su propio `WildAdventureSession`;
- Wild conserva `SimpleBattleOpponentPolicy`;
- Capture sigue disponible solo en el seam Wild;
- Run sigue disponible solo en el seam Wild;
- Trainer no expone `submit_capture_ball`;
- Trainer no expone `submit_player_run`;
- completar un ciclo Trainer no impide iniciar después un encuentro Wild.

### 26.67.7 Contratos internos históricos preservados

El cierre final no sustituye ni debilita las capas certificadas anteriormente.

Permanecen verdes:

- API histórica explícita `submit_player_action(player_action, opponent_action)`;
- API autónoma opt-in `submit_player_action_with_autonomous_trainer(player_action)`;
- proposal/substitution fail-closed;
- identidad de battle/turn/side;
- memoria side-specific detached;
- forced replacement propiedad de Battle Core;
- terminal-horizon semantics;
- settlement de victoria y derrota;
- reset post-completion;
- rechazo de proposal stale entre batallas;
- segunda batalla fresca sobre una misma sesión;
- regresiones completas del Trainer Battle Session: **66 PASS / 0 FAIL**.

### 26.67.8 Barreras que permanecen cerradas

El cierre del sistema actual **no** se utiliza como excusa para abrir subsistemas que no eran necesarios para esta integración.

Continúan CLOSED:

- Trainer Brain general/default;
- autonomía global aplicada a Wild u otros modos;
- scheduler/shared budget/660;
- FASE34;
- cambios de policy Wild;
- nueva política de Capture/Run para Trainer;
- cualquier segunda autoridad paralela a Battle Core.

Si en el futuro se desea construir alguno de esos elementos, deberá abrirse como una nueva feature/proyecto con alcance explícito y sus propios gates; no como continuación automática de C3f.

### 26.67.9 Estado final del plan 4/4

El contador de cierre queda definitivamente:

- **1/4 — C3f-ap reset + segunda batalla: COMPLETADO**;
- **2/4 — C3f-aq caller/integration seam: COMPLETADO**;
- **3/4 — C3f-ar integración real de autonomía Trainer: COMPLETADO**;
- **4/4 — C3f-as cierre final E2E + regresiones: COMPLETADO**.

Resultado final:

`TRAINER_AI_RUNTIME_SYSTEM_FINAL_CLOSURE_VALIDATED`

**Trainer AI runtime system: CLOSED / COMPLETED.**

### 26.67.10 Invariantes externas finales

PR #105 permanece **OPEN / unmerged**. Debe seguir siendo temporal y **no debe mergearse a `main` por este freeze**.

`main` permanece exactamente en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

El cierre Trainer AI no modifica `main`.

### 26.67.11 No existe siguiente microtranche autorizada

Este freeze **NO autoriza C3f-at, C3f-au ni ninguna fase 5/4**.

No queda una microtranche pendiente dentro del plan de cierre Trainer AI.

Trabajo futuro solo podrá reabrir esta superficie si ocurre una de estas dos condiciones:

1. aparece una **regresión concreta y reproducible** contra el sistema aquí certificado; o
2. se decide explícitamente iniciar una **nueva feature/proyecto** con alcance distinto al cierre actual.

En ausencia de una de esas condiciones, el trabajo del sistema Trainer AI descrito en este cuaderno queda terminado.
'''


def run(*args):
    return subprocess.check_output(args, text=True).strip()

head_parent = run('git', 'rev-parse', 'HEAD^')
if head_parent != EXPECTED_BASE:
    raise SystemExit(f'unexpected staging parent: {head_parent}')

text = BOOK.read_text(encoding='utf-8')
if '## 26.66 — Freeze C3f-ar' not in text:
    raise SystemExit('26.66 freeze marker missing')
if '## 26.67 — Freeze final C3f-as' in text:
    raise SystemExit('26.67 already present')
BOOK.write_text(text.rstrip() + SECTION + '\n', encoding='utf-8')

for helper in HELPERS:
    if helper.exists():
        helper.unlink()

subprocess.check_call(['git', 'config', 'user.name', 'github-actions[bot]'])
subprocess.check_call(['git', 'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com'])
subprocess.check_call(['git', 'add', '-A'])
subprocess.check_call(['git', 'commit', '-m', 'docs(trainer-ai): freeze 26.67 final runtime system closure'])
subprocess.check_call(['git', 'push', 'origin', 'HEAD:audit/trainer-ai-v3-random-cup-redesign-v1'])
