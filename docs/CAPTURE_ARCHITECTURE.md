# CAPTURE Architecture — FASE 7

Módulo: `modules/capture/`
Responsabilidad: resolución determinista de un intento de captura de una criatura salvaje.
100% puro — sin UI, sin Nodes, sin autoload. Toda la aleatoriedad se inyecta.

## Archivos

- `capture_ball_definition.gd` — `CaptureBallDefinition` (RefCounted): `ball_id`, `base_multiplier`,
  `guaranteed`. Inmutable (definición). `to_dict`/`from_dict` por integridad.
- `capture_ruleset.gd` — `CaptureRuleset` (RefCounted): `calvo_capture_v1`.
  - `SCHEMA_VERSION = 2`, `BALLS` (poke/great/ultra/master), `STATUS_BONUS`,
    `ALLOW_CAPTURE_KO = false`, `is_valid_capture_rate`.
  - `ball(id)`, `is_known_ball(id)`, `status_bonus(persistent_id)`,
    `catch_probability(capture_rate, ball_mult, status_mult, max_hp, current_hp)`.
- `capture_event.gd` — `CaptureEvent` (RefCounted): eventos semánticos
  `ATTEMPTED / SHAKE / FAILED / SUCCEEDED / REJECTED / PARTY_ADDED / STORAGE_REQUIRED`.
- `capture_battle_context.gd` — `CaptureBattleContext` (RefCounted): frontera de servidor.
  `is_wild`, `battle_finished`, `caller_trainer_id`, `target_owner_trainer_id`,
  `target_side_id`, `target_instance_id`.
- `capture_attempt.gd` — `CaptureAttempt` (RefCounted): entrada de la clienta
  (`target`, `ball_id`, `context`). NO tiene campo de éxito (no forjable).
- `capture_result.gd` — `CaptureResult`: `status` (SUCCESS/FAILED/INVALID), `ball_id`,
  `target_id`, `probability`, `shake_count`, `consume_item`, `reason`. Serializable.
- `capture_disposition.gd` — `CaptureDisposition`: `PARTY` / `STORAGE_REQUIRED`.
- `capture_resolution.gd` — `CaptureResolution`: `result` + `captured` (misma `CreatureInstance`)
  + `disposition` + `events`. Serializable.
- `capture_system.gd` — `CaptureSystem.resolve(attempt, rng, catalogs, party)`:
  valida, calcula probabilidad, consume RNG solo si no es garantizada, muta la party en éxito con
  espacio, y devuelve `CaptureResolution`.

## Flujo

1. La clienta envía `{action: CAPTURE, ball_id, target_id}` (intención, no éxito).
2. El servidor construye `CaptureAttempt` con la `CreatureInstance` real y un `CaptureBattleContext`
   real (salvaje, no terminada, lado correcto).
3. `CaptureSystem.resolve` valida → `INVALID` si falla alguna regla (no consume item).
4. Si es válido, calcula `p`; master/guaranteed ⇒ SUCCESS sin RNG; si no, `rng.randf() < p`.
5. En éxito: `res.captured = target` (misma instancia), y si la party tiene espacio ⇒
   `add_creature` + `PARTY_ADDED`; si está llena ⇒ `STORAGE_REQUIRED` (sin auto-reemplazo).

## Determinismo

- Mismo `attempt` + mismo `seed` de `rng` ⇒ mismo `status`, `shake_count` y `events`.
- Master Ball no consume RNG (`rng.state` inalterado).
- Golden tests (`CapturePartyTestSuite`) fijan probabilidades y resultados para detectar cambios
  involuntarios en `CaptureRuleset`.

## Separación

- NO rediseña Battle Core (solo lee HP/status/PP de la `CreatureInstance`).
- NO rediseña Progression Core.
- NO crea `CreatureInstance` nueva al capturar (preserva identidad/IV/EV/naturaleza/ability/moves).
- Storage (FASE 8) consumirá `STORAGE_REQUIRED`; aquí solo se señaliza.
