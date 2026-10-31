# Los 40 huecos de objetos — 2026-10-28

## Resultado de la búsqueda ampliada

De los **40 IDs sin coincidencia en el cruce inicial**, se han descargado y
revisado en hoja conjunta **39 ilustraciones existentes**, sin generar arte:

| Fuente | Entradas | Resolución de origen |
| --- | ---: | --- |
| Pokémon Global Link, servido por Serebii | 25 | 24 de 80 × 80; una de 80 × 79 |
| Leyendas: Arceus, servido por Serebii | 12 | 128 × 128 |
| Escarlata/Púrpura, servido por Serebii | 2 | 160 × 160 |

Las dos de E/P son Peso Ball normal y Metal Compuesto: había arte, pero no se
había resuelto su correspondencia con el inventario inicial. Global Link aporta
los 17 discos de Silvally, las cuatro ROM de Genesect, Malasada Maxi, Gema Hada,
Saquito Fragante y Dulce de Nata. Arceus aporta diez bolas de Hisui, Baya Hopo
y Cordón Unión.

Las ilustraciones Global Link tienen trazo más plano que E/P. Arceus usa otro
acabado de sombreado/borde. La hoja se ha inspeccionado para identidad/variante,
fallos gráficos evidentes y lectura estática; no es aprobación artística del
usuario ni prueba de escala/renderizado en la mochila. No se retocan los originales.

## Único caso de estilo pendiente: Rokikos

`pewter_crunchies` tiene un icono válido de **32 × 32** en Serebii. No se selecciona
como ilustración del mismo acabado: sigue pendiente encontrar una imagen mejor.
No se declara que ese arte no exista en ninguna otra fuente.

Se examinó también el PNG de 64 × 64 de PokéAPI/sprites en la revisión
`d8c2fb78563e28ad7b3abe938cf6e79998d04e90`. Se **rechaza**: al componerlo sobre
fondo claro se ven bloques de colores y silueta rota. Se conserva la comparación
`pewter_compare.png`; tener más píxeles no certifica calidad.

## Identidades y comprobaciones

Cada imagen se toma de un URL realmente enlazado por la página del objeto,
con coincidencia del nombre de archivo. No se elige otra imagen del mismo HTML:
algunas páginas incluyen también ingredientes y recetas de fabricación.

Los diez IDs `la...` se enlazan expresamente con las variantes de Leyendas:
Arceus. Super Ball, Poké Ball, Ultra Ball y Peso Ball de Hisui no se sustituyen
por sus variantes modernas homónimas. Se validan rutas `/legends/` y hashes
distintos de las imágenes modernas de referencia.

Las 40 imágenes se han decodificado, comprobando dimensiones, contenido alfa
no vacío y SHA-256. `ITEM_ART_GAPS_V1.json` registra fuentes, hashes de imágenes
y páginas, revisión estática, el candidato rechazado y el único pendiente.

`ITEM_ART_SCOPE.json/CSV` ya incorpora estas correspondencias adicionales.
En las cinco familias funcionales quedan **358 de 359 entradas con candidato
ilustrado**. El caso restante es Rokikos. Es una combinación de coincidencias
del inventario anterior y los 39 archivos nuevos revisados, no 358 archivos
descargados y aprobados visualmente uno a uno. Tampoco incluye certificación de
todas las demás familias del catálogo, como megapiedras, cristales Z o claves.

## Archivos y créditos

Carpeta:
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\huecos_40\`.

- `los_40_localizados.png`: las 40 entradas, con Rokikos destacado como pendiente.
- `images/`: PNG originales de cada ID, sin retocar.
- `discovery.json`, `download_inventory.json`: páginas observadas, variantes y descargas.
- `visual_review.json`: imágenes y hoja exactas revisadas, con hashes.
- `resolve_gaps.py`: reproduce las comprobaciones y la hoja desde las descargas
  guardadas. Solo mantiene la revisión estática si sus hashes siguen coincidiendo.

Créditos: The Pokémon Company / Nintendo / Game Freak por el arte; Serebii /
Joe Merrick y colaboradores por la recopilación. PokéAPI/sprites por la copia
inspeccionada y rechazada de Rokikos; no se presenta como recurso aprobado.

Ejemplos de procedencia:
[Disco Fuego](https://www.serebii.net/itemdex/firememory.shtml),
[PiroROM](https://www.serebii.net/itemdex/burndrive.shtml),
[Poké Ball de Hisui](https://www.serebii.net/itemdex/pokeballlegends.shtml),
[Metal Compuesto](https://www.serebii.net/itemdex/metalalloy.shtml).

La investigación comunitaria también encontró
[la ampliación de Arceus para Essentials](https://eeveeexpo.com/resources/924/)
y [PokéSprite](https://msikma.github.io/pokesprite/overview/inventory.html),
pero estos no se incorporaron: las páginas individuales ya ofrecían las imágenes
ilustradas y evitaban adoptar paquetes orientados a iconos pixelados pequeños.

No se instala arte en el juego, modifica mecánica, borra datos, aplica vetos
adicionales ni se necesita descargar un juego completo para estas 39 imágenes.
