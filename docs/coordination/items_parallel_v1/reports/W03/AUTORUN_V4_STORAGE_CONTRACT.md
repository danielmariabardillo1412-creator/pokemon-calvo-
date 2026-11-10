# IA3/W03 — TANDA 04: contrato de STORAGE sin límite global

Fecha: 2026-11-10. Propietaria: W03. Hito 02 de QUEUE_W03_TANDA_04.md.

## Hallazgo comprobable en fuente

- `modules/creatures/storage/storage_ruleset.gd`: `BOX_CAPACITY = 30` y comentario explícito «NO fixed MAX_BOXES cap in V1».
- `modules/creatures/storage/creature_storage.gd`: `ensure_capacity_for()` crea cajas mediante `ensure_box()` hasta tener hueco; `add_creature()` llama a ese método si no hay hueco.
- `modules/gameplay/showdown_adventure_session.gd::_finish`: el éxito de captura enruta vía `CaptureOwnershipRouter`; no existe una condición legítima «todas las cajas están llenas» que fuerce un rechazo de capacidad global.

## Conflicto exacto con la aceptación de IA6

La fila 02 pide «Party llena + STORAGE llena: primer intento real y respuesta de routing, sin perder/duplicar criatura ni bola». **Storage completamente llena no es un estado representable** bajo la política `calvo_storage_v1`; al llenar una caja, el siguiente depósito crea otra. Inyectar corrupción del PC o impedir creación de cajas para conseguir un rechazo no probaría el comportamiento de producción y violaría la protección de los módulos compartidos.

**Estado fila 02: BLOQUEADO_POR_CONTRATO**, no funcional nuevo. No modificar StorageRuleset, CreatureStorage, SaveV2, CreatureInstance ni Router desde W03.

**Alternativa legítima verificable:** llenar los 30 slots de una caja y los 6 de Party, capturar en combate nativo y exigir creación de la siguiente caja, exactamente una propiedad de la criatura, gasto de una sola Ball y persistencia SaveV2.

**Decisión pendiente de IA6:** aceptar la redefinición como prueba de autoexpansión del PC o diseñar explícitamente un límite de cajas en una campaña distinta. Ninguna de estas dos opciones se atribuye unilateralmente a W03.