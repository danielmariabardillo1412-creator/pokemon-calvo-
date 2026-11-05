# IA1/W01 — CAMPAÑA_005, bloque 05/10

**Rama:** `codex/calvo-items-20261104-w01-camp005`. **Ámbito:** equipables de combate, sin cambios al motor común.

## Cierre bloque 04

CI [#41954611857](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41954611857), SHA funcional `814943eb7445acee0161763eff85eb87285ed3ec`, Godot 4.403 PASS y Python 268 PASS. El CSV registra `CI_PASS_VERIFICADO`.

## Bloque 05 — matriz

| Objeto | Hook nativo | Efecto positivo | Controles |
|---|---|---|---|
| `twisted_spoon` | `onBasePower` | Psíquico (`psychic`) aumenta daño | Placaje, Reflejo |
| `metal_coat` | `onBasePower` | Foco Resplandor (`flash_cannon`) aumenta daño | Placaje, Reflejo |
| `kings_rock` | `onModifyMove` | Placaje puede hacer retroceder a Snorlax | ataque Normal contra Gengar inmune, Reflejo |

Roca del Rey **no** potencia el daño. Se exige evento nativo `|flinch` sobre el rival con objeto activo y se comparan 64 semillas para observar activación y no activación. Sin objeto o con objeto en reserva nunca debe haber ese retroceso. No se inventa una tasa exacta.

Cada caso conserva tres contextos `active`, `none`, `reserve`, identidad del portador, no consumo, dos unidades físicas, combate nativo y restauración SaveV2.

Nuevos: **3 objetos, 9 escenarios, 74 pares caso-semilla, 222 variantes**. Acumulado: **15 objetos, 45 escenarios, 122 pares, 366 variantes**. Se conservan los 36 escenarios anteriores.

## CI y límites

PENDIENTE DE CI nueva para el SHA de pruebas de bloque 05. Se exigen `CAMP005_W01_PY PASS blocks=5`, `CAMP005_W01_GODOT PASS blocks=5`, run completo `SUCCESS` y **regresión integral CAMP004 obligatoria en este hito**. No se proclama integración main/V28 ni prueba GPU/UI. Incidencia SaveV2 Rayo Solar a media carga sigue para IA6.
