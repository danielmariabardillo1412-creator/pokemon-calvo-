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


