# IA1/W01 · Auditoría Fase C preliminar (sin integración)

El precheck **no sustituye** la CI 38/38 ni autoriza `READY_FOR_IA6` por sí solo. Valida los **36 candidatos** (10 Fase A + 26 Fase B), la unicidad de IDs, 4 objetos excluidos por política, artefactos de test L2/L3 para cada placa y que ampliación de cobertura no se cuente como implementación nueva.

Cuando CI #42958587809 obtenga `completed/success` 38/38 sobre SHA `dead5a21679c0aa8f635f3ce12fce0279ada0fc0`, actualizar las 16 placas a `CERTIFICADO`, ejecutar este auditor hasta ver `W01_PHASE_C_LEDGER_READY total_certified=32 external=4` y preparar informe READY_FOR_IA6 en rama W01 sin fusionar.

**Estado ahora:** A10 + B6 certificados, B16 pilotos verdes pendientes de gate, B4 dependencias. 0 implementaciones de producción, integración árbitra NO.
