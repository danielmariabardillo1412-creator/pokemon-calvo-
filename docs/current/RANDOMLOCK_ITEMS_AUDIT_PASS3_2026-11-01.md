# Auditoría de objetos, pasada 3 — decisiones, duplicados y excepciones (2026-11-01)

**Vigencia:** tercera pasada del catálogo del randomlocke competitivo Pokémon Calvo. Documento persistente para transferir contexto a otras conversaciones/agentes. **Es una clasificación de contenido, no una modificación del sistema de objetos ni una certificación de funcionamiento.** La rama oficial `main` y el PR V28 permanecen separados.

## 1. Inventario de decisión vigente (verificado contra los 2.222 IDs)

| Estado | Entradas | Significado |
| --- | ---: | --- |
| `PERMITIR` | **706** | Candidato estratégico aprobado; implementación individual puede faltar |
| `CONDICIONAL` | **272** | Conservado por utilidad potencial o dependencia pendiente; NO generar |
| `DESCARTAR` | **1.244** | No incluir en distribución del juego; preservar datos originales |
| **Total** | **2.222** | Sin duplicados ni filas sin decisión |

**Fases:** 92 IDs de piedras Mega + **12 accesorios para activar Mega** = **104 elementos pospuestos para la fase de megaevolución**. Fase de objetos corrientes: **706 PERMITIR + 168 CONDICIONAL = 874 candidatos** (no 874 pendientes de programar). Los 1.242 descartados siguen documentados en [CSV maestro de decisiones](./RANDOMLOCK_ITEMS_SCOPE_V1.csv).

**Evolución histórica de la clasificación** (sin cambiar el juego): primera pasada 703/259/1260 → segunda 705/476/1041 → decisiones explícitas de usuario 705/371/1146 → análisis de MT/Z 705/278/1239 → examen de regalos y separación de Mega 705/275/1242 → rectificación de captura/incursiones 706/272/1244.

## 2. Exclusiones expresas del propietario registradas en el CSV

- **80 caramelos individuales de Let's Go** (`SPECIES_SPECIFIC_TRAINING`) → `DESCARTAR`. Aumentan AV (sistema de atributo distinto de los EV); no importar esos efectos a un randomlocke competitivo. Los caramelos normales de nivel/experiencia permanecen.
- **24 fichas del Superlanzador / Wonder Launcher** (`SIDE_MODE_ITEM`) → `DESCARTAR`. Los potenciadores comunes y todos los objetos equipados estratégicos conservan sus decisiones anteriores.
- **`poke_flute`** → `DESCARTAR`. No hay ahora Snorlax de historia bloqueando rutas ni función de despertar exigida; **excepción futura explícita** si el compañero introduce un Snorlax dormido y su evento. No confundir con Flauta Azul u otras flautas de utilidad real, conservadas donde correspondan.
- No alterar prohibiciones anteriores de `linking_cord`, revivir Pokémon debilitados, `wide_lens`, `bright_powder` ni el descarte de las incursiones/crafteo MT/pícnic.

## 3. Eliminación de 90 identificadores MT/MO/DT duplicados, SIN borrar sus ataques

De los **109 IDs de máquinas históricas** pendientes, el mapeo del proyecto `modules/inventory/item_connections_v1.json` vincula:
- **90 IDs** al **mismo `move_id`** que una de las **229 MT existentes del perfil `scarlet-violet`**. Por tanto, se marcan `DESCARTAR` **como identificador de objeto redundante**, no como ataque excluido ni como regla que suprima el aprendizaje. En cada fila del CSV se documenta el ID de MT actual equivalente y el `move_id` compartido.
- **19 IDs** enseñan movimientos que **no tienen equivalente en esas 229 MT**, y siguen `CONDICIONAL`. No se presupone que su movimiento esté permitido ni que haya que crear otra máquina: cruzar con el inventario de movimientos, los perfiles de especie y el formato de libros.

