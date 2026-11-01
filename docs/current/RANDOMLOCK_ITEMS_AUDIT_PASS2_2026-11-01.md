# Segunda auditoría de objetos: evitar falsos descartes (2026-11-01)

**Proyecto:** Pokémon Calvo — randomlocke competitivo, sin incursiones, sin fabricación de MT ni modo pícnic. **Estado:** auditoría documental de contenido, NO cambio de políticas, drops, inventario, motor ni partidas. El listado de decisiones por ID y justificación actual está en [RANDOMLOCK_ITEMS_SCOPE_V1.csv](./RANDOMLOCK_ITEMS_SCOPE_V1.csv).

## Resultado de la segunda pasada

- Primera revisión: **703 PERMITIR, 259 CONDICIONAL, 1.260 DESCARTAR** (2.222 IDs).
- Segunda pasada: **705 PERMITIR, 476 CONDICIONAL, 1.041 DESCARTAR** (2.222 IDs, todos únicos).
- **219 decisiones corregidas**: **2 pasan a PERMITIR** y **217 pasan a CONDICIONAL**, ninguno pasa directamente a generación activa. El criterio es *si podría ayudar a un Pokémon o al desarrollo del randomlocke, no descartarlo sin verificar la mecánica y el reglamento*.
- **92 megapiedras se mantienen condicionadas y APARCADAS hasta terminar objetos normales.** Alcance presente sin mega: **705 PERMITIR + 384 CONDICIONAL = 1.089 IDs por clasificar/implementar según corresponda**; NO son 1.089 efectos técnicos pendientes.

## Rectificaciones concretas: 6 IDs

| ID | Estado nuevo | Función y motivo | Condición/balance |
| --- | --- | --- | --- |
| `leaders_crest` | **PERMITIR** | **Emblema del Líder**: condiciona la evolución Bisharp → Kingambit al derrotar 3 Bisharp que lo llevan. Había sido tratado como «pícnic». | Adaptación a encuentros aleatorios pendiente. La especie propia no tiene que sostener el emblema para evolucionar en SV. |
| `rage_candy_bar` | **PERMITIR** | **Caramelo Furia**: cura estados alterados desde Gen VII; en Gen II-VI recuperaba 20 PS. Había sido tratado como historia. | No confundir sus efectos entre generaciones; falta probar la ruta de medicina. |
| `poke_flute` | **CONDICIONAL** | **Poké Flauta**: en Gen I y Rojo Fuego/Verde Hoja despierta a TODOS los Pokémon dormidos en combate, incluido rival; no se consume. En juegos posteriores como X/Y ya no se usa en batalla. | No incluir automáticamente en PvP ni dar curación ilimitada en aventura; pendiente definir reglas de mochila y uso fuera de combate. |
| `vs_seeker` | **CONDICIONAL** | **Buscapelea**: repetir combates de entrenadores para experiencia y dinero. | Solo si el nuevo mapa tiene sistema de revancha; cuidado con el farmeo y límites de nivel. |
| `pokemon_box_link` | **CONDICIONAL** | **Acceso a cajas remoto** sin Centro Pokémon. | Solo si las reglas de randomlocke permiten cambiar el equipo fuera del centro; posible función directa de interfaz sin objeto. |
| `dynamax_band` | **CONDICIONAL** | **Maximuñequera**: habilita Dinamax en combate, lo cual NO es lo mismo que iniciar incursiones. | Que se conserven movimientos Max en datos no prueba que el modo Dinamax esté autorizado. **Los 300 cristales de incursiones siguen fuera.** |

## Tres bloques que necesitaban revisión, aunque luego se decida descartarlos

| Bloque | IDs rescatados a CONDICIONAL | Riesgo identificado |
| --- | ---: | --- |
| `species_candies` / `SPECIES_SPECIFIC_TRAINING` | **80** | Los caramelos específicos de *Let's Go* **sí aumentan atributos** mediante AV; no equivalen a las EV de las generaciones habituales. Activar AV sin límites en Calvo rompería el competitivo. Revisar la conversión a EV o descartar expresamente, nunca declarar «decoración». |
| `all_machines` con `NEEDS_MACHINE_VERSION_PROFILE` | **109** | Son **8 MO + 1 MT00 + 100 DT/TR históricas**, no los 229 identificadores MT del perfil `scarlet-violet` ya verificados. Pueden enseñar movimientos útiles de otras generaciones. Quedan pendientes de revisión de versiones y compatibilidad: **no se generan ahora**. |
| `miracle_shooter` / `SIDE_MODE_ITEM` | **24** | Incluyen Ataque X 2/3/6, Directo 2/3 y acciones de objeto/habilidad. **Sí tienen efectos**, pero eran fichas del **Superlanzador**, modalidad PvP con coste en puntos, NO objetos normales de mochila. **No habilitar ni simular el modo sin decisión explícita**; es razonable acabar excluyéndolos por balance. |

