# INFORME FINAL — FASE 20: Trainer Intelligence Foundation V1

## Estado

**TECNICAMENTE COMPLETA / VALIDADA**

Rama: `feature/trainer-intelligence-foundation-v1`

Base: `feature/trainer-battle-session-v1`

SHA base de FASE 19: `318c7ee1bd7f5898493bb0c5f5dfcd6d6f8dc252`

PR: **#14 — FASE 20: trainer intelligence foundation V1**

HEAD de implementación validado antes del cierre documental: `89d2a9e8f2d6e2712ff436fc979ed57b33438f7b`

> Los commits de este informe/estado documental son posteriores al HEAD de implementación citado. El cierre definitivo debe conservar verdes los mismos gates sobre el HEAD documental final.

## Objetivo real de la fase

FASE 20 no intenta construir un entrenador que ya juegue bien. Su objetivo es evitar que la futura IA quede encerrada en una política simplista y construir las fronteras que puedan soportar heurísticas avanzadas, búsqueda, modelado del rival, MCTS, políticas neuronales, ensembles y self-play sin reescribir Battle Core.

La regla de diseño queda fijada así:

`percepción legítima -> memoria -> creencias -> contexto de decisión -> cerebro reemplazable -> acción -> Battle Core autoritativo`

La política `SimpleBattleOpponentPolicy` existente sigue siendo una ayuda técnica de presentación/fallback y **no** se convierte en arquitectura de producción.

## Resultado de la auditoría de Battle Core

La principal incógnita de entrada era si la IA necesitaría un simulador de combate paralelo.

La respuesta es **no**.

Battle Core ya posee una base adecuada para simulación contrafactual:

- `BattleState` puede serializarse y restaurarse profundamente;
- los participantes restaurados son nuevas `CreatureInstance`;
- HP, PP, stats, stat stages, estados, habilidad y objeto forman parte del snapshot pertinente;
- los lados/activos se restauran;
- el RNG determinista conserva y restaura su estado;
- Battle Core ya tenía una prueba de continuación desde snapshot que exige mismos eventos y mismo estado final;
- `BattleRuleset` y `BattleEffectRegistry` no esconden estado mutable específico de una batalla.

**Decisión:** la búsqueda futura reutilizará el mismo Battle Core en forks aislados. No se mantendrán dos implementaciones distintas de las reglas Pokémon.

## Componentes introducidos

### `BattleSimulationFork`

Crea una bifurcación profunda de `BattleState`, levanta un `AuthoritativeBattleServer` independiente y permite ejecutar turnos hipotéticos sin mutar la batalla real. También permite bifurcar un fork ya avanzado.

### `TrainerBattleMemory`

Memoria por perspectiva de batalla:

- Pokémon rivales vistos;
- movimientos revelados al usarse;
- habilidades reveladas al activarse;
- objetos revelados al activarse;
- historial semántico mínimo de eventos.

La metadata genérica de `BattleEvent` no se persiste en bruto. Solo se extraen explícitamente revelaciones públicas conocidas, evitando que campos internos añadidos en el futuro se conviertan accidentalmente en información para la IA.

### `TrainerBeliefState`

Distingue entre:

- información **revelada**;
- información **inferida**.

Las hipótesis usan confianza determinista en basis points `0..10000`. FASE 20 fija el contrato, no los priors probabilísticos definitivos.

### `TrainerObservation` / `TrainerObservationBuilder`

Frontera anti-trampa. Un cerebro futuro no recibe el `BattleState` vivo.

De su propio lado puede conocer el estado completo. Del jugador/rival solo recibe lo legítimamente observado o revelado. Se excluyen deliberadamente, entre otras cosas:

- RNG interno;
- roster rival no visto;
- referencias vivas a `CreatureInstance`;
- IV/EV/nature rivales;
- stats exactos rivales;
- HP numérico exacto rival;
- movimientos no revelados;
- habilidad no revelada;
- objeto no revelado.

### `TrainerDecisionContext`

Entrada segura para cualquier cerebro futuro. Contiene observación, snapshots de memoria/creencias y copias de acciones legales. No entrega autoridad ni referencias mutables de la batalla real.

### `TrainerBrain`

Interfaz reemplazable. La clase base devuelve `null`: FASE 20 evita deliberadamente introducir una política simplista por defecto como si fuera el cerebro definitivo.

### `TrainerDecisionTrace`

Registro serializable de candidatos, fuentes, puntuaciones, confianza, motivos, acción elegida y metadata de análisis. Servirá para depuración, benchmark, Brain A vs Brain B, análisis de derrotas y futuros datasets de self-play.

## Invariantes probados

La suite de FASE 20 comprueba, entre otros puntos:

