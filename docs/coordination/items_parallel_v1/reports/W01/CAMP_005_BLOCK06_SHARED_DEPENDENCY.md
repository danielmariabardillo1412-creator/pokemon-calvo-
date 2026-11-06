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
