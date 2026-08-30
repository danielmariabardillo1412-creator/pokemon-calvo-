# ADR-019 — Trainer Battle Session V1

Fecha: 2026-08-30  
Rama: `feature/trainer-battle-session-v1`  
Base: `feature/battle-run-presentation-v1`  
Estado: **ACCEPTED / VALIDATED**

## Contexto

FASE 18 cerró la vertical slice técnica de combate salvaje hasta cubrir Move, Switch, Capture y Run desde presentación, manteniendo Battle Core como autoridad de reglas.

Su informe final exigía no abrir otro bloque hasta cerrar el PR #12 sin merge y revisar la siguiente frontera por dependencias reales. El PR #12 fue cerrado sin merge antes de iniciar esta fase.

La revisión no encontró un roadmap prospectivo único que definiera de forma fiable una FASE 19 ya acordada. Por tanto, no se inventó una continuidad histórica inexistente: se compararon las fronteras funcionales que realmente faltaban.

Abrir Bag/objetos generales en combate se descartó como siguiente paso porque el dataset contiene una superficie de objetos muy superior a la semántica runtime actualmente soportada. Combate contra entrenadores, en cambio, reutiliza directamente Battle Core, Party/CreatureInstance y Progression, y además crea la frontera necesaria para una futura política/IA de entrenador.

## Alternativas evaluadas

### A. Trainer Battle Session headless sobre Battle Core

Elegida.

Permite probar la semántica de un combate contra un roster propiedad de otro entrenador sin introducir todavía NPC, UI, economía ni IA estratégica.

### B. Abrir Bag/ITEM como comando general de combate

Pospuesta.

La importación de items es muy amplia y el runtime actual solo cubre una fracción pequeña de sus efectos. Hacerlo ahora mezclaría una frontera de combate con una expansión grande de semánticas de objetos.

### C. Construir directamente NPC + presentación + trainer battle

Rechazada para esta fase.

Acoplaría world/presentation a una sesión cuyo contrato todavía no había sido probado de forma aislada.

### D. Implementar primero una IA de entrenador

Rechazada para esta fase.

Una política de decisión necesita antes una frontera estable que defina qué es un trainer battle, quién posee cada roster y dónde se valida una acción.

## Decisión

Se introduce `TrainerBattleSession`, una capa de aplicación headless que compone:

- `PlayerCollection` del jugador;
- identidad del entrenador rival;
- roster rival de `CreatureInstance`;
- `AuthoritativeBattleServer`;
- `BattleOutcome`;
- `ProgressionSystem`.

El Battle Core existente sigue siendo la autoridad de resolución de turnos, daño, prioridad, PP, estados, KO, switch y fin de batalla.

`TrainerBattleSession` no replica esas reglas.

## Ciclo de vida

Estados de sesión:

- `READY`;
- `BATTLE_ACTIVE`;
- `COMPLETED`.

Razones de finalización V1:

- `VICTORY`;
- `DEFEAT`.

No existen `CAPTURED` ni `FLED` en esta sesión.

`begin_battle(trainer_id, roster, battle_seed)` construye un `BattleState` con:

- jugador -> `side_a`;
- entrenador rival -> `side_b`;
- mismo `CreatureInstance` vivo/persistente, sin clones de gameplay.

La primera criatura viva de cada roster se coloca como activa; las demás conservan su identidad y orden relativo.

## Invariantes de identidad y roster

La frontera rechaza antes de construir BattleState:

- trainer id vacío;
- jugador sin criatura viva;
- rival sin criatura viva;
- `instance_id` vacío en cualquier combatiente;
- `instance_id` duplicado dentro de un roster;
- solapamiento de identidad entre roster del jugador y roster rival.

Esto evita dejar a capas inferiores la interpretación de un roster ambiguo o imposible.

## Comandos admitidos

`submit_player_action(player_action, opponent_action)` acepta acciones de Battle Core ya existentes.

En V1 la sesión admite por esta vía las acciones genéricas que Battle Core soporte y valide, especialmente:

- MOVE;
- SWITCH.

La sesión **no expone** API de Capture ni Run.

