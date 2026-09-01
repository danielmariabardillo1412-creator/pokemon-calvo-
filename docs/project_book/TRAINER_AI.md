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

---

## 12. Auditoría técnica PRE-FASE34 — primeros hallazgos confirmados

Checkpoint de auditoría posterior al cambio de premisa. Todavía **no se ha modificado código de IA**.

### 12.1 `TrainerSearchStateEvaluator` — REHACER FUNCIÓN DE UTILIDAD

El evaluador de búsqueda actual es deliberadamente táctico y de combate aislado:

- `TERMINAL_SCORE = 100000`;
- `KO_SCORE = 7000`;
- todo KO propio recibe el mismo coste;
- la pérdida de HP se valora como suma de ratios de HP;
- los estados persistentes reciben un coste fijo.

Incompatibilidad crítica con permadeath:

- si `foe_alive_after == 0`, devuelve inmediatamente `TERMINAL_SCORE` por `simulated_victory`;
- ese retorno ocurre **antes** de descontar KOs propios, HP perdido o daño estratégico al roster;
- por tanto, una simulación que gana el combate dejando el roster gravemente mutilado sigue siendo una victoria terminal máxima para esta capa.

Esto era razonable para optimizar un combate aislado. No es una función objetivo válida para Random Cup con muerte permanente.

**Clasificación:** infraestructura de búsqueda CONSERVAR; función de utilidad REHACER/SEPARAR en horizonte táctico + horizonte de campaña.

### 12.2 `TrainerTeamStrategicEvaluator` — CONSERVAR CONCEPTO / AMPLIAR HORIZONTE

Ya existe una capa de preservación de equipo útil:

- detecta si el activo es la única respuesta conocida a otra amenaza observada;
- con HP bajo, bonifica cambiar para preservarlo;
- penaliza arriesgarlo innecesariamente;
- solo usa datos propios completos + rivales ya observados.

Esto demuestra que la arquitectura ya tiene una noción embrionaria de valor estratégico.

Limitación:

- “futuro” significa amenazas observadas que quedan **dentro del combate actual**;
- no conoce el valor del Pokémon para la copa/campaña posterior.

**Clasificación:** CONSERVAR y ampliar mediante una capa de valor de roster/campaña, sin romper la frontera de información rival.

### 12.3 `TrainerStrategicSwitchEvaluatorV2` — ADAPTACIÓN MAYOR

La implementación V2 ya contiene:

- `KEY_BENCH_EXPOSURE_PENALTY`;
- `PRODUCTIVE_SACRIFICE_BONUS`;
- `_future_value_bp()`;
- comparación entre valor futuro del activo y la banca;
- protección frente a entradas malas de una pieza importante;
- una ventana explícita de `productive_sacrifice_window`.

Sin embargo, `_future_value_bp()` calcula el valor medio del Pokémon únicamente contra **oponentes observados que quedan en el combate actual**.

Consecuencia:

- el concepto de “sacrificio productivo” puede ser correcto en batalla aislada y desastroso bajo permadeath;
- el valor futuro actual no representa rareza, cobertura única del roster, reemplazabilidad ni utilidad en combates posteriores.

**Clasificación:** ADAPTAR DE FORMA IMPORTANTE. No eliminar el switching V2: conservar sus heurísticas tácticas y añadir una autoridad estratégica de campaña que pueda vetar/penalizar sacrificios según contexto.

### 12.4 `TrainerDecisionContext` — CONSERVAR FRONTERA / EXTENDER DE FORMA SEGURA

Contrato actual:

- `TrainerObservation`;
- snapshot de beliefs;
- snapshot de memoria de batalla;
- acciones legales.

No contiene `BattleState`, `CreatureInstance` rival ni RNG vivo, lo cual sigue siendo correcto.

Pero tampoco contiene ningún estado persistente de Random Cup/campaña.

Para permadeath hará falta un contexto estratégico propio, sanitizado, probablemente como snapshot separado, que pueda incluir **solo información legítima del propio entrenador/campaña**, por ejemplo estado persistente de su roster y recursos. No debe convertirse en una puerta trasera hacia información oculta rival.

**Clasificación:** CONSERVAR interfaz de seguridad; EXTENDER contrato con contexto de campaña cuando sus reglas estén definidas.

### 12.5 `TrainerBeliefInference` — CONSERVAR MOTOR / MODERNIZAR PRIORS

La inferencia base está bien desacoplada:

- consume `TrainerObservation` y memoria sanitizada;
- genera priors públicos de movimientos de nivel, habilidades y velocidad;
- refina velocidad con evidencia observable de orden de turno;
- no necesita datos ocultos.

El problema está en la interpretación del learnset:

- agrupa movimientos de nivel sin distinguir `version_group`;
- la extensión de FASE29 añade machine/tutor/egg con priors globales;
- ese comportamiento nació cuando el dataset no conservaba procedencia/versionado suficiente.

