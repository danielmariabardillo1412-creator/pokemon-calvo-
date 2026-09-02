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

---

## 14. Auditoría técnica — Trainer Loadouts frente a DATA V3 y Random Cup

Checkpoint específico de FASE32. **No se modifica código de producción en este tramo.**

### 14.1 `TrainerLoadoutValidator` — ADAPTACIÓN IMPORTANTE

La estructura general del validador sigue siendo útil. Ya comprueba correctamente:

- especie y nivel;
- naturaleza;
- límites de IV/EV y total EV;
- máximo de cuatro movimientos y ausencia de duplicados;
- existencia de movimientos en catálogo;
- compatibilidad de habilidad con especie;
- soporte runtime de habilidad;
- soporte runtime del held item.

El problema moderno está concentrado en la legalidad del moveset.

`_species_can_use_move()` conserva una premisa que DATA V3 ya invalidó: documenta que el dataset no retiene `version_group`. En realidad `LearnSetEntry` V3 preserva explícitamente `version_group` y `order`, además de `level`, `move_id` y `method`.

Actualmente la compatibilidad se reduce a:

- level-up si `entry.level <= level`;
- machine/tutor/egg u otro método admitido por `TrainerPublicCoverageBeliefInference` sin filtrar procedencia/versionado.

Por tanto, dos entradas de épocas/versiones distintas pueden terminar tratándose como igualmente válidas para un mismo Random Cup aunque el dato V3 permita distinguirlas.

**Clasificación:** CONSERVAR la arquitectura de validación; ADAPTAR DE FORMA IMPORTANTE la política de compatibilidad de movimientos para que dependa de un ruleset/provenance explícito.

### 14.2 Segunda brecha V3 — el moveset no valida ejecutabilidad runtime

A diferencia de habilidades y held items, `_validate_moves()` no verifica la clasificación runtime del movimiento. Basta con que:

- exista en el catálogo;
- sea compatible según el learnset antiguo.

DATA V3 congela una frontera explícita de 919 movimientos:

- 590 `RUNTIME_SUPPORTED`;
- 71 `PARTIAL_RUNTIME`;
- 246 `DATA_ONLY`;
- 12 `UNSUPPORTED`.

`MoveDefinition.classification` es un campo canónico de la definición, no metadata externa.

Consecuencia: el validador actual puede declarar válido un loadout con un movimiento que DATA V3 conserva como dato pero que no constituye una capacidad de combate plenamente ejecutable.

No se congela aún si `PARTIAL_RUNTIME` debe aceptarse, rechazarse o depender de una política más fina: eso debe formar parte del contrato del ruleset. `DATA_ONLY` y `UNSUPPORTED` no pueden seguir pasando inadvertidamente como si su ejecutabilidad fuese equivalente a `RUNTIME_SUPPORTED`.

### 14.3 No usar el whitelist histórico de Battle V2 como sustituto de DATA V3

`BattleEffectRegistry.runtime_supported_move_ids()` sigue existiendo, pero es una superficie histórica congelada de Battle V2 con una lista pequeña de movimientos.

No debe utilizarse como arreglo rápido para FASE32 porque reduciría accidentalmente el catálogo moderno a la antigua superficie.

La modernización debe consumir la clasificación/capacidades V3 canónicas y, si hace falta una API de legalidad runtime, construirla sobre ese contrato moderno en vez de resucitar el whitelist antiguo.

### 14.4 `TrainerRoleLoadoutGenerator` — CONSERVAR NÚCLEO / ADAPTAR CANDIDATOS

El generador no selecciona la especie: recibe `species_id` como entrada. Por ello **no contradice por sí mismo** la asignación aleatoria de especies de Random Cup.

Esto permite reutilizarlo potencialmente para construir o interpretar un loadout de una especie que el modo ya haya asignado legítimamente.

Son reutilizables como concepto:

- perfiles de IV/EV por calidad;
- naturalezas por rol;
- scoring determinista por rol;
- selección de habilidad/held item limitada a soporte runtime;
- priorización de STAB, daño físico/especial, utilidad y prioridad;
- determinismo de la construcción.

Sin embargo, `_moves_for_role()` hereda las mismas dos brechas del validador:

1. ignora `version_group` y `order` al construir candidatos;
2. no filtra candidatos por clasificación runtime V3.

Por tanto el scoring de rol puede seguir siendo útil, pero debe ejecutarse **después** de construir un conjunto de candidatos legal y ejecutable según el ruleset moderno.

### 14.5 Random Cup — construcción de loadout no equivale a interpretación del roster

`role_id` entra al generador desde fuera. El generador sabe optimizar un Pokémon para un rol solicitado, pero no decide por sí mismo qué rol tiene sentido dentro de los seis Pokémon aleatorios recibidos.

Random Cup necesita mantener separadas dos responsabilidades:

1. **interpretar el roster recibido** y detectar dinámicamente qué roles/coberturas existen o faltan;
2. **construir/configurar un loadout**, únicamente en los campos que las reglas del modo permitan modificar.

Esto evita que el generador se convierta en una forma indirecta de hacer trampas al azar: recibir una especie aleatoria no concede automáticamente permiso para escoger naturaleza, IV/EV, habilidad, item y cuatro movimientos ideales si el contrato de Random Cup no lo establece.

**Clasificación:** `TrainerRoleLoadoutGenerator` CONSERVAR como núcleo determinista reutilizable; ADAPTAR integración y legalidad; no convertirlo todavía en autoridad de Random Cup.

### 14.6 Tests FASE32 — BUENA ESTRUCTURA, FIXTURES OBSOLETOS PARA V3

La suite histórica prueba correctamente muchos contratos útiles:

- round-trip;
- IV/EV/naturaleza;
- movimientos duplicados o incompatibles;
- método de learnset no soportado;
- habilidad e item runtime;
- generación por rol;
- materialización;
- determinismo e independencia.

Pero sus movimientos son definiciones sintéticas creadas sin fijar explícitamente `classification`. Como `MoveDefinition` usa `DATA_ONLY` por defecto, los fixtures demuestran que la suite histórica **no estaba modelando la frontera moderna de clasificación de movimientos**.

Tampoco existen en esta suite casos que separen:

- varios `version_group` para una misma especie/movimiento;
- `RUNTIME_SUPPORTED` vs `PARTIAL_RUNTIME` vs `DATA_ONLY` vs `UNSUPPORTED`;
- reglas reales de procedencia V3;
- generación sobre una muestra representativa del catálogo V3.

El V2 de la suite únicamente corrige la prueba de independencia de contenedores; no moderniza legalidad/procedencia.

**Clasificación:** CONSERVAR estructura de tests; MODERNIZAR fixtures y añadir gates V3 antes de certificar FASE32 renovada.

### 14.7 Decisiones que deliberadamente NO se inventan en esta auditoría

Antes de modificar producción deben quedar congeladas reglas de Random Cup que el repositorio actual no define todavía de forma suficiente:

- qué `version_group` o conjunto de procedencias constituye el ruleset legal;
- tratamiento exacto de machine/tutor/egg;
- política sobre `PARTIAL_RUNTIME`;
- si moveset, naturaleza, IV/EV, habilidad y held item se asignan aleatoriamente, se generan una vez, se heredan o pueden optimizarse;
- qué campos puede variar la expertise del entrenador sin alterar la aleatoriedad de especies.

Resolver estas reglas después de codificar obligaría a rehacer el validador y el generador, por lo que el código queda intacto hasta cerrar ese contrato.

### 14.8 Estado de FASE32 tras auditoría

- `TrainerPokemonLoadout` como contrato de datos: **CONSERVAR**;
- `TrainerLoadoutValidator`: **CONSERVAR ESTRUCTURA / ADAPTAR LEGALIDAD V3**;
- `TrainerRoleLoadoutGenerator`: **CONSERVAR NÚCLEO / ADAPTAR CANDIDATOS E INTEGRACIÓN RANDOM CUP**;
- selección de especie dentro del generador: **NO EXISTE**, por tanto no viola Random Cup;
- scoring de rol: **CONSERVAR / REVALIDAR**;
- fixtures FASE32: **MODERNIZAR**;
- política exacta de `version_group` y `PARTIAL_RUNTIME`: **PENDIENTE DE CONTRATO**;
- código de producción modificado durante esta auditoría: **NO**.

Siguiente bloque recomendado: auditar `TrainerTeamAnalyzer`, `TrainerTeamComposer` y `TrainerTeamFactory` para separar análisis legítimo del roster aleatorio de cualquier selección de especies que ya no pertenezca al flujo Random Cup.

---

## 15. Auditoría técnica — Team Analysis / Composition frente a Random Cup

Checkpoint específico de FASE33. **No se modifica código de producción en este tramo.**

### 15.1 `TrainerTeamAnalyzer` — CONSERVAR COMO ANALIZADOR ESTRUCTURAL / ADAPTAR PARA RANDOM CUP

La estructura central encaja bien con una plantilla aleatoria ya asignada. `analyze()` recibe un `TrainerTeamDefinition` existente y no selecciona especies.

Actualmente calcula de forma genérica:

- número de miembros válidos;
- conteo de roles;
- tipos de las especies;
- tipos ofensivos presentes en el moveset;
- debilidades compartidas;
- resistencias por tabla de tipos;
- cobertura ofensiva;
- diversidad de roles y tipos;
- una puntuación de sinergia.

Además recorre `type_catalog.all_ids()`, por lo que la lógica no está hardcodeada a un subconjunto histórico de tipos y puede trabajar con el catálogo moderno cargado.

**Clasificación:** CONSERVAR el concepto y gran parte de la implementación como análisis estructural de plantilla.

### 15.2 Limitación crítica — los roles no se infieren dinámicamente

El Analyzer incrementa `role_counts` leyendo directamente `loadout.role_id`.

Eso significa que no responde todavía a la pregunta central de Random Cup:

> «me han tocado estos seis Pokémon; ¿qué función real puede cumplir cada uno dentro de este roster concreto?»

En FASE33 los roles ya estaban asignados antes de analizar el equipo. El Analyzer mide diversidad de esas etiquetas, pero no las descubre.

Random Cup necesitará una capa de **role inference / roster interpretation** que pueda derivar uno o varios roles plausibles desde datos legítimos del miembro ya recibido:

- stats;
- moveset legal existente;
- habilidad/held item si forman parte del loadout real;
- velocidad;
- bulk;
- cobertura;
- utilidad/status/setup;
- relación con el resto de la plantilla.

Un miembro puede desempeñar más de un papel y su valor debe ser relativo al roster, no solo una etiqueta fija.

**Clasificación:** Analyzer CONSERVAR; añadir o integrar inferencia dinámica de roles antes de usar `role_counts` como verdad estratégica.

### 15.3 Segunda brecha DATA V3 — cobertura ofensiva no filtra clasificación runtime

Para construir `attack_type_counts`, el Analyzer acepta cualquier movimiento existente con `power > 0`.

No comprueba `MoveDefinition.classification`.

Por tanto hereda la misma brecha detectada en FASE32: un movimiento `DATA_ONLY` o `UNSUPPORTED` podría inflar artificialmente la cobertura y la sinergia de un equipo si llega a un loadout por el validador antiguo.

La solución futura no debe duplicar reglas arbitrarias dentro del Analyzer. El contrato preferido es que el roster/loadout que llega a esta capa ya esté validado contra el ruleset V3, y que el Analyzer solo consuma capacidades realmente utilizables.

**Clasificación:** ADAPTAR integración con la nueva autoridad de legalidad/capacidades V3.

### 15.4 El Analyzer V1 es estático, no una función de valor de campaña

`TrainerTeamAnalyzer` trabaja con definiciones de loadout. No incorpora:

- HP persistente actual;
- estados persistentes;
- PP o recursos consumidos;
- miembros ya eliminados por permadeath;
- disponibilidad futura de curación;
- valor de supervivencia;
- coste de perder una cobertura única;
- reemplazabilidad real durante la copa.

Tampoco modela todavía sinergias defensivas aportadas por habilidades concretas; la resistencia base se calcula por tipado de especie.

Esto no es un bug de FASE33: era un analizador de composición estática.

Random Cup necesita conservarlo como una de las entradas del análisis, pero añadir una capa dinámica de **roster strategic state/value** sobre el estado persistente real.

### 15.5 `TrainerTeamComposer` — RETIRAR DEL FLUJO PRINCIPAL RANDOM CUP

La incompatibilidad aquí sí es directa.

`compose()` recibe un `species_pool` y, en cada iteración:

1. recorre especies candidatas;
2. prueba distintos roles para cada especie;
3. genera un loadout;
4. analiza la sinergia del equipo provisional;
5. escoge la combinación especie/rol con mayor puntuación;
6. repite hasta alcanzar el tamaño objetivo.

Por tanto, `TrainerTeamComposer` es explícitamente un **selector de especies** y optimizador de composición.

Eso contradice el contrato de Random Cup cuando las especies se asignan aleatoriamente y el entrenador no puede sustituir una mala tirada por otra especie del pool.

**Clasificación:** RETIRAR del flujo principal de Random Cup.

No se elimina del repositorio: sigue siendo una utilidad válida para otros modos, NPCs diseñados, fixtures, benchmarks o generación de equipos donde la selección de especies sí sea legítima.

### 15.6 Partes salvables del Composer — no conservar la autoridad equivocada

Aunque `compose()` no debe decidir especies en Random Cup, contiene heurísticas reutilizables como conceptos:

- `_role_fit()` para estimar adecuación estadística a un rol;
- evaluación incremental de sinergia;
- desempate determinista;
- selección de lead como problema separado.

Estas piezas no deben reutilizarse copiando el Composer entero dentro del nuevo flujo. Se extraerán o reimplementarán solo si un benchmark demuestra que aportan valor a la **interpretación de una plantilla ya asignada**.

La regla es clara:

`random assignment → interpret roster → decide cómo usarlo`

no:

`random assignment → volver a elegir especies para arreglarlo`.

### 15.7 Lead selection — idea válida, heurística insuficiente para permadeath

El Composer selecciona el lead después de construir el equipo mediante una heurística estática basada principalmente en:

- `base_speed`;
- bonus fuerte para `fast_attacker`;
- bonus para `support`;
- bonus menor para roles bulky/otros.

Eso es razonable como V1 para un equipo fresco y diseñado, pero no es suficiente para Random Cup persistente.

La futura selección de lead debe poder considerar también información propia legítima como:

- HP/estado persistente del miembro;
- valor estratégico y reemplazabilidad;
- cobertura única que conviene preservar;
- rol real inferido del roster;
- riesgo de exponer una pieza clave;
- información pública/observada del rival cuando proceda.

**Clasificación:** CONSERVAR el problema de selección de lead; ADAPTAR/REUBICAR la política. No debe seguir acoplada a la construcción de especies.

### 15.8 `TrainerTeamFactory` — CONSERVAR COMO MATERIALIZADOR INICIAL / NO USAR COMO RESTAURADOR DE CAMPAÑA

`TrainerTeamFactory` no selecciona especies ni roles. Valida un `TrainerTeamDefinition`, materializa cada loadout mediante `TrainerLoadoutFactory` y rota el roster retornado para que `lead_index` quede primero.

La separación es buena y no contradice Random Cup si se utiliza para crear inicialmente las instancias que el modo ha asignado legítimamente.

Sin embargo, la materialización produce instancias nuevas a partir del loadout. Los tests históricos verifican precisamente que las instancias creadas son independientes y que nacen con stats/moves inicializados.

Por ello, en una copa con persistencia **no debe recrearse el roster desde el `TrainerTeamDefinition` antes de cada combate**, porque eso podría restaurar estado que debía persistir o haberse perdido: HP, estado, PP, eliminación permanente u otros recursos según el contrato final.

La futura autoridad de Random Cup debe mantener las instancias/estado persistente y proyectar al Battle Core el roster superviviente correspondiente.

**Clasificación:** CONSERVAR como constructor/materializador inicial; PROHIBIR su uso como mecanismo de reset/restauración entre rondas.

### 15.9 Tests FASE33 — buenos para composición diseñada, insuficientes para Random Cup

La suite histórica prueba correctamente:

- round-trip y validación de `TrainerTeamDefinition`;
- límites de party y duplicados;
- detección de debilidades compartidas;
- diversidad de roles/tipos;
- Composer determinista desde un pool;
- selección de especie sin duplicados cuando así se pide;
- lead válido;
- materialización completa e independiente.

Pero sus fixtures están construidos expresamente para demostrar que un equipo balanceado diseñado obtiene mejor score que uno redundante y que el Composer puede escoger especies distintas de un pool.

No prueban:

- seis especies realmente asignadas al azar sin posibilidad de reemplazo;
- inferencia dinámica de roles;
- roster malo que la IA debe aceptar y explotar tal cual;
- miembros eliminados entre combates;
- análisis sobre HP/estado persistente;
- lead condicionado por supervivencia de campaña;
- cobertura filtrada por clasificación V3 real;
- valor de una pieza única frente a miembros redundantes.

**Clasificación:** CONSERVAR tests de FASE33 como regresión del modo de composición diseñada; AÑADIR una suite/corpus específico de interpretación Random Cup.

### 15.10 Estado de FASE33 tras auditoría

- `TrainerTeamDefinition`: **CONSERVAR** como definición estática, sin convertirla en autoridad de estado persistente;
- `TrainerTeamValidator`: **CONSERVAR / REVALIDAR** después de modernizar loadouts V3;
- `TrainerTeamAnalyzer`: **CONSERVAR ESTRUCTURA / ADAPTAR** con legalidad V3 e interpretación dinámica;
- inferencia de roles del roster: **NUEVA CAPA NECESARIA**;
- análisis estratégico de campaña: **NUEVA CAPA NECESARIA**;
- `TrainerTeamComposer`: **RETIRAR DEL FLUJO RANDOM CUP**, conservar para modos donde elegir especies sea legítimo;
- lead selection: **EXTRAER/ADAPTAR** como política sobre roster ya asignado;
- `TrainerTeamFactory`: **CONSERVAR COMO MATERIALIZADOR INICIAL**, no como restaurador entre combates;
- tests FASE33: **CONSERVAR COMO REGRESIÓN HISTÓRICA + AÑADIR RANDOM CUP V2**;
- código de producción modificado durante esta auditoría: **NO**.

