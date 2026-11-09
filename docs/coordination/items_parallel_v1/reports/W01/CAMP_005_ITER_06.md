# IA1/W01 — CAMPAÑA_005, bloque 06/10

**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`. **Identidad:** IA1/W01, equipables. No se cambia motor ni contratos compartidos.

## Cierre confirmado del bloque 05

El run oficial [#41966189357](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41966189357) fue `completed/success`, sobre SHA funcional `fc4fe90c83a89b98aee1cb4b02963ffac5f015ed`. Recibos exactos del job: `CAMP005_W01_PY PASS blocks=5 checks=335`, `CAMP005_W01_GODOT PASS blocks=5 checks=11012`; regresión completa `CAMP004_W01_PY PASS blocks=10 checks=1028` y `CAMP004_W01_GODOT PASS blocks=10 checks=16816`. Se cierra CSV del 05.

## Objetos y contratos nativos del bloque 06

| Objeto | Hook | Positivo real | Controles negativos |
| --- | --- | --- | --- |
| Escama Marina `deep_sea_scale` | `onModifySpD` | Clamperl recibe menos daño de `confusion` (ataque especial) | ataque físico `tackle`; portador Mew |
| Diente Marino `deep_sea_tooth` | `onModifySpA` | Clamperl aumenta daño de `water_gun` (especial) | movimiento físico `tackle`; portador Mew |
| Polvo Metálico `metal_powder` | `onModifyDef` | Ditto sin transformar recibe menos daño físico de `tackle` | ataque especial `confusion`; Ditto después de `transform` |

Se aplican los carriles reales `active`, `none`, `reserve`, idéntica semilla por carril, dos unidades físicas, propietario, no consumo, snapshot y restauración SaveV2. Daño recibido se mide mediante PS del portador (`start.hp - after.hp`); daño infligido con `damage`. No se confunden SpD/SpA/Def con multiplicadores genéricos de daño.

**Nueve escenarios nuevos**, 12 pares caso-semilla y 36 variantes; acumulado **54 escenarios, 134 pares, 402 variantes y 18 equipables**. Referencia preexistente `held_effect_sweep_v3.cjs` contiene pruebas positivas de Clamperl y Ditto, incluyendo su transformación.

## CI y aceptación

**PENDIENTE** de ejecutar Python y Godot para `blocks=6` con recuentos positivos y verificar run `completed/success` del SHA del bloque. CAMPAÑA_004 ya se regresó integralmente en bloque 05; volverá en 10 o si cambia producción. No se omiten controles preexistentes.

No se garantiza UI/GPU ni integración con `main`/V28. La incidencia SaveV2 de Rayo Solar a mitad de carga sigue asignada a IA6.

Siguiente `p` solamente tras CI positiva: certificar bloque 06 en el CSV y ejecutar únicamente bloque 07 (`quick_powder;razor_claw;razor_fang`).
## Reparación V5 tras primera CI de bloque 06

**Diagnóstico exacto:** [CI #42233251445](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42233251445) sobre SHA `7f38de23fa297f5d12f95e5135a565b223e63835`: Python PASS; Godot FAIL 4/12064. Las tres variantes de `metal_powder_transformed/19` fallaron únicamente al restaurar un checkpoint SaveV2 con Ditto todavía transformado; el cuarto fallo era la aserción global que depende de esas tres restauraciones. No se detectaron fallos del aumento de Def de Ditto sin transformar ni de los efectos de Clamperl.

**Cambio limitado al runner de W01:** observar y exigir primero el evento real de Transformación y el daño de Snorlax, preservando esas mediciones; cambiar realmente a Pokémon en reserva, verificar estado activo estable y conservar las dos unidades; después comprobar persistencia del snapshot estable y restauración exacta SaveV2. Los 54 escenarios y 134 pares siguen presentes, sin modificar los resultados del primer turno ni eliminar negativos.

**Dependencia IA6 no ocultada:** `ShowdownAdventureSession.restore_saved` / `ShowdownBackend.restore_saved` / snapshot nativo de `Transform`: un guardado DURANTE la transformación activa falla. Se mantiene test rojo/evidencia de la primera CI; no se ha alterado el backend ni relajado la obligación de restauración del estado estable. Para certificar restauración del checkpoint intermedio transformado se necesita un cambio de arquitectura compartida autorizado por IA6, con test aislado sobre mismo snapshot y SaveV2. **No afirmar que este fallo está reparado por W01.**

Segunda CI pendiente del mismo bloque 06. No iniciar bloque 07 antes de verificar que Python y Godot del 06 pasan.

## Dictamen de bloqueo tras segunda CI — NO CERTIFICADO

**Segunda ejecución fallida:** [#42235777234](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42235777234) sobre commit `17ba6ed11277e2651b1417692db2674c8b536bd0`. Python sí pasa: `CAMP005_W01_PY PASS blocks=6 checks=408`; Godot `CAMP005_W01_GODOT FAIL blocks=6 checks=12058 errors=4`. Tres errores son `metal_powder_transformed/19` en `active`, `none` y `reserve`: `cambio real a reserva tras Transformación` rechazado; el cuarto corresponde al fallo agregado de restauración/validez. La traza llega a `ShowdownAdventureSession.submit`, `ShowdownBackend._submit_choices` y `pipe_client.exchange`. El motivo exacto del rechazo todavía requiere investigación de la arquitectura compartida: **no está demostrado** que Transform por sí solo deshabilite el cambio.

**Primera ejecución fallida:** [#42233251445](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42233251445), commit `7f38de23fa297f5d12f95e5135a565b223e63835`: Python PASS; Godot FAIL, `checks=12064 errors=4`: el checkpoint SaveV2 de Ditto transformado no restauraba en ninguno de los tres modos, más fallo agregado.

**Resultado verificable:** pruebas de Clamperl y de la protección de Ditto sin transformar sin errores reportados; pruebas de transformación L2 ejecutadas, pero **L3 de guardado/restauración no certificado**. No es posible cerrar el bloque 06 como `CI_PASS_VERIFICADO`. Estado correcto: **BLOQUEADO_DEPENDENCIA_COMPARTIDA**. Su CSV aún muestra `EN_CI_AUTOMATICA`, porque cambiar el CSV ejecutaría de nuevo una CI acumulativa actualmente roja. El dictamen correcto está en este informe y en el ticket propio de W01, y requiere coordinación de IA6.

No se alteraron `main`, V28, otras ramas, backend compartido ni tests heredados. **No ejecutar bloque 07 con otra `p` hasta resolver la dependencia o recibir una decisión explícita de IA6**.

## Tercera CI: diagnóstico concreto para IA6 (7 de noviembre de 2026)

- [Run #42252938911](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42252938911), commit de pruebas `234b0bced95d497fe8804427c5c0b96c9963c674`, `completed/failure`.
- Python `CAMP005_W01_PY PASS blocks=6 checks=408`. Godot `CAMP005_W01_GODOT FAIL blocks=6 checks=12058 errors=4`.
- Tres mensajes `W01_CAMP005_BLOCK06_SWITCH_DIAGNOSTIC` sobre `metal_powder_transformed/19`, en modos `active`, `none`, `reserve`, muestran exactamente `error = "Cannot read properties of undefined (reading 'id')"` y `backend_last_error` idéntico.
- Comando rechazado: `switch 2`. `phase=move`; `revision=1`; `roster_active_id=own`; el activo tiene `transformed=true` y la reserva tiene PS 237/237, `transformed=false`. El fallo se repite con objeto activo, ausente y en reserva.
- El error es un TypeError de JavaScript enviado por RPC del backend, no un error reglamentario explícito de cambio de Pokémon. No está demostrado aún cuál es el campo `.id` ausente.

### Posible punto compartido y prueba de aislamiento

Archivo a revisar por IA6: `modules/battle/backends/showdown/native_engine.cjs`.
- `serialize` (alrededor de línea 83): `battle.toJSON()`.
- `restore` (alrededor de línea 96): `Battle.fromJSON(clone(snapshot))`, seguido de `b.restart(() => {})`.
- `dispatch(op=prepare)` (alrededor de línea 282): llama `fork.execute(op=restore)` antes de `choose`.
- `dispatch(op=choose)` (alrededor de línea 309): reconstruye candidato con `restore(serialize(session.battle))`.
- `ShowdownBackend.restore_saved` también usa el RPC `restore`. Por tanto, la restauración SaveV2 y el siguiente turno tras Transformación comparten reconstrucción de snapshots. Es una hipótesis, no una causa demostrada.

**Reproducción solicitada:** batalla nativa Ditto+reserva vs Snorlax, semilla `[19,2,3,4]`; `start → prepare/commit` de Transformación, `checkpoint` con `transformed=true`, y comparar (A) `restore(snapshot)` y (B) `prepare({p1:"switch 2",p2:"move 1"})`. Obtener stack JS COMPLETO, distinguiendo `fromJSON`, `restart` y `candidate.choose`, y localizar el valor undefined al leer `.id`. Probar luego SaveV2, neutralidad de Metal Powder tras transformación, PP, PS, identidad y propiedad. Si se modifica producción, ejecutar regresión CAMP004 íntegra.

**Autoridad:** La rama arbitral `codex/calvo-items-20261101-arbitro` permanece en SHA `385ee26598cfe8b2bc7e3e27698d296b7dfcc3e7` (último commit 4 de noviembre); ninguna autorización nueva de IA6 al comprobarlo el 7 de noviembre. W01 mantiene bloque 06 **BLOQUEADO_DEPENDENCIA_COMPARTIDA**, sin comenzar bloque 07, sin parche propio al backend. Solo 5 de 10 bloques certificados.

## IA6 2026-11-09 — parche condicionado sobre causa demostrada

Autorización verificable: `docs/coordination/items_parallel_v1/CAMPAIGN_005_W01_BLOCK06_NATIVE_TRANSFORM_REPAIR_AUTH_20261109.md` de rama árbitra, commit `ae22471638672812547f60c1150698af7fc7a3db`.

**Reproductor rojo aislado** [run #42678416631](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42678416631), SHA `fa68ac3d261123c8a0b97aa84d223e127a17403c`: misma semilla `[19,2,3,4]`. Transformación con y sin Polvo Metálico falla en `State.deserializePokemon` de `@pkmn/sim@0.10.11`, archivo `build/cjs/sim/state.js:210`; sin Transformación el estado se restaura (hash idéntico) y el cambio funciona. El control inicial contenía una aserción propia demasiado rígida sobre el orden de la reserva; corregida en reproducir posterior.

**Línea culpable exacta** en `deserializePokemon`: el `for (const [i, baseMoveSlot] of baseMoveSlots.entries())` lee `const moveSlot = pokemon.moveSlots[i]` y luego `moveSlot.id` sin comprobar que exista. Ditto posee **dos** movimientos originales (`transform`, `reflect`) y solo **uno** transformado (`tackle`); en el índice 1 la lista transformada no contiene `moveSlot`. La restauración no depende del objeto held; es fallo de reconstrucción del snapshot que afecta también al flujo nativo `prepare` y SaveV2. No cambiar la dependencia fijada ni las reglas Pokémon.

**Reparación limitada y explícita a `native_engine.cjs`:** en `restore(snapshot)`, normalizar únicamente en una copia privada los snapshots con `transformed=true` en los que `baseMoveSlots` sea más largo que `moveSlots`: añadir entradas virtuales temporales suficientes para superar la deserialización de la biblioteca; retirarlas del Pokémon restaurado antes de `restart`, sin alterar el original ni su hash canónico. Rechazar estructuras transformadas inválidas; no silenciar excepciones. El reproductor verifica que el hash serializado después de restauración sea idéntico, la reserva siga válida y el cambio real se ejecute. Godot restablece SaveV2 **en pleno turno transformado** ANTES del cambio; guarda y restaura nuevamente después de cambiar. No se omiten los 54 escenarios, 134 pares o los tres modos.

**Pruebas exigidas:** reproducir nativo A/B/C, control negativo de snapshot malformado, transacciones nativas preexistentes, Python CAMP005, Godot CAMP005 acumulativo, regresión completa Python/Godot CAMP004 tras modificación de `modules/`. **Todas las certificaciones del bloque 06 están pendientes de CI sobre el commit del parche.** No pasar a bloque 07 ni fusionar a `main` o V28.
