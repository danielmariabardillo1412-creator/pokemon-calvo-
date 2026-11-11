# W01 V4 — matriz de brechas funcionales tras gate parcial aprobado
Fecha: 2026-11-11.

## Gate staging realmente comprobada
- Workflow `.github/workflows/w01-continuous-v4-phase-c-partial.yml`.
- Ejecución [#43069765360](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43069765360), commit `54cce127b95221ce48c332f55ec5d06ab7367d72`.
- Consulta directa de jobs:
  - `stage_baseline`: completed/success.
  - `stage_v1_camp002`: completed/success.
  - `stage_held_l3`: completed/success.
- Esta CI **certifica solo las suites que ejecuta**. No reemplaza 38 jobs anteriores ejecutados exclusivamente en rama de origen ni los runners excluidos de staging.

## Brechas identificadas en el código histórico (fuente W01)
| Suite histórica | Dependencia/herencia en fuente | Cobertura exigida históricamente | Estado staging V4 |
|---|---|---|---|
| CAMP003 | `item_automation_v28.gd` + fixture y CSV específicos | Globo Helio inmunidad/explosión; Banda Focus supervivencia; Garra Rápida RNG activado y no activado; SaveV2 y negativos de reserva | No equivalente certificado en CI parcial |
| CAMP004 | Hereda runner CAMP003 + fixture/CSV específicos | 79 escenarios/185 pares semilla; Puño Suerte crítico Chansey, Dado Trucado 4/5 golpes, Periscopio, Telescopio RNG positivo y negativo | No equivalente certificado en CI parcial |
| CAMP005 | Hereda runner CAMP004 + fixture/CSV específicos | 90 escenarios/272 pares semilla; Incienso Suave acierto/fallo, Garra Afilada críticos, Colmillo Agudo y Roca del Rey retroceso RNG y ausencia | No equivalente certificado en CI parcial |
| TANDA03 | Runner V3 hereda V2 y usa fixture/CSV propio | 18 gemas, equip real, consumo, liquidación, SaveV2, legacy, rechazo equipamientos y reserva | Una parte de L3 de otros ítems cubierta, no 18 gemas |
| TANDA04 | Runners por objeto, fixtures y CI originales | 10 equipables competitivos, controles no equipar/reserva, efecto y SaveV2 | 2/10 (Restos y Baya Zidra) muestreados en L3 parcial, NO suite completa |
| V2 B01/B02/B03 | 22 items certificados y 4 dependencias (origen) | Efectos por tipo y portador, 16 placas, 38 jobs y negativos | Tabla Draco muestreada; resto no revalidado aquí |

## Riesgos y ejecución segura recomendada
1. **Prioridad 1:** implementar en staging un runner autónomo W01 y pequeño para casos críticos de consumo/reemplazo/legacy de gemas y control de estado de reserva, sin heredar clases históricas ausentes.
2. **Prioridad 2:** pruebas focalizadas de negativos deterministas CAMP003 (Globo Helio/inmunidad, Banda Focus). Para RNG CAMP004/005 usar semillas y trazas nativas que prueben ambas ramas, no sustituir por probabilidades teóricas.
3. **Prioridad 3:** seleccionar por tipo y portador una matriz paramétrica de las 16 placas, comparando daño activo/control/reserva y haciendo settle+SaveV2. No tocar formas de Arceus.
4. En cada incremento registrar: ID/escenario, nombre del archivo del test, condición positiva y negativa, SHA de código y CI real. Una comprobación parcial jamás debe promover automáticamente todas las filas a CERTIFICADO.
5. Prohibido hacer merge con la rama origen o sobrescribir `FieldItemService`, `SaveV2`, `CreatureInstance`, `PlayerCollection`, `FieldItemBag`, motor nativo global o cambios de IA6.

## Estado
`PHASE_C_PARTIAL_GATE_PASS`; `READY_FOR_IA6_MERGE = NO`. No se han modificado archivos de producción; integración oficial IA6 NO.