Siguiente bloque recomendado: localizar la autoridad actual de torneo/campaña/roster fuera de Battle Core y comprobar dónde debe vivir la eliminación permanente, la persistencia entre combates y la asignación aleatoria determinista.

---

## 16. Auditoría técnica — autoridad Random Cup, persistencia y permadeath

Checkpoint de arquitectura de modo/campaña. **No se modifica código de producción en este tramo.**

### 16.1 No existe todavía una autoridad Random Cup/campaña implementada

La búsqueda del repositorio no encuentra una implementación funcional de `Random Cup`, `permadeath`, `campaign` o `tournament` fuera de la documentación de este rediseño.

Por tanto no hay un sistema de torneo oculto que deba adaptarse. La capa de modo persistente será una responsabilidad nueva.

Esto es importante porque esa responsabilidad **no pertenece a Trainer AI ni a Battle Core**. Trainer AI decide usando un contexto permitido; Battle Core resuelve un combate. El modo Random Cup debe vivir por encima de ambos y poseer el estado que sobrevive entre batallas.

### 16.2 `CreatureParty` — base persistente reutilizable

Ya existe una primitiva apropiada para mantener un roster persistente:

- contiene las mismas `CreatureInstance` que otros sistemas mutan;
- identifica miembros por `instance_id`, no por especie ni índice;
- no crea, recalcula ni rerollear criaturas;
- permite `add_creature`, `remove_creature`, `reorder` y acceso por identidad;
- serializa de forma estable el roster y las instancias;
- el límite de seis vive en `PartyRuleset`.

Aunque la documentación histórica la describa como party del jugador, `CreatureParty` es estado de dominio puro y no contiene lógica específicamente humana/UI. Puede reutilizarse conceptualmente como contenedor de roster de un participante Random Cup, siempre que no se le añada lógica de torneo dentro.

**Clasificación:** CONSERVAR `CreatureParty` como primitiva de roster; NO convertirla en autoridad de Random Cup.

### 16.3 Persistencia real entre batallas ya existe a nivel de `CreatureInstance`

`TrainerBattleSession.begin_battle()` no clona ni rematerializa los combatientes. Entrega al `BattleState` las mismas `CreatureInstance` recibidas del propietario del roster.

Battle modifica esas instancias en vivo. Al terminar, `reconcile_post_battle()`:

- elimina estado exclusivamente temporal de combate;
- reinicia stat stages;
- mantiene estado persistente;
- conserva/clampa HP;
- conserva/clampa PP.

Esto significa que la infraestructura actual **ya puede transportar daño, PP y estado persistente a la siguiente batalla** sin crear un sistema nuevo de criaturas.

Pero esto describe el comportamiento técnico actual, no congela todavía que Random Cup deba conservar obligatoriamente todos esos recursos entre rondas. La muerte permanente sí es premisa canónica; la política exacta de curación/restauración entre combates sigue siendo una regla del modo pendiente de definición.

### 16.4 `TrainerBattleSession` — CONSERVAR COMO FRONTERA DE UNA BATALLA

La sesión ya está en el nivel correcto para:

- recibir identidad del entrenador rival;
- recibir un roster ya propiedad de otro sistema;
- crear el `BattleState` real;
- resolver el combate sin captura/flee;
- producir `BattleOutcome`/settlement;
- reconciliar las mismas instancias al finalizar.

No debe convertirse en torneo.

En particular, `_opponent_roster` es solo un array de referencias usado durante la sesión. Tras settlement la sesión limpia su referencia local, pero no destruye las `CreatureInstance` que un propietario externo siga manteniendo.

**Clasificación:** CONSERVAR `TrainerBattleSession` como frontera battle-scoped; la futura autoridad Random Cup la invoca, no se fusiona con ella.

### 16.5 Permadeath — debe aplicarse en la autoridad del modo tras settlement

`CreatureParty.remove_creature(instance_id)` ya ofrece la operación básica necesaria para eliminar una identidad del roster.

La regla canónica del proyecto dice que un Pokémon que cae bajo Random Cup queda eliminado permanentemente del roster futuro. Esa política no debe implementarse dentro de daño, KO, Battle Core ni `CreatureParty`, porque esos sistemas también sirven a modos donde faint no equivale a eliminación permanente.

Dirección arquitectónica:

1. Battle Core determina legítimamente el KO/final del combate;
2. `TrainerBattleSession` produce y reconcilia el settlement;
3. la autoridad Random Cup inspecciona el resultado/estado de sus participantes;
4. aplica la política de permadeath por `instance_id` al roster persistente correspondiente;
5. las rondas posteriores reciben únicamente los supervivientes.

Esto preserva la semántica genérica de batalla y hace que permadeath sea una regla explícita y testeable del modo.

### 16.6 Estado de participantes — hace falta una capa nueva por encima de `CreatureParty`

Un participante Random Cup necesitará más información que una lista de Pokémon. Como mínimo conceptual, la autoridad futura tendrá que poseer o referenciar:

- identidad del participante/entrenador;
- roster persistente;
- `TrainerProfile`/competencia cuando sea IA;
- recursos persistentes del modo si existen;
- situación de ronda/eliminación;
- datos necesarios para reproducibilidad/semillas.

No se congela todavía el nombre ni el schema exacto (`RandomCupState`, `RandomCupParticipant`, etc.). Primero se cerrarán las reglas del modo y después se diseñará el contrato mínimo.

### 16.7 SaveGame V2 no persiste una copa

El save actual persiste el agregado del jugador:

- `CreatureParty`;
- `CreatureStorage`;
- `PlayerInventory`.

No incluye:

- bracket/ronda de Random Cup;
- participantes rivales;
- rosters rivales persistentes;
- eliminaciones del torneo;
- seed/estado de asignación del torneo;
- recursos de copa separados del jugador.

Por tanto, si Random Cup debe sobrevivir a cerrar/cargar partida, será necesario ampliar la persistencia de forma explícita. No se modifica todavía `SaveGame V2` ni se decide una nueva versión de schema durante esta auditoría.

**Clasificación:** infraestructura de save CONSERVAR; integración Random Cup = NUEVO CONTRATO posterior.

### 16.8 Asignación aleatoria determinista — reutilizar patrón RNG, no el RNG vivo de Battle

El repositorio ya tiene dos precedentes:

- Battle usa `SeededRandomSource` para su snapshot determinista;
- sistemas gameplay como encounters/capture/CreatureFactory usan `RandomNumberGenerator` inyectado y seeds controladas.

La asignación de especies de Random Cup es una decisión del modo, no una tirada interna de Battle Core. Debe utilizar una fuente RNG inyectada/reproducible propiedad de la capa Random Cup y producir resultados reproducibles para tests y benchmarks.

No se congela en este checkpoint cuál de las dos abstracciones RNG se reutilizará. Sí queda congelado que:

- no habrá `randomize()` oculto;
- el mismo estado/seed y ruleset deberán reproducir la misma asignación;
- la IA no podrá pedir rerolls según la calidad del equipo;
- los `battle_seed` deben seguir siendo una preocupación separable de la semilla de asignación de roster.

### 16.9 Reglas de asignación que siguen pendientes

Antes de implementar el generador Random Cup deben definirse expresamente:

- pool exacto elegible: especies/formas;
- duplicados permitidos o no;
- nivel inicial y posible progresión;
- cómo se materializan moveset/naturaleza/IV/EV/habilidad/held item;
- `version_group`/provenance legal;
- política sobre movimientos `PARTIAL_RUNTIME`;
- si existe reposición de Pokémon tras una baja o el roster solo decrece;
- política de HP/PP/status/healing entre rondas;
- economía/objetos persistentes exactos.

Estas decisiones alteran directamente la IA y el valor de campaña, por lo que no se autorrellenan.

### 16.10 Tests que necesitará la nueva autoridad de modo

Cuando se implemente, el mínimo de regresiones deberá cubrir al menos:

- misma seed + mismo ruleset → misma asignación;
- seeds distintas pueden producir asignaciones distintas;
- ninguna IA puede rerollear especies recibidas;
- identidades `instance_id` estables durante toda la copa;
- Battle recibe las mismas instancias persistentes;
- estado permitido entre rondas no se restaura accidentalmente;
- un KO marcado por la regla de permadeath desaparece del roster futuro;
- un superviviente conserva exactamente el estado que el ruleset determine;
- participante sin miembros utilizables queda eliminado/incapaz de iniciar batalla;
- `TrainerTeamComposer` no participa en la asignación Random Cup;
- round-trip de estado de copa cuando se decida integrar save.

### 16.11 Estado arquitectónico tras esta auditoría

- autoridad Random Cup existente: **NO**;
- `CreatureParty`: **CONSERVAR COMO PRIMITIVA PERSISTENTE**;
- `CreatureInstance`: **CONSERVAR IDENTIDAD/ESTADO VIVO**;
- `TrainerBattleSession`: **CONSERVAR COMO SESIÓN DE UNA BATALLA**;
- permadeath en Battle Core: **NO**;
- permadeath en `CreatureParty`: **NO COMO REGLA INTERNA**;
- permadeath en futura autoridad Random Cup tras settlement: **DIRECCIÓN CANÓNICA**;
- estado/participante de copa: **NUEVA CAPA NECESARIA**;
- asignación aleatoria: **NUEVA CAPA DETERMINISTA NECESARIA**;
- save de copa: **NO EXISTE / INTEGRACIÓN POSTERIOR**;
- código de producción modificado durante esta auditoría: **NO**.

Siguiente bloque recomendado: congelar únicamente las reglas de Random Cup que bloquean la implementación —pool/duplicados, loadout inicial, persistencia HP/PP/status, reposición y recursos— antes de diseñar clases o tocar código.

---

## 17. Frontera de reglas Random Cup — confirmado vs abierto

Checkpoint de reglas previo a implementación. **No se modifica código de producción en este tramo.**

### 17.1 Reglas realmente canónicas ya confirmadas

Tras revisar documentación viva, historial de commits y decisiones previas del proyecto, solo hay dos reglas de Random Cup que están realmente congeladas:

1. **Las especies de los entrenadores se asignan aleatoriamente.** El entrenador debe jugar el roster que recibe y no puede corregir una mala tirada seleccionando otras especies.
2. **Muerte permanente.** Un Pokémon eliminado bajo este modo deja de formar parte del roster futuro.

El resto de decisiones que afectan a generación, curación, reposición y economía no aparecen definidas de forma canónica en documentación anterior.

### 17.2 No existen reglas antiguas ocultas que recuperar

`PROJECT_STATE.md` y `NEXT_STEPS.md` anteriores al rediseño describen el stack FASE19–33, pero no contienen un contrato Random Cup. La primera congelación explícita del modo es el commit `e3215b35cfd00b358d92e35f93074007cf98a7fc`, que introduce precisamente las dos premisas anteriores y deja el resto para auditoría.

Por tanto, no se debe tratar como “olvidada” ninguna regla sobre:

- duplicados;
- formas;
- curación entre rondas;
- PP;
- status;
- reposición;
- objetos persistentes;
- loadout inicial.

Esas decisiones siguen abiertas y deberán resolverse conscientemente.

### 17.3 `CreatureFactory` — reutilizable, pero no es una política Random Cup completa

`CreatureFactory.create()` ya ofrece una materialización determinista con RNG inyectado:

- IVs aleatorios por defecto;
- naturaleza aleatoria por defecto;
- EVs vacíos salvo override;
- primera habilidad de especie por defecto;
- moveset por `LearnsetSystem.initial_moves()` salvo override;
- HP inicial completo salvo override.

Esto es una buena primitiva de construcción, pero **no debe convertirse automáticamente en el ruleset Random Cup**.

La razón es doble:

1. la elección de primera habilidad no equivale a una política explícita de habilidad aleatoria/legal;
2. `LearnsetSystem.initial_moves()` agrega movimientos `level_up` sin distinguir `version_group`, `order` de procedencia moderna ni clasificación runtime V3.

Por tanto, la futura asignación deberá decidir primero el contrato de loadout y después usar `CreatureFactory` como materializador con overrides ya legales.

### 17.4 `LearnsetSystem.initial_moves()` hereda una premisa pre-V3

La función actual:

- recoge todas las entradas `level_up` con nivel `<= level`;
- las ordena únicamente por nivel;
- conserva las últimas cuatro;
- no filtra `version_group`;
- no filtra `MoveDefinition.classification`.

Eso es suficiente para la progresión histórica sobre fixtures estrechos, pero no puede ser la autoridad final de un roster Random Cup generado desde DATA V3.

**Clasificación:** CONSERVAR como utilidad histórica; MODERNIZAR o envolver mediante una política V3 antes de usarla para generación Random Cup.

### 17.5 Decisiones bloqueantes que siguen abiertas

Antes de diseñar `RandomCupRuleset`/`RandomCupState` deben resolverse únicamente estas familias de reglas:

- **Pool:** qué especies/formas pueden salir y si existen exclusiones por falta de soporte runtime.
- **Duplicados:** si una misma especie o forma puede aparecer más de una vez en un roster/torneo.
- **Nivel/progresión:** nivel inicial común o variable y si se gana experiencia/evoluciona durante la copa.
- **Loadout inicial:** movimientos, naturaleza, IV/EV, habilidad y held item; qué parte se aleatoriza y qué parte se deriva de reglas.
- **Provenance V3:** `version_group`, machine/tutor/egg y política de `PARTIAL_RUNTIME`.
- **Persistencia entre rondas:** HP, PP, status y cualquier curación automática.
- **Reposición:** roster decreciente puro frente a cualquier mecanismo de reemplazo.
- **Economía:** qué objetos de bolsa existen, si persisten y si se reponen.

No hace falta decidir aún bracket, presentación, save final o UI para empezar el núcleo del modo; esos temas pueden ir después de cerrar estas reglas.

### 17.6 Lo que sí puede diseñarse sin resolver todavía esas opciones

Aunque las políticas anteriores sigan abiertas, ya queda congelada una separación de responsabilidades que no depende de ellas:

`RandomCupRuleset` (política) → `RandomCupState/Participant` (estado persistente) → `TrainerBattleSession` (una batalla) → `Battle Core`.

Y de vuelta:

`Battle settlement` → `RandomCup authority` → aplicar permadeath/persistencia según ruleset → siguiente batalla.

La IA recibirá solo un snapshot sanitizado del estado propio de campaña que el ruleset permita conocer.

### 17.7 Orden seguro de implementación una vez cerradas las reglas

El orden recomendado sigue siendo pequeño y certificable:

1. contrato `RandomCupRuleset` sin UI/save;
2. participante/roster persistente y asignación determinista;
3. permadeath post-settlement;
4. política de persistencia HP/PP/status/recursos;
5. snapshot estratégico sanitizado para Trainer AI;
6. adaptación de utilidad/switching/items;
7. corpus multi-battle;
8. integración de save más adelante.

Esto evita construir primero una IA estratégica sobre un estado de campaña que luego cambie de significado.

### 17.8 Estado de este checkpoint

- reglas Random Cup canónicas recuperadas: **2** (asignación aleatoria de especies + permadeath);
- reglas históricas adicionales encontradas: **NO**;
- `CreatureFactory`: **CONSERVAR COMO MATERIALIZADOR, NO COMO RULESET**;
- `LearnsetSystem.initial_moves`: **NO USAR COMO AUTORIDAD V3 SIN ADAPTACIÓN**;
- decisiones bloqueantes restantes: **EXPLÍCITAMENTE LISTADAS**;
- código de producción modificado: **NO**.

Siguiente bloque recomendado: transformar estas decisiones abiertas en un contrato de reglas mínimo y escoger defaults de diseño únicamente donde exista una opción claramente coherente con la premisa Random Cup; cualquier elección de gameplay no derivable deberá mantenerse explícita hasta decisión del usuario.

---

## 18. Contrato mínimo Random Cup — decisiones técnicas derivables y correcciones de auditoría

Checkpoint de consolidación previo a crear clases. **No se modifica código de producción en este tramo.**

### 18.1 CORRECCIÓN IMPORTANTE — DATA V3 ya resuelve la coherencia de `version_group`

La auditoría de FASE32 detectó correctamente que comentarios y consumidores antiguos dicen que `version_group` no existe, pero sobreestimó el riesgo de mezclar generaciones dentro de un mismo learnset.

El adaptador V3 tiene una política canónica explícita:

`latest_conventional_mainline_per_species_v1`.

Para cada Pokémon:

1. inspecciona los grupos disponibles;
2. elige el grupo convencional de saga principal más reciente según una prioridad fija;
3. no usa Stadium/Colosseum/XD/Legends/otros grupos especiales como fallback;
4. construye el `CreatureSpecies.learnset` **solo con entradas de ese grupo seleccionado**;
5. conserva `version_group` y `order` en cada `LearnSetEntry` como procedencia trazable.

El manifest DATA V3 confirma: `one latest available conventional main-series version-group per Pokemon; no side-game fallback`.

Consecuencia: Random Cup **no necesita inventar un `version_group` global** ni filtrar una unión multigeneracional que ya no existe en V3. Debe heredar la procedencia canónica de DATA V3.

Sigue siendo necesario corregir los comentarios/contratos antiguos que afirman que `version_group` no se preserva, y utilizar `order` cuando corresponda para desempates deterministas. También sigue siendo necesario decidir qué métodos de aprendizaje (`level_up`, `machine`, `tutor`, `egg`) permite el ruleset.

Esta sección corrige expresamente cualquier frase anterior del cuaderno que sugiera que el catálogo V3 de una especie contiene entradas mezcladas de varias generaciones.

### 18.2 Pool Random Cup V1 — especies runtime, no formas preservadas

DATA V3 conserva 1.025 especies y 326 formas, pero las formas no se materializan actualmente como entradas independientes del `species_catalog` runtime. Existe incluso una regresión que verifica que las variantes de forma no entren como especies del catálogo.

