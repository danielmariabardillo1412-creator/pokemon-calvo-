# IA6 — RELEVO AUTORIZADO W05 · TANDA 04 (orden vigente)

**La tanda anterior está revisada y cerrada; no la repitas.** IA6 ha actualizado esta misma ruta, que es tu memoria operativa permanente. Al recibir `p` o `sigue`: 1) lee este archivo en TU rama, 2) recupera el CSV/checkpoint de TANDA 04, 3) ejecuta la primera fila pendiente, 4) continúa las 10 filas sin pedir autorización por microbloque y guarda checkpoints cuando se interrumpa el turno. No contestes solo «entendido» ni afirmes trabajo entre turnos.

**Única rama de trabajo:** `codex/calvo-items-20261109-w05-books-ui`. **Reglas generales:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` en la rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola maestra:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W05_TANDA_04.md` en rama árbitra. La cola íntegra queda reproducida abajo para no depender de contexto de conversación. No trabajar en `main`, V28 ni PR118. No modificar archivos fuera de permiso. No declarar CI SUCCESS de otra SHA. Al acabar TANDA 04, informe único y STOP hasta próxima orden IA6.

**Métrica obligatoria separada en tu respuesta:** `hitos N/10 | objetos nuevos X | pruebas/QA Y | integración IA6: no` (salvo integración expresamente certificada sobre la rama de IA6). Una barra 10/10 NO significa diez objetos terminados.

---

# IA6 — W05 AUTORUN TANDA 04: TRADUCCIONES ESPAÑOL ES DE LOS 229 LIBROS MT
**Rama:** `codex/calvo-items-20261109-w05-books-ui`. **Baseline:** T03 CI #42870869700 completed/success sobre cierre documental `048a14278c2000a3c2a66d4ee1db42076357705e` (código principal `93b13e63e175f5156146e3a6c8c5795e9efa8517`). 229/229 MT tienen panel enseñable; T03 detectó 218 nombres españoles sin verificar. **No adjudicar como nuevas MT estas traducciones**.

## Descubrimiento verificado por IA6 — FUENTE YA EN EL REPOSITORIO
- `data/api/v2/move/index.json` contiene 937 movimientos con URI hacia `data/api/v2/move/{id}/index.json`.
- Todos los **229** `machine_rows[tmXX]["scarlet-violet"]` se resuelven por nombre de movimiento al índice local; **0 ausentes**, 229 movimientos distintos. Ejemplo `data/api/v2/move/1/index.json` posee `names` con `language.name="es"` → `Destructor` para `pound`, fuente de localización verificable.
- La fuente preferida es `language.name="es"` (España), **no** `es-419` ni `en` salvo bloqueo o fallback no certificado. Los datos PokeAPI copiados al repositorio no se modifican.
- `SpanishGameText.CORE_MOVE_NAMES` cubre solo nombres de base; `FieldMachineBookProfile.presentacion` y panel siguen mostrando nombres sin traducción. Se autoriza corregir el camino de los libros usando **solo fuentes locales con metadatos comprobables**.

