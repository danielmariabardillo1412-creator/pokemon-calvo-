# IA1/W01 — CAMPAÑA_003, microbloque 08/10

**Estado al publicar:** `EN_CI_AUTOMATICA`; NO está verificado funcionalmente el bloque 08. Rama exclusiva `codex/calvo-items-20261103-w01-camp003`. IA6 asigna exactamente `luminous_moss;mental_herb;metronome`. Protocolo autónomo V5 activo; modificaciones solo en tests/fixture/documentación W01.

## Pruebas nativas de tres objetos nuevos

| Objeto | Evidencia anterior | Positivos y negativos |
|---|---|---|
| `luminous_moss` (Musgo Brillante) | `held_effect_sweep_v2.cjs`, `hit_type_stat_boost` Agua → `boosts.spd=1` | `moss_water_boost`: Agua Pistola del rival activa +1 Defensa Especial y consume solo el portador (19,23). `moss_normal_control`: Tackle no activa (19) |
| `mental_herb` (Hierba Mental) | `held_pilot.cjs`, cura `taunt`, `HELD_PILOT_VERIFIED` | `mental_taunt_cure`: al recibir Mofa elimina volátil y consume (19,23). `mental_no_taunt`: Amnesia no activa ni consume (19) |
| `metronome` (Metrónomo) | `held_effect_sweep_v3.cjs`, `repeat_and_reset` | `metronome_repeat_reset`: tres Agua Pistola consecutivas aumentan daño, Reflejo interrumpe, quinta acción Agua Pistola vuelve a daño base (19,23); `metronome_status_only` no activa ni consume (19) |

Cada prueba exige tres variantes **activo / ausente / reserva**, compara efectos nativos de la misma semilla, consumo, propietario e integridad de SaveV2. Para Metrónomo se conserva la secuencia real de PS del rival durante cinco turnos, no se simula daño ni se recalcula el efecto.

**Añadido:** 6 escenarios, 9 pares caso-semilla, 27 variantes. **Acumulado 01..08:** 54 escenarios, 108 pares, 324 variantes. Se mantienen intactos los 48 escenarios anteriores. Inspección estructural GitHub **24/24 invariantes PASS**, no equivale a ejecución Godot.

## Diagnóstico y autorreparación V5 en paralelo

- [CI #41565500695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565500695): Python `PASS blocks=7 checks=582`; Godot **FAIL blocks=7 checks=8793 errors=16**, después de completar toda la matriz y superar el anterior timeout. Fallos del propio arnés: 12 errores del ciclo de cambios `heavy_duty_boots` y 4 de lectura/comparación de orden `iron_ball` / `lagging_tail`. No atribuir PASS a 04–07.
- Corrección preliminar propia commit `2da7f3c5156d608abc5f35545ba3b5cb13f2fe43`: volver de reserva con plaza dinámica reordenada `switch 2`, mantener las aserciones de daño por Trampa Rocas; añadir traza de eventos nativos para investigar el orden. **No se han eliminado los negativos ni reprogramado las mecánicas.** El run de reparación se canceló tras nuevas pruebas independientes del bloque 08; último run acumulativo debe revalidarlo todo.
- Python y Godot del bloque 08 no tienen resultado definitivo todavía. Si el runner sigue fallando, corregir solo la causa concreta según V5; no marcar PASS ni pasar al bloque 09 dependiente hasta resolverla.

## Publicación

- Fixture `tests/fixtures/parallel_items/w01_campaign_003.json`: commit `d44f112b9422f14d4ef3646b5e068539e6c242ce`, blob `0728bb40640c9519f61cdb2568fac289bf77a266`.
- Godot `tests/gameplay/parallel_items_w01_campaign_003.gd`: commit `4b48d98b0432ebd6f4b4845cafe2ee72fb655fe0`, blob `28730756df0633c9440479e9e6100d4c71e4718c`.
- Python `tests/tools/test_parallel_items_w01_campaign_003.py`: commit `efe1abb568ec0fb52ee22709c67b99df8c30f3a8`, blob `c1da6380a988f14ca55d2de51041ec2359dace2d`.
- CSV progreso 8 filas, disparador `d68ca59bc61459e2295d467f67c765bb3a59bc69`. 01–03 `CI_PASS_VERIFICADO`; 04–07 `ENTREGADO_PENDIENTE_CI`; 08 `EN_CI_AUTOMATICA`.
- Nueva CI [#41567242610](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41567242610), `pending` al redactar. Debe emitir `CAMP003_W01_PY PASS blocks=8` y `CAMP003_W01_GODOT PASS blocks=8` y concluir `success`.

**Siguiente `p`:** verificar/reparar CI acumulativa y, solo si corresponde, ejecutar **bloque 09/10 `mirror_herb;muscle_band;protective_pads`**. Nunca tocar `main`, V28, producción ajena ni otras ramas. No certificar GPU/UI.

## Reparación V5 posterior a la entrega del bloque 08

**Veredicto nuevo del run 08:** [#41567242610](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41567242610) `completed/failure`. Python `CAMP003_W01_PY PASS blocks=8 checks=649`; Godot `CAMP003_W01_GODOT FAIL blocks=8 checks=9780 errors=4`. **Las 12 incidencias del ciclo Botas Gruesas de la CI 07 desaparecieron**, confirmando la corrección de orden de ranuras de cambio `["switch 2", "switch 2"]`; los únicos cuatro errores quedaron en el clasificador de primer movimiento `iron_speed_delay/{19,23}` y `lagging_same_priority_last/{19,23}`.

**Evidencia del log auténtico:** para los modos equipados la primera entrada fue `|move|p2a: calvo_p2_0|Tackle|p1a: calvo_p1_0`, mientras que en los controles fue `|move|p1a: calvo_p1_0|Tackle|p2a: calvo_p2_0`. Las aserciones de mecánica de Bola Férrea y Cola Plúmbea eran correctas: ambas hacen actuar después del oponente. El arnés defectuoso usaba `entry.contains("|p1a:")`, que encontraba el **objetivo** del movimiento incluso cuando el atacante era `p2a`, y por eso etiquetaba a ambos como `own`.

**Parche propio, sin tocar producción ni debilitar controles:** commit `8fe7e3e9d51462aeb6dcf18d01c2274d6835a831` (solo `tests/gameplay/parallel_items_w01_campaign_003.gd`). Corrige exclusivamente la identificación del actor a `entry.begins_with("|move|p1a:")`; se conservan la aserción estricta equipable `foe`/ausente `own`/reserva `own`, los 54 escenarios del fixture, las 108 semillas-escenario, las 324 variantes, el arnés SaveV2 y la comprobación del ciclo de Botas.

**Nueva CI acumulativa:** [#41569533376](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41569533376), SHA del parche anterior; estado inicialmente `in_progress`. Se requiere `CAMP003_W01_PY PASS blocks=8`, `CAMP003_W01_GODOT PASS blocks=8` y `completed/success` para certificar 04–08. Antes de ese resultado se mantiene `ENTREGADO_PENDIENTE_CI` para 04–07 y `EN_CI_AUTOMATICA` para 08.
