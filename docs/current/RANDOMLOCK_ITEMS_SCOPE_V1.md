# Catálogo propuesto para Pokémon Calvo — randomlocke competitivo (1-XI-2026)

> **Borrador de selección de contenido, no cambio en la lógica del juego.** Clasifica las 2.222 entradas canónicas. Los archivos originales, las partidas guardadas, los objetos ya implementados y las reglas de comercio permanecen intactos. Ninguna decisión de esta rama modifica `config/item_selection_v1.json` ni los generadores actuales.

## Resultado exacto del primer filtrado

| Decisión propuesta | Entradas | Qué significa |
| --- | ---: | --- |
| `PERMITIR` | **703** | Tiene función prevista en el randomlocke o competitivo; **NO** significa efecto ya implementado |
| `CONDICIONAL` | **259** | Conservado para revisión de especie, forma, mecánica de combate, economía o captura; no debe generarse sin resolver dependencia |
| `DESCARTAR` | **1.260** | No incluir en el catálogo de objetos generables de la versión actual; mantener definición para reversibilidad |
| **Total** | **2.222** | Cero IDs sin clasificar; ninguna entrada duplicada |

**Lista individual:** [RANDOMLOCK_ITEMS_SCOPE_V1.csv](./RANDOMLOCK_ITEMS_SCOPE_V1.csv). Contiene cada ID, nombre español, familia, categoría de origen, decisión, subgrupo, motivo, presencia en la muestra competitiva Gen9, exclusión previa, evidencia de campo V8, referencias evolutivas y presencia de definición nativa. **Los 703 no son un nuevo contador de objetos funcionales.**

### Desglose operativo

| Familia (origen) | PERMITIR | CONDICIONAL | DESCARTAR | Total |
| --- | ---: | ---: | ---: | ---: |
| MT/MO/DT históricas | 229 | 0 | 109 | 338 |
| Incursiones Dinamax | 0 | 0 | 300 | 300 |
| Materiales fabricación MT | 0 | 0 | 222 | 222 |
| Comida, picnic y recetas | 0 | 0 | 164 | 164 |
| Historia / llave / forma | 0 | 39 | 182 | 221 |
| Equipables competitivos candidatos | 177 | 0 | 2 | 179 |
| Megapiedras | 0 | 92 | 0 | 92 |
| Entrenamiento general | 84 | 0 | 0 | 84 |
| Caramelos específicos Let's Go | 0 | 0 | 80 | 80 |
| Legacy sin uso / formas heredadas | 0 | 32 | 49 | 81 |
| Bayas | 67 | 0 | 0 | 67 |
| Tesoros y coleccionables | 2 | 44 | 3 | 49 |
| Objetos de evolución | 44 | 0 | 1 | 45 |
| Poké Balls | 26 | 11 | 1 | 38 |
| Medicinas | 32 | 0 | 5 | 37 |
| Cristales Z equipados | 0 | 35 | 0 | 35 |
| Tokens de bolsa Z duplicados | 0 | 0 | 35 | 35 |
| Correo | 0 | 0 | 36 | 36 |
| Objetos de modo lateral (Miracle Shooter) | 0 | 0 | 24 | 24 |
| Campo, huida y captura | 15 | 6 | 0 | 21 |
| Fragmentos de teratipo | 18 | 0 | 0 | 18 |
| Crecimiento y fabricación de bellotas | 0 | 0 | 15 | 15 |
| Potenciadores de uso en combate | 9 | 0 | 0 | 9 |
| Complementos de actividad lateral | 0 | 0 | 5 | 5 |
| Registros de actividad lateral | 0 | 0 | 27 | 27 |
| **Total** | **703** | **259** | **1.260** | **2.222** |

## Reglas procedentes de las decisiones del proyecto

