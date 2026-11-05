# IA5/W05 — CAMPAÑA_006 · BLOQUE 06/10

**Fecha:** 2026-11-05. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Estado de publicación:** EN_CI_AUTOMATICA (histórico). **Estado actual:** CI PASS VERIFICADA. **Commit del fixture:** `5e25c47f550cc01123bd8c9b192c8f7853129090`.

## Cola IA6 y asignaciones canónicas

La fila 06 de la cola oficial en la rama árbitra reserva exclusivamente `tm227;tm228;tm229;tm01;tm02`. Mapeos confirmados contra `modules/inventory/item_connections_v1.json` en la versión activa `scarlet-violet`:

| MT | Movimiento SV |
| --- | --- |
| `tm227` | `alluring_voice` |
| `tm228` | `psychic_noise` |
| `tm229` | `upper_hand` |
| `tm01` | `take_down` |
| `tm02` | `charm` |

**Importante:** `tm01` y `tm02` conservan numeración usada en otros juegos, pero sus movimientos en SV son respectivamente `take_down` y `charm`. No se prueban ni activan mapeos antiguos. La fila 06 está incluida por IA6 dentro de las 49 reservas de CAMP006 y no se toma como permiso para duplicar pruebas de la CAMPAÑA_002 como entregas nuevas.

## Cobertura y controles

- Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_006.json`: **6 bloques / 30 MT**. Se conservan íntegros los 25 casos de 01–05.
- Python `tests/tools/test_parallel_items_w05_campaign_006.py --ci`: mapeo SV, reserva, exclusiones, unicidad intra campaña, datos y learnset compatible.
- Godot `tests/gameplay/parallel_items_w05_campaign_006.gd`: enseñanza positiva real con `FieldItemService.teach`, PP del movimiento, consumo de una unidad, conservación de Pokémon/propietario, persistencia SaveV2 y negativas por stock ausente, Pokémon ajeno, incompatibilidad y movimiento ya conocido, sin mutación.
- Se mantienen los runners, aserciones y contratos previos sin relajación. No hay parches en producción ni cambios en catálogos, políticas, learnsets, reglas, partidas reales o ramas ajenas.
- Regresiones CAMP005/004/003 completas aprobadas en hito 05 [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826); se exigirán de nuevo en 10/10 o modificación de módulos.

## Resultado CI del bloque 06 — PASS certificado

[GitHub Actions #41954495779](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41954495779): `completed/success` sobre SHA probado `54a05072b658329ef1b3a74d1fc67524225b78d5`, job `127006028074`. Recibos comprobados literalmente en logs del job:

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=6 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=6 checks=294`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=6 checks=294`
- `CAMP006_W05_GODOT PASS blocks=6 checks=1096`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=6 checks=1096`

Regresiones completas CAMP005/004/003: `skipped`, conforme a hito 06 sin cambio en `modules/`. El hito 05 ya certificó las seis regresiones completas en [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826). CSV preserva `EN_CI_AUTOMATICA` como estado histórico al disparar CI; el resultado PASS está certificado aquí. CI headless no demuestra UI/GPU ni integración global.

**Próxima `p` tras certificación:** bloque 07 `tm03;tm04;tm05;tm06;tm08`. No merges.
