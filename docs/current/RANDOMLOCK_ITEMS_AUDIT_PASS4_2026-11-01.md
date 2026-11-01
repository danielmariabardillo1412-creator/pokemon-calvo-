# Pasada 4 — equivalencias reales y falsos duplicados (2026-11-01)

**Proyecto:** Pokémon Calvo. **Carácter:** documento de decisión preliminar, sin cambios en código, guardados, estadísticas, mapas, UI, randomizador, MT activas ni `main`. Lista exacta y motivos: [RANDOMLOCK_ITEMS_SCOPE_V1.csv](./RANDOMLOCK_ITEMS_SCOPE_V1.csv).

## Situación tras revisar duplicados y excepciones

| Estado | Objetos | Nota |
| --- | ---: | --- |
| `PERMITIR` | **706** | Candidatos al juego; efecto técnico no asegurado |
| `CONDICIONAL` | **290** | 186 por revisar en fase corriente y 104 de la fase Mega |
| `DESCARTAR` | **1.226** | No distribuir; definiciones originales intactas |
| **Total** | **2.222** | Cero IDs duplicados o sin clasificación |

**Fase actual sin Mega: 892 = 706 permitidos + 186 condicionales.** **Fase Mega posterior: 104 = 92 megapiedras + 12 accesorios.** `892 + 104 + 1226 = 2222`. No interpretar 892 como efectos por programar ni como una versión final del catálogo.

## A. Efectos que parecen iguales, pero tienen excepciones importantes

