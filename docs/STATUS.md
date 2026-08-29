# Foundation V1 status

Fecha de validación: 2026-08-29  
Rama: `foundation/core-v1`  
Motor: `4.7.stable.official.5b4e0cb0f`

## Resultado

- Arquitectura auditada: **VALIDADA CON CAMBIOS**
- Importación/editor Godot 4.7: **PASS**, exit 0, sin errores de parseo
- Ejecución headless: **PASS**, exit 0
- Tests: **13 PASS / 0 FAIL**
- Battle minimal: **PASS**
- RNG determinista y empate de velocidad: **PASS**
- Snapshot JSON y restauración: **PASS**
- Autoloads: **0**
- Código/recursos externos incorporados: **0**

## Cobertura demostrada

- Definiciones de especie, tipo, movimiento y status como Resource
- Instancia mutable y estadísticas como RefCounted
- prioridad y velocidad
- daño, STAB y efectividad
- KO y final de combate
- Poison aislado en `StatusSystem`
- mismos seed/acciones producen mismos eventos y snapshot
- `BattleEvent` consumible por presentación
- snapshot con esquema, ruleset, algoritmo/estado RNG e IDs estables
- rechazo autoritativo de movimiento forjado sin mutación de HP/turno
- payload cliente sin daño, HP ni resultado

## Fuera de alcance

No hay networking, UI, mapas, assets, savegame general, captura,
party, inventario ni contenido Pokémon. No se debe iniciar la siguiente fase ni
mezclar esta rama en `main` sin autorización.

---

# Data pipeline V1 (post-Foundation)

Fecha de validación: 2026-08-29
Rama: `feature/data-pipeline-v1`
Motor: `4.7.stable.official.5b4e0cb0f`

## Resultado

- Importación/editor Godot 4.7: **PASS**, exit 0, sin errores de parseo
- Ejecución headless: **PASS**, exit 0
- Tests: **26 PASS / 0 FAIL** (13 Foundation + 12 pipeline de datos)
- Autoloads: **0** (sin cambios respecto a Foundation)
- `extends Node` fuera de `tests/`: **0**
- Código/recursos externos incorporados: **0**

## Qué se añadió

- Contrato de datos: `DatasetManifest` (esquema versionado + provenance).
- Validación: `DataValidator`, `DataValidationIssue`, `DataImportReport`.
- Importador: `DataImporter.import_dataset(raw, manifest) -> {game_data, report}`
  que RECHAZA IDs inválidos/duplicados, stats fuera de rango y referencias rotas.
- Definiciones estables: `AbilityDefinition`, `ItemDefinition`, `LearnSetEntry`,
  `EvolutionRecord`; `CreatureSpecies`/`MoveDefinition`/`TypeDefinition`/
  `StatusDefinition` ampliados con `to_dict`/`from_dict` y tipos duales.
- Catálogos enfocados inyectables + `GameData` (agregado con `to_dict`/`from_dict`
  y `to_definition_catalog()`).
- `DefinitionCatalog` Refactorizado a fachada sobre catálogos enfocados (misma API
  de batalla); `DamageCalculator` corregido para efectividad tipo atacante→defensor
  y STAB dual-type.
- Fixtures: `data/fixtures/starter_dataset.json` (7 especies + evoluciones,
  movimientos, tipos, habilidades, objeto, estado) y `data/manifests/starter_manifest.json`.
- Zonas de datos: `data/{raw,manifests,normalized,generated,fixtures,reports}`
  (`generated/` y `reports/` ignorados en git).

## Cobertura de datos demostrada

- manifiesto válido e inválido; IDs únicos; lookup especie/movimiento/tipo
- rechazo de referencia de tipo / movimiento / evolución rota
- definición inmutable; instancia referencia especie por ID
- round-trip JSON del dataset; batalla real importada desde el dataset

## Fuera de alcance de esta fase

No se importa PokéAPI ni datos masivos; no se crea UI de importación; no se mezcla
en `main`. El pipeline ya está listo para alimentar importación masiva cuando se
autorice (mismo `DataImporter`, distinta fuente cruda).

Informe final de FASE 3: `docs/INFORME_FINAL_FASE3.md`.

---

# FASE 4 — Importación masiva PokéAPI (+ QA 4.1)

