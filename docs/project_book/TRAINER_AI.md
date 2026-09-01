# CUADERNO TEMÁTICO — IA DE ENTRENADORES

Estado: **ACTIVO / FASE 34 — REBASELINE SOBRE DATA V3**.

Este documento consolida la continuidad útil de Trainer AI. No sustituye los ADR; evita tener que reconstruir FASE19–33 leyendo toda la historia antes de continuar.

## 1. Principio rector

La IA debe ser buena por **razonamiento, prioridades, composición y uso correcto de información legítima**, no porque vea datos ocultos.

Reglas permanentes:

- Battle Core es la autoridad de legalidad.
- El cerebro no recibe `BattleState` vivo ni RNG rival.
- No recibe moveset oculto, naturaleza/IV/EV rivales, objeto no revelado ni banca no observada.
- La dificultad no concede información oculta.
- Las creencias deben proceder de información pública, evidencia observada o priors explícitos y auditables.
- La selección simultánea de acciones debe modelarse como simultánea; el rival no conoce mágicamente nuestra acción antes de elegir.
- Las mejoras deben compararse mediante seeds/corpus/benchmarks reproducibles.
- **Existencia en DATA V3 no equivale a soporte runtime.** Ninguna capa de Trainer AI debe tratar un movimiento, habilidad, objeto o evolución `DATA_ONLY`/`UNSUPPORTED` como si Battle Core pudiera ejecutarlo fielmente.

Estas reglas nacen de FASE20–21 y siguen siendo válidas en el stack moderno.

## 2. Stack existente FASE19–33

### FASE 19 — Trainer Battle Session

Integra combate contra entrenador como sesión autoritativa y separa el controlador de decisiones de las reglas del Battle Core.

### FASE 20 — Trainer Intelligence Foundation

Establece contexto sanitizado, trazas, legalidad e infraestructura de inteligencia.

### FASE 21 — Tactical Intelligence

Introduce evaluación táctica explicable, estrategia de equipo, blunder guards y perfiles de personalidad.

`TrainerProfile` ya existe y define:

- `balanced`
- `aggressive`
- `cautious`
- `technical`.

Estos perfiles modifican pesos/prioridades; **no** modifican legalidad ni acceso a información.

### FASE 22 — Belief Inference

Amplía el estado de creencias sobre información rival sin convertir ausencia de evidencia en certeza.

### FASE 23 — Search Foundation

Introduce mundos plausibles y matriz de acciones simultáneas sobre contexto seguro. No usa información oculta del `BattleState` y no introduce MCTS.

### FASE 24 — Search Depth & Budget

Búsqueda determinista y acotada. La profundidad normal permanece limitada; no se amplía presupuesto sin contraejemplos que demuestren una necesidad real.

### FASE 25 — Self-Play Evaluation

Infraestructura determinista para comparar cerebros mediante self-play y medir diferencias en lugar de juzgarlas solo por intuición.

### FASE 26 — Evaluation Corpus

Corpus estadístico reproducible. En el benchmark certificado de la fase, el baseline obtuvo 48/60 y el planner 60/60: 12 mejoras emparejadas y 0 regresiones.

**Límite ahora explícito:** esta evidencia era un corpus V1 sintético y anterior al cierre DATA V3. Se conserva como regresión histórica, pero ya no basta para certificar que la IA representa bien el juego actual con 1.025 especies, 919 movimientos y 61.102 entradas de learnset.

### FASE 27 — Search Limit Benchmark

Demuestra que aumentar profundidad no era el siguiente arreglo correcto. El límite observado estaba en cobertura de acciones y en información realmente oculta, no en un depth insuficiente demostrado.

Ese resultado se conserva, pero FASE34 deberá comprobar si el universo DATA V3 aporta contraejemplos reales antes de seguir tratándolo como límite operativo suficiente.

### FASE 28 — Adaptive Branching / Action Coverage

Ordena amenazas/candidatos plausibles para recuperar respuestas relevantes sin ampliar indiscriminadamente branching, mundos o simulaciones. El conocimiento genuinamente oculto continúa oculto.

### FASE 29 — Public Coverage Beliefs

Añade priors públicos de machine/tutor/egg a baja confianza y mantiene fuera métodos incompatibles/especiales. Permite conservar coberturas públicas peligrosas dentro del límite acotado sin inventar sets concretos.

**Supuesto ahora obsoleto:** esta fase fue diseñada bajo el contrato de que el dataset no conservaba `version_group`. DATA V3 sí lo preserva en `LearnSetEntry`. Por tanto, la inferencia pública version-agnostic de FASE29 debe reauditarse y, donde corresponda, usar la procedencia coherente de DATA V3 en vez de mantener deliberadamente una limitación antigua.

