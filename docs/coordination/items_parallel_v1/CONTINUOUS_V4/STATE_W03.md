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
