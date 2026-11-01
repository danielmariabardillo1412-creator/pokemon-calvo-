# CAMPAÑA_001 — Acta de coordinación 003 (IA6)
**Fecha:** 2026-11-01. Complementa `CAMPAIGN_GATE_001.md` y **sustituye las restricciones transitorias sobre W02** de `CAMPAIGN_GATE_UPDATE_002.md`.

## Estado global real
- **W01:** ITER_02/03 preparada; pruebas de los dos bloques PASS en Godot staging; tests incorporados en árbitra commit `7b360f90`; **próximo `p`: ITER_03**, nunca nueva campaña.
- **W02:** ITER_03/03; **CAMPAÑA_001_FINALIZADA** como entrega y pruebas corregidas/validadas en staging [#41354434516](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354434516) (1544 checks, 16 casos + Python 18). Tests integrados en árbitra `52a5515e`. **STOP**: no cuarto bloque, no más `p` hasta próxima orden.
- **W03:** ITER_02/03; Net Ball y tests V11/V15 integrados en árbitra `82f9eea2`, Godot 4.7 PASS de staging [#41350463036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350463036) y de arb [#41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378). **Próximo `p`: ITER_03** dentro de la campaña original, ninguna otra funcionalidad.
- **W04:** ITER_02/03; pruebas de evoluciones 313 checks/12 escenarios PASS staging, integradas `7b360f90`. Su chat ha fallado; reanudar misma identidad W04 usando cuaderno y [relevo V2](PROMPT_RELEVO_W0X_V2.md). **Próximo `p`: ITER_03** solo si puede operar con permisos.
- **W05:** ITER_01/03; adaptador libros read-only validado 18 checks Godot y mapa 248/229/19, integrado `39df72c1` y regresión arb [#41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378) PASS. **Próximo `p`: ITER_02**, sin activar 19 legadas.
- **Total microbloques entregados 10/15**. Pendientes de publicación 5/15. Los PASS corresponden a ámbitos acotados, nunca a campaña completa o GPU.
- **CI del último commit árbitra `52a5515e`:** [#41354759130](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354759130) pendiente al publicar esta acta. No declarar `PASS EN SHA FINAL` sin verificarlo.

## Procedimiento
Cada `p` en una W activa UN microbloque dentro de sus rutas y límites existentes. IA6 valida los paquetes, arregla problemas de CI y publica la puerta. Las conversaciones no se pueden activar entre sí: el usuario debe entregar `p` al chat correspondiente; IA6 no trabaja en segundo plano.

**Prohibiciones:** `main`, `codex/items-v28-from-main`, PR #118, selección canónica, esquema de guardados, cambios compartidos no autorizados, reabrir Mega universal o activar MT/MO heredadas.
