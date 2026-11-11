# IA4/W04 — CAMPAÑA CONTINUA V3 — CERTIFICADA / READY_FOR_IA6

Fecha: 2026-11-11

## Certificación funcional exacta

- Rama exclusiva W04: `codex/calvo-items-20261104-w04-camp006`
- CI **#42959076143**, **completed / success**, [GitHub Actions](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42959076143).
- SHA funcional certificado: **`db24e6f38943e5782b0d028b2d6553267adecd6f`**. Los commits documentales posteriores no quedan certificados por ese SHA.
- Fase A: `W04_V3_A PASS seven_real_destinations`; se exige `form_id` de destino y no se hereda la de origen.
- Fase B: `W04_V3_L3 PASS checks=326 routes=7 ownership=14 rollback=2`. Las siete rutas se ejecutan de verdad mediante `FieldItemService.evolve`, con resultado nativo `EvolutionSystem.apply_evolution`, stock decrecido exactamente en uno, `instance_id` estable, conservación de IV/EV/naturaleza/movimientos/experiencia, permanencia en Party o Storage y SaveV2 persistente. Dos inyecciones de fallo tras sustitución del propietario (Party/Storage) verifican restauración de inventario, objeto y localización.
- Fase C: V2 B02 59 checks, B03 179 checks; V5 Galarica 64; V4 abilities PASS; V3 todas las regionales `native_functional=55 blocked=1` / 968 checks (Exeggutor Alola permanece bloqueado sin habilidad oculta Harvest); V2 piloto PASS; regresiones Python y Godot CAMP003–006 PASS; detector de cola V1 a V3 202 checks PASS.
- Nuevos **objetos**: 0 (los ítems ya existían). Nuevas rutas evolucionables de extremo a extremo en servicio: **7/7**, sin contar de nuevo los siete contratos L2 previos ni dos L2 Galarica como objetos.
- `main`, V28, PR118 y ramas de otras trabajadoras: sin alteraciones por W04.

## Rutas ejecutadas

| Origen | Ítem consumido | Destino | Party | Storage |
|---|---|---|---|---|
| darumaka_galar | ice_stone | darmanitan_galar_standard | PASS | PASS |
| growlithe_hisui | fire_stone | arcanine_hisui | PASS | PASS |
| sandshrew_alola | ice_stone | sandslash_alola | PASS | PASS |
| slowpoke_galar | galarica_cuff | slowbro_galar | PASS | PASS |
| slowpoke_galar | galarica_wreath | slowking_galar | PASS | PASS |
| voltorb_hisui | leaf_stone | electrode_hisui | PASS | PASS |
| vulpix_alola | ice_stone | ninetales_alola | PASS | PASS |

## Archivos cambiados y autoridad
- `modules/creatures/progression/evolution_system.gd` — **solo** `apply_evolution`.
- `modules/inventory/field_item_service.gd` — **solo** `evolution_options` y `evolve`.
- Pruebas W04 `w04_continuous_v3_red_destinations.gd`, `w04_continuous_v3_real_evolution.gd`, `w04_continuous_v3_fail_publish_service.gd`; workflow `parallel-w04-continuous-v3.yml`.
- `w04_autorun_v5_regional_evolution.gd` migró su aserción de regresión para **exigir** forma canónica correcta en vez de aceptar el defecto anterior.
- `test_parallel_items_w04_autorun_v1.py` reconoce la orden autorizada CONTINUOUS_V3 pero conserva el resto de aserciones congeladas.

## Riesgos, límites y ticket IA6

1. **Integración IA6 NO REALIZADA:** el PASS solo certifica la rama W04 y la API `FieldItemService.evolve`; no demuestra que la rama integradora de IA6 haya incorporado correctamente esta corrección ni que se hayan completado pruebas cruzadas con W02/W03.
2. **Mochila visual:** la CI V3 ejercita directamente el servicio, Party/Storage y SaveV2. No afirma un recorrido visual completo por `FieldItemBag` para las siete rutas; IA6 debe verificarlo en su integración.
3. **Rollback:** se prueba no gasto ante rechazos y dos fallos inyectados de publicación, pero no se ha inyectado cada modo de fallo posible del almacenamiento ni de la UI. El servicio intenta restaurar el estado si la publicación no coincide con lo preparado.
4. **Naturaleza efectiva W02:** esta rama no certifica `effective_nature_id` compartida; IA6 debe trasplantar y probar conjuntamente sin pisar el trabajo de W02.
5. **Política:** Exeggutor Alola continúa bloqueado por habilidad oculta; no se eluden mecanismos `DATA_ONLY` ni elecciones de trade-level/clock/giro que requieran autorización.
6. **Selección de integración:** IA6 debe revisar y trasplantar **por función** `apply_evolution`, `evolution_options` y `evolve`, con los tests W04, al branch de integración `codex/calvo-ia6-integration-20261109`, reejecutar CI y verificar variantes reales en UI. No usar merge ciego.

## Estado
**READY_FOR_IA6**. La campaña W04 V3 está agotada en su alcance. Ningún trabajo pendiente independiente requiere nuevas `p` en esta rama salvo autorización posterior de IA6.
