# IA6 — CAMPAÑA_006 W02 | HOLD_UNTIL_RECOVERY_GODOT

**Fecha:** 2026-11-04. **Nueva rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`. **Origen:** `codex/calvo-items-20261103-w02-camp005`. **Autoridad:** [manifiesto global](NEXT_CAMPAIGNS_20261104_MANIFEST.json) y [cola propia](CAMPAIGN_006_W02_QUEUE_APPROVED.csv). **Diez bloques autorizados; 21 IDs nuevos**, salvo explícitas reparaciones del backlog que no suman catálogo. **CI anterior:** [#41742682811](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742682811) FAILED — NO se declara cierre funcional.

## Propiedad / criterio de trabajo
FILA 01 OBLIGATORIA: reproducir y reparar CI anterior #41742682811: exp_candy_xl_level99_gain y relaxed_mint_level100, sin relajar aserciones. Antes del bloque 02 se exige CI CAMP005 completa PASS con 10/10 en la nueva rama. Para mentas, no inventar naturaleza efectiva: contrato de estadística real/SaveV2 y fuente aprobada antes de implementación. Funciones propias de entrenamiento solamente; no tocar APIs comunes sin IA6.

**Criterio de aceptación por bloque:** ejecución de un efecto positivo real en motor (L2) y, donde haya conexión, en demo/SaveV2 (L3), con controles negativos de no-consumo, identidad y rollback. Donde falte una política o productor compartido, una sola dependencia concreta indicando origen, contrato, consumidor, prueba pendiente y propietario IA6; NO contar como funcional ni repetir N pruebas negativas equivalentes. El mero éxito de CI no convierte un L1 en L2. Una versión visual/GPU solo se puede declarar tras inspección PC.

## Ejecución
- `01` reserva: `exp_candy_xl;relaxed_mint`. Después cada `p` ejecuta exactamente una fila secuencial 02..10. Cerrar y detener en 10/10 `CAMPAÑA_006_FINALIZADA`.
- **Puerta obligatoria para 02–10:** la suite Godot+Python completa de CAMP005 debe regresar a PASS en el nuevo SHA; mientras falle, solo reparar bloque 01.
- Progreso propio `reports/W02/CAMP_006_PROGRESO.csv`; fixture `tests/fixtures/parallel_items/w02_campaign_006.json`; Python `tests/tools/test_parallel_items_w02_campaign_006.py`; Godot `tests/gameplay/parallel_items_w02_campaign_006.gd`; un informe por microbloque. No copiar recibos anteriores como comprobaciones actuales.
- Ejecutar regresiones de la campaña inmediatamente anterior en hitos 01/05/10 y siempre que se modifique código de producción. Si el hito 01 es solo bootstrap 0, se ejecuta la primera regresión funcional tras bloquearse el 01.
- Reparación autónoma V5 solo en propiedad asignada por función, sin alterar `main`, V28, PR #118, rama árbitra ni otras trabajadoras. Sin merges automáticos ni cambios a políticas canónicas.


