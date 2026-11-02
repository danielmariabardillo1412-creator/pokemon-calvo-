# W03 / IA3 — ESTADO FINAL CAMPAÑA_002 (03/03)

**CAMPAÑA_002_FINALIZADA** como entrega. **ITER_03 en CI automática (SIN PASS todavía al cerrar)**; no ejecutar un cuarto bloque ni CAMP_003. Rama exclusiva `codex/calvo-items-20261102-w03-camp002`. El último commit propio de tests es `754b1ece5039a01da79144e9db60ea774cca6b13`; comprobar siempre último SHA/runs.
- **Orden IA6:** `CI_AUTOPILOT_V3.md` y `CAMPAIGN_GATE_002.md` prevalentes; IA4 finalizada de CAMP_001, no participa aquí. Trabajo autorizado solo en pruebas, fixtures e informes W03.
- **ITER01:** 9 Python estáticos PASS [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741).
- **ITER02:** 11 Python + 37 Godot negativos PASS [#41493879869](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493879869), W03 autónoma [#41539840311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539840311) PASS. Son **negativos** de bolas aún no habilitadas.
- **ITER03:** [informe](./CAMP_002_ITER_03.md) y [resumen final](./CAMP_002_FINAL.md), fixture `d55fa7b87864ff4d4058dd737505b42bbd560b10`, Godot `f469b38be329b239306806a4c01c08acef2980d9`, Python `34371e7c0284813ccc863ffaed7badbb6d5fa305`. 14 tests Python nuevos (3 añadidos), runner Godot preserva 37 negativos y añade regresión de Net/V11/V15 en 4 especies. `CAMP_002_W03_NEGATIVE` sigue informando `new_balls_functional=false`. **CI nueva en cola [#41547276442](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547276442)** al redactar; evaluar resultado y SHA en GitHub.
- **Dictámenes:** `dusk_ball` requiere noche/cueva fiables; `repeat_ball` historial de capturas persistente y semántica de especies/formas; `dive_ball` entorno subacuático confirmado. Para cada una se solicita a IA6 un gate independiente de contexto/migración antes de programar. **No se ha implementado ninguna de las tres**.
- **Regresiones:** V11 y V15 no incluyen Net en listas de no implementadas, V15 mantiene Repeat como negativa; Net ×3,5 Agua/Bicho y ×1 otras, Surskit sin duplicación, misma `CaptureInventoryService`/RNG/propiedad que la base. No modificar V11 ni V15 por nuevas pruebas.
- **IA6 debe:** comprobar el último workflow W03 para el SHA de tests, aceptar la auditoría/contratos si PASS, investigar/reparar excepción si FAIL. Después resolver procedencia y persistencia antes de autorizar una futura implementación. Nada de arte/GPU certificado.
- **No tocar:** `main`, V28, PR #118, CAMP001, otras ramas W, producción, adaptadores, `CaptureBattleContext`, `SaveGameData`, sesiones, selección, RNG, workflows. El workflow en W03 fue instalado por IA6 y se preservó sin cambios.

---

## Histórico preservado de CAMPAÑA_002 hasta ITER02

> **INSTRUCCIÓN VIGENTE IA6 — CI AUTOMÁTICA V3 (2026-11-02):** el estado histórico `PREPARADO_PENDIENTE_CI` o `STOP HASTA IA6` que aparece más abajo **ya no exige detenerse solo por esperar pruebas**. Lee en rama `codex/calvo-items-20261101-arbitro` [CI_AUTOPILOT_V3.md](../../CI_AUTOPILOT_V3.md) y `CAMPAIGN_GATE_002.md`: se ha instalado el workflow `.github/workflows/parallel-camp002-worker-autoci.yml` **en esta misma rama**; la primera ejecución propia [#41539840311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539840311) terminó `completed/success`. **Siguiente `p` ejecuta exclusivamente ITER_03 de CAMP_002** tras comprobar que no exista un FAIL más reciente. Cambios de tests disparan CI sin intervención de IA6; commits solo de informes NO la disparan. Si la nueva CI está `queued/in_progress`, puedes preparar hasta un bloque posterior ya autorizado sin declarar PASS ni borrar tests previos; un FAIL real exige reparar tu prueba en tus rutas exclusivas o STOP ante defecto funcional. **En ITER_03, publicar y STOP sin iniciar ITER_04/CAMP_003.** No implementar Dusk/Repeat/Dive; solo contratos/negativos. No tocar `main`, V28, otras ramas ni producción.

# IA3/W03 — Cuaderno operativo CAMPAÑA_002 (captura)

## ESTADO VIGENTE — ITER_02/03 PUBLICADA; nuevas pruebas PENDIENTES DE CI

- **Rama de escritura única:** `codex/calvo-items-20261102-w03-camp002`, creada originalmente desde checkpoint `67959eb8f19abfd2ae391872747a14f603fcab01`. No fusionar ramas CAMP_001 ni escribir en W04 congelada.
- **Permiso IA6 actualizado:** puerta `CAMPAIGN_GATE_002.md` blob `2fceaa04646db8a9538f3d3693c85b6e67422fd6`; gate de CI ITER_01 `CAMPAIGN_002_ITER01_CI_GATE.md` blob `12e9c3021e80f9e03e0f9b0e900853b9a7e6a513`; encargo W03 blob `96ec7241e2fad9f3c9f411a555649979c77b3953`. IA6 **autorizó ITER_02** tras PASS de la ITER_01.
- **PASS real histórico del bloque 01:** [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) SHA `967002fcbf26a1159d3a14a020e8921b34cfab8f`, `completed/success`, W03 Python **9 tests PASS**; no prueba efectos jugables.
- **Referencia externa fija y verificada realmente:** Pokémon Essentials / Maruno17 commit `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`; `Data/Scripts/011_Battle/007_Other battle code/010_Battle_PokeBallEffects.rb` blob `3deb95a4d4a38e51bf6950a4702f73e06a806c6f`; settings `Data/Scripts/002_BattleSettings.rb` blob `550a358751fba061adf3978460382de3dc3ab556`, `NEW_POKE_BALL_CATCH_RATES` si gen ≥7.
- **Ocaso / dusk_ball:** noche/cueva `battle.time == 2`; ×3 para gen ≥7 o ×3,5 pre-7; resto ×1. Falta señal autoritativa de reloj/cueva en `CaptureBattleContext`. Región de cueva en escena no se inyecta a captura.
- **Acopio / repeat_ball:** `battle.pbPlayer.owned?(battler.species)`; ×3,5 para gen ≥7 o ×3 pre-7; resto ×1. Falta registro histórico de especies propias/capturadas persistente; partido/PC actual no equivale a Pokédex histórica.
- **Buceo / dive_ball:** `battle.environment == :Underwater`; ×3,5 si subacuático, de lo contrario ×1. Falta flag del ambiente real del encuentro; tipo Agua no implica buceo.
- **ITER_02 GDScript nuevo:** `tests/gameplay/parallel_items_w03_campaign_002.gd`, commit `89d7ec1193c964f03db3c7efe0de3e897ba949a7`, blob `ccb45a1c31be3385b7bf7520c31a536b457eaaa6`. Valida comportamiento actual `unknown_ball`, rechazo sin gasto/RNG/mutaciones, prioridades de entrenador/KO/combate finalizado, Net y Poké Ball preservadas. **No aplica multiplicadores ni usa contextos inventados.**
- **Fixture ampliado:** `tests/fixtures/parallel_items/w03_campaign_002.json`, commit `d70d3b8aa2bd48a4524d7012d976a0179cea1a0f`, blob `09d387e36acc7e4bbddd07f3a2f2f7fde4956a21`; referencia SHA/lineas/factores normativos y `NEGATIVE_CHARACTERIZATION_ONLY`.
- **Python ampliado:** `tests/tools/test_parallel_items_w03_campaign_002.py`, commit `fe0772cd27459b0cf19c2a659570acfcccd3786f`, blob `f91e4b8d30fbbe80b92a8bbaf919e607856c2d50`; 11 unittests, dos nuevos verifican tabla normativa y contratos del runner Godot.
- **Informe:** [ITER_02](./CAMP_002_ITER_02.md) y [CSV de progreso](./CAMP_002_PROGRESO.csv). **Verificación local de contenido en GitHub: `STATIC_REVIEW_PASS`** (manual). **Unittest Python 11: SIN_EJECUTAR; Godot del script nuevo: SIN_EJECUTAR; CI ITER_02: SIN_EJECUTAR; GPU: SIN_EJECUTAR.** No dar PASS al bloque 02 antes de nuevo run IA6.
- **Comandos IA6 desde raíz de checkout/import Godot:** `python tests/tools/test_parallel_items_w03_campaign_002.py`; `godot --headless --path . --script tests/gameplay/parallel_items_w03_campaign_002.gd`. Revisar `CAMP_002_W03_NEGATIVE`, código de salida y SHA exacto.
- **Siguiente orden `p`: solo ITER_03 (decisión y contratos por bola, defensa contra regresiones de Net/V11/V15), tras consultar gate actualizado y detenerse si CI anuncia FAIL/bloqueo. No crear multiplicadores ni cambiar arquitectura. El cierre será `CAMPAÑA_002_FINALIZADA` tras 03/03, no antes.
- **STOP/permisos:** única escritura en fixture/test GDScript/test Python y reports W03 específicamente enumerados por `CAMP_002_W03.md`. Fuera de alcance: `CaptureSystem`, `CaptureBattleContext`, adaptadores, sesión, RNG, saves, selección, `.github`, arte, main, V28, PR #118 y cualquier rama W ajena.

---

## Histórico conservado — ITER_01

**Rama exclusiva:** `codex/calvo-items-20261102-w03-camp002`. **Estado histórico al cerrar ITER_01:** `ITER_01/03_ENTREGADA / PREPARADO_PENDIENTE_CI`. **IDs:** `dusk_ball`, `repeat_ball`, `dive_ball`.
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
