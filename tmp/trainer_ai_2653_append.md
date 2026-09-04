

---

## 26.53 — Freeze C3f-ae: wiring productivo dual side-specific desde battle start certificado; search/comportamiento sigue cerrado

Estado: **FREEZE DOCUMENTAL / C3f-ae CERTIFICADA / WIRING PRODUCTIVO ACTIVO / DECISIÓN DE COMPORTAMIENTO TODAVÍA CERRADA**.

Este freeze cierra C3f-ae después de certificar por separado un checkpoint técnico y un checkpoint humano tree-identical. El tranche introduce por primera vez producción real en esta cadena C3f, pero su alcance está deliberadamente limitado a ownership/lifecycle de memoria side-specific y a un seam read-only para futura integración de search. No selecciona acciones, no invoca brains/search y no activa `depth1_margin_3000_all_legal` como política de comportamiento.

### 26.53.1 Baseline, genealogía y diff exacto

Baseline exclusivo — freeze 26.52 certificado:

`1140f3c76c29e1765ae26f4be8594301e9fe763c`

Checkpoint técnico C3f-ae:

`8e7168712c4e85b1fdb0294065d82e0b4cd53159`

Checkpoint humano C3f-ae:

`2c92151d2b1ce04db2990647ad8bbea9e6e5f68c`

Los checkpoints técnico y humano son siblings reales:

- parent común: `1140f3c76c29e1765ae26f4be8594301e9fe763c`;
- tree común: `1fcf7e34b6346927ea5b2faa751321d27c197bfc`;
- ninguno desciende del otro.

Diff exacto contra 26.52:

- `modules/gameplay/trainer_battle_session.gd`: **+46 / -3**;
- `modules/trainer_ai/trainer_dual_side_battle_memory_owner.gd`: **+124 / -0**;
- `tests/trainer_ai/trainer_roster_dual_side_memory_production_wiring_audit_test_suite.gd`: **+398 / -0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**.

Superficie productiva de C3f-ae:

- `TrainerBattleSession`;
- nuevo `TrainerDualSideBattleMemoryOwner`.

Superficie productiva que NO se modifica:

- brains;
- `TrainerMultiTurnSearch`;
- `TrainerItemAwareSearch`;
- sampler productivo;
- budgets productivos;
- scheduler;
- phase logic;
- switching policy productiva.

### 26.53.2 Certificación técnica y humana

C3f-ae añade exactamente **25 checks** sobre los **1102** de C3f-ad:

`1102 + 25 = 1127`

Checkpoint técnico:

- **18/18 workflows SUCCESS**;
- Trainer Battle Session: **`66 PASS / 0 FAIL`**;
- FASE33 literal: **`1127 PASS / 0 FAIL`**;
- 25/25 checks C3f-ae PASS;
- **0 `SCRIPT ERROR`**;
- **0 traceback**;
- **0 líneas `FAIL`**;
- `tranche_status = WIRED_NO_BEHAVIOR_INTEGRATION`.

Checkpoint humano:

- **18/18 workflows SUCCESS**;
- Trainer Battle Session: **`66 PASS / 0 FAIL`**;
- FASE33 literal: **`1127 PASS / 0 FAIL`**;
- 25/25 checks C3f-ae PASS;
- **0 `SCRIPT ERROR`**;
- **0 traceback**;
- **0 líneas `FAIL`**;
- `tranche_status = WIRED_NO_BEHAVIOR_INTEGRATION`.

El log `trainer-team-composition-test.log` es byte-idéntico entre técnico y humano:

`sha256:faa59fdf0431f78e768a0bfc5a449d2366318ee794890959c51c0f045a78094c`

No se observa nondeterminismo entre ambos checkpoints.

### 26.53.3 Ownership dual desde battle start

C3f-ae añade `TrainerDualSideBattleMemoryOwner` como owner trusted de exactamente dos memorias:

- `side_a`;
- `side_b`.

El owner se inicializa como parte de `TrainerBattleSession.begin_battle()` antes de declarar la sesión `BATTLE_ACTIVE`. Cada `TrainerBattleMemory` comienza con el mismo `battle_id` y con su `observer_side_id` correcto desde el inicio de la batalla.

Si no pueden inicializarse las dos memorias de forma válida, `begin_battle()` falla cerrado con:

`trainer_memory_initialization_failed`

No existe bootstrap histórico retroactivo a mitad de batalla.

### 26.53.4 Fan-out autoritativo y aislamiento side-specific

Después de cada turno aceptado por Battle Core, `TrainerBattleSession` entrega el mismo lote autoritativo de `BattleEvent` al owner dual.

El fan-out es atómico a nivel de memoria:

1. clona ambas memorias live;
2. proyecta el mismo lote trusted sobre cada clone mediante `TrainerBattleMemory.observe_events()`;
3. cada memoria aplica su filtrado side-specific existente;
4. solo si ambas proyecciones tienen éxito sustituye las dos memorias live.

El audit ejecutado confirma:

- `authoritative_event_count = 5` en el turno de prueba;
- ambas memorias reciben el mismo envelope público de eventos;
- el reveal map de `side_a` aprende movimientos del rival y no los propios como conocimiento rival;
- el reveal map de `side_b` aplica la perspectiva inversa correctamente;
- generic metadata cruda y `source_id` no se persisten en el event log público de memoria;
- `side_a_reveal_isolated = true`;
- `side_b_reveal_isolated = true`;
- `public_log_metadata_sanitized = true`.

