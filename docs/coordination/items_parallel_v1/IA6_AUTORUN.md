# ORDEN IA6 — W04 · V5 ACTIVA · EVOLUCIONES REGIONALES POR NIVEL · 2026-11-11

**NUEVA MISIÓN AUTORIZADA EN ESTA RAMA:** `codex/calvo-items-20261111-w04-regional-level-v5`. La V4 de `codex/calvo-ia6-staging-20261111-w04-evolution` ha terminado y permanece congelada como entrega a IA6 con CI #42965322073 SUCCESS y SHA funcional `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`. NO repetirla ni modificarla. El nuevo trabajo es V5, no una extensión de certificación V4.

**AL RECIBIR `p` O `sigue`**: verifica el HEAD y working tree, lee `docs/coordination/items_parallel_v1/CONTINUOUS_V5/STATE_W04.md`; ejecuta la primera tarea pendiente de las FASES A → B → C del plan de abajo. Continua por bloques mientras el turno lo permita, sin pedir otra tanda al terminar diez hitos. Checkpoint de SHA/CI por bloque y recuperación en otra ventana si hace falta. Si hay trabajo local no subido en la rama V4 anterior, publícalo antes de cambiar, nunca pierdas cambios con checkout.

**PROTECCIÓN:** cambiar solo esta rama. Sin merge de la V4 ni de IA6; main, V28, PR118, otras W, XP global, UI/bolsa, SaveV2 y motor de batalla protegidos. No alterar política de habilidad oculta ni exclusión de `dynamax_candy`.

**Plan autoridad IA6:** `docs/coordination/items_parallel_v1/CONTINUOUS_V5/PLAN_W04.md` en `codex/calvo-items-20261101-arbitro`. Copia íntegra a continuación para recuperación sin depender de lectura cruzada.

---

# IA6 / W04 — CAMPAÑA CONTINUA V5 · EVOLUCIONES REGIONALES POR NIVEL (11-11-2026)

## Autoridad y origen
Rama exclusiva NUEVA: `codex/calvo-items-20261111-w04-regional-level-v5`. Nace de `codex/calvo-ia6-staging-20261111-w04-evolution` después de su entrega V4, **sin alterar ni prolongar la certificación V4**. V4 tiene 7/7 evoluciones de ítem L3 en staging, CI #42965322073 SUCCESS, código SHA `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`, y está READY_FOR_IA6_MERGE_CANDIDATE. IA6 conserva en exclusiva el merge oficial y las pruebas multiworker.

**Nueva misión real:** completar cobertura funcional de las evoluciones regionales `level_up` que utilizan requisitos ya implementados. No duplicar las siete evoluciones con objetos, ni repetir indiscriminadamente las 55/56 pruebas de encuentros. `p` reanuda el primer trabajo pendiente de V5, pasando de fase a fase sin otra orden.

## Inventario contrastado con config/pokemon_variants_v1.json
57 `regional_species`, 28 registros de evolución: 16 `level_up`, 7 `use_item`, 1 `trade`, 4 disparadores especiales. Hay **10 registros level_up con conditions={}** que forman el alcance positivo; su implementación L3 todavía NO está certificada:
| Origen | Destino | Nivel mínimo |
|---|---|---|
| diglett_alola | dugtrio_alola | 26 |
| geodude_alola | graveler_alola | 25 |
| grimer_alola | muk_alola | 38 |
| meowth_galar | perrserker | 28 |
| ponyta_galar | rapidash_galar | 40 |
| mr_mime_galar | mr_rime | 42 |
| corsola_galar | cursola | 38 |
| zigzagoon_galar | linoone_galar | 20 |
| zorua_hisui | zoroark_hisui | 30 |
| wooper_paldea | clodsire | 20 |

Los otros 6 `level_up` poseen condiciones que NO se deben descartar: Rattata Alola (noche), Meowth Alola (amistad), Linoone Galar (noche), Qwilfish Hisui (movimiento conocido), Sneasel Hisui (objeto + día), Sliggoo Hisui (lluvia). La evolución de Graveler Alola por intercambio y los 4 triggers especiales permanecen en ticket aparte. No asignar nivel arbitrario a intercambios ni inventar clima, reloj, eventos de combate o habilidades ocultas.

