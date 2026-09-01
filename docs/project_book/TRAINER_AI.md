# CUADERNO TEMÁTICO — IA DE ENTRENADORES

Estado: **ACTIVO / SIGUIENTE WORKSTREAM TÉCNICO**.

Este documento consolida la continuidad útil de Trainer AI. No sustituye los ADR; evita tener que reconstruir FASE19–33 leyendo toda la historia antes de diseñar la siguiente fase.

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

Corpus estadístico reproducible. En el benchmark certificado de la fase, el baseline obtuvo 48/60 y el planner 60/60: 12 mejoras emparejadas y 0 regresiones. Es evidencia del corpus V1, no prueba de superioridad universal.

### FASE 27 — Search Limit Benchmark

Demuestra que aumentar profundidad no era el siguiente arreglo correcto. El límite observado estaba en cobertura de acciones y en información realmente oculta, no en un depth insuficiente demostrado.

### FASE 28 — Adaptive Branching / Action Coverage

Ordena amenazas/candidatos plausibles para recuperar respuestas relevantes sin ampliar indiscriminadamente branching, mundos o simulaciones. El conocimiento genuinamente oculto continúa oculto.

### FASE 29 — Public Coverage Beliefs

Añade priors públicos de machine/tutor/egg a baja confianza y mantiene fuera métodos incompatibles/especiales. Permite conservar coberturas públicas peligrosas dentro del límite acotado sin inventar sets concretos.

### FASE 30 — Trainer Item Actions

ITEM pasa a ser una acción autoritativa con bolsa finita. Revive continúa deshabilitado; si algún día se habilita para NPC especiales, la política prevista limita el efecto a máximo un Pokémon revivido por combate especial.

### FASE 31 — Strategic Switching V2

Base seria actual de decisión:

- `TrainerStrategicSwitchEvaluatorV2`
- `TrainerStrategicSwitchTacticalEvaluator`
- `StrategicSwitchingTrainerBrain`.

Modela escape de matchups sin ruta, hard counters, mejora ofensiva clara, anti-ping-pong, preservación de banca valiosa, sacrificio productivo y evita heal spam en matchups bloqueados.

La amenaza rival se estima solo con especie/nivel públicos, movimientos revelados, beliefs ponderados, fallback STAB público y estado observable.

**Los entrenadores serios futuros deben construirse sobre esta ruta**, no regresar a un brain antiguo de search-only.

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

Solo se materializan habilidades/held items que tienen runtime real. No se inventa legalidad exacta de generación cuando el dataset solo permite afirmar compatibilidad pública importada.

### FASE 33 — Trainer Team Composition

Introduce:

- `TrainerTeamDefinition`
- `TrainerTeamValidator`
- `TrainerTeamAnalyzer`
- `TrainerTeamComposer`
- `TrainerTeamFactory`.

Analiza distribución de roles, tipos defensivos, cobertura equipada, debilidades compartidas y respuestas disponibles. El compositor es greedy, determinista y acotado: produce NPC razonables, no un óptimo competitivo global.

## 3. Lo que NO debe duplicar la siguiente fase

Ya existen:

- personalidad táctica (`TrainerProfile`);
- beliefs/inferencia;
- search acotado;
- prior público de cobertura;
- objetos finitos;
- switching estratégico;
- loadouts y calidad individual;
- composición/análisis de equipo.

Por tanto, crear otra clase llamada genéricamente “perfil de entrenador” que vuelva a mezclar todo sería arquitectura duplicada.

## 4. Siguiente problema correcto: estilo vs expertise

La próxima fase debe estudiar una separación explícita entre:

### Estilo

Cómo prefiere jugar un entrenador.

Ya existe en `TrainerProfile`: balanced/aggressive/cautious/technical.

### Competencia / expertise

Qué tan bien utiliza las herramientas legítimas que tiene disponibles y qué calidad de preparación recibe.

Aquí pueden entrar, si el diseño lo confirma:

- brain/política usada;
- calidad de loadout;
- calidad/coherencia del equipo;
- uso de objetos y stock;
- umbrales/competencia de switching;
- sofisticación de beliefs públicos permitidos;
- tolerancia a errores o simplificaciones deliberadas en NPC básicos;
- evaluación estratégica disponible.

**Nunca** debe entrar “ver movimientos ocultos” o cualquier otro privilegio ilegal.

## 5. Arquetipos narrativos futuros

Líder, Alto Mando, Campeón y boss-tier están explícitamente fuera del alcance de FASE31–33 y son candidatos naturales del siguiente trabajo.

No están todavía congelados como una lista obligatoria. Primero hay que auditar cómo representar expertise sin mezclarlo con personalidad ni crear una clase monolítica.

Un posible resultado sería que un Líder y un Campeón compartan estilo `technical` pero tengan distinta calidad de preparación/competencia; o que dos líderes con igual expertise tengan estilos muy diferentes.

## 6. Restricciones para FASE 34

Antes de escribir código:

1. auditar componentes/prototipos antiguos de difficulty/archetype/expertise;
2. comprobar referencias a `TrainerProfile` para evitar duplicación;
3. decidir contrato separado de estilo y competencia;
4. mantener `StrategicSwitchingTrainerBrain` como base seria salvo evidencia contraria;
5. definir tests que demuestren diferencias intencionadas entre niveles sin cheating;
6. comparar candidatos contra el corpus existente;
7. no ampliar depth/branching/MCTS/red neuronal sin un límite demostrado.

## 7. Neural AI

Una IA neuronal sigue siendo una línea experimental futura, no el siguiente parche.

Primero conviene tener entrenadores no neuronales fuertes, medibles y con arquitectura limpia. Esa base servirá después como benchmark, generador de experiencias, adversario o teacher para experimentar con sistemas neuronales sin confundir fallos del motor/datos con fallos de aprendizaje.

## 8. Fuentes documentales

Decisiones formales principales:

- ADR 019–030: evolución de sesión, inteligencia, beliefs, search, evaluación, cobertura pública e items;
- ADR 031: Strategic Switching V2;
- ADR 032: Trainer Loadouts;
- ADR 033: Trainer Team Composition.

Investigación histórica preservada:

`docs/history/research/TRAINER_AI_RESEARCH_FASE21.md`.

Este cuaderno es el punto normal de entrada para continuar Trainer AI; acudir a los ADR cuando se necesite el detalle contractual original.
