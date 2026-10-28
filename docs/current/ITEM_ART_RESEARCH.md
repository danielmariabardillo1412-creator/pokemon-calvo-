# Arte de objetos: primera comparación — 2026-10-28

Petición: buscar imágenes existentes más bonitas, modernas y detalladas, idealmente
completas; completar huecos solo con estilos compatibles. No se generan imágenes
nuevas ni se instala arte en el juego en esta fase.

Actualización de alcance por petición del usuario: ver `ITEM_CONTENT_SCOPE.md` y
`ITEM_ART_SCOPE.json/CSV`. Se apartan 105 entradas decorativas/de otros modos del
plan artístico, además de los 43 vetos anteriores. El inventario de fuentes de
esta investigación se conserva como evidencia original, sin borrar sus filas.

La búsqueda ampliada de los 40 huecos está en `ITEM_ART_GAPS.md`: 39 ilustraciones
existentes descargadas y revisadas estáticamente; Rokikos sigue pendiente de estilo.

Integración posterior autorizada para beta: `ITEM_ART_BETA.md`. Se instalan 364
imágenes en el proyecto y se conectan galería/mochila. Los recuentos de esta
investigación se mantienen como evidencia de la comparación previa.

## Resultado visual

Recomendación provisional: **Escarlata/Púrpura como base**. En los 21 originales
descargados de esta fuente hay lienzos de 160 × 160, contornos definidos, sombras y
volumen. La revisión de las 24 entradas compara detalle a 120 px y vista a 48 px.
Dream World es una alternativa ilustrada de trazo más plano; puede completar
algunos huecos, pero la mezcla se aprecia. No se promete que resulte invisible.

Los 24 IDs de `ITEM_ART_PILOT.json` tienen una imagen candidata en la propuesta:
21 de Escarlata/Púrpura, Cuerda Huida y Repelente de Dream World, y MT01 del
catálogo PokéAPI (160 × 160). La imagen de la MT no asigna ni cambia su movimiento.
El catálogo raíz de PokéAPI mezcla pixel art pequeño con imágenes más modernas;
no se trata como un estilo uniforme ni como arte ya instalado en nuestra mochila.

El estado actual se guarda en `ITEM_ART_RESEARCH.json`. `ITEM_ART_PILOT.json`
conserva la lista/snapshot del cierre anterior de Item Foundation, que su
verificador y generador reproducen; su campo histórico `images_downloaded: false`
no describe esta investigación posterior. No se reescriben las pruebas de esa fase.

No se ha encontrado/verificado una colección única que cubra todos los objetos
permitidos con este mismo acabado. El catálogo incluye cartas excluidas, objetos
de historia y modos laterales: 2.222 definiciones no significan 2.222 objetos que
haya que mostrar en la versión final.

## Fuentes examinadas

