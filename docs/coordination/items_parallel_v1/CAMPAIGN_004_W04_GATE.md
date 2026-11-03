# IA6 — CAMPAÑA_004 EXCLUSIVA W04 | ACTIVADA
**Fecha:** 2026-11-03. **Solicitud:** usuario confirma que IA4 acabó y desea que continúe sin esperar a W01 ni a otras trabajadoras. **Identidad:** IA4/W04. **Rama nueva:** `codex/calvo-items-20261103-w04-camp004`.

## Cierre anterior y sus límites
W04 CAMPAÑA_003 **10/10**, CI final [#41574086468](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574086468) `completed/success`, SHA `42e98b468d934765c04cd3f45fa4a3b3cd7767a5`, recibos `CAMP003_W04_MANIFEST_PASS reserved=10 completed=10 ids=30`, Python 120, Godot 270; regresión CAMP001 Godot 559. **No afirmar 30 evoluciones funcionales:** 14 rutas positivas observadas, 10 sin regla normalizada y 6 DATA_ONLY; varias formas positivas tienen condiciones insuficientes. Las 16 dependencias de CAMP003 quedan pendientes de resolución independiente y no pasan a PASS automáticamente.

## Nueva cola exacta y criterio
[CAMPAÑA_004 W04 — 36 IDs](CAMPAIGN_004_W04_QUEUE_APPROVED.csv), diez microbloques **reservados y no repetidos** frente a CAMP001 W04, las 30 evoluciones CAMP003, las colas globales CAMP003 y CAMP004 de W02/W03/W05:
- Bloques **01–03 (9 IDs):** 8 objetos `EVOLUTION` restantes (siete confites + `whipped_dream`) y `leaders_crest`, registrado en selección como `FOOD_OR_PICNIC_ACTIVITY` pese a su posible relación con evolución. **No cambiar categoría ni inventar modalidad**; auditar las condiciones canónicas reales.
- Bloques **04–08 (15):** `STORY_KEY_OR_FORM_REVIEW`, candidatos de formas/objetos de historia. Revisar si la selección aprobada tiene efecto funcional o solo entrada de catálogo; no habilitar transformaciones, combates o ítems claves sin contratos.
- Bloque **09 (5):** `LEGACY_OR_CATEGORY_REVIEW` (fusiones y Roto-poderes), **auditoría documental/código y negativos reales**. No editar captura de W03 ni entrenamiento de W02, ni implementar fusiones.
- Bloque **10 (7):** `TREASURE_OR_COLLECTIBLE`, revisión de utilidad real. `bottle_cap` y `gold_bottle_cap` pueden tocar entrenamiento W02: **no modificar** esas mecánicas desde W04. No inventar economía o aprendizaje de movimientos.
Son 36 **objetos seleccionados para investigación y pruebas**, no promesa de 36 implementaciones. Las dependencias de CAMP003 siguen en backlog IA6; esta nueva cola evita forzar arquitectura indefinida.

## Protocolo operacional
1. Nueva rama W04 CAMP004 creada desde el HEAD exacto de su W04 CAMP003, conservando código y todas las pruebas previas. Primero copiar puerta, cola, encargo y manifest en rama exclusiva; **solo IA6 actualiza la reserva**.
2. Mensaje inicial ejecuta bloque 01, después `p` un bloque 02..10 sin permisos por iteración; al 10/10 STOP. Escritura solo pruebas/fixtures/reportes CAMP004 propios; reparaciones autónomas V5 limitadas a evolución específica W04. **Ninguna reparación autónoma de captura, entrenamiento, MT, economía o formas sin contrato y propiedad concedida**.
3. Al ejecutar: comparar catálogo normalizado real, reglas EvolutionSystem/FieldItemService, políticas, consumo/rechazo, identidad/PC/SaveV2 según contrato. Marcar por ID `FUNCIONAL_VERIFICADO`, `NEGATIVO_SIN_SOPORTE`, `DEPENDENCIA` o `AUDITORIA_DE_DATOS`. Un test negativo correcto puede pasar CI, **sin certificar efecto positivo inexistente**.
4. GitHub Actions W04 CAMP004 validará identidad, 10 filas/36 IDs/sin duplicados, y exigirá recibos Python/Godot desde el primer bloque, más regresión CAMP003. Bootstrap 0/10 **no prueba nuevas mecánicas**.
5. Si una operación de GitHub devuelve **denegación de seguridad real**, detener esa operación sin intentar evasiones o rutas indirectas. En W04 hubo una denegación histórica al editar workflow anterior; IA6 comprueba la capacidad de nuevo workflow. Una dependencia de API compartida/SaveV2/permisos se escala, pero se continúa con otro bloque independiente autorizado.
6. Nunca tocar `main`, V28, PR #118, ramas de las otras W, datasets canónicos ni reglas Mega. La rama no se integra sola: IA6 audita lotes y conflictos; UI/GPU no certificados por headless.

**Esta puerta reemplaza el STOP de nueva campaña en CAMP003 solo para W04, sin alterar su cierre verificado.**
