> **IA6 AUTORIZA BLOQUE 03 / 2026-11-03:** [revisión exacta del bloque 02](CAMPAIGN_003_W04_ITER02_REVIEW.md): W04 **02/10**, CI [#41556682246](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556682246) `completed/success` Python 29 y Godot 54 comprobaciones, pero **Piedra Oval sigue como dependencia de evolución condicionada**; no se declara implementada mediante `use_item`. No es motivo para bloquear otros objetos independientes. La siguiente `p` ejecuta solo fila **03** `dragon_scale;dubious_disc;electirizer`, con auditoría de contratos y sin cambios a producción. El resto de W mantiene sus encargos y CI autónoma.

# IA6 — AMPLIACIÓN OFICIAL CAMPAÑA_003 PARA IA4/W04

**Fecha:** 2026-11-03. **ACTIVADA POR CORRECCIÓN DE LA EXCLUSIÓN DE IA4 A PETICIÓN DEL USUARIO.**

## Qué ocurrió
La conversación de IA4 se recuperó cuando falló su chat antiguo, completó CAMPAÑA_001 03/03 y la verificación final de IA6 en GitHub Actions [#41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097) terminó `completed/success`: **559 comprobaciones, 12 casos SaveV2, 0 errores** usando el runner corregido e integrado en árbitra. La rama vieja W04 puede contener reportes `PENDIENTE_CI` históricos porque IA6 **no reescribió la rama de la trabajadora**. Esos reportes no invalidan la CI del árbol integrado. El cierre de CAMPAÑA_001 **no implicaba retirar permanentemente la identidad W04**. Su exclusión del primer diseño CAMPAÑA_003 fue una decisión incorrecta de coordinación.

## Ampliación sin interferir con las otras cuatro
- El [GATE_003 principal](CAMPAIGN_GATE_003.md) había autorizado 4 W y una cola global de 40 bloques/150 IDs. Ya fue enviado a IA1/IA2/IA3/IA5. **No modificar ni reiniciar sus ramas, progresos, permisos ni workflow.**
- IA4 se incorpora como **quinta trabajadora** con **10 bloques/30 IDs adicionales y no superpuestos**; total operativo **50 bloques y 180 IDs reservados**. Su autoridad de IDs es **solo** [CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv](CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv), *no* la cola original de 40 bloques. Esta separación técnica impide romper el validador ya activo de las otras cuatro.
- Familia W04: objetos de **EVOLUTION** aún no ensayados por su campaña anterior. Excluidas las seis piedras `fire_stone`, `water_stone`, `thunder_stone`, `leaf_stone`, `ice_stone`, `moon_stone`. Candidatos seleccionados y reservados del catálogo; una reserva no demuestra implementación, ni garantiza que el juego soporte condiciones de intercambio/hora/región.
- Nueva rama `codex/calvo-items-20261103-w04-camp003` que IA6 creará desde la árbitra ya actualizada. Su SHA inicial figurará en [CAMPAIGN_003_W04_BRANCH_MANIFEST.md](CAMPAIGN_003_W04_BRANCH_MANIFEST.md) después de comprobar existencia.
- Encargo exclusivo: [campaigns/CAMP_003_W04.md](campaigns/CAMP_003_W04.md). **No repetir CAMPAÑA_001 ni tocar su rama antigua**.

## Continuación «p» y CI automática
- Primer mensaje de reactivación en el **chat nuevo/recuperado de IA4** ejecuta bloque 01, únicamente una fila exacta de su cola. Siguientes `p` ejecutan 02..10 sin pedir una nueva puerta IA6. Al 10/10 `CAMPAÑA_003_FINALIZADA` y STOP.
- Workflow W04 exclusivo `.github/workflows/parallel-camp003-w04-autoci.yml`, validador `tests/tools/test_parallel_items_w04_campaign_003_manifest.py`; se activa con pushes de pruebas/fixtures/progreso y no con reportes simples. En 0/10, éxito `BOOTSTRAP_NO_FUNCIONAL` solamente.
- Validar Python real `CAMP003_W04_PY PASS blocks=N checks=M` y Godot real `CAMP003_W04_GODOT PASS blocks=N checks=M`; el validador coteja N con el progreso y exige M>0. Si CI `queued/in_progress`, seguir solo con bloque independiente y sin afirmar PASS; falla real = reparar test propio o STOP para pedir revisión IA6 ante producción/contrato/guardados. No simular especies compatibles ni inventar requisitos.
- Ningún cambio a `main`, V28, PR #118, `modules/`, `data/`, `config/`, selección, partidas ni ramas de IA1/IA2/IA3/IA5. Las pruebas automáticas no certifican GPU/UI.

**Orden de prevalencia:** este adendo prevalece sobre cualquier frase anterior del GATE_003 o STATUS que diga "IA4 no participa"; **solo para W04**. Las instrucciones de las otras cuatro mantienen su validez íntegra.
