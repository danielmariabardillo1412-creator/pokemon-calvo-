# ADR-003 — Battle Core V2: effects, triggers y simulación determinista

- Estado: ACEPTADA
- Fecha: 2026-08-29
- Rama: `feature/battle-core-v2`
- Depende de: ADR-001 y ADR-002

## Context

Foundation V1 resolvía daño mediante un `TurnExecutor` lineal. El dataset posterior
aporta 937 movimientos, 373 habilidades y 2222 objetos, pero sus `effect_summary`
son prosa para personas, no contratos ejecutables. Añadir condicionales por
movimiento al executor habría convertido el orquestador en un punto de cambio
global, difícil de probar y peligroso para replays y servidor autoritativo.

## Problems

- No existían PP runtime, stages, stats especiales, accuracy/evasion ni críticos.
- Status era una lista de IDs y solo Poison tenía tick.
- El estado suponía exactamente dos criaturas sin party/switching.
- No había phases ni orden formal para efectos, abilities o items.
- `DefinitionCatalog` no exponía abilities/items al runtime de batalla.
- El snapshot v1 no podía restaurar esas mecánicas.

## Options considered

1. Condicionales por stable ID dentro de `TurnExecutor`: sencillo hoy, no escala.
2. Una clase por movimiento: expresivo para excepciones, explosión de clases para
   familias comunes.
3. Interpretar `effect_summary`: rechazado; la prosa inglesa es inestable y ambigua.
4. Scripts arbitrarios o Nodes por efecto: rompe determinismo, headless y revisión.
5. Specs compuestos + handlers reutilizables + handlers específicos excepcionales:
   equilibrio entre datos, extensibilidad y comportamiento auditable.

## Decision

Se elige la opción 5. `BattleEffectSpec` describe primitivas; `BattleEffectExecutor`
las ejecuta con `BattleEffectContext` y devuelve `BattleEffectResult`.
`BattleEffectRegistry` contiene mappings explícitos por stable ID para la muestra
V2. El futuro pipeline podrá proporcionar `effect_specs` estructurados con el mismo
contrato. Nunca se analiza `effect_summary`.

## Effect architecture

Primitivas implementadas: damage, heal, recoil, drain, inflict/cure status,
stat-stage change, chance, flinch y fixed damage. Specs se componen en arrays y
`Chance` contiene hijos. Un movimiento de daño obtiene `Damage` por su metadata
estructurada (`power`, `damage_class`, tipo); sus secundarios solo se ejecutan si
existe mapping/spec explícito.

Las mecánicas realmente únicas podrán usar un handler específico registrado, sin
modificar el flujo general. Multi-hit y Protect no se declaran soportados todavía.

## Trigger ordering

Orden determinista:

1. phase fija de `BattlePhase.ORDER`;
2. orden de lado (`side_a`, `side_b` según snapshot);
3. posición en party;
4. ability antes que held item;
5. orden del array de specs.

Nunca depende de iteración accidental de Dictionary, filesystem o Nodes. Switching
tiene prioridad 6 en `calvo_v1`; los empates restantes usan el RNG inyectado.

## Ruleset

Todas las decisiones generacionales viven en `BattleRuleset` con ID `calvo_v1`:
stages, accuracy/evasion, crítico, penalización de burn, velocidad/parálisis,
duración de sleep, thaw, inmunidades y ticks. Véase `BATTLE_RULESET_CALVO_V1.md`.

## Determinism

Toda aleatoriedad usa `SeededRandomSource`: accuracy, crítico, damage roll,
secundarios, sleep, parálisis, freeze y speed ties. Snapshot v2 conserva algoritmo
y estado RNG. Está probado que restaurar el snapshot y enviar la misma acción
siguiente produce exactamente los mismos eventos y estado final.

## Server authority

El cliente solo crea `MOVE` o `SWITCH`. El servidor valida fase, turno, actor,
`side_id` obligatorio (que el futuro transporte ligará al peer autenticado),
ownership, KO, move conocido, PP, objetivo
y sustitución. Daño, accuracy, crítico, status, HP y resultado no existen en el
payload de intención y siempre se calculan en servidor.

## Rejected alternatives

- ECS, EventBus, autoload managers y Nodes dentro de Battle Core.
- Reescribir `DamageCalculator`; se extendió conservando su responsabilidad.
- Duplicar type chart dentro de Battle.
- Declarar las 937 moves o 373 abilities soportadas por tener datos.
- Evolución, forms, capture, XP, inventario general o networking real.

## Consequences

Positivas:

- Nuevos efectos comunes se expresan con specs sin tocar `TurnExecutor`.
- Estado, eventos y orden son reproducibles y serializables.
- Party/switching ya forman parte del modelo autoritativo.
- Abilities/items comparten phases y reglas de orden.

Costes:

- El registro explícito debe mantenerse hasta que el pipeline emita specs validados.
- Los efectos compuestos crean más objetos RefCounted, aceptable para combate por
  turnos y mucho menor que crear Nodes.
- La compatibilidad de snapshots v1 no se implementa; no hay saves de producción.

## Risks

- El switching forzado elige el primer miembro vivo; selección interactiva queda
  para el protocolo futuro.
- Static usa `damage_class == physical` como aproximación de contacto porque el
  dataset no contiene una marca estructurada de contacto.
- Freeze está modelado con thaw moderno simple; no hay moves V2 que lo apliquen.
- No hay dobles, clima, terreno, hazards, multi-hit ni Protect.
- `ruleset_id` sigue siendo manual; debe vincularse a un hash de rules/data antes de
  replays persistentes de producción.
