# IA6 — ORDEN FIJA PARA ESTA VENTANA (W01)

**Esta es tu instrucción de arranque y reanudación.** Al recibir `p`, `sigue` o `continúa`, no preguntes «¿qué trabajo sigue?» ni esperes otra autorización por cada objeto. Sigue la siguiente fila pendiente de la tabla de abajo, reanuda automáticamente las otras filas autorizadas, publica checkpoint si el turno se agota y cierra la tanda tras diez filas examinadas. La IA6 solo revisa el lote cerrado.

**Protocolo técnico vinculante y fuente de verdad:** rama árbitra `codex/calvo-items-20261101-arbitro`, archivo `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md`. Cola central `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W01.md`.

**Permanencia:** IA6 actualizará ESTE MISMO archivo al aprobar una tanda nueva. Al iniciar `p`, comprueba el HEAD y la versión del archivo, no uses la conversación como única memoria. Los permisos de archivos protegidos y reglas de pruebas siguen vigentes. Ninguna orden aquí crea trabajos en segundo plano.

---

# IA6 — ORDEN PERMANENTE AUTORUN V1 — W01
**Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`
**Estado desde el que se reanuda:** CAMP005 cerrada 10/10; CI funcional #42717306543 SUCCESS; nueva rama creada por IA6 desde HEAD documental f7f28b1ea0bc.
**Activador:** `p`, `sigue` o `continúa` inicia o reanuda los **diez bloques de esta tanda**, sin pedir nuevo permiso por cada fila. Se trabaja hasta donde permita el turno/herramientas; si se interrumpe, checkpoint y siguiente `p` retoma la siguiente fila no cerrada.
**Reglas vinculantes:** leer `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. Se autoriza la reparación autónoma en archivos propios, la migración versionada de pruebas históricas y seguir con filas independientes pese a bloqueos. **Nunca saltar pruebas ni inventar L3.**
**Resumen al usuario:** barra de filas revisadas `[████░░░░░░] 4/10` y **funcionales N/10** diferenciadas; solo al final enviar cierre a IA6.
**Informe final único:** `docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V1_FINAL.md`; estado por fila en `AUTORUN_V1_PROGRESS.csv`. No tocar main, V28, PR118 ni otras ramas.

## Tanda 01 — diez gemas de combate, una por fila
La lista proviene de los IDs habituales del catálogo local; **confirmar cada ID activo con `DefinitionCatalog`, política y perfiles reales** antes de tocar producción. Excluir si el ID no está seleccionado o si ya está validado en campaña anterior; registrar `NO_APLICA` sin inventar sustituto fuera del catálogo.
| Fila | ID | Prueba de efecto requerida |
|---|---|---|
| 01 | `electric_gem` | Tipo Eléctrico |
| 02 | `grass_gem` | Planta |
| 03 | `ice_gem` | Hielo |
| 04 | `fighting_gem` | Lucha |
| 05 | `poison_gem` | Veneno |
| 06 | `ground_gem` | Tierra |
| 07 | `flying_gem` | Volador |
| 08 | `psychic_gem` | Psíquico |
| 09 | `bug_gem` | Bicho |
| 10 | `rock_gem` | Roca |

**Preflight:** conservar íntegra CAMPAÑA_005 con sus 30 equipables y regresión 004. Crear workflow propio de nueva rama desde el último workflow W01 certificado y cambiar triggers/paths. Un archivo `CAMP005` cerrado no debe reescribirse como si la gema perteneciera a esa campaña. Usar fixtures/runners nuevos `w01_autorun_v1`, con CI propia y motor nativo, sin mover `main` ni V28.

**Efecto positivo obligatorio por gema:** portador real + movimiento de tipo exacto, contra otro tipo, sin gema, una sola activación/cambio de PP, consumo y estado de equipamiento, reentrada a combate, snapshot/restauración de turno, SaveV2, sin consumir ante fallo/negativo. Determinar multiplicador por fuente canónica y motor existente, **no inventar porcentaje**. La mecánica de gemas fue certificada con `normal_gem/fire_gem/water_gem` en CAMP005 B10; reutilizar patrón y conservar casos de Transformación/Quick Powder.

**Edición autorizada:** pruebas y nueva rama W01, adapter local de held, solo funciones específicas de consumibles de tipo en su propio motor/backend; cualquier generalización que cambie otras reglas o cualquier serializador compartido se deja en ticket y se continúa. Rehacer CI completa al cerrar tanda. Si alguna gema no puede obtener positivo por falta de perfil o contrato, marcar bloqueada con prueba y avanzar. **No esperar IA6 hasta completar diez filas.**

