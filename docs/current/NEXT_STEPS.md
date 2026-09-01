# SIGUIENTE TRABAJO

## Ahora mismo

Terminar y certificar la **reorganización documental** sobre:

- rama: `chore/documentation-consolidation-v1`
- parent certificado: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`

Alcance permitido: documentación, índices, consolidación de cuadernos y archivo de worklogs. No tocar lógica de juego, datos canónicos, tests ni mecánicas.

## Cierre de esta reorganización

Antes de considerarla terminada:

1. `docs/current/` debe ser la única fuente documental de estado vivo;
2. los antiguos `docs/notebooks/` deben quedar consolidados/archivados, no activos;
3. DATA V3 debe tener un único cuaderno temático de consulta y sus diarios completos quedar en historial;
4. Trainer AI debe tener un único cuaderno temático con el stack FASE19–33 y el punto de continuación;
5. arquitectura, referencias, ADR e historial deben quedar separados por función;
6. todos los enlaces internos modificados deben apuntar a las rutas nuevas;
7. el diff frente a `b4f6adc2...` debe ser exclusivamente documental;
8. el HEAD final exacto debe pasar la matriz normal de workflows antes de cerrar el PR sin merge.

Como esta rama no contiene un HEAD de código previo al que añadir después cuadernos, no hace falta fabricar dos ciclos artificiales de CI: se exige **un ciclo completo sobre el HEAD documental final exacto**. Si el contenido cambia después de ese ciclo, debe repetirse.

## Después: Trainer AI

La siguiente fase se definirá tras una auditoría corta de la arquitectura existente.

Dirección prevista:

- no duplicar `TrainerProfile`, que ya representa estilo (`balanced`, `aggressive`, `cautious`, `technical`);
- separar **estilo** de **competencia/expertise**;
- construir entrenadores serios sobre `StrategicSwitchingTrainerBrain`, loadouts y composición de equipos ya existentes;
- mantener exactamente la misma frontera de información legítima para todos los niveles;
- demostrar diferencias de comportamiento/competencia mediante tests y corpus, no mediante acceso a información oculta;
- no aumentar profundidad, branching ni introducir MCTS/red neuronal sin un límite real demostrado.

Candidatos de expertise a estudiar, no todavía congelados: entrenador ordinario, entrenador competente, Líder, Alto Mando y Campeón/boss-tier.

Referencia: `docs/project_book/TRAINER_AI.md`.

## Más adelante

La sustitución/eliminación de la `main` antigua se hará **después** de que esta organización esté certificada. Será una operación separada para no mezclar reorganización documental con movimiento del baseline principal.
