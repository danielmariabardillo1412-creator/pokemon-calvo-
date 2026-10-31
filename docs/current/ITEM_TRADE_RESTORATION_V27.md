# Restauración de objetos evolutivos — V27

**La exclusión V26 fue un error de interpretación de Codex y queda revocada.**
Los diez objetos vuelven a estar permitidos para sus funciones evolutivas. No
necesitan una bonificación de combate adicional para ser útiles en este juego.
Cordón Unión conserva su veto explícito; el resto de vetos anteriores no cambia.

## Regla correcta para la fase futura

Se elimina solo el intercambio. Donde había un objeto evolutivo equipado, se
mantendrá ese objeto además del nivel que se defina después. Onix podrá llevar
Revestimiento Metálico para evolucionar a Steelix cuando cumpla la condición;
sin equiparlo, el jugador podrá conservar Onix. No habrá evolución automática
sin el objeto necesario. Las rutas sin objeto se estudiarán por separado.

Ahora no se implementa esa adaptación, no se eligen niveles y no se cambia
EvolutionSystem ni el dataset. Ver TRADE_EVOLUTIONS_FUTURE.md.

## Restaurados

Escama Dragón, Disco Extraño, Electrizador, Magmatizador, Escama Bella,
Protector, Tela Terrible, Saquito Fragante, Mejora y Dulce de Nata.
Revestimiento Metálico, Roca del Rey, Diente Marino y Escama Marina ya estaban
permitidos y se conservan también como requisitos evolutivos.

La configuración recupera exactamente las exclusiones aprobadas antes de V26,
con una nota que recoge la aclaración. Los datos originales, inventarios,
metadatos nativos, arte y guardados no se reescriben. Los informes V26 son
históricos: probaron una política que funcionaba técnicamente, pero esa política
no correspondía al diseño del usuario. No se reinterpretan como aceptación actual.

## Comprobaciones

- 3 grupos PASS / 5.102 comprobaciones: restauración 89, selección 20 y
  conexiones de objetos 4.993, con regresiones solapadas.
- Diez permisos de generación con soporte explícito recuperados y equipamiento
  real con cantidades correctas. Equipar/quitar solo cambia el objeto: no evoluciona
  al Pokémon ni altera sus demás datos. Requisitos canónicos equipados presentes.
- Onix/Revestimiento Metálico comprobado expresamente, con retirada del objeto.
- Cordón sigue bloqueado. No hay evolución por nivel provisional a nivel 100.
- Guarda completa PASS: 23.138 archivos protegidos y 15.647 ausentes preservados.
  Nueva base 94716ca; no se resella ni se altera evidencia histórica.
- 44 exclusiones totales; 624 equipables permitidos, 621 con descriptor nativo.
  Estas cifras no certifican todos los efectos del catálogo.

Resultados: ITEM_TRADE_RESTORATION_V27.json y
`.godot/trade_item_restoration_v27/results.json`.
