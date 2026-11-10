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
