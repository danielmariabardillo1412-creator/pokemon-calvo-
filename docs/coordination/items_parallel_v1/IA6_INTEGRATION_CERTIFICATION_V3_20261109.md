# IA6 — CERTIFICACIÓN V3: NATURALEZA EFECTIVA EN SAVE NATIVO · 2026-11-09

**Rama aislada:** `codex/calvo-ia6-integration-20261109`  
**SHA exacto de la CI:** `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e`  
**Run:** [GitHub Actions #42701239557](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42701239557), `completed/success`, 1 job PASS.

## Hallazgo crítico y corrección autorizada IA6

El helper de W02/CreatureInstance calcula atributos según `effective_nature_id` tras usar una menta, conservando `nature_id` original. Pero `modules/save/field_native_save.gd::_valid_creature` volvía a validar `c.stats` **exclusivamente contra `c.nature_id` original**; los snapshots de SaveV2 de la mochila podían ser correctos y aun así el *guardado real de mundo* fallaba por `invalid_owned_creature`.

**Reparación mínima en `modules/save/field_native_save.gd`:** calcular `stat_nature` desde `effective_nature_id` si está presente, y desde `nature_id` en save legado, comprobar ambas naturalezas mediante `ProgressionRuleset.is_valid_nature`, y hacer `StatCalculator.compute` contra `stat_nature`. No tocar `SaveGameData`, formato del envelope, checksum, serialización, estadísticas de combate, reglas ni catálogos. Preservar naturaleza original.

**Nuevo test de extremo a extremo:** `tests/gameplay/ia6_mint_field_native_save_20261109.gd` crea la demo real, selecciona una menta con efecto estadístico en el primer Pokémon, pulsa el botón de la mochila, verifica consumo único e identidad y guardado/recarga **mediante `field_native_bridge.save_game/load_game`**, sin autosave ni bypass. Recibo: `IA6_MINT_FIELD_SAVE PASS checks=18 features=real_bag,original_nature,effective_nature,savev2`.

## Recibos originales de la CI global V3

- `SHOWDOWN_TRANSACTIONS PASS 10`.
- `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3`.
- `IA6_INTEGRATION PASS checks=65 features=mint_effective_nature,escape_rope_bag_savev2`.
- `IA6_MINT_FIELD_SAVE PASS checks=18 features=real_bag,original_nature,effective_nature,savev2`.
- `W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=88`.
- `IA6_BOOK_BAG PASS checks=20 features=real_bag,w05_panel,one_teach,savev2`.
- `PROGRESSION_ITEMS_V18 PASS checks=8755 cases=4304 GPU=false`.
- `ITEM_CONNECTIONS PASS checks=4993 equip=624 evolutions=72 machines=229`.

**No sumar recuentos como casos únicos de juego**: algunos son verificaciones solapadas. Estos recibos corresponden al mismo SHA y job.

## Decisiones técnicas recientes IA6

- [Autorización restringida W03 repelentes L3](CAMPAIGN_006_W03_BLOCK03_REPEL_L3_WORLD_SEAM_AUTH_20261109.md): W03 puede modificar únicamente los métodos enumerados de `field_demo.gd`, `field_native_bridge.gd`, FieldItemBag y helper en su propia rama; IA6 fija avance del RNG al `next_rng` del encuentro suprimido, **sin** sumar batalla/semilla, world.repel versionado en payload existente, strict validation y guardados antiguos válidos. Pendiente CI W03; no es L3 ya certificado.
- [Contrato EXP Share](IA6_EXP_SHARE_PARTICIPATION_CONTRACT_20261109.md): permanece L1 por falta de participantes reales; no sumar XP duplicada.
- W04 sexo/día/luna e intercambio a nivel siguen sin productores o política; no inventar niveles o fase lunar.

## Límites estrictos

Todas las escrituras IA6 de producción están exclusivamente en `codex/calvo-ia6-integration-20261109`. No hubo merge a `main`, V28 ni PR118; ramas W01–W05 intactas. Las CI de campañas completas W01/W02 aún requieren puerta consolidada en el árbol mixto antes de aceptación general, así como revisión visual GPU. El panel de libros cuenta con pruebas de montaje real en demo para un caso representativo, no 229 pruebas de UI independientes. No declarar completada la campaña de repelentes ni el catálogo total.

**Para continuar:** revisar respuesta de W03 al gate, decidir productores de evolución W04 y montar integración selectiva adicional únicamente tras regresiones globales. Este acta V3 sustituye V2 como referencia última sin borrar sus evidencias.
