> **CERTIFICACIÓN FUNCIONAL DEFINITIVA — HITO 05/10 (2026-11-03).** [GitHub Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), SHA funcional `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`, job `126215005633`, `completed/success`. Recibos de log reales:
> - `CAMP005_W05_MANIFEST_PASS reserved=10 completed=5 ids=60 kind=NEW_IDS`
> - `CAMP005_W05_PY PASS blocks=5 checks=290`
> - `CAMP005_GATE_PY_PASS worker=W05 blocks=5 checks=290`
> - `CAMP005_W05_GODOT PASS blocks=5 checks=1091`
> - `CAMP005_GATE_GODOT_PASS worker=W05 blocks=5 checks=1091`
> - Regresión CAMP004 60 MT: `CAMP004_W05_PY PASS blocks=10 checks=580` y `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
> - Regresión CAMP003 60 MT: `CAMP003_W05_PY PASS blocks=10 checks=580` y `CAMP003_W05_GODOT PASS blocks=10 checks=2166`
>
> **RESULTADO:** 30/30 MT de CAMP005 validadas por Python/Godot, con regresiones completas CAMP004 y CAMP003 también PASS. Este veredicto prevalece sobre el estado CI pendiente que aparece más abajo como registro histórico. No se modificó producción. Godot headless no certifica interfaz/GPU.

# IA5/W05 — CAMPAÑA_005 · ITER_05/10 · HITO DE REGRESIÓN

**Estado inicial al publicar: EN_CI_AUTOMATICA.** La validación documental no acredita enseñanza funcional ni regresiones hasta leer los logs CI.

## Mandato IA6 y asignación SV
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp005`; gate `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md` y protocolo `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra.
- Bloque 05 exacto `tm166;tm167;tm168;tm169;tm170;tm171`, con estos mapeos `scarlet-violet` de `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm166` | `thunder` |
| `tm167` | `close_combat` |
| `tm168` | `solar_beam` |
| `tm169` | `draco_meteor` |
| `tm170` | `steel_beam` |
| `tm171` | `tera_blast` |

No asumir compatibilidad por existencia del mapeo: runners Python y Godot deben validar learnsets y enseñanza real, incluidos casos de rechazo.

## Entrega
1. `tests/fixtures/parallel_items/w05_campaign_005.json`: añadido exclusivamente bloque 05 y conservados 01–04, commit `c58a37bfd5f06550d0097ab58405680188622a0a`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una sola fila nueva `05` `EN_CI_AUTOMATICA`, commit `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`; activa CI.
3. Cotejo estático post-commit: **5 bloques, 5 filas, 30 MT distintas**, todas de seis ítems y concordancia exacta de IDs/orden/movimientos entre cola IA6, fixture, progreso y mapeo SV. Sin duplicados ni discrepancias.
4. Se conservan runners acumulativos `tests/tools/test_parallel_items_w05_campaign_005.py` y `tests/gameplay/parallel_items_w05_campaign_005.gd`, sin tocar producción. Python: datos, política, PP, mapeo y learnset de especie real SV. Godot: `FieldItemService.teach`, especie compatible/incompatible, stock, propietario, consumo unitario, identidad, PP, repetición sin coste y SaveV2.

## Evidencia de calidad
- Bloques 01–04 ya certificados: [Actions #41720191745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720191745), SHA `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, `completed/success`; `CAMP005_W05_PY PASS blocks=4 checks=232`, `CAMP005_W05_GODOT PASS blocks=4 checks=876`, gates PASS.
- CI hito 05 inicialmente pendiente: [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), SHA de progreso `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`. El run anterior del fixture #41721275333 puede ser cancelado por concurrencia sin constituir fallo funcional.
- Para declarar 30/30 MT: exigir `completed/success`, recibos `CAMP005_W05_PY PASS blocks=5 checks=N`, `CAMP005_W05_GODOT PASS blocks=5 checks=N`, y ambos gates `CAMP005_GATE_*` sobre el SHA de progreso, N positivo.
- **Primer hito de regresión obligatorio:** en el mismo run se deben leer `CAMP004_W05_PY PASS blocks=10 checks=N`, `CAMP004_W05_GODOT PASS blocks=10 checks=N`, `CAMP003_W05_PY PASS blocks=10 checks=N` y `CAMP003_W05_GODOT PASS blocks=10 checks=N`, con N positivo. La CI de este hito no puede considerarse aprobada sin dichos recibos.

## Continuidad y límites
- Siguiente `p`: comprobar veredicto del bloque 05 y sus regresiones antes de ejecutar exclusivamente bloque 06 `tm172;tm173;tm174;tm175;tm176;tm177`. Si falla, diagnosticar y autorreparar defectos propios bajo V5 sin rebajar aserciones.
- No tocar `main`, V28, PR118, árbitra, W01–W04, catálogos/learnsets, políticas, 19 MT históricas inactivas, partidas, workflows ni arquitectura compartida; sin merge. Headless no acredita GPU/UI.
- Detenerse al 10/10 con `CAMPAÑA_005_FINALIZADA`.

**Bloque 05 entregado, ejecución funcional y regresiones aún pendientes al redactar.**
