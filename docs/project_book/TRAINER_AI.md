# CUADERNO TEMÁTICO — IA DE ENTRENADORES

Estado: **ACTIVO / REDISEÑO MAYOR PRE-FASE34**.

Baseline de partida certificado: `3c25f3185e67e255c65f161904e911908a28a5e2`.

Rama de revisión: `audit/trainer-ai-v3-random-cup-redesign-v1`.

Este documento es la memoria viva de Trainer AI. Consolida continuidad, decisiones, descubrimientos y cambios de premisa para no depender del contexto de una conversación larga. Los ADR conservan el detalle contractual histórico, pero este cuaderno manda sobre qué partes siguen activas, cuáles necesitan adaptación y cuáles han quedado obsoletas.

---

## 0. CAMBIO DE PREMISA — DATA V3 + RANDOM CUP + MUERTE PERMANENTE

Antes de continuar con FASE34 se detectó que la IA de entrenadores fue diseñada parcialmente sobre un dataset bastante más pequeño e incompleto que el actual y bajo una premisa de equipos más planificables.

Desde DATA V3 y la definición del modo Random Cup, esas premisas ya no pueden asumirse.

### 0.1 DATA V3 cambia el conocimiento disponible

DATA V3 está cerrado y certificado con un catálogo mucho más amplio:

- 1.025 especies;
- 326 formas;
- 18 tipos runtime;
- 919 movimientos runtime/data auditados;
- 373 habilidades;
- 2.222 objetos;
- 61.102 entradas de learnset;
- 554 evoluciones.

Esto significa que una IA que pasó sus tests antiguos puede seguir funcionando técnicamente y aun así estar tomando decisiones desde supuestos obsoletos o demasiado estrechos.

Descubrimiento concreto ya confirmado:

- `TrainerPublicCoverageBeliefInference` todavía documenta que el dataset no preserva `version_group`.
- `TrainerLoadoutValidator` repite la misma premisa.
- DATA V3 sí preserva `version_group` y `order` en `LearnSetEntry`.

Por tanto, **tests verdes no bastan para certificar que el diseño antiguo aprovecha correctamente DATA V3**.

### 0.2 Random Cup invalida la especialización fija por tipo

Los Pokémon de cada entrenador se obtendrán de forma aleatoria. Un entrenador no puede depender de una identidad de equipo como:

- entrenador de Agua;
- entrenador de Fuego;
- entrenador de Planta;
- cualquier otra especialización que presuponga recibir especies de un tipo concreto.

El entrenador debe adaptarse a **la plantilla real que le haya tocado**.

La identidad del entrenador debe ser principalmente:

- conductual;
- táctica;
- estratégica;
- de gestión del riesgo;
- de explotación del roster disponible.

Un mismo entrenador debe poder comportarse de forma coherente aunque en dos partidas reciba equipos completamente distintos.

### 0.3 Muerte permanente cambia la función objetivo

En Random Cup, un Pokémon eliminado al morir no es solo una pérdida dentro del combate actual. Es una pérdida persistente del roster.

La IA ya no puede valorar una línea únicamente con:

`probabilidad de ganar este combate`.

Debe considerar al menos dos horizontes:

1. **Táctico:** cómo ganar el combate actual.
2. **Estratégico/campaña:** cómo ganar sin destruir innecesariamente el potencial futuro del roster.

Esto afecta especialmente a:

- switching;
- sacrificios;
- curación;
- preservación de piezas clave;
- selección de lead;
- riesgo aceptable;
- valoración de un KO propio a cambio de ventaja inmediata;
- uso de objetos limitados;
- evaluación de Pokémon redundantes frente a Pokémon irremplazables dentro del roster actual.

Debe existir una noción explícita o derivada de **valor de supervivencia / valor estratégico del miembro**, separada de su utilidad táctica inmediata.

### 0.4 Consecuencia de arquitectura

**FASE34 queda en pausa.**

No se diseñarán todavía arquetipos/dificultad encima de la arquitectura antigua como si nada hubiera cambiado.

Primero se realizará una auditoría completa:

`TRAINER AI FASE19–33 × DATA V3 × RANDOM CUP × PERMADEATH`

Cada componente se clasificará como:

- **CONSERVAR**;
- **ADAPTAR**;
- **REHACER / RETIRAR**.

No se reescribe por estética. Solo se cambia aquello cuya premisa haya quedado obsoleta o cuya interfaz no permita representar correctamente el nuevo juego.

---

## 1. Principios que siguen siendo canónicos

