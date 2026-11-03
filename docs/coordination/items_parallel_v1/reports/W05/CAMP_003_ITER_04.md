# IA5/W05 — CAMPAÑA_003 · ITER_04/10 — seis MT Scarlet/Violet

**Entrega: EN_CI_AUTOMATICA.** No se atribuye PASS funcional al bloque 04 hasta finalizar la CI de su SHA exacto.

## Asignación autorizada
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp003`.
- Cola vigente IA6: `CAMPAIGN_003_QUEUE_APPROVED.csv`, fila `04,W05,MACHINE`; encargo `campaigns/CAMP_003_W05.md`.
- IDs exactos y movimientos del perfil canónico `modules/inventory/item_connections_v1.json` para `scarlet-violet`:

| MT | Movimiento |
| --- | --- |
| `tm38` | `flame_charge` |
| `tm39` | `low_sweep` |
| `tm40` | `air_cutter` |
| `tm41` | `stored_power` |
| `tm42` | `night_shade` |
| `tm43` | `fling` |

## Archivos publicados
1. `tests/fixtures/parallel_items/w05_campaign_003.json`: se ha añadido **únicamente el bloque 04**, preservando literalmente los bloques 01–03. Commit de fixture `e74d3d4cbdb38bd71624cbb31516b335c121b1ed`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv`: una sola nueva fila `04`, estado `EN_CI_AUTOMATICA`. Commit `d9c38c6cb606bbe3081eebc16d4560944370a48a`. Este push activa la CI automática.
3. Se reutilizan íntegros y **sin reprogramación de producción** los runners propios acumulativos `tests/gameplay/parallel_items_w05_campaign_003.gd` y `tests/tools/test_parallel_items_w05_campaign_003.py`. El contrato requiere `blocks=4`, seis casos nuevos y **24 casos acumulativos**, learnsets reales SV, PP, propiedad, consumo, rechazo en condiciones negativas y persistencia SaveV2.
4. Control estático de la entrega efectuado contra GitHub: cuatro bloques, **24 IDs diferentes**, fila/orden exactos del CSV IA6 y movimiento `scarlet-violet` de cada ID. **Sin discrepancias**. Esta lectura no sustituye las pruebas funcionales de CI.

## Evidencia CI
- **Bloques 01–03 sí certificados:** [GitHub Actions #41556713903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556713903), SHA `c3c48e92ddf48708d7d941554e58420a994e55ed`, estado `completed/success`. Logs reales `CAMP003_W05_PY PASS blocks=3 checks=174` y `CAMP003_W05_GODOT PASS blocks=3 checks=661`, error de job 0.
- **Bloque 04 todavía no certificado:** [run #41558194753](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558194753), SHA `d9c38c6cb606bbe3081eebc16d4560944370a48a`, estaba `pending` en consulta inicial. La ejecución intermedia del fixture [#41558142876](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558142876) puede cancelarse por `concurrency.cancel-in-progress`; el resultado del SHA del progreso será el decisivo.
- Requisito pendiente: `CAMP003_W05_PY PASS blocks=4 checks=M` y `CAMP003_W05_GODOT PASS blocks=4 checks=M`, con `M>0`, en el mismo run.

## Continuación
Ante nueva `p`, comprobar CI de `d9c38c6c...` en la rama W05. Si `completed/success`, ejecutar exclusivamente bloque 05 `tm45;tm46;tm47;tm48;tm49;tm50`. Si `queued/in_progress`, solo otro bloque independiente de tests, sin declarar PASS. Ante FAIL, corregir solo pruebas propias sin reducir aserciones; un error real de `FieldItemService`, SaveV2 o datos compartidos exige STOP y notificar IA6.

**Protección:** ninguna escritura en `main`, V28, PR118, ramas ajenas, árbitra, producción, catálogo, política, scripts de CI ni guardados reales; 19 máquinas antiguas siguen inactivas. GPU/visual/UI no acreditadas.
