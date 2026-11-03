# IA1/W01 — CAMPAÑA_004 — Bloque 02/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp004`. **Asignación oficial:** `damp_rock;float_stone;icy_rock`. **Estado al publicar:** `EN_CI_AUTOMATICA` (no afirmar PASS funcional sin CI en el SHA final).

## Diagnóstico y reutilización

Las tres entradas figuran como seleccionadas en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` y ya tienen descriptor en el Dex nativo. El barrido histórico `tools/item_audit/held_effect_sweep_v3.cjs` contiene casos reales `weather_duration`, `no_weather`, `weight_threshold` y `fixed_power_control`. No se implementa otra simulación de combate y no se toca producción.

## Pruebas nuevas del bloque 02

| Objeto | Positivo nativo | Negativo / control |
|---|---|---|
| Roca Lluvia | `rain_dance` prolonga lluvia **tres turnos** más con portador activo que sin objeto, misma semilla | Sin movimiento de clima no modifica duración; reserva no modifica duración |
| Roca Helada | `snowscape` prolonga nieve **tres turnos** más con portador activo | Sin movimiento de clima no crea clima; reserva no prolonga |
| Piedra Pómez | En Garchomp, `grass_knot` del rival causa menos daño solo si el Pokémon activo lleva el objeto | `tackle` rival no debe cambiar por el peso; el objeto en reserva no actúa |

Se añaden seis escenarios y nueve pares caso-semilla, ejecutados en tres modos (`active`, `none`, `reserve`): **27 variantes nuevas con SaveV2**. La matriz acumulada prevista es **14 escenarios, 43 pares y 129 variantes**. Cada sesión comprueba invariantes de inventario, no consumo, igualdad de snapshot antes/después de restaurar, propiedad y comparación con dos controles de equipamiento. Se conservan intactas las ocho pruebas del bloque 01.

El contrato Python exige manifest de la árbitra, IDs nativos exactos, gancho `onModifyWeight`, fuentes/hashes originales, semillas, especies, movimientos, conteos y rutas del ejecutor Godot. El runner Godot amplía la comparación real existente a duración de clima y daño recibido con controles positivos y negativos. **Los números de comprobaciones Python/Godot y el veredicto funcional quedan pendientes de GitHub Actions**, no se anticipan.

## Continuidad

Fila 01 cerrada con evidencia `CI_PASS_VERIFICADO`, run [#41580332632](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41580332632) y SHA `525991c4ad55dd8952ed2f62a4fc7f2a820540f3`. Fila 02 `EN_CI_AUTOMATICA`; el SHA y run se completarán tras verificar la ejecución para evitar CI documental redundante. Si falla, aplicar reparación V5 sobre pruebas de W01 o su propio comportamiento (sin romper regresiones).

## Cierre funcional verificado — CI final del bloque 02

El primer commit de incorporación del bloque 02, `53382c244ce4638bc9a1c3f754efecfb20f561e2`, obtuvo un FAIL **solo** en el contrato Python del arnés, que todavía comparaba ocho nombres del primer bloque con el conjunto acumulado de catorce. El motor Godot no llegó a ejecutarse en ese run. El commit V5 de reparación `970db4c7696364cc1c5ebaf51719405d60430af0` separó explícitamente los ocho casos originales de los seis nuevos y evitó un segundo movimiento `reflect` duplicado en controles. No se eliminaron escenarios ni se editó producción.

**Run oficial:** [#41584708689](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584708689) sobre SHA `970db4c7696364cc1c5ebaf51719405d60430af0`, resultado **`completed/success`**. Recibos exactos de logs:

- `CAMP004_W01_MANIFEST_PASS reserved=10 completed=2 ids=30`
- `CAMP004_W01_PY PASS blocks=2 checks=177`
- `CAMP004_GATE_PY_PASS worker=W01 blocks=2 checks=177`
- `CAMP004_W01_GODOT PASS blocks=2 checks=3666`
- `CAMP004_GATE_GODOT_PASS worker=W01 blocks=2 checks=3666`

**Estado funcional:** `CI_PASS_VERIFICADO` de **2/10 bloques, seis equipables, 14 escenarios y 129 variantes**, con cero errores en los checks ejecutados de Godot 4.7 y Python. La suite CAMP003 no se ha vuelto a ejecutar en este bloque por no haber modificaciones de producción ni estar en hito 05/10; permanece intacta y sigue teniendo su última certificación anterior. Estas pruebas no cubren UI/GPU ni demuestran merge a main.

**Nota documental:** la fila 02 de `CAMP_004_PROGRESO.csv` aún muestra `EN_CI_AUTOMATICA`; se certifica aquí el resultado real del run y el SHA. Actualizar esa fila junto con el siguiente microbloque autorizado evita disparar otra CI costosa solo por metadatos, al igual que se hizo con la fila 01. Este commit de documentación no modifica código ni pruebas certificadas. **Siguiente `p`: bloque 03/10** (`loaded_dice;misty_seed;power_herb`).
