# Catálogo propuesto para Pokémon Calvo — randomlocke competitivo (1-XI-2026)

## ESTADO VIGENTE — décima auditoría · criterio «función específica para Pokémon» (2026-11-01)

**El usuario ha precisado que un objeto que solo sirve para explorar, desplazarse, decorar o repetir una función sin aportar estrategia nueva no debe generarse en el randomlocke.** Se retiran del catálogo de selección **10 IDs adicionales**: 5 condicionales de mundo/ropa (`bicycle`, `rotom_bike`, `town_map`, `dowsing_machine`, `discount_coupon`) y 5 permitidos que duplicaban efectos o dependían de evento ajeno (`fluffy_tail`, `poke_toy`, `park_ball`, `cherish_ball`, `premier_ball`). `poke_doll` queda como objeto de huida; no borrar ninguna ruta técnica V15/V21.

**Contador vigente: 701 PERMITIR + 270 CONDICIONAL + 1.251 DESCARTAR = 2.222 IDs únicos.** Mega aparcada: 104; condicionales ordinarios: 166. [Matriz vigente V4](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V4.csv) y [auditoría 10 con razones](./RANDOMLOCK_ITEMS_AUDIT_PASS10_2026-11-01.md). **Todos los recuentos anteriores de este archivo son históricos y no deben utilizarse como estado actual.**

> **Borrador de selección de contenido, no cambio en la lógica del juego.** Clasifica las 2.222 entradas canónicas. Los archivos originales, las partidas guardadas, los objetos ya implementados y las reglas de comercio permanecen intactos. Ninguna decisión de esta rama modifica `config/item_selection_v1.json` ni los generadores actuales.

## ESTADO VIGENTE — novena auditoría (2026-11-01) · prevalece sobre todos los contadores anteriores

**Decisión confirmada del usuario: DESCARTAR los 15 fósiles restaurables** porque el randomlocke ya obtiene esas especies por encuentros aleatorios; no habrá restauración de fósiles como nueva vía de Pokémon. Cambiado el CSV maestro por ID, sin borrar definiciones originales. **Totales vigentes: 706 PERMITIR + 275 CONDICIONAL + 1.241 DESCARTAR = 2.222.** De los 275 condicionales, **104 Mega están aparcados** y quedan **171 condicionales ordinarios**; fase de objetos normal **877 candidatos** (706+171). La [matriz vigente V3](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V3.csv) contiene los 275, y la [novena auditoría](./RANDOMLOCK_ITEMS_AUDIT_PASS9_2026-11-01.md) registra los 15 IDs y la razón. **El histórico V2 de 290 y los recuentos 706/290/1226 de pasadas anteriores ya NO son vigentes.**

## Estado ACTUAL — cuarta pasada de equivalencias (2026-11-01)

**Este bloque prevalece sobre los recuentos históricos de las pasadas 1, 2 y 3 que se conservan más abajo.**

[Auditoría 4: duplicados auténticos, MO, fusiones, bolas y fósiles](./RANDOMLOCK_ITEMS_AUDIT_PASS4_2026-11-01.md). Se detectaron **15 fósiles** descartados incorrectamente como historia: se devuelven a `CONDICIONAL`, porque pueden restaurar Pokémon pero todavía no está decidida esa mecánica en el randomlock. Se identificaron **3 MO** (`hm02`, `hm03`, `hm07`) que enseñan el mismo ataque que una MT vigente, pero pueden tener **función de campo o reutilización diferente**: se recuperan a `CONDICIONAL`. Los otros **87 ID de DT antiguos** duplicados por movimiento siguen fuera del catálogo de objetos generables, conservando las definiciones.

**Contador vigente comprobado:** **706 PERMITIR + 290 CONDICIONAL + 1.226 DESCARTAR = 2.222 IDs**. **Fase actual: 892 candidatos** (**706 permitidos + 186 condicionales**). **Mega más adelante: 104 (92 megapiedras + 12 accesorios)**. Ningún recuento representa el número de efectos técnicos que faltan por programar.

