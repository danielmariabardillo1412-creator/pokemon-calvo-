# W01 CONTINUOUS_V2 / B01-05 Cinta Experto

El efecto `onModifyDamage` y un piloto histórico `held_pilot.cjs` ya estaban presentes: **no añadir objeto nuevo a la métrica**. Prueba independiente NativeEngine de 5 modos (super eficaz, sin objeto, objeto en reserva, neutral con/sin objeto), idénticos seeds, contra Gyarados, sin falso daño fabricado.

L3 recorre mochila/equip/Showdown/settlement/SaveV2 y compara magnitud real del daño; el efecto solo debe aumentar daño super eficaz del portador activo, sin consumir la Cinta. Tras piloto verde debe integrarse en CI acumulativa de B con regresiones de A y campañas históricas. No tocar producción.
