from pathlib import Path
import os
import subprocess
import sys

BASE = "e2148c88b5d5ca30a2cf163bdc33e8ea108bc2c6"
NOTEBOOK = Path("docs/project_book/TRAINER_AI.md")
EXPECTED_NOTEBOOK_BLOB = "89a48755b4fa7bd8f66e56ef69612c9bbe9f74c0"
HELPERS = {
    ".github/scripts/c3fao_freeze_26_63.py",
    ".github/workflows/c3fao-freeze-26-63.yml",
    ".c3fao-freeze-26-63-trigger",
}

FREEZE = r'''
## 26.63 — Freeze C3f-ao: horizonte terminal explícito doblemente certificado; lifecycle cross-battle pasa a auditoría

Estado: **FREEZE DOCUMENTAL / C3f-ao DOBLEMENTE CERTIFICADA / BLOCKER TERMINAL-DEPTH RESUELTO SIN FALSEAR PROFUNDIDAD / VICTORIA Y DERROTA AUTÓNOMAS LLEGAN A FINISHED + SETTLEMENT / FAIL-CLOSED PRESERVADO / RESET + SEGUNDA BATALLA TODAVÍA NO AUDITADOS / ACTIVACIÓN GLOBAL CERRADA**.

C3f-ao ejecuta exactamente la corrección mínima autorizada por 26.62. La búsqueda puede ahora distinguir entre una rama físicamente truncada/incompleta y una rama que ya ha cerrado realmente el horizonte porque el `BattleState` posterior al root está en `FINISHED`. La corrección no rebaja `REQUIRED_DEPTH`, no inventa un segundo ply, no falsea `max_depth_reached`, no cambia scores ni tiebreaks y no relaja el fail-closed ante depth1 no terminal, matrices parciales o budget exhaustion.

### 26.63.1 Genealogía limpia y scope exacto

Freeze documental 26.62:

`26afaf795b0ecb31896bca08a7c9c716e707f6e0`

Checkpoint técnico C3f-ao certificado:

`2b555e05c8d0953b2202df0899212f8dced8f752`

Checkpoint humano C3f-ao certificado:

`e2148c88b5d5ca30a2cf163bdc33e8ea108bc2c6`

Los dos checkpoints son siblings reales:

- parent común: `26afaf795b0ecb31896bca08a7c9c716e707f6e0`;
- tree común: `d7ed2a02bc4ca5e12933a4c8dce4ed0a37f60902`;
- ninguno desciende del otro;
- contenido técnico y humano idéntico a nivel Git tree.

Diff neto exacto 26.62 → C3f-ao:

- `modules/trainer_ai/trainer_item_aware_action_proposal.gd`: **+39 / -5**;
- `modules/trainer_ai/trainer_multi_turn_search.gd`: **+28 / -0**;
- `tests/trainer_ai/trainer_battle_session_terminal_horizon_completeness_audit_test_suite.gd`: **+249 / -0**;
- `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd`: **+1 / -1**;
- total: **+317 / -6**;
- `TrainerBattleSession`: **0 cambios**;
- Battle Core: **0 cambios**;
- brains: **0 cambios**;
- scheduler/shared budget: **0 cambios**;
- docs/workflows dentro del tranche certificado: **0 cambios**.

### 26.63.2 Candidato inicial no canónico y corrección de telemetría

Antes de los siblings finales existió un candidato técnico no canónico:

`3658abb4d463b8e1bd5cb629afa920c34ac2cca5`

Ese candidato ya resolvía funcionalmente la frontera terminal, pero Evaluation Corpus cerró **208 PASS / 1 FAIL** en el check:

`c3fao_normal_depth_two_not_terminal`

El fallo no era de gameplay ni de search resolution. La telemetría `root_terminal_horizon_closed` se marcaba `true` si cualquier subrama terminal aparecía dentro de un root, incluso cuando el root había completado físicamente depth2 y no necesitaba cierre terminal anticipado.

La reparación final estrecha esa marca para que solo sea `true` cuando simultáneamente:

- `fully_completed_depth < REQUIRED_DEPTH`;
- `required_horizon_complete == true`;
- `terminal_horizon_closed_branch_count > 0`.

Por tanto un root normal que completa depth2 puede contener subramas terminales sin ser etiquetado falsamente como root cerrado anticipadamente. El candidato `3658abb...` queda como evidencia histórica no canónica de un defecto de semántica/telemetría de auditoría, no como fallo de la corrección productiva final.

### 26.63.3 Certificación técnica C3f-ao

Checkpoint técnico `2b555e05c8d0953b2202df0899212f8dced8f752`:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus run: `33984028536`;
- artifact: `9974603110`;
- literal: **`209 PASS / 0 FAIL`**;
- **28/28 checks C3f-ao PASS**;
- aggregate: `TERMINAL_HORIZON_COMPLETENESS_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`;
- Trainer Battle Session run: `33984028559`;
- artifact: `9974602428`;
- literal: **`66 PASS / 0 FAIL`**;
- Trainer Team Composition run: `33984028562`;
- artifact: `9974669185`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- **0 `SCRIPT ERROR`**, **0 traceback** en los seis logs test/import inspeccionados de las tres superficies.

### 26.63.4 Certificación humana sibling C3f-ao

Checkpoint humano `e2148c88b5d5ca30a2cf163bdc33e8ea108bc2c6`:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus run: `33984353136`;
- artifact: `9974694448`;
- literal: **`209 PASS / 0 FAIL`**;
- mismos **28/28 checks C3f-ao PASS**;
- mismo aggregate: `TERMINAL_HORIZON_COMPLETENESS_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`;
- Trainer Battle Session run: `33984353021`;
- artifact: `9974691896`;
- literal: **`66 PASS / 0 FAIL`**;
- Trainer Team Composition run: `33984353115`;
- artifact: `9974754938`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- **0 `SCRIPT ERROR`**, **0 traceback** en los seis logs test/import inspeccionados de las tres superficies.

Los tres logs de test relevantes son byte-idénticos técnico↔humano:

- Evaluation Corpus: `sha256:c94427dc01cfd8c4893b1eaa6db89222d313061cb093318ea9aee881818e7a6a`;
- Battle Session: `sha256:123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Team Composition: `sha256:996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`.

No se observa nondeterminismo técnico↔humano.

### 26.63.5 Semántica terminal-horizon certificada

`TrainerMultiTurnSearch` conserva la profundidad física real y añade una marca branch-local:

`terminal_horizon_closed = fork.state() != null and fork.state().phase == BattleState.FINISHED`

A partir de ahí calcula metadata explícita:

- `required_horizon_branch_count`;
- `terminal_horizon_closed_branch_count`;
- `required_horizon_complete_branch_count`;
- `required_horizon_complete`.

Una rama satisface el horizonte solicitado únicamente si:

1. alcanza físicamente la profundidad pedida; **o**
2. el estado posterior a esa rama está realmente `FINISHED`.

La completitud global continúa exigiendo matriz/world coverage completa y `budget_exhausted = false`.

No se falsean las métricas físicas:

- una rama terminal en el primer ply conserva `max_depth_reached = 1`;
- conserva `fully_completed_depth = 1`;
- no se simula un segundo ply inexistente.

`TrainerItemAwareActionProposal` separa ahora:

- `common_depth = 2` como **horizonte contractual** que sigue exigiendo la frontera de `TrainerBattleSession`;
- `common_physical_depth` como profundidad física mínima realmente ejecutada.

La resolución de cinco argumentos puede aceptar un root físico depth1 solo cuando el mapa explícito `root_horizon_complete` certifica su cierre. La forma legacy de cuatro argumentos continúa exigiendo depth2 físico y no gana una relajación implícita.

### 26.63.6 Frontera terminal exacta ya resuelta

En la reproducción de victoria C3f-an:

1. los dos primeros turnos autónomos siguen teniendo éxito;
2. Battle Core sigue ejecutando exactamente dos forced replacements autoritativos de `side_b`;
3. la memoria dual permanece coherente y fresca;
4. el tercer preflight produce ahora `PROPOSAL_READY`.

En ese tercer preflight:

- `required_depth = 2`;
- `common_depth = 2` contractual;
- `common_physical_depth = 1`;
- `move:c3fad_chip_b`: depth físico **1**, horizon complete `true`, depth2 `false`, terminal-horizon-closed `true`, score `-40000`;
- `move:c3fad_setup_b`: depth **2**, terminal-horizon-closed `false`, score `-82000`;
- `item:hyper_potion:c3fae_b2`: depth **2**, terminal-horizon-closed `false`, score `-82000`;
- `item:potion:c3fae_b2`: depth **2**, terminal-horizon-closed `false`, score `-82000`.

El root seleccionado continúa siendo de forma única:

`move:c3fad_chip_b`

No aparece ningún nuevo tiebreak ni fallback.

La llamada:

`submit_player_action_with_autonomous_trainer(player_action)`

obtiene `SUBSTITUTION_READY`, no usa caller side_b ni fallback, llega a `BattleState.FINISHED`, produce ganador `side_a` y `settle_finished_battle()` liquida correctamente como `VICTORY`.

El control histórico explícito continúa llegando a victoria + settlement y el control autónomo de derrota continúa llegando a `FINISHED`, ganador `side_b` y settlement `DEFEAT`.

### 26.63.7 Fail-closed y controles adversariales preservados

C3f-ao demuestra simultáneamente:

- terminal depth1 real con `FINISHED` → horizonte completo;
- nonterminal depth1 → bloqueado;
- budget exhaustion → bloqueado;
- partial matrix/world coverage → bloqueado;
- conjunto mixto depth1-terminal + depth2 → resolución determinista;
- control normal depth2 → `PROPOSAL_READY`, todos los roots horizon-complete y **ningún root etiquetado como cierre terminal anticipado**.

Siguen sin usarse:

- lexical tiebreak;
- input-order tiebreak;
- kind priority;
- sampler/RNG fallback;
- Pareto/frontier fallback;
- roster/Profile fallback;
- campaign/recovery/replacement policy;
- scheduler/shared budget/660.

Siguen `null`:

- `selected_strategy_id`;
- `selected_scheduler_id`;
- `selected_shared_budget`.

FASE34 permanece **CLOSED**.

### 26.63.8 Frontera lifecycle que todavía falta

C3f-ao ya certifica autonomía a través de:

- turnos ordinarios;
- KO;
- forced replacement de Battle Core;
- continuidad de memoria;
- victoria terminal;
- derrota terminal;
- `FINISHED`;
- settlement.

Sin embargo, la autorización original de 26.61 incluía además dos fronteras que C3f-an y C3f-ao **no ejecutan**:

`reset_after_completion()`

y el comienzo de **una segunda batalla sobre la misma instancia `TrainerBattleSession`**.

La inspección actual confirma que la suite C3f-ao no llama `reset_after_completion()` y que C3f-an tampoco cubre contaminación cross-battle. Por tanto todavía no existe evidencia end-to-end de que battle id, memoria, reports/toggles o proposals de la batalla terminada no puedan contaminar la siguiente batalla autónoma.

No se interpreta esto como un bug. Es una frontera todavía **NO AUDITADA**.

### 26.63.9 Siguiente microtranche autorizada: C3f-ap reset + segunda batalla lifecycle audit-only

**C3f-ap — auditar estrictamente TEST/AUDIT-ONLY que una `TrainerBattleSession` que termina y liquida una batalla autónoma puede pasar por `reset_after_completion()`, volver a `READY`, comenzar una segunda batalla limpia y ejecutar autonomía fresca sin contaminación de battle id, memoria, reports, toggles, roots, scores, proposals ni acciones de la batalla anterior; no modificar producción dentro de esta tranche.**

C3f-ap deberá comprobar como mínimo:

1. una victoria autónoma C3f-ao llega a `FINISHED` y settlement `VICTORY`;
2. después del settlement: `status = COMPLETED`, `_battle_server` ya no está activo, memory wiring no está READY y los reports/toggles Trainer públicos observables están limpios/OFF;
3. `reset_after_completion()` tiene éxito exclusivamente desde el estado completado válido;
4. control negativo: reset antes de completion falla cerrado con `session_not_completed` y no altera la batalla activa/READY;
5. después del reset: `status = READY`, `completion_reason` vacío y `opponent_trainer_id` vacío;
6. no queda report shadow/proposal/substitution de la batalla anterior;
7. no queda toggle shadow/proposal/substitution activado por la batalla anterior;
8. comenzar una segunda batalla sobre la **misma instancia de sesión** tiene éxito con identidad de entrenador distinta y estado nuevo;
9. la segunda batalla empieza en turn 0 y con battle id correspondiente únicamente al nuevo entrenador;
10. la memoria dual de la segunda batalla queda READY desde el nuevo estado y no contiene observaciones/eventos/instance ids exclusivos de la batalla anterior;
11. el primer proposal de `side_b` de la segunda batalla se calcula fresco contra el actor y legal action space actuales;
12. no se reutilizan root ids/scores/report/action por cache cross-battle; cualquier coincidencia de valor deberá estar respaldada por cálculo fresco, no identidad de objeto/reporte anterior;
13. una acción autónoma válida de la segunda batalla obtiene `SUBSTITUTION_READY` y avanza autoritativamente sin caller side_b;
14. un proposal/reporte conservado deliberadamente de la primera batalla, si se presenta a la frontera de validación, queda bloqueado por battle/turn/context mismatch y no avanza turno;
15. el método histórico continúa conservando su contrato independiente después del reset;
16. forced replacement continúa siendo propiedad exclusiva de Battle Core;
17. no se introduce `replacement_policy_used`, recovery/campaign semantics ni defaults entre batallas;
18. producción, Battle Core, brains, sampler, search budget y phase logic permanecen **0 cambios** durante C3f-ap;
19. no se abre autonomía global/default, Trainer Brain general, scheduler/shared budget/660 ni FASE34;
20. PR #105 permanece OPEN/unmerged y `main` no se toca;
21. si aparece un blocker real, C3f-ap debe **localizarlo causalmente y detenerse**; cualquier corrección productiva requerirá otra tranche explícitamente autorizada;
22. antes de un freeze posterior se exigirán checkpoint técnico y humano siblings/tree-identical con **18/18 workflows SUCCESS**.

Resultados admisibles C3f-ap:

- `AUTONOMOUS_CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED`;
- `AUTONOMOUS_CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`;
- `AUTONOMOUS_CROSS_BATTLE_RESET_BLOCKER_CONFIRMED`;
- `NEEDS_MORE_VALIDATION`;
- `BLOCKED`.

Incluso un C3f-ap validado **NO** autoriza por sí solo autonomía por defecto ni Trainer Brain general. El freeze posterior deberá decidir si la siguiente frontera es ya localizar/auditar el caller/integration point real del juego o si queda alguna frontera lifecycle objetiva adicional.

### 26.63.10 Invariantes externas

PR #105 debe continuar **OPEN / unmerged**.

`main` debe continuar exactamente en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

C3f-ao queda por tanto **DOBLEMENTE CERTIFICADA** como `TERMINAL_HORIZON_COMPLETENESS_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`; la única siguiente frontera autorizada es C3f-ap reset + segunda batalla lifecycle audit-only bajo las barreras anteriores.
'''


