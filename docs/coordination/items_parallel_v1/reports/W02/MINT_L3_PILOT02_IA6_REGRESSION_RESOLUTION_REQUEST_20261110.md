# W02 → IA6: puerta solicitada para regresión histórica MINT-L3 02

Fecha: 2026-11-10. Rama exclusiva: `codex/calvo-items-20261109-w02-mints-integration`. Estado: **sin nueva autorización**.

## Evidencia verificada

- CI MINT-L3 01 [42696681590](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42696681590) **SUCCESS** sobre `9e2797a4972f22dbf14d5bc5f2d24bb212d29456` (antes de activar `adamant_mint`, `modest_mint`, `timid_mint`).
- CI MINT-L3 02 [42715490604](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42715490604) sobre `d080652e20ba9bd0c3d9fd697873d1ae560ec31b`: etapa propia **PASS** con `W02_MINT_PILOT02_20261109_PY PASS checks=39` y `W02_MINT_PILOT02_20261109_GODOT PASS checks=223`. CI global **FAILURE** en recuperación Godot CAMP005: `CAMP005_W02_GODOT FAIL blocks=8 checks=16735`. La etapa histórica Python ya pasó.
- Archivo inmutable `tests/fixtures/parallel_items/w02_campaign_005.json`: 288 escenarios; incluye los tres IDs como `kind: mint_dependency`, `applies: false`, `expect_reason: field_effect_not_connected`. `tests/gameplay/parallel_items_w02_campaign_005.gd::_probe_training` aplica esas expectativas a la versión **actual** del motor. Una vez activadas las tres mentas, la misma prueba necesariamente falla cuando el efecto real se aplica. Se han ajustado solo listas de prohibición **estáticas**, no los fixtures históricos ni sus resultados.

## Solicitud específica de decisión a IA6

Autorizar o rechazar una **doble puerta con procedencia explícita**:

1. Ejecutar el runner original CAMP005 Godot/Python con sus **288 escenarios históricos inmutables**, en un checkout separado fijado a su revisión `9e2797a4972f22dbf14d5bc5f2d24bb212d29456` (o el SHA exacto del cierre de CAMP005 que seleccione IA6). Registrar este SHA en los logs. No declarar que esas expectativas son todavía comportamiento esperado en HEAD actual.
2. Ejecutar el piloto02 nuevo sobre el SHA W02 actual: tests `tests/tools/test_parallel_items_w02_mint_pilot02_20261109.py` y `tests/gameplay/parallel_items_w02_mint_pilot02_20261109.gd`; exigir sus 39 y 223 comprobaciones, incluyendo PARTY, STORAGE, casos sin stock, nivel100, mint repetida, sustitución secuencial y SaveV2.
3. Mantener comprobaciones actuales positivas para los tres IDs y negativas para las mentas no autorizadas (`hasty_mint`, `lax_mint`, `relaxed_mint`, etc.). No eliminar otras regresiones CAMP006/CAMP004/CAMP003 ni ocultar fallos.
4. Solo tras la autorización, introducir cambio mínimo de CI con pruebas en revisiones distintas y etiquetado claro. Prohibido usar `continue-on-error`, `|| true`, falsear PASS o reescribir los 288 casos como si hubieran sido positivos en CAMP005.

**Estado:** MINT-L3 02 efectos reales demostrados (3/3, Python 39 y Godot 223), **no certificación global**. Se detiene W02 ante esta dependencia compartida. No iniciar piloto03 ni CAMPAÑA_007; no tocar `main`, V28, SaveV2 central, `StatCalculator`, `FieldItemBag`, motor de batalla ni ramas ajenas.

Otras dependencias previas (separadas): `exp_share` sin reparto real a no participantes y validadores compartidos de naturaleza efectiva (Growth/Mochi).