## Diez grupos preautorizados (10×23 salvo grupo final de 22)
| Grupo | MT exactas |
|---|---|
| 01 | `tm01;tm02;tm03;tm04;tm05;tm06;tm07;tm08;tm09;tm10;tm11;tm12;tm13;tm14;tm15;tm16;tm17;tm18;tm19;tm20;tm21;tm22;tm23` |
| 02 | `tm24;tm25;tm26;tm27;tm28;tm29;tm30;tm31;tm32;tm33;tm34;tm35;tm36;tm37;tm38;tm39;tm40;tm41;tm42;tm43;tm44;tm45;tm46` |
| 03 | `tm47;tm48;tm49;tm50;tm51;tm52;tm53;tm54;tm55;tm56;tm57;tm58;tm59;tm60;tm61;tm62;tm63;tm64;tm65;tm66;tm67;tm68;tm69` |
| 04 | `tm70;tm71;tm72;tm73;tm74;tm75;tm76;tm77;tm78;tm79;tm80;tm81;tm82;tm83;tm84;tm85;tm86;tm87;tm88;tm89;tm90;tm91;tm92` |
| 05 | `tm93;tm94;tm95;tm96;tm97;tm98;tm99;tm100;tm101;tm102;tm103;tm104;tm105;tm106;tm107;tm108;tm109;tm110;tm111;tm112;tm113;tm114;tm115` |
| 06 | `tm116;tm117;tm118;tm119;tm120;tm121;tm122;tm123;tm124;tm125;tm126;tm127;tm128;tm129;tm130;tm131;tm132;tm133;tm134;tm135;tm136;tm137;tm138` |
| 07 | `tm139;tm140;tm141;tm142;tm143;tm144;tm145;tm146;tm147;tm148;tm149;tm150;tm151;tm152;tm153;tm154;tm155;tm156;tm157;tm158;tm159;tm160;tm161` |
| 08 | `tm162;tm163;tm164;tm165;tm166;tm167;tm168;tm169;tm170;tm171;tm172;tm173;tm174;tm175;tm176;tm177;tm178;tm179;tm180;tm181;tm182;tm183;tm184` |
| 09 | `tm185;tm186;tm187;tm188;tm189;tm190;tm191;tm192;tm193;tm194;tm195;tm196;tm197;tm198;tm199;tm200;tm201;tm202;tm203;tm204;tm205;tm206;tm207` |
| 10 | `tm208;tm209;tm210;tm211;tm212;tm213;tm214;tm215;tm216;tm217;tm218;tm219;tm220;tm221;tm222;tm223;tm224;tm225;tm226;tm227;tm228;tm229` |

## Plan funcional — no te detengas entre grupos
Por cada MT:
1. obtener `move_id` exacto desde perfil SV, traducir guiones bajos→guiones de PokeAPI **solo para lookup**, resolver ID usando el índice local exacto;
2. leer JSON local `data/api/v2/move/{id}/index.json`; validar `name` canónico y su entrada `names[]` `es`; si falta, `BLOQUEADO` con fuente y mantener fallback explícito, nunca inventar traducción;
3. guardar diccionario `move_id→nombre_es, source_api_id` en NUEVA tabla versionada `data/localization/machine_moves_es_sv_v1.json` (o recurso compatible, sin tocar datos canónicos existentes) y validador Python de integridad (229 IDs, unicidad, source, no contaminación es-419);
4. proporcionar helper localizado `modules/localization/machine_moves_es_sv_w05.gd` (solo resolución por ID) que reciba `move_id` y devuelva nombre validado o fallback; modificar **solo** `modules/inventory/field_machine_book_profile.gd::presentacion` y `scenes/visual/field_machine_book_panel.gd` para mostrar idioma ES de la fuente, sin alterar `FieldItemService.teach`, PP ni compatibilidad;
5. demostrar Godot headless una etiqueta castellana auténtica por cada ID que tenga `names.es` en fuente, y conservar todos los 229 positivos de enseñanza, rebinding, stock, 4 slots, SaveV2, acceso y regresiones T01–T03. Contrastar expresamente entradas `CORE_MOVE_NAMES` que difieran: priorizar `es` solo en panel/libro y registrar discrepancia; no modificar localización global.

**Permisos:** crear solo archivo JSON de traducción nuevo, helper nuevo, pruebas/fixtures/runner/workflow W05, editar la función `FieldMachineBookProfile.presentacion` y el panel W05. `modules/localization/spanish_game_text.gd`, `FieldItemService`, catálogos, PokeAPI fuente, `FieldItemBag`, SaveV2 central y otras ramas son **solo lectura**. IA6 integrará el perfil+panel en la mochila real; no declarar UI real integrada ni benchmark Windows/GPU. No crear componentes gráficos; solo localización textual fiable.

**Cierre:** `reports/W05/AUTORUN_V4_FINAL.md`: 10 grupos, nº traducidos con fuente ES, nº sin fuente, lista de diferencias respecto a anteriores nombres, CI SHA HEAD completed/success, 229/229 enseñanza todavía funcional. Recuento de **MT nuevas 0**; sí hay trabajo de calidad lingüística. `p/sigue` reanuda desde checkpoint. No más autorizaciones microbloque.

