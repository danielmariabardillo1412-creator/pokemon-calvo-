# IA6 — MANIFIESTO ADITIVO W04 / CAMPAÑA_003
**Estado:** incorporación de quinta trabajadora autorizada el 2026-11-03, sin alterar la cola de 40 tareas de las otras cuatro.

**Identidad:** IA4/W04, misma conversación recuperada; CAMPAÑA_001 03/03 completada y CI histórica real [#41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097) `completed/success` con test de SaveV2 corregido en árbitra.

**Rama nueva comprobada:** `codex/calvo-items-20261103-w04-camp003` creada desde SHA `cdefb23d130f62ee9c8c63ffd1d15bf9779f13f4` de árbitra; primer commit bootstrap `7260500f25070d1393ca2d0e51c70192acd7d65d`. El primer run #41553918508 falló **antes de iniciar un job** por sintaxis del workflow (dos nombres de pasos con dos puntos sin comillas). Corregido en rama W04 commit `a47351fc3a570057eee016a143f8d62e0a382459` y también en árbitra; el run de comprobación es [#41554077520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41554077520). Consultar conclusión real, sin atribuir PASS anticipado.

**Reservas:** [CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv](CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv): exactamente 10 microbloques de 3 evoluciones (30 IDs). La cola original [CAMPAIGN_003_QUEUE_APPROVED.csv](CAMPAIGN_003_QUEUE_APPROVED.csv) sigue con 40 bloques/150 IDs para IA1/IA2/IA3/IA5; **la ampliación total son 50 microbloques y 180 IDs, con dos archivos de reserva independientes**. No modificar el validador de 40/150 para las trabajadoras existentes.

**Progreso inicial:** `reports/W04/CAMP_003_PROGRESO.csv` tiene solo encabezado, 00/10; la activación inicial en su chat recuperado ejecuta bloque 01 y luego cada `p` ejecuta 02..10. IA4 debe consultar [CAMPAIGN_003_W04_ADDENDUM_GATE.md](CAMPAIGN_003_W04_ADDENDUM_GATE.md) y [campaigns/CAMP_003_W04.md](campaigns/CAMP_003_W04.md); no abrir trabajo en su rama antigua. No tocar `main`, V28, producción ni otras trabajadoras.

**CI nueva:** archivo `.github/workflows/parallel-camp003-w04-autoci.yml`, validador `tests/tools/test_parallel_items_w04_campaign_003_manifest.py`; al 0/10 el workflow da solo bootstrap, nunca PASS funcional de evolución. Revisar comprobaciones reales en Godot 4.7 al entregar cada bloque.