Fecha de validación: 2026-08-29
Rama: `feature/pokemon-data-import-v1`
Motor: `4.7.stable.official.5b4e0cb0f`
Fuente: PokéAPI `api-data` (SHA completo `784c50b3ad27d0390d3b047fc4c4511f71edd049`, **BSD 3-Clause**)
IP Pokémon: Nintendo/Creatures/Game Freak (la licencia BSD no otorga derechos sobre esa IP).

## Resultado

- Importación/editor Godot 4.7: **PASS**, exit 0, sin errores de parseo
- Ejecución headless: **PASS**, exit 0
- Tests: **61 PASS / 0 FAIL** (26 FASE 1-3 + 14 import masivo FASE 4 + 21 invariantes QA FASE 4.1)
- Autoloads: **0** (sin cambios respecto a Foundation)
- `extends Node` fuera de `tests/`: **0**
- Referencias rotas: **0** · Rechazados: **0** · Tiempo de import: **~927 ms**

## Volumen importado

- 986 especies base · 39 formas diferidas · 21 tipos
- 937 movimientos (DATA_READY 937; RUNTIME_SUPPORTED 76 / PARTIAL_RUNTIME 504 / DATA_ONLY 348 / UNSUPPORTED 9)
- 373 habilidades (DATA_ONLY) · 2222 objetos (DATA_ONLY)
- 129390 entradas de learnset
- Evoluciones: SOURCE_EDGES 484 · IMPORTED_EDGES 476 · DEFERRED_FORM_EDGES 8 · REJECTED 0
  - Cobertura importada: SUPPORTED_RUNTIME_OR_MODEL 388 / PARTIAL_RUNTIME 52 / UNSUPPORTED 36 (suma 476)
- 0 status conditions (ausentes en el commit fijado de la fuente)

## Qué se añadió / corrigió

- `tools/pokeapi_adapter.py`: lee la fuente api-data y produce raw + manifest + reports.
- `tools/run_import.gd`: import headless vía `DataImporter` (writes import_summary + normalized).
- Dataset canónico: `data/raw/pokemon_api.json`, `data/manifests/pokemon_api_manifest.json`,
  `data/normalized/pokemon_api.json`.
- Extensión de dominio solo-datos: `base_special_attack`/`base_special_defense` en
  `CreatureSpecies`; `damage_class`/`accuracy`/`pp`/`target`/`effect_summary`/`classification`
  en `MoveDefinition`; `effect_summary`/`classification` en `AbilityDefinition`; `method` en
  `LearnSetEntry`; `item_id` en `EvolutionRecord`. `DataImporter` lee los nuevos campos.
- Corrección FASE 4: `Catalog.all_ids()` devuelve `Array[StringName]` tipado (elimina SCRIPT ERROR).
- QA FASE 4.1: licencia corregida (BSD 3-Clause), SHA completo en manifest, cobertura de evoluciones
  recalculada sobre aristas importadas (suma = 476), terminología honesta DATA_READY/RUNTIME_SUPPORTED/
  PARTIAL_RUNTIME/DATA_ONLY/UNSUPPORTED, e invariantes de métricas en tests.
- Docs: `docs/DATA_SOURCES.md`, `docs/MECHANICS_COVERAGE.md`, `docs/CODEX_BATTLE_V2_HANDOFF.md`.

## Listo para Battle Core V2

SÍ. La capa de datos está completa, referencialmente sana y validada por invariantes; Battle Core V2
puede consumir `MoveDefinition`/`AbilityDefinition`/`ItemDefinition`/`EvolutionRecord` sin nuevo import.
NO se modificó el Battle existente (StatBlock/DamageCalculator intactos). NO se hizo merge a `main`.

Informe final de FASE 4: `docs/INFORME_FINAL_FASE4.md`. Handoff Codex: `docs/CODEX_BATTLE_V2_HANDOFF.md`.

---

# Battle Core V2

Fecha de validación: 2026-08-29
Rama: `feature/battle-core-v2`
Motor: `4.7.stable.official.5b4e0cb0f`

## Resultado

- Godot import/headless: **PASS**, sin errores de parseo/runtime, exit 0
- Tests: **131 PASS / 0 FAIL** (61 previos + 70 V2)
- Snapshot: schema **2**, ruleset `calvo_v1`, RNG `lcg32_v1`
- Autoloads: **0**
- `extends Node` fuera de tests: **0**
- `effect_summary` usado para gameplay: **0**

## Runtime añadido

