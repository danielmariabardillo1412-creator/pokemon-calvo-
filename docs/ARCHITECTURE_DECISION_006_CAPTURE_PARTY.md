# ADR-006 — Capture + Party Core V1 (calvo_capture_v1)

Fecha: 2026-08-29
Rama: `feature/capture-party-v1` (desde `feature/progression-core-v1`)
Motor: `4.7.stable.official.5b4e0cb0f`

## Estado

ACEPTADA e IMPLEMENTADA. Tests: **286 PASS / 0 FAIL** (222 base + 64 nuevos de Party/Capture).
0 autoloads, 0 Nodes fuera de `tests/`, 0 referencias rotas. NO merge a `main`.

## Contexto

FASE 6 entregó Progression Core (XP/nivel/stats/naturaleza/IV/EV/evolution). Faltaba la
**captura** de criaturas salvajes y una **party persistente**. La captura debe ser determinista y
resoluble en servidor (la clienta no puede forjar el éxito), y la party debe preservar la identidad
de la criatura (misma `instance_id`, sin reroll de IV/EV/naturaleza/ability/moveset/PP).

## Decisiones

1. **NO se rediseña Battle Core ni Progression Core.** La captura es una preocupación
   *post-batalla* resuelta por `CaptureSystem` sobre la `CreatureInstance` salvaje viva. El
   `BattleOutcome` NO se extiende con campos de captura; la frontera es: la batalla muta la
   criatura en sitio (HP/status/PP), y luego la capa de captura lee ese estado.
2. **Party como `CreatureParty` (RefCounted), no autoload.** Límite centralizado en
   `PartyRuleset.MAX_PARTY = 6`; identidad por `instance_id`; serialización round-trip vía
   `CreatureInstance.to_dict/from_dict`. Sin lógica duplicada (add/remove/swap/reorder).
3. **Capture 100% pura** en `modules/capture/`: sin UI, sin Nodes, sin autoload. Toda la
   aleatoriedad se inyecta (`RandomNumberGenerator` propiedad del servidor).
4. **Autoridad de servidor**: la clienta solo envía `ball_id` + `target_id`. El target real y el
   contexto de batalla (`CaptureBattleContext`) se resuelven en servidor, así el resultado no se
   puede forjar.
5. **Regla determinista `calvo_capture_v1`**: `p = (capture_rate/255) * ball_mult * status_mult *
   hp_factor`, con `hp_factor = (3·max_hp − 2·current_hp)/(3·max_hp)`. Master Ball garantizada
   (no consume RNG). Balls: poke 1.0 / great 1.5 / ultra 2.0 / master garantizada.
6. **Bonus de status solo persistente**: sleep/freeze 2.0; poison/burn/paralysis/badly_poisoned
   1.5; volátiles (flinch/confusión) no afectan.
7. **Restricciones**: target inválido, KO (salvo `ALLOW_CAPTURE_KO`), batalla de entrenador,
   batalla terminada, lado incorrecto y ball desconocida → `INVALID` (no consume item). Trainer
   siempre rechazado en `calvo_capture_v1`.
8. **Party llena → `STORAGE_REQUIRED`**: se devuelve la criatura capturada pero NO se auto-reemplaza.
   El almacenamiento (storage) es FASE 8. La criatura preserva identidad aunque no entre a la party.
9. **`schema_version` sigue en 2** (Party y Capture añaden campos aditivos; sin bump de contrato
   de Progression).
10. **`capture_rate` importado desde `pokemon-species`** (presente; bulbasaur 45, pikachu 190,
    mewtwo 3). Rango válido `1..255`; `0`/ausente = no capturable. PokéAPI `items` no trae
    multiplicadores de ball estructurados, así que la tabla `CaptureRuleset.BALLS` es la fuente de
    verdad (documentado en `CAPTURE_DATA_AUDIT.md`).

## Consecuencias

- Captura reproducible seed-a-seed (golden tests).
- Identidad y stats de la criatura preservados al 100% tras captura.
- Superficie pequeña y testeable; lista para FASE 8 (Storage + Save).
- Riesgo: `capture_rate` de PokéAPI es "rarity", no el mult aplicado de los juegos; la fórmula de
  probabilidad es una simplificación de `calvo_capture_v1` (aceptada como regla de diseño).

## Rechazado

- Extender `BattleOutcome` con captura (acoplaría Battle a captura).
- Autoload de party/capture (violaba el contrato 0-autoload del proyecto).
- Calcular la captura en la clienta (forjable).
