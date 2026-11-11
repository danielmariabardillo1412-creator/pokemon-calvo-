# IA4/W04 — CONTINUOUS_V2 — READY_FOR_IA6

Fecha: 2026-11-11. Rama exclusiva: `codex/calvo-items-20261104-w04-camp006`.

## Resultado certificado
**B01–B03 completados dentro del alcance autorizado.** CI [#42945615987](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42945615987) **COMPLETED / SUCCESS** sobre SHA funcional `c7ab98d1b0a2cac0ebbcfe74f1e27fee36d00f17` (HEAD posterior documental no se presume recertificado).

- B01: 57 fuentes regionales y 28 `EvolutionRecord`, manifiesto `reports/W04/CONTINUOUS_V2_REGIONAL_EVOLUTION_MATRIX.csv`. Clasificación estática: 11 runtime compatibles, 7 `use_item` condicionadas a item catalog, 10 DATA_ONLY/unsupported.
- B02: siete contratos regionales `use_item` con forma de origen/destino canónica, registro existente, catálogo y negativos: `W04_V2_B02 PASS checks=59 routes=7 L2=7 blocked=0 L3=0`. **5 contratos L2 adicionales** a los dos Galarica ya certificados T05. **0 objetos nuevos**, 0 evoluciones L3.
- B03: Factory de orígenes y destinos reales, identidad propia (no heredar forma incompatible), Party/Storage, native guard, SaveV2, corruptos/legacy: `W04_V2_B03 PASS checks=179 L3=0`. Estos son ejemplares creados mediante Factory; no confundir con un resultado de evolución nativa.
- Histórico: V5 Galarica PASS, V4 habilidades normales PASS, V3 formas `55/56` PASS (Exeggutor Alola bloqueado por habilidad oculta), V2 piloto PASS. CAMP003-006 Python y Godot PASS; `W04_AUTORUN_V1_PY PASS ... checks=202`.
- Corrigió incompatibilidad de cola histórica V1 con la orden IA6 CONTINUOUS_V2, conservando hash/fixtures/ID negativos y todas las aserciones antiguas. No se relajó un negativo funcional ni se usó skip.

## Rutas L2 certificadas (no L3)
1. `darumaka_galar` + `ice_stone` → `darmanitan_galar_standard`
2. `growlithe_hisui` + `fire_stone` → `arcanine_hisui`
3. `sandshrew_alola` + `ice_stone` → `sandslash_alola`
4. `slowpoke_galar` + `galarica_cuff` → `slowbro_galar` (L2 previamente certificado)
5. `slowpoke_galar` + `galarica_wreath` → `slowking_galar` (L2 previamente certificado)
6. `voltorb_hisui` + `leaf_stone` → `electrode_hisui`
7. `vulpix_alola` + `ice_stone` → `ninetales_alola`

## Ticket IA6 — integración nativa pendiente
`EvolutionSystem.apply_evolution` no garantiza `form_id` canónica de la especie de destino y no recibe `item_id` en la firma actual. La ruta de mochila no demuestra origen+forma+objeto, consumo transaccional, sustitución del dueño con `instance_id` estable ni rollback completo ante error. Además, la preservación de naturaleza efectiva W02 necesita revisión cruzada en la rama integradora. IA6 debe diseñar/adaptar seam compartida para:
1. Validar registro y contrato canónico antes de gastar ítem.
2. Resolver la forma **del destino** desde metadatos verificables, nunca copiar `form_id` de origen.
3. Reemplazar en Party/Storage la instancia única; preservar naturaleza original/efectiva, estado y SaveV2.
4. Gastar una unidad exactamente una vez, rollback del estado vivo ante fracaso, roundtrip nativo y pruebas negativas por origen/item/form/target.
5. No permitir Harvest oculta por defecto a Exeggutor Alola ni relajar DATA_ONLY.
La rama W04 **no** modificó archivos protegidos: el intento anterior en EvolutionSystem se revirtió al blob `2f684ae11f36c6c2183a7100b9015c3f6c906f49`.

## Estado final
`READY_FOR_IA6` — campaña V2 agotada en cuanto a trabajo independiente autorizado. Mantener parada de W04 hasta nueva asignación o permiso de integración; **no inventar tareas adicionales ni autoautorizar módulo compartido**. Sin merge a main, V28, PR118 o ramas ajenas.