Por tanto, el pool base técnicamente correcto para Random Cup V1 es:

`DefinitionCatalog.species_catalog` / especies runtime canónicas.

Las formas quedan fuera del sorteo V1 hasta que exista soporte explícito de formas combatibles como identidades/materializaciones de runtime. No se fingirá soporte mediante IDs que el dominio de criaturas no reconoce.

El pool final elegible podrá ser un subconjunto del catálogo base: una especie solo debe entrar si la política de loadout puede producir al menos una configuración de batalla legal y ejecutable para el nivel/métodos definidos por el ruleset.

### 18.3 Tamaño inicial y duplicados

`PartyRuleset.MAX_PARTY` es 6, coherente con la premisa del roster aleatorio de seis miembros.

**Contrato estructural V1:** roster inicial objetivo = 6, siempre que el pool elegible permita materializar seis miembros válidos.

Los duplicados no son una limitación técnica: `CreatureParty` identifica por `instance_id` y admite expresamente dos criaturas de la misma especie.

Por ello:

- `allow_duplicate_species` debe existir como política de Random Cup;
- su valor sigue siendo una elección de gameplay y no se congela por arquitectura.

### 18.4 Gate de capacidades runtime para generación automática

Random Cup no debe asignar automáticamente una mecánica que DATA V3 marca como incompleta o no ejecutable.

Default técnico seguro para V1:

- movimientos automáticos: **solo `RUNTIME_SUPPORTED`**;
- `PARTIAL_RUNTIME`: preservado en DATA V3, pero excluido de asignación automática V1 hasta tener una política granular que acepte conscientemente su semántica parcial;
- `DATA_ONLY` / `UNSUPPORTED`: nunca se materializan como capacidad de batalla Random Cup;
- habilidades: solo runtime-supported o vacío si la especie no tiene ninguna soportada;
- held item: solo runtime-supported o vacío si la política del modo no asigna uno.

Para movimientos esta comprobación debe apoyarse en `MoveDefinition.classification` V3, **no** en el pequeño whitelist histórico `BattleEffectRegistry.runtime_supported_move_ids()` de Battle V2.

Esto no elimina `PARTIAL_RUNTIME`; únicamente impide que una tirada aleatoria introduzca silenciosamente una mecánica conocida como incompleta en un modo que se utilizará para medir IA.

### 18.5 La autoridad del loadout pertenece al modo, no al cerebro

La asignación inicial debe seguir este orden:

`Random Cup sortea especie → ruleset genera/deriva loadout legal → materializa CreatureInstance → Trainer AI recibe lo que le tocó`.

La IA no puede volver a generar el Pokémon según su perfil, dificultad o calidad de decisión.

El `TrainerRoleLoadoutGenerator` histórico cambia IVs, EVs, naturaleza, movimientos, habilidad y objeto según `role_id`/`quality_id`. Por ello no puede utilizarse automáticamente como “expertise del entrenador” dentro de Random Cup: eso haría que competencia cognitiva modificase las propiedades físicas del Pokémon recibido.

Sus heurísticas de rol siguen siendo reutilizables, pero:

- como ayuda a una política de generación explícita del modo, si se decide así; o
- como base para interpretar roles del roster ya materializado.

La creación/materialización inicial de cada miembro ocurre una vez y conserva `instance_id`. Cualquier cambio posterior de nivel, evolución o moveset solo podrá venir de una regla explícita de progresión, nunca de rematerializar el roster antes de cada combate.

### 18.6 Métodos de aprendizaje — provenance resuelta, whitelist de métodos todavía abierta

Como DATA V3 ya ha elegido un único grupo mainline coherente por especie, la pregunta restante no es “qué generación usamos”, sino “qué fuentes de movimiento permite Random Cup”.

El ruleset deberá declarar un conjunto explícito, por ejemplo alguna combinación de:

- `level_up`;
- `machine`;
- `tutor`;
- `egg`.

Para `level_up` sigue aplicando `entry.level <= nivel`. Para el resto, la legalidad depende de que el método esté permitido por el ruleset y el movimiento pase el gate runtime V3.

`order` debe conservarse como parte de la selección determinista cuando varias entradas empatan o el orden de aprendizaje sea semánticamente relevante.

El valor concreto de `allowed_learn_methods` sigue siendo una elección de gameplay.

### 18.7 Nueva incompatibilidad encontrada — `TrainerBattleSession` aplica progresión asimétrica

`TrainerBattleSession.settle_finished_battle()` reutiliza la progresión del juego normal y, cuando gana `side_a`, ejecuta `ProgressionSystem.reconcile_battle_result()` únicamente sobre `player.party`.

Eso es correcto para la campaña normal jugador-vs-entrenador, pero no constituye una política neutral de torneo:

- si Random Cup tiene progresión, debe aplicarse según reglas simétricas/expresas a los participantes correspondientes;
- si Random Cup no tiene progresión, debe poder desactivar ese XP automático;
- no puede dejarse que el lado etiquetado como “player” gane niveles por accidente mientras el otro no.

**Clasificación actualizada de `TrainerBattleSession`:** CONSERVAR la frontera de batalla, pero ADAPTAR el settlement para permitir que la política de progresión se externalice o se desactive en Random Cup. No convertir la sesión en autoridad del torneo.

### 18.8 Decisiones de gameplay que siguen abiertas después de esta reducción

Ya no son bloqueos técnicos `version_group` ni soporte de formas V1: esos dos puntos quedan resueltos por la arquitectura/dataset actuales.

Siguen abiertos conscientemente:

1. `allow_duplicate_species`;
2. nivel inicial común/variable;
3. progresión: ninguna / XP / evolución / aprendizaje durante la copa;
4. `allowed_learn_methods`;
5. política concreta de IVs, EVs, naturaleza y selección de habilidad;
6. held items: ninguno / asignación y método;
7. recuperación entre rondas de HP/PP/status;
8. reposición o no de miembros eliminados;
9. bolsa inicial, persistencia y reposición de consumibles.

Estas opciones alteran el gameplay y la función de valor de campaña; no se eligen por comodidad de implementación.

### 18.9 Forma mínima provisional de `RandomCupRuleset`

Sin escribir todavía la clase, el contrato conceptual ya puede congelar campos/responsabilidades:

- `roster_size = 6`;
- `species_pool_policy = runtime_species_catalog_v1`;
- `forms_policy = default_runtime_species_only_v1`;
- `allow_duplicate_species = <gameplay>`;
- `initial_level_policy = <gameplay>`;
- `progression_policy = <gameplay>`;
- `allowed_learn_methods = <gameplay>`;
- `accepted_move_classifications = [RUNTIME_SUPPORTED]` para generación automática V1;
- `accepted_ability_policy = runtime_supported_or_none`;
- `held_item_policy = <gameplay>, siempre runtime-supported`;
- `between_battle_recovery_policy = <gameplay>`;
- `replacement_policy = <gameplay>`;
- `bag_policy = <gameplay>`;
- `learnset_provenance_policy = inherited_from_data_v3_manifest`;
- `assignment_seed` propiedad del modo y separada de cada `battle_seed`.

La validación del ruleset deberá fallar temprano si una combinación de políticas deja un pool incapaz de generar un roster legal.

### 18.10 Estado de este checkpoint

- mezcla multigeneracional real dentro de learnsets V3: **NO; CORRECCIÓN CONFIRMADA**;
- provenance de learnset: **HEREDAR DATA V3**;
- formas combatibles en `species_catalog`: **NO EN V1**;
- pool base V1: **ESPECIES RUNTIME DEL CATÁLOGO**;
- tamaño de roster: **6**;
- duplicados: **TÉCNICAMENTE SOPORTADOS / REGLA ABIERTA**;
- movimientos autoasignados: **RUNTIME_SUPPORTED V1**;
- `PARTIAL_RUNTIME` autoasignado: **NO POR DEFECTO**;
- autoridad de loadout: **RANDOM CUP, NO TRAINER AI**;
- rematerialización entre combates: **PROHIBIDA**;
- progresión actual de `TrainerBattleSession`: **ASIMÉTRICA / DEBE ADAPTARSE PARA RANDOM CUP**;
- decisiones puramente de gameplay restantes: **9 FAMILIAS EXPLÍCITAS**;
- código de producción modificado: **NO**.

Siguiente bloque recomendado: auditar el seam exacto de `TrainerDecisionContext` / `TrainerObservationBuilder` y diseñar el mínimo `TrainerCampaignSnapshot` sanitizado que permita valorar permadeath sin exponer estado rival oculto. Ese contrato puede diseñarse aunque HP/PP/items se recuperen o no: representará el estado propio real que exista en cada momento.

---

## 19. Auditoría técnica — seam de información de campaña para Trainer AI

Checkpoint de seguridad/arquitectura para conectar Random Cup con el cerebro. **No se modifica código de producción en este tramo.**

### 19.1 `TrainerObservationBuilder` — CONSERVAR Y NO ENSANCHAR CON CAMPAÑA

La observación actual está correctamente definida como una vista **battle-scoped**:

- incluye estado completo del lado propio que participa en la batalla;
- incluye la bolsa propia finita de esa batalla;
- del rival solo expone criaturas vistas y hechos revelados;
- oculta banca no observada, movimientos no revelados, habilidad/item ocultos, IV/EV/naturaleza, stats exactos y HP exacto;
- no expone RNG ni el roster autoritativo bruto.

Los tests FASE20 verifican de forma explícita esas propiedades.

Random Cup no debe convertir `TrainerObservation` en un contenedor híbrido de batalla+torneo. Campos como ronda de copa, bajas permanentes, políticas de recuperación o recursos de campaña pertenecen a otra vista.

**Clasificación:** CONSERVAR `TrainerObservation` y `TrainerObservationBuilder` como frontera battle-scoped. No añadirles `RandomCupState` ni datos persistentes de torneo.

### 19.2 `TrainerBattleMemory` — CONSERVAR COMO MEMORIA DE UNA BATALLA

`TrainerBattleMemory.begin()` limpia su estado y lo vincula al `battle_id`/perspectiva actuales. Guarda únicamente hechos observados durante esa batalla y deliberadamente reduce el envelope de eventos para no copiar metadata genérica que pudiera contener detalles internos.

Esto sigue siendo correcto.

No debe reutilizarse esta clase como memoria persistente de Random Cup. Si más adelante el diseño permite que un entrenador recuerde información legítimamente revelada en combates anteriores —por ejemplo ante un posible rematch— eso deberá ser una capa de conocimiento de campaña separada, con reglas explícitas de retención. No se autoriza ese conocimiento cruzado por defecto en este checkpoint.

**Clasificación:** CONSERVAR battle memory; memoria/knowledge inter-battle = responsabilidad separada si el ruleset la necesita.

### 19.3 `TrainerDecisionContext` — EXTENSIÓN ADITIVA Y OPCIONAL

El contexto actual contiene:

- `observation`;
- `belief_snapshot`;
- `memory_snapshot`;
- `legal_actions`.

Beliefs, memoria y acciones se copian/deserializan de forma que el brain no recibe referencias mutables del estado autoritativo. Los consumidores actuales acceden a campos concretos y no dependen de que el contexto tenga un conjunto cerrado de cuatro claves.

Dirección canónica para Random Cup:

- añadir un `campaign_snapshot` separado;
- por defecto `{}` para combates normales, fixtures y self-play histórico;
- copiarlo en profundidad al crear el `TrainerDecisionContext`;
- serializarlo como datos planos;
- nunca incluir objetos vivos, callables, nodos, `CreatureInstance`, `RandomCupState` o RNG.

Nombre de trabajo del contrato: **`TrainerCampaignSnapshot`**. El nombre de la clase concreta puede congelarse al implementar, pero la separación funcional queda decidida.

### 19.4 Autoridad y construcción — WHITELIST, no “serializar y borrar secretos”

El snapshot debe ser construido por una capa confiable de Random Cup mediante una **lista positiva de campos permitidos**.

Queda prohibido el patrón:

`RandomCupState.to_dict() → borrar unas claves rivales → entregar el resto al cerebro`.

Ese patrón sería frágil: un futuro campo nuevo de seed, bracket, rival o diagnóstico podría filtrarse sin que nadie actualizase el blacklist.

El patrón correcto es:

`RandomCup authority → CampaignSnapshotBuilder explícito → Dictionary/DTO sanitizado → TrainerDecisionContext`.

El builder debe crear cada campo permitido conscientemente y producir únicamente datos JSON-serializables/copias profundas.

### 19.5 Datos propios/públicos que el snapshot puede representar

Sin elegir todavía las nueve reglas de gameplay abiertas, el contrato puede admitir de forma segura familias de datos como:

- `schema_version`;
- `mode_id` / `ruleset_id`;
- identidad propia del participante si la IA la necesita como clave estable;
- índice de ronda y número conocido de rondas restantes **solo cuando esa información sea pública/definida por el modo**;
- tamaño inicial del roster;
- IDs propios de miembros que continúan en el roster, o un conteo equivalente cuando sea suficiente;
- número de bajas propias permanentes;
- flags/IDs públicos de las políticas de permadeath, recuperación, progresión, reposición y recursos;
- recursos persistentes **propios** si el ruleset finalmente los define;
- cualquier otro dato exclusivamente propio o públicamente conocido que sea necesario para valorar el coste de una decisión.

No debe duplicarse gratuitamente el estado completo de cada Pokémon: `TrainerObservation.own_party` ya contiene el estado propio de batalla necesario —HP, PP, stats, moveset, habilidad, item, status, etc.—. El snapshot de campaña añade **semántica persistente**, no una segunda copia divergente del roster.

Si en el futuro una modalidad permite registrar miembros propios que no participan en el combate actual, esa necesidad se modelará expresamente en el snapshot sin convertirlo en acceso al estado rival.

### 19.6 Datos expresamente prohibidos

El snapshot V1 no puede contener:

- `RandomCupState` o `RandomCupParticipant` vivos;
- referencias a `CreatureInstance`, `BattleState` o `AuthoritativeBattleServer`;
- RNG vivo, `rng_state`, assignment seed o estado interno de la secuencia aleatoria;
- resultados de futuras tiradas o futuras asignaciones;
- futuros `battle_seed`;
- especies/loadouts/IV/EV/naturaleza/items/recursos de rivales no revelados;
- roster persistente rival oculto;
- bolsa persistente rival oculta;
- información de bracket/emparejamiento que el modo no declare públicamente conocida;
- diagnósticos internos usados por tests/servidor.

Conocer que existe permadeath o que quedan X rondas puede ser legítimo; conocer qué seis Pokémon tiene un rival futuro porque `RandomCupState` los posee internamente no lo es.

Si más adelante hay información pública del torneo sobre otros participantes, deberá entrar mediante un contrato de **public tournament knowledge** explícito, no reutilizando estado autoritativo bruto.

### 19.7 Seam de inyección en `TrainerIntelligenceController`

`TrainerIntelligenceController` es ya la capa confiable que construye observación/contexto y luego llama al brain. Por tanto es el lugar correcto para **transportar** el snapshot sanitizado, pero no para construirlo desde estado de torneo bruto.

Dirección de implementación futura:

1. Random Cup/application layer construye el `TrainerCampaignSnapshot` permitido;
2. lo entrega al controlador como datos ya sanitizados;
3. `choose_action()` crea `TrainerDecisionContext` con ese snapshot;
4. el contexto realiza copia profunda;
5. el brain consume únicamente el contexto.

No se congela todavía si la API concreta será constructor, setter o parámetro de decisión. Sí queda congelado que el controlador no recibirá acceso general a `RandomCupState` solo para que él mismo “escoja qué mirar”.

El snapshot deberá refrescarse antes de una decisión si alguna variable de campaña permitida puede cambiar durante el combate y no está ya representada por `TrainerObservation`. La bolsa battle-scoped actual ya se actualiza por la observación, por lo que no debe duplicarse sin necesidad.

### 19.8 Compatibilidad con self-play y stack histórico

`TrainerSelfPlayMatch` crea controladores sin concepto de campaña y clona rosters para un único combate. Ese comportamiento sigue siendo válido como benchmark battle-only.

La extensión debe permitir:

- contexto antiguo → `campaign_snapshot = {}`;
- ningún cambio semántico para FASE20–33 cuando no hay Random Cup;
- corpus histórico intacto como regresión de batalla;
- nuevo orquestador/corpus multi-battle para Random Cup en una fase posterior.

No se debe transformar `TrainerSelfPlayMatch` en una simulación de copa por defecto.

### 19.9 Tests obligatorios al implementar el seam

La futura tranche deberá añadir al menos:

- contexto sin campaña sigue funcionando y serializando igual salvo la nueva clave vacía acordada;
- snapshot se copia en profundidad y mutar el origen después no cambia el contexto;
- snapshot es JSON-serializable;
- no contiene objetos vivos ni RNG;
- no contiene roster/bolsa/loadout rival oculto;
- no contiene assignment seed ni futuras tiradas;
- `TrainerObservation` mantiene intactos todos los gates de privacidad FASE20;
- una modificación del snapshot no muta `RandomCupState` ni el roster persistente;
- dos decisiones con el mismo estado permitido producen el mismo snapshot;
- self-play histórico puede seguir creando controladores sin snapshot;
- tests adversariales intentan introducir claves/objetos prohibidos y el builder/contrato los rechaza o no los emite.

Más adelante, cuando exista la función de valor de campaña, habrá tests conductuales separados que demuestren que cambiar **solo** un dato legítimo del snapshot —por ejemplo el valor de supervivencia derivado de una pieza única— puede cambiar una decisión sin alterar información rival.

### 19.10 Estado de este checkpoint

