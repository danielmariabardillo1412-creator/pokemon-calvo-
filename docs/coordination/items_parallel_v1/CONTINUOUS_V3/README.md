# IA6 — MISIONES DE DESBLOQUEO CONTINUO V3 · 2026-11-11

La campaña V2 ya fue agotada por W02/W03/W04/W05 (READY_FOR_IA6), mientras W01 continúa V2 en Fase B. IA6 comprobó checkpoints y CI: W02 #42937706214, W03 #42931723587, W04 #42945615987, W05 #42929830881, todos completed/success sobre sus SHAs funcionales. Los HEAD posteriores documentales pueden no coincidir con la CI.

**V3 sustituye V2 únicamente en la trabajadora cuya nota IA6_AUTORUN.md se haya actualizado expresamente.** Mantiene el protocolo general de checkpoints, ejecución sin STOP cada diez, dominios exclusivos, QA causal y CI/sha. W01 permanece en V2; no interrumpir su TANDA04+B02/B03. Cada W de V3 tiene misión de fases A/B/C, no diez IDs inventados. Al cerrar una fase con pruebas propias, continuar a la siguiente sin consultar IA6, hasta que se agote la misión, se encuentre bloqueo de arquitectura protegido, o acabe el turno.

Planes:
- [W02](PLAN_W02.md): recibo de participación de batalla y contrato EXP Share OPT-IN; no activar XP por defecto ni tocar ProgressionSystem.
- [W03](PLAN_W03.md): Heavy/Moon/Beast con fuente canónica de especie, ninguna bandera de mundo inventada.
- [W04](PLAN_W04.md): siete evoluciones regionales L3, permisos locales estrictos para EvolutionSystem.apply_evolution + FieldItemService.evolve/evolution_options.
- [W05](PLAN_W05.md): montaje real del panel MT en FieldItemBag, exclusivamente rama W05; integración central IA6 posterior.

**Extremos compartidos:** W02 es solo lectura de eventos de batalla; W03 tiene un cambio de contexto de captura, no de cierre XP; W04 usa EvolutionSystem y FieldItemService para regionales; W05 usa solo FieldItemBag para libros. IA6 integra cambios por función en su propia rama, comprobando competencia de W02 naturaleza efectiva, W03 ledger/repelentes, W04 forma y W05 panel. No cherry-pick de archivos compartidos a ciegas. **No tocar main, V28 ni PR118.**

Cada trabajadora debe guardar checkpoint V3 propio en CONTINUOUS_V3/STATE_W0X.md, con mission, phase, next_safe_action, HEAD, last_good_SHA, CI, verdaderas funciones L3, bloqueos y entrega IA6. No borrar el estado V2 que queda como historia. Si se agotan tareas, READY_FOR_IA6 es el resultado correcto. ChatGPT no puede permanecer en segundo plano ni abrir conversaciones automáticamente; un nuevo p reanuda el trabajo autorizado.

**Importante:** nunca afirmar que W04 o W05 están integradas en el árbol IA6 solo por probar su rama propia. Puerta final conjunta = CI propia de IA6 sobre SHA exacta, con SaveV2, FieldItemBag, Cuerda Huida, repelente, naturaleza efectiva, Repeat/Net, evolución regional y libro ES, más limitación Windows/GPU.