| Fuente | Inspección | Límite |
| --- | --- | --- |
| [Escarlata/Púrpura, Random Talking Bush](https://www.spriters-resource.com/nintendo_switch/pokemonscarletviolet/asset/187089/) | Identificados 523 nombres PNG en la página, que anuncia 525 elementos de archivo | La diferencia no se verificó dentro del ZIP: devuelve HTTP 403. Las 21 muestras se descargaron de sus páginas individuales de Serebii; no se declara descargada esta colección entera |
| [PokéAPI/sprites](https://github.com/PokeAPI/sprites/tree/d8c2fb78563e28ad7b3abe938cf6e79998d04e90/sprites/items) | Árbol completo de objetos, sin truncar: 3.395 PNG entre todas sus carpetas; 336 Dream World | Son archivos/versiones, no 3.395 objetos únicos. 24 muestras raíz y 20 Dream World descargadas y decodificadas |
| [HD items de Verdep](https://forums.pokemmo.com/index.php?/topic/56376-hd-items/) | Descargadas versiones DW y SV PC 2.0x: 2.678.071 y 3.621.587 bytes; 814 PNG por paquete, incluido icono del mod | Mezclan imágenes modernas, adaptaciones e iconos pequeños. IDs propios de PokeMMO, sin correspondencia automática con nuestros IDs. No se instala el mod |
| [Modern Items Sprites de stingflyer](https://gamebanana.com/mods/634394) | ZIP descargado: 11.265.214 bytes, 429 PNG de 128/256 px; muestra de 60 inspeccionada | Recopila imágenes modernas y Global Link; no es una colección nueva dibujada a mayor detalle. Nombres de textura del emulador. El autor reconoce huecos en objetos clave |
| [Dream World Items de TechSkylander1518](https://eeveeexpo.com/resources/689/) | Revisada descripción y procedencia del paquete; enlace Mega localizado | El ZIP Mega no se descargó. El autor advierte de reescalados y ausencia de MT y objetos clave; no se confunde con las 336 imágenes de PokéAPI |
| [Scarlet/Violet item sprites de lichen](https://eeveeexpo.com/resources/1288/) | Revisado catálogo declarado | Es pixel art, limitado a objetos introducidos en esa generación, con exclusiones declaradas. No resuelve la petición de un conjunto entero con más detalle |

## Cobertura y precauciones técnicas del inventario

`coverage_candidates.csv` cruza todas las definiciones con los nombres disponibles;
es **inventario candidato**, no cobertura descargada ni aprobación artística.
Se conserva separado del catálogo del juego. No se deducen imágenes por parecido.

El cruce numérico usa `item_game_indices.csv` de PokéAPI, no IDs de API como si
fueran números internos de otro juego. Se detectan nueve índices duplicados de
generación 9 y se apartan de la asignación automática. Las muestras por nombre
se identifican de forma independiente en la página del propio objeto. Se guardan
las ambigüedades. «Sin coincidencia» significa pendiente, no que no exista arte.
No se pliegan automáticamente MT de distintas versiones o cristales Z bolsa/equipado.

Siguiente paso: fijar la base visual después de comparar, cruzar los objetos que
realmente se usarán y completar las familias pendientes, en particular megapiedras,
cristales Z y objetos clave. Revisar escala y legibilidad al llevarlos a la mochila.
No reemplazar un objeto faltante por otro que solo se parezca.

## Créditos y condiciones conservados

- Imágenes oficiales: The Pokémon Company / Nintendo / Game Freak. La licencia
  del código o de un recopilatorio no se anuncia como permiso sobre esas imágenes.
- Serebii / Joe Merrick y colaboradores; PokéAPI/sprites como proveedor/recopilador.
- Random Talking Bush: extracción y publicación del archivo SV consultado.
- Verdep: HD items y adaptaciones. Su hilo también atribuye aportes a DecaTilde
  y Pokéclicker, entre otros; conservar el hilo para atribución por recurso al importar.
- TechSkylander1518: recopilación Dream World; acredita Bulbagarden Staff y Joe Merrick.
- stingflyer: empaquetado Modern Items Sprites. Su ficha indica CC BY-NC-ND 4.0
  y pide consultar para redistribución o uso de partes en otros mods. Se conserva
  para investigación, sin importar/redistribuir sus adaptaciones automáticamente.
- lichen: pack de pixel art examinado, no incorporado.

## Archivos de investigación

Todo el material descargado permanece en
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\`.

`comparativa_estilos.png` resume seis objetos. `comparativa_24_1.png` a
`comparativa_24_3.png` comparan los 24; `muestra_base_moderna.png` muestra la
propuesta combinada. Los PNG fuente se conservan sin retocar bajo `samples/`.
Las hojas comparativas solo componen/reescalan imágenes existentes para revisión.

`sample_inventory.json` conserva URL, tamaño, dimensiones, SHA-256 y ausencias de
cada muestra. Los tres `*_inventory.json` conservan inventarios y hashes de ZIP.
`research_items.py` reproduce las muestras/inspección de ZIP usando el índice y
árbol guardados; `present_comparison.py` genera las hojas y el cruce candidato.
Los CSV descargados de upstream conservan sus bytes; no sustituyen datasets locales.

No se modifica código de combate, políticas de selección, recursos del juego,
guardados, datos normalizados/brutos, pruebas ni workflows durante esta investigación.
