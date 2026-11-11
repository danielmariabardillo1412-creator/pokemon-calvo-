# IA2/W02 — CHECKPOINT CONTINUOUS_V2 / BAYAS — 2026-11-11

- worker: W02
- branch: `codex/calvo-items-20261109-w02-mints-integration`
- mission_version: `CONTINUOUS_V2/PLAN_W02.md` en árbitra; orden íntegra en `IA6_AUTORUN.md` de esta rama
- phase: B / auditoría de 42 bayas y QA sin duplicaciones
- block: 01/05, Persim pendiente de prueba nativa dedicada; bloques 02–05 cubiertos en CAMPAÑA_003 por 32 IDs
- next_id: `persim_berry`
- examined: 42/42 comparadas con fixture histórica, **NO** significa 42 nuevos objetos
- historically_positive_and_negative: 36/42 IDs tienen escenarios nativos positivos+negativos en `w02_campaign_003.json`; ya ejecutados con regresión CAMP003 en CI verde `42922087890`
- historical_only_b01: `aspear_berry`, `aguav_berry`, `iapapa_berry`, `mago_berry` (4 IDs)
- historical_complete_b02_b05: 32/32 ID de esos cuatro bloques en CAMP003, incluidos positivos y negativos; NO reimplementar
- new_tested_field_b01: `cheri_berry`, `chesto_berry`, `pecha_berry`, `rawst_berry`, `aspear_berry`, `oran_berry` (6 usos desde mochila; Aspear también histórico en combate)
- new_test_fixture: `tests/fixtures/parallel_items/w02_continuous_v2_block01.json` (12 casos, 6 positivos/6 negativos, cada uno en PARTY/sin stock/STORAGE)
- native_runner: `tests/gameplay/parallel_items_w02_continuous_v2_block01.gd`
- new_field_gate: etapa `W02 CONTINUOUS V2 B01 seis bayas campo...` = SUCCESS, run `42929837808`
- global_ci: `42929837808` lanzada sobre `69cbf0e56669142b25f5b785fde73630b80ec2b9`; estado observado IN_PROGRESS, no adjudicar SUCCESS global aún
- previous_full_green_code_sha: `7765c4bb6982662ae00695c8329c970e10931b4c`
- previous_full_green_run: `42922087890`
- new_game_objects: 0; no se ha cambiado código de producción
- l3_new_evidence_pending_global: 6 rutas de campo en pruebas nativas; 5 IDs no cubiertos por fixture CAMP003, Aspear solapa cobertura histórica
- pending: `persim_berry` no aparece en CAMP003 ni CAMP004 ni `w02_berries_v1`, y no tiene regla de campo en `imported_recovery_v19.json`. Requiere validación equipada real, no suponer ausencia de mecánica.
- ci_pending: comprobar `42929837808` hasta completed/success; si falla, reparar antes de certificar.
- owned_files_changed: dos archivos de test V2 y workflow W02; documentación de checkpoint. Pruebas duplicadas de Aguav/Iapapa/Mago retiradas al detectar CAMP003.
- protected_tickets: ninguno publicado en esta fase. Si Persim exige cambiar el backend Showdown o productores compartidos, ticket IA6, no editar.
- integration_IA6: NO acreditada, no merge a integración ni main.
- next_safe_action: 1) confirmar CI global; 2) inspeccionar disparador nativo de Persim (confusión, consumo, controles y SaveV2), y añadir ensayo aislado si procede; 3) emitir reporte de campaña con conteo de IDs ya certificados frente a rutas nuevas, sin recrear CAMPAÑA_003 ni reclamar 42 objetos nuevos.

## Contabilidad — evitar informes falsos

La fase V2 tiene 42 IDs, de los cuales **36 ya disponían de pruebas positivas y negativas históricas** en la CAMP003. El primer bloque tenía 4 de esos 36, cinco bayas sin casos históricos probadas ahora con uso de campo y `persim_berry` aún por verificar. La cobertura previa no implica una función **nueva**. La etapa nativa verde no equivale a la CI global verde. Una CI de rama W02 no acredita integración IA6.

## Reanudación

La próxima `p` lee `IA6_AUTORUN.md` y este archivo, inspecciona HEAD/CI antes de editar y continúa por el primer trabajo pendiente. Está prohibido repetir mecánicas ya cubiertas o realizar STOP automático cada diez; sólo concluir tras acreditación de Persim o ticket explícito de bloqueo compartido y cierre de la lista.

## Checkpoint incremental tras pruebas y CI acumulativa V2
- Audit CSV por ID: `docs/coordination/items_parallel_v1/reports/W02/CONTINUOUS_V2_BERRIES_AUDIT.csv` (42 filas).
- `persim_berry`: fixture `tests/fixtures/parallel_items/w02_continuous_v2_persim.json` y runner `tests/gameplay/parallel_items_w02_continuous_v2_persim.gd` PUBLICADOS, aún sin PASS propio.
- Gate estructural Python V2: `tests/tools/test_parallel_items_w02_continuous_v2.py`, PENDIENTE CI.
- CI acumulativa nueva: `42931293868` sobre SHA `0e59679abc91c353a5d58b33e0a4bf4ea2c51fc6`, estado PENDING observado (concurrency `cancel-in-progress: false`).
- CI anterior en curso: `42929837808` SHA `69cbf0e56669142b25f5b785fde73630b80ec2b9` IN_PROGRESS, etapa V2 campo SUCCESS y regresiones T04/T03/T02 SUCCESS; CAMP004/003 seguía activa.
- Código de producción modificado en V2: ninguno. Pruebas nuevas no equivalen a 42 objetos nuevos.
- Próxima acción segura: verificar conclusión de ambas CI y de Persim; si FALLA inspeccionar job/log y reparar prueba o ticket protegido; si todas SUCCESS publicar informe final con 36 históricas + 5 nuevos contratos L3 de campo + 1 Persim L3 y 0 objetos nuevos.
- No fusionar a IA6 ni certificar global hasta completed/success en SHA de los tests actuales.
