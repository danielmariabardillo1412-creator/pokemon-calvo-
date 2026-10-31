# Auditoría competitiva reproducible — Pokémon Calvo (31-10-2026)

## Respuesta numérica con alcance cerrado
Se cruzan los **47 objetos equipados distintos** que aparecen en los equipos predefinidos competitivos de **Pokémon Showdown, Gen 9, seis categorías Uber/OU/UU/RU/NU/PU** con la matriz de 2.222 IDs de Pokémon Calvo y los bloques con prueba integral de ITEMS_V28. **No equivale a todos los objetos usados en toda modalidad competitiva, VGC o randomlocke**. Es una lista concreta que puede ampliarse por evidencia; no se cuentan indiscriminadamente los 2.222 IDs.

- 47 de la referencia externa: **42** con escenarios de efecto documentados NO exhaustivos en la matriz V8; **4** con dependencia/contexto especial sin cerrar; **1** excluido (`wide_lens`). Los 47 existen en el simulador; 46 transferencias/equipamientos antiguos verificados; el excluido no debe reactivarse sin decisión.
- V28: **27 IDs** con ruta ampliada (7 EV + 3 defensivos + 9 de daño + 3 Elección + 3 pasivos/reactivos + 2 entrada/inmunidad); **12 están dentro de los 47**: `covert_cloak`, `expert_belt`, `mystic_water`, `never_melt_ice`, `choice_band`, `choice_specs`, `choice_scarf`, `leftovers`, `life_orb`, `rocky_helmet`, `air_balloon`, `heavy_duty_boots`. Los otros **15 son adicionales**.
- **Objetivo operativo cuantificado = 47 + 15 - 1 excluido = 61 IDs**. **27** con cierre ampliado V28; **30** con escenarios históricos pero sin prueba integral V28 por ID; **4** con dependencias. Pendiente de cierre ampliado: **34 = 30 verificables + 4 bloqueados**, no 34 efectos nuevos por escribir.
- El protocolo de V28 no reemplaza pruebas históricas, y un escenario nativo aprobado no certifica todos los disparadores, propietarios, persistencia y rutas gráficas. La revisión GPU/manual permanece pendiente.

