# IA3/W03 — CAMPAÑA_003 / ITER_04: Level Ball y Nest Ball

**Identidad y rama exclusiva:** IA3/W03, `codex/calvo-items-20261103-w03-camp003`.
**Autorización exacta:** fila `04,W03,CAPTURE_BALL,level_ball;nest_ball` de `CAMPAIGN_003_QUEUE_APPROVED.csv` (blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`). Cuarta fila registrada sin alterar las tres anteriores.

## Evidencia real previa
- Los bloques 01–03 tenían CI acumulativa PASS; último [#41556927911](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556927911) en SHA `5ec49e9290a3eba5230c7eb9b96e69a4b16ff4d9`: `CAMP003_W03_PY PASS blocks=3 checks=88` y `CAMP003_W03_GODOT PASS blocks=3 checks=317`.
- **Ya implementadas:** `modules/capture/capture_context_ball_effects.gd` blob `2eb24d7de69d60b0ac3a31ec28055dd8c5eea00b` registra Level; `modules/capture/capture_ball_effects.gd` blob `4e96b60ffe7b947817774d630b8e8afcca8d8591` registra Nest.
- **Level** usa nivel real del Pokémon activo `catcher_level`: ×1 cuando nivel activo ≤ objetivo; ×2 si supera al objetivo; ×4 si alcanza el doble; ×8 si alcanza el cuádruple. El multiplicador efectivo se limita mediante `min(factor, 255 / capture_rate)`; el registro real de especie es imprescindible. **Falta de nivel activo** (`-1`, `0`, `101`) → `capture_active_level_context_missing`, sin consumo/RNG.
- **Nest** utiliza exclusivamente el nivel del objetivo y `max((41−nivel)/10, 1)`: nivel 1 ×4, nivel 30 ×1,1, niveles 31/40/100 ×1. No necesita `catcher_level`.
- **Procedencia confiable del nivel:** `WildAdventureSession.capture_current()` obtiene `player_active().level`; `ShowdownAdventureSession.capture()` obtiene `battle_state().active_for_side("side_a").level`, ambos incorporados al `CaptureBattleContext`. Sin inventar variables ni editar sesión.

## Entrega del bloque 04, solo pruebas
- Fixture acumulativo `tests/fixtures/parallel_items/w03_campaign_003.json` blob `1dc12e0190c848c0f25079df81d208ac875bd56d`: incorpora 04 a 01–03, 2 especies reales (Mew: tasa baja; Caterpie: tasa alta), umbrales Level `9,10,11,19,20,39,40,100` frente a objetivo de nivel 10, niveles Nest `1,30,31,40,100`, PS completos/1, contextos inválidos `-1,0,101`.
- Godot `tests/gameplay/parallel_items_w03_campaign_003.gd` blob `3e7180db53076ebe0cb26e9d8bd9279ea05d58cd`: nuevos `_block_04`, `_check_block04_capture` y `_check_block04_reject`. Contrasta fórmula independiente con los dos adaptadores reales; en intentos válidos comprueba probabilidad, una bola, una tirada RNG, resultado y propiedad; en negativos, ausencia total de gasto/RNG/mutaciones.
- Python `tests/tools/test_parallel_items_w03_campaign_003.py` blob `6fce102ddf72cbc4da61e8e1a63894892a16be93`: comprueba nombres/reserva oficiales, archivos de efecto y contexto, productores Wild/Showdown, fronteras inclusivas/exclusivas, tope 255 y existencia de tests reales.
- CSV `CAMP_003_PROGRESO.csv`: cuarta fila `04,level_ball;nest_ball`, estado `EN_CI_AUTOMATICA`, commit de activación [34d963e5](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/commit/34d963e5c0cab2c840189b24a6c447353a4dd5db).
- CI iniciada automáticamente [#41558471582](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558471582) en SHA exacto `34d963e5c0cab2c840189b24a6c447353a4dd5db`. **CI COMPLETADA CON SUCCESS** sobre SHA `34d963e5c0cab2c840189b24a6c447353a4dd5db`. Logs del job `125663365696`: `CAMP003_W03_PY PASS blocks=4 checks=122`, `CAMP003_W03_GODOT PASS blocks=4 checks=490` y puertas `CAMP003_GATE_PY_PASS` / `CAMP003_GATE_GODOT_PASS`; Godot 4.7 sin errores. Esperar recibos estrictos `CAMP003_W03_PY PASS blocks=4 checks=M` y `CAMP003_W03_GODOT PASS blocks=4 checks=M`.
- Revisión estructural por GitHub satisfactoria, ahora complementada por ejecución Python y Godot 4.7 real con PASS. No hay certificación de GPU, visual ni perfiles de captura distintos de `calvo_capture_v1`.

**Próxima `p`:** bloque 05 de la cola, `fast_ball;dream_ball`, previa verificación del último run. Ante FAIL de test propio: reparar sin rebajar casos; problema de código compartido: STOP e intervención IA6. No tocar `main`, V28, `modules/`, catálogo, datos, workflows ni ramas ajenas.
