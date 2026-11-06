# IA3/W03 — CAMP006 bloque 04 — ENCOUNTER_RATE BLOQUEADO_IA6

**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`.
**Reserva literal:** `black_flute;white_flute;lure;super_lure;max_lure`. Son **cinco objetos ya inventariados**; cero nuevos.

## Dictamen
No se amplía `tests/fixtures/parallel_items/w03_campaign_006.json`, no se agrega una fila falsa al progreso, no se duplica la suite negativa ni se modifica producción. Progreso real de CAMPAÑA_006 se conserva en **3/10**. **ENCOUNTER** se pausa y se solicita autorización/decisión IA6. Es la misma frontera de productor compartido que impidió el L3 del bloque03; el mero helper de tasa aislado no conectaría un encuentro de demo.

## Evidencia comprobada (archivos actuales)
- `docs/current/ITEM_FIELD_V8.csv.txt`: `black_flute`, `white_flute`, `lure`, `super_lure`, `max_lure` tienen `FIELD_USE_NOT_CONNECTED`. Los dos primeros muestran `VERIFIED` para transferencia/equipamiento, **no certificación de uso de campo**.
- `scenes/overworld/technical_overworld.gd::_on_player_step_completed`: el generador llama a `_director.on_step(zone_id)`, que inicia sesión de encuentro, consume RNG y abre batalla. `modules/overworld/overworld_encounter_director.gd::on_step` no tiene hook pre-resolución para tasas, estados de objetos ni duración.
- `scenes/visual/field_demo.gd::field_prepare_native_encounter`: obtiene tabla, aplica únicamente la copia de `modules/gameplay/encounter_item_modifiers.gd` para `cleanse_tag`/`pure_incense`, clona el RNG, resuelve con `WildEncounterSystem.resolve` y registra estado futuro. **No consulta un estado de flauta/colonia ni un contador de duración.**
- `modules/overworld/overworld_player.gd` emite señales auténticas `step_completed`, suficientes para descontar pasos, pero no son por sí solas una interfaz de activación desde mochila, modificación de tabla ni SaveV2.
- Bloque03: `modules/overworld/field_repel_step_effect.gd` **L2 aislado** (100/200/250 pasos, filtro de niveles), CI [#41965873289](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41965873289) SUCCESS; **L3 pendiente** del mismo productor `field_demo`/director/SaveV2.

## Falta decisión canónica; no se inventan números
`black_flute` / `white_flute` provienen de generaciones con políticas de encuentros diferentes y duración/alcance dependientes de versión. `lure` / `super_lure` / `max_lure` aparecen asociados a mecánicas de Let's Go, cuyo disparador de encuentros y efecto no equivalen necesariamente a un cambio escalar de tasa en el resolver de batallas aleatorias de esta demo. **Ninguna tabla de reglas aprobada para la mezcla en Pokémon Calvo ha quedado fijada en el gate**. No introducir arbitrariamente factor de probabilidad, duración ni modificador acumulativo.

## Una interfaz y una decisión solicitadas a IA6
**Propietario:** IA6 para `OverworldEncounterDirector`, `technical_overworld.gd`, `field_demo.gd`, `FieldItemBag/Service`, estado de sesión y SaveV2; W03 podrá desarrollar un adaptador local puro solo una vez aprobado el contrato.

1. **Política**: matriz `item_id → source_version, effect_kind, chance_modifier, duration_kind, duration_steps, priority/stacking` para los cinco IDs. Especificar si las colonias se adaptan explícitamente al motor de encuentros por pasos o se excluyen de la integración.
2. **Productor pre-encuentro**: interfaz pura y estable, por ejemplo `prepare_encounter_table(zone_id, authored_table, effective_field_effect, leader, rng_snapshot) -> {table,reason}`. Aplicar una tabla derivada validada **antes** de consumir RNG o crear batalla; respetar `cleanse_tag`/`pure_incense` existentes y no introducir doble multiplicación.
3. **Contador**: suscribirse a `OverworldPlayer.step_completed` sin contar teletransportes, golpes contra paredes, load, pausas o movimientos de UI; arbitrar precedencia con Repel del bloque03.
4. **Activación**: comando de uso desde mochila, consumo unitario únicamente tras commit, rechazo sin gasto por zona sin aplicación, estado ocupado o política inválida. La autorización puntual sobre `FieldItemBag` del bloque02 SOLO cubrió `escape_rope` y no se extiende.
5. **Persistencia**: estado validable `item_id/remaining_steps/rule_version` en SaveV2, guardado/carga sin reactivar accidentalmente ni duplicar efectos.
6. **Pruebas de aceptación L3**: usar uno de los cinco ítems desde la mochila real, caminar pasos reales, confirmar tasa/candidatos mediante `WildEncounterSystem.resolve` y RNG semilla fija, expiración, prioridad, conservar identidad/cantidad al rechazar y guardar/cargar manual, sin alterar las regresiones CAMP005 y los positivos CAMP006 01–03.

## Regla de eficiencia
Dado que el bloque03 ya demuestra un helper L2 que espera exactamente ese productor de encuentros y el bloque04 no puede alcanzar L3 sin él, **no crear otro helper L2 aislado ni repetir diez pruebas negativas**. Se detiene la familia ENCOUNTER por dependencia común, como exige `CAMPAIGN_006_W03_GATE.md`.

**Acción exacta IA6**: autorizar punto concreto de hook pre-encuentro y uso de mochila, o implementar ese productor en rama árbitra; aprobar política versionada de los cinco objetos. Después autorizar reanudar el bloque04, o reasignar explícitamente la fila05 de CAPTURE_ENV si decide posponer ENCOUNTER. No avanzar secuencialmente ni marcar bloque04 como ejecutado hasta nueva instrucción.

**Prohibiciones respetadas:** no editar `main`, V28, PR118, ramas ajenas, mundo, sesión, inventario general ni SaveV2.
