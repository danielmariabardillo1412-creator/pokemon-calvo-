# Pokémon Calvo — DOS megapiedras universales por partida (especificación corregida V2)

**Regla expresa del usuario, 1 de noviembre de 2026.** Esta especificación **sustituye** cualquier frase antigua que indique una sola megaevolución por combate. Solo documenta la mecánica futura: **NO está implementada en Godot**.

## Decisión cerrada

- Cada partida/jugador puede **tener como máximo DOS PIEDRAS FÍSICAS**. Son **dos ejemplares de un mismo tipo universal** (`mega_stone_universal`, identificador propio **provisional**, no incluido entre los 2.222 IDs canónicos).
- **Las dos piedras sirven para cualquier Pokémon que tenga una megaforma válida incorporada al juego**. No es una piedra para Charizard y otra para Lucario: se pueden asignar a cualquier pareja de Pokémon compatibles y, tras terminar el combate, redistribuirlas a otra pareja.
- **MÁXIMO DOS MEGAEVOLUCIONES ACTIVADAS POR ENTRENADOR EN UN MISMO COMBATE**, una por cada piedra asignada a un Pokémon diferente. **Sí se pueden usar las dos durante el mismo combate**. No se mantiene la antigua propuesta de limitarse a una sola.
- **Asignación bloqueada durante todo el combate**: se deciden los dos portadores y, cuando proceda, sus variantes Mega **antes del inicio del enfrentamiento**. Durante ese combate no se puede retirar, pasar, cambiar o reasignar la piedra a otro Pokémon, ni cambiar la elección X/Y o equivalente. Se pueden cambiar Pokémon en batalla normalmente; lo que permanece fijo es a quién pertenece cada piedra. Una activación completada consume uno de los dos usos de Mega del combate **pero no consume ni destruye la piedra**.
- Si solo se tiene una piedra, como máximo se prepara/activa una Mega en ese combate. Si se tienen dos, se pueden preparar/activar hasta dos. **No se prestan ni generan piedras adicionales al comenzar un combate.**
- Después de finalizar el combate, el jugador **puede pasar ambas piedras a otros Pokémon** para el siguiente combate, siempre respetando el máximo de dos ejemplares por partida.
- No se generan ni diseñan 92 megapiedras específicas más 12 accesorios. Sus 104 IDs originales siguen archivados como **referencias técnicas** en `RANDOMLOCK_ITEMS_MEGA_APARCADO_V1.csv`, fuera de los 744 tipos de la lista de trabajo.
- **Recuento:** 743 tipos de objetos canónicos seleccionados + **un tipo nuevo de megapiedra universal** = **744 tipos de diseño**. Ese tipo nuevo tiene **DOS unidades**, no dos tipos diferentes. Los 2.222 registros canónicos originales no cambian.

## Contrato de funcionamiento futuro

1. **Obtención y límite absoluto:** en una partida nunca pueden existir más de dos piedras del jugador sumadas entre mochila, equipo activo, PC/cajas, depósitos, transferencias y reservas. El sistema de generación, tiendas, regalos, botín, intercambios, recuperación y guardado/carga debe impedir fabricar una tercera. El modo de conseguir inicialmente esas dos piedras está pendiente de diseñar; **no se conceden automáticamente por esta nota**.
2. **Compatibilidad:** cada piedra es universal, pero la megaevolución solo funciona si el Pokémon dispone de una megaforma autorizada y realmente incorporada al motor. No inventar especie, forma, estadísticas, habilidad, arte o aprendizaje. Si no es compatible, no debe transformarse ni perder la piedra.
3. **Preparación previa:** dos piedras, máximo dos portadores distintos designados antes de combatir. Para una especie con X/Y/u otras variantes, la elección se realiza también antes del combate y queda fijada hasta terminar.
4. **Durante el combate:** los portadores predefinidos pueden megaevolucionar cuando sean elegibles según reglas de batalla. El contador de activaciones válidas va de cero a dos **por entrenador y combate** y no se reinicia al cambiar o debilitarse un Pokémon. Una acción fallida/rechazada no debe consumir uso. Al megaevolucionar uno, el otro puede megaevolucionar también. Si ambos siguen en el campo, **no hay prohibición por la mera existencia de la primera Mega**; cualquier restricción por formatos de batalla requiere especificación separada y no puede reducir las dos activaciones confirmadas.
5. **Equipamiento bloqueado:** dentro del combate no hay traspaso de piedra desde un Pokémon debilitado ni desde la mochila a otro; tampoco se cambia la variante de forma ni se mueve el cupo a un tercero. Fuera del combate, se pueden intercambiar/reequipar libremente las piedras.
6. **Reversión:** al acabar la batalla, los Pokémon vuelven a la forma que corresponda según las reglas del sistema, sin pérdida de las piedras. Cambios de equipo y guardado han de mantener la titularidad sin duplicaciones.
7. **Casos especiales:** Rayquaza y cualquier megaevolución sin piedra en un juego original necesitarán una regla explícita que impida eludir el presupuesto de dos. **Propuesta técnica:** exigir también la universal; no está implementado ni constituye un tercer permiso de uso.
8. **Multijugador y persistencia:** el cupo es **dos por jugador/partida**, no dos globales para todos los jugadores del servidor. El sistema autoritativo del combate valida que ambos jugadores cumplan el límite. Si existen intercambios, debe quedar claro a qué partida pertenecen los ejemplares y prevenir duplicación/transacciones simultáneas.

## Pruebas que se exigirán al implementar

- Cero, una y dos piedras; intento de obtener la tercera rechazado sin perder otras posesiones.
- Dos Pokémon elegibles distintos con dos piedras; **ambos megaevolucionan legalmente en el mismo combate**; tercer intento denegado.
- Un Pokémon no compatible no activa la Mega ni consume uno de los dos usos.
- La selección de portadores y X/Y queda inmóvil durante el combate; intentar pasar una piedra tras KO, retirada o cambio de turno no funciona.
- Un Pokémon puede cambiarse en combate, salir y volver sin reasignar piedra ni duplicarla.
- Las piedras no se consumen; tras acabar el combate pueden equiparse a otros dos Pokémon.
- Guardar/cargar, PC, mochila, intercambios y multijugador respetan siempre el máximo de dos unidades.
- Verificar especies, megaformas, modelos, habilidades, estadísticas, animación y reversión reales antes de declarar PASS.

## Prioridad de proyecto y compatibilidad

**Aparcado para después del sistema de objetos ordinario.** Prohibido modificar ahora por esta decisión: `main`, V28, `config/item_selection_v1.json`, inventarios, guardados, escenas, assets o motor de batalla. En particular, **no desconectar lo ya implementado**. Mantener el archivo canónico de 2.222 IDs, la lista de diseño de 744 tipos y el archivo de 104 referencias Mega, en categorías separadas.

**Resumen vinculante para el relevo:** DOS piedras físicas, UN tipo universal, MÁXIMO DOS Mega por entrenador y combate; **sin reasignar las piedras durante el combate y con libertad de cambio entre combates**. Ninguna conversación futura debe reintroducir el límite erróneo de una sola Mega por combate.