- Effects compuestos + mappings explícitos por stable ID
- Pipeline determinista de phases y triggers
- PP runtime, siete stat stages, accuracy/evasion y críticos
- Daño physical/special, STAB, dual type, inmunidad y burn
- Poison, badly poisoned, burn, paralysis y sleep; freeze parcial
- Parties, active combatant, switch voluntario y reemplazo tras KO
- Abilities: intimidate, levitate, blaze, torrent, overgrow, static
- Held items: leftovers, sitrus_berry
- Eventos semánticos sin texto de UI
- Golden scenarios y continuación exacta desde snapshot

## Cobertura honesta

- Moves: RUNTIME_SUPPORTED 91 / PARTIAL_RUNTIME 496 / DATA_ONLY 341 / UNSUPPORTED 9
- Abilities: RUNTIME_SUPPORTED 6 / DATA_ONLY 367
- Items: RUNTIME_SUPPORTED 2 / DATA_ONLY 2220

No se implementaron evolución, forms, capture, XP, level progression, inventario,
UI, networking, overworld ni mecánicas generacionales especiales.

---

# FASE 5 — Move effects as structured data

Fecha de validación: 2026-08-29
Rama: `feature/battle-effects-data-v1` (creada desde `feature/battle-core-v2`)
Motor: `4.7.stable.official.5b4e0cb0f`
Fuente: PokéAPI `api-data` (SHA completo `784c50b3ad27d0390d3b047fc4c4511f71edd049`, BSD 3-Clause)

## Resultado

- Godot import/headless: **PASS**, sin errores de parseo/runtime, exit 0
- Tests: **137 PASS / 0 FAIL** (131 base + 6 nuevos FASE 5)
- Snapshot: schema **2**; dataset schema_version **2**; `BattleEffectSpec` V1
- Autoloads: **0**
- `extends Node` fuera de tests: **0**
- Importador: referencias rotas **0**, rechazados **0**, `effect_spec_invalid` **0**
- Determinismo headless: **PASS** (mismos seed/acciones ⇒ mismos eventos y snapshot)

## Qué se añadió

- `BattleEffectSpec`: kind `MULTI_HIT` + `min_hits/max_hits/min_turns/max_turns`; `to_dict`/`from_dict`.
- `MoveDefinition`: `effect_specs: Array[BattleEffectSpec]`, `crit_rate_bp`, `makes_contact`.
- `tools/pokeapi_adapter.py`: genera `effect_specs` desde metadata estructurada (status, stat changes,
  drain/recoil/heal, flinch, multi-hit, crit), bump schema_version → 2, y `data/reports/battle_effect_specs_summary.json`.
- `tools/move_flags_override.json`: override de contacto (la fuente no trae flags).
- `BattleEffectRegistry.effects_for_move`: prefiere specs del dataset; salta DAMAGE implícito si hay MULTI_HIT.
- `BattleEffectExecutor`: maneja `MULTI_HIT` (daño por golpe + recoil/drain por golpe).
- `DamageCalculator`: `crit_rate_bp` suma al umbral de crítico.
- `BattleTriggerSystem` + `Static`: `requires_contact` (corregido desde `requires_physical`).
- `DataImporter`: validación fuerte de `effect_specs` (rechaza specs rotos; issues en reporte).
- Tests: `pokeapi_effect_specs_integrity`, `fase5_multi_hit`, `fase5_static_contact`.
- Docs: `docs/ARCHITECTURE_DECISION_004_EFFECT_DATA.md`, `docs/MOVE_EFFECT_COVERAGE.md`.

## Cobertura honesta (937 movimientos)

- `RUNTIME_SUPPORTED`: **541** (antes 376 / contrato V2 previo 91)
- `PARTIAL_RUNTIME`: 60 · `DATA_ONLY`: 327 · `UNSUPPORTED`: 9
- `effect_specs_generated`: 352 movimientos · `generated_by_metadata`: 433 specs · `validation_errors`: 0
- Multi-hit: IMPLEMENTADO · Contact/Static: CORREGIDO (override) · Protect: DIFERIDO · Ruleset fingerprint: DIFERIDO

## Listo para Progression Core

SÍ (sujeto a revisión). La capa de efectos de movimiento está data-driven y validada; el Battle Core
no se rediseñó y los 131 tests base siguen en verde. NO se hizo merge a `main`.

---

# FASE 6 — Progression Core V1