Estas reglas permanecen válidas salvo evidencia técnica en contra:

- Battle Core es la autoridad de legalidad.
- El cerebro no recibe `BattleState` vivo ni RNG rival.
- No recibe moveset oculto, naturaleza/IV/EV rivales, objeto no revelado ni banca no observada.
- La dificultad no concede información oculta.
- Las creencias deben proceder de información pública, evidencia observada o priors explícitos y auditables.
- La selección simultánea de acciones debe modelarse como simultánea.
- Las mejoras deben compararse mediante seeds/corpus/benchmarks reproducibles.
- La IA debe ser mejor por razonamiento, adaptación y uso legítimo de información, no por cheating.

---

## 2. Stack histórico existente FASE19–33

El stack antiguo no se considera basura. Es una base probada que ahora debe auditarse contra las nuevas premisas.

### FASE19 — Trainer Battle Session

Sesión autoritativa contra entrenador y separación del controlador de decisiones respecto al Battle Core.

**Estado preliminar:** probablemente CONSERVAR.

### FASE20 — Trainer Intelligence Foundation

Contexto sanitizado, trazas, legalidad e infraestructura de inteligencia.

**Estado preliminar:** CONSERVAR.

### FASE21 — Tactical Intelligence

Evaluación táctica explicable, estrategia de equipo, blunder guards y `TrainerProfile`.

Perfiles existentes:

- `balanced`;
- `aggressive`;
- `cautious`;
- `technical`.

Estos perfiles son conductuales, no especializaciones por tipo, y por ello encajan bien con Random Cup.

**Estado preliminar:** CONSERVAR como concepto; AUDITAR pesos frente a permadeath.

### FASE22 — Belief Inference

Inferencia sobre información rival sin convertir ausencia de evidencia en certeza.

**Estado preliminar:** ADAPTAR a DATA V3.

### FASE23 — Search Foundation

Mundos plausibles y matriz de acciones simultáneas sobre contexto seguro.

**Estado preliminar:** CONSERVAR infraestructura; REEVALUAR función de utilidad.

### FASE24 — Search Depth & Budget

Búsqueda determinista y acotada.

**Estado preliminar:** CONSERVAR límites hasta que un benchmark moderno demuestre un cuello de botella real.

### FASE25 — Self-Play Evaluation

Infraestructura determinista de evaluación.

**Estado preliminar:** CONSERVAR.

### FASE26 — Evaluation Corpus

Corpus reproducible. El antiguo benchmark 48/60 vs 60/60 es evidencia histórica del corpus V1, no certificación de la IA actual sobre DATA V3/Random Cup.

**Estado preliminar:** infraestructura CONSERVAR; CORPUS debe ampliarse/reconstruirse.

### FASE27 — Search Limit Benchmark

Demostró que el problema observado entonces no era simplemente falta de profundidad.

**Estado preliminar:** conservar como evidencia histórica, no asumir que cubre el nuevo entorno.

### FASE28 — Adaptive Branching

Cobertura ordenada de amenazas sin ampliar indiscriminadamente el árbol.

**Estado preliminar:** CONSERVAR concepto; REVALIDAR con catálogo V3.

### FASE29 — Public Coverage Beliefs

Priors públicos de machine/tutor/egg.

**Estado preliminar:** ADAPTAR.

Motivo confirmado: contiene premisas antiguas sobre ausencia de `version_group` que DATA V3 ya invalida.

### FASE30 — Trainer Item Actions

Bolsa finita y acciones de objetos.

**Estado preliminar:** ADAPTAR a economía/persistencia de Random Cup.

Revive continúa deshabilitado salvo futura regla explícita.

### FASE31 — Strategic Switching V2

Componentes principales:

- `TrainerStrategicSwitchEvaluatorV2`;
- `TrainerStrategicSwitchTacticalEvaluator`;
- `StrategicSwitchingTrainerBrain`.

Modela hard counters, escape de matchups sin ruta, mejora ofensiva, anti-ping-pong, preservación y sacrificio productivo.

**Estado preliminar:** ADAPTAR DE FORMA IMPORTANTE.

El switching ya conoce preservación, pero debe incorporar el coste persistente de perder un miembro del roster y distinguir utilidad táctica de valor estratégico futuro.

### FASE32 — Trainer Loadouts

Loadout atómico con especie, nivel, rol/calidad, naturaleza, IV/EV, habilidad, objeto y moveset.

Roles V1:

- balanced;
- physical_attacker;
- special_attacker;
- fast_attacker;
- bulky_physical;
- bulky_special;
- support.

