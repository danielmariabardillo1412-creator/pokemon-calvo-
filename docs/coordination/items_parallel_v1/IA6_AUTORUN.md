# IA6 — RELEVO AUTORIZADO W04 · TANDA 04 (orden vigente)

**TANDA03 10/10 cerrada, CI #42876057234 y #42876625902 SUCCESS.** IA6 ha examinado los 56 casos: 51 positivos, 5 bloqueados por política de habilidad; TANDA04 se centra en desbloquear cuatro con habilidad normal canónica, sin inventar habilitación de la habilidad oculta. No repitas TANDA03 ni atribuyas diez objetos a diez hitos.

**Al recibir `p` o `sigue`:** consulta ESTA nota `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` de TU rama, recupera checkpoint y empieza el primer hito pendiente de la nueva TANDA04, continuando los diez sin solicitar permiso por microbloque. No existe ejecución background entre turnos; guardar checkpoint y reanudar con la próxima `p`.

**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`. Protocolo árbitro `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` en `codex/calvo-items-20261101-arbitro`; cola central `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W04_TANDA_04.md`. Después de completar 10 filas, emitir informe + CI final y detenerse hasta nuevo relevo IA6. `10/10 examinados` != `10 objetos nuevos` != `código integrado en IA6`. No tocar main, V28, PR118, otras ramas, archivos compartidos sin permisos expresos.

---

# IA6 — W04 TANDA 04 · SELECCIÓN DE HABILIDADES CANÓNICAS EN FORMAS REGIONALES
**Rama:** `codex/calvo-items-20261104-w04-camp006`. **Cierre comprobado T03:** 10/10 grupos, **51 de 56 formas** nuevas con identidad/persistencia positivas; **5 bloqueadas por habilidad inicial excluida**, 0 nuevas evoluciones por objeto. CI funcional [#42876057234](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42876057234) SUCCESS, código `20b47366a5b0798041fbf44297559d69421eaa58`; CI documental [#42876625902](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42876625902) SUCCESS sobre HEAD `1c2f4cb648f6e0018d5f7e5b8f96de447fe508e9`. No repetir conteo T03 ni reclamar 56/56 nativas.

## Hallazgo de IA6: se puede intentar desbloquear cuatro sin inventar habilidades
En `config/pokemon_variants_v1.json`, los candidatos canónicos son:
- `ponyta_galar` / `rapidash_galar`: primera `run_away` (excluida); alternativa normal `pastel_veil` (no excluida).
- `voltorb_hisui` / `electrode_hisui`: primera `soundproof` (excluida); alternativa normal `static` (no excluida).
- `exeggutor_alola`: primera `frisk` (excluida), alternativa `harvest` **OCULTA**. No dar habilidad oculta automáticamente sin un mecanismo legítimo de obtención y autorización explícita de modo Randomlock; mantener `BLOQUEADO` si no hay productor.

**Decisión de IA6:** se autoriza seleccionar una habilidad **canónica NORMAL** que pase la política vigente cuando la primera está prohibida, únicamente en la generación de encuentros regionales, sin cambiar el set de habilidades canónico, sin cambiar probabilidades de otras especies ni sobrescribir un `overrides.ability_id` válido. Si no hay normal permitida, fallar explícitamente. No confundir `ability_allowed` con garantía de implementación nativa; probar motor real.

## Diez hitos autorizados
| Fila | Entrega comprobable |
|---|---|
| 01 | Verificar las 5 especies bloqueadas, todas las `ability_slots`, política vigente y estado de `CreatureFactory.create` con prueba roja |
| 02 | Diseñar helper puro W04 que seleccione primera habilidad normal canónica permitida, sin retocar lista `ability_ids`, sin RNG adicional para otras especies |
| 03 | Conectar la selección **solo en ruta de variante regional** si hay acceso al `RandomlockContentPolicy` cargado sin volver a parsearlo en cada spawn; si hace falta API compartida nueva, ticket y QA en lugar de invasión |
| 04 | `ponyta_galar` → `pastel_veil`: encuentro real, Factory, Party/Storage, SaveV2 y guardia nativa |
| 05 | `rapidash_galar` → `pastel_veil`: mismos positivos/negativos |
| 06 | `voltorb_hisui` → `static`: mismos positivos/negativos |
| 07 | `electrode_hisui` → `static`: mismos positivos/negativos |
| 08 | `exeggutor_alola`: no habilitar `harvest` oculta como default sin productor; decisión explícita `BLOQUEADO`/evidencia o test de una fuente canónica permitida |
| 09 | Regresión de las 51 formas ya certificadas, base sin forma, forma no catalogada, naturaleza efectiva W02 en pruebas locales compatibles; no copiar estado de W02 |
| 10 | CI final CAMP003–006/T02/T03 + report `reports/W04/AUTORUN_V4_FINAL.md`, matriz de 56 y conteo de positivas actuales vs nuevas |

**Autoridad estricta:** `modules/creatures/progression/creature_factory.gd` solo la elección de habilidad de variantes **si se demuestra acceso a política inmutable sin cambios de contratos generales**; nuevo helper W04, nuevos tests/fixtures/workflow W04. `PokemonVariantCatalog.apply`, `DefinitionCatalog` y `WildEncounterSystem` solo lectura salvo que IA6 publique autorización adicional; si es imprescindible, NO mutarlos: prueba roja/ticket y pasar a las filas de QA. `RandomlockContentPolicy`, `config/randomlock_content_v1.json`, `CreatureInstance`, SaveV2 central, `FieldNativeSave`, `EvolutionSystem` (W02 ahora repara naturaleza efectiva), W03 captura y mochilas NO se editan.

`p` / `sigue` ejecuta hasta 10 hitos sin permisos por microbloque. `10/10` significa filas examinadas, no 10 formas nuevas. No usar habilidades inventadas ni marcar la quinta forma L3 sin productor. No editar main/V28/PR118/ramas ajenas. La unión en rama de IA6 sigue pendiente de pruebas conjuntas.

