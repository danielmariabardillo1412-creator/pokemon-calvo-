# IA6 — MANIFIESTO W03 / CAMPAÑA_004

**Estado:** nueva campaña autorizada por el usuario, solo W03. **Fecha:** 2026-11-03.
- Rama verificada: `codex/calvo-items-20261103-w03-camp004`.
- Creada desde HEAD completo de CAMP003 W03: `6d47ff595537bf1c6eb936b9c7cbec377db7f707`; CAMP003 tiene cierre CI [#41570102206](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570102206) SUCCESS con 10/10 bloques.
- Autoridad: [CAMPAIGN_004_W03_GATE.md](CAMPAIGN_004_W03_GATE.md), [cola de 36 IDs](CAMPAIGN_004_W03_QUEUE_APPROVED.csv), [encargo](campaigns/CAMP_004_W03.md).
- Archivo de cola copiado idéntico a la rama exclusiva W03. Progreso `reports/W03/CAMP_004_PROGRESO.csv` solo encabezado, fixture `tests/fixtures/parallel_items/w03_campaign_004.json` con `blocks=[]`.
- Nuevo validador `tests/tools/test_parallel_items_campaign_004_w03_manifest.py`, workflow `.github/workflows/parallel-camp004-w03-autoci.yml`, commit `ff328e2fb74137dee44d5a548d85b73525fd8f21`; éste verifica identidad y reservas en bootstrap, y exige runner Python/Godot W03 dedicado con bloque >=1, más regresión CAMP002/CAMP003. Se preparan los runners nuevos en el primer bloque, no se reutiliza un runner exclusivo de bolas como cobertura falsa de campo/Tera.
- GitHub Actions nuevo [#41571597653](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571597653), **completado SUCCESS** sobre SHA `ff328e2fb74137dee44d5a548d85b73525fd8f21` (job `125705501758`). Es **bootstrap 0/10**, no comprobación funcional CAMP004; pruebas Python/Godot nuevas se ejecutarán con primer bloque.
- No se ha tocado `main`, V28, PR #118, ramas W01/W02/W04/W05. No integrar sin auditoría.
