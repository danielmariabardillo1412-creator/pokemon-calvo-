# IA3/W03 — AUTORUN TANDA 02 FINALIZADA (PARCIAL L3)

**Fecha:** 2026-11-10 · **Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`
**Orden IA6:** `IA6_AUTORUN.md` TANDA 02 y `AUTONOMY_V1/QUEUE_W03_TANDA_02.md`
**SHA exacto de código/CI:** `4d6ee28064706e336ec8cf8ac89862356e886017`
**GitHub Actions:** [#42736177949](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42736177949) — **SUCCESS**, job `verify` creado y ejecutado. Los commits documentales posteriores no cambian código validado ni disparan ese workflow.

## Resultado de las 10 filas examinadas

| Fila | Resultado |
|---|---|
| 01 | Contrato de fuentes verdaderas trazado: `WildAdventureSession.capture_current`, `CaptureOwnershipRouter.route`, `PlayerCollection`, SaveV2 normal y campo nativo |
| 02 | Helper `caught_species_history_w03.gd`: species base desde metadatos canónicos, deduplicación y serialización versionada |
| 03 | Propiedad real `PlayerCollection.caught_base_species_ids`, independiente del equipo y almacenamiento actuales |
| 04 | El historial se registra solo tras `SUCCESS` y `routing.routed`; prueba positiva, fallo y doble captura no anotados. Falta una prueba aislada exhaustiva de almacenamiento lleno |
| 05 | Campo opcional en SaveV2 (versión 2 intacta); rechazo de duplicados, tipos malformados y partidas antiguas con ledger vacío |
| 06 | Persistencia probada en save/load manual de aventura y campo nativo, incluida carga de campo con ledger corrupto sin publicación |
| 07 | Contexto `previously_caught_base_species` producido desde colección en `WildAdventureSession`, **pero no** en la ruta nativa protegida |
| 08 | `repeat_ball`: captura ×3.5 para especie base previamente capturada y ×1 para otra especie, sin alterar el resto de Balls. Positivo en ruta de aventura |
| 09 | **BLOQUEADO L3 nativo:** falta conectar productor y registro tras commit en `ShowdownAdventureSession.capture`; archivo protegido explícitamente por IA6 |
| 10 | CI acumulativa integral: PASS. El paso de referencia Node 22 instala `@pkmn/sim` fijado para permitir ejecutar el suite del campo real |

**Contabilidad:** diez filas examinadas, siete hitos técnicos L2 positivos (02–08, con 07–08 parciales en nativo), un contrato de investigación L1, una prueba L3 bloqueada y un cierre QA. **Un único objeto nuevo en L2 de aventura: Repeat Ball. CERO objetos nuevos L3 completamente certificados.** No recontar como objetos nuevos los históricos `repel/super_repel/max_repel` ni Cuerda Huida. Los bloqueos anteriores (flutas/señuelos, Dive/Lure, Dusk, especiales) no se han resuelto.

## Evidencia de CI sobre el mismo SHA

| Runner | Recibo |
|---|---|
| CAMP006 Python | PASS bloques=3, 54 checks |
| CAMP006 Godot | PASS bloques=3, 78 checks |
| Repelentes mundo L3 | PASS 65 checks |
| CAMP005 Python | PASS 169 checks |
| CAMP005 Godot | PASS 208 checks |
| V1 auditoría de contexto | PASS 51 checks, sin declarar nuevos efectos de V1 |
| `parallel_items_w03_repeat_history_v2.gd` | PASS **37 checks**, `native_capture_l3=false` explícito |
| SaveV2 colección | PASS **40 checks** |
| SaveV2 adversarial | PASS **8 checks** |
| Battle reference pinned | PASS |
| Campo nativo, guardado y captura | `FIELD_NATIVE PASS checks=118 GPU=false errors=0` |

## Archivos editados de esta tanda

- `modules/capture/caught_species_history_w03.gd` (nuevo)
- `modules/capture/capture_battle_context.gd` y `capture_context_ball_effects.gd`
- `modules/creatures/storage/player_collection.gd`
- `modules/save/save_game_data.gd`, `save_game_repository.gd`, `load_result.gd` y `field_native_save.gd` **solo ledger autorizado**; SaveV2 `schema_version=2`, checksums y serializador intactos
- `modules/gameplay/wild_adventure_session.gd` (solo historial antes/después de captura y carga)
- `tests/gameplay/parallel_items_w03_repeat_history_v2.gd`, validadores Python históricos con whitelist de promoción solo para Repeat, workflow CI propio
- `reports/W03/AUTORUN_V2_PROGRESS.csv`, `AUTORUN_V2_NATIVE_REPEAT_SEAM_BLOCKER.md` y este cierre

Se conservaron fixtures originales CAMP005 y CAMP006. La whitelist histórica de Repeat Ball requiere un test positivo nuevo en HEAD, sin omitir tests, y conserva todos los tests de otras bolas. Los finales CRLF originales de `save_game_repository.gd` y `capture_battle_context.gd` fueron restaurados para hacer el diff revisable por IA6.

## Única decisión pendiente de IA6

**Ticket específico:** `reports/W03/AUTORUN_V2_NATIVE_REPEAT_SEAM_BLOCKER.md`. IA6 debe revisar/autorizar el cambio mínimo a `ShowdownAdventureSession.capture` para leer `player.caught_base_species_ids` antes de resolver la Ball y registrar éxito **únicamente** después de `_finish(...).accepted`. Completar prueba de dos capturas nativas después de guardado/carga, capturas fallidas, recuperación y almacenamiento lleno. W03 **no ha tocado** Showdown, motor de combate, `FieldItemBag`, catálogo, `CreatureInstance`, ni `SaveGameSerializer`.

**STOP:** TANDA 02 agotada; no inventar fila 11 ni nueva tanda. `main`, V28, PR118, ramas de otras trabajadoras y árbitra permanecen sin cambios.
