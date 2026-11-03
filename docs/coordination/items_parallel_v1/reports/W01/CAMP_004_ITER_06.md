# IA1/W01 — CAMPAÑA_004 — Bloque 06/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp004`. **IDs del gate de IA6:** `smoke_ball;smooth_rock;snowball`. Estado de publicación **EN_CI_AUTOMATICA**, no afirmar CI PASS antes de ejecución.

## Auditoría de implementación existente
- **Bola de Humo** aparece en catálogo de combate como `DATA_ONLY` y sin descriptor de ataque. **No es un agujero funcional por sí mismo**: `modules/gameplay/held_escape_items.gd` implementa la regla de escape garantizado y `showdown_adventure_session.gd:flee` la aplica a la actividad real `held_item_active` proporcionada por el simulador. La suite previa `opencode_world_held_v2.gd` ya prueba huida, supresión y mal de ojo. Reutilizado, no duplicado.
- **Roca Suave** dispone de descriptor `smoothrock`; `held_effect_sweep_v3.cjs` contiene la comparación contra tormenta de arena, ampliando tres turnos la duración.
- **Bola de Nieve** dispone de `snowball` con `onDamagingHit`; `held_effect_sweep_v2.cjs` prueba +1 Ataque y consumo tras `powder_snow`.

## Matriz nueva
| Objeto | Positivo | Negativos |
| --- | --- | --- |
| `smoke_ball` | Huida real garantizada tras Mal de Ojo; sin gasto de RNG, no consumo, sin generar turno nativo; prueba de huida normal | Sin objeto y reserva siguen bloqueados por Mal de Ojo; Torpeza suprime actividad incluso estando equipado; turno de Reflejo no activa huida |
| `smooth_rock` | Tormenta de arena dura exactamente tres turnos adicionales respecto a no equipado/reserva | Reflejo sin invocación no altera tiempo ni consume |
| `snowball` | Polvo Nieve causa daño de hielo, sube Ataque +1 y consume una unidad únicamente al portador | Agua Pistola y Amnesia no elevan Ataque ni consumen; equipamiento en reserva es inerte |

**Batería:** 9 escenarios nuevos, 12 pares caso-semilla y 36 variantes; acumulados 43 escenarios, 110 pares, 330 variantes y 18 objetos. Para todos: motor native, portador/ausente/reserva, propiedad física, SaveV2 de snapshot/proyección antes de huida; efectos y no-consumo en la acción real Run. Los 34 escenarios anteriores siguen presentes.

## CI y restricciones
Bloque 05 cerrado de forma verificable en [#41602276948](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41602276948), SHA `7034b8c783eb9996369cbf1c97229c05713c9a08`, con regresión CAMP003 completa aprobada. El bloque 06 debe comprobar `CAMP004_W01_PY PASS blocks=6` y `CAMP004_W01_GODOT PASS blocks=6` sobre SHA de cambios y `completed/success`. Reparar solo ámbito W01 V5. Sin cambios de producción, main, V28 o ramas ajenas, ni cobertura visual/GPU garantizada.

Se mantiene como pendiente de IA6 la proyección SaveV2 a mitad de carga de Rayo Solar sin Hierba Única detectada en bloque 03.

## Primera CI fallida y reparación V5
Run [#41611257621](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41611257621) sobre SHA `f5d8ca39c415428367b5deff667f503100625500` completó el manifiesto y contrato Python: `CAMP004_W01_PY PASS blocks=6 checks=588`. Godot ejecutó `9670` comprobaciones y devolvió `errors=4`; **los cuatro fallos derivan del único escenario `smoke_klutz_negative/19`**: `begin_wild` rechazó sus tres variantes (active/none/reserve), y la comparación general marcó modo activo inválido. No hubo fallo específico de Roca Suave, Bola de Nieve, huida bajo Mal de Ojo, huida normal ni objeto sin Run.

**Hipótesis por comprobar:** fixture anterior usaba Mew con habilidad ajena `klutz`. Se cambia solo la especie de ese escenario a **Woobat**, que puede tener Torpeza, preservando `klutz` y el efecto negativo exigido sobre `held_item_active` y `flee`. Se añade `session.last_error` a la aserción de apertura para diagnóstico verificable. Ningún caso, semilla, variante o comprobación se suprime. Nueva CI debe certificar el resultado; si sigue sin abrir, investigar la causa exacta, sin atribuirla sin evidencia a las habilidades.

## Tercer intento V5: diagnóstico concluyente de política Randomlock

CI [#41613512888](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41613512888), SHA `61db95e508a5164879cc62f07163aed82d9b823e`, obtuvo Python PASS (588) pero Godot FAIL (9670 checks, 4 errores) al abrir el control `smoke_klutz_negative`: causa explícita `content_policy`. La política de usuario `config/randomlock_content_v1.json` **excluye** `klutz` para cualquier especie, incluido Woobat; no es un problema de especie.

Sin modificar esa política ni producción, se sustituye solo el negativo incompatible por `smoke_magic_room_negative`. El rival invoca `magic_room` realmente y se exige que el objeto quede inactivo en el snapshot nativo y que `flee` no use bandera de garantía: procesa el intento normal en los tres modos. Se preservan los otros ocho escenarios del bloque 06, los 34 anteriores, todas las semillas, 110 pares y 330 variantes, y SaveV2. El test técnico antiguo de Torpeza sin política sigue existiendo, pero **no cuenta como escenario jugable Randomlock**. Nueva CI pendiente.
