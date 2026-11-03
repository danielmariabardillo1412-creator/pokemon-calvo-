# IA1/W01 — CAMPAÑA_003 · Microbloque 01

**Estado al publicar:** `EN_CI_AUTOMATICA`, no atribuir PASS a bloque nuevo hasta comprobar run. **Rama:** `codex/calvo-items-20261103-w01-camp003`; base de la campaña `41c1efeba0346349490f863131179ed7a8fc274c`. Encargo `campaigns/CAMP_003_W01.md` blob `b638d5525b0aec87dd730b5573a99cca53c0522e`, cola `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`.

## IDs autorizados y reutilización
- `air_balloon` (Globo Helio): ya marcado `HELD_PILOT_VERIFIED` en inventario, hooks `onStart|onDamagingHit|onAfterSubDamage`. Nueva cobertura: resistencia a Tierra vs control/reserva, explosión por daño Normal y retención sin golpe; snapshot SaveV2 de cada modo. No se implementa inmunidad manual.
- `assault_vest` (Chaleco Asalto): **ya verificado** en `tests/gameplay/parallel_items_w01_held_v1.gd` (bloqueo de estado y defensa especial); `YA_VERIFICADO_NO_DUPLICAR`. Se añade contraste de prohibición y aceptación de movimiento tras equipar con `FieldItemService` y restauración SaveV2, no reimplementación del efecto.
- `binding_band` (Banda Atadura): `held_effect_sweep_v3.cjs` ya prueba `partial_trap_residual` con `infestation` frente a control; el inventario no declara callback específico, pero el simulador nativo sí contiene referencia probada. Nuevo control: portador frente a no portador/reserva y `tackle` sin trampa, con SaveV2.
- Los tres ID están en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` como `SELECCIONADO`; selección no certifica combate.

## Pruebas y archivos publicados
- `tests/fixtures/parallel_items/w01_campaign_003.json`: 7 escenarios (3 Globo, 2 Chaleco, 2 Banda), 10 pares caso-semilla, 30 variantes `active|none|reserve`, cuatro referencias de código con SHA Git, eventos positivos y negativos.
- `tests/gameplay/parallel_items_w01_campaign_003.gd`: Godot headless reutiliza `_fixture` y `_restore_probe` V28; ejecuta `Native.begin_wild` y `submit` sobre `@pkmn/sim`; compara PS actor/rival, bloqueo de estado/consumo, y verifica snapshot y propietario SaveV2 de cada variante. Emite `CAMP003_W01_GODOT PASS blocks=N checks=M` exclusivamente si no hay errores.
- `tests/tools/test_parallel_items_w01_campaign_003.py`: valida la cola aprobada y progreso CSV, IDs reales/seleccionados, hashes de cuatro fuentes, restricciones de escenario/semillas, positivos y negativos históricos. `--ci` emite `CAMP003_W01_PY PASS blocks=N checks=M` solo tras superar contratos; no simula resultados de Godot.
- `reports/W01/CAMP_003_PROGRESO.csv`: una fila, bloque 01, tres IDs y `EN_CI_AUTOMATICA`.
- Commits de pruebas: `36baab52e8b7d22815bb20b540bd40a407864e98` (fixture), `3ab9773896a4ad8fd30b02883d57e6694dd8dc25` (Godot), `c374c1eda818de5578ebe59041b769d0c15dfce5` (Python); CSV `f9316279e97564f7b12ff71ad0692f572881afa2`.
- **Auditoría estructural local con blobs GitHub:** 16/16 condiciones PASS: tres IDs exactos, casos/semillas, controles, nativo, SaveV2 y recibos. **No equivale a CI funcional.**

## CI y límites
- Las CI intermedias anteriores a la fila de progreso con 0 bloques no acreditan esta prueba. Último run activado por CSV: [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) en SHA `f9316279e97564f7b12ff71ad0692f572881afa2` — `in_progress` al redactar este informe.
- Reproducir: `python -B tests/tools/test_parallel_items_w01_campaign_003.py --ci` y `godot --headless --path . --script res://tests/gameplay/parallel_items_w01_campaign_003.gd`, después de preparar Godot 4.7, Node 22, simulador y recursos mediante workflow existente.
- Si hay FAIL por test, revisar estrictamente aserciones y datos sin rebajar criterios. Si falta evento/mecánica o hay conflicto con producción compartida, **STOP y notificar IA6**; no cambiar motor.
- Fuera del alcance: pruebas GPU/UI, cierre de combate en mapa, Trick y todas las habilidades, climas y probabilidades de RNG.

**Siguiente `p`:** leer CI del último SHA de pruebas, encargo/cola y progreso. Si no hay FAIL, ejecutar **bloque 02 únicamente**, `blunder_policy;booster_energy;cell_battery`. No anticiparlo aquí.