| ID histórico | Movimiento referenciado |
| --- | --- |
| `hm01` | `cut` |
| `hm04` | `strength` |
| `hm05` | `flash` |
| `hm06` | `rock_smash` |
| `hm08` | `rock_climb` |
| `tm00` | `mega_punch` |
| `tr13` | `focus_energy` |
| `tr19` | `tri_attack` |
| `tr28` | `megahorn` |
| `tr31` | `iron_tail` |
| `tr39` | `superpower` |
| `tr41` | `blaze_kick` |
| `tr44` | `cosmic_power` |
| `tr50` | `leaf_blade` |
| `tr72` | `power_whip` |
| `tr83` | `ally_switch` |
| `tr85` | `work_up` |
| `tr91` | `venom_drench` |
| `tr93` | `darkest_lariat` |

Las MO de campo requieren decidir por separado si esas acciones existirán en el mapa original; no confundir tener el movimiento con necesitar MO como objeto. **No se han alterado el catálogo de movimientos ni `config/randomlock_content_v1.json`.**

## 4. Tres cristales Z descartados por las reglas que ya estaban aprobadas

| Cristal | Z excluido en el proyecto | Motivo |
| --- | --- | --- |
| `eevium_z_held` | `extreme_evoboost` | Z de estado; se permiten únicamente Z de daño |
| `pikashunium_z_held` | `10_000_000_volt_thunderbolt` | Pikachu con gorra y ataque expresamente vetados |
| `ultranecrozium_z_held` | `light_that_burns_the_sky` | Forma/ataque exclusivos no permitidos |

Los otros **32 cristales Z equipables** permanecen `CONDICIONAL`, porque sus rutas físicas de equipamiento/activación siguen requiriendo validación. Se preserva la decisión de movimientos Z de daño (50 integrados en los contextos reportados en `Z_MOVE_INTEGRATION.json`, con **400 casos nativos** y **1470 comprobaciones de gameplay** históricos), y no se reactivan Z de estado. Los 35 tokens `_z_bag` de representación ya están descartados de antes.

## 5. Tres objetos decorativos de Let's Go sin efecto de juego