- `TrainerObservationBuilder`: **CONSERVAR SIN DATOS DE CAMPAÑA**;
- `TrainerObservation`: **CONSERVAR BATTLE-SCOPED**;
- `TrainerBattleMemory`: **CONSERVAR BATTLE-SCOPED**;
- conocimiento inter-battle rival: **NO CONCEDIDO POR DEFECTO / CAPA FUTURA SI EL RULESET LO JUSTIFICA**;
- `TrainerDecisionContext`: **CONSERVAR FRONTERA + AÑADIR `campaign_snapshot` OPCIONAL**;
- autoridad del snapshot: **RANDOM CUP/APPLICATION LAYER**;
- construcción del snapshot: **WHITELIST EXPLÍCITO**;
- referencias vivas/RNG/estado rival oculto: **PROHIBIDOS**;
- self-play battle-only: **CONSERVAR**;
- corpus multi-battle Random Cup: **NUEVA CAPA POSTERIOR**;
- código de producción modificado en este checkpoint: **NO**.

Siguiente bloque recomendado: auditar dónde y cómo debe calcularse el **valor estratégico de cada miembro del roster** usando solo `own_party + campaign_snapshot`: cobertura única, redundancia, potencia/rol, estado persistente y coste de permadeath. El objetivo será definir el evaluador de roster antes de tocar `TrainerSearchStateEvaluator` o los pesos de switching.

### 19.11 CORRECCIÓN CANÓNICA — Random Cup no permite curación de bolsa

Regla de gameplay confirmada posteriormente por el usuario y que **supersede** cualquier parte anterior de las secciones 13, 17 o 18 que tratase la economía de pociones como una decisión todavía abierta para Random Cup:

- en Random Cup no se permiten `Potion`, `Super Potion`, `Hyper Potion`, `Max Potion`, `Full Restore` ni ninguna otra acción de curación mediante bolsa durante el combate;
- la prohibición es simétrica para jugador y entrenadores IA;
- el ActionSpace Random Cup no debe ofrecer acciones `ITEM` de curación a ningún lado;
- `TrainerItemTacticalEvaluator`, `TrainerItemAwareSearch` y la economía persistente de pociones quedan **FUERA DEL FLUJO RANDOM CUP**;
- FASE30 se conserva como infraestructura para otros modos donde los objetos de bolsa sí sean legales;
- Revive también queda fuera de Random Cup;
- el `TrainerCampaignSnapshot` Random Cup V1 no necesita representar recursos de curación de bolsa ni escasez de pociones.

Esta regla **no decide** por sí sola:

- recuperación automática de HP/PP/status entre combates;
- held items con curación o recuperación pasiva;
- otras categorías de objeto que un futuro ruleset pudiera permitir expresamente.

---

## 20. Auditoría técnica — valor estratégico de miembros del roster

Checkpoint de diseño del evaluador que permitirá razonar sobre permadeath sin mirar rivales futuros. **No se modifica código de producción en este tramo.**

### 20.1 Responsabilidad y nombre provisional

Hace falta una capa nueva, provisionalmente denominada:

**`TrainerRosterStrategicValueEvaluator`**.

Su responsabilidad no es decidir una acción ni predecir el siguiente rival. Debe responder, para cada miembro propio todavía disponible:

> «¿qué pierde objetivamente este roster si este `instance_id` desaparece de forma permanente?»

El evaluador consume únicamente:

- `TrainerObservation.own_party`;
- `TrainerDecisionContext.campaign_snapshot`;
- `DefinitionCatalog`/tabla de tipos y capacidades runtime propias.

No necesita ni debe consultar:

- `observed_opponents`;
- `belief_snapshot`;
- `memory_snapshot` rival;
- bracket oculto;
- futuros rivales;
- RNG/seed.

El matchup actual seguirá perteneciendo a las capas tácticas existentes. Este evaluador mide el **valor del activo dentro de su propio roster**.

### 20.2 Tres salidas separadas — no una cifra opaca

Por cada `instance_id` el resultado debe distinguir al menos:

1. **`structural_value_bp`** — importancia intrínseca/relativa del miembro para la composición del roster si estuviera utilizable.
2. **`operational_readiness_bp`** — cuánto de ese potencial puede ejercer en su estado actual dentro de la batalla.
3. **`permadeath_loss_cost_bp`** — coste estratégico de que desaparezca permanentemente bajo las reglas actuales de campaña.

Además debe devolver breakdown/reasons deterministas para trazabilidad.

Esta separación evita un error crítico: un Pokémon único a 10% de HP puede tener baja disponibilidad operativa **sin dejar de ser una pieza estructuralmente muy valiosa**. Reducir su valor permanente simplemente porque está herido empujaría a la IA a sacrificar precisamente aquello que más debería intentar conservar.

### 20.3 `structural_value_bp` — componentes permitidos

El valor estructural se deriva solo del roster propio superviviente y del loadout real ya materializado.

Componentes V1 candidatos:

- **capacidad de combate real:** stats actuales/base relevantes y movimientos ejecutables del loadout, no solo BST de la especie;
- **cobertura ofensiva útil:** tipos/funciones que sus movimientos `RUNTIME_SUPPORTED` aportan realmente;
- **cobertura ofensiva única:** bonus cuando ese miembro es el único —o claramente el mejor— que cubre una familia de tipos/funciones dentro del roster;
- **resistencia/inmunidad estructural:** tipado defensivo que aporta entradas seguras frente a tipos del universo conocido;
- **resistencia/inmunidad única:** mayor valor si ningún otro superviviente ofrece una respuesta defensiva equivalente;
- **rol inferido:** capacidad de actuar como atacante físico, especial, fast/cleaner, bulky, soporte, etc., derivada de stats+moveset reales y no de un `role_id` preasignado;
- **rol único/flexibilidad:** mayor valor cuando una función necesaria solo existe en ese miembro o cuando puede cubrir varias funciones útiles;
- **redundancia:** descuento cuando otros miembros pueden cumplir casi la misma función con calidad comparable.

No debe premiarse un movimiento `DATA_ONLY`, `UNSUPPORTED` o cualquier capacidad que el ruleset Random Cup no permita materializar. `PARTIAL_RUNTIME` tampoco cuenta en V1 mientras siga excluido de la generación automática.

La contribución de habilidades al valor ofensivo/defensivo solo se incorporará cuando exista una forma runtime explícita y auditable de medir esa capacidad. No se inventarán inmunidades o sinergias por nombre de habilidad.

### 20.4 Poder absoluto y valor relativo deben coexistir

No basta con ordenar los seis miembros entre sí.

Si el equipo aleatorio es muy malo, seguirá existiendo un «mejor miembro» relativo; eso no debe convertirlo artificialmente en una superestrella. Al mismo tiempo, una pieza moderada puede ser estratégicamente crucial si es la única que cubre una debilidad del roster.

Por tanto el valor estructural debe combinar:

- **capacidad absoluta legítimamente medible**;
- **contribución marginal al roster**;
- **redundancia/reemplazabilidad interna**.

No se congela todavía una fórmula ni pesos finales. Primero se definirán fixtures donde esos tres conceptos produzcan ordenaciones obvias y después se calibrarán los pesos contra ellos.

### 20.5 `operational_readiness_bp` — condición actual sin destruir el valor del activo

La disponibilidad operativa puede considerar:

- ratio de HP actual;
- status persistente actual;
- PP disponibles en movimientos relevantes;
- estado consumido del held item cuando corresponda;
- cualquier otra limitación propia ya visible en `own_party`.

Debe representar «qué tan utilizable está ahora», no «cuánto vale que siga existiendo».

La política de recuperación entre combates sigue abierta. Por tanto:

- HP/PP/status siempre pueden afectar la decisión **de la batalla actual**;
- solo afectan al valor de campaña futuro en la medida en que `campaign_snapshot` indique que esa condición persiste según el ruleset;
- si el ruleset cura/restaura algo entre rondas, el evaluador de pérdida permanente no debe fingir que ese daño temporal se arrastrará para siempre.

### 20.6 `permadeath_loss_cost_bp` — coste de borrar el activo

Random Cup tiene permadeath canónico, por lo que perder una instancia debe generar un coste separado de recibir daño normal.

El coste puede derivarse de:

- `structural_value_bp`;
- disponibilidad de sustitutos/redundancia dentro del roster;
- número de supervivientes respecto al roster inicial;
- política de reposición si finalmente existe;
- rondas restantes **solo si esa información es pública y está en `campaign_snapshot`**;
- estado operativo actual como modulador limitado, nunca como mecanismo que convierta una pieza única a 1 HP en «prescindible» automáticamente.

Cuando el roster se reduce y no existe reemplazo, perder otra pieza puede ser más grave que perder una pieza equivalente al principio. Ese multiplicador solo se activa cuando la política de campaña correspondiente está explícitamente disponible; no se asume mientras `replacement_policy` siga abierta.

### 20.7 `TrainerProfile` NO calcula el valor del Pokémon

El valor estructural y el coste objetivo de pérdida deben ser iguales para dos entrenadores que reciben exactamente el mismo estado propio.

`TrainerProfile` ya contiene `preservation_weight_bp`, con diferencias claras entre aggressive/cautious/technical. Esa es la capa apropiada para decidir **cuánto le importa** actuar sobre el riesgo, no para alterar los hechos del roster.

Separación canónica:

`RosterStrategicValueEvaluator` → hechos/valor objetivo del activo.

`TrainerProfile` → tolerancia conductual a exponer/sacrificar ese activo.

`Expertise` futura → calidad con la que se interpreta/utiliza el análisis legítimo, sin cambiar el roster ni la información disponible.

Esto mantiene la identidad del entrenador sin hacer que un agresivo «crea» falsamente que su pieza única vale menos.

### 20.8 Relación con el código FASE31 existente

`TrainerTeamStrategicEvaluator` ya detecta una pieza como única respuesta, pero solo respecto a oponentes observados que quedan **en la batalla actual**. Se conserva como capa táctica de preservación contextual.

`TrainerStrategicSwitchEvaluatorV2._future_value_bp()` también calcula valor únicamente frente a rivales observados restantes. No debe convertirse en el evaluador de campaña mediante más heurísticas añadidas dentro de esa función.

Dirección futura:

- mantener matchup/amenaza actual y amenazas observadas en FASE31;
- introducir `TrainerRosterStrategicValueEvaluator` como fuente separada de valor de campaña;
- switching combina ambos horizontes;
- `productive_sacrifice_window` deja de bastar por sí solo: un sacrificio que parece tácticamente productivo debe descontar el `permadeath_loss_cost_bp` del miembro;
- una pieza de alto coste puede recibir una penalización/veto estratégico al sacrificio salvo que ganar/sobrevivir a la batalla justifique realmente ese coste;
- una pieza muy redundante puede seguir siendo el sacrificio correcto cuando la situación lo exige.

No se elimina FASE31: se evita mezclar en una sola función «matchup futuro de esta batalla» y «valor persistente de campaña».

### 20.9 Relación futura con `TrainerSearchStateEvaluator`

El evaluador de búsqueda actual puntúa todos los KOs propios con un coste uniforme y devuelve victoria terminal antes de evaluar el daño al roster.

Cuando se implemente el valor de campaña:

- un KO propio simulado debe poder cargar el `permadeath_loss_cost_bp` específico de esa instancia;
- ganar el combate seguirá siendo un objetivo dominante, pero la utilidad terminal no debe borrar automáticamente el coste de terminar con medio roster muerto;
- daño no letal y KO permanente deben permanecer conceptualmente separados;
- los pesos finales se calibrarán mediante corpus Random Cup multi-batalla, no por intuición.

Este checkpoint **no congela** todavía cómo se combinarán matemáticamente el score táctico y el de campaña.

### 20.10 Efecto de la prohibición de pociones

La regla canónica de Random Cup simplifica este evaluador:

- no existe componente de «valor de conservar pociones»;
- no existe oportunidad estratégica de gastar una cura de bolsa para proteger una pieza;
- el evaluator no necesita inventario de pociones ni cantidades persistentes;
- switching, selección de acción, movimientos de recuperación propios del Pokémon si existen y held items permitidos serán las únicas formas de conservación dentro del combate que procedan del runtime/ruleset.

La recuperación automática **entre combates** sigue siendo una regla separada y se reflejará mediante `campaign_snapshot` cuando se defina.

### 20.11 Tests mínimos del futuro evaluador

Antes de integrarlo en switching/search debe existir una suite aislada con escenarios deterministas como:

- mismo roster + distintos `TrainerProfile` → mismos valores estructurales/loss-cost;
- miembro con cobertura única > miembro equivalente cuya cobertura está duplicada;
- resistencia/inmunidad única > resistencia repetida, a igualdad razonable;
- dos Pokémon de la misma especie pueden tener distinto valor por moveset/estado/función real;
- Pokémon único a HP bajo → `structural_value_bp` alto pero `operational_readiness_bp` bajo;
- movimiento `DATA_ONLY`/`UNSUPPORTED` no aumenta cobertura estratégica;
- eliminar un miembro del roster puede aumentar la unicidad/valor relativo de los supervivientes;
- si `replacement_policy` declara que no hay reemplazo, una plantilla muy reducida puede elevar el coste marginal de otra muerte;
- si una condición no persiste entre rondas según snapshot, no debe degradar permanentemente el loss-cost futuro;
- cambiar datos ocultos del rival no altera el resultado del evaluador;
- cambiar únicamente datos propios legítimos sí puede alterar el resultado;
- no existe dependencia de bolsa/pociones en Random Cup.

La suite debe registrar breakdowns para que una regresión no pase solo porque «la cifra final sigue parecida».

### 20.12 Estado de este checkpoint

- evaluador estratégico de roster existente: **NO; NUEVA CAPA NECESARIA**;
- nombre provisional: **`TrainerRosterStrategicValueEvaluator`**;
- entradas: **OWN PARTY + CAMPAIGN SNAPSHOT + CATÁLOGO**;
- rivales/beliefs/memoria rival: **FUERA DE ESTA CAPA**;
- salidas mínimas: **STRUCTURAL VALUE + OPERATIONAL READINESS + PERMADEATH LOSS COST**;
- personalidad dentro del valor objetivo: **NO**;
- `TrainerProfile.preservation_weight_bp`: **CONSERVAR COMO MODULADOR POSTERIOR DE DECISIÓN**;
- FASE31 tactical future-value: **CONSERVAR COMO HORIZONTE DE BATALLA, NO COMO CAMPAÑA**;
- economía de pociones Random Cup: **ELIMINADA DEL MODELO**;
- pesos/fórmula final: **NO CONGELADOS AÚN**;
- código de producción modificado: **NO**.

Siguiente bloque recomendado: diseñar la **inferencia dinámica de roles/capacidades sobre `own_party`** que alimentará el valor estructural —sin depender de `TrainerPokemonLoadout.role_id`— y decidir qué señales runtime son suficientemente fiables para clasificar atacante físico/especial, fast, bulky y support.

---

## 21. Auditoría técnica — inferencia dinámica de roles y capacidades

Checkpoint de diseño para interpretar el roster aleatorio ya materializado. **No se modifica código de producción en este tramo.**

### 21.1 Nueva capa — interpretar, nunca construir

Hace falta una capa nueva, provisionalmente denominada:

**`TrainerRosterRoleInference`**.

Su responsabilidad es leer un miembro propio tal como existe realmente y responder qué funciones puede cumplir. No selecciona especie, no cambia movimientos, no asigna EV/IV, no cambia naturaleza, no escoge habilidad ni held item.

Entradas V1:

- vista propia procedente de `TrainerObservation.own_party`;
- `DefinitionCatalog`;
- política runtime ya congelada para Random Cup.

No necesita ni debe leer:

- `TrainerPokemonLoadout.role_id` como verdad estratégica;
- `quality_id`;
- `TrainerProfile`;
- `observed_opponents`;
- beliefs;
- memoria rival;
- RNG/seed.

El `role_id` histórico se conserva por compatibilidad, authored teams y otros modos, pero Random Cup lo tratará como metadata no autoritativa.

### 21.2 FASE32 — separar construcción de inferencia

`TrainerRoleLoadoutGenerator` mezcla deliberadamente varias responsabilidades de construcción:

- `_ivs_for_quality()`;
- `_evs_for_role()`;
- `_nature_for_role()`;
- `_moves_for_role()`;
- `_supported_ability()`;
- `_held_item_for_role()`.

Estas funciones **no se reutilizan** para inferencia Random Cup porque modifican o seleccionan las propiedades del Pokémon.

Sí son reutilizables como inspiración conceptual:

- distinguir daño físico y especial;
- valorar STAB, potencia, prioridad y utilidad estructurada;
- reconocer que bulk físico y especial son funciones distintas;
- mantener determinismo y trazabilidad.

Los tests históricos FASE32 prueban el sentido contrario al que ahora necesitamos: `rol solicitado → construir loadout`. Random Cup necesita `loadout real → inferir roles`.

### 21.3 Las capacidades son más fundamentales que las etiquetas de rol

Para evitar meter efectos distintos a la fuerza dentro de `support`, la inferencia V1 debe producir primero un **vector de capacidades** y después derivar etiquetas de rol.

Capacidades mínimas propuestas:

- `physical_damage_bp`;
- `special_damage_bp`;
- `speed_pressure_bp`;
- `physical_bulk_bp`;
- `special_bulk_bp`;
- `control_bp`;
- `setup_bp`;
- `sustain_bp`.

Después se derivan puntuaciones de rol compatibles con el vocabulario existente:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `bulky_physical`;
- `bulky_special`;
- `support`.

`balanced` queda como **fallback/resumen** cuando no existe una función claramente dominante o cuando el miembro presenta un perfil muy repartido. No se utiliza como capacidad primaria que borre las funciones concretas detectadas.

### 21.4 Salida multietiqueta — un Pokémon puede cumplir varios papeles

La salida por `instance_id` debe incluir como mínimo:

- `capability_scores_bp`;
- `role_scores_bp`;
- `primary_role_id`;
- `secondary_role_ids`;
- `role_confidence_bp`;
- `evidence` / breakdown determinista.

No se fuerza una clasificación exclusiva.

Ejemplos válidos conceptualmente:

- atacante especial + fast attacker;
- bulky físico + support;
- atacante físico + setup;
- bulky especial + sustain;
- híbrido físico/especial si el stats+moveset real lo justifican.

Esto es especialmente importante en Random Cup: una plantilla aleatoria puede obligar a un mismo miembro a cubrir más de una función.

### 21.5 Señales para daño físico y especial

