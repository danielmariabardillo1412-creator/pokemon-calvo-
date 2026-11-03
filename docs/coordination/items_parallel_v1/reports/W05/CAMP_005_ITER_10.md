> **CERTIFICACIÓN DEFINITIVA BLOQUE 10/10 — CI PASS (2026-11-04).** [GitHub Actions #41742499805](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742499805), SHA de pruebas `b886c10756ad843d5f92834f29a42d31e63cf262`, job `126287538668`, `completed/success`. Se comprobaron directamente los logs de la ejecución final:
>
> - `CAMP005_W05_MANIFEST_PASS reserved=10 completed=10 ids=60 kind=NEW_IDS`
> - `CAMP005_W05_PY PASS blocks=10 checks=580`
> - `CAMP005_GATE_PY_PASS worker=W05 blocks=10 checks=580`
> - `CAMP005_W05_GODOT PASS blocks=10 checks=2166`
> - `CAMP005_GATE_GODOT_PASS worker=W05 blocks=10 checks=2166`
> - Regresión CAMP004 de 60 MT: `CAMP004_W05_PY PASS blocks=10 checks=580` y `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
> - Regresión CAMP003 de 60 MT: `CAMP003_W05_PY PASS blocks=10 checks=580` y `CAMP003_W05_GODOT PASS blocks=10 checks=2166`
>
> **VEREDICTO:** 60/60 MT nuevas de CAMP005 con pruebas funcionales Python y Godot aprobadas; 60 MT CAMP004 + 60 MT CAMP003 regresionadas y PASS en el mismo run. **`CAMPAÑA_005_FINALIZADA`, STOP W05.** Este veredicto posterior prevalece sobre referencias históricas inferiores a CI pendiente. No equivale a integración global ni prueba visual/GPU; sin cambios de producción o tests relajados.

# IA5/W05 — CAMPAÑA_005 · ITER_10/10 · CIERRE DE MT

**Estado inicial: 10/10 entregados; CI final pendiente de los recibos reales.**

## Autorización y seis MT finales

Rama exclusiva `codex/calvo-items-20261103-w05-camp005`; autorización IA6 en `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md`. Fila oficial 10:

| MT | Movimiento Scarlet/Violet |
| --- | --- |
| `tm196` | `flip_turn` |
| `tm197` | `dual_wingbeat` |
| `tm198` | `poltergeist` |
| `tm199` | `lash_out` |
| `tm200` | `scale_shot` |
| `tm201` | `misty_explosion` |

## Entrega y pruebas acumulativas

- Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`: añadido exclusivamente bloque 10, conservados 01–09; commit `d351a80cff579fc951e534580ab7fa26114b4868`.
- CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una fila 10 `EN_CI_AUTOMATICA`, commit `b886c10756ad843d5f92834f29a42d31e63cf262`. Dispara CI completa del hito final.
- **Control estático posterior a GitHub**: exactamente **10 bloques/10 filas/60 IDs únicos**, seis MT por bloque. Todos los IDs/parejas/orden idénticos entre fixture, CSV, cola oficial de IA6 y `modules/inventory/item_connections_v1.json` en versión `scarlet-violet`; cero discrepancias.
- Runners sin alteraciones `tests/tools/test_parallel_items_w05_campaign_005.py` y `tests/gameplay/parallel_items_w05_campaign_005.gd`: validación de catálogo/política, PP, learnset de especie elegible real SV; `FieldItemService.teach` en Godot 4.7 con compatible, incompatible, rechazo por stock o propietario, consumo exacto de una MT, rechazo de enseñanza repetida, identidad/party y SaveV2.
- No se modificó código de producción ni política, catálogos o learnsets; no se relajaron aserciones.

## Certificación y regresiones

- **01–09 verificados por CI:** [Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, `completed/success`; `CAMP005_W05_PY PASS blocks=9 checks=522`, `CAMP005_W05_GODOT PASS blocks=9 checks=1951`, gates PASS.
- **CI final hito 10** [Actions #41742499805](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742499805), SHA `b886c10756ad843d5f92834f29a42d31e63cf262`, inicialmente `pending`. El run intermedio de fixture #41742478253 puede cancelarse por concurrencia, que no equivale a un fallo funcional.
- **Requisitos para certificación final:** CI `completed/success`; recibos exactos `CAMP005_W05_PY PASS blocks=10 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=10 checks=N`, `CAMP005_W05_GODOT PASS blocks=10 checks=N`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=10 checks=N`, con N positivo.
- Regresiones obligatorias **en el mismo run final**: `CAMP004_W05_PY PASS blocks=10 checks=N`, `CAMP004_W05_GODOT PASS blocks=10 checks=N` y sus equivalentes de `CAMP003_W05_PY/GODOT`. Cada una prueba 60 MT de la campaña anterior. Pasaron previamente en hito 05; hay que repetirlas aquí para acreditar que las 120 anteriores no se han roto.

## Integración, límites y STOP

La CI headless no equivale a integración global ni revisión de UI/GPU. No tocar `main`, V28, PR118, rama árbitra, otras W, catálogos, learnsets, políticas, 19 MT legacy inactivas, guardados reales, workflows ni hacer merge. IA6 audita la rama y autoriza integración.

Con CI final y todas las regresiones PASS, publicar `CAMP_005_FINAL.md`, actualizar `CONTINUIDAD.md`, comunicar **`CAMPAÑA_005_FINALIZADA`** y **STOP**. No existe bloque 11 autorizado.

**ITER_10 entregada; CI pendiente al redactar.**
