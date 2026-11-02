# PRETRIAJE CONFIRMADO — CAMP_002 (IA6, 2026-11-02)

**Autoridad:** la persona usuaria ha ordenado autorizar CAMPAÑA_002. Este documento certifica **la existencia de referencias y la clasificación preliminar**, no el funcionamiento nuevo de los IDs ni un PASS de tests que aún no se han escrito.

## Árbol de partida
- `codex/calvo-items-20261101-arbitro` tenía HEAD `1c4ae17a4f0317f56ada57fff43aa2a0538f4bef` antes de preparar encargos; últimos tests CI sobre código `a8e09dbf8b15c61f1b18207d34548ff8a7ca46e4` fueron SUCCESS: [#41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) (W03/W05) y [#41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486) (gate antiguo). El diff desde entonces fue solo documental.
- `docs/coordination/items_parallel_v1/CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv` registra 267 IDs de CAMPAÑA_001. `QUEUE_V1.csv` tiene 744 filas, **no son 744 efectos sin implementar**. Las nuevas candidatas estaban seleccionadas y no forman parte de los 267 IDs ya revisados (salvo máquinas existentes en W05, cuya fase nueva es cobertura adicional de enseñanza).
- Ramas antiguas **no se reutilizan**: W01 respecto a árbitra diverged (ahead 18/behind 19); W02 (23/39), W03 (17/19), W05 (23/12); W02 además retiene versión antigua de arnés corregido por IA6. Cada rama CAMP_002 se creará limpia desde checkpoint arbitral con nuevo nombre, para preservar los reports antiguos y evitar merge de tests obsoletos.

## Clasificación por familia y material que ya existe
| Responsable | Candidato(s) | Verificación de existencia/dep | Dictamen de pretriaje |
| --- | --- | --- | --- |
| W01 | `ability_shield` | `tools/item_audit/held_effect_sweep_v3.cjs` blob `fd5d9d0b1eecf8b84f14e606631df93b40728586` incluye caso suppression/gastro_acid | `YA_EXISTE_TEST_NATIVO_REEVALUAR_GODOT` |
| W01 | `absorb_bulb` | `tools/item_audit/held_effect_sweep_v2.cjs` blob `c9ba4d7bcddad6ae69f085f4b69983461ad05219` incluye efecto de Agua +At.Esp y consumo | `YA_EXISTE_TEST_NATIVO_REEVALUAR_GODOT` |
| W01 | `adrenaline_orb` | `held_effect_sweep_v3.cjs` contiene `intimidate_trigger` (+1 velocidad, consumo) y `no_intimidate` | `YA_EXISTE_TEST_NATIVO_REEVALUAR_GODOT` |
| W02 | `sitrus_berry`, `lum_berry` | `QUEUE_V1.csv` refleja LOTE_002 documental, sin CI de estos casos CAMPAÑA_002 | `EXISTE_CATALOGO_PENDIENTE_PARIDAD` |
| W02 | `leppa_berry` | `held_effect_sweep_v3.cjs` tiene casos PP=0/PP=1, consumo/retenido | `YA_EXISTE_TEST_NATIVO_REEVALUAR_GODOT` |
| W02 | `figy_berry` | Catálogo seleccionado; perfil de naturaleza/generación debe comprobarse antes de esperar consumo | `EXISTE_CATALOGO_FALTA_TRIAJE_DE_REGLA` |
| W03 | `dusk_ball`, `repeat_ball`, `dive_ball` | Seleccionadas. `modules/capture/capture_battle_context.gd` expone `completed_turns` y `catcher_level`, no oscuridad/cueva, especie registrada ni ubicación subacuática; `capture_ball_effects.gd` y `capture_context_ball_effects.gd` no incluyen esas bolas en sus `IDS` | `DEPENDENCIA_DE_CONTEXTO`: **solo caracterización/contratos**, no nueva implementación |
| W05 | muestra de 229 MT activas | `FieldItemService.teach` y `tests/gameplay/parallel_items_w05_machine_books_v1.gd`: ya probadas `tm01`, `tm02`, `tm77`, 229 etiquetas/tipos y 19 heredadas rechazadas, [CI #41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) | `AMPLIAR_COBERTURA_SIN_REIMPLEMENTAR`, muestra ≥12 nuevas MT si el catálogo lo permite |

## Límite autorizado
- Cuatro W: `W01`, `W02`, `W03`, `W05`. **W04 congelada** con su rama y sus 02/03 de CAMP_001, sin sustitución.
- Únicamente pruebas parametrizadas nuevas, fixtures nuevos y reports propios, propiedad de rutas disjunta y cero escritura de producción. Si un test revela carencia funcional, la W produce un ticket `SOLICITUD_IA6`; IA6 decide autorización separada. Esto evita heredar permisos antiguos de CAMPAÑA_001 o alterar código común en paralelo.
- El resultado `PASS` de un test estático sobre su propio fixture NO certifica efecto jugable. Cada entrega conserva `PREPARADO_PENDIENTE_CI` hasta prueba de Godot/Node y hash exacto; IA6 centraliza CI por paquete, preferiblemente al completar microbloques compatibles.
- No tocar `main`, V28, PR #118, selección, guardados del usuario, dos Megas universales, arte de libros o 19 máquinas legadas.

## Próximo paso
Leer `CAMPAIGN_GATE_002.md` para ver nombres de ramas, modalidad de activación y tres microbloques autorizados. No usar las ramas de CAMP_001; cada worker debe confirmar rama y HEAD nuevo antes de aceptar la primera `p`.
