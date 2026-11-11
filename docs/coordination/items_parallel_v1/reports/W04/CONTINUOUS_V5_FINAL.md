# W04 — CONTINUOUS V5 · ENTREGA FINAL / READY_FOR_IA6

**Fecha:** 2026-11-11  
**Rama exclusiva:** `codex/calvo-items-20261111-w04-regional-level-v5`  
**CI final exacta:** [#43073026880](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43073026880) — **COMPLETED / SUCCESS**.  
**SHA funcional verificado:** `2aad1bfa2a5d74adf845699c2f161345177ea622`. Los commits documentales posteriores no son el SHA de código probado.  
**Estado:** **READY_FOR_IA6**, sin integración oficial ni UI certificada.

## Fase A — Causalidad y prueba roja
El recorrido probado fue **`ProgressionSystem.gain_experience` -> `ProgressionEvent.EVOLUTION_AVAILABLE` -> `ProgressionSystem.apply_evolution` -> `EvolutionSystem.apply_evolution` -> `PlayerCollection.replace_owned_same_identity`**, con Party/Storage y SaveV2 manual. No se crearon criaturas destino directamente con Factory para fingir evolución.

La CI roja [#43071438217](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43071438217) sobre SHA `329c26f1ce5da6221a0ea1445db6f1a300eb4a09` demostró **20/20 eventos auténticos** y **20/20 persistencias SaveV2**, pero **12 fallos** de `form_id` en los seis destinos regionales (Party/Storage). Los cuatro destinos especie independiente necesitaban `form_id` vacío, no una forma inventada. La evidencia roja demuestra pérdida de identidad; no un fallo general de XP.

## Fase B — Hunk mínimo
Se añadió exclusivamente el helper puro W04 `modules/creatures/progression/regional_level_evolution_contract_w04_v5.gd`: whitelist cerrada, `EvolutionRecord` auténtico `level_up` sin condiciones, umbral exacto, especie+forma **de origen** validada, destino exacto, `form_id` **de destino** obtenido de la fuente canónica y `form_id` vacío para los cuatro destinos independientes. Rechaza origen/forma/target/nivel falsificados.

**Única función productiva existente editada:** `EvolutionSystem.apply_evolution`, para resolver forma de destino de estas diez rutas con el helper. No se cambió el resto de la función ni el contrato V4 de objetos; se conservaron `effective_nature_id`, `nature_id`, IV/EV, experiencia, movimientos/PP y estadísticas. Nada se modificó en ProgressionSystem, XP, PlayerCollection, SaveV2, CreatureInstance, FieldItemService, UI, RNG, catálogos, política ni motor de batalla.

## Diez rutas certificadas — matriz
| Fuente | Destino | Umbral | Clase de destino | Resultado servicio |
|---|---|---:|---|---|
| diglett_alola | dugtrio_alola | 26 | forma regional | 2/2 Party/Storage + SaveV2 |
| geodude_alola | graveler_alola | 25 | forma regional | 2/2 |
| grimer_alola | muk_alola | 38 | forma regional | 2/2 |
| meowth_galar | perrserker | 28 | especie independiente | 2/2, `form_id` vacío |
| ponyta_galar | rapidash_galar | 40 | forma regional | 2/2 |
| mr_mime_galar | mr_rime | 42 | especie independiente | 2/2, `form_id` vacío |
| corsola_galar | cursola | 38 | especie independiente | 2/2, `form_id` vacío |
| zigzagoon_galar | linoone_galar | 20 | forma regional | 2/2 |
| zorua_hisui | zoroark_hisui | 30 | forma regional | 2/2 |
| wooper_paldea | clodsire | 20 | especie independiente | 2/2, `form_id` vacío |

**Dictamen de nivel:** diez rutas `L2` verificadas y **10/10 `L3_SERVICIO` en harness**, con reemplazo real mediante `PlayerCollection.replace_owned_same_identity` y SaveV2 manual. **`INTEGRACION_JUEGO_PENDIENTE`**: `ProgressionSystem.apply_evolution` devuelve una nueva instancia, pero no la publica automáticamente en el dueño; la decisión/aceptación visual y los controles de duplicación/rollback de un futuro consumidor requieren prueba integrada. No afirmar L3 end-to-end desde UI.

## Fase C — Puertas realmente ejecutadas
CI #43073026880:
- `W04_V5_PY PASS routes=10 conditional=6 trade=1 special=4 regional=57`; inventario **57 especies / 28 records (16 level, 7 item, 1 trade, 4 especiales)** y veto `dynamax_candy`.
- `W04_V5 PASS checks=526 routes=10 owners=20`; evento de nivel real, nivel previo insuficiente, Everstone, aceptación/declinación representada por ausencia de sustitución, formas y destino, naturaleza efectiva W02, IV/EV/PP/XP, reemplazo propietario y SaveV2. Helper niega forma falsificada, target incorrecto y bajo nivel. Las seis rutas condicionadas siguen `DATA_ONLY` y los disparadores no level no se activan con contexto de nivel.
- `W04_V3_L3 PASS checks=396 routes=7 ownership=14 rollback=2`; las siete evoluciones con objeto de V4 conservan rollback y naturaleza efectiva.
- `W04_AUTORUN_V3_ALL PASS checks=968 examined=56 native_functional=55 blocked=1`; Exeggutor Alola continúa bloqueada por la habilidad oculta Harvest.
- `W04_AUTORUN_V4 PASS checks=64 promoted=4 blocked=1`; cuatro habilidades normales regionales conservadas.
- `W04_V5_DYNAMAX_EXCLUSION PASS`; `dynamax_candy` permanece descartado.

**No se ejecutaron en la rama V5 CAMP003–006**: sus dependencias históricas no existen en la base staging; una CI verde de V4/fuente histórica no constituye PASS de esas suites sobre V5.

## Dependencias reservadas a IA6
1. Consumidor de eventos `EVOLUTION_AVAILABLE` y decisión de aceptar/declinar mediante la UI real; emisión del evento NO sustituye el objeto guardado automáticamente.
2. Atomicidad, duplicación y rollback integrados cuando un consumidor sustituya dueño tras evolucionar; el harness demuestra la API existente, no prueba todos los fallos de GUI ni una transacción nueva.
3. CAMP003–006 Python/Godot sobre la integración central y regresión multiworker W02/W03/W05.
4. Merge selectivo, no copiar archivos enteros de esta rama sobre IA6 y no atribuir certificación central a CI de W04.

**Objetos nuevos:** 0. Ningún cambio en `main`, V28, PR118, V4 entregada, ramas ajenas ni `codex/calvo-ia6-integration-20261109`.  
**Siguiente paso:** IA6 integra solamente hunks necesarios y ejecuta pruebas de consumidor/UI+CI completa. W04 **STOP / READY_FOR_IA6**: no inventar V6 ni repetir QA de lo certificado sin orden nueva.