Fecha de validación: 2026-08-29
Rama: `feature/progression-core-v1` (creada desde `feature/battle-effects-data-v1`, commit `f89725c`)
Motor: `4.7.stable.official.5b4e0cb0f`
Fuente: PokéAPI `api-data` (SHA `784c50b3ad27d0390d3b047fc4c4511f71edd049`, BSD 3-Clause)

## Resultado

- Godot import/headless: **PASS**, sin errores de parseo/runtime, exit 0
- Tests: **208 PASS / 0 FAIL** (137 base + 71 checks de Progression Core)
- Autoloads: **0** (sin cambios)
- `extends Node` fuera de tests: **0**
- Referencias rotas: **0** · Rechazados: **0**
- Determinismo headless: **PASS** (mismos seed/acciones ⇒ mismos eventos y snapshot)
- `schema_version`: **2** (sin bump; `growth_rate`/`ev_yield` son campos aditivos)

## Qué se añadió

### Runtime (lógica de progresión, separada de Battle y UI)
- `modules/creatures/progression/progression_ruleset.gd` — `calvo_progression_v1`:
  - 6 curvas de XP: `fast`, `medium`, `medium-slow`, `slow`, `erratic`, `fluctuating`
    (`E(1)=0`; para n≥2 `E(n)=max(0, floor(raw(n)))`; cache por species_id+nivel).
  - Límites: `MAX_LEVEL=100`, `MOVE_SLOTS_MAX=4`, `MAX_PARTY=6`, `MAX_EV_TOTAL=508`.
  - Tabla de naturalezas canónica (25) con multiplicadores 1.1 suben / 0.9 bajan / 1.0 neutras.
  - `experience_for_level`, `level_for_experience` (búsqueda monotónica), `experience_for_defeats`.
- `modules/creatures/progression/stat_calculator.gd` — `compute(base, ivs, evs, nature_id, level)`:
  - HP = `(2·base + iv + ev/4)·level/100 + level + 10`
  - Resto = `(2·base + iv + ev/4)·level/100 + 5`, luego `× nature_mult`.
- `modules/creatures/progression/learnset_system.gd` — `initial_moves`, `level_up_moves_between`,
  `moves_learned_at_level` (lee `CreatureSpecies.learnset`).
- `modules/creatures/progression/evolution_system.gd` — `classify_record`, `evolution_candidates`,
  `apply_evolution`, `coverage_report` (ver `docs/EVOLUTION_COVERAGE.md`).
- `modules/creatures/progression/creature_factory.gd` — `create(...)` determinista
  (stats recalculados, moveset inicial, PP, IVs aleatorias con seed).
- `modules/creatures/progression/progression_event.gd` — eventos semánticos
  (`LEVEL_UP`, `STAT_CHANGED`, `MOVE_LEARNED`, `MOVE_LEARN_CHOICE_REQUIRED`,
  `EVOLUTION_AVAILABLE`, `EXPERIENCE_GAINED`).
- `modules/creatures/progression/progression_system.gd` — orquesta
  `gain_experience`, `apply_move_choice` (LEARN/REPLACE/DECLINE), `apply_evolution`,
  `reconcile_battle_result` (consume `BattleOutcome`).
- `modules/battle/domain/battle_outcome.gd` — `BattleOutcome.from_battle_state(state, catalogs)`:
  contrato puro (RefCounted) entre Battle y Progression. El Battle EMITE el resultado; la Progresión
  lo CONSUME después (sin acoplar la capa de batalla a la de progresión).

### Dominio extendido (sin romper compatibilidad)
- `CreatureSpecies`: nuevos `growth_rate: String`, `ev_yield: Dictionary`,
  `base_stat_block()` + `to_dict`/`from_dict`.
- `CreatureInstance` (fuente de verdad mutable y persistente): nuevos `experience`, `ivs`, `evs`,
  `nature_id`, `friendship`, `moveset: Array[BattleMoveSlot]`; `recalculate_stats`,
  `add_move`/`replace_move`/`has_move`/`initialize_move_pp`, `reconcile_post_battle`
  (solo status volátiles; clamp HP/PP), `to_dict`/`from_dict` (round-trip JSON estable).
- `DataImporter.SPECIES_KEYS` extendido con `growth_rate`, `ev_yield`.
- `StatBlock.duplicate()` añadido (RefCounted sin `duplicate` nativo).

### Datos (adapter corregido)
- `tools/pokeapi_adapter.py`:
  - `growth_rate` desde `pokemon-species` (ej. bulbasaur = `medium-slow`).
  - `base_experience` desde el endpoint **`pokemon`** (no `pokemon-species`; corregido — antes
    leía `pokemon-species` y producía `0`).
  - `ev_yield` desde `pokemon` → `effort` mapeado a claves de stat.