1. **Sin incursiones:** descartar los 300 cristales Dinamax de evento. Esto **no elimina Pokémon ni movimientos** vinculados en otras fuentes; solo el ítem que inicia una incursión.
2. **Sin fabricar MT:** descartar 222 materiales. Preservar **229 MT** con enseñanza y consumo verificados en el perfil actual `scarlet-violet`; los otros **109 identificadores MT/MO/DT heredados** quedan fuera de la lista generable hasta que exista una razón y tabla de aprendizaje concreta. Una MT útil puede aparecer directamente en el mapa.
3. **Sin picnic ni minijuegos:** descartar comida/ingredientes, correo, objetos de otros modos, accesorios y registros decorativos. Un objeto evolutivo clasificado por PokéAPI como `picnic` no se pierde: la familia `EVOLUTION` se clasifica aparte.
4. **Megaevolución sí:** conservar las 92 entradas de megapiedras como `CONDICIONAL`; **no permitir que aparezcan todavía todas** hasta verificar especie base permitida, forma mega, activación y generación de procedencia. El catálogo de especies del proyecto parte de **1.025 especies base y 1.076 especies del pool permitido** según la auditoría de variantes; eso no certifica todas las megaformas. Algunos IDs pertenecen a incorporaciones posteriores a la generación IX y deben revisarse individualmente.
5. **Bayas, equipables, evolución, medicamentos, Poké Balls y entrenamiento sí.** Preservar objetos con capacidad estratégica y utilidad para progresar. Las Poké Balls de Leyendas Arceus (11 IDs `la...`) son condicionales porque sus reglas de lanzamiento/captura no equivalen automáticamente a una captura por menú; `beast_ball` se deja descartada como **propuesta del alcance previo**, todavía no se añade a la política activa.
6. **Historia no:** billetes, llaves, pases de ciudades y objetos de guion heredado no entran en el mapa nuevo. **Excepción deliberada:** herramientas y equipables que realmente cambian formas o afectan al Pokémon, p. ej. `griseous_core`, `adamant_crystal`, `lustrous_globe`, `blue_orb`, `red_orb`, `dna_splicers`, `reveal_glass`, `prison_bottle`, `gracidea`, `reins_of_unity`, `teal_mask`; quedan `CONDICIONAL`, no borrados.
7. **Cable Unión sigue excluido** (`linking_cord`), como en V27. Se preservan los **10 objetos originalmente necesarios para ciertas evoluciones por intercambio**. Su adaptación a evolución por nivel u objeto **todavía no tiene tabla de niveles aprobada**; no inventar un «nivel oficial mínimo» único, ni retirar el requisito del objeto cuando corresponda.
8. **Movimientos Z y teracristalización:** los 35 cristales Z **equipables** quedan condicionales por el perfil actual de movimientos Z de daño; los 35 tokens de bolsa `_z_bag` no son objetos equipables y se descartan. Los 18 fragmentos tera quedan permitidos por decisión del usuario el 1-XI-2026; un Pokémon puede teracristalizar sin requerirlos, pues sirven para cambiar su teratipo. Su ruta funcional todavía no está implementada/certificada.
9. **Dinero y tesoros:** se condicionan los objetos meramente vendibles hasta confirmar economía o tiendas; las Chapas/Chapas Doradas se conservan por la mejora de IV. No introducir botín valioso solo para inflar inventario.

## Contraste externo y sus límites

