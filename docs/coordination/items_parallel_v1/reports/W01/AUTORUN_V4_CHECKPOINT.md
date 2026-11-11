# IA1/W01 — TANDA 04 · checkpoint fila 02 y CI acumulativa

- **Orden:** `IA6_AUTORUN.md` TANDA04; única rama `codex/calvo-items-20261110-w01-gems-autobatch01`. No tocar main/V28/PR118.
- **Hito 01 `leftovers`: CERTIFICADO** por [CI #42923382323](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42923382323), 7/7 jobs SUCCESS, SHA funcional `197b908d949825631856d246d36144c88154ea0c`. Python 40, Node 4 variantes, Godot 76; camino L3 real. Era efecto nativo preexistente; **0 objetos implementados nuevos**.
- **Hito 02 `life_orb`: piloto funcional SUCCESS**, [CI #42926044147](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42926044147), SHA `2a8578db6a53fcb0cfe1b66b1ccc22dee1d6eb64`. Python 24, Node 5 variantes (daño, retroceso, inmune, estado, reserva), Godot 4 variantes/92 comprobaciones; `FieldItemService.equip`, FieldNativeSession, settle y SaveV2. **Pendiente CI acumulativa única con regresiones históricas para certificación oficial de fila 02**.
- **Este commit** incorpora `v4_life_orb` al workflow W01 V4 junto con `v4_leftovers` y los seis jobs heredados `v3_l3_field_path`, `v3_field_boundaries`, `v2_new_gems`, `tanda01_regression`, `camp004_regression`, `camp005_regression` (8 jobs en total). Comprobar head_sha y `completed/success` reales.
- **CSV** marca 01 certificado y 02 en `EN_CI_AUTOMATICA`; 03–10 PENDIENTE. Métricas oficiales al publicar: **1/10 certificados; 0 objetos nuevos; 1 recorrido L3 certificado y 1 piloto L3 verde pendiente de puerta acumulativa; integración IA6 NO**.
- **Siguiente p:** consultar CI disparada por este commit, investigar logs y reparar solo archivos propios W01 si falla. Cuando complete todos los jobs, marcar `life_orb` certificado (efecto previo nativo, sin crédito de implementación) y empezar `choice_band`, con bloqueo/reset tras cambiar de Pokémon desde mochila real.
- **Prohibiciones:** sin cambios a `native_engine.cjs`, SaveV2, motor global u otros propietarios; no falsear PASS ni adjudicar regresiones de otra SHA a la actual.

## Relevo verificado 2026-11-11 01:09 (Madrid)
- CI #42926374158 completed/success 8/8 en SHA `46e4204a77743656de68d2026f6533f712c618cd`, por lo que fila 02 `life_orb` está CERTIFICADA.
- Piloto #42927457230 completed/success en SHA `afb05a97a5dcfa0e654e819ea836598e2924df5d` para `choice_band`. Se incorpora como noveno job al workflow V4, aún no certificado globalmente.
- Fase A: 2/10; 0 objetos nuevos; 2 recorridos L3 nuevos en cobertura pero con efecto previo del motor; integración IA6 NO.
- Campaña CONTINUOUS_V2 activa: tras fila 10 seguir otros 26 IDs, no parar para pedir nueva tanda.

## Actualización 11-11-2026 · bloque 03
CI #42929306389 terminó **SUCCESS 9/9** en SHA `0d11b41549b713c68433fa6b1d11d18b7d7e670c`. Fila 03 `choice_band` **CERTIFICADO**. Los 4 pilotos filas 04–07 ya verdes pasan a workflow acumulativo de 13 jobs; certificación pendiente. Estado 3/10, 0 nuevos de producción, integración IA6 NO. Próximo piloto: fila08 `safety_goggles`.