## Fuentes con identidad verificable
- [Pokémon Showdown, gen9 factory sets](https://github.com/smogon/pokemon-showdown/blob/master/data/random-battles/gen9/factory-sets.json): blob Git SHA `d1813dac25222e5a5bf876bab3a14c3aebaca04c`, leído 31-10-2026. El recuento considera cada ID distinto, independientemente de la cantidad de sets en que aparece. Los equipos son ejemplos diseñados, **no porcentajes de uso de ladder**.
- [Matriz histórica de 2.222 IDs del proyecto](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/items-v28-from-main/docs/current/ITEM_FIELD_V8.csv.txt): blob `9509d537622039b2f1919067561631449b8ddc47`; aplicar como referencia de efecto nativo histórico, no como prueba nueva de V28.
- [V28, bloque 7: código funcional](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/commit/66b14d772f4e69746fbdb051f3294ee706cecae9) + [CI real](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41233384610): 20/20 workflows PASS; Godot Ubuntu `COMPETITIVE_DAMAGE_V28 PASS checks=500 ids=9 errors=0`; Windows portable `PUBLICATION_V27 PASS`. Es evidencia por SHA funcional, no del commit documental posterior.
- El estado V27 separado refiere **77 efectos de campo conectados y 16 Poké Balls conectadas**. No sumarlos automáticamente a los 61: son categorías con alcance distinto y posibles solapamientos.

## Lista completa de los 47 y su clasificación
Columnas: **V8** = E (escenario de efecto documentado pero no exhaustivo); D (contexto/dependencia); X (excluido). **V28** = prueba ampliada efectivamente verificada; — significa que NO consta esa cobertura específica, no que sea un objeto inoperante. Ordenados por número de apariciones en las alternativas de factory sets (no uso real).

| Objeto (Showdown) | ID interno | V8 | V28 | 
|---|---|---|---|
| Heavy-Duty Boots | `heavy_duty_boots` | E | Sí |
| Leftovers | `leftovers` | E | Sí, segunda familia declarativa |
| Choice Scarf | `choice_scarf` | E | Sí, piloto declarativo |
| Life Orb | `life_orb` | E | Sí, segunda familia declarativa |
| Rocky Helmet | `rocky_helmet` | E | Sí, segunda familia declarativa |
| Choice Specs | `choice_specs` | E | Sí, piloto declarativo |
| Air Balloon | `air_balloon` | E | Sí |
| Choice Band | `choice_band` | E | Sí, piloto declarativo |
| Assault Vest | `assault_vest` | E | — |
| Loaded Dice | `loaded_dice` | E | — |
| Lum Berry | `lum_berry` | E | — |
| Toxic Orb | `toxic_orb` | E | — |
| Booster Energy | `booster_energy` | E | — |
| Eviolite | `eviolite` | E | — |
| Expert Belt | `expert_belt` | E | Sí |
| Colbur Berry | `colbur_berry` | E | — |
| Weakness Policy | `weakness_policy` | E | — |
| Black Glasses | `black_glasses` | E | — |
| Covert Cloak | `covert_cloak` | E | Sí |
| Occa Berry | `occa_berry` | E | — |
| Earth Plate | `earth_plate` | E | — |
| Wellspring Mask | `wellspring_mask` | D | — |
| Power Herb | `power_herb` | E | — |
| Cornerstone Mask | `cornerstone_mask` | D | — |
| Flame Orb | `flame_orb` | E | — |
| Soul Dew | `soul_dew` | E | — |
| Wide Lens | `wide_lens` | X | — |
| Splash Plate | `splash_plate` | E | — |
| Focus Sash | `focus_sash` | E | — |
| Griseous Core | `griseous_core` | D | — |
| Chesto Berry | `chesto_berry` | E | — |
| Never-Melt Ice | `never_melt_ice` | E | Sí |
| Sticky Barb | `sticky_barb` | E | — |
| Shuca Berry | `shuca_berry` | E | — |
| Sitrus Berry | `sitrus_berry` | E | — |
| Mental Herb | `mental_herb` | E | — |
| Pixie Plate | `pixie_plate` | E | — |
| Rusted Sword | `rusted_sword` | D | — |
| Silk Scarf | `silk_scarf` | E | — |
| Soft Sand | `soft_sand` | E | — |
| Metal Coat | `metal_coat` | E | — |
| Red Card | `red_card` | E | — |
| Insect Plate | `insect_plate` | E | — |
| Throat Spray | `throat_spray` | E | — |
| Spell Tag | `spell_tag` | E | — |
| Kee Berry | `kee_berry` | E | — |
| Mystic Water | `mystic_water` | E | Sí |

## Quince IDs V28 adicionales fuera de la referencia
`power_weight`, `power_bracer`, `power_belt`, `power_lens`, `power_band`, `power_anklet`, `macho_brace`, `safety_goggles`, `clear_amulet`, `muscle_band`, `wise_glasses`, `charcoal`, `magnet`, `miracle_seed`, `black_belt`.

## Priorización del siguiente trabajo
Los ocho objetos priorizados (Botas, Restos, Pañuelo, Vidasfera, Casco, Gafas, Globo y Cinta) ya tienen prueba integral V28 acotada. Recommend a fourth consumption family: sitrus_berry and lum_berry (HP threshold/status cure). Inspect existing native coverage, then extend the same fixture/ownership/restore/consumption/save predicates; no production change presumed. PID lifecycle diagnosis is separate; GPU/manual remains pending. Dependencias de formas: `wellspring_mask`, `cornerstone_mask`, `griseous_core`, `rusted_sword`; no declararlas cerradas. `wide_lens` continúa excluido.

**Decisión de alcance pendiente del juego:** esta es una referencia base para *combates individuales competitivos* + ítems V28, no un canon universal de randomlocke. Las reglas específicas del randomlocke deciden qué equipables, curación en combate, generaciones, formas y formatos se permiten. El contador debe actualizarse solo cuando se cambie deliberadamente esa selección y contrastándola con pruebas, no a base de estimaciones sin nombre.

## Cierre del piloto Elección

Código 0c1f48eb4bd40ca15d794847d89c16ea6614ceb9; [Actions #41237512322](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41237512322), 20/20 workflows PASS. Los tres Choice recorren 15 escenarios compartidos, 665 comprobaciones en Ubuntu y 665 en Windows: daño específico/control, orden de turno, propiedad, bloqueo, persistencia, cambio de elección y mochila/mapa real. Los dos artefactos se descargaron y revalidaron por SHA-256 y escenario. No se reimplementaron efectos ni se certifican todas las interacciones. Avisos de ciclo de vida PID Linux y GPU/manual siguen pendientes; ver AUTOMATION_RESULTS.json.

## Segunda familia declarativa verificada

7f973f5bfb63cfae12f1dbaa956512e5291df0aa; [Actions #41241062641](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41241062641), 20/20 workflows PASS. Misma infraestructura con recuperación residual, daño/retroceso y contacto: Restos, Vidasfera, Casco Dentado. Los seis objetos del automatizador (incluidos Choice) completan 30 escenarios / 1935 aserciones por plataforma y 31 tests del validador. Dos artefactos SHA-256 revalidados por escenario contra checkpoints. Metadatos incompletos de PokéAPI 583 revisados estrictamente; datos intactos. Avisos PID Linux y GPU/manual siguen pendientes. No interpretar el recuento como certificación de todas las interacciones.

## Cierre de la tercera familia

**TERCERA FAMILIA VERIFICADA:** código `961cb0ac8712e03cd3d22e0115d8b11c1a36e08b`, [Actions #41252124368](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41252124368), **20/20 workflows PASS**. Globo Helio y Botas Gruesas incorporados al automatizador existente: **3335 comprobaciones / 40 escenarios / 8 objetos por plataforma**, más **56 tests del contrato**, Ubuntu y Windows con Godot 4.7. Globo: inmunidad Tierra, rotura física/especial real, pérdida de inmunidad, restauración y consumo persistido. Botas: cuatro peligros colocados realmente, entradas y reentradas, controles sin objeto/otro dueño y conservación. **61 = 27 verificados + 30 pendientes + 4 dependencias**. Evidencia raw de ambas plataformas y hashes revalidados. Linux: 242 diagnósticos PID en los logs capturados del automatizador; deuda abierta, distinguida del resultado funcional. Windows: 0. GPU/manual e interacciones especiales siguen pendientes. Producción y main intactos; PR #118 en borrador. El commit documental [skip ci] no añade certificación. Ver AUTOMATION_RESULTS.json.

Recommend a fourth consumption family: sitrus_berry and lum_berry (HP threshold/status cure). Inspect existing native coverage, then extend the same fixture/ownership/restore/consumption/save predicates; no production change presumed. PID lifecycle diagnosis is separate; GPU/manual remains pending.