`leaf_letter_eevee`, `leaf_letter_pikachu` y `small_bouquet` → `DESCARTAR`. Son recuerdos/regalos, no objetos estratégicos ni moneda funcional para el competitivo. Al menos las dos cartas Hoja Escrita constan explícitamente como **sin uso práctico** ([Bulbapedia — Leaf Letter](https://bulbapedia.bulbagarden.net/wiki/Leaf_Letter)).

## 6. Accesorios Mega — posponer junto con las megapiedras, no contabilizar como objetos de fase corriente

En el CSV se han marcado 12 IDs con `FASE_MEGA_SISTEMA_APARCADA`:

`key_stone`, `mega_anchor`, `mega_anklet`, `mega_bracelet`, `mega_charm`, `mega_cuff`, `mega_glasses`, `mega_glove`, `mega_pendant`, `mega_ring`, `mega_stickpin`, `mega_tiara`.

Son objetos de activación/soporte a la megaevolución; no son 12 evoluciones adicionales ni deben repartirse por el mapa. La [Piedra Activadora y accesorios](https://bulbapedia.bulbagarden.net/wiki/Key_Stone) confirman que comparten propósito. Su inclusión final dependerá de si se adopta la propuesta de dos piedras universales y de la interfaz. **La propuesta no está aprobada**, hay que hablarlo con el compañero al terminar los objetos normales.

## 6 bis. Rectificación de falsos descartes y objetos exclusivos de incursiones o transferencias

- **`beast_ball` (Ente Ball)**: cambia de `DESCARTAR` a **`PERMITIR`**. No existía prohibición expresa del usuario en `config/item_selection_v1.json`; descartarla por el mero hecho de ser especial fue un **error de la pasada inicial**. Sirve para capturar Ultraentes, que no deben confundirse con Pokémon de incursión. El cálculo concreto de captura se verificará en integración; `PERMITIR` no lo certifica. [Bulbapedia, modificadores de Poké Balls](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9_Ball).
- **`glimmering_charm` (Amuleto Cristalino)**: pasa a **`DESCARTAR`**; solo aumenta la recompensa de teralitos de incursiones tera. El juego no tendrá incursiones. Los **18 fragmentos tera permanecen permitidos** para cambiar el teratipo cuando el sistema esté listo. [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Glimmering_Charm).
- **`laorigin_ball` (Origen Ball)**: pasa a **`DESCARTAR`**; captura puntual de Dialga/Palkia en la historia de Leyendas Arceus, no Poké Ball de uso ordinario. [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Origin_Ball).
- **`lastrange_ball` (Extraña Ball)**: pasa a **`DESCARTAR`**; representación de transferencia entre juegos, sin obtención/uso normal en la aventura. [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Strange_Ball).

Se conservan como `CONDICIONAL` las 9 Poké Balls de Hisui con utilidad de captura real, que necesitan adaptar su fórmula/contexto al sistema de encuentros. La actualización cambia los totales a **706/272/1.244** y deja **874 candidatos de objetos corrientes** (706 aprobados, 168 pendientes).

## 7. Condicionales RESTANTES de la fase corriente: 168 IDs

| Familia | Pendientes | Criterio de revisión |
| --- | ---: | --- |
| STORY_KEY_OR_FORM_REVIEW | **38** | Distinguir objetos que cambian formas/captura/experiencia de instrumentos de mapa y herramientas de modo |
| Z_CRYSTAL | **32** | Validar objeto equipado, activación y política de daño |
| TREASURE_OR_COLLECTIBLE | **41** | Distinguir tutor de movimientos, economía y material evolutivo de venta decorativa |
| LEGACY_OR_CATEGORY_REVIEW | **23** | Roto-poderes/acciones de fusión útiles, sin introducir mecánicas especiales automáticamente |
| MACHINE | **19** | Movimientos únicos fuera de las MT activas |
| CAPTURE_BALL | **9** | 9 bolas generales de Leyendas Arceus; fórmula de captura/escena distinta |
| FIELD_USE | **6** | 6 bayas de captura variantes GO; reglas de captura todavía no adaptadas |
| **Total** | **168** | Ninguna se ofrece al jugador automáticamente |

**Detalle exacto por grupo (sin mega):**

- **CAPTURE_BALL (9)**: `lafeather_ball`, `lagigaton_ball`, `lagreat_ball`, `laheavy_ball`, `lajet_ball`, `laleaden_ball`, `lapoke_ball`, `laultra_ball`, `lawing_ball`
- **FIELD_USE (6)**: `golden_nanab_berry`, `golden_pinap_berry`, `golden_razz_berry`, `silver_nanab_berry`, `silver_pinap_berry`, `silver_razz_berry`
- **LEGACY_OR_CATEGORY_REVIEW (23)**: `dna_splicers_merge`, `dna_splicers_split`, `meteorite_2`, `meteorite_3`, `meteorite_4`, `n_lunarizer_merge`, `n_lunarizer_split`, `n_solarizer_merge`, `n_solarizer_split`, `reins_of_unity_merge`, `reins_of_unity_split`, `roto_bargain`, `roto_boost`, `roto_catch`, `roto_encounter`, `roto_exp_points`, `roto_friendship`, `roto_hatch`, `roto_hp_restore`, `roto_pp_restore`, `roto_prize_money`, `roto_stealth`, `z_power_ring`
- **MACHINE (19)**: `hm01`, `hm04`, `hm05`, `hm06`, `hm08`, `tm00`, `tr13`, `tr19`, `tr28`, `tr31`, `tr39`, `tr41`, `tr44`, `tr50`, `tr72`, `tr83`, `tr85`, `tr91`, `tr93`
- **STORY_KEY_OR_FORM_REVIEW (38)**: `adamant_crystal`, `bicycle`, `black_mane_hair`, `blue_orb`, `catching_charm`, `dna_splicers`, `dowsing_machine`, `dynamax_band`, `exp_charm`, `fishing_rod`, `fishing_rod_galar`, `good_rod`, `gracidea`, `griseous_core`, `honey`, `lustrous_globe`, `meteorite`, `meteorite_shard`, `old_rod`, `oval_charm`, `poke_radar`, `pokemon_box_link`, `prison_bottle`, `red_orb`, `reins_of_unity`, `reveal_glass`, `rotom_bike`, `rotom_catalog`, `shiny_charm`, `sparkling_stone`, `super_rod`, `teal_mask`, `tera_orb`, `town_map`, `vs_seeker`, `white_mane_hair`, `z_ring`, `zygarde_cube`
- **TREASURE_OR_COLLECTIBLE (41)**: `balm_mushroom`, `beach_glass`, `big_bamboo_shoot`, `big_mushroom`, `big_nugget`, `big_pearl`, `blue_shard`, `chalky_stone`, `comet_shard`, `discount_coupon`, `galarica_twig`, `gold_leaf`, `green_shard`, `heart_scale`, `lone_earring`, `marble`, `nugget`, `pearl`, `pearl_string`, `polished_mud_ball`, `pretty_wing`, `rare_bone`, `red_shard`, `relic_band`, `relic_copper`, `relic_crown`, `relic_gold`, `relic_silver`, `relic_statue`, `relic_vase`, `shoal_salt`, `shoal_shell`, `silver_leaf`, `star_piece`, `stardust`, `strange_souvenir`, `stretchy_spring`, `tiny_bamboo_shoot`, `tiny_mushroom`, `tropical_shell`, `yellow_shard`
- **Z_CRYSTAL (32)**: `aloraichium_z_held`, `buginium_z_held`, `darkinium_z_held`, `decidium_z_held`, `dragonium_z_held`, `electrium_z_held`, `fairium_z_held`, `fightinium_z_held`, `firium_z_held`, `flyinium_z_held`, `ghostium_z_held`, `grassium_z_held`, `groundium_z_held`, `icium_z_held`, `incinium_z_held`, `kommonium_z_held`, `lunalium_z_held`, `lycanium_z_held`, `marshadium_z_held`, `mewnium_z_held`, `mimikium_z_held`, `normalium_z_held`, `pikanium_z_held`, `poisonium_z_held`, `primarium_z_held`, `psychium_z_held`, `rockium_z_held`, `snorlium_z_held`, `solganium_z_held`, `steelium_z_held`, `tapunium_z_held`, `waterium_z_held`

### Dependencias indirectas identificadas (no descartar por categoría)

- `heart_scale` sirve como recurso histórico para recordar movimientos.
- `galarica_twig` sirve para obtener `galarica_cuff` / `galarica_wreath`: esos dos objetos evolutivos están ya PERMITIDOS. Si no existe elaboración de objetos evolutivos, la rama puede sobrar, pero no eliminarla por accidente.
- `shoal_salt` / `shoal_shell` se usaban para conseguir el `shell_bell`; Cascabel Concha ya está permitido.
- `blue_shard`, `red_shard`, `green_shard` y `yellow_shard` pueden tener rutas de tutor/intercambio. Que no haya **fabricación de MT** no implica que ya se haya decidido si habrá **tutores de movimientos**.
- `roto_boost`, `roto_catch`, `roto_exp_points` y otros roto-poderes sí pueden dar ventajas al Pokémon, así que están en revisión, NO en descartes automáticos.
- Tesoros exclusivamente vendibles quedan a la espera de decidir economía/tiendas, sin inflar catálogo con piezas inútiles por defecto.

## 8. Alcance, siguiente decisión y reversibilidad

**No hay PASS nuevo de Godot.** No cambiar `config/item_selection_v1.json`, data normalizada, saves, MT, sistema de combate, drops ni la rama `main`. Los 706 `PERMITIR` son intención de juego, no 706 efectos funcionando. La ruta técnica de ITEMS_V28 sigue independiente.

**Próxima revisión sensata:** validar los 168 candidatos por bloques con su dependencia exacta y decidir reglas de economía, captura, tutores y transformación; registrar excepciones nuevas de falsos descartes. No finalizar inventario hasta completar al menos una pasada de 1.242 excluidos atendiendo a posibles efectos poco evidentes.

**Fuentes del repositorio leídas:** `docs/current/RANDOMLOCK_ITEMS_SCOPE_V1.csv` (blob `7a9f3e83fc01c3b6d72403744e1a23be7c28adfd`), `docs/current/ITEM_INVENTORY.json` (blob `3000e5e24735a22f17d879f984346af463bda71b`), `modules/inventory/item_connections_v1.json` (blob `0525b37021edfc2e74c4fc2cb96e62f6f5b3e261`), `config/randomlock_content_v1.json` (blob `b75a9c0787ec99acd93c7a1011b35091b9085807`), `docs/current/Z_MOVE_INTEGRATION.json` (blob `b06748ff5691f0da0df27d0f184d7d6e45384c55`). Los datos originales se conservan.
