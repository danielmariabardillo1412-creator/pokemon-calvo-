# IA5/W05 — CAMPAÑA_004 · ITER_02/10 — MT Scarlet/Violet

**Estado de entrega: EN_CI_AUTOMATICA.** No atribuir PASS funcional a las seis MT nuevas hasta verificar la CI de este bloque.

## Encargo y fuente de verdad

Rama única `codex/calvo-items-20261103-w05-camp004`. Autorización oficial de IA6: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra. Bloque exacto `02,W05,MACHINE`:

| MT | Movimiento `scarlet-violet` |
| --- | --- |
| `tm88` | `swords_dance` |
| `tm89` | `body_press` |
| `tm90` | `spikes` |
| `tm91` | `toxic_spikes` |
| `tm92` | `imprison` |
| `tm93` | `flash_cannon` |

Los pares son los de la cola IA6 y se cotejaron individualmente con `modules/inventory/item_connections_v1.json`, versión activa SV. No se dedujo compatibilidad de generaciones anteriores.

## Trabajo publicado

1. **Fixture acumulativo** `tests/fixtures/parallel_items/w05_campaign_004.json`: bloque 02 añadido sin modificar bloque 01; commit `982c453964bec3c8baad6b12684d2cc78f6a8702`.
2. **Progreso** `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: una nueva fila `02`, `EN_CI_AUTOMATICA`; commit `fb5cb0433e17d805feb04755eed63b764005e797`, que activa workflow CI.
3. Suites propias ya preparadas `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` **conservadas sin cambios**. El runner Python exige mapeo, metadatos, versión, política y un learnset real SV por MT; el runner Godot exige enseñanza vía `FieldItemService.teach`, PP, stock, propiedad, especie compatible/incompatible, consumo, rechazo de repetición y SaveV2. Si el contrato falla, no reducir aserciones.
4. **Comprobación documental post-commit**: 2 bloques completos, 12 IDs únicos, orden y movimientos idénticos entre fixture, dos filas CSV, cola autorizada y perfil SV. Cero discrepancias; esto **no equivale** a resultado de tests funcionales.

## Evidencia CI y regresiones

- Bloque 01 ya acreditado: [GitHub Actions #41571216304](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571216304) `completed/success`, SHA `7d1b5b65da4135dc197a198ab08aa78e1646c84f`, Python CAMP004 `PASS blocks=1 checks=58`, Godot CAMP004 `PASS blocks=1 checks=231`. Mismo run: regresión CAMP003 de las 60 MT anteriores Python `PASS blocks=10 checks=580`, Godot `PASS blocks=10 checks=2166` y 11 tests CAMP002 `OK`.
- Bloque 02: [GitHub Actions #41572800181](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572800181), SHA de progreso `fb5cb0433e17d805feb04755eed63b764005e797`, inicialmente `pending`. La ejecución intermedia de fixture #41572746262 puede resultar `cancelled` por `concurrency.cancel-in-progress`; no confundir con fallo de pruebas.
- Contratos necesarios para aprobar: `CAMP004_W05_PY PASS blocks=2 checks=M`, `CAMP004_W05_GODOT PASS blocks=2 checks=M`, ambos gates de manifiesto y regresiones CAMP003/CAMP002 `PASS` sobre el mismo SHA `completed/success`.

## Autorreparación V5 y continuación

- Si CI falla, inspeccionar logs del SHA de progreso, reproducir error, reparar test propio o, ante defecto real dentro de especialidad W05, exclusivamente perfil o ruta `teach` en rama propia, con caso de regresión rojo/verde, sin relajar pruebas ni alterar APIs ajenas. Concurrencia, arquitectura, reglas ambiguas o permisos reales denegados requieren escalación.
- **Próxima `p`**: revisar CI del bloque 02 y, con `success`, ejecutar **solo bloque 03**, IDs `tm94;tm95;tm96;tm97;tm98;tm99`. No ejecutar más de un bloque por orden. Al 10/10 detenerse.
- No modificar `main`, V28, PR118, rama árbitra, otras trabajadoras, catálogo/política, 19 MT legacy, partidas reales ni workflow compartido. No fusionar ni atribuir validación visual/GPU por CI headless.

**BLOQUE 02/10 ENTREGADO. Estado funcional del bloque nuevo pendiente de CI.**