**Estado preliminar:** ADAPTAR.

Los roles siguen siendo útiles porque describen lo que un Pokémon puede hacer, no qué tipo debe tener. Sin embargo:

- la legalidad/compatibilidad debe reevaluarse con DATA V3;
- el generador no debe asumir conocimiento antiguo del learnset;
- debe decidirse qué partes del loadout son aleatorias, heredadas o configurables en Random Cup;
- el valor del loadout debe incluir su importancia relativa dentro del roster recibido.

### FASE33 — Trainer Team Composition

Componentes:

- `TrainerTeamDefinition`;
- `TrainerTeamValidator`;
- `TrainerTeamAnalyzer`;
- `TrainerTeamComposer`;
- `TrainerTeamFactory`.

`TrainerTeamAnalyzer` ya analiza dinámicamente roles, tipos, cobertura, resistencias y debilidades de una plantilla dada. Ese concepto encaja bien con equipos aleatorios.

`TrainerTeamComposer`, en cambio, selecciona especies de un pool buscando una composición mejor. En Random Cup el entrenador normalmente **no elige las especies que recibe**.

**Estado preliminar:**

- Analyzer: CONSERVAR/ADAPTAR.
- Composer como selector de especies: REHACER o retirar del flujo Random Cup.
- Posible nuevo papel: organizar/interpretar una plantilla ya asignada, no escoger sus especies.

---

## 3. Regla canónica de identidad del entrenador

Un entrenador **no se define por el tipo Pokémon que posee**.

Se define por cómo usa lo que le toca.

Ejemplos de dimensiones válidas:

- agresividad;
- cautela;
- conservación de plantilla;
- tolerancia al riesgo;
- uso de status/setup;
- preferencia por presión inmediata;
- sofisticación de switching;
- gestión de recursos;
- capacidad de identificar roles dentro de un equipo aleatorio;
- calidad de adaptación;
- competencia/expertise.

Dos entrenadores con exactamente los mismos Pokémon pueden jugar de forma muy distinta.

La personalidad y la competencia deben permanecer separadas:

- **estilo:** qué tipo de decisiones prefiere;
- **expertise:** qué tan bien utiliza las herramientas legítimas disponibles.

Ninguna de las dos concede información oculta.

---

## 4. Nuevo problema central: adaptación al roster aleatorio

La IA debe poder recibir una plantilla arbitraria y construir una interpretación interna de esa plantilla.

Como mínimo deberá poder identificar dinámicamente:

- atacante físico;
- atacante especial;
- velocidad/cleaner;
- bulky físico;
- bulky especial;
- soporte;
- cobertura única;
- resistencia única;
- respuesta a amenazas concretas;
- miembro redundante;
- miembro difícil de reemplazar;
- candidato a lead;
- miembro que conviene reservar;
- sacrificio menos costoso si la situación exige uno.

No se presupone que todos los equipos tengan todos los roles.

Una buena IA debe saber jugar también una plantilla mala, desequilibrada o extraña.

---

## 5. Valor de campaña / permadeath

Debe diseñarse una capa que valore el efecto de una decisión más allá del combate actual.

No se congela todavía una fórmula concreta, pero la auditoría debe estudiar variables como:

- HP y estado actuales;
- potencia del miembro;
- cobertura exclusiva;
- función estratégica única;
- redundancia dentro del roster;
- disponibilidad de sustitutos;
- salud/estado del resto del equipo;
- coste de perder acceso a una habilidad/movimiento/rol;
- valor esperado en combates futuros;
- importancia de conservar recursos consumibles.

La IA no debe volverse cobarde por sistema. A veces sacrificar un Pokémon seguirá siendo correcto. La diferencia es que ahora ese sacrificio debe ser **consciente de su coste persistente**.

---

## 6. Revisión obligatoria DATA V3

Antes de tocar dificultad/arquetipos se auditarán al menos:

- `TrainerBeliefInference`;
- `TrainerPublicCoverageBeliefInference`;
- `TrainerPlausibleWorldBuilder` y capas de search relacionadas;
- `TrainerRoleLoadoutGenerator`;
- `TrainerLoadoutValidator`;
- `TrainerTeamAnalyzer`;
- `TrainerTeamComposer`;
- `StrategicSwitchingTrainerBrain` y sus evaluadores;
- item decision/economy;
- corpus y escenarios de evaluación.

Preguntas de auditoría:

