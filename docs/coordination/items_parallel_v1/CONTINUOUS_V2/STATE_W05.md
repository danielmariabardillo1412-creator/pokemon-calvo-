# W05 — CONTINUOUS_V2 · READY_FOR_IA6 · CAMPAÑA COMPLETA
Fecha: 2026-11-11 (Europe/Madrid).
- worker: W05
- branch: codex/calvo-items-20261109-w05-books-ui
- mission_version: CONTINUOUS_V2/PLAN_W05.md
- phase: B01+B02+B03 COMPLETADAS (3/3), sin detención por 10/10
- block: B01 interfaz probada; B02 paquete probado; B03 contrato IA6 entregado
- next_id: READY_FOR_IA6; sin trabajo independiente restante bajo orden vigente
- checked: 58 checks Godot NUEVOS del consumidor + contrato Python; preservadas suites W05 229/229 y CAMP003–006
- functional: 229 libros ya certificados en panel separado (NO objetos nuevos)
- newly_functional: 0
- blocked: 0 internos; integración FieldItemBag y convivencia W03 exigen IA6
- L3: panel UI Godot headless + FieldItemService real + SaveV2 manual; montaje mochila real NO realizado
- last_green_code_sha: 426021c41b75d42cd2ee112ed4446f11e166ec54
- last_green_run_id: 42929830881
- ci_pending: NO; completed/success; verify SUCCESS y Windows PCK/runtime isolation SUCCESS
- windows_exe_bytes: 635389864; baseline_exe_bytes: 635385472; delta_bytes: +4392; growth_guard_bytes: 698924019
- windows_pck_bytes: 526370204; verified_es_from_pck: 229/229
- tracked_workspace_files: 19888 (NO son miembros PCK exactos)
- owned_files_changed: tests/tools/test_parallel_items_w05_continuous_v2.py; tests/gameplay/parallel_items_w05_continuous_v2.gd; .github/workflows/parallel-w05-books-ui-20261109.yml; docs/coordination/items_parallel_v1/CONTINUOUS_V2/W05_IA6_ACCEPTANCE.md; docs/coordination/items_parallel_v1/CONTINUOUS_V2/W05_READY_FOR_IA6.md; STATE_W05.md
- protected_tickets: mochila IA6 (incluidas Cuerda Huida y repelentes W03), pruebas Windows UI/GPU, peso distribución, Android sin preset, core light_screen
- next_safe_action: IA6 leer W05_READY_FOR_IA6.md y W05_IA6_ACCEPTANCE.md e integrar selectivamente en su propia rama; W05 STOP salvo nueva misión.

## Evidencia funcional
**Código CI:** 426021c41b75d42cd2ee112ed4446f11e166ec54
**CI:** https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42929830881
**Recibos:** W05_V2_CONSUMER_GODOT PASS checks=58; W05_V2_CONTRACT PASS; W05_V2_PACKAGE PASS exe_bytes=635389864 pck_bytes=526370204; W05_V5_PCK_PROBE PASS records=229 helper=1 source=pck_only.
**Documentos:** W05_READY_FOR_IA6.md y W05_IA6_ACCEPTANCE.md en el mismo directorio.
**NO certificado:** montaje real FieldItemBag, prueba W03 integrada, lanzamiento EXE Windows/GPU, Android.
**Integridad:** no se tocó main, V28, PR118, otros trabajadores ni módulos compartidos; los últimos commits tras código probado son de documentación.

---
## Checkpoint anterior (histórico)

# W05 — CONTINUOUS_V2 · Checkpoint tras B01 y ensayo B03
Actualizado: 2026-11-11 (Europe/Madrid).
- worker: W05
- branch: codex/calvo-items-20261109-w05-books-ui
- mission_version: CONTINUOUS_V2/PLAN_W05.md
- phase: B02 (CI paquete pendiente)
- block: B01 COMPLETADO / B02 EN CURSO / B03 CONTRATO PUBLICADO, PENDIENTE CI COMPLETA
- next_id: B02_PCK_EXE_SIZE_GUARD_CI
- checked: 229 libros históricos ya certificados; 58 comprobaciones NUEVAS en consumidor Godot, más contrato Python
- functional: 229 MT ya funcionales en panel aislado, **0 MT nuevas CONTINUOUS_V2**
- newly_functional: 0
- blocked: 0 internos; montaje mochila real/convivencia W03 reservados a IA6
- L3: panel Godot headless + servicio real, sin FieldItemBag integrado
- last_green_code_sha: 42466cfe9b012949472f12480a3d5e3b91573c92 (TANDA05, CI #42923848244)
- current_code_sha_under_CI: 426021c41b75d42cd2ee112ed4446f11e166ec54
- current_run_id: 42929830881
- ci_pending: RUN 42929830881; job verify SUCCESS, export pack job in_progress al emitir este checkpoint. **NO declarar CI total PASS hasta comprobación final**
- owned_files_changed: tests/tools/test_parallel_items_w05_continuous_v2.py; tests/gameplay/parallel_items_w05_continuous_v2.gd; .github/workflows/parallel-w05-books-ui-20261109.yml; docs/coordination/items_parallel_v1/CONTINUOUS_V2/W05_IA6_ACCEPTANCE.md; STATE_W05.md
- protected_tickets: FieldItemBag IA6 para montaje; coexistencia W03 Cuerda Huida/repelentes; prueba manual EXE Windows/GPU; Android no certificado; light_screen CORE global sin alterar
- next_safe_action: recuperar resultado de #42929830881, corregir sólo pruebas o workflow W05 si falla, guardar tamaño EXE/PCK y top grupos del workspace, luego informar READY_FOR_IA6 cuando B01/B02/B03 estén completos.

## Evidencia B01 y B03 consumidor
El job verify del run #42929830881 superó las regresiones de W05 y:
W05_V2_CONTRACT PASS books=229 source_es=229 teach_entrypoints=1 historical_regressions=preserved real_mount=pending_ia6
W05_V2_CONSUMER_GODOT PASS live_service=1 real_panel=1 accepted=1 duplicate_spend=0 storage_rejection=1 locked_rollback=1 savev2=1 actual_bag=NOT_MOUNTED w03_coexistence=IA6_PENDING checks=58

## Riesgo operativo
La primera iteración #42929714960 falló porque un editor del YAML duplicó secciones al insertar una cadena que contenía el operador $' de reemplazo. Se reconstruyó el workflow desde el último archivo verde de IA6 y la CI posterior arrancó ambos jobs correctamente. No se ha tocado producción ni alterado ninguna regresión. Evitar repetir ese mecanismo de sustitución.
