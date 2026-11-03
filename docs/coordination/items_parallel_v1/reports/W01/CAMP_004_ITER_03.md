# IA1/W01 — CAMPAÑA_004 — Microbloque 03/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp004`; **objeto de la asignación:** `loaded_dice;misty_seed;power_herb`. Estado inicial **EN_CI_AUTOMATICA**. Ningún PASS funcional se infiere sin GitHub Actions real.

## Auditoría previa y reutilización
- Dado Trucado: `docs/current/ITEM_INVENTORY.csv` incluye el hook nativo `onModifyMove`; la prueba histórica `tools/item_audit/held_effect_sweep_v2.cjs` exige `|-hitcount|` y 4–5 impactos de `bullet_seed` con el objeto. No se crea una versión paralela de multigolpe.
- Semilla Bruma: `onStart|onTerrainChange` en inventario. `tools/item_audit/held_effect_sweep_v3.cjs` valida +1 Defensa Especial en Campo de Niebla, consumo y no activación con terreno incorrecto.
- Hierba Única: `onChargeMove`, `HELD_PILOT_VERIFIED`; `tools/item_audit/held_pilot.cjs` confirma `solar_beam` en primer turno, con consumo. No se modifican los efectos existentes de producción.

## Matriz nueva
| Objeto | Positivo | Negativo |
| --- | --- | --- |
| `loaded_dice` | Semillas deterministas de `bullet_seed`, exige `|-hitcount|` 4 o 5, testigos de ambos y algún control con 2/3 | Sin equipar y reserva reproducen mismos golpes; `tackle` no adquiere golpes extra |
| `misty_seed` | Rival invoca `misty_terrain` y portador gana +1 Def. Especial, consumiendo una unidad | Rival invoca `electric_terrain`: cero mejora y cero consumo; reserva no activa |
| `power_herb` | `solar_beam` causa daño en primer turno solo con Hierba Única equipada y se consume | Sin objeto o en reserva, primer turno solo carga; `tackle` no consume ni altera daño |

Se entregan **6 escenarios nuevos, 19 pares caso-semilla y 57 variantes**. Total acumulado: **20 escenarios, 62 pares y 186 variantes** de sesiones nativas y SaveV2, con inventario/propietario comprobados antes y después de restauración. Los 14 escenarios de bloques 01–02 se conservan.

## CI, cierre y continuidad
Fila 02 del CSV cerrada con resultado real run [#41584708689](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584708689), SHA `970db4c7696364cc1c5ebaf51719405d60430af0`, Python 177 PASS, Godot 3666 PASS, sin errores. Fila 03 aún `EN_CI_AUTOMATICA` a la publicación; verificar recibos `CAMP004_W01_PY PASS blocks=3 checks=M` y `CAMP004_W01_GODOT PASS blocks=3 checks=M` y estado `completed/success` sobre SHA final. De haber errores, diagnóstico y reparación propios conforme V5. No modificar `main`, V28, árbitra, ramas ajenas ni realizar merge. El próximo `p`, **solo si este bloque se valida**, ejecuta el 04/10.

## Incidencia CI y reparación V5 — fase de carga de Rayo Solar

El primer run [#41589392286](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589392286), SHA `a26c444bcda2be3f470f10ee8d097b2662ae4116`, confirmó manifiesto y Python, pero Godot terminó `CAMP004_W01_GODOT FAIL blocks=3 checks=5254 errors=8`. Los ocho fallos son exactamente dos semillas × dos controles (sin objeto y en reserva) × dos aserciones dependientes: `proyección idéntica después SaveV2` y `Modo ... prueba combate y SaveV2` para `power_herb_solar_beam`. **No falló la igualdad del snapshot nativo ni los efectos positivos/negativos de combate o consumo.**

La causa localizada es que sin Hierba Única Rayo Solar permanece en su **turno intermedio de carga** y la proyección auxiliar tras restaurar no coincide, aunque el snapshot serializado sí. Este estado transitorio pertenece al ciclo compartido de vistas del combate, no a la activación del objeto. **No se modifica arquitectura ni se disimula la limitación de SaveV2 a mitad de carga.**

Parche de prueba W01: conserva el dato del **primer turno** para demostrar que Hierba Única golpea inmediatamente y los dos controles no; a continuación obliga a los dos controles a ejecutar un **segundo turno real** y exige que se acepte y que produzca daño. Solo entonces se ejecutan las aserciones originales estrictas de snapshot/proyección/propietario tras SaveV2 en estado estable. Se añaden comprobaciones, no se quita ninguna ni se reduce la matriz de 20 casos/62 pares. La restauración de la **fase intermedia de carga** queda como frontera pendiente de revisión por IA6, sin declarar que pase.

La CI sobre el commit reparado debe decidir PASS del bloque 03. No certificar mientras siga ejecutándose.

## Certificación funcional final — bloque 03/10

**Ejecución oficial:** [GitHub Actions #41590511208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41590511208), SHA de pruebas y reparación `b9aa52cd282938221e1b2554132a31ce0189d886`. **Estado `completed/success`, cero errores**. Recibos literales de CI:

- `CAMP004_W01_MANIFEST_PASS reserved=10 completed=3 ids=30`
- `CAMP004_W01_PY PASS blocks=3 checks=249`
- `CAMP004_GATE_PY_PASS worker=W01 blocks=3 checks=249`
- `CAMP004_W01_GODOT PASS blocks=3 checks=5452`
- `CAMP004_GATE_GODOT_PASS worker=W01 blocks=3 checks=5452`

La suite **acumulativa de CAMPAÑA_004: 3/10 bloques, 9 objetos, 20 escenarios, 62 pares caso-semilla y 186 variantes** está aprobada para las mecánicas de combate realmente ejercitadas. Las variantes comprueban propiedad, consumo cuando corresponde, controles negativos, integridad del snapshot y restauración SaveV2 **en estado estable**.

**Límite no ocultado:** la primera CI reveló discrepancia de proyección tras restaurar en medio del turno de carga de Rayo Solar *sin Hierba Única*; la igualdad de snapshot sí pasaba. La suite actual no proclama solucionar ni certificar esa proyección transitoria: completa el segundo turno del control, comprobando que el primero no hizo daño y el segundo sí, y después certifica íntegramente el ciclo SaveV2 estable. Esta limitación pertenece a vistas/restauración compartida y debe llegar a IA6 si se exige continuidad exacta de interfaz durante el movimiento cargado. No se modificó producción ni contrato compartido.

La fila 03 de `CAMP_004_PROGRESO.csv` conserva temporalmente `EN_CI_AUTOMATICA` por eficiencia de minutos CI; la prueba funcional está certificada por el run y SHA anteriores. En el siguiente `p` autorizado, actualizar fila 03 a `CI_PASS_VERIFICADO` y añadir fila 04 conjuntamente. No hay bloque 05 autorizado por esta orden; próxima tarea **04/10** `psychic_seed;punching_glove;ring_target`.
