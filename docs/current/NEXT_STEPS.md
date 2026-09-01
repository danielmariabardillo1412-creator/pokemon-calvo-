# SIGUIENTE TRABAJO

## Paso inmediato — cerrar PR #96

La reorganización documental está funcionalmente validada en el checkpoint:

`ee22bd5bcb5c57f0203ba2a95d19775ba01d5cb0`

con **18/18 workflows SUCCESS**.

Después de ese ciclo se completó la auditoría final de documentación formal y se corrigieron dos fuentes todavía obsoletas (`ARCHITECTURE.md` y `DATA_FOUNDATION_V3.md`), preservando sus versiones originales en historial.

Como esa corrección mueve el SHA, el nuevo HEAD final debe:

1. ejecutar los 18 workflows normales;
2. obtener **18/18 SUCCESS** sobre ese mismo SHA;
3. mantener un diff frente a `b4f6adc200bef18f8ac51b9144f2f9a838f464fd` limitado a `README.md` y `docs/**`;
4. cerrar PR #96 **sin merge**;
5. convertirse en el parent exacto del siguiente workstream.

No hacer un commit posterior para registrar el cierre del PR.

## Después — Trainer AI

Abrir la siguiente rama desde el HEAD final certificado de #96 y realizar primero una auditoría corta de la arquitectura existente.

Dirección ya confirmada:

- `TrainerProfile` ya cubre **estilo** (`balanced`, `aggressive`, `cautious`, `technical`);
- la siguiente capa debe representar **competencia/expertise** por separado;
- los entrenadores serios deben construir sobre `StrategicSwitchingTrainerBrain`;
- reutilizar Trainer Loadouts y Trainer Team Composition;
- mantener exactamente la misma frontera de información legítima para todos los niveles;
- demostrar diferencias de competencia mediante tests/corpus, nunca mediante hidden information;
- no aumentar depth/branching ni introducir MCTS/red neuronal sin un límite real demostrado.

Candidatos narrativos a estudiar, no todavía congelados como contrato: entrenador ordinario, entrenador competente, Líder, Alto Mando, Campeón/boss-tier.

Referencia operativa:

`docs/project_book/TRAINER_AI.md`.

## Más adelante

La sustitución/eliminación de la `main` antigua se realizará **después** de esta reorganización y de forma separada. No mezclar ese cambio de rama principal con FASE34 ni con la certificación documental.
