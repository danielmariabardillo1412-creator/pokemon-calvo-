# Objetos fuera del combate V4 — 2026-10-28

Se conectan **21 IDs** a la mochila real de la demo existente: las **15 medicinas**
del contrato moderno ya utilizado en combate y **6 bayas reductoras de EV**.
No se cambia la selección de objetos permitidos ni se activan nuevas reglas de
randomlocke. No se modifica ningún dataset bruto, imagen o perfil de combate.

## Conexiones

- Poción, Superpoción, Hiperpoción, Poción Máxima y Restaurar Todo recuperan PS
  según el mismo contrato utilizado por el motor nativo.
- Antídoto, Antiquemar, Antihielo, Despertar, Antiparalizador y Cura Total curan
  sus estados; Restaurar Todo combina la recuperación con su curación.
- Éter y Éter Máximo exigen seleccionar un movimiento. Elixir y Elixir Máximo
  restauran los movimientos del Pokémon, respetando sus máximos actuales de PP.
- Grana, Algama, Ispero, Meluce, Uvav y Tamate reducen hasta 10 EV de la
  estadística correspondiente y aplican la amistad base con Campana Alivio.

El servicio prepara una copia, valida el dueño y consume exactamente una unidad
al publicar un efecto real. Un objeto sin efecto, un objetivo ajeno, la mochila
corrupta, una actividad que bloquee el campo o un Pokémon debilitado no gastan
el objeto ni alteran el estado. Los vetos se siguen comprobando antes de actuar.
La curación puede operar sobre el mismo dueño en equipo o PC; la UI muestra el
equipo. Las pruebas de bayas de este lote usan objetivos en el equipo.

Curar sueño retira también su reloj nativo compartido; así el guardado no conserva
un reloj huérfano. Las bayas recalculan las estadísticas usando el sistema
existente. Al bajar PS máximos conservan el déficit con un mínimo de 1 PS para un
objetivo vivo. No se provoca un debilitamiento ni se revive a un Pokémon.

La mochila muestra PS actuales/máximos, ofrece selección de PP y mantiene visible
el objeto seleccionado después de refrescar la lista. Las MT conservan su
selección explícita de sustitución.

## Evidencia

- Sin ventana: **1814 comprobaciones, PASS**.
- Con GPU: **1816 comprobaciones, PASS**.
- **192 contextos positivos registrados** entre medicinas en equipo/PC y
  bayas con distintos EV/amistad. Las pruebas negativas y de guardado son
  comprobaciones adicionales, no IDs adicionales.
- Casos límite: PP aumentados, selección inválida, estados incorrectos, confusión,
  límites de amistad/EV, Campana Alivio consumida, Pomeg a 1 PS, propiedad ambigua,
  ausencia de objeto, actividad de combate y datos temporales de Transformación.
- El flujo real abre B, cura sueño, usa Poción/Éter/Grana, guarda y carga en un
  archivo de prueba separado, y entra en el combate nativo con los PS, EV, PP y
  estado resultantes. No se usa el archivo de partida habitual.
- Regresiones: conexiones de 625 equipados, 229 MT y rutas de evolución; medicina
  en combate; campo; guardado normal/adversarial; política; inventario/captura.
  Todas PASS.

Reproducción:

```text
python tools/item_audit/run_field_v4.py
```

El ejecutor lanza la ventana de prueba oculta, comprueba errores de script y
publica los informes solo después de pasar todas las fases. La evidencia local
queda en `.godot/item_field_v4/`; el JSON conserva hashes de fuentes y resultados.
La matriz de 2.222 IDs se publica como CSV con extensión `.csv.txt` para evitar
que Godot la importe como un recurso de traducción.

## Alcance pendiente

Las seis bayas ya tienen conexión de EV y amistad base. **Los bonus por Poké Ball
de captura y mapa de origen siguen pendientes**: CreatureInstance no conserva
esos metadatos. No se adivinan ni se certifican esos bonus. Campana Alivio sí se
comprueba mediante el estado real del objeto equipado.

De los 47 pendientes concretos del barrido V3, quedan **41 conexiones principales**:
26 rutas de formas, 14 usos de comida/concursos/mundo y Lazo Destino. Los bonus de
origen de las seis bayas se conservan aparte en `ITEM_PENDING_V4.json`.

Esto no cierra todo el catálogo: otros alimentos/medicinas/bayas de curación,
vitaminas, plumas, caramelos, IV, naturalezas y habilidades necesitan sus rutas;
también siguen las bolas condicionales, máquinas antiguas, evoluciones
condicionadas y Cuerda Huida. Los 189 IDs con escenarios de efecto de combate
verificados en fases previas conservan su alcance; estas 21 conexiones de campo
no se suman como 21 efectos equipados nuevos.

## Referencias y agradecimientos para créditos

Se reutiliza el contrato local `battle_medicine_profile.json` y los servicios
existentes de estadísticas, propiedad, inventario y guardado. Para las bayas se
contrasta el comportamiento con **Maruno17 y colaboradores de Pokémon Essentials**,
commit `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`:

- [Uso de bayas reductoras](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/013_Items/001_Item_Utilities.rb).
- [Amistad y recálculo de PS](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/014_Pokemon/001_Pokemon.rb).

La adaptación en GDScript usa nuestro estado transaccional; no ejecuta Ruby ni
instala otro motor. `tests/fixtures/item_field_v4/reference_contract.json`
conserva el commit, hashes y los límites de contexto para futuras revisiones.
