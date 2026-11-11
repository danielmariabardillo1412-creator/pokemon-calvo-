# RESUELTO EN STAGING W03 — IA6 autorizó tres hunks, test 37/37 PASS

Este ticket quedó **resuelto sólo en la staging W03** tras autorización expresa IA6 `IA6_W03_LEGACY_WILD_SEAM_AUTH_20261111.md`. Commit `0bf1bb2c` (un archivo y tres hunks) + CI obligatoria sin waiver [#43068968046](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43068968046) `SUCCESS` SHA `5a82da2a9dd1a868c3f8af9d73551fe16571adea`: `W03_REPEAT_V2_GODOT PASS checks=37`. **No se ha integrado aún en la rama oficial IA6.** Véase `reports/W03/CONTINUOUS_V4_LEGACY_REDGREEN_20261111.md`. El bloqueo de repelentes es independiente.

---

## Incidencia histórica que dio origen al permiso

# W03 V4 — puerta roja del adaptador antiguo WildAdventureSession

## Evidencia real

CI staging [#42964836905](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964836905), SHA `65e82eb37620a23c229d9e75b6b23c5d9a2197ef` **FAIL** en `Repeat owner-ledger canonical and SaveV2 regression`. Las puertas previas de Python y SaveV2 han pasado; `tests/gameplay/parallel_items_w03_repeat_history_v2.gd` emitió:

`W03_REPEAT_V2_GODOT FAIL checks=37 errors=["ledger exactly one base and party-owned","adventure reloaded ledger","repeat bonus from true ledger","live context ledger before attempt","repeat processed through real battle and spent","cannot double capture a closed encounter"]`

El test comprueba el adaptador histórico no nativo `WildAdventureSession`, distinto de `ShowdownAdventureSession`. El diff de la fuente W03 V3 frente a staging IA6 identificó **exactamente tres seams propios** omitidos en el archivo protegido `modules/gameplay/wild_adventure_session.gd`:
1. `capture_current`: tras obtener `target`, proyectar `context.previously_caught_base_species` desde `player.has_previously_caught(target.base_species_id(), catalogs)`, antes del intento.
2. `capture_current`: solo después de captura satisfactoria y enrutado de propiedad, `player.record_successful_capture(resolution.captured.base_species_id(), catalogs)`; no registrar fallos.
3. `load_game`: después de un SaveV2 válido, restaurar `restored.caught_base_species_ids = loaded.caught_base_species_ids.duplicate()`; sin inventar historial desde equipo o cajas.

El plan V4 **autoriza** PlayerCollection, SaveGameData/Repository/LoadResult, FieldNativeSave, contexto de captura y `ShowdownAdventureSession.capture`; **no autoriza** editar `WildAdventureSession`. Esta ventana no falsificará un PASS ni modificará un módulo no autorizado.

## Contrato para el propietario de la seam

Otorgar autorización mínima sobre esas tres líneas de `WildAdventureSession`, sin otras alteraciones, o excluir formalmente el adaptador legacy de los objetivos V4 si se certifica como retirado. Exigir retest del runner histórico SIN cambiar sus aserciones, más una CI acumulativa nueva. Hasta entonces **regresión legacy conocida y roja**, separada del recorrido nativo Showdown. No atribuir compatibilidad de todos los adaptadores de captura a un eventual CI verde de la ruta nativa.

**Estado:** `BLOCKED_AUTHORIZATION_WILD_ADVENTURE_SESSION`. El resultado no autoriza mezclar la rama staging en la integradora final sin una decisión explícita IA6.
