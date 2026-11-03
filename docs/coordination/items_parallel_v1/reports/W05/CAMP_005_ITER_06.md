> **CI DEFINITIVA VERIFICADA — BLOQUE 06/10 (2026-11-03):** [GitHub Actions #41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035), SHA funcional `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, job `126219771697`, `completed/success`. Recibos de logs reales: `CAMP005_W05_MANIFEST_PASS reserved=10 completed=6 ids=60 kind=NEW_IDS`; `CAMP005_W05_PY PASS blocks=6 checks=348`; `CAMP005_GATE_PY_PASS worker=W05 blocks=6 checks=348`; `CAMP005_W05_GODOT PASS blocks=6 checks=1306`; `CAMP005_GATE_GODOT_PASS worker=W05 blocks=6 checks=1306`. **36/36 MT de CAMP005 verificadas por pruebas automatizadas reales.** No se ejecutaron nuevamente las regresiones CAMP004/003 en este bloque 06; sí se verificaron en el hito 05. Este resultado prevalece sobre los estados de CI pendiente anotados más abajo antes de terminar el run. Sin modificaciones de producción. No se certifica interfaz visual/GPU.

# IA5/W05 — CAMPAÑA_005 · ITER_06/10

**Estado inicial:** EN_CI_AUTOMATICA; la validación estática de seis nuevas MT no acredita enseñanza real hasta leer la CI del mismo SHA.

## Autorización y mapeo

Rama exclusiva `codex/calvo-items-20261103-w05-camp005`; autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra. Bloque 06 `tm172;tm173;tm174;tm175;tm176;tm177`, mapeos `scarlet-violet` corroborados con `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm172` | `roar` |
| `tm173` | `charge` |
| `tm174` | `haze` |
| `tm175` | `toxic` |
| `tm176` | `sand_tomb` |
| `tm177` | `spite` |

## Entrega y comprobación

1. `tests/fixtures/parallel_items/w05_campaign_005.json`: solo agregado bloque 06, preservados 01–05; commit `7be70541c7879b2856cef432a2a1eb001939ca53`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una nueva fila 06 `EN_CI_AUTOMATICA`, commit `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, disparador CI.
3. Cotejo documental posterior a ambos commits: **6 bloques, 6 filas CSV, 36 IDs únicos**, seis por bloque, coincidencia exacta de orden, IDs y movimientos con cola IA6 y perfil SV. Cero discrepancias. No confundir con evidencia de aprendizaje real.
4. Runners CAMP005 Python/Godot sin cambios: comprueban metadatos, política, learnset SV real, tipo, PP, `FieldItemService.teach` con Pokémon compatible e incompatible, falta de stock/propietario, consumo de una unidad, intento repetido, identidad de instancia y SaveV2. No se modificó producción ni se redujeron pruebas.

## Evidencias CI

- Bloques 01–05 ya certificados: [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), SHA `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`, `completed/success`; `CAMP005_W05_PY PASS blocks=5 checks=290`, `CAMP005_W05_GODOT PASS blocks=5 checks=1091`, ambos gates PASS.
- En ese hito 05, regresiones completas de CAMP004: Python 580 checks y Godot 2166 PASS; CAMP003: Python 580 checks y Godot 2166 PASS. Estas regresiones no están previstas para el bloque 06 sin parches en producción.
- Nuevo run del bloque 06: [Actions #41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035), SHA funcional `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, observado inicialmente `pending`. El run previo del fixture #41722635151 puede resultar `cancelled` por la política de concurrencia.
- Certificación funcional del 06 exige `completed/success`, `CAMP005_W05_PY PASS blocks=6 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=6 checks=N`, `CAMP005_W05_GODOT PASS blocks=6 checks=N`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=6 checks=N`, con N positivo.

## Continuidad

La siguiente `p` ejecutará exclusivamente bloque **07** `tm178;tm179;tm180;tm181;tm182;tm183` después de comprobar la CI del bloque 06. Ante fallo, investigar logs y reparar bajo autonomía V5 únicamente pruebas o función de enseñanza propia de W05, conservando aserciones. Escalar a IA6 conflictos con API compartida, reglas ambiguas o ACL denegada real. Prohibido tocar `main`, V28, PR118, árbitra, otras W, catálogo/learnsets/políticas, las 19 MT históricas inactivas, partidas reales, workflows y hacer merge. Al 10/10 comunicar `CAMPAÑA_005_FINALIZADA` y STOP; CI headless no acredita UI/GPU.
