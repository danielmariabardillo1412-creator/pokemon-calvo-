# Pokémon Calvo — Megapiedra universal: especificación de selección V1

**Fecha:** 2026-11-01. **Estado:** diseño de contenido decidido por el usuario; implementación aplazada hasta después del resto de objetos. No certifica código ejecutable ni funcionamiento en Godot.

## Decisión fija
- Habrá **un único tipo de objeto**: **Megapiedra universal**, con identificador provisional de proyecto `mega_stone_universal`.
- Habrá **un máximo de dos ejemplares físicos de ese mismo objeto por partida/jugador**. **No son dos tipos distintos ni 92 megapiedras diferentes.**
- Ambas piedras serán **intercambiables y reutilizables**: se pueden equipar a cualquier especie o forma que **tenga una megaevolución definida y autorizada en el juego**. «Universal» no significa crear una nueva Mega para especies que no disponen de ella.
- No se consumen al usarlas; entre combates pueden retirarse y equiparse en otros Pokémon.
- Los **92 ID históricos de megapiedras específicas y 12 accesorios Mega** quedan en `APARCADO_MEGA`, archivados exclusivamente como posibles referencias de especie, forma y reglas técnicas; no deben distribuirse ni producirse como 104 objetos adicionales.
- La lista de desarrollo contabiliza **743 tipos de objetos normales + 1 tipo universal = 744 tipos distintos**, pero la piedra universal tiene **dos unidades máximas**. No sumar 2 al número de tipos (745 sería confundir unidades con objetos diferentes).

## Funcionamiento previsto
1. **Obtención y propiedad:** las dos copias son el presupuesto máximo durante toda la partida. Si el jugador solo ha conseguido una, posee una. Un reparto, recompensa, generación, tienda, botín, intercambio o carga que intente darle una tercera se bloquea. El método concreto de obtener las dos se decidirá cuando se diseñe su progresión.
2. **Control global:** contar en conjunto las piedras libres de la mochila, equipadas a Pokémon del equipo o PC, en otras cajas, depósitos o transferencias, y cualquier objeto reservado/asignado dentro del guardado; evitar duplicación al mover objetos, entregar Pokémon, guardar/cargar, importar, comerciar o repetir una recompensa. No basta contar solo la mochila. La implementación de inventarios compartidos/multijugador tendrá que decidir el propietario del cupo; por defecto se aplica por partida/jugador, **no una reserva mundial única para todo el servidor**.
3. **Equipar:** solo un ejemplar por Pokémon; únicamente un Pokémon con megaforma válida lo puede utilizar para transformarse. El resto debe obtener respuesta clara de no elegibilidad y conservar la piedra sin consumo. No se cambia la especie ni se improvisan estadísticas, habilidades, tipos o modelos.
4. **Preselección de variantes:** si una especie ofrece Mega X, Mega Y o más de una variante, se elige cuál **antes de empezar el combate**, durante la preparación del equipo. La variante queda fijada durante ese encuentro; no cambiarla oportunistamente después de ver la respuesta del rival. La selección persiste con el equipamiento sin exigir otra megapiedra física.
5. **Batalla:** la acción de megaevolucionar transforma temporalmente al candidato usando los datos de su megaforma, y la transformación se revierte cuando corresponda según las reglas del motor. Recomendación de balance **a validar con el compañero**: aunque haya hasta dos candidatos equipados, permitir **una única activación Mega por entrenador y combate**. **El usuario ha confirmado dos piedras en posesión, no dos Mega simultáneas.**
6. **Excepciones:** si Rayquaza u otra criatura puede megaevolucionar sin piedra en el material original, en Pokémon Calvo **se propone exigir la universal** para respetar el presupuesto de dos; verificar compatibilidad con reglas existentes antes de codificarlo. Los movimientos Z, Tera y Dinamax permanecen sistemas separados, sin inventar una limitación conjunta.
7. **Seguridad del guardado y PvP:** toda concesión, cesión, devolución o movimiento debe ser atómico y validado por el estado autorizado; detectar objetos duplicados o copias superiores a dos con una prueba de integridad. No se deben destruir partidas existentes ni inventar migraciones de objetos antes de aprobarlas.
8. **Pruebas futuras obligatorias:** dos copias concedidas y tercera rechazada; ambas equipadas a dos Pokémon compatibles; una especie sin Mega rechazada; X/Y persistente y bloqueada en combate; consumo nulo; cambio de equipamiento sin multiplicar unidades; guardado/carga y PC sin duplicaciones; carrera de concesiones en multijugador; correspondencia real con las megaformas existentes y devolución a forma base.

## Separación estricta de contenido y motor
- La **lista operativa V2** contendrá **una fila** con `mega_stone_universal`, `cantidad_maxima_por_partida=2`, `estado=DISEÑO_NO_IMPLEMENTADO`.
- No se agrega este identificador provisional a los **2222 ID canónicos** de PokéAPI, porque es una creación propia del proyecto. No se eliminan los 104 ID originales; están en archivo de referencia separado.
- No modificar `main`, V28, `config/item_selection_v1.json`, funciones de combate, guardados existentes o imágenes en esta fase.

**Acuerdo cerrado:** sustituir la carga de diseñar 92 piedras y 12 accesorios por **una piedra universal de dos ejemplares máximo**. Quedan por resolver solamente su programación, obtención, interfaz, pruebas y la regla de una Mega activa por combate.
