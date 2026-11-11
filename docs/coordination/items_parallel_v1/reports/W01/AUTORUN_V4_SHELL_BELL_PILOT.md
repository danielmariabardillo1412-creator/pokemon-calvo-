# W01 — TANDA04/06 · Shell Bell pilot

Selección canónica `shell_bell`, hook nativo `onAfterMoveSecondarySelf`. Ya existían escenarios nativos `bell_attack_heal`, `bell_status_control` y `bell_immune_control` en CAMP001, por lo que **no contar reimplementación**.

L2: motor nativo y daño efectivo a PS del rival; curación real `max(1,floor(damage/8))`, control sin equipar, reserva, inmunidad Ghost y ataque de estado. Sin consumir ni duplicar.
L3: `FieldItemService.equip` desde mochila, SaveV2 antes, combate `FieldNativeSession`, liquidación y SaveV2 después con 4 modalidades.
**NO PASADO aún**: archivos de piloto publicados para CI independiente. Solo si CI pilot y CI acumulativa SUCCESS dar por certificado. No modificar producción o shared seams.