def run(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def die(msg: str) -> None:
    print(f"FREEZE_ABORT: {msg}", file=sys.stderr)
    sys.exit(2)


branch = os.environ.get("GITHUB_REF_NAME", "")
if branch != "audit/trainer-ai-v3-random-cup-redesign-v1":
    die(f"unexpected branch {branch!r}")

if subprocess.call(["git", "merge-base", "--is-ancestor", BASE, "HEAD"]) != 0:
    die("expected human checkpoint is not an ancestor")

if not NOTEBOOK.exists():
    die("TRAINER_AI.md missing")

actual_blob = run("git", "hash-object", str(NOTEBOOK))
if actual_blob != EXPECTED_NOTEBOOK_BLOB:
    die(f"notebook drift: {actual_blob}")

changed_since_base = set(filter(None, run("git", "diff", "--name-only", BASE, "HEAD").splitlines()))
if changed_since_base != HELPERS:
    die(f"unexpected pre-freeze diff: {sorted(changed_since_base)}")

text = NOTEBOOK.read_text(encoding="utf-8")
if "## 26.62 — Freeze C3f-an" not in text:
    die("26.62 anchor missing")
if "## 26.63 — Freeze C3f-ao" in text:
    die("26.63 already present")

NOTEBOOK.write_text(text.rstrip() + "\n\n" + FREEZE.strip() + "\n", encoding="utf-8")
for helper in HELPERS:
    p = Path(helper)
    if p.exists():
        p.unlink()

subprocess.check_call(["git", "config", "user.name", "github-actions[bot]"])
subprocess.check_call(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"])
subprocess.check_call(["git", "add", "-A"])
staged = set(filter(None, run("git", "diff", "--cached", "--name-only").splitlines()))
expected_staged = set(HELPERS) | {str(NOTEBOOK)}
if staged != expected_staged:
    die(f"unexpected staged paths: {sorted(staged)}")

subprocess.check_call(["git", "commit", "-m", "docs(trainer-ai): freeze 26.63 C3f-ao terminal horizon completeness"])
subprocess.check_call(["git", "push", "origin", f"HEAD:{branch}"])
print("FREEZE_26_63_WRITTEN_AND_HELPERS_REMOVED")
