# Décima auditoría — filtro de función concreta para Pokémon (2026-11-01)

**Criterio del usuario:** no basta con que un objeto tenga funcionalidad en cualquier Pokémon oficial. Para estar en el botín de Pokémon Calvo debe tener una utilidad diferenciada en el **randomlocke competitivo**: captura, evolución, entrenamiento, curación, modificación del Pokémon, uso táctico de combate o un sistema de objetos necesario y explícitamente adoptado. **No quitar solo por rareza, antigüedad, poco uso o estética** si su comportamiento es diferente y pertinente. Revisar duplicados por efecto REAL y no solo por nombre. 

## Diez exclusiones añadidas a selección documental

| ID | Antes | Ahora | Motivo principal |
| --- | --- | --- | --- |
| `bicycle` | `CONDICIONAL` | `DESCARTAR` | Bicicleta de desplazamiento; no modifica captura, combate, entrenamiento, evolucion ni curacion de Pokemon. El mapa puede tener movimiento sin que el randomizador genere una bicicleta. |
| `rotom_bike` | `CONDICIONAL` | `DESCARTAR` | Bici Rotom para desplazamiento y acceso a terreno; no es un objeto con efecto sobre el Pokemon. No confundir con Catalogo Rotom, que si cambia formas. |
| `town_map` | `CONDICIONAL` | `DESCARTAR` | Mapa de navegacion del jugador; si existe minimapa o mapa del mundo debe ser interfaz y no botin aleatorio ni objeto de efecto Pokemon. |
| `dowsing_machine` | `CONDICIONAL` | `DESCARTAR` | Detector de objetos ocultos, sin efecto propio sobre Pokemon. La busqueda de botin puede existir como mecanica del mapa sin exigir este item. |
| `discount_coupon` | `CONDICIONAL` | `DESCARTAR` | Descuento especifico en boutique de ropa, sin bonus de captura, combate, evolucion, entrenamiento o curacion; no convertir en descuento universal de tienda. |
| `fluffy_tail` | `PERMITIR` | `DESCARTAR` | Cola Skitty activa exactamente la misma huida garantizada y consumible que Poke Muneco; V21 documenta los tres flujos equivalentes. Conservar funcionamiento tecnico y datos, quitar duplicado del botin. |
| `poke_toy` | `PERMITIR` | `DESCARTAR` | Pokeseñuelo activa exactamente la misma huida garantizada y consumible que Poke Muneco; V21 documenta los tres flujos equivalentes. Conservar funcionamiento tecnico y datos, quitar duplicado del botin. |
| `park_ball` | `PERMITIR` | `DESCARTAR` | Parque Ball es herramienta de recaptura garantizada exclusivamente en Pal Park; este randomlock no usa transferencia de Pokemon desde otra partida. No es otra Master Ball normal. |
| `cherish_ball` | `PERMITIR` | `DESCARTAR` | Gloria Ball es contenedor de regalos de evento no distribuible como objeto normal y en captura ordinaria tiene multiplicador x1 sin bonus secundario; su ruta Godot V15 puede preservarse sin generarla. |
| `premier_ball` | `PERMITIR` | `DESCARTAR` | Honor Ball tiene multiplicador x1 como Poke Ball ordinaria sin ventaja sobre el Pokemon; funcion de premio/estetica de compra no forma parte de una regla de juego aprobada. Preservar definicion si se decide mas adelante. |

- **5 condicionales -> descartados**: bicicleta, bicicleta Rotom, mapa, detector de objetos ocultos, descuento de boutique. Son herramientas de desplazamiento, interfaz/exploración y vestimenta, **no efectos propios de Pokémon**. No quitar del código el futuro mapa ni impedir moverse.
- **5 permitidos -> descartados**: Cola Skitty, Pokéseñuelo (duplican huida segura de Poké Muñeco), Parque Ball (Pal Park), Gloria Ball (regalo de evento, x1 sin otra ventaja) y Honor Ball (captura x1 como Poké Ball, sin regla económica de recompensa aprobada).
- **Poké Muñeco queda PERMITIR** como representante de huida garantizada consumible. En `ITEM_ESCAPE_V21.md` se confirma que los tres objetos ya implementados realizan la **misma acción FLED** y gastan una unidad; **no eliminar código ni romper pruebas**. Solo se cambia la clasificación de distribución **propuesta de catálogo**, no el motor.
- La variante `rotom_bike` **no** es `rotom_catalog`: el Catálogo Rotom sí puede cambiar forma/tipo/ataque de un Pokémon y permanece condicional.
- La `safari_ball` y `sport_ball` siguen permitidas: la documentación V15 acredita modificador **1.5x**. No meterlas en un veto por antigüedad o por el escenario original.
- **Maxisetas** `max_mushrooms` siguen permitidas: potencian cinco estadísticas del Pokémon en combate; se exigirá revisar el balance y su distribución. Fuente: https://bulbapedia.bulbagarden.net/wiki/Max_Mushrooms.
- **Reversibilidad:** las 10 entradas se mantienen en dataset canónico y el código V15/V21 no se toca. Toda futura recuperación debe justificar una mecánica específica de Pokémon Calvo, no el simple hecho de existir en juegos originales.

