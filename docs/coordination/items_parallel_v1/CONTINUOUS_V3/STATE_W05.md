# W05 — CAMPAÑA CONTINUA V3 · checkpoint de ejecución (no cierre)
Fecha: 2026-11-11 (Europe/Madrid)
- worker: W05
- branch: codex/calvo-items-20261109-w05-books-ui
- mission_version: CONTINUOUS_V3/PLAN_W05.md
- phase: A montaje REAL completado en código / B pruebas nativas y regresiones ejecutándose / C reporte y relevo pendiente
- next_id: CERTIFICAR_CI_V3_42957930359
- code_sha_under_CI: 803561dd6a0253458c576762d74b3c62435299fa
- run_id_under_CI: 42957930359 (in_progress en el momento del checkpoint)
- last_green_run: 42929830881 (BASELINE V2); job verify de V3 anterior #42957563964 SUCCESS sobre SHA edda0937a..., con 168 checks (SIN cancelación explícita), pero export aún pendiente en dicho intento.
- objects_new: 0; 229 libros ya certificados históricamente en panel
- l3_actual: FieldItemBag REAL de rama W05 modificado y probado en Godot headless preliminarmente; NO integrado en rama IA6
- tested: estructura V3 PASS; 168 checks Godot V3 PASS sobre SHA edda093..., nueva CI sobre 803561 incorpora cancelación (-1) y comprobación de ausencia de autosave
- protected_blocked: 0 dentro de autorización W05; IA6 debe combinar manualmente con Rope/Repel, verificar CI integrada y GPU.
- owned_changes: scenes/visual/field_item_bag.gd (solo _ready/open_bag/_refresh_choices/_apply/callback+variables locales); tests/gameplay/parallel_items_w05_continuous_v3.gd; tests/tools/test_parallel_items_w05_continuous_v3.py; .github/workflows/parallel-w05-books-ui-20261109.yml; docs/coordination/items_parallel_v1/CONTINUOUS_V3/W05_COLLISION_AUDIT.md
- collision_report: CONTINUOUS_V3/W05_COLLISION_AUDIT.md; la rama IA6 YA posee un panel MT distinto y Cuerda Huida. La rama W03 tiene también repelentes que faltan en snapshot IA6.
- next_safe_action: recuperar CI #42957930359, si fallo reparar SOLO código W05 autorizado y repetir. Si PASS en ambos jobs publicar reports/W05/CONTINUOUS_V3_FINAL.md y estado READY_FOR_IA6. No atribuir integración IA6.

## Ensayos anteriores y trazabilidad
- Intento #42957381981: FAIL en GDScript por inferencia de is_book; corregido con bool explícito.
- Intento #42957563964: verify SUCCESS sobre SHA edda0937..., recibo W05_V3_NATIVE_BAG_GODOT PASS checks=168, mientras el job Windows siguió exportando.
- Ensayo posterior añade cancelación real y no-autoguardado antes de considerar final.
- No tocar main, V28, PR118, FieldItemService, SaveV2, W03 ni IA6.

---
## Checkpoint inicial de IA6 (histórico)
# IA6 · W05 — CHECKPOINT INICIAL CAMPAÑA V3
- worker: W05
- branch: codex/calvo-items-20261109-w05-books-ui
- mission_version: CONTINUOUS_V3/PLAN_W05.md
- phase: A / pendiente de inicio
- next_id: primera tarea de fase A del PLAN_W05.md
- baseline_v2_last_green_run: 42929830881
- baseline_v2_code_sha: 426021c41b75d42cd2ee112ed4446f11e166ec54
- current_v3_code_sha: ninguno todavía
- current_v3_ci: PENDIENTE
- integration_IA6: NO
- objects_new_v3: 0 hasta que haya CI real
- blocked_v3: ninguno comprobado todavía
- next_safe_action: Montaje real de FieldMachineBookPanel dentro de FieldItemBag, prueba roja

Este archivo lo actualizará la trabajadora al completar una etapa, lanzar CI o agotarse un turno. No confundir el baseline V2 con CI de V3. Leer plan completo en IA6_AUTORUN.md de su rama y CONTINUOUS_V3/README.md de árbitra. No STOP automático por diez hitos. Solo READY_FOR_IA6 al agotar misión independiente real.