DATA V3 sí conserva `version_group` y `order`, por lo que debe definirse una política canónica de legalidad/procedencia para Random Cup antes de ajustar los priors.

**Clasificación:** CONSERVAR arquitectura de beliefs; ADAPTAR selección de candidatos y procedencia a DATA V3.

### 12.6 `TrainerPlausibleWorldFactory` — CONSERVAR GENERACIÓN / REVALIDAR HIPÓTESIS

El factory de mundos plausibles sigue respetando la frontera de seguridad:

- usa estado sintético, no RNG vivo;
- reconstruye rivales observados mediante proxies;
- muestrea habilidad y velocidad desde beliefs;
- usa movimientos revelados y candidatos de belief;
- limita el moveset plausible a los slots máximos;
- si no hay candidatos, recurre a `LearnsetSystem.initial_moves()`.

La estructura sigue siendo útil, pero sus mundos heredan cualquier error o estrechez del modelo de beliefs y del learnset antiguo.

**Clasificación:** CONSERVAR infraestructura; REVALIDAR después de modernizar beliefs/learnsets y corpus V2.

### 12.7 Arquitectura resultante que empieza a emerger

La auditoría apunta a separar claramente tres niveles:

1. **Observación / legalidad / beliefs** — qué puede saber legítimamente el entrenador.
2. **Interpretación dinámica del roster** — qué funciones, coberturas, redundancias y piezas únicas tiene el equipo aleatorio que realmente recibió.
3. **Utilidad de decisión** — combinar valor táctico del combate actual con valor estratégico de supervivencia/campaña.

`TrainerProfile` seguirá modulando estilo. La futura competencia/expertise deberá modular calidad de decisión, no acceso a información oculta.

Todavía no se congela una fórmula de valor de campaña: primero deben quedar definidas las reglas persistentes exactas de Random Cup (qué persiste además de la muerte, qué se repone, qué se regenera y cómo se asignan loadouts/recursos).

### 12.8 Estado del rediseño en este checkpoint

- código de IA modificado: **NO**;
- FASE34 iniciada: **NO**;
- incompatibilidad DATA V3 confirmada: **SÍ**;
- incompatibilidad de función objetivo con permadeath confirmada: **SÍ**;
- infraestructura reutilizable identificada: **SÍ**;
- siguiente auditoría: item/economy, observación propia, tests/corpus sintético y flujo de composición/loadout Random Cup.

---

## 13. Auditoría técnica — objetos, economía y persistencia

Checkpoint específico de FASE30 frente a Random Cup/permadeath. **No se modifica código en este tramo.**

### 13.1 `BattleSideItemInventory` — CONSERVAR COMO PRIMITIVA DE COMBATE

La separación existente es correcta y debe protegerse:

- el inventario es finito;
- puede serializarse, duplicarse y consumirse de forma determinista;
- pertenece al estado de batalla y puede copiarse en forks de simulación;
- está diseñado explícitamente como recurso **battle-scoped** y separado de la persistencia del jugador/campaña.

No debe deformarse `BattleSideItemInventory` para convertirlo en inventario persistente de Random Cup. La capa de campaña debe ser otra autoridad y entregar al Battle Core el inventario correspondiente a cada combate.

**Clasificación:** CONSERVAR.

### 13.2 Observación y privacidad del inventario — CONSERVAR

`TrainerObservationBuilder` expone al entrenador su propio inventario finito exacto y mantiene oculto el inventario rival no revelado.

`TrainerItemAwareWorldFactory` copia únicamente el inventario propio conocido a los mundos plausibles y deja sin modelar la bolsa rival desconocida.

Esta frontera sigue siendo compatible con Random Cup: el entrenador puede conocer sus propios recursos persistentes, pero no debe obtener gratuitamente información sobre recursos rivales futuros o no observados.

**Clasificación:** CONSERVAR frontera de información y mecanismo de copia.

### 13.3 `TrainerItemAwareSearch` — CONSERVAR INTEGRACIÓN / REVALIDAR CON CONTEXTO DE CAMPAÑA

La búsqueda ya integra `ITEM` junto a movimientos y cambios, estratifica las acciones y simula correctamente su consumo en forks.

No hay evidencia de que esta infraestructura deba reescribirse por el cambio de modo.

**Clasificación:** CONSERVAR integración y muestreo; revalidar cuando exista función de utilidad de campaña.

### 13.4 `TrainerItemTacticalEvaluator` — ADAPTACIÓN IMPORTANTE

La valoración actual de objetos es esencialmente local al combate:

- recompensa HP recuperado;
- valora cura de estado;
- penaliza overheal;
- descuenta un coste fijo por tipo de objeto.

Costes heurísticos actuales:

