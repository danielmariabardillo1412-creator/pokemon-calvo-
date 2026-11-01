# Puerta de compatibilidad — catálogo y V28 (1-XI-2026)

## Hechos comprobados en GitHub

- Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.
- `main`: V27, referencia de partida de V28 `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`.
- Rama de catálogo: `codex/item-catalog-randomlock-v1-20261101`; **71 commits delante de main**, ninguno detrás en la comparación realizada. Sus cambios de esta comparación son documentación y CSV de selección/coordinación, no un despliegue de los 744 objetos.
- V28: `codex/items-v28-from-main`, PR borrador #118, HEAD `7d49a23d15432b9e7845f2c8cd6b0ee5a88e286e`; **51 commits delante de main** y PR sin fusionar. Su diff incluye cambios en `modules/creatures/progression`, herramientas `tools/item_audit`, tests V28 y workflow de CI.
- Catálogo vs V28: ramas **divergentes**, 71 commits detrás y 51 delante al comparar V28 desde catálogo. No dar por disponible en ramas W el código de V28.
- Árbitra + W01-W05: las seis apuntaban exactamente al commit común `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af` antes de crear esta auditoría.
- V27 `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json`: 624 equipamientos transferidos, 57 rutas evolutivas por objeto, 229 máquinas activas, 77 efectos de campo y 16 bolas; son coberturas distintas, **no** 624 mecánicas certificadas.
- V28 `docs/handoff/ITEMS_V28/COMPETITIVE_COVERAGE_AUDIT.md`: objetivo **61** equipables competitivos de referencia, **27** con cierre ampliado, **30** sin ese cierre y **4** bloqueados por dependencia. Es un subconjunto de la lista de contenido de 744.
- Selección vigente catálogo: 743 canónicos + 1 tipo `mega_stone_universal` (2 unidades). Mega está **aparcada**.

## Incompatibilidad de decisión identificada

`beast_ball` (Ente Ball): el relato de V28 documenta **cancelación expresa** de implementación especial de Ultraentes y captura normal; el catálogo posterior V2 lo incluye como **SELECCIONADO**. **Esto no autoriza automáticamente reactivar código ni descartarlo.** Registrar `CONFLICTO_POLITICA_ENTE_BALL` y no programarlo hasta que la árbitra concilie la decisión vigente con el usuario y los cuadernos. Los tres IDs del primer lote W03 NO incluyen `beast_ball`.

## Regla de integración de partida

**Congelación de escrituras de producción en LOTE_001:** las cinco trabajadoras auditan la rama V27 y la V28 como referencias, pero cada una publica únicamente en `reports/W0X/` de su rama. Se prohíbe crear código contra el catálogo desactualizado respecto a V28.

Al recibir los cinco informes, la árbitra:
1. Extrae contratos compartidos ya existentes, puntos de colisión y pruebas reutilizables.
2. Prepara base de integración que incorpore selectivamente o mediante merge revisado la V28, exclusivamente **en la rama árbitra**; registra SHA, archivos y compatibilidad. No presupone que una lista de CI PASS en V28 certifica la combinación.
3. Ejecuta/verifica los checks de la base resultante antes de permitir producción; si falta entorno de ejecución, declara `BLOQUEADO_VERIFICACION`.
4. Exige que cada trabajadora sincronice **su propia rama** contra el checkpoint aprobado, sin sobrescribir trabajo ajeno. No habrá código de dos ramas contra bases diferentes sin revisión específica.
5. Asigna lotes de implementación **por familia, contrato reutilizable y propiedad exclusiva de archivos**; 1–3 IDs solo como piloto, no como límite permanente. No introducir lógica individual copiada si existe adaptador declarativo.

## Primera ronda: LOTE_001 (AUDITORÍA SOLAMENTE)

- W01: `assault_vest`, `loaded_dice`, `focus_sash` (combatientes).
- W02: `sitrus_berry`, `lum_berry`, `colbur_berry` (bayas y consumo).
- W03: `luxury_ball`, `net_ball`, `dusk_ball` (captura; compara V15 y V28, no cambia reglas).
- W04: `auspicious_armor`, `malicious_armor`, `black_augurite` (evoluciones y puertas de transformación; no anticipar niveles).
- W05: AUDITORÍA DE FAMILIA `MACHINE`: 248 IDs seleccionados vs 229 máquinas activas V27; generar diferencias exactas por ID y tipos de cobertura, sin cambiar libros/código.

**Criterio de aceptación:** reporte trazable con archivo, símbolo, prueba original y SHA; clasificar `FUNCION_Y_PRUEBA` / `CONEXION_PARCIAL` / `SIN_EVIDENCIA` / `DEPENDENCIA`, distinguendo alcance y rama. Proponer la automatización común, no modificarla aún. Registros antiguos no equivalen a PASS de código combinado.

## Protecciones

Ni `main`, ni PR #118, ni selección activa, ni modelos/arte, ni partidas, ni carpetas ajenas. Sin CI masiva en lote documental. Informe y commits en ramas exclusivas. La árbitra no declara PASS funcional de los 744 por haber completado un CSV.
