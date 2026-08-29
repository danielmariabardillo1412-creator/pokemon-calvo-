# Savegame Architecture — V2

Estado actual: `schema_version = 2`, `format_id = calvo_save_v2`.

V2 conserva las garantías de FASE 8/8C y añade persistencia explícita del inventario de FASE 9A.

## Files

- `modules/save/save_game_data.gd` — snapshot puro y validación estructural/de dominio.
- `modules/save/save_game_migration.gd` — normalización explícita del formato histórico V1 al V2 actual.
- `modules/save/save_game_serializer.gd` — IO + reemplazo protegido del fichero.
- `modules/save/save_game_repository.gd` — build/validate/persist + carga transaccional.
- `modules/save/save_result.gd` — `SaveResult`.
- `modules/save/load_result.gd` — resultado de carga con Party, Storage, Inventory y metadata de migración.

## Schema V2

```json
{
  "schema_version": 2,
  "format_id": "calvo_save_v2",
  "creatures": [
    {"instance_id": "...", "species_id": "...", "level": 5}
  ],
  "party": {
    "schema_version": 2,
    "ruleset_id": "calvo_party_v1",
    "ordered_instance_ids": ["..."]
  },
  "storage": {
    "schema_version": 2,
    "ruleset_id": "calvo_storage_v1",
    "boxes": [
      {"box_id": "box_0", "name": "Box 1", "capacity": 30, "slots": ["...", null]}
    ]
  },
  "inventory": {
    "schema_version": 1,
    "ruleset_id": "calvo_inventory_v1",
    "quantities": {
      "poke_ball": 12,
      "great_ball": 4
    }
  }
}
```

`creatures` continúa siendo el registro CANÓNICO: cada `CreatureInstance` completo se escribe una sola vez. Party y Storage referencian por `instance_id`. Inventory es otro agregado de estado mutable y se serializa una sola vez mediante `PlayerInventory`.

## Player aggregate

`PlayerCollection` contiene:

- `CreatureParty party`
- `CreatureStorage storage`
- `PlayerInventory inventory`

`SaveGameRepository.save_collection(path, player_collection)` persiste el agregado completo.

La API de nivel bajo `save_state(path, party, storage, inventory = null)` conserva compatibilidad para tests/callers antiguos; si no se pasa inventario genera una bolsa V2 vacía. El flujo normal del jugador debe utilizar `save_collection()` para no perder el inventario real.

## Validación V2 (`SaveGameData.validate`)

Un payload V2 se rechaza, entre otros casos, por:

- `missing_format_id` / `unsupported_format`
- `missing_schema` / `unsupported_schema`
- tipos estructurales incorrectos en creatures/party/storage/inventory/boxes
- `inventory_<reason>` si `PlayerInventory` rechaza su schema, ruleset o cantidades
- `empty_creature_instance_id`
- `duplicate_creature_id`
- party con ID vacío, duplicado o más de `PartyRuleset.MAX_PARTY`
- referencia a criatura inexistente
- `double_ownership`
- slot/storage corrupto

Un V2 sin `inventory` NO significa bolsa vacía: es un V2 inválido. Solo el migrador V1 puede sintetizar legítimamente una bolsa vacía.

Los campos de layout siguen transportándose como `Variant` hasta validación para que un JSON con tipos hostiles sea rechazado con un `reason` explícito en lugar de provocar un fallo de tipado antes del gate.

## Migración V1 → V2

El formato histórico reconocido es exclusivamente:

```text
schema_version = 1
format_id = calvo_save_v1
```

`SaveGameMigration.normalize()`:

1. duplica el diccionario en memoria;
2. cambia a schema 2 / `calvo_save_v2`;
3. añade un `PlayerInventory` vacío y válido;
4. deja Party, Storage y el registro canónico de criaturas intactos.

No se infieren objetos a partir de capturas ni de ninguna otra señal. Un supuesto campo `inventory` dentro de un V1 se ignora porque nunca perteneció al contrato V1.

Combinaciones mixtas como `calvo_save_v1 + schema 2`, `calvo_save_v2 + schema 1`, formatos desconocidos y schemas futuros se rechazan. No hay migraciones heurísticas.

La migración es **no destructiva**: `load()` NO reescribe el archivo V1. `LoadResult.migrated_from_version == 1` informa al caller. El siguiente save explícito escribe V2.

## Protected replacement (`SaveGameSerializer.write_atomic`)

Se conserva el contrato validado en FASE 8C:

1. escribir y verificar `path.tmp`;
2. si no existe target, publicar por rename;
3. si existe target, moverlo primero a `path.bak`;
4. publicar el temp;
5. si la publicación falla, restaurar el backup;
6. eliminar backup tras éxito.

Propiedad exigida: **LAST KNOWN GOOD SAVE PRESERVED**. No se afirma atomicidad fuerte de filesystem donde la plataforma no la garantice; sí se garantiza el protocolo de reemplazo/restore probado por la suite.

## Transactional load

`SaveGameRepository.load` es all-or-nothing:

1. lee y parsea JSON;
2. normaliza V1/V2 mediante `SaveGameMigration`;
3. valida el snapshot V2;
4. reconstruye y valida Inventory;
5. crea una sola vez cada `CreatureInstance` del registro canónico;
6. reconstruye Party comprobando cada `add_creature`;
7. reconstruye Storage y vuelve a comprobar ownership;
8. solo entonces publica `ok`, `party`, `storage` e `inventory`.

Ante cualquier fallo, `party`, `storage` e `inventory` permanecen `null`; no se publica estado parcial.

## CI / gates

Validado con Godot `4.7.stable.official.5b4e0cb0f`:

- suite de regresión: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**

ADR asociada: `docs/ARCHITECTURE_DECISION_009_SAVEGAME_V2.md`.
