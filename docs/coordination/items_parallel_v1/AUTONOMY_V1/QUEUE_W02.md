# IA6 — ORDEN PERMANENTE AUTORUN V1 — W02
**Rama exclusiva:** `codex/calvo-items-20261109-w02-mints-integration`
**Estado desde el que se reanuda:** MINT-L3 01 PASS #42696681590; MINT-L3 02 tiene efecto positivo Python39/Godot223 en #42715490604 pero CI global FAILED por expectativas históricas CAMP005.
**Activador:** `p`, `sigue` o `continúa` inicia o reanuda los **diez bloques de esta tanda**, sin pedir nuevo permiso por cada fila. Se trabaja hasta donde permita el turno/herramientas; si se interrumpe, checkpoint y siguiente `p` retoma la siguiente fila no cerrada.
**Reglas vinculantes:** leer `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. Se autoriza la reparación autónoma en archivos propios, la migración versionada de pruebas históricas y seguir con filas independientes pese a bloqueos. **Nunca saltar pruebas ni inventar L3.**
**Resumen al usuario:** barra de filas revisadas `[████░░░░░░] 4/10` y **funcionales N/10** diferenciadas; solo al final enviar cierre a IA6.
**Informe final único:** `docs/coordination/items_parallel_v1/reports/W02/AUTORUN_V1_FINAL.md`; estado por fila en `AUTORUN_V1_PROGRESS.csv`. No tocar main, V28, PR118 ni otras ramas.

## Preflight **preautorizado**: resolver conflicto de regresión MINT-L3 02 SIN detener tanda

IA6 aprueba la **doble puerta histórica + vigente** detallada en el protocolo general: conservar el fixture CAMP005 de 288 casos y ejecutarlo con su SHA congelado (`9e2797a4972f22dbf14d5bc5f2d24bb212d29456` es un baseline válido donde CI completa pasó); en HEAD actual ejecutar los casos no afectados, y usar whitelist EXACTA `adamant_mint;modest_mint;timid_mint` para exigir el efecto nuevo en lugar de los antiguos rechazos. Registrar cada transición negativa→positiva; todos los otros negativos siguen. Se autorizan modificaciones mínimas a **runner/test gate**, no a los 288 fixtures versionados. No usar `continue-on-error`, ni `|| true`, ni doble CI de SHAs confundidas. Al cerrar este preflight, pilot02 pasa a `CERTIFICADO` **solo si** CI global SUCCESS; si falla por dependencia distinta, documentar y seguir a las nuevas filas.

## Tanda 01 — diez mentas diferentes, 1 ID por microbloque
| Fila | ID | Naturaleza de destino y modificadores |
|---|---|---|
| 01 | `hasty_mint` | hasty: +Velocidad, −Defensa |
| 02 | `lax_mint` | lax: +Defensa, −Defensa Especial |
| 03 | `relaxed_mint` | relaxed: +Defensa, −Velocidad |
| 04 | `jolly_mint` | jolly: +Velocidad, −Ataque Especial |
| 05 | `bold_mint` | bold: +Defensa, −Ataque |
| 06 | `calm_mint` | calm: +Defensa Especial, −Ataque |
| 07 | `careful_mint` | careful: +Defensa Especial, −Ataque Especial |
| 08 | `brave_mint` | brave: +Ataque, −Velocidad |
| 09 | `quiet_mint` | quiet: +Ataque Especial, −Velocidad |
| 10 | `impish_mint` | impish: +Defensa, −Ataque Especial |

Primero comprobar reglas de `ProgressionRuleset.NATURE_MODIFIERS`, IDs reales y política; si alguna no existe/está excluida, marcar bloqueada sin activar. Usar `FieldItemService.use_item`, `FieldMintEffects`, naturaleza original y naturaleza efectiva; medir efectos con `StatCalculator.compute` y test positivo PARTY/STORAGE con y sin stock, identidad, PS, nivel100, PP, SaveV2, repetir, sustituir y corrupción. Mantener todas las mentas previas. **No** tocar `CreatureInstance`, `FieldNativeSave`, StatCalculator, EXP Share, FieldGrowth/Mochi, engine, mochila ni SaveV2 central.

**Regla especial de regresión:** cuando cada nueva menta invalide un `mint_dependency` histórico, usar whitelist de promoción y nueva prueba equivalente, nunca bloquearse esperando IA6. Conservar SHA de antiguo estado. Publicar CI final sobre HEAD con 10 filas y casos heredados vigentes. La integración IA6 de naturaleza efectiva en guardado de mundo ya está gestionada fuera de W02.
