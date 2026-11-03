# IA3/W03 — CAMPAÑA_003 / ITER_01: poke_ball y great_ball

**Rama exclusiva** `codex/calvo-items-20261103-w03-camp003`. **Autorización:** CAMPAIGN_GATE_003 blob `390f7ce6897462e1ae8e3cc7e3cd5f799b6c2213`, manifiesto blob `9b797b4d32fbab022e12d580e46b10f063f5690f`, asignación W03 blob `aae298ea54e8b6f70cfa260aaa8b5d0639fecd24`, cola blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`. Base inicial `41c1efeba0346349490f863131179ed7a8fc274c`, bootstrap HEAD de esta rama `dea12b6ca6a4925e2ae75e26a463dc154087f056`. Orden 01/10 exacta `poke_ball;great_ball`.

## Evidencia anterior y decisión
- Ambas bolas **ya implementadas** en `modules/capture/capture_ruleset.gd` blob `aaa848d77ff31349dae9720be001ff31658f55a9`: Poké ×1, Gran ×1,5, no garantizadas. No son nuevas funcionalidades.
- `CaptureSystem` blob `59d0149f27dd8f6bcdf8334b89c07cc1f88917cf` utiliza `CaptureRuleset.catch_probability` y una tirada `rng.randf()` en intentos normales; `CaptureInventoryService` blob `5898e23f3d935bd48df4a5f9e13c5b2cab7c852d` valida posesión y descuenta una unidad. V11 `item_capture_v11.gd` blob `44ad0d5fe48bd81239ecea9b57bb6690817af6a1` ya tiene matriz de 10.760 escenarios para otras cinco bolas y reusa el núcleo. **No duplicar esa matriz ni reprogramar bola alguna.**
- Nueva cobertura de integración acotada: misma especie (Caterpie/Pikachu/Mew), mismos PS (completos/1), misma semilla para Poké y Gran, resultado frente a probabilidad independiente del perfil `calvo_capture_v1`, monotonicidad de Gran, una unidad/una tirada RNG, referencia/propiedad si éxito, inmutabilidad si fallo; rechazos por entrenador y sin bola antes de consumir o avanzar RNG.

## Entrega ejecutada
- `tests/fixtures/parallel_items/w03_campaign_003.json` blob `59d16be0559b956ead0d6f18d9c3729ad0815287`: reserva 01, tabla de bolas, 3 especies, 2 PS y 2 negativos, etiqueta `YA_VERIFICADO_NO_DUPLICAR`.
- `tests/tools/test_parallel_items_w03_campaign_003.py` blob `15ac200cdfdb13aa31e0494399ca9ee0647ff93d`: contrato sobre la cola oficial, equivalencia de fixture/progreso, datos originales y existencia del test acumulativo; imprime `CAMP003_W03_PY PASS blocks=1 checks=M` únicamente al validar realmente.
- `tests/gameplay/parallel_items_w03_campaign_003.gd` blob `a6f777a43d2a813df59e86788d3f30d52a593875`: usa `CaptureInventoryService.resolve` en Godot 4.7 sobre datos reales; imprime `CAMP003_W03_GODOT PASS blocks=1 checks=M` solo con cero errores. Si aparecen bloques 02–10 sin prueba añadida, **falla explícitamente**.
- CSV con **una** fila 01: `EN_CI_AUTOMATICA`; `sha_pruebas` es SHA del blob del script Godot (SHA del commit se conocerá tras publicar). El workflow exclusivo se activa al hacer push y requiere recibos exactos por bloque.

## Verificación y dependencias
- Inspección del código de núcleo y del test histórico por conector GitHub; aún **no se han ejecutado nuevos Python/Godot** al publicar. PASS del bootstrap anterior [#41551961372](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551961372) es de **0 bloques** y no sirve como evidencia del 01.
- No detectada dependencia nueva de contexto para estos dos IDs; la restricción genérica de la cola `CONTEXTO_NO_DISPONIBLE_DEPENDENCIA_DOCUMENTAR` no implica que Poké/Gran estén bloqueadas.
- **Siguiente `p`: ITER_02 exclusivamente `ultra_ball;master_ball`**, revisar la CI real de la nueva rama; mantener regresión de ITER01. STOP ante FAIL compartido y no tocar `main`, V28, producción, catálogo, otras W, IA4 o workflow.
