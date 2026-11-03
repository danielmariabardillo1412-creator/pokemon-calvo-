# IA2/W02 — CAMPAÑA_005 · MICROBLOQUE 08/10

**Autoridad:** IA6, `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` fila 08, `campaigns/CAMP_005_W02.md` y V5. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. No se modificaron `main`, V28, rama árbitra, otras trabajadoras, producción, APIs compartidas ni workflows.

## Resultado discriminado: un objeto funcional y tres dependencias

| ID | Casos nuevos | Estado funcional realmente respaldado |
|---|---:|---|
| `fresh_start_mochi` | **10**: 7 positivos y 3 rechazos | **Conectado:** reinicia todos los EV, `ev_reset` y `ev_removed`, sin amistad; límites e integridad del estado |
| `adamant_mint` | **6** rechazos | **DEPENDENCY_MISSING**: no hay ruta para aplicar naturaleza efectiva Firme |
| `modest_mint` | **6** rechazos | **DEPENDENCY_MISSING**: no hay ruta para aplicar naturaleza efectiva Modesta |
| `jolly_mint` | **6** rechazos | **DEPENDENCY_MISSING**: no hay ruta para aplicar naturaleza efectiva Alegre |

**28 escenarios nuevos × 3 modalidades = 84 variantes previstas**. No se cuentan como funcionales los tres IDs de mentas.

### Mochi Reinicio — oráculo positivo real

`modules/inventory/field_mochi_effects.gd` tiene `fresh_start_mochi` en `supports`: comprueba EV válidos, requiere al menos un EV distinto de cero, pone las **seis estadísticas EV a cero**, recalcula las estadísticas sin cambiar amistad y devuelve `action=ev_reset` con `ev_removed=EV_total`. El runner `tests/gameplay/parallel_items_w02_campaign_005.gd` construye estados EV iniciales independientes (PS 100; Ataque 252; Defensa 60 + Ataque Especial 70; seis EV de 10; distribución 510; Velocidad 150; PS 100 + Velocidad 50 y amistad 254). Verifica que el estado final tenga seis EV cero, diferencia de PS preservada, estadísticas recalculadas, IV/PP/naturaleza/experiencia/amistad intactos, consumo único, SaveV2 y recibos JSON/SHA256. También rechaza sin consumir cuando los EV ya están a cero o se pasa una ranura incompatible (dos situaciones).

### Mentas — dependencia precisa, no simular funcionalidad

La configuración `config/item_selection_v1.json` **no excluye** `adamant_mint`, `modest_mint` ni `jolly_mint`. Sin embargo, `FieldItemService.use_item` no tiene ruta de menta, ni `FieldItemEffects`, `FieldGrowthEffects` o `FieldMochiEffects` soportan esos IDs; la salida nativa esperada del servicio es `status=DEPENDENCY_MISSING`, `reason=field_effect_not_connected`. `CreatureInstance` persiste `nature_id`, pero carece de un campo independiente para el **modificador estadístico de naturaleza adquirido por menta**. La tabla `ProgressionRuleset.NATURE_MODIFIERS` describe naturalezas base, pero eso **no implementa** la mecánica moderna de mentas. Es incorrecto modificar la naturaleza original como sustitución sin decisión de diseño de IA6.

Se definen seis rechazos por menta: naturaleza actual neutral, naturaleza igual a la solicitada, naturaleza distinta, amistad alta, ranura inesperada y nivel 100. En todos los modos `active` (PARTY con objeto), `none` (PARTY sin objeto) y `reserve` (STORAGE con objeto), el contrato exige que el Pokémon, la bolsa y la persistencia se conserven sin cambios. **No existen pruebas positivas de mentas porque aún no existe la funcionalidad**. El bloque 08 queda con `DEPENDENCIA_DOCUMENTADA`, no `CI_PASS_VERIFICADO`.

**Dependencia para IA6:** decidir si la naturaleza original permanece inmutable y una `effective_nature_id` separada afecta el cálculo estadístico y combate; diseñar persistencia/SaveV2, compatibilidad con los consumidores de stats y política de mentas repetidas. Sólo después debe implementarse por propietario coordinado de APIs compartidas y sustituir los rechazos por casos positivos reales. No se escribieron cambios de dominio no autorizados.

### Código propio y evidencias

- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json` — `9cab2ac454f5c422e9d5884d22f5750ec916850a`.
- Runner `tests/gameplay/parallel_items_w02_campaign_005.gd` — `c946fbd2f02e1b3513ce92b3bcf4515c54dd1541`, `da1bfedd68c1f33924ed53988e62996c6f0b856d`, `75124b5c642e556b5712f3e3474d57ffc321d7f9`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py` — `e535765b7efae09d3e2c3e33083dd64d3e26f12d`, `ed338158eecf9463f665bb40b810a1c14bd76be3`, `da302ed69ae753fec96e312660f5b650c071bbaa`, `fbb934a9d941c27ad84a8762d99d9df7344faef9`, `6f3c5c3d70b1e9533b1c3f1f7a16ca010a9fe5f7`, `4bfc7b2eef9e5a5aca7cb0a677c9a98788d32755`. Incluye `EXPECTED_08`, chequeos de ruta real, ausencia de ruta de mentas y **16 mutaciones adversariales**.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv` — `3292808445297cd0968f4acbcdd874692121d920`, fila 08 `DEPENDENCIA_DOCUMENTADA`, CI pendiente.

**Acumulado CAMP005:** **8/10 bloques publicados, 32 IDs asignados, 224 escenarios y 672 variantes programadas**. De los cuatro de esta fila, solamente Mochi Reinicio posee un efecto positivo implementado. Los tres de menta siguen bloqueados.

### CI y seguridad

Se comprobaron estructuralmente los ocho golden independientes, rutas fuente/fixture, 32 IDs únicos y 224 escenarios no repetidos. **No se han ejecutado Godot ni Python en el entorno de esta conversación ni recuperado runs/logs que certifiquen `CAMP005_W02_PY/GODOT PASS blocks=8`**. El conector de GitHub devuelve listas vacías para runs asociados a los commits; la consola de trabajo no tiene Godot ni puede resolver github.com para clonar. No inferir PASS/FAIL. Regresiones CAMP004/CAMP003, hito 05, siguen pendientes de logs verificables; ningún motor de producción fue alterado.

**Siguiente `p`:** revisar CI y ejecutar **sólo el bloque 09** `timid_mint;bold_mint;calm_mint;careful_mint`, sin inventar conexión funcional de mentas. Reportar la misma dependencia salvo que IA6 haya incorporado ya el sistema de naturaleza efectiva en GitHub. El bloque 10 debe esperar a una `p` posterior.
