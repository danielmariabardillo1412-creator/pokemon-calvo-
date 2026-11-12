# IA6 — checkpoint posterior al merge PR #122 y auditoría de colas (2026-11-12)

## Certificación oficial posfusión — verificada
- Repo `danielmariabardillo1412-creator/pokemon-calvo-`.
- Rama oficial `codex/calvo-ia6-integration-20261109`.
- HEAD oficial pin `b72e2ac72e566c26bb585fd633741fb7e254392e`; comparación contra ese commit **identical / ahead=0 / behind=0** en la auditoría.
- PR #122 **merged=true** en `b72e2ac72e566c26bb585fd633741fb7e254392e`: exclusivamente dos runners de restauración V27 actualizados para persistencia real de W03 repel (sin producción).
- Antes de merge, SHA candidato `3585f6e6d1e6db4fa8711f36d6adfa36406ec31a`: **20/20 PR CI completed/success**, incluyendo Windows V27 original sin waivers y Linux V28 40 escenarios e histórico.
- **CI oficial POSTMERGE** workflow `IA6 Official - W03 repel W05 books and Rope cross gate`, run **#43139045017**, job **130921270413**, **completed/success**, sin pasos fallidos: import Godot, W05 libros, Rope, mochila real, W03 repel. Link https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43139045017
- Cierre de PR #122: CERTIFIED_POSTMERGE para esa puerta exacta. **No** implica certificación universal de todas las trabajadoras o de nuevos trabajos V5–V7.

## Auditoría de trabajos pendientes
### IA1/W01
- Branch `codex/calvo-ia6-candidate-w01-held-qa-20261112`: detrás 4 commits de IA6, **0 ahead**: candidato anterior íntegramente contenido en oficial; no hacer segundo merge.
- `codex/calvo-ia6-candidate-w01-rocky-helmet-20261112`: **ahead=2 / behind=4**, diferencias solo `.github/workflows/ia6-w01-rocky-helmet-candidate-20261112.yml` y `tests/gameplay/w01_continuous_v4_camp003_rocky_helmet.gd`; prueba nativa Casco Dentado contacto/no contacto, active/none/reserve, restauración SaveV2. Es **QA candidata, no integración productiva**. Exigir CI en SHA real, historial CAMP003 y W01 previo, luego comparar con HEAD oficial. No trasladar staging W01 completa por detrás de IA6.
### IA2/W02
- `codex/calvo-ia6-w02-integration-20261111`: 0 ahead/81 behind de IA6. Ya está contenido; no duplicar.
- `codex/calvo-ia6-staging-20261111-w02-growth`: ahead=2/behind=95, solo `STATE_W02.md` y `IA6_AUTORUN.md`; V4 no activada, sin código nuevo. Reconfirmar contrato EXP Share V3 antes de autorizar implementación.
### IA4/W04
- V4 regional W04 ya en IA6 y puerta oficial #43124042732 SUCCESS.
- V6 nueva en branch `codex/calvo-items-20261112-w04-evolution-consumer-v6`: source SHA certificado `1dd5bb05e987b75cedadeefa09c64925ff4cb35b`, CI #43126697924 SUCCESS. 2 rutas Diglett Alola/Meowth Galar, UI señalizada 4 casos, Party+Storage 8, preservación V5/V4. **NO integrado** en rama IA6: falta evaluación de seam y CI cruzada.
- DEP-02 **BLOQUEO REAL**: `session.close()` se atasca (>180 s) después de XP→aceptar evolución→SaveV2; test V6 usa `stop_now()` solo para cleanup, **no certifica retorno al mapa**. V7 `codex/calvo-items-20261112-w04-battle-return-v7` STATE reporta fase A, `RETURN_TO_MAP_L3` **0/1**, sin CI V7 aún. Plan V7 publicado en árbitra `docs/coordination/items_parallel_v1/CONTINUOUS_V7/PLAN_W04.md`; W04 debe aislar fallo y probar `FieldNativeBridge.leave_battle()`, liberación del control de campo, un segundo combate, no duplicar XP.
- DEP-01 independiente: importación nativa Showdown rechazó naturaleza efectiva de menta `hardy`→`adamant` (Stat import mismatch). **Sin parche autorizado de motor**; la reproducción queda a W04/IA6/W02. No afirmar compatibilidad nativa total W02.
- W04 V7 branch diverge mucho (78 ahead/95 behind en auditoría, heredó V4–V6); **nunca merge completo**. Posterior candidato IA6 selectivo deberá partir del HEAD oficial actual, trasladar hunks probados y pasar puertas W02/W03/W05/SaveV2 y regreso al mapa.
### IA3/W03 e IA5/W05
- W03 captura Repeat/Net/Moon/ledger y repel están en oficial y tienen puertas oficiales; W05 libros integrados por PR #120 y revalidados postmerge #43139045017. No duplicar material antiguo.
- Mantener veto `dynamax_candy` `excluded_ids`.

## Orden próxima `p` IA6
1. Verificar CI y SHA exacto de W01 Rocky Helmet; discriminar PASS nativo vs pruebas insuficientes; preparar integración QA mínima solo si verde y alineada con IA6 HEAD. 
2. Revisar progreso de W04 V7 regreso al mapa antes de integrar V6. Si sigue bloqueado, preparar ticket de dependencia nativa y no sustituir cierre real por cleanup.
3. W02 EXP Share V3: recuperar contrato antes de habilitar staging. No confundir documentación con trabajo completado.
4. Nunca tocar `main`, V28, PR #118, rama oficial directamente ni ramas originales de las trabajadoras sin prueba SHA.

**Regla:** ninguna CI antigua valida HEAD posterior por inferencia; solo se certifica el SHA y suite observados.
