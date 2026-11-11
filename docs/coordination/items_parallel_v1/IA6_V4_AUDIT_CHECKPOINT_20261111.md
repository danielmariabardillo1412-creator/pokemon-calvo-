# IA6 — Auditoría de continuidad V4 / 2026-11-11

## Referencias inmutables y alcance
- Rama oficial: `codex/calvo-ia6-integration-20261109`.
- HEAD oficial verificado mediante comparación GitHub: `47a9e654c5207d7b29a656d9909a9e5479b3facd` (idéntico al HEAD consultado).
- W05: PR #120 fusionado en IA6; merge `dca006bb52e79bdefa1175e1593c66997fab9c2e`.
- CI previa W05: 20/20 SUCCESS, SHA `c0b601a087d2f1c39ef799fb9493ab90573819cc`, incluida Item Closure V3 #43071395377 Windows/Linux.
- POSTMERGE NO CERTIFICADO: el conector GitHub para listar workflows por SHA solo devuelve runs PR y no muestra las ejecuciones `push` del HEAD oficial. Un listado vacío no demuestra ausencia de CI ni SUCCESS.
- IA6 recibió después cinco commits sobre merge W05: cambios en `field_demo.gd`, `field_item_bag.gd`, `field_native_bridge.gd`, prueba `parallel_items_w03_repel_l3.gd` y workflow `.github/workflows/ia6-official-w03-w05-rope-20261111.yml`. No sobrescribir ni resetear estos cambios concurrentes.

## Auditoría staging (comparadas contra HEAD oficial)
- W01 `codex/calvo-ia6-staging-20261111-w01-held`: 32 commits ahead / 28 behind; sin hunks de producción propios en la comparación. L3 de 10 rutas y CI parcial PASS en informes; falta equivalencia T01–T04/V2/CAMP003–005, especialmente los escenarios RNG y gemas. NO READY_FOR_IA6_MERGE. Estado detallado `CONTINUOUS_V4/STATE_W01.md`.
- W02 `codex/calvo-ia6-staging-20261111-w02-growth`: 2 ahead / 28 behind; solo documentación, no cambios de producción. CONTINUOUS V4 sin activar. EXP Share V3 es prerequisito. NO MERGE.
- W03 `codex/calvo-ia6-staging-20261111-w03-capture`: 37 ahead / 28 behind. **Bloqueo legacy de seis aserciones resuelto**: CI #43068968046 SUCCESS, SHA `5a82da2a9dd1a868c3f8af9d73551fe16571adea`, test histórico W03_REPEAT_V2_GODOT 37 PASS. La staging aporta Repeat/Moon y serialización de historial, con cambios cruzados en `PlayerCollection`, `SaveGameData`, `FieldNativeSave`, `WildAdventureSession` y otros; **no hacer merge de rama completa**. Parte de repelentes ya está incorporada concurrentemente en IA6, pero su CI cruzada no está verificada. NO READY_FOR_FULL_MERGE.
- W04 `codex/calvo-ia6-staging-20261111-w04-evolution`: 31 ahead / 28 behind. CI #42965322073 SUCCESS sobre SHA `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`. 7 evoluciones regionales L3, 14 Party/Storage, checks 396 y rollback 2. Candidata selectiva, **no integrar** antes de CAMP003–006 en árbol actual, interfaz real FieldItemBag, SaveV2 + W02 + W03/W05.
- W05 staging original: 39 ahead / 28 behind, pero su paquete selectivo ya se integró mediante PR #120; **no repetir ni fusionar staging original**.

## Puerta W03/W05 publicada y pendiente de evidencia
Workflow actual `.github/workflows/ia6-official-w03-w05-rope-20261111.yml` (push rama IA6) ejecuta:
1. Restauración de recursos y import Godot.
2. 229 nombres españoles, no doble consumo, exclusión Dinamax y preservación Rope.
3. Mochila real W05, menta/rope IA6, SaveV2.
4. Prueba nativa `parallel_items_w03_repel_l3.gd` con Repel/Súper/Máximo, encuentros y guardado.
Su publicación no equivale a CI SUCCESS. Conservar un run ID, SHA probado y conclusión exacta antes de cerrar POSTMERGE.

## Siguiente paso autorizado IA6
1. Recuperar evidencia verificable de la ejecución `push` del workflow oficial, asociada al HEAD vigente, o informar imposibilidad sin falsificar resultados. No alterar aserciones.
2. Revisar únicamente hunks faltantes de W03 Repeat/Moon/ledger contra el HEAD actual, evitando reintroducir cambios antiguos de repelentes, mochila W05 o SaveV2.
3. Para W04 crear staging nuevo desde HEAD IA6 actual con trasplante selectivo y CI cruzada, no merge total de rama divergente.
4. Mantener W01 en QA pendiente y W02 bloqueada por EXP Share V3 hasta evidencia actual.
5. Proteger `main`, V28, PR #118 y ramas W01–W05. No etiquetar POSTMERGE_CERTIFIED sin run real completed/success.
