# IA6 — MANIFIESTO W02 / CAMPAÑA_004

**Estado:** ACTIVADA, nueva rama comprobada; trabajo funcional pendiente de iniciar 0/10. **Fecha:** 2026-11-03.

- **Identidad exclusiva:** IA2/W02. **Nueva rama:** `codex/calvo-items-20261103-w02-camp004`.
- **Fuente real:** HEAD de CAMPAÑA_003 W02 `291146f2efe617dbb7528050068e09e80a64022c`, con cierre 10/10. CI final anterior [#41570972406](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570972406) `completed/success`, Python/Godot y manifiesto; Godot 7.306 checks.
- **Nuevas reservas:** [cola de 40 IDs](CAMPAIGN_004_W02_QUEUE_APPROVED.csv), [gate](CAMPAIGN_004_W02_GATE.md), [encargo](campaigns/CAMP_004_W02.md). Dos bloques de 4 bayas (8) y ocho bloques de 4 medicinas (32), ninguno en colas previas W02 CAMP003 y overlay W02 CAMP001, ni otras campañas 003/004 actuales.
- La nueva rama tiene copia de su cola, gate, encargo, fixture `tests/fixtures/parallel_items/w02_campaign_004.json` con `blocks=[]`, progreso W02 `reports/W02/CAMP_004_PROGRESO.csv` solo encabezado y validador `tests/tools/test_parallel_items_campaign_004_w02_manifest.py`.
- **Workflow:** `.github/workflows/parallel-camp004-w02-autoci.yml`, SHA inicial `0a546247ccd4c9efa0cb93dd6ea5ce9e41d743a3`, Actions [#41572529404](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572529404). **RESULTADO CONFIRMADO:** `completed/success`, job `125708517899`, contrato/identidad y bootstrap SUCCESS en SHA `0a546247ccd4c9efa0cb93dd6ea5ce9e41d743a3`. Con 0 bloques, los pasos funcionales Python/Godot fueron SKIPPED; no se certifican funciones todavía.
- Los runners funcionales W02 específicos `tests/tools/test_parallel_items_w02_campaign_004.py` y `tests/gameplay/parallel_items_w02_campaign_004.gd` los crea IA2 al iniciar bloque 01; no se proporciona placeholder que pueda producir falso PASS. Su CI exigirá recibos con M>0 y la regresión acumulada de los 40 objetos CAMP003.
- Prohibiciones: no tocar `main`, V28, PR #118, otras ramas, selección/datos, APIs comunes sin propiedad IA6. Cada `p` ejecuta una fila y al 10/10 STOP.
