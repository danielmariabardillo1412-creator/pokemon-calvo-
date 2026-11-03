# IA5/W05 — CAMPAÑA_005 · ITER_02/10 — MT Scarlet/Violet

**Estado al publicar: EN_CI_AUTOMATICA.** No dar por aprobado el bloque 02 sin verificar los recibos Python y Godot del run de progreso.

## Autoridad y asignación

Rama exclusiva `codex/calvo-items-20261103-w05-camp005`. Fuente IA6 en `codex/calvo-items-20261101-arbitro`: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md`.

Bloque 02 autorizado `tm148;tm149;tm150;tm151;tm152;tm153` con el perfil activo `scarlet-violet`:

| MT | Movimiento SV |
| --- | --- |
| `tm148` | `sludge_bomb` |
| `tm149` | `earthquake` |
| `tm150` | `stone_edge` |
| `tm151` | `phantom_force` |
| `tm152` | `giga_impact` |
| `tm153` | `blast_burn` |

## Publicaciones y contratos

- Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`: añadidos exclusivamente seis casos al bloque 02, conservando íntegro el bloque 01; commit `ae06a0a83e5ae35011077ae465030fcda745cf74`.
- CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: añadida una única fila 02 `EN_CI_AUTOMATICA`, commit `83d89ccc862e2035181e7a0136c6256d73e9d063`, que activa la CI sobre los 12 casos.
- Se mantienen sin cambios los runners `tests/tools/test_parallel_items_w05_campaign_005.py` y `tests/gameplay/parallel_items_w05_campaign_005.gd`. El primero contrasta mapeo SV, metadatos de ataques, PP, política y al menos un learnset de máquina real SV para cada MT. El segundo ejecuta `FieldItemService.teach` real: compatible, incompatible, rechazo por falta de stock y propietario, PP, consumo único, repetición sin segundo coste, identidad y SaveV2.
- Cotejo estático post-commit: exactamente **2 bloques, 2 filas CSV y 12 MT distintas**, sin desviaciones respecto a cola oficial IA6 ni perfil SV. Esta verificación no es un sustituto de pruebas funcionales.

## Evidencia CI

- **Bloque 01 aprobado:** [GitHub Actions #41715365400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715365400), SHA `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, `completed/success`; `CAMP005_W05_PY PASS blocks=1 checks=58`, `CAMP005_W05_GODOT PASS blocks=1 checks=231`, ambos gates PASS.
- **Bloque 02 en ejecución/pendiente al redactar:** [GitHub Actions #41718416082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718416082), SHA `83d89ccc862e2035181e7a0136c6256d73e9d063`, primera consulta `pending`. Run anterior del fixture #41718391206 `in_progress`, susceptible de cancelarse por concurrencia; su cancelación no equivale a fallo de pruebas.
- Para certificar las 12 MT: run de progreso `completed/success` y recibos `CAMP005_W05_PY PASS blocks=2 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=2 checks=N`, `CAMP005_W05_GODOT PASS blocks=2 checks=N`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=2 checks=N`, con N positivo.
- El workflow de IA6 exige regresiones CAMP004 y CAMP003 al menos en hitos 05, 10 y parches funcionales propios. En el bloque 02 sin cambios de producción esas regresiones no se ejecutan; no atribuir un PASS inexistente.

## Próxima orden `p` y restricciones

Comprobar CI 02 antes de avanzar. Con resultado verde, ejecutar exclusivamente bloque **03** `tm154;tm155;tm156;tm157;tm158;tm159`. Si falla, diagnosticar logs y reparar autónomamente arnés/función W05 según V5 con nuevas pruebas reales, sin rebajar contratos. Escalar solo conflicto compartido, decisión global o permiso real denegado.

No tocar `main`, V28, PR118, rama árbitra, otras trabajadoras, catálogos/learnsets canónicos, políticas, 19 MT históricas inactivas, workflows ni guardados reales. Sin merge y sin atribuir pruebas visuales a Godot headless.

**ITER_02/10 publicada; PASS final pendiente al redactar.**