- Re-importado: 986 especies · 476 evoluciones · 0 referencias rotas.

## Contrato de separación (FASE 6)
- **0 autoloads**; `extends Node` solo en `tests/`.
- `CreatureSpecies` inmutable (definición) vs `CreatureInstance` mutable (estado/identidad `instance_id`).
- Battle Core muta la MISMA `CreatureInstance` en sitio (HP, `status_state`, `moveset.current_pp`);
  Progression Core lee/escribe nivel/XP/IV/EV/naturaleza y recalcula `stats`.
- NO se rediseñó el Battle Core; NO se creó UI; NO se hizo merge a `main`.

## Cobertura honesta — Evoluciones (476 aristas importadas)

| Coverage | Count | Detail |
|---|---|---|
| `RUNTIME_SUPPORTED` | 464 | level-up 388, trade 24, use-item 52 (ejecutable en runtime + test) |
| `DATA_ONLY` | 9 | trigger especial preservado como dato diferido (p.ej. `three_defeated_bisharp`, `use_move` annihilape) |
| `UNSUPPORTED` | 3 | trigger sin modelo (`other`, `shed`, `spin`); diferido |
| `PARTIAL` | 0 | — |
| **TOTAL** | **476** | 464 + 9 + 3 = 476 ✓ |

Detalle: `docs/EVOLUTION_COVERAGE.md` + `docs/PROGRESSION_DATA_AUDIT.md`.

## Listo para la siguiente fase

SÍ (sujeto a revisión). La progresión es data-driven, determinista y validada por 71 checks;
el Battle Core no cambió (los 137 tests base siguen en verde). NO se hizo merge a `main`.
Falta (fuera de alcance de FASE 6): UI de elección de movimiento/evolución, persistencia de
savegame/party, formas (39 diferidas), captura, y runtime de los 12 triggers especiales de evolución.

# FASE 7 — Capture + Party Core V1

Fecha de validación: 2026-08-29
Rama: `feature/capture-party-v1` (creada desde `feature/progression-core-v1`)
Motor: `4.7.stable.official.5b4e0cb0f`
Fuente: PokéAPI `api-data` (SHA `784c50b3ad27d0390d3b047fc4c4511f71edd049`, BSD 3-Clause)

## Resultado

- Godot import/headless: **PASS**, sin errores de parseo/runtime, exit 0
- Tests: **286 PASS / 0 FAIL** (222 base + 64 nuevos de Party/Capture)
- Autoloads: **0** (sin cambios)
- `extends Node` fuera de tests: **0**
- Referencias rotas: **0** · Rechazados: **0**
- Determinismo headless: **PASS** (mismos seed ⇒ mismos resultados/eventos de captura)
- `schema_version`: **2** (sin bump; capture_rate/party son campos aditivos)

## Qué se añadió

### Party (persistente)
- `modules/creatures/party/party_ruleset.gd` — `PartyRuleset`: **única fuente de verdad** de
  `MAX_PARTY = 6`, `SCHEMA_VERSION = 2`, `is_valid()`. (`CaptureRuleset.MAX_PARTY` eliminado: el
  límite 6 vive solo aquí.)
- `modules/creatures/party/creature_party.gd` — `CreatureParty`: add/remove/swap/reorder/get/
  contains/size/is_full/is_empty/get_creatures/get_ordered_ids/get_active/to_dict/from_dict.
  Round-trip estable vía `CreatureInstance`.
  - `reorder(ids)` exige permutación EXACTA del roster (mismo tamaño, sin duplicados, sin ids
    desconocidos/ausentes); entrada inválida ⇒ `false` y `_order` inalterado.
  - `from_dict` deduplica `ordered_instance_ids` (primera ocurrencia válida), ignora ids inexistentes,
    añade criaturas ausentes y respeta `MAX_PARTY`; invariante `_order.size() == _by_id.size()`.

### Capture (puro, determinista)
- `modules/capture/capture_ball_definition.gd` — `CaptureBallDefinition` (ball_id/mult/guaranteed).
- `modules/capture/capture_ruleset.gd` — `CaptureRuleset` (`calvo_capture_v1`): tabla BALLS,
  STATUS_BONUS, `catch_probability`, `is_valid_capture_rate`.
