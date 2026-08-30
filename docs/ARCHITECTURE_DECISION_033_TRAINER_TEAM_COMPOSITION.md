# ADR-033 — Trainer Team Composition V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACION.

## Contexto

FASE 32 convirtió naturaleza, IVs, EVs, habilidad, held item y moveset en un loadout atómico y validable por Pokémon. Eso resuelve la coherencia individual, pero no impide crear un entrenador con seis loadouts buenos que, juntos, repitan el mismo rol, acumulen una debilidad evidente o carezcan de cobertura ofensiva.

FASE 33 introduce una capa de equipo sin sustituir el diseño manual. Un equipo authored puede ser deliberadamente temático o imperfecto; el sistema debe distinguir legalidad de preferencias de composición.

## Decisión

Se añaden cinco componentes:

- `TrainerTeamDefinition`: contrato versionado del equipo y su lead;
- `TrainerTeamValidator`: legalidad estructural y validación recursiva de loadouts;
- `TrainerTeamAnalyzer`: diagnóstico explicable de roles, tipos, cobertura y debilidades compartidas;
- `TrainerTeamComposer`: composición automática greedy, determinista y acotada;
- `TrainerTeamFactory`: materialización de un equipo validado a roster de `CreatureInstance`.

### Contrato y legalidad

`TrainerTeamDefinition` contiene:

- `team_id`;
- lista ordenada de `TrainerPokemonLoadout`;
- `lead_index`;
- política `allow_duplicate_species`;
- `source_id`.

La legalidad usa `PartyRuleset.MAX_PARTY` como única fuente del máximo de seis. Cada miembro debe superar `TrainerLoadoutValidator`. Los duplicados de especie están prohibidos por defecto pero son configurables por equipo; no se impone Item Clause ni otras reglas competitivas que el juego base no haya decidido adoptar.

### Análisis de composición

`TrainerTeamAnalyzer` no altera el equipo. Expone:

- distribución de roles;
- tipos defensivos de las especies;
- tipos de ataques dañinos realmente equipados;
- debilidad por tipo ofensivo rival;
- número de resistencias/inmunidades disponibles frente a cada tipo;
- tipos rivales cubiertos de forma super eficaz;
- debilidades compartidas;
- debilidades compartidas sin una respuesta resistente;
- `synergy_score` explicable para comparación interna del compositor.

El score premia diversidad de roles y ataques, presencia de support/velocidad y mezcla física-especial; penaliza acumulaciones fuertes de tipo y debilidades compartidas sin respuesta. Es una heurística V1, no una medida universal de calidad competitiva.

### Composición automática

`TrainerTeamComposer` recibe pool de especies, nivel, tamaño, calidad y política de duplicados. Para cada hueco prueba los roles disponibles mediante `TrainerRoleLoadoutGenerator`, descarta loadouts inválidos y selecciona determinísticamente el candidato con mejor combinación de:

- análisis del equipo parcial;
- afinidad de stats base con el rol;
- pequeña preferencia explícita por roles todavía no representados.

El algoritmo es greedy y deliberadamente acotado. No pretende resolver globalmente team building competitivo ni explorar combinaciones exponenciales. Su función es producir NPCs razonables y reproducibles a partir de un pool.

### Lead operativo

El compositor selecciona un `lead_index` determinista con preferencia por fast attacker/support y velocidad base. `TrainerTeamFactory` da significado operativo al índice: materializa todos los miembros de forma independiente y devuelve el lead elegido en `roster[0]`, porque varios caminos actuales del battle/session stack usan el primer miembro como activo inicial.

La rotación del roster materializado no muta `TrainerTeamDefinition` ni reescribe los loadouts authored.

## Validación requerida

El gate debe demostrar:

- round-trip y firma determinista del equipo;
- límite central de seis miembros;
- lead válido;
- política de especies duplicadas configurable;
- propagación de errores de un loadout miembro;
- detección de debilidades compartidas y debilidades sin respuesta;
- un equipo diversificado obtiene mejor diagnóstico que uno redundante diseñado para el fixture;
- compositor determinista y tamaño exacto;
- especies únicas cuando la política lo exige;
- imposibilidad explícita si el pool no puede llenar el tamaño sin duplicados;
- capacidad de llenar cuando los duplicados están permitidos;
- diversidad mínima de roles y tipos ofensivos en el fixture de composición;
- materialización completa e independiente;
- IDs de instancia únicos;
- lead materializado en primera posición;
- no mutación de la definición durante materialización;
- rechazo de equipos inválidos;
- FASE 32 y todos los gates históricos verdes;
- regresión global Godot 4.7 verde sobre el mismo SHA.

## Fuera de alcance

FASE 33 no implementa todavía:

- búsqueda combinatoria/global de equipos óptimos;
- archetypes de Líder/Alto Mando/Campeón;
- equipos temáticos por tipo como política automática específica;
- hazards/pivots/Choice-lock completos;
- sinergias complejas de clima/campo;
- runtime de nuevas habilidades/held items;
- calibración automática del `synergy_score`;
- MCTS;
- Revive activo (continúa reservado para personajes especiales, máximo un Pokémon revivido por combate cuando se habilite).
