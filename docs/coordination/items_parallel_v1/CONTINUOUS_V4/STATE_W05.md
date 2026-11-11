# IA5/W05 — CONTINUOUS_V4 · READY_FOR_IA6_MERGE · STAGING CERRADA
Fecha: 2026-11-11 (Europe/Madrid)
- worker: W05
- branch: codex/calvo-ia6-staging-20261111-w05-books
- source_branch: codex/calvo-items-20261109-w05-books-ui (conservada sin cambios)
- mission_version: CONTINUOUS_V4/PLAN_W05.md
- fixed_staging_base: e63b2e6c7e175fba318cc2f562bebd1769589092
- phase: A+B+C COMPLETADAS 3/3; no quedan tareas independientes autorizadas
- next_id: READY_FOR_IA6_MERGE
- last_green_code_sha: 81d781e2d6c6c0be20eb77f001b6bd6c968f89c8
- last_green_run_id: 42965926888
- ci_pending: NO; GitHub Actions completed/success job verify SUCCESS
- objects_new: 0; active_machine_books_previously_certified: 229/229
- L3_staging: FieldDemo real + FieldItemBag real + FieldItemService real; 366 comprobaciones nuevas Godot V4 PASS, 4 slots, estado obsoleto, consumo x1, evitar doble gasto, Party/Storage, PP, guard/save manual
- original_W05_regressions: T01/T02/T03/T04 PASS; CAMP003-CAMP006 Python y Godot PASS
- rope_existing: función _apply_escape_rope idéntica a base por Python y humo IA6 65 checks PASS
- dynamax_candy: excluded_ids intacto, veto Python PASS
- source_ES: 229/229 etiquetas PokeAPI ES con hash de origen; helper real cargado desde PCK exportado
- windows_exe_bytes: 635426312
- windows_pck_bytes: 526406648
- windows_gpu_manual: NO CERTIFICADO
- android_export: NO CERTIFICADO
- official_ia6_integration: NO; staging no es rama central y no hay merge
- W03_repels: no acreditados ni integrados desde W05; pendiente IA6
- files_changed_production: scenes/visual/field_item_bag.gd; scenes/visual/field_machine_book_panel.gd; modules/inventory/field_machine_book_profile.gd; modules/localization/machine_moves_es_sv_w05.gd; data/localization/machine_moves_es_sv_v1.json
- tests_and_workflow: tests/tools/test_parallel_items_w05_staging_v4.py; tests/gameplay/w05_staging_v4_books_bag.gd; .github/workflows/w05-staging-v4-books-20261111.yml; heredadas regresiones W05 CAMP003–006/T01–T04 y export probes
- protected_files_untouched: FieldItemService, SaveV2, FieldNativeSave, GameData, EvolutionSystem, Showdown, branches W03/IA6 oficial, main, V28, PR118
- final_report: docs/coordination/items_parallel_v1/reports/W05/CONTINUOUS_V4_STAGING_FINAL.md
- next_safe_action: IA6 leer informe final y diff limitado a funciones de libros; fusionar selectivamente sobre su rama oficial, preservar Cuerda Huida, incorporar repelentes W03 separadamente, ejecutar CI integrada propia. W05 STOP por campaña agotada salvo orden nueva.

## Recibos finales verificables
- Código probado: 81d781e2d6c6c0be20eb77f001b6bd6c968f89c8
- CI: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965926888 (completed/success)
- W05_V4_BAG_CONTRACT PASS panel=1 signals=1 double_spend_guard=1 stable_ids=1 callback_ui_only=1
- W05_V4_SOURCE_ES PASS ids=229 exact_pokeapi=229 excluded_dynamax_candy=1 rope_unmodified=1
- W05_V4_REAL_FIELD_BAG PASS slots=4 es=229 one_panel=1 no_double_spend=1 stale=1 party_storage=1 savev2=1 no_autosave=1 rope_preserved=IA6_SMOKE checks=366
- CAMP003-CAMP006 Python/Godot PASS en cada campaña
- IA6_INTEGRATION PASS checks=65 features=mint_effective_nature,escape_rope_bag_savev2
- W05_V5_PCK_PROBE PASS records=229 runtime_samples=4 helper=1 source=pck_only
- W05_V4_WINDOWS_EXPORT PASS exe_bytes=635426312 pck_bytes=526406648 visual=UNVERIFIED android=UNVERIFIED

