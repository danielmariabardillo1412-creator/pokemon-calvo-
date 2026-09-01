# DATA FOUNDATION V3 — contrato canónico final

Estado: **CERRADO / CERTIFICADO END-TO-END**.

Este documento describe el contrato técnico vigente de DATA FOUNDATION V3. Para el resumen operativo y las decisiones de cierre, consultar `docs/project_book/DATA_V3.md`.

## Certificación final

- PR final: #95 — `DATA V3 — final end-to-end certification`
- rama: `audit/data-v3-end-to-end-closure-v1`
- HEAD final certificado: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- estado: cerrado **sin merge**
- validación del HEAD final: **18/18 workflows SUCCESS**.

El engineering SHA del cierre fue:

`9e17f903f229b6efc0044608dde66aba4783ef9c`

con:

- DATA V3 domain: **567 PASS / 0 FAIL**
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**.

## Fuente inmutable

La autoridad fuente está versionada en:

- branch: `data/pokeapi-v2-snapshot`
- source commit: `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree: `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree: `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- licencia: BSD 3-Clause.

`data/api/v2` y `data/schema/v2` son **read-only**. Las correcciones se realizan en adaptadores, contratos runtime o tests; nunca modificando manualmente el snapshot para hacerlo encajar.

## Pipeline

```text
data/api/v2 + data/schema/v2
        |
        v
 tools/pokeapi_adapter_v3.py
        |
        +--> auditorías semánticas acotadas
        +--> data/raw/pokemon_api.json
        +--> data/manifests/pokemon_api_manifest.json
        +--> data/reports/*
        |
        v
 DataImporter (Godot)
        |
        v
 data/normalized/pokemon_api.json
        |
        v
 GameData / DefinitionCatalog / runtime
```

El pipeline separa tres afirmaciones distintas:

1. la fuente contiene un dato;
2. V3 preserva ese dato;
3. Battle Core puede ejecutar fielmente esa mecánica.

No se confunden entre sí.

## Contrato estructural congelado

| Entidad | Total |
|---|---:|
| Especies base | 1.025 |
| Formas detectadas | 326 |
| Tipos runtime | 18 |
| Movimientos runtime | 919 |
| Habilidades | 373 |
| Objetos | 2.222 |
| Entradas de learnset | 61.102 |
| Evoluciones preservadas | 554 |
| Referencias rotas | 0 |
| Definiciones rechazadas | 0 |

Además, **18 movimientos XD Shadow** permanecen en la fuente pero se excluyen explícitamente del catálogo runtime de 18 tipos estándar.

## Localización e IDs

Los IDs internos son estables, normalizados y no dependen del idioma de presentación.

Cuando PokéAPI proporciona nombres localizados, el adaptador prioriza:

`es → es-419 → en`

Los nombres visibles pueden por tanto estar en español sin renombrar IDs, romper saves o alterar referencias internas.

La disponibilidad de una traducción de nombre no implica que todos los `effect_entries` de PokéAPI tengan traducción española; la localización completa de textos de presentación es una capa separada del contrato canónico.

## Learnsets

V3 no une learnsets de todas las generaciones.

Cada Pokémon selecciona un único `version_group` convencional/mainline coherente mediante una prioridad explícita. Cada entrada preserva:

- `move_id`
- `method`
- `level`
- `order` cuando existe
- `version_group`.

Esto evita mezclar simultáneamente niveles y compatibilidades de generaciones diferentes.

## Especies y formas

La detección de formas no depende de que un nombre tenga guion.

La identidad base/variedad usa `pokemon-species.varieties` y `is_default`, evitando descartar especies legítimas como Mr. Mime, Ho-Oh o Porygon-Z por heurísticas de nombre.

Las 326 formas detectadas se preservan separadas del catálogo de 1.025 especies base.

## Frontera de movimientos

De los 919 movimientos runtime:

- **590 RUNTIME_SUPPORTED**
- **71 PARTIAL_RUNTIME**
- **246 DATA_ONLY**
- **12 UNSUPPORTED**.

Invariante crítica:

`DATA_ONLY` con `effect_specs` ejecutables = **0**.

Un movimiento preservado pero no representable fielmente no puede ejecutar silenciosamente una aproximación más débil solo para aumentar cobertura.

## Frontera de habilidades

De las 373 habilidades:

- **21 RUNTIME_SUPPORTED**
- **14 PARTIAL_RUNTIME**
- **338 DATA_ONLY**.

No existe mapping ejecutable oculto para habilidades `DATA_ONLY`.

La metadata de slots y `is_hidden` se preserva independientemente de si la mecánica de la habilidad tiene runtime completo.

## Frontera de objetos

Los 2.222 registros canónicos son metadata preservada, no 2.222 mecánicas implementadas.

Held items con runtime certificado:

- `leftovers`
- `sitrus_berry`.

Trainer bag con runtime certificado:

- `potion`
- `super_potion`
- `hyper_potion`
- `max_potion`
- `full_restore`.

Contrato Calvo V1 de curación:

- 20
- 60
- 120
- full
- full + status.

Textos históricos de PokéAPI con valores 50/200 para Super/Hyper Potion son metadata histórica y **no redefinen** la ejecución 60/120 del ruleset del proyecto.

## Frontera de evoluciones

De 554 evoluciones preservadas:

- **391 RUNTIME_SUPPORTED**
- **0 PARTIAL_RUNTIME**
- **149 DATA_ONLY**
- **14 UNSUPPORTED**.

Se conservan exactamente **165 registros condicionados**.

Las condiciones no soportadas —amistad, hora, género, movimiento conocido, held item de intercambio, forma/región/localización, lluvia, estado de party y otras— no pueden degradarse silenciosamente a una evolución más débil por nivel, item o trade.

Solo siete selectores redundantes `base_form == current source species` permanecen ejecutables porque no cambian materialmente la condición.

## Cierre end-to-end

La suite final congela diez grupos de invariantes:

1. totales estructurales exactos;
2. procedencia fuente exacta;
3. igualdad de conjuntos de identidad raw ↔ normalized;
4. cierre de referencias cruzadas y totales de learnsets/evoluciones;
5. frontera Moves;
6. frontera Abilities;
7. frontera Evolutions y no ejecución conditioned DATA_ONLY;
8. superficies runtime exactas de Items;
9. ausencia de ejecución oculta DATA_ONLY en moves/abilities;
10. exclusión Shadow y totales de reportes.

La comparación de artefactos entre el cierre anterior y el engineering final demostró ausencia de deriva canónica: raw, normalized, manifest y reportes esenciales permanecieron byte-identical; las diferencias fueron únicamente los nuevos checks, registro de la clase de test y tiempos de importación.

## Regla de reapertura

DATA V3 no se reabre para subir porcentajes o perseguir un 100% nominal.

Un dominio se reabre cuando exista una causa concreta:

- regresión real;
- una nueva capacidad de Battle Core elimina un blocker documentado;
- cambio deliberado de fuente/provenance;
- necesidad concreta del juego que exige ampliar una frontera actualmente diferida.

Hasta entonces, `b4f6adc2...` es la base DATA V3 cerrada sobre la que deben evolucionar los demás sistemas.
