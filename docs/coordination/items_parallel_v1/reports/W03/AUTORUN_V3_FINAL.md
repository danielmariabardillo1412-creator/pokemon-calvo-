# IA3/W03 — AUTORUN TANDA 03 CIERRE: REPEAT BALL NATIVA L3

**Fecha:** 2026-11-10. **Rama:** `codex/calvo-items-20261104-w03-camp006`. **Orden IA6:** `IA6_AUTORUN.md` TANDA 03 y `AUTONOMY_V1/QUEUE_W03_TANDA_03.md`.

## Alcance y resultado

**Diez hitos examinados; 1 objeto funcional L3 añadido:** `repeat_ball`. Las filas 07 y 08 quedan **QA parcial**, no se certifica cobertura exhaustiva de todos los negativos exigidos ni una captura específicamente después de Transformación. No existen diez objetos nuevos: los diez hitos corresponden al mismo productor Repeat Ball.

| Fila | Resultado | Evidencia / límite |
| --- | --- | --- |
| 01 | L1 trazado | `ShowdownAdventureSession.capture` -> `CaptureInventoryService.resolve` -> `_finish` -> `PlayerCollection` |
| 02 | L3 test positivo y negativo | `parallel_items_w03_repeat_native_v3.gd`; prueba directa nativa, no la documentación antigua de L2 |
| 03 | L3 positivo | `previously_caught_base_species` procede de `player.has_previously_caught(target.base_species_id(),catalogs)` **antes** de resolver la bola |
| 04 | L3 positivo | Sólo tras resolución `SUCCESS` y `_finish("CAPTURED", ...).accepted`, registrar especie base en el ledger existente. Fallos, inventario inválido y otras finalizaciones no anotan |
| 05 | L3 positivo | Primera Master Ball en encuentro nativo; historial `pidgey`; guardado manual con SaveV2 embebido |
| 06 | L3 positivo | Recarga nativa; segundo encuentro; Repeat Ball con probabilidad bonificada; gasto exactamente una unidad; ledger sin duplicados |
| 07 | **QA parcial** | Se verifica no-stock nativo sin mutación/RNG, duplicado rechazado, y regresiones de Capture/SaveV2; **faltan test independiente nativo con party+storage totalmente llenos y fallo aleatorio de captura** |
| 08 | **QA parcial** | Guardar/cargar sesión nativa activa antes de Repeat, ledger y checkpoint íntegros; el runner nativo histórico cubre mecánicas y recuperación en general, pero **no demuestra Repeat tras Transformación específica** |
| 09 | QA completo de regresión | Repelentes 100/200/250, Cuerda Huida, captura nativa de campo, SaveV2 y CAMP005/CAMP006 conservados |
| 10 | CI de código **SUCCESS** | [#42869290576](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869290576) sobre SHA `7ef7dbb22c748306724658d122074c32d3f343e2`; último checkpoint documental `6ee302703f335bd0de2e65792cddf420e4d252b7` revalidado con [CI final #42869862584](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869862584) **completed/SUCCESS**, incluidos los tests nativos de Repeat Ball y las regresiones |

## Evidencia comprobada de código

- `W03_REPEAT_NATIVE_V3 PASS checks=26`: primera captura con Master Ball, historial solo tras éxito, guardado y recarga, Repeat Ball real en batalla nativa, consumos, deduplicación, no-stock sin alterar RNG y recuperación del combate previo al segundo intento.
- `CAMP006_W03_PY PASS blocks=3 checks=54 deferred=1`.
- `CAMP006_W03_GODOT PASS blocks=3 checks=78`.
- `CAMP006_W03_REPEL_L3 PASS checks=65`.
- `CAMP005_W03_PY PASS blocks=10 checks=169`.
- `CAMP005_W03_GODOT PASS blocks=10 checks=208`.
- `FIELD_NATIVE PASS checks=118 GPU=false errors=0`.
- SaveV2 colección/adversarial y W03 Repeat V2 también aprobaron en la misma ejecución.

## Cambios autorizados en esta tanda

- `modules/gameplay/showdown_adventure_session.gd::capture`: dos seams, propiedad de contexto del jugador antes del cálculo y registro de éxito después de `_finish` aceptado. No cambiar `_finish`, generador de RNG, combate, trainer, medicina, inventario global ni otros objetos.
- `tests/gameplay/parallel_items_w03_repeat_native_v3.gd`: test native real desde `field_demo.tscn`.
- `.github/workflows/parallel-camp006-w03-autoci.yml`: runner nuevo sin eliminar regresiones; una inserción malformada se corrigió antes de lograr CI real.
- `reports/W03/AUTORUN_V3_PROGRESS.csv` y este informe.

**No modificados:** `main`, V28, PR118, árbitra, otras ramas, `modules/save/**`, `FieldItemBag`, `CreatureInstance`, `CaptureSystem`, `SaveGameSerializer`, backend Showdown general, mecánicas de W04/W05.

## Revisión de IA6

Hay que integrar selectivamente el cambio localizado de `showdown_adventure_session.gd::capture`; no hacer merge ciego de rama. Las QA 07 y 08 permanecen parciales a falta de casos nativos independientes. La TANDA 03 no autoriza empezar una TANDA 04 sin nueva cola.
