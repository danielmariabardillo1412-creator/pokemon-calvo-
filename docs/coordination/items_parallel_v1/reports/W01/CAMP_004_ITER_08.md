# IA1/W01 — CAMPAÑA_004 — Bloque 08/10

**Rama de escritura:** `codex/calvo-items-20261103-w01-camp004`. **Autoridad:** `CAMPAIGN_004_W01_GATE.md`, cola aprobada y autonomía V5. **Objetos:** `toxic_orb`, `utility_umbrella`, `weakness_policy`.

## Base y trazabilidad

Bloque 07 se ha cerrado exclusivamente de forma administrativa usando [CI #41711361003](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711361003), SHA `328227633b204f04aebffe3af1773ca30e9d4955`, Godot 11316 / Python 707 PASS. No hay cambios de producción. Fuente canónica `ITEM_INVENTORY.csv`, `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, motor Showdown `gen9calvounifiedv1`, referencia nativa `held_effect_sweep_v2.cjs` y `held_effect_sweep_v3.cjs`.

## Pruebas incorporadas

| Objeto | Escenario positivo | Controles negativos |
| --- | --- | --- |
| Toxisfera | Mew adquiere envenenamiento grave al final de turno y conserva objeto | Gengar de tipo Veneno no se intoxica; Espacio Mágico desactiva el efecto; ausente/reserva |
| Parasol Multiuso | Bajo Sol reduce daño entrante de Ascuas; bajo Lluvia reduce daño entrante de Agua Pistola del Snorlax rival | Sin clima no cambia el daño; ausente/reserva; no consumo |
| Seguro Debilidad | Gyarados recibe Impactrueno supereficaz: +2 Ataque y +2 AtEsp, consume una sola unidad | Placaje neutro y Amnesia sin impacto no activan; ausente/reserva |

Matriz **9 casos / 13 pares semilla / 39 variantes**, y acumulado **62 casos / 137 pares / 411 variantes** cubriendo **24 objetos en 8 bloques**. La comparación usa motor Godot y propietario real, registro de estadísticas/status/PS, inventario, identidad de portador, snapshot y proyección restaurada de SaveV2 en los tres modos.

## Estado CI

**PENDIENTE DE EJECUCIÓN AUTOMÁTICA EN GITHUB ACTIONS** sobre el commit de este bloque. No certificar funcionalidad sin `CAMP004_W01_PY PASS blocks=8`, `CAMP004_W01_GODOT PASS blocks=8`, ambas puertas y resultado `completed/success` en el mismo SHA. Reparar bajo V5 cualquier fallo del arnés o de efecto W01 sin reducir cobertura. No alterar integración compartida, política, CAMPAÑA_003, main ni V28.

## Riesgos residuales

La proyección SaveV2 de Rayo Solar en fase intermedia sigue pendiente de IA6 (bloque 03), y la CI headless no demuestra GPU/UI ni integración en `main`/V28. Regresión integral CAMPAÑA_003 en hito 10 (o tras parche de producción), ya aprobada en hito 05.

## Primera CI y reparación de rendimiento del arnés

Primera ejecución [#41719364484](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719364484), SHA `63c2aa2f09b89fe75a87ff05e555780be8e64ee0`: contrato, manifiesto y Python aprobaron (`CAMP004_W01_PY PASS blocks=8 checks=818`). Godot se interrumpió por límite externo `timeout 900s` / `exit code 124`, **sin recibo de verificación funcional**. Los avisos repetidos de procesos PID inexistentes al cerrar `pipe_client.gd` son históricos y no se han usado para suprimir pruebas.

**Reparación V5 dentro del runner propio:** ejecutar de forma concurrente los tres controles independientes activo/ausente/reserva de cada caso mediante `call_deferred` + reunión de resultados, calcando el patrón aprobado de `parallel_items_w01_campaign_003.gd`. Se mantienen los 62 casos, 137 pares, las 411 variantes, todos los checks, snapshots e identidades SaveV2. Sin cambios de motor, política, workflow ni datos. Nueva CI pendiente: todavía NO es válido declarar PASS Godot.
