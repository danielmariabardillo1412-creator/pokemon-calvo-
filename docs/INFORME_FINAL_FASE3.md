# INFORME FINAL — FASE 3: Publicación de Foundation + Contrato de Datos e Importador V1

Fecha: 2026-08-29
Motor: Godot 4.7 stable (`4.7.stable.official.5b4e0cb0f`)
Rama entregada: `feature/data-pipeline-v1` (publicada en remote)

## 1. FOUNDATION PUBLICADA

- **SÍ.** La rama `foundation/core-v1` se publicó en remoto (push exit 0) en la fase
  previa, con 13 PASS / 0 FAIL y 0 autoloads. Esta FASE 3 parte de ella.

## 2. CONTRATO DE DATOS Y FORMATO

- **Formato canónico: JSON** + `DatasetManifest` versionado (ADR-002).
- `DatasetManifest`: `schema_version` (1), `dataset_version` (semver), `source`,
  `ruleset` (`foundation_v1`), `provenance` (origen + licencia). Cada dataset es
  reproducible y auditado — requisito para datos de terceros.
- Alternativas descartadas para V1: `.tres` masivo, CSV puro, SQL, Resource de
  autoría. Para volumen masivo futuro se admitirá JSONL/CSV como **fuente cruda**
  con un adaptador que normalice al mismo `Dictionary` de entrada.

## 3. IDENTIFICADORES (IDs)

- Slug estable `^[a-z0-9_]+$`, namespaced por catálogo, **sin prefijo**
  (`fire`, `poison`, no `type:fire`) para no romper los 13 tests de Foundation.
- Validados por `DataValidator.is_valid_id`. ID mal formado o duplicado ⇒ RECHAZADO.
- Un ID publicado no se reutiliza; renombrar exige migración.

## 4. MANIFIESTO / VERSIONADO

- `DatasetManifest.from_dict` / `is_valid()`. El importador exige manifiesto válido.

## 5. IMPORTADOR VALIDADO

- `DataImporter.import_dataset(raw, manifest) -> { game_data, report }`.
- Valida: ID bien formado, **unicidad**, stats base 1..255, y referencias
  (tipo / habilidad / movimiento / evolución). Toda rotura RECHAZA la definición
  (nunca se inyecta a medias).
- `DataImportReport`: conteos, `rejected[]`, `broken_references[]`,
  `unsupported_mechanics[]`, `issues[]`, `to_text()`.

## 6. CATÁLOGOS

- Catálogos enfocados inyectables: `SpeciesCatalog`, `MoveCatalog`, `TypeCatalog`,
  `AbilityCatalog`, `ItemCatalog`, `StatusCatalog` (todos `RefCounted`).
- `GameData`: agregado de los 6 catálogos + manifiesto, con `to_dict`/`from_dict`
  (round-trip probado) y `to_definition_catalog()`.
- `DefinitionCatalog`: **fachada** `RefCounted` que conserva la API de batalla
  (`species/move/type/status/type_multiplier`) sobre los catálogos enfocados.
- **0 autoloads** (sin cambios vs Foundation). `DamageCalculator` corregido para
  efectividad tipo atacante→defensor y STAB dual-type.

## 7. TESTS

- **26 PASS / 0 FAIL** en Godot 4.7 headless (13 Foundation + 12 pipeline de datos).
- Cubren: manifiesto válido/inválido, IDs únicos, lookup especie/movimiento/tipo,
  referencia rota de tipo/movimiento/evolución, definición inmutable, instancia
  referencia especie, round-trip JSON, y una **batalla real importada** desde el dataset.

## 8. ESTRUCTURA DE DATOS

- `data/{raw, manifests, normalized, fixtures, generated, reports}`.
- Versionado en git: `raw/`, `manifests/`, `normalized/`, `fixtures/`.
- Regenerable (`.gitignore`): `generated/` (artefactos derivados) y `reports/`.
- Fixtures entregados: `data/fixtures/starter_dataset.json` (7 especies + evoluciones,
  movimientos, tipos, habilidades, objeto, estado) y `data/manifests/starter_manifest.json`.

## 9. COMMITS

- 8 commits lógicos en `feature/data-pipeline-v1`:
  1. `data: añadir identificadores de dominio estables y to_dict/from_dict`
  2. `data: añadir manifiesto versionado y validacion de dataset`
  3. `data: añadir catalogos enfocados inyectables y agregado GameData`
  4. `data: añadir importador validado que rechaza datos invalidos`
  5. `battle: refactorizar DefinitionCatalog como fachada y corregir efectividad dual-type`
  6. `data: añadir fixtures starter y zonas de datos versionadas`
  7. `tests: validar el pipeline canonico de datos (12 nuevos)`
  8. `docs: documentar arquitectura de datos y ADR-002 del pipeline`
- Push a `origin/feature/data-pipeline-v1`: **OK (new branch)**.
- PR: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/new/feature/data-pipeline-v1

## 10. RIESGOS / NOTAS

- JSON puede inflarse con miles de entradas → mitigado con fuente cruda aparte +
  normalizado; no se importó PokéAPI todavía.
- Esquema de IDs sin prefijo depende de la disciplina de catálogo (documentado).
- `extends Node` fuera de `tests/`: 0. Código/recursos externos incorporados: 0.

## 11. ¿PREPARADO PARA IMPORTACIÓN MASIVA?

- **SÍ.** El mismo `DataImporter` escala; solo falta una fuente cruda (PokéAPI/
  CSV/JSONL) y un adaptador al `Dictionary` de entrada. El dominio de combate no
  cambia (sigue consumiendo `DefinitionCatalog`).

## 12. SIGUIENTE PASO (requiere autorización)

- Autorizar la importación masiva (fuente + mapeo) o construir la UI/herramienta de
  importación. No mezclar en `main` sin revisión.
