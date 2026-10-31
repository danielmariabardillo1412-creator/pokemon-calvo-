# Arte de objetos integrado en la beta — 2026-10-28

Actualización posterior: `ITEM_ART_EXPANSION_V2.md` amplía la galería a 609
entradas. Este documento conserva el alcance del primer lote de 364.
El estado vigente, incluidas ampliaciones posteriores, está en `ITEM_ART_CURRENT_STATUS.json`.

## Uso en la demo existente

Abrir `JUGAR_DEMO.cmd`, pulsar **F3** y elegir la pestaña **Objetos**.
Se puede buscar por nombre español o ID. Se muestran dos tamaños, 128 y 48 px,
con origen del arte y aviso de los diseños pendientes para la ambientación.
La galería comparte el bloqueo de movimiento/encuentros/guardado ya existente:
consultar una imagen no concede objetos ni cambia equipo, inventario o RNG.
La pestaña Pokémon conserva sus controles y comparaciones.

La mochila de medicinas del combate nativo ya muestra la imagen del objeto
seleccionado. Los botones de Poké Ball y Master Ball muestran sus iconos.
No se cambian efectos, cantidades, consumo, captura ni reglas de selección.

## Cobertura instalada

**364 PNG**, con sus bytes originales, bajo `assets/local_item_catalog/icons/`:

- 359 entradas de las cinco familias revisadas: bayas, equipados, bolas,
  medicinas permitidas y evolución.
- Cinco ejemplos adicionales de la muestra: Caramelo Raro, Menta Firme, MT01,
  Cuerda Huida y Repelente.

Origen seleccionado: **262 E/P, 83 Global Link, 17 Arceus, una MT de PokéAPI
y un icono pequeño provisional de Rokikos**. Total de imágenes: 4.284.295 bytes
(4,09 MiB), sin contar metadatos/importación de Godot.

El inventario anterior contaba coincidencias potenciales de nombres/números
en archivos de E/P. Este lote registra la fuente realmente descargada y elegida
para cada ID; los dos recuentos no son intercambiables. Confite Fruto y Extraña
Ball de Hisui se localizaron al resolver sus nombres fuera del índice general.

Se inspeccionaron cuatro hojas con las 364 imágenes; se comprobaron hashes,
dimensiones y carga como texturas Godot. La copia corrupta de Rokikos de PokéAPI
queda descartada: se usa el icono válido de 32 × 32 de Serebii, marcado provisional.
Las variantes modernas y de Hisui mantienen IDs separados; compartir un nombre
o una imagen no fusiona sus mecánicas. `lastrange_ball` y `strange_ball` conservan
sus IDs aunque la fuente ofrezca el mismo diseño de Extraña Ball.

## Decisión de ambientación del usuario

El usuario acepta estas imágenes **tal como están para la beta**. Más adelante
se discutirá su adaptación al mundo de romanos/vikingos. No se inicia ese rediseño.
Se señalan las ROM de Genesect, discos de Silvally, Cordón Unión, MT y bolas.
Las medicinas y otros diseños modernos también podrán revisarse cuando se acuerde
el criterio artístico general. No se cambian nombres canónicos ni efectos ahora.

Las ROM de Genesect son equipados que modifican el tipo de Tecno Shock; no curan.
Rokikos es una medicina de estados, distinta de una recuperación de PS. Tener
su imagen no habilita su uso: la ruta de medicinas existente sigue admitiendo
sus 15 objetos implementados. Los objetos de evolución/equipados que todavía
no tienen un flujo de mochila completo siguen pendientes de esa conexión.

## Lo que no cierra este lote

No certifica todo el catálogo de 2.222 definiciones ni todas las mecánicas.
Quedan otras familias por decidir/revisar artísticamente, incluidas megapiedras,
cristales Z, objetos clave, entrenamiento adicional y relaciones de MT de varias
versiones. Tampoco incluye los 148 descartes del plan de contenido/arte.

La selección artística no incorpora objetos a botines/tiendas. Las decisiones
adicionales de descarte siguen en `ITEM_CONTENT_SCOPE_DECISIONS.json`, y los
vetos de ejecución de Item Foundation conservan su alcance anterior.

## Créditos y reproducción

`assets/local_item_catalog/manifest.json` es el registro portable: rutas `res://`,
ID, dimensiones, SHA-256, URL de cada fuente, origen y estado provisional.
`assets/local_item_catalog/CREDITS.md` conserva los agradecimientos:
The Pokémon Company / Nintendo / Game Freak, Serebii / Joe Merrick y colaboradores,
y PokéAPI/sprites para las muestras Dream World y la MT.

Las descargas de investigación se conservan fuera del juego en
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\beta_v1\`.
El juego usa los PNG copiados y no depende de esa carpeta, de F: ni de internet.

`tools/item_audit/install_art_beta.py --prepared <prepared.json>` copia únicamente
los PNG declarados, conserva hashes y rechaza IDs fuera del plan. La preparación
por páginas y candidatos observados está en `prepare_beta.py` de la investigación.

Validación propia: `tests/gameplay/item_art_beta_test_runner.gd`, con `--capture`
para capturas reales con GPU. Regresiones: `field_native_test_runner.gd` y
`showdown_medicine_test_runner.gd`. Evidencias bajo `.godot/item_art_beta_v1/`;
informe final y hashes en `ITEM_ART_BETA_V1.json`. Los informes V1 anteriores
conservan el alcance de su fase y no se presentan como validación de este cambio.
