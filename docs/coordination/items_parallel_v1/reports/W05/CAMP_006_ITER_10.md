# IA5/W05 — CAMPAÑA_006 · BLOQUE 10/10 · HITO FINAL

**Fecha:** 2026-11-07. **Rama:** `codex/calvo-items-20261104-w05-camp006`. **Estado original al publicar:** PUBLICADO_PENDIENTE_CI. **Estado final:** `CAMPAÑA_006_FINALIZADA` — CI funcional y seis regresiones certificadas. **Commit del fixture:** `c929538eaff755c511273b9e82f955f8301fa35a`.

## Reserva final IA6 (únicamente 4 MT)

La fila 10 de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` de la rama árbitra especifica cuatro IDs activos; el mapeo se ha cotejado con el perfil `scarlet-violet` de `modules/inventory/item_connections_v1.json`:

| MT | Movimiento canónico en Scarlet/Violet |
|---|---|
| `tm31` | `metal_claw` |
| `tm36` | `rock_tomb` |
| `tm44` | `dragon_tail` |
| `tm77` | `waterfall` |

No utilizar las asociaciones históricas de estas MT. Fixture `tests/fixtures/parallel_items/w05_campaign_006.json` acumulativo: **10 bloques / 49 MT distintas**, 45 casos previos intactos, cero alteraciones al catálogo, learnsets, política, motor ni SaveV2.

## Puerta funcional de cierre

- Runner Python CAMP006 para toda la cola: IDs únicos y reservados, versión activa, metadatos del movimiento, PP, política, especie SV compatible y learnset real.
- Runner Godot CAMP006 para los 49 casos: `FieldItemService.teach` sobre especies reales compatibles, identidad y propiedad, PP, gasto de una unidad, stock, negativa por incompatibilidad/ausencia de stock/movimiento conocido y SaveV2. Conservar toda la cobertura de 01–09.
- **Obligatorio en este hito final:** ejecutar regresiones completas CAMP005, CAMP004 y CAMP003 **tanto Python como Godot**. Un PASS aislado de CAMP006 no permite cerrar 10/10.
- No confundir PASS headless con validación visual/GPU, integración de ramas o puesta en producción.

## CI final y cierre — CAMPAÑA_006_FINALIZADA

La CI real [GitHub Actions #42417890877](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42417890877) terminó en `completed/success` sobre el commit funcional `e03bdf44f14c79f52907d91907d7cc2ee2e0eba3` (job `128539815534`).

**Recibos exactos, verificados en logs de la misma ejecución:**

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=10 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=10 checks=481`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=10 checks=481`
- `CAMP006_W05_GODOT PASS blocks=10 checks=1781`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=10 checks=1781`

**Regresiones obligatorias del hito 10, todas en este mismo run:**

| Campaña | Recibo Python | Recibo Godot |
| --- | --- | --- |
| 005 | `CAMP005_W05_PY PASS blocks=10 checks=580` | `CAMP005_W05_GODOT PASS blocks=10 checks=2166` |
| 004 | `CAMP004_W05_PY PASS blocks=10 checks=580` | `CAMP004_W05_GODOT PASS blocks=10 checks=2166` |
| 003 | `CAMP003_W05_PY PASS blocks=10 checks=580` | `CAMP003_W05_GODOT PASS blocks=10 checks=2166` |

### Resultado, límites y entrega a IA6

**CAMPAÑA_006_FINALIZADA — W05 10/10, 49/49 MT Scarlet/Violet certificadas en su rama.** Cobertura acumulativa de `FieldItemService.teach`, PP, compatibilidad/learnsets, propiedad/identidad, stock/consumo, negativas sin mutación y persistencia SaveV2, mediante los runners de CI. Se conservaron las regresiones de las tres campañas anteriores.

**Límites:** CI Godot `headless` no es prueba visual ni de GPU; este resultado no certifica un merge en `main`, integración global con W01–W04 ni revisión funcional del frontend de libros. Se mantienen pendientes de revisión de integración por IA6; fuera del alcance de la presente campaña, no constituyen fallos de estas pruebas.

**Control de ramas:** no se modificaron `main`, V28, PR118, rama árbitra ni ramas de las otras trabajadoras; sin cambios en catálogos, learnsets, políticas, partidas reales, máquinas históricas excluidas o módulos de producción; sin merge.

El CSV mantiene `EN_CI_AUTOMATICA` como estado histórico del push que lanzó la CI; el veredicto PASS definitivo consta en este informe, continuidad y Actions. No editar el CSV solo para actualizar su etiqueta y provocar otra ejecución innecesaria.

**STOP.** No hay bloque 11 ni se inicia campaña adicional con `p`. La integración/aceptación global corresponde a IA6.
