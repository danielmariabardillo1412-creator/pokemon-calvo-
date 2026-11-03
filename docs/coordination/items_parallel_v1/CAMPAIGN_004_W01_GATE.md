# IA6 — CAMPAÑA_004 EXCLUSIVA W01 / GATE ACTIVADO
**Fecha:** 2026-11-03. **Autorización:** usuario confirma cierre de IA1 y solicita continuidad del equipo sin interrupciones. **Identidad única:** IA1/W01, especialidad equipables. **Rama exclusiva nueva:** `codex/calvo-items-20261103-w01-camp004`. **Cola:** [CAMPAIGN_004_W01_QUEUE_APPROVED.csv](CAMPAIGN_004_W01_QUEUE_APPROVED.csv): 10 bloques × 3 IDs = **30 equipables**, sin colisiones con campañas anteriores o activas.

## Evidencia anterior y cierre
CAMPAÑA_003 de W01 tiene 10/10 bloques entregados. Último run [#41575150716](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575150716) en SHA `f084188cb6d560576137c20fa74ea257abbfdb7a`, `completed/success`, `CAMP003_W01_PY PASS blocks=10 checks=806` y `CAMP003_W01_GODOT PASS blocks=10 checks=12392`, gates de manifiesto PASS. Esto certifica casos ejecutados en rama, no integración a main ni todas las interacciones competitivas. **La última fila del CSV CAMP003 aún conservaba estado histórico EN_CI_AUTOMATICA a la última consulta; prevalece el run real verificado, no falsificar estado documental.** Los errores previos de Botas Gruesas/Bola Férrea/Cola Plúmbea se resolvieron en esa suite.

## Nueva reserva
30 IDs `HELD_COMBAT_CANDIDATE` seleccionados en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, libres frente a CAMP001 W01, colas CAMP003 y CAMP004 de las otras cuatro, sin repetir CAMP003 W01:
- **01:** `ability_shield;absorb_bulb;adrenaline_orb`
- **02:** `damp_rock;float_stone;icy_rock`
- **03:** `loaded_dice;misty_seed;power_herb`
- **04:** `psychic_seed;punching_glove;ring_target`
- **05:** `room_service;scope_lens;shed_shell`
- **06:** `smoke_ball;smooth_rock;snowball`
- **07:** `sticky_barb;terrain_extender;throat_spray`
- **08:** `toxic_orb;utility_umbrella;weakness_policy`
- **09:** `white_herb;wise_glasses;zoom_lens`
- **10:** `black_belt;charcoal;magnet`

**Importante:** un ID seleccionado no es implementación funcional. Algunos objetos requieren clima, terreno, acción de una habilidad, RNG, tipos, umbrales, cambios de turno o contexto ausente; el objetivo es verificar con pruebas positivas y negativas de motor real donde haya contrato y declarar `DEPENDENCIA_COMPARTIDA` si falta una API o regla. No inventar efectos ni eliminar objetos por cuenta propia. `adrenaline_orb` podría depender de mecánicas no presentes: registrar incompatibilidad sin falsear activación.

## Protocolo de ejecución
1. Crear rama nueva desde HEAD de W01 CAMP003, preservar los 30 tests anteriores. La antigua rama queda sin cambios; no alterar `main` ni V28. La primera orden activa bloque **01**, cada `p` siguiente ejecuta exclusivamente un bloque 02..10. Al completar 10/10: `CAMPAÑA_004_FINALIZADA` y STOP.
2. W01 escribe exclusivamente fixture, Python, Godot, informe y progreso de su CAMP004 en su rama. **Autonomía de reparación V5** permite corregir efectos de SUS equipables en el módulo/adaptador de equipables, con pruebas realistas y diff mínimo; no reescribir combate compartido, bayas W02, captura W03, evoluciones W04 ni MT W05.
3. Por cada ID: fuente canónica, disparador, comparación con control sin equipado/reserva, consumo único/no consumo correcto, RNG cuando toque, protección contra efectos nulos, identidad y SaveV2. Si un efecto ya está integrado, reutilizarlo y añadir cobertura justificada; no reiniciar implementación.
4. CI CAMP004 W01 verifica cola, identidad, progreso, recibos Python/Godot de SHA con M>0, y regresión CAMP003. La suite CAMP003 completa tardó ~10 minutos en el cierre; **usar regresión completa en hitos 05/10 y ante cambios de producción** para no gastar minutos innecesarios, y además mantener pruebas anteriores sin modificarlas. Si la nueva batería excede límite, diagnosticar/optimizar sin bajar aserciones, o escalar incremento de timeout a IA6.
5. `queued`/ `in_progress` no es fallo: un bloque nuevo independiente puede prepararse según protocolo V5. Fallos requieren investigación propia, no permiso rutinario. `cancelled` por push más reciente no es regresión.
6. No hacer merge ni editar `main`, V28, PR118, rama árbitra u otras ramas; migraciones/contratos compartidos se elevan a IA6. Headless no prueba GPU/UI.
