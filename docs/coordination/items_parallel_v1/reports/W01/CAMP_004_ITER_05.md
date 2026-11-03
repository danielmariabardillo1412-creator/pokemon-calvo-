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

## Cierre certificado — GitHub Actions del bloque 05

**Run oficial:** [#41602276948](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41602276948), `completed/success`, SHA funcional `7034b8c783eb9996369cbf1c97229c05713c9a08`, **0 errores finales**. Recibos exactos:

- `CAMP004_W01_MANIFEST_PASS reserved=10 completed=5 ids=30`
- `CAMP004_W01_PY PASS blocks=5 checks=468`
- `CAMP004_GATE_PY_PASS worker=W01 blocks=5 checks=468`
- `CAMP004_W01_GODOT PASS blocks=5 checks=8639`
- `CAMP004_GATE_GODOT_PASS worker=W01 blocks=5 checks=8639`
- `CAMP003_W01_PY PASS blocks=10 checks=806`
- `CAMP003_W01_GODOT PASS blocks=10 checks=12392`

Se ha superado el **gate obligatorio de la regresión completa de CAMPAÑA_003** en el hito 05, tanto Python como Godot, con 10/10 bloques. La campaña actual queda **5/10 bloques funcionalmente certificados**, quince objetos, 34 escenarios, 98 pares caso-semilla, 294 variantes (active, none, reserve) con pruebas de efectos, controles e integridad SaveV2.

**Incidencia reparada bajo V5:** el primer run [#41602085941](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41602085941), sobre SHA `27d8199d8d50176a00696aa7feff00e0b1dc7a29`, falló en el contrato Python con `CAMP004_W01_PY FAIL: 'follow_move'`, antes de ejecutar Godot. Se exigía por error `follow_move` al escenario de Reflejo sin daño de Periscopio. En SHA `7034b8c7` la exigencia se limita a los tres casos de críticos de dos movimientos. **No se retiraron casos, semillas, controles o aserciones**. El run posterior completó todas las baterías con éxito.

**Límites conocidos:** la CI headless no cubre interfaz ni GPU; no demuestra integración de ramas en `main`/V28. Persiste el aviso de proyección de vista en restauración **durante carga intermedia de Rayo Solar sin Hierba Única**, documentado en bloque 03 para IA6; ninguna prueba del bloque 05 lo declara resuelto.

**Administración:** la fila 05 del progreso CSV conserva `EN_CI_AUTOMATICA` por el disparador de CI para ahorrar ejecución documental redundante. La certificación definitiva se acredita con el run y SHA citados; cerrar esa fila a `CI_PASS_VERIFICADO` al añadir la fila 06 en el siguiente `p`. **Próxima asignación: bloque 06/10 `smoke_ball;smooth_rock;snowball`**, y solo con una nueva `p`.
