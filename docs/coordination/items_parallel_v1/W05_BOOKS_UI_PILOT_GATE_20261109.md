# IA6 — RELEVO W05: PILOTO LIBROS-UI-L3 01 · 2026-11-09

**Nueva rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`, nacida del cierre documental `720c786a`. CAMP006 sigue FINALIZADA, 49 MT verificadas por #42417890877; no iniciar CAMP007.

**Trabajo autorizado 01:** sobre `tm202` y `tm31` (y caso incompatible), comprobar presentación textual española desde `FieldMachineBookProfile.presentacion`, selección de libro en la bolsa actual y `FieldItemService.teach`, learnset, PP, consumo 1, negativa sin gasto y SaveV2. Nuevo componente visual de presentación local si es indispensable, con tests de escena y CI. No cambiar `FieldItemBag` porque IA3 y el carril IA6 ya lo integran; si la unión necesita modificarlo, entrega interfaz exacta, contrato y test rojo, y solicita permiso. No duplicar lógica de enseñanza ni inventar arte/GPU.

**CI:** bootstrap de la nueva rama y regresión CAMPAÑA_006, sin rebajar cobertura. Consulta orden central `IA6_REACTIVATION_W02_W05_W03_W04_20261109.md` en árbitra. En la siguiente `p`, ejecutar exclusivamente este piloto y documentar L2/L3, SHA/CI y dependencias.
