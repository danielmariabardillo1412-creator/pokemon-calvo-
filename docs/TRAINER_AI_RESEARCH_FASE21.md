# FASE 21 — Trainer AI Research Notes

Estado: investigación cerrada para implementación táctica V1.

## Objetivo

Construir entrenadores buenos, explicables y medibles sin introducir redes neuronales.
La investigación estudia ideas públicas de varios motores/agentes; FASE 21 reimplementa
conceptos sobre el Battle Core propio. No se copia código de terceros en esta fase.

## Fuentes estudiadas

- pokeemerald-expansion — arquitectura de flags, scoring táctico, smart switching,
  selección de revenge killers y variación de comportamiento.
  https://github.com/rh-hideout/pokeemerald-expansion
- Foul Play / poke-engine — búsqueda de combate competitivo, incertidumbre y
  tratamiento de acciones simultáneas; reservado principalmente para fases de búsqueda.
  https://github.com/pmariglia/foul-play
- Laplace Pokémon Showdown AI — mundos plausibles, información oculta, blunder guards,
  trazas y análisis empírico de derrotas.
  https://github.com/influxtion/Laplace-Pokemon-Showdown-AI
- Pokémon Champions Engine — MCTS/DUCT con evaluador heurístico; referencia para una
  futura capa de búsqueda no neuronal.
  https://github.com/edlz/pokemon-champions-engine
- Metamon — múltiples oponentes/baselines y evaluación masiva; referencia para el
  futuro laboratorio de self-play/benchmarks.
  https://github.com/UT-Austin-RPL/metamon
- Athena (literatura de agentes Pokémon competitivos) — preservación de estructura
  de equipo y respuestas únicas frente a amenazas futuras.

## Decisiones derivadas

1. Battle Core sigue siendo la única autoridad de legalidad.
2. Un cerebro nunca recibe BattleState, RNG ni CreatureInstance rivales.
3. La dificultad no concede información oculta.
4. El evaluador debe explicar por qué puntúa una acción.
5. La táctica de turno y el valor estratégico del equipo son capas distintas.
6. Los perfiles cambian prioridades/riesgo, no reglas ni acceso a información.
7. Los blunder guards bloquean únicamente errores demostrables con información legítima.
8. FASE 21 no incluye MCTS, minimax, red neuronal ni self-play de producción.
9. La búsqueda futura debe modelar selección simultánea de acciones, no un rival que
   mágicamente conoce nuestra acción antes de escoger la suya.
10. Toda mejora futura deberá compararse con seeds y benchmarks reproducibles.

## Componentes seleccionados para FASE 21

- TrainerActionSpace
- TrainerProfile
- TrainerTacticalEvaluator
- TrainerTeamStrategicEvaluator
- TrainerBlunderGuard
- TacticalTrainerBrain
- TrainerIntelligenceController
- TrainerTacticalBenchmark

## Límites conscientes

El daño rival no se estima leyendo estadísticas exactas ocultas. Cuando hace falta una
aproximación, se reconstruye un proxy neutral a partir de especie y nivel públicamente
observados. La traza identifica explícitamente el modelo `public_species_proxy_v1`.

La inferencia avanzada de sets, objetos, habilidades y rangos de velocidad queda para
FASE 22. La búsqueda con BattleSimulationFork queda para FASE 23+.
