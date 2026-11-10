# IA6 — ORDEN ACTIVA TANDA 02 PARA W05

**ESTA NOTA SUSTITUYE LA TANDA 01, YA CERRADA.** La orden ha sido publicada por IA6 en 2026-11-10. **Al recibir `p`, `sigue` o `continúa`, empieza inmediatamente la PRIMERA FILA SIN CERRAR de la TANDA 02.** No reabrir TANDA 01 ni pedir permiso por cada hito. Reanudar por el CSV/checkpoint de esta tanda si se interrumpe el turno; no se trabaja en background entre turnos.

**Política maestra:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W05_TANDA_02.md` (rama árbitra). Las autorizaciones especiales y límites de edición de esta nota SON órdenes oficiales IA6. Las ramas son exclusivas. Todo PASS funcional requiere CI en SHA concreto. Al terminar las diez filas, entregar `TANDA 02 FINALIZADA` y STOP a espera de la siguiente nota.

---

# IA6 — IA5/W05 · AUTORUN TANDA 02, RESTANTES 180 MT DE SCARLET/VIOLET
**Fecha:** 2026-11-10. **Rama:** `codex/calvo-items-20261109-w05-books-ui`.
**Previo certificado:** TANDA01 49/49 MT, panel real aislado, #42730140482 SUCCESS sobre `91c8b1803dd93e3ec5a6d68338c41f38fe3f8e4f` (HEAD final del informe, código tested `fd6a04317b21d8afa15af43a25cbe777ae64c4f6`). **No reimplementar esos 49 ni reclamar GPU.**
**Esta orden autoriza 10 microbloques continuos**; `p/sigue` activa y reanuda la tanda sin consultarle permisos a IA6 fila a fila. Registrar estado por fila y cerrar con informe/CI.

## Selección verificada por IA6
Se tomaron los **229 IDs exactos** cuyo `modules/inventory/item_connections_v1.json::machine_rows[ID]["scarlet-violet"]` está definido. Se excluyeron los **49 IDs exactos** de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv`. Restan **180 IDs únicos** repartidos en 10 grupos de 18, sin inventar nuevos ID, sin usar numeración indiscriminada ni alterar V27/V28. Fuente y diff deben verificarse en su HEAD antes de tocar cualquier producción.

| Fila | 18 IDs de la tanda 02 |
|---|---|
| 01 | `tm07;tm16;tm18;tm21;tm22;tm23;tm24;tm25;tm26;tm27;tm28;tm29;tm30;tm32;tm33;tm34;tm35;tm37` |
| 02 | `tm38;tm39;tm40;tm41;tm42;tm43;tm45;tm46;tm47;tm48;tm49;tm50;tm51;tm52;tm53;tm54;tm55;tm56` |
| 03 | `tm57;tm58;tm59;tm60;tm61;tm62;tm63;tm64;tm65;tm66;tm67;tm68;tm69;tm70;tm71;tm72;tm73;tm74` |
| 04 | `tm75;tm76;tm78;tm79;tm80;tm81;tm82;tm83;tm84;tm85;tm86;tm87;tm88;tm89;tm90;tm91;tm92;tm93` |
| 05 | `tm94;tm95;tm96;tm97;tm98;tm99;tm100;tm101;tm102;tm103;tm104;tm105;tm106;tm107;tm108;tm109;tm110;tm111` |
| 06 | `tm112;tm113;tm114;tm115;tm116;tm117;tm118;tm119;tm120;tm121;tm122;tm123;tm124;tm125;tm126;tm127;tm128;tm129` |
| 07 | `tm130;tm131;tm132;tm133;tm134;tm135;tm136;tm137;tm138;tm139;tm140;tm141;tm142;tm143;tm144;tm145;tm146;tm147` |
| 08 | `tm148;tm149;tm150;tm151;tm152;tm153;tm154;tm155;tm156;tm157;tm158;tm159;tm160;tm161;tm162;tm163;tm164;tm165` |
| 09 | `tm166;tm167;tm168;tm169;tm170;tm171;tm172;tm173;tm174;tm175;tm176;tm177;tm178;tm179;tm180;tm181;tm182;tm183` |
| 10 | `tm184;tm185;tm186;tm187;tm188;tm189;tm190;tm191;tm192;tm193;tm194;tm195;tm196;tm197;tm198;tm199;tm200;tm201` |

## Contrato repetido por cada ID
Reutilizar el **panel existente** `scenes/visual/field_machine_book_panel.gd`, `FieldMachineBookProfile.presentacion`, el learnset `scarlet-violet` y **la única ruta** `FieldItemService.teach`. Comprobar en Godot headless que para cada libro existe Pokémon compatible real, aprendizaje positivo desde panel instanciado, PP correcto, identidad y propietario, -1 stock y SaveV2; negativos incompatible, sin stock, bloqueos, repetición, cuatro slots sin reemplazo y reemplazo explícito. No inventar compatibilidad ni modificar datos fuente. Para ID sin especie apta, documentar `BLOQUEADO` con evidencia, sin acreditar efecto.

**Prueba y eficiencia:** ampliar/parametrizar el runner usado en TANDA01 para grupos de 18 y no crear 180 escenas separadas. Ejecución acumulativa por grupos para limitar tiempo de CI y evitar suites innecesariamente duplicadas: cada grupo puede validarse aisladamente y el cierre revalida los 180 + regresión 49. En caso de timeout, segmentar jobs sin perder evidencias, nunca saltar aserciones. Contrato Python de integridad: 229 = 49 + 180 disjuntos, IDs/perfil exactos, 10×18 filas, ninguna duplicidad.

**Ownership:** W05 edita solamente panel propio, runners, fixtures, workflow propio e informes. Prohibido tocar `FieldItemBag`, `FieldItemService`, SaveV2 central, catálogos, learnsets, `main`, V28, PR118 u otras W. **La actualización del panel en la mochila real es responsabilidad IA6**; un test del panel independiente no es un test visual humano ni todos los Pokémon.

**CI cierre:** conservar piloto UI01/02 y TANDA01 49 IDs y CAMP006/005/004/003. Exigir `completed/success` sobre SHA con 10 grupos probados. Informe `reports/W05/AUTORUN_V2_FINAL.md` con funcionales/180 y bloqueados, HASH/CI, ningún crédito repetido. Al cerrar 10/10, STOP hasta nota nueva.