### FASE 30 — Trainer Item Actions

ITEM pasa a ser una acción autoritativa con bolsa finita. Revive continúa deshabilitado; si algún día se habilita para NPC especiales, la política prevista limita el efecto a máximo un Pokémon revivido por combate especial.

### FASE 31 — Strategic Switching V2

Base seria actual de decisión:

- `TrainerStrategicSwitchEvaluatorV2`
- `TrainerStrategicSwitchTacticalEvaluator`
- `StrategicSwitchingTrainerBrain`.

Modela escape de matchups sin ruta, hard counters, mejora ofensiva clara, anti-ping-pong, preservación de banca valiosa, sacrificio productivo y evita heal spam en matchups bloqueados.

La amenaza rival se estima solo con especie/nivel públicos, movimientos revelados, beliefs ponderados, fallback STAB público y estado observable.

**Los entrenadores serios futuros deben construirse sobre esta ruta salvo que FASE34 demuestre un defecto estructural concreto.** No regresar a un brain antiguo de search-only.

### FASE 32 — Trainer Loadouts

Un loadout es una unidad atómica:

- especie y nivel;
- rol/calidad;
- naturaleza;
- IV/EV;
- habilidad;
- held item;
- moveset;
- procedencia.

Roles V1:

- balanced
- physical_attacker
- special_attacker
- fast_attacker
- bulky_physical
- bulky_special
- support.

Calidades:

- basic: IV15 / EV0
- trained: IV25 + inversión moderada
- expert: IV31 + inversión especializada dentro de 510 EV.

Habilidades y held items ya se restringieron a runtime real. La legalidad/selección de movimientos fue diseñada con un contrato de datos anterior y debe reauditarse contra la frontera DATA V3 completa, especialmente para impedir que un movimiento canónico `DATA_ONLY` o `UNSUPPORTED` sea considerado una opción ejecutable solo porque existe y pertenece al learnset.

### FASE 33 — Trainer Team Composition

Introduce:

- `TrainerTeamDefinition`
- `TrainerTeamValidator`
- `TrainerTeamAnalyzer`
- `TrainerTeamComposer`
- `TrainerTeamFactory`.

Analiza distribución de roles, tipos defensivos, cobertura equipada, debilidades compartidas y respuestas disponibles. El compositor es greedy, determinista y acotado: produce NPC razonables, no un óptimo competitivo global.

Con DATA V3 debe revalidarse con especies/learnsets/coberturas canónicas representativas; pasar sus fixtures históricos no demuestra por sí solo que el heurístico siga bien calibrado sobre el universo actual.

## 3. Hallazgo material tras cerrar DATA V3

Antes de diseñar nuevos niveles de entrenador se planteó una cuestión correcta: FASE19–33 se construyó mientras el proyecto todavía trabajaba con un dataset más pequeño, incompleto y en varios puntos incorrecto. DATA V3 cambió materialmente el contrato de entrada.

Auditoría inicial sobre el baseline certificado `3c25f3185e67e255c65f161904e911908a28a5e2`:

- `TrainerPlausibleWorldFactory` es mayoritariamente data-driven y consume `DefinitionCatalog`, especies, learnsets y beliefs; esa arquitectura es reutilizable y se beneficia automáticamente de DATA V3.
- `TrainerPublicCoverageBeliefInference` conserva explícitamente el supuesto antiguo de que no existe `version_group`; ese supuesto ya es falso.
- `LearnSetEntry` en el baseline actual contiene `version_group`.
- `TrainerLoadoutValidator` y `TrainerRoleLoadoutGenerator` deben auditarse contra la nueva frontera de capability de movimientos; la existencia canónica ya no puede usarse como sinónimo de ejecución runtime.
- `TrainerEvaluationCorpus` es una infraestructura genérica reutilizable, pero la evidencia histórica FASE26 es sintética V1 y demasiado estrecha para certificar el comportamiento sobre DATA V3.
- El gran aumento de especies, movimientos y learnsets puede cambiar qué candidatos entran en los límites acotados de mundos/acciones. No se ampliarán esos límites por intuición: primero se buscarán contraejemplos DATA V3 reproducibles.

Conclusión: **no se tira FASE19–33**, pero tampoco se considera automáticamente revalidado por el hecho de que sus tests históricos sigan verdes.

## 4. Nueva FASE 34 — Trainer AI Rebaseline on DATA V3

FASE34 deja de ser, por ahora, “difficulty/archetypes”. Su objetivo es asegurar que la IA existente razona con el contrato DATA V3 actual y que sus límites siguen siendo honestos.

### Alcance obligatorio

