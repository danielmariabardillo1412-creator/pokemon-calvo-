# IA4/W04 — AUTORUN TANDA 04 — CIERRE AUDITADO
Fecha: 2026-11-10. Rama exclusiva: `codex/calvo-items-20261104-w04-camp006`.

## Resultado
**10/10 hitos examinados, 4 variantes desbloqueadas de las cinco pendientes de TANDA03, 1 bloqueada.**
Total acumulado: **55/56 formas regionales con validación nativa positiva**; no son 55 evoluciones ni objetos. El piloto Slowpoke de Galar anterior tampoco se recontó.

## Hitos
| Fila | Trabajo | Estado |
|---|---|---|
| 01 | Cinco especies, ability_slots, política vigente y prueba roja previa | VERIFICADO |
| 02 | Helper puro normal canonical `regional_ability_selection_w04.gd` | CERTIFICADO |
| 03 | Conexión limitada en `CreatureFactory`, policy cache cargada solo al necesitarla, sin RNG extra | CERTIFICADO |
| 04 | ponyta_galar run_away → pastel_veil normal | CERTIFICADO L3 |
| 05 | rapidash_galar run_away → pastel_veil normal | CERTIFICADO L3 |
| 06 | voltorb_hisui soundproof → static normal | CERTIFICADO L3 |
| 07 | electrode_hisui soundproof → static normal | CERTIFICADO L3 |
| 08 | exeggutor_alola: primera frisk excluida, harvest OCULTA; no se concede automáticamente | BLOQUEADO |
| 09 | Matriz de 56 formas; base y legacy sin forma; override válido preservado; pruebas antiguas | CERTIFICADO |
| 10 | CI de la tanda + CAMP003–006, T02 y T03, informe y CSV | CERTIFICADO |

## Evidencia
- CI V4 [#42890151094](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42890151094): COMPLETED / **SUCCESS**, HEAD funcional `e70d4d43b1f931f05195b9706b7077b6721b367d`.
- Pruebas Godot nuevas `tests/gameplay/w04_autorun_v4_ability.gd`: encuentros reales en `WildEncounterSystem.resolve`, habilidad permitida, Factory, Party/Storage, SaveV2 repository, validación `FieldNativeSave._valid_creature`, naturaleza/movimientos mediante persistencia exacta, overrides, identidad de forma.
- CI ejecutó y aprobó también V3 (55 positivas, una bloqueada), Slowpoke de Galar V2, Python CAMP003–006/V1/V2 y Godot CAMP003–006/resolvers.
- Se actualizaron exclusivamente las expectativas históricas de estado activo (nueva TANDA04) y la matriz V3 para reconocer las cuatro promociones; no se modificó el fixture congelado de CAMP005.

## Límite estricto de autoridad
Solo se editó la selección de habilidad regional concreta en `modules/creatures/progression/creature_factory.gd`, un helper nuevo `regional_ability_selection_w04.gd`, tests/workflows propios y los gates de continuidad W04. Política y datos canónicos permanecen intactos, ninguna habilidad oculta se convierte en default. No se editó `main`, V28, PR118 ni rama ajena. Tampoco `CreatureInstance`, `FieldNativeSave`, SaveV2 ni estados W02/W03 durante esta tanda.

**Precisión de alcance:** la policy cache evita volver a parsear el archivo en cada selección regional de habilidad, pero el validador histórico de identidad de forma mantiene su propio mecanismo anterior. No se ha cambiado esa interfaz ni el motor de habilidades en batalla. El cambio se certifica en generación de encuentros y guardado, no en implementación de efectos de habilidad en combate.

## Pendiente para IA6
`exeggutor_alola` sigue sin habilidad normal permitida (solo `frisk` denegada y `harvest` oculta). Hace falta decisión explícita de política o un productor legítimo para la habilidad oculta, sin autorización a W04 para hacerlo. La integración selectiva con W02 (naturaleza efectiva) y W03 (capturas) continúa siendo responsabilidad de IA6.

**STOP:** no empezar TANDA05 sin nueva orden publicada en `IA6_AUTORUN.md`. El cierre documental podrá tener SHA distinto del HEAD funcional; asociar correctamente cada run.
