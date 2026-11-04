# IA6 — CAMPAÑA_006 W04 | READY

**Fecha:** 2026-11-04. **Nueva rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`. **Origen:** `codex/calvo-items-20261103-w04-camp005`. **Autoridad:** [manifiesto global](NEXT_CAMPAIGNS_20261104_MANIFEST.json) y [cola propia](CAMPAIGN_006_W04_QUEUE_APPROVED.csv). **Diez bloques autorizados; 0 IDs nuevos**, salvo explícitas reparaciones del backlog que no suman catálogo. **CI anterior:** [#41752332374](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41752332374) SUCCESS.

## Propiedad / criterio de trabajo
Campaña de INTEGRACIÓN, cero objetos nuevos. Se permiten reparaciones en funciones propias de `modules/creatures/progression/evolution_system.gd` y adaptador específico local; los productores comunes, SaveV2, `CreatureInstance` y FieldItemService compartido requieren propiedad IA6. Política trade→level V27: level_values_selected=null; NO elegir niveles ni consumos. Primera pareja de manzanas/potes busca L3 positivo, no informes negativos repetidos. Condiciones sin fuente bloquean ESA acción, no se inventan.

**Criterio de aceptación por bloque:** ejecución de un efecto positivo real en motor (L2) y, donde haya conexión, en demo/SaveV2 (L3), con controles negativos de no-consumo, identidad y rollback. Donde falte una política o productor compartido, una sola dependencia concreta indicando origen, contrato, consumidor, prueba pendiente y propietario IA6; NO contar como funcional ni repetir N pruebas negativas equivalentes. El mero éxito de CI no convierte un L1 en L2. Una versión visual/GPU solo se puede declarar tras inspección PC.

## Ejecución
- `01` reserva: `sweet_apple;tart_apple;syrupy_apple`. Después cada `p` ejecuta exactamente una fila secuencial 02..10. Cerrar y detener en 10/10 `CAMPAÑA_006_FINALIZADA`.
- Una regresión de la campaña previa debe seguir pasando. CI bootstrap 0/10 comprueba estructura, no nuevas mecánicas.
- Progreso propio `reports/W04/CAMP_006_PROGRESO.csv`; fixture `tests/fixtures/parallel_items/w04_campaign_006.json`; Python `tests/tools/test_parallel_items_w04_campaign_006.py`; Godot `tests/gameplay/parallel_items_w04_campaign_006.gd`; un informe por microbloque. No copiar recibos anteriores como comprobaciones actuales.
- Ejecutar regresiones de la campaña inmediatamente anterior en hitos 01/05/10 y siempre que se modifique código de producción. Si el hito 01 es solo bootstrap 0, se ejecuta la primera regresión funcional tras bloquearse el 01.
- Reparación autónoma V5 solo en propiedad asignada por función, sin alterar `main`, V28, PR #118, rama árbitra ni otras trabajadoras. Sin merges automáticos ni cambios a políticas canónicas.

**Regla de eficiencia:** si dos bloques seguidos solo demuestran la misma dependencia sin una ruta nueva de integración, DETENER esa familia e informar IA6, sin fingir productividad. IA6 debe asignar el productor compartido antes de seguir la familia.
