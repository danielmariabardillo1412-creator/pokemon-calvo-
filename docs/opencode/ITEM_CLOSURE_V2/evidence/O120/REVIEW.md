# O120 — Bola de Humo y modificadores de encuentro

**Estado: PASS dentro de `PARTIAL_READY_FOR_REVIEW`.** No hay aceptación.
Evidencia serializada: `results.json` (SHA-256
`b804a2ae7716df7f3b7ac8d385ee079dffe837346bd833521b49d7a2af970fb6`).

## Implementación real

- `modules/gameplay/held_escape_items.gd`: `flee()` comprueba Bola de Humo en el
  límite de Run mediante el estado nativo `held_item_active` (incluye supresión
  por `ignoringItem`), antes del atrapamiento. Con el objeto activo la huida es
  segura, no dibuja RNG de escape y no consume el objeto. Un encuentro de
  entrenador o un Run bloqueado sigue rechazándose.
- `modules/gameplay/encounter_item_modifiers.gd`: copia validada de la tabla de
  encuentro con `roundi(bp * 2 / 3)`, mínimo 1 bp para probabilidad positiva, 0
  se mantiene 0 y 10000 → 6667. `field_demo.field_prepare_native_encounter` y
  `wild_adventure_session.gd` delegan en el helper.
- `field_world_items_v2.json` registra únicamente `smokeball` (gen 2, Fling 30);
  Cleanse Tag y Pure Incense no se registran como descriptores neutros.
- Los IDs `amulet_coin`, `exp_share`, `linking_cord` y `luck_incense` quedan
  `DEPENDENCY_MISSING` con motivo concreto.

## Puerta ejecutada

`python tools/verification/run_opencode_world_held_v2.py` — PASS, 9 grupos,
**1.606 checks**, 288.45 s. Incluye importador y prueba, Node de mundo, Godot de
mundo (56), campo nativo (118), restauración (912), V20 (267), huida V21 (218) y
GPU (35). Guardas antes y después: PASS.

Capturas revisadas:

- `.godot/opencode_world_held_v2/smoke_ball_bag.png` (1280×720, 87.573 bytes):
  «Bola de Humo · 1» en la mochila de campo, Bulbasaur «sin objeto» y el botón
  Equipar; la captura se toma antes de equipar.
- `.godot/opencode_world_held_v2/smoke_ball_equipped.png` (1280×720, 135.801
  bytes): mapa tras el equipamiento correcto. El estado «equipado» lo afirma el
  check real `leader.held_item_id == smoke_ball`; la captura no dibuja un texto
  de objeto equipado en el HUD.

## Límites

Cleanse Tag y Pure Incense son `PARTIAL_VERIFIED_RATE_ONLY`: solo se certifica la
tasa de encuentro mediante la copia validada; la semántica por pasos no está
representada. La puerta de familia pasó, pero el guard por familia no pudo
aislarse por los cambios compartidos sin commit. El guard global `--full` pasó.
No se declara COMPLETE ni ACCEPTED_BY_CODEX.
