# IA6 — ORDEN FIJA PARA ESTA VENTANA (W04)

**Esta es tu instrucción de arranque y reanudación.** Al recibir `p`, `sigue` o `continúa`, no preguntes «¿qué trabajo sigue?» ni esperes otra autorización por cada objeto. Sigue la siguiente fila pendiente de la tabla de abajo, reanuda automáticamente las otras filas autorizadas, publica checkpoint si el turno se agota y cierra la tanda tras diez filas examinadas. La IA6 solo revisa el lote cerrado.

**Protocolo técnico vinculante y fuente de verdad:** rama árbitra `codex/calvo-items-20261101-arbitro`, archivo `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md`. Cola central `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W04.md`.

**Permanencia:** IA6 actualizará ESTE MISMO archivo al aprobar una tanda nueva. Al iniciar `p`, comprueba el HEAD y la versión del archivo, no uses la conversación como única memoria. Los permisos de archivos protegidos y reglas de pruebas siguen vigentes. Ninguna orden aquí crea trabajos en segundo plano.

---

# IA6 — ORDEN PERMANENTE AUTORUN V1 — W04
**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`
**Estado desde el que se reanuda:** CAMP006 3 bloques funcionales; 04 por política V27; 05 sexo/día/luna; 06 Milcery/giro/forma bloqueados con resolver L2 PASS #42715401401.
**Activador:** `p`, `sigue` o `continúa` inicia o reanuda los **diez bloques de esta tanda**, sin pedir nuevo permiso por cada fila. Se trabaja hasta donde permita el turno/herramientas; si se interrumpe, checkpoint y siguiente `p` retoma la siguiente fila no cerrada.
**Reglas vinculantes:** leer `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. Se autoriza la reparación autónoma en archivos propios, la migración versionada de pruebas históricas y seguir con filas independientes pese a bloqueos. **Nunca saltar pruebas ni inventar L3.**
**Resumen al usuario:** barra de filas revisadas `[████░░░░░░] 4/10` y **funcionales N/10** diferenciadas; solo al final enviar cierre a IA6.
**Informe final único:** `docs/coordination/items_parallel_v1/reports/W04/AUTORUN_V1_FINAL.md`; estado por fila en `AUTORUN_V1_PROGRESS.csv`. No tocar main, V28, PR118 ni otras ramas.

## Tanda 01 — diez frentes concretos en evolución sin reinventar productores
| Fila | Trabajo | Alcance |
|---|---|---|
| 01 | CAMP006 B07 | `galarica_cuff;galarica_wreath;scroll_of_darkness;scroll_of_waters` variantes regionales |
| 02 | CAMP006 B08 | `gracidea;meteorite;reveal_glass;rotom_catalog;zygarde_cube` cambios de forma |
| 03 | CAMP006 B09 | `blue_orb;red_orb;griseous_core;lustrous_globe;adamant_crystal` forma por equipable |
| 04 | CAMP006 B10 | `dna_splicers;reins_of_unity;n_lunarizer_merge;n_solarizer_merge` fusiones y separación |
| 05 | QA positiva B01 | Revalidar manzanas `sweet/tart/syrupy` desde mochila a SaveV2 |
| 06 | QA fuente B02 | Revalidar autenticidad `chipped/cracked/masterpiece/unremarkable` sin afirmar `form_id` persistente si no existe |
| 07 | QA hold B03 | `dragon_scale;electirizer` held/reequipar/SaveV2 sin fingir trade→level |
| 08 | Resolver B05 | Contract tests sexo/día/luna y ausencia de productores; no fabricar evento |
| 09 | Resolver B06 | Contrato de 7 confites/63 formas, selección real de crema pendiente, sin evolucionar desde giro simulado |
| 10 | Auditoría transversal | Matriz de productor→consumidor→persistencia→rollback de todos los ID B07–B10; comprobar casos positivos disponibles y ticket único para fuentes compartidas |

**Regla de autonomía:** estudiar cada fila en orden; si hay ruta real independiente y código de evolución en ámbito W04, implementar efecto positivo + regresión/SaveV2. Si depende de `CreatureInstance.form_id`, factoría de sexo, mundo día/luna/giro, polí­tica V27, forma de registro/SaveV2 o servicio global, **marcar BLOQUEADA y seguir**. Se puede escribir y probar resolver puro/contrato sin mutar criatura; NO computar como efecto funcional. No crear Pokémon de sexo/formas inexistentes ni elegir formas Milcery arbitrariamente. B04, B05, B06 conservan su clasificación histórica; el informe final muestra 10 filas procesadas, pero `completed=3` solo cambia con pruebas positivas auténticas del bloque correspondiente.

**Ownership:** `modules/creatures/progression/evolution_system.gd` únicamente en funciones ya autorizadas W04 y adaptadores locales; nuevos helpers y tests propios. No tocar `CreatureInstance`, Factory, FieldItemService global, escena/mundo, `modules/save/**` ni main/V28. Si todo B07–B10 depende del mismo estado de forma, no pedir autorizaciones repetidas; documentar un ticket único a IA6, continuar QA independiente 05–10 y cerrar tanda con diagnóstico íntegro, no CI PASS funcional inventado.

