# ADR-009 — Savegame V2: inventario persistente y migración explícita

Estado: ACEPTADO / VALIDADO EN CI  
Fecha: 2026-08-29  
Rama: `feature/inventory-savegame-v2`

## Contexto

FASE 8 creó `calvo_save_v1`: registro canónico de `CreatureInstance` + layouts por referencia para Party y Storage, con carga transaccional y reemplazo protegido del fichero. FASE 9A añadió `PlayerInventory` y consumo real de Poké Balls, pero el inventario todavía no formaba parte del estado persistente.

Cambiar silenciosamente el significado de V1 habría hecho imposible distinguir saves antiguos de saves con inventario. También habría invitado a "reconstruir" objetos que nunca estuvieron registrados, creando estado ficticio.

## Decisión

### 1. Nuevo formato explícito

El save actual pasa a:

- `schema_version = 2`
- `format_id = calvo_save_v2`

Añade un único bloque top-level `inventory`, serializado mediante el contrato propio de `PlayerInventory`.

Party y Storage siguen siendo layouts de referencias; `creatures` sigue siendo el único registro canónico de criaturas. El inventario no se mezcla con ese registro porque es otro agregado de estado mutable.

### 2. `PlayerCollection` es el agregado de jugador

`PlayerCollection` contiene ahora:

- `party`
- `storage`
- `inventory`

`SaveGameRepository.save_collection()` persiste los tres componentes. El inventario no se acopla a `CaptureSystem`; FASE 9A mantiene la capa `CaptureInventoryService` por encima de la lógica pura de captura.

### 3. Migración V1 → V2 exacta y no heurística

`SaveGameMigration` reconoce únicamente el par histórico real:

- schema `1`
- format `calvo_save_v1`

La migración crea un V2 equivalente y añade **inventario vacío**.

No se intentan inferir Poké Balls u otros objetos a partir de capturas, Party, Storage, timestamps ni campos desconocidos. Un campo `inventory` inyectado dentro de un V1 tampoco se considera autoritativo: V1 nunca tuvo ese contrato.

Cualquier combinación desconocida, mezclada o futura se rechaza explícitamente.

### 4. Cargar no modifica el fichero

La migración ocurre en memoria. `load()` no reescribe automáticamente un save V1.

La siguiente operación explícita de guardado escribe V2 usando el reemplazo protegido ya validado en FASE 8C. Esto evita que una simple lectura sea destructiva y mantiene separadas lectura/migración de escritura.

### 5. Publicación transaccional ampliada

La carga reconstruye y valida primero:

1. inventario,
2. registro canónico de criaturas,
3. Party,
4. Storage.

Solo después publica `LoadResult.ok = true` y expone `party`, `storage` e `inventory`. Si cualquier parte falla, las tres salidas permanecen `null`.

`LoadResult.migrated_from_version` permite al caller saber si el estado vino de V1 sin alterar el fichero fuente.

## Invariantes

- Un V2 sin `inventory` es corrupto; no se interpreta como bolsa vacía.
- Inventario corrupto no puede producir estado parcial.
- V1 válido puede cargarse sin perder Party/Storage/criaturas.
- La migración V1 no inventa recursos.
- La carga V1 no reescribe el archivo.
- Un guardado posterior a la migración produce V2.
- Saves futuros o formatos desconocidos no se adivinan.
- El mecanismo de `tmp`/`bak` y preservación del último save bueno de FASE 8C permanece intacto.

## Alternativas rechazadas

### Mantener schema 1 y añadir `inventory` opcional

Rechazado: hace ambiguo si el campo falta por ser un save antiguo o por corrupción.

### Inferir el inventario antiguo

Rechazado: no existe fuente autoritativa para saber cuántas Poké Balls poseía el jugador. Inventar cantidades sería corrupción semántica.

### Reescribir automáticamente al cargar

Rechazado: leer no debe mutar el único fichero del usuario. La actualización se materializa en el siguiente save explícito.

### Acoplar inventario a `CaptureSystem`

Rechazado: rompe la separación de responsabilidades. `CaptureSystem` continúa siendo lógica pura; la propiedad/consumo de objetos vive en una capa superior.

## Validación

GitHub Actions con Godot `4.7.stable.official.5b4e0cb0f`:

- regresión histórica: **470 PASS / 0 FAIL**
- Inventory 9A: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- import Godot: PASS
- workflow: SUCCESS

La primera ejecución de 9B detectó un test histórico cuyo valor "inválido" (`calvo_save_v2`) pasó a ser precisamente el formato actual. Se corrigió el test para usar un identificador realmente ajeno; no se relajó el contrato de producción.

## Fuera de alcance

No se añaden autosave, múltiples perfiles, cloud save, UI de guardado, economía, tiendas ni nuevos tipos de objeto. Esos trabajos quedan para fases posteriores cuando exista una necesidad de gameplay concreta.
