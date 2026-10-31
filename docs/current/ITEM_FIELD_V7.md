# Vitaminas y plumas V7 — 2026-10-29

Se conectan 12 IDs canonicos al servicio de la mochila existente. Se mantiene
un componente puro de entrenamiento separado de curacion y de presentacion;
no recibe inventario, servicios, Nodes ni RNG. FieldItemService prepara la copia,
valida el dueño, publica y consume exactamente una unidad ante un aumento real.

| Estadistica | Vitamina (+10 EV) | Pluma (+1 EV) |
| --- | --- | --- |
| PS | hp_up | health_wing |
| Ataque | protein | muscle_wing |
| Defensa | iron | resist_wing |
| Ataque especial | calcium | genius_wing |
| Defensa especial | zinc | clever_wing |
| Velocidad | carbos | swift_wing |

Son los IDs de PokeAPI ya presentes; no se crean duplicados *_feather. Se aplica
el contrato moderno: hasta 252 EV por estadistica, 510 en total; las vitaminas
pueden superar 100 EV. Si solo cabe una parte del aumento, se aplica esa parte y
se consume una unidad; si no cabe nada, se conserva y no aumenta solo la amistad.
Se recalculan estadisticas con el sistema existente y se conserva el deficit de
PS al cambiar el maximo. Rige la frontera existente de objetivos vivos: no revive.

Amistad base por franjas <100/<200/resto: vitaminas 5/3/2 y plumas 3/2/1.
Campana Alivio activa multiplica por 1,5 y trunca; consumida no aporta bonus.
El perfil fijado usa amistad hasta 255 sin efectos de afecto ni soft cap, como la
referencia competitiva local. Los bonus de mapa/Poke Ball de captura permanecen
pendientes: CreatureInstance no almacena esos metadatos. No se certifica su efecto
por inventar un origen. ITEM_PENDING_V7.json recoge los 18 IDs afectados,
incluidas las seis bayas reductoras que ya estaban conectadas.

Los EV originales se validan antes de serializar la copia: la serializacion
existente convierte valores a int y de otra manera podria ocultar un valor
fraccionario o invalido. Se rechazan valores no numericos, no finitos, negativos,
fraccionarios, fuera de 252, claves desconocidas y total superior a 510. El helper
tambien valida al usarse de forma aislada. No cambia el serializador de criaturas.

Verificacion: 504 contextos positivos (12 objetos, equipo/PC, siete valores de
amistad y tres estados de Campana Alivio). Incluye formula independiente de Mew
Hardy Nv.100, limites parciales por estadistica y total, rechazo de no-op, datos
invalidos sin coercion o mutacion, estado temporal, bloqueo, objetivos ajenos,
identidad y conservacion de IV/naturaleza/movimientos/experiencia/estado/relojes.
La mochila real usa vitaminas y plumas, guarda/carga en archivo aislado y entra
al combate nativo con EV, estadisticas, PS y amistad resultantes.

Resultados finales: **6.990 comprobaciones sin ventana y 6.991 con GPU, PASS**.
Los diez grupos ejecutados pasan, incluida la regresion V4/V5/V6, conexiones,
API real, restauracion, medicinas de combate y politica. Importacion PASS.
Integridad completa PASS para 23.058 archivos historicos fuera de las cinco
excepciones aceptadas de esta linea de trabajo, ademas del delta V7 autorizado
y sellos de funciones. Captura GPU de mochila revisada visualmente.

Reproduccion desde la raiz de esta copia:

```text
python tools/item_audit/run_field_training_v7.py
```

Evidencia: `.godot/item_field_v7/results.json`, `godot.json`, `gpu.json`, logs y
`training_bag.png`. El primer piloto tuvo un error de inferencia de tipo en el
runner de pruebas (bag_before); se corrigio y su log queda conservado como
pilot_parse_failure.log, sin contarlo como PASS. El informe del lote solo se
publica cuando terminan las comprobaciones requeridas.

El alcance se comprueba contra 87a96506, conservando baselines anteriores sin
resellarlos. Datos, politicas, arte, motor nativo, schema de guardado, field_demo
y puente permanecen fuera de la superficie autorizada de este lote. No se
activan caramelos/XP, IV, mints, habilidades ni evoluciones nuevas con este cambio.
Las dependencias restantes siguen explicitadas, sin declarar cerrado el catalogo.

Referencia y agradecimientos: Maruno17 y colaboradores de Pokemon Essentials,
commit 8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b. Contrato y hashes fijados en
`tests/fixtures/item_field_v7/reference_contract.json`, incluyendo Settings y
BattleSettings para la version moderna y el perfil sin efectos de afecto.
No se ejecuta Ruby ni se instala otro motor.

- https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/013_Items/001_Item_Utilities.rb
- https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/014_Pokemon/001_Pokemon.rb