Si el lifecycle dual no está listo antes de un turno, la sesión falla cerrado con:

`trainer_memory_not_ready`

y el turno no avanza.

### 26.53.5 Seam read-only hacia futura integración de search

`TrainerBattleSession` expone únicamente snapshots detached:

- `trainer_memory_snapshot_for_side(side_id)`;
- `trainer_branch_memory_snapshot_for_side(side_id, events, branch_state)`;
- `trainer_memory_wiring_ready()`.

La memoria live mutable del owner no se entrega fuera de la capa trusted.

El audit demuestra:

- un snapshot devuelto puede mutarse/limpiarse sin alterar el owner live;
- un side inválido devuelve `null`;
- un branch snapshot parte de un clone de la memoria live;
- los eventos branch-local se proyectan únicamente sobre ese clone;
- mutar o limpiar el branch snapshot no altera las memorias live;
- un side inválido de branch falla cerrado.

Por tanto existe ya un **seam search-facing de lectura**, pero este freeze NO afirma que `TrainerMultiTurnSearch` o `TrainerItemAwareSearch` estén conectados a la sesión. Ninguna de esas clases fue modificada en C3f-ae.

### 26.53.6 Prueba de ausencia de integración de comportamiento

C3f-ae mantiene deliberadamente el contrato histórico de `TrainerBattleSession.submit_player_action()`:

- `player_action` sigue siendo obligatorio;
- `opponent_action` sigue siendo obligatorio;
- la sesión no tiene `choose_opponent_action()`;
- la sesión no tiene `choose_trainer_action()`;
- el owner dual no contiene brain, search, policy, sampler ni action-selection logic.

El audit prueba explícitamente que omitir `opponent_action`:

- devuelve cero eventos;
- produce `opponent_action_required`;
- no avanza el turno.

Campos canónicos:

- `production_wiring_present = true`;
- `behavior_integration_authorized = false`;
- `margin3000_behavior_enabled = false`;
- `production_sampler_modified = false`;
- `production_budget_modified = false`;
- `selected_strategy_id = null`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `shared_660_reopened = false`;
- `fase34_open = false`.

Resultado de tranche:

`WIRED_NO_BEHAVIOR_INTEGRATION`

### 26.53.7 Barreras que permanecen cerradas

C3f-ae NO autoriza todavía:

- que la sesión elija la acción del entrenador;
- activar `depth1_margin_3000_all_legal` como comportamiento;
- cambiar el sampler;
- cambiar budgets;
- seleccionar scheduler o reabrir 660;
- cambiar root fanout all-legal;
- cambiar inner cap3;
- introducir score cross-kind MOVE/SWITCH/ITEM;
- lexical/frontier/Pareto/roster/Profile/campaign/recovery/replacement como fallback;
- abrir FASE34;
- mergear PR #105.

Se mantienen MOVE/SWITCH/ITEM separados y `candidate_strategy_proven_safe_globally = false` para la evidencia margin3000 previa.

### 26.53.8 Siguiente frontera autorizada: C3f-af shadow search sobre lifecycle productivo

Una vez este freeze 26.53 obtenga CI completo limpio, se autoriza exclusivamente:

**C3f-af — integrar el seam dual side-specific de `TrainerBattleSession` con construcción role-local sanitizada y ejecución `TrainerItemAwareSearch` en modo shadow/read-only, sin alterar todavía la acción enviada a Battle Core.**

Objetivo: demostrar en lifecycle productivo real que el search puede consumir únicamente la memoria legítima de cada perspectiva y reproducir el contrato C3f-ac/C3f-ad sin fuga de información, antes de permitir que su resultado influya en una decisión.

C3f-af deberá:

1. consumir únicamente snapshots detached obtenidos del owner dual certificado;
2. construir observación, belief y `TrainerDecisionContext` side-matching para la perspectiva solicitada;
3. para continuaciones, utilizar branch snapshots clonados y eventos exclusivamente branch-local;
4. ejecutar `TrainerItemAwareSearch` role-local en shadow y registrar scores/candidatos SWITCH sin sustituir la acción real existente;
5. mantener `margin3000` SWITCH-only y comparar shadow margin3000 contra referencia all-legal dentro de los casos ejecutados;
6. probar que shadow on/off produce exactamente la misma acción enviada a Battle Core y el mismo estado/event stream autoritativo;
7. fallar cerrado ante lifecycle incompleto, side mismatch o contexto no sanitizable;
8. conservar root fanout all-legal separado del inner cap3;
9. mantener MOVE/SWITCH/ITEM separados;
10. no seleccionar scheduler, shared budget ni 660;
11. no introducir fallbacks prohibidos;
12. mantener FASE34 cerrada.

C3f-af NO podrá todavía:

- reemplazar `opponent_action` por una acción elegida por search;
- activar margin3000 como policy productiva que cambie comportamiento;
- modificar sampler/budget/scheduler/phase logic;
- afirmar seguridad global a partir de la telemetría shadow;
- abrir FASE34;
- mergear PR #105.

Solo un freeze posterior, apoyado en evidencia shadow limpia, podrá decidir si se autoriza la primera integración de comportamiento real.
