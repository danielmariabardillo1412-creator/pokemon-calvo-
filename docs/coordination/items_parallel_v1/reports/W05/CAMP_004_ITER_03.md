# IA5/W05 — CAMPAÑA_004 · ITER_03/10 — enseñanza MT Scarlet/Violet

**Estado al entregar: EN_CI_AUTOMATICA.** No se da PASS al bloque 03 sin resultado final de CI y recibos de Python y Godot.

## Mandato y asignación
- **Rama exclusiva**: `codex/calvo-items-20261103-w05-camp004`.
- Fuente de autoridad: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de la rama de IA6.
- Fila exacta `03,W05,MACHINE` en Scarlet/Violet:

| MT | Movimiento de la versión `scarlet-violet` |
| --- | --- |
| `tm94` | `dark_pulse` |
| `tm95` | `leech_life` |
| `tm96` | `eerie_impulse` |
| `tm97` | `fly` |
| `tm98` | `skill_swap` |
| `tm99` | `iron_head` |

Los seis movimientos fueron cotejados con `modules/inventory/item_connections_v1.json`, sin usar asignaciones de otra generación ni suponer especies compatibles.

## Publicaciones en la rama propia
1. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json`: se añadió exclusivamente bloque `03` con seis casos; los bloques `01` y `02` quedaron intactos. Commit `2b3b1237edd4695599e9a0f4cbb4caf694fed27f`.
2. CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: solo se añadió una fila `03`, estado `EN_CI_AUTOMATICA`, commit `e902ea2e8df76d3273fcdd6020186fcedc2f8ef4` que activa la CI.
3. Suites acumulativas W05 CAMP004 existentes `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` **sin modificar**. Godot llama `FieldItemService.teach` y comprueba learnset real SV, PP, compatibilidad, rechazo de uso sin stock, propietario ajeno, incompatibilidad, consumo, repetición sin doble coste y SaveV2. Python coteja datos y política. No se inventaron criaturas válidas ni se redujeron aserciones.
4. **Cotejo estático ejecutado en GitHub**: exactamente tres bloques, 18 MT únicas, tres filas CSV y mapeos idénticos a las tres filas de la cola IA6 y el perfil `scarlet-violet`; sin diferencias. La coherencia documental no es resultado de las pruebas de Godot.

## Evidencia y verificación CI
- **Bloques 01–02 realmente verificados:** [Actions #41572800181](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572800181), commit `fb5cb0433e17d805feb04755eed63b764005e797`, `completed/success`. Recibos de los logs: `CAMP004_W05_PY PASS blocks=2 checks=116` y `CAMP004_W05_GODOT PASS blocks=2 checks=446`, más gates de manifiesto `PASS`.
- En el mismo run, **regresiones preservadas**: CAMP003 60 MT, Python `PASS blocks=10 checks=580` y Godot `PASS blocks=10 checks=2166`; 11 tests de CAMP002 `OK`.
- **Nuevo bloque 03 (aún sin certificar al publicar):** [Actions #41573686036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573686036), SHA `e902ea2e8df76d3273fcdd6020186fcedc2f8ef4` de progreso, `pending` en primera consulta. Run intermedio del fixture #41573673543 estaba `in_progress`, susceptible de `cancelled` por concurrencia al entrar el run de progreso. No confundir cancelación con fallo de Godot.
- PASS del bloque 03 exige `completed/success` del **SHA de progreso** más recibos `CAMP004_W05_PY PASS blocks=3 checks=M` y `CAMP004_W05_GODOT PASS blocks=3 checks=M`, M positivo, gates de manifiesto correctos y regresiones CAMP003 y CAMP002.

## Próxima orden «p» y límites
- Comprobar primero CI del SHA de progreso; con `success`, ejecutar **solamente bloque 04** `tm100;tm101;tm102;tm103;tm104;tm105`. Si CI sigue en curso, se permite avanzar únicamente en un bloque independiente autorizado sin atribuir PASS. Si falla, diagnosticar y reparar autónomamente según protocolo V5 en su arnés o perfil/función `teach`, con regresiones intactas. Problema de arquitectura/API compartida, conflicto funcional con otra IA o permisos realmente denegados: escalar concretamente a IA6.
- No cambiar `main`, V28, PR118, árbitra, ramas W01–W04, catálogo canónico, política, 19 máquinas legacy, otros sistemas, workflows ni guardados reales. No hacer merge ni certificar UI/GPU headless.
- Al 10/10 `CAMPAÑA_004_FINALIZADA` y STOP, sin inventar ID, bloque 11 o nueva campaña.

**Entrega documental y pruebas: 03/10 publicado, 18 MT en suite, certificación de las seis nuevas pendiente al redactar.**
