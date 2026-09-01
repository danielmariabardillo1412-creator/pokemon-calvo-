# Índice de arquitectura

Esta carpeta contiene especificaciones de arquitectura y reglas por subsistema.

## Cómo leer estos documentos

`ARCHITECTURE.md` es la **visión general actual** y debe ser el primer documento de esta carpeta.

Los demás archivos nacieron en fases concretas y siguen siendo útiles para sus contratos técnicos. Cuando incluyen cifras de tests, nombres de fase o frases como “total actual”, esas cifras deben interpretarse como **evidencia del momento en que se cerró aquella especificación**, no como el total global del repositorio hoy.

Para saber el baseline, el número de workflows o qué trabajo está activo, consultar siempre `../current/`.

## Documentos

- `ARCHITECTURE.md` — visión general vigente.
- `BATTLE_ARCHITECTURE.md` — estado y fases del Battle Core.
- `BATTLE_EFFECTS.md` — contrato de efectos de combate.
- `BATTLE_RULESET_CALVO_V1.md` — reglas del ruleset de batalla.
- `DATA_FOUNDATION_V3.md` — contrato formal del pipeline DATA V3.
- `PROGRESSION_ARCHITECTURE.md` — progresión de criaturas.
- `PROGRESSION_RULESET_CALVO_V1.md` — ruleset de progresión.
- `CAPTURE_ARCHITECTURE.md` — captura.
- `CAPTURE_RULESET_CALVO_V1.md` — ruleset de captura.
- `PARTY_ARCHITECTURE.md` — party/roster.
- `STORAGE_ARCHITECTURE.md` — almacenamiento.
- `SAVEGAME_ARCHITECTURE.md` — persistencia/savegame.

## Decisiones asociadas

Los ADR no se duplican aquí. Están en `../adr/` y conservan el razonamiento/alcance original de cada decisión.

## Historia

Las especificaciones reemplazadas o auditorías de pipelines antiguos pertenecen a `../history/`, especialmente `legacy_data/` y `worklogs/`.