- Potion: 250;
- Super Potion: 500;
- Hyper Potion: 900;
- Max Potion: 1200;
- Full Restore: 1400;
- fallback: 1000.

Esto permite preferir una cura barata cuando dos objetos producen un resultado inmediato equivalente, pero **no representa el coste de oportunidad entre combates**.

En Random Cup, gastar un objeto debe poder depender también de variables legítimas como:

- cuántas unidades persistentes quedan;
- expectativa de combates restantes si esa información es pública para el propio entrenador;
- valor estratégico del Pokémon que se intenta salvar;
- posibilidad de sobrevivir sin gastar el recurso;
- redundancia o irremplazabilidad de esa pieza;
- disponibilidad futura de reposición, si las reglas del modo la permiten.

No se congela todavía ninguna fórmula.

**Clasificación:** ADAPTAR DE FORMA IMPORTANTE, conservando la lectura de efectos runtime en lugar de hardcodear cantidades curadas dentro de la IA.

### 13.5 DATA V3 — integración de efectos de objetos bien encaminada

La IA no codifica directamente dentro del evaluador que una Potion cure 20, una Super Potion 60, etc. Consulta los efectos runtime de `BattleEffectRegistry`.

Eso es positivo: el contrato de DATA/runtime puede seguir siendo la autoridad de efecto, mientras la IA decide **cuándo merece la pena gastar** el recurso.

**Clasificación:** CONSERVAR este desacoplamiento.

### 13.6 Tests existentes — correctos para batalla aislada, insuficientes para campaña

Los tests activos comprueban correctamente, entre otras cosas:

- snapshot y round-trip del inventario;
- forks que consumen su propia copia sin mutar la batalla viva;
- consumo unitario y rechazo cuando el objeto se agota;
- targeting de activo/banca viva;
- Revive deshabilitado;
- separación entre objetos de bolsa y held items;
- visibilidad del inventario propio;
- ocultación de la bolsa rival;
- copia exacta del inventario propio a mundos plausibles;
- elección de curación cuando una línea ofensiva inmediata muere;
- preferencia por rematar en vez de curar innecesariamente;
- preferencia por una cura menor cuando produce el mismo beneficio inmediato.

El V2 de tests corrige dos fixtures antiguos sin debilitar producción: curar a HP completo debe rechazarse y `own_item_inventory` conserva la forma serializada de `BattleSideItemInventory`.

Sin embargo, `TrainerItemActionsCorpusTestSuite` solo sustituye el cerebro del corpus de combate existente por `ItemAwareTrainerBrain`. No añade una secuencia persistente de varios combates.

Por tanto, los tests actuales **no prueban**:

- conservación de recursos entre rondas;
- coste de gastar una cura ahora frente a necesitarla después;
- consumo acumulado en una copa;
- decisión de salvar una pieza estratégica con un recurso escaso;
- reposición o ausencia de reposición entre combates.

**Clasificación:** CONSERVAR tests unitarios de batalla; AÑADIR posteriormente corpus determinista multi-combate de Random Cup.

### 13.7 Contrato arquitectónico provisional que sale de esta auditoría

La persistencia de Random Cup no debe vivir dentro de `BattleSideItemInventory` ni obligar al Battle Core a conocer toda la campaña.

Dirección provisional:

1. una futura autoridad de Random Cup/campaña mantiene roster y recursos persistentes;
2. antes de cada combate proyecta al Battle Core el inventario utilizable en esa batalla;
3. el `TrainerDecisionContext` recibe un **snapshot estratégico sanitizado** con la información propia de campaña que el entrenador tiene derecho a conocer;
4. la IA combina utilidad táctica del objeto con coste estratégico persistente;
5. al terminar el combate, la autoridad de campaña recoge los consumos y actualiza su estado persistente.

Esto mantiene limpia la separación Battle Core / modo de juego / cerebro.

El inventario rival persistente seguirá oculto salvo que una regla pública del modo indique lo contrario.

### 13.8 Estado de FASE30 tras auditoría

- `BattleSideItemInventory`: **CONSERVAR**;
- `TrainerObservationBuilder` para bolsa propia: **CONSERVAR**;
- `TrainerItemAwareWorldFactory`: **CONSERVAR**;
- `TrainerItemAwareSearch`: **CONSERVAR / REVALIDAR**;
- `TrainerItemTacticalEvaluator`: **ADAPTAR DE FORMA IMPORTANTE**;
- corpus/tests de batalla: **CONSERVAR**;
- evaluación de economía persistente: **NUEVA CAPA NECESARIA**;
- Revive: **SIGUE DESHABILITADO** salvo futura regla explícita;
- código modificado durante esta auditoría: **NO**.

Siguiente bloque de auditoría recomendado: `TrainerLoadoutValidator` + `TrainerRoleLoadoutGenerator` frente a DATA V3 y asignación aleatoria de especies.