La inferencia debe utilizar los **stats reales materializados** de `own_party`, no solo base stats de especie. Eso incorpora legítimamente nivel, IV, EV y naturaleza ya existentes sin volver a diseñarlos.

Para `physical_damage_bp` deben aportar evidencia, entre otras señales:

- Attack real;
- existencia de movimientos físicos `RUNTIME_SUPPORTED` con potencia > 0;
- potencia;
- STAB;
- accuracy;
- prioridad;
- capacidades estructuradas que amplifiquen de forma explícita una ruta física cuando exista soporte runtime auditable.

`special_damage_bp` aplica el mismo principio con Special Attack y movimientos especiales.

Un Attack enorme sin ningún movimiento físico ejecutable no basta para declarar al miembro atacante físico fuerte. Del mismo modo, un movimiento físico potente no debe ignorar que el stat real de Attack puede ser muy pobre.

### 21.6 `fast_attacker` — velocidad real + ruta ofensiva

La velocidad se obtiene del stat real propio y debe combinarse con una ruta ofensiva ejecutable.

Un Pokémon rápido que no puede ejercer presión ofensiva no debe recibir automáticamente una puntuación máxima de `fast_attacker`.

La prioridad positiva de movimientos aporta **cleaner/finish pressure**, pero no sustituye totalmente la velocidad real: un Pokémon lento con prioridad puede ser un buen rematador sin convertirse conceptualmente en uno de los miembros más rápidos del roster.

No se congela todavía una fórmula absoluta de normalización. Los fixtures deberán cubrir tanto velocidad intrínseca como comparación razonable entre miembros antes de fijar pesos.

### 21.7 Bulk físico y especial — potencial estructural, no HP actual

`physical_bulk_bp` debe derivarse de la capacidad real de absorber daño físico, principalmente:

- max HP;
- Defense real;
- tipado/resistencias estructurales cuando el evaluador correspondiente las integre de forma auditable;
- sustain explícito como señal complementaria, no como sustituto de bulk.

`special_bulk_bp` aplica el mismo principio con Special Defense.

**El HP actual no define el rol.** Un muro a 10% de vida sigue siendo estructuralmente bulky aunque esté temporalmente casi inutilizable. Su estado actual pertenece a `operational_readiness_bp` de la capa estratégica/táctica.

Los stat stages temporales tampoco deben reescribir el rol intrínseco.

### 21.8 Utilidad estructurada — separar control, setup y sustain

`BattleEffectSpec` ya proporciona señales semánticas suficientemente explícitas para no inferir por nombre de movimiento.

Mapeo conceptual V1:

- `INFLICT_STATUS` sobre oponente → `control`;
- `MODIFY_STAT_STAGE` negativo sobre oponente → `control` / debuff;
- `FLINCH` → `control`, ponderado por chance/condiciones disponibles;
- `MODIFY_STAT_STAGE` positivo sobre self → `setup`;
- `HEAL` sobre self → `sustain`;
- `DRAIN` → `sustain` + daño correspondiente;
- `CURE_STATUS` propio → `sustain/utility`;
- `RECOIL` → coste/penalización de sustain;
- `CHANCE` → recurse ponderando `chance_basis_points`;
- `REVIVE` → ignorado/prohibido en Random Cup;
- efectos de daño/fixed/max-HP/multi-hit → alimentan capacidades ofensivas cuando su semántica runtime sea ejecutable.

Un movimiento de setup propio **no convierte por sí solo** al Pokémon en support. Del mismo modo, recuperación propia puede reforzar bulk/sustain sin tener que etiquetarse automáticamente como soporte puro.

`support` se deriva principalmente de control, debuff, status, cura/utility y otras capacidades no puramente ofensivas que beneficien la estabilidad táctica del miembro/equipo dentro de las mecánicas realmente implementadas.

### 21.9 Gate DATA V3 — fail closed

La inferencia Random Cup V1 solo cuenta capacidades que el ruleset considera ejecutables.

Contrato actual:

- `RUNTIME_SUPPORTED` → puede contribuir;
- `PARTIAL_RUNTIME` → no contribuye en V1 mientras siga excluido de generación automática;
- `DATA_ONLY` → no contribuye;
- `UNSUPPORTED` → no contribuye.

La comprobación debe usar `MoveDefinition.classification`, no el whitelist histórico pequeño de Battle V2.

Aunque el generador Random Cup futuro debería impedir que llegue un moveset ilegal, la inferencia debe fallar de forma segura: un movimiento no aceptado no puede inflar silenciosamente un rol si entra por fixture, save antiguo u otro flujo.

### 21.10 Habilidades y held items — no inferir semántica por nombre

El miembro propio conoce su `ability_id` y `held_item_id`, pero Random Cup V1 no debe adjudicar roles mediante reglas como “si habilidad == Levitate entonces…” o “si item == Leftovers entonces bulky” salvo que exista una capacidad runtime estructurada y auditable que represente el efecto.

Dirección V1:

- stats + moveset + tipado estructural = señales base;
- habilidad/held item solo entran en el vector cuando exista una API semántica runtime explícita y comprobable;
- no duplicar a mano una segunda base de conocimiento de efectos dentro de Trainer AI.

Esto evita que la IA conozca mejor una mecánica por su nombre de lo que el propio runtime sabe ejecutar.

### 21.11 Rol intrínseco vs importancia del rol dentro del roster

Se congelan dos conceptos separados:

1. **Role inference intrínseca:** qué puede hacer este `instance_id` por sus stats/loadout reales.
2. **Roster role importance:** qué tan escasa, única o reemplazable es esa capacidad dentro de los supervivientes actuales.

La primera no debe cambiar simplemente porque muera un compañero.

La segunda sí puede cambiar radicalmente con permadeath.

Ejemplo:

- un Pokémon con `support=6200` y `special_attacker=7800` conserva esas capacidades si muere el soporte principal;
- después de la baja, su `support` puede pasar a ser la mejor alternativa del roster y aumentar su importancia estratégica, sin falsificar su score intrínseco.

Esta separación alimentará directamente `TrainerRosterStrategicValueEvaluator` y evita roles “mágicamente reescritos” por necesidades del equipo.

### 21.12 Estado actual, PP y status — no borrar identidad funcional

La inferencia estructural no debe degradarse porque:

- el Pokémon tenga poco HP;
- esté quemado/paralizado/etc.;
- un movimiento esté temporalmente sin PP;
- exista un stat stage temporal.

Esos datos sí importan para la **disponibilidad operativa** y la decisión táctica actual.

Si una política de Random Cup hace que PP/status persistan entre rondas, esa persistencia podrá reducir `operational_readiness_bp` o utilidad estratégica futura, pero seguirá separada de la pregunta “¿qué función define este loadout cuando es utilizable?”.

Si el propio Pokémon cambia persistentemente —nivel, evolución, moveset real— la inferencia se recalcula porque la capacidad objetiva sí cambió.

### 21.13 Relación con `TrainerTeamAnalyzer`

`TrainerTeamAnalyzer` actualmente calcula `role_counts` leyendo `loadout.role_id`.

En el flujo Random Cup moderno deberá consumir la nueva inferencia en vez de esa etiqueta authored.

Dirección futura:

- conservar análisis de tipos, debilidades, resistencias y cobertura reutilizable;
- reemplazar el conteo autoritativo de `role_id` por cobertura de roles inferidos;
- distinguir presencia fuerte de un rol de simples secundarios débiles;
- usar la distribución de scores para detectar ausencia, redundancia y unicidad;
- no congelar aún umbrales exactos hasta crear fixtures de inferencia.

El Analyzer histórico puede seguir comportándose como antes para `TrainerTeamDefinition` authored fuera de Random Cup si se necesita compatibilidad.

### 21.14 `balanced` no debe esconder información

`TrainerPokemonLoadout.ROLE_BALANCED` se conserva por compatibilidad, pero no debe convertirse en una bolsa donde caigan todos los casos difíciles.

En Random Cup:

- `balanced` puede ser `primary_role_id` de resumen si ningún rol específico domina o si existe una distribución muy pareja;
- aun así `role_scores_bp` y `capability_scores_bp` completos siempre se conservan;
- el valor estratégico y la IA pueden utilizar capacidades secundarias aunque el resumen diga `balanced`.

Así un híbrido no pierde información útil por una decisión de etiquetado.

### 21.15 Tests mínimos de la futura inferencia

Antes de integrarla en `TrainerTeamAnalyzer` o valor estratégico debe existir una suite aislada y determinista que pruebe al menos:

- mismo `CreatureInstance` + distinto `TrainerPokemonLoadout.role_id` histórico → misma inferencia;
- mismo miembro + distinto `TrainerProfile` → misma inferencia;
- misma especie con moveset físico vs moveset especial → roles distintos;
- misma especie con moveset de status/debuff vs ofensivo → soporte/control distinto;
- híbrido real → múltiples roles significativos, no clasificación exclusiva;
- self-setup aumenta `setup` pero no convierte por sí solo en support;
- recuperación/drain aumenta `sustain`;
- movimiento `DATA_ONLY`, `PARTIAL_RUNTIME` o `UNSUPPORTED` no aumenta capacidades V1;
- ataque alto sin ruta física ejecutable no obtiene score físico alto solo por stat;
- velocidad alta sin ruta ofensiva no obtiene automáticamente `fast_attacker` máximo;
- HP actual bajo no cambia `physical_bulk_bp`/`special_bulk_bp` estructural;
- current PP = 0 no borra el rol estructural, aunque una capa de readiness pueda penalizar disponibilidad;
- eliminar otro miembro del roster no cambia los role scores intrínsecos del superviviente;
- la importancia/escasez posterior sí puede cambiar al recalcular el roster;
- cambiar cualquier dato oculto rival no altera el resultado;
- mismo input → mismo output y mismo breakdown.

### 21.16 Estado de este checkpoint

- inferencia dinámica existente: **NO; NUEVA CAPA NECESARIA**;
- nombre provisional: **`TrainerRosterRoleInference`**;
- autoridad de `TrainerPokemonLoadout.role_id` en Random Cup: **NO**;
- salida: **MULTIROLE + VECTOR DE CAPACIDADES**;
- roles específicos: **PHYSICAL / SPECIAL / FAST / BULKY PHYSICAL / BULKY SPECIAL / SUPPORT**;
- `balanced`: **FALLBACK/RESUMEN, NO CAPACIDAD OCULTADORA**;
- señales base: **STATS REALES + MOVESET RUNTIME + EFFECT_SPECS + TIPADO ESTRUCTURAL**;
- HP/status/PP actuales dentro del rol estructural: **NO; VAN A READINESS**;
- perfil/personalidad dentro de inferencia: **NO**;
- rivales/beliefs/RNG dentro de inferencia: **NO**;
- habilidad/item por nombre: **PROHIBIDO**;
- pesos/umbrales numéricos finales: **NO CONGELADOS; PRIMERO FIXTURES**;
- código de producción modificado: **NO**.

Siguiente bloque recomendado: cerrar el **orden de implementación mínimo** de las nuevas piezas ya diseñadas (`campaign_snapshot`, role inference, roster strategic value) y decidir cuál puede implementarse/testearse primero sin depender de las reglas de gameplay de Random Cup que aún están abiertas.

---

## 22. Orden de implementación mínimo — dependencias y gates de certificación

Checkpoint de transición entre auditoría y primeras tranches de producción. **No se modifica código de producción en este commit.**

### 22.1 Grafo de dependencias

Las tres piezas nuevas no tienen el mismo grado de dependencia:

1. **`campaign_snapshot` seam**
   - depende únicamente del contrato de seguridad ya congelado;
   - no depende de nivel, duplicados, progresión, recuperación entre rondas, reposición ni loadout Random Cup;
   - puede existir vacío (`{}`) en todo el stack histórico.

2. **`TrainerRosterRoleInference`**
   - depende de `TrainerObservation.own_party`, catálogo DATA V3 y clasificación runtime de movimientos;
   - no depende de cómo se sorteó el Pokémon ni de qué política futura lo generó;
   - no depende de HP/PP/status persistentes porque esos estados no definen el rol intrínseco;
   - sí necesita fixtures/normalizaciones antes de congelar pesos y umbrales.

3. **`TrainerRosterStrategicValueEvaluator`**
   - depende de la inferencia de roles/capacidades;
   - usa `campaign_snapshot` para semántica persistente;
   - `structural_value_bp` puede diseñarse con datos ya disponibles, pero `permadeath_loss_cost_bp` completo depende de políticas como reposición y recuperación;
   - por tanto no debe implementarse primero ni con placeholders semánticos.

Orden canónico:

`safe campaign seam → role inference → strategic roster value → integración switching/search`.

### 22.2 Tranche C1 — extender `TrainerDecisionContext` de forma aditiva

Primera modificación de producción recomendada.

Cambios mínimos:

- añadir `campaign_snapshot: Dictionary = {}` a `TrainerDecisionContext`;
- ampliar `create()` con parámetro opcional al final, default `{}`;
- copiarlo con `duplicate(true)`;
- incluirlo en `to_dict()` mediante una clave estable;
- no modificar `TrainerObservation`, beliefs ni battle memory;
- ningún brain histórico debe necesitar leerlo.

La firma debe mantener compatibilidad porque todos los call sites existentes podrán seguir usando los argumentos actuales.

Tests FASE20 a ampliar:

- sin snapshot, contexto se sigue creando;
- snapshot vacío produce comportamiento antiguo;
- snapshot no vacío se copia en profundidad;
- mutar el Dictionary origen después no cambia el contexto;
- mutar la copia serializada no cambia el contexto;
- JSON serialization funciona;
- legal actions/belief/memory conservan sus gates anteriores.

Este cambio **sí puede implementarse ya** sin `RandomCupState` real.

### 22.3 Tranche C1b — transporte opcional en `TrainerIntelligenceController`

Después de certificar C1, añadir únicamente transporte de un snapshot ya sanitizado.

Dirección mínima:

- el controller mantiene una copia local del snapshot permitido o lo recibe mediante un seam explícito;
- el default es `{}`;
- `choose_action()` lo pasa a `TrainerDecisionContext.create()`;
- el controller no recibe `RandomCupState` vivo;
- el controller no construye conocimiento de campaña por su cuenta;
- reemplazar el snapshot de origen no muta `last_context` ya creado.

No hace falta crear todavía `TrainerCampaignSnapshotBuilder`: esa pieza pertenece a la futura capa Random Cup y debe construirse cuando exista el estado autoritativo del modo.

Esto evita crear una falsa clase de torneo solo para satisfacer una dependencia de tests.

### 22.4 Gate C1 — qué significa “certificado”

C1/C1b son cambios de producción, por lo que un commit final de esa tranche no puede considerarse certificado solo por revisión documental.

Gate mínimo:

- suite `TrainerIntelligenceFoundationTestSuite` verde con las nuevas regresiones;
- todas las regresiones antiguas de privacidad siguen verdes;
- ningún call site histórico necesita pasar campaña explícitamente;
- self-play battle-only conserva semántica con `{}`;
- full CI matrix verde en el **HEAD exacto final** de la tranche antes de llamarla certificada.

Si se añade documentación después del HEAD verde, debe rerunearse la matriz sobre el nuevo HEAD antes de certificar el exacto final.

### 22.5 Tranche C2 — fixtures de role inference antes de pesos

La segunda pieza implementable es `TrainerRosterRoleInference`, pero no conviene empezar pegando números intuitivos.

Primero debe crearse una suite aislada con fixtures sintéticos explícitos que definan relaciones esperadas, no cifras arbitrarias.

Ejemplos de invariantes:

- mismo stats + moveset físico claramente mejor que especial → `physical_attacker` > `special_attacker`;
- invertir moveset/stats invierte la relación;
- un híbrido conserva dos scores relevantes;
- velocidad sin presión ofensiva no basta para `fast_attacker` alto;
- HP+Defense altos elevan bulk físico aunque `current_hp` sea bajo;
- status/debuff estructurado eleva control/support;
- self-setup eleva setup pero no fuerza support;
- heal/drain elevan sustain;
- `DATA_ONLY`, `PARTIAL_RUNTIME`, `UNSUPPORTED` no aportan en Random Cup V1;
- `role_id`, `TrainerProfile`, rival y current PP no alteran el rol intrínseco.

Todos los movimientos sintéticos de esta suite deben fijar `classification` expresamente para no repetir el error de fixtures FASE32.

### 22.6 Normalización C2 — no usar solo ranking interno

La inferencia necesita combinar señal absoluta y relativa sin que un roster malo convierta automáticamente a su mejor miembro en “élite”.

Dirección de implementación:

- producir primero features/capacidades intrínsecas por miembro;
- normalizarlas mediante reglas deterministas que no dependan exclusivamente del ranking entre los seis;
- derivar `role_scores_bp` desde esos features;
- calcular `primary_role_id`/secundarios después, como resumen;
- breakdown obligatorio para poder calibrar y auditar.

Los primeros tests deben preferir **desigualdades/monotonicidad y estabilidad** antes que congelar scores exactos. Los valores exactos se congelarán cuando los fixtures representativos demuestren que la escala es razonable.

### 22.7 Tranche C2 — aislamiento deliberado

`TrainerRosterRoleInference` no debe integrarse inmediatamente en `TrainerTeamAnalyzer`, switching o search en el mismo commit.

Secuencia segura:

1. nueva clase + suite aislada;
2. certificar determinismo, fail-closed DATA V3 y multirole;
3. después adaptar `TrainerTeamAnalyzer` en una tranche separada para consumir los resultados inferidos en Random Cup;
4. mantener el flujo authored histórico con `role_id` cuando corresponda.

Esto permite saber si un fallo viene de la inferencia o de su consumidor.

### 22.8 Tranche C3 — valor estratégico solo después de C2

No implementar `TrainerRosterStrategicValueEvaluator` antes de disponer de role inference estable.

Motivos:

- de lo contrario volvería a depender de `role_id` authored;
- o duplicaría reglas de daño/bulk/support dentro del evaluador estratégico;
- ambas opciones crearían dos fuentes de verdad que divergirían.

C3 consume:

