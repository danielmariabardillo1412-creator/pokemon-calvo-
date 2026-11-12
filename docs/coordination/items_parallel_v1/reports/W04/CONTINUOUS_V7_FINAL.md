# IA4/W04 — CONTINUOUS V7 · ENTREGA CERTIFICADA

**Fecha:** 2026-11-12  
**Rama exclusiva W04:** `codex/calvo-items-20261112-w04-battle-return-v7`  
**SHA exacto de código probado:** `6d483b839ec57c674afc36acc508102f0df10fd5`  
**CI final:** [#43139645110](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43139645110) — **COMPLETED / SUCCESS**.  
**Dictamen:** `READY_FOR_IA6_MERGE_RETURN_CANDIDATE` limitado al retorno en Godot headless **mediante apagado forzoso declarado**, no a un shutdown RPC limpio; no está fusionado en la rama oficial de IA6.

## A · Causa reproducida y delimitación del bloqueo
V6 #43125581953 había completado combate nativo, XP, elección y SaveV2, pero se bloqueaba en `await session.close()`. En V7 la CI RED #43136832418 volvió a reproducir la espera bloqueada al cerrar el primer combate, después de aceptar Diglett Alola. La instrumentación #43137078426 demostró `PipeClient.close` detenido en `await exchange(tree, {"op": "shutdown"}, 1000)` antes del cierre de los pipes. Intentar enviar el shutdown sin esperar la respuesta, con posterior cierre de los descriptores, tampoco terminaba (#43137609917 y #43137966321); el transporte de cierre normal sigue sin ser seguro en CI headless.

**Límite de la afirmación:** el escenario confirma una frontera bloqueante de IO/pipe en el ciclo de cierre. No demuestra la causa interna exacta de los buffers del sistema operativo ni del worker Node. No se ha cambiado `exchange()` ni `native_engine.cjs` ni `worker.cjs`.

## B · Cambio mínimo de cierre
En `modules/battle/backends/showdown/pipe_client.gd::close`, se sustituyó el cierre bloqueante por una escalada explícita al `stop_now()` preexistente, cuya terminación había sido probada en la CI V6. Se guarda el PID previo, se advierte `forced_shutdown: blocking_graceful_pipe_boundary`, se llama a `stop_now()`, se comprueba `not OS.is_process_running(original_pid)` y se devuelve ese resultado. Este camino **no es un cierre limpio de shutdown RPC**, y no debe describirse como tal. Evita que `FieldNativeBridge.leave_battle` se quede esperando un pipe bloqueado. El cierre normal requiere una solución posterior de transporte con pruebas en Windows y Ubuntu.

El otro código productivo V6 permanece intacto: consumidor de `EVOLUTION_AVAILABLE`, naturaleza efectiva W02, XP, origen/destino, `FieldNativePresentation`, `PlayerCollection`, SaveV2 y motor JS. No se toca `main`, V28, PR #118 ni ramas de otras trabajadoras.

## C · Pruebas y métricas exactas
**CI final #43139645110:**
- `W04_V7_CLOSE PASS checks=66 pilots=2 accepted=2 declined=2`: cuatro combates Showdown reales, XP de evolución, aceptar/declinar, SaveV2 y `await session.close()` que **retorna vía fallback forzoso**, procesos efectivamente terminados.
- `W04_V7_MAP PASS checks=37 cycles=2 closed=2`: instancia real de `field_demo.tscn`, dos batallas consecutivas (Diglett Alola acepta; Meowth Galar rechaza), entrada por paso de campo, elección de evolución, `FieldNativeBridge.leave_battle`, cierre registrado una sola vez, vista cerrada, movimiento desbloqueado, guardado/carga manual SaveV2 después de volver al mapa y segunda batalla sin proceso huérfano detectado.
- `W04_V6_CONSUMER PASS checks=135 pilots=2 accepted=4 declined=4`; `W04_V6_NATIVE PASS checks=66 pilots=2 accepted=2 declined=2`.
- `W04_V5 PASS checks=526 routes=10 owners=20`; `W04_V3_L3 PASS checks=396 routes=7 ownership=14 rollback=2`.
- `W04_AUTORUN_V3_ALL PASS checks=968 examined=56 native_functional=55 blocked=1` (Exeggutor Alola sigue bloqueada por Harvest); `W04_AUTORUN_V4 PASS checks=64 promoted=4 blocked=1`.
- `W04_V5_PY PASS routes=10 conditional=6 trade=1 special=4 regional=57`. `dynamax_candy` continúa excluido.
- `W04_V7_MINT_DEP PASS checks=8 reproduced=2 unresolved=2`: **PASS del diagnóstico que demuestra dos fallos persistentes, NO PASS de compatibilidad**. `hardy` natal y `adamant` efectiva provocan: Diglett Alola ataque game=36/native=33; Meowth Galar ataque game=41/native=38.

**Diagnóstico W02 independiente:** `native_engine.cjs::nativeSet` envía `nature: spec.nature_id ?? 'Hardy'`, sin leer `effective_nature_id`; `importPersistent` compara `spec.stats` del juego contra `storedStats` calculadas por el simulador y rechaza diferencias. Recomendar a IA6/W02 que serialice/represente correctamente la naturaleza efectiva en la frontera de importación y conserve la natal para ficha, con validador de estadísticas estricto y pruebas antes/después de menta. W04 **no** está autorizada para editar ese motor.

## Límites de entrega y pendientes
- Estado **`RETURN_TO_MAP_L3` certificado en Godot 4.7 headless** mediante el puente real; no es prueba de visualización GPU, Android ni clic físico.
- **Shutdown limpio NO resuelto**. La solución activa usa `stop_now()` y se debe evaluar por IA6 en integración/Windows antes de lanzamiento. La CI no demuestra respuesta a shutdown RPC.
- Naturaleza efectiva distinta de natal falla todavía al importar al backend Showdown. No se falseó el PASS modificando valores de estadísticas.
- CAMP003–006 y regresiones cruzadas W01/W02/W03/W05 **no ejecutadas sobre la rama central IA6**; la CI de W04 no certifica integración global.
- **0 objetos nuevos**; ninguna fusión ni modificación de `main`, V28 o PR118.

## Transferencia a IA6
Integrar selectivamente **solo** la ruta de cierre acotada en `PipeClient.close()` y hunks certificados V6/V5 que aún falten, no sobreescribir archivos compartidos. Ejecutar el conjunto completo de regresiones, revisar el cierre en Windows y la compatibilidad de mentas. Conservar por separado tickets: `W04-V6-DEP-01` naturaleza efectiva ↔ Showdown; `W04-V7-DEP-02` shutdown RPC bloqueante (mitigado por terminación forzosa, pendiente solución limpia). W04 cierra V7 y no inicia V8 sin orden nueva.
