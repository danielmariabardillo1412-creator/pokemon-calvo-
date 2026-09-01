# Arquitectura actual — visión general

Este documento describe la **estructura vigente a alto nivel** del proyecto. Los contratos detallados de cada subsistema están en los demás documentos de esta carpeta y las decisiones originales en `docs/adr/`.

Para estado, SHA certificado y siguiente trabajo no usar este archivo: consultar `docs/current/`.

## Principios de arquitectura

El proyecto mantiene separación entre:

- **dominio y reglas**: estado y lógica autoritativa, independientes de presentación;
- **aplicación/orquestación**: coordina acciones legales y servicios del dominio;
- **presentación/escenas**: Godot Nodes, UI y adaptación visual;
- **datos estáticos**: definiciones canónicas importadas y catálogos;
- **IA de entrenadores**: consume una vista sanitizada del combate y nunca se convierte en autoridad de reglas.

La regla principal sigue siendo que una capa visual o un cerebro de entrenador puede **solicitar/seleccionar** una acción, pero la legalidad y mutación del estado pertenecen al sistema autoritativo correspondiente.

## Battle Core

El combate se apoya en `BattleState`, reglas deterministas, ejecución por fases y RNG inyectado. Presentation recibe eventos semánticos y no debe ser dueña de la verdad del combate.

El runtime soporta, entre otras superficies ya implementadas:

- movimientos y PP;
- daño físico/especial;
- stages;
- estados;
- habilidades e items dentro de la frontera runtime certificada;
- switching;
- acciones de items de entrenador;
- snapshot/serialización determinista.

Detalle:

- `BATTLE_ARCHITECTURE.md`
- `BATTLE_EFFECTS.md`
- `BATTLE_RULESET_CALVO_V1.md`

## Datos canónicos — DATA FOUNDATION V3

La fuente Pokémon es un snapshot inmutable de PokéAPI:

- `data/api/v2`
- `data/schema/v2`

El pipeline vigente es:

`snapshot → adapter V3 → auditorías semánticas → raw → DataImporter → normalized → runtime`

DATA V3 está cerrado en una frontera explícita entre dato preservado y mecánica ejecutable. No se interpreta la existencia de 373 habilidades o 2.222 objetos como soporte runtime de todas sus mecánicas.

Detalle formal: `DATA_FOUNDATION_V3.md`.

Resumen operativo/certificación: `docs/project_book/DATA_V3.md`.

## Criaturas, progresión, captura, party y almacenamiento

`CreatureSpecies` representa definición estática; `CreatureInstance` representa una criatura concreta con identidad y estado mutable.

Los subsistemas de progresión, captura, party y storage conservan esa identidad por `instance_id` y evitan duplicar una criatura al moverla entre superficies persistentes.

Detalle:

- `PROGRESSION_ARCHITECTURE.md`
- `PROGRESSION_RULESET_CALVO_V1.md`
- `CAPTURE_ARCHITECTURE.md`
- `CAPTURE_RULESET_CALVO_V1.md`
- `PARTY_ARCHITECTURE.md`
- `STORAGE_ARCHITECTURE.md`

## Savegame

El sistema de guardado mantiene registro canónico de criaturas y referencias desde party/storage, con validación antes de publicar estado cargado y reemplazo protegido del fichero.

Detalle: `SAVEGAME_ARCHITECTURE.md`.

## IA de entrenadores

La IA FASE19–33 es un sistema separado del Battle Core. Battle Core sigue siendo autoridad de legalidad.

La arquitectura de Trainer AI contiene actualmente:

- contexto de decisión sanitizado;
- evaluación táctica y perfiles de estilo;
- belief inference;
- búsqueda determinista y acotada sobre mundos plausibles;
- self-play y corpus de evaluación;
- branching adaptativo y cobertura pública inferida;
- items de entrenador finitos;
- switching estratégico;
- loadouts;
- análisis y composición de equipos.

`TrainerProfile` representa **estilo** (`balanced`, `aggressive`, `cautious`, `technical`) y no concede información oculta.

La ruta seria actual parte de `StrategicSwitchingTrainerBrain`. La siguiente expansión debe estudiar **competencia/expertise** como concepto separado del estilo, reutilizando loadouts y composición de equipo existentes.

Resumen operativo: `docs/project_book/TRAINER_AI.md`.

Decisiones formales: ADR 019–033 en `docs/adr/`.

## Overworld y presentación

Las escenas y controladores visuales viven fuera del dominio puro. La vertical slice técnica integra movimiento físico, encuentros y presentación del combate sin convertir la escena en autoridad de reglas.

La existencia de Nodes en overworld/presentación es intencionada; las antiguas afirmaciones de fases fundacionales del tipo “0 Nodes fuera de tests” no describen ya el repositorio completo.

## Determinismo y testabilidad

El determinismo se preserva donde afecta a reglas, simulación y evaluación. Las fuentes de aleatoriedad relevantes se inyectan o fijan mediante seeds en pruebas.

La autoridad de validación no es un contador escrito en documentación: son los workflows ejecutados sobre el **SHA exacto** que se pretende certificar. Los números de PASS incluidos en documentos de fases anteriores deben leerse como evidencia de aquella fase, no como total global actual.

## Documentos y autoridad

- estado vivo: `docs/current/`
- memoria temática: `docs/project_book/`
- arquitectura de subsistemas: `docs/architecture/`
- decisiones: `docs/adr/`
- evidencia histórica: `docs/history/`

En caso de conflicto, GitHub/CI/artefactos del SHA exacto y las fuentes canónicas prevalecen sobre los resúmenes documentales.
