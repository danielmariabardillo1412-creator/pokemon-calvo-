# IA6 — Dependencia compartida de W01, CAMPAÑA_005 bloque 06

**Estado:** BLOQUEADO_DEPENDENCIA_COMPARTIDA — no hay PASS del bloque 06.

## Fuente y consumidor
- **Origen:** restauración y transición de estado nativo Showdown cuando Ditto usa `transform`, en interacción con `ShowdownAdventureSession.restore_saved` / `ShowdownBackend.restore_saved` y flujo de `ShowdownAdventureSession.submit` → `ShowdownBackend._submit_choices` → `pipe_client.exchange`.
- **Consumidor:** W01 `tests/gameplay/parallel_items_w01_campaign_005.gd`, prueba `metal_powder_transformed/19`; los tres contextos `active`, `none`, `reserve`.
- **Contrato funcional necesario:** Ditto no recibe Defensa extra de `metal_powder` tras Transformación; la operación de combate debe mantener coherentes decisiones de cambio legales; un snapshot SaveV2 restaurado debe conservar íntegramente combate, propietario, equipamiento, inventario, Pokémon y estado nativo. Si el guardado en transformación no está soportado por diseño, IA6 debe declarar política y consumidor explícito antes de relajar ese requisito.

## Evidencias reproducibles
1. Primera CI [#42233251445](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42233251445), SHA `7f38de23fa297f5d12f95e5135a565b223e63835`: Python PASS 408; Godot FAIL 4 errores, `12064` checks ejecutados. Al intentar restaurar SaveV2 DURANTE Transformación, `disk checkpoint restored` devuelve falso en los tres modos; cuarto error agregado.
2. Segunda CI [#42235777234](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42235777234), SHA `17ba6ed11277e2651b1417692db2674c8b536bd0`: Python PASS 408; Godot FAIL 4, `12058` checks ejecutados. Tras comprobar el efecto y transformación nativa, W01 intenta `_switch_choice(session, &"reserve")`; `submit` rechaza el cambio en los tres modos. El cuarto error es agregado. No atribuir la causa del rechazo sin inspeccionar la respuesta exacta.
3. Los escenarios positivos de `deep_sea_scale` y `deep_sea_tooth`, y `metal_powder` sin Transformación, no generaron errores registrados en estas CI. No extrapolar ese resultado a SaveV2 durante Transformación ni integración final.

## Solicitud concreta a IA6

Investigar dentro de la autoridad del backend compartido:
- Obtener `last_error`, `accepted`, `request`, `revision`, slots del roster y razón exacta de rechazo del cambio posterior a Transformación, sin modificar contratos para silenciar el test.
- Determinar por qué `restore_saved` falla con snapshot transformado. Proponer cambio mínimo autorizado, o establecer política explícita de snapshots intermedios y modo correcto de estabilizarlos.
- Publicar un test específico en el propietario arquitectónico y autorizar a W01 únicamente el ajuste consumidor si hace falta.
- Repetir `CAMP005_W01_PY/GODOT PASS blocks=6` y el control acumulativo íntegro sobre el SHA reparado. Las regresiones CAMP004 ya fueron PASS en hito 05, pero son obligatorias si se modifica `modules/`.

**No hacer ahora:** mover código de backend a W01 sin autorización; declarar el bloque 06 aprobado; avanzar a bloque 07; fusionar a `main` o V28.

**Datos de alcance:** 18 IDs asignados en 6 bloques de CAMP005, 54 escenarios, 134 pares y 402 variantes; *solo* 5/10 bloques certificados actualmente.
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
