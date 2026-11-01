# Auditoría inversa 13 — caramelos AV, bayas sin efecto y utilidades redundantes

**Fecha:** 2026-11-01. **Alcance:** selección futura de objetos de Pokémon Calvo. Se han contrastado los efectos con datos del repositorio y referencias de Pokémon; se ha cambiado exclusivamente el catálogo documental. No se han editado escenas, código, efectos ya conectados, filtros runtime, partidas, main ni V28.

## Resultado verificado

- Catálogo maestro: **2222 IDs únicos**.
- Estado: **743 PERMITIR + 1375 DESCARTAR + 104 APARCADO_MEGA + 0 CONDICIONAL = 2222**.
- En esta pasada: **35 PERMITIR → DESCARTAR**.
- [Registro individual de 35 modificaciones](./RANDOMLOCK_ITEMS_AUDIT_PASS13_CHANGES.csv).
- [Lista operativa actual de 743 objetos](./RANDOMLOCK_ITEMS_BUILD_SCOPE_V1.csv); [104 Mega archivados](./RANDOMLOCK_ITEMS_MEGA_APARCADO_V1.csv).

## I. Caramelos de Let's Go: 18 excluidos

**Familias:** courage_candy, health_candy, mighty_candy, quick_candy, smart_candy, tough_candy; cada una con tres tamaños (básico, L, XL). **18 IDs**.

Los 80 caramelos específicos de especie de Let's Go ya habían sido excluidos por añadir **Awakening Values (AV)** fuera del balance usual de EV. Los 18 caramelos genéricos hacen lo mismo sobre una estadística y siguen reglas AV, no EV. Habían quedado PERMITIR por clasificación demasiado general como entrenamiento.

**No confundir** con: rare_candy, los cinco exp_candy, vitaminas, plumas de EV, mochis EV, mentas, habilidades, Huevo Suerte. Estos otros recursos mantienen PERMITIR porque sus efectos corresponden a aprendizaje, experiencia y reglas de entrenamiento ordinarias.

Referencias: https://bulbapedia.bulbagarden.net/wiki/AV ; https://www.serebii.net/letsgopikachueevee/candy.shtml . Además el repositorio ya tenía los 18 AV como `deferred_art_ids` en `ITEM_ART_EXPANSION_V2.json`.

## II. Bayas culinarias sin utilidad propia en este perfil: 13 excluidas

**IDs:** bluk_berry, nanab_berry, wepear_berry, pinap_berry, cornn_berry, magost_berry, rabuta_berry, nomel_berry, spelon_berry, pamtre_berry, watmel_berry, durin_berry, belue_berry.

En juegos principales, su función habitual es cocinar Pokécubos/Pokochos; no tienen los efectos automáticos propios de Bayas Zidra, Atania, Ziuela, etc. Históricamente podían modificar el tipo/potencia de Don Natural, pero **ese movimiento está inutilizado a partir de la octava generación** y el perfil del proyecto es Gen9. No hay concursos/cocina con utilidad competitiva adoptados que justifiquen 13 objetos adicionales. En el actual catálogo no se requiere crear estas 13 funciones.

**EXCEPCIÓN PROTEGIDA: razz_berry (Baya Frambu normal) SE CONSERVA**. En Let's Go puede facilitar la captura de Pokémon; las versiones silver_razz_berry y golden_razz_berry ya se seleccionaron por ese motivo. Mantener las tres en la lista objetivo no asegura que su aplicación de captura por turnos esté programada; requiere validación.

**El resto de bayas curativas, defensivas y de potenciación NO se eliminan.** Su efecto estratégico es distinto. Fuentes: https://bulbapedia.bulbagarden.net/wiki/Natural_Gift ; https://bulbapedia.bulbagarden.net/wiki/Razz_Berry ; https://www.smogon.com/ingame/guides/berries .

## III. Cuatro utilidades equipables sin efecto Pokémon diferenciado

- **amulet_coin** (Moneda Amuleto) y **luck_incense** (Incienso Duplo): duplican el dinero obtenido tras batallas, no las estadísticas del Pokémon; además no se acumulan entre sí. Ya se excluyeron los Roto Bonos de dinero por economía indirecta. No hay que construir dos objetos equipables adicionales para justificar la economía del juego.
- **cleanse_tag** (Amuleto) y **pure_incense** (Incienso Puro): reducen encuentros salvajes cuando el líder los lleva. Carecen de valor directo como objetos tácticos de batalla; hay repelentes ya seleccionados con finalidad de exploración. Incienso Puro tiene además un uso histórico de crianza, no previsto en la selección de este randomlocke.

Son **decisiones de selección reversible**: si en una revisión posterior se acuerda que las partidas necesitan bonificaciones económicas equipables o control específico de encuentros, se recuperará uno de esos objetos por su función y no ambos por duplicación. Los efectos históricos de Incienso Puro y Amuleto no se declaran idénticos en todas las generaciones.

Fuentes: https://bulbapedia.bulbagarden.net/wiki/Amulet_Coin ; https://bulbapedia.bulbagarden.net/wiki/Luck_Incense ; https://bulbapedia.bulbagarden.net/wiki/Cleanse_Tag ; https://bulbapedia.bulbagarden.net/wiki/Pure_Incense .

## Excepciones y continuidad

- **fluffy_tail (Cola Skitty)** y **max_mushrooms (Maxiseta)** permanecen PERMITIR por decisiones expresas del usuario.
- Conservar elementos estratégicos aunque sean poco usados: `destiny_knot` tiene efecto de enamoramiento en batalla además de cría; `odd_incense` potencia Psíquico; `lucky_egg` mejora experiencia; `exp_share` reparte experiencia; `soothe_bell` ayuda a amistad/evolución.
- No eliminar `razz_berry` por su etiqueta `baking_only`: lo comprobamos individualmente.
- **Próxima auditoría:** revisar el resto de los 743 permitidos (en particular objetos de uso directo, vitaminas/medicinas, efecto real de incienso y sistema de captura) y 1375 descartados para descubrir falsos positivos/negativos. No dar por terminada la depuración ni confundir un ID permitido con un objeto ya conectado en el motor.
