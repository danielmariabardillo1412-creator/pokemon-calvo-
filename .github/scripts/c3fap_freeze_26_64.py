from pathlib import Path
import subprocess
import sys

BASE = "70c02c9658cc71888548e974a7ca600fa6eb297d"
NOTEBOOK = Path("docs/project_book/TRAINER_AI.md")
EXPECTED_NOTEBOOK_BLOB = "d6b2e4f10d6854c2ab439f59cc3763e172e99e01"
HELPERS = {
    ".github/scripts/c3fap_freeze_26_64.py",
    ".github/workflows/c3fap-freeze-26-64.yml",
    ".c3fap-freeze-26-64-trigger",
}

FREEZE = r'''

## 26.64 — Freeze C3f-ap: reset + segunda batalla autónoma doblemente certificados; lifecycle interno cerrado

Estado: **FREEZE DOCUMENTAL / C3f-ap DOBLEMENTE CERTIFICADA / RESET + REUSE SAME SESSION VALIDADO / SEGUNDA BATALLA AUTÓNOMA FRESCA / STALE PROPOSAL CROSS-BATTLE FAIL-CLOSED / 0 PRODUCCIÓN / LIFECYCLE INTERNO CERRADO / SIGUIENTE FRONTERA = CALLER REAL DEL JUEGO**.

C3f-ap ejecuta exactamente la auditoría TEST/AUDIT-ONLY autorizada por 26.63. La misma instancia `TrainerBattleSession` completa una victoria autónoma, liquida la batalla, limpia memoria/reportes/toggles, rechaza un reset prematuro, acepta `reset_after_completion()` únicamente desde `COMPLETED`, vuelve a `READY`, arranca una segunda batalla con identidad y roster distintos, reconstruye memoria/proposal desde el estado nuevo y ejecuta autonomía fresca sin reutilizar estado de la batalla anterior.

No apareció ningún blocker productivo. No fue necesario modificar producción, Battle Core, brains, sampler, search budget ni phase logic.

### 26.64.1 Genealogía y scope exacto

Freeze documental 26.63:

`3e13dd3f9acfaf57b715ac9f720f4a8fb2e21732`

Checkpoint técnico C3f-ap:

`4669a496987ad5f95344116466b17d8b013d2779`

Checkpoint humano sibling C3f-ap:

`70c02c9658cc71888548e974a7ca600fa6eb297d`

Los dos checkpoints son siblings reales:

- parent común: `3e13dd3f9acfaf57b715ac9f720f4a8fb2e21732`;
- tree común: `f5c8adf9068df09d6edb2085a1a8557df500d8c0`;
- ninguno desciende del otro;
- contenido técnico y humano idéntico a nivel Git tree.

Diff neto exacto 26.63 → C3f-ap:

- `tests/trainer_ai/trainer_battle_session_cross_battle_reset_lifecycle_audit_test_suite.gd`: **+415 / -0**;
- `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd`: **+1 / -0**;
- total: **+416 / -0**;
- producción: **0 cambios**;
- `TrainerBattleSession`: **0 cambios**;
- Battle Core: **0 cambios**;
- brains: **0 cambios**;
- sampler: **0 cambios**;
- search budget: **0 cambios**;
- phase logic: **0 cambios**;
- docs/workflows dentro del tranche certificado: **0 cambios**.

Existió antes un candidato de test no canónico `2f6a57124cd4d68bc7160dd90f4b5a2b2ab3edf2` → `668fe832204edae55f18cfab78e5026b090be428`. No se certificó porque, aunque era test-only, no cubría todas las fronteras fail-closed exigidas por 26.63 —en particular reset prematuro y replay explícito de una proposal preservada de la primera batalla— y usaba un aggregate fuera de la lista autorizada. Se descarta como diseño de auditoría incompleto, no como fallo del producto.

### 26.64.2 Certificación técnica C3f-ap

Checkpoint técnico `4669a496987ad5f95344116466b17d8b013d2779`:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus run: `33999459902`;
- artifact: `9979050622`;
- literal: **`243 PASS / 0 FAIL`**;
- **34/34 checks C3f-ap PASS**;
- aggregate: `AUTONOMOUS_CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`;
- artifact digest: `sha256:3a61a938c5f2fea21ccca4775233a7c0b5ff3675816198a28046cc476e90b17e`;
- Evaluation test log: `sha256:cbd53994e43d4ec5f7c356c631d8eb827419b6df9b4839c7f0521a03632a2b59`;
- Trainer Battle Session run: `33999459914`;
- artifact: `9979048799`;
- literal: **`66 PASS / 0 FAIL`**;
- Battle test log: `sha256:123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Trainer Team Composition run: `33999459884`;
- artifact: `9979101578`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- Team test log: `sha256:996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- sin `SCRIPT ERROR` ni traceback en los artefactos Eval/Battle/Team inspeccionados.

### 26.64.3 Certificación humana sibling C3f-ap

Checkpoint humano `70c02c9658cc71888548e974a7ca600fa6eb297d`:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus run: `33999730033`;
- artifact: `9979124774`;
- literal: **`243 PASS / 0 FAIL`**;
- mismos **34/34 checks C3f-ap PASS**;
- mismo aggregate: `AUTONOMOUS_CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`;
- artifact digest: `sha256:ab7c51e5be42e22cbe51362e2300098bea6e61c0f874c4d606ef42c770b6cd37`;
- Evaluation test log: `sha256:cbd53994e43d4ec5f7c356c631d8eb827419b6df9b4839c7f0521a03632a2b59`;
- Trainer Battle Session run: `33999730030`;
- artifact: `9979122574`;
- literal: **`66 PASS / 0 FAIL`**;
- Battle test log: `sha256:123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`;
- Trainer Team Composition run: `33999730064`;
- artifact: `9979171878`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- Team test log: `sha256:996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- sin `SCRIPT ERROR` ni traceback en los artefactos Eval/Battle/Team inspeccionados.

Los tres logs de test relevantes son byte-idénticos técnico↔humano. No se observa nondeterminismo entre siblings.

### 26.64.4 Lifecycle cross-battle certificado

La primera batalla demuestra nuevamente el camino autónomo ya certificado por C3f-ao:

1. los dos primeros turnos autónomos tienen éxito;
2. el tercer turno autónomo terminal tiene éxito;
3. Battle Core llega a `FINISHED` con ganador `side_a`;
4. `settle_finished_battle()` devuelve settlement válido, `player_won = true` y `completion_reason = VICTORY`.

Antes del submit terminal se conserva deliberadamente una proposal válida de la primera batalla. Esa proposal queda ligada a su `battle_id` y turno originales para el control cross-battle posterior.

Tras settlement:

- `status = COMPLETED`;
- no existe batalla activa;
- `battle_state() == null`;
- memory wiring deja de estar READY;
- los snapshots de memoria públicos dejan de estar disponibles;
- shadow/proposal/substitution reports están vacíos;
- shadow/proposal/substitution toggles quedan OFF.

### 26.64.5 Reset fail-closed y reset válido

C3f-ap incluye un control negativo independiente que llama `reset_after_completion()` mientras otra sesión sigue en batalla activa. El resultado es exactamente:

- `reset_ok = false`;
- `last_error = session_not_completed`;
- mismo `battle_id` antes/después;
- mismo turno antes/después;
- la batalla sigue activa;
- trainer memory continúa READY.

Por tanto reset no puede cortar silenciosamente una batalla viva.

En la sesión completada, `reset_after_completion()` sí tiene éxito y deja:

- `status = READY`;
- `completion_reason` vacío;
- `opponent_trainer_id` vacío;
- sin Battle Server activo;
- sin memory wiring;
- reports vacíos;
- toggles OFF.

### 26.64.6 Segunda batalla fresca sobre la misma sesión

La segunda batalla usa la **misma instancia `TrainerBattleSession`**, pero un entrenador distinto:

`c3fap_second_trainer`

Su battle id es nuevo y la batalla arranca en turn 0.

El roster rival usa IDs nuevos:

- `c3fap_second_b0`;
- `c3fap_second_b1`;
- `c3fap_second_b2`.

Los IDs exclusivos de la primera batalla (`c3fae_b0`, `c3fae_b1`, `c3fae_b2`) no aparecen como vistos en la memoria nueva.

Los dos `TrainerBattleMemory` nacen ligados únicamente al nuevo battle id, con lados correctos. El primer proposal `side_b` de la segunda batalla:

- es `PROPOSAL_READY`;
- está ligado al nuevo battle id;
- está ligado a turn 0;
- tiene `context_side_matching = true`;
- evalúa exactamente todos sus roots legales actuales;
- su actor coincide con el `side_b` activo de la segunda batalla;
- la acción propuesta es detached.

### 26.64.7 Stale proposal de batalla 1 bloqueada explícitamente

La proposal preservada deliberadamente de la primera batalla se entrega directamente al validador de sustitución mientras la segunda batalla está activa.

El resultado certificado es:

- `substitution_status = BLOCKED`;
- `blocked_reason = proposal_battle_mismatch`;
- `submitted_action = null`;
- `caller_fallback_used = false`;
- el turno de la segunda batalla no avanza.

Esto demuestra que incluso una proposal que fue válida y READY en su batalla original no puede cruzar la frontera de identidad hacia una batalla posterior.

### 26.64.8 Autonomía fresca e histórico preservado en batalla 2

Después del control stale, la segunda batalla ejecuta una acción mediante:

`submit_player_action_with_autonomous_trainer(player_action)`

El resultado es:

- proposal fresca;
- `SUBSTITUTION_READY`;
- ningún caller side_b;
- ningún caller fallback;
- avance autoritativo de turno;
- forced switch, si aparece, continúa marcado/autorizado por Battle Core;
- memoria actualizada contra el nuevo battle id.

A continuación el control histórico `submit_player_action(player_action, opponent_action)` sigue funcionando de forma independiente y no materializa proposal/substitution reports cuando sus toggles permanecen OFF.

El source trace confirma además que `begin_battle()` construye un `TrainerDualSideBattleMemoryOwner.new()` y que cada consulta de proposal construye un `TrainerItemAwareActionProposal.new()`: no existe una cache cross-battle escondida en esas fronteras.

### 26.64.9 Decisión: lifecycle interno cerrado

C3f-ap queda **DOBLEMENTE CERTIFICADA** como:

`AUTONOMOUS_CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`

Con C3f-ao + C3f-ap ya existe evidencia end-to-end del lifecycle interno de `TrainerBattleSession` a través de:

- turnos autónomos ordinarios;
- KO;
- forced replacement autoritativo;
- memoria continua dentro de batalla;
- victoria y derrota;
- horizonte terminal;
- `FINISHED`;
- settlement;
- limpieza post-settlement;
- reset fail-closed;
- reset válido;
- segunda batalla en la misma sesión;
- memoria/proposal frescas;
- rechazo de proposal cross-battle stale;
- autonomía nueva en la segunda batalla;
- preservación de la API histórica.

No queda justificado abrir nuevas auditorías internas de lifecycle por mera precaución. Cualquier microtranche adicional antes de integración deberá estar motivada por un blocker real reproducido, no por ampliar indefinidamente la superficie auditada.

### 26.64.10 Contador de cierre

El plan de cierre visible queda ahora en:

- **1/4 — C3f-ap reset + segunda batalla: COMPLETADO**;
- **2/4 — C3f-aq caller/integration point real: SIGUIENTE**;
- **3/4 — C3f-ar integración real de autonomía Trainer: PENDIENTE**;
- **4/4 — cierre E2E + regresiones + freeze final: PENDIENTE**.

Por tanto quedan **3 pasos finales planificados**, salvo que una prueba futura demuestre un blocker real que obligue a una corrección adicional.

### 26.64.11 Siguiente microtranche autorizada: C3f-aq caller/integration-point audit

**C3f-aq — localizar y auditar TEST/AUDIT/TRACE-ONLY el caller real del juego que crea/posee `TrainerBattleSession` y suministra actualmente las acciones de `side_b`, identificar una única costura de integración para sustituir exclusivamente el suministro externo de la acción rival por `submit_player_action_with_autonomous_trainer(player_action)` en combates de entrenador, y demostrar que wild battle/capture/run y demás flujos no Trainer quedan fuera de esa costura. No modificar todavía comportamiento de producción.**

C3f-aq deberá producir como mínimo:

1. cadena concreta de archivos/clases/métodos desde gameplay/controller/application hasta `TrainerBattleSession.begin_battle(...)`;
2. cadena concreta del submit de turno y punto donde hoy se obtiene/pasa `opponent_action`;
3. evidencia de ownership/lifetime de `TrainerBattleSession` y de quién decide cuándo resetear/recrear una sesión;
4. discriminación inequívoca entre trainer battle y wild battle;
5. evidencia de que capture/run no atraviesan el seam Trainer;
6. una **única** recomendación de integration seam para C3f-ar, no una lista abierta de arquitecturas alternativas;
7. inventario mínimo de archivos de producción que C3f-ar necesitaría tocar;
8. controles que demuestren que el seam no exige activar globalmente autonomía ni modificar Battle Core;
9. determinar explícitamente si el Trainer Brain general es realmente necesario para esa integración; si no lo es, debe permanecer cerrado;
10. mantener scheduler/shared budget/660 y FASE34 CLOSED;
11. producción **0 cambios** durante C3f-aq;
12. PR #105 OPEN/unmerged y `main` intacto;
13. si el caller real no existe todavía o el flujo Trainer no está conectado al gameplay, localizar exactamente esa ausencia y convertirla en el seam mínimo de C3f-ar, sin abrir nuevas auditorías laterales;
14. checkpoints técnico/humano siblings y 18/18 solo si C3f-aq añade test/trace ejecutable al repo; si la evidencia resulta puramente documental/source-trace, el freeze deberá documentar explícitamente por qué no se fabricó CI artificial.

Resultados admisibles:

- `TRAINER_BATTLE_CALLER_INTEGRATION_SEAM_VALIDATED`;
- `TRAINER_BATTLE_CALLER_INTEGRATION_SEAM_VALIDATED_WITH_ISOLATION_BOUNDARY`;
- `TRAINER_BATTLE_CALLER_MISSING_SEAM_LOCALIZED`;
- `BLOCKED`.

Si C3f-aq valida o localiza el seam sin blocker productivo adicional, **el siguiente paso debe ser C3f-ar integración real**, no otra auditoría interna intermedia.

### 26.64.12 Invariantes externas

PR #105 continúa **OPEN / unmerged**.

`main` continúa exactamente en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

C3f-ap queda cerrada. La única siguiente frontera autorizada es C3f-aq caller/integration-point audit bajo el plan de cierre de tres pasos restantes.
'''


def run(*args):
    return subprocess.check_output(args, text=True).strip()


head = run("git", "rev-parse", "HEAD")
parent = run("git", "rev-parse", "HEAD^")
if parent != BASE:
    raise SystemExit(f"unexpected helper parent: {parent} != {BASE}")

blob = run("git", "rev-parse", f"HEAD:{NOTEBOOK.as_posix()}")
if blob != EXPECTED_NOTEBOOK_BLOB:
    raise SystemExit(f"unexpected notebook blob: {blob} != {EXPECTED_NOTEBOOK_BLOB}")

text = NOTEBOOK.read_text(encoding="utf-8")
if "## 26.64 — Freeze C3f-ap" in text:
    raise SystemExit("26.64 already present")
if "C3f-ao queda por tanto **DOBLEMENTE CERTIFICADA**" not in text:
    raise SystemExit("26.63 tail marker missing")

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

subprocess.check_call(["git", "commit", "-m", "docs(trainer-ai): freeze 26.64 C3f-ap cross-battle lifecycle"])
subprocess.check_call(["git", "push", "origin", "HEAD:audit/trainer-ai-v3-random-cup-redesign-v1"])
print("C3FAP_FREEZE_26_64_WRITTEN")
