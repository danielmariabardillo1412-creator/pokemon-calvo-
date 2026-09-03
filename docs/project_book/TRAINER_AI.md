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

---

### 26.16 C3a — evidencia estructural de valor de roster, antes del scalar

C3 entra en producción mediante una microtranche deliberadamente más pequeña que el evaluador estratégico completo. El objetivo de C3a es construir una **capa de evidencia estructural auditable** y demostrar sus invariantes antes de congelar pesos para `structural_value_bp`.

#### Motivo de la separación

El diseño de las secciones 20 y 22 exige distinguir:

- `structural_value_bp`;
- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`.

Además, `permadeath_loss_cost_bp` completo sigue bloqueado por reglas de campaña todavía no cerradas, especialmente:

- `replacement_policy`;
- `between_battle_recovery_policy`.

Por tanto C3a **no inventa defaults de gameplay** ni publica todavía ninguno de esos tres scalars. Primero estabiliza los hechos que una futura fórmula podrá consumir.

#### Frontera de entrada auditada

La auditoría previa confirmó que `TrainerObservation.own_party` contiene vistas propias generadas como:

`CreatureInstance.to_dict().duplicate(true)`.

Por tanto la nueva capa puede consumir directamente `own_party` y reutilizar `TrainerRosterRoleInference` sobre el mismo `Dictionary` seguro, sin:

- recibir `BattleState`;
- recibir `CreatureInstance` vivo;
- rematerializar loadouts;
- consultar `TrainerPokemonLoadout.role_id` authored;
- duplicar fórmulas de role inference.

#### Implementación

SHA C3a de código:

`b88d142410cbb71b32f127f62ba153e70c7debcb`

Nueva clase:

`TrainerRosterStrategicValueEvaluator`

Modelo de evidencia:

`trainer_roster_structural_evidence_v1`

API C3a:

`extract_structural_evidence(own_party: Array) -> Dictionary`

El nombre de la clase corresponde al evaluador C3 diseñado, pero en esta tranche la API expuesta se limita deliberadamente a **evidencia estructural**. No existe aún una API que finja devolver valor estratégico final.

#### Evidencia por miembro superviviente

Para cada miembro propio válido y no KO se registra:

- `instance_id`;
- `species_id`;
- `role_model_id`;
- `support_model_id`;
- `role_scores_bp` completos;
- máximo y suma de afinidades de rol;
- roles fuertes con umbral `7500`;
- cantidad de movimientos `RUNTIME_SUPPORTED`;
- cantidad de movimientos dañinos `RUNTIME_SUPPORTED`;
- tipos rivales que sus movimientos dañinos pueden cubrir super-efectivamente;
- tipos de ataque que su tipado resiste;
- inmunidades estructurales de tipado.

Después, respecto al resto de supervivientes, se separan:

- roles fuertes únicos vs redundantes;
- cobertura ofensiva única vs redundante;
- resistencias únicas vs redundantes;
- inmunidades únicas vs redundantes.

La evidencia de roles se obtiene mediante `TrainerRosterRoleInference`; C3a no vuelve a calcular daño, bulk o support por su cuenta.

#### Política runtime y fail-closed

La cobertura ofensiva solo cuenta movimientos que cumplen simultáneamente:

- definición conocida;
- `classification == RUNTIME_SUPPORTED`;
- `power > 0`.

`PARTIAL_RUNTIME`, `DATA_ONLY`, `UNSUPPORTED` y movimientos desconocidos no pueden inflar cobertura estratégica.

La capa también falla cerrada ante catálogo ausente, miembro no-`Dictionary`, `instance_id` inválido o especie desconocida.

#### Semántica de supervivencia

C3a distingue expresamente estado operativo y existencia estructural:

- un miembro a **1 HP pero vivo** conserva la misma evidencia estructural que a HP completo;
- un miembro con `current_hp <= 0` / KO deja de contar entre los supervivientes;
- al desaparecer un miembro, la unicidad/redundancia de los restantes se recalcula.

Esto preserva el contrato de C3: estar herido no convierte una pieza valiosa en estructuralmente prescindible, mientras que una baja permanente sí cambia la composición disponible.

`operational_readiness_bp` se implementará/calibrará en una tranche separada y no contamina esta evidencia.

#### Información deliberadamente fuera de C3a

`extract_structural_evidence()` no lee:

- `TrainerProfile`;
- `observed_opponents`;
- beliefs;
- memoria rival;
- RNG/seed;
- `campaign_snapshot`;
- bracket ni rivales futuros.

La ausencia de `campaign_snapshot` es deliberada en C3a: la evidencia estructural objetiva del roster no necesita políticas persistentes. Esas políticas entrarán más adelante al convertir hechos estructurales en coste de campaña.

El `TrainerTeamStrategicEvaluator` histórico FASE21 tampoco se reutiliza: continúa siendo una capa battle-scoped de preservación frente a amenazas rivales ya observadas.

#### Diff neto C3a

Desde el checkpoint documental C2f:

`f9e0dccc4c9cf4562c2f0bc248d1e326de26293a`

hasta el SHA C3a:

`b88d142410cbb71b32f127f62ba153e70c7debcb`

el diff neto está limitado exactamente a tres archivos:

- `modules/trainer_ai/trainer_roster_strategic_value_evaluator.gd` — nuevo;
- `tests/trainer_ai/trainer_roster_structural_evidence_test_suite.gd` — nuevo;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd` — runner ampliado.

No se modificaron:

- `TrainerTeamAnalyzer`;
- `TrainerTeamComposer`;
- `TrainerRosterRoleInference`;
- `TrainerTeamStrategicEvaluator`;
- switching;
- search;
- DATA V3;
- FASE34.

#### Regresiones C3a

La nueva `TrainerRosterStructuralEvidenceTestSuite` hereda la cadena completa de Team Composition/C2f y añade 17 comprobaciones específicas.

Demuestra, entre otras cosas:

- modelo de evidencia registrado;
- conteo correcto de supervivientes;
- reutilización del umbral de rol fuerte `7500`;
- rol físico redundante cuando dos supervivientes lo cubren;
- rol especial único cuando solo uno lo cubre;
- unicidad recalculada después de eliminar otro miembro;
- bajar a 1 HP no reescribe estructura;
- KO elimina al miembro del conjunto superviviente;
- cobertura ofensiva única identificada;
- inmunidad estructural única identificada;
- duplicar esa inmunidad la convierte en redundante;
- misma especie con moveset distinto produce evidencia de rol distinta;
- movimiento `DATA_ONLY` no aporta ruta ofensiva ni rol;
- determinismo;
- JSON serializable;
- ausencia deliberada de los tres scalars finales;
- catálogo nulo falla cerrado.

Resultado FASE33 sobre el SHA C3a:

**286 PASS / 0 FAIL**.

#### Certificación técnica

Sobre `b88d142410cbb71b32f127f62ba153e70c7debcb`:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: **286 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- PR #105: abierto y sin merge;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, no movido.

Por tanto, **C3a queda técnicamente CERTIFICADO** como capa de hechos estructurales previa a la función de valor.

#### Siguiente microtranche autorizada

Siguiente bloque exacto:

**C3b — auditoría real-data de la evidencia estructural antes de congelar `structural_value_bp`.**

La auditoría deberá medir sobre rosters/materializaciones representativas, como mínimo:

- distribución de roles fuertes por miembro y por roster;
- frecuencia de roles únicos y redundantes;
- amplitud y unicidad de cobertura ofensiva;
- amplitud y unicidad de resistencias/inmunidades;
- correlaciones fuertes entre señales para evitar contar dos veces el mismo hecho;
- comportamiento al retirar miembros y recalcular contribución marginal;
- sentinelas de piezas objetivamente fuertes pero redundantes;
- sentinelas moderados pero estructuralmente únicos;
- especies/loadouts con evidencia casi vacía para comprobar fail-closed y escala baja.

C3b debe ser primero **test/audit-only**. No debe seleccionar una fórmula solo porque produzca una distribución bonita.

Todavía NO:

- congelar pesos de `structural_value_bp` por intuición;
- implementar `operational_readiness_bp` como sustituto del valor estructural;
- implementar `permadeath_loss_cost_bp` definitivo;
- inventar `replacement_policy` o `between_battle_recovery_policy`;
- integrar switching/search con campaña;
- iniciar FASE34;
- reescribir `TrainerTeamComposer`;
- mergear PR #105 a `main`.

La autoridad externa de estado sigue siendo GitHub y este cuaderno conserva la continuidad semántica de C3.

---

### 26.17 C3b — auditoría real-data de evidencia estructural

C3b queda **AUDITADO Y TÉCNICAMENTE CERTIFICADO** como tranche exclusivamente de tests/análisis sobre la evidencia C3a. No se modifica producción y no se congela todavía `structural_value_bp`.

#### Objetivo

Antes de convertir la evidencia estructural en una cifra era necesario responder con DATA V3 real:

- cuánto de la función de un miembro es fuerte pero redundante;
- cuánto valor marginal aparece por cobertura/defensa única;
- si la fuerza absoluta y la unicidad son realmente la misma señal;
- cuánto cambia la contribución marginal al retirar un compañero;
- si resistencias e inmunidades pueden sumarse directamente;
- si existen miembros relativamente modestos pero únicos;
- si existen casos de señal baja y además completamente redundante.

#### SHA C3b

`45f51df9306bf955e28b736d681b90add626a1d3`

Desde el baseline documental C3a:

`ada027e5d4195075d4a3cd32c2747083c22831e5`

el diff neto C3b queda limitado a **tres archivos de tests**:

- `tests/trainer_ai/trainer_roster_structural_real_data_audit_test_suite.gd`;
- `tests/trainer_ai/trainer_roster_structural_overlap_real_data_audit_test_suite.gd`;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`.

No se modificó ningún archivo de producción.

#### Probe real-data

Se reutiliza el contrato ya probado en C2:

`runtime_levelup_l50_neutral_probe_v1`

Para cada especie:

- nivel 50;
- IV 31;
- EV 0;
- naturaleza neutral;
- últimos cuatro movimientos level-up disponibles hasta nivel 50;
- únicamente movimientos `RUNTIME_SUPPORTED`.

DATA V3 contiene:

- especies totales: 1.025;
- especies elegibles con probe: **1.021**;
- especies sin probe moves: 4.

#### Construcción de rosters sin fingir todavía el generador Random Cup final

C3b evita tanto el orden Pokédex simple como RNG artificial.

Se utilizan dos schedules cíclicos deterministas de tamaño 6 sobre las 1.021 especies elegibles:

- stride `173`;
- stride `389`.

Cada especie actúa como anchor una vez por schedule y aparece exactamente seis veces por schedule.

Resultado:

- rosters auditados: **2.042**;
- apariciones de miembros: **12.252**;
- todas las plantillas tienen seis miembros;
- determinismo exacto al repetir el informe.

La metodología no pretende representar probabilidades finales del Random Cup. Su objetivo es mezclar cada especie contra dos vecindarios deterministas diferentes y observar cómo cambia su contribución relativa.

#### Resultados — roles fuertes

Apariciones con al menos un rol fuerte único:

**1.560 / 12.252**.

Apariciones con al menos un rol fuerte redundante:

**11.935 / 12.252**.

Histograma de roles fuertes únicos por aparición:

- 0 -> 10.692;
- 1 -> 1.457;
- 2 -> 98;
- 3 -> 4;
- 4 -> 1.

Histograma de roles fuertes redundantes:

- 0 -> 317;
- 1 -> 1.811;
- 2 -> 3.718;
- 3 -> 3.423;
- 4 -> 2.036;
- 5 -> 883;
- 6 -> 64.

Conclusión: **tener un rol fuerte no implica que ese rol sea escaso dentro del roster**. La redundancia de roles es la situación dominante.

#### Fuerza absoluta vs contribución única

Histograma del máximo role score por decil:

- 5000–5999 -> 24;
- 6000–6999 -> 72;
- 7000–7999 -> 348;
- 8000–8999 -> 816;
- 9000–9999 -> 1.464;
- 10000 -> 9.528 apariciones.

Esto confirma que el máximo role score por sí solo es una señal muy saturada para valor estratégico.

Correlación de Pearson aproximada entre `role_score_max_bp` y total de unidades estructurales únicas, usando inicialmente la evidencia defensiva C3a cruda:

**624 bp ≈ 0,0624**.

Después de separar correctamente resistencia no inmune e inmunidad:

**540 bp ≈ 0,0540**.

Por tanto la fuerza absoluta y la contribución marginal son casi ortogonales en este muestreo.

#### Cobertura ofensiva

Apariciones con cobertura ofensiva única:

**6.439 / 12.252**.

Histograma de tipos cubiertos de forma única:

- 0 -> 5.813;
- 1 -> 3.355;
- 2 -> 1.858;
- 3 -> 793;
- 4 -> 294;
- 5 -> 94;
- 6 -> 35;
- 7 -> 10.

La cobertura ofensiva única aparece con mucha más frecuencia que un rol fuerte único y, por tanto, aporta información estructural distinta.

Correlación `unique_role` vs `unique_offense`:

**145 bp ≈ 0,0145**.

Conclusión: contar solo roles fuertes perdería una gran parte de la contribución marginal real del roster.

#### Hallazgo crítico — resistencia e inmunidad NO son campos aditivos independientes

C3a registra:

- `resisted_attack_type_ids` cuando el multiplicador es `< 1`;
- `immune_attack_type_ids` cuando el multiplicador es `0`.

Por definición, una inmunidad también aparece en la familia cruda de resistencias.

C3b añadió un segundo audit que deriva, sin cambiar producción:

**resistencia exclusiva = resistencia no inmune**

más inmunidad como familia separada.

Sobre 12.252 apariciones:

- evidencia defensiva cruda y disjunta difieren en **3.376 casos (27,6%)**;
- crudo sobrecuenta unidades únicas en **1.680** apariciones;
- crudo infracuenta unidades únicas en **1.696** apariciones;
- coinciden en 8.876;
- delta absoluto acumulado: **3.628 unidades**;
- delta neto crudo−disjunto: solo **−56**.

El neto casi cero es engañoso: sobreconteos e infraconteos se cancelan estadísticamente aunque el error semántico individual sea grande.

Ejemplo de sobreconteo:

- una inmunidad única puede aparecer simultáneamente como `unique_resistance` + `unique_immunity`.

Ejemplo de infraconteo:

- miembro A es inmune a un tipo;
- miembro B lo resiste sin ser inmune;
- el conteo crudo de “resistencia” los considera redundantes;
- al separar familias, B puede ser el único resistor no inmune mientras A conserva la inmunidad única.

Por tanto una futura fórmula **NO puede sumar directamente `unique_resistance` + `unique_immunity` de C3a**.

Debe operar sobre familias disjuntas o normalizar el solapamiento antes de puntuar.

#### Defensa disjunta

Apariciones con al menos una resistencia exclusiva única:

**6.708 / 12.252**.

Histograma de resistencias exclusivas únicas:

- 0 -> 5.544;
- 1 -> 3.404;
- 2 -> 1.895;
- 3 -> 822;
- 4 -> 360;
- 5 -> 158;
- 6 -> 54;
- 7 -> 12;
- 8 -> 3.

Correlaciones con defensa disjunta:

- `unique_exclusive_resistance` vs `unique_immunity`: **0,1761**;
- `unique_offense` vs `unique_exclusive_resistance`: **0,2309**;
- `unique_role` vs `unique_exclusive_resistance`: **0,0281**.

Conclusión: cobertura defensiva, cobertura ofensiva y unicidad de rol son señales parcialmente independientes. No deben colapsarse previamente en una sola etiqueta.

#### Contribución marginal tras una baja

Se auditan 24 rosters por schedule y se retira cada uno de sus seis miembros:

- casos de retirada: **288**.

Con la primera evidencia C3a:

- casos donde la baja crea nueva unicidad entre supervivientes: **276 / 288**;
- nuevas unidades únicas acumuladas: 1.120.

Con defensa disjunta:

- casos con nueva unicidad: **276 / 288**;
- nuevas unidades únicas: **1.042**.

Conclusión canónica:

**el valor estructural no puede ser un score fijo de especie/loadout independiente del roster superviviente.**

La misma pieza puede pasar de redundante a crítica después de una baja sin que cambien sus capacidades intrínsecas.

#### Sentinelas — fuerte pero redundante

Se observaron miembros con `role_score_max_bp >= 9000` y ningún rol fuerte único, entre ellos:

- Zygarde;
- Skorupi;
- Nuzleaf;
- Exeggcute;
- Zubat;
- Skitty;
- Numel;
- Iron Valiant.

Esto no significa que carezcan de valor: varios conservan cobertura o inmunidades únicas. Significa que **potencia de rol y escasez de rol deben permanecer separadas**.

#### Sentinelas — moderado pero estructuralmente único

Con `role_score_max_bp` entre 5000 y 7499 aparecen ejemplos con contribuciones únicas:

- Ninjask — cobertura Psychic;
- Elekid — cobertura Flying y defensa útil según roster;
- Electrode — cobertura Flying/Water;
- Wingull — cobertura Bug;
- Wiglett — cobertura Electric;
- Voltorb — contribución defensiva;
- Brambleghast — cobertura Water;
- Diglett — inmunidad Electric en uno de los contextos muestreados.

Conclusión: un scalar que requiera primero “ser fuerte” antes de reconocer unicidad borraría activos moderados pero estratégicamente irreemplazables.

#### Extremo bajo refinado

El primer predicate de “evidencia casi vacía” era demasiado estricto:

`role_max < 5000 AND 0 damaging runtime moves`

y produjo 0 ejemplos.

C3b no interpreta eso como “todos los Pokémon son valiosos”. El predicate simplemente no discriminaba con el probe actual.

El refinamiento usa:

- ningún rol fuerte (`role_max < 7500`);
- cero unidades estructurales únicas disjuntas en ese roster.

Resultado:

**47 apariciones**.

Ejemplos observados incluyen:

- Diglett;
- Glameow;
- Electrode;
- Darkrai;
- Taillow;
- Keldeo;
- Wiglett;
- Elgyem;
- Swellow;
- Elekid.

El hecho de que algunas especies aparezcan tanto en sentinelas moderados-únicos como en sentinelas bajos-redundantes en otro roster es precisamente la demostración esperada: **la contribución marginal depende de los compañeros**, no solo de la especie.

#### Qué NO debe hacer una futura fórmula

Queda descartado conceptualmente como diseño adecuado:

- usar solo `role_score_max_bp`;
- sumar todos los roles fuertes como si fueran independientes;
- sumar `unique_resistance` + `unique_immunity` crudos;
- usar un valor fijo por especie;
- convertir cada campo único en bonus lineal ilimitado;
- tratar un miembro moderado como prescindible solo por no superar `7500`;
- confundir HP actual con valor estructural.

#### Forma mínima que deberá comparar C3c

La siguiente comparación test-only debe mantener al menos tres conceptos separados:

1. **capacidad absoluta** — qué tan funcional es el miembro por sus capacidades intrínsecas certificadas;
2. **contribución marginal** — qué propiedades útiles son únicas en el roster actual;
3. **redundancia/reemplazabilidad** — cuánto de lo que aporta ya lo cubren otros supervivientes.

La defensa debe entrar mediante señal disjunta:

- resistencia no inmune;
- inmunidad.

No se seleccionará una fórmula porque “la distribución se vea bonita”.

Debe evaluarse con sentinelas fuertes-redundantes, moderados-únicos, bajos-redundantes y cambios después de retirar miembros.

#### Certificación C3b

Sobre:

`45f51df9306bf955e28b736d681b90add626a1d3`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: **318 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- auditoría base y auditoría defensiva disjunta: deterministas y JSON-serializables;
- producción C3a: sin modificaciones;
- `main`: no movido;
- PR #105: abierto y sin merge.

Por tanto **C3b queda TÉCNICAMENTE CERTIFICADO**.

#### Siguiente microtranche autorizada

**C3c — comparación test-only de fórmulas candidatas para `structural_value_bp`.**

Debe:

- consumir exclusivamente la evidencia C3a + normalización defensiva disjunta demostrada por C3b;
- comparar varias familias pequeñas y explicables;
- preservar una base absoluta para que un roster malo no convierta automáticamente a su mejor miembro en élite;
- añadir valor marginal sin permitir que breadth ilimitado sature el score;
- aplicar redundancia como reemplazabilidad, no como castigo que borre capacidad real;
- comprobar monotonicidad razonable;
- recalcular al cambiar el roster;
- comparar distribuciones en los dos schedules C3b;
- inspeccionar sentinelas fuertes-redundantes, moderados-únicos y bajos-redundantes;
- comprobar que la fórmula no depende de HP actual, profile, rival, beliefs o RNG.

C3c sigue siendo **TEST/AUDIT-ONLY**.

Todavía NO:

- modificar producción para devolver `structural_value_bp`;
- implementar `operational_readiness_bp` como sustituto;
- implementar `permadeath_loss_cost_bp` definitivo;
- inventar `replacement_policy`;
- inventar `between_battle_recovery_policy`;
- integrar switching/search con campaña;
- iniciar FASE34;
- mergear PR #105.

La autoridad externa de estado sigue siendo GitHub y este cuaderno conserva la continuidad semántica de C3.
### 26.18 C3c — orden léxico estable, reproducibilidad cerrada y comparación canónica

C3c detectó antes de seleccionar ninguna fórmula una contradicción entre las cifras agregadas de la auditoría defensiva C3b al repetir el mismo árbol con una suite adicional. El incidente se trató como bloqueo de calibración: mientras una auditoría usada para elegir pesos no fuera reproducible entre procesos, no se autorizaba congelar `structural_value_bp`.

#### Diagnóstico A/B y causa raíz

Se aislaron progresivamente como no causales:

- el número de clases globales registradas;
- una subclase vacía de la suite real-data;
- la mera herencia de C3b;
- el inicializador `_disjoint_helper`;
- `class_name` de la suite C3c;
- ejecutar o no ejecutar C3c antes de la auditoría disjunta.

El diagnóstico definitivo ejecutó en runners limpios los árboles exactos:

- C3b documental certificado: `e88a953c6453c373dba4692880bc870eca519876`;
- C3c previo al fix: `e8a06165222c3414dc95639dc270bb273dd1d3ac`.

El script de fingerprint se generó después del import de Godot para no alterar el registro de clases. Reconstruyó `GameData.from_dict()` tres veces dentro del mismo proceso y comparó:

- hash del JSON normalizado de entrada;
- hash de la tabla de tipos;
- orden de especies mediante `Array[StringName].sort()`;
- el mismo conjunto convertido a `String` y ordenado léxicamente;
- evidencia defensiva por especie;
- rosters de los schedules C3b;
- métricas disjuntas resultantes.

Resultado:

- el JSON de entrada permanecía idéntico;
- la tabla de tipos permanecía idéntica;
- los dos SHAs daban los mismos fingerprints al partir de procesos limpios;
- pero reconstrucciones sucesivas del mismo catálogo podían producir órdenes diferentes al ordenar `StringName` directamente;
- el mismo conjunto convertido a `String` y ordenado léxicamente era estable.

Hash léxico estable observado para el conjunto de especies:

`8993c5072020adadf7c79e9013687caff0e71dcf6e0ddca97c96ccccd6e6a68e`

Hash estable de la tabla de tipos:

`4d88ebda2100d8f67aaa5a90422b58d5634da653edf13273d4a49649078163b3`

Hash estable del JSON normalizado de entrada:

`9819bba7c6f7893994531ae1aedb86d86d293105a0cf5b42509c4f58960aa1ae`

La causa raíz era por tanto **el harness de auditoría**, no la IA de producción: C3b construía los rosters cíclicos a partir de un orden no canónico de `StringName`.

#### Corrección

Los audits C3 pasan ahora por `_lexically_sorted_species_ids()`:

1. convertir cada ID a `String`;
2. ordenar léxicamente;
3. convertir el resultado ordenado a `StringName`.

Se añadió la regresión:

`structural_real_data_species_order_is_lexical`

La suite C3c volvió además a su forma normal:

- `class_name TrainerRosterStructuralFormulaComparisonTestSuite`;
- ejecución directa desde `trainer_team_composition_test_runner.gd`;
- sin workaround de `load()` dinámico;
- sin workflows ni probes diagnósticos en el árbol final.

El scan posterior de `tests/trainer_ai` no encontró otro schedule/muestreo Trainer AI que dependa de ordenar nativamente `StringName`: los otros usos históricos de `all_ids()` recorren la población completa y no definen los ciclos/muestras marginales C3.

#### Consecuencia sobre 26.17

Las cifras numéricas de C3b registradas en 26.17 se conservan como historia del diagnóstico, pero **quedan superseded como baseline cuantitativo**.

No se invalida la conclusión semántica de 26.17:

- potencia absoluta y contribución marginal deben mantenerse separadas;
- resistencia e inmunidad deben tratarse como familias disjuntas;
- la unicidad depende del roster;
- no debe existir valor fijo por especie;
- HP actual no debe contaminar valor estructural.

Lo que cambia es el roster determinista usado para cuantificar esas relaciones.

#### C3b — métricas canónicas con scheduling léxico

Población y muestreo:

- especies totales DATA V3: `1025`;
- especies elegibles: `1021`;
- schedules: `2` (`173`, `389`);
- rosters: `2042`;
- apariciones de miembros: `12252`.

Auditoría estructural base:

- apariciones con rol fuerte único: `1540`;
- apariciones con rol fuerte redundante: `11920`;
- apariciones con cobertura ofensiva única: `6627`;
- apariciones con resistencia o inmunidad única en evidencia cruda: `7614`;
- retirada marginal: `283 / 288` casos crean nueva unicidad;
- nuevas unidades únicas acumuladas tras retirada: `1204`.

Correlaciones, en basis points:

- `role_max` vs unidades únicas totales: `564`;
- cobertura ofensiva única vs resistencia única cruda: `2273`;
- resistencia única cruda vs inmunidad única: `3897`;
- rol único vs cobertura ofensiva única: `-181`;
- rol único vs resistencia única cruda: `-68`.

Los dos schedules son cercanos:

- cobertura ofensiva única: `3308` / `3319`;
- rol único: `767` / `773`.

#### C3b — defensa disjunta canónica

Separando explícitamente:

- resistencia no inmune;
- inmunidad;

se obtiene:

- delta absoluto de unidades defensivas raw vs disjuntas: `3759`;
- apariciones con diferencia semántica defensiva: `3487 / 12252`;
- raw > disjoint: `1824`;
- raw < disjoint: `1663`;
- raw == disjoint: `8765`;
- net raw - disjoint: `107`;
- apariciones con resistencia exclusiva única: `6663`;
- apariciones low-signal sin contribución única: `53`;
- retirada marginal disjunta: `280 / 288` casos crean nueva unicidad;
- nuevas unidades únicas disjuntas tras retirada: `1100`.

Correlaciones disjuntas, en basis points:

- `role_max` vs unidades únicas totales disjuntas: `722`;
- resistencia exclusiva única vs inmunidad única: `2034`;
- cobertura ofensiva única vs resistencia exclusiva única: `2498`;
- rol único vs resistencia exclusiva única: `39`.

La conclusión defensiva se refuerza: la diferencia raw/disjoint no es ruido y debe permanecer fuera de cualquier suma ingenua.

#### C3c — familias comparadas

C3c compara cinco candidatos test-only:

1. `role_max_only`;
2. `naive_unique_units_additive`;
3. `family_presence_blend`;
4. `capped_units_blend`;
5. `guarded_family_bonus`.

Base absoluta común para los blends/contextuales:

`absolute_capacity_bp = round((3 * role_max + role_second) / 4)`

El floor blend usado en esta primera comparación es:

`max(0.80 * absolute, 0.70 * absolute + 0.30 * context)`

La prueba sigue siendo **AUDIT/TEST-ONLY**: estos pesos no son todavía contrato de producción.

#### Candidatos descartados por la auditoría canónica

`role_max_only`:

- media: `9736`;
- techo `10000`: `9528 / 12252`;
- respuesta marginal positiva tras retirada: `0 / 288`.

Se descarta: satura y no responde a la contribución marginal del roster.

`naive_unique_units_additive`:

- media: `9853`;
- techo: `9603`;
- respuesta marginal positiva: `101 / 288`.

Se descarta: la suma lineal de unidades únicas satura casi toda la población y destruye discriminación.

`guarded_family_bonus`:

- media: `9790`;
- techo: `8374`;
- respuesta marginal positiva: `114 / 288`.

Se descarta: aunque acota el bonus, la suma directa sobre una base absoluta ya alta continúa saturando excesivamente.

#### Dos familias supervivientes

`family_presence_blend`:

- media: `8021`;
- mínimo: `4363`;
- techo: `35`;
- `>= 7500`: `10150`;
- `>= 9000`: `1249`;
- strong-role-redundant mean: `8074`;
- moderate-unique mean: `6086`;
- low-signal/no-unique mean: `5379`;
- floor violations: `0`;
- retirada marginal positiva: `201 / 288`;
- casos negativos tras retirada: `0`;
- delta positivo acumulado: `209671`;
- máximo delta positivo: `3921`;
- medias por schedule: `8011` / `8032`.

`capped_units_blend`:

- media: `7800`;
- mínimo: `4363`;
- techo: `7`;
- `>= 7500`: `9533`;
- `>= 9000`: `352`;
- strong-role-redundant mean: `7872`;
- moderate-unique mean: `5683`;
- low-signal/no-unique mean: `5379`;
- floor violations: `0`;
- retirada marginal positiva: `243 / 288`;
- casos negativos tras retirada: `0`;
- delta positivo acumulado: `199201`;
- máximo delta positivo: `2750`;
- medias por schedule: `7793` / `7807`.

Ambos sobreviven esta ronda porque:

- conservan suelo de capacidad absoluta;
- no producen delta marginal negativo al retirar un compañero;
- reconocen nueva unicidad;
- no dan bonus contextual a low-signal/no-unique;
- mantienen la invariancia de 1 HP;
- un KO puede cambiar el contexto de supervivientes;
- limitan la saturación;
- muestran estabilidad entre los dos schedules.

`capped_units_blend` queda **mejor posicionado**, pero todavía no congelado: tiene solo `7` techos frente a `35`, responde en `243` retiradas frente a `201` y distingue cantidad marginal dentro de una familia hasta caps explícitos, sin breadth ilimitado.

#### Reproducibilidad y certificación técnica

El fix y C3c quedaron en el árbol humano exacto:

`7552445cfec68f4fb6ed6d639c17184ed0e44651`

Sobre ese SHA:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition primera ejecución: **338 PASS / 0 FAIL**;
- el mismo job se reruneó deliberadamente sobre el mismo SHA;
- segunda ejecución: **338 PASS / 0 FAIL**;
- los JSON C3b base, C3b disjunto y C3c fueron numéricamente idénticos entre ambas ejecuciones;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- producción C3a: sin modificaciones;
- `main`: no movido;
- PR #105: abierto y sin merge.

Por tanto, el incidente de reproducibilidad queda **CERRADO** y `7552445c...` es el baseline técnico canónico de C3c tras estabilizar el harness.

#### Siguiente microtranche autorizada

Antes de llevar una fórmula a producción, realizar una única ronda test-only de **sensibilidad local alrededor de `capped_units_blend`**.

Objetivo: comprobar que su ventaja no depende de un punto arbitrario demasiado fino de pesos.

La exploración debe ser pequeña y explicable, no una búsqueda masiva de hiperparámetros. Como mínimo debe variar de forma controlada:

- peso de contexto frente a capacidad absoluta alrededor del `30%` actual;
- caps/peso de las cuatro familias marginales sin cambiar su semántica;
- conservar el floor absoluto;
- comparar saturación, respuesta marginal, estabilidad entre schedules y sentinelas.

No se elegirá una variante solo porque maximice una métrica aislada. Debe existir una región estable de comportamiento razonable.

Sigue prohibido en la siguiente microtranche:

- modificar producción para devolver `structural_value_bp`;
- implementar `operational_readiness_bp` como sustituto;
- implementar `permadeath_loss_cost_bp` definitivo;
- inventar `replacement_policy` o `between_battle_recovery_policy`;
- integrar switching/search;
- iniciar FASE34;
- mergear PR #105.

### 26.19 C3c2 — sensibilidad local y selección de `structural_value_bp`

C3c2 somete al candidato mejor posicionado de C3c, `capped_units_blend`, a una vecindad local pequeña antes de autorizar su paso a producción. La intención no es optimizar la distribución contra el dataset, sino comprobar que la decisión no depende de un punto frágil de parámetros.

#### Baseline de código certificado

La suite test-only de sensibilidad quedó certificada sobre el SHA humano tree-identical:

`621c5f6d6cf28bf460ae8b6c10b3d8f1b6e58ef0`

Resultado en ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: **355 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- producción: sin modificaciones en C3c2;
- `main`: sin mover;
- PR #105: abierto y sin merge.

#### Vecindad auditada

Se comparan nueve variantes, producto de:

- peso contextual: `25%`, `30%`, `35%`;
- caps `compact`, `baseline`, `broad`.

Caps por familia:

- `compact`: role `1`, offense `2`, exclusive resistance `2`, immunity `1`;
- `baseline`: role `2`, offense `3`, exclusive resistance `3`, immunity `2`;
- `broad`: role `2`, offense `4`, exclusive resistance `4`, immunity `2`.

Todas conservan el mismo suelo absoluto y la misma separación semántica de defensa demostrada por C3b.

Las nueve variantes cumplen:

- `0` violaciones del suelo absoluto;
- `0` deltas marginales negativos tras retirar un compañero;
- respuesta positiva a cambios legítimos de unicidad;
- ningún bonus contextual para miembros low-signal sin evidencia única;
- determinismo;
- serialización JSON;
- spreads mínimos entre los schedules `173` y `389`.

#### Resultado central

`baseline_w30` reproduce exactamente el `capped_units_blend` de C3c:

- media: `7800`;
- mínimo: `4363`;
- techo `10000`: `7 / 12252`;
- `>= 7500`: `9533`;
- `>= 9000`: `352`;
- strong-role-redundant mean: `7872`;
- moderate-unique mean: `5683`;
- low-signal/no-unique mean: `5379`;
- retirada marginal positiva: `243 / 288`;
- retirada marginal negativa: `0 / 288`;
- delta positivo acumulado: `199201`;
- máximo delta positivo: `2750`;
- medias por schedule: `7793 / 7807`;
- spread entre schedules: `14 bp`.

#### Por qué no mover los parámetros

La vecindad es estable, por lo que no existe señal técnica que justifique retocar el baseline solo para mejorar una cifra agregada.

Los perfiles `compact` reducen fuertemente el extremo alto y también la respuesta marginal: con `compact_w35`, por ejemplo, el máximo cae a `9300` y solo `176 / 288` retiradas producen mejora. Eso comprime contribuciones estructurales legítimas.

Los perfiles `broad` aumentan la amplitud contextual, pero duplican los techos del baseline (`15` frente a `7`) sin corregir ningún fallo semántico observado.

`w25` responde a más retiradas y eleva más población al tramo alto, pero concede mayor influencia relativa al contexto. `w35` reduce progresivamente la respuesta marginal. `w30` queda entre ambos extremos y mantiene el comportamiento ya auditado en C3c.

Por tanto no se selecciona `baseline_w30` porque su histograma “se vea mejor”, sino porque:

1. está en el centro de una región local estable;
2. conserva la capacidad absoluta como suelo real;
3. reconoce contribución marginal sin saturación masiva;
4. no genera deltas negativos por nueva unicidad;
5. mantiene spreads mínimos entre schedules independientes;
6. no requiere una segunda recalibración para resolver ningún sentinel roto.

#### Fórmula seleccionada y congelada para C3d

Se selecciona para el futuro `structural_value_bp` de producción:

**modelo:** `capped_units_blend / baseline_w30`.

Capacidad absoluta:

`absolute_capacity_bp = round((3 * role_max_bp + role_second_bp) / 4)`

Contexto estructural:

- contar únicamente unidades **únicas** del roster actual;
- familias separadas: rol fuerte, cobertura ofensiva, resistencia exclusiva no inmune, inmunidad;
- caps: role `2`, offense `3`, exclusive resistance `3`, immunity `2`;
- normalizar el contexto capado a basis points de forma determinista, exactamente como la candidata C3c/C3c2 certificada.

Blend final:

`structural_value_bp = max(round(0.80 * absolute_capacity_bp), round(0.70 * absolute_capacity_bp + 0.30 * context_bp))`

La implementación de producción deberá portar literalmente esta semántica y demostrar equivalencia contra la fórmula test-only; no se autoriza reinterpretar pesos durante el port.

#### Límites que siguen congelados

Esta selección **solo** congela `structural_value_bp`.

Todavía NO se autoriza:

- fingir un `operational_readiness_bp` definitivo;
- exponer `permadeath_loss_cost_bp` definitivo;
- inventar `replacement_policy`;
- inventar `between_battle_recovery_policy`;
- integrar el valor estructural en switching/search;
- modificar pesos FASE31 por campaña;
- iniciar FASE34;
- mergear PR #105.

#### Siguiente microtranche autorizada

**C3d — portar la fórmula seleccionada a `TrainerRosterStrategicValueEvaluator` y exponer `structural_value_bp` con breakdown auditable.**

C3d debe ser una tranche de producción aislada:

- reutilizar la evidencia C3a, no duplicar role inference ni semántica DATA V3;
- mantener HP actual fuera del scalar estructural salvo para excluir miembros ya KO del roster superviviente;
- mismo miembro a 1 HP y a HP completo → mismo `structural_value_bp`;
- retirar un compañero puede aumentar el valor de supervivientes por nueva unicidad, pero no reducirlo por ese motivo;
- perfil, rival, beliefs y RNG no entran;
- output determinista y JSON-serializable;
- incluir componentes suficientes para auditar `absolute_capacity_bp`, unidades únicas capadas, `context_bp`, suelo y blend;
- mantener ausentes `operational_readiness_bp` y `permadeath_loss_cost_bp` hasta que sus contratos de gameplay estén resueltos.

C3c2 queda por tanto **CERTIFICADO** y `capped_units_blend / baseline_w30` queda **SELECCIONADO** como fórmula estructural para C3d.

### 26.20 C3d — `structural_value_bp` en producción

C3d porta a producción la fórmula estructural seleccionada y certificada en C3c/C3c2 sin ampliar el contrato a readiness, loss-cost ni integración táctica.

#### Certificación de código

SHA humano tree-identical certificado:

`6e80a1813904a1efb29ecc6f34ffc0cf1d9d8131`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: **370 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- PR #105: abierto y `merged=false`;
- `main`: permanece en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

El árbol C3d añade únicamente:

- producción en `modules/trainer_ai/trainer_roster_strategic_value_evaluator.gd`;
- nueva suite `tests/trainer_ai/trainer_roster_structural_value_production_test_suite.gd`;
- runner FASE33 actualizado para ejecutar la suite nueva, que hereda y conserva todas las regresiones C3a.

No queda ningún workflow temporal ni staging auxiliar en el net diff C3d.

#### API de producción

`TrainerRosterStrategicValueEvaluator` conserva `extract_structural_evidence(own_party)` como contrato C3a y añade una capa separada:

`evaluate_structural_value(own_party: Array) -> Dictionary`

La separación es deliberada: el extractor de evidencia no adquiere semántica de campaña ni se convierte en un scalar implícito.

Modelo:

`trainer_roster_structural_value_capped_units_blend_v1`

Fórmula:

`capped_units_blend_baseline_w30_v1`

El resultado top-level expone:

- `model_id`;
- `formula_id`;
- `evidence_model_id`;
- `role_presence_threshold_bp`;
- `member_count`;
- miembros KO omitidos;
- índices inválidos omitidos;
- `member_values`.

Cada miembro superviviente expone:

- `instance_id`;
- `species_id`;
- `structural_value_bp`;
- breakdown determinista y JSON-serializable.

#### Fórmula portada literalmente

Capacidad absoluta:

`absolute_capacity_bp = round((3 * role_max_bp + role_second_bp) / 4)`

Contexto estructural usa exclusivamente contribuciones únicas del roster superviviente y mantiene cuatro familias separadas:

1. rol fuerte único;
2. cobertura ofensiva única;
3. resistencia exclusiva no inmune única;
4. inmunidad única.

Caps de producción:

- role: `2`;
- offense: `3`;
- exclusive resistance: `3`;
- immunity: `2`.

Valor por unidad:

- role: `2500 bp`;
- offense: `1000 bp`;
- exclusive resistance: `1000 bp`;
- immunity: `1500 bp`.

`context_bp` queda limitado a `10000`.

Suelo absoluto:

`absolute_floor_bp = round(0.80 * absolute_capacity_bp)`

Blend:

`blended_score_bp = round(0.70 * absolute_capacity_bp + 0.30 * context_bp)`

Resultado:

`structural_value_bp = max(absolute_floor_bp, blended_score_bp)`

con clamp final `0..10000`.

#### Defensa disjunta ya no es solo auditoría

C3d porta a producción la corrección semántica demostrada por C3b:

- primero se calcula el conjunto de inmunidades;
- `exclusive resistance = resisted - immune`;
- resistencia exclusiva e inmunidad se cuentan y particionan por separado;
- una inmunidad no puede volver a aportar simultáneamente como resistencia.

La regresión `roster_structural_value_defense_is_disjoint` demuestra explícitamente esta frontera.

#### Paridad contra la fórmula certificada

La nueva suite no se limita a comprobar rangos.

Para el fixture de producción calcula de forma independiente:

- evidencia C3a;
- normalización defensiva disjunta C3b;
- métricas C3c;
- `capped_units_blend` test-only certificado.

Después exige igualdad exacta con el `structural_value_bp` de producción.

Regresión:

`roster_structural_value_matches_selected_c3c_formula`

Resultado: **PASS**.

Por tanto el port no reinterpretó pesos, caps ni redondeos durante el paso a producción.

#### Invariantes C3d certificados

FASE33 demuestra además:

- model/formula/evidence IDs correctos;
- solo se cuentan supervivientes;
- no se muta `own_party`;
- breakdown auditable;
- mismo miembro a `1 HP` y HP completo → mismo `structural_value_bp`;
- un KO sale del roster estructural y puede cambiar el contexto de los supervivientes;
- retirar un compañero puede elevar la importancia estructural de otro por nueva unicidad;
- defensa disjunta;
- determinismo;
- JSON serialization;
- null catalog fail-closed.

La suite comprueba expresamente que C3d **no** expone:

- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`.

#### Estado de C3 después de C3d

La parte estructural de C3 queda **IMPLEMENTADA Y CERTIFICADA EN PRODUCCIÓN**.

Ya existe una respuesta estable a:

> ¿qué valor estructural objetivo aporta este superviviente al roster actual, independientemente de su HP operativo presente?

Pero todavía no existe una respuesta completa y canónica a:

> ¿cuánto cuesta perderlo permanentemente en esta campaña concreta?

Ese segundo concepto sigue bloqueado por gameplay, principalmente:

- `replacement_policy`;
- `between_battle_recovery_policy`;
- opcionalmente rondas restantes si la regla pública del modo decide exponerlas.

#### Frontera inmediata — no integrar switching/search todavía

Aunque `structural_value_bp` ya es producción real, **no se integra todavía** en `TrainerStrategicSwitchEvaluatorV2`, `TrainerSearchStateEvaluator` ni otros brains.

Motivo: usar ahora el scalar estructural como sustituto de `permadeath_loss_cost_bp` mezclaría dos conceptos que el diseño separó expresamente. Un activo estructuralmente valioso puede tener distinta urgencia de preservación según reposición, recuperación y estado operativo de campaña.

Por tanto siguen congelados:

- switching/search campaign-value integration;
- `productive_sacrifice_window` con loss-cost persistente;
- valoración desigual de KOs en search por campaña;
- FASE34;
- merge de PR #105.

#### Siguiente bloque autorizado

**C3e — auditoría read-only del contrato de `operational_readiness_bp` y de la frontera con `between_battle_recovery_policy`.**

Objetivo:

1. inventariar exactamente qué señales operativas seguras ya existen en `own_party` (`current_hp`, `max_hp`, status, PP, held item consumido u otras);
2. separar qué puede medirse como readiness **del estado actual** sin conocer reglas entre combates;
3. identificar qué semántica depende necesariamente de `between_battle_recovery_policy`;
4. decidir si puede implementarse un readiness actual separado y honesto o si debe seguir bloqueado;
5. no crear defaults de recuperación ni reposición;
6. no implementar `permadeath_loss_cost_bp` durante esta auditoría;
7. no integrar todavía switching/search.

C3d queda así **CERTIFICADO** y la siguiente acción segura vuelve a ser una auditoría de contrato, no una expansión automática de comportamiento.


### 26.21 C3e — auditoría del contrato de `operational_readiness_bp`

C3e se ejecuta como auditoría read-only de contrato después de certificar C3d. No modifica producción, no introduce un scalar nuevo y no integra campaign-value en switching/search.

#### Baseline certificado

Baseline documental humano:

`ab61ab644439e5a2527ea84ba064d0c6fa05bfa3`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- C3d estructural ya estaba certificado en producción;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Señales operativas ya disponibles de forma segura

`TrainerObservationBuilder` construye `own_party` a partir de `CreatureInstance.to_dict()` y por tanto la IA propia dispone, sin leer `BattleState` ni referencias mutables, de:

- `current_hp`;
- `stats.max_hp`;
- `moveset[].move_id`;
- `moveset[].current_pp`;
- `moveset[].max_pp`;
- `status_state.persistent_id`;
- `status_state.turns_remaining`;
- `status_state.toxic_counter`;
- `status_state.volatile`;
- `stat_stages`;
- `held_item_id`;
- `held_item_consumed`;
- identidad, especie, nivel, stats y moves conocidos del propio roster.

La observación propia es completa; esta evidencia no requiere rival, beliefs, memory, profile ni RNG.

#### Qué persiste realmente al salir de Battle

`CreatureInstance.reconcile_post_battle()` establece una frontera importante:

Persiste/clampa:

- HP actual;
- PP actual;
- status persistente;
- `held_item_consumed` no se resetea en reconciliación.

Se elimina como estado puramente de batalla:

- todos los `stat_stages`;
- todos los status volátiles.

`TrainerBattleSession.settle_finished_battle()` llama a `reconcile_post_battle()` sobre ambos rosters y no aplica ninguna curación adicional de HP, PP o status.

Por tanto el runtime actual demuestra persistencia técnica de esos recursos, pero **NO define una política canónica de Random Cup entre rondas**.

#### `campaign_snapshot` no resuelve todavía recovery/replacement

`TrainerDecisionContext.campaign_snapshot` y `TrainerIntelligenceController.set_campaign_snapshot()` son hoy un seam seguro de transporte por copia profunda.

La regresión existente solo certifica que puede transportar datos como `schema_version`, `round_index` y `own_roster.alive_instance_ids` sin aliasing.

No existe todavía contrato canónico para:

- `between_battle_recovery_policy`;
- `replacement_policy`;
- restauración de PP;
- curación de HP;
- curación de status;
- reposición/reactivación de held items consumidos;
- número público de rondas restantes como entrada obligatoria.

Por tanto C3e no puede inferir esas reglas ni crear defaults.

#### HP — señal directamente utilizable

HP sí admite una medida objetiva de estado actual:

`hp_ratio_bp = current_hp / max_hp`

con clamp `0..10000`.

Para un miembro vivo, reducir HP debe poder reducir readiness actual sin modificar `structural_value_bp`.

Un cambio de HP por sí solo no cambia identidad, rol estructural, cobertura ni unicidad C3d.

#### PP — señal válida, agregación todavía no autorizada

PP actual/máximo por movimiento es estado operativo real y persistente en el runtime actual.

Pero un promedio bruto de PP del moveset sería semánticamente incorrecto:

- agotar un movimiento irrelevante no equivale a agotar la única ruta ofensiva útil;
- un support puede depender de una única ruta dedicada;
- dos moves con el mismo rol pueden aportar redundancia real;
- DATA_ONLY/unknown moves no deben crear readiness ficticio.

C3e autoriza tratar PP como evidencia por movimiento y capacidad, no como media lineal no ponderada.

La siguiente tranche deberá reutilizar clasificación runtime y evidencia de roles ya certificadas, sin duplicar semántica DATA V3.

#### Status persistente — efectos runtime objetivos, impacto dependiente del rol

Los status persistentes tienen semántica runtime concreta bajo `BattleRuleset calvo_v1`:

- burn: multiplicador físico `5000 bp` y daño residual `max_hp / 16`;
- paralysis: Speed `5000 bp` y probabilidad de impedir acción `2500 bp`;
- poison: daño residual `max_hp / 8`;
- badly poisoned: daño creciente mediante `toxic_counter / 16` del max HP;
- sleep: duración persistida en `turns_remaining`, rango base `1..3` al aplicarse;
- freeze: thaw `2000 bp` por intento de acción.

Esto demuestra que status es evidencia operativa real.

Pero una única penalización uniforme por “tener status” sería falsa:

- burn afecta mucho más a una ruta física que a una especial;
- paralysis afecta especialmente a valor basado en velocidad y además a disponibilidad de acción;
- poison/toxic erosionan supervivencia, no directamente la potencia intrínseca del moveset;
- sleep/freeze afectan disponibilidad temporal y su impacto depende del horizonte.

C3e no congela todavía un `status_penalty_bp` agregado.

#### Held item consumido — estado real, valor genérico no demostrado

`held_item_consumed` es observable para el propio roster y el Battle Core deja de disparar triggers del item cuando está consumido.

Además la reconciliación post-battle no lo restaura.

Por tanto “item disponible vs consumido” es evidencia operativa válida del estado actual.

Sin embargo no todos los held items aportan el mismo valor y algunos pueden no ser relevantes para el rol estructural del miembro. C3e no autoriza restar una penalización fija simplemente por `held_item_consumed=true`.

#### Estado transitorio que debe quedar fuera del readiness de campaña

Aunque `own_party` contiene `stat_stages` y status volátiles durante una batalla, C3e los excluye de la futura capa de readiness persistente porque:

- se borran explícitamente en `reconcile_post_battle()`;
- ya pertenecen a evaluación táctica del estado de combate;
- incorporarlos a valor operativo de campaña mezclaría horizonte táctico y persistencia entre combates.

No se prohíbe que los brains tácticos los usen; se prohíbe reutilizarlos como si fueran degradación persistente C3.

#### Conclusión de contrato

**Sí es implementable un `operational_readiness_bp` del estado operativo PRESENTE**, separado y honesto, sin conocer `between_battle_recovery_policy`.

No es todavía implementable de forma honesta:

- readiness proyectado después de la recuperación entre rondas;
- coste permanente de perder el miembro;
- expectativa de reposición;
- valoración de rondas futuras basada en reglas aún inexistentes.

La semántica obligatoria debe distinguir:

1. `structural_value_bp`: valor estructural del superviviente en el roster, ya C3d;
2. current operational readiness: degradación/utilidad del estado persistente actual;
3. post-recovery readiness: transformación futura que solo puede existir cuando haya política de recuperación;
4. `permadeath_loss_cost_bp`: capa posterior que necesita además replacement/campaign rules.

No se permite usar el punto 2 como sustituto de 3 o 4.

#### Siguiente microtranche autorizada — C3f-a

**C3f-a — extracción TEST/AUDIT-ONLY de evidencia operativa actual, todavía sin scalar.**

Debe construir fixtures y/o helper test-only que exponga como mínimo:

- `hp_ratio_bp`;
- por move runtime-supported: `move_id`, `current_pp`, `max_pp`, `pp_ratio_bp`, disponibilidad `current_pp > 0`;
- rutas desconocidas/DATA_ONLY separadas y fail-closed;
- status persistente estructurado con sus parámetros runtime públicos relevantes;
- `held_item_id` + `held_item_consumed` como evidencia, sin penalización genérica;
- exclusión explícita de stat stages y volátiles del contrato persistente;
- determinismo;
- JSON serialization;
- ausencia de rival/belief/profile/RNG/campaign-policy.

Debe además explorar cómo relacionar PP agotado con capacidad real sin usar un promedio bruto de cuatro slots. Es válido comparar representaciones, pero todavía no congelar `operational_readiness_bp`.

Sigue prohibido durante C3f-a:

- modificar C3d `structural_value_bp`;
- exponer un scalar readiness de producción;
- inventar `between_battle_recovery_policy` o `replacement_policy`;
- implementar `permadeath_loss_cost_bp`;
- integrar switching/search campaign-value;
- iniciar FASE34;
- mergear PR #105.


### 26.22 C3f-a — evidencia operativa actual TEST/AUDIT-ONLY

C3f-a ejecuta la autorización de 26.21 sin adelantar el scalar. Su objetivo es demostrar qué degradación operativa presente puede medirse de forma auditable antes de comparar fórmulas de `operational_readiness_bp`.

#### Baseline y certificación

Baseline humano C3e:

`604ff9dfdc564f14a33553b68fe5286ab014db32`

C3f-a técnico:

`78e2d7cf535c45b9bb92c24e0247195fd19d1faf`

C3f-a humano tree-identical certificado:

`8023b1ccc670eeeecb597516b6e5310eebe9de57`

Sobre el SHA humano exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Team Composition: **396 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

El net diff funcional de C3f-a contra C3e es exclusivamente de tests:

- `tests/trainer_ai/trainer_roster_operational_evidence_audit_test_suite.gd` — suite nueva;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd` — una sustitución de runner para heredar C3d y añadir C3f-a.

**No hay cambios de producción.**

#### Modelo de auditoría

La suite introduce únicamente en tests:

`trainer_roster_current_operational_evidence_audit_v1`

No existe todavía un `operational_readiness_bp` de producción ni test-only congelado.

Para cada vista propia, la evidencia conserva:

- `instance_id`;
- `species_id`;
- estado KO actual;
- HP actual, máximo y `hp_ratio_bp`;
- PP por movimiento runtime-supported;
- disponibilidad de cada ruta por `current_pp > 0`;
- movimientos agotados;
- movimientos DATA_ONLY/excluidos;
- movimientos desconocidos;
- afinidad de cada ruta PP con roles sensibles;
- status persistente y parámetros runtime públicos;
- held item presente/consumido/disponible;
- lista explícita de campos transitorios excluidos.

La salida es determinista y JSON-serializable.

#### HP queda como señal directa

C3f-a prueba el ratio presente:

`hp_ratio_bp = current_hp / max_hp`

con clamp seguro.

También prueba KO como estado operativo sin convertirlo en un scalar C3 nuevo.

Esto preserva la separación ya certificada:

- HP puede degradar readiness presente;
- HP no reescribe `structural_value_bp`.

#### PP se conserva por ruta, no como media del moveset

Para cada movimiento runtime-supported se registra:

- `move_id`;
- `current_pp`;
- `max_pp`;
- `pp_ratio_bp`;
- `pp_state_valid`;
- `available`;
- `damage_class`;
- `power`;
- `type_id`.

Un estado PP inválido falla cerrado:

- no se considera disponible;
- `pp_ratio_bp = 0`;
- no crea capacidad ficticia.

Los movimientos desconocidos o no runtime-supported quedan separados y tampoco crean readiness ficticio.

#### Afinidad de rol por ruta PP

C3f-a no inventa una clasificación PP nueva. Para cada movimiento runtime-supported construye una vista de un solo movimiento y reutiliza `TrainerRosterRoleInference` ya certificado.

Se conservan máximos de afinidad para roles donde PP puede cortar capacidad ejecutable:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `support`.

Se calculan dos familias de evidencia:

1. máximo de afinidad disponible en todas las rutas runtime del moveset;
2. máximo de afinidad que todavía conserva al menos una ruta con PP.

La segunda nunca puede superar a la primera: la suite certifica esta monotonicidad.

#### Hallazgo clave — la media de PP colisiona semánticamente

C3f-a construye dos estados del mismo miembro:

A. ruta física agotada + support lleno;

B. ruta física llena + support agotado.

En ambos casos una media bruta del PP de los dos slots da exactamente:

`5000 bp`.

Sin embargo las capacidades disponibles no son equivalentes.

La evidencia route-aware demuestra simultáneamente que:

- A conserva menos afinidad disponible de `physical_attacker` que B;
- A conserva más afinidad disponible de `support` que B.

Por tanto queda demostrado con regresión ejecutable que:

**`mean(current_pp/max_pp)` del moveset NO es una medida válida de readiness operativo.**

No se debe volver a introducir esa simplificación en C3f-b o producción.

#### Status persistente se conserva con semántica runtime, no con penalización genérica

La suite certifica evidencia estructurada para:

- burn: multiplicador físico 5000 bp + divisor residual 16;
- paralysis: Speed 5000 bp + skip 2500 bp;
- poison: divisor residual 8;
- badly poisoned: divisor 16 + `toxic_counter` actual;
- sleep: `turns_remaining`;
- freeze: thaw 2000 bp.

Esto permite a la futura comparación de fórmulas utilizar consecuencias runtime reales.

C3f-a **no** asigna una penalización uniforme por status.

#### Held item queda deliberadamente como evidencia cruda

Se registra:

- `item_id`;
- presencia;
- `consumed`;
- `available`.

Se prueba explícitamente que un item consumido deja de estar disponible.

No se genera `generic_penalty_bp` ni otra equivalencia universal porque C3f-a no ha demostrado que todos los held items tengan un valor comparable.

#### Estados transitorios excluidos

C3f-a excluye expresamente:

- `stat_stages`;
- `status_state.volatile`.

Además prueba que añadir o retirar esos datos transitorios **no cambia la salida de evidencia persistente**.

La razón sigue siendo la frontera de 26.21: `reconcile_post_battle()` los elimina y ya pertenecen al horizonte táctico de Battle.

#### Seguridad semántica

La evidencia C3f-a no contiene ni consume:

- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`;
- `campaign_snapshot` como fuente de política;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- oponente;
- beliefs;
- TrainerProfile;
- RNG.

Por tanto no adelanta reglas de campaña inexistentes.

#### Conclusión C3f-a

C3f-a demuestra que el estado operativo presente tiene cuatro familias conceptualmente distintas:

1. **supervivencia presente** — HP;
2. **capacidad ejecutable restante** — rutas PP todavía disponibles y su afinidad funcional;
3. **degradación persistente con efectos runtime** — status;
4. **recurso equipado persistente** — held item disponible/consumido, todavía sin valor escalar certificado.

No existe evidencia para colapsar las cuatro con una media simple.

Especialmente PP necesita una representación sensible a la ruta/capacidad, no al número de slots.

C3f-a queda **CERTIFICADO** y no modifica la fórmula estructural C3d.

#### Siguiente microtranche autorizada — C3f-b

**C3f-b — comparación TEST/AUDIT-ONLY de fórmulas candidatas para readiness operativo ACTUAL.**

Debe reutilizar la evidencia C3f-a y comparar varias familias pequeñas y explicables antes de seleccionar ninguna.

Como mínimo debe incluir controles que permitan detectar fórmulas defectuosas:

- un control `hp_only`;
- una familia que combine HP con retención route-aware de capacidad PP;
- una o más familias que incorporen status con efectos dependientes del rol/semántica;
- una variante deliberadamente ingenua basada en media PP, solo como foil, para demostrar sus colisiones.

C3f-b debe probar invariantes relacionales, no elegir por una distribución bonita:

- bajar HP no puede aumentar readiness;
- agotar una ruta runtime no puede aumentar readiness;
- restaurar PP no puede reducir readiness;
- una ruta agotada irrelevante debe afectar menos que una ruta que sostiene una capacidad fuerte, cuando la evidencia permita distinguirlo;
- burn debe penalizar más a una configuración física que a una especial comparable;
- paralysis debe reflejar degradación de velocidad/disponibilidad de acción;
- poison/toxic deben afectar supervivencia/attrition sin fingir pérdida estructural;
- sleep/freeze deben modelarse de manera explícita y conservadora, no como una constante universal sin horizonte;
- stat stages y volátiles deben seguir fuera;
- no debe cambiar `structural_value_bp`;
- no debe usar rival, beliefs, profile, RNG ni políticas de recuperación/reemplazo.

Held item seguirá **evidence-only** durante C3f-b salvo que una auditoría separada demuestre una semántica de valor suficiente para incorporarlo.

C3f-b sigue siendo TEST/AUDIT-ONLY: todavía no autoriza exponer `operational_readiness_bp` en producción.

Siguen prohibidos:

- readiness post-recuperación sin política canónica;
- `permadeath_loss_cost_bp` definitivo;
- inventar `between_battle_recovery_policy` o `replacement_policy`;
- integrar campaign-value en switching/search;
- FASE34;
- mergear PR #105.


### 26.23 C3f-b — comparación TEST/AUDIT-ONLY de fórmulas de readiness actual

C3f-b se ejecuta después de C3f-a con una restricción explícita: comparar composiciones posibles de la evidencia operativa ya certificada sin exponer todavía `operational_readiness_bp` en producción.

#### Baseline certificado

Baseline documental humano de C3f-a:

`0b1c858c9bb7b53f2079701ab1c8f650a9ad66e3`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- C3f-a mantenía la evidencia operativa exclusivamente en tests;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Scope ejecutado

Se añadió únicamente una suite test-only:

`tests/trainer_ai/trainer_roster_operational_readiness_formula_comparison_test_suite.gd`

y una sustitución de una línea en:

`tests/trainer_ai/trainer_team_composition_test_runner.gd`

No se modificó ninguna clase de producción.

La comparación usa seis familias deliberadamente distintas:

1. `hp_only`;
2. `naive_mean_pp_blend`;
3. `route_retention_blend`;
4. `route_action_status_blend`;
5. `route_action_status_product`;
6. `active_tick_assumption_product`.

Ninguna de ellas queda seleccionada como fórmula canónica. El reporte conserva explícitamente:

`selected_operational_readiness_formula: null`

#### Controles negativos útiles

`hp_only` confirma que HP por sí solo no puede representar agotamiento de PP ni status.

`naive_mean_pp_blend` confirma el defecto ya descubierto en C3f-a: un promedio bruto de PP no representa la capacidad operativa que realmente sigue disponible.

En DATA V3 real se detectaron **72 casos** en el muestreo donde el promedio naive penaliza al miembro aunque la representación route-aware comprueba que una ruta redundante equivalente conserva la capacidad.

La suma de diferencia `route_retention_blend - naive_mean_pp_blend` sobre esos escenarios de agotamiento fue:

`66,462 bp`

No se interpreta esa suma como métrica de calidad absoluta; demuestra únicamente que ambos modelos no son semánticamente equivalentes.

#### PP route-aware — propiedad confirmada

La familia route-aware compara, por rol sensible a PP, la evidencia de capacidad total con la evidencia que sigue teniendo al menos una ruta runtime-supported disponible.

Esto permite que:

- agotar una ruta irrelevante no destruya otra capacidad;
- agotar una de dos rutas redundantes no cree una pérdida ficticia;
- agotar la única ruta que sustenta una capacidad sí reduzca su retención;
- restaurar PP nunca reduzca readiness;
- DATA_ONLY/unknown continúen fail-closed.

C3f-b refuerza por tanto la conclusión de C3f-a: la unidad correcta para PP no es el slot medio, sino la capacidad operativa conservada.

#### Burn — impacto dependiente del rol confirmado

La comparación usa la semántica runtime certificada de burn y la afinidad física/especial ya disponible.

En el muestreo real determinista:

- casos physical-dominant: **63**;
- penalización media del candidato blend: **1000 bp**;
- casos special-dominant: **50**;
- penalización media: **407 bp**.

Esto confirma que una penalización fija por `burn=true` sería incorrecta. El efecto debe depender de cuánto descansa la capacidad útil del miembro en la ruta física.

#### Paralysis — acción + dependencia de Speed

La capa test-only separa:

- probabilidad de perder acción;
- pérdida de Speed;
- dependencia real del rol `fast_attacker`.

Durante la primera ejecución se descubrió un fallo del propio fixture, no de la fórmula: se construyó `StatBlock` como si el último parámetro fuera Speed.

El contrato real de `StatBlock.new` es:

`max_hp, attack, defense, speed, special_attack, special_defense`

Por tanto los fixtures iniciales rápido/lento tenían ambos `speed=70`; los valores `200/45` habían caído en `special_defense`.

Se corrigió el fixture para colocar `200/45` en Speed y se reforzó la regresión exigiendo primero que la afinidad `fast_attacker` del fixture rápido sea realmente superior antes de comparar la penalización de paralysis.

Con esa corrección, el miembro dependiente de Speed recibe una degradación mayor, como exige la semántica del status.

#### Sleep y freeze

Bajo el contrato de estado actual:

- sleep con `turns_remaining > 0` tiene disponibilidad inmediata de acción `0`;
- freeze usa la probabilidad runtime de thaw como disponibilidad de acción actual.

Esto no pretende valorar un horizonte de varios turnos; únicamente expresa la capacidad de actuar bajo el estado presente.

#### Poison/toxic — separación obligatoria de horizonte

C3f-b confirma una frontera especialmente importante.

Para el scalar de capacidad operativa inmediata:

- poison no reduce por sí mismo la disponibilidad de la acción presente;
- toxic tampoco debe convertirse automáticamente en una pérdida inmediata de acción.

En el muestreo real:

- `poison_immediate_penalty_cases = 0`;
- bajo el candidato explícitamente condicionado a “siguiente tick activo”, `poison_active_tick_penalty_cases = 128/128`.

Por tanto la presión de attrition es real, pero depende de un horizonte. El candidato se llama deliberadamente:

`active_tick_assumption_product`

y reporta:

`attrition_candidate_requires_active_end_turn_assumption: true`

No puede promoverse silenciosamente a readiness canónico mientras no se defina qué horizonte está valorando.

#### Held item continúa fuera del scalar

`held_item_id` y `held_item_consumed` siguen siendo evidencia operativa válida, pero C3f-b no ha demostrado un valor genérico común a todos los items.

Los candidatos producen el mismo score con item disponible o consumido cuando el resto del estado es idéntico.

Esto es intencional. No se autoriza una penalización fija por item consumido.

#### Primer SHA y fallo de auditoría

Primer SHA técnico:

`d4142e896e0cb7695a9fbcd0577eae2535887f95`

Resultado:

- **17/18 workflows SUCCESS**;
- único fallo: Trainer Team Composition;
- FASE33: **421 PASS / 2 FAIL**;
- Godot general: SUCCESS;
- DATA V3: SUCCESS.

Los dos fallos eran de la suite:

1. fixture de paralysis con los argumentos de `StatBlock` en posición incorrecta;
2. la aserción `comparison_remains_test_only` exigía ausencia de la clave `selected_operational_readiness_formula`, aunque el reporte la contenía correctamente con valor `null`.

No se modificó ninguna fórmula candidata para resolver esos fallos.

La corrección fue exclusivamente test-only: **9 adiciones / 5 eliminaciones** en la suite C3f-b.

#### SHA técnico corregido

SHA técnico corregido:

`ad2b8721a7b65d244f43602f68b1a786e67b2f0e`

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **423 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

Reporte real-data determinista:

- `sample_members = 128`;
- `sample_stride = 8`;
- `naive_penalizes_but_route_preserves_cases = 72`;
- `route_minus_naive_depletion_score_delta_sum = 66462`;
- `burn_physical_dominant_count = 63`;
- `burn_physical_dominant_mean_penalty_bp = 1000`;
- `burn_special_dominant_count = 50`;
- `burn_special_dominant_mean_penalty_bp = 407`;
- `poison_immediate_penalty_cases = 0`;
- `poison_active_tick_penalty_cases = 128`;
- `held_item_in_scalar = false`;
- `selected_operational_readiness_formula = null`.

#### Certificación humana tree-identical

SHA humano final C3f-b:

`0d51894121ccfcdb9ec8bf9d1634492a099a4a4a`

Su árbol es idéntico al SHA técnico corregido.

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: SUCCESS;
- Godot 4.7: SUCCESS;
- DATA Foundation V3: SUCCESS;
- PR #105: OPEN / unmerged;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

C3f-b queda **CERTIFICADO**.

#### Qué queda demostrado y qué NO

Queda demostrado que una futura capa de readiness debe poder disponer, como mínimo, de tres componentes semánticamente distintos:

1. `hp_state_bp` / HP actual relativo;
2. `route_retention_bp` / capacidad sensible a PP que sigue operativa;
3. `immediate_status_action_bp` / degradación de la capacidad de actuar ahora, dependiente del status y del rol.

También queda demostrado que:

- HP solo es incompleto;
- PP medio naive es semánticamente defectuoso;
- PP route-aware maneja correctamente redundancia;
- burn y paralysis necesitan dependencia de rol;
- poison/toxic introducen attrition dependiente del horizonte;
- held item todavía no tiene una penalización genérica demostrada.

NO queda demostrado todavía:

- que los pesos `55/25/20` del blend sean canónicos;
- que la multiplicación pura sea preferible al blend;
- que sleep deba convertir el scalar agregado en cero;
- que un scalar único sea mejor interfaz que exponer primero subcomponentes;
- cómo incorporar attrition sin una definición explícita de horizonte;
- cómo valorar held items de forma general;
- ninguna política de recovery/replacement;
- `permadeath_loss_cost_bp`.

#### Siguiente microtranche autorizada — C3f-c

**C3f-c — sensibilidad/decomposición TEST/AUDIT-ONLY del readiness actual.**

Debe comparar la estabilidad semántica de las familias que sobrevivieron C3f-b, con especial atención a:

- blend frente a producto;
- sensibilidad a pesos razonables del blend;
- comportamiento cuando un solo subcomponente cae a cero;
- diferencia entre “capacidad inmediata” y “attrition pressure”;
- si conviene que la futura API de producción exponga primero `hp_state_bp`, `route_retention_bp` e `immediate_status_action_bp` y deje el scalar agregado sin seleccionar;
- monotonicidad al curar HP;
- monotonicidad al restaurar PP;
- monotonicidad al retirar/curar un status;
- ausencia de penalización por held item mientras no exista valoración certificada;
- determinismo y JSON serialization.

C3f-c seguirá siendo exclusivamente test/audit. No debe modificar `TrainerRosterStrategicValueEvaluator` ni ninguna otra clase de producción.

Sigue prohibido durante C3f-c:

- exponer `operational_readiness_bp` de producción;
- inventar `between_battle_recovery_policy`;
- inventar `replacement_policy`;
- implementar `permadeath_loss_cost_bp`;
- integrar campaign-value en switching/search;
- iniciar FASE34;
- mergear PR #105.


### 26.24 C3f-c — sensibilidad y descomposición del readiness actual

C3f-c se ejecuta después de certificar C3f-b con una pregunta más estricta que “qué fórmula distribuye mejor”: comprobar si existe base semántica suficiente para comprimir HP, retención de rutas PP y disponibilidad inmediata por status en un único `operational_readiness_bp`.

#### Baseline certificado

Baseline documental humano:

`cb04ffb945566623a872a746fb8cbdfbe02f5fce`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- C3f-b estaba certificado con FASE33 **423 PASS / 0 FAIL**;
- `selected_operational_readiness_formula` seguía `null`;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Scope ejecutado

C3f-c sigue siendo exclusivamente TEST/AUDIT-ONLY.

Se añadió:

`tests/trainer_ai/trainer_roster_operational_readiness_decomposition_sensitivity_test_suite.gd`

y se sustituyó una única línea del runner para ejecutar esta suite como heredera de C3f-b.

No se modificó producción.

La suite preserva todos los checks C3f-a/C3f-b y añade una representación explícita de cuatro señales:

1. `hp_state_bp`;
2. `route_retention_bp`;
3. `immediate_status_action_bp`;
4. `attrition_pressure_bp`.

El cuarto componente se mantiene deliberadamente fuera de la tupla de capacidad inmediata porque necesita horizonte.

#### Cinco blends razonables auditados

Se compararon cinco vecindades de pesos test-only, todas normalizadas a 10000 bp:

- `hp_heavy_60_20_20`;
- `baseline_55_25_20`;
- `route_heavy_45_35_20`;
- `status_heavy_45_25_30`;
- `capability_heavy_40_30_30`.

También se mantuvo el producto puro de los tres componentes inmediatos como contraste.

Ningún conjunto de pesos queda seleccionado como canónico.

#### Reversión de ranking por pesos — demostración exacta

Se construyeron dos estados sintéticos:

A:

- HP = 4000;
- route retention = 10000;
- status action = 10000.

B:

- HP = 8000;
- route retention = 6000;
- status action = 6000.

Con blend `60/20/20`:

- A = 6400;
- B = 7200;
- B > A.

Con blend `40/30/30`:

- A = 7600;
- B = 6800;
- A > B.

Por tanto dos elecciones de pesos razonables pueden **invertir el orden estratégico de los miembros** sin que cambie ninguna evidencia subyacente.

Esto impide justificar ahora una selección de pesos como si fuera una consecuencia objetiva del runtime.

#### Colisión semántica del blend

Bajo `55/25/20` se demostraron dos estados distintos que producen exactamente 8000 bp:

A:

- HP 10000;
- route 10000;
- status action 0.

B:

- HP 10000;
- route 2000;
- status action 10000.

El primero conserva HP y rutas pero no puede actuar ahora; el segundo puede actuar pero ha perdido la mayor parte de sus rutas sensibles a PP.

El scalar lineal los colapsa al mismo valor aunque semánticamente no sean intercambiables.

#### Colisión semántica del producto

El producto también pierde información.

A:

- HP 5000;
- route 10000;
- status 10000.

B:

- HP 10000;
- route 5000;
- status 10000.

Ambos producen 5000 bp bajo producto pese a representar degradaciones distintas.

Por tanto el problema no se resuelve sustituyendo blend por multiplicación.

#### Desacuerdo extremo cuando un componente llega a cero

Con los otros dos componentes en 10000:

- status action = 0 -> blend baseline = 8000, producto = 0;
- route retention = 0 -> blend baseline = 7500, producto = 0;
- HP = 0 -> blend baseline = 4500, producto = 0.

Esto expone una diferencia conceptual grande:

- un blend puede mantener un score alto aunque el miembro no pueda actuar ahora;
- el producto puede colapsar a cero un activo estructuralmente intacto que solo está temporalmente dormido.

C3f-c no encuentra base canónica para decidir cuál de esas interpretaciones debe representar un único scalar.

#### Monotonicidad

Todos los blends auditados y el producto sí cumplen las invariantes locales básicas:

- subir HP no reduce score;
- restaurar PP no reduce score;
- curar un status no reduce score.

La ausencia de problemas de monotonicidad no basta, sin embargo, para seleccionar una fórmula: las colisiones y las inversiones de ranking siguen presentes.

#### Sleep demuestra por qué debe conservarse la descomposición

En el fixture de sleep:

- `hp_state_bp = 10000`;
- `route_retention_bp = 10000`;
- `immediate_status_action_bp = 0`.

El blend baseline devuelve 8000; el producto devuelve 0.

La tupla descompuesta conserva toda la información relevante sin obligar a elegir prematuramente entre esas dos interpretaciones.

#### Attrition permanece separado

Un miembro sano y el mismo miembro poisoned pueden tener idéntica tupla inmediata:

- mismo HP actual;
- misma retención de rutas;
- misma disponibilidad de acción inmediata.

Pero poison tiene `attrition_pressure_bp > 0`.

Esto demuestra que la presión de desgaste es una cuarta señal independiente del readiness inmediato y no debe introducirse silenciosamente en el scalar sin una definición de horizonte.

#### Held item sigue fuera de los componentes numéricos

Cambiar únicamente `held_item_consumed` no altera:

- `hp_state_bp`;
- `route_retention_bp`;
- `immediate_status_action_bp`;
- `attrition_pressure_bp`.

El estado del item sigue siendo evidencia estructurada, no una penalización genérica certificada.

#### Muestreo real DATA V3

C3f-c ejecutó además un muestreo determinista de **128 miembros** de DATA V3 (`stride=8`).

La degradación del probe alternó de forma determinista:

- cuatro niveles de HP: 25%, 50%, 75%, 100%;
- agotamiento del primer move en muestras alternas;
- burn, paralysis o sin status en ciclo de tres.

El objetivo no es simular una distribución real de torneo, sino verificar sensibilidad de los agregados sobre estados diversos construidos desde miembros canónicos reales.

Se obtuvieron **97 tuplas inmediatas distintas**.

Medias por agregador:

- `hp_heavy_60_20_20`: **7053 bp**;
- `baseline_55_25_20`: **7227 bp**;
- `route_heavy_45_35_20`: **7576 bp**;
- `status_heavy_45_25_30`: **7291 bp**;
- `capability_heavy_40_30_30`: **7465 bp**;
- producto: **4128 bp**.

Spread entre medias:

**3448 bp**.

Mínimos observados:

- hp-heavy: 3862;
- baseline: 4088;
- route-heavy: 4539;
- status-heavy: 4343;
- capability-heavy: 4569;
- producto: 853.

Todos alcanzaron 10000 en algún estado.

La magnitud de la divergencia sobre los mismos miembros vuelve a confirmar que la elección del agregador tendría consecuencias conductuales sustanciales.

#### SHA técnico C3f-c

SHA técnico:

`ba9b87d79f51f0384856ccdc4e177bed5f2dfa61`

Diff desde 26.23:

- nueva suite C3f-c: **354 líneas**;
- runner: **1 línea cambiada**;
- producción: **0 cambios**.

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **443 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

#### Certificación humana tree-identical

SHA humano C3f-c:

`df5f21c410df0ae8b560ee87e05f23f662f99722`

Su árbol es idéntico al SHA técnico C3f-c.

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: SUCCESS;
- Godot 4.7: SUCCESS;
- DATA Foundation V3: SUCCESS.

C3f-c queda **CERTIFICADO**.

#### Decisión de arquitectura

C3f-c NO autoriza todavía `operational_readiness_bp`.

La evidencia acumulada C3e -> C3f-c favorece una interfaz de producción descompuesta antes que un scalar agregado:

- `hp_state_bp` es objetivo y directo;
- `route_retention_bp` está certificado como alternativa semánticamente superior al PP medio;
- `immediate_status_action_bp` captura la degradación de acción actual con dependencia de rol;
- attrition debe conservarse como evidencia/horizonte separado;
- held item debe conservarse como evidencia hasta tener valoración específica.

La descomposición conserva información que todos los scalars auditados pierden.

#### Siguiente microtranche autorizada — C3f-d

**C3f-d — producción de componentes de readiness actual, SIN scalar agregado.**

Debe crear una superficie de producción separada y auditable para extraer, por miembro propio:

- `hp_state_bp`;
- `route_retention_bp`;
- `immediate_status_action_bp`;
- evidencia estructurada de attrition, incluyendo como mínimo la pérdida del siguiente tick cuando sea definible, pero sin convertirla en readiness proyectado;
- `held_item_id` + `held_item_consumed` como evidencia sin penalización genérica;
- breakdown suficiente para auditar qué rutas PP sustentan cada rol y qué status runtime produjo el factor de acción.

La preferencia arquitectónica es una clase separada de `TrainerRosterStrategicValueEvaluator`, para no mezclar valor estructural y degradación operativa.

La API NO debe exponer:

- `operational_readiness_bp` agregado;
- pesos de blend;
- producto agregado;
- readiness post-recovery;
- replacement expectation;
- `permadeath_loss_cost_bp`.

Regresiones mínimas obligatorias:

- paridad con la evidencia/semántica C3f-a/b/c;
- HP monotónico;
- PP route-aware y redundancia;
- burn físico/especial;
- paralysis dependiente de Speed;
- sleep/freeze;
- poison/toxic como attrition separado;
- held item evidence-only;
- exclusión de stat stages y volátiles;
- no mutación;
- determinismo;
- JSON serialization;
- null catalog fail-closed;
- ausencia de rival/belief/profile/RNG/campaign policy.

Sigue prohibido durante C3f-d:

- seleccionar o exponer `operational_readiness_bp` agregado;
- inventar `between_battle_recovery_policy`;
- inventar `replacement_policy`;
- implementar `permadeath_loss_cost_bp`;
- integrar campaign-value en switching/search;
- iniciar FASE34;
- mergear PR #105.


### 26.25 C3f-d — producción de componentes descompuestos de readiness actual

C3f-d se ejecuta después de que C3f-c demostrase que no existe base suficiente para congelar un único `operational_readiness_bp`. La decisión de arquitectura es por tanto deliberada: llevar a producción los componentes semánticamente certificados sin destruir información mediante un agregado prematuro.

#### Baseline certificado

Baseline documental humano de C3f-c:

`36cd0460db5e0192a4a6831986d2b254c5148947`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **443 PASS / 0 FAIL**;
- C3f-c había probado inversión de ranking con pesos razonables, colisiones semánticas del blend y del producto y una dispersión de **3448 bp** entre agregados sobre los mismos 128 estados real-data degradados;
- la recomendación certificada era `decomposed_components_first`;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Scope ejecutado

Se añadió una nueva clase de producción separada del evaluador estructural:

`modules/trainer_ai/trainer_roster_operational_readiness_evaluator.gd`

Clase:

`TrainerRosterOperationalReadinessEvaluator`

Modelo:

`trainer_roster_current_operational_components_v1`

API pública:

`evaluate_current_components(own_party: Array) -> Dictionary`

La separación respecto de `TrainerRosterStrategicValueEvaluator` es intencional. El valor estructural responde a la pregunta de qué representa permanentemente un activo dentro del roster; la superficie C3f-d responde a qué parte de su capacidad está operativa **ahora**. Mezclar ambas capas habría vuelto a permitir que HP/PP/status borrasen valor estructural permanente, una contradicción que C3 había prohibido desde el diseño.

C3f-d modifica exactamente tres archivos respecto del baseline 26.24:

1. nueva clase de producción `trainer_roster_operational_readiness_evaluator.gd`;
2. nueva suite `trainer_roster_operational_readiness_production_test_suite.gd`;
3. una sustitución de una línea en `trainer_team_composition_test_runner.gd` para ejecutar la nueva suite heredando las auditorías anteriores.

No se modifica `TrainerRosterStrategicValueEvaluator`, switching, search, controller, campaign value ni ninguna política de gameplay.

#### Resultado de roster y tratamiento fail-closed

La llamada devuelve:

- `model_id`;
- `member_count`;
- `skipped_invalid_member_indices`;
- `member_components`.

Se omiten de forma fail-closed:

- entradas que no sean `Dictionary`;
- entradas sin `instance_id`;
- entradas sin `species_id`;
- especies ausentes del `DefinitionCatalog`.

Con `DefinitionCatalog == null`, la superficie devuelve un resultado vacío con el mismo `model_id` y no inventa datos.

A diferencia de la capa estructural, los miembros KO **no se eliminan**. C3f-d es una fotografía del estado operativo de cada miembro conocido: un KO permanece representado con `hp_state_bp = 0`, `is_knocked_out = true` y sin aplicar attrition activa. Eliminarlo ocultaría precisamente el estado que esta superficie debe describir.

#### Los tres componentes inmediatos de producción

Cada miembro válido expone, de forma independiente:

1. `hp_state_bp`;
2. `route_retention_bp`;
3. `immediate_status_action_bp`.

No existe un cuarto campo que los agregue.

No se produce `operational_readiness_bp`, ni blend, ni producto, ni pesos ocultos.

##### `hp_state_bp`

Representa únicamente HP actual relativo:

`current_hp * 10000 / max_hp`

con clamp del HP actual a `[0, max_hp]` y `0` si no hay un `max_hp` válido.

La suite certifica monotonicidad directa: curar HP no puede empeorar el componente.

##### `route_retention_bp`

C3f-d migra a producción la semántica route-aware certificada en C3f-a/C3f-b.

Solo participan movimientos con:

`classification == RUNTIME_SUPPORTED`

Unknown y DATA_ONLY no aportan capacidad y fallan cerrados.

Para cada movimiento runtime-supported se conserva evidencia auditable:

- `move_id`;
- `current_pp`;
- `max_pp`;
- `pp_ratio_bp`;
- validez del estado PP;
- disponibilidad actual;
- damage class;
- power;
- type;
- afinidad por rol sensible a PP.

Los roles sensibles a PP son:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `support`.

La afinidad de cada ruta reutiliza `TrainerRosterRoleInference` sobre el moveset reducido a ese movimiento. Después se calculan máximos por rol para todas las rutas y para las rutas que conservan PP.

La retención queda:

- `10000` si no existe capacidad PP-sensitive que dividir;
- en otro caso, suma de capacidad disponible / suma de capacidad total, en basis points.

Esto conserva la propiedad clave descubierta en C3f-a/b: agotar una de dos rutas redundantes no destruye ficticiamente la capacidad mientras otra ruta equivalente siga disponible.

El `breakdown.route_retention` conserva además:

- `all_pp_sensitive_role_max_bp`;
- `available_pp_sensitive_role_max_bp`;
- `runtime_move_pp`;
- movimientos disponibles;
- movimientos agotados;
- movimientos excluidos;
- movimientos desconocidos.

##### `immediate_status_action_bp`

Representa degradación de la capacidad de actuar **ahora**, no attrition futura ni recuperación posterior.

La lógica es la misma certificada en C3f-b:

- sin status: `10000`;
- burn: penalización dependiente de cuánto descansa la capacidad real en la ruta física frente a especial y del multiplicador runtime de burn;
- paralysis: combina probabilidad runtime de perder acción con degradación de Speed ponderada por dependencia real del rol `fast_attacker`;
- sleep: `0` mientras `turns_remaining > 0`;
- freeze: disponibilidad actual igual a la probabilidad runtime de thaw;
- poison/toxic: `10000` en este componente, porque no implican por sí solos pérdida de la acción presente;
- status persistente no reconocido: no se inventa modificador y queda marcado como no reconocido.

El breakdown conserva `rule_id`, efectos runtime y dependencias intermedias para que el cálculo sea auditable.

#### Attrition permanece separada del estado inmediato

C3f-d añade un bloque `attrition` estructurado, pero **no lo incorpora a ningún scalar**.

El bloque distingue explícitamente entre:

- que exista una fórmula de daño residual para el status;
- que el miembro sea el activo y esté vivo, por lo que el siguiente tick aplicaría bajo el supuesto explícito de final de turno activo;
- cuánto representa el tick respecto a `max_hp`;
- cuál sería el daño entero según el mismo redondeo del runtime;
- cuánto daño puede aplicarse realmente limitado por `current_hp`.

Campos principales:

- `active_member_required`;
- `requires_active_end_turn_assumption`;
- `next_active_tick_formula_defined`;
- `next_active_tick_applies_now`;
- `next_active_tick_loss_max_hp_bp`;
- `next_active_tick_raw_damage_hp`;
- `next_active_tick_applied_damage_hp`;
- divisor residual;
- contador toxic antes y para el próximo tick;
- `projected_readiness_included = false`.

#### Paridad exacta con el runtime residual

Antes de producir daño entero se verificó el contrato real de `StatusSystem`.

La producción C3f-d replica exactamente:

- poison: `max(1, max_hp / poison_divisor)`;
- burn: `max(1, max_hp / burn_divisor)`;
- toxic: incrementa primero el contador y luego calcula `max(1, max_hp * counter / toxic_divisor)`;
- el daño aplicado no supera HP actual.

También respeta la frontera runtime de aplicación: el residual de final de turno procesa al miembro activo vivo. Por eso un Pokémon poisoned en bench puede tener una fórmula definida, pero `next_active_tick_applies_now = false`. Lo mismo ocurre con un miembro KO.

Esto evita confundir “este status tiene presión de attrition” con “este daño se va a aplicar necesariamente en este instante”.

#### Held item: evidencia, no valoración genérica

La superficie conserva:

- `held_item_id`;
- `held_item_consumed`;
- `present`;
- `available`.

Consumir el item no cambia por sí solo `hp_state_bp`, `route_retention_bp` ni `immediate_status_action_bp`.

Sigue sin existir una penalización universal porque C3f-b/c no la demostraron y los items no tienen valor homogéneo.

#### Transitorios excluidos

C3f-d conserva la frontera ya auditada:

- `stat_stages` no entra en la capa persistente de readiness;
- `status_state.volatile` tampoco.

El output marca explícitamente:

`excluded_transient_fields = ["stat_stages", "status_state.volatile"]`

La suite comprueba que añadir stages o volatile state no cambia la salida persistente.

Esto evita mezclar una fotografía de recursos/estado persistente con condiciones tácticas efímeras de una batalla concreta.

#### Independencia de información oculta y políticas

La suite inyecta ruido externo y comprueba que el resultado no cambia ante:

- opponent;
- rival memory;
- beliefs;
- TrainerProfile;
- RNG;
- campaign snapshot.

Además recorre el output de forma recursiva y prohíbe claves que congelarían prematuramente capas bloqueadas, entre ellas:

- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- blend weights;
- product score;
- post-recovery readiness.

#### Suite de producción C3f-d

Nueva suite:

`tests/trainer_ai/trainer_roster_operational_readiness_production_test_suite.gd`

Hereda `TrainerRosterOperationalReadinessDecompositionSensitivityTestSuite`, por lo que ejecuta primero los **443 checks** anteriores.

Añade **29 checks** específicos de producción que cubren:

- model id y shape;
- no mutación;
- paridad directa C3f-a de rutas PP;
- paridad directa C3f-b de los tres componentes;
- monotonicidad de HP;
- redundancia de rutas;
- burn y paralysis dependientes de rol;
- sleep/freeze;
- poison/toxic;
- daño residual entero igual al runtime;
- cap de daño por HP actual;
- held items evidence-only;
- transitorios excluidos;
- KO retenido;
- diferencia active/bench;
- independencia de contexto oculto/políticas;
- fail-closed;
- determinismo;
- serialización JSON;
- ausencia de scalar/políticas prohibidas.

#### SHA técnico C3f-d

SHA técnico:

`653f1cae9a98b5d6441900fbf02690f1a4a367c6`

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **472 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

La primera implementación pasó completa; no fue necesario ningún ciclo de corrección.

#### Certificación humana tree-identical

Árbol del SHA técnico:

`43a55fa32439f67092d5bd1adda0c877d503e258`

SHA humano C3f-d:

`5fff90738b46d96a5ec6a9c1888e10d19a9e807d`

Es tree-identical al técnico.

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **472 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS;
- PR #105: OPEN / unmerged;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

C3f-d queda **CERTIFICADO** técnicamente.

#### Qué queda autorizado en producción y qué NO

Queda autorizada como superficie de producción independiente la lectura actual de:

1. HP relativo;
2. capacidad PP-sensitive que sigue conservando rutas runtime-supported;
3. disponibilidad inmediata de acción bajo status persistente;
4. evidencia separada de attrition del próximo tick activo cuando la fórmula está definida;
5. identidad/disponibilidad del held item sin valoración genérica.

No se autoriza todavía ningún consumidor estratégico de esa superficie.

En particular siguen bloqueados:

- un agregado `operational_readiness_bp`;
- cualquier blend/producto/pesos canónicos;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- `permadeath_loss_cost_bp`;
- una estimación post-recovery;
- integración de campaign-value en switching/search;
- FASE34;
- merge de PR #105.

#### Siguiente microtranche autorizada — C3f-e

**C3f-e — auditoría real-data directa de la superficie de producción.**

C3f-a/b/c probaron la semántica con helpers audit-only y C3f-d probó paridad sintética directa al migrarla. Antes de permitir un consumidor, la siguiente barrera debe ejecutar la **clase de producción real** sobre DATA V3 real.

C3f-e será exclusivamente TEST/AUDIT-ONLY y no modificará producción.

Debe, como mínimo:

- instanciar `TrainerRosterOperationalReadinessEvaluator` sobre miembros reales DATA V3 mediante una selección determinista auditable;
- reutilizar, para comparabilidad, el muestreo de 128 miembros / stride 8 de C3f-b/c y, si el coste permite hacerlo sin degradar CI, ampliar la sonda a los 1021 elegibles;
- producir las mismas degradaciones deterministas de HP, PP, status e item;
- comparar exactamente producción frente a la semántica certificada de los helpers para `hp_state_bp`, `route_retention_bp`, `immediate_status_action_bp` y `next_active_tick_loss_max_hp_bp`;
- auditar active frente a bench para residual;
- auditar `runtime_move_pp` y afinidades de rol sobre datos reales;
- medir rangos/distribuciones sin convertirlos en criterio de selección de scalar;
- exigir determinismo y JSON serialization;
- comprobar otra vez ausencia de `operational_readiness_bp` y de políticas bloqueadas.

C3f-e no podrá introducir consumidores de producción, recovery/replacement, permadeath-loss ni FASE34.

Solo después de C3f-e deberá decidirse en un checkpoint documental si los componentes pueden exponerse a una futura capa de campaign value **sin agregarlos**, o si el avance debe detenerse hasta que las reglas de recovery/replacement estén definidas.


### 26.26 C3f-e — auditoría real-data de la superficie operativa de producción

**Estado:** CERRADO / CERTIFICADO.

C3f-e se ejecutó como microtranche exclusivamente de **test/audit** para comprobar que la superficie de producción introducida en C3f-d no solo conserva la semántica en fixtures sintéticos, sino también al consumir el DATA V3 canónico a escala amplia.

#### Baseline y SHAs

- Baseline documental C3f-d / 26.25: `ff10b71cfec2e6481ac1d723a86cb032880f79d3`.
- SHA técnico C3f-e: `184ee9cc75afb14a96a710e31071dd01f8d40a43`.
- SHA humano tree-identical C3f-e: `eed5528e47776f06517a6a7f46e23132ea1ac36a`.
- Árbol técnico/humano común: `95cf27e95c400c23980adeccb333a570bf3e2ca7`.

El SHA humano fue construido sobre exactamente el mismo árbol que el SHA técnico y se certificó de nuevo por CI antes de considerar C3f-e cerrado.

#### Alcance neto

El diff de C3f-e frente a `ff10b71...` quedó limitado a **dos archivos de test**:

1. nuevo `tests/trainer_ai/trainer_roster_operational_readiness_production_real_data_audit_test_suite.gd` — **+398 líneas**;
2. `tests/trainer_ai/trainer_team_composition_test_runner.gd` — sustitución de una sola línea para ejecutar la nueva suite heredada.

No se modificó ningún archivo de producción.

En particular, C3f-e **no** cambió:

- `TrainerRosterOperationalReadinessEvaluator`;
- `TrainerRosterStrategicValueEvaluator`;
- switching estratégico;
- búsqueda/planning;
- controller/campaign integration;
- recovery/replacement;
- reglas de permadeath;
- FASE34.

#### Objetivo auditado

La suite invoca directamente la clase de producción:

`TrainerRosterOperationalReadinessEvaluator`

modelo:

`trainer_roster_current_operational_components_v1`

y compara sus salidas contra los helpers semánticos ya certificados durante C3f-a/C3f-b/C3f-c.

La condición de aceptación fue **paridad exacta, mismatch = 0**, no una distribución visualmente razonable.

#### Dataset y metodología

Se reutilizó el probe canónico real-data:

`runtime_levelup_l50_neutral_probe_v1`

sobre DATA V3 normalizado.

Cobertura principal:

- especies elegibles con moveset runtime: **1021**;
- miembros sanos auditados: **1021 / 1021**;
- entradas de movimientos runtime inspeccionadas: **4015**.

Cada uno de esos 1021 miembros fue evaluado en estado sano, HP completo, PP completo y sin status persistente. La producción debía devolver los tres componentes inmediatos en techo y conservar paridad exacta de rutas PP con la semántica certificada.

Además se construyó una muestra degradada determinista:

- stride: **8**;
- miembros: **128**;
- degradación de HP;
- degradación de PP;
- rotación de status persistente;
- active/bench;
- disponibilidad/consumo de held item.

La rotación de status cubrió:

- `burn`: 19 casos;
- `paralysis`: 18;
- `poison`: 18;
- `badly_poisoned`: 18;
- `sleep`: 18;
- `freeze`: 18;
- sin status: 19.

#### Paridad de producción

Resultado central: **todos los contadores de divergencia quedaron en cero**.

- `healthy_component_parity_mismatches = 0`;
- `healthy_route_evidence_mismatches = 0`;
- `healthy_non_ceiling_component_cases = 0`;
- `degraded_component_parity_mismatches = 0`;
- `degraded_route_evidence_mismatches = 0`;
- `attrition_bp_mismatches = 0`;
- `attrition_raw_damage_mismatches = 0`;
- `attrition_applied_damage_mismatches = 0`;
- `active_bench_application_mismatches = 0`;
- `held_item_component_mismatches = 0`;
- `blocked_output_cases = 0`.

Esto certifica que la migración de C3f-d no reinterpretó silenciosamente la semántica de las auditorías previas.

#### Diversidad observada

La muestra degradada no colapsó en unos pocos estados triviales:

- vectores inmediatos distintos: **96** sobre 128 miembros;
- `hp_state_bp`: media **6230**, mínimo **2427**, máximo **10000**;
- `route_retention_bp`: media **9512**, mínimo **6250**, máximo **10000**;
- `immediate_status_action_bp`: media **6148**, mínimo **0**, máximo **10000**.

La lectura es importante: la paridad cero no proviene de que todos los casos produzcan el mismo vector.

#### Attrition y active/bench

C3f-e verificó por separado la semántica de attrition:

- casos con attrition activo aplicado: **27**;
- casos bench que conservan fórmula de attrition pero no la aplican como tick activo actual: **28**;
- mismatches de presión en bp: **0**;
- mismatches de daño residual entero bruto: **0**;
- mismatches de daño aplicado limitado por HP actual: **0**;
- mismatches active/bench: **0**.

Por tanto, producción mantiene la distinción certificada entre:

1. que un status tenga una fórmula residual;
2. cuánto sería el próximo tick;
3. que ese tick se aplique **ahora** al miembro activo.

No se convirtió attrition en una predicción multi-turn ni en una política de campaña.

#### Held item

La disponibilidad de held item sigue siendo evidencia explícita, no un multiplicador oculto de readiness.

La auditoría alternó item disponible/consumido y obtuvo:

`held_item_component_mismatches = 0`

Los tres componentes inmediatos permanecen independientes de esa disponibilidad mientras no exista una semántica autorizada que convierta el item en valor operacional agregado.

#### Scalar deliberadamente no seleccionado

C3f-e **no** selecciona ni produce:

`operational_readiness_bp`

El reporte conserva explícitamente:

`selected_operational_readiness_formula = null`

La razón continúa siendo la demostrada por C3f-c: agregaciones razonables pueden invertir rankings y destruir información distinta con el mismo número final.

La interfaz certificada sigue siendo **component-first**:

- `hp_state_bp`;
- `route_retention_bp`;
- `immediate_status_action_bp`;
- attrition separado;
- item como evidencia separada.

#### Consumidores todavía no autorizados

El propio reporte C3f-e fija:

`consumer_integration_authorized = false`

Por tanto, cerrar C3f-e **no** autoriza todavía a introducir esta superficie directamente en:

- switching;
- search/planning;
- selección de sacrificios;
- decisiones de curación;
- lógica de campaña;
- valoración de pérdida permanente.

Antes de un consumidor real debe existir una microtranche separada que defina qué componentes puede leer, en qué horizonte y con qué invariantes, sin esconder una nueva fórmula scalar en el consumidor.

#### Límites que siguen bloqueados

Siguen fuera de alcance:

- scalar global `operational_readiness_bp`;
- `permadeath_loss_cost_bp` definitivo;
- `replacement_policy` inventada;
- `between_battle_recovery_policy` inventada;
- lectura de rival/beliefs/hidden bracket como valor objetivo del roster propio;
- integración switching/search de campaña;
- FASE34;
- merge de PR #105.

#### CI y certificación

SHA técnico `184ee9cc75afb14a96a710e31071dd01f8d40a43`:

- **18/18 workflows SUCCESS**;
- FASE33 Team Composition: **491 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

SHA humano tree-identical `eed5528e47776f06517a6a7f46e23132ea1ac36a`:

- **18/18 workflows SUCCESS**;
- FASE33 Team Composition: **491 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

El reporte real-data fue determinista y JSON-serializable en ambos SHAs.

#### Invariantes del repositorio

Durante la certificación humana se verificó de nuevo:

- PR #105: **OPEN**, `merged_at = null`;
- head de PR #105: `eed5528e47776f06517a6a7f46e23132ea1ac36a` antes del append documental;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, sin movimiento.

#### Conclusión de C3f-e

C3f-e cierra la duda principal posterior a C3f-d: la superficie descompuesta de readiness no solo pasa fixtures; **reproduce exactamente la semántica certificada sobre DATA V3 real**, tanto en estado sano como bajo degradaciones de HP/PP/status/attrition/item.

Esto permite considerar estable el **contrato productor** de componentes operativos actuales.

No permite aún considerar estable ningún **contrato consumidor** ni ningún scalar global.

#### Siguiente frontera prudente

La siguiente microtranche debe permanecer separada de la integración de comportamiento: diseñar y auditar un **contrato de consumo component-first** que combine la evidencia estructural y operacional sin seleccionar a escondidas un `operational_readiness_bp`, sin inventar recovery/replacement y sin conectar todavía switching/search.

Solo después de demostrar invariantes de ese contrato podrá evaluarse una integración concreta en una tranche posterior.


### 26.27 C3f-f — contrato component-first para consumidores, sin scalar combinado

Estado: **CERRADO / CERTIFICADO**.

Baseline de entrada de C3f-f:

`3c5a6d8985ae9291804622e7056a16861d74e31f`

Ese baseline correspondía a C3f-e + 26.26 ya certificados, con:

- `TrainerRosterStrategicValueEvaluator` en producción;
- `TrainerRosterOperationalReadinessEvaluator` en producción;
- `structural_value_bp` certificado;
- componentes operacionales actuales certificados por separado;
- DATA V3 real-data auditada;
- ningún `operational_readiness_bp` agregado seleccionado;
- ninguna integración nueva con switching/search;
- recovery/replacement/permadeath todavía sin política inventada.

#### Objetivo de C3f-f

Antes de permitir que cualquier consumidor combine valor estructural y estado operacional, comprobar si existe un contrato conjunto que:

1. una ambas superficies por identidad canónica;
2. conserve explícitamente sus modelos de origen;
3. no esconda pesos ni un ranking total;
4. trate correctamente a miembros KO;
5. mantenga attrition separado del vector inmediato;
6. no lea contexto rival, beliefs, perfil, RNG ni políticas de campaña inexistentes;
7. sea determinista, serializable y robusto frente al orden de entrada.

C3f-f fue deliberadamente **test/audit-only**.

No añadió clase de producción ni consumidor conductual.

#### Suite añadida

`tests/trainer_ai/trainer_roster_component_first_consumer_contract_audit_test_suite.gd`

Clase:

`TrainerRosterComponentFirstConsumerContractAuditTestSuite`

Audit ID:

`c3f_f_component_first_consumer_contract_audit_v1`

Contrato candidato auditado:

`trainer_roster_component_first_consumer_contract_candidate_v1`

La suite hereda la cadena C3 anterior y añade 18 invariantes nuevas.

FASE33 pasa de 491 a **509 checks**.

#### Join canónico

El contrato candidato NO hace `zip` posicional de las dos superficies.

Une los resultados por:

`instance_id`

Esto es obligatorio porque las semánticas de KO difieren de forma intencionada:

- la valoración estructural excluye del roster superviviente al miembro KO;
- la superficie operacional conserva el miembro KO y registra su estado actual.

Por tanto, para cada miembro el contrato candidato expone explícitamente:

- identidad;
- `availability_state`;
- subbloque `structural` con `available`;
- subbloque `operational` con `available`;
- evidencia separada de item;
- attrition separado del vector inmediato.

No se inventa un `structural_value_bp` para un KO.

#### Modelos de origen explícitos

El contrato conserva los IDs canónicos de las dos superficies:

- estructural: `trainer_roster_structural_value_capped_units_blend_v1`;
- operacional: `trainer_roster_current_operational_components_v1`.

No fusiona ambos modelos bajo una fórmula nueva.

#### Muestreo real-data

Se reutiliza DATA V3 real y la geometría de probe/schedule ya certificada.

Datos del audit:

- especies elegibles: **1021**;
- rosters muestreados: **128**;
- miembros por roster: **6**;
- estados conjuntos inspeccionados: **768**;
- stride del muestreo: **8**.

#### Integridad del join

Resultado:

- `missing_operational_join_cases = 0`;
- `missing_structural_survivor_join_cases = 0`;
- `species_identity_mismatches = 0`;
- `duplicate_contract_instance_ids = 0`;
- `model_identity_mismatches = 0`;
- `reorder_contract_mismatches = 0`.

Por tanto, el contrato candidato es estable frente al reordenamiento del input y no depende de posiciones del array.

#### Independencia de capas

Se ejecutaron probes específicos para impedir contaminación entre valor permanente y estado presente.

HP:

- `hp_operational_change_cases = 24`;
- `hp_structural_mutation_mismatches = 0`.

PP:

- `pp_route_change_cases = 11`;
- `pp_structural_mutation_mismatches = 0`;
- `pp_unexpected_operational_dimension_mismatches = 0`.

Status:

- `status_action_change_cases = 24`;
- `status_structural_mutation_mismatches = 0`;
- `status_unexpected_operational_dimension_mismatches = 0`.

Held item:

- `item_availability_change_cases = 24`;
- `item_structural_mutation_mismatches = 0`;
- `item_numeric_component_mismatches = 0`.

Esto confirma que la interfaz component-first mantiene separadas las dimensiones en vez de volver a introducir una media implícita.

#### KO y recomputación de roster

Se ejecutaron **24 KO probes**.

Resultado:

- `ko_contract_missing_cases = 0`;
- `ko_fake_structural_value_cases = 0`;
- `ko_operational_state_mismatches = 0`.

Además:

- `survivor_operational_changes_after_teammate_ko = 0`;
- `survivor_structural_change_after_teammate_ko = 36`;
- `survivor_structural_decrease_after_teammate_ko = 0`.

Semántica confirmada:

- perder un compañero puede cambiar la importancia estructural marginal de los supervivientes;
- esa pérdida NO reescribe artificialmente su HP, PP o status actual;
- el miembro KO sigue visible operacionalmente;
- no recibe un valor estructural falso como si siguiera disponible.

#### Pareto y ausencia de ranking total gratuito

C3f-f compara el vector inmediato sin attrition mediante dominancia Pareto.

Resultados real-data:

- comparaciones de pares: **1920**;
- pares con dominancia Pareto: **519**;
- pares incomparables: **1401**;
- pares con trade-off `structural_higher / operational_lower`: **1379**.

Así, aproximadamente el **73 %** de los pares inspeccionados son incomparables sin introducir una preferencia externa.

Este resultado es importante.

No es una carencia del contrato: demuestra que structural value y operational state describen dimensiones realmente diferentes.

Un consumidor que necesite escoger entre esos miembros tendrá que aportar una política explícita de decisión correspondiente a su problema concreto.

No se autoriza transformar esta incomparabilidad en:

- `combined_score`;
- `combined_score_bp`;
- `ranking_score`;
- `preservation_score`;
- `best_member_id`;
- `operational_readiness_bp` global.

#### Attrition

Attrition permanece fuera del vector Pareto inmediato.

Esto evita convertir poison/toxic/burn residual en una pérdida de capacidad inmediata sin horizonte temporal.

El contrato puede transportar la evidencia de attrition certificada, pero un consumidor futuro deberá declarar de forma explícita cuándo y con qué horizonte la utiliza.

#### Contextos prohibidos

Resultado:

- `forbidden_contract_key_cases = 0`;
- `forbidden_context_key_cases = 0`.

El contrato candidato no contiene ni consume:

- `observed_opponents`;
- `beliefs`;
- `rival_memory`;
- `trainer_profile`;
- `campaign_snapshot`;
- bracket oculto;
- futuros oponentes;
- RNG/seed;
- recovery/replacement policy;
- switching/search score.

#### Determinismo y serialización

C3f-f confirma:

- reporte determinista;
- JSON serializable;
- input reorder invariant.

#### Incidente mecánico durante la tranche

Primer SHA técnico:

`51f774d1...`

La primera ejecución no llegó a auditar semántica por una dedentación accidental dentro del loop de miembros de la propia suite.

El error dejaba `instance_id` y `state` fuera de scope.

No afectaba a producción.

Se corrigió únicamente la indentación mediante un workflow temporal autolimpiable.

SHA técnico corregido:

`4337fdf8e02c60ea9e67cf8d16530749366bcc22`

Diff neto frente al baseline C3f-e:

- suite C3f-f nueva;
- runner actualizado;
- **cero producción**;
- **cero temporales**.

Sobre ese SHA:

- **18/18 workflows SUCCESS**;
- Team Composition: **509 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

#### Certificación humana

SHA humano tree-identical:

`cce96ae42d0b788ced20d9717e90cbc1aa250201`

Sobre ese SHA exacto se repite:

- **18/18 workflows SUCCESS**;
- FASE33: **509 PASS / 0 FAIL**;
- Godot general: SUCCESS;
- DATA V3: SUCCESS.

PR temporal #105 permanece:

- `state = open`;
- `merged_at = null`;
- head = `cce96ae42d0b788ced20d9717e90cbc1aa250201` al cerrar la certificación.

`main` permanece exactamente en:

`f8452a1625ccb8389c9e52ff4416a96a24e00efd`

#### Conclusión C3f-f

C3f-f valida la **forma del contrato component-first**.

La evidencia real-data demuestra que:

1. structural value y operational state deben mantenerse separados;
2. el join debe hacerse por identidad, no por posición;
3. KO necesita semántica explícita de disponibilidad;
4. attrition debe permanecer separado del vector inmediato;
5. un ranking total global no está justificado;
6. los consumidores futuros deben declarar su propia política concreta y auditable.

#### Siguiente microtranche autorizada

**C3f-g — portar el contrato component-first a una superficie de producción pasiva.**

Scope autorizado:

- clase nueva y aislada;
- composición de `TrainerRosterStrategicValueEvaluator` + `TrainerRosterOperationalReadinessEvaluator`;
- join por `instance_id`;
- misma semántica KO certificada;
- mismos IDs de modelo explícitos;
- attrition e item conservados como evidencia separada;
- determinismo/fail-closed/JSON;
- paridad exacta con el contrato audit-only C3f-f;
- DATA V3 audit después del port.

Sigue **NO autorizado** en C3f-g:

- seleccionar `operational_readiness_bp`;
- crear `combined_score` o ranking total;
- escoger `best_member_id`;
- integrar switching/search;
- modificar brains;
- usar rival/beliefs/profile como valor objetivo;
- inventar `replacement_policy`;
- inventar `between_battle_recovery_policy`;
- definir `permadeath_loss_cost_bp` definitivo;
- abrir FASE34;
- mergear PR #105.

La superficie C3f-g, si pasa, será únicamente un **productor pasivo de contrato**, no una nueva conducta del entrenador.


### 26.28 C3f-g — contrato component-first pasivo en producción

Estado: **CERRADO / CERTIFICADO**.

Baseline de entrada:

`a18ead23063e9061604c2bc6b9244d2c2ff1b2f3`

Ese baseline correspondía a C3f-f + 26.27 ya certificados con **18/18 SUCCESS** y FASE33 **509 PASS / 0 FAIL**.

#### Objetivo

Portar a producción la forma component-first validada por C3f-f sin introducir ningún consumidor conductual.

La tranche debía limitarse a:

- componer `TrainerRosterStrategicValueEvaluator` y `TrainerRosterOperationalReadinessEvaluator`;
- unir por `instance_id`;
- conservar semántica KO explícita;
- conservar model IDs y formula ID de origen;
- mantener attrition e item como evidencia separada;
- devolver orden canónico y determinista;
- no seleccionar scalar, ranking, miembro ni política.

#### Producción añadida

Archivo:

`modules/trainer_ai/trainer_roster_component_first_contract.gd`

Clase:

`TrainerRosterComponentFirstContract`

Model ID:

`trainer_roster_component_first_contract_v1`

API:

`build_contract(own_party: Array) -> Dictionary`

La clase es un **productor pasivo**. No modifica brains, switching, search ni decisiones.

#### Forma del resultado

Cabecera:

- `model_id`;
- `structural_model_id`;
- `structural_formula_id`;
- `operational_model_id`;
- `member_count`;
- `member_states`.

Los miembros se unen mediante `instance_id` y se ordenan léxicamente.

Cada estado mantiene:

- `instance_id`;
- `species_id`;
- `availability_state`;
- bloque `structural`;
- bloque `operational`.

#### KO

La semántica de C3f-f se porta literalmente:

- el miembro KO permanece en el contrato porque sigue existiendo en la superficie operacional;
- `availability_state = knocked_out`;
- `operational.available = true`;
- `operational.is_knocked_out = true`;
- `hp_state_bp = 0`;
- `structural.available = false`;
- no existe `structural_value_bp` falso;
- `unavailable_reason = knocked_out_not_in_surviving_structural_roster`.

La pérdida de un compañero puede recomputar valor estructural de supervivientes, pero no reescribe sus componentes operacionales.

#### Fail-closed

- catálogo null -> contrato vacío con model ID válido;
- miembros inválidos -> no producen estados falsos;
- no se sintetizan joins estructurales inexistentes.

#### Suite de producción

Archivo:

`tests/trainer_ai/trainer_roster_component_first_contract_production_test_suite.gd`

Clase:

`TrainerRosterComponentFirstContractProductionTestSuite`

Hereda C3f-f y añade **21 checks**.

Se comprueba:

- DATA cargada;
- 1021 especies elegibles en probe;
- model ID de producción;
- IDs estructural/operacional y formula ID;
- igualdad exacta con el contrato candidato C3f-f tras normalizar únicamente el model ID del wrapper;
- conteo completo de miembros;
- no mutación del input;
- invariancia al orden de entrada;
- orden léxico de salida;
- joins completos;
- semántica KO;
- no reescritura operacional de supervivientes tras KO de compañero;
- attrition e item separados;
- ausencia recursiva de scalar/policy/context prohibido;
- ausencia de selección conductual;
- determinismo;
- JSON;
- fail-closed de inputs inválidos y catálogo null.

#### Paridad C3f-f -> C3f-g

Check crítico:

`component_contract_production_matches_certified_candidate_shape`

Resultado: **PASS**.

La producción coincide con la forma certificada C3f-f, salvo el cambio deliberado:

`trainer_roster_component_first_consumer_contract_candidate_v1`

->

`trainer_roster_component_first_contract_v1`

No se añadió ninguna semántica nueva durante el port.

#### Scope neto

Frente al baseline 26.27:

- nueva clase de producción: +102 líneas;
- nueva suite: +180 líneas;
- runner: una sustitución;
- cero brains;
- cero switching/search;
- cero documentación en el checkpoint técnico;
- cero temporales.

#### Certificación técnica

SHA técnico:

`eb95227bb2f12aaba8aedff6002b940445912320`

Resultado:

- **18/18 workflows SUCCESS**;
- Team Composition: **530 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

#### Certificación humana

SHA humano tree-identical:

`65c988e367cdedb75b333735d7b9f3eb6ae5067a`

Árbol:

`5318530191365199f244d854c68de5b540f7fbc0`

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **530 PASS / 0 FAIL**;
- Godot general: SUCCESS;
- DATA V3: SUCCESS.

PR #105 permanece abierto y no mergeado.

`main` permanece exactamente en:

`f8452a1625ccb8389c9e52ff4416a96a24e00efd`

#### Conclusión

C3f-g demuestra que el contrato component-first puede existir en producción como **superficie pasiva** sin introducir ranking ni comportamiento.

La disponibilidad de esta clase NO autoriza por sí sola a ningún brain a consumirla.

Sigue sin existir un scalar agregado operacional ni un `combined_score`.

#### Siguiente microtranche autorizada

**C3f-h — auditoría real-data del contrato de producción.**

Scope:

- test/audit-only;
- ejecutar `TrainerRosterComponentFirstContract` directamente sobre DATA V3 real;
- usar muestreo determinista ya certificado;
- comprobar paridad roster-a-roster con el contrato candidato C3f-f;
- comprobar 0 mismatches de identidad/model IDs/joins/KO/reorder;
- comprobar ausencia de scalars/policies/context prohibido;
- registrar distribución de availability y trade-offs sin seleccionar ranking;
- determinismo y JSON.

Sigue NO autorizado:

- conectar switching/search;
- modificar brains;
- seleccionar `operational_readiness_bp`;
- crear `combined_score`, ranking o `best_member_id`;
- inventar recovery/replacement;
- definir `permadeath_loss_cost_bp` definitivo;
- FASE34;
- merge de PR #105.


### 26.29 C3f-h — auditoría real-data del contrato component-first de producción

Estado: **CERRADO / CERTIFICADO**.

Baseline documental de entrada:

`73094431fdf8e481807592d966de9554df94f2e8`

Ese baseline correspondía a C3f-g + 26.28, con `TrainerRosterComponentFirstContract` ya disponible en producción como productor pasivo y certificado con **18/18 SUCCESS** y FASE33 **530 PASS / 0 FAIL**.

#### Objetivo

C3f-h era la barrera real-data exigida antes de considerar cualquier interfaz de consumo posterior.

La tranche debía permanecer estrictamente **TEST/AUDIT-ONLY** y demostrar que la clase de producción real:

- conserva la forma certificada en C3f-f;
- mantiene joins por `instance_id`;
- preserva semántica KO;
- es invariante al orden de entrada;
- no introduce scalar, ranking ni policy oculta;
- reproduce los trade-offs estructural/operacional observados por el contrato candidato;
- no autoriza todavía comportamiento.

No se modificó ninguna clase de producción.

#### Scope neto

Frente al baseline 26.28, C3f-h modifica exactamente:

1. nueva suite `tests/trainer_ai/trainer_roster_component_first_contract_real_data_audit_test_suite.gd`;
2. una sustitución en `tests/trainer_ai/trainer_team_composition_test_runner.gd`.

Diff neto final:

- suite C3f-h: +314 líneas;
- runner: +1 / -1;
- cero producción;
- cero docs dentro del checkpoint técnico;
- cero workflows o triggers temporales supervivientes.

#### Incidente del primer intento

Primer SHA técnico:

`591177294039fd94b76778cbd301762b3bb9699d`

La matriz produjo **17/18 SUCCESS**, con fallo únicamente en Team Composition.

La auditoría semántica no llegó a ejecutarse. Godot rechazó la suite porque redeclaraba dos constantes que ya existían en la jerarquía padre:

- `SAMPLE_STRIDE`;
- `KO_PROBE_ROSTERS`.

No era un fallo del contrato de producción ni una divergencia real-data.

La corrección consistió exclusivamente en eliminar esas dos redeclaraciones y reutilizar las constantes heredadas. Se aplicó mediante workflow temporal autolimpiable. Un primer intento del workflow temporal tuvo un error YAML en su `if:` por el texto del mensaje; no ejecutó job ni tocó contenido. El workflow reparado se ejecutó correctamente y se autolimpió.

SHA técnico corregido:

`7f37fb73c6044207cf47377f2f675edadba2e64b`

Árbol corregido:

`f67f25495310e30a3191b7d31493505ad1c1737c`

#### Muestreo real-data

Audit ID:

`c3f_h_component_first_contract_production_real_data_v1`

Se reutiliza la geometría determinista ya certificada:

- especies elegibles: **1021**;
- rosters muestreados: **128**;
- miembros por roster: **6**;
- estados conjuntos inspeccionados: **768**;
- stride: **8**;
- KO probes: **24**.

La auditoría ejecuta `TrainerRosterComponentFirstContract` directamente y compara su salida con la construcción candidata C3f-f bajo el mismo roster real.

#### Paridad exacta producción -> contrato candidato

Resultado:

- `candidate_parity_mismatches = 0`;
- `reorder_mismatches = 0`;
- `identity_mismatches = 0`;
- `model_id_mismatches = 0`;
- `duplicate_instance_id_cases = 0`;
- `missing_operational_join_cases = 0`;
- `missing_structural_survivor_join_cases = 0`;
- `forbidden_contract_key_cases = 0`;
- `forbidden_context_key_cases = 0`.

La clase de producción reproduce por tanto el contrato certificado roster-a-roster sin depender de posiciones del array ni introducir contexto oculto.

Model IDs observados:

- producción: `trainer_roster_component_first_contract_v1`;
- estructural: `trainer_roster_structural_value_capped_units_blend_v1`;
- fórmula estructural: `capped_units_blend_baseline_w30_v1`;
- operacional: `trainer_roster_current_operational_components_v1`.

#### KO real-data

Sobre 24 KO probes:

- `ko_candidate_parity_mismatches = 0`;
- `ko_fake_structural_value_cases = 0`;
- `ko_state_mismatches = 0`.

Para los supervivientes:

- `survivor_operational_changes_after_teammate_ko = 0`;
- `survivor_structural_change_after_teammate_ko = 29`;
- `survivor_structural_decrease_after_teammate_ko = 0`.

Esto vuelve a confirmar la separación central de C3:

- perder un compañero puede aumentar o recomputar la importancia estructural marginal de quienes sobreviven;
- esa pérdida no reescribe artificialmente HP, PP ni status de esos supervivientes;
- el miembro KO sigue representado operacionalmente;
- no recibe un `structural_value_bp` falso.

El número 29 no debe compararse literalmente con los 36 cambios registrados en C3f-f como si fuera una regresión: ambas suites usan contextos de probe distintos para ese contador agregado. La comprobación relevante es la paridad directa C3f-h dentro de sus mismos KO probes, y esa paridad es **0 mismatches**.

#### Pareto y trade-offs reproducidos en producción

C3f-h vuelve a obtener exactamente sobre la muestra:

- pair comparisons: **1920**;
- Pareto dominance pairs: **519**;
- incomparable pairs: **1401**;
- `structural_higher_operational_lower_pairs`: **1379**.

La producción conserva por tanto la misma geometría conceptual que C3f-f: la mayoría de comparaciones no admiten un ganador total sin aportar una preferencia externa.

No se selecciona ni se autoriza:

- `combined_score`;
- `combined_score_bp`;
- `ranking_score`;
- `best_member_id`;
- scalar global `operational_readiness_bp`.

#### Attrition y comportamiento

`attrition_excluded_from_immediate_pareto = true`.

La evidencia residual continúa fuera del vector inmediato, porque incorporarla requiere un horizonte temporal explícito.

Además:

`consumer_behavior_integration_authorized = false`

C3f-h certifica datos y forma de interfaz; no autoriza que un brain tome decisiones con ella todavía.

#### Determinismo y serialización

Los checks C3f-h confirman:

- reporte determinista;
- JSON serializable;
- orden de entrada irrelevante;
- ausencia recursiva de claves prohibidas.

#### Certificación técnica corregida

SHA técnico:

`7f37fb73c6044207cf47377f2f675edadba2e64b`

Resultado sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **547 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

#### Certificación humana tree-identical

SHA humano C3f-h:

`3c8850ab0eb9aacf07aab00155ff97452b6e4690`

Parent directo:

`73094431fdf8e481807592d966de9554df94f2e8`

Árbol:

`f67f25495310e30a3191b7d31493505ad1c1737c`

Sobre ese SHA exacto se reproduce:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **547 PASS / 0 FAIL**;
- reporte C3f-h con todos los mismatch counters críticos en 0;
- Godot general: SUCCESS;
- DATA V3: SUCCESS;
- PR #105: OPEN / unmerged;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

C3f-h queda **CERTIFICADO**.

#### Conclusión

C3f-h demuestra que `TrainerRosterComponentFirstContract` no solo reproduce sintéticamente el contrato candidato: también lo mantiene sobre DATA V3 real, en rosters degradados, reordenamientos y KO.

La superficie component-first puede considerarse una **fuente pasiva de hechos certificada**.

Lo que todavía NO está demostrado es una política general para convertir esos hechos en una elección única. La evidencia de 1401 pares incomparables y 1379 trade-offs refuerza precisamente que imponer ahora un scalar global sería inventar preferencias.

#### Siguiente microtranche autorizada — C3f-i

**C3f-i — auditoría test-only de una interfaz Pareto/frontier pasiva sobre el contrato de producción.**

Objetivo: comprobar si un consumidor puede reducir alternativas claramente dominadas sin convertir la frontera restante en ranking ni introducir pesos ocultos.

C3f-i seguirá siendo TEST/AUDIT-ONLY y no modificará producción.

Debe como mínimo:

- consumir únicamente `TrainerRosterComponentFirstContract`;
- definir de forma explícita qué dimensiones inmediatas participan en dominancia;
- mantener attrition fuera salvo horizonte explícito, que no se autoriza en esta tranche;
- producir conjunto de IDs no dominados, no `best_member_id`;
- demostrar invariancia al orden;
- demostrar que añadir una alternativa dominada no cambia la frontera válida;
- demostrar que una alternativa incomparable se conserva;
- comprobar KO y availability;
- comprobar monotonicidad de dominancia por componente;
- auditar DATA V3 real sobre el mismo muestreo determinista;
- medir tamaños de frontier, empates y casos totalmente dominados;
- exigir determinismo y JSON;
- prohibir scalar, pesos, TrainerProfile, rival, beliefs, RNG y campaign policy.

C3f-i **NO** autoriza todavía:

- clase de producción nueva;
- consumidor conductual;
- switching/search;
- modificación de brains;
- `best_member_id`;
- ranking total;
- `combined_score`;
- `operational_readiness_bp` agregado;
- recovery/replacement;
- `permadeath_loss_cost_bp` definitivo;
- FASE34;
- merge de PR #105.

Solo si C3f-i demuestra una frontier semánticamente estable deberá decidirse en otro checkpoint si esa operación puramente parcial puede migrarse a una helper de producción pasiva.


### 26.30 C3f-i — auditoría Pareto/frontier pasiva sobre contrato component-first

Estado: **CERRADO / CERTIFICADO**.

Baseline documental de entrada:

`5e520e39b597670c839247f0028d2a36b6031eb9`

Ese baseline correspondía a C3f-h + 26.29, con `TrainerRosterComponentFirstContract` ya certificado como fuente pasiva de hechos sobre DATA V3 real, pero sin interfaz de selección ni consumidor conductual.

#### Objetivo

C3f-i debía responder una pregunta muy concreta antes de permitir cualquier port adicional a producción:

> ¿Puede una operación Pareto reducir alternativas claramente peores usando únicamente componentes certificados, sin convertirse de forma encubierta en ranking o policy?

La tranche fue estrictamente **TEST/AUDIT-ONLY**.

No se modificó producción.

#### Scope neto

Frente a 26.29, C3f-i modifica exactamente:

1. nueva suite `tests/trainer_ai/trainer_roster_component_first_pareto_frontier_audit_test_suite.gd`;
2. una sustitución en `tests/trainer_ai/trainer_team_composition_test_runner.gd`.

Diff técnico:

- suite C3f-i: +398 líneas;
- runner: +1 / -1;
- cero producción;
- cero docs dentro del checkpoint técnico;
- cero workflows temporales.

#### Semántica de dominancia reutilizada

C3f-i no inventa una nueva regla. Reutiliza exactamente la semántica auditada en C3f-f/C3f-h.

Vector inmediato, en este orden conceptual:

1. `structural_value_bp`;
2. `hp_state_bp`;
3. `route_retention_bp`;
4. `immediate_status_action_bp`.

A domina B si y solo si:

- A es mayor o igual que B en las cuatro dimensiones;
- A es estrictamente mayor que B en al menos una.

No participan:

- attrition;
- held item;
- `TrainerProfile`;
- rival/opponent data;
- beliefs;
- RNG;
- campaign policy;
- scalar agregado de readiness;
- pesos;
- `combined_score`.

La frontier se define únicamente como el conjunto de `instance_id` supervivientes y disponibles que **no están dominados por ningún otro miembro elegible**.

La salida se ordena léxicamente para estabilidad y no representa preferencia.

#### Audit ID

`c3f_i_component_first_pareto_frontier_audit_v1`

#### Muestreo real-data

Se reutiliza la geometría certificada de C3f-h:

- especies elegibles: **1021**;
- rosters muestreados: **128**;
- miembros elegibles inspeccionados: **768**;
- miembros por roster: **6**;
- sample stride: **8**;
- KO probes: **24**.

El productor consumido es la clase real de producción:

`TrainerRosterComponentFirstContract`

model id:

`trainer_roster_component_first_contract_v1`

#### Geometría Pareto reproducida

C3f-i reproduce exactamente la geometría pareada ya vista en C3f-h:

- pair comparisons: **1920**;
- Pareto dominance pairs: **519**;
- incomparable pairs: **1401**.

Esto confirma que la nueva operación frontier no redefine dominancia para obtener una distribución más conveniente.

#### Resultado de la frontier real-data

Sobre 768 ocurrencias de miembros:

- miembros no dominados / frontier: **424**;
- miembros dominados eliminables: **344**.

Por rosters:

- rosters con al menos una reducción: **124 / 128**;
- rosters donde los 6 siguen no dominados: **4 / 128**;
- rosters con frontier de un solo miembro: **12 / 128**;
- rosters con frontier vacía: **0**.

Tamaño mínimo:

`1`

Tamaño máximo:

`6`

Suma de tamaños de frontier:

`424`

Media:

`424 / 128 = 3.3125`

Histograma exacto:

- tamaño 1: **12** rosters;
- tamaño 2: **22**;
- tamaño 3: **34**;
- tamaño 4: **38**;
- tamaño 5: **18**;
- tamaño 6: **4**.

Por tanto:

- **116 / 128 rosters** conservan más de una alternativa no dominada;
- aproximadamente el **90.6 %** de los rosters siguen necesitando una preferencia o reasoning externo para elegir entre la frontier;
- la operación elimina **344 / 768 ≈ 44.8 %** de las ocurrencias como claramente dominadas, sin resolver artificialmente el resto.

Esta es la conclusión central de C3f-i:

> **Pareto es útil como primitive de pruning, no como decision function.**

#### Ejemplos reales de frontier

Algunos ejemplos del reporte:

- anchor 0: `magnemite`;
- anchor 8: `alcremie`, `cutiefly`, `raging_bolt`;
- anchor 16: `decidueye`, `grimer`, `marowak`, `tapu_lele`;
- anchor 24: `archaludon`, `meditite`, `rellor`, `terapagos`;
- anchor 32: `dipplin`, `mesprit`, `tinkatink`;
- anchor 40: `heatran`, `togepi`;
- anchor 48: `drapion`, `hitmonlee`, `minun`, `toucannon`;
- anchor 56: `beautifly`, `drowzee`, `morpeko`, `sandygast`, `trevenant`.

Estos ejemplos muestran que una frontier puede variar desde una solución completamente dominadora hasta cinco alternativas con trade-offs irreducibles bajo las dimensiones actuales.

#### Invariantes sintéticas

C3f-i certifica además:

1. añadir una alternativa dominada no modifica la frontier válida;
2. añadir una alternativa incomparable la conserva en frontier;
3. dos vectores numéricamente iguales no se dominan entre sí y ambos sobreviven;
4. una mejora componente-a-componente es monotónica y domina al vector inferior;
5. un trade-off cruzado permanece incomparable;
6. modificar solo attrition o held-item evidence no cambia el vector Pareto inmediato ni crea dominancia.

En la muestra real no aparecieron pares con vector numérico exactamente idéntico:

`identical_vector_pairs = 0`

La semántica de empate queda, no obstante, cubierta sintéticamente.

#### Orden y determinismo

Resultados:

- `reorder_frontier_mismatches = 0`;
- `frontier_order_mismatches = 0`;
- reporte determinista: PASS;
- JSON serializable: PASS.

La frontier no depende del orden original de `own_party`.

#### KO

Sobre 24 probes:

- `ko_contract_missing_cases = 0`;
- `ko_frontier_inclusions = 0`;
- `ko_empty_frontier_cases = 0`.

Es decir:

- el KO no desaparece del contrato de producción;
- no participa como candidato elegible en la frontier;
- quitarlo de la frontier no destruye el conjunto válido de supervivientes.

#### Prohibiciones verificadas

C3f-i escanea recursivamente el propio reporte y la superficie de frontier.

Resultado:

- `forbidden_frontier_key_cases = 0`;
- `forbidden_context_key_cases = 0`.

No aparecen:

- `best_member_id`;
- `ranking_score`;
- `combined_score`;
- scalar agregado oculto;
- rival/opponent context;
- belief context;
- campaign policy.

Además:

- `behavior_integration_authorized = false`;
- `frontier_production_authorized = false` dentro de la propia tranche audit-only.

#### Certificación técnica

SHA técnico C3f-i:

`22fd15da222e67e74b739337cd808df68f55e4f5`

Árbol:

`dde7727879a1189ba2a8d1e0418b64225e881d78`

Resultado exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **567 PASS / 0 FAIL**;
- Godot 4.7: SUCCESS;
- DATA Foundation V3: SUCCESS.

#### Certificación humana tree-identical

SHA humano C3f-i:

`6b1455b7510224ec427a242f20a3ba944f2c568a`

Parent directo:

`5e520e39b597670c839247f0028d2a36b6031eb9`

Árbol:

`dde7727879a1189ba2a8d1e0418b64225e881d78`

Sobre este SHA exacto se reproduce:

- **18/18 SUCCESS**;
- FASE33: **567 PASS / 0 FAIL**;
- pair geometry: **519 dominance / 1401 incomparable**;
- frontier: **424 no dominados / 344 dominados**;
- histogram: `1:12 · 2:22 · 3:34 · 4:38 · 5:18 · 6:4`;
- reorder mismatches: 0;
- KO frontier inclusions: 0;
- forbidden keys/context: 0.

Invariantes externas tras la certificación:

- PR #105: OPEN / unmerged;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

C3f-i queda **CERTIFICADO**.

#### Conclusión arquitectónica

La evidencia autoriza una distinción importante:

- **sí** existe una operación parcial, weight-free y determinista que puede podar alternativas objetivamente dominadas;
- **no** existe todavía una política certificada para ordenar o escoger entre las alternativas no dominadas.

Mover la frontier a producción no equivale a mover una decisión a producción si la helper se mantiene estrictamente como transformación pasiva del contrato.

#### Siguiente microtranche autorizada — C3f-j

**C3f-j — port pasivo de la operación Pareto/frontier a producción, con paridad exacta contra C3f-i.**

Esta autorización es estrecha.

C3f-j puede añadir una única helper/clase pasiva de producción, por ejemplo:

`TrainerRosterParetoFrontier`

Debe:

- consumir solamente un contrato ya producido por `TrainerRosterComponentFirstContract`;
- usar exactamente las cuatro dimensiones certificadas por C3f-i;
- mantener la misma semántica `>= todas + > al menos una`;
- considerar elegibles solo estados `surviving` con structural/operational available;
- excluir KO de la frontier sin borrar su estado del contrato original;
- devolver IDs no dominados ordenados léxicamente;
- puede devolver también IDs dominados y counts para auditabilidad, siempre sin ranking;
- tener `model_id` explícito;
- ser deterministic y JSON serializable;
- no mutar input;
- fallar cerrado ante contrato inválido;
- tener tests de paridad exacta contra la helper audit-only C3f-i;
- mantener attrition e item fuera del vector inmediato.

C3f-j **NO** puede:

- elegir un `best_member_id`;
- devolver ranking total;
- añadir pesos;
- crear `combined_score`;
- agregar `operational_readiness_bp`;
- usar TrainerProfile;
- leer rival/opponent/beliefs;
- leer RNG;
- leer campaign policy;
- modificar `TrainerRosterComponentFirstContract` para insertar conducta;
- conectarse a switching/search;
- modificar brains;
- decidir cambio de Pokémon;
- resolver replacement/recovery;
- cerrar `permadeath_loss_cost_bp`;
- abrir FASE34;
- mergear PR #105.

Después de C3f-j será obligatorio un checkpoint separado antes de cualquier consumidor conductual. Idealmente, la helper de producción deberá pasar primero una auditoría real-data propia que reproduzca C3f-i antes de decidir si alguna capa de reasoning puede consumirla.


### 26.31 C3f-j — port pasivo de Pareto/frontier a producción, sin consumidor conductual

C3f-j queda cerrado como **productionization pasiva** de la operación Pareto/frontier certificada en C3f-i.

El objetivo de esta microtranche no era decidir qué miembro del roster usar, cambiar o preservar. El objetivo era mucho más estrecho: demostrar que la geometría Pareto ya auditada podía existir como helper real de producción sin introducir por accidente un ranking, un scalar combinado, un tie-break oculto ni una política de campaña.

#### Baseline

C3f-j parte exactamente del checkpoint documental 26.30:

`d7566e0ef16f329ae9ddc07dd5405440948e1574`

Ese baseline estaba certificado con:

- `18/18 SUCCESS`;
- FASE33 `567 PASS / 0 FAIL`;
- Godot general verde;
- DATA V3 verde;
- PR #105 abierto y sin merge;
- `main` inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Alcance técnico exacto

El diff técnico de C3f-j respecto a `d7566e...` quedó limitado a tres archivos:

1. `modules/trainer_ai/trainer_roster_pareto_frontier.gd`
2. `tests/trainer_ai/trainer_roster_pareto_frontier_production_test_suite.gd`
3. `tests/trainer_ai/trainer_team_composition_test_runner.gd`

No se modificaron:

- brains;
- switching;
- search;
- campaign integration;
- `TrainerProfile`;
- FASE34;
- documentación durante el tramo técnico;
- workflows permanentes.

El control de alcance registró aproximadamente:

- helper de producción: `+146` líneas;
- suite de certificación/audit: `+421` líneas;
- runner: `+1 / -1`.

#### Helper productiva

Se añadió:

`TrainerRosterParetoFrontier`

Archivo:

`modules/trainer_ai/trainer_roster_pareto_frontier.gd`

Modelo:

`trainer_roster_pareto_frontier_v1`

Fuente contractual obligatoria:

`trainer_roster_component_first_contract_v1`

API pública de esta tranche:

`evaluate(contract: Dictionary) -> Dictionary`

La helper consume solamente un contrato ya producido por `TrainerRosterComponentFirstContract`.

No reconstruye observaciones, no lee battle memory y no recibe contexto de campaña.

#### Vector Pareto congelado

C3f-j usa exactamente las cuatro dimensiones ya certificadas por C3f-i:

1. `structural_value_bp`
2. `hp_state_bp`
3. `route_retention_bp`
4. `immediate_status_action_bp`

No se añadió una quinta dimensión.

No entran en el vector inmediato:

- attrition;
- held item;
- TrainerProfile;
- rival/opponent;
- beliefs;
- RNG;
- campaign snapshot;
- replacement policy;
- recovery policy;
- permadeath policy.

La dominancia sigue siendo exactamente:

- A debe ser `>=` B en las cuatro dimensiones;
- y A debe ser `>` B en al menos una.

Por tanto, dos miembros con tradeoff real siguen siendo incomparables.

Dos vectores idénticos tampoco se rompen por orden léxico ni por instance id.

#### Elegibilidad

La helper solo introduce en el cálculo Pareto estados que cumplen simultáneamente:

- `availability_state == "surviving"`;
- structural disponible;
- operational disponible;
- los cuatro componentes requeridos presentes como enteros.

Los KO permanecen en el contrato de origen, pero quedan fuera de la frontier y del conjunto dominated calculado sobre candidatos elegibles.

La helper no muta el contrato original.

#### Fail-closed

C3f-j endurece explícitamente la entrada antes de producir una frontier.

Devuelve resultado vacío/no válido ante, entre otros:

- `model_id` de contrato incorrecto;
- `member_states` no Array;
- `member_count` ausente/no entero/incoherente;
- member state no Dictionary;
- instance id vacío;
- instance id duplicado;
- availability state desconocido;
- structural/operational con forma inválida;
- componente requerido ausente o no entero en un candidato que declara disponibilidad.

No devuelve una frontier parcial fingiendo que un contrato roto era válido.

#### Output productivo

El resultado expone solamente una partición pasiva y trazabilidad:

- `model_id`;
- `source_contract_model_id`;
- `frontier_dimensions`;
- `input_contract_valid`;
- `eligible_member_count`;
- `frontier_count`;
- `dominated_count`;
- `frontier_instance_ids`;
- `dominated_instance_ids`;
- `attrition_excluded_from_immediate_frontier`;
- `held_item_excluded_from_immediate_frontier`.

Los IDs de frontier y dominated salen ordenados léxicamente para determinismo/auditabilidad.

Ese orden **no tiene semántica de preferencia**.

C3f-j no expone:

- `best_member_id`;
- `selected_member_id`;
- ranking;
- `combined_score`;
- pesos;
- scalar de operational readiness;
- decisión de switching;
- autorización de conducta.

#### Suite de producción

Se añadió:

`TrainerRosterParetoFrontierProductionTestSuite`

La suite hereda C3f-i, por lo que conserva toda la barrera previa y añade checks específicos del port productivo.

El total FASE33 subió de:

`567 PASS / 0 FAIL`

a:

`601 PASS / 0 FAIL`

#### Invariantes sintéticas certificadas

Entre otros checks, C3f-j demuestra:

- model id correcto;
- source contract model id correcto;
- dimensiones idénticas a C3f-i;
- contrato válido aceptado;
- paridad exacta con la helper audit-only en un caso sintético;
- frontier/dominated forman la partición esperada de elegibles;
- input no mutado;
- invariancia ante reorder del input;
- outputs ordenados léxicamente;
- vectores iguales conservan ambos miembros;
- tradeoff structural/operational conserva ambos miembros;
- cambios solo en attrition/item no cambian la frontier inmediata;
- KO queda fuera sin borrarse del contrato;
- survivor con capa no disponible no recibe valores fabricados;
- modelo incorrecto falla cerrado;
- member count incorrecto falla cerrado;
- IDs duplicados fallan cerrado;
- componente faltante falla cerrado;
- determinismo;
- JSON serializable;
- ausencia de scalar/ranking/contexto prohibido;
- ausencia de selección conductual.

#### Auditoría real-data productiva

Audit id:

`c3f_j_pareto_frontier_production_real_data_v1`

La auditoría ejecuta la helper de producción sobre el mismo esquema real-data de C3f-i y compara roster por roster contra la operación audit-only certificada.

Cobertura:

- especies elegibles: `1021`;
- rosters muestreados: `128`;
- member states elegibles: `768`;
- stride: `8`;
- probes KO: `24`.

Resultado exacto:

- `frontier_parity_mismatches = 0`;
- `dominated_partition_mismatches = 0`;
- `model_id_mismatches = 0`;
- `source_contract_model_id_mismatches = 0`;
- `dimension_mismatches = 0`;
- `reorder_mismatches = 0`;
- `contract_mutation_cases = 0`;
- `ko_frontier_parity_mismatches = 0`;
- `ko_frontier_inclusions = 0`;
- `forbidden_output_key_cases = 0`;
- `forbidden_context_key_cases = 0`.

La distribución productiva reproduce exactamente C3f-i:

- frontier member occurrences: `424`;
- dominated member occurrences: `344`;
- rosters con reducción: `124 / 128`;
- histograma de tamaño de frontier:
  - `1 -> 12`;
  - `2 -> 22`;
  - `3 -> 34`;
  - `4 -> 38`;
  - `5 -> 18`;
  - `6 -> 4`.

La productionization, por tanto, no cambió la geometría certificada.

#### Certificación técnica

SHA técnico final:

`a49c1239a1c4af0d372f346634cbc35f0b906ba3`

Sobre ese SHA:

- `18/18 SUCCESS`;
- FASE33 `601 PASS / 0 FAIL`;
- Godot general verde;
- DATA V3 verde;
- reporte C3f-j con todos los mismatches críticos en cero.

#### Checkpoint humano tree-identical

Se creó un commit humano con el mismo árbol técnico y parent directo del baseline 26.30:

`c844d3cb88aadbb572696bd2a455a02040cc5d5d`

El objetivo era excluir de la historia certificada los commits técnicos intermedios de staging y certificar exactamente el árbol ya validado.

La segunda ejecución reprodujo:

- `18/18 SUCCESS`;
- FASE33 `601 PASS / 0 FAIL`;
- `frontier_parity_mismatches = 0`;
- `dominated_partition_mismatches = 0`;
- `reorder_mismatches = 0`;
- `contract_mutation_cases = 0`;
- `ko_frontier_parity_mismatches = 0`;
- `ko_frontier_inclusions = 0`;
- mismo `424 / 344`;
- mismo `124 / 128`;
- mismo histograma `12 / 22 / 34 / 38 / 18 / 4`.

#### Invariantes externas

Tras la certificación humana C3f-j:

- PR #105 sigue `OPEN`;
- PR #105 sigue `merged = false`;
- head de PR #105: `c844d3cb88aadbb572696bd2a455a02040cc5d5d`;
- base: `main`;
- `main` sigue exactamente en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Conclusión C3f-j

La operación Pareto/frontier ya puede considerarse una **primitive productiva pasiva certificada**.

Eso NO significa que el Trainer AI ya tenga permiso para usarla para cambiar de Pokémon, buscar acciones o escoger un miembro.

La helper sabe responder:

> ¿qué candidatos no están estrictamente dominados dentro de este vector component-first?

No sabe responder:

> ¿qué candidato debo elegir?

La diferencia sigue siendo deliberada.

En 116 de las 128 rosters auditadas en C3f-i la frontier conserva más de una alternativa. Por tanto, convertir `frontier_instance_ids[0]` en una selección sería introducir silenciosamente un tie-break léxico, no una decisión estratégica certificada.

C3f-j queda cerrado sin esa contaminación.

#### Siguiente microtranche autorizada — C3f-k

**C3f-k — auditoría test-only de semántica de consumo de frontier, todavía sin selección ni integración conductual.**

Antes de conectar la primitive Pareto a cualquier brain, switching o search, C3f-k debe estudiar qué puede significar de forma segura “consumir” una frontier sin transformarla accidentalmente en ranking.

C3f-k queda limitado a tests/audit.

Debe comprobar, como mínimo:

- join lossless de `frontier_instance_ids` contra `TrainerRosterComponentFirstContract` por `instance_id`;
- cada frontier member conserva accesibles por separado structural y operational components;
- los dominated members siguen auditables en el contrato aunque no sean candidatos de frontier;
- `frontier_count == 1` significa únicamente “único no dominado en este vector”, no “acción universalmente correcta”;
- `frontier_count > 1` mantiene explícitamente el tradeoff sin resolver;
- el orden léxico no puede actuar como tie-break;
- item y attrition permanecen side evidence y no desempates ocultos;
- un KO/removal obliga a recomputar contrato/frontier y no a reutilizar una selección anterior;
- ningún output puede exponer winner/ranking/combined scalar;
- no puede leer TrainerProfile/rival/beliefs/RNG/campaign policy;
- no puede modificar brains;
- no puede tocar switching/search;
- no puede decidir acciones;
- FASE34 sigue cerrada.

C3f-k no está autorizado a añadir todavía una clase productiva consumidora.

Cualquier futura integración conductual requerirá un checkpoint documental separado después de C3f-k y una autorización explícita de alcance.


### 26.32 C3f-k — semántica de consumo de frontier sin selección conductual

Estado: **CERRADO / DOBLEMENTE CERTIFICADO**.

C3f-k ejecuta la barrera exigida por 26.31 antes de permitir cualquier consumidor real de `TrainerRosterParetoFrontier`. La tranche permanece estrictamente **TEST/AUDIT-ONLY**: estudia qué significa consumir una frontier sin convertir su orden, side evidence o cardinalidad en una política de selección encubierta.

#### Baseline y SHAs

Baseline documental 26.31:

`9b75d2bb7c81f0a2aad6adfe2013b09713473405`

SHA técnico C3f-k:

`2892c93e2b30452c3cd878d53f556ecea755c4b3`

SHA humano tree-identical C3f-k:

`eeb4b0aa04176c77b683e4262479a356d61bbe82`

El checkpoint humano tiene como parent directo el baseline documental 26.31 y reproduce el árbol técnico certificado de C3f-k.

#### Alcance neto

C3f-k modifica únicamente tests/audit:

- `tests/trainer_ai/trainer_roster_pareto_frontier_consumption_audit_test_suite.gd`: **+401 líneas**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**.

No se modificaron:

- producción;
- brains;
- switching;
- search/planning;
- campaign integration;
- recovery/replacement;
- FASE34.

Audit ID:

`c3f_k_pareto_frontier_consumption_semantics_audit_v1`

Modelo de frontier productiva auditado:

`trainer_roster_pareto_frontier_v1`

Contrato fuente:

`trainer_roster_component_first_contract_v1`

#### Join lossless y conservación de componentes

La auditoría vuelve a unir los IDs de frontier contra `TrainerRosterComponentFirstContract` por `instance_id`, nunca por posición.

Cobertura real-data:

- especies elegibles: `1021`;
- rosters muestreados: `128`;
- estados elegibles: `768`;
- stride: `8`;
- frontier member occurrences: `424`;
- dominated member occurrences: `344`.

Resultado:

- `frontier_join_missing_cases = 0`;
- `frontier_join_duplicate_cases = 0`;
- `dominated_join_missing_cases = 0`;
- `dominated_join_duplicate_cases = 0`;
- `component_preservation_mismatches = 0`.

Por tanto, consumir la frontier no borra la evidencia estructural ni operacional de sus miembros, y los dominated continúan siendo auditables en el contrato fuente.

#### Frontier única NO equivale a acción

Distribución observada:

- `single_frontier_rosters = 12`;
- `multiple_frontier_rosters = 116`.

La auditoría congela expresamente:

`single_frontier_is_action_decision = false`

Una frontier de un solo miembro significa únicamente:

> único no dominado dentro del vector component-first actual.

No significa:

- mejor switch universal;
- miembro que deba entrar ahora;
- sacrificio correcto;
- acción correcta independientemente del matchup;
- autorización para saltarse legalidad, táctica o policy contextual.

#### Orden léxico — solo determinismo, nunca preferencia

Los IDs de frontier permanecen ordenados léxicamente para estabilidad y auditabilidad, pero C3f-k prueba explícitamente que ese orden no puede actuar como desempate.

Resultado:

`lexical_order_used_as_tiebreak = false`

La suite incluye renombrado adversarial de IDs y demuestra que cambiar únicamente los nombres puede cambiar qué vector aparece primero en el array ordenado sin cambiar la geometría estratégica.

Consecuencia canónica:

**`frontier_instance_ids[0]` NO puede interpretarse como candidato preferido.**

Cualquier consumidor que haga eso introduciría una policy léxica accidental y violaría el contrato certificado.

#### Attrition y held item — side evidence, no tiebreak oculto

C3f-k mantiene attrition e item fuera del vector Pareto inmediato y comprueba que tampoco puedan reaparecer silenciosamente como desempate posterior.

Resultado:

`side_evidence_used_as_tiebreak = false`

Cambiar únicamente evidencia de attrition o disponibilidad de held item no autoriza a reordenar la frontier ni a declarar un ganador.

Esas señales siguen disponibles para una futura policy que declare de forma explícita horizonte y semántica, pero no son preferencias implícitas de C3f-k.

#### KO/removal invalida la frontier anterior

Se ejecutaron `24` probes de KO/removal.

Resultado:

- `ko_probe_cases = 24`;
- `stale_frontier_invalidated_cases = 24`;
- `ko_frontier_inclusions = 0`;
- `ko_rejoin_missing_cases = 0`;
- `ko_rejoin_duplicate_cases = 0`.

Semántica congelada:

1. cambia el roster superviviente;
2. se recomputa `TrainerRosterComponentFirstContract`;
3. se recomputa `TrainerRosterParetoFrontier`;
4. no se reutiliza una frontier o selección previa como si siguiera válida.

Esto es obligatorio porque una baja puede cambiar el `structural_value_bp` marginal de los supervivientes aunque sus componentes operacionales propios no hayan cambiado.

#### Contexto y outputs prohibidos

Resultado:

- `forbidden_output_key_cases = 0`;
- `forbidden_context_key_cases = 0`.

C3f-k no produce ni consume:

- `best_member_id`;
- `selected_member_id`;
- ranking total;
- `combined_score`;
- scalar global de readiness;
- TrainerProfile como criterio objetivo;
- rival/opponent data;
- beliefs;
- RNG;
- hidden bracket;
- recovery policy;
- replacement policy;
- campaign policy;
- switching/search score.

Y mantiene explícitamente:

`behavior_integration_authorized = false`

#### Certificación técnica

Sobre:

`2892c93e2b30452c3cd878d53f556ecea755c4b3`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **624 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- todos los contadores críticos de joins, KO, tiebreaks y contexto prohibido: `0` donde corresponde.

#### Certificación humana tree-identical

Sobre:

`eeb4b0aa04176c77b683e4262479a356d61bbe82`

se reprodujo la segunda matriz completa:

- **18/18 workflows SUCCESS**;
- FASE33: **624 PASS / 0 FAIL**;
- mismo audit C3f-k y mismas invariantes materiales;
- Godot general: SUCCESS;
- DATA V3: SUCCESS.

La cifra `436 PASS / 0 FAIL` observada en `Trainer Loadouts Tests` pertenece a FASE32 y no sustituye al gate C3f-k. El contador canónico de esta tranche es FASE33 **624 PASS / 0 FAIL**.

#### Invariantes externas

Tras la certificación humana:

- PR #105: **OPEN**;
- `merged_at = null`;
- head: `eeb4b0aa04176c77b683e4262479a356d61bbe82` antes de este append documental;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, sin movimiento.

PR #105 continúa siendo temporal y **NO debe mergearse**.

#### Conclusión C3f-k

C3f-k cierra la semántica segura de consumo de una frontier pasiva:

- frontier puede podar dominados;
- los componentes siguen accesibles por separado;
- dominated sigue auditable;
- frontier única no es una acción;
- frontier múltiple no se resuelve por orden;
- side evidence no es desempate oculto;
- cambios de roster invalidan la frontier previa;
- no existe todavía una policy conductual autorizada.

La primitive Pareto está preparada para ser **una entrada** de reasoning futuro, no para convertirse en decision function por sí sola.

#### Siguiente microtranche autorizada — C3f-l

Antes de tocar un brain, switching o search, abrir un checkpoint separado:

**C3f-l — auditoría/diseño de la frontera del primer consumidor conductual.**

C3f-l debe decidir de forma explícita y auditable:

- qué problema concreto será el primer consumidor;
- qué información táctica legítima adicional necesita además de la frontier;
- en qué condiciones la frontier puede usarse solo como pruning y cuándo no;
- qué ocurre con frontier de 1 frente a frontier de varios miembros;
- cómo impedir que el orden léxico, attrition o item se conviertan en tiebreaks accidentales;
- qué evento obliga a recomputar contrato/frontier;
- qué invariantes debe cumplir antes de autorizar cualquier cambio de conducta.

C3f-l empieza como **documental/audit-only**. No debe integrar todavía nada mientras no se congele el contrato del consumidor concreto.

Sigue prohibido hasta una autorización posterior explícita:

- conectar directamente `frontier_instance_ids[0]` a switching;
- modificar search/planning;
- modificar brains;
- inventar `between_battle_recovery_policy` o `replacement_policy`;
- definir `permadeath_loss_cost_bp` definitivo;
- iniciar FASE34;
- mergear PR #105.


### 26.33 C3f-l — frontera del primer consumidor conductual: Pareto NO puede podar switching antes del matchup

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / TEST-AUDIT-ONLY**.

C3f-l ejecuta la barrera abierta en 26.32: antes de conectar `TrainerRosterParetoFrontier` a un brain, switching o search, había que identificar el primer consumidor plausible y comprobar qué semántica podía aceptar sin convertir una primitive rival-agnostic en una policy conductual falsa.

El primer consumidor auditado es:

`TrainerStrategicSwitchEvaluatorV2`

model id:

`strategic_switch_expected_matchup_v2`

La conclusión es negativa pero decisiva:

> **la frontier Pareto component-first NO es un pre-filtro seguro de candidatos de switching, ni siquiera cuando contiene un único miembro.**

#### Baseline y SHAs certificados

Baseline documental 26.32:

`563a1809e84fe4526222adfd957c218e8c169f66`

SHA técnico limpio C3f-l:

`79dfa671621f653cb4dedd2800eb2cdd2585a898`

SHA humano tree-identical C3f-l:

`09d7473d05c6a056536af4dbc7e18a2f7a0f1edf`

Árbol técnico/humano común:

`b5892437bb3946c0bcdfa9c7487956d6895ac747`

Ambos checkpoints tienen como parent directo el baseline documental 26.32. Los commits de staging quedan excluidos de la historia certificada.

#### Alcance neto limpio

Frente a 26.32, C3f-l cambia únicamente:

- nueva suite `tests/trainer_ai/trainer_roster_frontier_first_consumer_boundary_audit_test_suite.gd`: **+244 líneas**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+2 / -2**.

No cambia:

- producción;
- `TrainerStrategicSwitchEvaluatorV2`;
- brains;
- switching behavior;
- search/planning;
- campaign policy;
- recovery/replacement;
- FASE34.

Audit ID:

`c3f_l_first_behavior_consumer_boundary_audit_v1`

#### Por qué switching es una frontera distinta

La frontier C3f-k es deliberadamente rival-agnostic y usa solo el vector inmediato component-first:

1. `structural_value_bp`;
2. `hp_state_bp`;
3. `route_retention_bp`;
4. `immediate_status_action_bp`.

No conoce al rival actual, sus tipos, movimientos públicos, amenaza ni matchup.

`TrainerStrategicSwitchEvaluatorV2`, en cambio, evalúa evidencia contextual de la batalla, incluyendo capacidad ofensiva contra el rival activo y amenaza pública recibida por cada candidato.

Por tanto, dominancia en el espacio component-first no implica dominancia en el problema táctico de switching.

#### Contraejemplo adversarial certificado

C3f-l construye un contrato component-first válido con tres miembros:

- `boundary_active`: vector `5000 / 5000 / 5000 / 5000`;
- `frontier_water`: vector `9000 / 9000 / 9000 / 9000`;
- `dominated_grass`: vector `7000 / 7000 / 7000 / 7000`.

Así, `frontier_water` domina estrictamente a `dominated_grass` en las cuatro dimensiones C3f-k.

Resultado Pareto:

- `frontier_count = 1`;
- `frontier_instance_ids = ["frontier_water"]`;
- `dominated_instance_ids` contiene `dominated_grass`.

Después se presenta un rival Water real dentro del fixture FASE31 y se evalúan ambos switches con `TrainerStrategicSwitchEvaluatorV2` sin modificarlo.

Resultado táctico:

- score de switch de `frontier_water`: **2200**;
- score de switch de `dominated_grass`: **5800**;
- ofensiva del Water frontier contra el rival Water: **3692 bp**;
- ofensiva del Grass dominado contra el rival Water: **8076 bp**;
- amenaza pública recibida por Water frontier: **10200 bp**;
- amenaza pública recibida por Grass dominado: **2500 bp**.

El candidato eliminado por un supuesto pre-filtro Pareto sería precisamente el mejor counter táctico del escenario.

Por tanto:

`dominated_counter_outscores_frontier_member = true`

#### Semántica congelada

C3f-l certifica expresamente:

`hard_frontier_pruning_safe_for_switching = false`

`frontier_selection_authorized = false`

`frontier_score_bonus_authorized = false`

`behavior_integration_authorized = false`

La frontier tampoco puede convertirse en un bonus silencioso de score. Hacerlo introduciría una preferencia nueva no demostrada y volvería a mezclar valor roster-state con matchup táctico.

Incluso cuando:

`frontier_count == 1`

ese miembro es solo el único no dominado bajo el vector component-first actual. **No es automáticamente el mejor switch.**

#### Orden obligatorio de razonamiento

C3f-l congela:

`required_ordering = legal_and_contextual_switch_evidence_before_any_nonbinding_frontier_use`

Interpretación segura:

`frontier_is_roster_state_evidence_not_a_switch_candidate_filter`

Esto significa:

1. primero se preserva el espacio de acciones legales;
2. después se evalúa el contexto táctico pertinente al problema de switching;
3. solo después podría explorarse en otra tranche si la frontier aporta evidencia no vinculante;
4. nunca puede eliminarse un candidato únicamente porque esté dominado en el vector rival-agnostic C3f-k.

#### Checks C3f-l

La suite añade 13 comprobaciones y todas pasan:

- audit id correcto;
- consumidor real de switching identificado;
- frontier productiva certificada usada;
- frontier component-first de un solo miembro reproducida;
- counter táctico marcado como dominated component-first;
- counter dominado con mejor ofensiva contextual;
- counter dominado con menor amenaza pública;
- counter dominado con mejor score final de switching;
- hard pruning declarado inseguro;
- integración conductual sigue no autorizada;
- contexto/legalidad deben preceder a cualquier uso de frontier;
- determinismo;
- JSON serialization.

#### Reporte C3f-l canónico

```json
{
  "audit_id": "c3f_l_first_behavior_consumer_boundary_audit_v1",
  "behavior_integration_authorized": false,
  "candidate_consumer": "strategic_switching",
  "candidate_consumer_model_id": "strategic_switch_expected_matchup_v2",
  "controller_begin_ok": true,
  "controller_produced_action": true,
  "dominated_counter_offense_bp": 8076,
  "dominated_counter_outscores_frontier_member": true,
  "dominated_counter_public_threat_bp": 2500,
  "dominated_counter_switch_score": 5800,
  "dominated_instance_ids": ["boundary_active", "dominated_grass"],
  "frontier_count": 1,
  "frontier_instance_ids": ["frontier_water"],
  "frontier_member_offense_bp": 3692,
  "frontier_member_public_threat_bp": 10200,
  "frontier_member_switch_score": 2200,
  "frontier_model_id": "trainer_roster_pareto_frontier_v1",
  "frontier_score_bonus_authorized": false,
  "frontier_selection_authorized": false,
  "hard_frontier_pruning_safe_for_switching": false,
  "required_ordering": "legal_and_contextual_switch_evidence_before_any_nonbinding_frontier_use",
  "safe_interpretation": "frontier_is_roster_state_evidence_not_a_switch_candidate_filter",
  "source_contract_model_id": "trainer_roster_component_first_contract_v1",
  "switch_actions_available": true
}
```

#### Incidente de staging — no forma parte del checkpoint limpio

El primer staging de C3f-l llegó a producir **637 PASS / 0 FAIL**, pero el log contenía dos `SCRIPT ERROR` al reutilizar el fixture FASE31: su helper de catálogo intentaba emitir checks antes de que la sonda hubiera inicializado el callback heredado.

Ese SHA **NO se certificó**.

Staging inicial rechazado:

`7c911b3ed11b6c494ff23add8e75e52398365661`

La corrección fue exclusivamente test-harness: inicializar un callback no-op antes de construir el catálogo heredado. No cambió producción ni el contraejemplo.

Staging corregido:

`8838a2ab0ca61e71430dc4334165040261299a4e`

Ese staging dio 18/18 SUCCESS y 637/0 sin los errores de script. A continuación se reconstruyó exactamente su árbol como el checkpoint técnico limpio `79dfa671...`, excluyendo ambos commits de staging de la historia certificada.

#### Certificación técnica limpia

Sobre:

`79dfa671621f653cb4dedd2800eb2cdd2585a898`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **637 PASS / 0 FAIL**;
- FASE31 / Strategic Switching V2: SUCCESS;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- sin `SCRIPT ERROR` de la sonda;
- reporte C3f-l con el contraejemplo anterior.

#### Certificación humana tree-identical

Sobre:

`09d7473d05c6a056536af4dbc7e18a2f7a0f1edf`

con árbol idéntico:

`b5892437bb3946c0bcdfa9c7487956d6895ac747`

se reprodujo:

- **18/18 workflows SUCCESS**;
- FASE33: **637 PASS / 0 FAIL**;
- FASE31: SUCCESS;
- mismo reporte C3f-l;
- mismo `5800 > 2200`;
- mismo `8076 > 3692` ofensivo;
- mismo `2500 < 10200` de amenaza pública;
- Godot general: SUCCESS;
- DATA V3: SUCCESS.

C3f-l queda **DOBLEMENTE CERTIFICADO**.

#### Invariantes externas

Tras la certificación humana:

- PR #105: **OPEN**;
- `merged = false`;
- `merged_at = null`;
- head previo a este freeze documental: `09d7473d05c6a056536af4dbc7e18a2f7a0f1edf`;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, sin movimiento.

PR #105 continúa siendo temporal y **NO debe mergearse**.

#### Conclusión C3f-l

La primitive Pareto sigue siendo útil como descripción parcial del estado del roster, pero C3f-l demuestra un límite esencial:

> **dominancia roster-state rival-agnostic no equivale a dominancia táctica contra el rival actual.**

Por ello quedan prohibidos:

- filtrar `BattleAction.SWITCH` por `frontier_instance_ids` antes del evaluator;
- elegir automáticamente el único frontier member;
- bonificar score solo por pertenecer a frontier;
- penalizar score solo por quedar dominated;
- conectar `frontier_instance_ids[0]` a switching;
- modificar brains/search con esta primitive sin una nueva auditoría.

La ausencia de autorización conductual se mantiene intacta.

#### Siguiente microtranche autorizada — C3f-m

**C3f-m — shadow/read-only overlap audit entre switching real y Pareto, todavía sin cambiar conducta.**

Objetivo: medir sobre una muestra amplia de escenarios cuánto se solapan o divergen:

- el/los mejores candidatos según `TrainerStrategicSwitchEvaluatorV2`;
- los miembros de `TrainerRosterParetoFrontier`;
- los miembros component-first dominated.

C3f-m debe ser TEST/AUDIT-ONLY y no modificar scores, pruning ni brains.

Debe medir, como mínimo:

- cuántas veces el mejor switch está dentro de frontier;
- cuántas veces el mejor switch está dominated component-first;
- distribución de gaps de score;
- frontier size frente a número de switches legales;
- casos de `frontier_count == 1` donde otro switch contextual gana;
- casos donde todos los switches legales están en frontier;
- sensibilidad a rival/type/public move evidence;
- determinismo y JSON;
- cero selección nueva y cero cambio conductual.

Solo con esa evidencia podrá decidirse si la frontier tiene algún uso contextual no vinculante en switching o si debe permanecer completamente fuera de esa capa.

Sigue prohibido durante C3f-m:

- hard pruning;
- score bonus/penalty por frontier membership;
- cambio de brains;
- cambio de search;
- campaign policy;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- `permadeath_loss_cost_bp` definitivo;
- FASE34;
- merge de PR #105.


### 26.34 C3f-m — shadow overlap real-data: la frontier Pareto es observabilidad, no filtro de switching

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / SHADOW-AUDIT-ONLY**.

C3f-m amplía la barrera abierta por C3f-l. C3f-l había demostrado con un contraejemplo adversarial que un miembro dominado por la frontier component-first puede ser el mejor switch contextual. C3f-m comprueba ahora si ese problema era excepcional o aparece de forma material sobre DATA V3 real.

La respuesta es inequívoca:

> **la frontier Pareto correlaciona con parte de los mejores switches, pero no es segura para podar, seleccionar ni bonificar candidatos de switching.**

#### Baseline y SHAs certificados

Baseline documental 26.33:

`88c5e35faca81cdab490a4761a69127c8f6ff7c9`

SHA técnico limpio C3f-m:

`e19b1b2d1759675fa4ab4903ba5f95fd53bc2e31`

SHA humano tree-identical C3f-m:

`77bc71463da3ddadb7329e49200108c6028792e7`

Árbol técnico/humano común:

`18b456ef018deec634c0cbc5bdb58f41f4ce01e5`

Los dos checkpoints tienen como parent directo 26.33. Los commits de staging quedan fuera de la historia certificada.

#### Scope neto limpio

Frente a 26.33, C3f-m modifica únicamente:

- nueva suite `tests/trainer_ai/trainer_roster_frontier_switching_shadow_overlap_audit_test_suite.gd`: **+543 líneas**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+2 / -2**.

No modifica:

- producción;
- `TrainerStrategicSwitchEvaluatorV2`;
- brains;
- score de switching;
- espacio de acciones legales;
- search/planning;
- campaign policy;
- recovery/replacement;
- FASE34.

Audit ID:

`c3f_m_switching_frontier_shadow_overlap_audit_v1`

#### Matriz real-data

C3f-m consume directamente las primitivas de producción ya certificadas:

- contrato: `trainer_roster_component_first_contract_v1`;
- frontier: `trainer_roster_pareto_frontier_v1`;
- switching: `strategic_switch_expected_matchup_v2`;
- probe DATA V3: `runtime_levelup_l50_neutral_probe_v1`.

Geometría de la auditoría:

- especies elegibles: **1021**;
- sample stride: **8**;
- rosters muestreados: **128**;
- offsets deterministas de rival: **37** y **503**;
- pares roster/rival: **256**;
- modos de evidencia por par: **2**;
- escenarios contextuales: **512**;
- candidatos de switch por escenario: **5**;
- evaluaciones de candidatos: **2560**.

Modos de evidencia:

1. `species_fallback`;
2. `revealed_damaging_move`.

Todos los escenarios son shadow/read-only. La frontier no entra en el evaluador de switching y no modifica ningún score.

#### Integridad de la muestra

Resultado:

- `opponent_selection_failures = 0`;
- `context_build_failures = 0`;
- `contract_validation_failures = 0`;
- `frontier_validation_failures = 0`;
- `candidate_partition_mismatches = 0`;
- `contexts_with_frontier_bench = 512`;
- `contexts_without_frontier_bench = 0`.

Por tanto, los resultados de overlap no proceden de escenarios incompletos ni de candidatos sin clasificar.

#### Resultado central — hard pruning pierde óptimos reales

Sobre 512 escenarios:

- `best_set_intersects_frontier_cases = 411`;
- `hard_frontier_pruning_loses_all_optima_cases = 101`;
- `best_set_dominated_only_cases = 101`;
- `best_set_contains_dominated_cases = 303`.

Equivale aproximadamente a:

- **80.27 %** de escenarios donde la frontier conserva al menos un switch óptimo;
- **19.73 %** donde filtrar a frontier elimina **todos** los switches óptimos;
- **59.18 %** donde el conjunto de mejores switches contiene al menos un miembro que Pareto marca como dominated.

El dato de 80.27 % NO autoriza pruning. Un filtro que destruye todo el conjunto óptimo en aproximadamente uno de cada cinco escenarios es semánticamente inseguro para switching.

C3f-m mantiene por tanto:

`hard_frontier_pruning_safe_for_switching = false`

`sample_supports_hard_pruning = false`

#### Coste observado de filtrar solo a frontier

En los 101 escenarios donde la frontier no conserva ningún óptimo:

- `frontier_only_score_loss_cases = 101`;
- `frontier_only_score_loss_sum = 280900`;
- `frontier_only_score_loss_mean = 2781`;
- `frontier_only_score_loss_max = 5900`.

La pérdida no es solo una diferencia teórica de pertenencia al conjunto. El score contextual de switching puede degradarse de forma material.

Ejemplos certificados incluyen:

- Rayquaza dominado como mejor switch frente a Baxcalibur, pérdida frontier-only **700**;
- Scovillain dominado frente a Calyrex, pérdida de hasta **2200**;
- Sirfetch'd/Wailord dominados frente a Nosepass, pérdida **2200**;
- Mr. Rime dominado frente a Rowlet, pérdida **4400**;
- Incineroar dominado frente a Ferroseed, pérdida **4400**.

Estos ejemplos no crean una nueva regla de matchup. Solo muestran que la evaluación contextual real puede invertir la utilidad relativa respecto del espacio rival-agnostic de la frontier.

#### La evidencia pública del rival cambia el óptimo

C3f-m compara para cada uno de los 256 pares roster/rival los dos modos de evidencia.

Resultado:

- `evidence_pair_comparisons = 256`;
- `evidence_changed_best_set_cases = 77`.

Aproximadamente **30.08 %** de los pares cambian su conjunto de mejores switches cuando se pasa de fallback por especie a movimiento dañino público revelado.

Esto refuerza la separación arquitectónica:

- la frontier describe estado/valor component-first del roster propio;
- switching resuelve un problema contextual condicionado por rival y evidencia pública legítima;
- una geometría rival-agnostic no puede sustituir esa evaluación contextual.

Por modo:

`species_fallback`:

- escenarios: **256**;
- conserva algún óptimo: **207**;
- pierde todos los óptimos: **49**;
- best set contiene dominated: **158**.

`revealed_damaging_move`:

- escenarios: **256**;
- conserva algún óptimo: **204**;
- pierde todos los óptimos: **52**;
- best set contiene dominated: **145**.

El problema persiste bajo ambos modos; no depende de una única forma de evidencia rival.

#### Empates — semántica de conjunto, no ganador léxico

C3f-m no fuerza un ganador cuando varios candidatos comparten score máximo.

Semántica congelada:

`best_set_semantics = all_equal_max_score_switch_ids`

`lexical_best_selection_used = false`

Histograma del tamaño del best set:

- 1 -> **206** escenarios;
- 2 -> **120**;
- 3 -> **62**;
- 4 -> **27**;
- 5 -> **97**.

El orden léxico sigue siendo únicamente determinismo/auditabilidad. No es una preferencia de conducta.

#### Distribución de frontier en banquillo

Número de miembros frontier disponibles como switch por escenario:

- 1 -> **72**;
- 2 -> **112**;
- 3 -> **176**;
- 4 -> **120**;
- 5 -> **32**.

Todos los 512 escenarios tenían al menos un miembro frontier de banquillo. Por tanto, los 101 casos de pérdida completa no pueden explicarse por una frontier vacía o sin candidato legal: son contradicciones reales entre dominancia component-first y utilidad contextual de switching.

#### Semántica canónica resultante

C3f-m congela:

`frontier_pruning_authorized = false`

`frontier_score_bonus_authorized = false`

`behavior_integration_authorized = false`

`recommended_switching_use = shadow_observability_only_not_candidate_filter`

Para switching, la frontier puede mantenerse como **telemetría/observabilidad de roster-state**, por ejemplo para explicar posteriormente que un switch táctico escogido estaba fuera de la frontier. No puede utilizarse como:

- filtro duro;
- shortlist vinculante;
- bonus silencioso de score;
- desempate;
- elección automática;
- sustituto del matchup contextual.

C3f-l permanece íntegramente vigente.

#### Incidente de staging — excluido de la historia certificada

El primer staging de C3f-m alcanzó **17/18 workflows SUCCESS**. Team Composition falló antes de ejecutar la auditoría porque la clase hija redeclaró `EXPECTED_ELIGIBLE_SPECIES`, constante ya presente en la jerarquía padre.

SHA staging fallido:

`ed44d42ca13db0ea9ad59e78baa417079a9570de`

No fue un fallo conceptual, de DATA V3, del contrato, de frontier ni de switching. Godot rechazó la redeclaración durante import.

La corrección eliminó exclusivamente esa línea duplicada y reutilizó la constante heredada.

SHA staging corregido:

`2e7215e8d668d618bcd6303989c14a91a61a2721`

El diff entre ambos fue exactamente:

- 1 archivo;
- **0 adiciones / 1 eliminación**.

El staging corregido produjo 18/18 SUCCESS, FASE33 **653 PASS / 0 FAIL** y el reporte C3f-m canónico. Después su árbol se reconstruyó como el SHA técnico limpio, por lo que ambos staging quedan fuera de la historia certificada.

#### Certificación técnica limpia

Sobre:

`e19b1b2d1759675fa4ab4903ba5f95fd53bc2e31`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **653 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Strategic Switching V2: SUCCESS;
- mismo reporte C3f-m;
- sin `SCRIPT ERROR`.

#### Certificación humana tree-identical

Sobre:

`77bc71463da3ddadb7329e49200108c6028792e7`

se reproduce:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **653 PASS / 0 FAIL**;
- mismo reporte C3f-m y mismas 512 observaciones contextuales;
- Godot general: SUCCESS;
- DATA V3: SUCCESS;
- Strategic Switching V2: SUCCESS;
- sin `SCRIPT ERROR`.

C3f-m queda **DOBLEMENTE CERTIFICADO**.

#### Invariantes externas

En el cierre técnico/humano:

- PR #105 continúa **OPEN**;
- `merged_at = null`;
- base: `main`;
- `main` permanece exactamente en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

PR #105 sigue siendo temporal y **NO debe mergearse**.

#### Conclusión C3f-m

C3f-m convierte el aviso adversarial de C3f-l en evidencia cuantitativa amplia.

La frontier component-first tiene valor descriptivo: en alrededor del 80 % de esta matriz comparte al menos un óptimo con switching. Pero ese solapamiento no constituye una policy porque:

- falla completamente en **101/512** escenarios;
- los dominated aparecen en best sets en **303/512**;
- la evidencia pública del rival cambia el óptimo en **77/256** pares;
- las pérdidas de score frontier-only alcanzan **5900**.

Por tanto, para switching la frontera correcta queda cerrada así:

> **contexto táctico y legalidad primero; frontier solo como observabilidad no vinculante.**

No existe autorización para integrar Pareto dentro del score ni dentro del filtrado de switching.

#### Estado de la secuencia

**C3f-n NO está abierto todavía.**

Cualquier siguiente microtranche debe abrirse en un checkpoint separado y justificar un problema distinto. No puede reinterpretar C3f-m como permiso implícito para integrar frontier en switching.

Continúa prohibido:

- modificar brains por esta frontier;
- podar legal actions por frontier;
- añadir frontier bonus a switching/search;
- convertir orden léxico en preferencia;
- inventar recovery/replacement/permadeath policy;
- iniciar FASE34;
- mergear PR #105.


### 26.35 C3f-n — el sampling acotado de search depende del orden de switches

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / TEST-AUDIT-ONLY**.

C3f-n abre un problema distinto del cerrado en C3f-m. C3f-m demostró que la frontier Pareto no puede podar switching de forma segura. C3f-n audita ahora una frontera anterior dentro de `TrainerMultiTurnSearch`: qué acciones de switch llegan siquiera a entrar en search cuando el presupuesto limita el número de acciones por lado.

El resultado demuestra una dependencia de orden previa a cualquier integración de roster value:

> **con el presupuesto default de tres acciones y cinco switches disponibles, el sampler productivo actual conserva un solo switch; cambiar únicamente el orden de entrada cambia qué switch sobrevive al muestreo.**

C3f-n no modifica el sampler. Solo certifica su semántica actual y bloquea cualquier integración de roster value en search hasta diseñar y auditar una frontera de muestreo adecuada.

#### Baseline y SHAs certificados

Baseline documental 26.34:

`51e5846a4de19804239fa012f18dfdbc3b0a67c7`

SHA técnico limpio C3f-n:

`504625ac275732838bbb5b2a5a616ce33952ba7a`

SHA humano tree-identical C3f-n:

`113168ab59d1c1c2800bb6734c71fc131e7b3426`

Árbol técnico/humano común:

`de873aee6ae31c01667d4745d826ba3ae2101b0b`

Ambos checkpoints tienen como parent directo 26.34. No existe diferencia funcional entre técnico y humano.

#### Scope neto limpio

Frente a 26.34, C3f-n modifica únicamente tests/audit:

- nueva suite `tests/trainer_ai/trainer_roster_search_switch_sampling_boundary_audit_test_suite.gd`: **+249 líneas**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**.

No modifica:

- `TrainerMultiTurnSearch`;
- `TrainerActionSpace`;
- `TrainerSearchBudget`;
- evaluadores de switching;
- brains;
- scores;
- legal actions;
- frontier productiva;
- campaign policy;
- recovery/replacement;
- FASE34.

Audit ID:

`c3f_n_search_switch_sampling_order_boundary_audit_v1`

Modelo de search auditado:

`simultaneous_depth_budget_v1`

Modelo de sampling auditado:

`kind_stratified_round_robin_v1`

#### Por qué C3f-n era una frontera distinta

El presupuesto default de `TrainerSearchBudget.depth_two_default()` usa:

`max_actions_per_side = 3`

El sampler productivo de `TrainerMultiTurnSearch` separa clases de acción y hace round-robin estratificado. Esa propiedad garantiza que un cap pequeño pueda conservar diversidad entre MOVE y SWITCH, pero no garantiza invariancia ni cobertura entre múltiples switches de la misma clase.

C3f-n audita precisamente esa segunda propiedad antes de permitir que structural value, operational readiness o frontier aparezcan en search.

#### Geometría sintética controlada

La auditoría construye el mismo conjunto semántico de acciones bajo distintos órdenes de switches:

- moves: **4**;
- switches: **5**;
- acciones totales: **9**;
- cap default: **3**.

Switch IDs:

- `switch_alpha`;
- `switch_beta`;
- `switch_gamma`;
- `switch_delta`;
- `switch_epsilon`.

No cambia entre probes:

- número de moves;
- número de switches;
- tipos de acción;
- presupuesto;
- search model;
- sampler;
- scores;
- frontier;
- roster value.

Solo cambia el orden de entrada de los cinco switches.

#### Resultado default — un solo switch entra en search

Con orden inicial alpha -> beta -> gamma -> delta -> epsilon, el sample exacto bajo cap 3 es:

`MOVE sampling_move_0`

`SWITCH switch_alpha`

`MOVE sampling_move_1`

Contadores:

- `default_sample_size = 3`;
- `default_sample_move_count = 2`;
- `default_sample_switch_count = 1`;
- `default_switch_omitted_count = 4`;
- `default_switch_coverage_bp = 2000`.

Por tanto, en esta geometría el sampler conserva:

**1 / 5 switches = 20 %**

y omite cuatro switches legales antes de que search pueda compararlos.

Esto no implica por sí solo que esos cuatro fueran tácticamente mejores. C3f-n certifica una propiedad anterior y más básica: **no llegan al conjunto buscado**.

#### Invertir solo el orden cambia el switch muestreado

Con el mismo conjunto de acciones y orden inverso de switches:

`epsilon -> delta -> gamma -> beta -> alpha`

el sample pasa a:

`MOVE sampling_move_0`

`SWITCH switch_epsilon`

`MOVE sampling_move_1`

Resultado:

`reverse_order_changes_sampled_switch = true`

`default_sampling_switch_order_invariant = false`

`input_switch_order_dependency_proven = true`

No cambia ninguna evidencia táctica ni estratégica. El cambio de switch muestreado procede únicamente de la posición de entrada.

#### Rotaciones — cualquiera de los cinco puede convertirse en el único switch buscado

C3f-n ejecuta cinco rotaciones cíclicas del mismo conjunto de switches.

Resultado:

- `rotation_cases = 5`;
- `distinct_sampled_switches_across_rotations = 5`;
- `all_switches_can_be_selected_by_order_only = true`.

Rotaciones certificadas:

1. alpha primero -> se muestrea alpha;
2. beta primero -> se muestrea beta;
3. gamma primero -> se muestrea gamma;
4. delta primero -> se muestrea delta;
5. epsilon primero -> se muestrea epsilon.

La prueba no afirma que el orden del party sea la única fuente posible de ese orden en todas las rutas. La propiedad ejecutable certificada es más precisa:

> **el resultado del bounded sampling depende del orden de entrada de los switch actions.**

La revisión de `TrainerActionSpace` muestra además que la ruta actual enumera switches recorriendo `side.party_ids`; esa observación arquitectónica motiva la siguiente auditoría, pero C3f-n no convierte por sí sola esa relación en una nueva policy ni en una corrección productiva.

#### Control con cap completo

La misma entrada se ejecuta con cap **9**, suficiente para conservar las nueve acciones.

Resultado:

- `full_cap = 9`;
- `full_cap_switch_count = 5`;
- `full_cap_preserves_all_switches = true`.

Por tanto, la pérdida de cobertura no procede de `BattleAction`, de la construcción sintética ni de switches inválidos. Aparece específicamente al aplicar el bounded sampling con cap 3.

#### El problema precede a Pareto y roster value

C3f-n congela:

`frontier_used_for_sampling = false`

`roster_value_used_for_sampling = false`

La dependencia de orden existe **antes** de conectar:

- `TrainerRosterComponentFirstContract`;
- `TrainerRosterParetoFrontier`;
- structural value;
- operational readiness.

Por eso no sería correcto intentar solucionar el problema añadiendo simplemente frontier o un bonus de roster value al sampler actual. Primero debe definirse una frontera de sampling que sea auditable y no introduzca una policy accidental por posición.

C3f-m sigue plenamente vigente: Pareto no puede usarse como hard pruning de switches.

#### Semántica congelada

C3f-n fija:

`default_sampling_switch_order_invariant = false`

`input_switch_order_dependency_proven = true`

`behavior_integration_authorized = false`

`search_sampling_redesign_authorized = false`

Recomendación documental:

`audit_order_invariant_context_aware_switch_sampling_before_search_roster_value_integration`

Esto significa:

- el sampler actual queda auditado, no corregido;
- no se autoriza aumentar scores por frontier;
- no se autoriza ordenar switches por frontier;
- no se autoriza seleccionar un `frontier_instance_ids[0]`;
- no se autoriza convertir orden léxico o party order en preferencia;
- no se autoriza cambiar budgets productivos todavía;
- no se autoriza comportamiento nuevo.

#### Certificación técnica limpia

Sobre:

`504625ac275732838bbb5b2a5a616ce33952ba7a`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **669 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Trainer Search Foundation: SUCCESS;
- Trainer Search Depth Budget: SUCCESS;
- Trainer Search Limit Benchmark: SUCCESS;
- Trainer Strategic Switching V2: SUCCESS;
- reporte C3f-n determinista y JSON serializable.

#### Certificación humana tree-identical

Sobre:

`113168ab59d1c1c2800bb6734c71fc131e7b3426`

se reproduce:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **669 PASS / 0 FAIL**;
- mismo modelo `simultaneous_depth_budget_v1`;
- mismo sampler `kind_stratified_round_robin_v1`;
- mismo sample default MOVE0 / SWITCH-alpha / MOVE1;
- mismo `default_switch_coverage_bp = 2000`;
- mismo `default_switch_omitted_count = 4`;
- mismo cambio alpha -> epsilon al invertir orden;
- mismas cinco rotaciones seleccionables únicamente por orden;
- mismo control full-cap con los cinco switches preservados;
- Godot general, DATA V3 y gates de search: SUCCESS.

C3f-n queda **DOBLEMENTE CERTIFICADO**.

#### Invariantes externas

Durante el cierre C3f-n:

- PR #105 continúa **OPEN**;
- `merged = false`;
- `merged_at = null`;
- base: `main`;
- `main` permanece exactamente en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

PR #105 sigue siendo temporal y **NO debe mergearse**.

#### Conclusión C3f-n

Antes de discutir cómo introducir roster value en search, existe una frontera más básica que debe sanearse conceptualmente: el bounded sampler decide qué switch actions llegan a ser buscadas.

Con el cap default auditado, una banca de cinco alternativas queda reducida a una sola alternativa de switch, y la identidad de esa alternativa depende del orden de entrada.

Eso crea una barrera de diseño independiente de Pareto:

> **primero debe existir un sampling de switches determinista, auditable y no dependiente de una preferencia posicional accidental; después podrá estudiarse si alguna evidencia estratégica entra de forma no destructiva.**

No se ha cambiado comportamiento en C3f-n.

#### Siguiente microtranche autorizada — C3f-o

**C3f-o — comparación TEST/AUDIT-ONLY de estrategias de sampling de switches order-invariant y context-aware para search.**

C3f-o queda autorizado únicamente a comparar diseños, no a modificar producción.

Debe comprobar como mínimo:

- invariancia ante reorder del mismo conjunto de switch actions;
- determinismo;
- compatibilidad con un budget acotado;
- conservación explícita de diversidad MOVE/SWITCH;
- qué ocurre cuando hay más switches que plazas disponibles;
- uso únicamente de contexto público/legal certificado;
- que una alternativa tácticamente fuerte no quede eliminada por una geometría rival-agnostic;
- que Pareto no actúe como hard pruning, según C3f-m;
- que orden léxico sea solo desempate de representación, nunca preferencia semántica;
- que TrainerProfile, RNG, beliefs ocultas, recovery/replacement y campaign policy no entren accidentalmente;
- que ningún diseño quede seleccionado para producción sin un checkpoint posterior separado.

C3f-o no puede todavía:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- cambiar `max_actions_per_side` productivo;
- integrar frontier/roster value en search;
- modificar brains;
- abrir FASE34;
- mergear PR #105.


### 26.36 C3f-o — sampling contextual elimina el sesgo de orden, pero cap 3 no preserva todos los óptimos

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / TEST-AUDIT-ONLY**.

C3f-o parte del problema congelado en 26.35: el bounded sampler productivo de search es sensible al orden de entrada de los switches cuando `max_actions_per_side = 3`. Este microtranche no corrige producción. Compara, en sombra, estrategias de selección de switch que sean deterministas y order-invariant antes de autorizar cualquier cambio en `TrainerMultiTurnSearch`.

El resultado separa dos problemas que no deben confundirse:

1. **eliminar la dependencia del orden de entrada es posible**;
2. **eliminarla no basta para justificar una poda semántica** cuando varios switches empatan como máximos bajo la evidencia contextual disponible.

Con el cap productivo actual de tres acciones y conservando al menos una plaza MOVE, solo quedan como máximo dos plazas SWITCH. En la matriz real auditada existen **186 / 512 contextos** donde el conjunto de máximos tácticos tiene tres o más miembros. Por tanto, bajo esa geometría, cap 3 no puede preservar simultáneamente todo el conjunto óptimo y la diversidad MOVE/SWITCH.

#### Baseline y SHAs certificados

Baseline documental 26.35:

`7dea5464ecd17c9903dc58fac4de70c53abbb7bd`

SHA técnico limpio C3f-o:

`d0ae3f141ea237f81c92ee4e42eddaa48d2fd4a7`

SHA humano tree-identical C3f-o:

`6650355933f3d719354b6721de9549b34950f124`

Árbol técnico/humano común:

`40152cf6d314bccb4c43084477aeaadf846ac8e2`

Ambos checkpoints tienen como parent directo 26.35. No existe diferencia funcional entre técnico y humano.

#### Scope neto limpio

Frente a 26.35, C3f-o modifica únicamente tests/audit:

- nueva suite `tests/trainer_ai/trainer_roster_search_switch_sampling_strategy_comparison_audit_test_suite.gd`: **+610 líneas**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**.

No modifica:

- `TrainerMultiTurnSearch`;
- `TrainerActionSpace`;
- `TrainerSearchBudget`;
- `TrainerStrategicSwitchEvaluatorV2`;
- brains;
- scores productivos;
- legal actions;
- frontier productiva;
- campaign policy;
- recovery/replacement;
- FASE34.

Audit ID:

`c3f_o_switch_sampling_strategy_comparison_audit_v1`

Modelos observados:

- search: `simultaneous_depth_budget_v1`;
- sampler actual: `kind_stratified_round_robin_v1`;
- switching contextual: `strategic_switch_expected_matchup_v2`;
- frontier: `trainer_roster_pareto_frontier_v1`;
- source contract: `trainer_roster_component_first_contract_v1`.

#### Matriz real reutilizada

C3f-o reutiliza la geometría certificada de C3f-m:

- **1021 especies elegibles**;
- **128 rosters**;
- **512 contextos de switching**;
- **2560 ocurrencias de candidatos switch**;
- offsets rival: `[37, 503]`;
- modos de evidencia: `species_fallback` y `revealed_damaging_move`;
- **2048 probes de reorder** entre las cuatro estrategias.

No hay:

- hidden belief hypotheses;
- memory event log;
- campaign snapshot;
- RNG;
- recovery policy;
- replacement policy;
- campaign policy;
- roster value integrado en search.

El `TrainerProfile` usado es neutral para esta comparación y conserva:

`switch_weight_bp = 10000`

No se usa una preferencia semántica de perfil para resolver candidatos.

#### Cuatro estrategias comparadas

C3f-o compara cuatro políticas en sombra:

1. `lexical_id_one_switch_negative_control`
2. `pareto_frontier_one_switch_negative_control`
3. `contextual_switch_score_one_switch_candidate`
4. `contextual_switch_score_two_switch_candidate`

Las dos primeras son **controles negativos**. Las dos contextuales son candidatas de auditoría, no candidatas aprobadas para producción.

Todas son implementadas únicamente dentro de la suite C3f-o.

#### Invariancia de reorder

Resultado global:

- `reorder_probe_cases = 2048`;
- `reorder_mismatch_cases = 0`;
- `bounded_size_violation_cases = 0`;
- `diversity_failure_cases = 0`.

Por tanto, las cuatro estrategias de comparación pueden hacerse deterministas y order-invariant.

Pero esta propiedad **no equivale a corrección semántica**.

El control lexical lo demuestra directamente: ordenar canónicamente por ID elimina la dependencia del orden de entrada, pero convierte el ID en preferencia artificial si se usa para decidir qué candidato sobrevive.

#### Control negativo lexical — order-invariant pero semánticamente inválido

`lexical_id_one_switch_negative_control`

Resultado:

- casos: **512**;
- `any_optimum_preserved_cases = 245`;
- `loses_all_optima_cases = 267`;
- `all_optima_preserved_cases = 36`;
- `partial_optimum_cases = 209`;
- `selected_dominated_cases = 228`;
- `reorder_mismatches = 0`;
- `lexical_semantic_preference = true`;
- `production_ready = false`.

Conclusión:

> **ser order-invariant no basta.**

Un canonical sort por ID es reproducible, pero no contiene evidencia táctica. No puede convertirse en policy de selección.

#### Control negativo Pareto-first — sigue destruyendo óptimos tácticos

`pareto_frontier_one_switch_negative_control`

Resultado:

- casos: **512**;
- `any_optimum_preserved_cases = 274`;
- `loses_all_optima_cases = 238`;
- `all_optima_preserved_cases = 51`;
- `partial_optimum_cases = 223`;
- `selected_dominated_cases = 0`;
- `frontier_hard_filter = true`;
- `reorder_mismatches = 0`;
- `production_ready = false`.

Este control combina dos errores que C3f-l/C3f-m ya prohibieron:

- filtrar primero por frontier rival-agnostic;
- después escoger un representante lexical de esa frontier.

Pierde todos los máximos contextuales en **238 / 512** contextos.

C3f-o reafirma:

`frontier_hard_pruning_authorized = false`

#### Candidata contextual con una plaza SWITCH

`contextual_switch_score_one_switch_candidate`

Geometría bajo cap 3:

- MOVE slots: **2**;
- SWITCH slots: **1**.

Resultado:

- casos: **512**;
- `any_optimum_preserved_cases = 512`;
- `loses_all_optima_cases = 0`;
- `all_optima_preserved_cases = 206`;
- `partial_optimum_cases = 306`;
- `top_set_overflow_cases = 306`;
- `lexical_equal_score_cutoff_cases = 306`;
- `selected_dominated_cases = 204`;
- `reorder_mismatches = 0`;
- `frontier_hard_filter = false`;
- `production_ready = false`.

La señal contextual preserva **al menos un máximo** en los 512 contextos y puede retener counters tácticos component-first dominated. Eso evita el fallo de Pareto-first.

Sin embargo, solo preserva **todo** el conjunto óptimo en los 206 contextos donde el máximo es único.

En los otros 306 contextos existe empate en el cutoff. El ID lexical usado por la auditoría dentro del empate es solo una representación determinista de qué elementos caben; **no certifica que esos miembros sean semánticamente mejores que los empatados excluidos**.

#### Candidata contextual con dos plazas SWITCH

`contextual_switch_score_two_switch_candidate`

Geometría bajo el mismo cap 3:

- MOVE slots: **1**;
- SWITCH slots: **2**.

Resultado:

- casos: **512**;
- `any_optimum_preserved_cases = 512`;
- `loses_all_optima_cases = 0`;
- `all_optima_preserved_cases = 326`;
- `partial_optimum_cases = 186`;
- `top_set_overflow_cases = 186`;
- `lexical_equal_score_cutoff_cases = 349`;
- `selected_dominated_cases = 338`;
- `reorder_mismatches = 0`;
- `frontier_hard_filter = false`;
- `production_ready = false`.

Dar dos plazas de switch mejora la preservación completa del óptimo:

**206 -> 326 contextos**.

Pero todavía quedan **186 / 512** contextos donde hay más máximos empatados que plazas switch disponibles.

Por tanto, aumentar de una a dos plazas no resuelve la frontera conceptual.

#### Distribución exacta del conjunto óptimo contextual

C3f-o reproduce el best-set histogram de C3f-m:

- tamaño 1 -> **206** contextos;
- tamaño 2 -> **120**;
- tamaño 3 -> **62**;
- tamaño 4 -> **27**;
- tamaño 5 -> **97**.

Total:

**512 contextos**.

No se colapsan los empates a un primer ID para construir esta distribución. El best set significa:

`all_equal_max_score_switch_ids`

#### Cap necesario para preservar todos los máximos + al menos un MOVE

Si se exige conservar al menos una plaza MOVE, el cap total mínimo requerido es:

- best-set 1 -> cap **2**: 206 contextos;
- best-set 2 -> cap **3**: 120;
- best-set 3 -> cap **4**: 62;
- best-set 4 -> cap **5**: 27;
- best-set 5 -> cap **6**: 97.

Histograma certificado:

`{"2":206,"3":120,"4":62,"5":27,"6":97}`

Resultado:

- `cap_three_one_move_preserves_full_optimal_set_cases = 326`;
- `cap_three_one_move_cannot_preserve_full_optimal_set_cases = 186`;
- `contexts_requiring_cap_above_three_for_full_optimal_set = 186`;
- `required_total_cap_max = 6`.

Esta es la barrera principal de C3f-o.

#### Por qué no se puede declarar ganadora la estrategia contextual todavía

C3f-o sí demuestra que el score contextual existente contiene mejor evidencia para **no perder todos los máximos** que los controles lexical/Pareto de esta auditoría.

Pero no demuestra que dos switches empatados en `TrainerStrategicSwitchEvaluatorV2` sean intercambiables para una búsqueda multi-turn.

Un empate de primer paso puede romperse después por:

- estado futuro tras el switch;
- opciones de segundo turno;
- respuesta rival;
- diferencias de profundidad/horizonte;
- interacción con el presupuesto de nodos y acciones.

Por tanto, podar un empate contextual antes de search podría borrar precisamente la continuación que search profundo habría preferido.

C3f-o **no autoriza** asumir equivalencia entre miembros empatados.

#### Semántica lexical congelada

Lexical ordering puede usarse para:

- serialización estable;
- firma determinista;
- presentación reproducible;
- recorrer elementos de un empate sin afirmar preferencia.

No puede usarse para:

- decir que `id_a` es tácticamente mejor que `id_b`;
- eliminar un candidato empatado y tratar la eliminación como semanticamente segura;
- seleccionar un switch real por ID.

Los `lexical_equal_score_cutoff_cases` son precisamente una señal de pérdida potencial, no una autorización de desempate.

#### Pareto sigue fuera de la poda de switches

C3f-o conserva intacta la barrera C3f-m:

- la frontier no entra en las candidatas contextuales como hard filter;
- una candidata contextual puede seleccionar miembros dominated;
- una plaza contextual selecciona dominated en **204** contextos;
- dos plazas contextuales seleccionan dominated en **338** contextos.

Eso es coherente con el resultado previo: dominance de roster-state no implica dominance contra el rival actual.

No se autoriza:

- frontier bonus;
- frontier penalty;
- hard frontier pruning;
- `frontier_instance_ids[0]` como preferencia.

#### Contexto oculto y policy externa ausentes

Contadores certificados:

- `nonempty_hidden_belief_cases = 0`;
- `nonempty_memory_event_cases = 0`;
- `nonempty_campaign_snapshot_cases = 0`;
- `rng_used = false`;
- `recovery_policy_used = false`;
- `replacement_policy_used = false`;
- `campaign_policy_used = false`;
- `roster_value_integrated = false`.

La auditoría se limita a contexto legal/público ya certificado.

#### Ninguna estrategia queda seleccionada

C3f-o congela explícitamente:

`selected_strategy_id = null`

`production_strategy_selected = false`

`search_sampling_redesign_authorized = false`

`behavior_integration_authorized = false`

Por tanto, ni la variante contextual de una plaza ni la de dos plazas queda aprobada para producción.

#### Canonical report C3f-o

```json
{
  "audit_id": "c3f_o_switch_sampling_strategy_comparison_audit_v1",
  "behavior_integration_authorized": false,
  "bounded_action_cap": 3,
  "bounded_size_violation_cases": 0,
  "cap_three_one_move_cannot_preserve_full_optimal_set_cases": 186,
  "cap_three_one_move_preserves_full_optimal_set_cases": 326,
  "context_build_failures": 0,
  "contexts_requiring_cap_above_three_for_full_optimal_set": 186,
  "contextual_one_all_optima_preserved_cases": 206,
  "contextual_two_all_optima_preserved_cases": 326,
  "current_sampling_model_id": "kind_stratified_round_robin_v1",
  "diversity_failure_cases": 0,
  "eligible_species": 1021,
  "frontier_hard_pruning_authorized": false,
  "minimum_move_slots_for_diversity": 1,
  "nonempty_campaign_snapshot_cases": 0,
  "nonempty_hidden_belief_cases": 0,
  "nonempty_memory_event_cases": 0,
  "production_strategy_selected": false,
  "recommended_next_boundary": "resolve_contextual_tie_overflow_and_search_depth_preservation_before_any_sampler_port",
  "reorder_mismatch_cases": 0,
  "reorder_probe_cases": 2048,
  "required_total_cap_histogram": {"2":206,"3":120,"4":62,"5":27,"6":97},
  "required_total_cap_max": 6,
  "rng_used": false,
  "roster_value_integrated": false,
  "sampled_rosters": 128,
  "scenarios": 512,
  "search_model_id": "simultaneous_depth_budget_v1",
  "search_sampling_redesign_authorized": false,
  "selected_strategy_id": null,
  "switch_candidate_occurrences": 2560,
  "switching_model_id": "strategic_switch_expected_matchup_v2"
}
```

Resultados por estrategia:

```json
{
  "contextual_switch_score_one_switch_candidate": {
    "any_optimum_preserved_cases": 512,
    "all_optima_preserved_cases": 206,
    "partial_optimum_cases": 306,
    "loses_all_optima_cases": 0,
    "top_set_overflow_cases": 306,
    "selected_dominated_cases": 204,
    "production_ready": false
  },
  "contextual_switch_score_two_switch_candidate": {
    "any_optimum_preserved_cases": 512,
    "all_optima_preserved_cases": 326,
    "partial_optimum_cases": 186,
    "loses_all_optima_cases": 0,
    "top_set_overflow_cases": 186,
    "selected_dominated_cases": 338,
    "production_ready": false
  },
  "lexical_id_one_switch_negative_control": {
    "any_optimum_preserved_cases": 245,
    "all_optima_preserved_cases": 36,
    "loses_all_optima_cases": 267,
    "production_ready": false
  },
  "pareto_frontier_one_switch_negative_control": {
    "any_optimum_preserved_cases": 274,
    "all_optima_preserved_cases": 51,
    "loses_all_optima_cases": 238,
    "production_ready": false
  }
}
```

#### Certificación técnica limpia

Sobre:

`d0ae3f141ea237f81c92ee4e42eddaa48d2fd4a7`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **692 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Trainer Search Foundation: SUCCESS;
- Trainer Search Depth Budget: SUCCESS;
- Trainer Search Limit Benchmark: SUCCESS;
- Trainer Strategic Switching V2: SUCCESS;
- reporte C3f-o determinista y JSON serializable;
- sin script errors.

#### Certificación humana tree-identical

Sobre:

`6650355933f3d719354b6721de9549b34950f124`

se reproduce:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **692 PASS / 0 FAIL**;
- mismos 512 contextos y 2560 candidatos;
- mismos 2048 reorder probes y 0 mismatches;
- mismo best-set histogram `206/120/62/27/97`;
- mismo required-cap histogram `206/120/62/27/97` para caps `2/3/4/5/6`;
- mismos **186** contextos que exceden cap 3;
- mismo cap máximo requerido **6**;
- contextual 1-slot: 512/512 preservan algún óptimo, 206 preservan todos;
- contextual 2-slot: 512/512 preservan algún óptimo, 326 preservan todos;
- lexical control pierde todos los óptimos en 267 contextos;
- Pareto control pierde todos los óptimos en 238 contextos;
- Godot general, DATA V3, switching y gates de search: SUCCESS.

C3f-o queda **DOBLEMENTE CERTIFICADO**.

#### Conclusión C3f-o

La dependencia de orden detectada en C3f-n no obliga a escoger entre party order y lexical order. Puede eliminarse mediante una ordenación contextual determinista.

Pero C3f-o también demuestra que **la salida contextual de primer paso no siempre tiene un máximo único**. Bajo el cap actual, los empates grandes fuerzan una pérdida de candidatos antes de search si se intenta imponer una selección fija.

Por tanto, el siguiente problema ya no es “qué switch va primero”, sino:

> **si dos o más switches empatan como máximos contextuales, ¿puede search profundo distinguirlos y cambiar cuál era realmente la mejor continuación?**

Hasta responder eso, no es seguro colapsar el empate por ID ni cambiar producción.

#### Siguiente microtranche autorizada — C3f-p

**C3f-p — auditoría TEST/AUDIT-ONLY de tie-overflow y preservación de profundidad de search.**

C3f-p queda autorizado únicamente a observar/comparar diseños.

Debe comprobar como mínimo:

- contextos donde `TrainerStrategicSwitchEvaluatorV2` tiene múltiples máximos empatados;
- ejecutar continuaciones de search por cada miembro del top set sin usar lexical como preferencia;
- medir cuántas veces candidatos empatados divergen después de uno o más plies;
- medir cuántas veces elegir un solo representante lexical borraría la mejor continuación profunda;
- comparar preservación con 1-slot, 2-slot y expansión del top tier;
- cuantificar coste de nodos/acciones de preservar el empate;
- mantener MOVE/SWITCH diversity explícita;
- no usar Pareto como hard pruning;
- no usar hidden beliefs, RNG, campaign policy, recovery/replacement ni TrainerProfile como desempate accidental;
- mantener determinismo y serialización JSON;
- no seleccionar todavía un sampler productivo.

C3f-p no puede todavía:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- cambiar `max_actions_per_side` productivo;
- integrar frontier/roster value en search;
- modificar brains;
- abrir FASE34;
- mergear PR #105.


### 26.37 C3f-p — los empates inmediatos de switching no son equivalencia profunda: search depth-2 distingue 48/48 casos auditados

C3f-p queda **CERRADO Y DOBLEMENTE CERTIFICADO** como auditoría TEST/AUDIT-ONLY.

#### Baseline de partida

C3f-p parte exclusivamente del freeze documental 26.36:

`2068625010763f7698d3779f5c3fd470db92ac99`

C3f-o había demostrado dos hechos distintos:

1. el sampler actual de search con `max_actions_per_side = 3` puede introducir dependencia del orden de entrada entre switches;
2. una ordenación contextual puede eliminar esa dependencia de orden, pero el score táctico inmediato de `TrainerStrategicSwitchEvaluatorV2` produce empates reales de tamaño 2–5 que no caben siempre dentro del cap 3 si se reserva al menos un MOVE.

La pregunta de C3f-p fue deliberadamente más estrecha:

> cuando dos o más switches empatan como máximos según la evaluación táctica inmediata, ¿son realmente equivalentes después de ejecutar `TrainerMultiTurnSearch` a profundidad 2, o una poda previa al search puede borrar la mejor continuación?

C3f-p no estaba autorizado a modificar producción ni a escoger todavía una política de sampling.

#### Superficies productivas observadas, no modificadas

La auditoría reutiliza sin modificar:

- `TrainerStrategicSwitchEvaluatorV2`;
- `TrainerMultiTurnSearch`;
- `TrainerSearchBudget.depth_two_default()`;
- el sampler productivo `kind_stratified_round_robin_v1` para continuaciones;
- Battle Core como autoridad de ejecución de turnos;
- DATA V3 canónico y el probe `runtime_levelup_l50_neutral_probe_v1`.

`TrainerMultiTurnSearch.evaluate(context, root_action)` permite evaluar explícitamente cada switch raíz empatado. Por ello C3f-p pudo comparar todos los miembros del top-set inmediato **sin modificar `TrainerMultiTurnSearch` ni `TrainerActionSpace`**.

El sampler existente sigue actuando en las continuaciones internas, por lo que el audit observa el search real vigente en lugar de sustituirlo por un planner ficticio.

---

#### Primer intento provisional: fallo legítimo de harness, no fallo de producción

Primer SHA provisional:

`cab4a1eb496867cc9d6c0280d7d7b5701b98ea71`

Árbol provisional:

`5e9a6c85dc082d2b5298e62eb8ffd542f42af4d5`

Parent:

`2068625010763f7698d3779f5c3fd470db92ac99`

Ese primer intento añadió únicamente la auditoría y el cambio de runner; producción permaneció intacta.

Resultado CI provisional:

- **17/18 workflows SUCCESS**;
- único fallo: FASE33 / Trainer Team Composition;
- FASE33: **708 PASS / 5 FAIL**;
- `168/168` evaluaciones raíz devolvieron un resultado de search;
- pero `depth_two_incomplete_evaluations = 168`;
- `world_coverage_failures = 168`.

No se certificó ese SHA.

La diagnosis aisló una diferencia de contrato entre dos tipos de test:

- C3f-m/C3f-o construían un contexto **shadow de switching** con:
  `observation.phase = "action_selection"`;
- eso era suficiente para `TrainerStrategicSwitchEvaluatorV2`, porque esa auditoría no ejecutaba Battle Core;
- `TrainerMultiTurnSearch`, en cambio, reconstruye un `BattleState` desde la observación;
- Battle Core solo acepta acciones en:
  `BattleState.WAITING_FOR_ACTIONS = "waiting_for_actions"`.

Por tanto, las acciones de las worlds de search eran rechazadas por una fase sintética que nunca habría sido la fase canónica recibida desde `TrainerObservationBuilder` en una selección de acción real.

Conclusión exacta del incidente:

**fue un mismatch TEST-HARNESS / CONTEXT-CONTRACT, no una avería de `TrainerMultiTurnSearch`, ni un agotamiento de presupuesto, ni una incapacidad de la arquitectura para comparar los empates.**

---

#### Única corrección aplicada

Para evitar un ciclo de parches, C3f-p permitió una sola corrección enfocada.

Se añadió un adaptador exclusivamente de test:

`tests/trainer_ai/trainer_roster_search_tie_depth_preservation_canonical_phase_audit_test_suite.gd`

Clase:

`TrainerRosterSearchTieDepthPreservationCanonicalPhaseAuditTestSuite`

El adaptador hereda el builder certificado de C3f-o y cambia únicamente:

`context.observation.phase = BattleState.WAITING_FOR_ACTIONS`

No cambia:

- roster;
- rival;
- evidence mode;
- legal actions;
- beliefs;
- memory;
- campaign snapshot;
- scores inmediatos de switching;
- budget;
- sampler;
- search;
- Battle Core;
- profile;
- roster value;
- Pareto.

El reporte deja explícito:

- `source_shadow_phase = "action_selection"`;
- `search_context_phase = "waiting_for_actions"`;
- `test_only_phase_adapter_used = true`;
- `production_phase_logic_modified = false`.

No hubo una segunda corrección.

---

#### Checkpoint técnico limpio C3f-p

SHA técnico:

`0d44b7fe3837bc9ec8bc0d357e2e84f0619339ec`

Árbol:

`6c074d9947a018232674f6e5c15a05b2af0bd743`

Parent directo:

`2068625010763f7698d3779f5c3fd470db92ac99`

Commit:

`test(trainer-ai): audit C3f-p switch tie depth preservation`

Diff limpio contra 26.36:

1. `tests/trainer_ai/trainer_roster_search_tie_depth_preservation_audit_test_suite.gd`
   - `+581`;
2. `tests/trainer_ai/trainer_roster_search_tie_depth_preservation_canonical_phase_audit_test_suite.gd`
   - `+36`;
3. `tests/trainer_ai/trainer_team_composition_test_runner.gd`
   - `+1 / -1`.

**Cambios de producción: 0.**

Certificación técnica exacta:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **713 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Trainer Search Foundation: SUCCESS;
- Trainer Search Depth Budget: SUCCESS;
- Trainer Search Limit Benchmark: SUCCESS;
- Trainer Strategic Switching V2: SUCCESS;
- sin script errors.

---

#### Checkpoint humano tree-identical

SHA humano:

`ed212c2828a927f455f7f5ee1eab4a3f9c64cd4b`

Árbol:

`6c074d9947a018232674f6e5c15a05b2af0bd743`

Mismo parent directo:

`2068625010763f7698d3779f5c3fd470db92ac99`

Commit:

`test(trainer-ai): human checkpoint C3f-p`

El checkpoint humano es **tree-identical** al técnico y reproduce exactamente el mismo delta de tres archivos de test.

Certificación humana exacta:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **713 PASS / 0 FAIL**;
- mismo reporte JSON C3f-p;
- Godot general: SUCCESS;
- DATA V3: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS.

C3f-p queda por tanto doblemente certificado antes del freeze documental.

---

#### Geometría del audit C3f-p

Audit ID:

`c3f_p_switch_tie_depth_preservation_audit_v1`

Población heredada de C3f-m/C3f-o:

- especies elegibles: `1021`;
- rosters muestreados: `128`;
- escenarios totales: `512`;
- escenarios con empate inmediato de switching: `306`.

Distribución de los 306 empates inmediatos:

- top-set tamaño 2: `120`;
- top-set tamaño 3: `62`;
- top-set tamaño 4: `27`;
- top-set tamaño 5: `97`.

Para que la auditoría profunda permaneciera acotada y reproducible se tomó una muestra estratificada:

- `6` casos por tamaño de empate;
- por cada uno de los dos evidence modes;
- tamaños auditados: `2, 3, 4, 5`;
- evidence modes:
  - `species_fallback`;
  - `revealed_damaging_move`.

Muestra final:

- casos seleccionados: `48`;
- 12 de tamaño 2;
- 12 de tamaño 3;
- 12 de tamaño 4;
- 12 de tamaño 5;
- 24 `species_fallback`;
- 24 `revealed_damaging_move`.

Número total de root switches evaluados:

`12×2 + 12×3 + 12×4 + 12×5 = 168`

Budget productivo observado, no cambiado:

- `depth_turns = 2`;
- `max_worlds = 4`;
- `max_simulations = 220`;
- `max_actions_per_side = 3`.

Integridad de ejecución:

- `root_search_evaluations = 168`;
- `search_result_failures = 0`;
- `context_build_failures = 0`;
- `depth_two_incomplete_evaluations = 0`;
- `world_coverage_failures = 0`;
- `budget_exhausted_evaluations = 0`.

Por tanto, las 168 raíces alcanzan profundidad 2 completa y cobertura completa de las worlds usadas por el search.

---

#### Resultado central: 48/48 empates inmediatos se rompen en profundidad 2

Resultado canónico:

- `depth_divergence_cases = 48`;
- `depth_all_still_tied_cases = 0`;
- `depth_unique_best_cases = 48`;
- `depth_multiple_best_cases = 0`;
- `deep_best_set_size_histogram = {1: 48}`.

Es decir:

**los 48/48 casos seleccionados que eran empates perfectos bajo el score táctico inmediato dejaron de ser empates al ejecutar search depth-2.**

En esta muestra, cada top-set inmediato acabó teniendo un único ganador profundo.

Esto no demuestra que absolutamente todo empate posible del juego vaya a romperse siempre, porque C3f-p no ejecutó las 306 situaciones profundas completas. Sí demuestra que la igualdad del score inmediato **no es una equivalencia semántica suficiente para colapsar candidatos antes de search**.

El reporte lo registra como:

`arbitrary_single_representative_not_proven_safe_cases = 48`

---

#### Riesgo de conservar solo un representante lexical

Si dentro del empate inmediato se conservara únicamente el primer ID lexical:

- preserva el ganador profundo: `19/48`;
- pierde el ganador profundo: `29/48`.

Porcentaje de pérdida en esta muestra:

`29 / 48 ≈ 60,42 %`

Por tanto, lexical no es un desempate semántico aceptable.

---

#### Riesgo de conservar dos representantes lexicales

Si se conservaran los dos primeros IDs lexicales:

- preserva el ganador profundo: `30/48`;
- pierde el ganador profundo: `18/48`.

Pérdida:

`18 / 48 = 37,5 %`

Dos slots recuperan 11 casos que 1-slot perdía, pero siguen sin ser universalmente seguros.

---

#### Preservación del top-tier inmediato completo

Manteniendo todos los miembros del empate inmediato:

- preserva el ganador profundo: `48/48`;
- pierde el ganador profundo: `0/48`.

Esto es evidencia a favor de **no resolver el empate arbitrariamente antes de search**.

No constituye todavía autorización para expandir todo top-tier en producción: C3f-p también cuantifica el coste.

---

#### Resultado por tamaño del empate

##### Tie size 2

- casos: `12`;
- divergen en profundidad: `12/12`;
- 1-slot lexical pierde: `7`;
- 2-slot pierde: `0`;
- score spread sum: `54.353`;
- spread máximo: `10.541`.

##### Tie size 3

- casos: `12`;
- divergen: `12/12`;
- 1-slot lexical pierde: `7`;
- 2-slot pierde: `5`;
- score spread sum: `104.016`;
- spread máximo: `20.329`.

##### Tie size 4

- casos: `12`;
- divergen: `12/12`;
- 1-slot lexical pierde: `5`;
- 2-slot pierde: `5`;
- score spread sum: `127.033`;
- spread máximo: `20.894`.

##### Tie size 5

- casos: `12`;
- divergen: `12/12`;
- 1-slot lexical pierde: `10`;
- 2-slot pierde: `8`;
- score spread sum: `121.244`;
- spread máximo: `14.330`.

Los empates grandes son especialmente peligrosos para un cutoff fijo pequeño.

---

#### Resultado por evidence mode

##### species_fallback

- casos: `24`;
- divergen: `24/24`;
- 1-slot pierde: `17`;
- 2-slot pierde: `11`;
- score spread sum: `181.659`;
- spread máximo: `12.769`.

##### revealed_damaging_move

- casos: `24`;
- divergen: `24/24`;
- 1-slot pierde: `12`;
- 2-slot pierde: `7`;
- score spread sum: `224.987`;
- spread máximo: `20.894`.

La divergencia profunda no depende de un único modo de evidencia pública.

---

#### Magnitud de la divergencia

Entre el mejor y peor miembro del empate inmediato después de depth-2:

- spread acumulado: `406.646`;
- spread medio: `8.471`;
- spread máximo: `20.894`.

Esto refuerza que muchos de estos empates no son “casi lo mismo” una vez considerada la continuación.

---

#### Ejemplos auditables

Algunos casos representativos:

- rival Lunatone:
  - Magnemite `-10.951`;
  - Swampert `-14.553`;
  - ganador profundo: Magnemite.

- rival Sandaconda:
  - Braviary `-5.950`;
  - Murkrow `-3.906`;
  - lexical-first Braviary pierde el ganador profundo.

- rival Aron:
  - Basculegion `-4.186`;
  - Drednaw `-3.513`;
  - lexical-first pierde.

- rival Roserade:
  - Delibird `-10.109`;
  - Maushold `-6.829`;
  - lexical-first pierde.

- rival Voltorb:
  - Electrode `-11.283`;
  - Iron Treads `-742`;
  - lexical-first pierde;
  - spread: `10.541`.

- rival Bombirdier:
  - Dracovish `-4.381`;
  - Heatran `-11.566`.

- rival Poliwrath:
  - Golem `-5.352`;
  - Magcargo `-5.401`;
  - incluso aquí un empate inmediato se rompe por solo `49` puntos.

- rival Combusken:
  - Golisopod `-7.193`;
  - Staraptor `-3.311`;
  - lexical-first pierde.

- rival Stoutland:
  - Lilligant `-21.471`;
  - Wobbuffet `-17.526`;
  - lexical-first pierde.

- rival Watchog:
  - Escavalier `-10.984`;
  - Shiftry `-8.173`;
  - lexical-first pierde.

---

#### Coste de preservar los candidatos empatados

C3f-p también registra el coste agregado de la muestra de 48 casos.

##### 1-slot lexical

- root evaluations: `48`;
- simulations: `2.400`.

##### 2-slot lexical

- root evaluations: `96`;
- simulations: `4.800`.

##### top-tier completo

- root evaluations: `168`;
- simulations: `8.424`.

Coste adicional del top-tier completo:

- vs 1-slot: `+6.024` simulaciones;
- vs 2-slot: `+3.624` simulaciones.

Multiplicadores agregados de esta auditoría:

- top-tier completo vs 1-slot: `35.100 bp = 3,51×`;
- top-tier completo vs 2-slot: `17.550 bp = 1,755×`.

Estos multiplicadores describen **el coste agregado de este audit**, no se congelan como predicción exacta del coste de una futura integración productiva. Una política futura podría usar detección de empate, branching adaptativo, presupuestos compartidos u otras técnicas que C3f-p todavía no evalúa.

---

#### Semántica de seguridad congelada

C3f-p congela:

- `production_sampler_unchanged = true`;
- `move_switch_diversity_boundary_preserved = true`;
- `frontier_used_for_depth_selection = false`;
- `roster_value_integrated = false`;
- `recovery_policy_used = false`;
- `replacement_policy_used = false`;
- `campaign_policy_used = false`;
- `live_rng_used = false`;
- hidden belief cases = `0`;
- memory event cases = `0`;
- campaign snapshot cases = `0`;
- `profile_used_as_presearch_tiebreak = false`;
- `profile_varied_across_tied_candidates = false`;
- `selected_sampler_strategy_id = null`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`.

Interpretación canónica:

> **la igualdad del score inmediato de switching no autoriza a colapsar el top-set antes de search. La profundidad puede distinguir candidatos que parecían equivalentes, pero preservar todo el top-tier tiene un coste medible que debe diseñarse explícitamente.**

C3f-p rechaza como política universal segura:

- un representante arbitrario;
- lexical 1-slot;
- lexical 2-slot;
- cualquier cutoff previo que trate la igualdad inmediata como equivalencia profunda.

C3f-p NO autoriza todavía:

- expansión productiva automática de todo el top-tier;
- cambio de `max_actions_per_side`;
- port de un sampler nuevo;
- modificación de `TrainerMultiTurnSearch`;
- modificación de `TrainerActionSpace`;
- integración de Pareto en search;
- integración de roster value en search;
- modificación de brains;
- cambio de comportamiento;
- apertura de FASE34.

---

#### Siguiente microtranche autorizada — C3f-q

C3f-q puede abrirse únicamente como **TEST/AUDIT-ONLY** para estudiar diseños de preservación de empate que intenten conservar la información profunda sin pagar siempre el coste del top-tier completo.

Debe comparar, como mínimo, variantes conceptuales como:

- resolver solo los top-sets realmente empatados, no todos los switches;
- expansión adaptativa del top-tier bajo un budget explícito;
- evaluación incremental/deferred tie resolution;
- límites de 1/2 slots frente a expansión condicionada;
- reutilización o reparto de budget entre candidatos empatados, si puede modelarse en test sin cambiar producción;
- pérdida de óptimo profundo;
- coste en simulaciones/nodos;
- determinismo;
- invariancia al orden de entrada;
- preservación de MOVE/SWITCH diversity.

C3f-q debe mantener fuera:

- lexical como preferencia semántica;
- Pareto como hard pruning;
- roster value como tiebreak prematuro;
- hidden beliefs;
- live RNG;
- campaign/recovery/replacement policy;
- TrainerProfile como desempate accidental.

C3f-q tampoco puede todavía seleccionar/portar una estrategia productiva salvo nueva autorización documental posterior.

`FASE34` sigue **CERRADA**.

PR #105 sigue siendo temporal y **NO DEBE MERGEARSE**.

`main` debe permanecer intacta.


### 26.38 C3f-q — depth-1 reduce coste, pero cap 3 sigue incompatible con preservación profunda sin pérdidas

#### Baseline certificado

C3f-q parte exclusivamente del cierre documental certificado de C3f-p / 26.37:

`f9b26100fac7e6125dfb7c0f561115280ac55228`

No se modificó `main`, no se abrió FASE34 y PR #105 siguió siendo temporal y no mergeable por política del proyecto.

#### Alcance autorizado

C3f-q fue autorizado como **TEST/AUDIT-ONLY** para comparar diseños adaptativos de preservación de empates contextuales antes de cualquier port del sampler a producción.

El objetivo fue responder si se podía conservar la información profunda demostrada por C3f-p sin pagar siempre el coste del top-tier completo y, simultáneamente, sin romper el presupuesto productivo actual `max_actions_per_side = 3` reservando al menos una acción MOVE.

Quedaron fuera de alcance:

- cambios en `TrainerMultiTurnSearch`;
- cambios en `TrainerActionSpace`;
- cambios de `TrainerSearchBudget.depth_two_default()`;
- cambios en brains;
- integración de Pareto en selección;
- integración de roster value en search;
- lexical ordering como preferencia semántica;
- hidden beliefs;
- live RNG;
- recovery/replacement/campaign policy;
- selección o port de una estrategia productiva;
- FASE34;
- merge de PR #105.

#### Implementación audit-only

Suite nueva:

`tests/trainer_ai/trainer_roster_search_tie_adaptive_preservation_audit_test_suite.gd`

Clase:

`TrainerRosterSearchTieAdaptivePreservationAuditTestSuite`

Audit ID:

`c3f_q_adaptive_tie_preservation_cost_audit_v1`

La suite hereda C3f-p y reutiliza exactamente la misma geometría estratificada de datos reales:

- `eligible_species = 1021`;
- `sampled_rosters = 128`;
- `population_scenarios = 512`;
- `population_tie_cases = 306`;
- `population_untied_cases = 206`;
- tasa de contextos con empate inmediato = `5976 bp` = 59,76 %;
- `selected_cases = 48`;
- 12 casos para cada tamaño de empate 2/3/4/5;
- 24 `species_fallback`;
- 24 `revealed_damaging_move`;
- `immediate_tied_root_candidates = 168`.

El runner pasa a iniciar la cadena con:

`TrainerRosterSearchTieAdaptivePreservationAuditTestSuite.new().run(...)`

El diff técnico limpio contra 26.37 contiene exclusivamente:

- suite C3f-q nueva: +711 líneas;
- runner: +2/-2;
- **cero producción**.

El commit automático de staging generado durante la creación del archivo:

`40ecef7a45c87680abcc46104cc64925888c93f3`

no forma parte de la historia limpia certificada.

#### Dos profundidades, mismo marco de presupuesto

Screen barato:

`TrainerSearchBudget.constrained(1, 4, 220, 3)`

Referencia profunda:

`TrainerSearchBudget.depth_two_default()`

Por tanto:

- screen: depth 1, worlds 4, max simulations 220, action cap 3;
- referencia: depth 2, worlds 4, max simulations 220, action cap 3.

Cada uno de los 168 candidatos raíz empatados fue evaluado con `TrainerMultiTurnSearch.evaluate(context, root_action)` tanto a depth 1 como a depth 2.

Resultados de integridad:

- `depth_one_evaluations = 168`;
- `depth_two_reference_evaluations = 168`;
- `search_result_failures = 0`;
- `incomplete_depth_evaluations = 0`;
- `budget_exhausted_evaluations = 0`;
- `world_coverage_failures = 0`;
- `context_build_failures = 0`;
- `reference_depth_divergence_cases = 48`;
- `reference_unique_deep_best_cases = 48`.

C3f-p queda reproducido: todos los 48 empates inmediatos de la muestra vuelven a producir un ganador profundo único a depth 2.

#### Coste base observado

- screening depth 1 de los 168 candidatos: `999` simulaciones;
- referencia top-tier completa depth 2: `8424` simulaciones.

No se modeló reutilización de cache/budget entre depth 1 y depth 2:

`shared_budget_reuse_modeled = false`

La contabilidad adaptativa es deliberadamente conservadora:

`actual depth1 screen + selected depth2 evaluations`.

#### Controles negativos

##### Lexical 1-slot

`lexical_one_slot_negative_control`

- preserva deep optimum: 19/48;
- pierde deep optimum: 29/48;
- simulaciones: 2400;
- violaciones cap3+un MOVE: 0;
- order invariant: false.

##### Lexical 2-slot

`lexical_two_slot_negative_control`

- preserva: 30/48;
- pierde: 18/48;
- simulaciones: 4800;
- violaciones cap3+un MOVE: 0;
- order invariant: false.

Estos controles confirman que limitarse a uno o dos representantes lexicográficos no es una política semánticamente segura.

#### Estrategias adaptativas por margen depth-1

Todas usan únicamente scores de search depth 1 para la preselección, preservan conjuntos completos cuando caen dentro del margen y son input-order invariant en la auditoría.

| Estrategia | Preserva | Pierde | Sims totales | >2 SWITCH / viola cap3+MOVE |
|---|---:|---:|---:|---:|
| `depth1_margin_0` | 40/48 | 8 | 3399 | 0/48 |
| `depth1_margin_500` | 43/48 | 5 | 3999 | 1/48 |
| `depth1_margin_1500` | 47/48 | 1 | 5019 | 5/48 |
| `depth1_margin_3000` | 48/48 | 0 | 5763 | 11/48 |
| `depth1_margin_6000` | 48/48 | 0 | 7965 | 24/48 |

Hallazgo principal:

`depth1_margin_3000` fue la estrategia **cero-pérdidas más barata de las probadas**, pero no queda autorizada ni seleccionada.

Frente a la referencia full-tier:

- full-tier = 8424 simulaciones;
- margin-3000 = 5763;
- ahorro = 2661 simulaciones;
- reducción aproximada = **31,59 %**.

Sin embargo, `depth1_margin_3000` necesita promover más de dos switches en 11/48 casos. Con el cap productivo 3 y la obligación de mantener al menos un MOVE, esos 11 casos no caben en el mismo conjunto bounded de acciones.

El número `3000` es exclusivamente un umbral de auditoría. C3f-q no demuestra que sea una constante semántica generalizable ni autoriza su uso productivo.

#### Estrategias gap + full fallback

| Estrategia | Preserva | Pierde | Sims totales | >2 SWITCH / viola cap3+MOVE |
|---|---:|---:|---:|---:|
| `depth1_gap_500_full_fallback` | 44/48 | 4 | 4791 | 8/48 |
| `depth1_gap_1500_full_fallback` | 48/48 | 0 | 6975 | 19/48 |
| `depth1_gap_3000_full_fallback` | 48/48 | 0 | 8331 | 29/48 |

El fallback conservador puede eliminar pérdidas, pero incrementa precisamente la frecuencia con la que el top-set ya no cabe dentro de cap3+un MOVE.

#### Referencia full top-tier

`full_top_tier_depth_two_reference`

- preserva: 48/48;
- pierde: 0/48;
- candidatos promovidos: 168;
- máximo simultáneo: 5;
- casos con >2 switches: 36/48;
- simulaciones: 8424.

Es semánticamente segura en la muestra respecto al ganador profundo observado, pero incompatible con interpretar `max_actions_per_side = 3` como un único contenedor que además debe mantener diversidad MOVE/SWITCH.

#### Frontera coste–pérdida auditada

El informe identifica, considerando solo pérdida profunda y simulaciones —no autorización productiva—:

`["depth1_gap_500_full_fallback","depth1_margin_0","depth1_margin_1500","depth1_margin_3000","depth1_margin_500"]`

como frontera coste–pérdida entre las variantes contextuales probadas.

Esto **no** constituye ranking semántico ni selección de estrategia.

#### Conclusión C3f-q

C3f-q demuestra simultáneamente cuatro cosas:

1. **Depth 1 contiene señal útil.** El mejor depth-1 único pierde 8/48 deep optima, frente a 29/48 del lexical one-slot.
2. **Se puede ahorrar coste sin observar pérdida profunda en la muestra.** Margin-3000 preservó 48/48 con ~31,59 % menos simulaciones que full-tier.
3. **Ese ahorro no resuelve el límite arquitectónico.** Las variantes cero-pérdidas todavía necesitan más de dos switches en algunos contextos y, por tanto, no caben en cap3 si se reserva al menos un MOVE.
4. **No existe entre las estrategias auditadas una variante que combine simultáneamente `0 deep-optimum loss` y `0 cap3+MOVE violations`.**

Por tanto, el problema ya no debe formularse como «qué representante del empate elegir dentro de los dos slots disponibles». La frontera correcta es comprobar si la resolución del empate contextual raíz debe vivir **fuera del bounded action sampler**, manteniendo el cap3 para las continuaciones internas.

#### Barreras semánticas preservadas

C3f-q certifica:

- `contextual_strategy_reorder_mismatches = 0`;
- preselección contextual basada solo en depth-1 search;
- `frontier_used_for_preselection = false`;
- `roster_value_used_for_preselection = false`;
- `profile_used_as_presearch_tiebreak = false`;
- hidden beliefs = 0;
- memory events = 0;
- campaign snapshot = 0;
- live RNG = false;
- recovery policy = false;
- replacement policy = false;
- campaign policy = false;
- production sampler unchanged;
- no global cap change;
- no production behavior change.

Estado de autorización:

- `selected_strategy_id = null`;
- `production_strategy_selected = false`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`;
- FASE34 permanece CLOSED.

#### Checkpoints certificados

Técnico limpio:

`dbdc23ede1f0d08de89d3fbf24e72a479f60d96c`

Humano tree-identical:

`1a416fe40e0088e9bc48d177046b3ee26b0b0872`

Árbol común:

`67467373d26692c09bf278f647a72fc76c56e140`

Ambos tienen parent directo:

`f9b26100fac7e6125dfb7c0f561115280ac55228`

Certificación técnica:

- 18/18 GitHub Actions SUCCESS;
- FASE33: **732 PASS / 0 FAIL**;
- Godot 4.7 SUCCESS;
- DATA V3 SUCCESS;
- Search Foundation SUCCESS;
- Search Depth Budget SUCCESS;
- Search Limit Benchmark SUCCESS;
- Strategic Switching V2 SUCCESS;
- mismo JSON canónico C3f-q.

Certificación humana:

- 18/18 GitHub Actions SUCCESS;
- FASE33: **732 PASS / 0 FAIL**;
- mismo JSON canónico C3f-q;
- mismo árbol y mismo diff que el técnico.

#### Siguiente microtranche autorizada

Se autoriza **C3f-r — TEST/AUDIT-ONLY root tie-resolution / deferred root-expansion feasibility audit**.

Objetivo: comprobar si los switches pertenecientes al top-set contextual empatado pueden resolverse como una capa de expansión raíz separada del bounded action sampler, dejando `max_actions_per_side = 3` intacto para las continuaciones internas y preservando explícitamente diversidad MOVE/SWITCH.

C3f-r debe comparar al menos:

- bounded sampler actual como control;
- evaluación de cada switch del top-tier contextual como root action explícita, con continuaciones internas manteniendo cap3;
- expansión adaptativa condicionada por señal depth-1, sin convertir ningún umbral C3f-q en constante productiva;
- coste total de simulaciones/nodos por decisión;
- coste máximo y medio por contexto;
- preservación del deep optimum observado;
- input-order invariance;
- determinismo;
- contabilidad explícita de que root fan-out y inner action cap son presupuestos conceptualmente distintos;
- comparación con subir el cap global solo como **negative/control cost model**, no como autorización;
- posibilidad o imposibilidad de fijar un presupuesto total por decisión sin truncar semánticamente el top-tier.

C3f-r **no** puede:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- cambiar production `max_actions_per_side`;
- seleccionar `depth1_margin_3000` ni ningún otro umbral como regla productiva;
- integrar Pareto o roster value en preselección;
- introducir lexical semantic tiebreaks;
- introducir hidden beliefs, RNG o campaign policy;
- modificar brains;
- abrir FASE34;
- mergear PR #105.

Si C3f-r demuestra una separación raíz/continuación segura, bounded y determinista, el siguiente checkpoint podrá decidir si existe base suficiente para un port productivo mínimo. Si no la demuestra, debe congelar el bloqueo en lugar de inventar un desempate.


### 26.39 C3f-r — fan-out raíz separado conserva cap3 interno; diversidad MOVE/SWITCH validada, descarte no-top aún no seguro

C3f-r parte del baseline documental certificado 26.38:

`b079b1871d239afc927dda760e5ca05cae7c0a31`

La microtranche permanece estrictamente **TEST/AUDIT-ONLY**. No modifica `TrainerMultiTurnSearch`, `TrainerActionSpace`, brains, budgets productivos, switching productivo, Pareto productivo ni ninguna política de campaña. `FASE34` permanece cerrada y PR #105 continúa siendo temporal/no mergeable por decisión de proyecto.

#### Objetivo auditado

C3f-q había demostrado que, con el cap productivo actual `max_actions_per_side = 3` y reservando al menos un slot MOVE, ninguna de las estrategias contextuales auditadas podía simultáneamente:

- preservar todos los óptimos profundos observados;
- conservar el cap3 en la raíz;
- y evitar una preferencia arbitraria dentro de los empates contextuales.

C3f-r por tanto no intenta elegir un sampler. Su pregunta es más estrecha:

> ¿Puede separarse el **fan-out de acciones raíz** del `cap3` usado por las continuaciones internas, evaluando explícitamente los switches empatados como raíces independientes y manteniendo el límite productivo de tres acciones por lado dentro de cada búsqueda?

El audit compara además esta arquitectura con el control productivo actual y con el control negativo de aumentar un único cap global.

#### Checkpoints limpios

Checkpoint técnico:

`37d4d1cb6ab8928b5639f32a6e8e29b9b0595e44`

Checkpoint humano tree-identical:

`e1ad264b0b50205bef41de4cd5ae4ee0a2a12596`

Tree común:

`d2889b972888d2f036b9f3bf97abf03460a56f8e`

Ambos commits tienen como parent directo:

`b079b1871d239afc927dda760e5ca05cae7c0a31`

El diff limpio frente a 26.38 contiene únicamente:

- `tests/trainer_ai/trainer_roster_search_root_tie_deferred_expansion_audit_test_suite.gd`: **+961 / 0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**;
- producción: **0**;
- brains: **0**;
- `TrainerMultiTurnSearch`: **0**;
- `TrainerActionSpace`: **0**;
- budgets productivos: **0**;
- workflows persistentes: **0**.

Suite:

`TrainerRosterSearchRootTieDeferredExpansionAuditTestSuite`

Audit ID:

`c3f_r_root_tie_deferred_expansion_feasibility_audit_v1`

La suite hereda la cadena C3f-q → C3f-p → C3f-o → C3f-n → C3f-m → C3f-l → C3f-k, de modo que las barreras anteriores siguen ejecutándose en el mismo gate.

#### API productiva observada: la acción raíz ya puede evaluarse explícitamente

La producción actual expone una separación arquitectónica relevante:

`TrainerMultiTurnSearch.evaluate(context, root_action)`

recibe una acción raíz concreta antes de que las continuaciones internas usen `_bounded_actions(...)`.

C3f-r utiliza exclusivamente esa API existente desde test para evaluar raíces explícitas. No añade ningún método de producción.

Queda por tanto auditada la distinción:

- **root fan-out**: número de acciones raíz que el caller decide evaluar de forma independiente;
- **inner action cap**: `max_actions_per_side = 3` aplicado dentro de las continuaciones de cada raíz.

C3f-r registra explícitamente:

- `explicit_root_action_api_used = true`;
- `root_fanout_is_not_inner_action_cap = true`;
- `inner_max_actions_per_side = 3`;
- `production_global_cap_unchanged = true`;
- `production_sampler_unchanged = true`.

#### Población de referencia

Para mantener comparabilidad exacta con C3f-p/q, el audit reutiliza los mismos **48 contextos de empate**:

- 1021 especies elegibles;
- 512 escenarios de población C3f-m/o;
- 306 contextos con empate inmediato;
- 48 casos estratificados;
- tie size 2: 12 casos;
- tie size 3: 12 casos;
- tie size 4: 12 casos;
- tie size 5: 12 casos;
- `species_fallback`: 24 casos;
- `revealed_damaging_move`: 24 casos;
- 168 candidatos raíz empatados en total.

Budget interno mantenido:

- depth: 2;
- worlds: 4;
- simulations por raíz: 220;
- actions per side: 3.

#### Corrección importante del fixture antes de certificar

Durante C3f-r se detectó que el fixture heredado de C3f-m/p/q construye deliberadamente `legal_actions` únicamente con acciones `SWITCH`.

Ese fixture es válido para comparar semántica y coste entre switches, pero **no puede por sí solo demostrar la obligación MOVE/SWITCH de 26.38**.

La primera formulación de C3f-r intentó leer diversidad no-SWITCH sobre ese fixture y produjo un FAIL. Ese FAIL no se ocultó ni se convirtió artificialmente en PASS.

La corrección certificada separa dos capas:

1. **referencia real SWITCH-only**: conserva exactamente los 48 contextos anteriores para todos los scores profundos, costes y comparaciones C3f-p/q;
2. **mixed-root diversity probe**: usa los cinco IDs de switch legales reales de cada contexto y los top-sets contextuales reales, añadiendo exactamente dos acciones MOVE deterministas **solo para geometría de selección raíz**.

El probe mixto declara explícitamente:

- `reference_context_switch_only = true`;
- `uses_real_switch_ids_and_contextual_top_sets = true`;
- `synthetic_moves_used_for_geometry_only = true`;
- `deep_scores_recomputed_with_synthetic_moves = false`.

Por tanto, los MOVE sintéticos no alteran ningún score profundo ni ninguna conclusión táctica. Solo permiten comprobar de manera limpia que las estrategias de fan-out preservan al menos un MOVE y un SWITCH cuando ambos tipos existen en la raíz.

#### Mixed-root probe — resultado

Casos:

- `cases = 48`;
- `context_failures = 0`;
- `probe_move_count = 2`;
- `adaptive_diversity_failure_cases = 0`;
- `adaptive_reorder_mismatch_cases = 0`.

Control bounded actual sobre geometría mixta:

- MOVE diversity failures: **0/48**;
- SWITCH diversity failures: **0/48**;
- root fan-out máximo: 3;
- reorder mismatch: **48/48**.

Interpretación:

El sampler actual conserva diversidad de tipos bajo esta geometría, pero la identidad del switch retenido continúa dependiendo del orden de entrada.

Full top-tier additive deferred sobre geometría mixta:

- MOVE diversity failures: **0/48**;
- SWITCH diversity failures: **0/48**;
- root fan-out máximo: 7;
- reorder mismatch: **24/48**.

La variante aditiva reduce el sesgo, pero no lo elimina: conserva además cualquier switch que el bounded sampler hubiera seleccionado por orden.

Full top-tier replacement deferred sobre geometría mixta:

- MOVE diversity failures: **0/48**;
- SWITCH diversity failures: **0/48**;
- root fan-out máximo: 7;
- reorder mismatch: **0/48**.

Las variantes adaptive replacement también conservan MOVE/SWITCH en **48/48** y tienen reorder mismatch **0**:

- margin 0: fan-out máximo 3;
- margin 500: máximo 5;
- margin 1500: máximo 6;
- margin 3000: máximo 7;
- margin 6000: máximo 7.

Conclusión limitada:

> Separar el fan-out raíz del cap interno **es compatible con diversidad MOVE/SWITCH**. Esto no demuestra todavía que sea seguro eliminar switches legales que quedan fuera del top-tier contextual inmediato.

#### Control productivo actual — referencia SWITCH-only

Sobre los 48 casos reales comparables:

- cases: 48;
- root evaluations: 144;
- deep optimum preserved: **30/48**;
- deep optimum lost: **18/48**;
- evaluation failures: 0;
- incomplete depth2: 0;
- budget exhausted: 0;
- world coverage failures: 0;
- fan-out sum: 144;
- fan-out max: 3;
- mean fan-out: 3.0000;
- switch reorder mismatch: **48/48**;
- simulations sum: **7200**;
- simulations mean: **150**;
- simulations max: **270**;
- contexts above 220 total-simulation control: **23/48**;
- hard bound: 660.

El dato `non_switch_diversity_failure_cases = 48` en esta referencia no se interpreta como fallo de estrategia: documenta que el fixture de referencia es explícitamente SWITCH-only.

#### Full top-tier additive deferred

Semántica:

- conserva el bounded root sample actual;
- añade cualquier miembro del top-tier contextual que falte;
- por construcción nunca elimina una raíz actualmente muestreada;
- puede retener el sesgo de orden heredado del sampler actual.

Resultado:

- deep optimum preserved: **48/48**;
- lost: **0/48**;
- fan-out sum: 208;
- fan-out max: 5;
- fan-out > inner cap3: **44/48**;
- reorder mismatch: **35/48**;
- bounded sampled switch dropped: **0/48**;
- simulations sum: **10260**;
- simulations mean: **213**;
- simulations max: **450**;
- contexts above 220 total-simulation control: **23/48**;
- hard total simulations bound: **1100**;
- inner cap violation: **0**.

Interpretación:

La variante aditiva demuestra que el fan-out separado puede preservar todos los óptimos profundos observados sin tocar `inner cap3`, pero no resuelve completamente la dependencia de orden.

#### Full top-tier replacement deferred

Semántica:

- conserva las raíces no-SWITCH bounded cuando existen;
- reemplaza el representante SWITCH arbitrario por el top-tier contextual completo;
- no usa lexical como preferencia semántica.

Resultado real SWITCH-only:

- deep optimum preserved: **48/48**;
- lost: **0/48**;
- fan-out sum: 168;
- fan-out max: 5;
- fan-out > inner cap3: **24/48**;
- reorder mismatch: **0/48**;
- bounded sampled switch dropped: **29/48**;
- simulations sum: **8424**;
- simulations mean: **175**;
- simulations max: **450**;
- contexts above 220 total-simulation control: **17/48**;
- hard total simulations bound: **1100**;
- inner cap violation: **0**.

La mejora frente a additive es clara en coste y orden-invariance, pero aparece la nueva frontera semántica crítica:

`dropping_non_top_switch_proven_safe = false`

En **29/48** contextos, replacement elimina el switch que el bounded sampler actual habría retenido porque ese switch no pertenece al top-tier contextual inmediato.

C3f-r **no demuestra** que ese descarte sea seguro contra profundidad. Que un switch no sea máximo para `TrainerStrategicSwitchEvaluatorV2` no implica que no pueda convertirse en la mejor raíz después de la búsqueda multi-turno.

Por eso replacement **no queda autorizado para producción**.

#### Adaptive replacement — coste y preservación

Todas estas estrategias:

- usan solo evidencia contextual pública ya disponible;
- son reorder-invariant en los 48 casos;
- mantienen `inner cap3` sin violaciones;
- no usan Pareto ni roster value;
- no usan lexical como preferencia semántica;
- no se autorizan para producción.

`depth1_margin_0`:

- preserves: 40/48;
- loses: 8/48;
- drops current bounded switch: 48/48;
- fan-out max: 1;
- simulations sum: 3399;
- mean: 70;
- max: 135;
- contexts >220: 0.

`depth1_margin_500`:

- preserves: 43/48;
- loses: 5/48;
- drops current bounded switch: 47/48;
- fan-out max: 3;
- simulations sum: 3999;
- mean: 83;
- max: 315;
- contexts >220: 2.

`depth1_margin_1500`:

- preserves: 47/48;
- loses: 1/48;
- drops current bounded switch: 46/48;
- fan-out max: 4;
- simulations sum: 5019;
- mean: 104;
- max: 405;
- contexts >220: 6.

`depth1_margin_3000`:

- preserves: **48/48**;
- loses: **0/48**;
- drops current bounded switch: **44/48**;
- fan-out max: 5;
- simulations sum: **5763**;
- mean: 120;
- max: 405;
- contexts >220: 8.

`depth1_margin_6000`:

- preserves: 48/48;
- loses: 0/48;
- drops current bounded switch: 36/48;
- fan-out max: 5;
- simulations sum: 7965;
- mean: 165;
- max: 495;
- contexts >220: 12.

El dato más tentador es margin3000: reproduce **0 pérdidas** en la muestra con bastante menos coste que el full top-tier.

Pero C3f-r congela explícitamente que esto **no basta para seleccionarlo**:

- elimina el switch bounded actual en 44/48;
- todavía no se ha evaluado si alguno de esos switches no-top se convierte en el mejor root profundo;
- el hecho de que margin3000 preserve el mejor miembro **dentro del top-tier inmediato** no responde a la seguridad de podar candidatos legales fuera de dicho top-tier.

Por tanto:

`selected_strategy_id = null`

#### Control negativo: subir un único cap global

C3f-r también prueba la alternativa aparentemente sencilla de aumentar el mismo `max_actions_per_side` para que quepan todos los switches empatados y dejar que ese cap mayor se propague también a las continuaciones.

En los 48 casos seleccionados, para conservar el top-tier completo mediante el sampler actual fue necesario:

- cap requerido: **5 en 48/48**;
- histogram: `{"5":48}`;
- cap máximo: 5;
- cap medio: 5.

Resultado del control con cap global 5:

- evaluations: 48;
- completed depth2: **26/48**;
- incomplete depth2: **22/48**;
- budget exhausted: **22/48**;
- result failures: 0;
- world coverage failures: 0;
- simulations sum: 5482;
- mean: 114;
- max: 220;
- entre los 26 casos que sí completaron, score cambiado frente a cap3: **12**.

Así, aumentar un único cap no es una sustitución neutra del root fan-out separado.

Con un budget fijo de 220 simulaciones, el cap mayor aumenta el branching interno y provoca agotamiento/incompletitud en casi la mitad de la muestra.

C3f-r congela:

`global_cap_change_authorized = false`

#### Budget total: separación finita, pero todavía no política final

C3f-r sí demuestra que separar raíces e interior no crea una expansión no acotada.

Para full top-tier additive y replacement, bajo los máximos auditados:

- max root fan-out = 5 en la referencia SWITCH-only;
- max simulations por raíz = 220;
- hard bound = **5 × 220 = 1100 simulaciones** por decisión auditada.

Por eso:

`separate_root_and_inner_budget_is_finitely_bounded = true`

Pero **1100 no queda aceptado como budget productivo**. Es únicamente un límite superior de construcción para la geometría auditada.

El siguiente tranche debe estudiar el coste de preservar todos los switches legales y cómo se comportaría un budget total compartido sin reintroducir poda semánticamente ciega.

#### Contexto prohibido ausente

C3f-r mantiene las barreras anteriores:

- hidden belief cases: 0;
- memory event cases: 0;
- campaign snapshot cases: 0;
- live RNG: false;
- recovery policy: false;
- replacement policy: false;
- campaign policy: false;
- Pareto en root selection: false;
- roster value en root selection: false;
- TrainerProfile como pre-search tiebreak: false.

`TrainerProfile.balanced()` solo satisface la API de búsqueda existente y se mantiene constante; no decide qué candidato raíz entra.

#### Estado de autorización tras C3f-r

C3f-r **sí demuestra**:

1. la API productiva actual permite evaluar acciones raíz explícitas;
2. el fan-out raíz puede separarse del `inner cap3` sin modificar producción;
3. full top-tier additive y replacement preservan 48/48 óptimos profundos observados dentro del top-tier inmediato;
4. replacement elimina la dependencia de orden del conjunto raíz auditado;
5. una sonda mixta real-switch + synthetic-MOVE valida diversidad MOVE/SWITCH para current/additive/replacement/adaptive;
6. subir el cap global a 5 no es equivalente y agota el budget en 22/48 casos;
7. la separación root/inner es finitamente acotable.

C3f-r **no demuestra**:

1. que un switch legal no-top pueda podarse sin riesgo;
2. que replacement sea seguro pese a descartar el bounded switch actual en 29/48;
3. que margin3000 sea seguro pese a descartar el bounded switch actual en 44/48;
4. que 1100 simulaciones sea un budget productivo aceptable;
5. que exista ya una política compartida de budget entre múltiples roots;
6. que deba portarse ningún sampler a producción.

Estado congelado:

- `selected_strategy_id = null`;
- `production_strategy_selected = false`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`;
- `production_sampler_unchanged = true`;
- `production_global_cap_unchanged = true`;
- `dropping_non_top_switch_proven_safe = false`.

Recommended next boundary exacto:

`resolve_non_top_switch_root_semantics_and_total_budget_before_any_sampler_port`

#### Certificación técnica

SHA:

`37d4d1cb6ab8928b5639f32a6e8e29b9b0595e44`

GitHub Actions:

- **18/18 SUCCESS**.

FASE33:

- run `33722312865`;
- job `100543873824`;
- `=== TRAINER TEAM COMPOSITION RESULT: 761 PASS / 0 FAIL ===`;
- `FASE 33 trainer team composition gate satisfied: 761 PASS / 0 FAIL`.

Además:

- Godot 4.7 SUCCESS;
- DATA Foundation V3 SUCCESS;
- Search Foundation SUCCESS;
- Search Depth Budget SUCCESS;
- Search Limit Benchmark SUCCESS;
- Strategic Switching V2 SUCCESS;
- resto de workflows SUCCESS.

#### Checkpoint humano tree-identical

SHA:

`e1ad264b0b50205bef41de4cd5ae4ee0a2a12596`

Tree:

`d2889b972888d2f036b9f3bf97abf03460a56f8e`

Parent:

`b079b1871d239afc927dda760e5ca05cae7c0a31`

La matriz humana reproduce:

- **18/18 SUCCESS**;
- FASE33 run `33722673873`;
- job `100544911610`;
- **761 PASS / 0 FAIL**;
- mismo JSON C3f-r;
- mismos 48/48 full-top preservados;
- mismos 29/48 drops de replacement;
- mismos 44/48 drops de margin3000;
- mismos 22/48 agotamientos del control cap5;
- misma mixed-root diversity sin fallos.

Queda por tanto certificado que el resultado no depende del SHA técnico concreto: técnico y humano son tree-identical y reproducen la misma evidencia.

#### Próxima microtranche autorizada: C3f-s

Se autoriza exclusivamente:

**C3f-s — TEST/AUDIT-ONLY non-top switch root semantics + total-budget preservation**

Objetivo:

Resolver la principal incógnita que impide seleccionar replacement/adaptive: comprobar si los switches legales descartados por el top-tier contextual inmediato pueden convertirse en la mejor raíz después de búsqueda profunda.

C3f-s debe, como mínimo:

- partir del estado certificado 26.39;
- reutilizar los contextos C3f-r donde replacement/adaptive descartan switches legales;
- evaluar **todos los switches legales** como raíces explícitas, no solo el top-tier inmediato;
- ejecutar depth2 con el mismo inner cap3 para cada raíz;
- comparar el mejor root profundo global con el mejor root profundo contenido en el top-tier inmediato;
- medir `non_top_becomes_deep_best_cases`;
- medir `top_tier_contains_global_deep_best_cases`;
- medir `replacement_pruning_loses_global_deep_best_cases`;
- medir `adaptive_margin3000_pruning_loses_global_deep_best_cases`;
- separar ties profundos como conjuntos, sin representative lexical semántico;
- medir root evaluations, simulations sum/mean/max y hard bounds del fan-out legal completo;
- auditar coste frente a controles de budget total sin modificar ningún budget productivo;
- si se modela budget compartido, distinguir claramente un control de coste de una poda semántica;
- mantener una sonda separada MOVE/SWITCH si el fixture profundo continúa siendo SWITCH-only;
- no usar Pareto como pruning, bonus o tiebreak;
- no usar roster value para seleccionar roots;
- no usar hidden beliefs, live RNG, campaign snapshot/policy, recovery o replacement policy;
- no usar TrainerProfile como tiebreak previo;
- producir salida determinista y JSON-serializable;
- mantener `selected_strategy_id = null` salvo autorización documental posterior explícita.

C3f-s **no autoriza**:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- modificar brains;
- cambiar `max_actions_per_side` productivo;
- cambiar `max_simulations` productivo;
- portar replacement o margin3000 a producción;
- integrar Pareto/roster value en search;
- abrir FASE34;
- mergear PR #105.

La decisión sobre cualquier sampler productivo queda bloqueada hasta saber si la poda de switches no-top es semánticamente segura y hasta tener una política de budget total auditada.


### 26.40 C3f-s — el top-tier contextual no es una poda segura: 6/48 óptimos depth2 nacen fuera

C3f-s parte del baseline documental certificado 26.39:

`ff8a7653125ea92a475418cfeecb1818a99ce99d`

La microtranche permanece estrictamente **TEST/AUDIT-ONLY**. No modifica `TrainerMultiTurnSearch`, `TrainerActionSpace`, brains, budgets productivos, switching productivo, Pareto productivo ni ninguna política de campaña. `FASE34` permanece cerrada y PR #105 continúa siendo temporal y no debe mergearse.

#### Pregunta que C3f-s debía resolver

C3f-r había demostrado que separar el fan-out de acciones raíz del `inner cap3` era arquitectónicamente viable y que el top-tier contextual completo podía conservar el mejor continuation observado **dentro del propio top-tier**. Sin embargo, quedaba una frontera semántica sin resolver:

> ¿Puede un switch legal que no pertenece al top-tier inmediato de `TrainerStrategicSwitchEvaluatorV2` convertirse en el mejor root cuando se evalúa con la búsqueda depth2 real?

Mientras esa pregunta no estuviera contestada, eliminar switches no-top antes de search no podía considerarse seguro.

C3f-s amplía por tanto el oracle. Ya no compara únicamente miembros del top-tier inmediato: evalúa **todos los switches legales** como roots explícitos y compara sus valores depth2.

#### Checkpoints limpios

Checkpoint técnico:

`1db4ed3b76aef8a59fed78f43291b45bb0a1dd28`

Checkpoint humano tree-identical:

`30e52bdc51c6ba292e012639b23c5b87ddaa99c2`

Tree común:

`3b3a96da61b88bf3e208cd147ecd48b85b973299`

Ambos commits tienen como parent directo:

`ff8a7653125ea92a475418cfeecb1818a99ce99d`

El diff limpio frente a 26.39 contiene únicamente:

- `tests/trainer_ai/trainer_roster_search_all_legal_switch_root_semantics_audit_test_suite.gd`: **+628 / 0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**;
- producción: **0**;
- brains: **0**;
- `TrainerMultiTurnSearch`: **0**;
- `TrainerActionSpace`: **0**;
- `TrainerSearchBudget`: **0**;
- workflows persistentes: **0**.

Suite:

`TrainerRosterSearchAllLegalSwitchRootSemanticsAuditTestSuite`

Audit ID:

`c3f_s_all_legal_switch_root_semantics_total_budget_audit_v1`

La suite hereda C3f-r y, por esa cadena, C3f-q → C3f-p → C3f-o → C3f-n → C3f-m → C3f-l → C3f-k. Las barreras anteriores continúan ejecutándose en el mismo gate.

#### Oracle ampliado: todos los switches legales

C3f-s conserva exactamente la muestra estratificada de 48 contextos usada por C3f-p/q/r y reconstruye cada contexto sobre DATA V3 canónico.

Geometría:

- especies elegibles: **1021**;
- casos seleccionados: **48**;
- `species_fallback`: **24**;
- `revealed_damaging_move`: **24**;
- switches legales por contexto: **5**;
- roots legales totales: **240**;
- roots evaluados: **240/240**.

Budget por root, sin cambios productivos:

- depth: **2**;
- worlds: **4**;
- `max_simulations`: **220**;
- `max_actions_per_side`: **3**.

Cada switch legal se evalúa mediante la API productiva ya existente:

`TrainerMultiTurnSearch.evaluate(context, root_action)`

La selección del root que entra en el oracle es TEST/AUDIT-ONLY. C3f-s no porta ningún sampler a producción.

#### Integridad del experimento

Resultados de ejecución:

- `context_rebuild_failures = 0`;
- `root_evaluation_failures = 0`;
- `incomplete_depth_two_root_evaluations = 0`;
- `budget_exhausted_root_evaluations = 0`;
- `world_coverage_failure_root_evaluations = 0`;
- `top_tier_score_parity_mismatches = 0`;
- `top_tier_best_set_parity_mismatches = 0`;
- `semantically_complete_cases = 48`;
- `semantically_inconclusive_cases = 0`.

Los 48 contextos producen un único mejor root global depth2:

- `global_deep_unique_best_cases = 48`;
- `global_deep_multiple_best_cases = 0`;
- histograma del best-set global: `{1: 48}`.

Los empates siguen tratados como conjuntos. C3f-s no usa un representante lexical para semántica:

`deep_best_semantics = all_equal_max_score_switch_ids`

`lexical_representative_used_for_semantics = false`

#### Hallazgo principal: el no-top puede ser el mejor root profundo

De los 48 contextos:

- 36 tienen al menos un switch legal fuera del top-tier inmediato;
- 12 no tienen candidatos no-top que podar;
- en **6/48** contextos, el mejor root global depth2 está fuera del top-tier inmediato;
- en los seis casos el ganador no-top es además el **único** óptimo profundo;
- no hubo ningún caso de empate entre un óptimo top-tier y uno no-top.

Exacto:

- `non_top_becomes_deep_best_cases = 6`;
- `non_top_only_deep_best_cases = 6`;
- `non_top_joint_deep_best_cases = 0`;
- `top_tier_contains_global_deep_best_cases = 42`;
- `top_tier_contains_all_global_deep_best_cases = 42`.

Tasas descriptivas de esta muestra:

- sobre los 48 contextos: **6/48 = 12,5 %**;
- entre los 36 contextos donde existe algo no-top que podar: **6/36 = 16,67 %**.

Estas tasas describen exclusivamente la muestra auditada; no son una estimación poblacional ni una probabilidad productiva.

La conclusión semántica sí es categórica para la frontera auditada:

> El top-tier contextual inmediato **no es una poda segura** antes de depth2. Existe evidencia real reproducible de switches no-top que se convierten en el mejor continuation profundo.

#### Seis contraejemplos canónicos

1. `anchor = 552`, `species_fallback`, rival `aron`
   - ganador global: `structural_real_probe_ho_oh` → **-2226**;
   - top-tier inmediato: `basculegion` → -4186, `drednaw` → -3513;
   - `ho_oh` queda fuera del top-tier y gana depth2.

2. `anchor = 696`, `species_fallback`, rival `roserade`
   - ganador global: `structural_real_probe_arboliva` → **-4205**;
   - top-tier inmediato: `delibird` → -10109, `maushold` → -6829;
   - `arboliva` queda fuera del top-tier y gana depth2.

3. `anchor = 672`, `revealed_damaging_move`, rival `combusken`
   - ganador global: `structural_real_probe_cresselia` → **-1270**;
   - top-tier inmediato: `golisopod` → -7193, `staraptor` → -3311;
   - `cresselia` queda fuera del top-tier y gana depth2.

4. `anchor = 816`, `revealed_damaging_move`, rival `stoutland`
   - ganador global: `structural_real_probe_clauncher` → **-15645**;
   - top-tier inmediato: `lilligant` → -21471, `wobbuffet` → -17526;
   - `clauncher` queda fuera del top-tier y gana depth2.

5. `anchor = 936`, `revealed_damaging_move`, rival `watchog`
   - ganador global: `structural_real_probe_nosepass` → **-3153**;
   - top-tier inmediato: `escavalier` → -10984, `shiftry` → -8173;
   - `nosepass` queda fuera del top-tier y gana depth2.

6. `anchor = 248`, `revealed_damaging_move`, rival `scatterbug`
   - ganador global: `structural_real_probe_ursaring` → **-170**;
   - top-tier inmediato: `buizel` → -255, `iron_hands` → -1018, `nidoking` → -1900;
   - `ursaring` queda fuera del top-tier y gana depth2.

#### Impacto directo sobre full top-tier replacement

En C3f-r, `full_top_tier_replacement_deferred` eliminaba todo switch no-top y era order-invariant.

Frente al oracle ampliado de C3f-s:

- contextos donde replacement poda switches legales: **36/48**;
- roots legales podados: **72**;
- contextos donde la poda elimina **todos** los óptimos globales depth2: **6/48**;
- contextos donde elimina al menos un óptimo global: **6/48**.

Exacto:

`replacement_pruning_loses_global_deep_best_cases = 6`

`replacement_pruning_removes_any_global_deep_best_cases = 6`

Por tanto:

`dropping_non_top_switch_proven_safe = false`

Y, después de C3f-s, ya no es solo falta de prueba: existe un contraejemplo positivo repetido seis veces en la muestra.

#### Impacto sobre `depth1_margin_3000`

C3f-q/r había observado que `depth1_margin_3000` preservaba 48/48 de los óptimos **del oracle restringido al top-tier inmediato**.

Contra el nuevo oracle all-legal:

- contextos donde margin3000 poda algún switch legal: **47/48**;
- roots legales podados: **143**;
- contextos donde pierde todos los óptimos globales depth2: **6/48**;
- contextos donde elimina algún óptimo global: **6/48**.

Exacto:

`adaptive_margin3000_pruning_loses_global_deep_best_cases = 6`

`adaptive_margin3000_pruning_removes_any_global_deep_best_cases = 6`

Así, `depth1_margin_3000` tampoco queda autorizado como hard-pruning all-legal.

#### Por qué C3f-s no contradice C3f-q/r

No existe contradicción entre los resultados:

- C3f-p/q/r preguntaban si una estrategia conservaba el mejor continuation **entre los candidatos del top-tier inmediato ya admitidos en el oracle**;
- C3f-s amplía el universo de comparación a **todos los switches legales**;
- los 48/48 anteriores siguen siendo correctos dentro de aquel universo restringido;
- C3f-s demuestra que aquel universo era insuficiente para justificar una poda semántica previa a depth2.

La frontera cambia de:

> «¿Cuál miembro del top-tier debo conservar?»

a:

> «¿Qué evidencia barata puede reducir roots sin eliminar un switch no-top que después gana en profundidad?»

#### Coste de evaluar los cinco roots legales

C3f-s mide el coste real observado de evaluar los cinco switches legales como roots independientes, manteniendo el `inner cap3` intacto.

Resultados:

- root evaluations: **240**;
- simulaciones totales: **12000**;
- media por contexto: **250**;
- máximo por contexto: **450**;
- hard bound por contexto: **1100** = 5 roots × 220 simulaciones/root.

Controles descriptivos de coste:

- contextos >220 simulaciones: **23/48**;
- contextos >440: **23/48**;
- contextos >660: **0/48**;
- contextos >880: **0/48**;
- contextos >1100: **0/48**.

Exacto:

`cost_control_exceed_cases = {220: 23, 440: 23, 660: 0, 880: 0, 1100: 0}`

Importante:

- estos umbrales son **controles de contabilidad**, no políticas;
- `total_budget_controls_are_accounting_only = true`;
- `shared_total_budget_allocation_modeled = false`;
- `cost_control_used_for_semantic_pruning = false`.

C3f-s no autoriza un budget global 660, ni 440, ni ningún otro. Tampoco simula una política de reparto compartido entre roots.

#### Separación root fan-out / inner cap sigue válida

Aunque C3f-s evalúa cinco roots por contexto, cada root mantiene el budget productivo interno:

- `inner_depth_turns = 2`;
- `inner_max_worlds = 4`;
- `inner_max_simulations_per_root = 220`;
- `inner_max_actions_per_side = 3`.

No hubo:

- depth2 incompleto;
- root budget exhaustion;
- fallos de world coverage.

Por tanto, C3f-s conserva el hallazgo arquitectónico de C3f-r:

> El fan-out de raíces puede estudiarse por separado del `max_actions_per_side = 3` de las continuaciones internas.

Lo que C3f-s invalida es usar el top-tier inmediato como hard-filter semántico para decidir qué roots merecen entrar.

#### Mixed-root MOVE/SWITCH probe

El fixture profundo heredado continúa siendo SWITCH-only. Para comprobar la obligación de diversidad sin contaminar los scores, C3f-s mantiene una sonda geométrica separada con dos MOVE sintéticos y los cinco IDs de switch reales.

Resultados:

- casos: **48**;
- context failures: **0**;
- MOVE diversity failures: **0**;
- SWITCH diversity failures: **0**;
- switch reorder root-set mismatches: **0**;
- root fan-out máximo en geometría mixta: **7**.

Los MOVE sintéticos siguen siendo exclusivamente geométricos:

- `synthetic_moves_used_for_geometry_only = true`;
- `deep_scores_recomputed_with_synthetic_moves = false`.

Por tanto, ningún score profundo de C3f-s depende de acciones MOVE artificiales.

#### Contexto prohibido y tiebreaks ausentes

C3f-s mantiene explícitamente fuera del root selection:

- Pareto frontier;
- roster value;
- `TrainerProfile` como tiebreak previo;
- hidden beliefs;
- memory events;
- campaign snapshot;
- RNG vivo;
- recovery policy;
- replacement policy;
- campaign policy;
- lexical preference semántica.

Exacto:

- `frontier_used_for_root_selection = false`;
- `roster_value_used_for_root_selection = false`;
- `profile_used_as_presearch_tiebreak = false`;
- hidden/memory/campaign cases = **0**;
- `live_rng_used = false`;
- recovery/replacement/campaign policy = **false**.

#### Estado de autorización después de C3f-s

C3f-s no selecciona estrategia productiva:

`selected_strategy_id = null`

Y congela:

- `production_strategy_selected = false`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`;
- `production_sampler_unchanged = true`;
- `production_max_actions_unchanged = true`;
- `production_max_simulations_unchanged = true`;
- `production_phase_logic_modified = false`.

No queda autorizada ninguna de estas decisiones:

- full top-tier replacement en producción;
- margin3000 como hard filter;
- expandir siempre los cinco switches productivamente;
- adoptar un total budget 660/440/220;
- cambiar `max_actions_per_side`;
- cambiar `max_simulations`;
- integrar Pareto o roster value en search;
- modificar brains;
- abrir FASE34.

#### Certificación técnica

Checkpoint:

`1db4ed3b76aef8a59fed78f43291b45bb0a1dd28`

Resultado:

- **18/18 GitHub Actions SUCCESS**;
- FASE33 run: `33749085438`;
- FASE33 job: `100628253926`;
- `=== TRAINER TEAM COMPOSITION RESULT: 785 PASS / 0 FAIL ===`;
- `FASE 33 trainer team composition gate satisfied: 785 PASS / 0 FAIL`;
- DATA V3 run `33749085432`: SUCCESS;
- Godot 4.7: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS;
- canonical C3f-s JSON reproduce 240/240 roots y los seis ganadores no-top;
- import registra `TrainerRosterSearchAllLegalSwitchRootSemanticsAuditTestSuite` sin error.

#### Certificación humana tree-identical

Checkpoint:

`30e52bdc51c6ba292e012639b23c5b87ddaa99c2`

Tree:

`3b3a96da61b88bf3e208cd147ecd48b85b973299`

Resultado:

- **18/18 GitHub Actions SUCCESS**;
- FASE33 run: `33749730172`;
- FASE33 job: `100630261780`;
- `=== TRAINER TEAM COMPOSITION RESULT: 785 PASS / 0 FAIL ===`;
- `FASE 33 trainer team composition gate satisfied: 785 PASS / 0 FAIL`;
- DATA V3 run `33749730340`: SUCCESS;
- Godot 4.7: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS;
- mismo JSON C3f-s;
- mismos 240/240 roots;
- mismos seis ganadores no-top;
- mismos costes 12000 / 250 / 450;
- cero fallos de reconstrucción, depth, budget o coverage.

#### Decisión congelada

C3f-s demuestra dos hechos simultáneos:

1. **Semántica:** no es seguro convertir el top-tier contextual inmediato en hard-pruning para depth2. Seis contextos reales del audit tienen un único mejor root profundo fuera de ese top-tier.
2. **Arquitectura/coste:** evaluar todos los switches como roots separados es finitamente acotado y, en esta muestra, no supera 450 simulaciones/contexto; pero C3f-s no modela ni autoriza todavía un scheduler/budget compartido productivo.

Por tanto, la siguiente frontera no puede ser «portar replacement». Primero hay que encontrar si existe un screening barato de **todos los switches legales** que preserve el oracle all-legal depth2 con un coste razonable y una política de budget explícita.

#### Próxima microtranche autorizada

**C3f-t — TEST/AUDIT-ONLY all-legal depth-one screening contra oracle all-legal depth-two + budget-safe root scheduling.**

C3f-t queda autorizada para:

- reutilizar los mismos 48 contextos de C3f-s;
- conservar como ground truth el best-set depth2 calculado sobre **todos los switches legales**;
- calcular evidencia depth1 barata para **todos los switches legales**, no solo para el top-tier inmediato;
- comparar estrategias deterministas de screening, margin, gap y/o fallback que decidan qué roots pasan a depth2;
- medir cuántos óptimos globales all-legal se preservan o pierden;
- medir roots promovidos, simulaciones depth1, simulaciones depth2 y coste total;
- separar explícitamente coste de screening de coste de continuación;
- auditar alternativas de scheduler/budget compartido **solo como contabilidad/test**, sin convertir el agotamiento de budget en una preferencia semántica silenciosa;
- mantener al menos una geometría mixed-root que preserve MOVE/SWITCH cuando ambos tipos existan;
- mantener order invariance;
- tratar empates como conjuntos;
- mantener Pareto, roster value, hidden beliefs, RNG, campaign/recovery/replacement policy y `TrainerProfile` como tiebreak fuera del preselection;
- producir salida determinista y JSON-serializable.

C3f-t **no** queda autorizada para:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- modificar brains;
- cambiar `max_actions_per_side` productivo;
- cambiar `max_simulations` productivo;
- integrar Pareto o roster value en search;
- seleccionar un threshold/scheduler/sampler para producción;
- abrir FASE34;
- mergear PR #105.

La condición para cualquier tranche posterior de port productivo será que C3f-t pueda demostrar, sobre el oracle all-legal de C3f-s, una frontera explícita entre **preservación semántica** y **coste/budget**, sin volver a introducir orden arbitrario ni una poda que elimine los contraejemplos `ho_oh`, `arboliva`, `cresselia`, `clauncher`, `nosepass` o `ursaring`.

Recommended next boundary:

`audit_all_legal_depth_one_screening_against_all_legal_depth_two_oracle_before_any_sampler_port`


### 26.41 C3f-t — depth1 all-legal encuentra 39/48 líderes; margin3000 conserva 48/48 en la muestra con 7053 simulaciones

C3f-t parte del baseline documental certificado 26.40:

`a77e54b7c7f50210281b9df6e34e1fe3450b6ea6`

La microtranche permanece estrictamente **TEST/AUDIT-ONLY**. No modifica `TrainerMultiTurnSearch`, `TrainerActionSpace`, `TrainerSearchBudget`, brains, switching productivo, Pareto productivo, política de campaña ni ninguna superficie de producción. `FASE34` permanece cerrada y PR #105 continúa siendo temporal y no debe mergearse.

#### Pregunta que C3f-t debía resolver

C3f-s había ampliado el oracle desde el top-tier inmediato a **todos los switches legales** y había demostrado una frontera crítica: en 6/48 contextos, el único mejor root depth2 estaba fuera del top-tier inmediato de `TrainerStrategicSwitchEvaluatorV2`.

Por tanto, la pregunta ya no podía ser «qué miembro del top-tier conservar», sino:

> ¿Puede un screen barato, order-invariant y aplicado simétricamente a todos los switches legales reducir el fan-out depth2 sin borrar el óptimo global observado, y cuál es el coste real de hacerlo?

C3f-t responde esta pregunta en la misma muestra certificada de C3f-s mediante un **depth1 all-legal screen** y comparación contra el oracle depth2 all-legal ya certificado.

#### Checkpoints limpios

Checkpoint técnico:

`7d785adc245da6ce0a676242e5e5688b3149f68d`

Checkpoint humano tree-identical:

`f907ba3946a0e5748bb76e5c58e93ba8e2b0142c`

Tree común:

`941ea516f95c5aa533258bf5220433724dca0473`

Ambos commits tienen como parent directo el baseline documental 26.40:

`a77e54b7c7f50210281b9df6e34e1fe3450b6ea6`

El diff limpio frente a 26.40 contiene únicamente:

- `tests/trainer_ai/trainer_roster_search_all_legal_screen_budget_audit_test_suite.gd`: **+749 / 0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**;
- producción: **0**;
- brains: **0**;
- `TrainerMultiTurnSearch`: **0**;
- `TrainerActionSpace`: **0**;
- `TrainerSearchBudget`: **0**;
- workflows persistentes: **0**.

Suite:

`TrainerRosterSearchAllLegalScreenBudgetAuditTestSuite`

Audit ID:

`c3f_t_all_legal_depth1_screen_budget_audit_v1`

La suite hereda C3f-s y, por esa cadena, C3f-r → C3f-q → C3f-p → C3f-o → C3f-n → C3f-m → C3f-l → C3f-k. Todas las barreras anteriores continúan ejecutándose en el mismo gate.

#### Optimización de ejecución sin alterar el experimento

C3f-t no repite innecesariamente el oracle depth2 de C3f-s. La suite cachea TEST-ONLY el resultado exacto de `_collect_c3fs_observations()` durante `super.run()` y reutiliza esas observaciones para el screen depth1.

Esto permite añadir únicamente el trabajo nuevo autorizado:

- 48 contextos;
- 5 switches legales/contexto;
- **240 evaluaciones depth1 all-legal**.

El oracle depth2 de referencia sigue siendo exactamente el de C3f-s:

- 240 roots depth2;
- **12000 simulaciones**;
- máximo observado por contexto: **450**.

No se reduce muestra, no se cambia budget y no se sustituye el oracle por una aproximación.

#### Geometría y budgets

Muestra reutilizada:

- especies elegibles: **1021**;
- casos seleccionados: **48**;
- `species_fallback`: **24**;
- `revealed_damaging_move`: **24**;
- switches legales por contexto: **5**;
- ocurrencias legales: **240**.

Screen depth1:

- depth: **1**;
- worlds: **4**;
- `max_simulations`: **220**;
- `max_actions_per_side`: **3**;
- evaluaciones: **240/240**;
- simulaciones de screen: **1425**.

Oracle depth2:

- depth: **2**;
- worlds: **4**;
- `max_simulations`: **220** por root;
- `max_actions_per_side`: **3**;
- simulaciones de referencia: **12000**.

Integridad del screen:

- `context_attach_failures = 0`;
- `screen_context_failures = 0`;
- `screen_result_failures = 0`;
- `screen_incomplete_depth_evaluations = 0`;
- `screen_budget_exhausted_evaluations = 0`;
- `screen_world_coverage_failures = 0`.

#### Qué tan informativo es depth1

Los 48 contextos de C3f-s tienen un único mejor root depth2. C3f-t mide en qué posición depth1 aparece ese ganador profundo.

Histograma exacto:

- rank 1 → **39**;
- rank 2 → **6**;
- rank 3 → **2**;
- rank 4 → **1**;
- rank 5 → **0**.

Por tanto:

- `deep_best_screen_leader_cases = 39`;
- **39/48 = 81,25 %** de los ganadores depth2 ya son líderes depth1;
- todos los ganadores depth2 de esta muestra están dentro del top-4 depth1.

Gap entre el líder depth1 y el futuro ganador depth2:

- suma: **5665**;
- media: **118**;
- máximo: **1665**.

Esto es evidencia fuerte de que depth1 all-legal contiene señal útil, pero **no demuestra** que rank ≤4 o gap ≤1665 sean invariantes del sistema fuera de esta muestra.

#### Los seis ganadores no-top de C3f-s bajo el screen all-legal

C3f-t caracteriza explícitamente los seis contraejemplos que habían invalidado la poda por top-tier inmediato.

1. `ho_oh` — anchor 552, `species_fallback`, rival `aron`
   - depth1 rank: **1**;
   - gap: **0**;
   - depth1: -1327;
   - depth2: -2226;
   - retenido por top-k 1/2/3/4 y margins 500/1500/3000/6000.

2. `arboliva` — anchor 696, `species_fallback`, rival `roserade`
   - rank: **1**;
   - gap: **0**;
   - depth1: -1201;
   - depth2: -4205;
   - retenido por todas las estrategias auditadas.

3. `cresselia` — anchor 672, `revealed_damaging_move`, rival `combusken`
   - rank: **1**;
   - gap: **0**;
   - depth1: -2735;
   - depth2: -1270;
   - retenido por todas las estrategias auditadas.

4. `clauncher` — anchor 816, `revealed_damaging_move`, rival `stoutland`
   - rank: **2**;
   - gap: **63**;
   - depth1: -5946;
   - depth2: -15645;
   - top-k1 lo elimina;
   - top-k2/3/4 y todos los margins lo retienen.

5. `nosepass` — anchor 936, `revealed_damaging_move`, rival `watchog`
   - rank: **1**;
   - gap: **0**;
   - depth1: -2126;
   - depth2: -3153;
   - retenido por todas las estrategias auditadas.

6. `ursaring` — anchor 248, `revealed_damaging_move`, rival `scatterbug`
   - rank: **3**;
   - gap: **1000**;
   - depth1: -1494;
   - depth2: -170;
   - top-k1: eliminado;
   - top-k2: eliminado;
   - top-k3/4: retenido;
   - margin500: eliminado;
   - margin1500/3000/6000: retenido.

Los seis contraejemplos de C3f-s caben dentro de margin1500. Sin embargo, esto **no convierte margin1500 en seguro**, porque existe otro contexto de la muestra cuyo óptimo profundo sí queda eliminado por margin1500.

#### Familia top-k con empate preservado

C3f-t compara top-k 1/2/3/4 sobre scores depth1. El corte es por **tier de score**, no por representante lexical: un empate en el boundary conserva todos los candidatos empatados.

`lexical_cutoff_used_for_top_k = false`

`top_k_ties_preserved = true`

Resultados:

##### top-k1

- preserva óptimo profundo: **39/48**;
- pierde: **9/48**;
- roots promovidos: 48;
- screen: 1425 simulaciones;
- depth2 promovido: 2400;
- total staged: **3825**;
- máximo/contexto: **135**.

Es barato pero semánticamente insuficiente.

##### top-k2

- preserva: **45/48**;
- pierde: **3/48**;
- roots promovidos: 96;
- depth2: 4800;
- total: **6225**;
- máximo/contexto: **225**.

Sigue siendo inseguro en la muestra.

##### top-k3

- preserva: **47/48**;
- pierde: **1/48**;
- roots promovidos: 144;
- depth2: 7200;
- total: **8625**;
- máximo/contexto: **315**.

No queda autorizado: existe una pérdida positiva.

##### top-k4

- preserva: **48/48**;
- pierde: **0/48**;
- roots promovidos: 192;
- depth2: 9600;
- total: **11025**;
- máximo/contexto: **405**.

Top-k4 tiene cero pérdidas en esta muestra, pero **no se declara seguro ni seleccionado para producción**. 48 casos no establecen un invariante general.

#### Familia de margin all-legal

C3f-t compara margins depth1 de 500/1500/3000/6000 contra el mejor score depth1 del contexto.

##### margin500

- preserva: **44/48**;
- pierde: **4/48**;
- roots promovidos: **63**;
- distribución: 35 casos con 1 root, 11 con 2, 2 con >2;
- depth2: 3126;
- screen: 1425;
- total: **4551**;
- máximo/contexto: **315**.

Inseguro en la muestra.

##### margin1500

- preserva: **47/48**;
- pierde: **1/48**;
- roots promovidos: **87**;
- distribución: 22 con 1 root, 17 con 2, 9 con >2;
- depth2: 4350;
- total: **5775**;
- máximo/contexto: **405**.

Dato importante: **retiene los seis ganadores no-top originales de C3f-s y aun así pierde otro óptimo profundo distinto**. Por tanto, diseñar únicamente alrededor de los seis contraejemplos conocidos sería sobreajuste.

##### margin3000

- preserva: **48/48**;
- pierde: **0/48**;
- roots promovidos: **117**;
- distribución: 9 con 1 root, 19 con 2, 20 con >2;
- depth2: **5628**;
- screen: **1425**;
- total staged: **7053**;
- máximo/contexto: **405**.

Frente al oracle full all-legal de 12000 simulaciones:

- ahorro observado: **4947 simulaciones**;
- coste relativo: **7053 / 12000 ≈ 58,78 %**.

Este es el tradeoff observado más interesante de C3f-t, pero permanece **AUDIT EVIDENCE ONLY**. No se autoriza threshold 3000 ni se selecciona estrategia productiva.

##### margin6000

- preserva: **48/48**;
- pierde: **0/48**;
- roots promovidos: **172**;
- distribución: 0 con 1 root, 10 con 2, 38 con >2;
- depth2: 9204;
- total: **10629**;
- máximo/contexto: **495**.

También cero pérdidas en la muestra, pero con mucho menos ahorro que margin3000.

#### Control sin poda

`all_legal_screen_no_prune_control` hace depth1 a todos y luego depth2 a todos:

- preserva 48/48;
- screen: 1425;
- depth2: 12000;
- total: **13425**;
- máximo/contexto: **495**.

Como era de esperar, añadir un screen sin usarlo para reducir roots solo añade overhead. Sirve como control de contabilidad.

#### Cost-loss frontier descriptivo

El informe calcula una frontera coste/pérdida únicamente descriptiva:

`["depth1_margin_1500_all_legal", "depth1_margin_3000_all_legal", "depth1_margin_500_all_legal", "depth1_topk_1_tie_preserving"]`

Esto **no selecciona** ninguna estrategia:

`cost_loss_frontier_selects_production_strategy = false`

La presencia de una estrategia en esa frontera significa únicamente que no está simultáneamente dominada en los dos ejes observados coste/pérdida dentro de este conjunto de candidatos.

#### Budget compartido: solo contabilidad, no scheduler ejecutado

C3f-t conserva los controles:

`[220, 440, 660, 880, 1100]`

Pero no implementa ni ejecuta un scheduler de budget compartido.

Exacto:

- `shared_budget_controls_are_accounting_only = true`;
- `shared_budget_execution_modeled = false`;
- `equal_reservation_accounting_only = true`;
- `selected_shared_budget = null`.

La tabla de equal reservation hace únicamente lo siguiente:

1. resta del control total el coste observado del screen depth1;
2. divide el remanente por el número de roots promovidos;
3. compara esa cuota con el coste depth2 observado de cada root.

No modela:

- ejecución intercalada;
- early stop;
- redistribución de remanentes;
- starvation temporal;
- prioridad entre roots;
- orden de scheduling;
- truncación real de un root a mitad de búsqueda;
- cache sharing entre roots.

Por tanto, una celda `fit` en esta tabla **no equivale** a demostrar que un scheduler real bajo ese budget conservaría la misma decisión.

#### Ejemplo de budget accounting: margin3000

Para `depth1_margin_3000_all_legal`:

- coste staged total: 7053;
- máximo/contexto: 405;
- contextos con coste >220: **19**;
- >440: **0**;
- >660: **0**;
- >880: **0**;
- >1100: **0**.

Equal reservation — `deep_best_reservation_fit_cases`:

- 220 → **29/48**;
- 440 → **48/48**;
- 660 → **48/48**;
- 880 → **48/48**;
- 1100 → **48/48**.

Esto sugiere que 440 merece ser probado como control en un scheduler real, pero **C3f-t no autoriza budget 440** ni afirma que un scheduler real de 440 sea semánticamente equivalente.

#### Ejemplo de budget accounting: top-k4

Top-k4:

- coste total: 11025;
- máximo/contexto: 405;
- >220: 23 contextos;
- >440: 0.

Equal reservation deep-best fit:

- 220 → 25/48;
- 440 → 48/48;
- 660+ → 48/48.

De nuevo: esto es una sonda de capacidad, no una política ejecutada.

#### Separación root fan-out / inner cap sigue intacta

C3f-t no confunde el número de roots promovidos con `max_actions_per_side` del search interior.

- `root_fanout_is_separate_from_inner_action_cap = true`;
- inner `max_actions_per_side = 3` permanece intacto;
- la geometría mixed MOVE/SWITCH conserva diversidad;
- `move_diversity_failure_cases = 0`;
- `switch_diversity_failure_cases = 0`;
- `switch_reorder_root_set_mismatch_cases = 0`.

La observación de que una estrategia promueva >2 switches no autoriza subir el cap3 ni reemplazar el slot de MOVE. Significa que el fan-out de roots debe seguir tratándose como una capa separada si alguna estrategia de este tipo llegara a diseñarse en producción.

#### Orden e información prohibida

C3f-t conserva:

- `strategy_reorder_mismatch_cases = 0`;
- hidden beliefs: 0;
- memory events: 0;
- campaign snapshot: 0;
- live RNG: false;
- Pareto usado para preselección: false;
- roster value usado para preselección: false;
- profile usado como pre-search tiebreak: false;
- recovery policy: false;
- replacement policy: false;
- campaign policy: false.

No hay filtrado por frontier, no hay bonus de roster, no hay preferencia lexical semántica y no se introduce información rival oculta.

#### Estado de autorización tras C3f-t

Permanece exacto:

- `selected_strategy_id = null`;
- `selected_shared_budget = null`;
- `production_strategy_selected = false`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`;
- producción modificada = false;
- `FASE34` = CLOSED.

C3f-t **no autoriza**:

- portar margin3000;
- portar top-k4;
- portar margin6000;
- cambiar `TrainerMultiTurnSearch`;
- cambiar `TrainerActionSpace`;
- cambiar `TrainerSearchBudget`;
- cambiar `max_actions_per_side`;
- adoptar budget 440/660/etc.;
- integrar Pareto/roster value;
- modificar brains;
- abrir FASE34;
- mergear PR #105.

#### Certificación técnica C3f-t

SHA:

`7d785adc245da6ce0a676242e5e5688b3149f68d`

Resultado:

- **18/18 GitHub Actions SUCCESS**;
- FASE33: **811 PASS / 0 FAIL**;
- Godot general: SUCCESS;
- DATA V3: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS;
- import registra `TrainerRosterSearchAllLegalScreenBudgetAuditTestSuite`;
- JSON C3f-t reproducido exactamente.

#### Certificación humana tree-identical C3f-t

SHA:

`f907ba3946a0e5748bb76e5c58e93ba8e2b0142c`

Tree:

`941ea516f95c5aa533258bf5220433724dca0473`

Resultado:

- **18/18 GitHub Actions SUCCESS**;
- FASE33: **811 PASS / 0 FAIL**;
- mismo JSON C3f-t;
- mismo histograma `39/6/2/1`;
- mismas 1425 simulaciones de screen;
- mismas pérdidas por estrategia;
- mismos costes staged;
- mismas tablas de budget accounting;
- DATA V3/Godot/search/switching gates SUCCESS.

#### Interpretación congelada

C3f-t cambia de forma importante el espacio de diseño, pero todavía no autoriza integración:

1. el screen depth1 aplicado a **todos** los switches legales es mucho más informativo que el top-tier inmediato de switching;
2. 39/48 ganadores depth2 ya son líderes depth1;
3. los 48/48 ganadores auditados quedan en rank ≤4 y gap ≤1665;
4. estrategias agresivas siguen perdiendo óptimos: top-k1 pierde 9, top-k2 pierde 3, top-k3 pierde 1, margin500 pierde 4 y margin1500 pierde 1;
5. top-k4, margin3000 y margin6000 tienen 0 pérdidas en estos 48 casos;
6. margin3000 ofrece el mejor punto observado entre las estrategias 0-loss de la muestra: **7053 vs 12000 simulaciones**;
7. pero cero pérdidas en 48 casos no demuestra seguridad poblacional;
8. y el budget compartido real sigue sin estar modelado/ejecutado.

La frontera correcta pasa a ser:

> ampliar/adversarializar la validación de los candidatos 0-loss de C3f-t y ejecutar semánticas reales de scheduling/budget compartido antes de cualquier port del sampler.

#### Siguiente microtranche autorizada

Queda autorizada únicamente:

**C3f-u — TEST/AUDIT-ONLY broader/adversarial validation of all-legal depth1 screening + executed shared-budget scheduling semantics.**

C3f-u debe, como mínimo:

- partir del baseline documental 26.41 certificado;
- conservar C3f-t/C3f-s como barreras heredadas;
- ampliar la muestra más allá de los mismos 48 casos, con selección determinista y explícita;
- priorizar casos adversariales alrededor de los boundaries observados: rank 3/4, gaps cercanos o superiores a 1500/1665/3000, contextos donde top-k3/margin1500 fallan y diversidad de evidence mode;
- probar al menos `depth1_margin_3000_all_legal` y `depth1_topk_4_tie_preserving` contra un oracle all-legal depth2 más amplio;
- mantener `margin6000` como control conservador si el coste lo permite;
- si ejecutar los 512 contextos completos con cinco roots depth2 viola el timeout, usar una expansión determinista estratificada/adversarial claramente documentada, sin sobreafirmar cobertura no ejecutada;
- medir nuevos deep-best rank/gap máximos y cualquier pérdida de los candidatos 0-loss de C3f-t;
- ejecutar, no solo contabilizar, una semántica TEST-ONLY de budget compartido entre roots;
- comparar al menos controles totales 220/440/660 donde sean técnicamente viables;
- declarar explícitamente el algoritmo de scheduling auditado: orden, quantum o asignación, redistribución de remanente, early stop y condición de truncación;
- permutar el orden de roots para detectar starvation/order dependency;
- medir cuándo un budget compartido cambia el mejor root respecto al oracle sin truncar;
- separar siempre root fan-out del `inner max_actions_per_side = 3`;
- preservar diversidad MOVE/SWITCH en la geometría auditada;
- no usar Pareto como hard prune;
- no usar hidden beliefs, RNG, campaign policy, recovery ni replacement;
- no usar `TrainerProfile` como tiebreak semántico;
- mantener salida determinista y JSON-serializable;
- no seleccionar sampler ni budget productivo todavía.

C3f-u **no queda autorizada** para:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- modificar `TrainerSearchBudget`;
- cambiar `max_actions_per_side` productivo;
- cambiar `max_simulations` productivo;
- integrar frontier/roster value;
- modificar brains;
- abrir `FASE34`;
- mergear PR #105.

La autorización es únicamente para producir evidencia adicional que permita decidir si existe una ruta de sampler/scheduler suficientemente segura para una futura microtranche de diseño productivo.


### 26.42 C3f-u — la validación adversarial ampliada conserva 72/72 y el scheduler compartido solo completa 32/32 con 660 en la muestra

C3f-u queda cerrada como microtranche estrictamente **TEST/AUDIT-ONLY**. Parte del baseline documental 26.41 y amplía la evidencia de C3f-t sin modificar búsqueda productiva, action-space, budgets productivos, brains, Pareto, roster value ni comportamiento.

#### Baseline y checkpoints limpios

Baseline documental 26.41:

`f63665420facd3b001695cc340a7a004efb85e32`

Checkpoint técnico C3f-u:

`fb3b7ac5e04520cfcab1c807dd77db2e4ad3a75d`

Checkpoint humano tree-identical C3f-u:

`259a0bf6fac0f29c640b45f05612487a2038a07d`

Tree común técnico/humano:

`c0afe5b9a28235e8644391fc12a4181e23e8fc09`

Tanto el checkpoint técnico como el humano tienen como parent directo el freeze 26.41 `f6366542...`; por tanto, la historia limpia contiene una sola microtranche audit-only sobre el baseline certificado.

El diff limpio frente a 26.41 contiene únicamente:

- `tests/trainer_ai/trainer_roster_search_broader_adversarial_shared_budget_audit_test_suite.gd`: **+807**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1/-1**.

No hay cambios de producción.

Durante el desarrollo existió un sibling de staging defectuoso que no forma parte de la historia limpia final. Se descartó en vez de encadenar parches sobre él. No se congela una causa raíz no demostrada para ese staging.

#### Suite y modelos auditados

Suite:

`TrainerRosterSearchBroaderAdversarialSharedBudgetAuditTestSuite`

Audit ID:

`c3f_u_broader_adversarial_shared_budget_audit_v1`

Scheduler TEST-ONLY:

`equal_upfront_root_reservation_no_redistribution_v1`

Modelos productivos observados sin modificación:

- search: `simultaneous_depth_budget_v1`;
- action sampling: `kind_stratified_round_robin_v1`;
- inner depth: 2;
- inner `max_actions_per_side`: 3;
- inner `max_worlds`: 4;
- inner `max_simulations` por root: 220.

C3f-u conserva explícitamente la separación entre **root fan-out** y el cap interno de acciones. Expandir roots en el harness no equivale a cambiar `max_actions_per_side` productivo.

#### Expansión determinista de la muestra

C3f-u conserva íntegros los 48 casos certificados de C3f-t y añade 24 casos adversariales nuevos:

- legacy C3f-t: **48**;
- fallos al reutilizar legacy: **0**;
- nuevos adversariales: **24**;
- total expandido: **72**;
- casos semánticamente completos: **72**;
- inconclusos: **0**.

La expansión nueva toma exactamente 3 casos por cada uno de los 8 estratos:

- tie size 2 × `species_fallback`;
- tie size 2 × `revealed_damaging_move`;
- tie size 3 × `species_fallback`;
- tie size 3 × `revealed_damaging_move`;
- tie size 4 × `species_fallback`;
- tie size 4 × `revealed_damaging_move`;
- tie size 5 × `species_fallback`;
- tie size 5 × `revealed_damaging_move`.

La geometría poblacional de referencia sigue siendo:

- eligible species: **1021**;
- tie contexts poblacionales: **306**.

Antes de elegir los 24 nuevos casos se ejecutó el screen depth1 sobre **258 candidatos adversariales no-legacy** y hubo:

- `population_screened_adversarial_candidates = 258`;
- `population_screen_failures = 0`.

No se redujo cobertura para obtener un resultado verde.

#### Rank y gap del ganador depth2 frente al screen depth1

Referencia C3f-t:

- rank máximo: 4;
- gap máximo: 1665.

En los 72 casos C3f-u:

- rank 1 → **54**;
- rank 2 → **11**;
- rank 3 → **5**;
- rank 4 → **2**;
- suma → **72**;
- gap sum → **10121**;
- gap mean → **140**;
- gap max → **1665**.

Solo en los 24 nuevos adversariales:

- rank máximo → **4**;
- gap máximo → **1120**.

Por tanto, la ampliación adversarial no produjo todavía un ganador depth2 fuera de rank 4 ni por encima del gap 1665 observado en C3f-t. Esto es evidencia de muestra, no una cota global demostrada.

#### Candidatos de screen sobre los 72 casos

Se comparan tres candidatos TEST-ONLY contra el oracle all-legal depth2.

**`depth1_margin_3000_all_legal`**

- cases: 72;
- preserves deep optimum: **72**;
- losses: **0**;
- promoted switches sum: 222;
- promoted max: 5;
- screening simulations: 2145;
- depth2 simulations: 11178;
- total simulations: **13323**.

**`depth1_topk_4_tie_preserving`**

- cases: 72;
- preserves deep optimum: **72**;
- losses: **0**;
- promoted switches sum: 288;
- promoted max: 4;
- screening simulations: 2145;
- depth2 simulations: 14496;
- total simulations: **16641**.

**`depth1_margin_6000_all_legal`**

- cases: 72;
- preserves deep optimum: **72**;
- losses: **0**;
- promoted switches sum: 284;
- promoted max: 5;
- screening simulations: 2145;
- depth2 simulations: 15072;
- total simulations: **17217**.

Los tres candidatos conservan el óptimo depth2 en los 72 casos auditados, y `margin3000` sigue siendo el menos costoso de esos tres en esta muestra.

Pero quedan congeladas las barreras:

- `candidate_strategy_proven_safe_globally = false`;
- `candidate_strategy_selected = false`;
- `production_strategy_selected = false`;
- `selected_strategy_id = null`.

**72/72 no equivale a seguridad poblacional ni autoriza un sampler productivo.**

#### Scheduler de budget compartido realmente ejecutado

C3f-u ya no se limita al accounting de C3f-t. Ejecuta un scheduler TEST-ONLY sobre 32 contextos:

- 24 casos adversariales nuevos;
- 8 casos legacy seleccionados por boundary rank/gap;
- total scheduler cases: **32**.

Contrato exacto del scheduler:

- model ID: `equal_upfront_root_reservation_no_redistribution_v1`;
- shared budgets: `[220, 440, 660]`;
- allocation: `equal_upfront_floor_remaining_div_promoted_roots`;
- root order probe: `lexical_and_reverse`;
- redistribution: **none**;
- early stop: **false**;
- truncation condition: `quota_unavailable_or_any_promoted_root_not_depth2_complete_or_budget_exhausted_or_world_coverage_incomplete`.

El scheduler ejecuta las reservas, no infiere su resultado a partir de costes cacheados.

Controles globales:

- budget violations: **0**;
- order probes: **96**;
- forward/reverse allocation mismatches: **0**;
- truncated case occurrences: **22**;
- no-decision occurrences: **22**.

##### Shared budget 220

- cases: 32;
- total-budget violations: 0;
- truncated: **14**;
- no decision: **14**;
- promotion loses global best: 0;
- preserves oracle global best: **18/32**;
- changed best vs oracle: **14**;
- forward/reverse best-set mismatches: 0;
- allocation mismatches: 0;
- quota/root min: 35;
- quota/root mean: 49;
- quota/root max: 102;
- actual simulations sum: 4214.

##### Shared budget 440

- cases: 32;
- total-budget violations: 0;
- truncated: **8**;
- no decision: **8**;
- promotion loses global best: 0;
- preserves oracle global best: **24/32**;
- changed best vs oracle: **8**;
- forward/reverse best-set mismatches: 0;
- allocation mismatches: 0;
- quota/root min: 79;
- quota/root mean: 107;
- quota/root max: 212;
- actual simulations sum: 6646.

##### Shared budget 660

- cases: 32;
- total-budget violations: 0;
- truncated: **0**;
- no decision: **0**;
- promotion loses global best: 0;
- preserves oracle global best: **32/32**;
- changed best vs oracle: **0**;
- forward/reverse best-set mismatches: 0;
- allocation mismatches: 0;
- quota/root min: 123;
- quota/root mean: 156;
- quota/root max: 220;
- actual simulations sum: 7086.

#### Interpretación del budget 660

El resultado de 660 es fuerte pero queda deliberadamente limitado a su dominio observado:

> bajo **este scheduler concreto**, en **estos 32 casos**, shared budget 660 completa todos los roots promovidos y reproduce el mejor set del oracle sin truncar.

No se infiere de ello que:

- 660 sea suficiente para toda la población;
- 660 sea el budget productivo correcto;
- este scheduler sea el scheduler productivo correcto;
- una política con redistribución vaya a comportarse igual;
- `margin3000` sea globalmente seguro.

Por tanto:

- `selected_shared_budget = null`;
- `selected_strategy_id = null`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`.

Los budgets 220 y 440 demuestran además que la semántica de budget compartido **sí importa**: no basta con que el preselector contenga el ganador; starvation/truncation puede impedir completar la comparación.

#### Semántica prohibida sigue ausente

En C3f-u:

- Pareto no se usa como preselector/hard prune;
- roster value no se usa como preselector;
- `TrainerProfile` no se usa como tiebreak pre-search;
- hidden belief cases no vacíos: 0;
- memory event cases no vacíos: 0;
- campaign snapshot cases no vacíos: 0;
- live RNG: false;
- recovery policy: false;
- replacement policy: false;
- campaign policy: false.

Producción permanece intacta:

- sampler productivo unchanged;
- `max_actions_per_side` productivo unchanged;
- `max_simulations` productivo unchanged;
- phase logic productiva unchanged;
- cero modificaciones de brains.

#### Certificación técnica

Checkpoint técnico:

`fb3b7ac5e04520cfcab1c807dd77db2e4ad3a75d`

Resultado:

- **18/18 GitHub Actions SUCCESS**;
- FASE33: **832 PASS / 0 FAIL**;
- Godot 4.7 general SUCCESS;
- DATA V3 SUCCESS;
- Trainer Search Foundation SUCCESS;
- Trainer Search Depth Budget SUCCESS;
- Trainer Search Limit Benchmark SUCCESS;
- Trainer Strategic Switching V2 SUCCESS;
- resto de workflows Trainer SUCCESS;
- suite C3f-u registrada/importada sin regresión de scripts.

#### Certificación humana tree-identical

Checkpoint humano:

`259a0bf6fac0f29c640b45f05612487a2038a07d`

Tree común:

`c0afe5b9a28235e8644391fc12a4181e23e8fc09`

Resultado humano:

- **18/18 GitHub Actions SUCCESS**;
- FASE33: **832 PASS / 0 FAIL**;
- mismo JSON canónico C3f-u;
- mismos 72/72 para `margin3000`, top-k4 y margin6000;
- mismos 14/8/0 truncados para budgets 220/440/660;
- mismo 18/24/32 oracle-best preservation;
- mismos 0 budget violations;
- mismos 0 forward/reverse allocation mismatches;
- DATA V3/Godot/search/switching gates SUCCESS.

#### Interpretación congelada

C3f-u aporta dos resultados nuevos y distintos:

1. la familia all-legal depth1 screen conserva los tres candidatos 0-loss de C3f-t en una expansión determinista a 72 casos, con `margin3000` todavía como el de menor coste observado entre esos tres;
2. el budget compartido deja de ser accounting-only: 220 y 440 truncan casos bajo el scheduler auditado, mientras 660 completa los 32/32 casos scheduler y reproduce el oracle en los 32.

Sin embargo, todavía no existe base suficiente para portar producción porque:

- 72 casos siguen siendo una muestra;
- los 24 nuevos fueron elegidos adversarialmente dentro de la geometría conocida, no son un held-out independiente de la selección de candidato;
- el scheduler se ejecutó solo sobre 32 casos;
- se auditó un único algoritmo de reserva sin redistribución;
- el éxito 32/32 de 660 no constituye una cota global.

La frontera correcta pasa a ser:

> validar fuera de la muestra de selección que `margin3000` conserva el óptimo y que el scheduler/budget observado sigue siendo robusto antes de autorizar cualquier port productivo.

#### Siguiente microtranche autorizada

Queda autorizada únicamente:

**C3f-v — TEST/AUDIT-ONLY held-out validation of the 0-loss screen candidates and shared-budget scheduler robustness before any production port.**

C3f-v debe, como mínimo:

- partir del freeze documental 26.42 certificado;
- heredar C3f-u/C3f-t/C3f-s como barreras;
- construir una muestra determinista **held-out**, no reutilizada para escoger los 24 adversariales de C3f-u;
- mantener diversidad por evidence mode y geometría de tie/rank/gap cuando sea técnicamente posible;
- ejecutar all-legal depth1 screen y oracle all-legal depth2 en esa muestra;
- medir de nuevo `depth1_margin_3000_all_legal`, `depth1_topk_4_tie_preserving` y `depth1_margin_6000_all_legal` sin asumir que siguen siendo 0-loss;
- registrar cualquier counterexample como resultado válido, sin cambiar thresholds para ocultarlo;
- ejecutar el scheduler compartido sobre held-out cases y comprobar truncation, no-decision, oracle-best preservation y order dependency;
- incluir 660 como control observado de C3f-u, pero **no** tratarlo como budget ya seleccionado;
- incluir al menos un control inferior que permita observar de nuevo la frontera de starvation/truncation;
- si se compara una política de redistribución, mantenerla estrictamente TEST-ONLY y reportarla como control, no como selección productiva;
- mantener root fan-out separado de `inner max_actions_per_side = 3`;
- no usar Pareto como hard prune;
- no usar roster value como preselector;
- no usar hidden beliefs, RNG, campaign policy, recovery ni replacement;
- no usar `TrainerProfile` como tiebreak semántico;
- mantener salida determinista y JSON-serializable;
- no seleccionar todavía sampler, scheduler ni budget productivo salvo que una microtranche posterior lo autorice explícitamente.

C3f-v **no queda autorizada** para:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerActionSpace`;
- modificar `TrainerSearchBudget`;
- cambiar `max_actions_per_side` productivo;
- cambiar `max_simulations` productivo;
- integrar frontier/roster value;
- modificar brains;
- abrir `FASE34`;
- mergear PR #105.

FASE34 permanece **CLOSED**. PR #105 sigue siendo temporal y no debe mergearse.


### 26.43 C3f-v — held-out independiente confirma 24/24 para los tres screens; 660 completa 24/24 pero la integración productiva todavía necesita localizar el seam correcto

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / TEST-AUDIT-ONLY**.

C3f-v ejecuta exactamente la única microtranche autorizada por 26.42: validar fuera de la muestra de selección de C3f-u que las tres familias de screening 0-loss observadas seguían preservando el oracle all-legal depth2 y que el scheduler de budget compartido mantenía una frontera reproducible de starvation/truncation.

La conclusión es positiva respecto a la muestra, pero deliberadamente más estrecha que una autorización productiva:

> **los tres candidatos vuelven a conservar el óptimo en 24/24 casos held-out y el scheduler auditado vuelve a completar todos los casos con 660; esto fortalece la evidencia, pero no convierte `margin3000`, 660 ni el scheduler en cotas globales ni autoriza todavía un port directo al search productivo.**

#### Baseline y checkpoints limpios

Baseline documental 26.42:

`c3ce2204c719abf698c7250e49118c40ea747705`

Checkpoint técnico limpio final C3f-v:

`c652fa97fb27f49a2a60142c2558b522b71c1b9f`

Checkpoint humano tree-identical C3f-v:

`7e2b1bbd984cce818c082d075e9b7377c1958943`

Tree común:

`dace26d1d494c7a1e53e1273eaaa0a81cb920849`

Ambos checkpoints limpios tienen como parent directo el baseline documental 26.42. El diff neto contra ese baseline contiene únicamente:

- `tests/trainer_ai/trainer_roster_search_held_out_shared_budget_validation_audit_test_suite.gd`: **+583 / 0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+2 / -2**;
- `.github/workflows/trainer-team-composition-tests.yml`: **+1 / -1**, exclusivamente `timeout 240s -> 360s`;
- producción: **0**;
- brains: **0**;
- `TrainerMultiTurnSearch`: **0**;
- `TrainerActionSpace`: **0**;
- `TrainerSearchBudget`: **0**.

Suite:

`TrainerRosterSearchHeldOutSharedBudgetValidationAuditTestSuite`

Audit ID:

`c3f_v_held_out_shared_budget_validation_audit_v1`

#### Incidente CI durante la certificación humana — timeout del harness, no fallo semántico

La primera pareja técnico/humana construida con el mismo árbol funcional de C3f-v expuso un defecto de infraestructura: el sibling humano `cc7e9759eca37cdf0bf3ba93afff7d827c2904e8` terminó FASE33 con `exit 124` por el `timeout 240s` del workflow.

El log demostró que:

- no había ningún check FAIL;
- import había terminado correctamente;
- el proceso fue cortado por tiempo después de ejecutar C3f-u;
- C3f-v ni siquiera había empezado;
- el mismo árbol funcional había terminado verde en la ejecución técnica previa.

Por tanto el incidente se clasificó como **timeout flaky del gate**, no como nondeterminismo semántico.

La corrección limpia fue exclusivamente ampliar el límite externo de FASE33:

`timeout 240s -> timeout 360s`

No se redujo cobertura, no se alteró ningún expected metric y no se tocó producción. La historia final certificada se reconstruyó directamente desde `c3ce2204...`, dejando fuera el sibling fallido como staging no canónico.

#### Selección held-out — realmente disjunta de C3f-u

C3f-v no toma simplemente «los siguientes 24» del mismo schedule de selección.

El dataset canónico ya contiene dos schedules balanceados. C3f-u trabaja sobre la geometría derivada del schedule con stride `173`; C3f-v construye su población held-out sobre el segundo schedule:

- `held_out_schedule_index = 1`;
- `held_out_schedule_stride = 389`.

Además excluye explícitamente las **72 case keys** utilizadas por C3f-u.

Resultado:

- casos held-out: **24**;
- overlap con C3f-u: **0**;
- candidatos unseen tras exclusión: **243**;
- casos semánticamente completos: **24/24**;
- inconclusos: **0**;
- fallos de oracle: **0**;
- fallos de screen: **0**.

La selección no usa resultados para elegir casos:

- `depth1_scores_used_for_held_out_selection = false`;
- `depth2_scores_used_for_held_out_selection = false`;
- `rank_gap_used_for_held_out_selection = false`;
- rank/gap se miden **después** de seleccionar.

Selection ID:

`balanced_strata_lexical_even_spread_disjoint_from_c3fu_v1`

Base de selección:

`alternate_roster_schedule_then_tie_evidence_strata_then_lexical_even_spread`

#### Balance de estratos

La muestra conserva exactamente 3 casos por cada combinación de:

- tie size `2 / 3 / 4 / 5`;
- evidence mode `species_fallback / revealed_damaging_move`.

Por tanto:

- tie size 2: **6**;
- tie size 3: **6**;
- tie size 4: **6**;
- tie size 5: **6**;
- species fallback: **12**;
- revealed damaging move: **12**.

No existe ningún estrato insuficiente.

#### El held-out amplía la frontera rank/gap observada

Distribución del ganador depth2 según su posición depth1:

- rank 1: **18**;
- rank 2: **3**;
- rank 3: **3**.

Gap depth1 del ganador depth2 respecto al líder depth1:

- suma: **4268**;
- media entera reportada: **177**;
- máximo: **1909**.

Este máximo es material porque supera el máximo previo de C3f-t/u:

`1665 -> 1909`

El hecho de que aparezca una frontera nueva en held-out es precisamente una razón para mantener la interpretación sample-scoped. `margin3000` contiene 1909 en esta muestra; **no se convierte por ello en una cota matemática universal**.

#### Resultado held-out de los tres candidatos

C3f-v vuelve a ejecutar all-legal depth1 screen y oracle all-legal depth2 para cada caso, sin asumir 0-loss.

##### `depth1_margin_3000_all_legal`

- casos: **24**;
- preserva deep optimum: **24/24**;
- pérdidas: **0**;
- counterexamples: **0**;
- roots promovidos: **73**;
- screening simulations: **720**;
- depth2 simulations: **3762**;
- total simulations: **4482**.

##### `depth1_margin_6000_all_legal`

- casos: **24**;
- preserva deep optimum: **24/24**;
- pérdidas: **0**;
- counterexamples: **0**;
- roots promovidos: **88**;
- screening simulations: **720**;
- depth2 simulations: **4722**;
- total simulations: **5442**.

##### `depth1_topk_4_tie_preserving`

- casos: **24**;
- preserva deep optimum: **24/24**;
- pérdidas: **0**;
- counterexamples: **0**;
- roots promovidos: **96**;
- screening simulations: **720**;
- depth2 simulations: **4896**;
- total simulations: **5616**.

Dentro del held-out, `margin3000` vuelve a ser el de menor coste observado entre los tres candidatos 0-loss.

#### Evidencia conjunta C3f-u + C3f-v — descriptiva, no prueba global

Como C3f-v tiene `0` overlap con los 72 casos de C3f-u, puede resumirse descriptivamente la evidencia observada como **96 casos distintos**:

- `margin3000`: **96/96** preservaciones observadas;
- `margin6000`: **96/96** preservaciones observadas;
- top-k4 tie-preserving: **96/96** preservaciones observadas.

Coste observado combinado:

- `margin3000`: **17,805** simulaciones;
- `margin6000`: **22,659** simulaciones;
- top-k4: **22,257** simulaciones.

Esto refuerza `margin3000` como candidato empírico de menor coste entre los tres, pero C3f-v mantiene explícitamente:

`candidate_strategy_proven_safe_globally = false`

`candidate_strategy_selected = false`

`selected_strategy_id = null`

No se selecciona threshold de producción.

#### Scheduler compartido ejecutado sobre held-out

C3f-v reutiliza el mismo scheduler TEST-ONLY de C3f-u:

- model ID: `equal_upfront_root_reservation_no_redistribution_v1`;
- allocation: `equal_upfront_floor_remaining_div_promoted_roots`;
- redistribution: **none**;
- early stop: **false**;
- root order probe: `lexical_and_reverse`;
- budgets: `[220, 440, 660]`.

Se ejecuta sobre los **24 casos held-out**.

Controles globales:

- total budget violations: **0**;
- order probe cases: **72**;
- forward/reverse allocation mismatches: **0**;
- forward/reverse best-set mismatches: **0**.

##### Shared budget 220

- preserva oracle best: **16/24**;
- changed best vs oracle: **8**;
- truncated: **8**;
- no decision: **8**;
- budget violations: 0.

##### Shared budget 440

- preserva oracle best: **22/24**;
- changed best vs oracle: **2**;
- truncated: **2**;
- no decision: **2**;
- budget violations: 0.

##### Shared budget 660

- preserva oracle best: **24/24**;
- changed best vs oracle: **0**;
- truncated: **0**;
- no decision: **0**;
- budget violations: 0.

Por tanto la frontera starvation/truncation se reproduce fuera de la muestra C3f-u: los controles inferiores todavía pueden impedir una decisión completa aunque el screen haya preservado el ganador.

#### Evidencia conjunta del scheduler

Los 32 casos scheduler de C3f-u pertenecen a la muestra previa; los 24 de C3f-v son held-out respecto a los 72 C3f-u. Descriptivamente, sobre **56 casos distintos** ejecutados con el mismo scheduler:

- budget 220: **34/56** preservan oracle best; **22** trunc/no-decision;
- budget 440: **46/56** preservan oracle best; **10** trunc/no-decision;
- budget 660: **56/56** preservan oracle best; **0** trunc/no-decision.

Sin embargo:

- 56 casos siguen siendo una muestra;
- solo se ha auditado un scheduler sin redistribución;
- 660 no es una cota matemática derivada del hard bound de todos los estados posibles;
- no existe todavía semántica productiva congelada para un caso futuro que trunque bajo el shared budget.

C3f-v mantiene por ello:

`budget_660_is_observed_control_not_selected = true`

`selected_shared_budget = null`

`selected_scheduler_id = null`

#### Certificación técnica limpia

Sobre:

`c652fa97fb27f49a2a60142c2558b522b71c1b9f`

resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **852 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS;
- audit C3f-v completo y JSON-serializable;
- cero counterexamples de los tres candidatos en held-out;
- cero budget/order violations.

#### Certificación humana tree-identical

Sobre:

`7e2b1bbd984cce818c082d075e9b7377c1958943`

se reproduce una segunda matriz completa:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **852 PASS / 0 FAIL**;
- mismo audit ID C3f-v;
- mismos 24 casos held-out y 0 overlap;
- mismo histograma de 8 estratos a 3 casos cada uno;
- mismo rank histogram `18 / 3 / 3`;
- mismo gap máximo **1909**;
- mismos `24/24` para margin3000, margin6000 y top-k4;
- mismos scheduler results `16/24`, `22/24`, `24/24` para budgets `220/440/660`;
- mismos `8/2/0` trunc/no-decision;
- DATA V3, Godot, search y switching gates: SUCCESS.

C3f-v queda **DOBLEMENTE CERTIFICADO**.

#### Invariantes externas

Después de la certificación humana C3f-v y antes de este freeze documental:

- PR #105 sigue **OPEN**;
- PR #105 sigue `merged = false`;
- head de PR #105: `7e2b1bbd984cce818c082d075e9b7377c1958943`;
- base: `main`;
- `main` sigue exactamente en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

PR #105 continúa siendo temporal y **NO debe mergearse**.

#### Revisión del seam productivo — C3f-v no certifica un prefilter directo del brain

Antes de convertir el éxito held-out en autorización productiva se releyó la ruta real de search.

`DepthSearchTrainerBrain.choose_action()` recorre actualmente **todas** las `context.legal_actions` como roots y llama a `_search.evaluate(context, action)` por cada acción legal no nula.

En cambio, el cap `max_actions_per_side` y `ACTION_SAMPLING_MODEL = kind_stratified_round_robin_v1` viven dentro de `TrainerMultiTurnSearch.evaluate()`, donde `_bounded_actions()` se utiliza para muestrear respuestas/continuaciones de los estados simulados.

Esto importa porque la cadena C3f-n..v estudió la geometría de preservar candidatos SWITCH frente a ese boundary de sampling/search. No autoriza a introducir sin más `margin3000` como un filtro de `context.legal_actions` en el brain: esa ruta hoy ya evalúa todos los roots legales y un prefilter allí podría eliminar trabajo que la producción actual sí realiza.

Tampoco está demostrado todavía que la misma policy de screen pueda aplicarse simétricamente a:

- own continuation actions;
- opponent continuation actions;
- opponent responses del root;

sin acceder a información que el lado observador no posee o sin cambiar la semántica simultánea.

Por tanto, el éxito 96/96 no se interpreta como permiso para «cambiar el sampler ya». Primero hay que localizar exactamente el seam que la evidencia auditada representa.

#### Decisión congelada después de C3f-v

Quedan demostrados, sample-scoped, estos hechos:

1. un held-out determinista y realmente disjunto vuelve a preservar 24/24 para los tres candidatos;
2. `margin3000` sigue siendo el menor coste observado de los tres candidatos 0-loss sobre 96 casos distintos;
3. el held-out amplía el gap máximo observado de 1665 a 1909 sin producir counterexample para margin3000;
4. el scheduler no-redistribution reproduce starvation en 220/440 y completa 24/24 con 660;
5. la evidencia conjunta del scheduler es 56/56 para 660 sin truncation, pero sigue siendo muestral;
6. no hubo order dependency ni budget violations en el scheduler auditado;
7. el brain productivo ya enumera todas las acciones legales como roots, mientras el sampling cap vive dentro del search de respuestas/continuaciones.

No queda demostrado ni autorizado:

- que `margin3000` sea universalmente seguro;
- que top-k4 o margin6000 deban descartarse globalmente;
- que 660 sea un budget universal;
- que el scheduler auditado sea la policy productiva correcta;
- qué fallback debe usar producción si un shared budget futuro trunca;
- que el screen pueda aplicarse a acciones del oponente sin violar la frontera de información;
- qué llamada concreta de `_bounded_actions()` debe reemplazarse o separarse;
- ningún cambio de conducta productiva.

Por tanto siguen explícitamente en `false/null`:

- `production_strategy_selected`;
- `search_sampling_redesign_authorized`;
- `behavior_integration_authorized`;
- `selected_strategy_id`;
- `selected_scheduler_id`;
- `selected_shared_budget`.

#### Siguiente microtranche autorizada — C3f-w

Queda autorizada únicamente:

**C3f-w — TEST/AUDIT-ONLY production-seam mapping of the validated all-legal screen/shared-budget design before any sampler port.**

C3f-w debe resolver una pregunta más arquitectónica que estadística:

> **¿qué boundary productivo concreto corresponde realmente a la evidencia C3f-n..v, y puede modificarse sin reducir una enumeración que hoy ya es all-legal ni contaminar el modelo de información del oponente?**

Debe, como mínimo:

- mapear todas las llamadas productivas a `_bounded_actions()` dentro de `TrainerMultiTurnSearch` y distinguir su función: root opponent responses, own depth2 continuations y opponent depth2 continuations;
- congelar explícitamente que `DepthSearchTrainerBrain.choose_action()` ya enumera `context.legal_actions` completos y que C3f-w no puede introducir un prefilter de roots del brain por analogía;
- identificar qué call-site o nueva API corresponde realmente a la geometría de switch sampling auditada desde C3f-n;
- demostrar con tests/adapters, no solo comentario, si el screen contextual all-legal puede reconstruirse sobre un estado simulado de continuación usando únicamente información legítima disponible;
- separar own-side screening de opponent-side sampling y comprobar que ninguna propuesta necesita banca/moveset/estado oculto rival;
- auditar si aplicar la misma policy a ambos lados es semánticamente válido o si hace falta una API diferenciada;
- comprobar que root fan-out y `inner max_actions_per_side = 3` continúan siendo conceptos separados;
- mantener `max_simulations = 220` por evaluación productiva sin cambio;
- definir qué resultado contractual debe producir un futuro scheduler si el shared budget trunca o deja roots sin decisión; **no** se permite ocultar ese caso con lexical fallback, frontier, roster value ni current sampler sin declararlo y medirlo;
- determinar si 660 puede siquiera convertirse en un budget productivo en esa arquitectura o si debe permanecer solo como control hasta existir un seam de scheduler explícito;
- producir una conclusión inequívoca de seam: `SAFE_NARROW_SEAM`, `NEEDS_NEW_API` o `BLOCKED`, con razones auditables;
- mantener determinismo y JSON serialization;
- mantener toda la tranche TEST/AUDIT-ONLY.

C3f-w **no queda autorizada** para:

- modificar `TrainerMultiTurnSearch` de producción;
- modificar `TrainerActionSpace`;
- modificar `TrainerSearchBudget`;
- modificar `DepthSearchTrainerBrain` ni brains derivados;
- cambiar `max_actions_per_side` productivo;
- cambiar `max_simulations` productivo;
- seleccionar `margin3000`, top-k4, margin6000, 660 o cualquier scheduler como policy productiva;
- integrar Pareto o roster value en search;
- usar hidden beliefs, memory privada, RNG, campaign/recovery/replacement policy como preselector/tiebreak;
- abrir FASE34;
- mergear PR #105.

La condición para cualquier port posterior será que C3f-w identifique un seam productivo explícito y demuestre que el cambio propuesto no sustituye accidentalmente una enumeración all-legal existente por una poda muestral ni rompe la simetría/información de la búsqueda simultánea.

Recommended next boundary:

`map_validated_screen_and_shared_budget_to_exact_production_search_seam_before_any_sampler_port`


### 26.44 C3f-w — el seam productivo real no coincide con el experimento base; `NEEDS_NEW_API` antes de cualquier port

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / TEST-AUDIT-ONLY**.

C3f-w ejecuta la microtranche de localización del seam exigida por 26.43. Su objetivo no era volver a medir los 96 casos de screening ni seleccionar `margin3000`/660, sino comprobar si la geometría auditada en C3f-n..v podía trasladarse literalmente al search que usa hoy el brain estratégico.

La respuesta ejecutable es inequívoca:

> **NO existe hoy un seam productivo equivalente al experimento C3f-n..v. El brain ya enumera todos los roots legales; el search estratégico efectivo es ItemAware y usa MOVE/SWITCH/ITEM; el cap de acciones vive en tres call-sites internos distintos; `max_simulations` es por root y no compartido; y la perspectiva rival necesita su propio contexto/memoria sanitizados. Por tanto un port directo sería semánticamente incorrecto. `seam_status = NEEDS_NEW_API`.**

Esto no invalida la evidencia C3f-n..v. Esa evidencia sigue demostrando, dentro de sus muestras, la utilidad del screening y la frontera observada del scheduler. C3f-w delimita qué adaptadores/contratos faltan para poder llevar esa evidencia al runtime real sin cambiar de problema a escondidas.

#### Checkpoints C3f-w

Baseline documental 26.43:

`e9681102cfc716128462b5ea43ad54e46b27c5c7`

Checkpoint técnico:

`e6d6ff8ae163dfd805342f97a0e73b4d474d5906`

Checkpoint humano tree-identical:

`3b8697315cb9e30e100b06ca74ca7b3e7119064e`

Tree común:

`07ab7316e0bda7e4d6456cc5cb3036b5ebc69597`

Parent común:

`e9681102cfc716128462b5ea43ad54e46b27c5c7`

Los dos checkpoints son siblings reales: mismo parent y mismo tree.

Diff neto C3f-w contra 26.43:

- `tests/trainer_ai/trainer_roster_search_production_seam_mapping_audit_test_suite.gd`: **+349 / 0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**;
- producción: **0**;
- brains: **0**;
- search productivo: **0**;
- budgets productivos: **0**;
- workflows productivos: **0**.

Suite:

`TrainerRosterSearchProductionSeamMappingAuditTestSuite`

Audit ID:

`c3f_w_search_production_seam_mapping_audit_v1`

#### Hallazgo 1 — el root fan-out productivo ya es all-legal

`DepthSearchTrainerBrain.choose_action()` recorre `context.legal_actions` y llama a `_search.evaluate(context, action)` para cada root legal no nulo.

C3f-w certifica:

- `depth_brain_enumerates_all_legal_roots = true`;
- `depth_brain_uses_bounded_root_prefilter = false`;
- `root_fanout_separate_from_inner_action_cap = true`.

Por tanto el cap `max_actions_per_side = 3` auditado desde C3f-n no es un preselector de roots del brain. Es un límite interno del árbol de search.

#### Hallazgo 2 — el search estratégico efectivo no usa el sampler base MOVE/SWITCH

La cadena real es:

`StrategicSwitchingTrainerBrain -> ItemAwareTrainerBrain -> TrainerItemAwareSearch`.

C3f-w certifica:

- `strategic_brain_extends_item_aware = true`;
- `item_brain_installs_item_aware_search = true`;
- `item_search_overrides_bounded_actions = true`.

C3f-n había instanciado explícitamente `TrainerMultiTurnSearch` y auditado:

`kind_stratified_round_robin_v1`

El search efectivo ItemAware usa:

`move_switch_item_stratified_round_robin_v1`

El probe mixto con cap 3 demuestra una diferencia observable:

Input:

`[move_zero, move_one, switch_zero, potion]`

Sampler base:

`[move_zero, switch_zero, move_one]`

Sampler ItemAware:

`[move_zero, switch_zero, potion]`

Por tanto:

`mixed_action_sampler_probe.signatures_differ = true`

No puede asumirse que una política validada sobre el sampler base MOVE/SWITCH conserva su significado cuando ITEM participa en el sampler efectivo.

#### Hallazgo 3 — `_bounded_actions()` no representa una sola frontera semántica

C3f-w localiza **tres** call-sites internos:

1. respuestas del rival al root;
2. continuaciones propias depth2;
3. continuaciones rivales depth2.

Resultado:

- `bounded_action_call_site_count = 3`;
- `root_opponent_responses = true`;
- `own_depth2_continuations = true`;
- `opponent_depth2_continuations = true`.

Una sustitución global de `_bounded_actions()` introduciría la misma política en tres roles diferentes sin haber demostrado que comparten información disponible, objetivo ni fallback correcto.

#### Hallazgo 4 — el sampler actual no recibe el contexto necesario para un screen contextual

La firma productiva de `_bounded_actions(actions, limit)` no recibe:

- `side_id`;
- `TrainerDecisionContext`;
- `TrainerBattleMemory`.

C3f-w certifica:

- `base_sampler_accepts_side_id = false`;
- `base_sampler_accepts_context = false`;
- `base_sampler_accepts_memory = false`.

Por tanto no existe hoy una API en la que portar limpiamente una selección side-aware/context-aware sin ensanchar el contrato de producción.

#### Hallazgo 5 — 660 compartido no equivale a cambiar `TrainerSearchBudget.max_simulations`

`TrainerMultiTurnSearch.evaluate(context, root_action)` crea un contador local `simulations_used` para esa evaluación de root.

C3f-w certifica:

`max_simulations_scope = per_root_search_evaluate_local_counter`

Con el valor productivo actual:

`production_max_simulations_per_root = 220`

Por ejemplo, cinco roots independientes podrían disponer en conjunto de un hard cap agregado de:

`5 * 220 = 1100`

Eso NO es el scheduler TEST-ONLY C3f-u/v de budget total compartido 660.

C3f-w certifica explícitamente:

- `shared_total_budget_field_present = false`;
- `shared_root_scheduler_api_present = false`;
- `control_660_directly_maps_to_current_budget = false`.

Por tanto **NO** queda autorizado cambiar `max_simulations` de 220 a 660. Hacerlo multiplicaría otra dimensión del coste y no implementaría el scheduler auditado.

#### Hallazgo 6 — la perspectiva rival necesita un contrato propio

`TrainerObservationBuilder` exige una `TrainerBattleMemory` coherente con el `observer_side_id` y restringe información no observada del rival.

C3f-w certifica:

- `observation_builder_requires_matching_observer_memory = true`;
- `observation_builder_restricts_unseen_opponents = true`;
- `multi_search_uses_observation_builder = false`;
- `bounded_sampler_receives_observer_context = false`;
- `reuse_observer_memory_for_opponent_perspective_authorized = false`.

Estados de frontera:

- continuaciones propias: `NEEDS_UPDATED_OBSERVER_CONTEXT_API`;
- continuaciones rivales: `NEEDS_OPPONENT_PERSPECTIVE_API`.

No está demostrado que la misma política de screening sea segura para ambos lados:

`same_screen_policy_both_sides_proven_safe = false`

#### Hallazgo 7 — faltan outcomes explícitos de scheduler

El futuro contrato de budget compartido deberá distinguir, como mínimo:

- `COMPLETE`;
- `TRUNCATED`;
- `NO_DECISION`.

C3f-w no autoriza fallbacks implícitos cuando el budget no completa la matriz:

- lexical fallback: **false**;
- frontier fallback: **false**;
- roster-value fallback: **false**;
- current-sampler fallback: **false**;
- implicit fallback: **false**.

Esto preserva la lección de C3f-u/v: una truncation no puede maquillarse como una decisión válida por conveniencia del runtime.

#### Veredicto ejecutable

C3f-w produce:

`seam_status = NEEDS_NEW_API`

Y conserva:

`behavior_integration_authorized = false`

`search_sampling_redesign_authorized = false`

`production_strategy_selected = false`

`selected_strategy_id = null`

`selected_scheduler_id = null`

`selected_shared_budget = null`

No hay selección productiva de `margin3000`, top-k4, margin6000 ni 660.

#### Certificación técnica

Checkpoint:

`e6d6ff8ae163dfd805342f97a0e73b4d474d5906`

Resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **876 PASS / 0 FAIL**;
- los **24 checks nuevos C3f-w: PASS**;
- JSON C3f-w completo y determinista;
- `seam_status = NEEDS_NEW_API`;
- producción sin cambios.

#### Certificación humana tree-identical

Checkpoint:

`3b8697315cb9e30e100b06ca74ca7b3e7119064e`

Resultado reproducido:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **876 PASS / 0 FAIL**;
- mismo audit ID;
- mismos 24 checks C3f-w;
- mismo JSON semántico;
- mismo `NEEDS_NEW_API`;
- mismo tree `07ab7316e0bda7e4d6456cc5cb3036b5ebc69597`.

C3f-w queda **DOBLEMENTE CERTIFICADO**.

#### Invariantes externas antes del freeze 26.44

- PR #105: **OPEN**;
- PR #105: `merged_at = null`;
- head certificado: `3b8697315cb9e30e100b06ca74ca7b3e7119064e`;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

PR #105 sigue siendo temporal y **NO debe mergearse**.

FASE34 permanece **CLOSED**.

#### Frontera autorizada siguiente — C3f-x

26.44 autoriza únicamente:

**C3f-x TEST/AUDIT-ONLY — diseñar y probar contratos ejecutables para un selector interno side-aware + action-kind-aware y un scheduler de budget total compartido entre roots, preservando semántica ItemAware MOVE/SWITCH/ITEM y outcomes explícitos `COMPLETE/TRUNCATED/NO_DECISION`, antes de cualquier port productivo.**

C3f-x deberá mantener como invariantes:

- producción: **0 cambios**;
- root fan-out productivo continúa all-legal;
- `inner max_actions_per_side = 3` continúa separado del root fan-out;
- el selector recibe explícitamente el lado y contexto sanitizado que necesita;
- ITEM permanece una clase de acción explícita y no se degrada al bucket MOVE;
- la perspectiva rival no reutiliza memoria privada del observer;
- el scheduler posee un budget **total compartido entre roots**, no un `max_simulations` por-root maquillado;
- outcomes mínimos: `COMPLETE`, `TRUNCATED`, `NO_DECISION`;
- no lexical fallback;
- no frontier fallback;
- no roster-value fallback;
- no hidden-belief fallback;
- no Profile como tiebreak semántico;
- no campaign/recovery/replacement policy;
- no seleccionar todavía estrategia, scheduler ni budget productivos;
- mantener `candidate_strategy_proven_safe_globally = false`;
- mantener C3f-s/t/u/v/w como evidencia previa intacta;
- FASE34 sigue CLOSED;
- PR #105 sigue OPEN/unmerged;
- `main` no se toca.

Si C3f-x demuestra que esos contratos no pueden aislarse sin un rediseño amplio del comportamiento del Trainer, deberá **parar y documentar el blocker** en vez de ensanchar scope.

Cualquier integración de producción deberá esperar a una autorización documental posterior y separada.


### 26.45) Freeze C3f-x — contrato TEST-ONLY side-aware/action-kind-aware + shared-total scheduler certificado; política todavía no seleccionada

C3f-x parte exclusivamente del freeze canónico 26.44:

`86cef6432d03ef44c1d30de5a72da96dfb64cb1d`

26.44 había cerrado C3f-w con:

`seam_status = NEEDS_NEW_API`

y había autorizado únicamente diseñar/probar, en TEST/AUDIT, dos contratos ejecutables antes de cualquier port productivo:

1. un selector interno **side-aware + action-kind-aware + perspective-aware**;
2. un scheduler que posea **un único budget total compartido entre roots**.

C3f-x no modifica producción ni selecciona todavía una policy de reducción, scheduler o budget productivos.

#### Checkpoints certificados

| checkpoint | SHA |
|---|---|
| técnico C3f-x | `460475b8522b94febd9d30dc467b0deeff209fd9` |
| humano tree-identical | `f94ce24da85d88f065cc71c67f671c77f85e468b` |
| tree común | `eb739b8cebf25c3a9981817ea2638279c0839d72` |
| parent común | `86cef6432d03ef44c1d30de5a72da96dfb64cb1d` |

Los checkpoints técnico y humano son **siblings reales**:

- mismo parent;
- mismo tree;
- ningún commit técnico está en la ancestry del humano;
- el segundo checkpoint reproduce el mismo contenido bajo un SHA distinto.

#### Diff exacto de C3f-x

Respecto a 26.44:

- `tests/trainer_ai/trainer_roster_search_contract_api_design_audit_test_suite.gd`: **+581**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1/-1**;
- producción: **0 cambios**;
- brains: **0 cambios**;
- `TrainerMultiTurnSearch`: **0 cambios**;
- `TrainerActionSpace`: **0 cambios**;
- `TrainerSearchBudget`: **0 cambios**;
- ItemAware production search: **0 cambios**;
- workflows permanentes: **0 cambios**.

Audit ID:

`c3f_x_search_contract_api_design_audit_v1`

Estado contractual:

`CONTRACT_API_ISOLATABLE_POLICY_UNSELECTED`

#### Incidente de ejecución detectado y corregido antes de certificar

El primer intento técnico de C3f-x fue:

`5c851af8aee2b1bde4d002b5242bf2ed37129519`

Ese intento obtuvo:

- 17/18 workflows SUCCESS;
- Trainer Team Composition: FAILURE;
- FASE33: **878 PASS / 29 FAIL**.

El import de Godot había pasado. El fallo real era uno solo, dentro de la construcción del informe C3f-x:

`budget_reports[String(budget)] = ...`

Godot 4.7 reportó que no existía un constructor `String` válido para ese entero. Como el informe abortó antes de construirse, quedó `{}` y las 29 comprobaciones posteriores fallaron en cascada.

Por tanto, **29 FAIL no representaban 29 contradicciones del contrato**. Representaban un único error de ejecución previo a sus aserciones.

La corrección fue estrictamente mecánica:

`String(budget)` -> `str(budget)`

No se modificó:

- ninguna expectativa semántica;
- ningún outcome esperado;
- ninguna cuota;
- ningún límite;
- ningún fallback;
- ninguna policy;
- ningún archivo productivo.

Para mantener la disciplina anti-ciclo, el intento fallido y el staging de corrección fueron retirados de la historia canónica. C3f-x se reconstruyó limpiamente desde 26.44 y produjo el técnico definitivo `460475b8...`.

#### Contrato TEST-ONLY del selector

Contract ID:

`side_aware_action_kind_aware_fail_closed_selector_contract_v1`

Roles modelados explícitamente:

- `root_opponent_response`;
- `own_depth2_continuation`;
- `opponent_depth2_continuation`.

El contrato exige:

- `side_id` explícito;
- perspectiva sanitizada explícita;
- correspondencia entre role, side y perspectiva;
- MOVE, SWITCH e ITEM como clases de acción explícitas;
- `inner limit = 3`;
- ninguna reutilización de memoria privada del observer para construir perspectiva rival.

Cuando las acciones caben completas en el límite, el selector no necesita reducir semánticamente y devuelve:

`COMPLETE`

Probe ejecutado con tres acciones:

- MOVE: 1;
- SWITCH: 1;
- ITEM: 1.

Resultado:

- input: **3**;
- selected: **3**;
- los tres kinds preservados exactamente.

Cuando existen **4 acciones para cap 3** y todavía no hay una policy semántica seleccionada, el contrato no inventa una decisión:

`NO_DECISION`

Reason:

`semantic_overflow_policy_not_selected`

Selected signature:

`[]`

Esto es deliberadamente fail-closed.

#### Frontera de perspectiva rival

Un contexto rival sanitizado y explícitamente separado se acepta en el probe:

`opponent_perspective_probe = COMPLETE`

En cambio, intentar reutilizar memoria privada del observer como perspectiva del oponente produce:

`NO_DECISION`

Reason:

`opponent_perspective_cannot_reuse_observer_private_memory`

También se rechaza una discrepancia role/perspective/side con:

`NO_DECISION`

De esta forma C3f-x no convierte una conveniencia de implementación en permiso para usar información que el lado simulado no debería poseer.

#### Sin desempate lexical encubierto

C3f-x mantiene explícitamente:

`lexical_fallback_authorized = false`

`canonicalization_used_for_behavior = false`

El probe forward/reverse comprueba únicamente invariancia de **set** cuando no hace falta reducción. La ordenación lexical usada para telemetría/comparación no participa en la selección de conducta.

#### Contrato TEST-ONLY del scheduler compartido

Contract ID:

`shared_total_equal_quota_no_redistribution_contract_v1`

El scheduler de contrato posee:

- un único `shared_total_budget`;
- hard cap local por root: **220**;
- cuotas upfront iguales;
- redistribución: **0**;
- outcomes explícitos: `COMPLETE`, `TRUNCATED`, `NO_DECISION`;
- ninguna decisión implícita cuando no existe presupuesto suficiente.

Roots del probe, en simulaciones solicitadas:

- root_0: 40;
- root_1: 80;
- root_2: 120;
- root_3: 130;
- root_4: 130.

Total requerido para completar ese probe:

**500** simulaciones.

##### Control 220

Quota upfront:

**44** por root.

Allocations:

- root_0: 40;
- root_1: 44;
- root_2: 44;
- root_3: 44;
- root_4: 44.

Resultado:

- simulations allocated: **216**;
- unused budget: **4**;
- complete roots: **1**;
- truncated roots: **4**;
- budget violations: **0**;
- global outcome: `TRUNCATED`.

##### Control 440

Quota upfront:

**88** por root.

Allocations:

- root_0: 40;
- root_1: 80;
- root_2: 88;
- root_3: 88;
- root_4: 88.

Resultado:

- simulations allocated: **384**;
- unused budget: **56**;
- complete roots: **2**;
- truncated roots: **3**;
- budget violations: **0**;
- global outcome: `TRUNCATED`.

##### Control 660

Quota upfront:

**132** por root.

Allocations:

- root_0: 40;
- root_1: 80;
- root_2: 120;
- root_3: 130;
- root_4: 130.

Resultado:

- simulations allocated: **500**;
- unused budget: **160**;
- redistributed simulations: **0**;
- complete roots: **5**;
- truncated roots: **0**;
- budget violations: **0**;
- global outcome: `COMPLETE`.

##### Control budget 0

Resultado:

- allocations: **0** en todos los roots;
- simulations allocated: **0**;
- no-decision roots: **5**;
- global outcome: `NO_DECISION`.

#### Invariancia ante orden de roots

El probe forward/reverse sobre budget 440 reproduce:

- mismas allocations por root: **true**;
- mismos outcomes por root: **true**.

No se introduce dependencia del orden de enumeración de roots.

#### 660 sigue sin ser equivalente al budget productivo actual

C3f-x mantiene explícitamente la distinción descubierta en C3f-w:

- hard cap actual por evaluación/root observado: **220**;
- cinco roots independientes a 220 podrían permitir hasta **1100**;
- control shared-total auditado: **660**.

Por tanto:

`1100 != 660`

C3f-x demuestra que una API de shared-total budget **puede aislarse en test**. No demuestra que el runtime actual ya posea esa semántica ni autoriza a reinterpretar `max_simulations = 220` como 660 compartido.

#### Certificación técnica definitiva

Checkpoint:

`460475b8522b94febd9d30dc467b0deeff209fd9`

Resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **907 PASS / 0 FAIL**;
- **31/31 checks nuevos C3f-x: PASS**;
- JSON C3f-x completo;
- JSON determinista y serializable;
- selector contract: PASS;
- scheduler contract: PASS;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS;
- Item Actions: SUCCESS;
- Loadouts: SUCCESS;
- cero producción modificada.

#### Certificación humana tree-identical

Checkpoint:

`f94ce24da85d88f065cc71c67f671c77f85e468b`

Tree común:

`eb739b8cebf25c3a9981817ea2638279c0839d72`

Parent común:

`86cef6432d03ef44c1d30de5a72da96dfb64cb1d`

Resultado reproducido:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **907 PASS / 0 FAIL**;
- mismos **31/31 checks C3f-x: PASS**;
- mismo `audit_id`;
- mismo `contract_status = CONTRACT_API_ISOLATABLE_POLICY_UNSELECTED`;
- mismos probes del selector;
- mismos outcomes 220/440/660/0 del scheduler;
- mismas allocations y unused budgets;
- mismo root-order probe;
- mismas barreras de información;
- mismos `null/false` productivos.

C3f-x queda **DOBLEMENTE CERTIFICADO**.

#### Qué demuestra C3f-x

C3f-x resuelve la pregunta inmediata de 26.44:

1. el missing seam de C3f-w puede representarse mediante contratos aislados sin modificar producción;
2. un selector puede exigir role, side y perspectiva sanitizada de forma explícita;
3. MOVE/SWITCH/ITEM pueden preservarse como kinds separados;
4. un overflow sin policy seleccionada puede fallar cerrado en vez de introducir un fallback no auditado;
5. una perspectiva rival puede mantenerse separada de la memoria privada del observer;
6. un scheduler puede poseer un budget total compartido, con cuotas deterministas y outcomes explícitos;
7. `TRUNCATED` y `NO_DECISION` pueden permanecer visibles en vez de convertirse en decisiones implícitas;
8. root fan-out all-legal y `inner max_actions_per_side = 3` siguen siendo conceptos separados.

#### Qué NO demuestra ni autoriza C3f-x

C3f-x **no** demuestra:

- que `margin3000` sea globalmente seguro;
- que 660 sea un budget universal;
- que el scheduler de contrato sea la policy productiva correcta;
- que el selector fail-closed sea por sí solo suficiente para producción;
- que la policy validada en C3f-u/v se comporte correctamente en los tres roles ItemAware;
- que se pueda portar el contrato sin adaptar APIs productivas;
- que una perspectiva rival productiva ya exista con todos los datos sanitizados necesarios.

C3f-x **no autoriza**:

- modificar `TrainerMultiTurnSearch`;
- modificar `TrainerItemAwareSearch`;
- modificar `TrainerActionSpace`;
- modificar `TrainerSearchBudget`;
- modificar brains;
- modificar `max_actions_per_side`;
- modificar `max_simulations`;
- integrar un adapter productivo;
- seleccionar `margin3000`, top-k4, margin6000, 660 o scheduler como policy productiva;
- lexical fallback;
- frontier fallback;
- roster-value fallback;
- hidden-belief fallback;
- Profile como desempate;
- campaign/recovery/replacement policy;
- abrir FASE34.

Permanecen explícitamente:

`candidate_strategy_proven_safe_globally = false`

`behavior_integration_authorized = false`

`production_adapter_authorized = false`

`production_files_modified = false`

`selected_strategy_id = null`

`selected_scheduler_id = null`

`selected_shared_budget = null`

`fase34_open = false`

#### Invariantes externas antes del freeze 26.45

Después de la certificación humana:

- PR #105: **OPEN**;
- PR #105: `merged = false`;
- head certificado: `f94ce24da85d88f065cc71c67f671c77f85e468b`;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

PR #105 continúa siendo temporal y **NO debe mergearse**.

FASE34 permanece **CLOSED**.

#### Decisión congelada

C3f-w había determinado que el runtime productivo necesita una API nueva antes de portar la evidencia de C3f-n..v.

C3f-x demuestra que esa frontera nueva es **aislable y testeable**, pero deja deliberadamente la policy semántica sin seleccionar:

`contract_status = CONTRACT_API_ISOLATABLE_POLICY_UNSELECTED`

No hay contradicción entre ambos resultados:

- C3f-w: la API productiva actual no basta;
- C3f-x: la API que falta puede definirse con contratos ejecutables estrechos y fail-closed;
- siguiente paso: probar una policy candidata **a través de esos contratos aislados**, todavía sin adapter productivo.

#### Siguiente microtranche autorizada — C3f-y

26.45 autoriza únicamente:

**C3f-y — TEST/AUDIT-ONLY candidate-screen policy-through-contract audit sobre los roles ItemAware antes de cualquier production adapter.**

Boundary exacto:

`test_candidate_screen_policy_through_isolated_contract_on_item_aware_roles_before_any_production_adapter`

C3f-y podrá usar como **candidato de test**, no como selección productiva, la evidencia sample-scoped previa de C3f-u/v. En particular, `depth1_margin_3000_all_legal` puede ser ejercitado porque fue el candidato 0-loss de menor coste observado sobre los 96 casos distintos de C3f-u+v, pero deberá conservar:

`candidate_strategy_proven_safe_globally = false`

C3f-y deberá, como mínimo:

- mantener toda la tranche **TEST/AUDIT-ONLY**;
- no repetir sin necesidad la selección held-out C3f-v;
- pasar una candidate screen policy a través del contrato aislado C3f-x;
- cubrir explícitamente los tres roles: root opponent response, own depth2 continuation y opponent depth2 continuation;
- preservar MOVE/SWITCH/ITEM como clases explícitas en el camino ItemAware;
- usar perspectivas sanitizadas y side-aware;
- impedir reutilización de memoria privada del observer para decisiones del oponente;
- comprobar overflow y failure outcomes sin lexical/current-sampler/frontier/roster-value fallback oculto;
- mantener root fan-out all-legal separado del inner cap 3;
- usar 660 únicamente como control observado si hace falta medir el scheduler, no como budget productivo seleccionado;
- conservar outcomes `COMPLETE/TRUNCATED/NO_DECISION` visibles;
- registrar cualquier counterexample como evidencia válida;
- parar y documentar `BLOCKED` si la policy no puede pasar por los contratos ItemAware sin ampliar la frontera de información o cambiar conducta productiva;
- producir JSON determinista y serializable;
- conservar C3f-s/t/u/v/w/x intactos;
- producción: **0 cambios**;
- FASE34: **CLOSED**;
- PR #105: OPEN/unmerged;
- `main`: sin cambios.

C3f-y **no queda autorizada** para integrar ningún adapter en producción, seleccionar globalmente `margin3000` o 660, ni convertir evidencia muestral en garantía universal.

Cualquier port productivo deberá esperar una autorización documental posterior y separada.


### 26.46) Freeze C3f-y — candidate switch screen atravesado por contrato ItemAware; blocker cross-kind documentado

C3f-y parte exclusivamente del freeze canónico 26.45:

`ab92bf275517afe62e3a9d8c6ff4b39320c6a720`

26.45 autorizaba únicamente probar en TEST/AUDIT el candidato `depth1_margin_3000_all_legal` a través de los tres roles ItemAware, sin producción y sin globalizar la evidencia C3f-u/v.

#### Checkpoints certificados

| checkpoint | SHA |
|---|---|
| técnico C3f-y reconstruido tree-identical | `1a6b3ca17a2a7e25ec9e026f5a0e4b9dbeb2ff5b` |
| humano tree-identical | `cfbbc52b69a5b6893667bfd9696aea7d44c602df` |
| tree común | `1946ec045a3a8f79baa329f8f8476296763cedf0` |
| parent común | `ab92bf275517afe62e3a9d8c6ff4b39320c6a720` |

Son siblings reales: mismo parent, mismo tree, mismo contenido y ninguno desciende del otro.

La cronología fue excepcional y queda registrada sin maquillarla: el humano `cfbbc52b...` ya existía y estaba certificado cuando, al retomar la sesión, no se pudo recuperar un objeto técnico sibling previo fiable. Para restaurar el protocolo sin alterar contenido se reconstruyó después el técnico `1a6b3ca...` usando exactamente el tree del humano y el parent 26.45. Ese técnico reconstruido fue sometido de nuevo a la matriz completa. No se afirma que existiera cronológicamente antes del humano.

#### Diff exacto de C3f-y

Respecto a 26.45:

- `tests/trainer_ai/trainer_roster_search_candidate_policy_contract_item_aware_audit_test_suite.gd`: **+513**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1/-1**;
- producción: **0 cambios**;
- brains: **0 cambios**;
- `TrainerMultiTurnSearch`: **0 cambios**;
- `TrainerItemAwareSearch`: **0 cambios**;
- `TrainerSearchBudget`: **0 cambios**;
- workflows permanentes: **0 cambios**;
- FASE34: **CLOSED**.

Audit ID:

`c3f_y_candidate_policy_through_item_aware_contract_audit_v1`

Estado:

`BLOCKED`

Blocker:

`cross_kind_candidate_screen_policy_undefined`

Reason:

`validated_margin_candidate_has_switch_only_evidence_and_no_authorized_cross_kind_item_aware_composition_policy`

#### Evidencia conservada sin globalizar

El candidato sigue siendo `depth1_margin_3000_all_legal`, con scope **switch_only**.

Evidencia previa C3f-u + C3f-v:

- casos distintos observados: **96**;
- deep optimum preservado observado: **96/96**;
- pérdidas observadas: **0**;
- evidencia: sample-scoped SWITCH candidates only;
- `candidate_strategy_proven_safe_globally = false`.

C3f-y no vuelve a seleccionar la muestra held-out ni convierte 96/96 en prueba universal.

Membership rule ejercitada:

`switch_depth1_score_gte_best_switch_depth1_score_minus_3000`

#### Tres roles ItemAware

Se ejercitan explícitamente:

1. `root_opponent_response`;
2. `own_depth2_continuation`;
3. `opponent_depth2_continuation`.

Los tres exigen side, role y perspectiva sanitizada coherentes, preservan MOVE/SWITCH/ITEM como kinds distintos y mantienen `inner max_actions_per_side = 3` separado del root fan-out all-legal.

#### Probe sin reducción

Con exactamente una MOVE, una SWITCH y una ITEM, las tres acciones caben en cap 3 y no hace falta preferencia cross-kind.

Resultado en los tres roles:

`COMPLETE`

#### Probe SWITCH-only con overflow

Con cuatro SWITCH sí existe evidencia aplicable. C3f-y usa margin3000 dentro de su dominio:

- input SWITCH: **4**;
- cap: **3**;
- selected SWITCH: **3**;
- membership coincide con margin3000;
- forward/reverse conserva el mismo set;
- lexical no selecciona conducta.

Esto demuestra únicamente que el candidato puede atravesar el contrato en su dominio switch-only.

#### Probe mixed-kind con overflow

Con MOVE + SWITCH + SWITCH + ITEM aparece el blocker real. Margin3000 solo define selección entre SWITCH. No existe todavía una semántica autorizada para:

- comparar MOVE vs SWITCH vs ITEM;
- reservar slots por kind;
- reducir múltiples MOVEs;
- reducir múltiples ITEMs;
- componer candidatos per-kind bajo cap 3.

Usar margin3000 sobre SWITCH y rellenar el resto con el round-robin ItemAware actual introduciría una preferencia cross-kind no auditada. C3f-y no lo hace.

Resultado en los tres roles:

`NO_DECISION`

El overflow mixto queda fail-closed.

#### Sampler ItemAware actual

Modelo observado:

`move_switch_item_stratified_round_robin_v1`

Se mantiene:

`current_item_aware_round_robin_reused_as_candidate_policy = false`

`current_sampler_fallback_used = false`

El sampler actual no se promociona silenciosamente a policy semántica cross-kind.

#### Información rival y fallbacks

Reutilizar memoria privada del observer como perspectiva rival devuelve `NO_DECISION` antes de aplicar policy.

Siguen prohibidos como fallbacks/tiebreaks ocultos:

- lexical;
- frontier;
- roster value;
- Profile;
- current sampler;
- hidden belief;
- campaign snapshot;
- recovery;
- replacement;
- reserva ITEM inventada.

#### Scheduler y budget

C3f-y no reejecuta ni selecciona scheduler/budget productivo:

- `selected_strategy_id = null`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `shared_scheduler_reexecuted = false`;
- 660 sigue no seleccionado;
- 220 productivo no se reinterpreta como shared-total.

#### Certificación humana

`cfbbc52b69a5b6893667bfd9696aea7d44c602df`

- **18/18 workflows SUCCESS**;
- FASE33: **935 PASS / 0 FAIL**;
- **28/28 checks nuevos C3f-y PASS**;
- `tranche_status = BLOCKED`;
- JSON determinista/serializable;
- cero producción.

#### Certificación técnica reconstruida

`1a6b3ca17a2a7e25ec9e026f5a0e4b9dbeb2ff5b`

- **18/18 workflows SUCCESS**;
- FASE33: **935 PASS / 0 FAIL**;
- **28/28 checks nuevos C3f-y PASS**;
- mismo audit ID, blocker, probes y null/false productivos;
- mismo tree que el humano.

C3f-y queda **DOBLEMENTE CERTIFICADO**, con la anomalía cronológica de reconstrucción técnica documentada explícitamente.

#### Qué demuestra C3f-y

C3f-y demuestra de forma estrecha que:

1. el contrato ItemAware puede preservar todo cuando no requiere reducción;
2. margin3000 puede operar en overflow SWITCH-only, su dominio auditado;
3. margin3000 no define por sí solo una semántica MOVE/SWITCH/ITEM;
4. completar slots mediante fallback no auditado ampliaría la semántica;
5. el contrato puede detectar esa ampliación y devolver `NO_DECISION`;
6. la perspectiva rival puede fallar cerrado antes de selección;
7. el blocker se localiza sin modificar producción.

No demuestra ni autoriza que margin3000 sea globalmente seguro, que pueda comparar SWITCH con MOVE/ITEM, que deba reservarse un slot por kind, que el round-robin ItemAware sea la policy correcta, que 660 deba seleccionarse ni que exista ya un adapter productivo seguro.

Se mantiene:

`production_strategy_selected = false`

`production_adapter_authorized = false`

`production_files_modified = false`

`candidate_strategy_proven_safe_globally = false`

`fase34_open = false`

#### Invariantes externas

- PR #105: **OPEN**;
- PR #105: **merged = false**;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`;
- head humano antes del freeze: `cfbbc52b69a5b6893667bfd9696aea7d44c602df`.

PR #105 sigue temporal y **NO debe mergearse**.

#### Decisión documental del blocker

C3f-y exige `blocker_requires_documentary_decision = true`. 26.46 resuelve esa decisión **sin autorizar producción**.

El siguiente paso no es portar margin3000. Es diseñar y comparar una semántica cross-kind explícita en TEST/AUDIT, manteniendo margin3000 limitado al subconjunto SWITCH para el que existe evidencia.

#### Frontera autorizada siguiente — C3f-z

26.46 autoriza únicamente:

**C3f-z — TEST/AUDIT-ONLY cross-kind MOVE/SWITCH/ITEM composition-policy design under sanitized side-aware ItemAware perspectives before any production adapter.**

C3f-z deberá mantener:

- producción, brains, `TrainerMultiTurnSearch` y `TrainerItemAwareSearch`: **0 cambios**;
- root fan-out all-legal intacto y separado de inner cap 3;
- los tres roles ItemAware;
- side/perspective sanitizados y role-matching;
- memoria privada del observer prohibida para perspectiva rival;
- MOVE/SWITCH/ITEM separados;
- margin3000 limitado a SWITCH;
- `candidate_strategy_proven_safe_globally = false`;
- ningún score cross-kind inventado;
- ninguna reserva 1 MOVE + 1 SWITCH + 1 ITEM asumida como correcta por definición;
- lexical solo para telemetría;
- ItemAware round-robin solo como control, no como preferencia semántica implícita;
- frontier/roster/Profile/campaign/recovery/replacement fuera de tiebreaks ocultos;
- scheduler/660 sin reselección;
- strategy/scheduler/shared-budget siguen `null`;
- FASE34 CLOSED;
- PR #105 OPEN/unmerged;
- `main` intacto.

C3f-z deberá distinguir como mínimo:

1. no-reduction: preservar todo si cabe;
2. switch-only overflow: margin3000 solo en su dominio;
3. mixed overflow con como máximo una MOVE y una ITEM: probar explícitamente una composición narrow, sin asumirla segura;
4. múltiples MOVEs o múltiples ITEMs: sin selector per-kind auditado, `NO_DECISION`;
5. perspectiva rival inválida: `NO_DECISION` antes de selección.

El resultado deberá ser explícitamente uno de:

- `SAFE_TEST_CONTRACT`;
- `NEEDS_MORE_POLICY`;
- `BLOCKED`.

26.46 no predecide cuál. Cualquier adapter o cambio productivo requiere freeze documental posterior y separado.


### 26.47 C3f-z — contrato narrow cross-kind ItemAware certificado; producción sigue bloqueada hasta mapear perspectiva y scores simulados

Estado: **CERRADO / DOBLEMENTE CERTIFICADO / TEST-AUDIT-ONLY**.

C3f-z parte exclusivamente del freeze canónico 26.46:

`366eb2d1fc02efbbaaa0a2dcd645ab88e52b54c2`

26.46 autorizaba diseñar en TEST/AUDIT una semántica cross-kind explícita MOVE/SWITCH/ITEM, manteniendo `depth1_margin_3000_all_legal` restringido al subconjunto SWITCH y fallando cerrado cuando hiciera falta una preferencia per-kind o cross-kind no auditada.

#### Checkpoints certificados

| checkpoint | SHA |
|---|---|
| técnico C3f-z | `7204228408a14ad4a768903b86d108831be819cb` |
| humano tree-identical | `729f83b73a96e17561d867f65deee27ba1299eb2` |
| tree común | `62de286d2a0adb57e72222c4d1836f233be10a00` |
| parent común | `366eb2d1fc02efbbaaa0a2dcd645ab88e52b54c2` |

Son siblings reales: mismo parent, mismo tree, mismo contenido y ninguno desciende del otro.

#### Diff exacto de C3f-z

Respecto a 26.46:

- `tests/trainer_ai/trainer_roster_search_cross_kind_composition_policy_audit_test_suite.gd`: **+551 / 0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**;
- producción: **0 cambios**;
- brains: **0 cambios**;
- `TrainerMultiTurnSearch`: **0 cambios**;
- `TrainerItemAwareSearch`: **0 cambios**;
- `TrainerSearchBudget`: **0 cambios**;
- documentación dentro de los checkpoints técnico/humano: **0 cambios**;
- workflows permanentes: **0 cambios**;
- FASE34: **CLOSED**.

Audit ID:

`c3f_z_cross_kind_item_aware_composition_policy_audit_v1`

Resultado:

`tranche_status = SAFE_TEST_CONTRACT`

Policy ID TEST-ONLY:

`preserve_single_move_single_item_plus_switch_margin3000_fail_closed_v1`

Precondición narrow:

`at_most_one_move_at_most_one_item_switch_subset_resolves_with_margin3000_without_secondary_reduction`

#### Política narrow demostrada

C3f-z separa explícitamente MOVE, SWITCH e ITEM y demuestra únicamente esta composición estrecha:

1. si el conjunto completo cabe en el cap, se preserva completo;
2. si existe overflow únicamente dentro de SWITCH, `margin3000` puede reducir **solo el subconjunto SWITCH**;
3. si hay como máximo una MOVE y como máximo una ITEM, y el subconjunto SWITCH queda reducido exactamente hasta los slots restantes sin necesitar una segunda preferencia, el contrato puede devolver `COMPLETE`;
4. si hay múltiples MOVEs, devuelve `NO_DECISION`;
5. si hay múltiples ITEMs, devuelve `NO_DECISION`;
6. si margin3000 todavía deja demasiados SWITCH para los slots disponibles, devuelve `NO_DECISION`;
7. una perspectiva rival inválida falla cerrado antes de selección.

La policy no introduce un score cross-kind y no afirma que MOVE, SWITCH e ITEM sean comparables numéricamente.

#### Qué permanece explícitamente prohibido

No se autoriza ningún fallback para completar slots mediante:

- orden lexical;
- current ItemAware round-robin;
- Pareto frontier;
- roster value;
- Trainer Profile;
- beliefs ocultas;
- campaign/recovery/replacement policy.

El round-robin ItemAware actual se conserva únicamente como **control observable**, no como policy candidata implícita.

`margin3000` continúa restringido al dominio SWITCH para el que existe evidencia sample-scoped.

#### Resultado sobre los casos de frontera

El audit certifica que:

- no-reduction preserva todos los actions;
- narrow mixed composition puede completar cuando no exige escoger entre dos MOVEs ni dos ITEMs;
- multiple-MOVE overflow -> `NO_DECISION`;
- multiple-ITEM overflow -> `NO_DECISION`;
- unresolved SWITCH overflow -> `NO_DECISION`;
- observer-private memory para perspectiva rival -> rechazado;
- role/perspective mismatch -> rechazado;
- lexical ordering no participa en conducta;
- root fan-out all-legal permanece separado del inner cap 3.

#### Evidencia previa conservada sin globalizar

C3f-z no reabre la selección held-out C3f-v.

El candidato `depth1_margin_3000_all_legal` conserva únicamente la evidencia previa:

- dominio auditado: SWITCH candidates;
- casos distintos C3f-u + C3f-v: **96**;
- deep optimum observado preservado: **96/96**;
- pérdidas observadas: **0**;
- `candidate_strategy_proven_safe_globally = false`.

Los controles scheduler previos permanecen históricos:

- 220 / 440 / 660 pueden seguir apareciendo como controles auditados;
- `660` **NO** queda seleccionado;
- `max_simulations = 220` productivo **NO** se reinterpreta como shared-total;
- no se ejecuta un port de scheduler.

#### Certificación técnica

Checkpoint:

`7204228408a14ad4a768903b86d108831be819cb`

Resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **965 PASS / 0 FAIL**;
- **30/30 checks nuevos C3f-z: PASS**;
- audit ID correcto;
- `tranche_status = SAFE_TEST_CONTRACT`;
- JSON determinista y serializable;
- policy narrow y probes fail-closed: PASS;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Search Foundation: SUCCESS;
- Search Depth Budget: SUCCESS;
- Search Limit Benchmark: SUCCESS;
- Strategic Switching V2: SUCCESS;
- Item Actions: SUCCESS;
- Loadouts: SUCCESS;
- cero producción modificada.

#### Certificación humana tree-identical

Checkpoint:

`729f83b73a96e17561d867f65deee27ba1299eb2`

Resultado reproducido:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Trainer Team Composition: **965 PASS / 0 FAIL**;
- mismos **30/30 checks C3f-z: PASS**;
- mismo audit ID;
- mismo `tranche_status = SAFE_TEST_CONTRACT`;
- misma policy ID y precondición narrow;
- mismos probes `COMPLETE` / `NO_DECISION`;
- mismas barreras de información;
- mismos `null/false` productivos;
- mismo tree que el técnico.

C3f-z queda **DOBLEMENTE CERTIFICADO**.

#### Qué demuestra C3f-z

C3f-z resuelve el blocker exacto de C3f-y de forma estrecha:

1. existe una composición cross-kind TEST-ONLY que no necesita inventar un score MOVE-vs-SWITCH-vs-ITEM;
2. margin3000 puede mantenerse confinado al subconjunto SWITCH;
3. el contrato puede preservar una MOVE y una ITEM cuando ninguna clase exige preferencia interna adicional;
4. los casos fuera de esa precondición pueden permanecer `NO_DECISION` en vez de ocultar una policy nueva;
5. la frontera de información rival puede seguir fail-closed;
6. el resultado es aislable, determinista y JSON-serializable.

#### Qué NO demuestra ni autoriza C3f-z

`SAFE_TEST_CONTRACT` significa seguro **como contrato de test bajo sus precondiciones**, no seguro como integración productiva.

C3f-z no demuestra:

- que la policy narrow cubra todos los estados reales ItemAware;
- que multiple-MOVE o multiple-ITEM puedan resolverse sin otra policy;
- que margin3000 sea globalmente seguro;
- que exista un score cross-kind válido;
- que el runtime actual disponga del contexto necesario en `_bounded_actions(actions, limit)`;
- que los tres call-sites internos puedan construir la misma perspectiva;
- que una perspectiva oponente productiva pueda reutilizar memoria privada del observer;
- que los scores SWITCH del estado raíz sean válidos para un estado simulado posterior;
- que 660 sea un budget productivo;
- que exista ya un production adapter seguro.

Permanecen explícitamente:

`production_strategy_selected = false`

`production_adapter_authorized = false`

`behavior_integration_authorized = false`

`candidate_strategy_proven_safe_globally = false`

`production_files_modified = false`

`selected_strategy_id = null`

`selected_scheduler_id = null`

`selected_shared_budget = null`

`fase34_open = false`

#### Invariantes externas

Después de la certificación humana C3f-z:

- PR #105: **OPEN**;
- PR #105: `merged = false`;
- head humano certificado: `729f83b73a96e17561d867f65deee27ba1299eb2`;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

PR #105 continúa siendo temporal y **NO debe mergearse**.

#### Hallazgo de seam que gobierna la siguiente tranche

La lectura productiva posterior a C3f-z confirma que el contrato narrow todavía no tiene un punto de inserción equivalente en runtime:

- `TrainerItemAwareSearch._bounded_actions()` recibe únicamente `(actions, limit)`;
- los tres call-sites viven dentro de `TrainerMultiTurnSearch.evaluate()`;
- cada call-site representa un role diferente del árbol simulado;
- un screen contextual necesita una perspectiva sanitizada correspondiente al side/role simulado;
- un screen SWITCH necesita scores calculados para el **estado simulado correcto**, no scores heredados del root por conveniencia;
- reutilizar la memoria privada del observer como conocimiento del oponente continúa prohibido.

Por tanto el siguiente paso no es integrar C3f-z en producción. Primero hay que demostrar qué información legítima existe —o falta— en cada role y de dónde puede obtenerse el score SWITCH sin cruzar la frontera de información.

#### Siguiente microtranche autorizada — C3f-aa

26.47 autoriza únicamente:

**C3f-aa — TEST/AUDIT-ONLY simulated-perspective and SWITCH-score source mapping for the three ItemAware continuation roles before any production adapter.**

Boundary exacto:

`map_sanitized_simulated_perspective_and_switch_score_sources_per_item_aware_role_before_any_adapter`

C3f-aa deberá, como mínimo:

- permanecer estrictamente **TEST/AUDIT-ONLY**;
- mapear por separado los tres roles ya localizados: root opponent response, own depth2 continuation y opponent depth2 continuation;
- identificar para cada role el `side_id`, estado simulado y perspectiva necesaria;
- comprobar si las APIs productivas actuales pueden construir una perspectiva sanitizada legítima para ese role;
- comprobar si existe una fuente productiva legítima para recalcular los scores SWITCH sobre ese estado simulado;
- prohibir expresamente reutilizar scores SWITCH calculados sobre el estado raíz si el estado simulado ha cambiado;
- prohibir reutilizar memoria privada del observer como memoria/perspectiva del oponente;
- distinguir, por role, un resultado explícito como `EXISTING_API_SUFFICIENT`, `NEEDS_ADAPTER` o `BLOCKED_BY_INFORMATION_BOUNDARY`;
- si un role necesita API nueva, declararlo y fallar cerrado; no inventar contexto sintético;
- mantener MOVE/SWITCH/ITEM separados;
- conservar la policy C3f-z como contrato narrow TEST-ONLY, sin portarla todavía;
- mantener root fan-out all-legal separado del inner cap 3;
- no seleccionar strategy/scheduler/shared budget;
- no reabrir 660 como budget productivo;
- no modificar production, brains, search, budgets ni action space;
- producir JSON determinista y serializable;
- FASE34: CLOSED;
- PR #105: OPEN/unmerged;
- `main`: intacto.

C3f-aa deberá terminar con una conclusión arquitectónica inequívoca sobre si cada role puede alimentar el contrato narrow C3f-z usando únicamente información válida. Cualquier adapter productivo requerirá un freeze documental posterior y separado.
