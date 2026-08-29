# ADR-002 — Formato de datos y esquema de IDs para el dataset

Fecha: 2026-08-29
Estado: **ACEPTADA**
Rama: `feature/data-pipeline-v1`
Depende de: ADR-001 (feature-first + hexagonal selectivo, 0 autoloads)

## Contexto

Foundation V1 probó el dominio de combate con `.tres` de editor y 13 tests. Para
datos masivos (objetivo: autoría escalable, validada y reproducible, y eventual
importación de fuentes de terceros) necesitábamos un contrato de datos canónico:
formato de autoría, esquema de IDs y un importador que valide y rechace lo inválido
sin tocar las reglas de combate.

## Decisiones

### 1. Formato canónico: JSON (+ manifiesto versionado)

- JSON es legible, diff-friendly, versionable y trivial de validar/regenerar en CI
  con GDScript 4.7 (`JSON.parse_string` / `JSON.stringify`). No requiere addons.
- El dataset va acompañado de `DatasetManifest` (`schema_version`, `dataset_version`,
  `source`, `ruleset`, `provenance`) para que cada import sea reproducible y auditado
  (origen + licencia), requisito clave al usar datos de terceros.
- Alternativas consideradas y descartadas para V1:
  - `.tres` masivo: incómodo de diff/revisión y acoplado al editor.
  - CSV puro: pobre para estructuras anidadas (learnset/evolutions).
  - SQL/DB: sobre-ingeniería hasta no tener volumen real.
  - GDScript `Resource` como formato de autoría: acopla autoría al editor.
- Para volumen masivo futuro se permitirá JSONL/CSV como **fuente cruda**; un
  adaptador los normaliza al mismo `Dictionary` de entrada del `DataImporter`. El
  formato canónico interno sigue siendo el JSON de `data/normalized`.

### 2. Esquema de IDs: slug estable, minúsculas, sin prefijo

- `^[a-z0-9_]+$`, namespaced implícitamente por catálogo (`fire` en `TypeCatalog`,
  no `type:fire`). Elegido para NO romper los 13 tests de Foundation que ya usan
  estos IDs. Queda documentado que un ID publicado no se reutiliza ni se renombra
  sin migración.
- No se adoptó el prefijo `type:`/`species:` (más auto-documentado) para evitar
  tocar la base de tests; se revisará si crece el riesgo de colisión entre catálogos.

### 3. Importador validado que RECHAZA, no silencia

- `DataImporter` valida ID bien formado, unicidad, stats 1..255 y referencias
  (tipo/habilidad/movimiento/evolución). Cualquier fallo RECHAZA esa definición y
  aparece en `DataImportReport.rejected`. Nunca se inyecta un dato a medias.
- Esto protege la integridad del `DefinitionCatalog` que consume el combate.

### 4. Catálogos enfocados + fachada de batalla, sin autoload

- Catálogos inyectables (`SpeciesCatalog`, `MoveCatalog`, `TypeCatalog`,
  `AbilityCatalog`, `ItemCatalog`, `StatusCatalog`) agregados en `GameData`.
- `DefinitionCatalog` es solo una fachada `RefCounted` que expone la API de batalla
  (`species/move/type/status/type_multiplier`) sobre esos catálogos. Se pasa
  explícitamente a `AuthoritativeBattleServer` / `DamageCalculator`. 0 autoloads.

### 5. Efectividad tipo: se consulta tipo atacante → defensor

- `TypeDefinition.multiplier_against(defender_type_id)` lee el mapa del TIPO
  ATACANTE. `DamageCalculator` itera los tipos DEFENSOR y multiplica. STAB vía
  `CreatureSpecies.has_type(move.type_id)`. Soporta dual-type. (Se corrigió un
  sentido invertido respecto a la refactorización inicial.)

## Consecuencias

- Positivas: datos desacoplados de reglas; import reproducible y auditado; mismo
  dominio para 7 o 1000 especies; round-trip JSON probado; frontera clara.
- Negativas / riesgos: JSON puede inflarse con miles de entradas (mitigado: fuente
  cruda aparte + normalizado); el esquema de IDs sin prefijo depende de la
  disciplina de catálogo.

## Validación

Implementado y verificado en Godot 4.7 headless: `DataImporter`, catálogos,
`GameData`, manifiesto y 12 tests nuevos de pipeline (total 26 PASS / 0 FAIL).
Fixtures en `data/fixtures/starter_dataset.json` + `data/manifests/starter_manifest.json`.
