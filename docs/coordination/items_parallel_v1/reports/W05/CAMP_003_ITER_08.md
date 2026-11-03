# IA5/W05 — CAMPAÑA_003 · ITER_08/10 — enseñanza de MT Scarlet/Violet

**Estado de entrega: EN_CI_AUTOMATICA.** El PASS funcional de las seis MT de este bloque no se certifica hasta comprobar la nueva CI de GitHub Actions.

## Encargo autorizado y datos canónicos
- Rama propia: `codex/calvo-items-20261103-w05-camp003`. Autoridad: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv` y `campaigns/CAMP_003_W05.md` en rama árbitra.
- Fila `08,W05,MACHINE`, seis IDs EXACTOS; todos los movimientos se verificaron directamente en el mapeo `scarlet-violet` de `modules/inventory/item_connections_v1.json`.

| Máquina | Movimiento |
| --- | --- |
| `tm63` | `psychic_fangs` |
| `tm64` | `bulk_up` |
| `tm65` | `air_slash` |
| `tm66` | `body_slam` |
| `tm67` | `fire_punch` |
| `tm68` | `thunder_punch` |

## Publicación
1. `tests/fixtures/parallel_items/w05_campaign_003.json`: añadidas únicamente las seis entradas del bloque `08`, preservados 01–07. Commit **`75082f500b06d27c80de3b117c2ce8a25d67ec56`**.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv`: exactamente una nueva fila `08`, `EN_CI_AUTOMATICA`, commit **`aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`**. Es el SHA de activación de la CI más reciente.
3. Suites acumulativas propias `tests/tools/test_parallel_items_w05_campaign_003.py` y `tests/gameplay/parallel_items_w05_campaign_003.gd` conservadas sin modificar. Validan dinámicamente todos los bloques del fixture: aquí deben comprobar **8 bloques / 48 máquinas**, con PP, learnset real `machine/scarlet-violet`, propiedad, consumo, incompatibilidad, rechazos y SaveV2. En ausencia de contexto real no pueden dar PASS.
4. **Verificación estática efectuada:** 8 bloques exactos, 48 MT únicas, 8 filas de progreso y correspondencia íntegra entre la cola de IA6, los movimientos del perfil y cada entrada del fixture. Sin discrepancias. No equivale a ejecución del bloque 08.

## Evidencia CI
- **Bloques 01–07 pasaron CI real:** [#41560159198](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560159198) SHA `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`, `completed/success`. En el log del job: `CAMP003_W05_PY PASS blocks=7 checks=406` y `CAMP003_W05_GODOT PASS blocks=7 checks=1521`. El validador compartido confirma ambos recibos.
- **Bloque 08 no acreditado todavía:** [#41560433553](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560433553), SHA `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c` del progreso; `pending` en la primera consulta. La ejecución anterior del fixture [#41560420588](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560420588) estaba `in_progress` y puede quedar cancelada por `concurrency.cancel-in-progress`; **el run de progreso es el decisivo**.
- Contrato esperado para dar PASS: `CAMP003_W05_PY PASS blocks=8 checks=M` y `CAMP003_W05_GODOT PASS blocks=8 checks=M`, con `M > 0`, y `completed/success` del mismo SHA.

## Continuación y protección
- **Siguiente `p`:** comprobar último run real del SHA de progreso 08/10; si `success`, ejecutar exclusivamente bloque **09** (`tm69;tm70;tm71;tm72;tm73;tm74`). Si `queued/in_progress`, solo un bloque de pruebas independiente y sin PASS inventado. Si `failure`, corregir exclusivamente pruebas W05 sin rebajar aserciones o STOP y elevar IA6 ante incidencia de servicio, catálogo, SaveV2 o política.
- Intocables: `main`, V28, PR118, ramas ajenas, árbitra, `modules/`, `data/`, `config/`, catálogo canónico, CI compartida, partidas reales y 19 MT legadas. GPU/UI/arte no comprobados.

**BLOQUE 08/10 ENTREGADO; CI del bloque aún pendiente.**
