# Curvas de experiencia — corrección previa a caramelos

Base local: 52c37164. Durante la revisión para reutilizar la progresión existente
se detectaron dos fallos previos, confirmados también por el hash del archivo del
original protegido (solo leído, no ejecutado ni modificado):

1. PokéAPI conserva slow-then-very-fast y fast-then-very-slow. El ruleset solo
   reconocía erratic/fluctuating, por lo que esas especies usaban medium.
2. El tramo 69–98 de erratic dividía por 1.000; la tabla requiere 500. La tabla
   calculada dejaba incluso de ser monótona y la búsqueda inversa fallaba.

La corrección está en ProgressionRuleset: normaliza los dos nombres al consultar
la regla central y corrige ese divisor. Mantiene los IDs canónicos de datos,
el fallback de nombres desconocidos y todas las fórmulas restantes. No duplica
reglas en un efecto de objeto ni modifica datasets, selección de contenido,
imágenes, motor nativo o formato de guardado.

## Referencia independiente y reproducción

Se extrajeron 600 valores factuales ya existentes en Git de los seis growth-rate
del snapshot PokéAPI. Todos coinciden con los arrays constantes de Essentials
8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b:
[GrowthRate.rb](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/010_Data/001_Hardcoded%20data/001_GrowthRate.rb).
Créditos: Maruno17 y colaboradores. No se ejecutó Ruby ni un regenerador de datos.
El contrato conserva blobs Git, hashes y valores en
tests/fixtures/progression_growth_curves/reference_contract.json.

La prueba cubre niveles 1–100, seis curvas y ocho nombres, umbrales/inversa,
puntos anterior/siguiente, topes y fallback. Recorre además las 43 especies base
con esos nombres, comprobando fábrica, ganancia de nivel, serialización y XP de
combate. Incluye datos de especies excluidas para verificar la fórmula: no las
habilita en los pools del juego.

Antes de corregir: 1.205 asserts fallidos de 4.209. Después: 4.209 PASS. Los
resultados/logs previos se conservan en .godot/cleanup_checks/growth_alias_before/;
la repetición y el núcleo 472 PASS están en growth_alias_after/.

La verificación ampliada usa tools/verification/run_growth_curves.py y un guard
compartido nuevo, parametrizado por checkpoint y allowlist. No modifica ni
resella los manifiestos de T006B o V5–V8. Su manifiesto propio queda en
.godot/progression_growth_curves_audit/scope_base.json.

Resultado ampliado: **PASS en los nueve grupos**, incluida importación, curvas
4.209, núcleo 472, campo nativo 118, restauración 912, PP V8 43.588, entrenamiento
V7 6.990, corpus de entrenadores 628 y PP con GPU 43.590. Integridad completa:
22.949 archivos protegidos PASS y 15.647 ausentes con skip-worktree preservados.
Ocho comprobaciones del guard verifican rechazo de hash incorrecto, archivo
ausente, cambios fuera de alcance, raíz/salida incorrectas y resellado; no alteran
el manifiesto real. Los casos negativos usan fixtures locales dentro de .godot.

Informe con comandos/logs/hashes: [PROGRESSION_GROWTH_CURVES_FIX.json](PROGRESSION_GROWTH_CURVES_FIX.json).
Evidencia local adicional: .godot/progression_growth_curves_audit/runs/,
prerequisite_evidence.json y guard_contract_checks.json.
Para repetir las puertas con el manifiesto ya preparado:

```text
python tools/verification/run_growth_curves.py
```

--prepare solo crea el manifiesto inicial del checkpoint declarado y rechaza
sobrescribir uno existente; no se usa para validar cambios posteriores fuera
del alcance. El guard compartido puede usarse con contratos nuevos de objetos,
sin acoplarlos al runner histórico de V8.

## Límites de esta corrección

Es un requisito previo; los caramelos siguen pendientes de conectar. No se
introducen decisiones automáticas de movimientos/evolución ni un motor nuevo.
El contador de efectos de campo permanece en 61 (V8).

No se reescriben partidas antiguas ni se cambia su schema. No existe actualmente
pokemon_calvo_field.json en el userdata de esta copia. Una futura importación
de partidas de la versión anterior debe revisar coherencia de nivel/XP para
estas curvas antes de migrar valores; no reparar silenciosamente ni consumir
caramelos sobre un estado incoherente. El original y su userdata quedan aparte.
