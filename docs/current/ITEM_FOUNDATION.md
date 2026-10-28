# Objetos: inventario y primera reutilización — 2026-10-28

Actualización posterior: `ITEM_CONNECTIONS_V1.md` documenta la mochila real,
equipar/retirar, evoluciones con objeto y MT activas, con comprobación automática.
`ITEM_SYSTEM_CURRENT_STATUS.json` es el punto de continuación funcional. El arte
ya tiene 1.011 entradas en el cierre `ITEM_ART_REVIEWED_V5.md`. Las cifras y el
orden de continuación de este documento conservan el estado de la primera fase.

## Qué está hecho

Se inventarían los **2.222 IDs** del catálogo existente, sin regenerar ni cambiar
los datasets. `ITEM_INVENTORY.json/CSV` cruza categoría, motor nativo, rutas de
mochila/captura, referencias evolutivas y política de contenido. No confunde la
presencia de un nombre con una mecánica funcionando.

El runtime fijado `@pkmn/sim@0.10.11` reconoce **565 entradas**, incluidas las 35
equivalencias explícitas de cristales `_z_held` ya existentes. 309 entradas tienen
callbacks. Ninguno de esos recuentos certifica por sí mismo su uso. Los tokens
`_z_bag` siguen separados del objeto equipado; no se convierten por parecido.

Ya había conexión para **15 medicinas de combate** y **4 Poké Balls básicas**.
Las 38 entradas de bolas del catálogo no equivalen a 38 efectos de captura
conectados. El sistema evolutivo clasifica 72 referencias de objeto (26 IDs):
57 reglas de elegibilidad disponibles y 15 solo de datos. Falta la ruta de
mochila y consumo; no se anuncian como 57 usos de objeto terminados.

## Primer lote real de equipados

21 objetos, dos semillas cada uno: **42 casos positivos** en el motor nativo y
**461 comprobaciones Godot**, incluido replay por IPC, HP/objeto exactos,
conservación de entradas, guardado JSON y publicación de la propiedad real.

Restos, Lodo Negro, Baya Zidra, Baya Aranja, Baya Ziuela, Vidasfera, Cinta Elegida,
Chaleco Asalto, Banda Focus, Casco Dentado, Globo Helio, Botas Gruesas, Hierba
Blanca, Hierba Única, Refleluz, Cinta Experto, Espray Bucal, Botón Escape,
Tarjeta Roja, Hierba Mental y Baya Higog. Los IDs estables y resultados exactos
están en `.godot/item_audit_v1/held_native.json` y `held_projection.json`.

Se comprueban ejemplos de recuperación/daño residual, consumo, bloqueo de
movimientos, daño, supervivencia, contacto, inmunidad, trampas de entrada,
restauración de bajadas, carga, pantallas, cambios forzados y confusión por
naturaleza. No es cobertura exhaustiva de cada objeto y todas sus interacciones.

Se corrige una conexión concreta: Showdown emite `-clearnegativeboost` al usar
Hierba Blanca. El adaptador ahora reconoce ese mensaje; estadísticas y efectos
siguen viniendo del estado nativo. No se escribió otra fórmula de objeto.

La Baya Zidra consumida al entrar en combate se guarda/restaura sin repetir la
curación. La colección original no cambia antes de cerrar el encuentro; una
captura publica su consumo y HP una sola vez. Para el round-trip de archivo se
comparan todos los valores y el hash del JSON nativo canónico: los hashes internos
de transacción dependen del orden de inserción y los números JSON de Godot son
floats, por lo que no se usan como comparador entre representaciones distintas.

## Decisiones de selección

El usuario delega la decisión respetando los nombres indicados por su amigo:
**Lupa (`wide_lens`) y Polvo Brillo (`bright_powder`) quedan excluidos**. Lupa
aumenta precisión, pero se respeta el veto nominal; no se añade un veto de
Incienso Suave por inferencia.

Se excluyen los cinco revivificadores: Revivir, Revivir Máximo, Hierba Revivir,
Ceniza Sagrada y Maxipanal. Este último también revive; fuente primaria guardada
en `.godot/item_audit_v1/sources/max_honey.json`, correspondiente al
[objeto 1630 de PokéAPI](https://github.com/PokeAPI/api-data/blob/master/data/api/v2/item/1630/index.json).
Se excluyen las 36 cartas. Total: **43 IDs**.

`config/item_selection_v1.json` y `item_selection_policy.gd` separan permiso de
contenido de soporte mecánico. `can_generate` exige además un conjunto explícito
de IDs utilizables. El guardia está probado, pero aún no hay nuevos generadores
de botín/tiendas enlazados a él. No borra inventarios, guardados o definiciones.
Los demás vetos de competitivo o narrativos no se inventan aquí.

Poké Muñeco tiene efecto de escape y no se clasifica automáticamente como un
peluche puramente decorativo. Las bayas de categoría «other» se reconocen por
su definición nativa; «unused» no implica ausencia de función.

## Datos que requieren trabajo posterior

Hay **338 MT/MO/DT** y learnsets de varias versiones, pero `ItemDefinition` no
contiene la relación estructurada objeto → movimiento → versión. Las
descripciones mezclan generaciones: no se usarán como código ni se deducirá el
movimiento únicamente del número de MT.

El catálogo contiene 1.267 descripciones vacías y 87 con marcadores `XXX`.
Se registran como límites de documentación; no se retoca el dataset validado.
Los 300 cristales de incursión Dinamax no son 300 ataques Maxi ni objetos
necesarios para activar el Dinamax que ya tiene el juego. Materiales de MT,
comida, objetos de historia, entrenamiento y modos laterales quedan agrupados
para revisar su utilidad real; no son miles de mecánicas nuevas certificadas.

Las megapiedras y fragmentos Tera dependen de fases especiales pendientes.
Los objetos narrativos/futuristas requieren adaptación acordada, sin cambiar
silenciosamente sus IDs o efectos.

## Orden para continuar

1. Comparar estilo/cobertura de arte con los **24 IDs** de `ITEM_ART_PILOT.json`
   al tamaño real de mochila. La investigación posterior ya tiene imágenes y
   comparativas de los 24: ver `ITEM_ART_RESEARCH.md`. La base moderna es una
   recomendación provisional; no hay estilo aprobado ni importación al juego.

   Actualización posterior: el usuario acepta el arte existente para la beta.
   `ITEM_ART_BETA.md` documenta 364 imágenes instaladas y la pestaña Objetos de F3,
   además de iconos en la mochila de combate. La aceptación es provisional para
   la beta; los diseños históricos y la funcionalidad restante siguen separados.
2. Conectar equipar/quitar/intercambiar a mochila y propiedad, respetando consumo,
   vetos y bloqueo durante combate. Reutilizar `PlayerInventory`/`PlayerCollection`.
3. Ampliar pruebas por familias de equipados; un objeto sin efecto en una fixture
   insuficiente se marca «necesita contexto», no PASS.
4. Conectar uso fuera de combate, evolución/entrenamiento y relaciones de MT;
   después condiciones de bolas especiales y objetos del mundo que se incluyan.

Reproducir: `python tools/item_audit/run.py`. Verificar evidencias actuales:
`python tools/item_audit/verify.py`. Informe de cierre de esta fase:
`ITEM_FOUNDATION_V1.json`. No significa que los 2.222 objetos sean jugables.
