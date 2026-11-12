# IA6 — W04 / V7 ACTIVA · 12-11-2026 · REGRESO A MAPA DESPUÉS DE EVOLUCIÓN

**NUEVA RAMA EXCLUSIVA:** `codex/calvo-items-20261112-w04-battle-return-v7`; origen: V6 completada `codex/calvo-items-20261112-w04-evolution-consumer-v6`.
**EL SIGUIENTE `p`** lee `docs/coordination/items_parallel_v1/CONTINUOUS_V7/STATE_W04.md` y ejecuta FASE A: reproducción RED del bloqueo `await session.close()` en combate real pos-evolución y retorno a mapa por `FieldNativeBridge.leave_battle`; luego reparación mínima autorizada y CI. No repetir V6 2/2 ni V5 10/10 por rutina.
**EVIDENCIA ANTERIOR:** #43126697924 SUCCESS SHA `1dd5bb05e987b75cedadeefa09c64925ff4cb35b` NO prueba vuelta al mapa; #43125581953 mostró colgado durante cierre. La prueba V6 limpiaba con `stop_now()`, que no cuenta como cierre del juego.
**SEGUNDO TICKET:** naturaleza efectiva `hardy`→`adamant` falla en importación Showdown (#43124774406). SOLO diagnóstico en V7, no editar motor ni falsear estadísticas, propietario IA6/W02.
**ACOTACIONES:** hunks y permisos exclusivos listados abajo, rama oficial IA6 y main/V28/PR118 intocables, `dynamax_candy` excluido. A→B→C sin STOP artificial; publicar SHA/CI y checkpoint; no trabajo en background.

---

# IA6 / W04 — CONTINUOUS_V7 · REGRESO NORMAL AL MAPA TRAS EVOLUCIÓN NATIVA
**Orden IA6 2026-11-12. Rama EXCLUSIVA nueva:** `codex/calvo-items-20261112-w04-battle-return-v7`, creada a partir de V6 terminada `codex/calvo-items-20261112-w04-evolution-consumer-v6`. La CI V6 #43126697924 SUCCESS certificó código `1dd5bb05e987b75cedadeefa09c64925ff4cb35b`, pero NO demuestra la salida del combate y retorno a exploración. El head documental posterior de V6 es distinto. **V7 empieza con 0/1 cierre nativo, no atribuirle ese PASS.**

## Falla real que debe resolver V7 (no repetir las diez evoluciones)
El informe `reports/W04/CONTINUOUS_V6_FINAL.md` registra ticket **W04-V6-DEP-02**: en CI #43125581953 el escenario completó combate → XP → prompt → aceptación → SaveV2, pero `await session.close()` no retornó en 180 segundos. La suite V6 verde sustituyó **SOLO la limpieza de test** por `session.stop_now()`. Esto no prueba retorno a mapa, cierre limpio del worker, desbloqueo de movimiento ni ciclo de exploración.

### Fase A — reproducción causal real
1. Inspeccionar HEAD/estado, el test V6 completo, `ShowdownAdventureSession/FieldNativeSession`, `modules/battle/backends/showdown/showdown_backend.gd::close/stop_now`, `pipe_client.gd::close/exchange`, `FieldNativePresentation` y `field_native_bridge.gd::leave_battle`, `field_demo.gd` lock/unlock. Identificar **qué await concreto se atasca**: shutdown RPC, drenar stdio, timer, SceneTree, estado busy, deadlock de señal UI o doble cierre. No suponer la causa por duración.
2. Construir prueba RED reproducible con combate Showdown real que produzca XP/evolución y llamada genuina de `FieldNativeBridge.leave_battle()` después de aceptar; verificar que la escena se oculta, bandera busy se limpia, movimiento de campo vuelve, `field_record_native_battle_closed` recibe exactamente una llamada y SaveV2 permite guardado manual al terminar. En segunda ruta declinar; controlar no duplicación de XP/evolución; repetir ciclo dos batallas. No confundir `session.stop_now()` de limpieza final de test con cierre normal. Medir/limitar atascos sin dejar workers huérfanos.
3. Ejecutar red estricta, guardar SHA/CI y logs de la etapa exacta. Comparar contra `FieldNativeBridge` oficial más reciente (IA6 HEAD puede haber cambiado) sin copiar fichero entero.

### Fase B — cambio mínimo autorizado EN ESTA STAGING
Permitidos hunks focalizados si se demuestra falla real en:
- `scenes/visual/field_native_bridge.gd::leave_battle` y guardas de retorno,
- `scenes/visual/field_native_presentation.gd` únicamente finalización/estado de prompt,
- `modules/battle/backends/showdown/showdown_backend.gd::close` si hay fallo concreto de su ciclo de cierre,
- `modules/battle/backends/showdown/pipe_client.gd::close` **únicamente** si el RED muestra que shutdown/stdio/timer es el culpable, con timeout real y parada garantizada preservando semántica normal; probar tanto Windows relevante como Ubuntu cuando CI lo permita. NO tocar `exchange`, `worker.cjs`, `native_engine.cjs`, motor JS, `ProgressionSystem`, (SaveV2), `CreatureInstance`, `PlayerCollection`, experiencia, recursos, scripts de W01/W02/W03/W05, ni alterar las 10 formas V5/7 rutas V4.
- Añadir test/fixture/workflow solo W04. Una corrección de cierre no debe camuflar un proceso muerto como cierre correcto: registrar éxito de shutdown o escalado forzoso con razón, liberar resources y conservar snapshots/estado del equipo. Si cambio implica otro módulo protegido, **detener producción** y ticket exacto IA6 en lugar de modificarlo unilateralmente.

### Fase C — CI e informe de entrega
1. CI headless Godot 4.7 con Node y Showdown fijados, 2 pilotos: Diglett Alola→Dugtrio Alola y Meowth Galar→Perrserker; aceptar, rechazar, un segundo ciclo, errores de cierre/guardado y captura/huida de control cuando proceda; afirmar `RETURN_TO_MAP_L3` solo tras `leave_battle` y movimiento efectivamente reactivado.
2. Conservar W04 V6 135+66 checks, V5 526, 7 objetos V4 396, naturaleza efectiva compatible a nivel de servicio, save normal/legacy/adversarial disponible, 55/56 regionales, veto Dinamax; CI SHA exacto y sin silencios/cancelaciones.
3. Ticket independiente **W04-V6-DEP-01** naturaleza efectiva diferente (`hardy`→`adamant`) rechazado en importación Showdown por `Stat import mismatch`. Reproducirlo de forma aislada, documentar el punto exacto `_creature_dto`/reglas del importador y el remedio sugerido a IA6/W02, **sin parchear** estadísticas/motor o relajar el validador desde W04. Esta dependencia NO se considera resuelta por arreglar cierre. No modificar importación nativa sin nueva autorización IA6.
4. Si se prueba el retorno con API real, entregar `reports/W04/CONTINUOUS_V7_FINAL.md`, `CONTINUOUS_V7/STATE_W04.md` con estado `READY_FOR_IA6_MERGE_RETURN_CANDIDATE`, SHA/CI y diffs limitados. Si no, `BLOCKED_SHARED_CLOSE_SEAM`, causa demostrada y propuesta mínima. No etiquetar OK por render en GPU, Android o suites CAMP003–006 si no corrieron.

**Autonomía:** siguiente `p` ejecuta fase A y avanza por B/C sin parar cada 10 hitos; checkpoint cada turno. 0 objetos nuevos de catálogo; 1 fallo de ciclo vital corregido si PASS. No fusionar oficial IA6 (su HEAD ya ha avanzado desde base W04), main, V28 ni PR118. La integración central y CI cruzada corresponden a IA6. No modificar otras trabajadoras. `dynamax_candy` sigue excluido.
