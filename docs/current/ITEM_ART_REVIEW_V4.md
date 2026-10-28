# Revisión por lotes de imágenes pendientes — 2026-10-28

Actualización posterior: las 350 entradas revisadas y los siete candidatos
generados se incorporaron al catálogo en `ITEM_ART_REVIEWED_V5.md`. Las cifras
de esta revisión se conservan como evidencia anterior a la integración.

Petición: revisar los objetos pendientes y anotar recursos que haya que buscar,
mejorar o rehacer. Se aplaza el rediseño de MT/MO/DT. No se cambia la política de
contenido ni se inventa un efecto para habilitar objetos por disponer de imagen.

## Barrido terminado

De las 1.405 entradas pendientes del recuento V1, se consultan **768**, dejando
aparte las 337 máquinas y los 300 objetos de eventos/incursiones. Primero se
revisaron 317 objetos clave/formas/legados/cultivo y después los otros 451.
Los resultados intermedios se conservaron y reanudaron, sin duplicar descargas.

- **350 entradas con ilustración localizada y revisada en cuatro hojas**.
- Son **125 hashes de imagen distintos**, no 350 dibujos diferentes.
- **418 entradas con referencia pequeña válida**, pendientes de estilo si se
  decide conservar esos objetos. No son 418 encargos de generación aprobados.
- Se resuelven 28 nombres con guiones dobles del repositorio de sprites; una
  URL fallida por puntuación no se interpreta como ausencia de imagen.

Se comprueban dimensiones reales, decodificación, alfa visible y SHA-256. La
inspección muestra los candidatos sobre blanco y a 32 px sobre fondo oscuro.
No se detectan nuevas ilustraciones corruptas entre las 350 seleccionadas.
Es una revisión en hojas, no una prueba de efectos, de mochila nativa ni de
lectura de cada imagen en el juego final.

## Registro de trabajo artístico

**Confirmado del catálogo ya instalado: Rokikos (`pewter_crunchies`)** conserva
un sprite pequeño provisional. Queda apuntado para buscar o generar una versión
afín. La antigua alternativa grande corrupta continúa descartada. Los siete
candidatos generados ya están preparados y no se vuelven a contar como dibujos
por hacer.

**Opcional: once rotopoderes (`roto_*`)** tienen un acabado sencillo con un
símbolo central deliberadamente pixelado. Se registra esa diferencia de estilo
para valorarla si se incluyen sus efectos; no son imágenes rotas y no se ordena
rehacerlos automáticamente.

**Condicional: 418 referencias pequeñas.** La lista exacta está en
`ITEM_ART_STYLE_QUEUE_V1.csv`, con ID, nombre, familia, PNG de referencia,
dimensiones, hash y siguiente acción. Gran parte pertenece a historia de juegos
concretos, caramelos de Let's Go u otros sistemas por decidir. No se borra nada
por antigüedad, texto vacío o categoría `unused`.

## Arte compartido y casos que requieren cuidado

Los 222 materiales de MT usan dos gráficos de bolsa compartidos en las fuentes
consultadas (217 y cinco entradas). No se les asignan bolsas por similitud de
color: las URL proceden de páginas/archivos con el nombre del objeto. Se registra
que son representaciones genéricas de la fuente, no dibujos específicos de cada
ingrediente. Esa reutilización se conserva como candidata, sin solicitar 222
ilustraciones nuevas.

También se detectan cestas compartidas en algunos objetos de picnic y una misma
Poké Ball para las de Koraidon/Miraidon. Se conservan los IDs separados y el
grupo de hashes compartidos; tener la misma imagen no fusiona objetos.

El Distintivo de Líder (`leaders_crest`) dispone de imagen revisada y no se
descarta con picnic decorativo por la categoría que tenga el dataset. Las
categorías son un indicio de organización, no una prueba de utilidad.

Se examinó además OLDSEAMAP de la carpeta `90x90` del paquete Dream World: el
archivo real mide 48×48 y es pixelado. Se rechazó como mejora moderna y no se
incluye entre las 350 ilustraciones. No se incorpora otro recurso de ese paquete.

## Estado y continuación

El juego conserva **654 entradas instaladas**. Hay siete candidatos generados
y 350 entradas con ilustración de fuente revisada fuera del catálogo, pendientes
de selección de contenido/integración. No se presentan como 1.011 objetos ya
funcionales. Los 156 descartes artísticos previos siguen iguales.

MT/MO/DT mantienen la dirección visual de discos durante esta fase; se pospone
su sustitución por libros u otro soporte. El barrido no certifica que todas las
máquinas estén mapeadas ni que sus imágenes estén incorporadas al catálogo.
Los 300 cristales de incursión esperan una decisión sobre ese sistema, no un
redibujado de 300 movimientos Dinamax.

Fuentes, PNG originales, páginas, errores y cuatro hojas finales:
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\review_batch_v4\`.
Cada candidato conserva URL y SHA-256. Créditos de las ilustraciones consultadas:
The Pokémon Company/Nintendo/Game Freak; recopilación Serebii y PokéAPI/sprites.
No se publica ni se ejecuta código de paquetes externos.

Informes del proyecto:

- `ITEM_ART_REVIEW_V4.json`: 350 recursos, grupos compartidos y 418 referencias.
- `ITEM_ART_REVIEW_V4.csv`: estado de las 2.222 entradas con siguiente acción.
- `ITEM_ART_FIX_QUEUE_V1.json`: Rokikos, retoques opcionales y trabajo condicional.
- `ITEM_ART_STYLE_QUEUE_V1.csv`: lista concreta de las 418 referencias pequeñas.

Reproducción del barrido: `tools/item_audit/review_pending_art.py` (reanuda el
cache). Cierre de revisión: `tools/item_audit/finalize_art_review_v4.py`.
Los hashes de los datos, el filtro de objetos y el catálogo instalado se
comparan con el censo anterior y permanecen iguales. No se ejecutan regresiones
de combate para este cambio documental y de investigación de imágenes.
