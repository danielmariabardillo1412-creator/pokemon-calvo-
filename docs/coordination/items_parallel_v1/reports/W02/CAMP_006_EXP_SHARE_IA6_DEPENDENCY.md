# IA6 — W02 CAMPAÑA_006: bloqueo de integración Exp Share

**Hallazgo en bloque 05 y ratificado en bloque 10.** La implementación `ProgressionSystem.reconcile_battle_result(participants, outcome, catalogs, ruleset, starting_items)` solo calcula supervivientes desde `participants` y concede XP por criatura participante. `progression_held_items.gd` implementa Lucky Egg y Everstone, pero no Exp Share. `FieldItemService.equip` permite equipar el objeto y SaveV2 conserva el ID, sin que ello equivalga a repartir XP.

**Contrato mínimo pendiente de IA6:** definir generación/versiones del Repartir Exp. y criterio de elegibilidad (miembros del equipo no participantes, estados, almacenamiento, Pokémon debilitados y duplicados), productor de lista de receptores desde sesión/partida, consumidor único de progresión, evento XP, persistencia SaveV2 y protección contra dobles recompensas. La decisión de reparto y la modificación de las APIs compartidas quedan reservadas a IA6.

**Prueba positiva pendiente:** con uno o varios Pokémon participantes y un destinatario elegible no participante, comprobar XP exacta, no duplicación, cambios de nivel/aprendizaje, política de exclusión y guardado-carga, más negativas de no participación/inventario.

**Estado**: DEPENDENCY_MISSING / L1. No convertir la prueba negativa de W02 en funcionalidad ni declarar completa toda la familia de objetos hasta autorizar e integrar esta dependencia.
