# Evoluciones por intercambio — trabajo aplazado

Decisión del usuario, 2026-10-31: se eliminará la necesidad de intercambiar y
se adaptarán esas evoluciones a progresión por nivel. **Ahora no se implementa.**
Cordón Unión queda excluido porque no forma parte de ese diseño. Las evoluciones
normales por nivel o piedra no se desactivan.

Para la fase futura se contrastarán juegos/randomizadores existentes y cualquier
tabla que facilite el amigo. No se ha elegido un nivel común, no se activa nivel
37 y no se altera el dataset canónico para simular que esas especies tenían un
nivel original. El usuario aplazó expresamente esta decisión.

La consulta preliminar a [Universal Pokémon Randomizer ZX, Gen4RomHandler](https://github.com/Ajarmar/universal-pokemon-randomizer-zx/blob/master/src/com/dabomstew/pkrandom/romhandlers/Gen4RomHandler.java)
muestra criterios distintos según el caso: nivel 37 para intercambio simple,
objetos conservados en otras rutas y una excepción de Slowpoke con piedra. Es
referencia para investigar más adelante, no una norma adoptada para este juego.

Al retomarlo habrá que resolver niveles, intercambios con objeto, parejas de
especies, variantes regionales/tamaños y destinos múltiples (p. ej., Clamperl y
Slowpoke), antes de convertir registros en un adaptador de reglas del juego.
Se conservarán los objetos con otras funciones de combate. Cordón y los diez
evolutivos revisados en ITEM_TRADE_EXCLUSIONS_V26.md/.json quedan excluidos del
conjunto utilizable. La futura adaptación no deberá reintroducir automáticamente
requisitos de esos objetos al copiar una referencia de otro randomizador.

El intercambio por sí mismo no fija un nivel mínimo oficial. Los niveles de
las fases previas, cuando existan, no sustituyen la futura tabla de adaptación.
Este apunte no implementa ningún cambio de evolución.
