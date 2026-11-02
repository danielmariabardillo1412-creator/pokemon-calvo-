# CIERRE TECNICO CAMP_001 — FOTO CONSOLIDADA PARA RELEVO (IA6, 2026-11-02)

**Naturaleza:** informe de auditoría, NO nueva campaña, NO permiso de ejecución, NO certificación global de todos los objetos. Fuente operativa preferente para continuar: `CAMPAIGN_GATE_UPDATE_005.md` + este documento + `STATUS.md`. Conservar documentos previos como históricos, sin tratarlos como estado vigente.

## 1. Foto verificada de ramas y puertas
- Árbitra: `codex/calvo-items-20261101-arbitro`, HEAD de partida auditado `b01ee6f6929507dcfe80482a411667a45a0251b1`; después de ese HEAD solo se publicará documentación de cierre.
- W01 `05003b7e31c08ea9c2956eb47bda5e5786ce275d`, W02 `605139d60b28b222a8211585844548cf4b1a3cd7`, W03 `c2c48204dafdb89571d5a0e74b3226e6e3ca5233`, W04 `146dfd0c17334ef95295e1106b26b86375bddfe2`, W05 `2f7e2d32368916d7df01c13f8234ee24981d1bc4`. No modificar ramas ajenas.
- Último código consolidado y ensayado en árbitra: SHA `a8e09dbf8b15c61f1b18207d34548ff8a7ca46e4`. `git compare(a8e09dbf, arbitro)` devolvió **4 commits adelantados, 0 retrasados y solo 2 rutas documentales** (`STATUS.md`, `CAMPAIGN_GATE_UPDATE_005.md`) antes de este documento. NO hay diferencias funcionales posteriores a ese árbol de pruebas.
- [Actions #41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486): `completed/success` en SHA `a8e09dbf`, regresión histórica W01–W04 y veredicto general.
- [Actions #41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482): `completed/success` en **el mismo SHA**, CI acotada nueva W03 final + W05 final. Godot 4.7 headless.
- `main` HEAD auditado `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`, rama V28 `codex/items-v28-from-main` HEAD `7d49a23d15432b9e7845f2c8cd6b0ee5a88e286e`. Ninguna escritura en esas ramas durante la auditoría. PR #118 no se ha promovido.

## 2. Situación de microbloques
| Trabajadora | Progreso | Última evidencia / alcance real | Orden |
| --- | ---: | --- | --- |
| W01 | 03/03 | Seis objetos equipados (`black_sludge`, `shell_bell`, `big_root`, `eviolite`, `expert_belt`, `safety_goggles`); prueba de escenarios acotados W01 en staging #41350981613, 2428 checks/24 filas, incluidos en árbitra; ITER_03 consolidó docs/hashes | STOP |
| W02 | 03/03 | Seis bayas (`oran`, `pecha`, `cheri`, `persim`, `chesto`, `rawst`); corrección de **arnés** sobre log de simulador + semilla de JSON; #41354434516 1544 checks/16 casos, Python 18 y prueba de recibos PASS | STOP |
| W03 | 03/03 | `net_ball` multiplicador Agua/Bicho x3,5 sin doble acumulación, capturas y propiedad/SaveV2; suite final 60 checks/0 errores; CI #41364601482 | STOP |
| W04 | 02/03 | Seis piedras (fuego, agua, trueno, hoja, hielo, lunar), rutas positivas/controles seleccionados; paquete #41350981613 W04 PASS 313 checks/12 casos; **la ITER_03 no existe y no está certificada** | **CONGELADA POR EL USUARIO**, no reabrir ni sustituir |
| W05 | 03/03 | 248 MACHINE seleccionadas clasificadas (229 activas SV, 19 sin versión activa); etiquetas/tipos y 3 ejemplos de enseñanza `tm01/tm02/tm77`, PP, consumo, rechazos y SaveV2; #41364434498 y #41364601482: 1083 checks/0 errores, Python 14 | STOP |
**Balance documental 14/15**. No indicar `CAMPAÑA_001_GLOBAL_FINALIZADA`, ni activar `p` para nadie, ni empezar CAMPAÑA_002.

## 3. Riesgo detectado: cola histórica obsoleta
`QUEUE_V1.csv` no recoge estos resultados; por ejemplo `black_sludge` sigue `PENDIENTE_PRUEBA_O_CLASIFICACION_POR_ID`, `net_ball` sigue `CAPTURA_CARACTERIZADA_NET_NO_IMPLEMENTADA`, y `tm01` sigue `CONSISTENCIA_ESTATICA_PASS_248_229_19_FUNCIONAL_PENDIENTE`. Son estados **anteriores** al GATE_005: ignorarlos como evidencia actual.

Por seguridad **no se ha reescrito el CSV grande ni el catálogo de selección**. Para cualquier planificación futura, aplicar esta precedencia:
1. `CAMPAIGN_GATE_UPDATE_005.md` (permiso y congelación) + este cierre (evidencia CAMPAÑA_001).
2. Actas `integration/` y CI identificadas por SHA.
3. `QUEUE_V1.csv` únicamente para **candidatos no presentes en esta campaña**, sometidos a nuevo triaje por ID. Actualizar su metadata durante una futura campaña expresamente aprobada, no ahora.
4. `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` es una instantánea V27 de fecha `2026-10-31`, NO incorpora por definición la evidencia CAMP_001 de noviembre; usarla como referencia histórica, no certificación actual.

Nunca traducir una cobertura de **escenarios seleccionados** en `TODOS_LOS_EFECTOS_CERTIFICADOS`. Para las 229 MT, clasificación y etiqueta no equivalen a ejecutar enseñanza de 229 x cada especie. Para las seis piedras W04, dos iteraciones probadas no equivalen al cierre 03/03.

## 4. Riesgos y dependencias aún abiertos (sin encargo)
- **W04:** preservar HEAD y sus informes 01/02; chat fallido, congelación expresa. No fusionar su rama en bloque, reescribirla o reemplazarla por otra conversación sin orden nueva.
- **Pruebas visuales/GPU del PC del usuario**: 0 acreditadas por esta campaña; arte de libros y seis diseños siguen sin aprobar, igual que UI visual real.
- **Cobertura competitiva adicional:** interacciones no muestreadas de objetos equipados y bayas, variantes nativas del motor, especies/movimientos no ejecutados en la muestra. El estado V27 marcaba `verification_all_effects_complete=false`, `untested_native_contexts=323`, `reviewed_held_and_berry_dependencies_pending=41`; cifras **históricas, no recuento corregido CAMP_001**.
- **Perfiles, formas y economía**: la ficha V27 mantiene como dependencias `amulet_coin`, `exp_share` y `luck_incense`; no adjudicar comportamiento sin contrato. No alterar configuración de mega piedras (2 universales) mientras se cierra inventario.
- La sincronización a `main` **NO está autorizada** y no forma parte del cierre. No tocar V28 ni PR #118.

## 5. Próxima decisión pendiente del usuario
- La campaña queda **en pausa controlada** con cuatro trabajadoras cerradas y W04 congelada, mientras no se autorice expresamente un nuevo alcance.
- Si se desea avanzar más adelante, IA6 podrá **preparar una propuesta** de CAMPAÑA_002 con triaje por ID basado en pruebas reales y propiedad de rutas sin tocar la W04. Prepararla no es activarla; cada trabajadora necesita asignación y permiso nuevos.
- La próxima conversación IA6 debe leer **esta instantánea primero**, luego solo las CI/actas pertinentes al nuevo problema; no reabrir todo el histórico ni usar la cola vieja como fuente de verdad.
