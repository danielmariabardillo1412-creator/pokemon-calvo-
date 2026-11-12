# IA6 — W04 V5→V7 selectivo · checkpoint 2026-11-12

## Base verificada y PR
- HEAD oficial IA6 previo: `03a1d7352f3152af7a44ee3b28b61afd47dffd34`. No se ha modificado.
- Rama candidata: `codex/calvo-ia6-w04-v5-v7-selective-20261112`, creada desde SHA oficial exacto.
- PR #125 (DRAFT): https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/125
- HEAD candidata al checkpoint: `209810e1810b80e98d4f3a933f16afc2246f304e`. Compare **ahead=5, behind=0**, 5 archivos.
- CI #43146967024 `IA6 W04 selective V5 regional level evolution and cross-worker` creada y **queued** última consulta; total 21 workflows generales en curso/cola. **No hay PASS certificado todavía para esta candidata**.
- Ningún objeto nuevo ni modificación de `main`, V28, PR118 o ramas fuente.

## Integrado en candidata: exclusivamente V5
1. `modules/creatures/progression/regional_level_evolution_contract_w04_v5.gd`: original W04, diez rutas canónicas de subida de nivel.
2. `modules/creatures/progression/evolution_system.gd`: bloque acotado adicional entre resolución regional por objeto y construcción del nuevo CreatureInstance, prueba evidencia fuente→destino y asigna form_id canónico. Cálculo de estadísticas **W02 effective_nature_id preservado textualmente**, no se ha sobrescrito la función completa.
3. `tests/gameplay/w04_continuous_v5_level_up.gd`: runner W04 V5 original, diez rutas, 20 propietarios, SaveV2.
4. `tests/tools/test_w04_continuous_v5_level.py`: Python inventario de rutas, veto Dinamax.
5. `.github/workflows/ia6-w04-selective-v5-gate-20261112.yml`: puerta basada en original V5, pruebas Python, Godot 4.7, V4 7 rutas/rollback, regional 55/56, habilidades normales y veto `dynamax_candy`. `push` candidata y `pull_request` a oficial.

## V6/V7 AÚN NO integrados; auditoría de conflictos
- W04 source V7 `codex/calvo-items-20261112-w04-battle-return-v7` diverge **ahead=81 / behind=98** del oficial (antes de crear candidata), por tanto **merge directo prohibido**.
- `scenes/visual/field_native_bridge.gd` W04 tiene hunk `has_pending_evolution_w04()` pero **omite** el guard `blocked_by_repel` y `field_commit_repelled_encounter_rng` existentes en oficial. Copiar el archivo completo borraría W03; solo insertar guardas de evolución en sus funciones exactas tras comparar.
- `scenes/visual/field_native_presentation.gd`: el original W04 V6 añade cola/panel de decisión, consume únicamente eventos `settle_finished_battle()`; el oficial tiene cambios existentes de Save/Load y `super._settle()`. Cambiar todo perdería estado legítimo. Requiere patch por hunks, conservando semántica de settle única y test de doble settlement.
- `modules/battle/backends/showdown/pipe_client.gd::close()`: W04 V7 reemplaza graceful `exchange(shutdown)` por `stop_now()`, marca `forced_shutdown`. Source CI #43139645110 **SUCCESS**, HEAD código W04 `6d483b839ec57c674afc36acc508102f0df10fd5`, prueba headless dos ciclos, **37 checks, battle_closed=2**. Es workaround de cierre forzoso, NO prueba que el RPC shutdown se haya arreglado. Windows y finalización normal siguen sin certificación.
- W04-V6-DEP-01 naturaleza efectiva `hardy`→`adamant`: Showdown JS no toma effective_nature_id, `Stat import mismatch`; bloqueado, no modificar motor sin ticket específico IA6.
- No se han llevado aún `w04_postbattle_evolution_consumer_v6.gd`, UI, bridge, `pipe_client.gd`, tests V6/V7. Su mera presencia en la rama fuente NO autoriza fusión.

## Próxima p
1. Leer resultado exacto de CI #43146967024 y gates asociados a SHA `209810e1...`; si falla, corregir sin eludir tests. Mantener PR draft.
2. Si V5 verde, aplicar V6 por hunk auditado a partir de **esta candidata** y probar integración con W01 Rocky Helmet, W02 naturaleza efectiva, W03 captura+repel, W05 libros y SaveV2. Evitar doble settlement. 
3. V7 `pipe_client.close`: diseñar test Windows y ciclo real before/after; exigir worker PID cerrado, teardown síncrono, mapa recuperado y reentrada segundo combate. No afirmar graceful, no esconder fallback.
4. No merge antes de las puertas completas y exactitud del HEAD.

**Regla:** todo SUCCESS en rama W04 trabajadora no sustituye QA de la candidata IA6 sobre código combinado.
