# IA1 / W01 — CONTINUOUS_V2 FINAL · READY_FOR_IA6

**Estado: READY_FOR_IA6.** Fases A+B+C finalizadas y certificadas en rama propia; **NO** integradas en la rama oficial de IA6.

## Gates comprobadas
| Control | Run | SHA del run | Evidencia |
|---|---|---|---|
| Fase A diez equipables | [#42939814729](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939814729) | `83dacee5c924505f5234503a4fef126ea0bb0e01` | 16/16 SUCCESS |
| Fase B bloque 01 | [#42954745915](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42954745915) | `1bfd86991cfbd01509b29a245f2e8ee7ada45e93` | 22/22 SUCCESS |
| Regresión integral A+B | [#42958587809](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958587809) | `dead5a21679c0aa8f635f3ce12fce0279ada0fc0` | **38/38 SUCCESS**, incluido CAMP004/005 |
| Veto posterior de IA6 Caramelo Dinamax | [#42960157622](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42960157622) | `53b292321b7eba52b3b5469505c4cefb29e86886` | Python + Godot: `checks=22 excluded=45` |
| Auditoría final Fase C ledger | [#42964085232](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964085232) | `8464374f56bb52075ced46fcf2af5b867dcfaa14` | **SUCCESS** y `W01_PHASE_C_LEDGER_READY total_certified=32 external=4` |

## Contabilidad y titularidad
- **36 IDs examinados**, únicos: 10 Fase A + 26 Fase B.
- **32 efectos ya implementados antes, ahora con L2/L3 certificados**. A 10, B01 6, B02 10, B03 6. Todos los SHA y runs de cada fila constan en `AUTORUN_V4_PROGRESS.csv` y `CONTINUOUS_V2_PHASE_B_PROGRESS.csv`.
- **4 DEPENDENCIA_FUERA_W01:** `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`; no seleccionados, `native_entry=False`, NO contar como implementados o funcionales.
- **Objetos nuevos de producción implementados en esta misión: 0.** El trabajo de W01 crea y aumenta cobertura y fiabilidad QA y comprueba el motor ya existente; no equivale a tener 32 cambios de código funcional.
- **Integración en rama oficial IA6: NO**. READY significa que IA6 puede revisar y trasladar selectivamente, no que un merge haya tenido lugar.
- La exclusión explícita `dynamax_candy` se conserva sin afectar Rare Candy/Exp Candies ni los 36 IDs de W01. No está autorizada su implementación o selección.

## Pruebas y límites
- Recorrido genuino `PlayerInventory → FieldItemService.equip → FieldNativeSession/Showdown → settle_finished_battle → SaveV2`.
- Positivos y negativos por efecto, portador, reserva, incompatibilidad de tipo, PS, bloqueo, consumo, restauración y preservación de inventario; para placas solo impulso por tipo, no formas de Arceus.
- No cambiar `main`, V28, PR118, ramas ajenas, SaveV2, `CreatureInstance`, `FieldItemService` ni motor global.

## Relevo aprobado por IA6
La nueva misión `CONTINUOUS_V4` de W01 está preasignada en `codex/calvo-ia6-staging-20261111-w01-held`. Queda **autorizada su activación DESPUÉS de este cierre** y de recuperar la instrucción/STATE de esa staging. La staging es un ensayo: no sustituye ni fusiona rama árbitra; primero comparar diff funcional y ejecutar test rojo contra base IA6 `e63b2e6c7e175fba318cc2f562bebd1769589092`.
