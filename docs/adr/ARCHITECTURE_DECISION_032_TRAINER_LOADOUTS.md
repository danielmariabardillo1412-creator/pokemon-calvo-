# ADR-032 — Trainer Loadouts V1

## Estado

ACEPTADA / IMPLEMENTADA / VALIDADA.

## Contexto

FASE 31 cerró la toma de decisiones de switching sobre un equipo ya existente. El siguiente salto de calidad no debe ser otra heurística de turno, sino asegurar que los Pokémon de entrenadores importantes llegan al combate con configuraciones internamente coherentes.

Naturaleza, IVs, EVs, habilidad, held item y moveset no se consideran bonificaciones independientes. Forman un único loadout: cambiar una pieza puede alterar qué rol cumple el Pokémon y si la configuración completa tiene sentido.

## Decisión

FASE 32 introduce cuatro componentes separados:

- `TrainerPokemonLoadout`: contrato serializable del conjunto completo;
- `TrainerLoadoutValidator`: legalidad/coherencia estructural y compatibilidad con el runtime;
- `TrainerLoadoutFactory`: materialización determinista a `CreatureInstance` usando las fórmulas canónicas existentes;
- `TrainerRoleLoadoutGenerator`: presets deterministas por rol y calidad para NPCs no authorados manualmente.

### Contrato atómico

Un loadout contiene:

- especie;
- nivel;
- rol;
- calidad de entrenamiento;
- naturaleza;
- IVs;
- EVs;
- habilidad;
- held item;
- hasta cuatro movimientos;
- procedencia (`source_id`).

El contrato tiene schema versionado, round-trip determinista y firma canónica.

### Validación estricta

El validador reutiliza `ProgressionRuleset` como fuente de verdad:

- nivel 1..100;
- IV 0..31;
- EV 0..252 por stat;
- EV total <= 510;
- naturaleza entre las 25 soportadas;
- máximo cuatro movimientos, sin duplicados.

Además:

- la habilidad debe existir, pertenecer a la especie y estar soportada por Battle Core;
- el held item debe existir y estar soportado como held item por Battle Core;
- un movimiento debe existir y estar presente en el learnset público de la especie;
- level-up exige nivel suficiente;
- machine/tutor/egg se aceptan como compatibilidad pública version-agnostic porque el dataset actual no preserva `version_group`;
- métodos de aprendizaje no soportados no se inventan como legales.

Los datos inválidos se rechazan. No se clampa ni sustituye silenciosamente un loadout authored, porque eso produciría divergencia entre diseño y combate real.

### Materialización

`TrainerLoadoutFactory` crea un `CreatureInstance` independiente y aplica:

- IV/EV/naturaleza exactos;
- `StatCalculator.compute` mediante `CreatureInstance.recalculate_stats`;
- experiencia correspondiente al nivel;
- habilidad y held item;
- moveset con PP inicializado;
- HP completos.

No usa RNG: mismo loadout + mismo ID producen el mismo estado salvo la identidad explícita.

### Generación por rol

V1 define roles pequeños e interpretables:

- balanced;
- physical_attacker;
- special_attacker;
- fast_attacker;
- bulky_physical;
- bulky_special;
- support.

Y tres calidades:

- basic: IV 15, EV 0;
- trained: IV 25 e inversión moderada;
- expert: IV 31 e inversión especializada dentro del límite 510.

El rol decide conjuntamente naturaleza, EVs y orden de preferencia del moveset. La selección de movimientos puntúa daño, categoría físico/especial, STAB, prioridad y utilidad estructurada. Support y roles bulky dan mayor peso a movimientos de utilidad.

La habilidad se selecciona solo entre habilidades de la especie con runtime real. El held item V1 se limita a los dos comportamientos actualmente implementados: Leftovers para roles de aguante/support y Sitrus Berry para roles ofensivos, si las definiciones están presentes.

### Alcance de la legalidad de movesets

El proyecto ya importa compatibilidades machine/tutor/egg, pero no `version_group`. FASE 32 puede afirmar `species-compatible in imported public data`; no puede afirmar todavía `legal in exact generation/version`.

Esto queda explícito para no convertir una aproximación del dataset en una falsa garantía de legalidad histórica.

## Validación

Validación del código sobre `4b9398f47cfec5bf2e938a88914fe7540e88f375`:

- gate FASE 32: **216 PASS / 0 FAIL**;
- round-trip y firma deterministas: PASS;
- límites IV/EV/naturaleza/moveset: PASS;
- incompatibilidades de move/ability/item: PASS;
- compatibilidad machine pública: PASS;
- presets physical/special/support: PASS;
- quality basic/expert y límites de inversión: PASS;
- materialización exacta contra `StatCalculator`: PASS;
- PP y HP inicializados: PASS;
- invalid loadout rechazado sin clamping silencioso: PASS;
- independencia profunda probada por mutación causal: PASS;
- FASE 31 y gates históricos: SUCCESS;
- regresión global Godot 4.7: SUCCESS;
- total sobre el SHA de código: **15/15 workflows SUCCESS**.

Incidente de validación: la primera ejecución obtuvo **215 PASS / 1 FAIL** porque el test de independencia usó desigualdad de `Dictionary`/`Array` como sustituto de identidad. GDScript compara esos contenedores por contenido, por lo que dos copias independientes e idénticas podían comparar igual. Se corrigió únicamente el fixture: ahora muta una materialización y verifica que la segunda no cambia. No se modificó producción para satisfacer el test.

Este commit documental final debe volver a obtener los mismos **15/15 workflows SUCCESS**. Si queda verde, será el HEAD canónico de FASE 32 y el PR se cerrará sin merge.

## Fuera de alcance

FASE 32 no implementa todavía:

- optimización global de equipos de seis;
- sinergia entre varios Pokémon / team building;
- perfiles de Líder, Alto Mando o Campeón;
- Choice items u otros held items sin runtime;
- habilidades todavía no ejecutables por Battle Core;
- version-group exacto del learnset;
- selección estocástica de loadouts;
- calibración matemática automática;
- MCTS;
- Revive activo (sigue reservado para personajes especiales, máximo un Pokémon revivido por combate cuando se habilite en una fase futura).
