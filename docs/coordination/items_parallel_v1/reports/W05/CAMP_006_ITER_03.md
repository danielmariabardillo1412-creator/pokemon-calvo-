# IA5/W05 — CAMPAÑA_006 · BLOQUE 03/10

**Fecha:** 2026-11-04. **Estado de publicación:** EN_CI_AUTOMATICA, SIN PASS VERIFICADO. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Commit de fixture/contrato:** `a2716f2dffb16212be3c3ec5827d12c4a7126d80`.

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

## Criterio CI pendiente
La nueva fila de `CAMP_006_PROGRESO.csv` activa `.github/workflows/parallel-camp006-w05-autoci.yml`. Exigir en mismo SHA: `completed/success` y recibos `CAMP006_W05_PY PASS blocks=3 checks=N`, `CAMP006_W05_GODOT PASS blocks=3 checks=N` y gates PY/GODOT con N positivo. **No atribuir PASS sin logs reales.**

**Próxima `p` tras cierre válido:** bloque 04 `tm217;tm218;tm219;tm220;tm221`. Sin merges.
