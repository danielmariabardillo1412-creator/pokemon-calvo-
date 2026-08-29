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

