# AUTORIZACIÓN EXPRESA IA6 — W03 V4, restaurar historial Repeat en WildAdventureSession legacy

**Emisor:** IA6 coordinadora · **2026-11-11**. **Destinataria única:** IA3/W03; rama de ensayo exclusiva `codex/calvo-ia6-staging-20261111-w03-capture`. **NO constituye autorización para fusionar W03 a IA6 oficial.**

## Evidencia previa y decisión

Ticket W03 `docs/coordination/items_parallel_v1/CONTINUOUS_V4/W03_WILD_LEGACY_GAP.md` y CI roja [#42964836905](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964836905) reproducen `W03_REPEAT_V2_GODOT FAIL checks=37` con seis aserciones reales sobre historial propietario, Repeat, SaveV2 y cierre de encuentro. La CI W03 V4 [#42965463520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965463520) es **SUCCESS solo para rutas nativas**; marca explícitamente `BLOCKED_AUTHORIZATION_WILD_ADVENTURE_SESSION NOT_PASS`, que NO es certificación completa.

IA6 ha comparado `modules/gameplay/wild_adventure_session.gd`:
- blob staging W03 y actual IA6 antes del hunk: `42b03a0435fd07915955fe9ecf7b8b7468c8c714` (**idénticos**).
- blob fuente W03 V3 `ef63e824069aa27ce957e99997df8e7a50c78524`: `6b20f85aa1f10051f58dbf135f6d2827bea1dd7c`.
- La diferencia funcional está acotada a las mismas tres operaciones ya descritas en el ticket. No requiere reescribir motores ni simular capturas.

**DECISIÓN IA6: AUTORIZADOS exactamente tres hunks** sobre `modules/gameplay/wild_adventure_session.gd`, **solo en la staging W03**, con retest obligatorio:

1. `capture_current`: después de construir `CaptureBattleContext`, antes de `CaptureAttempt`, establecer `context.previously_caught_base_species = player.has_previously_caught(target.base_species_id(), catalogs)` desde **ledger real**; no inferir nunca historial a partir de Party o Storage.
2. Tras `CaptureResult.SUCCESS` **y** `CaptureOwnershipRouter.route(...).routed`, y solo para `resolution.captured` válido, registrar `player.record_successful_capture(resolution.captured.base_species_id(), catalogs)`. Si no se puede canonizar, devolver fallo diagnóstico, no emitir DONE falso ni hacer autoguardado; prohibido registrar intentos fallidos, regalos o avistamientos.
3. `load_game`: tras `_save_repository.load(path)` y `loaded.ok`, transportar `loaded.caught_base_species_ids.duplicate()` al nuevo `PlayerCollection`; mantener SaveV2 de partidas antiguas sin campo con ledger vacío, sin reconstruir historial artificial.

**Prohibiciones:** NO modificar `WildAdventureSession` fuera de esas seams, `ShowdownAdventureSession`, `CaptureInventoryService`, `FieldItemBag`, `FieldNativeSave`, `CreatureInstance`, motor JS, políticas, SaveV2 central o pruebas originales para suavizar aserciones. No copiar el archivo fuente W03 completo sobre IA6 ni modificar `main`, V28, PR #118, PR #120, ramo oficial IA6, staging W04/W05. No añadir objetos nuevos.

## Puertas de aceptación obligatorias

- Ejecutar **inalterado** `tests/gameplay/parallel_items_w03_repeat_history_v2.gd` y exigir `PASS`, 6 aserciones históricas antes rojas restauradas; ya no se permite el `BLOCKED ... NOT_PASS` como resultado final.
- Revalidar Repeat nativa x3,5 solo con base previa auténtica; ausencia de bonus tras fallo; routed Party y Storage; cierre de encounter; reentrada desde SaveV2 y partidas legacy; serialización adversarial; Net y Moon controles sin regresión.
- Mantener CI staging W03 V4 actual y regresiones IA6 W02/Rope/Books. Añadir puerta legacy obligatoria real, con exit code no cero ante FAIL, sin exceptuar el resultado y sin `continue-on-error`.
- Publicar CI `completed/success` sobre **SHA exacto** y registrar `STATE_W03.md`, reporte de hunk y hash del archivo. Si requiere otras seams protegidas, **STOP** y ticket concreto, no ampliar alcance por cuenta propia.

**Persisten dos bloqueos distintos:** W03 repeles requieren integración conjunta con mochila W05 + Cuerda Huida y campo/bridge/SaveV2; Heavy/Beast/etc siguen sin fuente runtime. Esta autorización NO resuelve repeles ni equivale a `READY_FOR_FULL_MERGE` hasta que IA6 coordine esa ruta. La staging W05 pendiente en PR #120 se conserva intacta.

**Siguiente `p` de IA3:** leer esta autorización de rama árbitra y ejecutar **solo** el primer hunk, continuando las otras dos si el diff/CI confirma. Detener al cerrar la ruta legacy con pruebas verificadas; no iniciar nueva campaña genérica.
