# IA1/W01 — CAMPAÑA_005 — Continuidad y bloqueo CI

**Repositorio:** `danielmariabardillo1412-creator/pokemon-calvo-`
**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`
**Coordinación/solo lectura:** `codex/calvo-items-20261101-arbitro`

## Estado real tras primer encargo
- CAMPAÑA_004 previa: 10/10 CI aprobada #41733777992, evidencias heredadas, NO se recontarán como nuevos.
- CAMP005 bloque 01 autorizado `black_glasses;dragon_fang;hard_stone`. Fixture, validador Python y runner Godot funcional diseñados para 9 escenarios, 12 pares semilla, 36 controles de equipamiento con SaveV2; además progreso e informe `CAMP_005_ITER_01.md`.
- **No existe workflow aplicable a `codex/calvo-items-20261104-w01-camp005`**. El heredado `parallel-camp004-w01-autoci.yml` solo escucha la rama antigua y ejecuta contrato CAMP004. CI inicial de CAMP005: ningún run.
- El bloque 01 queda `DEPENDENCIA_DOCUMENTADA`, no `CI_PASS_VERIFICADO`; **no se ha observado ningún resultado funcional nuevo**. Ejecutar/crear CI corresponde a IA6 por V5. Los errores concretos de Godot, si los hubiera, solo podrán diagnosticarse tras el primer run.
- Invariantes: una `p` autoriza solo un bloque; sin CI 01 no avanzar a 02. No tocar `main`, V28, la rama árbitra, otras ramas, políticas comunes, ni producción ajena.
- Próximo paso de IA6: workflow con Godot 4.7, Python 3.11, Node22, recibos `CAMP005_W01_PY/GODOT PASS blocks=1` con checks positivos y **regresión CAMP004 completa en el mismo run** (hito 01), además de 05/10.
- Una vez CI tenga resultado, W01 diagnostica/recupera bloqueo, certifica 01 con SHA/run y queda preparada para bloque 02 `miracle_seed;mystic_water;never_melt_ice`.

Consultar para detalles mecánicos y requisitos de CI `CAMP_005_ITER_01.md`. Sin permiso nuevo de IA6 no modificar workflows.

## Recuperación CI y bloque 02 — trabajo autorizado

- IA6 instaló workflow propio `.github/workflows/parallel-camp005-w01-autoci.yml` en W01; la antigua dependencia de CI **queda resuelta**. Run [#41767517526](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767517526), SHA `bd33aeb3f993804c3c85217b81892356af39aac5`, **SUCCESS**: bloque 01 Python 88 PASS / Godot 1109 PASS, regresión CAMP004 íntegra Python 1028 PASS / Godot 16816 PASS. Registrar fila 01 `CI_PASS_VERIFICADO`.
- Con esta `p` se autoriza exactamente el bloque 02 `miracle_seed;mystic_water;never_melt_ice`. Positivos: `energy_ball`, `surf` e `ice_beam`; negativos `tackle` y `reflect` por objeto. Cada caso en modos activo/ausente/reserva con misma semilla; SaveV2, identidad y consumo. Nueve escenarios, doce pares, 36 variantes. Acumulado: seis objetos, 18 casos, 24 pares, 72 variantes. Código de producción inalterado.
- Esperar recibos `CAMP005_W01_PY PASS blocks=2 checks=N` y `CAMP005_W01_GODOT PASS blocks=2 checks=N` con N positivo y run `completed/success` sobre SHA del bloque 02. Si falla, diagnosticar y reparar rama propia según V5, no reducir aserciones.
- Regresión completa CAMP004 aprobada hito 01; nueva ejecución obligatoria en hitos 05 y 10 o tras cambios de producción. No inventar integración global, UI o GPU. Incidencia anterior SaveV2 en carga intermedia de Rayo Solar continúa pendiente para IA6.
- **Próxima `p` solo después de CI positiva:** bloquear cierre documental de 02 con SHA/run y ejecutar bloque 03 `poison_barb;sharp_beak;silk_scarf`. Nunca tocar `main`, V28, árbitra ni ramas ajenas.

## Bloque 02 — certificación real CI

La ejecución [GitHub Actions #41778911208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778911208) ha terminado `completed/success` sobre el **SHA de pruebas** `69438bfb81921456a87eb7da18b3442f50c79873`. Recibos extraídos del job:
- `CAMP005_W01_SCOPE PASS blocks=2`
- `CAMP005_W01_PY PASS blocks=2 checks=148`
- `CAMP005_W01_GODOT PASS blocks=2 checks=2207`

**Estado funcional: bloque 02 aprobado, 2/10 verificados**, 6 objetos, 18 escenarios, 24 pares caso-semilla y 72 variantes, con comparaciones nativas y SaveV2. Workflow y motores previos sin cambios en este commit. El workflow omitió legítimamente la regresión completa CAMPAÑA_004 en hito 02, ya verificada en el run del hito 01 #41767517526; volverá en hitos 05 y 10 o por parche de producción.

La fila 02 del CSV queda temporalmente `EN_CI_AUTOMATICA` para no disparar CI por el cierre documental. En la **siguiente `p`**, certificarla con `CI_PASS_VERIFICADO`, SHA `69438bfb81921456a87eb7da18b3442f50c79873` y run `41778911208` antes de insertar la fila 03. El siguiente microbloque, y solo ese, es `poison_barb;sharp_beak;silk_scarf`.

La incidencia SaveV2 del turno de carga de Rayo Solar de CAMPAÑA_004 sigue pendiente para IA6; no hay prueba visual/GPU ni integración en main/V28. **STOP en 02/10 hasta nueva `p`**.

## Bloque 03/10 — entrega y matriz acumulativa

- **B02 certificado:** CI [#41778911208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778911208), SHA `69438bfb81921456a87eb7da18b3442f50c79873`, `CAMP005_W01_PY PASS blocks=2 checks=148`, `CAMP005_W01_GODOT PASS blocks=2 checks=2207`. Fila 02 en `CI_PASS_VERIFICADO`.
- **B03 autorizado** `poison_barb;sharp_beak;silk_scarf`: golpe positivo `sludge_bomb`, `aerial_ace`, `tackle`, respectivamente; negativo `tackle`, `tackle`, `water_gun`; control no dañino `reflect`. Es esencial que Pañuelo de Seda potencie Placaje y que **Pistola Agua**, no Placaje, sea su control de tipo diferente.
- Nueve casos nuevos, doce pares y 36 variantes. Acumulado 3 bloques, 9 objetos, 27 casos, 36 pares, 108 variantes; tres modalidades equipamiento activo/ausente/reserva con owner y SaveV2, sin recortar escenarios anteriores.
- `CAMP005_W01_PY PASS blocks=3` y `CAMP005_W01_GODOT PASS blocks=3`, run `completed/success`, son la condición de cierre de B03. No atribuir aprobación por construcción de blobs ni basarse en el PASS de B02; revisar los logs y reparar con V5 si falla.
- No se modifican motor, workflow, main, V28, rama árbitra, PR #118 ni ramas W02-W05. La regresión integral CAMP004 corresponde al hito 05/10, 10/10 o parches de producción; el run previo del hito 01 está aprobado.
- Próxima `p` (solo si B03 PASS): bloque 04 `silver_powder;soft_sand;spell_tag`. Incidencia SaveV2 de Rayo Solar a media carga heredada de CAMP004 continúa para IA6, sin proclamar corrección ni integración global.

## Bloque 03 — certificación de CI real

La CI [#41783664400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41783664400) concluyó **`completed/success`** sobre el SHA de pruebas `67d0fe6041e690cc8059fd626eea7cdd4a840db2`. Se verificaron los recibos literales del job:
- `CAMP005_W01_SCOPE PASS blocks=3`
- `CAMP005_W01_PY PASS blocks=3 checks=208`
- `CAMP005_W01_GODOT PASS blocks=3 checks=3305`

Se mantiene el acumulado **3/10 bloques, 9 equipables, 27 escenarios, 36 pares caso-semilla y 108 variantes**, con comprobaciones funcionales de efecto positivo y SaveV2. No hubo modificaciones del motor ni de las pruebas heredadas. La regresión CAMP004 en el hito 03 se omitió legítimamente por la política del workflow (fue SUCCESS en el hito 01, run #41767517526; se repetirá al 05 y 10 o ante parche de producción).

Para evitar una CI redundante por metadatos, la fila 03 del CSV seguirá provisionalmente `EN_CI_AUTOMATICA`; con la próxima `p` se cerrará como `CI_PASS_VERIFICADO`, SHA `67d0fe6041e690cc8059fd626eea7cdd4a840db2` y run `41783664400`, antes de añadir el bloque 04 `silver_powder;soft_sand;spell_tag`. **No iniciar bloque 04 sin `p` explícita**.

Incidencia histórica SaveV2 de Rayo Solar a media carga pendiente de IA6; sin certificación visual/GPU ni fusión a main o V28.

## Bloque 04 — entrega técnica (pendiente de CI nueva)

- Bloque 03 certificado en fila de CSV: [run #41783664400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41783664400), SHA de pruebas `67d0fe6041e690cc8059fd626eea7cdd4a840db2`, Godot 3305 PASS y Python 208 PASS.
- Se añaden exclusivamente los tres IDs autorizados del bloque 04: `silver_powder` → Bicho/`bug_buzz`, `soft_sand` → Tierra/`earth_power`, `spell_tag` → Fantasma/`shadow_ball`. Controles comunes `tackle` (tipo no coincidente) y `reflect` (estado). Tres modos activos, ausente, reserva, SaveV2 y no consumo.
- Bloque 04: nueve casos y doce pares, 36 variantes. Acumulado 4 bloques, 12 objetos, 36 casos, 48 pares, 144 variantes. Los 27 casos previos no se eliminan; no se modifica producción ni CI.
- Estado `EN_CI_AUTOMATICA`, **NO decir PASS hasta run nuevo completado y exitoso con recibos Godot/Python blocks=4 y SHA idéntico**.
- Regresión completa CAMP004 prevista hitos 05/10 o por cambios de producción. Incidencia SaveV2 Rayo Solar intermedia para IA6. Sin integración `main`/V28 ni verificación GPU/UI.
- Próxima orden `p`, una vez CI positiva: certificar 04 y ejecutar **solo** bloque 05 `twisted_spoon;metal_coat;kings_rock`.

## Certificación final del bloque 04 — GitHub Actions

- [Run oficial #41954611857](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41954611857): `completed/success`.
- Commit funcional verificado: `814943eb7445acee0161763eff85eb87285ed3ec`.
- Recibos literales del job: `CAMP005_W01_SCOPE PASS blocks=4`, `CAMP005_W01_PY PASS blocks=4 checks=268`, `CAMP005_W01_GODOT PASS blocks=4 checks=4403`.
- **Estado funcional: 4/10 bloques aprobados, 12 equipables, 36 escenarios, 48 pares, 144 variantes.** La regresión completa CAMPAÑA_004 se omitió conforme al workflow para bloque 04, y se ejecutará obligatoriamente en 05 y 10 o con cambios de producción.
- La fila 04 del CSV continúa temporalmente `EN_CI_AUTOMATICA` para no ejecutar CI redundante por documentación. En la próxima `p`, cerrar como `CI_PASS_VERIFICADO`, con SHA funcional `814943eb7445acee0161763eff85eb87285ed3ec` y run `41954611857`, antes del bloque 05.
- No se certifica aún integración a `main`, V28 ni pruebas visuales/GPU. Pendiente para IA6: SaveV2 de Rayo Solar a mitad de carga.

## Bloque 05 — entrega pendiente de CI
- Bloque 04 certificado: SHA `814943eb7445acee0161763eff85eb87285ed3ec`, CI #41954611857, Godot 4403/Python 268.
- Asignados solo `twisted_spoon` (Psíquico), `metal_coat` (Acero), `kings_rock` (retroceso 10% nativo al golpear). Roca del Rey debe observar activación Y no activación durante 64 semillas; no se sustituye por metadatos.
- Nuevos: 9 escenarios, 74 pares, 222 variantes; acumulado: 45 escenarios, 122 pares, 366 variantes. SAVEV2 en los tres modos. Regresión CAMP004 obligatoria en esta CI del hito 05.
- Próxima `p`, solo tras CI SUCCESS: certificar bloque 05 y seguir bloque 06 `deep_sea_scale;deep_sea_tooth;metal_powder`. No tocar motor compartido, main, V28 u otras ramas.

## Bloque 06/10 — nuevo trabajo publicado, condicionado a CI
- B05 certificado: [CI #41966189357](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41966189357), SHA `fc4fe90c83a89b98aee1cb4b02963ffac5f015ed`; CAMP005 11012 Godot/335 Python; regresión CAMP004 16816 Godot/1028 Python, sin fallos.
- Los tres IDs nuevos W01: `deep_sea_scale` (Clamperl, SpD), `deep_sea_tooth` (Clamperl, SpA), `metal_powder` (Ditto, Def sin transformar). Prueba positiva de daño, controles físicos/especiales, portador incompatible y transformación. Usar combate nativo y SaveV2 en tres modalidades; no fingir que son modificadores de tipo.
- B06 añade 9 escenarios/12 pares/36 variantes; acumulado 6 bloques/18 objetos/54 escenarios/134 pares/402 variantes. No editar producción ni otras ramas.
- CI bloque 06 pendiente: cerrar solo si `CAMP005_W01_PY PASS blocks=6` y `CAMP005_W01_GODOT PASS blocks=6` y run `completed/success` en SHA de pruebas. Hito de regresión CAMP004 siguiente en 10/10 o si producción cambia.
- Próxima `p` tras CI positiva: certificar 06 y ejecutar solo 07 (`quick_powder;razor_claw;razor_fang`).
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
## Diagnóstico incremental autorizado en W01 (2026-11-06)

El usuario ha pulsado `p` y se ha comprobado el estado de la rama árbitra `codex/calvo-items-20261101-arbitro`: último commit `385ee26598cfe8b2bc7e3e27698d296b7dfcc3e7` del 4 de noviembre. **No existe nueva autorización de IA6 para cambiar el backend ni proceder al bloque 07.**

Se ha inspeccionado el código actual del contrato compartido, sin modificarlo: `ShowdownBackend.submit` devuelve `{accepted:false,error:…}`; `_submit_choices` recibe el mensaje de `PipeClient.exchange` y preserva `prepared.error` en `_rejected(reason)`; `ShowdownAdventureSession.submit` también puede rechazar por `inactive_or_changed_campaign`. Los logs existentes no imprimían el campo `error` del rechazo, por lo que no se puede adjudicar la causa a `Transform`, a restricciones del combate, a un evento de proyección o a la llamada de test.

Para cerrar esa laguna sin tocar producción, se instrumenta exclusivamente la prueba de W01 para emitir `W01_CAMP005_BLOCK06_SWITCH_DIAGNOSTIC` cuando el cambio posterior a Transformación no es aceptado. Incluye causa exacta devuelta, fase, revisión, elección, request y roster; no modifica ni elimina los escenarios acumulados. **No convierte el bloque 06 en PASS ni autoriza el 07.**

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

## B06 — certificación final verificable (9 de noviembre de 2026)

**CI oficial:** [#42679854792](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42679854792), `completed/success` para SHA funcional `2900431b3b50d3d47dbf7fabbb554915cd9c8319`. Evidencia literal de su único job:

- `CAMP005_W01_SCOPE PASS blocks=6`
- `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3` (A/B/C + rechazo explícito de malformed en script)
- `SHOWDOWN_TRANSACTIONS PASS 10`
- `CAMP005_W01_PY PASS blocks=6 checks=408`
- `CAMP005_W01_GODOT PASS blocks=6 checks=12124`
- `CAMP004_W01_PY PASS blocks=10 checks=1028`
- `CAMP004_W01_GODOT PASS blocks=10 checks=16816`

**Dictamen:** desbloqueado el fallo real del simulador en `State.deserializePokemon` durante Transformación mediante normalización efímera de slots sobre copia privada en `native_engine.cjs`. Se ha probado restauración nativa y SaveV2 en el turno con Ditto transformado, el posterior cambio legal, preservación de hash, inventario, propietario y PP, así como efecto de Polvo Metálico condicionado y los dos objetos de Clamperl. No se omite ningún escenario de campañas previas; acumulado **6/10 bloques cerrados, 18 objetos, 54 escenarios, 134 pares caso-semilla, 402 modalidades ejecutadas**.

Fila 06 del progreso: `CI_PASS_VERIFICADO`, anclada al SHA de código y al run completos. El cambio de documentación/CSV causa una nueva CI de verificación de metadatos; el SHA funcional citado no cambia. **Próxima `p`:** confirmar la CI final de metadatos y ejecutar exclusivamente el bloque 07 `quick_powder;razor_claw;razor_fang`; no adelantarse a ese bloque ahora.

**Límite:** esta autorización no aprueba merge. IA6 debe revisar el parche antes de integración compartida. `main`, V28 y ramas ajenas intactos.

## B07 — certificado definitivo (9 de noviembre de 2026)

**Rama propia:** `codex/calvo-items-20261104-w01-camp005`. **SHA funcional:** `1e713a1925fe3fa582f21b5353e2c7f265ba928d`. **CI [#42689328705](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42689328705) `completed/success`**, sobre ese mismo SHA.

- `CAMP005_W01_SCOPE PASS blocks=7`, `CAMP005_W01_PY PASS blocks=7 checks=480`.
- `CAMP005_W01_GODOT PASS blocks=7 checks=20049`; 63 escenarios, 222 pares caso-semilla, 666 modalidades acumuladas. B07 sumó 9 escenarios, 88 pares y 264 modalidades sin retirar ninguno de B01–B06.
- `W01_B07_NATIVE_SPEED PASS cases=3`: Polvo Veloz dobla velocidad solo de Ditto sin transformar; Mew y Ditto transformado no reciben el bono, sin simular RNG.
- Garra Afilada: crítico nativo por Foco Energía con testigo exclusivo frente a ausencia/reserva; negativos Reflejo y Gengar. Colmillo Agudo: ambos resultados de retroceso con 64 semillas reproducibles; negativos por ausencia, reserva, inmunidad y movimiento de estado. Sin consumo; restauración SaveV2 y propiedad comprobadas en los tres carriles.
- `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3` y `SHOWDOWN_TRANSACTIONS PASS 10` de nuevo. No cambios a `native_engine.cjs` ni otro módulo de producción.
- CAMP004 íntegra **no se reejecutó** en B07 conforme a workflow (solo hitos 01/05/10 o cambios de `modules/`); permanece acreditada en run #42679854792 (Python 1028; Godot 16816).

**Estado oficial: 7/10.** Fila 07 `CI_PASS_VERIFICADO`. La próxima `p` autoriza **solo** bloque 08: `odd_incense;rock_incense;rose_incense`. No empezar 08 ni publicar modificaciones fuera de W01 durante este turno. La CI que dispare el commit documental posterior se comprobará independientemente; su resultado no debe confundirse con el run funcional citado.
