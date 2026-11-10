# AUTORUN V1 W03 — PRODUCTORES AUSENTES COMPARTIDOS (filas 01–04 y 06)

Consulta reproducible: `modules/capture/capture_battle_context.gd` solo contiene `is_wild`, estado/propiedad, `completed_turns`, `catcher_level`. Los productores `modules/gameplay/showdown_adventure_session.gd` y `wild_adventure_session.gd` componen contexto de batalla sin transmitir procedencia del encuentro, reloj de mapa ni Pokédex persistente. `modules/capture/capture_context_ball_effects.gd` registra solo quick/timer/level. La cola histórica CAMP005 ya registra cada contrato pendiente. No se dará por válido un flag de test que no provenga de producción.

| Filas | IDs | Interfaz requerida | Prueba roja que desbloquearía |
|---|---|---|---|
| 01 | black_flute;white_flute;lure;super_lure;max_lure | productor de frecuencia real en escena + política versionada de duración/apilamiento y persistencia en snapshot mundo | compra/uso auténtico, movimiento/encuentro observable, cambio de frecuencia sin RNG duplicado y carga |
| 02 | dive_ball;lure_ball | `EncounterOrigin(kind: fish/surf/dive)` emitido por productor de encuentro y asociado a batalla capturable | pesca real → encuentro → `CaptureBattleContext` del propietario → multiplicador positivo/caso neutro |
| 03 | dusk_ball | reloj/fuente de iluminación y mapa autorizado → contexto capturable | encuentro en noche/cueva verificados → bonus, día normal no bonus |
| 04 | repeat_ball | Pokédex persistente `caught_base_species_ids` con historial ANTERIOR al encuentro, SaveV2 + contexto de batalla | primera captura neutra → captura de la misma especie → persistir/reabrir → repetición con bonus |
| 06 | love_ball;moon_ball;heavy_ball;beast_ball | sexo individual persistente/versión de evolución/masa por forma y ultraente más política por generación | dos sexos/especie reales; ruta de piedra lunar activa; peso real; ultraente catalogado y captura desde sesión |

Las implementaciones de `safari_ball` y `sport_ball` aplican actualmente x1.5 incondicional; no equivalen a una zona Safari o concurso Bicho real. Hasta decisión de IA6 se registran como **parciales**. No se edita `FieldItemBag`, `field_demo`, `field_native_bridge`, `SaveV2` ni APIs centrales en esta tanda; la integración anterior de repelente se preserva.

Se mantiene prueba roja previa `tests/tools/test_parallel_items_w03_block05_source_red.py` como diagnóstico esperado, nunca como PASS funcional. Revalidación específica en `tests/tools/test_parallel_items_w03_autorun_v1.py`.
