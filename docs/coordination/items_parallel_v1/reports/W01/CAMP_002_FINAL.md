# W01 — CAMPAÑA_002_FINALIZADA

Rama: `codex/calvo-items-20261102-w01-camp002`. Entrega: **03/03 microbloques**. Únicos IDs: `ability_shield`, `absorb_bulb`, `adrenaline_orb`.

## Matriz de cobertura

| Objeto | Casos | Semillas por caso | Efecto previsto y contrastado en ITER_02 |
|---|---:|---:|---|
| Escudo Habilidad | 2 | 2+1 | Gastroácido no suprime al portador; control sin objeto |
| Tubérculo | 3 | 2+1+1 | Agua: +1 At. Esp. y consumo; sin agua, retención |
| Nerviosfera | 2 | 2+1 | Intimidación: +1 velocidad y consumo; control sin activación |
| **TOTAL** | **7** | **10 ejecuciones** | **30 variantes**: activo, ninguno y reserva |

## Comprobación real y pendiente

- ITER_01: CI #41484879741: PASS del contrato y seis mutaciones rechazadas. No certificaba el efecto Godot de W01.
- ITER_02: CI #41493879869: Godot W01 PASS, **687 comprobaciones / 10 ejecuciones / 0 errores**, Python validó 30 variantes. CI automática propia #41539775567: **SUCCESS**.
- ITER_03: se añadieron **30 restauraciones SaveV2**, validación exacta de checkpoint/propietario/estado/stock y **30 recibos adicionales con hashes SHA-256**, para un total esperado de 60 recibos. Auditoría estática **22/22 PASS**. Nueva CI de los cambios: #41547041337, **EN_CI_AUTOMATICA al publicar**, aún no declarada PASS.
- Fixture Git blob: `74c91b2cfb69d7525ee4d42cc1e57f442c4a808d`.
- Runner Git blob: `a020292d65f2d4f09e12d6716d15101a8f32a500`.
- Validador Git blob: `27bd3bc373db74bc3c93298b07e30e71df129188`.

## Limitaciones

SaveV2 se prueba dentro de la sesión aislada, no tras la vuelta al mapa. Pendientes: GPU/UI, liquidación final, otras habilidades, cambios de portador y más situaciones de combate. Ningún script de producción ha sido modificado.

**Cierre:** CAMPAÑA_002_FINALIZADA como entrega de pruebas; STOP. Un PASS de CI en ITER_02 no certifica automáticamente la nueva ITER_03. No comenzar ITER_04 ni CAMP_003 sin autorización de IA6.
