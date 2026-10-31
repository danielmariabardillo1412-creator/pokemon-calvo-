# O110 — once usos de combate desde la mochila nativa

**Estado: PASS dentro de `PARTIAL_READY_FOR_REVIEW`.** No hay aceptación.
Evidencia serializada: `results.json` (SHA-256
`8bde07a97d2f6782ec50f682467e4a1f2162fb4be2fc3f50cb6ab1079744eb28`).

## Implementación real

`modules/battle/backends/showdown/native_bag_effects.cjs` aplica los efectos con
las APIs nativas del simulador y `applyMedicine` enruta los 11 IDs revisados sin
alterar la rama de las 15 medicinas. Perfil compartido:
`modules/inventory/battle_support_profile.json` (11 filas).

- Seis X (ataque, defensa, ataque especial, defensa especial, velocidad,
  precisión): +2 etapas, tope +6, rechazo sin efecto.
- Dire Hit: `focusenergy` nativo. Guard Spec: `mist` nativo en el lado propio,
  sin reaplicar si ya está activo.
- Flautas azul, amarilla y roja: curan sueño, confusión y atracción; son
  reutilizables y no gastan unidad.
- Los ocho potenciadores consumen exactamente una unidad solo cuando el efecto
  se aplica. Un rechazo no dibuja RNG, no muta el estado y no gasta.
- La amistad base `battleitem +1` bajo 200 se proyecta a través del checkpoint
  del roster; los bonos por origen/Luxury siguen pendientes.

## Puerta ejecutada

`python tools/verification/run_opencode_support_v2.py` — PASS, 14 grupos,
**13.274 checks**, 379.09 s. Incluye importador y prueba del importador, Node
nativo, Godot de apoyo (147), core (472), medicina (120), aventura (86), campo
nativo (118), restauración (912), recuperación V19 (2.386), progresión V18
(8.755), huida V21 (218), GPU de apoyo (37) y GPU de medicina (23). Guardas antes
y después: PASS.

Captura revisada: `.godot/opencode_battle_support_v2/battle_support_bag.png`
(1280×720, SHA-256 `ad5c7d60cf436d2d...`); muestra «Ataque X · 3», el aviso «Se
consume una unidad al tener efecto» y el objetivo Bulbasaur.

## Límites

La puerta de familia pasó, pero el guard por familia no pudo aislarse porque el
árbol contiene también O100/O120 en archivos compartidos (`native_engine.cjs`,
`showdown_adventure_session.gd`). El guard global `--full` pasó. La proyección de
amistad no cubre origen/Luxury ni paridad SV. No se declara COMPLETE ni
ACCEPTED_BY_CODEX.
