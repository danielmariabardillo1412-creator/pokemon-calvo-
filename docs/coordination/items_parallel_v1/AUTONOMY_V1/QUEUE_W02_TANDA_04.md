# IA6 W02 TANDA 04 — eliminar doble recálculo Growth tras menta y evolución
Rama: codex/calvo-items-20261109-w02-mints-integration.
Baseline: T03 CI #42890511612 SUCCESS, código 17df457b1320. Ticket AUTORUN_V3_IA6_GROWTH_DOUBLE_RECALC_TICKET.md revisado.
PROTOCOLO IA6: 10 hitos autorizados sin nueva puerta por hito; p/sigue consulta IA6_AUTORUN.md en su propia rama, usa checkpoint y ejecuta el siguiente paso. Terminar solo al cubrir 10 hitos o agotar todos los seguros; informe + SHA funcional + CI completed/success. Hitos != objetos nuevos != integración IA6. No hay ejecución entre turnos. No tocar main, V28, PR118, ramas ajenas ni ficheros no autorizados.

PERMISO EXCEPCIONAL: solo modules/inventory/field_growth_effects.gd::plan, en el tramo que restaura effective_nature_id y recalcula stats después de EvolutionSystem.apply_evolution. T03 ya corrigió EvolutionSystem; suprimir redundancia solo tras pruebas. EvolutionSystem, CreatureInstance, FieldItemService, Stats, SaveV2 central y W04 son SOLO LECTURA.
10 HITOS:
01. Diagnóstico exacto y prueba de recálculo redundante.
02. Prueba de equivalencia antes/después en estado original+efectivo.
03. Quitar solo recálculo duplicado; preservar selección de evolución y delta HP.
04. Bulbasaur→Ivysaur tras adamant_mint por nivel.
05. Eevee→Vaporeon por ítem tras menta, sin gasto incorrecto.
06. Múltiples niveles, movimientos, decisión rechazada y rollback.
07. PARTY/STORAGE, identidad, IV/EV, HP y PP.
08. SaveV2 normal/legacy/corrupto tras crecimiento+evolución.
09. Contrato de coexistencia con form_id de W04 solo mediante tests, sin copiar campo.
10. CI completa T01–03/CAMP003–006 y reporte reports/W02/AUTORUN_V4_FINAL.md.
Si la reducción no se puede medir sin modificar clases protegidas, conservar equivalencia funcional y documentar limitación. Cero objetos nuevos; reparación localizada.