1. **DT de Espada/Escudo vs. MT de Escarlata/Púrpura.** Las DT eran consumibles y las MT de Escarlata/Púrpura también son consumibles. De los 100 IDs `tr00..tr99`, el catálogo de referencia registra **87** cuyos `move_id` ya están presentes en las 229 MT activas: solo se elimina el **objeto duplicado**, no el movimiento ni los datos de aprendizaje en otras generaciones. Las **13 restantes** permanecen condicionales. Los diferentes perfiles de compatibilidad entre especies y generaciones **no se equiparan automáticamente**. Fuentes [TR Sword/Shield](https://pokemondb.net/sword-shield/tms) y [MT Scarlet/Violet](https://www.serebii.net/scarletviolet/tm.shtml).
2. **MO históricas que comparten movimiento con MT actual.** `hm02` (Vuelo), `hm03` (Surf) y `hm07` (Cascada) habían quedado descartadas como simples duplicados. **Recuperadas a `CONDICIONAL`: son reutilizables históricamente y pueden habilitar funciones del mapa**, algo diferente de enseñar un ataque con una MT consumible. Si esas funciones se implementan directamente en el mapa sin MO, al final se descartarán como objetos. Las otras cinco MO históricas siguen condicionales por no tener MT equivalente.
3. **Objetos de fusión y reversión.** `dna_splicers_merge/split`, `reins_of_unity_merge/split`, `n_solarizer_merge/split` y `n_lunarizer_merge/split` pueden representar **los dos estados/acciones de una sola herramienta física**. No son dos objetos para repartir necesariamente. Su efecto de fusionar y separar **sí cambia**; todavía hay que definir un único objeto de bolsa más estado de fusión y conservación de ambas entidades. Por eso no se descarta todavía uno de los IDs de la base canónica. Referencias: [ADN Splicers separación](https://www.dittobase.com/scarlet-violet/items/dna-splicers--split), [Necrosol](https://bulbapedia.bulbagarden.net/wiki/N-Solarizer), [Necroluna](https://bulbapedia.bulbagarden.net/wiki/N-Lunarizer), [Riendas Unión](https://www.wikidex.net/wiki/Riendas_uni%C3%B3n).
4. **Meteoritos de Deoxys.** `meteorite` y `meteorite_2/3/4` son representaciones de métodos/estaciones para cambiar **formas diferentes** de Deoxys, no decoración simple; en Gen IX un único Meteorito permite recorrer las formas. **Posible simplificación futura a un solo objeto**, condicionada a la regla propia para la selección de forma. No se ha recortado todavía la capacidad estratégica de elegir forma. [Meteorito — WikiDex](https://www.wikidex.net/wiki/Meteorito_%28Deoxys%29).
5. **Cupones Rotom y otros consumibles.** Roto Captura, Roto Experiencia, Roto Refuerzo, Roto Cura PS, Roto Cura PP y Roto Amistad tienen **efectos distintos** y no equivalen automáticamente a objetos curativos/equipables corrientes, especialmente en duración, objetivos, coste y modo de uso. Se mantienen condicionales, sin importación automática del sistema Rotom. [RotomDex — Serebii](https://www.serebii.net/ultrasunultramoon/rotomdex.shtml).
6. **Poké Balls de Leyendas Arceus.** Hay 9 variantes restantes. Las Heavy/Leaden/Gigaton vs Feather/Wing/Jet se diferencian por alcance y contexto de captura fuera de combate; incluso las Poké/Super/Ultra históricas tienen multiplicadores propios de PLA. No afirmar equivalencia con las Poké Balls normales sin decidir captura aérea, sigilo o captura por turnos. La implementación actual `modules/capture/capture_ruleset.gd` usa reglas clásicas deterministas, no demuestra que la futura aventura vaya a copiar todo Hisui. [Captura PLA — Serebii](https://www.serebii.net/legendsarceus/capture.shtml); [Pokémon oficial](https://legends.arceus.pokemon.com/en-us/gameplay/).

## B. Corrección de la pasada 1: 15 fósiles con posible efecto real sobre Pokémon

La clasificación previa asignaba **15 fósiles a DESCARTAR por `HISTORIA_AJENA`**, pese a que en los juegos correspondientes permiten **restaurar un Pokémon**, con especial tratamiento de las cuatro piezas combinables de Galar.

**Se recuperan solo como `CONDICIONAL`, no como `PERMITIR`:**

`armor_fossil`, `claw_fossil`, `cover_fossil`, `dome_fossil`, `fossilized_bird`, `fossilized_dino`, `fossilized_drake`, `fossilized_fish`, `helix_fossil`, `jaw_fossil`, `old_amber`, `plume_fossil`, `root_fossil`, `sail_fossil`, `skull_fossil`.

**Decisión pendiente importante:** si el randomlocke obtiene todos los Pokémon en encuentros aleatorios y no quiere añadir restauración de fósiles, estos **15 volverían a descartarse**. Si se permite restaurarlos, definir si cuentan como encuentro/obtención adicional, cómo se randomiza la especie y qué pasa con las combinaciones de Galar. No se implementa laboratorio, mecánica ni NPC de forma anticipada. [Pokémon Fossils](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_fossil).

## C. Rectificaciones efectuadas en CSV

- **15 fósiles:** `DESCARTAR` → `CONDICIONAL` por restauración potencial.
- **3 MO con dimensión de campo:** `DESCARTAR` → `CONDICIONAL` por diferencia real con la MT de igual ataque.
- **0 objetos nuevos PERMITIR y 0 cambios de funcionamiento.** El catálogo pasa del estado tras pasada 3 (706/272/1244) al estado **706/290/1226**.

Los descartes expresos del usuario permanecen: 80 caramelos individuales Let's Go, 24 fichas Superlanzador, Poké Flauta (reversible para evento Snorlax), cartas, materiales MT, cristales de incursiones, Cable Unión, revive y los vetos de precisión/evasión anteriores. Las 229 MT verificadas del perfil Escarlata/Púrpura siguen permitidas.

## D. Cola vigente de condicionales en fase ordinaria — 186

| Familia | IDs |
| --- | ---: |
| `STORY_KEY_OR_FORM_REVIEW` | 53 |
| `TREASURE_OR_COLLECTIBLE` | 41 |
| `Z_CRYSTAL` | 32 |
| `LEGACY_OR_CATEGORY_REVIEW` | 23 |
| `MACHINE` | 22 |
| `CAPTURE_BALL` | 9 |
| `FIELD_USE` | 6 |
| **Total** | **186** |

**Prioridades:**
- Revisar los 15 fósiles con la futura política de encuentros randomlock.
- Revisar los 22 identificadores de MT/MO/DT antiguos (incluidas 3 MO con funcionalidad adicional de campo) sin inventar reglas del mapa.
- Reducir 41 tesoros solo después de confirmar economía, tiendas, tutores y materiales evolutivos. Una pepita y una perla pueden ser ambas vendibles, pero tener valor distinto y por tanto NO ser equivalentes.
- Mantener 32 cristales Z hasta conectar sus efectos equipados; no mezclar con movimientos Z de estado excluidos.
- Examinar 23 IDs legacy, incluidas fusiones que parecen duplicadas por ser estados de una herramienta, pero sin borrar el estado `split` que puede ser necesario como dato de simulación.
- Comprobar 38+ otros objetos de historia/forma/campo y 9 Poké Balls de Hisui por función real y contexto de uso.

## Control de límites

**No se ha ejecutado ninguna prueba nueva de Godot, y no se han cambiado las reglas activas.** El CSV es un filtro de contenido **provisional**. Este informe registra el cuarto pase para que el siguiente agente o ventana de contexto pueda continuar sin rehacer decisiones. Las 92 megapiedras y 12 accesorios siguen apartados hasta terminar esta fase y discutir el diseño con el compañero.

**Fuentes internas:** `docs/current/ITEM_INVENTORY.json` (blob `3000e5e24735a22f17d879f984346af463bda71b`), `modules/inventory/item_connections_v1.json` (blob `0525b37021edfc2e74c4fc2cb96e62f6f5b3e261`), `config/item_selection_v1.json` (blob `c164a8dc4d0302b9af69e4b6c7957b0be3ff302a`), [pasada 3](./RANDOMLOCK_ITEMS_AUDIT_PASS3_2026-11-01.md) (blob `66388bda7d4b4cf53ca75723b5c968339d83840c`), [CSV maestro](./RANDOMLOCK_ITEMS_SCOPE_V1.csv) (blob `e06a53d23184b72b9fb2ecbd988ba8cb1cb97665`).
