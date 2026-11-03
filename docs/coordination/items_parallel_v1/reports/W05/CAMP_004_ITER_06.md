# IA5/W05 — CAMPAÑA_004 · ITER_06/10 — MT Scarlet/Violet

**Estado al publicar: EN_CI_AUTOMATICA.** La correspondencia documental de seis MT nuevas no acredita funcionamiento hasta verificar la CI.

## Asignación autorizada

- Rama exclusiva: `codex/calvo-items-20261103-w05-camp004`.
- Autoridad IA6: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y `AUTONOMOUS_REPAIR_V5.md`.
- Fila exacta `06,W05,MACHINE`, seis MT `scarlet-violet` cotejadas con `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm112` | `aura_sphere` |
| `tm113` | `tailwind` |
| `tm114` | `shadow_ball` |
| `tm115` | `dragon_pulse` |
| `tm116` | `stealth_rock` |
| `tm117` | `hyper_voice` |

## Publicación y comprobación documental

1. `tests/fixtures/parallel_items/w05_campaign_004.json`: añadido exclusivamente el bloque 06, conservando 01–05 sin reescritura; commit `d1b7ce62395cedf340db44dc4aff1fbcef0c630a`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: una fila nueva 06, estado `EN_CI_AUTOMATICA`, commit `e3ef241634ad013d20907272ca319cfdd51fba6c` que activa la CI acumulativa.
3. Validación estática post-commit frente a GitHub: **6 bloques, 6 filas CSV, 36 máquinas distintas**, sin duplicados ni desajustes de orden, IDs o movimiento entre la cola de IA6, fixture, progreso y perfil SV. Esta validación no equivale a ejecutar enseñanza Godot.
4. Los runners `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` se mantienen acumulativos **sin modificaciones**: Python comprueba versión, metadatos, política y learnset real; Godot verifica `FieldItemService.teach`, positivo compatible, negativo incompatible/stock/propiedad, PP, consumo de unidad, repetición y SaveV2. No se inventaron especies ni se hicieron parches funcionales sin defecto probado.

## Evidencia CI

- Los primeros cinco bloques (**30 MT**) están certificados: [GitHub Actions #41576524159](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576524159), SHA `0ab410a15fa47b301b76f68c402a2e8e8d3d9fd7`, `completed/success`; logs `CAMP004_W05_PY PASS blocks=5 checks=290`, `CAMP004_W05_GODOT PASS blocks=5 checks=1091` y ambos gates correctos.
- En ese mismo run: regresión **CAMP003** de 60 MT (`CAMP003_W05_PY PASS blocks=10 checks=580`, `CAMP003_W05_GODOT PASS blocks=10 checks=2166`) y **CAMP002** (11 tests `OK`).
- Nuevo bloque 06: [GitHub Actions #41579048410](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579048410) SHA de progreso `e3ef241634ad013d20907272ca319cfdd51fba6c`, inicialmente `pending`. La ejecución previa de fixture #41579033578 estaba `in_progress` y puede resultar `cancelled` por la política de concurrencia, lo que no indica defecto funcional.
- Para certificar **36 MT**, exigir en el run exacto `completed/success`, `CAMP004_W05_PY PASS blocks=6 checks=M`, `CAMP004_W05_GODOT PASS blocks=6 checks=M`, ambos gates `PASS`, regresiones CAMP003 y CAMP002 y M positivo. No declarar PASS por estar en cola.

## Continuidad y control V5

- **Próxima `p`:** comprobar CI bloque 06; con `success`, ejecutar solo bloque **07**, `tm118;tm119;tm120;tm121;tm122;tm123`, sin adelantar 08. Si CI sigue en curso, solo un bloque independiente autorizado, sin PASS inventado. Ante `failure`, diagnosticar logs y reparar dentro de la especialidad W05 con `AUTONOMOUS_REPAIR_V5.md`, nuevo test de reproducción y regresión completa, sin rebajar aserciones.
- Escalar a IA6 solo conflicto con otra trabajadora, modificación de API/arquitectura compartida, norma general ambigua o acceso realmente denegado. No modificar `main`, V28, PR118, árbitra, ramas ajenas, catálogos, políticas, 19 MT históricas, workflows ni partidas reales. No fusionar; CI headless no acredita GPU/UI.
- Diez bloques máximo; al 10/10 comunicar `CAMPAÑA_004_FINALIZADA` y STOP.

**ITER_06/10 entregada: 36 MT en fixture; CI funcional del nuevo bloque pendiente al redactar.**