1. ¿Consume realmente el catálogo V3 o presupone fixtures/datos antiguos?
2. ¿Ignora campos que ahora sí existen?
3. ¿Hace inferencias demasiado amplias debido a limitaciones antiguas ya resueltas?
4. ¿Evalúa los 18 tipos y la cobertura moderna de forma genérica?
5. ¿Distingue runtime-supported, partial/data-only y unsupported cuando corresponde?
6. ¿Puede trabajar con cualquier especie/forma válida del pool?
7. ¿Sus tests prueban comportamiento realista o solo fixtures sintéticos estrechos?
8. ¿Su función objetivo sigue siendo válida con muerte permanente?

---

## 7. Corpus de evaluación V2 requerido

El corpus antiguo no se borra, pero deja de ser suficiente para certificar la siguiente IA.

El futuro corpus debe incluir escenarios derivados del catálogo moderno y plantillas aleatorias, por ejemplo:

- equipos equilibrados;
- equipos con debilidad compartida grave;
- equipos sin atacante especial;
- equipos con una única respuesta a una amenaza;
- equipos con una pieza excepcional y varias mediocres;
- equipos con roles redundantes;
- situaciones donde sacrificar gana el combate pero empeora claramente la campaña;
- situaciones donde conservar demasiado hace perder un combate que debía arriesgarse;
- decisiones de objeto bajo recursos persistentes;
- matchups con cobertura machine/tutor/egg dependiente de procedencia/versionado.

La evaluación debe separar:

- calidad táctica del combate;
- supervivencia del roster;
- consumo de recursos;
- capacidad de adaptación a equipos no diseñados a mano.

---

## 8. Clasificación preliminar de arquitectura

### CONSERVAR casi seguro

- separación Battle Core / cerebro;
- `TrainerDecisionContext` sanitizado;
- prohibición de cheating;
- trazas explicables;
- `TrainerProfile` como estilo conductual;
- infraestructura de self-play;
- matriz simultánea de acciones;
- idea de `TrainerTeamAnalyzer`;
- búsqueda acotada mientras no haya evidencia de un límite nuevo.

### ADAPTAR

- beliefs y public coverage a DATA V3;
- loadouts y legalidad;
- roles sobre roster aleatorio;
- switching con valor persistente;
- items con economía/persistencia;
- corpus;
- evaluación de equipo;
- selección de lead;
- heurísticas de preservación/sacrificio.

### REHACER / RETIRAR del flujo Random Cup

- cualquier especialización fija por tipo;
- cualquier lógica que presuponga que el entrenador puede elegir sus especies si Random Cup no lo permite;
- `TrainerTeamComposer` como selector de especies para el flujo principal, salvo que encuentre otro uso legítimo;
- cualquier contrato basado en carencias del dataset antiguo que DATA V3 ya haya resuelto.

Esta clasificación es preliminar y se actualizará con evidencia de código/tests.

---

## 9. FASE34 queda redefinida

La antigua propuesta de “Trainer Archetypes / Difficulty Profiles V1” **no se ejecuta todavía**.

El siguiente tramo real es una auditoría/rediseño de compatibilidad.

Nombre de trabajo provisional:

**PRE-FASE34 — Trainer AI Modernization Audit / Random Cup & Permadeath Redesign**.

Salida esperada:

1. mapa completo CONSERVAR/ADAPTAR/REHACER;
2. contrato canónico de Random Cup;
3. contrato canónico de permadeath para la IA;
4. lista de supuestos obsoletos por DATA V3;
5. nuevo corpus de evaluación requerido;
6. orden de implementación por tramos pequeños y certificables;
7. solo después, redefinir FASE34 sobre la arquitectura moderna.

---

## 10. Regla de trabajo

Antes de cada cirugía relevante:

- registrar el objetivo y el hallazgo en este cuaderno;
- no perder decisiones importantes en el chat;
- mantener SHAs, pruebas y resultados reproducibles;
- no considerar un componente “bueno” solo porque compile o pase un fixture antiguo;
- no rehacer componentes que sigan siendo correctos;
- actualizar este cuaderno después de cada tranche certificada.

Este cuaderno es el punto de recuperación si se llena o se pierde el contexto de conversación.

---

## 11. Fuentes documentales históricas

Decisiones formales principales:

- ADR 019–030: sesión, inteligencia, beliefs, search, evaluación, cobertura pública e items;
- ADR 031: Strategic Switching V2;
- ADR 032: Trainer Loadouts;
- ADR 033: Trainer Team Composition.

Investigación histórica:

`docs/history/research/TRAINER_AI_RESEARCH_FASE21.md`.

DATA V3 consolidado:

`docs/project_book/DATA_V3.md`.
