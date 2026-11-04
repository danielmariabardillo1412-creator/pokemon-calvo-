# IA6 — CAMPAÑA_006 W05 | READY

**Fecha:** 2026-11-04. **Nueva rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Origen:** `codex/calvo-items-20261103-w05-camp005`. **Autoridad:** [manifiesto global](NEXT_CAMPAIGNS_20261104_MANIFEST.json) y [cola propia](CAMPAIGN_006_W05_QUEUE_APPROVED.csv). **Diez bloques autorizados; 49 IDs nuevos**, salvo explícitas reparaciones del backlog que no suman catálogo. **CI anterior:** [#41742499805](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742499805) SUCCESS.

## Propiedad / criterio de trabajo
Solo 49 MT activas en `scarlet-violet`: 28 (`tm202..tm229`) y 21 de numeración anterior aún no cubiertas. Cada bloque enseña movimiento real compatible con PP/stock/consumo/SaveV2; mantener regressiones CAMP003/004/005. Las 19 máquinas antiguas sin entrada SV están fuera del alcance. No modificar catálogo, learnsets, otros subsistemas ni inventar movimientos. Tras cerrar 49, prioridad futura libro/UI, no generar IDs nuevos.

**Criterio de aceptación por bloque:** ejecución de un efecto positivo real en motor (L2) y, donde haya conexión, en demo/SaveV2 (L3), con controles negativos de no-consumo, identidad y rollback. Donde falte una política o productor compartido, una sola dependencia concreta indicando origen, contrato, consumidor, prueba pendiente y propietario IA6; NO contar como funcional ni repetir N pruebas negativas equivalentes. El mero éxito de CI no convierte un L1 en L2. Una versión visual/GPU solo se puede declarar tras inspección PC.

## Ejecución
- `01` reserva: `tm202;tm203;tm204;tm205;tm206`. Después cada `p` ejecuta exactamente una fila secuencial 02..10. Cerrar y detener en 10/10 `CAMPAÑA_006_FINALIZADA`.
- Una regresión de la campaña previa debe seguir pasando. CI bootstrap 0/10 comprueba estructura, no nuevas mecánicas.
- Progreso propio `reports/W05/CAMP_006_PROGRESO.csv`; fixture `tests/fixtures/parallel_items/w05_campaign_006.json`; Python `tests/tools/test_parallel_items_w05_campaign_006.py`; Godot `tests/gameplay/parallel_items_w05_campaign_006.gd`; un informe por microbloque. No copiar recibos anteriores como comprobaciones actuales.
- Ejecutar regresiones de la campaña inmediatamente anterior en hitos 01/05/10 y siempre que se modifique código de producción. Si el hito 01 es solo bootstrap 0, se ejecuta la primera regresión funcional tras bloquearse el 01.
- Reparación autónoma V5 solo en propiedad asignada por función, sin alterar `main`, V28, PR #118, rama árbitra ni otras trabajadoras. Sin merges automáticos ni cambios a políticas canónicas.


