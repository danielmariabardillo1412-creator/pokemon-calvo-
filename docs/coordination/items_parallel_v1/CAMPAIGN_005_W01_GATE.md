# IA6 — CAMPAÑA_005 W01 | READY

**Fecha:** 2026-11-04. **Nueva rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`. **Origen:** `codex/calvo-items-20261103-w01-camp004`. **Autoridad:** [manifiesto global](NEXT_CAMPAIGNS_20261104_MANIFEST.json) y [cola propia](CAMPAIGN_005_W01_QUEUE_APPROVED.csv). **Diez bloques autorizados; 30 IDs nuevos**, salvo explícitas reparaciones del backlog que no suman catálogo. **CI anterior:** [#41733777992](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733777992) SUCCESS.

## Propiedad / criterio de trabajo
Trabajo solamente de equipables de combate. Reparaciones V5 exclusivamente en funciones de sus modificadores y estado equipado, sin modificar la arquitectura de batalla, captura, campo, evolución o MT de otras IA. Cada bloque debe probar efecto positivo real si existe; si ya hay implementación, añadir cobertura incremental sin reescribir.

**Criterio de aceptación por bloque:** ejecución de un efecto positivo real en motor (L2) y, donde haya conexión, en demo/SaveV2 (L3), con controles negativos de no-consumo, identidad y rollback. Donde falte una política o productor compartido, una sola dependencia concreta indicando origen, contrato, consumidor, prueba pendiente y propietario IA6; NO contar como funcional ni repetir N pruebas negativas equivalentes. El mero éxito de CI no convierte un L1 en L2. Una versión visual/GPU solo se puede declarar tras inspección PC.

## Ejecución
- `01` reserva: `black_glasses;dragon_fang;hard_stone`. Después cada `p` ejecuta exactamente una fila secuencial 02..10. Cerrar y detener en 10/10 `CAMPAÑA_005_FINALIZADA`.
- Una regresión de la campaña previa debe seguir pasando. CI bootstrap 0/10 comprueba estructura, no nuevas mecánicas.
- Progreso propio `reports/W01/CAMP_005_PROGRESO.csv`; fixture `tests/fixtures/parallel_items/w01_campaign_005.json`; Python `tests/tools/test_parallel_items_w01_campaign_005.py`; Godot `tests/gameplay/parallel_items_w01_campaign_005.gd`; un informe por microbloque. No copiar recibos anteriores como comprobaciones actuales.
- Ejecutar regresiones de la campaña inmediatamente anterior en hitos 01/05/10 y siempre que se modifique código de producción. Si el hito 01 es solo bootstrap 0, se ejecuta la primera regresión funcional tras bloquearse el 01.
- Reparación autónoma V5 solo en propiedad asignada por función, sin alterar `main`, V28, PR #118, rama árbitra ni otras trabajadoras. Sin merges automáticos ni cambios a políticas canónicas.


