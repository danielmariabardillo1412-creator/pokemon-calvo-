# ADR-029 — Public Coverage Beliefs V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACION.

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

## Validación requerida

El gate debe demostrar al menos:

- priors machine/tutor/egg con menor confianza que level-up;
- métodos especiales excluidos;
- movimiento incompatible ausente;
- procedencia pública explícita;
- ausencia de `version_group` inventado;
- cobertura peligrosa sobreviviendo al cap de cuatro sin ampliar branching;
- comparación A/B donde FASE 28 conoce la creencia pero la poda y FASE 29 la conserva;
- cobertura realmente incompatible todavía invisible;
- determinismo;
- corpus FASE 26 ejecutado con el candidato FASE 29 sin regresiones;
- todos los gates históricos y la regresión global verdes sobre el mismo SHA.

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
