# IA6 — COLA W04 · TANDA 06 — evolución nativa con forma regional correcta
Fecha: 2026-11-11. Trabajadora: IA4/W04.
Rama de trabajo exclusiva: `codex/calvo-items-20261104-w04-camp006`.
Baseline: TANDA 05 cerrada 10/10, 2 contratos L2, 0 evoluciones L3; 55/56 formas regionales validadas. Informes `reports/W04/AUTORUN_V5_FINAL.md` y `AUTORUN_V5_PROGRESS.csv`. No repetir T05.

## Objetivo y alcance
Corregir de forma mínima y verificable el defecto demostrado por T05: `EvolutionSystem.apply_evolution` crea la especie de destino pero deja vacío `form_id` para `slowpoke_galar` usando `galarica_cuff` o `galarica_wreath`. Obtener evolución nativa con identidad de destino `slowbro-galar` / `slowking-galar`, no la forma de origen. Conservar comportamiento de evoluciones ordinarias y Randomlock.

## Autorización extraordinaria, estrictamente acotada
IA6 autoriza a W04, **solo en su rama**, un cambio mínimo en la función `EvolutionSystem.apply_evolution` y un helper W04 si es necesario para resolver y validar la `form_id` del destino en las dos rutas Galarica existentes. No usar asignación genérica de la forma del origen. Respetar las convenciones reales de ID verificadas en el código antes de editar. El permiso no se extiende a otras funciones de EvolutionSystem ni a `FieldItemBag`, `FieldItemService`, `CreatureInstance`, `CreatureFactory`, SaveV2 central, configuración ni motor de batalla. La integración mochila→consumo→reemplazo→rollback sigue reservada a IA6. Si la corrección requiere otro módulo compartido, registrar ticket y no tocarlo.

## Diez hitos consecutivos (sin nueva p por hito)
01. Recuperar HEAD/checkpoint y certificar baseline T05, identificar ruta de `apply_evolution`, firma y productores reales.
02. Reproducir fallo con prueba roja de forma de destino al aplicar `galarica_cuff` a Slowpoke Galar.
03. Reproducir fallo análogo con `galarica_wreath`; verificar IDs canónicos exactos.
04. Introducir reparación mínima autorizada de forma del destino, condicionada al contrato especie+forma+objeto+registro; no afectar casos ordinarios.
05. Positivos reales `slowpoke_galar` → `slowbro_galar` y → `slowking_galar`, con `form_id` correcto y especie correcta, vía `apply_evolution` nativa.
06. Negativos: Slowpoke Kanto, origen sin forma, ítem erróneo, destino incompatible, forma corrupta; no promover si falla validación canónica.
07. Preservar `instance_id`, datos estadísticos, `nature_id`, estado persistente; verificar naturaleza efectiva solo si está disponible en su rama, sin editar W02.
08. Verificar Party/Storage y round-trip SaveV2 **del resultado producido realmente por la evolución nativa**, con legacy y casos corruptos; no simularlo creando destino directamente con Factory.
09. Regresiones completas T05/T04/T03/T02, CAMP003–006, caminos de evoluciones comunes y política Exeggutor Alola/Harvest oculta intacta.
10. CI final SUCCESS sobre SHA funcional, actualizar checkpoint e informe `reports/W04/AUTORUN_V6_FINAL.md` con separación L2, evolución nativa y L3 desde mochila.

## Reglas de aceptación
- `10/10 hitos examinados` no equivale a `10 efectos funcionales`.
- No contar L3 mientras falte consumidor transaccional real de mochila; describir nativamente como L2/integración parcial.
- No conceder Harvest oculta a Exeggutor Alola.
- Nunca modificar `main`, V28, PR #118 ni ramas ajenas.
- Si hay limitación técnica fuera del seam, registrar prueba roja/ticket, seguir pruebas independientes y cerrar con bloqueos explícitos. No inventar PASS.
- La trabajadora debe continuar todos los hitos dentro del turno hasta agotarlos o alcanzar un bloqueo real; conservar checkpoint para siguiente `p` solo si no termina. Sin trabajo en segundo plano.
