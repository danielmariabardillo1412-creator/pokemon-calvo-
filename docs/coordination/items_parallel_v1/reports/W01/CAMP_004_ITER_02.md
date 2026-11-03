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