## Seguimiento de regresiones históricas
Primer intento #42965053798 FALLÓ por incompatibilidad con selección directa del test IA6; parche válido permite selección programática mientras conserva rechazo del inventario obsoleto. #42965380397 y #42965816461 quedaron CANCELLED por nuevas revisiones y no cuentan como certificación. Sólo #42965926888 certifica el código final.

---
## Checkpoint anterior (histórico)
# W05 · STAGING CONTINUOUS_V4 — CHECKPOINT DE EJECUCIÓN (NO CIERRE)
Actualizado: 2026-11-11.
- worker: W05
- branch: codex/calvo-ia6-staging-20261111-w05-books
- fixed_staging_base: e63b2e6c7e175fba318cc2f562bebd1769589092
- mission_version: CONTINUOUS_V4/PLAN_W05.md
- phase: A DIF SELECTIVO EN STAGING · B PRUEBAS EN CI · C PENDIENTE CERTIFICACIÓN
- next_id: RECUPERAR_RESULTADO_CI_42965926888
- source_v3_code_sha: 803561dd6a0253458c576762d74b3c62435299fa
- code_sha_under_test: 81d781e2d6c6c0be20eb77f001b6bd6c968f89c8
- current_ci: #42965926888 (en curso al crear este checkpoint; NO marcar PASS)
- previous_attempts: #42965053798 FALLÓ por incompatibilidad con selector de prueba IA6; se corrigió bloqueo de selección directa sin volver a permitir stock obsoleto. #42965380397 avanzó a exportación pero fue cancelada por actualización de workflow.
- new_objects: 0
- inherited_existing: 229 MT ya certificadas en W05 V3; no volver a contarlas nuevas
- staging_integration: panel YA existente en IA6, se mantuvo una sola instancia; se añadieron guardas por ID, botón Usar global exclusivo, slot 0-3, callback sin consumo, nombres ES PokeAPI y filtro/sort/stale desde W05
- source_localization: datos fuente W05 229 entradas verificadas PokeAPI + helper MachineMovesEsSvW05 en staging, sin tocar SpanishGameText global
- historical_regressions: copiados con hashes históricos W05 T01–T04 y CAMP003–006 GD/Python, fixtures y progreso a staging. CI V4 ejecuta todas; verificar resultados de run actual.
- dynamax_candy: permanece en config/item_selection_v1.json excluded_ids; prueba V4 verifica.
- w03_rope: función _apply_escape_rope idéntica al base IA6 por puerta Python, smoke nativo incluido.
- w03_repels: NO integrados ni autorizados W05, ticket posterior IA6
- protected: FieldItemService/SaveV2/FieldNativeSave/GameData/otros W sin cambios; main V28 PR118 y rama integradora IA6 intactos
- official_ia6_integration: NO; sólo STAGING
- gpu_windows_android: NO CERTIFICADOS
- next_safe_action: si CI #42965926888 falla, reparar SOLO ficheros permitidos, repetir SHA CI; si pasa export PCK y regresiones, escribir CONTINUOUS_V4_STAGING_FINAL.md, hunks exactos y READY_FOR_IA6_MERGE. No fusionar a rama oficial.

## Antiguo checkpoint IA6 (histórico)
# W05 — CONTINUOUS_V4 / ESTADO INICIAL IA6
- worker: W05
- branch: codex/calvo-ia6-staging-20261111-w05-books
- staging_base_sha: e63b2e6c7e175fba318cc2f562bebd1769589092
- mission_version: CONTINUOUS_V4/PLAN_W05.md
- phase: A / DIFF
- code_changes_v4: 0 (rama recién creada, aún no tiene código nuevo)
- green_ci_v4: ninguno (CI histórica de origen no es CI de staging)
- integrated_into_official_IA6: NO
- last_source_ci: consultar PLAN_W05.md y SHA exacto certificado
- next_safe_action: Probar mochila IA6 existente; asegurar panel único, doble consumo y Rope intacta
- protected_files: no tocar main, V28, PR118, rama integradora oficial ni ramas de otras W
- next_checkpoint: actualizar fase, SHA, CI, hunks y tests; detener al fin con READY_FOR_IA6_MERGE

La nota IA6_AUTORUN.md de ESTA rama contiene el plan íntegro. Para W01/W02 está PROHIBIDO activar hasta que V2/V3 de rama original cierre realmente. Una p reanuda acciones autorizadas y no ejecuta nada en background.
