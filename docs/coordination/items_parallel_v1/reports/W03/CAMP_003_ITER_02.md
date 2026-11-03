# IA3/W03 — CAMPAÑA_003 / ITER_02: Ultra Ball y Master Ball

**Identidad:** IA3/W03. **Rama única:** `codex/calvo-items-20261103-w03-camp003`.
**Reserva exclusiva:** fila 02 de `CAMPAIGN_003_QUEUE_APPROVED.csv`, `ultra_ball;master_ball`. **No modificar producción, catálogo, ramas antiguas o de otras W.**

## Estado previo y fallo corregido del bloque 01
- **CAMP003 ITER01** publicó `poke_ball;great_ball` en `6e5db746ba2041d36da3034f8ad32d1059efd9c7`.
- CI [#41553752377](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553752377) **FAIL antes de Godot**: Python buscaba literalmente `quit(1 if not errors.is_empty() else 0)`, que no aparecía porque el runner utiliza `if errors.is_empty(): quit(0) else: quit(1)`. Era un error de comparación textual del propio test, no evidencia de fallo en producción.
- Corregido únicamente el test con comprobación estricta de rama de éxito y fallo, commit `70fb7f7a2746abbdbd7fd70b3b95e65fef07d704`.
- Reejecución real [#41555095544](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555095544), SHA `70fb7f7a2746abbdbd7fd70b3b95e65fef07d704`: **SUCCESS**, recibos `CAMP003_W03_PY PASS blocks=1 checks=31` y `CAMP003_W03_GODOT PASS blocks=1 checks=56`. No se reprogramó ninguna de las bolas.

## Contrato 02: ya implementadas, caracterización complementaria
- **Ultra Ball:** tabla `CaptureRuleset.BALLS` ×2, `guaranteed=false`; 3 especies reales (Mew, Pikachu, Caterpie) × PS completos/1 PS. Verificación independiente de `calvo_capture_v1`, una tirada de RNG canónico y una bola gastada en captura y fracaso, resultado e identidad de equipo.
- **Master Ball:** tabla ×1 pero `guaranteed=true`. Garantiza captura sin consumir RNG (probabilidad interna de resolución 0.0 por bypass, **no** tasa real de éxito 0%). Consume una sola Master. Cubre las mismas 3 especies/PS, identidad, equipo lleno de 6 → requisito de PC → enrutador real `CaptureOwnershipRouter`, propiedad única.
- **Negativos de ambas:** intento contra entrenador, sin bola en mochila y objetivo KO: resultado `INVALID`, motivo exacto, ni inventario ni criatura ni equipo ni RNG modificados.
- **No duplicar:** el runner conserva intacto `_block_01()`, añade `_block_02()` y utiliza servicios compartidos existentes; el Python mantiene las aserciones de 01, añade verificaciones puntuales de 02. El fixture contiene únicamente los bloques 01 y 02, cero IDs externos.
- **Commit de fixture:** `479e90c43e8bea3225ea68a7a947454ef6627320`; **runner:** `248b62289d5c90f0e115ccc7e78ff55f9f98ce96`; **Python:** `cf266efa94bcfe7080d0efcb12d27ddf67207beb`; **CSV:** `c48c62f5fb662dba9480327faa432afe56860adf`. Son cuatro commits secuenciales, solo rutas exclusivas de W03.
- **CI propia del bloque 02:** [#41555590257](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555590257) iniciada sobre `c48c62f5fb662dba9480327faa432afe56860adf`. **RESULTADO POSTERIOR CONFIRMADO: CI #41555590257 SUCCESS en SHA c48c62f5fb662dba9480327faa432afe56860adf; Python blocks=2 checks=56 PASS; Godot blocks=2 checks=108 PASS.**. Algunos runs intermedios pueden cancelarse por `concurrency.cancel-in-progress`; solo juzgar el último SHA completo. Requiere `CAMP003_W03_PY PASS blocks=2 checks=M`, `CAMP003_W03_GODOT PASS blocks=2 checks=M`, M positivo.
- **Si CI FAIL:** diagnosticar el log del SHA real; reparar exclusivamente el test propio sin suprimir casos. Si el motor o el contrato compartido falla, STOP y pedir IA6. No declarar PASS por comprobación estática.
- **Siguiente `p`: bloque 03 `quick_ball;timer_ball`**, solamente tras revisar CI de esta rama. Nunca ejecutar 04 antes de otra `p`.
