# ADR-010 — Wild Encounters Core V1

Estado: ACEPTADO / VALIDADO EN CI  
Fecha: 2026-08-29  
Rama: `feature/wild-encounters-v1`

## Contexto

El proyecto ya disponía de criaturas persistentes (`CreatureInstance`), `CreatureFactory`, Battle, Progression, Capture, Party, Storage, Inventory y Savegame V2. Faltaba una frontera de dominio para producir encuentros salvajes a partir de una zona sin acoplar la lógica a mapas, pasos del jugador, UI o assets.

## Decisión

### 1. El caller decide CUÁNDO; Encounter decide QUÉ

`WildEncounterSystem` no conoce hierba, pasos, colisiones ni escenas. Una futura capa de overworld decide cuándo solicitar una tirada para un `zone_id`. El núcleo de encuentros decide:

1. si ocurre encuentro;
2. qué slot ponderado resulta elegido;
3. qué nivel se genera;
4. qué `CreatureInstance` persistente nace.

Así el motor puede probarse headless y la presentación romana queda desacoplada.

### 2. Contrato versionado

Ruleset:

- schema `1`
- ID `calvo_wild_encounters_v1`
- probabilidad expresada en basis points `0..10000`
- pesos enteros positivos y acotados
- niveles `1..100`

Cada slot tiene stable `slot_id`, `species_id`, `weight`, `min_level` y `max_level`.

Cada tabla tiene stable `zone_id`, probabilidad base y slots ordenados.

### 3. Validar antes de consumir RNG

Tabla y slots se validan estructuralmente y contra `SpeciesCatalog` antes de cualquier tirada. Datos corruptos, especies inexistentes, pesos inválidos o rangos imposibles no alteran el stream RNG.

`chance=0` produce `NONE` sin RNG. `chance=10000` evita la tirada de probabilidad innecesaria.

### 4. Selección ponderada determinista

Los slots usan pesos relativos; no se exige que sumen 100. La selección recorre el orden declarado y aplica una tirada entera sobre `total_weight`.

El nivel se elige de forma inclusiva entre `min_level` y `max_level`.

### 5. CreatureFactory sigue siendo dueño de los rasgos individuales

Encounter no reimplementa IV, Nature, Ability, stats ni moveset. Una vez elegidos especie/nivel, delega en `CreatureFactory`.

Esto mantiene una sola fuente de verdad para la creación de Pokémon persistentes.

### 6. Identidad reproducible

El `instance_id` del salvaje se deriva del stream RNG inyectado antes de llamar a `CreatureFactory`. Por tanto el mismo estado inicial reproduce el encuentro completo, incluida identidad; encuentros consecutivos sobre un stream continuo generan IDs distintos.

No se usa contador global para la identidad del encuentro.

### 7. RNG elegido en V1

El subsistema utiliza `RandomNumberGenerator` inyectado porque es el contrato ya usado por `CreatureFactory`, Progression y Capture. Battle conserva por ahora `SeededRandomSource` para su snapshot determinista.

Unificar ambas abstracciones puede estudiarse más adelante, pero no se amplía el alcance de esta fase con una migración transversal de RNG.

### 8. Resultado semántico

`WildEncounterResult` expone:

- `INVALID`
- `NONE`
- `ENCOUNTER`

más `reason`, `zone_id`, `slot_id`, `species_id`, `level` y la criatura cuando existe.

No contiene texto localizado ni decisiones visuales.

## Fronteras

### Overworld futuro

Debe aportar `zone_id` y decidir cuándo pedir una tirada. No debe seleccionar especies por su cuenta.

### Battle

Un `ENCOUNTER` entrega un `CreatureInstance` listo para construir un combate salvaje. Encounter no crea `BattleState`.

### Capture

La misma instancia puede pasar posteriormente a `CaptureInventoryService`. El test vertical de esta fase demuestra Encounter → Capture con identidad conservada y consumo real de Master Ball.

### Savegame

Una criatura salvaje no entra en el save hasta convertirse en estado propiedad del jugador (Party/Storage). No se añade estado de Encounter al save en V1.

## Alternativas rechazadas

### Hardcodear encuentros en escenas/mapas

Rechazado: mezcla contenido, lógica y presentación; impide QA headless y reutilización.

### Porcentajes float

Rechazado para el contrato base: basis points enteros son más fáciles de versionar, comparar y testear determinísticamente.

### Crear directamente BattleState

Rechazado: Encounter debe terminar al producir la criatura y metadatos del encuentro. La orquestación de combate pertenece a una capa superior.

### Añadir clima/hora/bioma desde V1

Diferido: no existe todavía un overworld canónico que suministre esos contextos. Añadirlos ahora sería arquitectura especulativa.

## Validación

GitHub Actions con Godot `4.7.stable.official.5b4e0cb0f`:

- regresión histórica: **470 PASS / 0 FAIL**
- Inventory 9A: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- import headless: PASS
- workflow: SUCCESS

## Fuera de alcance

No mapas, grass/step triggers, UI, música, sprites, condiciones por hora/clima, repelentes, habilidades que alteran encuentros, cadenas, hordas ni encuentros de entrenador.
