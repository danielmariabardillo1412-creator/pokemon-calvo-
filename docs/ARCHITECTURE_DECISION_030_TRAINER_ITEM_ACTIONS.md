# ADR-030 — Trainer Item Actions V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACION.

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

## Validación requerida

El gate debe demostrar:

- serialización y round-trip de ITEM;
- snapshot/fork de inventario finito;
- consumo 1 -> 0 y rechazo de reutilización;
- no consumo en acciones rechazadas;
- Potion/Super/Hyper/Max/Full Restore correctos;
- curación de un miembro vivo de la banca;
- independencia entre bag item y held item;
- Revive desactivado aunque exista en la bolsa;
- bolsa rival ausente de observación y mundos plausibles;
- búsqueda sin mutación del combate vivo;
- selección de curación cuando evita una derrota inmediata;
- preferencia por una jugada ganadora frente a curación innecesaria;
- preferencia de recurso menor cuando produce el mismo efecto útil;
- corpus FASE 26 ejecutado con el candidato FASE 30 sin regresiones;
- todos los gates históricos y regresión global verdes sobre el mismo SHA.

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
