# IA6 — CAMP_002 ITER_02, diagnóstico de CI y puerta temporal (2026-11-02)

**ESTADO: PRUEBA NUEVA NO APROBADA GLOBALMENTE. No enviar ITER_03 de W01/W02 hasta reparación y nueva puerta IA6.** Este informe no reescribe el cierre de CAMPAÑA_001 ni suspende el relevo autorizado de IA4/IA5.

## Evidencia exacta
- CI staging `codex/calvo-items-20261102-ci-camp002-iter02`, SHA `90836989979339db4e26c2c35668b321418c2917`, [GitHub Actions #41492689274](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41492689274) = `completed/failure`. Estos archivos no se integran ni se etiquetan como funcionales hasta verificación.
- **W01/IA1 02/03:** Python `--contracts` y `--self-test` PASS, Godot 4.7 **Parse Error** `The member "OUT" already exists in parent class res://tests/gameplay/item_field_effects_v4.gd` al cargar `tests/gameplay/parallel_items_w01_campaign_002.gd:6`. Es error del arnés nuevo, no prueba de que `ability_shield`, `absorb_bulb` o `adrenaline_orb` funcionen o fallen. Staging corrige solo el nombre `OUT` a `W01_C002_OUTPUT`, conservando toda aserción. **No se ha corregido la rama worker W01**.
- **W02/IA2 02/03:** Python del fixture y unittest PASS; Godot `PARALLEL_ITEMS_W02_CAMP002 FAIL checks=672 cases=9`: la sesión nativa no inicia en los escenarios `figy_modest_low_c002` y `figy_modest_high_c002` para portador, ausencia y reserva; falla cobertura de Figy. No se deduce que `figy_berry` esté mal implementada; puede fallar dto, naturaleza, perfil o referencia. El runner W02 imprime error de apertura en staging diagnóstico; NO suprime controles ni cambia producción.
- **W03/IA3 02/03:** Python `tests=11` PASS y Godot `CAMP_002_W03_NEGATIVE {"checks":37,"errors":[],"new_balls_functional":false,"scope":"NEGATIVE_CURRENT_BEHAVIOR_ONLY","status":"PASS"}`. Dusk/Repeat/Dive siguen NO IMPLEMENTADAS y sin contextos autoritativos; no confundir prueba de negativos con funcionalidad.
- Reintento [Actions #41493314741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493314741), staging SHA `b6c55277764671cf74871b75f5690fbacab24f5a`: **pendiente de veredicto** al crear este documento. Incluye corrección de nombre W01 y trazas de apertura W02, sin modificaciones en ramas worker, `main`, V28 o W04.

## Reglas siguientes
- **W01 y W02:** STOP de ITER_03 hasta que IA6 compruebe nueva CI y dé instrucción explícita de sincronización de la corrección del test. Nunca usar `p` para saltar un FAIL real.
- **W03:** 02/03 test de negativos PASS en el primer run; permiso del siguiente bloque depende del gate normal y de no recibir nueva evidencia contraria. No autorizar implementar bolas sin contexto.
- **W04:** relevo de chat permitido para **CAMP_001 ITER_03**, conforme [CAMPAIGN_HANDOFF_GATE_20261102.md](CAMPAIGN_HANDOFF_GATE_20261102.md). Rama y trabajo antiguo intactos.
- **W05:** relevo de chat permitido para **CAMP_002 ITER_02**. El selector 01/03 pasó Python y catálogo real en #41484879741. Nada de edición de `FieldItemService.teach`.

**Prioridad:** obtener resultados por SHA real, corregir defectos de test sin debilitar aserciones, documentar errores funcionales como bloqueos si el código de producción es responsable. Toda validación visual/GPU sigue pendiente.
