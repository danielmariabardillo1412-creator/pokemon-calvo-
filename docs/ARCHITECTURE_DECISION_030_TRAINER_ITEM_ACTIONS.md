# ADR-030 — Trainer Item Actions V1

## Estado

ACEPTADA / IMPLEMENTADA / VALIDADA.

## Contexto

FASE 29 cerró la inferencia pública de coberturas. La siguiente carencia observada es que un entrenador humano no decide únicamente entre MOVE y SWITCH: algunos NPCs disponen de recursos finitos de bolsa y deben poder gastar un turno en curar HP o estados.

El sistema no puede modelar la bolsa como estado privado del brain. Si el inventario no viaja dentro de BattleState, una simulación profunda podría reutilizar una Hiperpoción indefinidamente. Por tanto, el recurso debe ser parte del estado autoritativo y de los forks.

## Decisión

### Acción ITEM

`BattleAction` incorpora `ITEM`, `item_id` y `target_id`. `AuthoritativeBattleServer` valida la acción mediante el mismo contrato autoritativo usado para MOVE/SWITCH.

Una acción ITEM comprueba:

- definición de objeto conocida;
- soporte explícito como objeto de bolsa de combate;
- cantidad restante > 0;
- objetivo perteneciente al entrenador;
- modo de objetivo compatible;
- existencia de un efecto real antes de consumir el recurso.

Una acción rechazada no consume inventario ni avanza el turno.

### Inventario finito en BattleState

`BattleSideItemInventory` es un inventario determinista y serializable por lado. `BattleState` conserva inventarios por `side_id` y los incluye en snapshot únicamente cuando no están vacíos, manteniendo estables los snapshots V2 históricos sin recursos.

`BattleSimulationFork` hereda el inventario a través de la serialización de BattleState. Consumir un objeto en un fork no muta el combate vivo.

### Objetos de bolsa V1

Se registran por reglas estructuradas:

- Potion: +20 HP;
- Super Potion: +60 HP;
- Hyper Potion: +120 HP;
- Max Potion: HP completos;
- Full Restore: HP completos + cura estado persistente.

Los objetos de bolsa permanecen separados de held items. `leftovers` y `sitrus_berry` continúan usando triggers de objeto equipado y no forman parte del inventario de entrenador.

### Revive preparado pero desactivado

El registro de objetos de entrenador define modos de objetivo `alive` y `fainted`, y `BattleEffectSpec` reserva el efecto `REVIVE`. Ningún Revive está registrado en FASE 30.

Por tanto:

- entrenadores normales no pueden revivir;
- añadir accidentalmente `revive` a una bolsa no habilita la acción;
- una futura fase podrá registrar Revive únicamente para NPCs especiales;
- la política acordada será como máximo un Pokémon revivido por combate especial, representado mediante un único recurso finito, no usos infinitos.

### Frontera anti-cheat

`TrainerObservation` contiene la bolsa propia exacta, porque es información del entrenador. No contiene la bolsa rival.

`TrainerItemAwareWorldFactory` copia únicamente el inventario propio al mundo plausible y registra el inventario rival como no modelado. No se inventan recursos del oponente.

### Inteligencia de objetos

FASE 30 introduce candidato separado:

- `TrainerItemAwareWorldFactory`;
- `TrainerItemAwareSearch`;
- `TrainerItemTacticalEvaluator`;
- `ItemAwareTrainerBrain`.

El search estratifica MOVE/SWITCH/ITEM dentro del presupuesto existente. Un objeto consumido en turno 1 deja de estar disponible en turno 2 del mismo fork.

El evaluador de objetos usa recuperación efectiva, curación de estado, desperdicio por overheal y un coste de oportunidad explícito. Los costes de recurso son heurísticos V1 y quedan marcados para calibración matemática posterior; no se consideran parámetros óptimos.

## Validación

La primera ejecución de CI produjo 133 PASS / 3 FAIL. Los tres fallos eran errores de fixture, no defectos de producción:

1. el test de fork intentaba usar Hyper Potion a HP completos; el servidor la rechazó correctamente con la regla de `item_no_effect`;
2. dos comprobaciones derivadas de ese rechazo esperaban consumo dentro del fork;
3. el test de observación leyó `own_item_inventory` como mapa plano, cuando el contrato correcto conserva la forma serializada de `BattleSideItemInventory` bajo `quantities`.

No se modificó producción para satisfacer esas expectativas. `TrainerItemActionsV2TestSuite` corrigió únicamente los fixtures y conservó la suite original como historial del diagnóstico.

Resultado validado sobre el commit de código `4553e6e958b149968031da07a27af5a837ed83c6`:

- FASE 30 item actions: **136 PASS / 0 FAIL**;
- corpus FASE 26 ejecutado con `ItemAwareTrainerBrain`: **36 PASS / 0 FAIL**;
- resultado del candidato en corpus: **60 victorias / 0 derrotas**;
- **0 regresiones emparejadas** respecto al planner validado;
- Revive permanece no registrado y es rechazado aunque exista accidentalmente en la bolsa;
- consumo de inventario, snapshot/fork y aislamiento del combate vivo validados;
- bolsa propia visible y bolsa rival ausente de la observación/mundos plausibles;
- el brain cura cuando la línea ofensiva inmediata pierde, no cura cuando puede cerrar el combate y prefiere el recurso menor cuando dos curaciones producen el mismo beneficio útil;
- **13/13 workflows SUCCESS**, incluida la regresión global Godot 4.7, sobre el mismo commit de código.

## Fuera de alcance

FASE 30 no implementa todavía:

- Revive activo;
- límites/configuración de objetos por clase de NPC;
- estrategia avanzada de switching;
- selección de held items;
- naturalezas/EV/IV de loadout;
- team building;
- perfil Líder/Alto Mando/Campeón;
- calibración automática de costes de objetos;
- MCTS.