## Control de conteos

Estado anterior: 706 PERMITIR + 275 CONDICIONAL + 1241 DESCARTAR = 2222.

**Estado vigente tras esta revisión: 701 PERMITIR + 270 CONDICIONAL + 1251 DESCARTAR = 2222.**

- Mega aparcado: 104 IDs intactos.
- Ordinarios condicionales: 166 IDs.
- Candidatos ordinarios de fase actual: 867 = 701 + 166.
- [Matriz vigente V4 de 270 condicionales](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V4.csv). V3 se conserva como registro histórico.
- [Catálogo maestro vigente](./RANDOMLOCK_ITEMS_SCOPE_V1.csv) contiene exactamente 2222 IDs únicos.

## Otros objetos sospechosos: NO descartados todavía

| IDs o grupo | Por qué se revisan | Por qué no retirarlos automáticamente |
|---|---|---|
| `fishing_rod`, `fishing_rod_galar`, `old_rod`, `good_rod`, `super_rod` | Cinco herramientas para crear encuentros por pesca | Si hay captura en rutas acuáticas, sí originan Pokémon y su función puede ser diferente. Verificar si el randomlocke tiene pesca como vía de encuentro autorizada; no inventar tres niveles de caña. |
| `honey`, `poke_radar`, `roto_encounter`, `roto_stealth` | Modifican frecuencia y selección de encuentros, potencialmente alterando el azar | En un randomlocke pueden manipular probabilidad de criatura/encuentro, pero no necesariamente equivalen; falta regla explícita de encuentros. |
| `oval_charm`, `roto_hatch` | Necesitan crianza o eclosión de huevos | Si no se contempla crianza, son inútiles; el randomlocke ordinario no la presupone. No inventar que ya está formalmente prohibida. |
| `pokemon_box_link` | Acceso a cajas portátil sin cambiar sistema de Pokémon | Puede saltarse restricciones del desafío; una caja básica puede quedar como función UI/centro Pokémon sin objeto de botín. |
| `vs_seeker`, `roto_exp_points`, `roto_prize_money` | Repetición o multiplicación de XP y dinero, posibles vías de farm | Exp y dinero se usan para mejorar al Pokémon, por lo que hay función indirecta; no los equiparar a un mapa decorativo. |
| `lure`, `super_lure`, `max_lure` | Afectan Pokémon raros/variocolores y duración | No equivalen necesariamente a Repelentes, que reducen encuentros; preservarlos mientras se valora el sistema de encuentros. |
| `blue_flute`, `red_flute`, `yellow_flute` | Curan sueño/enamoramiento/confusión; reutilizables | Efecto directo sobre estado, aunque su balance puede ser superior al consumible. No descartar por la categoría «flautas». |
| `black_flute`, `white_flute` | Modifican los encuentros salvajes | Distintas a las tres curativas: cambiar encuentros puede tener o no encaje en randomlocke; revisar reglas de encuentro. |
| `rare_bone`, `big_nugget`, `pretty_wing` | Tesoros vendibles, pero distinta potencia al usar Lanzamiento | La economía NO basta para conservar todos los tesoros; Lanzamiento puede dar una acción real al Pokémon. Evaluar poder y recuperación antes de excluir. |
| `tera_orb`, `z_ring`, `dynamax_band` | Activadores de mecánica especial, a diferencia de elementos del mundo | Deben funcionar como desbloqueo del sistema y no como botín aleatorio; conservar condicional, evitar duplicar activadores. |

## Advertencias para auditorías siguientes

1. **No interpretar «no competitivo» como «sin valor»**: los equipables débiles con activación de habilidad, las curas puntuales y los cambios de tipo pueden tener estrategias válidas.
2. **No volver a introducir fósiles, revivires de KO, caramelos AV, cartas, ítems de incursión, materiales de MT o Megas aparcadas** por basarse en categorías históricas.
3. **No cambiar generación de botín activa ni borrar módulos por una depuración del catálogo**, especialmente rutas verificadas de huida y captura.
4. **No falsificar cierre**: todavía quedan 270 condicionales, incluidas 104 Mega, y auditoría inversa por completar de 701 permitidos y 1251 descartados.
5. Las exclusiones documentales son el resultado del criterio general indicado por el usuario; pueden corregirse si aparece una utilidad específica diferenciada que no se había identificado.

Fuentes verificables: `docs/current/ITEM_ESCAPE_V21.md`, `docs/current/ITEM_CAPTURE_V15.md`, [Bulbapedia - Escape item](https://bulbapedia.bulbagarden.net/wiki/Escape_item), [Park Ball](https://bulbapedia.bulbagarden.net/wiki/Park_Ball), [Cherish Ball](https://bulbapedia.bulbagarden.net/wiki/Cherish_Ball), [Premier Ball](https://bulbapedia.bulbagarden.net/wiki/Premier_Ball), [Flute](https://bulbapedia.bulbagarden.net/wiki/Flute).
