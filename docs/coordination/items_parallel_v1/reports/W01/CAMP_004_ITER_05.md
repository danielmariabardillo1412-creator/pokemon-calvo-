# IA1/W01 — CAMPAÑA_004 — Bloque 05/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp004`. **Asignación oficial:** `room_service;scope_lens;shed_shell`. Publicación inicial en estado `EN_CI_AUTOMATICA`.

## Auditoría previa
Los tres IDs están seleccionados en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, con entrada nativa en `ITEM_INVENTORY.csv`. La suite histórica `held_effect_sweep_v3.cjs` contiene contratos para los tres (Servicio Raro con Espacio Raro, Periscopio con Foco Energía y crítico, Muda Concha contra Mal de Ojo). Se reutilizan Godot y el motor Showdown, sin añadir simulador y sin tocar módulos de producción.

## Contratos nuevos de juego
| Equipable | Efecto positivo | Contraprueba |
|---|---|---|
| `room_service` | El rival activa `trick_room`; el portador pierde un nivel de Velocidad y consume una unidad | Sin Espacio Raro no altera stats ni consume. Equipado en reserva o ausente no activa |
| `scope_lens` | `focus_energy` + `tackle`: críticas reales con el Periscopio, testigo de semillas donde sin objeto no hay crítico | Control sin objeto y reserva coinciden; `reflect` no provoca crítico ni gasto |
| `shed_shell` | `mean_look` del rival: se registra solicitud nativa sin bloqueo del portador, después `switch 2` aceptado y `active_id=reserve` | Sin objeto y en reserva aparecen atrapados y no se ejecuta el cambio; sin Mal de Ojo, no hay trampa |

Cada caso se prueba con equipamiento activo, ausente y en reserva, inventario físico, no consumo salvo Servicio Raro, snapshot nativo y restauración SaveV2. **Bloque 05: 6 escenarios / 23 pares caso-semilla / 69 variantes. Acumulado: 34 escenarios, 98 pares y 294 variantes, 15 objetos.** No se desactivan los cuatro bloques previos.

## Gate obligatorio del hito 05
El workflow de IA6 contiene `if: steps.scope.outputs.blocks == '5'`: ejecutar adicionalmente **toda la regresión CAMP003 W01** (Python y Godot 4.7). Se exige el recibo de CAMPAÑA_004 y dos recibos `CAMP003_W01_PY PASS blocks=10 checks=N` y `CAMP003_W01_GODOT PASS blocks=10 checks=N`, con conclusión `completed/success`. Este trabajo no se declara terminado sin ese gate.

Bloque 04 previamente aprobado run [#41592180823](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41592180823) sobre SHA `ec13e1c6b30a58c8ac8c7c6bab3052d2ddec8699`: 6593 Godot y 388 Python, sin errores. CSV fila 04 queda actualizado. En fila 05 solo se registra `EN_CI_AUTOMATICA` hasta CI real. **Nada en `main`, V28, otras ramas ni producción.**

## Primera CI y reparación V5

El run [#41602085941](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41602085941) tuvo error `CAMP004_W01_PY FAIL: 'follow_move'` en el validador. Causa: una condición basada en la familia `scope_lens` exigía injustificadamente `follow_move` en el control de Reflejo, que intencionalmente sólo tiene un movimiento. La prueba de escenario de crítico sí requiere exactamente `focus_energy` seguido de `tackle`. El parche limita esa condición a los tres escenarios de críticos con secuencia de dos turnos (`punch_chansey_critical`, `punch_wrong_species` y `scope_focus_crit`), preservando el negativo de Periscopio, los otros 33 escenarios y los 98 pares. El fallo fue anterior a Godot, por lo que no demuestra ni descarta defectos de combate. Publicar y revisar CI completa, incluida regresión CAMP003.
