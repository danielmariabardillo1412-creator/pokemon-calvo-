# IA4/W04 — TANDA 02 FINALIZADA · 2026-11-10

**Rama propia:** `codex/calvo-items-20261104-w04-camp006`  
**Orden activa:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`, SHA blob `aeb1bd71c815b27c7984308d9b045ed064ba77e8`  
**Orden central IA6:** `AUTONOMY_V1/QUEUE_W04_TANDA_02.md`, SHA blob `607128980a6202d1def27d45338fbdf772b5d39b`  
**Estado:** **10/10 hitos revisados, 1 productor/identidad de forma canónica real con persistencia certificada, 1 hito de cambio de forma L3 bloqueado; 0 evoluciones por objeto/transformaciones/fusiones nuevas.**

> El piloto **no** es una nueva evolución ni una autorización para transformar 18 objetos. Es un **Slowpoke de Galar real** generado por `WildEncounterSystem.resolve` con especie regional real `slowpoke_galar` → `CreatureFactory.create` → `CreatureInstance.form_id = "slowpoke-galar"` derivado de PokéAPI. El guardado/carga Party+Storage y el sobre nativo SaveV2 son funcionales y positivos. La tabla de encuentro del test está creada explícitamente para el piloto, **no** se afirma que una zona concreta del mapa actual lo ofrezca sin configurarla.

## Hitos de la tanda

| Fila | Hito | Estado |
|---|---|---|
| 01 | Buscar productor auténtico de forma | FUENTE_VERIFICADA: regional `source_pokemon_id=10164`, PokéAPI `pokemon-form/10323` |
| 02 | `CreatureInstance.form_id` opcional | CERTIFICADO_CAMPO: vacío por defecto, sin inferencia para especie base |
| 03 | Serializar/deserializar | CERTIFICADO_SERIALIZACION: forma solo si está presente; legacy sin `form_id` conserva ausencia |
| 04 | Validación exacta | CERTIFICADO_VALIDACION: un solo piloto `slowpoke_galar → slowpoke-galar`, catálogos y Randomlock; rechaza forma y tipo corruptos |
| 05 | SaveV2 nativo, legacy y errores | CERTIFICADO_SAVEV2: `schema_version=2`, guardado positivo y rechazo sin sobrescribir el bueno |
| 06 | Fuente Factory/encuentro real | CERTIFICADO_PRODUCTOR_REAL: especie de la tabla → objeto real con `form_id`; **1 resultado funcional nuevo** |
| 07 | Party/Storage y atributos | CERTIFICADO_PROPAGACION: mismo objeto al depositar/retirar, identidad, IVs, EVs, naturaleza y movimientos intactos |
| 08 | Cambio de forma por objeto | **BLOQUEADO**: `FieldItemService` y transacción de variante protegidos, sin fuente de estado ni regla de cambio |
| 09 | Round-trip / rollback | CERTIFICADO_ROUNDTRIP: SaveGameRepository y FieldNativeSave, cambios inválidos no sobrescriben guardado correcto |
| 10 | CI y cierre | **CERTIFICADO_CI_FINAL**: regresiones CAMP003/004/005/006 y antiguo AUTORUN V1 |

`AUTORUN_V2_PROGRESS.csv` registra las diez filas por separado. El contador `funcional_real=1` se asigna **solo** a la fila06 para no contar múltiples veces el mismo piloto en campos, serialización, Factory y SaveV2.

## Contrato exacto de forma

- La creación usa el objeto `CreatureSpecies` verdaderamente elegido por el catálogo regional; la fuente original `config/pokemon_variants_v1.json` contiene `slowpoke_galar` con `base_species_id=slowpoke`, `regional_form=galar`, `source_pokemon_id=10164`.
- Se comprueba `data/api/v2/pokemon/10164/index.json` (especie `slowpoke`, forma `slowpoke-galar` y URL `pokemon-form/10323`) y `data/api/v2/pokemon-form/10323/index.json` (ID, nombre, vínculo y forma galar), además de `RandomlockContentPolicy.form_allowed`.
- No se acepta `overrides.form_id` de usuario, `species_id=slowpoke` base, ni formas no catalogadas. El helper de piloto `canonical_form_identity_w04.gd` devuelve vacío fuera del caso canónico estricto.
- `CreatureInstance.to_dict` emite la propiedad **solo si no es vacía**, y `from_dict` respeta un dato string sin completar formas legacy. `SaveGameData.validate` verifica el campo opcional y correspondencia `slowpoke_galar → slowpoke-galar` sin cambiar versión ni `build/to_dict/from_dict`; la comprobación completa de origen PokéAPI+Randomlock se realiza **antes de publicar un guardado nativo** en `FieldNativeSave._valid_creature`. No se tocan cálculos de estadísticas, habilidades ni `battle_transform_original`.
- La prueba ejerce un encuentro mediante `WildEncounterSystem.resolve`, no asigna `form_id` manualmente para producir el positivo. También intenta una forma falsa y comprueba la validación negativa y el archivo anterior conservado. Los estados del mundo y el servicio de objetos no se modificaron.

## CI de cierre: comprobado en HEAD funcional y progreso definitivo

**[Run #42735277975](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42735277975) — COMPLETED / SUCCESS**  
**SHA probado:** `8c216c9c15dd028241cb664c99f06d79a81c5536`.

Recibos reales del run:

- `W04_AUTORUN_V2_PY PASS checks=29 source=real_slowpoke_galar expected_form=slowpoke-galar`
- `W04_AUTORUN_V2_FORM_PILOT scope=canonical_slowpoke_galar producer=real_encounter form=slowpoke-galar savev2=2 gameplay_form_change=false`
- `W04_AUTORUN_V2_FORM PASS checks=37`
- `CAMP006_W04_PY PASS completed=3 last_executed=06 deferred=04 checks=211`
- `CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks=326`
- `CAMP006_W04_RESOLVER_L2 PASS completed=3 last_executed=06 deferred=04 checks=91`
- `CAMP006_W04_MILCERY_L2 PASS completed=3 last_executed=06 deferred=04 blocked=05,06 checks=150`
- `CAMP005_W04_PY PASS blocks=10 checks=673`
- `CAMP005_W04_GODOT PASS blocks=10 checks=1423`
- `CAMP004_W04_PY PASS blocks=10 checks=387`
- `CAMP004_W04_GODOT PASS blocks=10 checks=1090`
- `CAMP003_W04_PY PASS blocks=10 checks=120`
- `CAMP003_W04_GODOT PASS blocks=10 checks=270`

Adicionalmente, **AUTORUN V1 completo** volvió a terminar en **SUCCESS** [#42734715338](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42734715338), SHA `2980393004152de7f347e6c3dffd1b280d166929`.

## Migración precisa de pruebas históricas

Las primeras CI durante la implementación detectaron una negativa histórica *absoluta*: «ningún CreatureInstance tiene `form_id`». Se sustituyeron **únicamente las aserciones estáticas incompatibles** en los runners Python W04 CAMP005, CAMP006 y AUTORUN V1 por una **lista blanca explícita**: `slowpoke_galar → slowpoke-galar`.

Se mantuvieron los escenarios Godot anteriores, sus pruebas reales de rechazo para las demás especies, las regresiones de mochila/SaveV2 y el fixture histórico CAMP005 sin cambiarlo (blob `a504b65c73a399ab6c00e80b02481fe26392ec0e`). Las aserciones positivas equivalentes de productor/guardado están en `tests/gameplay/w04_autorun_v2_form_identity.gd`. No se introdujeron skips, `continue-on-error` ni cambios a la política V27. No se atribuyen como aprobados los runs iniciales fallidos: el recibo válido es el final `42735277975`.

## Cambios propios entregados

1. `modules/creatures/progression/canonical_form_identity_w04.gd` — validador exacto de catálogo/PokéAPI/política, piloto restringido.
2. `modules/creatures/domain/creature_instance.gd` — solamente campo opcional y to_dict/from_dict aditivos.
3. `modules/creatures/progression/creature_factory.gd` — derivación solo de fuente regional realmente elegida.
4. `modules/save/field_native_save.gd::_valid_creature` — guardia adicional, sin eliminar stats/naturaleza efectiva/guardas originales.
5. `modules/save/save_game_data.gd::validate` — estructura opcional, sin cambio de versión.
6. `tests/gameplay/w04_autorun_v2_form_identity.gd` y `tests/tools/test_w04_autorun_v2_form_identity.py` — pruebas negativas/positivas y productor verdadero.
7. `.github/workflows/parallel-w04-autorun-v2.yml` — CI completa; `AUTORUN_V2_PROGRESS.csv` — 10 filas.
8. Runners Python históricos W04 adaptados por **whitelist de un solo caso**.

**No se modificaron**: `main`, V28, PR#118, otras ramas, `FieldItemService`, `FieldItemBag`, sistema de captura, controlador de mapa, reloj/giro, `SaveGameSerializer`, `SaveGameRepository`, `SaveGameMigration`, schema SaveV2, Showdown, `StatCalculator` ni método `recalculate_stats`.

**Para IA6 — integración selectiva obligatoria:** su rama conjunta ya tiene cambios W02 sobre naturaleza efectiva en `CreatureInstance` y W03 en guardado nativo/SaveGameData. Trasplantar **solo** `form_id` opcional, serialización, helper y guardas por función; **no** copiar la clase completa W04 ni realizar merge ciego. Ejecutar CI conjunta del árbol combinado.

**Resultado operativo:** `TANDA 02 FINALIZADA`. W04 detiene su cola aquí; esperar nuevo `IA6_AUTORUN.md` de IA6 para TANDA03.
