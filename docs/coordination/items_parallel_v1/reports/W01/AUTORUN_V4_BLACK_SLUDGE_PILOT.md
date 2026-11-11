# W01 TANDA04/09 Lodo Negro — Piloto, no certificado

- Efecto nativo previo en CAMP001: `sludge_poison_heal` y `sludge_nonpoison_damage`. No se atribuye nueva implementación.
- 7 modos Node y Godot: 4 para Gengar Poison (portador/control/reserva/PS completos), 3 Mew no Poison (portador/control/reserva); 1/16 PS cura y 1/8 penaliza según las reglas nativas, más SaveV2, equipo y propiedad.
- L3 auténtico: `FieldItemService.equip`, `FieldNativeSession`, combate y liquidación real, `SaveV2` antes/después. Nunca editar FieldItemService ni motor.
- **Pendiente CI propia y posterior CI acumulativa**. No se contabiliza en certificados, ni como objeto nuevo.
