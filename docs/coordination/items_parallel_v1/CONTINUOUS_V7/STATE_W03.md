# IA3/W03 — CONTINUOUS V7 · FASE A: TRAZADO DE CÓDIGO (2026-11-12)
- worker: W03
- branch: codex/calvo-items-20261112-w03-black-white-flutes-v7
- source: IA6_AUTORUN.md vigente (relevo V6 -> V7), dos IDs existentes: black_flute y white_flute.
- previous V6: Dusk Ball cueva CI #43125138000 SUCCESS en staging; integración IA6 todavía no acreditada.
- progress: FASE A PARCIAL — inspección estática de ruta realizada, prueba runtime RED NO EJECUTADA; fases B/C NO INICIADAS.
- V7 L3: **0/2**; no código funcional V7, no CI V7.
- intended profile: calvo_flutes_classic_encounter_rate_v1 exclusivo y explícito (Negra ×0.5, Blanca ×1.5; no acumular; no consumir).

## Hallazgos verificados sobre el código V7 de GitHub
1. `scenes/visual/field_demo.gd::field_note_native_step(position)` detecta zona física con `zone_at_position` y registra el paso; la decisión nativa está en `field_prepare_native_encounter(zone_id)` (líneas 695-726 aprox.).
2. `field_prepare_native_encounter` obtiene `_director._tables[zone_id]`, lo pasa primero por `EncounterItemModifiers.prepare_table` (Cleanse Tag/Pure Incense), copia el estado RNG, y llama a `WildEncounterSystem.resolve(table, staged,...)`; luego filtra Repel por nivel cuando YA hay encuentro. Por tanto, la tasa de flautas debe modificar una copia de la tabla validada **antes** de `resolve`, sin segundo RNG ni mutar tabla original. Comprobar que el porcentaje exacto está expresado en la tabla antes de programar.
3. `field_item_bag.gd::_refresh_choices` y `_apply` (líneas 142-245) despachan Repel y Cuerda; NO aparece una ruta especial para flautas en esos handlers inspeccionados. La ruta general exige criatura, incompatible con efecto de campo sin objetivo. La prueba RED funcional todavía debe ejecutarse, no inferirla de esta ausencia.
4. `field_native_world_snapshot` guarda posición, `region`, configuración, RNG, semilla, formato y repelente, pero no flauta. `field_validate_native_loaded_world` valida el mundo antes de `field_publish_native_loaded_world`; hay que añadir serialización validada y preservar saves legacy. En los fragmentos inspeccionados no existe `map_id` persistente; `region` surface/cave no equivale a identidad estable de mapa. Duración hasta cambio real de mapa: pendiente de demostrar, no reclamar L3 completo sin productor.
5. `OverworldEncounterDirector.on_step` también posee una vía de encuentro propia; debe confirmarse en runtime cuál usa el puente nativo para no modificar una ruta inactiva.

## Siguiente p ejecutable
- Leer clases `WildEncounterTable`, `WildEncounterSystem`, `TechnicalEncounterPoolBuilder`, `field_native_bridge.gd` y el origen real de `map_id`/transición.
- Crear prueba Godot RED mediante mochila verdadera y pasos físicos (hierba y cueva, seeds fijas): no consumo, tasa base, Negra ×0.5, Blanca ×1.5, sustitución, Repel, SaveV2; correr contra SHA sin parche para acreditar RED runtime.
- Si no existe transición de mapa auténtica, registrar `L2_CONTEXT_ONLY / map-transition-pending` y ticket, sin éxito ficticio.
- Solo después implementar hunks mínimos, ejecutar CI de V7 y regresiones.

## Invariantes
No tocar main, V28, PR #118, integración IA6 ni ramas ajenas. Mantener W05 libros, W03 Repel/Rope/Dusk/captura, W02 mentas, SaveV2 y `dynamax_candy` excluido.
