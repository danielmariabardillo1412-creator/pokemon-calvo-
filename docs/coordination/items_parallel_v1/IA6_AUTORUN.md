# IA6 · W02 — MODO CAMPAÑA CONTINUA V2 ACTIVADO

**ORDEN PERMANENTE: YA NO SE PARA POR 10/10.** Esta orden sustituye la obligación `STOP al cerrar TANDA X` de la versión anterior, sin derogar permisos técnicos ni pruebas. Identifícate como W02, utiliza SOLO la rama `codex/calvo-items-20261109-w02-mints-integration`. El plan de trabajo completo se copia abajo y tiene varios bloques; **cuando uno termina con CI, pasa directamente al siguiente bloque del MISMO plan SIN PEDIR IA6**.

Con cada `p` o `sigue`: (1) consulta tu HEAD y esta nota; (2) lee o crea `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W02.md` de TU RAMA; (3) continúa la primera tarea pendiente de toda la CAMPAÑA, no solo de la última tanda; (4) trabaja secuencialmente mientras el turno lo permita, registrando checkpoints cada 10. Si el contexto se agota, publica estado y una próxima `p` reanuda desde GitHub. **No te quedes diciendo «esperando tanda siguiente» si quedan fases preautorizadas en este plan.**

**Protocolo IA6 V2 (prioritario):** rama árbitra `codex/calvo-items-20261101-arbitro`, `docs/coordination/items_parallel_v1/CONTINUOUS_V2/README.md`. **Plan central y único:** `docs/coordination/items_parallel_v1/CONTINUOUS_V2/PLAN_W02.md` en árbitra (copia íntegra abajo). Si en el futuro IA6 actualiza este mismo archivo con una misión más reciente, leer siempre HEAD y respetar la última versión.

**Control de seguridad:** no autoautorizar módulos protegidos, no fusionar ramas, no editar main/V28/PR118, no mover trabajo de otra W. No atribuir a IA6 integración no realizada. Si toda la misión termina o el resto exige exclusivamente una seam compartida, publicar `READY_FOR_IA6` y detenerse; no crear bucles de QA vacíos. Si hay más tareas independientes, continuar sin esperar. **Una `p` no mantiene ejecución asíncrona ni abre otra conversación automáticamente.**

**Contabilidad en cada respuesta:** `CAMPAÑA fase | bloque n/total | objetos nuevos | ya certificados | L3 verdaderos | bloqueados | CI SHA | integración IA6 pendiente`. Un 10/10 de bloque no es 100% de campaña.

---

# W02 — CAMPAÑA CONTINUA V2 · BAYAS, MEDICINAS Y ENTRENAMIENTO
**Rama:** `codex/calvo-items-20261109-w02-mints-integration`.
**Baselines:** TANDA04 cerrada con CI #42922087890 SUCCESS; se eliminó recálculo duplicado de `Growth.plan`; no repetir las 21 mentas, el proceso de naturaleza efectiva ni QA ya certificados.

## Cola completa — 42 bayas canónicas presentes en holdable_ids
Los IDs de abajo están en el catálogo de equipables al emitir V2. Son **candidatos**, no 42 efectos inexistentes. Muchos pueden tener pruebas anteriores W02/CAMP004 o handlers de batalla. Verificar fuente, versión, política y recorrido real antes de reclamar implementación.

| Bloque automático | IDs | Cantidad |
|---|---|---|
| 01 | `cheri_berry`, `chesto_berry`, `pecha_berry`, `rawst_berry`, `aspear_berry`, `persim_berry`, `oran_berry`, `aguav_berry`, `iapapa_berry`, `mago_berry` | 10 |
| 02 | `wiki_berry`, `enigma_berry`, `liechi_berry`, `ganlon_berry`, `salac_berry`, `petaya_berry`, `apicot_berry`, `lansat_berry`, `starf_berry`, `kee_berry` | 10 |
| 03 | `maranga_berry`, `micle_berry`, `custap_berry`, `jaboca_berry`, `occa_berry`, `passho_berry`, `wacan_berry`, `rindo_berry`, `yache_berry`, `chople_berry` | 10 |
| 04 | `kebia_berry`, `shuca_berry`, `coba_berry`, `payapa_berry`, `tanga_berry`, `charti_berry`, `kasib_berry`, `haban_berry`, `colbur_berry`, `babiri_berry` | 10 |
| 05 | `chilan_berry`, `roseli_berry` | 2 |

**Orden de trabajo continuo:** recorrer todos los bloques, hasta agotar lista. Para cada baya: si ya está funcional con prueba real, `YA_CERTIFICADA` con CI SHA y no duplicar. Si no existe ruta real, implementar únicamente handler berry específico en la superficie W02 ya autorizada, con condición exacta (PS/status/PP/EV/consumo según perfil canónico y sin inventar efecto). Demostrar Party/Storage, stock, SaveV2, owner/rollback, y combate si es efecto activado al final del turno o al recibir daño.

**Límites importantes:** `sitrus_berry` ya figura en TANDA04 de W01 y se certificó en CAMP004 W02; excluida de esta nueva cola para prevenir doble escritura. No editar equipables no berry W01, bolas W03, formas W04 ni panel W05. Los efectos sostenidos en motor Showdown o modificación de sistema compartido fuera de seam W02 requieren ticket y pasan a `BLOCKED_SHARED`, sin editar motor nativo. W02 puede usar tests/harness/fixtures/workflow nuevos propios, datos canónicos SOLO LECTURA, cambios de handlers **berry o medicina W02 previamente propios** si autorización y prueba roja lo justifican. No modificar `CreatureInstance`, `StatCalculator`, motor global, `SaveV2` central, `FieldItemBag`, `FieldNativeSave`, `EvolutionSystem`, configuración de contenido ni ramas ajenas.

**Cierre real:** un único informe de campaña al terminar lista, con filas `already/functional_new/blocked/no_aplica`, SHA de CI y pendientes de IA6. Si todas las restantes tienen bloqueador común, ticket único y `READY_FOR_IA6` sin inventar pruebas. No STOP por alcanzar cada 10.


