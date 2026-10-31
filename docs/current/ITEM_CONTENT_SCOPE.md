# Objetos con utilidad para Pokémon Calvo — 2026-10-28

Actualización posterior: `ITEM_ART_EXPANSION_V2.md` aplica al plan artístico
seis entradas adicionales de cristales Z incompatibles con las reglas ya
acordadas. El informe acumulado marca 154 descartes, conservando la separación
entre selección artística, revisión de contenido y filtros de ejecución.

El usuario pide retirar decoración y objetos sin un papel útil en este juego
competitivo/randomlocke, para evitar buscar arte o implementar contenido innecesario.
La popularidad competitiva no decide si un objeto tiene función.

## Decisión aplicada al plan artístico

Se apartan **105 entradas adicionales** de la búsqueda/importación de imágenes:

| Grupo | Entradas | Motivo |
| --- | ---: | --- |
| Personalización de picnic | 73 | 19 manteles, 16 tazas, 13 botellas, 6 platos y 19 palillos decorativos/variantes de presentación del minijuego |
| Tarjetas de datos | 27 | Solo registran resultados del Pokéathlon, fuera del alcance del juego actual |
| Pañuelos de concursos | 5 | Modifican aspectos de concurso; no las estadísticas normales de combate |

Los IDs y motivos quedan explícitos en `ITEM_CONTENT_SCOPE_DECISIONS.json`.
No se seleccionan por palabras del nombre al ejecutar el filtro: el listado
de 73 IDs es fijo y revisable. Las categorías completas de pañuelos y tarjetas
se usan tras comprobar las cinco y 27 descripciones respectivas.

Sumados a los 43 vetos anteriores, son **148 entradas fuera del plan artístico**.
Quedan 2.074 definiciones para revisión funcional; no significa que todas vayan
a incluirse, estén implementadas ni que necesiten imágenes diferentes.

## Objetos útiles que se conservan

Conservar objetos con una función propia de combate, captura, evolución,
entrenamiento, aprendizaje, intercambio o economía. No excluir un objeto solo
por poco uso, rareza, antigüedad, descripción vacía, ausencia de callback o falta
de imagen. Los objetos narrativos y dependientes de otros sistemas se revisan
según la función que tenga nuestro juego.

Se verifican ejemplos que evitan eliminaciones erróneas:

- `auspicious_armor` y `leaders_crest`: la categoría de origen es **picnic**, pero
  intervienen en evoluciones. La categoría no se veta en bloque.
- `bottle_cap`: figura como **loot**, pero sirve para entrenamiento. «Botín» no
  equivale a decoración. Pepitas y otros objetos vendibles tienen papel económico.
- Escamas Corazón y fragmentos: pueden intervenir en aprendizaje/intercambios.
- `choice_scarf` es Pañuelo Elección, distinto de los cinco pañuelos de concursos.
- `poke_doll` y `poke_toy` terminan combates salvajes; no se tratan como peluches
  decorativos. Se mantiene el criterio funcional documentado en Item Foundation.
- Cristales Z, MT, bayas y megapiedras no se excluyen por etiquetas ambiguas o
  relaciones con otros juegos. Sus vetos mecánicos individuales siguen separados.

El picnic base y sus cinco pelotas quedan en revisión: interactuar con Pokémon
puede tener utilidad. Tampoco se descartan automáticamente ingredientes de comida,
materiales de MT o tesoros. El nombre de una categoría no resuelve esos casos.

## Efecto sobre la cobertura artística

De las 105 entradas apartadas, 100 no tenían coincidencia en las dos fuentes
cruzadas y cinco solo en Dream World. Esas 100 dejan de contarse como trabajo
artístico pendiente. No se han demostrado 100 imágenes inexistentes.

Las cinco familias funcionales del recuento anterior mantienen 359 entradas:
290 tienen candidato de Escarlata/Púrpura; añadiendo Dream World hay 319.
Quedan **69 sin coincidencia E/P**, de las que 29 ya tienen coincidencia DW y
40 siguen pendientes de localizar/relacionar. La eliminación de decoración no
reduce esos 69: pertenecen a objetos funcionales. Los recuentos son de metadatos,
no aprobación visual de cada archivo ni cobertura de todas las demás familias.

Actualización posterior: la búsqueda descrita en `ITEM_ART_GAPS.md` ha localizado
39 ilustraciones para esos 40 pendientes. El informe actual `ITEM_ART_SCOPE.json`
incorpora la evidencia: 358/359 entradas de esas familias tienen candidato ilustrado;
Rokikos solo tiene por ahora un icono pequeño válido. El párrafo anterior conserva
el recuento inicial para explicar el origen de la búsqueda, no el pendiente actual.

## Alcance y reproducción

`ITEM_ART_SCOPE.json` y `.csv` contienen las 2.222 decisiones, motivos y candidatos
de arte. Se generan con `python tools/item_audit/build_art_scope.py`.
El script comprueba los 105 descartes, los 43 anteriores, los ejemplos protegidos,
el recuento de 69, la muestra de 24 y que datos/política de ejecución no cambien.

**Esta fase filtra la lista artística y registra decisiones de contenido futuro.**
No se borra ningún dato o recurso ni se cambian inventarios/guardados. El guardia
de ejecución de Item Foundation conserva sus 43 vetos anteriores; no hay nuevos
pools de tienda/botín habilitados. Al integrar esos pools se aplicará también
esta selección documentada. Los informes históricos V1 conservan su alcance.

## Fuentes

- [Nintendo: picnics, personalización y efectos de comida](https://www.nintendo.com/au/news-and-articles/new-pokemon-picnics-and-more-revealed-for-the-pokemon-scarlet-and-pokemon-violet-video-games/).
  Distingue los diseños de los accesorios de los efectos útiles de los bocadillos.
- [PokéAPI, Pañuelo Azul](https://github.com/PokeAPI/api-data/blob/master/data/api/v2/item/238/index.json): efecto de Belleza en concursos.
- [PokéAPI, Tarjeta Datos 01](https://github.com/PokeAPI/api-data/blob/master/data/api/v2/item/486/index.json): registro de victorias del Pokéathlon.
- Definiciones locales validadas y referencias evolutivas del inventario anterior.
  Los SHA-256 de las entradas se conservan en el informe de esta fase.
