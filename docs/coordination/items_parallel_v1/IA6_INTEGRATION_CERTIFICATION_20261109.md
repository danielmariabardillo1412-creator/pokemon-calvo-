# IA6 — Acta de integración selectiva y CI combinada · 2026-11-09

**Ámbito:** rama aislada `codex/calvo-ia6-integration-20261109` · **commit certificado:** `e983eb5e2bf775b1553f84948d49568af51daba4` · **GitHub Actions:** [#42697961364](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42697961364) **completed/success**.

## Código incorporado selectivamente y sometido a pruebas
- **W02 (entrenamiento):** `modules/creatures/domain/creature_instance.gd`, `modules/inventory/field_item_service.gd`, `modules/inventory/field_mint_effects.gd`; estado opcional de naturaleza efectiva, transacción de menta y compatibilidad con el estado original.
- **W03 (campo):** `modules/overworld/escape_rope_demo_pilot.gd`, `modules/overworld/field_world_item_transaction.gd`, `modules/overworld/field_repel_step_effect.gd`, `scenes/visual/field_item_bag.gd`; Cuerda Huida desde mochila/traslado/consumo/SaveV2, mientras los repelentes se mantienen **solo L2**.
- **W01 (combate):** único reemplazo funcional de `restore()` en `modules/battle/backends/showdown/native_engine.cjs`. Se contrastó igualdad exacta del archivo W01 con el archivo base más ese único reemplazo; no hubo otros cambios al motor. El remedio solo normaliza temporalmente los slots virtuales de snapshots transformados durante deserialización con `@pkmn/sim@0.10.11` y conserva los originales.

No se mezclaron ramas enteras, ni se tocó `main`, V28, PR #118 o las ramas W01–W05.

## Recibos reales de CI #42697961364
| Paso | Recibo exacto |
| --- | --- |
| Regresión de transacciones nativas | `SHOWDOWN_TRANSACTIONS PASS 10` |
| Reproductor nativo W01 Transform/Save | `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3` |
| Prueba cruzada W02/W03 | `IA6_INTEGRATION PASS checks=27 features=mint_effective_nature,escape_rope_bag_savev2` |
| Progresión y equipamiento V18 | `PROGRESSION_ITEMS_V18 PASS checks=8755 cases=4304 GPU=false` |
| Conexiones de objetos/bolsa | `ITEM_CONNECTIONS PASS checks=4993 equip=624 evolutions=72 machines=229` |

**Preparación corregida en CI:** el runner antiguo de conexiones exigía `.godot/item_audit_v1/godot_inventory.json`, `.godot/item_connections_v1/source_machine_rows.json` y `machine_fixtures.json`; ahora se generan con los procedimientos canónicos antes de ejecutarlo. El generador reproduce el mismo mapa funcional (338 máquinas, 229 SV, 631 equipables de metadatos), pero `holdable_source` difiere únicamente como procedencia. Se registra `IA6_CONNECTION_PROVENANCE_DRIFT`, se comprueba identidad de todos los campos funcionales y se restauran **exactamente** los bytes del perfil versionado; ningún catálogo de producción queda reescrito por la CI.

**Correcciones de CI anteriores:** #42680021807 falló V18 por runtime sin instalar; #42680403069 falló conexiones por fixtures ausentes; #42696411261 y #42696840709 localizaron divergencia de exportación; #42697848816 falló sintaxis YAML al insertar pruebas nativas, corregida antes del run actual. Ninguna CI fallida se declara certificación de juego.

## Nivel certificado y reservas

**PASS combinado en rama aislada**, no `main`. W01 dispuso además de una CI completa propia de CAMP005 B06 (`#42679854792`) y B07 (`#42692174058`); en esta rama mixta se reejecutaron reproductor nativo + transacciones + V18 + conexiones, **NO todos los escenarios Godot de CAMP005 W01**. No atribuirle por ese motivo regresión total de W01 sobre el árbol mixto.

W02: las nuevas `lonely_mint/mild_mint/naive_mint` del piloto abierto **no forman parte todavía de esta certificación**. W03: los repelentes `repel/super_repel/max_repel` son L2; sin mochila + director + SaveV2 L3 de la rama conjunta. W04: sexo/día/luna y política V27 siguen bajo contrato; no se inventaron datos. W05: libro visual/selección aún fuera del árbol certificado; UI GPU/manual no comprobada. `exp_share` continúa L1 según [contrato técnico de participación](IA6_EXP_SHARE_PARTICIPATION_CONTRACT_20261109.md).

**Aún no autorizar merge a main ni V28.** Siguiente carril IA6: revisar nuevas entregas W02/W05 y resolver interfaces compartidas de W03/W04; añadir regresiones de las campañas en el árbol combinado antes de aceptación global.
