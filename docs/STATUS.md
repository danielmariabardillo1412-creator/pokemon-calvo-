# Pokémon Calvo — Current Project Status

Fecha de sincronización: 2026-08-30  
Motor validado: `4.7.stable.official.5b4e0cb0f`  
Estado de desarrollo: **stacked development; no merge a `main`**

Este documento es el índice de estado **actual**. Los informes `INFORME_FINAL_FASE*.md` y los ADR conservan el detalle histórico y la evidencia de cada bloque. No se debe usar un total antiguo de tests o una descripción de una fase intermedia como descripción del proyecto completo.

## Baseline validado actual

La cadena funcional validada llega hasta **FASE 18 — Battle Run Presentation V1**:

`Overworld físico -> zona de encuentro -> WildEncounterSystem -> WildAdventureSession -> Battle visible -> MOVE / CAPTURE / SWITCH / RUN -> settlement -> confirmación -> Overworld`

La presentación no es autoridad de gameplay. MOVE/SWITCH pasan por Battle Core; CAPTURE y RUN pasan por comandos de aplicación de `WildAdventureSession`; la UI construye intenciones y representa resultados autoritativos.

La rama funcional más reciente es:

`feature/battle-run-presentation-v1`

PR #12 está cerrado **sin merge**. El desarrollo posterior debe partir de esa historia o de una rama descendiente explícitamente documentada; `main` no representa todavía este baseline.

## Gates finales del baseline

GitHub Actions final de FASE 18: run `33300590609`, job `99227876718`.

| Gate | Resultado |
|---|---:|
| Historical regression | 470 PASS / 0 FAIL |
| Inventory | 47 PASS / 0 FAIL |
| Savegame V2 | 40 PASS / 0 FAIL |
| Savegame V2 adversarial | 8 PASS / 0 FAIL |
| Wild Encounters | 54 PASS / 0 FAIL |
| Logical Vertical Slice | 62 PASS / 0 FAIL |
| Overworld | 59 PASS / 0 FAIL |
| Battle Presentation | 43 PASS / 0 FAIL |
| Battle Commands | 53 PASS / 0 FAIL |
| Battle Capture Presentation | 68 PASS / 0 FAIL |
| Battle Switch Presentation | 49 PASS / 0 FAIL |
| Wild RUN Command | 71 PASS / 0 FAIL |
| Battle RUN Presentation + audit | 94 PASS / 0 FAIL |
| Godot import headless | PASS |

Artifact: `godot-ci-logs-33300590609`  
Artifact ID: `9728809265`  
SHA-256: `29d1020bea96f87d4b2b2660f95dd7b9643933816d4f504f1afb721316fdc7cd`

El diagnóstico de parser provocado por el test de JSON corrupto es intencionado y termina en PASS. Los warnings de Node.js de GitHub Actions no son errores del juego.

## Cadena de bloques recientes

| Bloque | Rama | Estado | Resultado dedicado |
|---|---|---|---:|
| FASE 8C — Storage/Save hotfix | `feature/storage-save-hotfix-v1` | CLOSED / VALIDATED | baseline 470 / 0 |
| FASE 9A — Inventory Core | `feature/inventory-core-v1` | CLOSED / VALIDATED | 47 / 0 |
| FASE 9B — Inventory + Savegame V2 | `feature/inventory-savegame-v2` | CLOSED / VALIDATED | 40 / 0 + adv 8 / 0 |
| FASE 10 — Wild Encounters | `feature/wild-encounters-v1` | CLOSED / VALIDATED | 54 / 0 |
| FASE 11 — Logical Vertical Slice | `feature/vertical-slice-core-v1` | CLOSED / VALIDATED | 62 / 0 |
| FASE 12 — Overworld Core | `feature/overworld-core-v1` | CLOSED / VALIDATED | 59 / 0 |
| FASE 13 — Battle Presentation | `feature/battle-presentation-v1` | CLOSED / VALIDATED | 43 / 0 |
| FASE 14 — Battle Commands | `feature/battle-commands-v1` | validated in descendant baseline | 53 / 0 |
| FASE 15 — Capture Presentation | `feature/battle-capture-presentation-v1` | CLOSED / VALIDATED | 68 / 0 |
| FASE 16 — Switch Presentation | `feature/battle-switch-presentation-v1` | CLOSED / VALIDATED | 49 / 0 |
| FASE 17 — Wild RUN Command | `feature/wild-run-command-v1` | CLOSED / VALIDATED | 71 / 0 |
| FASE 18 — Run Presentation | `feature/battle-run-presentation-v1` | CLOSED / VALIDATED | 94 / 0 |

