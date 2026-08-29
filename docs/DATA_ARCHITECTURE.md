# Data architecture — canonical data contract & import pipeline

Status: implementado en `feature/data-pipeline-v1` (post-Foundation V1).
Motor: Godot 4.7 stable. Formato canónico: **JSON** (con manifiesto versionado).

## Principio rector

El dominio de combate NO sabe de dónde vienen los datos. Solo consume
`DefinitionCatalog` (y los catálogos enfocados). El formato de autoría
(JSON/CSV/SQL/API) vive detrás de un importador validado y reproducible, de modo
que cambiar la fuente no toca las reglas. Esto cumple ADR-001 (feature-first +
hexagonal selectivo) y la regla "0 autoloads / dependencias explícitas".

## Flujo

```text
data/raw/*.json  (fuente cruda, autoría humana o scrape)
        |
        v  DatasetManifest (schema_version, dataset_version, source, ruleset, provenance)
   DataImporter.import_dataset(raw, manifest)  ->  { game_data, report }
        |
        |  valida: id bien formado, único, stats 1..255, referencias (tipo/habilidad/movimiento/evolución)
        v
   Catalogs enfocados (SpeciesCatalog, MoveCatalog, TypeCatalog,
        AbilityCatalog, ItemCatalog, StatusCatalog)  ->  GameData
        |
        v  GameData.to_definition_catalog()
   DefinitionCatalog   (fachada de batalla: species/move/type/status/type_multiplier)
        |
        v  pasado explícitamente a AuthoritativeBattleServer / DamageCalculator
```

## Identificadores (IDs)

- Cadenas estables en minúsculas con `[a-z0-9_]+`: `embercub`, `fire`, `poison`,
  `potion`. No prefijados (`species:pikachu` NO) para no romper los 13 tests de
  Foundation; el namespace es implícito por catálogo.
- Validados por `DataValidator.is_valid_id`. Un ID mal formado o duplicado se
  RECHAZA (no se silencia).
- Un ID publicado no se reutiliza. Renombrarlo exige migración explícita.

## Formato canónico (JSON)

Cada archivo `data/raw/*.json` es un objeto con claves de lista:
`types`, `moves`, `abilities`, `items`, `statuses`, `species`. Ejemplo mínimo en
`data/fixtures/starter_dataset.json`. Convenciones:

- Tipos: `effectiveness` es un mapa `tipo_defensor -> multiplicador` (2.0 / 0.5 / 1.0).
  Se consulta sobre el TIPO ATACANTE contra el DEFENSOR (`type_multiplier(ataque, defensa)`).
- Especies: `types` (lista, 1-2) o `primary_type_id`/`secondary_type_id`. `learnset`
  es lista de `{level, move_id}`. `evolutions` es lista de `{species_id, min_level, trigger}`.
- Stats base en 1..255. Movimientos con `power`, `type_id`, `priority`.
- Habilidades/objetos/estados: campos escalares; `end_turn_max_hp_divisor` y
  `minimum_damage` para daño de estado.

Para volúmenes masivos (PokéAPI, miles de filas) el mismo `DataImporter` escala;
solo cambia la fuente cruda (CSV/JSONL) y se añade un adaptador que produzca el
mismo `Dictionary` de entrada. No se introduce otro patrón.

## Manifiesto / versionado

`DatasetManifest` lleva `schema_version` (1), `dataset_version` (semver), `source`,
`ruleset` (`foundation_v1`) y `provenance` (nombre, versión, url, licencia). El
importador exige manifiesto válido; así cada dataset es reproducible y auditado
(origen y licencia documentados, requisito para datos de terceros).

## Validación y reporte

`DataImporter` devuelve `DataImportReport` con:
- conteos: `species_imported`, `moves_imported`, `abilities_imported`,
  `items_imported`, `statuses_imported`, `evolutions_count`.
- `rejected: Array[String]` — "id (motivo)": `invalid_id`, `duplicate_id`,
  `invalid_stats`, `broken_type_reference`, `broken_ability_reference`,
  `broken_move_reference`, `broken_evolution_reference`, `build_error`.
- `broken_references: Array[String]` y `unsupported_mechanics: Array[String]`
  (mecánicas del JSON aún no soportadas por el dominio, p.ej. campos de más).
- `issues: Array[DataValidationIssue]` y `to_text()` para un informe legible.

Regla: toda referencia rota/ID inválido RECHAZA esa definición; el pipeline nunca
inyecta datos a medias.

## Serialización de catálogos (GameData)

`GameData` (agregado de los 6 catálogos + manifiesto) expone `to_dict()` /
`from_dict()`, de modo que un dataset importado se puede volcar a JSON canónico
(`data/normalized`) y recargar sin el importador (round-trip probado por test).
`GameData.to_definition_catalog()` construye la fachada de batalla.

## Dual-type y STAB

`CreatureSpecies.type_ids_resolved()` devuelve 1-2 `StringName`. `DamageCalculator`
multiplica la efectividad por cada tipo defensor y aplica STAB si
`has_type(move.type_id)`. Verificado con fuego↔planta/agua y el fixture starter.

## Qué versionar vs regenerar

- Versionado en git: `data/raw`, `data/fixtures`, `data/manifests`, `data/normalized`.
- Regenerable (en `.gitignore`): `data/generated` (artefactos Godot/.tres derivados)
  y `data/reports` (salida del importador).

## Tests

`tests/test_runner.gd` cubre el pipeline: manifiesto válido/inválido, IDs únicos,
lookup de especie/movimiento/tipo, referencia de tipo/movimiento/evolución rota,
definición inmutable, instancia referencia especie, round-trip y una batalla real
importada. 26 PASS / 0 FAIL en Godot 4.7 headless.

## Fronteras y autoloads

`DefinitionCatalog` y los catálogos enfocados son `RefCounted`, se construyen y se
pasan explícitamente (nunca autoload). `DataImporter` es `RefCounted` y no toca
`SceneTree`. El runner sigue siendo un `Node` de test headless, el único fuera de
`tests/`.