- [Pokémon Showdown — factory sets Gen9](https://github.com/smogon/pokemon-showdown/blob/master/data/random-battles/gen9/factory-sets.json). La auditoría V28 anterior extrajo **47 IDs equipados distintos** de seis categorías de esta muestra. En el CSV: **45 PERMITIR, 1 CONDICIONAL, 1 DESCARTAR** (`wide_lens`, prohibido previamente). **Esta muestra no mide frecuencias de todos los formatos, VGC ni un randomlocke completo.**
- [Pokémon Showdown — conjuntos de random battle Gen9](https://github.com/smogon/pokemon-showdown/blob/master/data/random-battles/gen9/sets.json) y [generador de equipos](https://github.com/smogon/pokemon-showdown/blob/master/data/random-battles/gen9/teams.ts). Base para funciones de combate, **no inventario de todos los objetos de campo**.
- [Universal Pokémon Randomizer ZX](https://github.com/Ajarmar/universal-pokemon-randomizer-zx/wiki). Trata por separado evoluciones imposibles, MT/MO, Pokémon, encuentros y objetos malos: evidencia de diseño de randomizadores, **no autorización automática de los mismos objetos**.

## Fuentes exactas del repositorio

- `docs/current/ITEM_INVENTORY.json` — 2.222 filas, blob `3000e5e24735a22f17d879f984346af463bda71b`.
- `docs/current/ITEM_FIELD_V8.csv.txt` — estados por ID, blob `9509d537622039b2f1919067561631449b8ddc47`.
- `config/item_selection_v1.json` — reglas previas, blob `c164a8dc4d0302b9af69e4b6c7957b0be3ff302a`.
- `docs/handoff/ITEMS_V28/COMPETITIVE_COVERAGE_AUDIT.md` en rama `codex/items-v28-from-main`, blob `91d30a5c5e76f7266a3e4a00acca628781049542`.
- `docs/current/POKEMON_VARIANTS_INTEGRATION.json` — especies y variantes con alcance verificable.
- `config/randomlock_content_v1.json` — exclusiones reales de Pokémon/forma/movimiento; no implica sistema final de randomización.
- `modules/inventory/item_connections_v1.json` — versión MT activa `scarlet-violet`.

## Aclaración confirmada: equipables, movimientos Z y megapiedras (2026-11-01)

**Equipables competitivos:** están incluidos en los 703 candidatos: `charcoal` (Carbón), `focus_sash` (Banda Aguante), `focus_band` (Cinta Aguante), `choice_band`, `choice_specs`, `life_orb`, `leftovers`, `muscle_band`, etc. **Carbón potencia ataques Fuego, no modifica directamente la estadística Ataque.** Son objetivos del catálogo, no garantía de cobertura integral individual. `wide_lens` y `bright_powder` mantienen su exclusión específica existente, sin prohibir por ello los demás objetos Focus.

**Movimientos Z — resolución histórica, NO volver a decidirlos desde cero.** [Libro de reglas `RANDOMLOCK_RULES.md`](../../docs/project_book/RANDOMLOCK_RULES.md), sección «Decisión Z vigente y solicitudes futuras — 2026-10-27», y [`Z_MOVE_INTEGRATION.json`](./Z_MOVE_INTEGRATION.json):
- El usuario/amigo había aprobado **movimientos Z de daño SÍ; movimientos Z de estado NO**; los movimientos de estado normales permanecen.
- Registros vigentes: **50 movimientos Z de daño con integración en contextos probados**, a partir de 53 catalogados; excluidos 1 Z de estado (`extreme_evoboost`) y 2 exclusivos de formas/usuarios ausentes (`light_that_burns_the_sky`, `10_000_000_volt_thunderbolt`). No reinterpretar como «todos los Z cancelados» ni como pruebas universales de combate.
- Los **35 cristales Z equipables** continúan `CONDICIONAL` **por conexión de objeto y activación**, no porque la política sobre ataques Z esté pendiente. Los **35 tokens `_z_bag`** son duplicados de representación, no equipables.
- **No confirmada:** una limitación compartida por Mega/Z/Gigamax y la disponibilidad física de los cristales en mapa/randomizer. No cambiar reglas de combate basándose en el catálogo.

**Megapiedras — decisión de diseño aprobada:** mantener megaevolución mediante **piedra equipada y transformación estratégica en combate**, no una evolución irreversible por nivel. Los **92 IDs** se mantienen en el CSV con estado técnico `CONDICIONAL`, bajo `MEGA_APROBADA_IMPLEMENTACION_PENDIENTE`: **permitidos por concepto**, pero no generar ni afirmar que están operativos hasta confirmar especie elegible, megaforma incluida (también las incorporadas en Leyendas Z-A) y mecanismo probado de activación/reversión. La auditoría previa de objetos registraba **sistema Mega ausente**; datos nativos, iconos o transferencia de piedra no lo sustituyen.

**Fragmentos tera (`*_tera_shard`, 18): APROBADOS como contenido por el usuario (1-XI-2026).** Sirven para cambiar el teratipo asignado, **no** para activar la teracristalización. Pasan de `CONDICIONAL` a `PERMITIR` en el CSV; **su uso, coste, consumo y guardado todavía requieren implementación y pruebas** antes de permitir su generación en partidas.

**Aritmética actualizada:** 703 `PERMITIR` + 259 `CONDICIONAL` + 1260 `DESCARTAR` = 2222. Los **18 fragmentos tera** pasan a `PERMITIR` por decisión expresa del usuario; las **92 megapiedras** y **35 cristales Z** siguen condicionados técnicamente. No se modifica la política activa, los datos, V28 ni `main`; sin nuevas pruebas Godot.

## Desglose de las 92 megapiedras

Las **92 entradas** del catálogo corresponden a **86 especies megaevolucionables**. Hay **seis piedras adicionales por distintas alternativas de forma**: Charizard X/Y, Mewtwo X/Y, Raichu X/Y, y piedras Z alternativas para Absol, Garchomp y Lucario. Cada piedra se asigna a su especie/forma, **no** vale para cualquier Pokémon. Excepción histórica: Rayquaza puede megaevolucionar sin una megapiedra en los juegos donde esa regla se aplica.

Fuentes de contraste: [Pokémon, explicación oficial](https://mega.pokemon.com/es-es/), [Bulbapedia: lista de megapiedras](https://bulbapedia.bulbagarden.net/wiki/Mega_Stones), [Pokémon Legends Z-A: megapiedras](https://www.serebii.net/legendsz-a/megastones.shtml). Que existan las 92 entradas en el inventario **no acredita** que las 86 megaformas estén implementadas en el motor ni en el pool de formas del randomlocke. La arquitectura debe reutilizar un **único sistema de megaevolución parametrizado**, no programar una mecánica por piedra.

## Revisión pendiente antes de aplicar el filtro

- **Ningún descartado se borra.** No cambiar tiendas, drop tables, mapas, partidas guardadas ni políticas runtime con una tabla preliminar.
- Revisar por ID los **259 condicionales**, especialmente megapiedras y megaformas de Leyendas Z-A (no inferir su disponibilidad en el motor), cambios de forma, variantes de captura, cristales Z, tesoros económicos y objetos de tutor.
- Confirmar que las **229 MT** corresponden al repertorio elegido para el randomlocke (actualmente Escarlata/Púrpura), sin suponer automáticamente compatibilidad de otras generaciones.
- La distribución aleatoria debe obtener candidatos **solo de `PERMITIR` con efecto realmente conectado**; un ID en este CSV no certifica implementación, tasas ni balance. Los `CONDICIONAL` permanecen **fuera del generador** hasta aprobación explícita.
- Cualquier objeto añadido posteriormente se inserta por ID y motivo, conservando trazabilidad. No reconstruir los 2.222 ni reiniciar V28; catálogo de contenido y pruebas de funcionalidad son sistemas distintos.

**Estado:** `DRAFT_CLASSIFICATION_ONLY`; `main` intacta, sin aplicación de política o nuevas pruebas de Godot. El trabajo de objetos V28 continúa en su PR #118 independiente.
