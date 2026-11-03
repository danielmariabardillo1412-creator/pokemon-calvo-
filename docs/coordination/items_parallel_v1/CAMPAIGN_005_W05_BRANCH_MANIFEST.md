# IA6 — MANIFIESTO RAMA / CAMPAÑA_005 W05
**Fecha:** 2026-11-03. **Estado:** ACTIVADA Y BOOTSTRAP VERIFICADO.

- **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp005`, creada desde HEAD de CAMP004 `8c49755e663f11b38268d4de1547758c35692879`; conserva sus 60 MT previas y pruebas sin alterar la rama de origen.
- **Autoridad:** [gate](CAMPAIGN_005_W05_GATE.md), [cola](CAMPAIGN_005_W05_QUEUE_APPROVED.csv), [encargo](campaigns/CAMP_005_W05.md), [mensaje](CAMPAIGN_005_W05_ACTIVATION_MESSAGE.md) y sus copias originales en rama W05.
- **Reserva:** 10 microbloques, 60 MT `tm142` a `tm201`; seleccionadas y con mapping `scarlet-violet`, no incluidas en CAMP003/CAMP004 W05. **No contarlas funcionales todavía**.
- **Scaffolding:** `reports/W05/CAMP_005_PROGRESO.csv` solo cabecera, fixture `tests/fixtures/parallel_items/w05_campaign_005.json` `blocks=[]`, script `tests/tools/test_parallel_items_w05_campaign_005_manifest.py`, workflow `.github/workflows/parallel-camp005-w05-autoci.yml`. Runners Godot/Python funcionales se crean al ejecutar bloque 01.
- **CI bootstrap:** [GitHub Actions #41711755340](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711755340) `completed/success` sobre SHA `c1db16b52a43671c895f667de9d74595b0c988b4`. Solo identidad, reservas y progreso 0/10. No ejecuta casos funcionales nuevos.
- **Correcciones de bootstrap:** primer YAML defectuoso por expansión de reemplazo JS `$'`; reparado. El manifest inicial confundió TRAINING con MACHINE; reparado. El overlay CAMP001 contenía **metadatos MT** pero no enseñanza por ID; el guard excluye SOLO las muestras realmente enseñadas en CAMP001, no bloquea falsamente `tm142`–`tm201`. Los runs fallidos anteriores fueron configuración, no fallos Godot.
- **Regresión:** CAMP004 y CAMP003 se vuelven a comprobar en hitos 05/10 y parches de producción. Con 0 bloques, no afirmar que una MT se enseña. Proteger las 19 MT legacy inactivas, `main`, V28, PR118, ramas ajenas y reglas canónicas.

**Siguiente paso:** enviar activación a IA5, ejecutar bloque 01, después `p` hasta 10/10 y STOP.
