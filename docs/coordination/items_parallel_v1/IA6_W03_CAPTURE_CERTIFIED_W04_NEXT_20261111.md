# IA6 — cierre de captura W03 y prioridad W04 (2026-11-11)

## HEAD y hechos verificados
- Rama oficial IA6 `codex/calvo-ia6-integration-20261109` HEAD `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f` (comparación identical en la sesión).
- W05 integrada por PR #120 (merge `dca006bb52e79bdefa1175e1593c66997fab9c2e`); pruebas premerge 20/20 SUCCESS.
- Puerta **oficial conjunta W03 repel / W05 libros / Rope**:
  - Run #43084120282 sobre `47a9e654c5207d7b29a656d9909a9e5479b3facd`: completed/success, job 130743939263 SUCCESS.
  - Run #43106031150 sobre `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`: completed/success, job 130809468848 SUCCESS.
  - Página: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/workflows/ia6-official-w03-w05-rope-20261111.yml
- Puerta **oficial W03 captura Repeat/Net/Moon/ledger** run #43106031155, SHA `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`, completed/success, job 130809468412 SUCCESS. Página: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/workflows/ia6-official-w03-capture-20261111.yml
- La puerta estricta W03 captura incluye pruebas sin waiver de legacy WildAdventureSession (37), Repeat nativa y negativos, Net nativa y negativos, Moon, SaveV2 y adversarial, menta/naturaleza efectiva, Rope, panel W05 y repelentes. No inferir por esto cobertura de todas las campañas W03 001–006.
- Tras checkpoint previo `47a9e654`, IA6 avanzó **24 commits** al SHA anterior. Comparación confirma que los módulos de captura, historial y persistencia W03 ya están incorporados. NO realizar otra integración W03 desde su rama staging divergente.

## Decisiones de coordinación
1. **W03 captura y repelentes:** incorporados y certificados por puertas oficiales identificadas. Los bloqueos anteriores de seis aserciones legacy y falta de prueba conjunta ya no aplican para estas rutas.
2. **W05:** incorporada y revalidada junto con W03/rope; no volver a copiar el paquete W05.
3. **W04:** próximo foco. Su staging `codex/calvo-ia6-staging-20261111-w04-evolution` diverge respecto del HEAD actual (31 ahead, 52 behind). No hacer merge de la rama completa, especialmente `FieldNativeSave`, `SaveGameData`, `CreatureInstance`, `FieldItemService` y `EvolutionSystem`. Preparar nueva rama selectiva basada exactamente en HEAD IA6 actual, trasplantar solo hunks W04 necesarios y suites QA, certificar CAMP003–006 y UI real más SaveV2 y regresiones W02/W03/W05.
4. **W01:** pruebas parciales verdes en staging; falta equivalencia de regresiones históricas completas. Mantener en QA.
5. **W02:** sigue bloqueada por política/contrato EXP Share V3 hasta nueva evidencia.
6. Proteger `main`, V28, PR #118 y todas las ramas originales; conservar el veto `dynamax_candy`.

## Próxima tecla p
- Revisar si ya existe rama candidata W04 basada en `ddc8a1af`; no duplicarla. Si no, crear rama IA6 W04 selectiva (sin editar rama oficial) y hacer inventario de diferencias efectivas y dependencias.
- Identificar los hunks concretos de evolución regional que faltan sobre el HEAD actual y sus pruebas.
- CI verde sobre SHA de candidata antes de PR a rama oficial; después, postmerge CI sobre SHA oficial.
