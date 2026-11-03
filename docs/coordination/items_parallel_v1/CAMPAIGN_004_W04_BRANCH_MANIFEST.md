# IA6 — MANIFIESTO REAL W04 / CAMPAÑA_004
**Fecha:** 2026-11-03. **Estado:** ACTIVADA por encargo explícito del usuario.

- **Identidad exclusiva:** IA4/W04.
- **Rama nueva:** `codex/calvo-items-20261103-w04-camp004`.
- **SHA fuente del HEAD W04 CAMP003:** `f359775396935cc6e8c382ce96377a29fdd33a35`. Se creó exactamente desde ese SHA; la rama CAMP003 original permanece sin cambios.
- **CI previa de cierre:** [#41574086468](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574086468) `completed/success`, SHA funcional `42e98b468d934765c04cd3f45fa4a3b3cd7767a5`, 10/10 bloques, Python 120, Godot 270; regresión CAMP001 559. **De 30, 14 evoluciones positivas y 16 dependencias de reglas o DATA_ONLY; no considerar 30 funcionales.**
- **Nueva reserva exacta:** [CAMPAIGN_004_W04_QUEUE_APPROVED.csv](CAMPAIGN_004_W04_QUEUE_APPROVED.csv), 10 filas, **36 IDs**: ocho evolutivos, uno de revisión contextual, quince forma/historia, cinco legacy y siete tesoros. Sin solapes con W04 CAMP001/CAMP003 y todas las colas CAMP003/CAMP004 activas W02/W03/W05. **No se aprueban nuevos sistemas de juego por estar seleccionados.**
- **Puerta y encargo:** [CAMPAIGN_004_W04_GATE.md](CAMPAIGN_004_W04_GATE.md), [campaigns/CAMP_004_W04.md](campaigns/CAMP_004_W04.md), [mensaje de activación](CAMPAIGN_004_W04_ACTIVATION_MESSAGE.md).
- **Autoridad copiada en su rama:** cola/gate/encargo originales, fichero de progreso `reports/W04/CAMP_004_PROGRESO.csv` con solo encabezado, fixture `tests/fixtures/parallel_items/w04_campaign_004.json` con `blocks=[]`, validador `tests/tools/test_parallel_items_w04_campaign_004_manifest.py`.
- **Workflow creado** `.github/workflows/parallel-camp004-w04-autoci.yml` commit `39d6ab12ed62668868a291be47ddd78948b4e87a`; incluye identidad/36 IDs, bootstrap explícito, nuevos runners Python y Godot para bloques reales, regresión CAMP003 en cada bloque y CAMP001 en bloque 5/10. [Actions bootstrap #41574785492](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574785492): comprobar su conclusión actual antes de declarar PASS. **0/10 no prueba comportamiento funcional**.
- El arnés Python `test_parallel_items_w04_campaign_004.py` y Godot `parallel_items_w04_campaign_004.gd` deberán crearse por IA4 con sus primeras pruebas; **no hay placeholder que finja PASS**.
- El antecedente histórico de denegación de edición de workflow W04 era una operación concreta; se ha creado un workflow nuevo para campaña autorizada. Cualquier nueva denegación real se respeta y escala, no se sortea.
- **No** tocar `main`, V28, PR #118 ni ramas W01/W02/W03/W05. No hacer merge a árbitra automáticamente; IA6 deberá integrar tras auditoría.
