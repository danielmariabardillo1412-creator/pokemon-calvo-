# IA5/W05 — CAMPAÑA_004 · ITER_09/10

**Estado de entrega: EN_CI_AUTOMATICA.** La CI funcional del bloque 09 debe comprobarse antes de afirmar PASS para 54 MT.

## IDs autorizados por IA6

Rama exclusiva: `codex/calvo-items-20261103-w05-camp004`. Gate `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md` y AUTONOMOUS_REPAIR_V5 de la rama árbitra.

| MT | Movimiento `scarlet-violet` |
|---|---|
| `tm130` | `helping_hand` |
| `tm131` | `pollen_puff` |
| `tm132` | `baton_pass` |
| `tm133` | `earth_power` |
| `tm134` | `reversal` |
| `tm135` | `ice_beam` |

Cada par fue cotejado contra la fila 09 de la cola IA6 y `modules/inventory/item_connections_v1.json` para Scarlet/Violet.

## Cambios y evidencias

- Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_004.json`: agregado exclusivamente bloque 09 con seis IDs, conservando los bloques 01–08. Commit `c89ed525a7355a36484bc8aaa6d3e9a084fef4f1`.
- Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: una fila nueva `09` con estado `EN_CI_AUTOMATICA`, commit `cc092d4935036be18503965af3519852ecc9b39f`, que dispara la CI.
- Validación documental post-commit realizada: **9 bloques, 9 filas, 54 máquinas únicas**, seis por bloque, sin divergencias de IDs, orden ni movimientos con la cola IA6 y el catálogo SV. Esta comprobación no sustituye la enseñanza funcional en Godot.
- Suites propias acumulativas Python/Godot CAMP004 conservadas, sin parche de producción ni cambios de aserciones. Comprueban metadatos, learnset real SV, `FieldItemService.teach`, PP, consumo, propietario, incompatibilidad, no-stock, repetición y SaveV2.

## CI real y regresión

- **Bloques 01–08 verificados:** [GitHub Actions #41584156568](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584156568), SHA `2d62f9efda8f47c1c434fe5a9b5b8dbd166b9f43`, `completed/success`. Recibos Python `CAMP004_W05_PY PASS blocks=8 checks=464` y Godot `CAMP004_W05_GODOT PASS blocks=8 checks=1736`; ambos gates PASS.
- Regresión en el mismo run: CAMP003 Python `PASS blocks=10 checks=580`, Godot `PASS blocks=10 checks=2166` para 60 MT previas; CAMP002 11 tests `OK`.
- **Nuevo bloque 09:** [GitHub Actions #41589081119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589081119), SHA exacto `cc092d4935036be18503965af3519852ecc9b39f`, `pending` en primera consulta. Run anterior del fixture #41589064444 estaba `in_progress` y puede cancelarse por concurrencia. Su cancelación no significa fallo.
- Para declarar **54/54 MT** funcionalmente verificadas, leer `completed/success` y los recibos `CAMP004_W05_PY PASS blocks=9 checks=N`, `CAMP004_W05_GODOT PASS blocks=9 checks=N`, ambos gates y regresiones en el mismo SHA.

## Continuidad

**Próxima `p`:** verificar la CI 09; con resultado `success`, ejecutar únicamente el último **bloque 10**, `tm136;tm137;tm138;tm139;tm140;tm141`. Ante fallo, diagnosticar y reparar autónomamente pruebas/función W05 bajo V5 con regresión real, sin reducir aserciones ni alterar otros sistemas. Conflicto compartido, diseño global o permiso denegado real → IA6.

No tocar `main`, V28, PR118, árbitra, otras ramas, catálogos, políticas, 19 máquinas legacy, saves, workflows o producción ajena; sin merge ni validación visual/GPU por headless. Después del bloque 10: `CAMPAÑA_004_FINALIZADA` y STOP.

**Entrega bloque 09/10 publicada; certificación CI nueva pendiente al redactar.**
