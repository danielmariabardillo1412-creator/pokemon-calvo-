# IA5/W05 — CAMPAÑA_003 · ITER_09/10 — enseñanza MT Scarlet/Violet

**Estado: EN_CI_AUTOMATICA.** El PASS funcional de las seis MT nuevas está pendiente de la CI sobre el SHA del progreso.

## Autorización y datos originales
- Rama exclusiva `codex/calvo-items-20261103-w05-camp003`; autoridad `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv` y `campaigns/CAMP_003_W05.md` de IA6.
- Bloque exacto `09,W05,MACHINE`: seis MT nuevas, sin saltos ni reutilización. Correspondencia `scarlet-violet` comprobada directamente en `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm69` | `ice_punch` |
| `tm70` | `sleep_talk` |
| `tm71` | `seed_bomb` |
| `tm72` | `electro_ball` |
| `tm73` | `drain_punch` |
| `tm74` | `reflect` |

## Cambios reales publicados
1. Fixture `tests/fixtures/parallel_items/w05_campaign_003.json`: se añadió únicamente bloque `09`, sin alterar los bloques `01–08`. Commit **`cdcd2ed0ce02913c0508e5da297a4d54b37dddf2`**.
2. Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv`: una nueva fila `09`, `EN_CI_AUTOMATICA`. Commit **`d17bffb0134d80b03f762c8c5f650e4e07f5e34f`**, que activa el workflow.
3. Runners de W05 `tests/tools/test_parallel_items_w05_campaign_003.py` y `tests/gameplay/parallel_items_w05_campaign_003.gd` **sin cambios**: siguen acumulativos; para este SHA deben recorrer **9 bloques y 54 MT**. Exigen learnsets reales SV, metadatos y PP, uso de servicio real, negativas por stock/propiedad/compatibilidad/duplicados, consumo y SaveV2. No se inventan especies ni se reimplementa `FieldItemService.teach`.
4. Verificación estática efectuada contra GitHub: nueve bloques, **54 IDs diferentes**, correspondencia exacta entre fixture, filas/orden del progreso, la cola autorizada IA6 y el perfil SV. No hubo discrepancias. No sustituye pruebas funcionales.

## Evidencias de CI
- **Bloques 01–08 VERIFICADOS:** [#41560433553](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560433553), SHA `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`, `completed/success`; leídos en logs `CAMP003_W05_PY PASS blocks=8 checks=464` y `CAMP003_W05_GODOT PASS blocks=8 checks=1736` (Godot 4.7). 48 MT cubiertas por CI real.
- **Bloque 09 PENDIENTE:** [#41563035302](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563035302), SHA `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`, inicialmente `pending`. Run intermedio de fixture [#41563021095](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563021095), inicialmente `in_progress`, puede cancelarse por `concurrency.cancel-in-progress`. Es decisivo el run del SHA de progreso.
- Requisito para PASS del bloque nuevo: `completed/success` y recibos `CAMP003_W05_PY PASS blocks=9 checks=M` / `CAMP003_W05_GODOT PASS blocks=9 checks=M`, con `M>0`, en los logs correspondientes.

## Siguiente acción / STOP
- Próxima `p`: revisar CI del último SHA de pruebas/progreso. Con `success`, ejecutar **solamente bloque 10** `tm75;tm76;tm78;tm79;tm80;tm81` (último autorizado), sin bloque 11. Si `queued/in_progress`, únicamente un bloque independiente de tests y estado pendiente. Con `failure`, reparar solo arnés propio sin reducir aserciones o STOP y elevar IA6 cuando afecta producción/servicio, SaveV2, datos canónicos o dependencias.
- Tras bloque `10/10`, `CAMPAÑA_003_FINALIZADA` como entrega y STOP; su CI aún debe distinguirse de la conclusión documental. El cierre consolidado corresponde a IA6.
- Prohibido modificar `main`, V28, PR118, ramas ajenas, árbitra, `modules/`, `data/`, `config/`, catálogo canónico, workflow CI, guardados reales, 19 legacy, arte/GPU/UI.

**ITER_09/10 entregada. Estado funcional nuevo: pendiente de CI.**
