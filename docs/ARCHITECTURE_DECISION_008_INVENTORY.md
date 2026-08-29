# ADR-008 — Inventory Core V1 y consumo transaccional de Poké Balls

**Estado:** ACEPTADO / FASE 9A VALIDADA  
**Rama:** `feature/inventory-core-v1`  
**Política:** `calvo_inventory_v1`

## Contexto

Tras FASE 8, captura, Party, Storage y Savegame ya tenían contratos deterministas y tests de identidad. Sin embargo, captura solo declaraba semánticamente `consume_item = true`: todavía no existía una bolsa persistente de cantidades ni una capa que comprobara que el jugador poseía la Poké Ball antes de resolver una captura.

Acoplar esas cantidades directamente a `CaptureSystem` habría mezclado dos dominios distintos: la fórmula de captura y la propiedad/consumo de objetos. También habría hecho más difícil reutilizar y probar el motor de captura como lógica pura.

## Decisión

### 1. Inventario como estado de dominio independiente

Se introduce `PlayerInventory` como `RefCounted`, sin UI, Nodes, autoload, filesystem ni RNG.

El inventario:

- se indexa por `item_id` estable;
- mantiene cantidades enteras positivas de forma dispersa (cantidad 0 = entrada ausente);
- usa `MAX_STACK = 999` como política explícita de V1, no como dato importado de PokeAPI;
- rechaza operaciones inválidas sin mutar el estado;
- serializa los IDs en orden lexicográfico estable;
- tiene schema propio `schema_version = 1` y `ruleset_id = calvo_inventory_v1`;
- rechaza payloads corruptos o incompatibles en vez de repararlos silenciosamente.

En FASE 9A este schema es **standalone**. Todavía no modifica el schema global de Savegame.

### 2. CaptureSystem permanece puro

`CaptureSystem` sigue sin conocer el inventario. Solo expone públicamente `validate_attempt()`, que es exactamente la misma validación que utiliza `resolve()`.

Esto permite que una capa superior compruebe prerrequisitos de propiedad antes de consumir RNG o mutar Party, sin duplicar las reglas de captura.

### 3. Capa de aplicación para consumo

`CaptureInventoryService` coordina Inventory + Capture:

1. valida el intento con `CaptureSystem.validate_attempt()`;
2. un intento inválido mantiene la semántica original y no exige ni consume objeto;
3. un intento válido exige un inventario sano y al menos una unidad de la ball solicitada;
4. reserva/retira exactamente una unidad antes de resolver;
5. el intento válido consume una unidad tanto en éxito como en fallo;
6. si el contrato de CaptureSystem cambiara y devolviera inesperadamente un resultado no consumidor después de haber validado, la unidad se restaura defensivamente.

La Master Ball mantiene su propiedad especial: éxito garantizado sin consumir RNG, pero sí consume una unidad real del inventario.

### 4. Captura con Party llena

Una captura válida con Party llena consume la ball y sigue devolviendo `STORAGE_REQUIRED`. El routing hacia Storage continúa perteneciendo a la capa de ownership creada en FASE 8; Inventory no se acopla a Storage.

## Invariantes

- Cantidades nunca negativas.
- Una operación rechazada no cambia el inventario.
- Un intento de captura inválido no consume objeto ni RNG.
- Un intento válido sin la ball requerida no consume RNG ni muta Party.
- Un intento válido con ball consume exactamente 1 unidad, tanto si captura como si falla.
- La captura preserva la misma `CreatureInstance`; Inventory no crea ni copia criaturas.
- `CaptureSystem` no depende de `PlayerInventory`.
- Orden de serialización del inventario determinista por texto del `item_id`.

## Validación

GitHub Actions, Godot `4.7.stable.official.5b4e0cb0f`:

- regresión previa: **470 PASS / 0 FAIL**;
- suite específica FASE 9A: **47 PASS / 0 FAIL**;
- importación headless: PASS.

El primer gate de 9A detectó un defecto real: `StringName.sort()` no proporcionaba el orden lexicográfico esperado para los IDs. Se corrigió ordenando por la representación `String`, y el segundo gate quedó verde.

## Fuera de alcance de FASE 9A

- persistir Inventory dentro del Savegame global;
- migraciones del schema de Savegame;
- objetos curativos, revivir, PP, evolución u objetos de campo;
- UI de bolsa;
- tiendas, dinero o economía;
- networking/autorización remota.

## Siguiente bloque recomendado

**FASE 9B — Inventory + Savegame V2.**

Debe decidirse y probarse explícitamente la evolución de schema. La dirección preferida es introducir un Savegame V2 con una migración real y mínima desde V1 (inventario vacío al migrar), manteniendo carga transaccional y sin inventar datos que el save antiguo no contenía.
