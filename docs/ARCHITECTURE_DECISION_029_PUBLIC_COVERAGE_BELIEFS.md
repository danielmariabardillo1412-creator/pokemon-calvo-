# ADR-029 — Public Coverage Beliefs V1

## Estado

VALIDADA / CERRADA TECNICAMENTE.

## Contexto

FASE 27 demostró un límite legítimo de información: un movimiento oculto que no pertenecía al
prior público de level-up no podía aparecer en los mundos plausibles. FASE 28 corrigió la poda
de respuestas peligrosas ya conocidas, pero deliberadamente no inventó nuevas hipótesis.

La auditoría del pipeline de datos confirmó que `LearnSetEntry` conserva `method` y que el
adaptador fijado de PokeAPI importa `move_learn_method`. El dataset actual no conserva
`version_group`, por lo que podemos modelar compatibilidad pública histórica/importada, pero no
afirmar legalidad exacta por generación o versión.

## Decisión

FASE 29 separa dos problemas:

1. que una cobertura sea una hipótesis pública legítima;
2. que una cobertura peligrosa de baja confianza sobreviva el límite de cuatro movimientos del
   mundo plausible.

### 1. Priors de compatibilidad pública

`TrainerPublicCoverageBeliefInference` hereda `TrainerBeliefInference` y mantiene intactos los
priors level-up validados de FASE 22.

Solo se añaden tres métodos generalizables en V1:

- `machine`: 1600 bp;
- `tutor`: 1300 bp;
- `egg`: 900 bp.

Estos valores son **priors heurísticos de compatibilidad**, no probabilidades calibradas de uso.
Se validarán posteriormente en el laboratorio matemático. Nunca reducen la confianza de una
hipótesis level-up o revelada ya existente.

Métodos especiales como `form_change` quedan excluidos de V1. No se agrupan todos los métodos
no-level-up porque varios representan mecanismos excepcionales y no una cobertura genérica.

La procedencia se registra como
`public_species_coverage_compatibility_v1:<method>`.

### 2. Selección de cobertura relevante

`TrainerCoverageAwareWorldFactory` hereda la ordenación por amenaza de FASE 28 y conserva el
máximo de cuatro movimientos plausibles.

Si una cobertura pública compatible quedó fuera por su baja confianza:

- se selecciona la cobertura omitida más peligrosa contra el activo propio observado;
- nunca se expulsa un movimiento ya revelado;
- solo sustituye al movimiento no revelado menos peligroso de los cuatro seleccionados;
- solo sustituye si su amenaza estimada es estrictamente mayor;
- el número de movimientos plausibles no aumenta.

Por tanto, compatibilidad no equivale a certeza ni genera branching ilimitado.

### 3. Integración A/B

`TrainerPublicCoverageAdaptiveSearch` y `PublicCoverageAdaptiveTrainerBrain` son candidatos
separados sobre FASE 28.

`TrainerIntelligenceController` utiliza `TrainerPublicCoverageBeliefInference` como inferencia
por defecto cuando dispone de catálogo. Los tests históricos que instancian directamente
`TrainerBeliefInference` conservan el modelo original, lo que mantiene una regresión fuerte de
FASE 22.

## Frontera anti-cheat

FASE 29 sigue sin entregar a la inferencia:

- `BattleState` rival;
- `CreatureInstance` rival;
- RNG vivo;
- moveset real oculto;
- IV/EV/naturaleza rival;
- objeto o habilidad no revelados.

Una cobertura incompatible con el learnset público sigue ausente hasta revelarse.

Además, ninguna traza o creencia puede afirmar `version_group`, porque ese dato no existe en el
pipeline canónico actual.

## Resultados del gate FASE 29

El fixture causal convierte la nuke de branching de FASE 28 en una compatibilidad pública
`machine` de baja confianza y añade un cuarto señuelo `level_up` de alta confianza.

Resultado:

- **70 PASS / 0 FAIL**;
- level-up conserva el prior reciente de FASE 22;
- `machine = 1600 bp`, `tutor = 1300 bp`, `egg = 900 bp`;
- `form_change` excluido;
- movimiento incompatible ausente;
- procedencia pública de `machine` presente;
- ninguna creencia inventa `version_group`;
- la cobertura realmente incompatible del control histórico sigue invisible y el planner sigue
  perdiendo **0/6**, preservando la frontera anti-cheat;
- la nuke `machine` peligrosa sobrevive el cap de cuatro en el candidato FASE 29;
- `max_actions_per_side` continúa en 3;
- el candidato FASE 29 gana **6/6** el escenario de branching y abre con el debuff defensivo.

### Comparación A/B causal contra FASE 28

El brain FASE 28 se ejecutó con **la misma inferencia pública nueva**. Por tanto, ambos modelos
conocen la hipótesis `machine`; la única diferencia relevante es la selección de cobertura en el
mundo plausible.

Resultado:

- FASE 28: **0/6**;
- FASE 29: **6/6**;
- la traza FASE 28 no contiene la nuke porque los cuatro priors level-up la expulsan antes de
  buscar;
- la traza FASE 29 sí la contiene porque sustituye una cola débil por una cobertura públicamente
  compatible y más peligrosa.

Esto demuestra que la ganancia no procede de omnisciencia ni de aumentar el branching, sino de
combinar una hipótesis pública legítima con una poda más informativa.

## Regresión de inteligencia sobre FASE 26

El candidato FASE 29 se ejecutó sobre las 60 partidas del corpus estadístico existente.

Resultado:

- baseline: **48/60**;
- candidato FASE 29: **60/60**;
- mejoras emparejadas: **12**;
- regresiones emparejadas: **0**;
- pares iguales: **48**;
- 0 draws;
- 0 partidas inválidas;
- determinismo confirmado;
- gate de corpus: **36 PASS / 0 FAIL**.

El 60/60 sigue siendo evidencia dentro del corpus controlado, no una afirmación de superioridad
universal.

## Certificación

Sobre el HEAD de código y ADR previo al cierre documental
`17ab65fdc7aeea2dfaef0af18954a74b6cd16106` se obtuvieron **12/12 workflows SUCCESS**:

- FASE 29 public coverage beliefs;
- FASE 28 adaptive branching;
- FASE 27 search-limit benchmark;
- FASE 26 evaluation corpus;
- FASE 25 self-play;
- FASE 24 search-depth budget;
- FASE 23 search foundation;
- FASE 22 belief inference;
- FASE 21 tactical intelligence;
- FASE 20 intelligence foundation;
- FASE 19 trainer battle session;
- regresión global Godot 4.7.

El commit documental final debe repetir esta certificación antes de cerrar PR #25.

## Fuera de alcance

FASE 29 no implementa:

- acción ITEM;
- inventario de entrenador;
- selección de held items;
- naturalezas/EV/IV de loadout;
- team building;
- legalidad exacta por generación/version_group;
- MCTS.

Esas capacidades permanecen separadas para poder medir causalmente cada mejora.

## Siguiente decisión

FASE 30 debe abrir el tercer tipo de decisión autoritativa del entrenador: **ITEM**, con inventario
finito por NPC, consumo real del recurso y evaluación contrafactual contra MOVE/SWITCH. No debe
usar umbrales rígidos de HP ni inventario infinito.
