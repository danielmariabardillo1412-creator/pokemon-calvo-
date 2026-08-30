# ADR-020 — Trainer Intelligence Foundation

**Estado:** EN IMPLEMENTACION / FASE 20

## Contexto

FASE 19 dejó una sesión headless de combate contra entrenadores que reutiliza Battle Core, pero la acción rival sigue llegando desde fuera. La siguiente capa no debe cristalizar una política simplista como arquitectura definitiva: el objetivo del proyecto es poder evolucionar hacia búsqueda, modelado del rival, creencias sobre información oculta, expertos heurísticos/neuronales y self-play sin reemplazar la autoridad del combate.

La política `SimpleBattleOpponentPolicy` existente pertenece a la presentación técnica y permanece como fallback/fixture; no es el contrato de inteligencia de entrenadores.

## Auditoría de Battle Core previa a la decisión

La auditoría del HEAD final de FASE 19 confirma:

1. `BattleState.to_dict()/from_dict()` serializa/restaura turno, fase, ganador, lados, participantes, estado RNG y `battle_started`.
2. `CreatureInstance.to_dict()/from_dict()` reconstruye instancias nuevas e incluye HP, PP, stats, stages, status persistente/volátil, habilidad y objeto.
3. `BattleSide`, `StatStages` y `BattleStatusState` tienen round-trip propio.
4. `SeededRandomSource` expone un LCG32 determinista y Battle Core persiste su estado en `BattleState.rng_state` al completar el turno.
5. Ya existe una prueba de continuación RNG desde snapshot que exige mismos eventos y mismo snapshot final.
6. `BattleRuleset` actúa como configuración y `BattleEffectRegistry` reconstruye sus tablas al instanciarse; el estado mutable de una batalla reside en el snapshot, no en esos objetos.

**Consecuencia:** no se crea un segundo motor de combate para IA. La búsqueda futura debe bifurcar Battle Core desde snapshots aislados.

## Decisión

FASE 20 introduce contratos de infraestructura, no una política de producción:

### 1. `BattleSimulationFork`

Restaura un `BattleState` profundo desde snapshot y construye un `AuthoritativeBattleServer` aislado. Permite ejecutar contrafactuales con las mismas reglas y RNG sin mutar la batalla viva. Los forks pueden bifurcarse de nuevo.

Battle Core sigue siendo la única autoridad de legalidad y ejecución.

### 2. `TrainerBattleMemory`

Memoria por perspectiva. Registra:

- criaturas rivales vistas;
- movimientos revelados por `ACTION_USED`;
- habilidades reveladas por `ABILITY_TRIGGERED`;
- objetos revelados por `ITEM_TRIGGERED`;
- historial semántico mínimo de eventos.

El historial genérico **no copia `BattleEvent.metadata`**. La metadata se usa puntualmente para extraer revelaciones conocidas, pero no se entrega en bruto al cerebro; así un campo diagnóstico futuro no puede convertirse accidentalmente en una vía de información oculta.

### 3. `TrainerBeliefState`

Separa hechos revelados de hipótesis. Las creencias usan confianza entera en basis points (0..10000) y evidencia `inferred` o `revealed`. No se fijan todavía priors ni algoritmo probabilístico: ese módulo podrá ser sustituido/ampliado en fases posteriores.

### 4. `TrainerObservation` + `TrainerObservationBuilder`

Es la frontera anti-trampa.

El lado propio recibe su estado completo. Del rival solo se exponen criaturas ya vistas y datos legítimamente observables/revelados. La vista rival no contiene:

- RNG interno;
- roster aún no visto;
- `CreatureInstance` vivo;
- IV/EV/nature;
- stats exactos;
- HP numérico exacto (se usa ratio en basis points);
- movimientos no revelados;
- habilidad no revelada;
- objeto no revelado.

La elección de ratio de HP como señal visible es V1; podrá cuantizarse en el futuro si la presentación final muestra menos precisión.

### 5. `TrainerDecisionContext`

Contrato de entrada de cualquier cerebro futuro. Contiene observación, snapshot de memoria, snapshot de creencias y copias de acciones legales. No contiene `BattleState`, `CreatureInstance` ni objeto RNG autoritativo.

### 6. `TrainerBrain`

Interfaz reemplazable. La clase base deliberadamente no elige ninguna acción. Heurísticas, search/MCTS, redes, ensembles o maestros LLM deberán implementar este mismo borde.

### 7. `TrainerDecisionTrace`

Registro serializable para candidatos, puntuaciones, confianza, fuentes, razón de selección y métricas. Es la base para depuración, comparativas Brain A vs Brain B, análisis de derrotas y futuros datasets de self-play.

## Invariantes

- Una simulación nunca muta objetos de la batalla viva.
- Dos forks del mismo snapshot con las mismas acciones deben producir la misma evolución RNG/estado.
- Un entrenador no obtiene información oculta leyendo `BattleState` bruto.
- Toda acción final vuelve a Battle Core para validación/ejecución.
- La dificultad/persona futura no se implementará quitando percepción básica; deberá variar presupuesto, calidad de inferencia, riesgo, horizonte, expertos y/o modelo entrenado.

## No objetivos de FASE 20

- MCTS completo.
- Minimax/expectiminimax completo.
- red neuronal entrenada.
- LLM en runtime.
- política heurística final.
- personalidad final de NPC.
- modelado probabilístico de movesets/items/abilities con priors reales.
- generación definitiva de acciones legales.
- UI/presentación de entrenadores.
- persistencia de una batalla activa.

## Riesgos abiertos

1. El simulador futuro necesitará una política explícita para muestrear mundos/RNG contrafactuales; el fork actual conserva continuación exacta.
2. La observación V1 conoce HP rival como ratio 0..10000; puede reducirse a barras/intervalos si la regla de visibilidad final lo exige.
3. El historial de memoria es deliberadamente conservador; futuros expertos podrán requerir campos públicos adicionales, que deberán añadirse mediante whitelist.
4. Antes de search profundo habrá que construir un proveedor de acciones candidatas que permanezca subordinado a la validación del servidor.

## Secuencia prevista

Tras cerrar esta fundación:

1. legal-action/candidate generation;
2. evaluadores tácticos interpretables;
3. perfiles/persona;
4. belief priors + modelado del jugador;
5. búsqueda sobre `BattleSimulationFork`;
6. telemetry/self-play/benchmark;
7. expertos neuronales/ensemble si demuestran ventaja.

La arquitectura permite cambiar el orden de estas capas sin rehacer Battle Core ni `TrainerBattleSession`.
