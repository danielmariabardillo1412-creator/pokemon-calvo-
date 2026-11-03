# IA4/W04 — CAMPAÑA_004 / Microbloque 03

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`.  
**Estado de entrega:** `EN_CI_AUTOMATICA`; no atribuir PASS antes de consultar GitHub Actions.

## IDs autorizados
- `strawberry_sweet`: confite Fresa, familia EVOLUTION.
- `whipped_dream`: Dulce de Nata, familia EVOLUTION.
- `leaders_crest`: Distintivo de Líder, **familia original FOOD_OR_PICNIC_ACTIVITY**. Su clasificación de selección no se modifica.

## Contratos y precauciones
PokeAPI `data/api/v2/item/1167/index.json` describe el confite de Fresa y Milcery con el objeto llevado y un giro. El motor registra `spin` como `UNSUPPORTED`: no es una piedra de evolución por mochila.

`docs/current/ITEM_SCOPE_V25.md` identifica Dulce de Nata con Swirlix→Slurpuff; su modalidad de intercambio/objeto equipado no debe degradarse a uso directo. El proyecto también reconoce `leaders_crest` como objeto relevante para evolución pese a su categoría de picnic; `EvolutionSystem.UNSUPPORTED_TRIGGERS` contiene `three_defeated_bisharp`. No se inventan contadores de rivales derrotados, equipamiento obligatorio ni triggers alternativos para Bisharp→Kingambit.

## Pruebas del bloque
Runner `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `4f8bf65e2b1b4f49d1bb940010508adb22472411`: acumula bloques 01–03. Verifica presencia de las tres definiciones, clasificación real de las reglas y rechazo cuando la condición no está soportada. En Eevee y en las especies de origen Milcery, Swirlix y Bisharp comprueba que `use_item`, `evolution_options` y `evolve` no activen evoluciones falsas ni gasten inventario. Si `holdable` está habilitado, comprueba equipar/retirar, ausencia de evolución automática, conservación de identidad y SaveV2. Si existe una ruta positiva auténticamente `TRIGGER_USE_ITEM + RUNTIME_SUPPORTED`, prueba la evolución, consumo unitario, propiedades persistentes y guardado, sin asumirla.

Fixture `tests/fixtures/parallel_items/w04_campaign_004.json` commit `4599a43837c32e2de941acab500da1ad2c74e044`. Validador Python `tests/tools/test_parallel_items_w04_campaign_004.py` commit `f3ffcb1ebc80254bd3cfaff579f79418ab8b328b`; comprueba selección, categoría original, reserva, fuentes y cobertura negativa. Progreso registrado commit `a1b5f4bdcc64c86457b50f4cadb977804a6cf888`.

**Pendiente:** CI GitHub Actions con recibos `CAMP004_W04_PY PASS blocks=3 checks=M` y `CAMP004_W04_GODOT PASS blocks=3 checks=M`, más regresión CAMPAÑA_003. La regresión CAMPAÑA_001 del workflow se ejecuta en bloques 05 y 10.

No se ha modificado producción, `main`, V28, workflows, catálogo canónico, rama árbitra ni ramas ajenas. No se afirma funcionalidad de rutas sin prueba positiva.

**Siguiente `p`:** bloque 04/10 (`adamant_crystal;blue_orb;catching_charm`), previa verificación de esta CI.


## CI del bloque 03 verificada

GitHub Actions [#41576674332](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576674332), SHA `a1b5f4bdcc64c86457b50f4cadb977804a6cf888`, `completed/success`. Recibos:
- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=3 ids=36`.
- `CAMP004_W04_PY PASS blocks=3 checks=88`.
- `CAMP004_W04_GODOT PASS blocks=3 checks=292`.
- Regresión CAMP003: `CAMP003_W04_PY PASS blocks=10 checks=120` y `CAMP003_W04_GODOT PASS blocks=10 checks=270`.

El runner informó por separado `status=DEPENDENCIA records=0` para `strawberry_sweet`, `whipped_dream` y `leaders_crest`. Se probaron rechazos, persistencia e inventario, **no una evolución positiva**. Los tres permanecen `DEPENDENCIA_DOCUMENTADA`. El bloqueo de disparadores `spin` y `three_defeated_bisharp` no se ha relajado.

Fila 03 reconciliada en `CAMP_004_PROGRESO.csv`, commit `e9035624278e65e06e0e656d17278c1a6daa209d`. El cambio al CSV inicia una nueva CI para comprobar el estado consolidado; no confundir el recibo original con esa ejecución posterior.


## Verificación final del progreso consolidado

GitHub Actions [#41576832454](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576832454), SHA `e9035624278e65e06e0e656d17278c1a6daa209d`, terminó **completed/success** tras actualizar el CSV al estado `DEPENDENCIA_DOCUMENTADA`. Recibos repetidos: `CAMP004_W04_MANIFEST_PASS reserved=10 completed=3 ids=36`, Python `PASS blocks=3 checks=88`, Godot `PASS blocks=3 checks=292`, y regresiones de CAMP003 Python 120/Godot 270. Se mantienen los tres `status=DEPENDENCIA records=0`.

**CAMPAÑA_004: 03/10 microbloques entregados y auditados**, sin confundir esta puerta de pruebas con efectos jugables. El informe y continuidad son los únicos cambios posteriores a esa CI; ningún módulo funcional cambió.
