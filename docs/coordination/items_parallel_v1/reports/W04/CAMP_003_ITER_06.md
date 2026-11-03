# IA4/W04 — CAMPAÑA_003 / Microbloque 06

**Estado:** publicado; **EN_CI_AUTOMATICA**, no se atribuye PASS funcional sin logs reales.

## Objetos asignados y alcance
- `auspicious_armor`
- `malicious_armor`
- `metal_alloy`

Se mantienen intactos los bloques 01–05. El runner, el validador Python, el fixture y el progreso se han ampliado de forma acumulativa para 06.

## Pruebas programadas
El runner analiza las evoluciones definidas en el catálogo activo y las clasifica mediante `EvolutionSystem.classify_record`. Solo prueba una evolución positiva cuando la ruta cumple `TRIGGER_USE_ITEM` y `RUNTIME_SUPPORTED`; comprueba gasto único, identidad, IV/EV, movimientos, experiencia, amistad y SaveV2. Cuando el registro exige otra modalidad o condición, comprueba que el servicio rechace el uso directo y conserve inventario y estado del Pokémon. Una ausencia de regla se documenta como `DEPENDENCIA`; nunca como funcionamiento garantizado.

**Advertencia:** formas y condiciones regionales de las armaduras, o modalidad de Metal Alloy, no se deducen de los nombres de los objetos. El resultado ejecutable depende de los registros reales.

## Publicación en rama W04
- Runner Godot: `d042b7c45ef598c6307a232888dc687793071684`.
- Fixture: `8b4fa35a2acf67e02b37dbb09f92ecf2912b8220`.
- Validador Python: `8ea210470b5579d8fd905b7396d35f6b290478be`.
- Progreso: `2703d9692cf3c1101ae494575af2bc8b29942d09`.

## Incidencia de escritura
En el intento inicial del bloque 06 la herramienta devolvió `Esta llamada a la herramienta se ha bloqueado por los controles de seguridad de OpenAI`. Se verificó que la cuenta conectada posee permiso `admin` y `push` sobre el repositorio, y que la rama W04 no había avanzado desde el último HEAD. Un nuevo intento **normal** de `update_file` en la misma rama y ruta autorizada fue aceptado sin cambiar permisos, sin usar endpoints alternativos y sin alterar controles. Se desconoce la razón interna del rechazo previo.

## Validación restante
- Resultado real Python y Godot 4.7 sobre el SHA final: **PENDIENTE DE COMPROBACIÓN**.
- Si la CI falla: diagnosticar logs y reparar el runner/contrato propio bajo `AUTONOMOUS_REPAIR_V5.md`, conservando regresiones.
- `main`, V28, ramas de otras trabajadoras, workflows y código de producción: **sin cambios**.

Siguiente `p`: microbloque 07, solo si no hay un fallo funcional confirmado que impida continuar.
