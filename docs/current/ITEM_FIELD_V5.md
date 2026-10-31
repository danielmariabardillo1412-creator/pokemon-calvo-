# Recuperacion de campo V5 — 2026-10-29

Se amplian las conexiones de la mochila existente con 23 IDs permitidos del
catalogo, sin cambiar imagenes, politicas, schema o motor de combate.
Se reutiliza la preparacion y publicacion transaccional de FieldItemService.
FieldItemEffects aplica las reglas de un perfil de campo separado del perfil de
medicinas admitidas durante combate. La UI solo presenta y solicita la accion.

Contrato fijado, cantidades modernas (Gen 7+):

| Grupo | IDs | Efecto de campo |
| --- | --- | --- |
| Bebidas y alimentos | fresh_water, soda_pop, lemonade, moomoo_milk, berry_juice, sweet_heart | +30, +50, +70, +100, +20, +20 PS |
| Bayas de PS | oran_berry, sitrus_berry | +10 PS; un cuarto de PS maximos, truncado, minimo 1 |
| Bayas de estado | cheri_berry, chesto_berry, pecha_berry, rawst_berry, aspear_berry | Paralisis, sueno, ambos venenos, quemadura, congelacion |
| Curacion completa | lum_berry, lava_cookie, old_gateau, casteliacone, lumiose_galette, shalour_sable, big_malasada, pewter_crunchies, rage_candy_bar | Mismo contrato de Cura Total ya usado en el juego, incluida confusion |
| PP | leppa_berry | +10 PP al movimiento elegido, hasta su maximo actual |

Rage Candy Bar utiliza la opcion moderna de cura de estado, no su curacion de PS
antigua. No se agregan flautas reutilizables ni hierbas con efectos de amistad en
este lote. Los desencadenantes de bayas equipadas siguen en el motor nativo y no
se sustituyen por estas reglas de uso voluntario fuera del combate.

El uso positivo consume exactamente una unidad. Sin efecto, objetivo ajeno,
actividad bloqueada, seleccion PP invalida, estado temporal de Transformacion o
Pokemon debilitado dejan inventario y criatura intactos. Curar sueno retira el
reloj compartido; otros relojes y estados no relacionados se conservan.

Resultados: 1.049 comprobaciones sin ventana y 1.051 con GPU; 46 contextos
positivos (23 IDs en equipo y PC). Los 12 grupos ejecutados pasan, sin errores de
script; incluyen las regresiones V4, conexiones, medicinas de combate, API
nativa/legado, integracion, restauracion, politica e inventario/captura.
Integridad completa: 23.058 archivos historicos protegidos fuera de los cinco
archivos permitidos, ademas de los sellos de funciones.

Verificacion del lote: `.godot/item_field_v5/results.json`, `godot.json`,
`gpu.json`, logs y `recovery_bag.png`. El runner publica JSON/matriz/estado solo
tras completar sus comprobaciones, sin convertir timeouts o errores de script en
PASS. El primer intento de generar el informe fallo por sombrear una variable del
runner, despues de que sus 12 procesos terminaran con PASS. Se corrigio el
runner y se reanudaron la integridad y publicacion, conservando el fallo inicial
en results_report_error.json; no se atribuye PASS a ese primer intento.
La comprobacion GPU usa un archivo de partida de prueba separado.
El informe JSON registra los resultados reales y sus hashes; no se suman IDs de
pruebas repetidas como objetos adicionales.

Reproducir desde la raiz de esta copia:

```text
python tools/item_audit/run_field_recovery_v5.py --full-integrity
```

Los baselines de arquitectura T006B quedan intactos y conservan su alcance
historico. El runner V5 declara sus archivos permitidos contra 0e2cd3a y comprueba
el resto de los archivos protegidos anteriores, junto a las funciones selladas y
los hashes de datos/politica/arte del informe previo.

Alcance pendiente: no certifica todo el catalogo. Siguen las 41 rutas revisadas
que necesitan formas/crianza/mundo y los 323 contextos nativos aun no revisados.
Tambien quedan otras medicinas, entrenamiento, origen de captura, maquinas
antiguas, bolas condicionales, evoluciones condicionadas y Cuerda Huida.
La matriz completa conserva la cobertura previa, agregando solo esta ruta de
campo a los 23 IDs. Consultar ITEM_PENDING_V5.json.

Referencia y creditos: Maruno17 y colaboradores de Pokemon Essentials, commit
8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b, copia local ya disponible.
Se adapta el contrato al estado propio sin ejecutar Ruby ni instalar otro motor.
Los hashes de Settings, Item Utilities e Item Effects estan fijados en
`tests/fixtures/item_field_v5/reference_contract.json`.

- https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/013_Items/002_Item_Effects.rb
- https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/013_Items/001_Item_Utilities.rb
