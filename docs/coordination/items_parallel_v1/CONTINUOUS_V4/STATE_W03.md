# IA3/W03 — CONTINUOUS_V4 STAGING · ENTREGA NATIVA CERTIFICADA / BLOQUEOS PROTEGIDOS

- **worker / staging**: W03 / `codex/calvo-ia6-staging-20261111-w03-capture`; base IA6 `e63b2e6c7e175fba318cc2f562bebd1769589092`.
- **mission_version**: `CONTINUOUS_V4/PLAN_W03.md` de rama árbitra. No se tocaron main, V28, PR118, rama integradora IA6 ni ramas de otras W.
- **phase**: A COMPLETADA (diff por función); B CERTIFICADA para **Showdown nativo**; C REPORTE/TICKETS FINALIZADOS, **regresión total BLOQUEADA** por seam legacy fuera de autorización.
- **new_object_ids**: 0. **newly_ported_native_effects**: Repeat x3.5 desde ledger exitoso autenticado y Moon x4 desde evolución Stone del catálogo. Net x3.5 **ya existía** en base IA6, no duplicada.
- **last_green_stage_code_sha**: `0cb612cd548ee47ff66fabf85472e64e10951a28`.
- **last_green_stage_ci**: [42965463520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965463520) `completed/success` en el SHA exacto de código. Su job tiene 18 pasos SUCCESS y 0 fallidos; **NO equivale a suite completa de regresión**, porque detecta y registra fallo conocido `WildAdventureSession`.
- **qa_native_stage**: Repeat 26 PASS + negativos 18 PASS; Net 79 PASS + negativos 19 PASS; Moon 41 PASS (2 capturas); SaveV2 40 PASS + adversarial 8 PASS; mint native 18 PASS; IA6 mint+rope 65 PASS; bag libros 20 PASS; fuente Python 34 checks, datos 1082 especies.
- **red_legacy_explicit**: `W03_REPEAT_V2_GODOT FAIL checks=37`, **6 aserciones rojas reales** en ruta `WildAdventureSession` **no editada por falta de permiso**. La CI publica `W03_V4_LEGACY_WILD BLOCKED_AUTHORIZATION_WILD_ADVENTURE_SESSION NOT_PASS`; sin falsear histórico. Ticket `CONTINUOUS_V4/W03_WILD_LEGACY_GAP.md`.
- **repel_shared_gap**: `FieldItemBag` IA6 tiene libros W05 y cuerda; faltan hunk Repel y origen/guardado de mundo. W03 dejó mochila, mapa y puente intactos. Ticket `CONTINUOUS_V4/W03_REPEL_BAG_GAP.md`.
- **protected_sources**: `FieldItemBag`, `CreatureInstance`, `FieldItemService`, `native_engine.cjs`, `config/item_selection_v1.json` (dynamax_candy excluido) protegidos por SHA de blob; `FieldNativeSave._valid_creature` preserva naturaleza efectiva.
- **blocked_balls**: Heavy/Beast/Dive/Dusk/Lure/Love sin productor, Safari/Sport parciales; Magikarp L5 move_policy ticket previo.
- **final_report**: `docs/coordination/items_parallel_v1/reports/W03/CONTINUOUS_V4_STAGING_FINAL.md`.
- **integration_IA6_official**: NO. **ready_state**: `READY_FOR_IA6_REVIEW_NATIVE_ONLY / BLOCKED_SHARED_SEAMS`, **NO READY_FOR_FULL_MERGE**.
- **ci_pending**: NO sobre el último SHA de código. Los commits posteriores son docs `[skip ci]`, no atribuirles CI.
- **next_safe_action**: IA6 revisa hunks, decide autorización puntual para `WildAdventureSession.capture_current/load_game`, integra repeles con W05 de forma selectiva y ejecuta CI integrada; W03 no puede continuar esas seams sin nueva orden. No repetir QA en bucle.

---

## Checkpoint histórico previo preservado

# IA3/W03 — V4 STAGING, FASE A COMPLETADA · FASE B EN CERTIFICACIÓN

