# IA4/W04 — CAMPAÑA_004 / Microbloque 09

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`.  
**Cola autorizada:** `n_lunarizer_merge`, `n_solarizer_merge`, `roto_catch`, `roto_exp_points`, `roto_friendship`.  
**Estado al publicar:** `EN_CI_AUTOMATICA` (no confundir archivos publicados con pruebas ejecutadas).

## Diagnóstico de catálogo y titularidad

Las cinco entradas están `SELECCIONADO` en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, todas en familia `LEGACY_OR_CATEGORY_REVIEW`. En `ITEM_INVENTORY.csv` tienen `source_category=unused`, `connection=DATA_ONLY`, `native_entry=False`, `evolution_links=0` y bandera `placeholder_description`. El perfil `item_connections_v1.json` no las permite equipar; `imported_recovery_v19.json` no les asigna curación de campo.

- `n_lunarizer_merge`: se comprueba el inventario al tener **Necrozma y Lunala como criaturas distintas en el equipo**. No inventar fusión, transformación ni pérdida de la segunda criatura por `use_item` / `evolve`.
- `n_solarizer_merge`: la misma comprobación con **Necrozma y Solgaleo**. Se protege identidad de las dos criaturas y las cantidades mediante SaveV2.
- `roto_catch`: cupón legacy; efectos de captura son competencia de W03. W04 no certifica multiplicadores de captura.
- `roto_exp_points` y `roto_friendship`: cupones legacy; no certificar experiencia ni amistad en W04 sin pruebas de sus módulos. Tampoco declarar su efecto funcional por aparecer en catálogo.

La palabra `unused` y `placeholder_description` constituye una **señal de revisión para IA6**, no una decisión unilateral de excluir objetos seleccionados.

## Entregables

- Runner `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `65f539a39b88a1e690082e53ce8c1b2ac4466663`. Añade `BLOQUE_09`, examina las rutas evolutivas reales y, si no hay ruta ejecutable, prueba `use_item`, `evolve` a un destino explícito y `equip` rechazados sin gasto con **ambas criaturas presentes**. SaveV2 debe conservar Necrozma, su compañero y el inventario. Para los cupones prueba Eevee como control de uso de campo, rechazos, identidad y SaveV2, sin entrar en sistemas de captura, entrenamiento o amistad.
- Fixture `tests/fixtures/parallel_items/w04_campaign_004.json`, commit `6eb0a3b1a47ff009c75d1c7a04235d38c60d8f39`, quinto grupo de cinco objetos en el bloque 09, sin alterar los ocho anteriores.
- Validador `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `44a0befb47cfbe798ebf2f49b30fe8d7bbc248ec`, exige nueve filas y 29 IDs acumulados, familia legacy, ausencia de equipamiento, `DATA_ONLY`, descripción provisional, cobertura de pareja y aserciones SaveV2.
- Progreso `reports/W04/CAMP_004_PROGRESO.csv`, commit `cf6111da607eb850da867759b61840ad188f3494`, bloque 09 en `EN_CI_AUTOMATICA`.

## Puerta de CI y límites

Verificar `CAMP004_W04_MANIFEST_PASS reserved=10 completed=9 ids=36`, `CAMP004_W04_PY PASS blocks=9 checks=N`, `CAMP004_W04_GODOT PASS blocks=9 checks=N`, regresión de CAMP003 Python/Godot. En caso de fallo se analiza y repara solo el código de prueba propio o cambios permitidos por V5; no eliminar aserciones para obtener PASS. Regresión CAMP001 conservada y ejecutada por el workflow en puertas 05 y 10.

No se han modificado producción, `main`, V28, rama árbitra, otras trabajadoras, catálogos ni workflow. Las 16 dependencias heredadas de CAMPAÑA_003 siguen sin resolver.

**Siguiente `p` cuando esta CI sea satisfactoria:** bloque 10/10, `big_nugget;bottle_cap;gold_bottle_cap;heart_scale;nugget;pretty_wing;rare_bone`. No iniciarlo en esta iteración.

## Evidencia real CI09

GitHub Actions [#41602009788](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41602009788), SHA `cf6111da607eb850da867759b61840ad188f3494`, ha terminado **completed/success**. Recibos exactos de los logs:

- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=9 ids=36`.
- `CAMP004_W04_PY PASS blocks=9 checks=312`.
- `CAMP004_W04_GODOT PASS blocks=9 checks=847`.
- Regresión CAMPAÑA_003: Python `PASS blocks=10 checks=120` y Godot `PASS blocks=10 checks=270`.

**Salida por ID:** `n_lunarizer_merge` y `n_solarizer_merge`: `status=DEPENDENCIA records=0 conditioned=0` por fusión de dos criaturas sin contrato; `roto_catch`, `roto_exp_points` y `roto_friendship`: `status=AUDITORIA_LEGACY records=0 conditioned=0`, respectivamente captura W03, experiencia y amistad fuera de W04. Ninguno queda certificado como efecto jugable.

El CSV se reconcilió a `DEPENDENCIA_DOCUMENTADA` con recibo `41602009788`, commit `d338594b9e085f1de1698e44006a99d0b5a83c36`. La actualización del CSV provoca una segunda ejecución CI sobre el progreso consolidado, cuyo resultado se verifica por separado.

**Bloque 09 técnicamente entregado, pendiente solo de la confirmación CI de consolidación.**


## Segunda CI09 consolidada

La ejecución [#41602238413](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41602238413), SHA `d338594b9e085f1de1698e44006a99d0b5a83c36`, terminó **completed/success** después de registrar la fila 09 como `DEPENDENCIA_DOCUMENTADA`. Recibos repetidos del log:
- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=9 ids=36`.
- `CAMP004_W04_PY PASS blocks=9 checks=312`.
- `CAMP004_W04_GODOT PASS blocks=9 checks=847`.
- Regresión CAMPAÑA_003 Python **120** y Godot **270** PASS.

Los dos objetos de fusión se mantienen `DEPENDENCIA records=0` y los tres cupones `AUDITORIA_LEGACY records=0`. El PASS confirma los contratos de rechazo, inventario y SaveV2 de W04, no efectos de fusión, captura, experiencia o amistad.

**Bloque 09/10 cerrado.** No iniciar bloque 10 hasta otro `p`.
