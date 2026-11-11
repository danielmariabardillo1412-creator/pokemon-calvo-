# IA3/W03 — V4: WildAdventureSession legacy RED → GREEN (autorizado por IA6)

**Fecha:** 11 de noviembre de 2026. **Rama:** `codex/calvo-ia6-staging-20261111-w03-capture`. **Integración oficial IA6: NO.**

## Mandato y alcance exactos

IA6 publicó `docs/coordination/items_parallel_v1/CONTINUOUS_V4/IA6_W03_LEGACY_WILD_SEAM_AUTH_20261111.md` en rama árbitra, sobre ticket `W03_WILD_LEGACY_GAP.md`. Autoriza únicamente tres hunks en `modules/gameplay/wild_adventure_session.gd`; prohíbe alterar pruebas originales y otros módulos protegidos.

**Blob original de staging:** `42b03a0435fd07915955fe9ecf7b8b7468c8c714` (idéntico al IA6 anterior); **blob nuevo:** `f8aacfdeb24a317d865717c98add76712a3b8196`.

**Commit de tres hunks:** `0bf1bb2c1f33499338c5e946128a2dc58c06b504`; GitHub `fetch_commit` verificó **un archivo y tres hunks**, únicamente inserciones:

1. `capture_current`, tras `context.catcher_level` y antes de `CaptureAttempt`: `context.previously_caught_base_species = player.has_previously_caught(target.base_species_id(), catalogs)`. Fuente: ledger exitoso del propietario, jamás equipo/almacén.
2. `capture_current`, tras `resolution.result.status == SUCCESS` y `CaptureOwnershipRouter.route(...).routed`: ante `resolution.captured == null` o `not player.record_successful_capture(resolution.captured.base_species_id(), catalogs)`, devolver `capture_history_canonicalization_failed`. Si fue enrutada y canónica, registrar antes de cerrar el encuentro; intentos fallidos no se registran.
3. `load_game`, tras cargar SaveV2 válido y reconstruir `restored.inventory`: `restored.caught_base_species_ids = loaded.caught_base_species_ids.duplicate()`. Histórico sin campo → array vacío; no inventar anteriores capturas.

**El fichero de pruebas original no fue modificado.** Sólo se ajustó `.github/workflows/ia6-w03-v4-capture-staging.yml` para ejecutar `parallel_items_w03_repeat_history_v2.gd` obligatoriamente con `set -euo pipefail`, `PASS checks=37` exacto y sin `continue-on-error`, excepciones ni el `BLOCKED...NOT_PASS` anterior. El workflow se dispara también al modificar `wild_adventure_session.gd`.

## Prueba independiente de código exacto

- **CI nueva:** [#43068968046](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43068968046) `completed/success`.
- **SHA código/workflow verificado:** `5a82da2a9dd1a868c3f8af9d73551fe16571adea`.
- **Jobs:** uno; **18 steps SUCCESS, 0 FAILURE**.
- **Regresión antes roja:** `W03_REPEAT_V2_GODOT PASS checks=37 native_capture_l3=false` y `W03_V4_LEGACY_WILD PASS strict_unmodified_test=true checks=37`. Las seis aserciones históricamente rojas ahora son PASS. El sufijo `native_capture_l3=false` es la etiqueta histórica del test legado, **no** indica fallo de las rutas Showdown nativas verificadas separadamente.
- **Repeat nativa:** `W03_REPEAT_NATIVE_V4 PASS checks=26` y negativos `PASS checks=18`.
- **Net nativa:** `W03_NET_NATIVE_V5 PASS checks=79` y negativos `PASS checks=19`.
- **Moon nativa:** `W03_V3_MOON PASS native=2 checks=41`.
- **SaveV2:** 40 PASS; adversarial 8 PASS.
- **Coexistencia IA6:** Menta/SaveV2 18 PASS; menta y Cuerda Huida 65 PASS; panel de libros en mochila 20 PASS.
- **Guardas de fuente:** Python 34 PASS; 5 blobs protegidos inalterados y `dynamax_candy` excluido. Fuente canónica 1.082 especies, seis líneas Moon y sin inventar clasificación Ultraente ni peso runtime.

## Límites para la integración oficial

Este cierre elimina el antiguo bloqueo de permiso de `WildAdventureSession`, **pero no fusiona** la staging con `codex/calvo-ia6-integration-20261109`. La integración de Repel/Súper Repel/Repel Máximo sigue necesitando autorización y reconciliación entre `FieldItemBag` (libros W05 + Cuerda Huida), `field_demo`, `field_native_bridge` y SaveV2. Ticket `CONTINUOUS_V4/W03_REPEL_BAG_GAP.md`.

Heavy/Beast/Dive/Dusk/Lure/Love siguen sin fuentes completas; Safari/Sport parcialmente por zona; Magikarp L5 `move_policy` mantiene su ticket independiente. Esta CI reejecutó **las puertas V4 seleccionadas**, no toda la historia CAMP003–006/V1–V3. No atribuirles certificación no ejecutada.

**Estado de entrega:** `READY_FOR_IA6_MERGE_CAPTURE / REPEL_SHARED_SEAM_PENDING`. IA6 puede revisar y aplicar selectivamente los hunks de captura en su rama oficial, y debe ejecutar la CI sobre ese árbol conjunto. **NO READY_FOR_FULL_MERGE** sin decisión sobre repelentes y regresión conjunta. W03 STOP válido sin otra autorización.
