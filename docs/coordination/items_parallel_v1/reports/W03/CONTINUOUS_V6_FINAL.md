# IA3/W03 — ENTREGA CONTINUOUS_V6 / BOLA OCASO CUEVA REAL
**Fecha:** 12 de noviembre de 2026

**Rama exclusiva:** `codex/calvo-items-20261112-w03-dusk-cave-v6`.  
**Base fija:** `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`.  
**Commit EXACTO certificado:** `a5733eb3683222d302ec6ed084bb1ac69575b9ce`.  
**[CI de cierre #43125138000](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43125138000): completed / SUCCESS; 21 pasos SUCCESS y 0 FAIL.**

## Resultado y alcance
- Fases A→B→C completadas en staging: **1/1 `dusk_ball` L3 para cueva auténtica** (no noche).
- **0 IDs nuevos**: la Bola Ocaso ya estaba seleccionada en catálogo. No sumar esta tarea como creación de otro objeto.
- Multiplicador verificado **×3 al estar en `technical_cave_floor` auténtico, ×1 en `technical_grass` y ×1 si no existe un productor de zona válido**, usando la misma especie, nivel, PS, estado y seed en el test de comparación.
- Procedencia validada en cada captura mediante un Callable que consulta la zona física auténtica (Area2D + OverworldEncounterDirector + posición de jugador + región). El ID de criatura original se coteja antes de dar efecto.
- Guardado/carga manual SaveV2 recupera el origen desde una posición de mundo validada. No se crea un flag de cueva/noche que pueda llegar desde la interfaz.
- El flujo no introduce cambios en economía de inventario, propiedad Party/Storage, historial de especies, RNG global ni scripts Showdown JS.

## Recibos exactos en el log final
| Puerta | Resultado |
|---|---|
| Fuente, protección y baseline RED estático | `W03_V6_SOURCE PASS checks=25 protected=8 baseline_red=2 dusk_factor=3 veto_dynamax=true` |
| Fuente Pokémon previa | `W03_V3_SOURCE PASS checked=1082 moon=6 runtime_weight=0 ultra_fields=0` |
| Bola Ocaso positiva sobre 2 encuentros nativos reales | `W03_DUSK_V6 PASS checks=23 native=2 producer=real_cave_and_grass savev2=true` |
| Bola Ocaso negativa | `W03_DUSK_V6_NEG PASS checks=20 cave_source=live fail_rng=real` |
| SaveV2 habitual / adversarial | **40/0 y 8/0** |
| Repeat legacy original | **37 PASS** sin waiver |
| Repeat nativa y hostil | **26 y 18 PASS** |
| Net nativa y hostil | **79 y 19 PASS** |
| Moon nativa | **41 PASS** |
| Menta SaveV2, menta + Cuerda | **18 y 65 PASS** |
| Libros IA6, panel W05 real | **20 y 366 PASS** |
| Repelentes completos | **66 PASS** |

La prueba fallida previa [#43124880797](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43124880797) mostró 22/23 checks; falló una comparación de stock/propiedad porque el **propietario de test anterior a `load_game` estaba obsoleto** tras publicación atómica de nueva colección. Se actualizó solo la variable del test y la CI completa pasó sin alterar reglas de producción. El hueco RED del baseline se probó **estáticamente contra su árbol Git**, no mediante ejecución Godot pre-parche; no contar prueba runtime RED inexistente.

## Archivos funcionales editados
`scenes/visual/field_demo.gd`, `scenes/visual/field_native_bridge.gd`, `modules/gameplay/showdown_adventure_session.gd`, `modules/capture/capture_battle_context.gd`, `modules/capture/capture_context_ball_effects.gd`.

**Solo nuevos tests/CI:** `tests/gameplay/parallel_items_w03_dusk_native_v6.gd`, `tests/gameplay/parallel_items_w03_dusk_native_v6_negatives.gd`, `tests/tools/test_ia6_w03_v6_dusk_source_guard.py`, `.github/workflows/ia6-w03-v6-dusk-cave.yml`.

Los cinco archivos de producción son hunks estrechos; no se realiza cherry-pick ni merge completo de la rama V6 en IA6. Ver `CONTINUOUS_V6/W03_V6_SOURCE_DIAGNOSTIC.md` para diff lógico por función, matriz de productores faltantes y límites honestos de QA.

## Decisión y próximos responsables
**`READY_FOR_IA6_MERGE_DUSK_CAVE_CANDIDATE`. IA6 V6 oficial todavía NO integrada.** En la revisión de entrega el HEAD oficial IA6 había avanzado a `5ece417fe0e15c9507c870601bf87ce97e184996`, así que IA6 debe comparar contra su nuevo árbol y trasladar selectivamente solo los cinco hunks, aplicar y ejecutar CI posterior de los tests equivalentes sobre el SHA oficial. **W03 no debe editar la integradora oficial ni abrir V7 por su cuenta.**

Restan como no probadas las campañas íntegras 003–006 sobre el HEAD nuevo, 7/7 rutas W04 y la implementación de noche/cuevas en mapas diferentes del técnico. Dusk en cueva sí queda probado en esta staging.
