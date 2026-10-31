param([int]$BatchSize = 20)
$ErrorActionPreference = 'Stop'
if ($BatchSize -lt 1 -or $BatchSize -gt 20) { throw 'BatchSize debe estar entre 1 y 20.' }
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$godot = 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Falta Godot 4.7 local.' }
& $godot --headless --path $projectRoot --script tests/visual/move_contact_capture.gd -- --self-test
if ($LASTEXITCODE -ne 0) { throw 'Falló la prueba del selector temporal; no generar evidencia con muestras repetidas.' }
# Complete functional sweep first; do not touch canonical data or re-import packs.
& $godot --headless --path $projectRoot --script tests/visual/move_batch_audit_runner.gd --log-file .godot/move_batch_checks/contacts_headless.log
if ($LASTEXITCODE -ne 0) { throw 'Falló el barrido funcional; no crear hojas como si todo funcionara.' }
& $godot --path $projectRoot --script tests/visual/move_contact_capture.gd --resolution 64x64 --disable-render-loop --disable-vsync --max-fps 0 --log-file .godot/move_batch_checks/contacts_gpu.log
if ($LASTEXITCODE -ne 0) { throw 'Falló la captura GPU.' }
& python (Join-Path $PSScriptRoot 'build_move_contact_sheets.py') --batch-size $BatchSize
if ($LASTEXITCODE -ne 0) { throw 'Falló la composición o su evidencia estaba obsoleta.' }
