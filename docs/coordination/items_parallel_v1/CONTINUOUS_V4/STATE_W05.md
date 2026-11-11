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