FASE 14 conserva en su informe la nota histórica de que el HEAD documental necesitaba repetición de CI. Los descendientes FASE 15–18 y el CI final de FASE 18 ejecutan y conservan su gate de 53/0; por tanto forma parte del baseline validado actual. No se reescribe el informe histórico para fingir que aquella evidencia existía antes.

## Capacidades presentes

### Datos y criaturas

- dataset normalizado PokéAPI fijado por commit/provenance;
- 986 especies base, tipos, movimientos, habilidades, objetos, learnsets y evoluciones importados con IDs estables;
- `CreatureInstance` persistente con identidad, IV/EV, naturaleza, nivel/XP, HP/status, ability, held item y moveset/PP;
- progresión, stats, learnsets y evolución modelados fuera de Battle.

### Battle

- Battle Core autoritativo y determinista;
- MOVE y SWITCH;
- PP, accuracy/evasion, stages, críticos, tipos, status, triggers, algunas abilities/held items y effects estructurados;
- eventos semánticos consumibles por presentación;
- snapshot/replay determinista del core.

### Colección y persistencia

- Party máx. 6;
- Storage por cajas de 30 slots con cajas dinámicas;
- Inventory persistente;
- Savegame V2 con migración real V1 -> V2, validación defensiva y carga transaccional;
- identidad canónica de criaturas compartida por Party/Storage.

### Aventura y presentación técnica

- movimiento físico cardinal y colisiones;
- pasos por distancia real y zonas de encounter;
- encuentro salvaje determinista;
- Battle overlay técnico sobre la misma sesión real;
- MOVE, CAPTURE, SWITCH y RUN utilizables;
- captura fallida recibe represalia; captura exitosa enruta ownership;
- cambio electivo y reemplazo automático tras KO;
- huida con `calvo_escape_v1`, intentos acumulativos y reacción rival al fallo;
- confirmación explícita antes de volver al Overworld.

## Límites actuales importantes

Todavía no hay UI/arte final, mapa romano definitivo, NPCs/diálogo, puertas/transiciones de mapas, audio, world-state persistente, networking ni trainer-battle loop completo.

Tampoco existe todavía un flujo jugador-completo para **decisiones de progresión post-battle**. `ProgressionSystem` puede emitir `MOVE_LEARN_CHOICE_REQUIRED` y `EVOLUTION_AVAILABLE`, pero `BattlePresentationController` hoy solo registra de forma genérica que la progresión fue reconciliada; no presenta ni conserva una cola de decisiones obligatorias para el jugador. Esta frontera debe cerrarse antes de considerar la victoria -> progreso -> retorno como UX completa.

La cobertura de contenido también es deliberadamente parcial: cientos de efectos únicos, la mayoría de abilities/items, forms y triggers especiales de evolución siguen fuera del runtime completo. Ver `docs/MECHANICS_COVERAGE.md`, `docs/MOVE_EFFECT_COVERAGE.md` y `docs/EVOLUTION_COVERAGE.md`.

## Fuente canónica para decidir el siguiente trabajo

1. Este `STATUS.md` para estado agregado actual.
2. `docs/ROADMAP.md` para orden recomendado y dependencias futuras.
3. ADRs para decisiones arquitectónicas.
4. `INFORME_FINAL_FASE*.md` para evidencia histórica de cada bloque.
5. GitHub Actions para demostrar el HEAD exacto; un informe sin CI verde del HEAD no basta.

No se abre una nueva fase funcional solo porque toque el siguiente número. Primero se identifica una frontera real, se audita el contrato existente y se define el gate.