**No eliminar todavía** las dos variantes `merge/split` de ADN, Necrosol/Necroluna o Riendas Unión ni los meteoritos de Deoxys: pueden representar operaciones/estados internos de **un solo objeto físico**, pero la fusión/desfusión o forma concreta son mecánicas diferentes que requieren una tabla de transformación y pruebas. No eliminar por identidad nominal; documentar antes cómo se sustituyen por un solo objeto en el inventario.

## Histórico: tercera auditoría y decisiones de exclusión (2026-11-01)

[Informe histórico y cola de 168 condicionales tras la tercera pasada](./RANDOMLOCK_ITEMS_AUDIT_PASS3_2026-11-01.md). El listado **vigente** es la [auditoría 4](./RANDOMLOCK_ITEMS_AUDIT_PASS4_2026-11-01.md).

Se han **descartado expresamente** 80 caramelos específicos de Let's Go (AV), 24 objetos de Superlanzador y la Poké Flauta (sin Snorlax dormido en el mapa). La Poké Flauta puede rescatarse si se diseña ese evento con el compañero.

**Rectificaciones posteriores:** Ente Ball vuelve a `PERMITIR` por su efecto estratégico de captura de Ultraentes. Amuleto Cristalino, Origen Ball y Extraña Ball pasan a `DESCARTAR` porque sus funciones dependen de incursiones, una misión concreta o transferencias, respectivamente. Los 18 fragmentos tera continúan permitidos. Se detalla en el informe de la pasada 3.

Se han **descartado documentalmente** 90 IDs históricos MT/MO/DT que enseñan el **mismo movimiento que una de las 229 MT activas**, sin excluir ni borrar ataques, 3 cristales Z incompatibles con exclusiones anteriores y 3 recuerdos decorativos de Let's Go. Permanecen bajo revisión **19 máquinas históricas sin equivalente** y **32 cristales Z viables en principio**.

**104 entradas pertenecen a la fase Mega aplazada**: 92 megapiedras y 12 anillos/pulseras/accesorios que contienen o habilitan la Piedra Activadora. Quedan **874 candidatos en la fase ordinaria de aquella pasada**, de los cuales **168 estaban pendientes de decisión**. Las 706 entradas permitidas **no equivalen a 706 efectos funcionales**. No se ha cambiado el motor ni la política activa del juego.

## Histórico: segunda auditoría conservadora (2026-11-01)

Se ha documentado la [segunda revisión cruzada de las 2.222 entradas](./RANDOMLOCK_ITEMS_AUDIT_PASS2_2026-11-01.md). La primera selección **703 / 259 / 1.260** era provisional: tenía falsos descartes. Se recuperaron **219 IDs** para evaluación por efectos sobre Pokémon: **2 PERMITIR** (Emblema del Líder y Caramelo Furia) y **217 CONDICIONAL** (Poké Flauta, Buscapelea, acceso portátil a cajas, Maximuñequera, 80 caramelos de especie, 109 MT/MO/DT históricas y 24 objetos del Superlanzador). **No se han incorporado como efectos funcionales ni autorizado generación automática.**

**Conteo HISTÓRICO al acabar la segunda pasada (ya superado):** 705 PERMITIR + 476 CONDICIONAL + 1.041 DESCARTAR = 2.222. La pasada 3 deshace 105 rescates por veto expreso, descarta 90 máquinas históricas duplicadas, 3 Z incompatibles y 3 regalos sin uso. **Consulta el estado vigente debajo y [la pasada 3](./RANDOMLOCK_ITEMS_AUDIT_PASS3_2026-11-01.md).**

## Orden de trabajo confirmado — objetos antes que megaevoluciones (2026-11-01)

**Decisión expresa del usuario:**

