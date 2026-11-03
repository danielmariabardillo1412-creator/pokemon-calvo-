## CI FINAL comprobada — CAMPAÑA_005_FINALIZADA

Ejecución [GitHub Actions #41742709006](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742709006) sobre SHA funcional `5fe580ece1498eccdd4dce51fda630fa2b021416`: **completed/success**. Recibos literales: `CAMP005_W03_MANIFEST_PASS reserved=10 completed=10 ids=28 kind=FUNCTIONAL_BACKLOG`; `CAMP005_W03_PY PASS blocks=10 checks=169`; `CAMP005_GATE_PY_PASS`; `CAMP005_W03_GODOT PASS blocks=10 checks=208`; `CAMP005_GATE_GODOT_PASS`. Regresiones del hito final: `CAMP004_W03_PY PASS blocks=10 checks=187`, `CAMP004_W03_GODOT PASS blocks=10 checks=1344`, `CAMP003_W03_PY PASS blocks=10 checks=279`, `CAMP003_W03_GODOT PASS blocks=10 checks=986`.

**CI completa significa pruebas y contratos aprobados, no que los 28 objetos de backlog sean plenamente jugables**. Únicamente el bloque10 revalida Friend/Heal/Quick/Timer funcionales. No hay alta de objetos nuevos, modificación de producción ni certificación SaveV2 integral. STOP tras 10/10, pendiente de nueva campaña explícita de IA6.

---

# IA3/W03 — CAMPAÑA_005 / BLOQUE 10 — Cierre de captura, amistad, curación, turno y persistencia

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`. **IDs oficiales:** `friend_ball;heal_ball;quick_ball;timer_ball`. Son **cuatro elementos del backlog anterior**, no objetos nuevos. Último microbloque autorizado de diez.

## Integración funcional existente — comprobada con código real

| Objeto | Productor y consumidor concretos | Efecto existente |
|---|---|---|
| Friend Ball | `CaptureSystem.resolve → CaptureBallEffects.on_catch → CreatureInstance.friendship` | En captura exitosa establece amistad **exactamente 200**, incluso si antes era mayor; no altera PS, PP ni sueño |
| Heal Ball | `CaptureSystem.resolve → CaptureBallEffects.on_catch → CreatureInstance` | Al capturar recupera PS, elimina estado persistente y restablece PP hasta el máximo actual, preservando máximos aumentados |
| Quick Ball | `ShowdownAdventureSession.capture → CaptureBattleContext.completed_turns → CaptureContextBallEffects` | ×5 si `completed_turns=0`; ×1 tras un turno completado; contexto inexistente rechaza antes de gastar |
| Timer Ball | Misma fuente autoritativa del turno y consumidor de contexto | ×(1+0,3·turnos completos), máximo ×4; prevalidación para turno ausente, sin consumo ni RNG |

`CaptureSystem` ejecuta `on_catch` **solo después de resolver éxito**, y el adaptador de inventario valida el intento antes de alterar bolsa. La sesión construye el turno desde `battle_state().turn`, no desde UI o parámetros arbitrarios. El contexto pertenece a captura y no necesita nuevas APIs compartidas para estos cuatro efectos.

## Pruebas nuevas CAMP005 — ejecutables

El runner Godot `_block_10` añade capturas reales con `CaptureInventoryService.resolve`, bolsa con dos unidades, criatura Caterpie salvaje con PS bajos, sueño y PP aumentado: comprueba éxito, consumo de **una sola bola**, identidad conservada, party, Freund/Heal específicos y `CreatureInstance.to_dict/from_dict` de amistad, PS, estado y PP. Para Quick/Timer, prueba multiplicadores de turnos 0,1 y 10, y el rechazo por `completed_turns=-1` mediante el servicio de inventario sin gasto ni avance del RNG ni alteración de criatura/party.

El auditor Python valida las fuentes de cada regla, el productor de turnos en la sesión, la ruta exacta `CaptureSystem` de prevalidación y `on_catch`, la selección de los cuatro IDs y la cobertura ejecutable Godot. **No se duplica** una matriz de `unknown_ball` o un mero test negativo de CAMP004.

## Alcance real de persistencia

`CreatureInstance.to_dict/from_dict` conserva la identidad y cambios de amistad, PS, estado persistente y PP. **Esto NO certifica el ciclo completo de SaveV2** (sesión cerrada, guardado real, disco, recarga y reconstrucción de almacenamiento). IA6 debe reservar la validación integral SaveV2 para el propietario del sistema. Tampoco se certifica ejecución visual/GPU por CI headless.

## Cierre y arbitraje

Clasificación por cada uno de los cuatro IDs: **INTEGRACION_EXISTENTE_REVALIDADA**, no `FUNCIONAL_VERIFICADO_NUEVO`. Ningún módulo de producción se ha cambiado; sin cambios en `main`, V28, PR #118, otras ramas, política canónica ni SaveV2.

**Gate final obligatorio:** `CAMP005_W03_PY PASS blocks=10`, `CAMP005_W03_GODOT PASS blocks=10`, ambos gates IA6 **y regresiones CAMP004/CAMP003 completas** sobre el SHA final del CSV. No anunciar `CAMPAÑA_005_FINALIZADA` sin comprobar estos recibos.
