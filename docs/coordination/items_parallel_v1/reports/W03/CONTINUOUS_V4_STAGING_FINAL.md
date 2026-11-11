# IA3/W03 — CONTINUOUS V4 STAGING · ENTREGA SELECTIVA NATIVA / BLOQUEOS PROTEGIDOS

**Fecha:** 2026-11-11. **Rama staging exclusiva:** `codex/calvo-ia6-staging-20261111-w03-capture`.
**Base fija IA6:** `e63b2e6c7e175fba318cc2f562bebd1769589092`.
**Origen W03 V3:** `ef63e824069aa27ce957e99997df8e7a50c78524`, CI histórica #42958535816 SUCCESS.
**Código staging certificado:** `0cb612cd548ee47ff66fabf85472e64e10951a28`, [CI #42965463520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965463520), `completed/success`.

> **Nota de alcance irrenunciable:** esa CI valida el **recorrido nativo Showdown + coexistencia IA6**, y contiene un test **legacy realmente rojo** (`WildAdventureSession`) diagnosticado y marcado `BLOCKED_AUTHORIZATION_WILD_ADVENTURE_SESSION NOT_PASS`. No presentarla como una certificación sin fallos de todos los adaptadores. Esta rama **NO** es la rama integradora oficial de IA6.

## Resultado por fase de la orden V4

| Fase | Resultado |
|---|---|
| A — diff selectivo de fuente W03 frente a base IA6 | **COMPLETADA**; sólo se portaron piezas faltantes |
| B — captura real Showdown, owner, stock, RNG, almacenamiento y SaveV2 | **PASS** en staging, incluida coexistencia de menta/rope/libros |
| C — CI y entrega de dependencias | **COMPLETADA para la ruta nativa**, **BLOQUEADA para regresión completa** por adaptador `WildAdventureSession` no autorizado y repelentes fuera de ámbito |
| Objetos nuevos de inventario | **0** |
| Funcionalidades efectivamente incorporadas en ensayo | Repeat (historial auténtico) y Moon (EvolutionRecord); Net ya presente en base IA6 |
| Integración oficial IA6 | **NO**, rama `codex/calvo-ia6-integration-20261109` sin tocar |
| Estado de cesión | `READY_FOR_IA6_REVIEW_NATIVE_ONLY / BLOCKED_SHARED_SEAMS`, **NO READY_FOR_FULL_MERGE** |

### Hunk por archivo: exactamente lo que falta en base y se incorporó en staging

| Archivo | Cambio localizado | Garantía |
|---|---|---|
| `modules/capture/caught_species_history_w03.gd` | Helper nuevo de canonicalización de especie base, ordenación, duplicados y parse de historial | No deriva historial de equipo ni caja |
| `modules/capture/capture_source_w03_v3.gd` | Helper nuevo, fuente Moon `EvolutionRecord` + `moon_stone`/trigger/target/version | Sin fabricar origen de mundo |
| `modules/creatures/storage/player_collection.gd` | Campo `caught_base_species_ids`, métodos `has_previously_caught` y `record_successful_capture` | Depósito/retiro/roster sin cambios |
| `modules/capture/capture_battle_context.gd` | Campos aditivos de Repeat y autenticación Moon | RNG y contexto anterior intactos |
| `modules/capture/capture_context_ball_effects.gd` | Registro Repeat y Moon; 3,5× al repetir especie base, 4× Moon auténtica, 1× control | Quick/Timer/Level intactas |
| `modules/gameplay/showdown_adventure_session.gd::capture` | Lee historial del propietario antes de resolver, proyecta Moon sólo en esa bola, registra captura **tras** commit real | `_finish`, RNG, inventario, otras bolas y motor JS sin cambios |
| `modules/save/save_game_data.gd` | Campo opcional y esquema de historial, `to_dict/from_dict/build/validate` | SaveV2 antiguo sin campo conserva historial vacío, sin reescribir |
| `modules/save/save_game_repository.gd` | `save_collection` toma ledger y `decode_snapshot` lo recupera transaccionalmente | `save_state` mantiene firma anterior y valor histórico vacío |
| `modules/save/load_result.gd` | Único campo transportador `caught_base_species_ids` | Aditivo; IA6 debe revisar esta seam de dato |
| `modules/save/field_native_save.gd` | `write/decode` del historial, valida origen del catálogo | `_valid_creature` de IA6 **intacto**, incluidas mentas/naturaleza efectiva |
| `modules/capture/capture_ruleset.gd` | **Sin modificación directa**; enumera automáticamente los dos IDs registrados en `ContextBallEffects` | Evita sobrescribir otras reglas |
| `modules/capture/capture_ball_effects.gd` | **Sin modificación**, Net ×3,5 existente en base | No se acredita como efecto nuevo W03 V4 |

Las pruebas históricas W03 copiadas son **archivos de tests propios**, no sustituciones de producción compartida. Se añadieron `tests/tools/test_ia6_w03_staging_v4.py` y una CI independiente `.github/workflows/ia6-w03-v4-capture-staging.yml`.

### CI de staging — evidencias positivas (SHA exacto)

- **Guarda de hunk/política:** `IA6_W03_V4_PY PASS checks=34 protected=5 contextual=5 veto_dynamax=true`, con SHA de blob de `FieldItemBag`, `CreatureInstance`, `native_engine.cjs`, `FieldItemService` y `config/item_selection_v1.json` preservados. Caramelo Dinamax excluido; Rare Candy y Exp Candy **no** arrastrados al veto.
- **Auditoría canónica:** `W03_V3_SOURCE PASS checked=1082 moon=6 runtime_weight=0 ultra_fields=0`. Heavy/Beast continúan bloqueadas por productores ausentes, sin inventar whitelist.
- **SaveV2 clásico:** 40 PASS y adversarial 8 PASS.
- **Repeat Ball nativa:** `W03_REPEAT_NATIVE_V4 PASS checks=26`, `W03_REPEAT_NATIVE_V4_NEG PASS checks=18` — captura nativa y propietario, full Party/PC, historial de especie base, fallo/stock y SaveV2.
- **Net Ball nativa existente:** `W03_NET_NATIVE_V5 PASS checks=79`, negativos `W03_NET_NATIVE_V5_NEG PASS checks=19`. Agua/Bicho, consumo, owner y casos adversariales.
- **Moon Ball V3 integrada en staging:** `W03_V3_MOON PASS native=2 checks=41`, Clefairy ×4, Goldeen ×1, fallo RNG real, historial/SaveV2.
- **Coexistencia IA6:** `IA6_MINT_FIELD_SAVE PASS checks=18`; `IA6_INTEGRATION PASS checks=65 features=mint_effective_nature,escape_rope_bag_savev2`; `IA6_BOOK_BAG PASS checks=20 features=real_bag,w05_panel,one_teach,savev2`. Ningún cambio propio en mochila de libros.
- CI #42965463520 completó su job con **18 steps SUCCESS y 0 steps FAIL**. Ese recuento de pasos **no oculta** el test legacy rojo, registrado abajo.

### REGRESIÓN ROJA — no está resuelta, no contada como PASS

`tests/gameplay/parallel_items_w03_repeat_history_v2.gd` ejecutó su ruta antigua de `WildAdventureSession` y emitió `FAIL checks=37` con **seis aserciones** referentes a historial de primera captura, historial tras cargar, bono Repeat real y cierre. Esa ruta necesita tres cambios mínimos fuera de la autorización V4:

1. `WildAdventureSession.capture_current`: proyectar el ledger auténtico del propietario antes del lanzamiento.
2. Tras éxito y ownership reales en el mismo método, registrar especie base capturada; nunca en fallo ni fuera de dominio.
3. `WildAdventureSession.load_game`: restaurar `caught_base_species_ids` del `LoadResult` ya validado.

Ticket con evidencia exacta y autorización requerida: `docs/coordination/items_parallel_v1/CONTINUOUS_V4/W03_WILD_LEGACY_GAP.md`.

La CI deja intacto el test original, detecta **exactamente** la huella de esas seis aserciones fallidas, la publica como `BLOCKED_AUTHORIZATION_WILD_ADVENTURE_SESSION NOT_PASS` y sólo después ejecuta los casos Showdown. Esto sirve para certificar **la ruta nativa** sin fingir una puerta de regresión total. La entrada al merge oficial debe someterse al dictamen IA6 y a su propia CI, incluyendo la ruta legacy si sigue viva.

### SEGUNDA DEPENDENCIA PROTEGIDA — repelentes, libros y mundo

Diff comparado entre source `ef63e824` y base `e63b2e6c`: el `FieldItemBag` de IA6 contiene el panel `Abrir libro` de W05, pero carece del `_apply_repel` y el despacho de Repel/Súper/Máximo de W03; faltan igualmente el estado `_repel_effect`/SaveV2/RNG de campo en `field_demo.gd` y el `blocked_by_repel` de `field_native_bridge.gd`. La staging **no modificó** ningún archivo de mundo/mochila. Ticket separado:

`docs/coordination/items_parallel_v1/CONTINUOUS_V4/W03_REPEL_BAG_GAP.md`.

IA6 debe unir específicamente hunk de repelente + panel de libros + Cuerda Huida y ejecutar pruebas de coexistencia, sin hacer cherry-pick de clases completas. No contar repelentes como funcionalidad integradora V4.

## Restantes bloqueos y pruebas NO acreditadas

Heavy Ball (peso en hectogramos disponible en fuente raw, **no** en catálogo runtime) y Beast Ball (sin clasificación auténtica Ultraente) permanecen bloqueadas. También Dive/Dusk/Lure/Love por mundo y Safari/Sport parcialmente por zonas; Magikarp nivel 5 `move_policy` independiente. No se inventaron datos nuevos.

No se ejecutó la **totalidad** de los scripts históricos W03 CAMP003–006/T01–05 dentro de V4; sí se ejecutaron los casos nativos seleccionados Repeat/Net/Moon y SaveV2. Parte de la cobertura antigua de campo/repel depende de las seams protegidas pendientes. **No confundir cobertura nativa PASS con CI acumulativa completa V1–V3 de todos los subsistemas.**

## Acción concreta para IA6

**Revisar los nueve hunks de producción y el campo añadido en LoadResult; integrar selectivamente sólo tras CI propia.** Decidir explícitamente el permiso/estado de `WildAdventureSession` y resolver el ticket repelentes con W05 sin perder libro/rope/menta. Mantener veto `dynamax_candy`. Esta staging no toca `main`, V28, PR118, rama oficial ni otras W.

**Cierre honesto:** funcionalidad nativa Repeat/Moon trasladada y certificada sobre `0cb612cd`, Net conservada, compatibilidad IA6 menta/rope/libro PASS; **regresión legacy 6 FAIL conocida, repelentes no integrados, integración oficial IA6 NO**. Entrega `READY_FOR_IA6_REVIEW_NATIVE_ONLY`, **no** `READY_FOR_FULL_MERGE`.