- `modules/capture/capture_event.gd` — `CaptureEvent` (ATTEMPTED/SHAKE/FAILED/SUCCEEDED/
  REJECTED/PARTY_ADDED/STORAGE_REQUIRED).
- `modules/capture/capture_battle_context.gd` — `CaptureBattleContext` (frontera de servidor:
  is_wild/battle_finished/caller_trainer_id/target_owner_trainer_id/target_side_id).
- `modules/capture/capture_attempt.gd` — `CaptureAttempt` (target/ball_id/context; sin campo de éxito).
- `modules/capture/capture_result.gd` — `CaptureResult` (status/ball_id/target_id/probability/
  shake_count/consume_item/reason).
- `modules/capture/capture_disposition.gd` — `CaptureDisposition` (PARTY/STORAGE_REQUIRED/UNROUTED).
- `modules/capture/capture_resolution.gd` — `CaptureResolution` (result + captured + disposition + events).
- `modules/capture/capture_system.gd` — `CaptureSystem.resolve(attempt, rng, catalogs, party)`:
  valida, calcula `p`, consume RNG solo si no garantizada, muta party en éxito con espacio. `party == null`
  ⇒ éxito resuelto con disposición `UNROUTED` y SIN evento `PARTY_ADDED` (no afirma un add falso).

### Datos
- `CreatureSpecies.capture_rate: int = 0` + `to_dict`/`from_dict` + `is_valid_capture_rate()`.
- `DataImporter.SPECIES_KEYS` + `"capture_rate"`; `tools/pokeapi_adapter.py` lee `pokemon-species`.
- Re-importado: 986 especies · 0 referencias rotas.

## Regla de captura (calvo_capture_v1)

`p = (capture_rate/255) * ball_mult * status_mult * hp_factor`
`hp_factor = (3·max_hp − 2·current_hp)/(3·max_hp)`. Master Ball garantizada (sin RNG).
Balls: poke 1.0 / great 1.5 / ultra 2.0 / master garantizada. Bonus de status: sleep/freeze 2.0;
poison/burn/paralysis/badly_poisoned 1.5. Trainer siempre rechazado. Party llena ⇒ STORAGE_REQUIRED
(sin auto-reemplazo). Detalle: `CAPTURE_RULESET_CALVO_V1.md`, `CAPTURE_DATA_AUDIT.md`.

## Contrato de separación (FASE 7)

- **0 autoloads**; `extends Node` solo en `tests/`.
- Capture NO rediseña Battle ni Progression; lee HP/status de la `CreatureInstance` viva.
- Captura preserva identidad: `res.captured` es la MISMA `CreatureInstance` (IV/EV/naturaleza/
  ability/moveset/PP intactos). No se crea ni rerolla criatura.
- **Separación de responsabilidad, NO antiforgery**: `CaptureSystem` es lógica pura/determinista; el
  RNG se inyecta. La validación de que `target`/`context` vienen de estado confiable (frontera
  cliente/servidor) es responsabilidad de una capa superior cuando exista networking. `CaptureSystem`
  no afirma por sí mismo que el éxito "no se puede forjar".
- `capture_rate` importado de PokéAPI; multipliers de ball son tabla canónica del juego.

## Hotfix (invariantes, pre-FASE 8)

Corrige: `reorder` aceptaba duplicados; `from_dict` podía reconstruir `_order` con duplicados;
`CaptureRuleset.MAX_PARTY` duplicado (eliminado, `PartyRuleset` es única fuente); `CaptureSystem`
emitía `PARTY_ADDED` con `party == null` (ahora `UNROUTED`); y se corrigieron comentarios de
seguridad sobreclaimados + el test `capture_server_forged_impossible` renombrado a
`capture_non_guaranteed_not_auto_success` (no demuestra antiforgery). Tests añadidos: 11 nuevos
checks de invariantes (reorder duplicado, from_dict dedupe/consistencia/max-6, null-party). Total:
**308 PASS / 0 FAIL**. NO merge a `main`.

## Listo para la siguiente fase

SÍ (Storage + Save). La captura y la party están data-driven y validadas; el Battle y Progression
Core no cambiaron (los 222 tests base siguen en verde). NO se hizo merge a `main`.
Falta (fuera de alcance de FASE 7): Storage real (FASE 8), persistencia savegame, UI de captura/
party, y runtime de reemplazo automático en party llena (hoy solo señaliza STORAGE_REQUIRED).


