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