1. **FASE ACTUAL — objetos ordinarios del randomlocke competitivo.** Alcance del catálogo **892 IDs excluyendo los 104 elementos del subsistema Mega**: **706 `PERMITIR` + 186 `CONDICIONAL` corrientes**. Revisar los 186 condicionales; implementar y probar lo funcionalmente pendiente de los permitidos, sin repetir trabajo ya verificado. Los 892 NO son 892 efectos sin programar.
2. **FASE SIGUIENTE, solo DESPUÉS de terminar la fase de objetos:** megaevoluciones y su interfaz, formas, activación, pruebas y objetos asociados. Las **92 entradas `MEGA_STONE` y 12 accesorios de activación Mega** se mantienen en estado `CONDICIONAL` y **excluidos del trabajo presente**, no se reparten ni habilitan. La posible **piedra universal con máximo dos unidades** es una propuesta a discutir con el compañero, no una decisión aplicada.
3. **Conservación:** mantener los 2.222 registros originales y los descartes propuestos sin destrucción, guardar trazabilidad y no modificar la rama oficial `main` ni las pruebas V28 de forma indirecta.

**Comprobación de cierre de cantidades:** 706 permitidos + 186 condicionales corrientes = **892 en fase actual**; 104 elementos Mega aparte (92 piedras y 12 accesorios); 1.226 descartados; **892 + 104 + 1.226 = 2.222**. El criterio `PERMITIR` expresa alcance de contenido, **no** un PASS de implementación. Esta nota es documental; no cambia el generador de objetos.

## Estado vigente del catálogo tras cuarta auditoría (2026-11-01)

| Decisión propuesta | Entradas | Qué significa |
| --- | ---: | --- |
| `PERMITIR` | **706** | Tiene función prevista en el randomlocke o competitivo; **NO** significa efecto ya implementado |
| `CONDICIONAL` | **290** | Conservado para revisión de especie, forma, mecánica de combate, economía o captura; no debe generarse sin resolver dependencia |
| `DESCARTAR` | **1.226** | No incluir en el catálogo de objetos generables de la versión actual; mantener definición para reversibilidad |
| **Total** | **2.222** | Cero IDs sin clasificar; ninguna entrada duplicada |

**Lista individual:** [RANDOMLOCK_ITEMS_SCOPE_V1.csv](./RANDOMLOCK_ITEMS_SCOPE_V1.csv). Contiene cada ID, nombre español, familia, categoría de origen, decisión, subgrupo, motivo, presencia en la muestra competitiva Gen9, exclusión previa, evidencia de campo V8, referencias evolutivas y presencia de definición nativa. **Los 706 no son un nuevo contador de objetos funcionales.**

### Desglose operativo

| Familia (origen) | PERMITIR | CONDICIONAL | DESCARTAR | Total |
| --- | ---: | ---: | ---: | ---: |
| MT/MO/DT históricas | 229 | 22 | 87 | 338 |
| Incursiones Dinamax | 0 | 0 | 300 | 300 |
| Materiales fabricación MT | 0 | 0 | 222 | 222 |
| Comida, picnic y recetas | 1 | 0 | 163 | 164 |
| Historia / llave / forma | 1 | 56 | 164 | 221 |
| Equipables competitivos candidatos | 177 | 0 | 2 | 179 |
| Megapiedras | 0 | 92 | 0 | 92 |
| Entrenamiento general | 84 | 0 | 0 | 84 |
| Caramelos específicos Let's Go | 0 | 0 | 80 | 80 |
| Legacy sin uso / formas heredadas | 0 | 32 | 49 | 81 |
| Bayas | 67 | 0 | 0 | 67 |
| Tesoros y coleccionables | 2 | 41 | 6 | 49 |
| Objetos de evolución | 44 | 0 | 1 | 45 |
| Poké Balls | 27 | 9 | 2 | 38 |
| Medicinas | 32 | 0 | 5 | 37 |
| Cristales Z equipados | 0 | 32 | 3 | 35 |
| Tokens de bolsa Z duplicados | 0 | 0 | 35 | 35 |
| Correo | 0 | 0 | 36 | 36 |
| Objetos de modo lateral (Miracle Shooter) | 0 | 0 | 24 | 24 |
| Campo, huida y captura | 15 | 6 | 0 | 21 |
| Fragmentos de teratipo | 18 | 0 | 0 | 18 |
| Crecimiento y fabricación de bellotas | 0 | 0 | 15 | 15 |
| Potenciadores de uso en combate | 9 | 0 | 0 | 9 |
| Complementos de actividad lateral | 0 | 0 | 5 | 5 |
| Registros de actividad lateral | 0 | 0 | 27 | 27 |
| **Total** | **706** | **290** | **1.226** | **2.222** |

