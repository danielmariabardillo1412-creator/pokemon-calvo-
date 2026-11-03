# IA2/W02 — CAMPAÑA_003 / BLOQUE 03/10

**Entrega:** `EN_CI_AUTOMATICA`, no declarar PASS hasta ejecución real del SHA con tres filas de progreso. Rama exclusiva `codex/calvo-items-20261103-w02-camp003`, sin cambios en producción/otras ramas.

## Alcance autorizado (cola IA6)
| Baya | Disparo nativo que debe comprobarse | Control sin activación | Fuente histórica |
|---|---|---|---|
| `colbur_berry` | Mew (Psíquico) recibe `dark_pulse` Siniestro supereficaz; daño activo menor y consumo | `tackle` Normal, sin reducción ni consumo | `held_effect_sweep_v2.cjs` |
| `custap_berry` | Snorlax con PS a un quinto, contra Gengar rápido: primer `\|move\|` es `p1a`, consume | PS máximos, Gengar actúa primero y Custap se retiene | `held_effect_sweep_v3.cjs` (`low_hp_order` / `full_hp`) |
| `enigma_berry` | Gyarados recibe `thunder_shock` Eléctrico supereficaz, cura `floor(maxHP/4)` y consume | `tackle` neutral, no cura ni consume | `held_effect_sweep_v3.cjs` (`super_effective_heal` / `neutral_no_trigger`) |
| `ganlon_berry` | PS a un quinto, `\|-boost\|p1a:\|def\|` nativo y consumo | PS cerca del máximo, sin subida ni consumo | `held_effect_sweep_v2.cjs` (`ganlon_berry:'def'`) |

**Fuente técnica, no implementación:** los cuatro efectos ya aparecen en sweep nativo; se reutiliza `item_automation_v28.gd`/motor fijado, `FieldItemService`, `SaveGameRepository`. Se ensayan **solo bayas equipadas**, no campo ni GPU.

**Ejecución del arnés acumulativo:** 9 escenas bloque 01 + 8 bloque 02 + 8 bloque 03 = **25 escenas**, tres dueños `active/none/reserve` por escena = **75 variantes de combate**. Además de mecánica propia, se exige que una unidad consumida no se publique dos veces, la reserva no influya al activo y SaveV2/FLED conserve estado e inventario. Las evidencias JSON son comprobadas con SHA256.

**Verificación anti-falsos PASS:** la prueba de orden Custap inspecciona el primer `|move|` real, excluye el movimiento del rival; los boosts Ganlon y Apicot filtran `|-boost|p1a:` para no atribuirse los del rival. Python exige expectativas por escenario y rechaza ocho mutaciones adversariales adicionales (tipo incorrecto, prioridad, cambio de umbral, daño neutral, confusión indebida, estadística errónea, omisión de caso o ID ajeno).

**Commits de pruebas:** fixture `cd837d26ca2283296a11dbd41af8672208694de0`; Godot `94d107df596ced40283845430e8cb36e9e7a686f`; Python `8e5b6b111c17259d0f73c08d8bb307a64155afa7`; CSV `44482761ab0217323335d9a1bc63f060cbcad513`.

**Regresión previa:** [Actions #41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832) `completed/success` sobre 2 bloques: `CAMP003_W02_PY PASS blocks=2 checks=122` y `CAMP003_W02_GODOT PASS blocks=2 checks=1406`. **No cubre los nuevos cuatro IDs del bloque 03.**

**CI actual:** workflow por rama `parallel-camp003-worker-autoci.yml` disparado por cambios en tests/progreso; debe acreditar recibos `CAMP003_W02_PY PASS blocks=3 checks=M` y `CAMP003_W02_GODOT PASS blocks=3 checks=M` en SHA nuevo. El simple PASS de bootstrap o de otros bloques no basta. Un FAIL exige reparar exclusivamente el test propio con rigor idéntico o STOP ante defecto de producción.

**Siguiente `p`:** únicamente bloque 04 `haban_berry;iapapa_berry;jaboca_berry;kasib_berry` si último run de este bloque pasa, o sigue pendiente y se permite prueba independiente sin ocultar fallos. No ampliar IDs ni tocar `main`, V28, catálogo, motor, workflow o demás ramas.
