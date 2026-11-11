# W01 · CONTINUOUS_V2 · Cierre funcional de Fases A y B

## Evidencia de certificación real
- [CI global #42958587809](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958587809): `completed/success`; exactamente **38/38 jobs success**, SHA funcional fijo `dead5a21679c0aa8f635f3ce12fce0279ada0fc0`, sin fallos ni pendientes.
- CI 22 jobs B01 [#42954745915](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42954745915): SUCCESS; CI 16 jobs Fase A [#42939814729](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939814729): SUCCESS.
- Guard posterior de exclusión `dynamax_candy` [#42960157622](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42960157622): SUCCESS con Python y Godot (`checks=22 excluded=45`). Publicado por IA6 tras el SHA de los 38 jobs y verificado por separado.
- Auditoría estructural Fase C **todavía pendiente de nueva CI sobre CSV definitivo**. No escribir `READY_FOR_IA6` hasta validarla.

## Contabilidad sin duplicidades
| Grupo | Candidatos | Certificación | Dependencias | Producción nueva |
|---|---:|---:|---:|---:|
| Fase A TANDA04 | 10 | 10 | 0 | 0 |
| Fase B B01 | 10 | 6 | 4 | 0 |
| Fase B B02 | 10 | 10 | 0 | 0 |
| Fase B B03 | 6 | 6 | 0 | 0 |
| **Total** | **36** | **32** | **4** | **0** |

Las 16 placas B02/B03 cuentan con piloto individual SUCCESS y quedan formalmente CERTIFICADAS en `CONTINUOUS_V2_PHASE_B_PROGRESS.csv` por **CI global #42958587809 SHA `dead5a21679c0aa8f635f3ce12fce0279ada0fc0`**. La matriz de pilotos conserva SHA/CI individuales para diagnósticos, añadiendo el estado final global.

Excepciones de alcance: `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag` conservan `DEPENDENCIA_FUERA_W01`: la selección efectiva no las autoriza y `native_entry=False`. No incluirlas en 32 funciones certificadas.

Cobertura: pruebas positivas y negativas del efecto equipable con `FieldItemService.equip → Showdown/FieldNativeSession → settle_finished_battle → SaveV2`, además de comprobaciones nativas de daño tipo correcto/incorrecto, reserva, sin objeto, no consumo y restauración. No se implementaron mecánicas de formas Arceus, ni se modificó código de producción.

## Límites y siguiente puerta
**La integración en la rama árbitra IA6 todavía NO se ha realizado.** El sello `CERTIFICADO` acredita cobertura y funcionalidad en la rama W01, no fusión, UI general, ni release.

La Fase C pendiente necesita nueva CI del ledger con recibo `W01_PHASE_C_LEDGER_READY total_certified=32 external=4`. Solo tras su PASS podrá publicarse `READY_FOR_IA6` y activar el relevo V4 ya anunciado por IA6.