- fork creado correctamente;
- `BattleState`, lados, criaturas, estado, stages y PP están desacoplados;
- alterar HP/PP/stages/status/switch en un fork no altera la batalla real;
- dos forks idénticos con las mismas acciones producen mismos eventos y mismo resultado;
- un fork secundario arranca exactamente desde su padre;
- el banquillo rival no visto permanece oculto;
- moves/ability/item permanecen ocultos hasta revelarse;
- IV/EV/nature/stats exactos/RNG no cruzan la frontera de observación;
- memoria y creencias sobreviven round-trip JSON de forma canónica;
- el contexto de decisión clona las acciones y no expone `BattleState`/RNG;
- la clase `TrainerBrain` base no contiene una política implícita;
- metadata interna artificialmente inyectada en eventos no llega a la memoria del cerebro, mientras las revelaciones públicas siguen funcionando.

## Validación CI

Sobre el HEAD de implementación `89d2a9e8f2d6e2712ff436fc979ed57b33438f7b`:

- **Trainer Intelligence Foundation:** `63 PASS / 0 FAIL`
- **Trainer Battle Session (regresión FASE 19):** `66 PASS / 0 FAIL`
- **Godot 4.7 Tests históricos:** `SUCCESS`

Los tres workflows terminaron correctamente sobre el mismo HEAD.

## Incidencias encontradas durante la fase

### 1. Round-trip JSON: 58 PASS / 2 FAIL

La primera versión compilaba y pasaba toda la arquitectura salvo dos comparaciones de round-trip (`TrainerBattleMemory` y `TrainerBeliefState`). El límite JSON podía devolver números con representación de tipo distinta.

**Corrección:** se canonicalizaron los campos enteros durante `from_dict()` en lugar de relajar los tests.

Resultado posterior: `60 PASS / 0 FAIL`.

### 2. Auditoría explícita de metadata: 62 PASS / 1 FAIL

Después de endurecer la memoria se añadió una prueba específica de fuga. Su primera versión buscaba literalmente la palabra `metadata` en todo el JSON. Los fixtures se llamaban `metadata_player` y `metadata_audit`, por lo que la prueba se autogeneraba un falso positivo.

**Diagnóstico:** no existía fuga real.

**Corrección:** la prueba inspecciona estructuralmente si cada evento conserva una clave `metadata` y verifica además la ausencia de los secretos artificiales concretos.

Resultado final: `63 PASS / 0 FAIL`.

## Lo que FASE 20 NO significa

Todavía **no existe una IA estratégica de entrenador que elija por sí sola una buena acción**.

FASE 20 ha construido los ojos, la memoria, la separación entre saber/suponer, la frontera anti-trampa, la caja negra intercambiable del cerebro, la telemetría y el mecanismo seguro para imaginar futuros.

No incluye todavía:

- generador definitivo de acciones legales/candidatas;
- evaluador táctico de daño/KO/switch/setup/preservación;
- personalidad de entrenadores;
- priors reales para información oculta;
- modelo del jugador;
- MCTS/minimax/expectiminimax;
- red neuronal;
- LLM de runtime;
- self-play;
- integración visual/overworld de entrenadores.

## Riesgos abiertos deliberadamente

1. `BattleSimulationFork` continúa el RNG exactamente; la búsqueda probabilística futura necesitará una política explícita para representar resultados alternativos sin falsear autoridad.
2. FASE 20 representa HP rival observado como ratio en basis points. Podrá cuantizarse si la UI final solo debe mostrar barras/intervalos.
3. La memoria pública es conservadora. Nuevas señales observables deberán entrar por whitelist, no copiando metadata arbitraria.
4. Antes de MCTS necesitamos un espacio de acciones/candidatos limpio y un evaluador táctico interpretable que permita verificar si la IA entiende lo básico.

## Próximo tramo recomendado

Nueva recomendación técnica, no roadmap histórico previo:

**FASE 21 — Trainer Action Space & Tactical Evaluation Foundation**

Objetivo propuesto:

1. generar acciones candidatas completas y válidas para MOVE/SWITCH sin saltarse Battle Core;
2. crear features/evaluadores tácticos interpretables para daño, KO, velocidad/prioridad, matchup, supervivencia, estados, stages, cambios y preservación;
3. producir `TrainerDecisionTrace` explicable para cada evaluación;
4. crear un baseline determinista únicamente como benchmark/CI/fallback, no como plantilla del cerebro final;
5. preparar el contrato que después usarán personalidad, beliefs avanzadas y búsqueda.

MCTS o un modelo neuronal deberían llegar **después** de que este nivel sea observable, medible y testeable.

## Conclusión

FASE 20 elimina uno de los mayores riesgos estructurales de la línea de IA: ya sabemos que el mismo Battle Core puede actuar como simulador aislado y que el cerebro puede mantenerse separado de información privada y de la autoridad del combate.

La base queda preparada para aumentar inteligencia sin tener que convertir una política pobre en el centro irreversible del sistema.
