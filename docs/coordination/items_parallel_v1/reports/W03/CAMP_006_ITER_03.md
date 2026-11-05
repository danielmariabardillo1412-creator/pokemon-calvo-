# IA3/W03 — CAMPAÑA_006, bloque 03: Repelentes — efecto L2 demostrado

**Rama:** `codex/calvo-items-20261104-w03-camp006`. **IDs del backlog anterior:** `repel;super_repel;max_repel`, sin objetos nuevos. Propiedad funcional concedida por `CAMPAIGN_006_W03_GATE.md`: adaptador propio de mundo/captura, NO `field_demo.gd`, `OverworldEncounterDirector`, sesión, bolsa general, `PlayerCollection`, `PlayerInventory` ni SaveV2.

## Evidencia positiva implementada
El nuevo `modules/overworld/field_repel_step_effect.gd` se conecta a `OverworldPlayer.step_completed` y descuenta duración únicamente por señales emitidas después de `apply_motion`/desplazamiento real sujeto a colisiones. El estado activa exactamente uno de los tres IDs. La duración se toma de los datos del catálogo PokeAPI integrado en el repositorio (items 79, 76, 77): Repel 100 pasos, Super Repel 200, Max Repel 250. No hay desplazamiento ni cuenta de paso cuando `movement_enabled=false`.

La decisión L2 `blocks_level(wild_level,leader_level)` rechaza **solo** niveles salvajes estrictamente inferiores al líder mientras quedan pasos activos; permite el mismo nivel o superior. Un Pokémon sin nivel válido no se veta artificialmente. Se prueba también caducidad exactamente al último paso; no hay RNG interno ni generación artificial de encuentros. `to_dict/restore` permite serializar y restaurar este estado **como contrato aislado**, no lo integra en SaveV2.

**Prueba real:** `tests/gameplay/parallel_items_w03_campaign_006.gd::_block_03` instancia `OverworldPlayer`, conecta la señal real y recorre 100+200+250 pasos por `player.apply_motion(Vector2.RIGHT,1/3)`; prueba emisión tras movimiento real, rechazo de duplicado, nivel inferior/igual/superior, bloqueo de movimiento, último paso, no-RNG, instantánea/restauración y rechazo de instantánea inválida sin mutación. Python verifica el código, el productor `OverworldPlayer` y la reserva exacta.

## Dependencia compartida para IA6 — NO DECLARAR L3

El productor de encuentros de la demo vive en `scenes/overworld/technical_overworld.gd::_on_player_step_completed` y `scenes/visual/field_demo.gd::_on_player_step_completed / field_prepare_native_encounter`. `OverworldEncounterDirector.on_step` inicia la batalla dentro de `session.begin_encounter`; después de ese punto es demasiado tarde para vetar por nivel sin deshacer estado/RNG. El módulo propio **no está conectado** ni a ese productor ni a `FieldItemBag`, y la duración no se incorpora al guardado SaveV2. No se consume aún un repelente desde mochila ni se bloquea realmente la batalla en la demo. **L2 positivo aislado, L3 PENDIENTE DE IA6.**

### Una interfaz compartida concreta solicitada

Asignar a IA6 la producción/consumo de un estado único `FieldRepelStepEffect` enlazado a `step_completed` solo si la sesión está explorando; el comando de mochila validará y consumirá un repelente, reservará un solo efecto activo y manejará rechazo sin consumo. El productor debe verificar el líder real de `CreatureParty` y decidir antes de `begin_encounter`, preservando la distribución de niveles, RNG y posibilidad de encuentro de nivel permitido; si se materializa un candidato para conocer su nivel, debe definirse explícitamente cuándo se consume el RNG, qué ocurre con el candidato suprimido y cómo no se inicia batalla. Persistir/recuperar `active_id + remaining_steps` dentro del propietario de SaveV2 y probar caminar, guardar/cargar, continuar y caducar exactamente; sin introducir pasos por teletransporte, UI, recarga o colisión. Este cambio cruza los propietarios de mundo/encuentros/sesión/SaveV2 **NO autorizados a W03**. Solicitud a IA6: publicar autorización mínima o el productor compartido para una futura integración L3, sin inventar API de guardado o alterar reglas de captura.

## CI y regresión de CAMPAÑA_005
[GitHub Actions #41965630903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41965630903), SHA `7be81acec35ee8fce4edd5f1a5e1bb917d408f54`, **completed/success**:
- `CAMP006_W03_PY PASS blocks=3 checks=43`
- `CAMP006_W03_GODOT PASS blocks=3 checks=77`
- `CAMP005_W03_PY PASS blocks=10 checks=169`
- `CAMP005_W03_GODOT PASS blocks=10 checks=208`

**Estado:** bloque 03 L2 terminado con evidencia positiva y ticket de productor L3 abierto; no afirmar que los repelentes son ya utilizables desde la mochila ni que filtran encuentros en la demo. `main`, V28, PR118, ramas ajenas, APIs compartidas y SaveV2 central permanecen intactos.
