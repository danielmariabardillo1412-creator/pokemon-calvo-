# IA6 — W01/IA1 · AUTORUN TANDA 04: equipables competitivos, 10 candidatos reales
Fecha: 2026-11-11. Rama exclusiva: `codex/calvo-items-20261110-w01-gems-autobatch01`.

## Punto de partida CERTIFICADO
La TANDA03 anterior está **CERRADA**: 10/10 hitos; 18 gemas históricas comprobadas por recorrido real `PlayerInventory → FieldItemService.equip → FieldNativeSession/Showdown → settle_finished_battle → SaveV2`. **0 objetos nuevos en esa tanda**. CI final [#42918737459](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42918737459) completada SUCCESS sobre HEAD `dd0eab2509e50e44597de3d8d39366b7f3f823b3`, seis jobs SUCCESS. Informe `reports/W01/AUTORUN_V3_FINAL.md`. **No repetir las gemas** ni CAMPAÑAS 003/004/005.

## 10 objetos equipables a examinar, uno por fila
Todos los IDs siguientes aparecen en `modules/inventory/item_connections_v1.json::holdable_ids` del HEAD auditado, **pero holdable NO es una certificación funcional ni equivale a seleccionado en política**. Antes de implementarlos comprobar política efectiva, código de batalla, pruebas preexistentes y si ya se certificaron en CAMP001/002 u otra tanda. La prioridad es completar efectos reales faltantes sin reescribir funcionalidades que ya existen.

| Fila | ID | Criterio positivo de la mecánica real |
|---|---|---|
| 01 | `leftovers` | recuperación al final de turno con PS perdidos; control PS completos |
| 02 | `life_orb` | potencia de daño y retroceso propio; inmunidad/fallo sin daño según regla nativa |
| 03 | `choice_band` | potencia física y bloqueo real de movimiento; cambio/reset válido |
| 04 | `choice_specs` | potencia especial y bloqueo real de movimiento; reserva/cambio |
| 05 | `choice_scarf` | velocidad/orden y bloqueo real; prioridad e independencia de velocidad |
| 06 | `shell_bell` | curación proporcional a daño realmente causado; controles sin daño |
| 07 | `eviolite` | Defensa/Def. Esp. solo en especies que pueden evolucionar conforme al catálogo |
| 08 | `safety_goggles` | bloqueos canónicos de polvo/efectos de clima; no bloquear ataques ajenos |
| 09 | `black_sludge` | recuperación Poison y penalización no Poison; dueño y tick correctos |
| 10 | `sitrus_berry` | activación real por umbral HP, consumo una vez, sin doble disparo al restaurar |

**Regla antirrepetición:** Para cada ID, si ya existe efecto completo y probado en escenarios L3 comparables, registrar `YA_CERTIFICADO` con SHA+CI+prueba y no contar como objeto nuevo; ejecutar únicamente el test faltante de integración si procede. Si está excluido, `NO_APLICA`. Si no hay soporte real, implementar y probar en seam local autorizado. Si varias filas resultan `YA_CERTIFICADO`, los **únicos suplentes preseleccionados** son `adrenaline_orb`, `absorb_bulb`, `rowap_berry` (también holdable): sustituir como máximo 3 filas ya certificadas, documentando la correspondencia; NUNCA contar dos veces. No ampliar más la tanda sin IA6.

## Contrato técnico y autonomía
1. `p`/`sigue` significa: leer `IA6_AUTORUN.md` de tu propia rama, comprobar checkpoint y ejecutar **la primera fila pendiente y las siguientes hasta 10** sin pedir autorización por objeto. Si acaba turno, guardar checkpoint y reanudar con otra `p`. Sin ejecución ficticia entre turnos.
2. Por cada objeto: efecto positivo del motor **nativo que ya usa el juego**, control sin objeto/tipo/portador/condición, consumos y resets correctos, uso desde `FieldItemService.equip` con propietario real, batalla, `settle_finished_battle` y SaveV2/legacy cuando proceda, no RNG fabricado; compatibilidad con Transformación/reserva cuando aplique. Usar fuente de reglas ya fijada en el repo; **no inventar multiplicadores ni simplificar efectos**.
3. Pruebas nuevas Python + Godot + nativo Showdown para cada efecto L2/L3, y CI acumulativa de CAMP003/004/005, T01/02/03, sin bajar denominadores ni `continue-on-error`.
4. **Permiso de modificación:** solo adaptadores/funciones **específicas del ítem** dentro del seam de held W01 ya usado y propio; tests/fixtures/runner/workflow e informes W01. `modules/battle/backends/showdown/native_engine.cjs` se permite **exclusivamente si un test rojo reproduce un fallo localizado del ID y el arreglo no cambia reglas globales ni otros objetos**. `FieldItemService`, `FieldItemBag`, `PlayerCollection`, `CreatureInstance`, `SaveGameRepository`, `SaveV2`, captura W03, formas W04 y panel W05 son solo lectura. Si un objeto exige seam protegido más amplio, prueba roja + ticket y sigue con otro.
5. Al finalizar: `reports/W01/AUTORUN_V4_PROGRESS.csv`, `reports/W01/AUTORUN_V4_FINAL.md`, SHA funcional, CI final real. Métricas separadas: **10 filas examinadas | N objetos nuevos implementados | M ya certificados | K bloqueados | efectos L3 realmente nuevos | integración en rama IA6: NO**. No se atribuye a W01 la integración conjunta de IA6. STOP tras las 10 filas.

**Protegido:** `main`, V28 y PR #118 intactos, no merges ni escritura en otras ramas. La integración final de W01/W02/W03/W04/W05 será una puerta independiente de IA6.
