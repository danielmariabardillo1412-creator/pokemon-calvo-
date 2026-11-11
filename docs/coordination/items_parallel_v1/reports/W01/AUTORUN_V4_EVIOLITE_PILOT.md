# W01/IA1 — TANDA04/07 · Mineral Evolutivo

- Se autorizan pruebas L2/L3 únicamente. Pidgeotto (evoluciona a Pidgeot) debe reducir daño físico (Tackle) y especial (Psychic), mientras Pidgeot final no obtiene el efecto.
- Existían escenarios `eviolite_pre_physical`, `eviolite_pre_special`, `eviolite_final_physical`, `eviolite_final_special` en W01 CAMP001; no recontar mecánica ya existente.
- NativeEngine con seeds 19/23 y 20 ejecuciones incluidas negativas por reserva y forma final; Godot real `FieldItemService.equip` + `FieldNativeSession` + settlement + SaveV2 diez sesiones.
- Estado: pruebas y CI piloto preparadas; **no se declara PASS hasta ejecutar**. Sin modificaciones de producción ni del catálogo evolutivo W04.
