# IA6 — CAMPAÑA_004 exclusiva W05 / GATE ACTIVO
**Fecha:** 2026-11-03. **Autorización:** petición explícita del usuario de dar más trabajo a W05 sin esperar a las demás. **Única trabajadora incluida:** IA5/W05. 10 microbloques, 6 MT Scarlet/Violet por bloque, **60 IDs nuevos**. No es una extensión de CAMPAÑA_003 (cerrada 10/10).

## Base de evidencia y selección
- CAMPAÑA_003 W05 tiene 10/10, 60 MT y CI final [#41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563) `completed/success`, SHA validado `984a80a128f5c6847664325ae487956adb838f49`. El HEAD posterior de su rama es documental; **no reemplaza** la evidencia de CI.
- Selección aprobada en [CAMPAIGN_004_W05_QUEUE_APPROVED.csv](CAMPAIGN_004_W05_QUEUE_APPROVED.csv): IDs `tm82` a `tm141` inclusive, 60 diferentes, presentes en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (familia MACHINE) y con mapping `scarlet-violet` en `modules/inventory/item_connections_v1.json` de la rama W05 CAMP003. Reservas sin solapamiento con los 60 IDs de CAMP003, los de muestra CAMP002, ni `tm01`, `tm02`, `tm77` de CAMP001. Hay otras 88 candidatas activas fuera de esta reserva, no autorizadas todavía.
- **Importante:** metadatos presentes y mapeo activo no prueban learnset compatible ni enseñanza funcional. La trabajadora debe validar especies reales, PP, compatibilidad, rechazo, consumo, propietario y SaveV2 por cada ID; si falla, reparar con V5 donde sea suyo o documentar dependencia real sin falsificar PASS. No habilitar las 19 máquinas históricas inactivas.

## Rama, propiedad y autonomía
- Rama nueva de W05: `codex/calvo-items-20261103-w05-camp004`, a crear desde HEAD comprobado de `codex/calvo-items-20261103-w05-camp003` para preservar en el árbol los 60 tests anteriores. Reconfirmar SHA de origen en manifiesto al crear. La rama de CAMP003 queda intacta.
- Identidad W05 explícita. Nunca inferir identidad a partir de memoria compartida. Trabajar exclusivamente en la rama nueva. Solo editar pruebas y fixtures CAMP004 propios y, para defectos reproducidos en sus IDs, cambios mínimos de `field_machine_book_profile.gd` / función `teach` según [AUTONOMOUS_REPAIR_V5.md](AUTONOMOUS_REPAIR_V5.md); CI sobre el SHA del parche; no tocar otras funciones/ramas o APIs compartidas sin revisión IA6.
- Cada `p` ejecuta exactamente el siguiente bloque de cola; no saltar, repetir, pasar del 10 ni autogenerar campañas. La primera orden de activación ejecuta bloque 01. Al 10/10, STOP y solicitar otra asignación IA6.

## Criterio de pruebas y CI
- Nuevo runner Godot y Python bajo nombres `*_campaign_004`; manifiesto y GitHub Actions exclusivos W05 con validación del conteo y recibos `CAMP004_W05_PY PASS blocks=N checks=M` y `CAMP004_W05_GODOT PASS blocks=N checks=M`. Nada de PASS si la CI está pendiente o si falta contexto real.
- Reutilizar arquitectura y suites CAMP003, conservar regresión CAMP003 de 60 MT y CAMP002. Proteger tests negativos, preservar política de 19 legacy, no inventar especies y no modificar catálogo.
- CI en verde en la rama W05 no implica integración global; IA6 auditará diff, colisiones, recibos y riesgos. Sin merge a `main`, V28, árbitra ni PR #118 por parte de W05. No certificar UI/GPU visual por headless.

**NOTA DE PREVALENCIA:** ESTA puerta autoriza CAMPAÑA_004 únicamente W05 y reemplaza el STOP de nuevas campañas escrito en sus documentos históricos CAMP003; dicho cierre 10/10 sigue siendo válido para CAMP003.
