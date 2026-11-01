# ESTADO DE COORDINACIÓN — LOTE_001 revisado; LOTE_002 asignado, SIN EJECUTAR

**Fecha:** 2026-11-01. **Árbitra**, rama `codex/calvo-items-20261101-arbitro`.

## Resultado recibido

Cinco informes `LISTA_PARA_REVISION`, revisados y **aceptados como auditorías documentales** (no pruebas de código nuevo), con HEAD:
- W01: `aa224efeb261a05a63e5d3cae928748ec195aeb1` ·  [informe propio](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w01/docs/coordination/items_parallel_v1/reports/W01/LOTE_001.md)
- W02: `dd9d1616e405f5ac2d455185abbc7f5a39449233` ·  [informe propio](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w02/docs/coordination/items_parallel_v1/reports/W02/LOTE_001.md)
- W03: `c84a0f9cd5e1890038eb2e085fa2304e2e001cd2` ·  [informe propio](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w03/docs/coordination/items_parallel_v1/reports/W03/LOTE_001.md)
- W04: `26eabd19cea4f2b9c88961e3b03852b32eaf8ea4` ·  [informe propio](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w04/docs/coordination/items_parallel_v1/reports/W04/LOTE_001.md)
- W05: `d9fffd2da1c9e4f2c120557503503292a34844f6` ·  [informe propio](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_001.md)

**260 IDs triados** (3+3+3+3+248). **Nuevos efectos en producción 0.** **CI/Godot nuevos 0.** W05: 229 máquinas con evidencia histórica de conexión, 19 sin perfil activo; sin libro visual certificado.

## Checkpoint común

- Merge contenido V27/catálogo + V28 en árbitra `38188cc208e67b19002437ac75160898ce332ec2` (dos padres, diferencias **sin archivos coincidentes**). **BASE_COMBINADA_SIN_CI**: no hay ejecución de Godot de la fusión.
- `main` intacta. PR #118 y rama V28 intactas. Las cinco ramas W conservaron sus propias auditorías, aún deben sincronizar checkpoint a su rama antes de escribir pruebas.
- Política `beast_ball` contradictoria entre V28 y nuevo catálogo, **sin autorización de producción**.
- Ver [revisión integral](./integration/LOTE_001_REVIEW_2026-11-01.md).

## Ronda siguiente

| W | LOTE_002 | Objetivo | Permisos | Estado |
|---|---|---|---|---|
| W01 | [LOTE_002_W01](./assignments/LOTE_002_W01.md) | Pruebas de 3 equipables | Scripts/fixtures propios + cuaderno | ASIGNADO_SIN_ACTIVAR |
| W02 | [LOTE_002_W02](./assignments/LOTE_002_W02.md) | Pruebas de consumo 3 bayas | Scripts/fixtures propios + cuaderno | ASIGNADO_SIN_ACTIVAR |
| W03 | [LOTE_002_W03](./assignments/LOTE_002_W03.md) | Test de contexto para net_ball; otros 2 bloqueados | Tests propios + cuaderno | ASIGNADO_SIN_ACTIVAR |
| W04 | [LOTE_002_W04](./assignments/LOTE_002_W04.md) | Regresión 3 evoluciones por mochila | Tests propios + cuaderno | ASIGNADO_SIN_ACTIVAR |
| W05 | [LOTE_002_W05](./assignments/LOTE_002_W05.md) | Validador 248 máquinas (229+19) | Script, tests y fixtures propios + cuaderno | ASIGNADO_SIN_ACTIVAR |

**No son autorizaciones de modificar producción.** Las W pueden leer trabajo ajeno pero solo escribir en rutas propias. Integración serializada por IA6 y **una sola batería de CI consolidada** si es viable; faltan tests del árbol combinado. Ninguna W inicia nuevo lote sin intervención del usuario.

## Relevo y conteos de catálogo

743 canónicos seleccionados, 1375 descartados, 104 mega históricas aparcadas; 1 mega universal provisional adicional = 744 tipos de diseño; 2 unidades del mismo tipo, hasta 2 activaciones por entrenador/combate, pero Mega no se desarrolla ahora.
