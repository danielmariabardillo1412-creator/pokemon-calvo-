# Conexiones de objetos y comprobación automática V1 — 2026-10-28

Se amplía el juego existente. La nueva **B · Mochila** permite equipar, retirar,
usar objetos evolutivos con una ruta soportada y enseñar movimientos con las MT
del perfil activo. Se trabaja sobre la colección real del jugador, sin generar
otra partida ni habilitar todo el catálogo por disponer de una imagen.

## Conexiones incorporadas

`modules/inventory/field_item_service.gd` ofrece transacciones síncronas entre
mochila y criaturas propias de equipo/PC. Rechaza uso durante combate, transición,
configuración u otra pantalla, objetos vetados, objetivos ajenos y usos sin efecto.
El cambio de equipado devuelve el anterior; un equipado ya consumido no reaparece.
Se mantienen identidad, posición de almacenamiento y los demás datos de la criatura.

Evolución: se reutiliza `EvolutionSystem`, no se sustituyen sus condiciones por
«tener la piedra». Se conectan las **57 rutas de uso de objeto ya clasificadas
como soportadas**. Las 15 condicionadas o de forma continúan pendientes: once
rechazadas por su dependencia y cuatro comparten el ID base de destino con una
ruta normal, por lo que esa ruta normal se prueba por separado. No se presenta
una evolución base como si hubiera resuelto la variante regional.

El inventario consume una unidad únicamente tras conseguir el cambio y conservar
la propiedad. No se rerrolan habilidades para saltarse un veto. Enseñar o evolucionar
no restaura PS ni revive a una criatura. La futura muerte permanente del randomlocke
seguirá siendo una regla de propiedad/partida independiente; no se añade aquí.

Máquinas: `item_connections_v1.json` contiene las relaciones explícitas
**objeto → versión → movimiento** de los **338 IDs** existentes. Las tablas
primarias están fijadas al commit de PokéAPI
`2bf639e5572812a67d2b94903fdcb9d095f5aeb2`, con URL y SHA-256 por archivo.
No se deduce el movimiento de una descripción multigeneración: MT01 puede tener
significados diferentes según la versión.

El perfil de uso actual es **Escarlata/Púrpura**, con **229 MT** de un uso.
La mochila muestra qué movimiento enseñan antes de consumirlas. Comprueba la
compatibilidad de la especie con la procedencia de esa versión, movimientos
vetados, PP iniciales, aprendizaje repetido y elección explícita de un hueco si
ya conoce cuatro movimientos. No olvida automáticamente el primero.

**Los otros 109 IDs —MT00, ocho MO y 100 DT— tienen relación de datos, pero no
uso activado en este perfil.** Sus reglas de versión/compatibilidad deben fijarse
antes de convertirlos en objetos jugables. Cambiar su imagen después no requiere
cambiar estos IDs ni el servicio. No se habilita la fabricación de MT.

## Verificador automático

Ejecutar desde la carpeta del juego:

```text
python tools/item_audit/run_connections.py --gpu --regressions
```

Necesita Godot y el runtime nativo fijado del proyecto, ya utilizados por el
combate. `GODOT_BIN` permite indicar otra ubicación de Godot. Las referencias
primarias pequeñas están dentro de `tests/fixtures/item_connections_v1/primary/`;
no requiere la carpeta externa de investigación ni descarga datasets brutos.
Los CSV se guardan como `.csv.txt` para evitar que Godot los importe como traducciones.

El proceso verifica sus hashes, regenera únicamente el adaptador aditivo, exporta
la elegibilidad actual, ejecuta los casos sin ventana, opcionalmente con GPU y las
regresiones. Se ejecutan secuencialmente; los guardados de prueba tienen nombres
propios distintos para ambos modos y se eliminan al terminar. Incluye límite de
tiempo y trata los errores de script como fallo aunque un informe parcial parezca
correcto.

Cobertura de este cierre:

- **625 IDs**: equipar, retirar y conservar cantidades; no equivale a probar sus
  625 efectos en combate. Se comprueban sustitución, consumo previo y propiedad en PC.
- **57 rutas evolutivas**: transformación, consumo, identidad y datos conservados,
  además de casos fijos de Eevee, Growlithe y Pikachu y rechazos sin mutación.
- **229 MT**: al menos una especie compatible por MT, movimiento correcto según
  fuente, PP, consumo y bloqueo; no todas las combinaciones especie/MT posibles.
- **338 máquinas**: cruce de las relaciones por versión con las filas primarias.
- Mochila real: evolucionar Eevee, enseñar Derribo mediante MT01, equipar Restos,
  guardar/cargar por la ruta de campaña y llevar ese mismo objeto al combate nativo.
  Un turno con Protección verifica la curación de Restos; no se publica el estado
  de combate sobre la campaña antes de su cierre.
- Apertura/cierre del menú, bloqueo del mapa/guardado y rechazo de una llamada
  directa al servicio durante un combate.
- Se conserva la validación anterior de medicinas/captura/equipados como evidencia
  de su fase original; no se etiqueta como una nueva certificación exhaustiva.

Los totales finales de comprobaciones y regresiones están en
`ITEM_CONNECTIONS_V1.json`; las evidencias reproducibles en
`.godot/item_connections_v1/`. La captura `field_bag.png` corresponde a la
mochila incrustada en el juego, no a una ventana ajena a la demo.

## Estado por objeto y trabajo restante

`ITEM_CONNECTIONS_V1.csv` y el JSON registran los **2.222 IDs**, separando
transferencia de equipado, uso de campo y evidencia de efecto de combate.
No se marca como roto un objeto que no debe usarse directamente desde la mochila:
materiales necesitan fabricación, tesoros compra/venta/intercambio, Poké Balls el
contexto de captura y objetos de historia su sistema correspondiente.

**Cuerda Huida**: existen portal y salida de la cueva en la demo, pero falta una
ruta de uso de objeto con destino de escape y regla explícita de consumo/reutilización.
Se informa como dependencia pendiente, no como PASS por poder mover al personaje.

Continúan pendientes las medicinas fuera de combate, entrenamiento/naturalezas
mediante objetos, condiciones de bolas especiales, intercambios/evoluciones con
condiciones, cambios de forma, reglas de las máquinas antiguas y los sistemas del
mundo que finalmente se conserven. No se construyen sistemas de incursión o historias
de otros juegos solo para justificar objetos de su dataset.

Los vetos existentes se respetan y no se cambian. No se conectan nuevos botines,
tiendas o premios a un conjunto de objetos sin efectos certificados. El arte
mantiene sus 1.011 entradas y no se rediseñan discos ni otros objetos.

Se conservan los hashes de `data/raw`, `data/normalized`, las dos políticas y el
manifest artístico anteriores a este lote. Las nuevas tablas son un adaptador,
no una regeneración de los datos corregidos durante las fases previas.

Referencias de estructura: [máquinas en PokéAPI](https://pokeapi.co/docs/v2#machines-section)
y [CSV primario fijado](https://github.com/PokeAPI/pokeapi/blob/2bf639e5572812a67d2b94903fdcb9d095f5aeb2/data/v2/csv/machines.csv).