## Control de familias principales

- **Conservar candidatos estratégicos:** los 177 equipables de combate del filtro anterior siguen PERMITIR; otros dos (`wide_lens`, `bright_powder`) permanecen prohibidos por política vigente. Abarca carbón, objetos tipo Focus, elección, Restos, Vidasfera, placas, bayas, defensas, inmunidades, precisión, curación, entrenamiento, evolución y captura.
- **Proteger efectos ocultos por categoría:** se cruzaron los **2.222 IDs** con familia de inventario, clasificación del catálogo, pistas de definición nativa y estados históricos V8. Los únicos dos objetos descartados con *hooks* nativos registrados son precisamente `wide_lens` y `bright_powder`, exclusiones explícitas. **Esto NO prueba que los demás descartes sean inútiles**: Poké Flauta, Emblema del Líder, Caramelo Furia y caramelos de especie muestran por qué la ausencia de hooks es insuficiente.
- **Descartes que siguen coherentes con el usuario:** 300 cristales de incursiones (NO Pokémon ni ataques Max), 222 materiales de fabricación de MT, 36 cartas, decoración de pícnic/recetas sin actividad, billetes y llaves de guiones ajenos, y Cable Unión. Los objetos con utilidad asociada a un sistema descartado siguen siendo revisables si aparece una excepción.
- **Estado de funcionalidad separado:** `PERMITIR` / `CONDICIONAL` indican **intención de contenido**, nunca implementación Godot certificada. Los objetos de aventura utilizables desde la mochila y los **objetos equipados** tienen rutas distintas. No mezclar reglas PvP con curación permitida en aventura.

## Política propuesta: Pokémon competitivo frente a aventura

**No decidida ni aplicada:** en los combates **PvP**, prohibir usar objetos de la bolsa durante los turnos, pero mantener los **objetos equipados** y sus consumos automáticos; durante la **aventura randomlocke**, decidir individualmente medicina de bolsa/huida/captura y si los objetos reutilizables (Poké Flauta, flautas curativas, Buscapelea) son legales. No llamar «trampa» a una mecánica histórica sin especificar primero el reglamento propio. El Wonder Launcher fue una modalidad excepcional con coste en puntos.

## Fuentes y limitaciones

**Inventario de proyecto:** `docs/current/ITEM_INVENTORY.json` (2.222; blob `3000e5e24735a22f17d879f984346af463bda71b`); `docs/current/ITEM_FIELD_V8.csv.txt` (blob `9509d537622039b2f1919067561631449b8ddc47`); `config/item_selection_v1.json` (política actual). La columna V8 es **histórica**, no certificación nueva.
**Efectos externos específicos**: [Poké Flauta — Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9_Flute), [Emblema del Líder — Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Leader%27s_Crest), [Caramelo Furia — Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Rage_candy_bar), [Caramelos de especie — Serebii](https://www.serebii.net/letsgopikachueevee/candy.shtml), [Superlanzador — Smogon](https://www.smogon.com/smog/issue20/wonder_launcher), [DT/MT y formato actual — conexión V8 del proyecto](./ITEM_FIELD_V8.csv.txt), [Maximuñequera — Pokémon oficial](https://swordshield.pokemon.com/en-us/gameplay/pokemon-become-huge-dynamax/), [Buscapelea — Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/VS_Seeker), [Pokémon Box Link — Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Box_Link).

**Alcance honesto:** se ha realizado una **segunda pasada sistemática por clasificación e indicadores** y comprobación manual dirigida de excepciones críticas, **no una prueba exhaustiva de los efectos de cada objeto en todas las generaciones**. Podrán aparecer más excepciones en sucesivas pasadas. No se ha ejecutado Godot ni revisado visualmente ninguna mecánica porque esta auditoría solo actualiza documentación.

**Siguiente auditoría aconsejada:** revisar ID a ID los 1.041 DESCARTAR restantes que sean de familia `STORY_KEY_OR_FORM_REVIEW`, `FOOD_OR_PICNIC_ACTIVITY` o `LEGACY_OR_CATEGORY_REVIEW`; rastrear condiciones de evolución no referenciadas en PokéAPI, efectos de escenario y actividades que afecten Pokémon; verificar después los 384 CONDICIONALES de la fase no-mega. **No bloquear el listado final como definitivo antes de esas pasadas.**

**Persistencia y aislamiento:** este informe y el CSV son documentación en la rama `codex/item-catalog-randomlock-v1-20261101`. `main`, los generadores actuales, la política de exclusiones y PR #118 V28 no se modifican.