- **branch**: `codex/calvo-ia6-staging-20261111-w03-capture`, derivada de IA6 `e63b2e6c7e175fba318cc2f562bebd1769589092`.
- **mission**: `CONTINUOUS_V4/PLAN_W03.md` activo; **NO** usar rama W03 histórica V3 ni integradora oficial IA6.
- **phase**: A DIFF **COMPLETADA** (hunks selectivos), B **CI EN EJECUCIÓN**, C tickets de dependencia preparados; entrega final pendiente.
- **new_inventory_object_ids**: 0. **ported_into_staging**: historial Repeat auténtico (×3,5 para especie base ya capturada), Moon ×4 por EvolutionRecord Piedra Lunar y ×1 neutral, persistencia opcional de historial en SaveV2; Net x3,5 ya estaba en base IA6, no duplicado.
- **source_certified_sha**: `ef63e824069aa27ce957e99997df8e7a50c78524`, CI histórica `42958535816` SUCCESS; **no acredita esta staging**.
- **staging_code_ci_candidate_sha**: `0cb612cd548ee47ff66fabf85472e64e10951a28` (workflow `ia6-w03-v4-capture-staging.yml`).
- **staging_run**: [42965463520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965463520), `in_progress` al escribir esta nota; **no afirmar SUCCESS antes de comprobar resultado**.
- **previous_run**: [42964836905](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964836905) FAIL en original `parallel_items_w03_repeat_history_v2.gd` debido a `WildAdventureSession` (módulo **fuera de permisos**). La nueva CI expone exactamente ese RED como `BLOCKED_AUTHORIZATION_WILD_ADVENTURE_SESSION NOT_PASS`, **jamás lo cuenta como éxito**, y continúa probando la ruta nativa.
- **protected_baseline**: `FieldItemBag`, `CreatureInstance`, `native_engine.cjs`, `FieldItemService`, política de exclusión `dynamax_candy` intactos, SHA de blob vigilados por Python. Se conserva validación de menta/naturaleza efectiva en `FieldNativeSave._valid_creature`.
- **file_hunks**: helper `caught_species_history_w03.gd` y `capture_source_w03_v3.gd` (nuevos, solo W03); `PlayerCollection` (campo y dos funciones ledger); `SaveGameData` (campo aditivo, to/from/build/validate); `SaveGameRepository` (save_collection/decode_snapshot); `LoadResult` (único campo transportado); `FieldNativeSave` (write/decode, **sin modificar _valid_creature**); `CaptureBattleContext` (tres campos); `CaptureContextBallEffects` (Repeat+Moon); `ShowdownAdventureSession.capture` (proyectar contexto/registrar éxito). Sin copiar archivos compartidos enteros.
- **blocked_tickets**: `CONTINUOUS_V4/W03_WILD_LEGACY_GAP.md` y `CONTINUOUS_V4/W03_REPEL_BAG_GAP.md`. Faltan productores Heavy/Beast/Dive/Dusk/Lure/Love y zonas Safari/Sport en origen; no se inventaron.
- **integration_IA6_official**: NO. No tocar `codex/calvo-ia6-integration-20261109`, `main`, V28, PR118 ni otras W.
- **next_safe_action**: consultar CI 42965463520 y sus logs. Si falla prueba nativa autorizada, reparar solo hunk correspondiente. Si pasa ruta nativa, completar informe staging con alcance y registrar blocker legacy explícito, sin declarar integración oficial ni plena regresión legacy.
- **ready_for_merge**: PENDIENTE mientras no haya decisión IA6 sobre el error `WildAdventureSession`; V4 staging puede certificar ruta nativa de forma parcial, **no** afirmar puerta de integración total.

---

## Checkpoint inicial IA6 preservado

# W03 — CONTINUOUS_V4 / ESTADO INICIAL IA6
- worker: W03
- branch: codex/calvo-ia6-staging-20261111-w03-capture
- staging_base_sha: e63b2e6c7e175fba318cc2f562bebd1769589092
- mission_version: CONTINUOUS_V4/PLAN_W03.md
- phase: A / DIFF
- code_changes_v4: 0 (rama recién creada, aún no tiene código nuevo)
- green_ci_v4: ninguno (CI histórica de origen no es CI de staging)
- integrated_into_official_IA6: NO
- last_source_ci: consultar PLAN_W03.md y SHA exacto certificado
- next_safe_action: Contrastar fuentes de W03 vs base IA6 y registrar funciones específicas que faltan
- protected_files: no tocar main, V28, PR118, rama integradora oficial ni ramas de otras W
- next_checkpoint: actualizar fase, SHA, CI, hunks y tests; detener al fin con READY_FOR_IA6_MERGE

La nota IA6_AUTORUN.md de ESTA rama contiene el plan íntegro. Para W01/W02 está PROHIBIDO activar hasta que V2/V3 de rama original cierre realmente. Una p reanuda acciones autorizadas y no ejecuta nada en background.
