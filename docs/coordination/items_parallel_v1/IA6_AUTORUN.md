# IA6 — ORDEN ACTIVA TANDA 02 PARA W04

**ESTA NOTA SUSTITUYE LA TANDA 01, YA CERRADA.** La orden ha sido publicada por IA6 en 2026-11-10. **Al recibir `p`, `sigue` o `continúa`, empieza inmediatamente la PRIMERA FILA SIN CERRAR de la TANDA 02.** No reabrir TANDA 01 ni pedir permiso por cada hito. Reanudar por el CSV/checkpoint de esta tanda si se interrumpe el turno; no se trabaja en background entre turnos.

**Política maestra:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W04_TANDA_02.md` (rama árbitra). Las autorizaciones especiales y límites de edición de esta nota SON órdenes oficiales IA6. Las ramas son exclusivas. Todo PASS funcional requiere CI en SHA concreto. Al terminar las diez filas, entregar `TANDA 02 FINALIZADA` y STOP a espera de la siguiente nota.

---

# IA6 → W04/IA4 · AUTORUN TANDA 02: IDENTIDAD DE FORMA PERSISTENTE, PILOTO REAL
**Rama:** `codex/calvo-items-20261104-w04-camp006` · **Fecha:** 2026-11-10.

**Auditoría de TANDA01:** 10/10 filas revisadas, dos QA L3 de funciones **previas**, **0 transformaciones/formas/fusiones nuevas**. CI [#42729967922](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729967922) SUCCESS sobre `3385011da12ed6f3d0d68a82c33348c7c23e17fc`; HEAD final documental `19246f6158874edf71d37d7fafed3af12833e102`. 18 IDs/23 rutas bloqueados por falta de identidad de forma; ver `reports/W04/AUTORUN_V1_SHARED_PRODUCER_TICKET.md`. **No repetir las mismas auditorías.**

**Protocolo vinculante:** `AUTONOMY_V1/README.md`. Una sola `p` autoriza iniciar y avanzar las diez filas de esta tanda dentro de los turnos que sean necesarios, con checkpoints; no pedir permiso nuevo por cada fila. CI y reporte de cierre por diez filas. No trabajo en segundo plano garantizado. Únicamente rama propia. Prohibido editar `main`, V28, PR118, otras ramas. Un bloqueo se documenta y se pasa a la siguiente prueba independiente; no acreditar L3 falso.

## Decisión IA6 — crear primero un productor transversal
Antes de implementar seis familias de formas y fusiones, desarrollar **UN piloto de identidad de forma canónica persistente** de `CreatureInstance`, sin inventar un `form_id` por especie base ni introducir forma ficticia. Elegir caso real y comprobable (p.ej. Galar Slowpoke o autenticidad Sinistea si la fuente de Factory/encuentro realmente está disponible). Es preferible una ruta positiva real con SaveV2 y retrocompatibilidad a 18 pruebas negativas nuevas. La identidad de forma es distinta de `species_id`, shiny, género, naturaleza, transformación temporal o `held_item_id`.

## Diez hitos autorizados
| Fila | Entrega concreta |
|---|---|
| 01 | Catálogo canónico: localizar IDs de forma, base species y fuente verdadera de creación/captura; escoger **un único piloto** donde el productor exista |
| 02 | Contrato opcional `CreatureInstance.form_id` de valor exacto de catálogo: vacío para legado cuando no haya forma distinguida; no convertir automáticamente por la especie |
| 03 | Serialización y deserialización opcional en `CreatureInstance.to_dict/from_dict`, sin alterar API ni `instance_id` |
| 04 | Validación estricta de formas declaradas (tipo, correspondencia base species, origen en catálogo, Randomlock policy) antes de publicar saves, rechazar corrupción |
| 05 | Pruebas SaveV2 legacy y campo nativo que demuestren que forma válida permanece y una inválida NO se acepta; sin nueva `schema_version` |
| 06 | Conexión mínima con productor real de Factory/encuentro **si está presente**: obtener forma de un dato fuente del juego, no de test o elección arbitraria |
| 07 | Propagación de forma al capturar/almacenar/mover sin duplicar objeto, alterar naturaleza, IV/EV/PP o estado de combate |
| 08 | Aplicar un cambio de forma real solo si existe una regla canónica autentificada y transacción permitida (prioridad: una de B02 o B07); caso positivo y negativo |
| 09 | Round-trip Party/Storage + SaveV2 nativo del caso piloto, rollback y migración legacy; preservar caso base sin forma y W04 CAMP005/006 |
| 10 | CI de cierre con pruebas Python/Godot de toda la familia propia + regresiones CAMP003/004/005/006. Informe `reports/W04/AUTORUN_V2_FINAL.md`: L3 real vs estructura, SHA y pendientes productores |

## Delegación IA6 **limitada** de módulos compartidos, SOLO en rama W04
Autorizados exclusivamente:
- `modules/creatures/domain/creature_instance.gd`: añadir `form_id` opcional y serializar/deserializar; conservar campos/habilidades/naturalezas originales y no tocar `recalculate_stats` ni `battle_transform_original`.
- `modules/creatures/progression/creature_factory.gd`: aceptar/propagar un `form_id` **solo si hay fuente canónica auténtica** y con guardas; evitar romper firmas anteriores.
- `modules/save/field_native_save.gd::_valid_creature`: validación aditiva de `form_id` si hay fuente verificable, SIN borrar el cálculo original de stats y SIN tocar su comportamiento de naturaleza efectiva que IA6 corrigió en su rama. Si la función no permite validar sin invasión, ticket y prueba, sin reescritura.
- `modules/creatures/progression/evolution_system.gd`: solamente métodos y adaptadores de forma ya autorizados a W04; no tratar `spin`/fusión como evolución sin fuente real.
- `modules/save/save_game_data.gd::validate`: **exclusivamente** validación estructural aditiva del campo `form_id` opcional por criatura (si existe), sin tocar ningún otro campo, layout o snapshot, conservando `schema_version=2`. IA3 edita otra parte del mismo archivo: IA6 integrará ambas diferencias por función, nunca merge completo.
- Helpers de formas nuevos locales, fixture y tests W04, workflows propios. No alterar `SaveGameData.build/to_dict/from_dict` ni persistencia de la colección ajena.

**No tocar:** `SaveGameSerializer`, `SaveGameRepository`, `SaveGameMigration`, mapa/reloj/giro, `FieldItemService`, `FieldItemBag`, sistema de captura, Showdown/estadísticas, o código de otras trabajadoras; **no cambiar `schema_version=2`**. Si para piloto L3 de Factory y captura hace falta un seam no listado, documentar API mínima y hacer pruebas positivas hasta el nivel que de verdad permitan los módulos autorizados, sin falsificar L3. Pueden quedar hitos bloqueados, pero no pedir autorización después de cada fila.

**Integración IA6 posterior:** IA6 tiene cambios de W02 en `CreatureInstance` (naturaleza efectiva) y de W03 en guardado nativo; **no integrar copiando la clase completa desde W04**. IA6 revisará y trasplantará solo el campo de forma y validaciones con CI conjunta.

**Resultado que se busca:** al menos 1 criatura real con identidad de forma fuente, persistida/recuperada y validada; NO afirmar que los 18 objetos B07–B10 ni Milcery/fusiones estén conectados hasta implementar sus propios disparadores. Al cerrar las diez filas, STOP y aviso IA6.

