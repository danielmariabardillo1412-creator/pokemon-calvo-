# IA3/W03 — CAMPAÑA V3 · FASES A/B CERTIFICADAS, REGRESIÓN FINAL EN CURSO

- **mission**: `CONTINUOUS_V3/PLAN_W03.md` en árbitra; activa en `IA6_AUTORUN.md` de la rama propia W03.
- **branch**: `codex/calvo-items-20261104-w03-camp006`; sin modificación de ramas ajenas, main, V28, PR118.
- **phase**: A datos reales **CERRADA**, B Moon nativa **CI SUCCESS**, C ticket + Magikarp **QA SUCCESS**, regresiones históricas final **PENDIENTE**.
- **next_safe_action**: comprobar CI histórica [#42958535816](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958535816) para SHA `ef63e824069aa27ce957e99997df8e7a50c78524`; reparar únicamente test histórico adicional que exija bloqueos V1/V2 ya superados, sin relajar pruebas funcionales ni inventar feature. Si verde publicar `reports/W03/CONTINUOUS_V3_FINAL.md` y `READY_FOR_IA6`.
- **Moon L3**: `moon_ball`, fuente EvolutionRecord `moon_stone` con seis especies canónicas y perfil `moon_ball_gen7_plus_v1`. Prueba nativa ×4 Clefairy/×1 Goldeen, fallo RNG, propiedad, inventario, SaveV2; [#42958341652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958341652) **SUCCESS** sobre SHA `b79f322d89619144f0111205d770e1b4db057b0f`. **41 checks Moon**; origen Python auditor 1.082 especies, 6 evolucionan por Moon Stone, Randomlock sin exclusiones; Magikarp reproducido y negativo.
- **Heavy L2/BLOCKED_CONTEXT**: PokeAPI local tiene peso en hectogramos (`pokemon/35.weight=75`); no está en `CreatureSpecies.source_metadata` ni en `DefinitionCatalog` de combate. No implementado ni mult inventado; requiere seam de peso por forma y política aditiva versionada.
- **Beast BLOCKED_CONTEXT**: ninguna marca Ultraente en fuente de 1.025 especies + 57 regionales; no confundir con `is_legendary` o generación.
- **Phase C world blockers**: Dive/Dusk/Lure/Love sin productor mundo; Safari/Sport solo parciales sin zonas. Ticket único: `CONTINUOUS_V3/W03_PRODUCER_DEPENDENCIES.md`.
- **V3 objects created**: 0 IDs nuevos de inventario; **1 ID existente promovido a L3 por nueva implementación**, Moon Ball. Anteriores V2 16 completas y dos parciales intactas; no contarlas como objetos nuevos.
- **last_green_code_sha**: `b79f322d89619144f0111205d770e1b4db057b0f` (CI V3, no certifica suite histórica conjunta).
- **last_green_ci**: `42958341652`, V3 SUCCESS. 
- **pending_full_regression_sha**: `ef63e824069aa27ce957e99997df8e7a50c78524` / run `42958535816` inicialmente in_progress; no afirmar SUCCESS aún.
- **integration_IA6**: NO.
- **previously_observed_red**: CAMP005 Python/Godot y AUTORUN V1 contenían aserciones históricas sobre Moon no registrada; se actualizaron **solo para permitir Moon autorizado**, manteniendo bloqueos Love/Heavy/Beast y afirmaciones de origen.
- **code files**: `modules/capture/capture_source_w03_v3.gd`, dos campos aditivos de `capture_battle_context.gd`, rama `moon_ball` en `capture_context_ball_effects.gd`, proyección en `showdown_adventure_session.gd::capture`, runner `parallel_items_w03_continuous_v3.gd`, scripts de auditoría, tests históricos y workflows.
- **checkpoint**: este documento [skip ci]; no se cuenta como SHA funcional.

---

## Checkpoint IA6 de activación original (conservado)

# IA6 · W03 — CHECKPOINT INICIAL CAMPAÑA V3
- worker: W03
- branch: codex/calvo-items-20261104-w03-camp006
- mission_version: CONTINUOUS_V3/PLAN_W03.md
- phase: A / pendiente de inicio
- next_id: primera tarea de fase A del PLAN_W03.md
- baseline_v2_last_green_run: 42931723587
- baseline_v2_code_sha: 2c4b0a63f04572be1dd86d565e7b71e78d897c65
- current_v3_code_sha: ninguno todavía
- current_v3_ci: PENDIENTE
- integration_IA6: NO
- objects_new_v3: 0 hasta que haya CI real
- blocked_v3: ninguno comprobado todavía
- next_safe_action: Datos de especie para Heavy/Moon/Beast y productor real

Este archivo lo actualizará la trabajadora al completar una etapa, lanzar CI o agotarse un turno. No confundir el baseline V2 con CI de V3. Leer plan completo en IA6_AUTORUN.md de su rama y CONTINUOUS_V3/README.md de árbitra. No STOP automático por diez hitos. Solo READY_FOR_IA6 al agotar misión independiente real.
