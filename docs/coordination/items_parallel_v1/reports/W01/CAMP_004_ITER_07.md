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

## Certificación final del bloque 07/10

**Run GitHub Actions:** [#41711361003](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711361003) · `completed/success` · **0 errores** · SHA funcional `328227633b204f04aebffe3af1773ca30e9d4955`.

Recibos literales inspeccionados en el log del job:

- `CAMP004_W01_MANIFEST_PASS reserved=10 completed=7 ids=30`
- `CAMP004_W01_PY PASS blocks=7 checks=707`
- `CAMP004_GATE_PY_PASS worker=W01 blocks=7 checks=707`
- `CAMP004_W01_GODOT PASS blocks=7 checks=11316`
- `CAMP004_GATE_GODOT_PASS worker=W01 blocks=7 checks=11316`

**Resultado acumulado:** siete microbloques de diez, 21 objetos, 53 escenarios, 124 pares caso-semilla y 372 variantes, con pruebas nativas de efecto, negativo, propiedad e integridad SaveV2. Se mantuvieron los 43 escenarios y 110 pares anteriores.

**Conclusiones del bloque:** Toxiestrella infiere daño residual y transferencia real al rival por contacto sin confundirla con eliminación del objeto; Cubresuelos amplía tres turnos terreno eléctrico y psíquico sin consumirse; Espray Bucal activa +1 Ataque Especial con `round` y `growl`, se consume solo cuando procede y no se activa con `tackle` ni `reflect`. Los negativos sin equipamiento y con objeto en reserva pasan en la misma batería.

**Regresiones:** CAMPAÑA_004 01–07 ha pasado íntegra. No se ejecutó CAMPAÑA_003 completa en este hito 07, al no haber cambios de producción: su último PASS sigue siendo la puerta del hito 05, run #41602276948 (12.392 Godot / 806 Python). Siguiente regresión obligatoria CAMP003 en hito 10 o si se modifica producción.

**Límites:** la CI headless no certifica GPU, interfaz ni la integración en `main`/V28. Continúa abierto el defecto de proyección de estado a mitad de carga de Rayo Solar sin Hierba Única (bloque 03) para IA6; no se modificó API compartida.

**Estado documental y próxima autorización:** la fila 07 del CSV conserva `EN_CI_AUTOMATICA` porque modificarla por separado provocaría una segunda ejecución pesada. La certificación funcional es el run y SHA anteriores. Con la próxima `p`, cambiar la fila 07 a `CI_PASS_VERIFICADO` con SHA `328227633b204f04aebffe3af1773ca30e9d4955` y CI `41711361003`, además de añadir exactamente la fila 08. **Próximo bloque 08/10:** `toxic_orb;utility_umbrella;weakness_policy`; no avanzarlo sin nueva `p`.