## Reglas procedentes de las decisiones del proyecto

1. **Sin incursiones:** descartar los 300 cristales Dinamax de evento. Esto **no elimina Pokémon ni movimientos** vinculados en otras fuentes; solo el ítem que inicia una incursión.
2. **Sin fabricar MT:** descartar 222 materiales. Preservar **229 MT** con enseñanza y consumo verificados en el perfil actual `scarlet-violet`; los **109 identificadores MT/MO/DT históricos** ya se cotejaron por movimiento: **87 IDs DT redundantes están descartados**, y **22 ID históricos quedan condicionales**, incluidos 3 MO que tienen uso diferente fuera del combate por no tener MT equivalente en el perfil actual. No se borró ninguno de sus ataques. Una MT útil puede aparecer directamente en el mapa.
3. **Sin picnic ni minijuegos:** descartar comida/ingredientes, correo, accesorios y registros decorativos. Los 24 objetos especiales del Superlanzador han sido **descartados por decisión expresa del usuario**, igual que los 80 caramelos individuales de Let's Go, sin afectar a los potenciadores generales. Se ha rescatado el Emblema del Líder (`leaders_crest`) del grupo `picnic` por su función evolutiva; además los objetos de familia `EVOLUTION` se preservan.
4. **Megaevolución sí:** conservar las 92 entradas de megapiedras como `CONDICIONAL`; **no permitir que aparezcan todavía todas** hasta verificar especie base permitida, forma mega, activación y generación de procedencia. El catálogo de especies del proyecto parte de **1.025 especies base y 1.076 especies del pool permitido** según la auditoría de variantes; eso no certifica todas las megaformas. Algunos IDs pertenecen a incorporaciones posteriores a la generación IX y deben revisarse individualmente.
5. **Bayas, equipables, evolución, medicamentos, Poké Balls y entrenamiento sí.** Preservar objetos con capacidad estratégica y utilidad para progresar. Las 9 Poké Balls ordinarias de Leyendas Arceus quedan condicionales hasta adaptar su captura; `laorigin_ball` y `lastrange_ball` se descartan por ser exclusivas de historia/transferencia. `beast_ball` (Ente Ball) se ha **recuperado como PERMITIR** por su ventaja de captura de Ultraentes: excluirla en la primera pasada fue un error, nunca una prohibición del usuario.
6. **Historia no:** billetes, llaves, pases de ciudades y objetos de guion heredado no entran en el mapa nuevo. **Excepción deliberada:** herramientas y equipables que realmente cambian formas o afectan al Pokémon, p. ej. `griseous_core`, `adamant_crystal`, `lustrous_globe`, `blue_orb`, `red_orb`, `dna_splicers`, `reveal_glass`, `prison_bottle`, `gracidea`, `reins_of_unity`, `teal_mask`; quedan `CONDICIONAL`, no borrados.
7. **Cable Unión sigue excluido** (`linking_cord`), como en V27. Se preservan los **10 objetos originalmente necesarios para ciertas evoluciones por intercambio**. Su adaptación a evolución por nivel u objeto **todavía no tiene tabla de niveles aprobada**; no inventar un «nivel oficial mínimo» único, ni retirar el requisito del objeto cuando corresponda.
8. **Movimientos Z y teracristalización:** **32 cristales Z equipables** quedan condicionales por conexión de objeto y **3 se descartan** porque su movimiento/forma ya estaba excluido; los 35 tokens de bolsa `_z_bag` no son objetos equipables y se descartan. Los 18 fragmentos tera quedan permitidos por decisión del usuario el 1-XI-2026; un Pokémon puede teracristalizar sin requerirlos, pues sirven para cambiar su teratipo. Su ruta funcional todavía no está implementada/certificada.
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

**Equipables competitivos:** están incluidos en los 706 candidatos: `charcoal` (Carbón), `focus_sash` (Banda Aguante), `focus_band` (Cinta Aguante), `choice_band`, `choice_specs`, `life_orb`, `leftovers`, `muscle_band`, etc. **Carbón potencia ataques Fuego, no modifica directamente la estadística Ataque.** Son objetivos del catálogo, no garantía de cobertura integral individual. `wide_lens` y `bright_powder` mantienen su exclusión específica existente, sin prohibir por ello los demás objetos Focus.

