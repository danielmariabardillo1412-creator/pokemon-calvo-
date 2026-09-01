# CUADERNO TEMÁTICO — DATA FOUNDATION V3

Estado: **CERRADO / CERTIFICADO**.

Este documento es la referencia operativa consolidada de DATA V3. Los diarios detallados de ejecución se conservan en `docs/history/worklogs/data_v3/` y no es necesario leerlos para continuar otros workstreams.

## 1. Cierre certificado

- PR #95: `DATA V3 — final end-to-end certification`
- rama: `audit/data-v3-end-to-end-closure-v1`
- final HEAD: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- estado: cerrado **sin merge**
- resultado final: **18/18 workflows SUCCESS** sobre el HEAD final.

El cierre no significa que todas las mecánicas Pokémon existentes estén implementadas. Significa que la frontera entre dato preservado y mecánica realmente ejecutable quedó explícita, coherente y protegida por regresiones.

## 2. Fuente inmutable

- snapshot branch: `data/pokeapi-v2-snapshot`
- source commit: `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree: `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree: `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2` y `data/schema/v2`: read-only.

Pipeline:

`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`

No editar JSON generado o fuente inmutable manualmente para corregir una prueba.

## 3. Contrato estructural congelado

- especies: **1.025**
- formas: **326**
- tipos runtime: **18**
- movimientos: **919**
- habilidades: **373**
- objetos: **2.222**
- learnset entries: **61.102**
- evoluciones: **554**
- broken references: **0**
- rejected definitions: **0**
- movimientos XD Shadow excluidos: **18**.

## 4. Moves V3

Frontera final:

- **590 RUNTIME_SUPPORTED**
- **71 PARTIAL_RUNTIME**
- **246 DATA_ONLY**
- **12 UNSUPPORTED**
- total: **919**.

Invariante importante: movimientos `DATA_ONLY` con `effect_specs` ejecutables = **0**.

No ampliar Battle Core únicamente para aumentar el contador de soporte.

## 5. Abilities V3

Cierre específico: PR #92, final `73dc4dced11804d762182a5017389bea77208aa7`.

Frontera:

- **21 RUNTIME_SUPPORTED**
- **14 PARTIAL_RUNTIME**
- **338 DATA_ONLY**
- total: **373**.

No existe mapeo ejecutable oculto para habilidades `DATA_ONLY`.

## 6. Items V3

Cierre específico: PR #93, final `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`.

Superficies runtime cerradas:

Held items:

- `leftovers`
- `sitrus_berry`

Trainer bag:

- `potion`
- `super_potion`
- `hyper_potion`
- `max_potion`
- `full_restore`

Contrato de curación Calvo V1:

- Potion: 20
- Super Potion: 60
- Hyper Potion: 120
- Max Potion: full
- Full Restore: full + status.

Los textos históricos 50/200 de Super/Hyper Potion presentes en metadata de PokéAPI **no redefinen** la semántica runtime del juego.

Oran Berry quedó deliberadamente diferida.

## 7. Evolutions V3

Cierre específico: PR #94, final `be5b4bde75252afa2ef355b2e7392d0884c42d7a`.

Frontera:

- **391 RUNTIME_SUPPORTED**
- **0 PARTIAL_RUNTIME**
- **149 DATA_ONLY**
- **14 UNSUPPORTED**
- total: **554**.

Hay exactamente **165** registros condicionados preservados.

La corrección fundamental del cierre impide que condiciones no soportadas —amistad, hora, género, movimiento conocido, held item de intercambio, forma/región/localización, lluvia, estado de party, etc.— se simplifiquen silenciosamente a una evolución más débil por nivel/item/trade.

Solo siete selectores redundantes `base_form == current source species` permanecen ejecutables porque no cambian realmente la condición.

## 8. Certificación end-to-end

La suite final añade diez invariantes cruzados que congelan:

1. contrato estructural exacto;
2. procedencia inmutable exacta;
3. identidad raw ↔ normalized;
4. cierre de referencias cruzadas y counts de learnset/evoluciones;
5. frontera Moves;
6. frontera Abilities;
7. frontera Evolutions + no ejecución conditioned DATA_ONLY;
8. superficies exactas de Items;
9. ausencia de ejecución oculta DATA_ONLY en moves/abilities;
10. exclusión Shadow y totales de reportes.

Engineering válido de #95:

- SHA `9e17f903f229b6efc0044608dde66aba4783ef9c`
- **18/18 SUCCESS**
- DATA domain: **567 PASS / 0 FAIL**
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**.

La comparación de artefactos contra #94 confirmó ausencia de deriva canónica: raw, normalized, manifest y reportes esenciales permanecieron byte-identical; las únicas diferencias esperadas fueron los diez tests nuevos, registro de una nueva clase de test y timings de importación.

## 9. Significado de “cerrado”

DATA V3 no debe reabrirse para “llegar al 100%” ni para mejorar cifras.

Solo se reabre un dominio cuando:

- aparece una regresión real;
- una nueva mecánica de Battle Core elimina un blocker documentado;
- una fuente canónica/provenance cambia deliberadamente;
- una necesidad concreta del juego exige ampliar una frontera actualmente diferida.

Hasta entonces, el trabajo debe avanzar sobre otros sistemas.

## 10. Archivo de trabajo

Los diarios originales que documentan auditorías y cierres se conservan en:

`docs/history/worklogs/data_v3/`

Ahí están el antiguo notebook 02 y los notebooks 06–25. Se consultan para auditoría histórica, no como estado operativo.

Documento formal del pipeline/arquitectura:

`docs/architecture/DATA_FOUNDATION_V3.md`
