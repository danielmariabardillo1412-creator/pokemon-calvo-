# W04 — CONTINUOUS V6 · ENTREGA CERTIFICADA / CONSUMIDOR POSCOMBATE

**Fecha:** 2026-11-12  
**Rama exclusiva:** `codex/calvo-items-20261112-w04-evolution-consumer-v6`  
**Código SHA funcional exacto:** `1dd5bb05e987b75cedadeefa09c64925ff4cb35b`  
**GitHub Actions:** [#43126697924](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43126697924) **COMPLETED / SUCCESS**.  
**Dictamen:** **READY_FOR_IA6_MERGE_CONSUMER_CANDIDATE**, **NO integrado** en rama IA6, `main`, V28 ni PR118.

## Fase A: fallo causal reproducido
El `ShowdownAdventureSession._finish` produce XP real por `ProgressionSystem.reconcile_battle_result` y devuelve una lista `progression_events` después de publicar la liquidación sobre el dueño. La presentación anterior, `showdown_adventure_lab.gd::_settle`, llamaba `session.settle_finished_battle()` y **descartaba sus eventos**. Por tanto, un `EVOLUTION_AVAILABLE` auténtico no provocaba confirmación de jugador ni publicación en Party/Storage desde el campo. Esta es la frontera reparada; no se alteró la mecánica de experiencia.

## Fase B: intervención mínima
1. **Nuevo helper puro**, `modules/gameplay/w04_postbattle_evolution_consumer_v6.gd`. Para los diez `level_up` incondicionales V5 verifica evento real, `creature_id`, dueño actual único (Party/Storage), fuente/forma canónica, objetivo, nivel, `EvolutionRecord`, `Everstone` y elección vigente. `accept` aplica `ProgressionSystem.apply_evolution` existente y publica `PlayerCollection.replace_owned_same_identity`; `decline` no cambia el Pokémon. Una aceptación inválida o repetida es rechazada.
2. **Hunks de presentación**, `scenes/visual/field_native_presentation.gd`: intercepta **solo** la salida exitosa de `settle_finished_battle` y procesa los `progression_events` devueltos. Reutiliza una instancia de `FieldGrowthChoices` con el texto contextual **No evolucionar**. Las elecciones son secuenciales si hay más de una, sin volver a consumir XP. Bloquea retorno/guardado/carga mientras hay decisión pendiente y muestra el resultado.
3. **Hunks del puente**, `scenes/visual/field_native_bridge.gd`: impide `leave_battle`, `save_game` y `load_game` mientras el consumidor tiene una decisión pendiente. No cambia el formato de SaveV2 ni el sistema de mapa.
4. **Tests nuevos**, `tests/gameplay/w04_continuous_v6_consumer.gd` y `tests/gameplay/w04_continuous_v6_native_battle_ui.gd`, con workflow `.github/workflows/w04-continuous-v6-consumer.yml`. CI instala de forma aislada el `@pkmn/sim@0.10.11` fijado mediante lockfile y usa `POKEMON_CALVO_NODE=node`; no se toca el motor.

**Rutas piloto:**
- `diglett_alola` nivel 25 → 26 con resultado `dugtrio_alola`: conservando `form_id` regional real.
- `meowth_galar` nivel 27 → 28 con resultado `perrserker`: especie independiente, sin inventar forma regional de destino.

## Fase C: pruebas exactas
Evidencia literal del log verde #43126697924:
- `W04_V6_CONSUMER PASS checks=135 pilots=2 accepted=4 declined=4`: dos rutas × Party/Storage × aceptar/rechazar, XP/eventos, guardas de evento falso, prompt alterado, Everstone, guardado/carga manual y `effective_nature_id` W02 con estadísticas acordes a la naturaleza efectiva en el contrato de servicio.
- `W04_V6_NATIVE PASS checks=66 pilots=2 accepted=2 declined=2`: cuatro combates **Showdown reales** con rival debilitado por movimiento, XP liquidada al final, aparición del widget real de `FieldNativePresentation`, aceptar/declinar **mediante señal del widget en headless**, identidad de Party, anti-doble liquidación y SaveV2. No equivale a una prueba de clic gráfico/GPU manual.
- `W04_V5_PY PASS routes=10 conditional=6 trade=1 special=4 regional=57`.
- `W04_V5 PASS checks=526 routes=10 owners=20`; las diez rutas por nivel V5 permanecen.
- `W04_V3_L3 PASS checks=396 routes=7 ownership=14 rollback=2`; las siete rutas de objeto V4 permanecen.
- `W04_AUTORUN_V3_ALL PASS checks=968 examined=56 native_functional=55 blocked=1`.
- `W04_AUTORUN_V4 PASS checks=64 promoted=4 blocked=1`.
- `W04_V6_DYNAMAX_EXCLUSION PASS`; el `dynamax_candy` rechazado permanece excluido.

**Métrica:** consumidor real con decisión y publicación **2/2 pilotos**, cuatro casos de combate real; contratos de 10 rutas V5 existentes (no se cuentan diez nuevos pilotos visuales); **objetos nuevos 0**. Regresión disponible PASS. Suites históricas CAMP003–006 **NO ejecutadas** en la base V6 porque faltan dependencias originales; corresponde ejecutarlas sobre la integración oficial IA6.

## Dos incidencias de integración — no ocultarlas
**W04-V6-DEP-01 · Naturaleza efectiva y Showdown.** Con `nature_id=hardy` y `effective_nature_id=adamant`, `ShowdownBackend.open` rechazó la criatura **antes de combate**, alegando `Stat import mismatch ... /attack` (Diglett: game 36 vs native 33; Meowth: 45 vs 41). Reproducción registrada en CI fallida #43124774406. La prueba V6 de contrato comprueba mentas distintas; el piloto nativo usa naturaleza efectiva `hardy` igual a natal para no atribuir un PASS falso a W02 + nativo. **IA6/W02/motor** deben resolver y ensayar esa interoperabilidad sin modificar XP ni las reglas desde W04.

**W04-V6-DEP-02 · Cierre normal del worker tras victoria.** En la CI headless, el primer caso pasó apertura, ataque, settlement, prompt, aceptación y SaveV2, pero `await session.close()` no retornó dentro de 180 segundos (CI #43125581953, trazas `W04_V6_NATIVE_STAGE ... closing`). La prueba verde utiliza el método **existente** `session.stop_now()` *solo como limpieza del fixture*; no cambia la política de cierre real del juego. IA6 debe verificar `FieldNativeBridge.leave_battle → await session.close()` en entorno real y corregir el seam protegido si reproduce el bloqueo. **No afirmar vuelta completa al mapa certificada.**

## Límites expresos
- Flujo de señal UI en Godot headless certificado; **clic real/GPU/visibilidad en monitor no certificado**.
- Intercambio y disparadores especiales/condicionados siguen sin simplificarse; Exeggutor Alola permanece bloqueada sin Harvest oculta.
- Ni `ProgressionSystem`, ni `FieldItemService`, `FieldGrowthEffects`, `CreatureInstance`, `PlayerCollection`, `SaveV2`, `showdown_backend`, `native_engine.cjs`, W02/W03/W05 fueron modificados.
- Esta CI prueba **esta rama W04**, no la cohabitación con rama IA6 `codex/calvo-ia6-integration-20261109`. Traspaso selectivo por hunks y pruebas multiworker aún pendientes.

**Siguiente acción segura:** IA6 revise y trasplante el helper y los hunks de presentación/bridge, ejecute CAMP003–006, integración W02/W03/W05 y UI gráfica; gestione DEP-01 y DEP-02. W04 no debe iniciar V7 ni cambiar ramas protegidas sin nueva orden.