## Fase A — Diagnóstico causal y contratos
1. Leer el HEAD de ESTA rama, `IA6_AUTORUN.md`, `CONTINUOUS_V5/STATE_W04.md` y la matriz canónica. Confirmar que los 10 registros y destinos existen y diferenciar evolución regional de especie no regional (p. ej., Perrserker y Clodsire).
2. Reproducir el camino auténtico `ProgressionSystem.gain_experience -> EVOLUTION_AVAILABLE -> ProgressionSystem.apply_evolution -> EvolutionSystem.apply_evolution` con eventos reales, no llamadas directas a Factory. Registrar prueba roja si el destino pierde la identidad canónica o no se publica en Party/Storage. Exigir que nivel 1 antes del umbral NO habilite evolución y que Everstone la bloquee si la regla existe.
3. Separar para cada ruta productor real disponible, L2/emitida, L3 de servicio, y bloqueo. No suponer que la generación del evento equivale a reemplazar criatura en el juego.

## Fase B — Corrección mínima y pilotos L3
4. Autorizar exclusivamente helpers W04 nuevos y corrección estrecha de la resolución de `form_id` **del destino** en `EvolutionSystem.apply_evolution` para esas diez rutas, solo si prueba roja confirma pérdida real. Preservar sin cambios la ruta de siete objetos y `effective_nature_id` W02. Un destino sin forma regional válida no debe recibir una `form_id` inventada.
5. Crear tests Python/Godot por ruta que partan de XP/nivel auténticos y evento de evolución, incluyan aceptación/declinación cuando aplique, validación de umbral, propietario Party/Storage, identidad estable, estadísticas con naturaleza natal y efectiva, IV/EV/PP, experiencia, SaveV2 manual, fuente/forma incorrecta, bloqueo Everstone y duplicación/rollback de sustitución.
6. El reemplazo real del dueño se podrá probar mediante el API existente `PlayerCollection.replace_owned_same_identity` desde tests/harness propio, nunca falsificando la implementación. Si hay un seam ausente en el consumidor/XP/GUI, **documentar DEPENDENCY_MISSING** y seguir con la siguiente ruta; NO editar `ProgressionSystem.gain_experience`, `reconcile_battle_result`, FieldItemBag, Showdown, BattleOutcome, SaveV2, PlayerCollection ni UI ajena.
7. No calificar como L3 de juego una evolución que solo se ejecute mediante helper aislado. Distinguir `L2`, `L3_SERVICIO` y `INTEGRACION_JUEGO_PENDIENTE`.

## Fase C — Regresión y entrega
8. Conservar 7/7 rutas de ítem V4, 55/56 encuentros y la exclusión `dynamax_candy`. Añadir negativas para los seis `level_up` condicionados, comercio y disparadores especiales, demostrando que no se activan por simplificación.
9. Ejecutar CI sobre SHA funcional, Godot/Python pertinentes y regresiones V4 existentes. Las suites CAMP003–006 que faltan en base staging se reservan a IA6: ausencia de fichero **no equivale** a PASS ni justifica reescribir historia.
10. Publicar `docs/coordination/items_parallel_v1/reports/W04/CONTINUOUS_V5_FINAL.md`, matriz por ruta, CI exacta, diff por función, tests y `CONTINUOUS_V5/STATE_W04.md` con READY_FOR_IA6. Si se agota toda tarea independiente, detenerse sin rondas de QA ficticias.

## Propiedad, límites y continuidad
V5 solo puede escribir en SU rama `codex/calvo-items-20261111-w04-regional-level-v5`: helper/test/fixture/report/workflow W04 y, condicionado a prueba roja, resolución de forma para las 10 rutas en `EvolutionSystem.apply_evolution`. No editar ramas V4 entregadas, IA6 integración, `main`, V28 ni PR118. No tocar `CreatureInstance`, `FieldItemService`, `ProgressionSystem`, `FieldItemBag`, SaveV2, catálogo, política, experiencia, RNG o archivos W01/W02/W03/W05. Para un cambio compartido fuera de esta autoridad, ticket con evidencia y continuar lo independiente. `p` no ejecuta tareas asíncronas: checkpoint cada fase/bloque para reanudar. Reportar: `V5 fase | 10 rutas examinadas | L2 | L3 servicio | integración juego | bloqueadas | objetos nuevos (esperado 0) | CI/SHA | IA6 central pendiente`.