Razón: Capture pertenece a la semántica de encuentro salvaje y Run ya fue diseñado como comando específico de `WildAdventureSession`, no como `BattleAction` genérico.

## Frontera de autoridad

La sesión comprueba la frontera mínima de participante:

- acción del jugador -> `side_a`;
- acción rival -> `side_b`.

Después delega en `AuthoritativeBattleServer.submit_turn()`.

Battle Core sigue rechazando, entre otros, actor falsificado, turno stale, target/actor ilegal o acción incompatible con el estado vivo.

La auditoría confirma que una acción falsificada o stale no avanza el turno.

## Política del entrenador rival: límite explícito

En esta fase la acción rival candidata se suministra desde fuera de `TrainerBattleSession` y Battle Core valida su legalidad.

Esto **NO equivale** a una IA de entrenador ni a autoridad de red completa.

Una futura política/IA deberá elegir la acción rival detrás de una frontera de autoridad adecuada. FASE 19 únicamente garantiza que la sesión puede recibir una acción rival y que Battle Core decide si es legal.

No se afirma seguridad frente a un cliente hostil en networking.

## Settlement y progresión

`settle_finished_battle()` solo acepta un Battle Core ya `FINISHED`.

Construye `BattleOutcome` y:

- en victoria del jugador, reutiliza `ProgressionSystem.reconcile_battle_result()`;
- en derrota, no concede progresión al jugador;
- reconcilia estado transitorio post-battle de ambos rosters;
- completa la sesión como `VICTORY` o `DEFEAT`.

No se implementa una segunda fórmula paralela de XP.

### Limitación importante

FASE 19 **no implementa ni afirma** todavía:

- multiplicador especial de XP por trainer battle;
- premio monetario;
- robo/pérdida de dinero al perder;
- recompensas de NPC;
- reglas de rematch.

Esas reglas requieren diseño explícito posterior.

## Reutilización de la sesión

Después de `COMPLETED`, `reset_after_completion()` devuelve la sesión a `READY`.

Se rechaza reset mientras existe un combate activo.

Una sesión reseteada puede abrir un nuevo combate contra otro entrenador sin conservar estado transitorio del combate anterior.

## Auditoría adversarial

No se cerró la fase con el primer verde de la suite base.

La suite final cubre además:

- ids duplicados en roster rival;
- ids vacíos;
- solapamiento de identidad jugador/rival;
- reset durante combate activo;
- lado rival falsificado;
- actor del jugador falsificado;
- turnos stale;
- invariancia de turno ante rechazos;
- roster rival con varias criaturas y reemplazo tras KO;
- victoria solo tras derrotar el roster rival;
- submit después de settlement;
- doble settlement;
- primer miembro rival ya KO y selección del primer miembro vivo;
- ausencia intencional de Capture/Run en la API.

Resultado final del gate específico: **66 PASS / 0 FAIL**.

## Compatibilidad y regresión

En el mismo HEAD final auditado antes del cierre documental:

- `Trainer Battle Session Tests`: **success**;
- `Godot 4.7 Tests` histórico completo: **success**;
- import headless: **PASS**.

Por tanto, FASE 19 no exige modificar Battle Core ni romper las fases 1–18 existentes.

## Límites aceptados

Fuera de alcance de FASE 19:

- presentación visual de trainer battle;
- NPC y trigger en Overworld;
- diálogo pre/post combate;
- retratos/sprites/animaciones del entrenador;
- política o IA estratégica rival;
- networking/multiplayer;
- economía/recompensas;
- Bag/ITEM general en combate;
- captura en trainer battle;
- huida de trainer battle;
- guardado/reanudación de un trainer battle activo;
- balance final y reglas específicas de una generación de Pokémon no incorporadas explícitamente.

## Consecuencia arquitectónica

A partir de esta fase ya existe una frontera separada para:

`roster jugador + trainer id + roster rival -> Battle Core -> VICTORY/DEFEAT -> Progression`

Las fases posteriores pueden construir presentación, NPC y política de entrenador encima sin convertir Overworld/UI en propietarios de las reglas de combate.
