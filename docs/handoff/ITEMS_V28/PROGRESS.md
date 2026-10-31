# Registro cronológico — ITEMS_V28

- 2026-10-31: inspección mínima sin barrido del repositorio. V27 fusionada en main `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`; PR #116 merged. V3 #117 cerrada sin fusionar; 20/20 workflows PASS sobre `c554ab7635fb847aa395d2dbb5bc523b560bc6de`. El diff confirmado entre main y V3 preserva 7 archivos funcionales/CI y 5 históricos. Main ejecutó `Godot 4.7 Tests` PASS para el merge.
- Decisión: main oficial estable; rama `codex/items-v28-from-main` desde el SHA oficial. No reabrir ni fusionar la PR V3. Reconstruir solamente el **código probado** por blobs idénticos, dejando sus cuadernos antiguos históricos. Crear paquete de traspaso ITEMS_V28.
- **Pendiente exacto:** copiar los siete blobs declarados, ejecutar CI real V28, inspeccionar jobs de fallos solamente; registrar SHA, checks y estado; no declarar V28 verificada antes de los workflows. Después seleccionar familia nueva y revisar dependencias puntuales. La aprobación GPU/manual queda pendiente.