- role/capability inference certificada;
- cobertura/tipado estructural reutilizable;
- `own_party`;
- `campaign_snapshot`.

### 22.9 Qué parte de C3 está bloqueada por gameplay

`structural_value_bp` y parte de la redundancia pueden implementarse cuando C2 esté estable.

Pero no se debe congelar el `permadeath_loss_cost_bp` completo hasta resolver al menos:

- `replacement_policy`;
- `between_battle_recovery_policy` para saber cuánto del estado operativo se arrastra;
- información pública de rondas/restantes si se quiere usar ese factor.

La ausencia de pociones de bolsa **ya está resuelta y no bloquea C3**.

Si estas políticas siguen abiertas al llegar a C3, se puede implementar primero un evaluador estructural separado, pero no una API que finja devolver un loss-cost definitivo con defaults inventados.

### 22.10 Integración con FASE31/search — última, no primera

Solo después de C1–C3:

- `TrainerStrategicSwitchEvaluatorV2` puede consumir coste de pérdida persistente;
- `productive_sacrifice_window` puede descontar/vetar según `permadeath_loss_cost_bp`;
- `TrainerSearchStateEvaluator` puede dejar de tratar todos los KOs propios como equivalentes;
- la victoria terminal puede combinarse con coste real del roster superviviente.

No se tocarán esos pesos todavía: necesitan corpus Random Cup y evaluación multi-batalla.

### 22.11 Qué reglas abiertas NO bloquean C1 ni C2

Pueden seguir pendientes sin impedir las dos primeras tranches:

- duplicados;
- nivel inicial exacto;
- XP/evolución/progresión;
- machine/tutor/egg;
- política concreta de IV/EV/naturaleza/habilidad;
- held items;
- recuperación HP/PP/status entre rondas;
- reposición.

C2 interpreta el Pokémon **ya materializado** y por ello no necesita saber por qué reglas llegó a tener esos stats/movimientos.

La única frontera runtime que sí necesita es la ya congelada para Random Cup V1: contar únicamente capacidades aceptadas (`RUNTIME_SUPPORTED`).

### 22.12 Primer cambio de producción autorizado

Con la auditoría actual ya existe suficiente contrato para abandonar la fase exclusivamente documental en una tranche muy pequeña.

**Primer cambio autorizado:** C1 — `campaign_snapshot` opcional en `TrainerDecisionContext`, con tests FASE20.

No requiere decidir ninguna regla de gameplay pendiente y no cambia la conducta de los brains mientras el snapshot permanezca vacío.

Después de certificar C1 se decidirá si C1b entra en la misma microfase o en la siguiente según el tamaño real del diff/tests.

### 22.13 Estado de este checkpoint

- orden de implementación: **CONGELADO**;
- C1 campaign seam: **IMPLEMENTABLE YA**;
- C1b controller transport: **IMPLEMENTABLE DESPUÉS DE C1**;
- C2 role inference: **IMPLEMENTABLE TRAS FIJAR FIXTURES/ESCALA, SIN ESPERAR RANDOM CUP COMPLETO**;
- C3 strategic value: **DESPUÉS DE C2; LOSS-COST COMPLETO BLOQUEADO PARCIALMENTE POR POLÍTICAS DE CAMPAÑA**;
- switching/search: **INTEGRACIÓN POSTERIOR**;
- `RandomCupState` artificial para tests C1: **NO CREAR**;
- pociones de bolsa: **NO FORMAN PARTE DEL FLUJO RANDOM CUP**;
- código de producción modificado en este checkpoint: **NO**.

Siguiente bloque recomendado: ejecutar la **tranche C1** en código —extensión aditiva de `TrainerDecisionContext` + regresiones FASE20—, correr los tests pertinentes y, si quedan verdes, preparar la certificación del HEAD exacto antes de pasar al transporte del controller.

---

## 23. Tranche C1 — `campaign_snapshot` en `TrainerDecisionContext`

Checkpoint de primera modificación de producción del rediseño PRE-FASE34.

### 23.1 Implementación

C1 extiende de forma aditiva el contrato seguro de `TrainerDecisionContext`:

- añade `campaign_snapshot: Dictionary = {}`;
- `create()` recibe `p_campaign_snapshot` como último parámetro opcional con default `{}`;
- el snapshot se copia mediante `duplicate(true)`;
- `to_dict()` lo serializa bajo la clave estable `campaign` mediante una nueva copia profunda;
- los call sites históricos continúan siendo válidos sin pasar campaña;
- no se ha modificado `TrainerObservation`, `TrainerBattleMemory`, beliefs, brains ni `TrainerIntelligenceController` en esta tranche.

Commits de implementación:

- `6f28d3bdb7677351ac21fd6b31f6b86715a80ee7` — `feat(trainer-ai): add optional campaign snapshot to decision context`;
- `9ca4c78d34d6ad47f1577eb4a5d95d5d75b6abf7` — regresiones FASE20 iniciales;
- `27d1f2ec9fc86895d8e5b5006ed2a67181664827` — corrección estricta de tipado del resultado JSON del test.

### 23.2 Regresiones añadidas

FASE20 comprueba ahora explícitamente:

- contexto antiguo sin snapshot → `campaign_snapshot` vacío;
- serialización con clave `campaign` vacía en ese caso;
- snapshot no vacío aceptado;
- mutar el diccionario origen no altera el contexto;
- mutar arrays/diccionarios anidados del origen no altera el contexto;
- mutar la salida de `to_dict()` no altera el snapshot almacenado;
- JSON round-trip/serialización del snapshot funciona;
- las regresiones existentes de aislamiento, privacidad, ausencia de `BattleState` y ausencia de RNG siguen intactas.

### 23.3 Incidente CI detectado y corregido

La primera ejecución CI sobre `9ca4c78d34d6ad47f1577eb4a5d95d5d75b6abf7` falló únicamente en `Trainer Intelligence Foundation Tests` durante importación de Godot.

Causa exacta:

- el nuevo test usaba `var parsed := JSON.parse_string(json_text)`;
- Godot 4.7 infería ese retorno como `Variant`;
- el proyecto trata ese warning de inferencia como error.

No fue un fallo del contrato de campaña ni una regresión de runtime.

Corrección:

`var parsed: Variant = JSON.parse_string(json_text)`.

El fix quedó en `27d1f2ec9fc86895d8e5b5006ed2a67181664827`.

### 23.4 Certificación de código C1

PR de auditoría/CI: **#98**, abierto contra `main` únicamente para ejecutar la matriz. No debe mergearse; el patrón previsto es cerrarlo sin merge después de la validación del HEAD final.

Sobre el SHA exacto:

`27d1f2ec9fc86895d8e5b5006ed2a67181664827`

resultado confirmado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- `Trainer Intelligence Foundation Tests`: **70 PASS / 0 FAIL**;
- `Godot 4.7 Tests`: SUCCESS;
- `Data Foundation V3 Tests`: SUCCESS;
- self-play, beliefs, tactical, search, adaptive branching, items, loadouts, team composition, switching y corpus: SUCCESS.

Por tanto, **C1 de código queda CERTIFICADO en `27d1f2ec9fc86895d8e5b5006ed2a67181664827`**.

### 23.5 Estado y siguiente tranche

- C1 context seam: **IMPLEMENTADO Y CERTIFICADO**;
- `campaign_snapshot` en controller: **TODAVÍA NO**;
- `RandomCupState`/builder artificial creado para tests: **NO**;
- conducta histórica con snapshot vacío: **CONSERVADA**;
- `main`: **NO MOVIDO**;
- siguiente modificación de producción autorizada: **C1b — transporte opcional del snapshot ya sanitizado mediante `TrainerIntelligenceController`**.

Este commit documental posterior a `27d1f2ec...` deberá pasar la matriz completa sobre su propio SHA antes de que el HEAD final de la rama pueda considerarse certificado.

---

## 24. Tranche C1b — transporte de `campaign_snapshot` en `TrainerIntelligenceController`

Checkpoint de cierre del seam de campaña entre la capa de aplicación confiable y el contexto de decisión seguro.

### 24.1 Implementación

C1b extiende únicamente el transporte en `TrainerIntelligenceController`:

- añade `_campaign_snapshot: Dictionary = {}` como almacenamiento privado del controller;
- añade `set_campaign_snapshot(p_campaign_snapshot)` y realiza `duplicate(true)` al recibir el dato;
- `choose_action()` pasa `_campaign_snapshot` como quinto argumento a `TrainerDecisionContext.create()`;
- el comportamiento por defecto continúa siendo `{}` para combates normales y self-play battle-only;
- el controller recibe únicamente un snapshot **ya sanitizado**;
- el controller no recibe `RandomCupState` vivo;
- el controller no construye ni infiere información de campaña;
- `begin()`, memoria de batalla, observación, beliefs y brains no cambian en esta tranche.

Commits de C1b:

- `a69bb0e2a8b6a62b4d22bbf8de925cbf36b89142` — `feat(trainer-ai): transport campaign snapshot through controller`;
- `2cf09fe1ebd2fba28543a84c3809523c014574ec` — `test(trainer-ai): cover controller campaign snapshot transport`;
- `eead7947e72d4fb9b02df271875f8d2ec2c36858` — `test(trainer-ai): run controller campaign transport regression`.

### 24.2 Regresiones específicas

Se añadió una suite aislada `TrainerIntelligenceControllerCampaignTestSuite` y se conectó al runner FASE20.

Las siete comprobaciones nuevas son:

- `intel_controller_campaign_begin`;
- `intel_controller_campaign_default_empty`;
- `intel_controller_campaign_source_detached`;
- `intel_controller_campaign_nested_detached`;
- `intel_controller_campaign_refreshes_next_context`;
- `intel_controller_campaign_previous_context_stable`;
- `intel_controller_campaign_can_clear`.

La suite demuestra que:

- el controller funciona sin campaña explícita;
- el origen se copia en profundidad;
- mutaciones posteriores del Dictionary origen no contaminan la decisión;
- actualizar el snapshot afecta a la siguiente decisión;
- un `last_context` ya creado permanece estable cuando el controller recibe otro snapshot;
- volver a `{}` limpia el transporte para decisiones posteriores.

### 24.3 Certificación de código C1b

PR temporal de auditoría/CI: **#99**, contra `main`, sin intención de merge.

SHA exacto de código C1b:

`eead7947e72d4fb9b02df271875f8d2ec2c36858`

Resultado confirmado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- `Trainer Intelligence Foundation Tests`: **77 PASS / 0 FAIL**;
- `Godot 4.7 Tests`: SUCCESS;
- `Data Foundation V3 Tests`: SUCCESS;
- self-play, beliefs, tactical, search, adaptive branching, item actions, loadouts, team composition, switching y corpus: SUCCESS.

Por tanto, **C1b de código queda CERTIFICADO en `eead7947e72d4fb9b02df271875f8d2ec2c36858`**.

### 24.4 Consecuencia arquitectónica y siguiente tranche

Con C1 + C1b queda completo el seam seguro de transporte:

`application layer confiable → snapshot sanitizado → TrainerIntelligenceController → TrainerDecisionContext → brain`.

Todavía **NO** existe `TrainerCampaignSnapshotBuilder` ni autoridad `RandomCupState/Participant` funcional. Esa futura capa deberá construir el snapshot mediante whitelist positiva, tal como quedó congelado en la sección 19; el controller no sustituye esa responsabilidad.

Estado:

- C1 context seam: **IMPLEMENTADO Y CERTIFICADO**;
- C1b controller transport: **IMPLEMENTADO Y CERTIFICADO EN SHA DE CÓDIGO**;
- builder/autoridad Random Cup real: **NO IMPLEMENTADOS**;
- integración `TrainerTeamAnalyzer`: **NO TOCADA**;
- switching/search con valor de campaña: **NO TOCADOS**;
- C3 strategic value: **NO INICIADO**;
- `main`: **NO MOVIDO**;
- siguiente tranche autorizada tras certificar el HEAD documental final: **C2 — fixtures e invariantes de `TrainerRosterRoleInference` antes de fijar pesos**.

Este commit documental debe rerunear la matriz completa sobre su **SHA exacto** antes de considerar certificado el HEAD final de la rama.

---

## 25. Tranche C2a — contrato ejecutable de fixtures para inferencia de roles

Checkpoint previo a implementar `TrainerRosterRoleInference`. Esta tranche congela únicamente la frontera de entrada y los casos de prueba básicos; **no implementa todavía inferencia, pesos, role scores ni integración con consumidores**.

### 25.1 Frontera de fixtures

La futura inferencia trabajará sobre la misma clase de datos que ya expone `TrainerObservation.own_party`: diccionarios sanitizados equivalentes a `CreatureInstance.to_dict()`, no `BattleState` ni `CreatureInstance` vivos.

Se añadió `TrainerRosterRoleInferenceFixtures` con un catálogo sintético deliberadamente pequeño y explícito:

- una especie neutral de fixture;
- movimiento físico `RUNTIME_SUPPORTED`;
- movimiento especial `RUNTIME_SUPPORTED`;
- movimiento de prioridad `RUNTIME_SUPPORTED`;
- control como `MODIFY_STAT_STAGE` negativo sobre oponente;
- setup como `MODIFY_STAT_STAGE` positivo sobre self;
- sustain como `HEAL` sobre self;
- un movimiento `PARTIAL_RUNTIME`;
- un movimiento `DATA_ONLY`;
- un movimiento `UNSUPPORTED`.

A diferencia de los fixtures históricos FASE32, **todos los movimientos fijan `classification` de forma explícita**. Esto evita repetir el error de tratar por accidente un fixture que usa el default `DATA_ONLY` como si fuese una capacidad plenamente ejecutable.

### 25.2 Invariantes congeladas antes de los pesos

Se añadió `TrainerRosterRoleInferenceFixtureTestSuite` y se conectó al runner de Trainer Loadouts.

Las 18 comprobaciones nuevas congelan que:

- los seis movimientos positivos del fixture son explícitamente `RUNTIME_SUPPORTED`;
- `PARTIAL_RUNTIME`, `DATA_ONLY` y `UNSUPPORTED` están representados de forma separada;
- control usa semántica estructurada de debuff al oponente;
- setup usa semántica estructurada de buff propio;
- sustain usa semántica estructurada de curación propia;
- las vistas física y especial usan stats reales materializados distintos;
- physical/special fixtures poseen rutas de daño distintas;
- la vista propia es JSON-serializable y cruza una frontera `Dictionary`;
- bajar HP conserva stats y moveset estructurales y altera únicamente una señal de readiness;
- llevar PP a cero conserva la identidad estructural del movimiento;
- los movimientos de clasificación excluida pueden llegar deliberadamente a futuros tests fail-closed;
- dos vistas generadas por separado son profundamente independientes.

Estas pruebas **no afirman todavía** cuánto debe valer cada capacidad. Preparan el terreno para que C2b pruebe relaciones de monotonicidad y fail-closed sin inventar scores exactos antes de tiempo.

### 25.3 Incidente CI del primer intento

El primer HEAD de fixtures sometido a CI fue:

`7ebb76df2ff2d58cc7d8b3c083e8f42bb4452de0`.

Resultado:

- 17/18 workflows: SUCCESS;
- `Trainer Loadouts Tests`: FAILED.

La importación general del proyecto había terminado correctamente. El fallo exacto estaba dentro de la nueva suite:

`Cannot infer the type of "pp_variant_ok" variable because the value doesn't have a set type.`

Como la suite no pudo compilarse, el runner intentó instanciar una clase inválida (`Nonexistent function 'new' in base 'GDScript'`) y terminó agotando el timeout de 240 s con exit 124.

No fue una regresión semántica de Trainer AI ni un fallo de los contratos C2. Fue un error de tipado estricto del test bajo Godot 4.7.

Corrección aplicada:

- `pp_variant_ok: bool` explícito;
- `independent: bool` explícito de forma preventiva;
- `a_stats: Dictionary` explícito.

El fix quedó en:

`add1dd76ed8b5f9fbe507dd595d246ca4eb2b3cb` — `test(trainer-ai): fix strict bool typing in C2 fixtures`.

### 25.4 Certificación de C2a

PR temporal de auditoría/CI: **#100**, contra `main`, sin intención de merge.

Sobre el SHA exacto:

`add1dd76ed8b5f9fbe507dd595d246ca4eb2b3cb`

resultado confirmado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- `Trainer Loadouts Tests`: **234 PASS / 0 FAIL**;
- de esos checks, **18 son las nuevas invariantes C2a**;
- `Godot 4.7 Tests`: SUCCESS;
- `Data Foundation V3 Tests`: SUCCESS;
- resto de gates de Trainer AI: SUCCESS.

Por tanto, **C2a de fixtures/tests queda CERTIFICADO en `add1dd76ed8b5f9fbe507dd595d246ca4eb2b3cb`**.

### 25.5 Límites y siguiente tranche

Estado al cerrar C2a:

- `TrainerRosterRoleInference` de producción: **TODAVÍA NO EXISTE**;
- pesos/umbrales numéricos: **NO FIJADOS**;
- role scores / primary / secondary roles: **NO IMPLEMENTADOS**;
- `TrainerTeamAnalyzer`: **NO TOCADO**;
- switching/search: **NO TOCADOS**;
- código de producción modificado en C2a: **NO**;
- `main`: **NO MOVIDO**.

Siguiente tranche autorizada: **C2b — implementar la mínima extracción intrínseca de capacidades contra estos fixtures**, empezando por fail-closed de `MoveDefinition.classification`, stats/moveset estructurales y relaciones de monotonicidad. Todavía sin integrar `TrainerTeamAnalyzer`, switching ni search y sin congelar pesos finales por intuición.

Este commit documental debe rerunear la matriz completa sobre su **SHA exacto** antes de considerar certificado el HEAD final de la rama.

---

## 26. Consolidación C2b–C2e-e — role inference, DATA V3 y evidencia de control

Este checkpoint reconcilia en el cuaderno temático el trabajo realizado después de C2a. `docs/current/PROJECT_STATE.md` y `docs/current/NEXT_STEPS.md` conservaron el estado operativo durante las microtranches; esta sección incorpora ahora las decisiones, incidentes, SHAs y resultados que deben sobrevivir a un cambio de conversación.

