from pathlib import Path
import subprocess

BASE = "f29d79a5ddc6a56113db97678293a9a746f767f2"
BRANCH = "audit/trainer-ai-v3-random-cup-redesign-v1"
NOTEBOOK = Path("docs/project_book/TRAINER_AI.md")
HELPERS = {
    ".github/scripts/c3faq_freeze_26_65.py",
    ".github/workflows/c3faq-freeze-26-65.yml",
    ".c3faq-freeze-26-65-trigger",
}

FREEZE = r'''

## 26.65 — Freeze C3f-aq: caller Trainer ausente localizado; seam único de integración fijado

Estado: **FREEZE DOCUMENTAL / C3f-aq SOURCE-TRACE-ONLY CERRADA / `TRAINER_BATTLE_CALLER_MISSING_SEAM_LOCALIZED` / NO EXISTE CALLER TRAINER EN RUNTIME / WILD AISLADO / SEAM ÚNICO C3f-ar FIJADO / 0 PRODUCCIÓN / SIN CI ARTIFICIAL / QUEDAN 2 PASOS FINALES**.

C3f-aq ejecuta exactamente la auditoría caller/integration-point autorizada por 26.64. La conclusión no es que exista un caller Trainer defectuoso, sino que **el flujo Trainer todavía no está conectado a la vertical slice ejecutable**. `TrainerBattleSession` permanece como capa de aplicación headless plenamente probada, mientras el runtime ejecutable actual solo conecta Overworld + `WildAdventureSession` + presentación de combate salvaje.

No se modifica producción en C3f-aq. La evidencia es source-trace/arquitectura sobre el snapshot exacto 26.64; por ello, conforme a 26.64.11.14, no se fabrican checkpoints técnico/humano ni CI artificial para una auditoría sin código ejecutable nuevo.

### 26.65.1 Baseline y resultado

Baseline/freeze 26.64 auditado:

`f29d79a5ddc6a56113db97678293a9a746f767f2`

Tree del baseline:

`d7248ff200b52039b6a1a9ada2ad66e4e30eb688`

Resultado C3f-aq:

`TRAINER_BATTLE_CALLER_MISSING_SEAM_LOCALIZED`

No apareció blocker interno nuevo en Trainer AI ni en `TrainerBattleSession`; la ausencia localizada es de integración runtime/presentation/Overworld, exactamente una de las salidas admisibles previstas por 26.64.

### 26.65.2 Entry point ejecutable real

`project.godot` fija el main scene actual en:

`res://scenes/overworld/technical_overworld.tscn`

La escena `technical_overworld.tscn` contiene actualmente un único nodo de presentación de batalla:

`CanvasLayer/BattlePresentation`

cuyo script es:

`res://modules/battle/presentation/spanish_battle_presentation_controller.gd`

No existe en la escena un nodo/controller Trainer paralelo.

### 26.65.3 Ownership real actual: solo WildAdventureSession

`scenes/overworld/technical_overworld.gd` declara y construye:

`var _session: WildAdventureSession`

mediante:

`_session = WildAdventureSession.new(collection, _catalogs, rules)`

El mismo root configura `BattlePresentationController` con esa sesión Wild y abre la presentación cuando `OverworldEncounterDirector.on_step(...)` produce `battle_started`.

No declara, construye ni posee `TrainerBattleSession`.

El inventario exacto de `modules/overworld` en 26.64 contiene director/zone/player/step-outcome de encuentros salvajes, pero **ningún trainer trigger/director/controller**.

### 26.65.4 No existe caller runtime de TrainerBattleSession

La búsqueda global de `TrainerBattleSession.new` devuelve únicamente suites de test. No existe uso de producción/escena que instancie la sesión.

La búsqueda de `TrainerBattlePresentationController` no devuelve resultados.

`modules/gameplay` contiene `trainer_battle_session.gd` y `trainer_battle_settlement.gd`, pero no una capa de presentación/Overworld Trainer.

Esto coincide con ADR-019, que dejó explícitamente fuera de alcance de FASE19:

- presentación visual de trainer battle;
- NPC y trigger en Overworld;
- diálogo pre/post combate;
- sprites/animaciones del entrenador.

El informe de FASE19 también identificó como dependencia posterior precisamente `Trainer Battle Presentation/Overworld seam` una vez existiera una política rival reutilizable.

Por tanto, la ausencia encontrada es consistente con la arquitectura histórica; no es una regresión ni un caller perdido.

### 26.65.5 Dónde se genera hoy opponent_action

`modules/battle/presentation/battle_presentation_controller.gd` está tipado explícitamente a:

`var session: WildAdventureSession`

Para MOVE y SWITCH construye la acción del jugador y genera la reacción rival con:

`SimpleBattleOpponentPolicy.choose_move_action(...)`

antes de llamar:

`WildAdventureSession.submit_player_command(..., opponent_action)`

El mismo patrón se utiliza para CAPTURE fallida y RUN no garantizado, porque ambos son comandos **exclusivamente Wild** cuya reacción rival se valida dentro de `WildAdventureSession`.

Este `opponent_action` no es el caller Trainer buscado por C3f-aq. Es la política técnica de la vertical slice salvaje existente y debe permanecer fuera de C3f-ar.

### 26.65.6 Aislamiento Trainer vs Wild certificado por contrato

`WildAdventureSession` posee semánticas que `TrainerBattleSession` deliberadamente no expone:

- `CAPTURE`;
- `RUN`;
- encuentro salvaje;
- capture RNG / escape RNG;
- `current_wild()`;
- ownership/routing de captura.

`TrainerBattleSession`, en cambio, representa exclusivamente:

`player roster + trainer id + trainer roster -> Battle Core -> VICTORY/DEFEAT -> settlement`

y desde C3f-am expone la frontera autónoma:

`submit_player_action_with_autonomous_trainer(player_action)`

Por tanto **no se generalizará `BattlePresentationController` para hacer ambas cosas**. Convertir el controller Wild existente en una unión Wild+Trainer mezclaría Capture/Run, RNG y semántica de encuentro con una sesión que intencionadamente carece de ellas.

### 26.65.7 Seam único autorizado para C3f-ar

C3f-ar deberá introducir una costura **paralela y explícita**, no un toggle global:

`technical_overworld -> TrainerBattleSession -> TrainerBattlePresentationController -> submit_player_action_with_autonomous_trainer(player_action) -> Battle Core`

La ownership/lifetime propuesta queda fijada así:

1. `technical_overworld.gd` continúa poseyendo `_session: WildAdventureSession` para encuentros salvajes;
2. añade una propiedad separada `_trainer_session: TrainerBattleSession`;
3. una entrada/trigger técnico Trainer construye o resetea esa sesión y llama `begin_battle(trainer_id, roster, seed)`;
4. se abre un `TrainerBattlePresentationController` separado;
5. el controller Trainer construye **solo** la acción `side_a` del jugador;
6. MOVE/SWITCH del jugador se entregan a `submit_player_action_with_autonomous_trainer(player_action)`;
7. el caller no calcula, pasa ni conserva `opponent_action`;
8. tras `BattleState.FINISHED`, la sesión Trainer ejecuta `settle_finished_battle()` y la presentación devuelve el control al Overworld;
9. antes de reutilizar la misma sesión para otro entrenador se usa la frontera ya certificada `reset_after_completion()`;
10. `WildAdventureSession`, `BattlePresentationController`, Capture y Run permanecen en su seam actual, sin circular por Trainer AI.

No quedan autorizadas otras arquitecturas alternativas para C3f-ar salvo blocker real reproducido.

### 26.65.8 Inventario mínimo de producción previsto para C3f-ar

El seam puede implementarse con **tres superficies de producción**:

1. **NUEVO** `modules/battle/presentation/trainer_battle_presentation_controller.gd` — presentación Trainer separada, sin Capture/Run y sin política rival externa;
2. **MODIFICAR** `scenes/overworld/technical_overworld.gd` — ownership de `TrainerBattleSession`, roster/trigger técnico, apertura/cierre Trainer y retorno a exploración;
3. **MODIFICAR** `scenes/overworld/technical_overworld.tscn` — nodo de presentación Trainer y trigger/área técnica que haga alcanzable el combate desde el main scene.

Los tests de C3f-ar podrán añadir suites/runners, pero no cuentan como producción.

No se autoriza modificar para esta integración:

- `modules/gameplay/trainer_battle_session.gd`, salvo blocker real demostrado por C3f-ar;
- Battle Core;
- `WildAdventureSession`;
- `BattlePresentationController` Wild;
- Capture/Run;
- brains generales;
- scheduler/shared budget/660;
- FASE34.

### 26.65.9 Trainer Brain general no es requisito de integración

C3f-aq determina explícitamente que **no es necesario activar un Trainer Brain general** para C3f-ar.

La frontera certificada `submit_player_action_with_autonomous_trainer(player_action)` ya crea una proposal fresca `side_b`, aplica la validación de sustitución y entrega la acción al Battle Core sin caller fallback. C3f-ar únicamente debe conectar el input real del jugador a esa API.

Por tanto permanecen CLOSED:

- Trainer Brain general/default;
- autonomía global/default para otros tipos de batalla;
- scheduler/shared budget/660;
- FASE34.

### 26.65.10 Contador de cierre

El plan visible queda ahora:

- **1/4 — C3f-ap reset + segunda batalla: COMPLETADO**;
- **2/4 — C3f-aq caller/integration seam: COMPLETADO**;
- **3/4 — C3f-ar integración real de autonomía Trainer: SIGUIENTE**;
- **4/4 — cierre E2E + regresiones + freeze final: PENDIENTE**.

Quedan por tanto **2 pasos finales planificados**, salvo blocker real reproducido durante la integración.

### 26.65.11 Siguiente microtranche autorizada: C3f-ar integración real

**C3f-ar — implementar la vertical slice Trainer mínima y separada en el main scene técnico usando el seam fijado por 26.65: `technical_overworld` posee una `TrainerBattleSession`, un controller Trainer separado presenta MOVE/SWITCH y entrega únicamente la acción del jugador a `submit_player_action_with_autonomous_trainer(...)`; debe existir una entrada Trainer alcanzable desde Overworld, settlement y retorno a exploración, sin modificar el seam Wild ni introducir caller `opponent_action`.**

C3f-ar deberá demostrar como mínimo:

1. trainer battle alcanzable desde el `run/main_scene` real;
2. `TrainerBattleSession.begin_battle(...)` llamado desde el runtime, no solo tests;
3. controller Trainer separado y sin controles Capture/Run;
4. MOVE y SWITCH del jugador atraviesan la API autónoma sin `opponent_action` externo;
5. proposal/substitution READY y turno autoritativo real;
6. KO/forced replacement continúan bajo Battle Core;
7. victoria/derrota llegan a `FINISHED` y settlement;
8. cierre de presentación devuelve movimiento/exploración;
9. Wild Move/Switch/Capture/Run mantienen su comportamiento y su controller existente;
10. no se activa Trainer Brain general, autonomía global, scheduler/shared budget/660 ni FASE34;
11. añadir tests E2E/aislamiento suficientes y exigir **18/18 workflows SUCCESS** en checkpoints técnico/humano siblings antes del freeze siguiente;
12. PR #105 OPEN/unmerged y `main` intacto.

Si C3f-ar queda verde, el único paso restante será el **cierre final E2E/regresión/documental**, no otra auditoría intermedia.

### 26.65.12 Invariantes externas

PR #105 debe continuar **OPEN / unmerged**.

`main` debe continuar exactamente en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

C3f-aq queda cerrada como source-trace con caller ausente causalmente localizado; la única siguiente frontera autorizada es C3f-ar integración real.
'''