1. Mapear cada subsistema de Trainer AI contra los dominios DATA V3 que consume.
2. Localizar supuestos heredados de V1/V2 o de la primera importación V3.
3. Hacer `version_group`-aware la inferencia/compatibilidad donde DATA V3 ya aporta esa procedencia.
4. Verificar explícitamente capability runtime de movimientos, habilidades y objetos usados por Trainer AI.
5. Revalidar plausible worlds y ordenación de candidatos sobre el universo canónico actual.
6. Revalidar loadouts, composición de equipos y switching con casos reales DATA V3.
7. Crear un banco/corpus DATA V3 reproducible con especies, tipos, roles, coberturas y matchups canónicos representativos.
8. Conservar el corpus sintético FASE26 como regresión histórica; no sustituirlo, sino complementarlo.
9. Reejecutar Search Limit/Adaptive Branching contra contraejemplos DATA V3.
10. Mantener los presupuestos actuales salvo evidencia reproducible de que son el cuello de botella.
11. Mantener anti-cheat y Battle Core como autoridad sin excepciones.

### Lo que FASE34 no hará por defecto

- no añadirá Líder/Alto Mando/Campeón todavía;
- no introducirá MCTS o red neuronal;
- no aumentará depth/worlds/branch caps para “aprovechar más datos” sin una prueba causal;
- no convertirá DATA_ONLY en runtime;
- no reabrirá DATA V3 salvo encontrar una regresión real del propio DATA.

## 5. Qué se conserva y qué se reaudita

### Se conserva como arquitectura base

- frontera anti-cheat y `TrainerDecisionContext` sanitizado;
- legalidad autoritativa de Battle Core;
- búsqueda simultánea determinista;
- arquitectura de beliefs;
- fábrica de mundos plausibles;
- objetos finitos;
- switching estratégico;
- contratos de loadout/equipo;
- infraestructura de self-play/corpus/benchmark.

### Se reaudita antes de extender

- priors públicos y `version_group`;
- legalidad/capability de movimientos usados por loadouts y beliefs;
- cobertura de candidatos bajo los límites de branching;
- heurísticos de loadout/composición con especies reales V3;
- evaluación de amenazas/switching con el catálogo ampliado;
- validez del corpus como evidencia representativa.

## 6. Estilo vs expertise queda para FASE 35

`TrainerProfile` ya representa estilo:

- balanced
- aggressive
- cautious
- technical.

La futura competencia/expertise seguirá siendo una capa separada. Candidatos narrativos: entrenador ordinario, entrenador competente, Líder, Alto Mando y Campeón/boss-tier.

Pero esa capa se diseñará **después de FASE34**, porque no tiene sentido calibrar dificultad sobre una IA que todavía no ha sido rebaselined contra el dataset canónico actual.

La regla anti-cheat se mantiene: mayor expertise significa usar mejor información legítima, mejor preparación y mejores decisiones; nunca ver información oculta.

## 7. Criterio de éxito de FASE 34

FASE34 se podrá cerrar solo si:

- no quedan supuestos de datos antiguos que contradigan DATA V3 en las superficies auditadas;
- Trainer AI no puede seleccionar/razonar como ejecutable una capability que el runtime no soporte;
- existe evidencia DATA V3 reproducible además del corpus sintético histórico;
- los límites de search/branching quedan confirmados o modificados únicamente por contraejemplos medidos;
- todos los gates Trainer históricos permanecen verdes;
- DATA V3 permanece estable;
- la matriz completa del repositorio certifica el HEAD exacto final.

## 8. Neural AI

Una IA neuronal sigue siendo una línea experimental futura, no el siguiente parche.

Primero conviene tener entrenadores no neuronales fuertes, medibles y con arquitectura limpia. Esa base servirá después como benchmark, generador de experiencias, adversario o teacher para experimentar con sistemas neuronales sin confundir fallos del motor/datos con fallos de aprendizaje.

## 9. Fuentes documentales

Decisiones formales principales:

- ADR 019–030: evolución de sesión, inteligencia, beliefs, search, evaluación, cobertura pública e items;
- ADR 031: Strategic Switching V2;
- ADR 032: Trainer Loadouts;
- ADR 033: Trainer Team Composition.

Investigación histórica preservada:

`docs/history/research/TRAINER_AI_RESEARCH_FASE21.md`.

Baseline padre de FASE34:

`3c25f3185e67e255c65f161904e911908a28a5e2`

Rama de auditoría/rebaseline:

`audit/trainer-ai-data-v3-rebaseline-v1`

Este cuaderno es el punto normal de entrada para continuar Trainer AI; acudir a los ADR cuando se necesite el detalle contractual original.