### 26.1 Reconciliación de certificaciones anteriores

Los cierres documentales exactos posteriores a las secciones 23–25 fueron:

- C1 `campaign_snapshot` en `TrainerDecisionContext`: HEAD final `850bc5083d5dbc6fae742591efbef56eb80b7be1`, 18/18 workflows SUCCESS;
- C1b transporte sanitizado por `TrainerIntelligenceController`: HEAD final `1dbe88c65206e37ecef9f8bb9cffe1f5eb89615b`, 18/18 SUCCESS, FASE20 77 PASS / 0 FAIL;
- C2a fixtures/invariantes: HEAD final `927c59e7e428ea07999d1fa58978fa7a22889f6e`, 18/18 SUCCESS, Trainer Loadouts 234 PASS / 0 FAIL, PR #100 cerrado sin merge.

`main` permaneció fuera del workstream y no debe moverse automáticamente.

### 26.2 C2b — evidencia intrínseca de capacidades

C2b creó la primera implementación real de `TrainerRosterRoleInference`.

Principio congelado:

`loadout materializado propio -> evidencia estructural auditable`, no `role_id authored -> verdad estratégica`.

`extract_intrinsic_evidence()` conserva, entre otras señales:

- stats materializados;
- potencia física/especial de movimientos ejecutables;
- señal de daño físico y especial;
- bulk físico/especial;
- speed;
- prioridad;
- control;
- setup;
- sustain;
- movimientos runtime incluidos/excluidos/desconocidos.

Gate fail-closed Random Cup V1:

- solo `MoveDefinition.classification == RUNTIME_SUPPORTED` aporta capacidad;
- `PARTIAL_RUNTIME`, `DATA_ONLY`, `UNSUPPORTED` y unknown quedan fuera;
- HP/PP actuales no reescriben identidad intrínseca;
- `TrainerProfile`, `role_id` authored y ruido rival no intervienen.

HEAD final C2b:

`6bceaeda1a1439c9ad690e5c48745c112b74ba2a`

Resultado:

- 18/18 workflows SUCCESS;
- Trainer Loadouts: 261 PASS / 0 FAIL;
- PR #101 cerrado sin merge.

### 26.3 C2c — afinidades funcionales multirole

C2c añadió `infer_role_scores()` con modelo `trainer_roster_role_affinity_v1`.

Los scores `0..10000` son **afinidad funcional intrínseca**, no fuerza total ni valor estratégico.

Roles continuos:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `bulky_physical`;
- `bulky_special`;
- `support`.

Principios:

- un híbrido puede tener varias afinidades altas;
- Speed sin ruta ofensiva no fabrica `fast_attacker`;
- setup propio no se convierte automáticamente en `support`;
- movimientos no ejecutables no inflan roles;
- magnitud absoluta C2b permanece separada de afinidad relativa C2c.

HEAD final C2c:

`9d3c54bb970be160418dec14648c78a90a2f64ad`

Resultado:

- 18/18 SUCCESS;
- Trainer Loadouts: 280 PASS / 0 FAIL;
- PR #102 cerrado sin merge.

### 26.4 C2d — auditoría contra DATA V3 real

Se creó un probe exclusivamente de auditoría, no una política Random Cup:

- nivel 50;
- IV31;
- EV0;
- naturaleza neutral;
- hasta cuatro últimos movimientos `level_up <= 50`;
- solo `RUNTIME_SUPPORTED`.

Cobertura:

- especies totales: 1.025;
- elegibles en la sonda inicial: 1.011;
- la auditoría posterior quedó estabilizada en 1.021 tras la corrección DATA descrita abajo.

Hallazgo original de C2d: los scores continuos eran demasiado anchos para transformarlos directamente en etiquetas discretas.

En la primera medición:

- 569 especies tenían 3+ roles >=7500;
- 289 tenían 4+;
- solo 512 tenían un único máximo;
- 499 empataban entre 2–5 roles en el máximo.

Conclusión congelada:

**afinidad funcional != magnitud absoluta != valor estratégico**.

HEAD final C2d:

`35c689e657816f62b7428d6128ae3cfdc6ce15eb`

Resultado:

- 18/18 SUCCESS;
- Trainer Loadouts: 290 PASS / 0 FAIL;
- PR #103 cerrado sin merge.

### 26.5 C2e-a — auditoría jerárquica de labels

Se probó sin tocar producción la hipótesis de sacar `fast_attacker` del plano de roles primarios porque es un descriptor compuesto `speed ∩ offense`.

Resultado:

- empates de máximo: 499 -> 373;
- primarios únicos: 512 -> 638;
- aun quedaba demasiada ambigüedad;
- `support` colisionaba en el máximo con otro rol en 302 especies;
- 74 de los 638 primarios únicos tenían magnitud absoluta igual o inferior a la mediana de su propia familia.

Consecuencia:

un Pokémon puede tener una función principal clara sin ser fuerte en términos absolutos; C3 debe conservar esa separación.

HEAD final C2e-a:

`00b0369b016b9c0c7b6643203cd49130ccddb166`

Resultado:

- 18/18 SUCCESS;
- Trainer Loadouts: 297 PASS / 0 FAIL;
- PR #104 cerrado sin merge.

### 26.6 C2e-b — auditoría de `support` y bug semántico descubierto en DATA V3

La auditoría de `support` detectó ejemplos ofensivos que aparecían como control máximo. La investigación bajó hasta PokeAPI, adaptador y Battle Core y encontró un bug real fuera de Trainer AI.

Problema:

- el conversor legado decidía el target de `stat_changes` usando el target general del movimiento;
- en movimientos dañinos cuyo coste/debuff pertenece al usuario, como Close Combat/Superpower/Hammer Arm, eso podía convertir un efecto `SELF` en `OPPONENT`;
- `BattleEffectExecutor` ejecuta literalmente `spec.target`, por lo que el error podía alterar el Pokémon equivocado en combate.

La familia canónica afectada era `move-category/7` / `damage-raise`, con 28 movimientos de daño + cambios de stats del usuario.

No se parcheó Trainer AI para ocultarlo.

Corrección canónica principal:

`a2341d4f77f22f54b89916fd8e91ac7b26d2c8d5`

La reparación regeneró DATA desde el snapshot inmutable y añadió regresión end-to-end.

Regresión permanente:

- categoría 7 completa presente;
- 28/28 movimientos con sus `MODIFY_STAT_STAGE` propios sobre `SELF`;
- Close Combat ejecutado realmente contra Battle Core reduce al actor, no al rival.

Checkpoint final de recertificación DATA/Trainer AI posterior a la reparación:

`f198fcc16587c268f6f890f0747602b4283c131d`

Resultado:

- 18/18 workflows SUCCESS;
- DATA V3 domain: 567 PASS / 0 FAIL;
- Spanish/type/runtime: 314 PASS / 0 FAIL;
- catálogo estructural preservado: 1.025 especies, 919 movimientos, 61.102 learnset entries, 554 evoluciones, 0 broken refs/rejected definitions.

La remedición post-fix demostró que el bug DATA era real pero **no era la causa principal de la saturación de support**.

Probe post-fix estable:

- 1.025 especies;
- 1.021 elegibles;
- 4 sin movimientos del probe;
- `support > 0`: 892;
- `support >= 7500`: 444;
- `support == 10000`: 441;
- support máximo único: 103;
- support empatado en el máximo: 338;
- colisión con ofensiva: 201;
- colisión con bulk: 164;
- `support == 10000` coexistiendo con ofensiva >=7500: 354.

### 26.7 C2e-c — probabilidad runtime y precisión

Commits audit test-only principales:

- `30a4949d8fda685935cd190426907a9ecb9cec97`;
- `6b82df60a0d1f39c7dcd08f39a81439d20d3c7a0`.

Trainer Loadouts sobre `6b82df60...`:

**317 PASS / 0 FAIL**.

Hallazgo A — metadata probabilística duplicada:

- Battle Core tira el dado únicamente en nodos `BattleEffectSpec.CHANCE`;
- los hijos no vuelven a tirar su `chance_basis_points`;
- la inferencia antigua multiplicaba `chance_basis_points` en cada nodo;
- ciertos efectos secundarios conservaban la probabilidad tanto en wrapper como hijo.

Consecuencia:

- 284 especies tenían parte de su control infravalorado;
- Moonblast: 900 bp en inferencia antigua frente a 3000 bp de semántica runtime;
- Discharge: 900 -> 3000;
- Rock Slide ya era 3000 -> 3000.

Este defecto reduce control; no explica la saturación por exceso.

Hallazgo B — accuracy no formaba parte del control:

- 312 especies reducían su mejor control al ponderar por precisión base;
- control actual `==10000`: 441;
- proxy accuracy `==10000`: 240;
- 201 máximos caerían por debajo de 10000;
- 30 casos >=7500 caerían por debajo de 7500.

Sentinelas:

- Screech: 10000 on-hit, accuracy 85% -> 8500 por intento;
- Thunder Wave: 10000, 90% -> 9000;
- Dynamic Punch: 10000, 50% -> 5000;
- Rock Slide: 3000 × 90% -> 2700.

No se congeló `chance × accuracy` como fórmula de support; se trató como evidencia de fiabilidad.

### 26.8 C2e-d — forma del control: fiabilidad y breadth separados

Commits test-only principales:

- `cc5297119b24acec2972cdbfb0fbdea1b8ccf8c0`;
- `255cf8db722ca7248bc4a3fd7b648dd8fa8fab07`.

Trainer Loadouts:

**332 PASS / 0 FAIL**.

Sobre 1.021 especies elegibles:

- alguna ruta de control: 867;
- 2+ movimientos de control: 564;
- 2+ efectos/ejes distintos: 506;
- exactamente una ruta de alta fiabilidad >=7500: 346;
- 2+ rutas de alta fiabilidad: 65.

Dentro de los 441 techos `control_signal_bp == 10000`:

- 90 tienen un solo movimiento de control;
- 351 tienen varios;
- 30 no conservan ninguna ruta >=7500 al ponderar CHANCE runtime + accuracy base;
- 346 tienen exactamente una ruta de alta fiabilidad;
- solo 65 tienen dos o más rutas de alta fiabilidad.

La sonda también confirmó que deben distinguirse:

1. varios movimientos que repiten el mismo eje;
2. un único movimiento que afecta varios ejes, como Noble Roar.

Por tanto `move breadth` y `effect breadth` son hechos diferentes.

### 26.9 C2e-e — evidencia de control separada en producción

Objetivo: **añadir información sin recalibrar todavía `support`**.

`TrainerRosterRoleInference.extract_intrinsic_evidence()` conserva ahora en paralelo:

- `control_signal_bp` legado, para compatibilidad temporal;
- `control_best_runtime_effect_bp`;
- `control_reliability_bp`;
- `control_secondary_reliability_bp`;
- `control_move_count`;
- `control_effect_key_count`;
- `control_effect_family_count`;
- `control_dedicated_move_count`;
- `control_damaging_move_count`;
- `control_strongest_stat_drop_stages`;
- `control_breakdown` determinista por movimiento.

La helper por movimiento conserva:

- `move_id`;
- accuracy en bp;
- mejor probabilidad runtime del efecto;
- mejor fiabilidad por intento;
- route count;
- effect keys;
- effect families;
- magnitud de stat drop;
- dedicado vs dañino.

**`infer_role_scores().support` sigue usando el `control_signal_bp` antiguo en esta tranche.**

Esto es deliberado: representación y recalibración son cambios separados.

Incidente CI del primer intento:

- HEAD provisional `80f19095...`;
- Trainer Loadouts: 346 PASS / 3 FAIL;
- los tres fallos pertenecían solo a la evidencia nueva;
- causa exacta: la helper intentaba leer `BattleEffectSpec.stat_key`, pero el contrato real se llama `stat_id`.

No era un fallo del modelo ni una regresión histórica.

Fix exacto:

`bcb7a2036d9750662c14763ab8b1d519e432da47`

Resultado de código/test:

- 18/18 workflows SUCCESS;
- Trainer Loadouts: **349 PASS / 0 FAIL**;
- los 332 checks anteriores siguen verdes;
- 17 checks nuevos prueban chance runtime, accuracy, mejor/segunda fiabilidad, breadth, magnitud, dedicado/dañino, fail-closed y JSON/determinismo;
- las distribuciones real-data anteriores permanecen iguales porque `support` no fue recalibrado.

HEAD documental final de C2e-e:

`de1af3934e20d421848f4289f309d69b50551cb6`

Resultado sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- Trainer Loadouts: **349 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

### 26.10 Estado canónico al cerrar este checkpoint

Cerrado/certificado:

- C1 campaign seam;
- C1b controller transport;
- C2a fixtures;
- C2b evidencia intrínseca;
- C2c afinidades multirole;
- C2d real-data audit;
- C2e-a labels audit;
- reparación DATA V3 `damage-raise`;
- C2e-c probability/accuracy audit;
- C2e-d control-shape audit;
- C2e-e representación separada de evidencia de control.

Todavía **NO** integrar:

- `TrainerTeamAnalyzer` con esta inferencia;
- switching/search con valor de campaña;
- C3 `TrainerRosterStrategicValueEvaluator`;
- FASE34 difficulty/expertise.

`support` de producción **todavía no está recalibrado**.

### 26.11 Siguiente microtranche exacta — comparación de fórmulas de support

Antes de modificar `support` en producción se debe ejecutar una comparación test-only sobre las 1.021 especies elegibles del probe post-fix.

La comparación debe usar las señales C2e-e sin aplastarlas prematuramente y medir como mínimo:

- intensidad/semántica del control;
- mejor fiabilidad por intento;
- segunda fiabilidad;
- breadth por movimientos;
- breadth por efectos/ejes;
- dedicado vs secundario de ataque;
- sustain como eje separado;
- colisiones con roles ofensivos/bulk;
- supports legítimos sentinela frente a falsos techos.

No elegir una fórmula porque simplemente produzca menos `10000`.

La candidata debe ser:

- determinista;
- explicable;
- monotónica en señales razonables;
- compatible con fail-closed runtime;
- discriminativa en DATA V3 real;
- sin convertir un único proc secundario en especialista de support;
- sin borrar a un support real porque su potencia absoluta sea modesta.

Solo después de comparar candidatos se autoriza cambiar `infer_role_scores().support` en una tranche separada.

### 26.12 Recuperación en una conversación nueva

Si esta conversación se llena o se cambia de ventana, recuperar Trainer AI así:

1. leer este `docs/project_book/TRAINER_AI.md`, especialmente sección 26;
2. leer `docs/current/PROJECT_STATE.md` y `docs/current/NEXT_STEPS.md`;
3. verificar en GitHub la rama `audit/trainer-ai-v3-random-cup-redesign-v1` y su HEAD exacto;
4. comprobar PR #105, que sigue siendo PR temporal/auditable y **NO debe mergearse a main** mientras C2e permanezca abierto;
5. verificar que `main` no se haya movido automáticamente;
6. continuar desde **comparación test-only de fórmulas de support**.

La autoridad final de estado externo es GitHub; el cuaderno conserva las decisiones y la continuidad semántica.

---

### 26.13 C2e-f — comparación test-only de fórmulas de `support`

Se completó la comparación exigida antes de recalibrar `infer_role_scores().support`.

La producción **no fue modificada** durante esta tranche. `TrainerRosterRoleInference` sigue devolviendo el `support` legado mientras las fórmulas candidatas viven únicamente en suites de auditoría.

#### Candidatas comparadas

Primer checkpoint test-only:

`a04fee0b415764ae53ca5925eb9559de73e0fe6e`

Se compararon sobre las 1.021 especies elegibles del mismo probe real-data:

- `legacy`;
- `reliability_max`;
- `balanced_evidence`;
- `portfolio_evidence`.

Baseline legado:

- `support >= 7500`: 444;
- `support == 10000`: 441;
- support máximo único: 103;
- colisiones en máximo: 338;
- colisiones con ofensiva: 201;
- colisiones con bulk: 164;
- casos de una sola ruta dedicada fiable `>=7500`: 56.

`reliability_max = max(control_reliability_bp, sustain_signal_bp)`:

- `support >= 7500`: 414;
- `support == 10000`: 240;
- support máximo único: 81;
- colisiones en máximo: 181;
- colisiones con ofensiva: 105;
- colisiones con bulk: 91;
- casos de una sola ruta dedicada fiable `>=7500`: 56.

Conclusión: la fiabilidad por intento corrige una parte material de la saturación sin borrar los 56 casos dedicados fiables.

`balanced_evidence`:

- `support >= 7500`: 408;
- `support == 10000`: 0;
- colisiones en máximo: 0;
- casos dedicados fiables `>=7500`: 56.

**RECHAZADA** como fórmula final. Eliminar todos los `10000` comprime estructuralmente el eje `support` frente a otros roles y produce una mejora aparente de colisiones que no es comparable en la misma escala.

`portfolio_evidence`:

- `support >= 7500`: 323;
- `support == 10000`: 6;
- colisiones en máximo: 5;
- casos dedicados fiables `>=7500`: 31.

**RECHAZADA** por exceso de severidad: pierde 25 de los 56 casos de una sola ruta dedicada fiable que el baseline de fiabilidad conservaba.

Trainer Loadouts en este checkpoint: **379 PASS / 0 FAIL**.

#### Refinamiento aditivo rechazado

Segundo checkpoint test-only:

`0257dbf0ac3b55c93597ab2ce00126f90d44a9db`

Se probó una fórmula que partía de fiabilidad pero sumaba de forma continua:

- segunda fiabilidad;
- breadth por movimientos;
- breadth por efectos;
- breadth por familias;
- proporción dedicada;
- magnitud del stat drop;
- sustain.

Resultado:

- `support >= 7500`: 427;
- `support == 10000`: 360;
- colisiones en máximo: 274;
- colisiones con ofensiva: 160;
- colisiones con bulk: 134;
- casos dedicados fiables `>=7500`: 56.

