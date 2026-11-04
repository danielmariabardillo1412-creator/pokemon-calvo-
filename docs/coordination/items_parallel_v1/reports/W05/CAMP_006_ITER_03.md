# IA5/W05 — CAMPAÑA_006 · BLOQUE 03/10

**Fecha:** 2026-11-04. **Estado de publicación:** EN_CI_AUTOMATICA (histórico), **CI PASS VERIFICADA** posteriormente. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Commit de fixture/contrato:** `a2716f2dffb16212be3c3ec5827d12c4a7126d80`.

## Reserva IA6 y movimientos reales
Solo cinco máquinas de la tercera fila de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` (comparada con la rama árbitra) y sus movimientos exactos del perfil versionado `scarlet-violet`:

| MT | Movimiento |
| --- | --- |
| `tm212` | `triple_axel` |
| `tm213` | `coaching` |
| `tm214` | `sludge_wave` |
| `tm215` | `scorching_sands` |
| `tm216` | `feather_dance` |

## Pruebas comprometidas
- Fixture propio `tests/fixtures/parallel_items/w05_campaign_006.json` ahora contiene **3 bloques / 15 MT**, sin retirar ni modificar las 10 MT ya certificadas de 01/02.
- Los runners acumulativos `tests/tools/test_parallel_items_w05_campaign_006.py` y `tests/gameplay/parallel_items_w05_campaign_006.gd` ya ejecutan cada registro declarado en fixture y progreso. No se han relajado ni sustituido por aserciones de metadatos.
- Python comprueba reserva, unicidad, perfil SV, datos canónicos, PP, política y una especie con learnset SV; este recibo **no prueba Godot**.
- Godot usa `FieldItemService.teach` para cada MT con especie real compatible; comprueba PP correcto, consumo de exactamente una unidad, propiedad/identidad, falta de stock, incompatibilidad, movimiento repetido, rechazo sin mutación y guardado/carga SaveV2.
- Sin cambios a motor, catálogos, learnsets, políticas, partidas reales, UI, `main`, V28, ramas ajenas ni máquinas históricas. Se mantienen pruebas anteriores. Regresiones CAMP005/004/003 completas en hitos 05/10 o si cambia producción; hito 01 ya fue aprobado.

## Resultado CI — PASS funcional certificado

[GitHub Actions #41778440182](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778440182): `completed/success`, SHA probado `2c44ac98354d163f755fb408372b8c54b0a9cfec`, job `126404154789`. Recibos extraídos del log real (mismo commit de fixture y CSV):

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=3 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=3 checks=147`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=3 checks=147`
- `CAMP006_W05_GODOT PASS blocks=3 checks=556`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=3 checks=556`

Paso de regresiones CAMP005/004/003: `skipped` por calendario de hitos 01/05/10 (no se modificó `modules/`). Hito 01 tenía regresiones aprobadas. No confundir este PASS headless con inspección gráfica ni con merge global. CSV conserva `EN_CI_AUTOMATICA` como estado histórico de publicación, y no se modifica únicamente por el PASS.

**Próxima `p` tras cierre válido:** bloque 04 `tm217;tm218;tm219;tm220;tm221`. Sin merges.
