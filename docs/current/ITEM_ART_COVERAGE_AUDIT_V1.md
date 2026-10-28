# Recuento de imágenes de objetos — 2026-10-28

Auditoría reproducible: `python tools/item_audit/audit_art_coverage.py`.
Se cruzan los 2.222 IDs normalizados con el plan artístico, el catálogo instalado
y los siete candidatos generados. Se verifican los hashes de las imágenes y que
los archivos fuente/datos/política no cambian durante el recuento.

## Resultado exacto por entrada

- 653 con imagen instalada sin marcar como provisional de estilo.
- 1 con icono instalado provisional: Rokikos (`pewter_crunchies`).
- 7 con imagen preparada, todavía sin instalar.
- 156 apartadas del plan artístico por criterios ya registrados.
- 1.405 sin imagen instalada/preparada y pendientes de revisión de contenido.

Total: 2.222. Hay 661 entradas con imagen instalada o preparada; sus archivos
seleccionados contienen 614 hashes distintos, porque algunos IDs comparten arte.
El número de entradas no equivale al número de ilustraciones diferentes.

## Las 1.405 entradas pendientes

| Familia | Entradas |
| --- | ---: |
| MT/MO/DT | 337 |
| Cristales de eventos de incursión | 300 |
| Materiales de fabricación de MT | 222 |
| Objetos clave, historia, eventos o formas | 221 |
| Comidas, ingredientes y actividades relacionadas | 91 |
| Categoría legada/unused, sin clasificación final | 81 |
| Caramelos específicos de especie | 80 |
| Objetos del modo Lanzador | 24 |
| Entrenamiento especial y Maxisetas | 20 |
| Cultivo/fabricación: abonos y bonguris | 15 |
| Recuerdos de compañero | 8 |
| Bayas de captura de Let's Go | 6 |
| **Total** | **1.405** |

El dataset tiene 338 máquinas: 230 MT, ocho MO y 100 DT. MT01 dispone de una
imagen de muestra; por eso el recuento restante es 337, no 338. Este número no
decide cuántos diseños necesita el futuro reemplazo de discos por libros u otro
soporte. Tampoco establece relaciones movimiento/versión, que siguen pendientes.

Los 300 cristales pertenecen a objetos de eventos/incursiones: no son 300
movimientos Dinamax pendientes. Los materiales de MT solo serían necesarios
si el juego conserva esa fabricación. Su inclusión no se decide en esta auditoría.

Las cinco familias principales ya revisadas (bayas, objetos equipables de combate,
medicinas, evolución y Poké Balls) no tienen entradas pendientes de imagen dentro
del plan actual; Rokikos tiene imagen, con acabado provisional.

## Límites y archivos

Las 1.405 son entradas del dataset todavía por revisar, no una lista aprobada de
dibujos a generar para el juego. No se eliminan automáticamente objetos por ser
antiguos, tener texto vacío o estar en la categoría unused; algunas entradas de
ese grupo pueden tener funciones válidas. Las coincidencias de nombres en fuentes
de arte tampoco cuentan como imágenes listas: 121 tienen pistas de fuentes en
el barrido anterior, sin certificación de descarga ni revisión visual actual.

No se genera Rokikos ni se rediseñan máquinas en este turno: el usuario pidió
primero el recuento para discutir después MT/MO/DT. Se conserva la idea de libros
como propuesta, sin elegir todavía un diseño ni cambiar los objetos del juego.

- `ITEM_ART_COVERAGE_AUDIT_V1.json`: informe con hashes y los 2.222 IDs.
- `ITEM_ART_COVERAGE_AUDIT_V1.csv`: estado de cada entrada.
- `ITEM_ART_REMAINING_REVIEW_V1.csv`: lista exacta de las 1.405 por revisar.
- `ITEM_ART_CURRENT_STATUS.json`: enlace de continuación.

La auditoría no cambia imágenes, mecánicas, selección de contenido, datasets,
guardados ni créditos. El catálogo instalado sigue teniendo 654 entradas.