Trainer Loadouts: **397 PASS / 0 FAIL**.

**RECHAZADA**. La evidencia demuestra que convertir breadth en puntos aditivos vuelve a saturar el eje. Breadth debe conservarse como evidencia estructural y no necesariamente aplastarse en una suma lineal.

#### Candidata seleccionada — `guarded_reliability`

Checkpoint test-only seleccionado:

`b8750b65422726e5f198b9ba8684480c6aff160d`

Principio:

1. la magnitud ordinaria de `support` sigue viniendo de la mejor fiabilidad por intento y de sustain;
2. breadth/redundancia no regalan puntos de forma continua;
3. la evidencia adicional se usa para decidir si un techo exacto de `10000` está justificado.

Regla auditada:

- si `sustain_signal_bp >= 10000` -> `10000`;
- si `control_reliability_bp >= 9000` y `control_secondary_reliability_bp >= 7500` -> `10000`;
- si `control_reliability_bp >= 9000`, `sustain_signal_bp >= 5000` y existe al menos una ruta dedicada -> `10000`;
- en cualquier otro caso:
  `min(max(control_reliability_bp, sustain_signal_bp), 9500)`.

Los umbrales `9000 / 7500 / 5000` y el cap `9500` son una **política de clasificación auditable**, no una constante natural. Se aceptan provisionalmente porque reutilizan escalas ya empleadas por el modelo y su comportamiento real-data es claramente mejor que las alternativas comparadas.

Resultado sobre 1.021 especies elegibles:

- `support > 0`: 892;
- `support >= 7500`: **414**;
- `support >= 9000`: **309**;
- `support == 10000`: **82**;
- support máximo único: **77**;
- colisiones en máximo: **67**;
- colisiones con ofensiva: **33**;
- colisiones con bulk: **36**;
- `support >=7500` coexistiendo con ofensiva alta: 335;
- `support ==10000` coexistiendo con ofensiva alta: 65;
- casos de una sola ruta dedicada fiable `>=7500`: **56/56 preservados**;
- casos `==10000` con una sola ruta de control: 6;
- casos `==10000` con una sola ruta dañina de control: **0**;
- casos `==10000` con múltiples rutas de control: 76;
- casos `==10000` con sustain: 27.

Comparación directa:

- legado: 441 techos / 338 colisiones;
- `reliability_max`: 240 techos / 181 colisiones;
- `guarded_reliability`: **82 techos / 67 colisiones**.

A diferencia de `balanced_evidence`, `guarded_reliability` mantiene especialistas reales en `10000`.
A diferencia de `portfolio_evidence`, conserva los 56 casos dedicados fiables.
A diferencia del refinamiento aditivo, no vuelve a inflar `support` por sumar breadth.

Sentinelas relevantes:

- Abomasnow: mejor fiabilidad 9500 + segunda 8500 -> `10000`;
- Alcremie: control dedicado 10000 + sustain 5000 -> `10000`;
- Amoonguss: 10000 + segunda 9000 + sustain -> `10000`;
- Ampharos: 10000 + segunda 3000, sin sustain -> `9500`;
- Annihilape/Screech: fiabilidad 8500 -> `8500`;
- Araquanid: 10000 + segunda 3000, solo control dañino -> `9500`;
- Arcanine: 10000 + segunda 1000, sin sustain -> `9500`;
- Archaludon/Breaking Swipe: una única ruta dañina 10000 -> `9500`;
- Bellibolt: mejor fiabilidad 5000 -> `5000`.

Certificación del checkpoint `b8750b65422726e5f198b9ba8684480c6aff160d`:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Loadouts: **416 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- `main`: no movido;
- PR #105: temporal, abierto y sin merge.

#### Decisión y siguiente microtranche

**`guarded_reliability` queda SELECCIONADA como candidata para la tranche de producción, pero todavía NO implementada en producción en este checkpoint.**

Siguiente microtranche exacta:

- implementar una helper explícita en `TrainerRosterRoleInference`;
- hacer que `infer_role_scores().support` use la regla `guarded_reliability`;
- conservar `control_signal_bp` legado dentro de la evidencia para compatibilidad/auditoría;
- añadir regresiones unitarias de la nueva regla y regresión real-data;
- demostrar que una única ruta dañina perfecta no alcanza `10000`;
- demostrar que dos rutas fiables o control dedicado + sustain sí pueden justificar `10000`;
- preservar fail-closed, determinismo y JSON;
- no integrar todavía `TrainerTeamAnalyzer`;
- no tocar switching/search con valor de campaña;
- no iniciar C3;
- no iniciar FASE34.

La implementación de producción debe ser una tranche separada de esta comparación.

---

### 26.14 C2e-g — `guarded_reliability` en producción

La tranche separada de producción autorizada al cerrar C2e-f queda **IMPLEMENTADA Y CERTIFICADA**.

#### Implementación

Commit de producción generado por la tranche:

`fa9f415ac5c840ea2eba40d2056ebc4c05766974`

`TrainerRosterRoleInference` incorpora ahora:

- `SUPPORT_MODEL_ID = trainer_roster_support_guarded_reliability_v1`;
- umbral de alta fiabilidad `7500`;
- umbral de fiabilidad muy alta `9000`;
- corroboración de sustain `5000`;
- cap de especialista no corroborado `9500`;
- helper explícita `_support_score_from_capabilities()`.

`infer_role_scores().support` deja de usar directamente el máximo legado entre `control_signal_bp` y sustain y pasa a ejecutar la política `guarded_reliability` seleccionada en C2e-f.

Regla de producción:

- `sustain_signal_bp >= 10000` -> `10000`;
- `control_reliability_bp >= 9000` + `control_secondary_reliability_bp >= 7500` -> `10000`;
- `control_reliability_bp >= 9000` + `sustain_signal_bp >= 5000` + al menos una ruta dedicada -> `10000`;
- resto:
  `min(max(control_reliability_bp, sustain_signal_bp), 9500)`.

La salida de role inference expone además `support_model_id` para hacer auditable la política que produjo el score.

La señal histórica `control_signal_bp` **se conserva intacta dentro de `intrinsic_evidence`**. No se ha borrado ni reutilizado retroactivamente: continúa disponible para auditoría/compatibilidad mientras el score de `support` usa la nueva política.

#### Diff neto de la tranche

Entre el checkpoint documental anterior:

`dd5aeab760cf3f32c1f5b04dfc02b9c467b37907`

y el commit de producción `fa9f415ac5c840ea2eba40d2056ebc4c05766974`, el diff neto queda limitado exactamente a cinco archivos:

- `modules/trainer_ai/trainer_roster_role_inference.gd`;
- `tests/trainer_ai/trainer_loadouts_test_runner.gd`;
- `tests/trainer_ai/trainer_roster_control_evidence_test_suite.gd`;
- `tests/trainer_ai/trainer_roster_support_guarded_reliability_test_suite.gd`;
- `tests/trainer_ai/trainer_roster_support_production_test_suite.gd`.

El workflow temporal usado para aplicar la tranche se autolimpió y **no permanece en el árbol final**.

No se modificaron:

- `TrainerTeamAnalyzer`;
- switching;
- search;
- C3;
- FASE34.

#### Regresiones de producción

La nueva `TrainerRosterSupportProductionTestSuite` demuestra explícitamente:

- una única ruta dañina perfecta tiene fiabilidad `10000` pero `support = 9500`;
- una única ruta dedicada perfecta permanece alta pero no alcanza automáticamente el techo;
- dos rutas fiables pueden justificar `10000`;
- control dedicado + sustain suficiente puede justificar `10000`;
- accuracy reduce el score cuando corresponde;
- sustain-only se conserva;
- control `DATA_ONLY` falla cerrado y no genera `support`;
- `support_model_id` queda registrado;
- determinismo;
- serialización JSON.

La regresión histórica C2e-e que exigía que `support` todavía no se recalibrase fue sustituida deliberadamente por el nuevo contrato. A la vez se mantiene una comprobación separada de que `control_signal_bp` legado no ha cambiado.

#### Regresión DATA V3 real

La suite `TrainerRosterSupportGuardedReliabilityTestSuite` compara ahora la producción contra la fórmula candidata auditada sobre las 1.021 especies elegibles y exige:

`production_guarded_mismatch_count == 0`.

Resultado certificado:

- especies totales: 1.025;
- elegibles en probe: 1.021;
- sin probe moves: 4;
- `support > 0`: **892**;
- `support >= 7500`: **414**;
- `support >= 9000`: **309**;
- `support == 10000`: **82**;
- support máximo único: **77**;
- colisiones en máximo: **67**;
- colisiones con ofensiva: **33**;
- colisiones con bulk: **36**;
- una sola ruta dedicada fiable `>=7500`: **56/56 preservados**;
- techos con una única ruta dañina de control: **0**;
- mismatch producción vs fórmula seleccionada: **0**.

Sentinelas de producción:

- Abomasnow -> `10000`;
- Alcremie -> `10000`;
- Amoonguss -> `10000`;
- Ampharos -> `9500`;
- Annihilape -> `8500`;
- Araquanid -> `9500`;
- Arcanine -> `9500`;
- Archaludon -> `9500`;
- Bellibolt -> `5000`.

#### Certificación exacta

Como `fa9f415ac5c840ea2eba40d2056ebc4c05766974` fue creado por `github-actions[bot]`, se creó un commit de certificación con **el mismo árbol exacto y cero cambios de archivos**:

`46c6841dab1ea425476b8c3aaec78f5665bd7ba2`

Resultado sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Loadouts: **436 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- `production_guarded_mismatch_count`: **0**;
- PR #105: abierto, temporal y sin merge;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, no movido.

Por tanto, **C2e-g queda CERTIFICADO** y `guarded_reliability` deja de ser una candidata test-only: es ya la política de producción de `infer_role_scores().support`.

#### Estado C2 después de C2e-g

Cerrado/certificado:

- C2a — fixtures;
- C2b — evidencia intrínseca;
- C2c — afinidades multirole;
- C2d — auditoría real-data;
- C2e-a — calibración de labels;
- reparación DATA V3 `damage-raise`;
- C2e-c — probability/accuracy audit;
- C2e-d — control shape;
- C2e-e — evidencia de control separada;
- C2e-f — comparación y selección de fórmula;
- C2e-g — recalibración de `support` en producción.

La inferencia de roles queda suficientemente estable para pasar al **consumidor siguiente definido en la sección 22.7**, manteniendo la separación de responsabilidades.

#### Siguiente tranche autorizada

Siguiente bloque:

**C2f — adaptación separada de `TrainerTeamAnalyzer` para consumir `TrainerRosterRoleInference` en flujo Random Cup.**

Alcance recomendado:

- auditar primero cómo consume hoy `role_id` authored;
- conservar el flujo histórico authored cuando corresponda;
- introducir una ruta Random Cup que consuma `role_scores_bp`/evidencia inferida en vez de fingir roles authored;
- evitar duplicar fórmulas de daño/bulk/support dentro de `TrainerTeamAnalyzer`;
- mantener la inferencia como única fuente de verdad de capacidades/roles intrínsecos;
- añadir fixtures donde el mismo roster recibe interpretación dinámica sin depender de especialización fija por tipo;
- certificar la integración en una tranche aislada antes de C3.

Todavía **NO**:

- integrar switching/search con valor de campaña;
- iniciar `TrainerRosterStrategicValueEvaluator` C3;
- iniciar FASE34;
- convertir `TrainerTeamComposer` en selector de especies Random Cup;
- mergear PR #105 a `main`.

La autoridad externa de estado sigue siendo GitHub y este cuaderno conserva la continuidad semántica.

---

### 26.15 C2f — `TrainerTeamAnalyzer` consume inferencia en Random Cup

C2f queda **IMPLEMENTADO Y CERTIFICADO** como tranche aislada posterior a la estabilización de `TrainerRosterRoleInference`.

#### Problema auditado

El `TrainerTeamAnalyzer` histórico contaba directamente `TrainerPokemonLoadout.role_id` y su `synergy_score` premiaba, entre otras cosas:

- diversidad de roles authored;
- presencia authored de `support`;
- presencia authored de `fast_attacker`;
- combinación authored de presión física y especial.

Esa semántica sigue siendo válida para equipos históricos/authored y para `TrainerTeamComposer`, pero no puede actuar como autoridad de capacidades en Random Cup.

La auditoría confirmó además que `TrainerTeamComposer` usa `TrainerTeamAnalyzer.analyze()` dentro de su búsqueda greedy. Por tanto, sustituir globalmente la semántica de `analyze()` habría mezclado C2f con la futura retirada/reorientación del Composer y habría roto la separación de responsabilidades congelada en 21.13/22.7.

#### Implementación aislada

SHA de código C2f:

`61b839cb78d15c29c8fa5a8fe62eadda2118be90`

El diff neto desde el checkpoint documental certificado anterior `ba97648cec7777aa747c2c4a95fd0836617a3e57` queda limitado a tres archivos:

- `modules/trainer_ai/trainer_team_analyzer.gd`;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`;
- `tests/trainer_ai/trainer_team_random_cup_analysis_test_suite.gd`.

`TrainerTeamComposer` **NO fue modificado**.

`TrainerTeamAnalyzer` conserva:

`analyze(team)`

con la semántica authored histórica.

Se añade explícitamente:

`analyze_random_cup(team)`

con modelo:

`trainer_team_analysis_random_cup_v1`.

La ruta Random Cup:

1. materializa cada `TrainerPokemonLoadout` mediante `TrainerLoadoutFactory`;
2. convierte el `CreatureInstance` materializado a la frontera `Dictionary`;
3. llama a `TrainerRosterRoleInference.infer_role_scores()`;
4. no replica fórmulas de daño, bulk ni support dentro del Analyzer;
5. agrega el vector multirole completo en vez de reducir cada miembro a una etiqueta exclusiva.

#### Agregación Random Cup

Roles inferidos agregados:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `bulky_physical`;
- `bulky_special`;
- `support`.

`balanced` **no se trata como capacidad**.

Se conserva como señal continua:

- `role_score_sums_bp`;
- `role_max_scores_bp`;
- `member_role_inference`.

Se usa el umbral ya calibrado de:

`STRONG_ROLE_BP = 7500`

únicamente para resumir **presencia fuerte**, no para borrar secundarios.

El resultado expone:

- `role_counts` de presencia fuerte;
- `absent_strong_roles`;
- `unique_strong_roles`;
- `redundant_strong_roles`;
- `inferred_member_count`;
- `uninferred_member_indices`;
- breakdown por miembro con `role_scores_bp`, `role_model_id` y `support_model_id`.

El `synergy_score` Random Cup reutiliza los componentes no relacionados con roles del Analyzer histórico —tipos, cobertura, debilidades/resistencias y redundancia de tipado— y reemplaza solo la contribución authored de roles por la contribución derivada de presencia fuerte inferida.

#### Compatibilidad demostrada

La nueva suite `TrainerTeamRandomCupAnalysisTestSuite` hereda `TrainerTeamCompositionTestSuite` y ejecuta primero todas las regresiones históricas de FASE33.

Regresiones C2f añadidas:

- modelo Random Cup registrado;
- modelo authored preservado;
- todos los miembros válidos inferidos;
- análisis no muta el equipo;
- threshold fuerte = `7500`;
- sumas/máximos/counts agregados coinciden con el breakdown de miembros;
- absent/unique/redundant forman una partición completa de roles;
- `balanced` no se promociona a capacidad;
- la ruta authored sigue reaccionando a `role_id`;
- la ruta Random Cup ignora cambios de `role_id` cuando stats/moveset reales no cambian;
- cambiar el moveset real sí cambia la inferencia;
- determinismo;
- serialización JSON;
- input nulo falla cerrado.

Prueba adversarial clave:

- mismo roster y mismos loadouts objetivos;
- todos los `role_id` se relabelan a `balanced`;
- `analyze()` histórico cambia su lectura de roles;
- `analyze_random_cup()` produce exactamente el mismo resultado que antes.

Esto demuestra que Random Cup ya no depende de la etiqueta authored.

Prueba de causalidad objetiva:

- se cambia realmente el moveset del primer miembro a una ruta especial;
- su `physical_attacker` inferido cae a `0`;
- aparece señal `special_attacker`;
- el análisis Random Cup cambia.

#### Certificación exacta

Sobre el SHA:

`61b839cb78d15c29c8fa5a8fe62eadda2118be90`

resultado confirmado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition / FASE33: **269 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Trainer Loadouts: SUCCESS;
- switching/search y demás gates históricos: SUCCESS;
- PR #105: abierto y sin merge;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, no movido.

Por tanto, **C2f queda CERTIFICADO**.

#### Estado de arquitectura tras C2f

Cerrado/certificado:

- C1 campaign seam;
- C1b controller transport;
- C2a fixtures;
- C2b evidencia intrínseca;
- C2c scores multirole;
- C2d auditoría real-data;
- C2e calibración de labels/control/support;
- C2f consumo de role inference por `TrainerTeamAnalyzer` en Random Cup.

Todavía **NO**:

- integrar switching/search con valor persistente;
- iniciar `TrainerRosterStrategicValueEvaluator` sin revisar antes sus dependencias/políticas abiertas;
- iniciar FASE34;
- convertir `TrainerTeamComposer` en selector Random Cup;
- mergear PR #105 a `main`.

#### Siguiente paso

Antes de implementar C3 debe hacerse una **auditoría de entrada de C3** contra el estado real ya cerrado:

- recuperar el contrato de `TrainerRosterStrategicValueEvaluator`;
- separar qué parte de `structural_value_bp` ya puede implementarse con C2f;
- identificar qué parte de `permadeath_loss_cost_bp` continúa bloqueada por `replacement_policy`, recuperación persistente u otras reglas de gameplay aún abiertas;
- revisar si existe ya algún `TrainerTeamStrategicEvaluator` histórico reutilizable o si su semántica pertenece a otro problema;
- no tocar switching/search hasta tener esa frontera documentada y testeable.

La siguiente tranche, por tanto, es **auditoría C3 previa a código**, no implementación automática de loss-cost con defaults inventados.