**Movimientos Z — resolución histórica, NO volver a decidirlos desde cero.** [Libro de reglas `RANDOMLOCK_RULES.md`](../../docs/project_book/RANDOMLOCK_RULES.md), sección «Decisión Z vigente y solicitudes futuras — 2026-10-27», y [`Z_MOVE_INTEGRATION.json`](./Z_MOVE_INTEGRATION.json):
- El usuario/amigo había aprobado **movimientos Z de daño SÍ; movimientos Z de estado NO**; los movimientos de estado normales permanecen.
- Registros vigentes: **50 movimientos Z de daño con integración en contextos probados**, a partir de 53 catalogados; excluidos 1 Z de estado (`extreme_evoboost`) y 2 exclusivos de formas/usuarios ausentes (`light_that_burns_the_sky`, `10_000_000_volt_thunderbolt`). No reinterpretar como «todos los Z cancelados» ni como pruebas universales de combate.
- Los **35 cristales Z equipables** continúan `CONDICIONAL` **por conexión de objeto y activación**, no porque la política sobre ataques Z esté pendiente. Los **35 tokens `_z_bag`** son duplicados de representación, no equipables.
- **No confirmada:** una limitación compartida por Mega/Z/Gigamax y la disponibilidad física de los cristales en mapa/randomizer. No cambiar reglas de combate basándose en el catálogo.

**Megapiedras — decisión de diseño aprobada:** mantener megaevolución mediante **piedra equipada y transformación estratégica en combate**, no una evolución irreversible por nivel. Los **92 IDs** se mantienen en el CSV con estado técnico `CONDICIONAL`, bajo `MEGA_APROBADA_IMPLEMENTACION_PENDIENTE`: **permitidos por concepto**, pero no generar ni afirmar que están operativos hasta confirmar especie elegible, megaforma incluida (también las incorporadas en Leyendas Z-A) y mecanismo probado de activación/reversión. La auditoría previa de objetos registraba **sistema Mega ausente**; datos nativos, iconos o transferencia de piedra no lo sustituyen.

**Fragmentos tera (`*_tera_shard`, 18): APROBADOS como contenido por el usuario (1-XI-2026).** Sirven para cambiar el teratipo asignado, **no** para activar la teracristalización. Pasan de `CONDICIONAL` a `PERMITIR` en el CSV; **su uso, coste, consumo y guardado todavía requieren implementación y pruebas** antes de permitir su generación en partidas.

**Aritmética V4 vigente:** 706 `PERMITIR` + 290 `CONDICIONAL` + 1226 `DESCARTAR` = 2222. Los **18 fragmentos tera** pasan a `PERMITIR` por decisión expresa del usuario; las **92 megapiedras y 12 accesorios Mega** siguen aparcados; de los 35 cristales Z, 32 permanecen condicionados y 3 están descartados según reglas anteriores. No se modifica la política activa, los datos, V28 ni `main`; sin nuevas pruebas Godot.

## Desglose de las 92 megapiedras

Las **92 entradas** del catálogo corresponden a **86 especies megaevolucionables**. Hay **seis piedras adicionales por distintas alternativas de forma**: Charizard X/Y, Mewtwo X/Y, Raichu X/Y, y piedras Z alternativas para Absol, Garchomp y Lucario. Cada piedra se asigna a su especie/forma, **no** vale para cualquier Pokémon. Excepción histórica: Rayquaza puede megaevolucionar sin una megapiedra en los juegos donde esa regla se aplica.

