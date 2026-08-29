# PARTY Architecture — FASE 7

Módulo: `modules/creatures/party/`
Responsabilidad: roster persistente del jugador (máximo 6), identidad por `instance_id`,
serialización estable. Sin UI, sin Nodes, sin autoload.

## Archivos

- `party_ruleset.gd` — `PartyRuleset` (RefCounted): ÚNICA fuente de verdad del límite de roster.
  - `MAX_PARTY = 6`, `SCHEMA_VERSION = 2`, `RULESET_ID = &"calvo_party_v1"`.
  - `is_valid()` valida el diccionario serializado (tamaño ≤ 6, ids únicos).
  - `CaptureRuleset.MAX_PARTY` fue eliminado en el hotfix: el límite 6 vive solo aquí.
- `creature_party.gd` — `CreatureParty` (RefCounted): estado de la party.
  - `_order: Array[StringName]` (orden) + `_by_id: Dictionary` (instancias).
  - `add_creature(c)` / `remove_creature(instance_id)` / `swap(a, b)` / `reorder(ids)`.
  - `get_creature(id)` / `get_creatures()` / `get_ordered_ids()` / `get_active()`.
  - `contains_instance_id(id)` / `size()` / `is_full()` / `is_empty()`.
  - `to_dict()` / `from_dict(d)` (round-trip vía `CreatureInstance`).
  - `to_dict` emite `{schema_version, ruleset_id, ordered_instance_ids, creatures}` donde
    `creatures` es `{instance_id: <CreatureInstance.to_dict()>}`.

## Invariantes

- La party NO crea, recalcula ni rerolla criaturas; solo las contiene.
- `add_creature` rechaza (false) si ya existe el `instance_id` o si está llena.
- `reorder(ids)` requiere una PERMUTACIÓN EXACTA del roster actual: mismo número de elementos, sin
  `instance_id` duplicado, sin id desconocido, sin id ausente. Cualquier otra entrada (p.ej.
  `[A,B,C,A]`, `[A,A,B]`, `[A,B]`, `[A,B,D]`) devuelve `false` y NO modifica `_order`.
- `from_dict` es defensivo: preserva la primera aparición válida de cada `ordered_instance_ids`,
  ignora duplicados posteriores e ids inexistentes, añade después las criaturas válidas ausentes del
  order, respeta `MAX_PARTY`, y nunca duplica `instance_id`. Invariante reconstruida:
  `_order.size() == _by_id.size()` y cada id de `_order` existe exactamente una vez en `_by_id`.
- Round-trip: `from_dict(to_dict(p)).get_ordered_ids() == p.get_ordered_ids()` y cada criatura
  preserva species/level/ivs/nature/ability/moveset/PP.

## Separación

- NO toca Battle Core ni Progression Core.
- La party se llena desde Capture (`CaptureSystem.resolve` llama `party.add_creature` en éxito con
  espacio) o desde Storage (FASE 8). La party no conoce la regla de captura.

## Tests

`CapturePartyTestSuite` (tests/capture_party_test_suite.gd): party_empty/add/max_six/
reject_seventh/duplicate_id/remove/swap/reorder/serialization/creature_fidelity.
