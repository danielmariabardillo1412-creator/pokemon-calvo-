# Medicinas amargas V6 — 2026-10-29

Se conectan tres objetos permitidos a la mochila existente. No se cambia ningun
veto ni se activa Hierba Revivir. Se reutilizan la curacion moderna ya probada y
la transaccion de FieldItemService; la UI explica la reduccion de amistad.

| Objeto canonico | Efecto | Amistad menor de 200 | Desde 200 |
| --- | --- | --- | --- |
| energy_powder | +60 PS | -5 | -10 |
| energy_root | +120 PS | -10 | -15 |
| heal_powder | Cura Total existente | -5 | -10 |

La amistad no baja de cero; Campana Alivio no aumenta ni reduce las perdidas.
Tampoco hay bonus de origen para cambios negativos: estas tres rutas no requieren
los metadatos ausentes de captura. La perdida ocurre solo si se aplica la
curacion; un Pokemon sano conserva amistad y objeto. El umbral se evalua usando
la amistad anterior. Curar sueno elimina su reloj compartido.

El helper opera sobre la copia preparada por el servicio, reutilizando POCION
SUPER/HIPER/CURA TOTAL del contrato de medicinas moderno, sin otra autoridad de
inventario ni doble consumo. Los efectos equipados y las medicinas durante
combate conservan el alcance anterior.

Pruebas: 144 contextos positivos (3 objetos, equipo/PC, ocho valores de amistad,
sin Campana Alivio/equipada/consumida). Tambien cubren valores invalidos,
seleccion inesperada, objetivo ajeno, campo bloqueado, no revivir, limite de PS,
fuente sin mutar, consumo exacto y conservacion de estadisticas, movimientos,
objeto equipado y ubicacion. El flujo real usa las tres medicinas, guarda/carga
en una partida de prueba aislada y entra al combate nativo con PS/amistad/estado
resultantes. Se conservan las pruebas V4 y V5 como regresiones.

Resultados: **1.754 comprobaciones sin ventana y 1.755 con GPU, PASS**.
Nueve grupos ejecutados con PASS, incluidas las regresiones V4/V5, conexiones,
API real, restauracion, medicina de combate y politica. Integridad completa
PASS: 23.058 archivos historicos fuera de las cinco excepciones aceptadas de
esta linea de trabajo, ademas del delta autorizado V6 y los sellos de funciones.
Captura de mochila revisada visualmente.

Reproduccion desde la raiz de esta copia:

```text
python tools/item_audit/run_field_herbs_v6.py
```

Evidencia local: `.godot/item_field_v6/results.json`, `godot.json`, `gpu.json`,
logs y `herbs_bag.png`. El JSON registra los resultados realmente ejecutados.
El informe completo de 2.222 filas sigue en la matriz CSV; el JSON V6 es
incremental y referencia el informe completo V5 para evitar repetir sus filas.
El verificador declara el delta V6 contra 5bbf7d1 y mantiene los hashes historicos
fuera de las excepciones V5 ya aceptadas, junto a las funciones selladas. La firma
compartida de scope ahora admite base y allowlist explicitas; su llamada V5 por
defecto conserva los mismos limites. No se modifican ni resellan los baselines.

Pendiente: vitaminas/plumas, XP/IV/naturalezas/habilidades, 41 rutas de
formas/mundo/crianza revisadas, 323 contextos nativos todavia no revisados,
bonus de origen de captura, maquinas antiguas y evoluciones/bolas/mundo
condicionales. No se certifica todo el catalogo por cerrar estas tres rutas.

Referencia y agradecimientos: Maruno17 y colaboradores de Pokemon Essentials,
commit 8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b. Contrato y SHA-256 de Item
Effects/Pokemon fijados en tests/fixtures/item_field_v6/reference_contract.json.
Se interpreta el contrato ya disponible localmente; no se ejecuta Ruby.

- https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/013_Items/002_Item_Effects.rb
- https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/014_Pokemon/001_Pokemon.rb
