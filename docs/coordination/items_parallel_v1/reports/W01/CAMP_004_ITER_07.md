# IA1/W01 — CAMPAÑA_004 — Bloque 07/10

**Rama:** `codex/calvo-items-20261103-w01-camp004`. **IDs autorizados:** `sticky_barb;terrain_extender;throat_spray`. Estado inicial `EN_CI_AUTOMATICA`.

## Inspección del motor y de fuentes
El catálogo canónico los clasifica equipables seleccionados. `held_effect_sweep_v3.cjs` documenta Toxiestrella residual y transferencia tras contacto, y Cubresuelos ampliando el terreno 3 turnos. `held_pilot.cjs` documenta `throat_spray` activado tras `round`, +1 Ataque Especial y consumo. No se añade simulador ni se modifican módulos de producción.

## Matriz del bloque
| Objeto | Positivos | Negativos |
| --- | --- | --- |
| Toxiestrella | Daño residual exactamente 1/8 del PS máximo; contacto rival mediante Placaje transfiere el objeto al rival nativo | Sin objeto o en reserva no hay residual; Agua Pistola no provoca transferencia |
| Cubresuelos | Campo Eléctrico y Campo Psíquico ganan tres turnos de duración | Sin invocar terreno no aparece duración ni se consume el objeto |
| Espray Bucal | `round` y `growl` sonoros activan +1 Ataque Especial y consumen objeto | `tackle` y `reflect` no activan ni consumen; objeto ausente o en reserva inerte |

**Cobertura nueva:** 10 escenarios, 14 pares y 42 variantes independientes; **acumulado:** 53 escenarios, 124 pares, 372 variantes, 21 objetos. Cada variante comprueba combate nativo, inventario físico, estado de equipamiento, propietario congelado y reconstrucción estricta SaveV2 (snapshot y proyección). La transferencia de Toxiestrella se comprueba explícitamente por `foe_native_item=stickybarb` y no debe clasificarse como destrucción del objeto.

## Puertas y límites
Cierre previo bloque 06: CI [#41707616043](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41707616043), SHA `bc2f236ba9cd23072b78589d6f100437c436e7e8`, 9729 Godot PASS / 588 Python PASS. Fila 06 cerrada con esa evidencia. Espera `CAMP004_W01_PY PASS blocks=7`, `CAMP004_W01_GODOT PASS blocks=7`, ambas puertas y conclusión `completed/success`. Regresión completa CAMP003 ya pasó en el hito 05, y se repetirá en el hito 10 o si cambia producción; no corresponde repetirla en el 07 si no hay cambios de módulos.

Restricciones: `main`, V28, árbitra y demás trabajadoras intocables. Sin garantías visuales/GPU ni integración. Persistencia transitoria SaveV2 de carga de Rayo Solar sigue pendiente de IA6.
