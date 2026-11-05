# IA1/W01 — CAMPAÑA_005, bloque 04/10

**Rama:** `codex/calvo-items-20261104-w01-camp005`. **Encargo IA6:** `silver_powder;soft_sand;spell_tag`.

## Bloque 03: cierre documental

La CI [#41783664400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41783664400) certificó el SHA `67d0fe6041e690cc8059fd626eea7cdd4a840db2` con `CAMP005_W01_PY PASS blocks=3 checks=208` y `CAMP005_W01_GODOT PASS blocks=3 checks=3305`. Se cierra su fila como `CI_PASS_VERIFICADO`, sin atribuirle las nuevas pruebas del bloque 04.

## Matriz del bloque 04

| ID | Tipo | Positivo sobre Mew, nivel 100 | Control de otro tipo | Control no dañino |
| --- | --- | --- | --- | --- |
| `silver_powder` (Polvo Plata) | Bicho | `bug_buzz` | `tackle` | `reflect` |
| `soft_sand` (Arena Fina) | Tierra | `earth_power` | `tackle` | `reflect` |
| `spell_tag` (Hechizo) | Fantasma | `shadow_ball` | `tackle` | `reflect` |

Contratos nativos existentes: `onBasePower`, IDs `silverpowder`, `softsand`, `spelltag`, selección en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`; referencia `tools/item_audit/held_effect_sweep_v2.cjs`. Se aprovechan la misma implementación de batalla y los carriles del runner heredado, sin modificar el motor.

Cada positivo se contrasta con el mismo ataque en portador activo, sin objeto y en reserva (semillas 19, 23). Cada negativo de tipo y estado usa la semilla 19. Los tres modos comprueban identidad del portador, daño, conservación de dos unidades, no consumo y proyección/restauración SaveV2. El positivo exige `damage_active > damage_none == damage_reserve`; los negativos exigen igualdad de daño (o cero en movimiento de estado).

**Bloque 04:** 3 objetos, 9 escenarios, 12 pares caso-semilla, 36 variantes. **Acumulado CAMP005:** 12 objetos, 36 escenarios, 48 pares, 144 variantes. Los 27 escenarios de los tres bloques previos se conservan.

## Estado de certificación

**PENDIENTE DE CI del bloque 04.** Solo contar como aprobado tras ejecutar `CAMP005_W01_PY PASS blocks=4 checks=N` y `CAMP005_W01_GODOT PASS blocks=4 checks=N`, N positivo, y observar GitHub Actions `completed/success` sobre el SHA de pruebas de este bloque. La regresión integral CAMP004 no es obligatoria hasta el hito 05/10, 10/10 o cambios de producción.

**Límites:** sin prueba visual/GPU; no se acredita integración a `main` o V28. Continúa para IA6 la incidencia de SaveV2 a mitad de carga de Rayo Solar, detectada en CAMP004. No se han modificado `modules/`, workflow, otras ramas ni motores comunes.

**Próxima `p` solo tras PASS:** cerrar 04 documentalmente y ejecutar bloque 05 `twisted_spoon;metal_coat;kings_rock`, con regresión CAMP004 completa obligatoria.