def run(*args):
    return subprocess.check_output(args, text=True).strip()

head = run("git", "rev-parse", "HEAD")
parent = run("git", "rev-parse", "HEAD^")
if parent != BASE:
    raise SystemExit(f"unexpected helper parent: {parent} != {BASE}")

text = NOTEBOOK.read_text(encoding="utf-8")
if "## 26.65 — Freeze C3f-aq" in text:
    raise SystemExit("26.65 already present")
if "## 26.64 — Freeze C3f-ap" not in text or "la única siguiente frontera autorizada es C3f-aq" not in text:
    raise SystemExit("26.64 tail marker missing")

NOTEBOOK.write_text(text.rstrip() + FREEZE + "\n", encoding="utf-8")
for helper in HELPERS:
    p = Path(helper)
    if p.exists():
        p.unlink()

subprocess.check_call(["git", "config", "user.name", "github-actions[bot]"])
subprocess.check_call(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"])
subprocess.check_call(["git", "add", NOTEBOOK.as_posix()])
for helper in HELPERS:
    subprocess.call(["git", "add", "-A", helper])

staged = run("git", "diff", "--cached", "--name-only").splitlines()
expected = {NOTEBOOK.as_posix(), *HELPERS}
if set(staged) != expected:
    raise SystemExit(f"unexpected staged paths: {staged}")

subprocess.check_call(["git", "commit", "-m", "docs(trainer-ai): freeze 26.65 C3f-aq caller seam"])
subprocess.check_call(["git", "push", "origin", f"HEAD:{BRANCH}"])
print("C3FAQ_FREEZE_26_65_WRITTEN")
