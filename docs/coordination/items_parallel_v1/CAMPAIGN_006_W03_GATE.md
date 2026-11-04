# IA6 — CAMPAÑA_006 W03 | READY

**Fecha:** 2026-11-04. **Nueva rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`. **Origen:** `codex/calvo-items-20261103-w03-camp005`. **Autoridad:** [manifiesto global](NEXT_CAMPAIGNS_20261104_MANIFEST.json) y [cola propia](CAMPAIGN_006_W03_QUEUE_APPROVED.csv). **Diez bloques autorizados; 0 IDs nuevos**, salvo explícitas reparaciones del backlog que no suman catálogo. **CI anterior:** [#41742709006](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742709006) SUCCESS.

## Propiedad / criterio de trabajo
Es campaña de INTEGRACIÓN, no otra auditoría negativa. IA6 concede propiedad por función exclusivamente a un adaptador nuevo propio del mundo/captura, y a lógica local de `modules/capture/`. Desplazamiento, estado de mundo, sesión, inventario general y SaveV2 pertenecen a IA6: no editarlos sin asignación puntual. El bloque 01 prueba un return_anchor sobre la demo; no requiere mundo completo. Cada bloque debe añadir efecto L2/L3 comprobable o generar un único ticket de productor común pendiente, NO repetir rechazo negativo como éxito de integración.

**Criterio de aceptación por bloque:** ejecución de un efecto positivo real en motor (L2) y, donde haya conexión, en demo/SaveV2 (L3), con controles negativos de no-consumo, identidad y rollback. Donde falte una política o productor compartido, una sola dependencia concreta indicando origen, contrato, consumidor, prueba pendiente y propietario IA6; NO contar como funcional ni repetir N pruebas negativas equivalentes. El mero éxito de CI no convierte un L1 en L2. Una versión visual/GPU solo se puede declarar tras inspección PC.

## Ejecución
- `01` reserva: `escape_rope`. Después cada `p` ejecuta exactamente una fila secuencial 02..10. Cerrar y detener en 10/10 `CAMPAÑA_006_FINALIZADA`.
- Una regresión de la campaña previa debe seguir pasando. CI bootstrap 0/10 comprueba estructura, no nuevas mecánicas.
- Progreso propio `reports/W03/CAMP_006_PROGRESO.csv`; fixture `tests/fixtures/parallel_items/w03_campaign_006.json`; Python `tests/tools/test_parallel_items_w03_campaign_006.py`; Godot `tests/gameplay/parallel_items_w03_campaign_006.gd`; un informe por microbloque. No copiar recibos anteriores como comprobaciones actuales.
- Ejecutar regresiones de la campaña inmediatamente anterior en hitos 01/05/10 y siempre que se modifique código de producción. Si el hito 01 es solo bootstrap 0, se ejecuta la primera regresión funcional tras bloquearse el 01.
- Reparación autónoma V5 solo en propiedad asignada por función, sin alterar `main`, V28, PR #118, rama árbitra ni otras trabajadoras. Sin merges automáticos ni cambios a políticas canónicas.

**Regla de eficiencia:** si dos bloques seguidos solo demuestran la misma dependencia sin una ruta nueva de integración, DETENER esa familia e informar IA6, sin fingir productividad. IA6 debe asignar el productor compartido antes de seguir la familia.
