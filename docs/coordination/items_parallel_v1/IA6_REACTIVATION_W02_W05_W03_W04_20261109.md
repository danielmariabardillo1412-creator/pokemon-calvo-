# IA6 — REACTIVACIÓN CONTROLADA W02–W05 · 2026-11-09

**Autoridad:** IA6, tras comprobación de ramas y últimas CI. Este documento no reabre CAMPAÑA_006, no certifica nuevos efectos y no autoriza merges. No tocar `main`, V28, PR #118 ni ramas ajenas.

## Estado y decisiones

| Trabajadora | Recibo vigente | Asignación inmediata | Dónde trabajar |
| --- | --- | --- | --- |
| W02 | CAMP006 FINALIZADA, #42437567862 SUCCESS; `gentle_mint` positivo, otras mentas pendientes | Piloto MINT-L3: conectar las tres mentas `lonely_mint`, `mild_mint`, `naive_mint` desde mochila, stats reales y SaveV2 | `codex/calvo-items-20261109-w02-mints-integration` |
| W03 | CAMP006 3 completados; 04 diferido, 05 bloqueado por productor; CI últimas sin jobs por YAML | Primero reparación de workflow, SIN contar bloque; después completar integración L3 de repelentes del 03, en prueba desde pasos/encuentro real | `codex/calvo-items-20261104-w03-camp006` |
| W04 | CAMP006 completados 01–03; 04 diferido, 05 bloqueado; #42679483422 SUCCESS de diagnóstico | Implementar resolver puro de condiciones de sexo/día/luna, con contratos reales de datos y pruebas; NO declarar L3 sin productores | `codex/calvo-items-20261104-w04-camp006` |
| W05 | CAMP006 FINALIZADA, 49 MT, #42417890877 SUCCESS | Piloto LIBROS-UI-L3: presentación española de libros + recorrido de selección/enseñanza real y SaveV2, sin alterar catálogo | `codex/calvo-items-20261109-w05-books-ui` |

## W02 — nueva tarea INTEGRACIÓN MINT-L3 01 (no CAMPAÑA_007)

Partir de cierre W02 sin modificar sus comprobaciones. El helper `field_mint_effects.gd` solo admite actualmente `naughty/gentle/rash/sassy/serious`. Implementar únicamente `lonely/mild/naive`, con validación canónica de naturaleza efectiva, invariantes de HP, especie, originales, identidad, efecto estadístico real, consumo de una unidad y SaveV2 (incluidas partidas anteriores sin campo de naturaleza efectiva). Probar uso real desde mochila donde exista el camino. Descartar dobles consumos, falsas mutaciones y estado temporal de combate; mantener la naturaleza original. No tocar `StatCalculator`, `ProgressionSystem`, Showdown, SaveV2 central. CI nueva de rama para bootstrap + nuevas pruebas. Un `p` posterior no autoriza fila 02 sin nueva puerta IA6: esta orden es un PILOTO 01.

## W03 — reparación de CI + mundo real

El workflow `.github/workflows/parallel-camp006-w03-autoci.yml` tiene líneas duplicadas al final después de `path: camp006-w03-*.log`, con indentación YAML inválida; últimos runs #42679055349 / #42678974569 / #42678885605 FAILED sin jobs. Repararlo en su propia rama, eliminando solamente cola corrupta y manteniendo todos los steps existentes. Validar estructura y obtener ejecución real; conservar CAMP005 regresión completa. Reparación de CI no consume bloque ni es PASS funcional.

A continuación trabajar sobre integración L3 del bloque 03: productor `OverworldPlayer.step_completed`, filtro real anterior al encuentro en `OverworldEncounterDirector`, activación desde mochila, gasto una sola unidad, duración 100/200/250 pasos reales y persistencia de `active_id/remaining_steps` en fuente legítima de SaveV2. Se autoriza investigar y crear adaptador local a la rama W03; cambios mínimos y exclusivamente relativos al repelente en `OverworldEncounterDirector` y `FieldItemBag` requieren tests positivos, negativos, RNG estable y revisión central ANTES de integración; NO modificar SaveV2 central ni sesión compartida sin puerta adicional. Si falta productor de persistencia, entregar interfaz exacta + test rojo real y detener esa parte. El bloque 04 sigue aplazado y 05 bloqueado por falta de pesca/surf/buceo; no contarlos. Esta tarea es remediación del 03 y no autoriza avanzar al 06.

## W04 — núcleo de condiciones de evolución

No inventar niveles de intercambio (política V27 `level_values_selected:null`). Desarrollar un resolver aislado, sin modificar `CreatureInstance`, SaveV2 ni `FieldItemService` central, para leer condiciones canónicas ya importadas y aceptar o rechazar **datos verificados**: `dawn_stone` Kirlia macho→Gallade / Snorunt hembra→Froslass; `oval_stone` held + level-up de día; `peat_block` luna llena. Aislar la evaluación sin fingir que sexo, día y luna proceden hoy del juego: L2 del resolver no es L3. Reportar contrato mínimo concreto para productores persistentes: sexo individual en fábrica/criatura, reloj del mundo jugable y fase lunar. Mantener CI CAMP006/CAMP005 y estados `completed=3`, 04 diferido, 05 bloqueado hasta producto real. No ejecutar bloque 06 (Alcremie) sin puerta. El nuevo resolver es preparación positiva del sistema compartido; IA6 decidirá integración y dueños de productores.

## W05 — nuevo piloto LIBROS-UI-L3 01 (no CAMPAÑA_007)

Conservar 49 MT certificadas y todas las regresiones. Probar con especies reales `tm202`, `tm31` (perfiles activos SV) y casos negativos un panel de **presentación de libro** a partir de `FieldMachineBookProfile.presentacion` y `FieldItemService.teach`: texto español/tipo del movimiento, compatibilidad/learnset, PP, selección de destino, sustitución si procede, consumo una unidad solo si enseña y SaveV2 tras recarga. Priorizar reutilizar mochila actual; no construir sistema paralelo de aprendizaje. Se permite un controlador/componente de presentación nuevo y tests en rama propia; NO cambiar `FieldItemBag`, SaveV2, datos canónicos ni frontend común sin puerta IA6 (W03 usa `FieldItemBag` para Cuerda Huida). CI nueva de rama para bootstrap + nuevas pruebas; no declarar revisión visual/GPU hasta prueba humana en PC. No reactivar máquinas legacy ni inventar nuevos IDs.

## Puertas comunes

Cada trabajadora publica documento breve de continuidad con HEAD exacto, diff, pruebas y CI real; distingue L1/L2/L3, dependencias y cambios compartidos. Los pilotos 01 no cuentan como objetos nuevos; no inventar CAMPAÑA_007 completa. IA6 integrará solo cambios revisados en `codex/calvo-ia6-integration-20261109` después de CI, sin merge total. No alterar el estado de CAMPAÑA_006_FINALIZADA para W02/W05. Cada `p` en W02/W05 ejecuta solo la tarea piloto autorizada hasta su cierre y posterior decisión explícita.
