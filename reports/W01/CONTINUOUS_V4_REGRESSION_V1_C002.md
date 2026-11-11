# W01 V4 — Recepción de regresiones V1 y CAMP002 en staging

Fecha de comprobación: 2026-11-11.
Rama: `codex/calvo-ia6-staging-20261111-w01-held`.

## Evidencia observada
- Workflow: `.github/workflows/w01-continuous-v4-held-regression-v1-v2.yml`.
- Run: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965532842
- SHA indicado en el checkpoint de lanzamiento: `39570126842821a885e5e5da9803a6bb75ca66b4`.
- Consulta directa de los jobs de la ejecución: `held_stage_v1_camp002` = `completed/success`.
- El workflow contiene las suites originales de W01 V1 y CAMP002, controles Python, Godot, nativo y SaveV2. La verificación del job no sustituye inspección detallada de sus artefactos.

## Límites y siguientes puertas
- Esta prueba NO certifica T01–T04, V2 ni CAMP003–005 de la rama staging.
- No proclamar `READY_FOR_IA6_MERGE` hasta una puerta acumulativa con regresiones suficientes sobre SHA concreto.
- Los informes de auditoría referenciados por el STATE deben verificarse por ruta; `reports/W01/CONTINUOUS_V4_DIFF_AUDIT.md` no apareció al consultarlo en esta rama (404).
- No copiar módulos protegidos ni alterar `native_engine.cjs`, SaveV2 o políticas de IA6. Registrar pruebas ausentes y construir QA selectivo, nunca inventar PASS.
- Integración oficial IA6: NO.
