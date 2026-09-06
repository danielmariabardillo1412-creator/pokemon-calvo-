from pathlib import Path
import subprocess

BOOK = Path('docs/project_book/TRAINER_AI.md')
HELPERS = [
    Path('.github/scripts/c3far_freeze_26_66.py'),
    Path('.github/workflows/c3far-freeze-26-66.yml'),
    Path('.github/triggers/c3far-freeze-26-66.trigger'),
]
EXPECTED_BASE = '802249f6fd4f0415181b659d3101870371acf927'

SECTION = r'''

## 26.66 — Freeze C3f-ar: autonomía Trainer integrada en runtime real y doblemente certificada

Estado: **FREEZE DOCUMENTAL / C3f-ar DOBLEMENTE CERTIFICADA / `AUTONOMOUS_TRAINER_RUNTIME_SEAM_INTEGRATED` / MAIN SCENE REAL / MOVE+SWITCH AUTÓNOMOS / SETTLEMENT+RETORNO / WILD AISLADO / 18/18 TÉCNICO+HUMANO / 3/4 COMPLETADO / QUEDA 1 PASO FINAL**.

C3f-ar ejecuta exactamente la integración autorizada por 26.65. El flujo contra entrenador ya no es solo una capa headless: existe una entrada alcanzable desde el `run/main_scene`, un controller Trainer separado, una `TrainerBattleSession` poseída por el Overworld técnico y un submit real donde el caller construye únicamente la acción `side_a` del jugador y delega `side_b` a `submit_player_action_with_autonomous_trainer(player_action)`.

No se ha abierto Trainer Brain general, autonomía global, scheduler/shared budget/660 ni FASE34. El seam Wild conserva su controller y su `SimpleBattleOpponentPolicy`, además de Capture y Run.

### 26.66.1 Genealogía canónica

Baseline exclusivo — freeze 26.65:

`1f7d28368bc0a8d38a5f68dc05c335f192d80ada`

Checkpoint técnico canónico C3f-ar:

`3ea45dc9869d3f3bf229b8ab54acd40501c6ecbd`

Checkpoint humano C3f-ar:

`802249f6fd4f0415181b659d3101870371acf927`

Los dos checkpoints son siblings reales:

- parent común: `1f7d28368bc0a8d38a5f68dc05c335f192d80ada`;
- tree común: `9daed2f92568a602cd5c8fb04fa96ff7d0ff56e5`;
- ninguno desciende del otro.

### 26.66.2 Scope exacto de C3f-ar

Diff canónico contra 26.65:

1. **NUEVO producción** `modules/battle/presentation/trainer_battle_presentation_controller.gd`;
2. **MODIFICADO producción** `scenes/overworld/technical_overworld.gd`;
3. **MODIFICADO producción** `scenes/overworld/technical_overworld.tscn`;
4. **NUEVO test** `tests/trainer_ai/trainer_battle_runtime_integration_test_suite.gd`;
5. **MODIFICADO test runner** `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd` para ejecutar la nueva suite async.

No se modifica:

- `modules/gameplay/trainer_battle_session.gd`;
- Battle Core;
- `WildAdventureSession`;
- `BattlePresentationController` Wild;
- `SpanishBattlePresentationController` Wild;
- Capture/Run;
- Trainer Brain general;
- scheduler/shared budget/660;
- FASE34.

### 26.66.3 Candidato no canónico: fallo de aserción estática, no de producto

El primer candidato C3f-ar:

`77f2f1814dca124ae668ed801ff36c02b4d6bd1b`

importó correctamente y ejecutó satisfactoriamente toda la ruta funcional nueva, pero Evaluation terminó en **311 PASS / 2 FAIL**.

Los dos únicos fallos eran aserciones estáticas de la propia suite:

- `c3far_trainer_controller_has_no_capture_surface`;
- `c3far_trainer_controller_has_no_run_surface`.

La prueba buscaba además las palabras genéricas `Capture` y `Run` dentro del source. Las encontró en comentarios que precisamente documentaban que el controller Trainer **no expone Capture/Run**. No falló ninguna llamada runtime ni ninguna frontera de autonomía.

La corrección canónica cambia únicamente esas dos condiciones para comprobar la API real (`func submit_capture_ball` / `func submit_player_run`). El código de producción se conserva idéntico. El candidato `77f2f...` queda no canónico/orphaned como fallo de test, no como fallo de integración.

### 26.66.4 Certificación técnica exacta

Checkpoint técnico `3ea45dc9869d3f3bf229b8ab54acd40501c6ecbd`:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Evaluation Corpus run: `34002182103`;
- artifact: `9979812737`;
- literal: **`313 PASS / 0 FAIL`**;
- **70/70 checks C3f-ar PASS**;
- Evaluation test log SHA256: `a6f7a129279b9381acc88c61c226c154ee8b0a41b399fcdffc1dc4bfe9e0b42c`;
- Trainer Battle Session run: `34002182106`;
- artifact: `9979811402`;
- literal: **`66 PASS / 0 FAIL`**;
- Battle test log SHA256: `123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Trainer Team Composition run: `34002182138`;
- artifact: `9979863436`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- Team test log SHA256: `996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- sin `SCRIPT ERROR` ni traceback en los tres logs inspeccionados.

### 26.66.5 Certificación humana exacta

Checkpoint humano `802249f6fd4f0415181b659d3101870371acf927`:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Evaluation Corpus run: `34002435481`;
- artifact: `9979887408`;
- literal: **`313 PASS / 0 FAIL`**;
- mismos **70/70 checks C3f-ar PASS**;
- Evaluation test log SHA256: `a6f7a129279b9381acc88c61c226c154ee8b0a41b399fcdffc1dc4bfe9e0b42c`;
- Trainer Battle Session run: `34002435614`;
- artifact: `9979884722`;
- literal: **`66 PASS / 0 FAIL`**;
- Battle test log SHA256: `123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Trainer Team Composition run: `34002435526`;
- artifact: `9979936222`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- Team test log SHA256: `996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- sin `SCRIPT ERROR` ni traceback en los tres logs inspeccionados.

Los tres logs relevantes son byte-idénticos técnico↔humano. No se observa nondeterminismo entre siblings.

### 26.66.6 Integración runtime certificada

La suite C3f-ar instancia el `run/main_scene` real:

`res://scenes/overworld/technical_overworld.tscn`

y valida el flujo alcanzable desde movimiento físico del `OverworldPlayer`.

La escena contiene dos seams separados:

- `CanvasLayer/BattlePresentation` → Wild;
- `CanvasLayer/TrainerBattlePresentation` → Trainer.

Además incorpora un `TrainerTrigger` técnico independiente del `EncounterZone` Wild.

Al alcanzar el trigger Trainer:

1. el Overworld construye/posee una `TrainerBattleSession`;
2. `begin_battle(...)` arranca una batalla Trainer real;
3. el movimiento del jugador se congela;
4. se abre exclusivamente el controller Trainer;
5. el controller Wild permanece oculto;
6. no se inicia una batalla Wild accidentalmente.

### 26.66.7 MOVE y SWITCH sin caller `opponent_action`

El `TrainerBattlePresentationController` no usa `SimpleBattleOpponentPolicy` y no expone un argumento `opponent_action`.

Para MOVE y SWITCH construye únicamente el `BattleAction` de `side_a` y llama:

`submit_player_action_with_autonomous_trainer(player_action)`

La prueba E2E certifica sobre un SWITCH runtime real:

- eventos autoritativos no vacíos;
- turno avanzado;
- `last_error` vacío;
- `substitution_status = SUBSTITUTION_READY`;
- `caller_action = null`;
- `caller_fallback_used = false`;
- `trainer_brain_integration_authorized = false`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `fase34_open = false`.

Por tanto la acción rival que llega a Battle Core es la proposal autónoma certificada, no una acción fabricada por presentation/Overworld.

### 26.66.8 FINISHED, settlement y retorno al Overworld

La misma ruta ejecuta un MOVE terminal real y certifica:

- Battle Core produce eventos;
- la batalla llega a `FINISHED`;
- `TrainerBattleSession.settle_finished_battle()` completa;
- `completion_reason = VICTORY` en el control de victoria;
- la presentación permanece visible hasta Continue;
- el Overworld permanece congelado antes de Continue;
- `continue_after_completion()` llama la frontera de reset ya certificada;
- la sesión vuelve a `READY`;
- el overlay Trainer se oculta;
- el movimiento del Overworld se reanuda.

Forced replacement, KO y reglas de batalla continúan bajo Battle Core; C3f-ar no introduce un segundo resolvedor.

### 26.66.9 Aislamiento Wild preservado

Tras completar el combate Trainer, la suite mueve al jugador al `EncounterZone` real y certifica que el flujo Wild sigue siendo alcanzable.

Controles explícitos:

- Wild battle arranca;
- overlay Wild se muestra;
- Trainer battle no se reabre;
- overlay Trainer permanece oculto;
- Capture sigue expuesto en Wild;
- Run sigue expuesto en Wild;
- el controller Wild conserva `SimpleBattleOpponentPolicy.choose_move_action(...)`;
- el controller Trainer no tiene `submit_capture_ball` ni `submit_player_run`.

C3f-ar no convierte la autonomía Trainer en una policy global para encuentros salvajes.

### 26.66.10 Decisión: integración funcional cerrada

C3f-ar queda **DOBLEMENTE CERTIFICADA** como integración real de la autonomía Trainer.

La cadena runtime demostrada es ahora:

`Overworld físico → TrainerTrigger → TrainerBattleSession.begin_battle → TrainerBattlePresentationController → player MOVE/SWITCH side_a → submit_player_action_with_autonomous_trainer → proposal/substitution side_b → Battle Core → FINISHED → settlement → reset/Continue → Overworld`

El seam Wild permanece paralelo e independiente.

No queda autorizada otra microtranche funcional intermedia antes del cierre final salvo blocker real reproducido.

### 26.66.11 Contador de cierre

El plan visible queda:

- **1/4 — C3f-ap reset + segunda batalla: COMPLETADO**;
- **2/4 — C3f-aq caller/integration seam: COMPLETADO**;
- **3/4 — C3f-ar integración real de autonomía Trainer: COMPLETADO**;
- **4/4 — C3f-as cierre final E2E + regresiones + freeze final: SIGUIENTE Y ÚNICO PASO RESTANTE**.

Queda por tanto **1 único paso final planificado**.

### 26.66.12 Única siguiente microtranche autorizada: C3f-as cierre final

**C3f-as — FINAL CLOSURE / TEST-AUDIT-FIRST del sistema Trainer AI integrado: ejecutar una certificación E2E/regresión final sobre el `run/main_scene` y las fronteras ya cerradas, sin añadir funcionalidad nueva ni modificar producción salvo que aparezca un blocker real reproducible. Si queda verde, congelar el cierre definitivo del sistema Trainer AI; no abrir otra microtranche intermedia.**

C3f-as deberá comprobar como mínimo:

1. `project.godot` sigue arrancando `technical_overworld.tscn`;
2. la escena real sigue conteniendo seams Wild y Trainer separados;
3. una instancia fresca del main scene puede ejecutar trigger Trainer → MOVE/SWITCH autónomo → `FINISHED` → settlement → Continue → Overworld;
4. una instancia fresca independiente cubre también el cierre de **derrota** Trainer y retorno al Overworld, sin caller side_b;
5. proposal/substitution continúan fail-closed y sin caller fallback;
6. no existe `opponent_action` externo en el controller Trainer;
7. Capture/Run siguen ausentes del seam Trainer y presentes en Wild;
8. después de un ciclo Trainer, el seam Wild sigue ejecutable;
9. `TrainerBattleSession` histórico explícito continúa pasando sus regresiones;
10. Battle Core, forced replacement y ownership no se duplican en presentation/Overworld;
11. Trainer Brain general/default continúa CLOSED;
12. scheduler/shared budget/660 continúa CLOSED;
13. FASE34 continúa CLOSED;
14. no se cambia la policy Wild;
15. no se modifica producción si la ejecución no descubre un blocker real;
16. checkpoint técnico y humano deben ser siblings desde 26.66 con tree idéntico;
17. ambos deben obtener **18/18 workflows SUCCESS**;
18. inspeccionar literales Evaluation/Battle/Team y ausencia de `SCRIPT ERROR`/traceback;
19. PR #105 debe permanecer OPEN/unmerged;
20. `main` debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`;
21. si todo queda verde, el freeze posterior debe declarar **Trainer AI runtime system CLOSED/COMPLETED** y no autorizar una nueva microtranche de este sistema.

Resultado objetivo:

`TRAINER_AI_RUNTIME_SYSTEM_FINAL_CLOSURE_VALIDATED`

Resultados alternativos admisibles únicamente si existe evidencia concreta:

- `FINAL_CLOSURE_BLOCKED_BY_RUNTIME_REGRESSION`;
- `FINAL_CLOSURE_BLOCKED_BY_ISOLATION_REGRESSION`;
- `BLOCKED`.

### 26.66.13 Invariantes externas

PR #105 continúa **OPEN / unmerged**.

`main` continúa exactamente en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

C3f-ar queda cerrada. La única frontera restante del plan es C3f-as cierre final 4/4.
'''


def run(*args):
    return subprocess.check_output(args, text=True).strip()

head_parent = run('git', 'rev-parse', 'HEAD^')
if head_parent != EXPECTED_BASE:
    raise SystemExit(f'unexpected staging parent: {head_parent}')

text = BOOK.read_text(encoding='utf-8')
if '## 26.65 — Freeze C3f-aq' not in text:
    raise SystemExit('26.65 freeze marker missing')
if '## 26.66 — Freeze C3f-ar' in text:
    raise SystemExit('26.66 already present')
BOOK.write_text(text.rstrip() + SECTION + '\n', encoding='utf-8')

for helper in HELPERS:
    if helper.exists():
        helper.unlink()

subprocess.check_call(['git', 'config', 'user.name', 'github-actions[bot]'])
subprocess.check_call(['git', 'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com'])
subprocess.check_call(['git', 'add', '-A'])
subprocess.check_call(['git', 'commit', '-m', 'docs(trainer-ai): freeze 26.66 C3f-ar runtime integration'])
subprocess.check_call(['git', 'push', 'origin', 'HEAD:audit/trainer-ai-v3-random-cup-redesign-v1'])
