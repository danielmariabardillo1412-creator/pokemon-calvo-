# IA4/W04 — TANDA 03 FINALIZADA (56 variantes regionales)
Fecha: 2026-11-10. Rama exclusiva: `codex/calvo-items-20261104-w04-camp006`.

## Resultado auditado
- **10/10 grupos examinados; 56/56 especies investigadas** (excluido el Slowpoke de Galar piloto anterior).
- **51/56 identidades canónicas nuevas con encuentro real, validación de forma y validador nativo positivo, Party/Storage y SaveV2 repository positivo**.
- **5/56 bloqueadas para guardado nativo**, aunque fuente canónica/forma se validan: `exeggutor_alola` (habilidad inicial `frisk`), `ponyta_galar` y `rapidash_galar` (`run_away`), `voltorb_hisui` y `electrode_hisui` (`soundproof`). Las cinco habilidades están excluidas por `RandomlockContentPolicy.ability_allowed`; no se editó dicha política ni se cambió la habilidad generada para fingir un PASS.
- **0 evoluciones por objeto nuevas; 0 transformaciones por objeto/fusiones nuevas**. Una identidad regional generada por Factory NO equivale a evolución.
- Los encuentros se crean en tablas explícitas de test de `WildEncounterSystem.resolve`; **no** se afirma que alguna zona jugable actual incluya estas especies.
- La validación nativa positiva de los 51 se comprobó mediante `FieldNativeSave._valid_creature`. El guardado/carga de Party y Storage se comprobó mediante `SaveGameRepository`. No afirmar round-trip del sobre `FieldNativeSave.write/read` para todos los 51: el test V3 conserva el piloto native completo de Slowpoke de Galar por separado.

## Manifiesto por fila
| Fila | Región | Examinadas | Formas con validación nativa positiva | Bloqueadas |
|---|---|---:|---:|---|
| 01 | Alola 1 | 6 | 6 | 0 |
| 02 | Alola 2 | 6 | 6 | 0 |
| 03 | Alola 3 | 6 | 5 | 1 |
| 04 | Galar 1 | 6 | 4 | 2 |
| 05 | Galar 2 | 6 | 6 | 0 |
| 06 | Galar 3 | 6 | 6 | 0 |
| 07 | Hisui 1 | 5 | 3 | 2 |
| 08 | Hisui 2 | 5 | 5 | 0 |
| 09 | Hisui 3 | 5 | 5 | 0 |
| 10 | Hisui + Paldea | 5 | 5 | 0 |
| **Total** | | **56** | **51** | **5** |

## Contrato de identidad
1. Lista blanca exacta de 57 pares (las 56 nuevas + el piloto Slowpoke de Galar) declarados en `canonical_form_identity_w04.gd` a partir del registro verificado `config/pokemon_variants_v1.json`.
2. El `source_pokemon_id` de `CreatureSpecies.source_metadata` se coteja con `data/api/v2/pokemon/<id>/index.json` y el `pokemon-form` enlazado. `form_id` proviene del nombre auténtico del formulario PokéAPI, no de una interpolación ni de un override de UI. `mr_mime` del catálogo se corresponde con `mr-mime` de PokéAPI. Variantes como Darmanitan Galar Standard y Tauros Paldea Breed se comprueban por los IDs reales.
3. Guardado SaveV2 optativo y compatible con legacy; se rechazan campos corruptos, especies equivocadas y formas cruzadas.
4. Factory conserva source real, especie, naturaleza, IV/EV, habilidad y movimientos sin sustituir los valores para aprobar casos de prueba.
5. `RandomlockContentPolicy` conserva su autoridad, incluyendo el bloqueo de habilidades de cinco formas. Es una dependencia de política/selección de habilidad de alcance IA6; W04 no modifica código protegido.

## CI real — SHA funcional
**[W04 V3 run #42876057234](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42876057234): COMPLETED/SUCCESS**, SHA `20b47366a5b0798041fbf44297559d69421eaa58`.

Comprobaciones: primer grupo Alola 6/6, matriz exhaustiva V3 (56 examinadas, 51 nativas positivas, 5 bloqueadas), piloto Slowpoke de Galar, estáticas históricas CAMP003–006/AUTORUN V1 y TANDA02, regresiones Godot CAMP003–006, resolver y Milcery. Todos los steps de la CI indicada: SUCCESS.

La última actualización documental del CSV puede producir SHA posterior al funcional. No atribuir el run anterior a un SHA posterior sin verificar CI nueva.

## Cambios de alcance propio
- `modules/creatures/progression/canonical_form_identity_w04.gd`: lista blanca y verificador PokéAPI real; admite slugs regionales compuestos; no sintetiza identidades.
- `modules/creatures/progression/creature_factory.gd`: derivación solo de especie verdaderamente seleccionada por catálogo; sin overrides de forma.
- `modules/save/save_game_data.gd::validate`: solo regla opcional y estructural de `form_id`; SaveV2 versión 2 sin cambio.
- `tests/gameplay/w04_autorun_v3_alola_group01.gd`, `tests/gameplay/w04_autorun_v3_all_regional.gd`, workflow `parallel-w04-autorun-v3.yml`.
- Adaptación con whitelist de las aserciones estáticas congeladas de W04 para la sucesión de la cola IA6, sin suprimir tests ni fixtures históricos.

## Pendiente para IA6
Decidir formalmente cómo seleccionar una habilidad permitida en los encuentros reales de cinco especies si es compatible con la política de contenido. Si no lo es, mantener esas cinco excluidas de guardado nativo. No ampliar autorizaciones W04 unilateralmente. Integración selectiva con ramas W02/W03: preservar naturaleza efectiva y ledger de captura, jamás merge global a ciegas.

**STOP W04**: no tareas 11+ hasta que IA6 publique la siguiente tanda en `IA6_AUTORUN.md`.
