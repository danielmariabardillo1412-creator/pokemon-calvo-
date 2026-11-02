# IA3/W03 — Cuaderno operativo CAMPAÑA_002 (captura)

**Rama exclusiva:** `codex/calvo-items-20261102-w03-camp002`. **Estado:** `ITER_01/03_ENTREGADA / PREPARADO_PENDIENTE_CI`. **IDs:** `dusk_ball`, `repeat_ball`, `dive_ball`.
**BASE comprobada:** `67959eb8f19abfd2ae391872747a14f603fcab01`. **No reutilizar ni escribir en ramas 20261101.**
**Órdenes IA6:** `CAMPAIGN_GATE_002.md` blob `ebc787803599e2b13cbd24c169b69112d18f7a42` (ACTIVADA), `CAMPAIGN_002_BRANCH_MANIFEST.md` blob `bb9471862d3116b982f90e1867d512e278f801e0`, `campaigns/CAMP_002_W03.md` blob `96ec7241e2fad9f3c9f411a555649979c77b3953`. Revisar estas órdenes al inicio de cada `p`.

## Estado técnico comprobado (ITER_01)

- **Informe** [CAMP_002_ITER_01.md](./CAMP_002_ITER_01.md); **progreso** [CAMP_002_PROGRESO.csv](./CAMP_002_PROGRESO.csv).
- **Fixture** `tests/fixtures/parallel_items/w03_campaign_002.json` (blob `00b54a7be631aba0e6261dc3ca74d0e8cbcc290b`), commit `2aef47c241219bf91f4ec9b1e795fd7256912759`: tres triggers, fuentes responsables y falsos positivos explícitamente prohibidos; ningún factor numérico.
- **Test** `tests/tools/test_parallel_items_w03_campaign_002.py` (blob `e14ea14116ab1d8f07ad7983268d866a0c74dd82`), commit inicial `e7e814fd30d32f6b80fdb0c522b83103cb6be302`, corrección regex `de6beff3010199417a28054ae81dbe0c3586d8d8`: nueve pruebas `unittest` sobre matriz, catálogos, contexto real, productores de contexto, adaptadores y fronteras de snapshot. Ejecutar desde checkout: `python tests/tools/test_parallel_items_w03_campaign_002.py`.
- **Fuentes de verdad:** `CaptureBattleContext` solo guarda `is_wild/battle_finished/caller_trainer_id/target_owner_trainer_id/target_side_id/completed_turns/catcher_level`. `WildAdventureSession.capture_current` y `ShowdownAdventureSession.capture` construyen esos datos desde batalla real y llaman `CaptureInventoryService.resolve`; ninguno propaga noche/cueva, Pokédex histórica o inmersión.
- **Ocaso** `dusk_ball`: `field_demo.gd` tiene `region == &"cave"` y snapshot separado `world.region`; **no** forma parte del contrato confiable de captura. No deducir noche de reloj local/turno.
- **Acopio** `repeat_ball`: equipo y PC solo acreditan propiedad actual; no historial de especies capturadas y liberadas. `SaveGameData` V2 no guarda Pokédex histórica. Contrato/migración requieren decisión IA6.
- **Buceo** `dive_ball`: no existe flag autoritativo de encuentro subacuático en contexto o sesiones inspeccionadas. Tipo Agua, nombre de bola o cueva no demuestran inmersión.
- **Estado de IDs:** las tres aparecen `SELECCIONADO` en CSV, y `NATIVE_ENTRY_REQUIRES_EFFECT_CASE` en inventario; no figuran en `BallEffects.IDS` ni `ContextBallEffects.IDS`. Por ello `DEPENDENCIA_DE_CONTEXTO`, no funcional. `net_ball` permanece implementada y probada históricamente, pero no pertenece a estos tres IDs.
- **Verificación real:** comparaciones de blobs/estructura en conector GitHub `STRUCTURE_PASS`. Se corrigió un falso positivo de campos de clase en el validador; **nuevo test Python SIN_EJECUTAR**, Godot SIN_EJECUTAR, nueva CI SIN_EJECUTAR, GPU SIN_EJECUTAR. Sin Godot ni clonación local (DNS error). No escribir `FUNCIONAL_PASS` ni confundir CI anterior #41364601482/#41364601486 con estos tests.
- **Siguiente `p`: ejecutar solo ITER_02** para consultar fuente normativa fijada y crear negativos GDScript del estado real, sin parchear adaptadores ni fórmula. ITER_03 después del siguiente `p`, nunca antes. Tres microbloques máximo. IA6 coordina CI/integración y repara fallos.
- **STOP si:** fallo en test ejecutado, cambio de contrato, choque de ruta, requisito no autorizado, nueva política o falta de fuente verificada.
- **Rutas exclusivas de escritura:** `tests/gameplay/parallel_items_w03_campaign_002.gd`, `tests/tools/test_parallel_items_w03_campaign_002.py`, `tests/fixtures/parallel_items/w03_campaign_002.json`, `reports/W03/CAMP_002_ITER_0N.md`, `CAMP_002_PROGRESO.csv`, `CAMP_002_FINAL.md`, y este cuaderno.
- **NO TOCAR:** módulos de captura, contexto, adaptadores Net/Quick/Timer/Level, RNG, partidas/savedata, data, catálogo, `main`, V28, PR #118, ramas antiguas, W01/W02/W04/W05. IA4 congelada.

## Historia separada

La memoria detallada previa de W03 permanece en la [rama antigua CAMPAÑA_001](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w03/docs/coordination/items_parallel_v1/reports/W03/CONTINUIDAD.md). El cuaderno antiguo de LOTE_002 llegó por herencia del checkpoint a esta rama nueva, pero **se ha sustituido solo en esta rama** para evitar órdenes y estados obsoletos. No se fusionaron informes antiguos ni se alteraron ramas ajenas.

**Para SHA final:** consultar HEAD de esta rama; no puede escribirse el SHA de un commit dentro de su propio archivo.