Fuentes de contraste: [Pokémon, explicación oficial](https://mega.pokemon.com/es-es/), [Bulbapedia: lista de megapiedras](https://bulbapedia.bulbagarden.net/wiki/Mega_Stones), [Pokémon Legends Z-A: megapiedras](https://www.serebii.net/legendsz-a/megastones.shtml). Que existan las 92 entradas en el inventario **no acredita** que las 86 megaformas estén implementadas en el motor ni en el pool de formas del randomlocke. La arquitectura debe reutilizar un **único sistema de megaevolución parametrizado**, no programar una mecánica por piedra.

## Estado actual: megapiedras pospuestas (2026-11-01)

**Decisión expresa del usuario:** APARCAR la implementación de la megaevolución y el debate de las dos piedras universales hasta hablar con su compañero. Ahora se prioriza el catálogo y la conexión de objetos normales. No programar ni ilustrar megapiedras ni adaptar formularios/combates durante esta fase.

La propuesta de **una clase de megapiedra universal con dos copias por partida** continúa abajo como **idea no aprobada**. Diseño visual también provisional: conservar la forma general de la megapiedra y sustituir el emblema interior por un signo de infinito, con nombre aún por decidir. No producir imagen todavía ni tratar estas dos unidades como límite vigente.

Si más adelante se confirma el sistema, la variante para un Pokémon con varias megaformas (p. ej. Charizard X/Y) debería elegirse **al equipar/preparar el equipo, antes del combate**, y quedar bloqueada para ese combate; luego la megaevolución se activaría opcionalmente durante la batalla. El combate clásico solo permite un Pokémon megaevolucionado por entrenador. Esto es **propuesta UX**, no implementación.

**Sin cambios técnicos ni de recuentos**: los 92 IDs de megapiedra siguen condicionales en la clasificación del catálogo y no se generan; no tocar `main`, el motor de objetos actual, rutas de combate, ni el PR de V28.

## Propuesta en debate: megapiedra universal con dos unidades por partida (2026-11-01)

**Estado: propuesta del usuario pendiente de consultarla con su amigo. NO es una decisión final y NO modifica la política activa ni las 92 entradas originales de piedras.**

- En vez de distribuir 92 IDs de megapiedras específicas, distribuir **dos copias totales** de **un único ID nuevo de piedra universal** por partida/guardado. Las piedras no se consumen; se pueden reequipar entre combates. Este máximo debe controlarse en todo el guardado (equipo, PC, bolsa, mapa y transacciones), no solo en la bolsa.
- Solo puede equiparse para megaevolucionar a una especie que tenga **megaforma definida y válida**. Equiparla no inventa megaforma ni sustituye estadísticas/habilidades/modelos. No se crean nuevas megaformas ni ilustraciones por esta propuesta.
- **Máximo de dos candidatos equipados simultáneamente y una megaevolución activada por entrenador y combate** si se adopta la mecánica por turnos clásica. No confundir dos piedras disponibles con dos megaevoluciones activas en el mismo combate. Normativa oficial clásica: [Pokémon España](https://www.pokemon.com/es/destacados/mayo-trae-consigo-la-magia-de-la-megaevolucion). El sistema de tiempo real de Leyendas Z-A no debe mezclarse inadvertidamente.
- Para Charizard, Mewtwo, Raichu y otras especies con variantes X/Y/Z, la **megaforma se preselecciona al preparar el equipo** y queda bloqueada durante ese combate, evitando el cambio oportunista tras ver al rival. La forma exacta sigue pendiente de diseño/validación.
- Propuesta técnica no destructiva: mantener las piedras originales y su tabla especie→megaforma como **metadatos del motor nativo**; el objeto de la partida es universal, mientras el adaptador construye el correspondiente ID nativo específico durante la ejecución del combate (siempre que el simulador soporte esa megaforma), sin reescribir cada efecto. En guardado/mapa/bolsa persiste solo el ID universal.
- La antigua excepción de Rayquaza debe revisarse: bajo límite de dos candidatos, permitir megaevolucionar sin piedra rompería el presupuesto. O se le exige la universal, o se documenta una excepción con coste competitivo equivalente; **pendiente de aprobación**.
- **Riesgo:** simplificar 92 ítems y su distribución NO elimina el trabajo de implementar/validar las megaformas, su UI, su arte y su integración real. Tampoco garantiza equidad si el reparto de ambas piedras no es equivalente entre jugadores.
- **No aplicar todavía una política de ejecución** a partir de los recuentos (706 PERMITIR / 290 CONDICIONAL / 1226 DESCARTAR) ni activar nuevas reglas. Si se aprueba, se producirá una V2 del catálogo, sin eliminar las definiciones canónicas, y una especificación funcional separada para el adaptador de megaevolución.

## Revisión pendiente antes de aplicar el filtro

- **Ningún descartado se borra.** No cambiar tiendas, drop tables, mapas, partidas guardadas ni políticas runtime con una tabla preliminar.
- Revisar por ID los **186 condicionales corrientes** detallados en [auditoría 4](./RANDOMLOCK_ITEMS_AUDIT_PASS4_2026-11-01.md): 22 máquinas históricas (incluidas 3 MO de campo), 32 cristales Z, 41 tesoros, 53 claves/formas/fósiles/experiencia/campo, 23 legacy útiles, 9 bolas de Leyendas Arceus y 6 bayas de captura GO. Las 92 megapiedras y 12 accesorios se dejan para fase posterior.
- Confirmar que las **229 MT** corresponden al repertorio elegido para el randomlocke (actualmente Escarlata/Púrpura), sin suponer automáticamente compatibilidad de otras generaciones.
- La distribución aleatoria debe obtener candidatos **solo de `PERMITIR` con efecto realmente conectado**; un ID en este CSV no certifica implementación, tasas ni balance. Los `CONDICIONAL` permanecen **fuera del generador** hasta aprobación explícita.
- Cualquier objeto añadido posteriormente se inserta por ID y motivo, conservando trazabilidad. No reconstruir los 2.222 ni reiniciar V28; catálogo de contenido y pruebas de funcionalidad son sistemas distintos.

**Estado:** `DRAFT_CLASSIFICATION_ONLY`; `main` intacta, sin aplicación de política o nuevas pruebas de Godot. El trabajo de objetos V28 continúa en su PR #118 independiente.

## Sexta revisión registrada — lotes 25 + 46 (2026-11-01)

La continuación posterior a la quinta auditoría examinó **71 IDs distintos** (25 tesoros y 46 de formas). **No ha alterado las 2.222 filas ni los estados oficiales**: 706/290/1226. De esos 71, **33 ya estaban PERMITIR y 38 CONDICIONAL**. No restar automáticamente objetos de los 290; las recomendaciones de conservación/descartes siguen sujetas a revisión. Las diferencias, dependencias y propuestas están **guardadas por ID** en el [registro de revisión V1](./RANDOMLOCK_ITEMS_REVIEW_LOG_V1.csv) y explicadas en la [sexta auditoría](./RANDOMLOCK_ITEMS_AUDIT_PASS6_2026-11-01.md). **Próxima acción: resolver los condicionales de fase ordinaria sin volver a repasar los 71 salvo que se detecte contradicción.**

## Séptima revisión — matriz de los 290 condicionales (2026-11-01)

Se ha generado [RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V2.csv](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V2.csv), con **290 filas por ID** y función, dependencia, riesgo y propuesta de decisión. Los **104 elementos Mega permanecen apartados**; los **186 condicionales normales** se han organizado por requisito, de los cuales **38 ya tenían una revisión individual V6 que prevalece sobre agrupaciones posteriores**. [Auditoría 7](./RANDOMLOCK_ITEMS_AUDIT_PASS7_2026-11-01.md). **No se ha modificado el maestro 706/290/1226 ni el estado activo del juego.** Las propuestas son reversibles y pendientes de contraste/decisión.

## Octava pasada — auditoría inversa preliminar (2026-11-01)

Se ha iniciado la revisión inversa con **15 IDs señalados (14 permitidos y un descartado)** en el [registro por ID](./RANDOMLOCK_ITEMS_AUDITORIA_INVERSA_V1.csv) y la [auditoría 8](./RANDOMLOCK_ITEMS_AUDIT_PASS8_2026-11-01.md). **Duralium** puede ser un falso descarte por tutores/EV; Parque Ball/Gloria Ball/Honor Ball requieren justificar su distribución; Maxisetas tiene un potenciador de cinco estadísticas cuya disponibilidad requiere balance. Ningún estado ha sido cambiado aún. Seguir auditando la lista completa y no confundir permisos con verificación técnica.
